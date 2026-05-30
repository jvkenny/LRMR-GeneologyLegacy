#!/usr/bin/env python3
"""Auto-assign `branch` to People rows where branch IS NULL.

Strategy (in order of preference):

1. Build a lineage tree from the FamilySearch extract by linking each
   gen-N couple to a gen-(N-1) child via surname match (Czech/Italian
   gender variants get normalized; both husband-side and wife-side
   surnames are tried).
2. For each NULL-branch person with an fs_id, walk DOWN the tree
   (towards the proband). The first descendant with a known branch
   wins; that branch is propagated up to the NULL person.
3. Fallback: a surname-based map for people whose FS lineage chain
   breaks before reaching a labeled descendant (e.g. Czech and Italian
   surnames have clear branch ownership from CLAUDE.md notes).

Two-step protocol:
  default              writes reports/auto_branch_<DATE>.{md,json}
  --apply              writes the GPKG branch column

Backs up GPKG to .pre-branch.bak before --apply.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import sqlite3
import sys
import unicodedata
from collections import defaultdict
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GPKG = REPO / "src/data/lrgdm.gpkg"
EXTRACT_DIR = REPO / "src/data/familysearch"
PROBAND_PID = "L274-KNT"

# Final-resort surname-based mapping. Only used when the FS lineage walk
# can't find a labeled descendant. Each entry is keyed by the NORMALIZED
# surname (lowercase, ASCII-folded, Czech/Italian gender stem). The Czech
# Říha/Klusová and similar surnames here default to Paternal Kroll, since
# CLAUDE.md notes them as the Kroll paternal-grandmother lineage extending
# into Bohemia. Surnames that could belong to multiple branches (e.g. Reed)
# are intentionally omitted — those people should be settled via the FS
# walk, not the fallback.
FALLBACK_SURNAME_MAP: dict[str, str] = {
    # Czech (Kroll paternal-grandmother Bohemian lineage) — but Říha is
    # ambiguous: Czech surnames in the Zika branch (Anton + Josefína Říha)
    # vs Czech surnames in the Kroll-Bohemia branch (Laura Kroll's parents
    # and beyond). The FS walk should resolve. Omit ambiguous Czech here.
    # French-Canadian (Pouliot branch via Beatrice Pouliot)
    "filiatrault": "Pouliot",
    "stlouis": "Pouliot",
    "cheffre": "Pouliot",
    "audet": "Pouliot",
    "lapointe": "Pouliot",
    "lapierre": "Pouliot",
    "tremblay": "Pouliot",
    "denis": "Pouliot",
    "pepin": "Pouliot",
    "lachance": "Pouliot",
    "godbout": "Pouliot",
    "stmars": "Pouliot",
    "delage": "Pouliot",
    # Italian (Maternal Mariotti)
    "bellandi": "Maternal Mariotti",
    "giovacchini": "Maternal Mariotti",
    "ercolini": "Maternal Mariotti",
    "grossi": "Maternal Mariotti",
    "baldi": "Maternal Mariotti",
    "giacomelli": "Maternal Mariotti",
    "parlanti": "Maternal Mariotti",
    "porciani": "Maternal Mariotti",
    # Paternal Reed colonial-American ancestors. Hannah Paulson is
    # Paternal Reed in the existing data; Simon Poulson III + Ann Patton
    # are her parents (Paulson/Poulson is a vowel-spelling variant).
    "poulson": "Paternal Reed",
    "paulson": "Paternal Reed",
    "patton": "Paternal Reed",
}


def _stems_for(token: str) -> set[str]:
    """Generate matching stems for a surname token.

    Handles:
      * Czech feminine -ová and masculine -a (Říha/Říhová → "rih")
      * Czech masculine -ek vocalization (Michalíček/Michalíčková share
        the "michalick" stem)
      * English plurals (Spear/Spears, Oakes/Oaks)
      * Trailing -e (Oakes → "oak")
    """
    s = unicodedata.normalize("NFKD", token).encode("ascii", "ignore").decode().lower()
    s = re.sub(r"[^a-z]", "", s)
    if not s:
        return set()
    out = {s}
    if s.endswith("ova") and len(s) > 3:
        out.add(s[:-3])
        out.add(s[:-3] + "a")
    if s.endswith("a") and len(s) > 3:
        out.add(s[:-1])
    if s.endswith("s") and len(s) > 3:
        out.add(s[:-1])
    if s.endswith("es") and len(s) > 4:
        out.add(s[:-2])
    if s.endswith("ek") and len(s) > 3:
        out.add(s[:-2] + "k")        # michalicek → michalick
    return out


def fs_surname_set(name: str | None) -> set[str]:
    """Surname stems for matching across a name.

    Considers every token except the first (given name), plus tokens
    around `dit` patterns, plus Czech/Italian gender stems. Returns the
    UNION of matching stems so two names match iff their stem sets
    intersect.
    """
    if not name:
        return set()
    n = re.sub(r"\([^)]*\)", "", name).strip()
    n = re.sub(r"\b(Sr\.?|Jr\.?|II|III|IV|lll)\b", "", n).strip()
    parts = [p for p in n.split() if p]
    if len(parts) < 2:
        # Single-name people are rare in this dataset; fall back to the
        # whole string as a stem so it can still match itself.
        return _stems_for(n) if n else set()

    # Candidates: every word except the first. This captures last-name
    # AND embedded maiden names like "Josephine Riha Veta" → {Riha, Veta}.
    candidates = set(parts[1:])

    # "dit" idiom: "Filiatrault dit St. Louis"
    m = re.search(r"\bdit\b\s*(.+)$", n, re.I)
    if m:
        candidates.update(m.group(1).split())
    m = re.search(r"^(.+?)\s+\bdit\b", n, re.I)
    if m:
        candidates.update(m.group(1).split())

    stems = set()
    for c in candidates:
        stems |= _stems_for(c)
    return stems


def load_extract() -> dict:
    candidates = sorted(EXTRACT_DIR.glob("extract_*.json"))
    if not candidates:
        sys.exit(f"No FS extract found in {EXTRACT_DIR}")
    return json.loads(candidates[-1].read_text())


def build_lineage(extract: dict) -> tuple[dict[str, str], dict[str, list[str]]]:
    """Return (child_to_parent_couple, parent_couple_to_child).

    parent_couple_to_child is a mapping from a "couple key" (frozenset of
    the two parent PIDs) to a list of children PIDs (typically 1).
    child_to_parent_couple is its inverse: child PID → parent couple key.
    """
    fs_by_pid = {p["pid"]: p for p in extract["people"]}
    couples = extract["couples"]

    # Index couples by generation
    by_gen: dict[int, list[dict]] = defaultdict(list)
    for c in couples:
        by_gen[c["generation"]].append(c)

    # The proband sits at gen 0 (children list at gen -1 doesn't exist).
    # For each couple at gen N (N ≥ 1), its child is at gen N-1.
    # Candidates at gen N-1: every person who appears as parent in a
    # gen-(N-1) couple, plus the proband if N-1 == 0.
    couple_child: dict[str, str] = {}    # coupleId -> child pid
    ambiguous: list[dict] = []

    for c in couples:
        gen = c["generation"]
        if gen == 0:
            # gen 0 couple represents proband + spouse — no upstream child.
            continue
        p1 = c.get("parent1Pid")
        p2 = c.get("parent2Pid")
        cid = c.get("coupleId") or f"gen{gen}-{p1}-{p2}"

        # surname sets for each parent
        s1 = fs_surname_set((fs_by_pid.get(p1) or {}).get("name")) if p1 else set()
        s2 = fs_surname_set((fs_by_pid.get(p2) or {}).get("name")) if p2 else set()
        parent_surnames = s1 | s2

        # Candidates at gen-1
        candidates = []
        if gen - 1 == 0:
            candidates.append(extract.get("proband") or PROBAND_PID)
        for c2 in by_gen.get(gen - 1, []):
            if c2.get("parent1Pid"):
                candidates.append(c2["parent1Pid"])
            if c2.get("parent2Pid"):
                candidates.append(c2["parent2Pid"])

        matched = []
        for cand_pid in candidates:
            cand_name = (fs_by_pid.get(cand_pid) or {}).get("name")
            cand_surnames = fs_surname_set(cand_name)
            if cand_surnames & parent_surnames:
                matched.append(cand_pid)

        if len(matched) == 1:
            couple_child[cid] = matched[0]
        elif len(matched) > 1:
            # Multiple matches — typically because the same surname
            # appears in two sub-branches at gen N-1. Pick the first
            # but record ambiguity.
            couple_child[cid] = matched[0]
            ambiguous.append({
                "coupleId": cid,
                "gen": gen,
                "parents": [p1, p2],
                "candidates": matched,
                "picked": matched[0],
            })
        # else: no match; couple has no traced child in the proband's pedigree

    # Person → couple (the couple they're a parent IN, NOT a child of)
    # Plus parent-couple-key → child:
    parent_couple_to_child: dict[frozenset, str] = {}
    for c in couples:
        cid = c.get("coupleId")
        if cid not in couple_child:
            continue
        p1 = c.get("parent1Pid")
        p2 = c.get("parent2Pid")
        key = frozenset({p for p in (p1, p2) if p})
        parent_couple_to_child[key] = couple_child[cid]

    # Build per-person: who is your child? (the child of the couple you're in)
    person_child: dict[str, str] = {}    # parent pid -> their child pid
    for c in couples:
        cid = c.get("coupleId")
        child = couple_child.get(cid)
        if not child:
            continue
        if c.get("parent1Pid"):
            person_child[c["parent1Pid"]] = child
        if c.get("parent2Pid"):
            person_child[c["parent2Pid"]] = child

    return person_child, ambiguous


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    if not GPKG.exists():
        sys.exit(f"GPKG not found: {GPKG}")

    extract = load_extract()
    fs_by_pid = {p["pid"]: p for p in extract["people"]}
    person_child_fs, ambiguous = build_lineage(extract)

    conn = sqlite3.connect(GPKG)
    conn.row_factory = sqlite3.Row

    # GPKG-side maps
    rows = list(conn.execute(
        "SELECT person_id, primary_name, fs_id, branch FROM People"
    ))
    pid_to_branch: dict[str, str | None] = {r["person_id"]: r["branch"] for r in rows}
    pid_to_name: dict[str, str] = {r["person_id"]: r["primary_name"] for r in rows}
    fs_to_pid: dict[str, str] = {}
    for r in rows:
        if r["fs_id"]:
            fs_to_pid[r["fs_id"]] = r["person_id"]

    # GPKG Relationships: build parent->child as ground truth (overrides FS guess)
    rel_parent_child = defaultdict(list)   # parent_pid -> [child_pid]
    for pa, pb in conn.execute(
        "SELECT person_id_a, person_id_b FROM Relationships WHERE relation='parent'"
    ):
        if pa and pb:
            rel_parent_child[pa].append(pb)

    # Walk function: given a person_id, walk down through children until we
    # find a non-NULL branch. Returns (branch, path).
    def walk_down(start_pid: str, start_fs: str | None) -> tuple[str | None, list[str], str]:
        """Return (branch, path_of_person_ids, source).

        source ∈ {"gpkg_self", "gpkg_rel", "fs_walk", "fallback_surname",
                  "unknown"}
        """
        # Self
        b = pid_to_branch.get(start_pid)
        if b:
            return b, [start_pid], "gpkg_self"

        # Walk via GPKG Relationships first (most reliable)
        visited = {start_pid}
        queue: list[tuple[str, list[str]]] = [(start_pid, [start_pid])]
        while queue:
            cur, path = queue.pop(0)
            for child in rel_parent_child.get(cur, []):
                if child in visited:
                    continue
                visited.add(child)
                bc = pid_to_branch.get(child)
                if bc:
                    return bc, path + [child], "gpkg_rel"
                queue.append((child, path + [child]))

        # Walk via FS extract child mapping
        if start_fs:
            visited_fs = {start_fs}
            path_fs = [start_pid]
            cur_fs = start_fs
            for _ in range(15):    # bound to avoid loops
                nxt_fs = person_child_fs.get(cur_fs)
                if not nxt_fs or nxt_fs in visited_fs:
                    break
                visited_fs.add(nxt_fs)
                nxt_pid = fs_to_pid.get(nxt_fs)
                if nxt_pid:
                    path_fs.append(nxt_pid)
                    bc = pid_to_branch.get(nxt_pid)
                    if bc:
                        return bc, path_fs, "fs_walk"
                else:
                    # Reach the proband or someone not in GPKG — note path
                    path_fs.append(f"fs:{nxt_fs}")
                cur_fs = nxt_fs

        # Fallback surname map
        name = pid_to_name.get(start_pid, "")
        surnames = fs_surname_set(name)
        for s in surnames:
            if s in FALLBACK_SURNAME_MAP:
                return FALLBACK_SURNAME_MAP[s], [start_pid], "fallback_surname"

        return None, [start_pid], "unknown"

    # Process all NULL-branch People
    null_branch = [r for r in rows if not r["branch"]]
    proposals = []
    for r in null_branch:
        person_id = r["person_id"]
        fs_id = r["fs_id"]
        branch, path, source = walk_down(person_id, fs_id)
        proposals.append({
            "person_id": person_id,
            "primary_name": r["primary_name"],
            "fs_id": fs_id,
            "proposed_branch": branch,
            "source": source,
            "path": path,
            "path_names": [pid_to_name.get(p) or p for p in path],
        })

    # Stats
    by_source = defaultdict(int)
    by_branch = defaultdict(int)
    for p in proposals:
        by_source[p["source"]] += 1
        if p["proposed_branch"]:
            by_branch[p["proposed_branch"]] += 1

    today = date.today().isoformat()
    reports_dir = REPO / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)
    json_path = reports_dir / f"auto_branch_{today}.json"
    md_path = reports_dir / f"auto_branch_{today}.md"

    json_path.write_text(json.dumps({
        "generated": today,
        "null_branch_count": len(null_branch),
        "by_source": dict(by_source),
        "by_branch": dict(by_branch),
        "ambiguous_fs_couples": ambiguous,
        "proposals": proposals,
    }, indent=2))

    lines = [
        f"# Auto-Branch Proposal — {today}",
        "",
        f"- NULL-branch People: **{len(null_branch)}**",
        f"- Proposals with a branch: **{sum(1 for p in proposals if p['proposed_branch'])}**",
        f"- Proposals UNKNOWN: **{sum(1 for p in proposals if not p['proposed_branch'])}**",
        "",
        "## By source",
        "",
        "| source | count |",
        "|---|---:|",
    ]
    for src in ("gpkg_self", "gpkg_rel", "fs_walk", "fallback_surname", "unknown"):
        lines.append(f"| `{src}` | {by_source.get(src, 0)} |")
    lines += ["", "## By proposed branch", "", "| branch | count |", "|---|---:|"]
    for br, ct in sorted(by_branch.items(), key=lambda x: -x[1]):
        lines.append(f"| {br} | {ct} |")

    lines += ["", "## Proposals", "",
              "| person_id | name | fs_id | proposed branch | source | path |",
              "|---|---|---|---|---|---|"]
    for p in sorted(proposals, key=lambda x: (x["source"], x["person_id"])):
        path_str = " → ".join(p["path_names"][:6])
        if len(p["path_names"]) > 6:
            path_str += " → …"
        lines.append(
            f"| `{p['person_id']}` | {p['primary_name']} | "
            f"`{p['fs_id'] or ''}` | {p['proposed_branch'] or '*UNKNOWN*'} | "
            f"`{p['source']}` | {path_str} |"
        )

    if ambiguous:
        lines += ["", "## Ambiguous FS couples (surname matched > 1 candidate)", ""]
        for a in ambiguous:
            lines.append(
                f"- couple `{a['coupleId']}` gen {a['gen']} — "
                f"parents {a['parents']}, candidates {a['candidates']}, picked `{a['picked']}`"
            )

    md_path.write_text("\n".join(lines))
    print(f"Wrote {md_path}")
    print(f"Wrote {json_path}")
    print(f"NULL-branch People processed: {len(null_branch)}")
    print(f"  with proposed branch: {sum(1 for p in proposals if p['proposed_branch'])}")
    print(f"  unknown:              {sum(1 for p in proposals if not p['proposed_branch'])}")
    print("  by source:", dict(by_source))

    if not args.apply:
        print("\n(dry-run) pass --apply to commit.")
        conn.close()
        return 0

    backup = GPKG.with_suffix(".gpkg.pre-branch.bak")
    shutil.copy2(GPKG, backup)
    print(f"\nBacked up GPKG to {backup}")

    # Drop People triggers (no geom on People, but trigger-handling is safe)
    cur = conn.cursor()
    cur.execute("BEGIN")
    n = 0
    for p in proposals:
        if not p["proposed_branch"]:
            continue
        cur.execute(
            "UPDATE People SET branch = ? WHERE person_id = ?",
            (p["proposed_branch"], p["person_id"]),
        )
        n += 1
    conn.commit()
    conn.close()

    print(f"\n== APPLIED ==")
    print(f"  branches updated: {n}")
    print("\nNext: run cleanup_model.py to rebuild derived layers, then validate_gpkg.py.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
