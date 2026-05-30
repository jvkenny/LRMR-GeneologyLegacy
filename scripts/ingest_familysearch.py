#!/usr/bin/env python3
"""Ingest missing ancestors from a FamilySearch extract into the LRGDM GPKG.

Reads the newest src/data/familysearch/extract_*.json and adds People rows for
every FS person whose `pid` doesn't already appear as a `fs_id` in the GPKG.
Also adds new Places rows for any birth/death place that doesn't canonicalize
to an existing Places.name.

Two-step protocol:
  --dry-run (default) writes reports/ingest_proposal_<DATE>.{md,json}
  --apply              writes the GPKG (and regenerates derived layers)

Branch is set via a surname-based heuristic (see SURNAME_BRANCH_MAP). Anyone
whose surname doesn't match falls through with branch=NULL — surfaced in the
proposal for the user to assign.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from datetime import date
from pathlib import Path

from lrgdm_db import connect

REPO = Path(__file__).resolve().parents[1]
EXTRACT_DIR = REPO / "src/data/familysearch"

# Surname -> branch. Matches existing GPKG conventions (which are inconsistent
# but at least internally coherent — "Paternal Reed" is used as the label for
# the Reed-family lineage even though that lineage is on John's maternal side).
# When the FS surname matches multiple branches (e.g., multiple "Reed"s
# spanning different family threads), the first key wins.
SURNAME_BRANCH_MAP = {
    # Paternal Reed lineage (the Reed surname family, descends through Karen Reed)
    "Reed": "Paternal Reed",
    "Talley": "Paternal Reed",
    "Willey": "Paternal Reed",
    "Thorla": "Paternal Reed",
    "Thorley": "Paternal Reed",
    "Dickerson": "Paternal Reed",
    "Cook": "Paternal Reed",
    "Bonham": "Paternal Reed",
    "Paulson": "Paternal Reed",
    "Paulsen": "Paternal Reed",
    "Poulson": "Paternal Reed",
    "Barnard": "Paternal Reed",
    "Dye": "Paternal Reed",
    "Allen": "Paternal Reed",
    "Lemley": "Paternal Reed",
    # Paternal Kenny lineage (Edward Kenny + ancestors)
    "Kenny": "Paternal Kenny",
    # Paternal Kroll lineage (Phyllis Kroll + ancestors)
    "Kroll": "Paternal Kroll",
    # Maternal Mariotti lineage (Leah Rae Mariotti + ancestors)
    "Mariotti": "Maternal Mariotti",
    # Maternal Lambert lineage (existing convention)
    "Lambert": "Maternal Lambert",
    # Pouliot (existing convention)
    "Pouliot": "Pouliot",
    # Zika side (Earl Reed Sr's wife Isabelle Zika's lineage)
    "Zika": "Zika",
    "Zíka": "Zika",
    # Italian surnames — Mariotti lineage (Leah Rae Mariotti's ancestors)
    "Mariotti": "Maternal Mariotti",
    "Niccolai": "Maternal Mariotti",
    "Porciani": "Maternal Mariotti",
    "Dini": "Maternal Mariotti",
    "Pagni": "Maternal Mariotti",
    "Spadoni": "Maternal Mariotti",
    "Giorgi": "Maternal Mariotti",
    "Lenzi": "Maternal Mariotti",
    "Bartoletti": "Maternal Mariotti",
    "Marchi": "Maternal Mariotti",
    "Lapini": "Maternal Mariotti",
    "NICCOLAI": "Maternal Mariotti",
    "PORCIANI": "Maternal Mariotti",
}

PROBAND_PID = "L274-KNT"
# Skip these — they're the proband and his spouse, not ancestors.
# Also any other PIDs known to be in-laws of John (not blood ancestors).
SKIP_PIDS = {
    "L274-KNT",  # John (proband)
    "PQCN-4WD",  # Celine (spouse)
}


def normalize_place(name: str | None) -> str:
    if not name:
        return ""
    s = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode().lower()
    s = re.sub(r"\b(united states|usa|u\.s\.|u\.s\.a\.)\b", "usa", s)
    s = re.sub(r"\s+", " ", s)
    s = re.sub(r"\s*,\s*", ", ", s)
    return s.strip()


def surname(name: str | None) -> str:
    """Best-effort surname extraction from primary_name."""
    if not name:
        return ""
    n = name.replace(" Sr", "").replace(" Jr", "").replace(" III", "").replace(" II", "").strip()
    # Drop trailing parentheticals
    n = re.sub(r"\([^)]*\)", "", n).strip()
    parts = n.split()
    return parts[-1] if parts else ""


def infer_branch(name: str | None) -> str | None:
    s = surname(name)
    return SURNAME_BRANCH_MAP.get(s)




def infer_place_quality(name: str) -> str:
    if not name:
        return "unknown"
    head = name.split(",", 1)[0].strip()
    if re.match(r"^\d+\s+[NSEW]?\s*[A-Za-z]", head):
        return "address"
    if re.search(r"cemetery", head, re.I):
        return "cemetery"
    if re.search(r"\bward\s+\d+", head, re.I):
        return "ward"
    if re.search(r"\btownship\b", head, re.I):
        return "township"
    if re.search(r"\bhundred\b$", head, re.I):
        return "township"
    if re.search(r"\bcounty\b", head, re.I):
        return "county"
    commas = name.count(",")
    if commas == 0:
        return "region"
    if commas >= 1:
        return "settlement"
    return "unknown"


def next_id(conn: sqlite3.Connection, table: str, col: str, prefix: str, width: int = 4) -> int:
    rows = list(conn.execute(f"SELECT {col} AS v FROM {table} WHERE {col} LIKE %s", (f"{prefix}%",)))
    nums = []
    for r in rows:
        m = re.match(rf"{re.escape(prefix)}(\d+)$", r["v"] or "")
        if m:
            nums.append(int(m.group(1)))
    return (max(nums) + 1) if nums else 1


def fmt_id(prefix: str, n: int, width: int = 4) -> str:
    return f"{prefix}{n:0{width}d}"


def _capture_and_drop_triggers(cur: sqlite3.Cursor, tables: list[str]) -> list[tuple[str, str]]:
    captured = []
    for t in tables:
        for n, s in cur.execute(
            "SELECT name, sql FROM sqlite_master WHERE type='trigger' AND tbl_name=?", (t,),
        ):
            captured.append((n, s))
    for n, _ in captured:
        cur.execute(f'DROP TRIGGER IF EXISTS "{n}"')
    return captured


def _recreate(cur, captured):
    for _, sql in captured:
        if sql:
            cur.execute(sql)


def load_extract() -> dict:
    candidates = sorted(EXTRACT_DIR.glob("extract_*.json"))
    if not candidates:
        sys.exit(f"No FS extract found in {EXTRACT_DIR}")
    return json.loads(candidates[-1].read_text())


def parse_year(s: str | None) -> int | None:
    if not s:
        return None
    m = re.search(r"(1[5-9]\d{2}|20\d{2})", s)
    return int(m.group(1)) if m else None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--include-living", action="store_true",
                    help="also ingest living people (default: skip; privacy)")
    args = ap.parse_args()

    extract = load_extract()
    conn = connect()

    # Existing identity
    existing_fs = {
        r["fs_id"] for r in conn.execute(
            "SELECT fs_id FROM person WHERE fs_id IS NOT NULL AND fs_id != ''"
        )
    }
    existing_places = {
        normalize_place(r["name"]): r["place_id"]
        for r in conn.execute("SELECT place_id, name FROM place")
        if r["name"]
    }

    next_p = next_id(conn, "person", "person_id", "P-")
    next_pl = next_id(conn, "place", "place_id", "PL-")

    # Plan ingest
    plan_people: list[dict] = []
    plan_places: dict[str, dict] = {}      # keyed by normalized name; values include place_id
    skipped: list[dict] = []
    branch_unknown: list[dict] = []

    for fs in extract["people"]:
        pid = fs["pid"]
        if pid in SKIP_PIDS:
            skipped.append({"pid": pid, "name": fs["name"], "reason": "proband or spouse"})
            continue
        if pid in existing_fs:
            skipped.append({"pid": pid, "name": fs["name"], "reason": "already linked via fs_id"})
            continue
        if fs.get("living") and not args.include_living:
            skipped.append({"pid": pid, "name": fs["name"], "reason": "living (privacy)"})
            continue

        # Place handling: birth + death (skip burial for now)
        def resolve_place(ev: dict | None, plan_places: dict) -> str | None:
            if not ev or not ev.get("place"):
                return None
            norm = normalize_place(ev["place"])
            if norm in existing_places:
                return existing_places[norm]
            if norm in plan_places:
                return plan_places[norm]["place_id"]
            # Only create if we have coordinates
            if ev.get("lat") is None or ev.get("lon") is None:
                return None
            new_pid = fmt_id("PL-", _next_pl[0])
            _next_pl[0] += 1
            plan_places[norm] = {
                "place_id": new_pid,
                "name": ev["place"],
                "lat": ev["lat"],
                "lon": ev["lon"],
            }
            return new_pid

        _next_pl = [next_pl + len(plan_places)]
        birth_place = resolve_place(fs.get("birth"), plan_places)
        death_place = resolve_place(fs.get("death"), plan_places)
        next_pl = _next_pl[0]

        branch = infer_branch(fs["name"])
        sex = (fs.get("gender") or "").lower() or None
        if sex == "male":
            sex_val = "male"
        elif sex == "female":
            sex_val = "female"
        else:
            sex_val = None

        new_person_id = fmt_id("P-", next_p + len(plan_people))
        row = {
            "person_id": new_person_id,
            "fs_pid": pid,
            "primary_name": fs["name"],
            "sex": sex_val,
            "birth_date": (fs.get("birth") or {}).get("date"),
            "birth_place_id": birth_place,
            "death_date": (fs.get("death") or {}).get("date"),
            "death_place_id": death_place,
            "life_confidence": "high" if (fs.get("sourceCount") or 0) > 0 else "med",
            "privacy_level": "private" if fs.get("living") else "public",
            "branch": branch,
            "notes": f"Imported from FamilySearch extract on {date.today().isoformat()}.",
            "source_summary": f"FamilySearch (FS PID: {pid})",
            "fs_id": pid,
        }
        plan_people.append(row)
        if branch is None:
            branch_unknown.append({"person_id": new_person_id, "name": fs["name"], "surname": surname(fs["name"])})

    # ---- write proposal ----
    today = date.today().isoformat()
    reports_dir = REPO / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)
    json_out = reports_dir / f"ingest_proposal_{today}.json"
    md_out = reports_dir / f"ingest_proposal_{today}.md"

    json_out.write_text(json.dumps({
        "generated": today,
        "extract": str(sorted(EXTRACT_DIR.glob("extract_*.json"))[-1].relative_to(REPO)),
        "include_living": args.include_living,
        "to_ingest_people": len(plan_people),
        "to_ingest_places": len(plan_places),
        "skipped": skipped,
        "people": plan_people,
        "places": list(plan_places.values()),
        "branch_unknown": branch_unknown,
    }, indent=2))

    lines = [
        f"# FS Ingest Proposal — {today}",
        "",
        f"- To-ingest People: **{len(plan_people)}**",
        f"- To-create Places: **{len(plan_places)}**",
        f"- People with `branch=NULL` after heuristic (need manual assignment): **{len(branch_unknown)}**",
        f"- Skipped: **{len(skipped)}** (proband/spouse, already-linked via fs_id, or living)",
        "",
        "## Branch heuristic",
        "",
        "Surname → branch mapping is in `scripts/ingest_familysearch.py`. Mapped surnames:",
        ", ".join(f"`{s}` → `{b}`" for s, b in SURNAME_BRANCH_MAP.items()),
        "",
        "## New People",
        "",
        "| new id | name | sex | birth | death | branch | fs_id |",
        "|---|---|---|---|---|---|---|",
    ]
    for p in plan_people:
        lines.append(
            f"| `{p['person_id']}` | {p['primary_name']} | {p['sex'] or ''} | "
            f"{p['birth_date'] or ''} | {p['death_date'] or ''} | "
            f"{p['branch'] or '*NULL — review*'} | `{p['fs_pid']}` |"
        )

    if branch_unknown:
        lines += ["", "## People needing branch assignment", ""]
        for r in branch_unknown:
            lines.append(f"- `{r['person_id']}` {r['name']} (surname `{r['surname']}`)")

    if plan_places:
        lines += ["", "## New Places", "", "| new id | name | lat | long | quality |", "|---|---|---|---|---|"]
        for pl in plan_places.values():
            q = infer_place_quality(pl["name"])
            lines.append(f"| `{pl['place_id']}` | {pl['name']} | {pl['lat']} | {pl['lon']} | {q} |")

    lines += ["", "## Skipped", ""]
    for s in skipped[:30]:
        lines.append(f"- `{s['pid']}` {s['name']} — {s['reason']}")
    if len(skipped) > 30:
        lines.append(f"- _... and {len(skipped) - 30} more_")

    md_out.write_text("\n".join(lines))

    print(f"Wrote {md_out}")
    print(f"Wrote {json_out}")
    print(f"To ingest: {len(plan_people)} People, {len(plan_places)} Places")
    print(f"Skipped:   {len(skipped)}")
    print(f"Branch unknown (will be NULL): {len(branch_unknown)}")

    if not args.apply:
        print("\n(dry-run) pass --apply to write to the GPKG.")
        conn.close()
        return 0

    # ---- apply ----
    cur = conn.cursor()

    # Places first (so person FKs resolve); geom built via PostGIS.
    for pl in plan_places.values():
        q = infer_place_quality(pl["name"])
        cur.execute(
            "INSERT INTO place (place_id, name, std_name, geom, geocode_quality, notes) "
            "VALUES (%s, %s, %s, ST_SetSRID(ST_MakePoint(%s, %s), 4326), %s, %s)",
            (pl["place_id"], pl["name"], pl["name"], float(pl["lon"]), float(pl["lat"]),
             q, f"Imported from FS extract {today}"),
        )

    # People
    for p in plan_people:
        cur.execute(
            "INSERT INTO person (person_id, primary_name, sex, birth_date, birth_place_id, "
            " death_date, death_place_id, life_confidence, privacy_level, branch, notes, "
            " source_summary, fs_id) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            (p["person_id"], p["primary_name"], p["sex"], p["birth_date"], p["birth_place_id"],
             p["death_date"], p["death_place_id"], p["life_confidence"], p["privacy_level"],
             p["branch"], p["notes"], p["source_summary"], p["fs_id"]),
        )

    conn.commit()
    conn.close()

    # Derived map layers are live views — no rebuild step.
    print("\nDone. Inserted:")
    print(f"  People: {len(plan_people)}")
    print(f"  Places: {len(plan_places)}")
    print(f"\nRun `python3 scripts/validate_gpkg.py` to confirm.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
