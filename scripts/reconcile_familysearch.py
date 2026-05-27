#!/usr/bin/env python3
"""Match GPKG People rows against a FamilySearch extract and propose fs_id values.

Input:  src/data/familysearch/extract_<PROBAND>_<DATE>.json
        src/data/lrgdm_v2.gpkg
Output: reports/fs_reconciliation_<DATE>.md   (human-reviewable)
        reports/fs_reconciliation_<DATE>.json (machine-applyable, includes
                                               proposed UPDATE statements)

No DB writes. Review the markdown, then run apply_familysearch_matches.py
to commit accepted matches.
"""
from __future__ import annotations

import argparse
import json
import re
import sqlite3
import sys
import unicodedata
from dataclasses import dataclass
from datetime import date
from difflib import SequenceMatcher
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]


def normalize_name(raw: str | None) -> str:
    if not raw:
        return ""
    s = unicodedata.normalize("NFKD", raw).encode("ascii", "ignore").decode()
    s = s.lower()
    s = re.sub(r"\(.*?\)", " ", s)        # drop maiden-name parentheticals
    s = re.sub(r"[^a-z\s]", " ", s)
    return " ".join(s.split())


def name_tokens(n: str) -> set[str]:
    return set(normalize_name(n).split())


def parse_year(date_str: str | None) -> int | None:
    if not date_str:
        return None
    m = re.search(r"(1[5-9]\d{2}|20\d{2})", date_str)
    return int(m.group(1)) if m else None


def name_similarity(a: str, b: str) -> float:
    na, nb = normalize_name(a), normalize_name(b)
    if not na or not nb:
        return 0.0
    base = SequenceMatcher(None, na, nb).ratio()
    ta, tb = name_tokens(a), name_tokens(b)
    if ta and tb:
        jaccard = len(ta & tb) / len(ta | tb)
        return max(base, jaccard)
    return base


@dataclass
class FsPerson:
    pid: str
    name: str
    gender: str | None
    lifespan: str | None
    birth_year: int | None
    death_year: int | None
    birth_place: str | None
    death_place: str | None


def load_fs(path: Path) -> list[FsPerson]:
    payload = json.loads(path.read_text())
    out = []
    for p in payload.get("people", []):
        birth = p.get("birth") or {}
        death = p.get("death") or {}
        out.append(
            FsPerson(
                pid=p["pid"],
                name=p["name"],
                gender=p.get("gender"),
                lifespan=p.get("lifespan"),
                birth_year=parse_year(birth.get("date")),
                death_year=parse_year(death.get("date")),
                birth_place=birth.get("place"),
                death_place=death.get("place"),
            )
        )
    return out


def score_match(person_row: dict, fs: FsPerson) -> tuple[float, str]:
    """Return (score 0-1, reason)."""
    name_score = name_similarity(person_row["primary_name"], fs.name)

    gpkg_birth_year = parse_year(person_row.get("birth_date"))
    gpkg_death_year = parse_year(person_row.get("death_date"))

    date_score = 0.5
    date_reasons = []
    if gpkg_birth_year and fs.birth_year:
        diff = abs(gpkg_birth_year - fs.birth_year)
        if diff == 0:
            date_score = 1.0
            date_reasons.append(f"birth year exact ({gpkg_birth_year})")
        elif diff <= 2:
            date_score = 0.85
            date_reasons.append(f"birth year ±{diff} ({gpkg_birth_year} vs {fs.birth_year})")
        elif diff <= 5:
            date_score = 0.6
            date_reasons.append(f"birth year ±{diff} ({gpkg_birth_year} vs {fs.birth_year})")
        else:
            date_score = 0.2
            date_reasons.append(f"birth year mismatch ({gpkg_birth_year} vs {fs.birth_year})")
    elif gpkg_death_year and fs.death_year:
        diff = abs(gpkg_death_year - fs.death_year)
        if diff == 0:
            date_score = 0.95
            date_reasons.append(f"death year exact ({gpkg_death_year})")
        elif diff <= 2:
            date_score = 0.8
            date_reasons.append(f"death year ±{diff}")

    score = 0.6 * name_score + 0.4 * date_score
    reason = f"name sim {name_score:.2f}"
    if date_reasons:
        reason += "; " + "; ".join(date_reasons)
    return score, reason


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--extract",
        type=Path,
        default=REPO / "src/data/familysearch" / max(
            (p.name for p in (REPO / "src/data/familysearch").glob("extract_*.json")),
            default="",
        ),
    )
    ap.add_argument("--gpkg", type=Path, default=REPO / "src/data/lrgdm_v2.gpkg")
    ap.add_argument("--out-dir", type=Path, default=REPO / "reports")
    ap.add_argument("--min-score", type=float, default=0.55)
    args = ap.parse_args()

    if not args.extract.exists():
        print(f"extract not found: {args.extract}", file=sys.stderr)
        return 1

    fs_people = load_fs(args.extract)
    fs_by_pid = {p.pid: p for p in fs_people}

    conn = sqlite3.connect(args.gpkg)
    conn.row_factory = sqlite3.Row
    unlinked = [
        dict(r) for r in conn.execute(
            "SELECT person_id, primary_name, sex, birth_date, death_date, branch, fs_id "
            "FROM People WHERE fs_id IS NULL OR fs_id = ''"
        )
    ]
    already_linked_pids = {
        r["fs_id"] for r in conn.execute(
            "SELECT fs_id FROM People WHERE fs_id IS NOT NULL AND fs_id != ''"
        )
    }
    conn.close()

    results = []
    for row in unlinked:
        scored = []
        for fs in fs_people:
            if fs.pid in already_linked_pids:
                continue
            s, why = score_match(row, fs)
            if s >= args.min_score:
                scored.append((s, why, fs))
        scored.sort(reverse=True, key=lambda x: x[0])
        results.append({
            "person_id": row["person_id"],
            "primary_name": row["primary_name"],
            "birth_date": row["birth_date"],
            "death_date": row["death_date"],
            "branch": row["branch"],
            "candidates": [
                {
                    "fs_pid": fs.pid,
                    "fs_name": fs.name,
                    "fs_birth_year": fs.birth_year,
                    "fs_death_year": fs.death_year,
                    "fs_birth_place": fs.birth_place,
                    "score": round(s, 3),
                    "reason": why,
                }
                for (s, why, fs) in scored[:3]
            ],
        })

    today = date.today().isoformat()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    json_path = args.out_dir / f"fs_reconciliation_{today}.json"
    md_path = args.out_dir / f"fs_reconciliation_{today}.md"

    json_path.write_text(json.dumps({
        "generated": today,
        "extract": str(args.extract.relative_to(REPO)),
        "gpkg": str(args.gpkg.relative_to(REPO)),
        "min_score": args.min_score,
        "already_linked_count": len(already_linked_pids),
        "unlinked_count": len(unlinked),
        "results": results,
    }, indent=2))

    lines = [
        f"# FamilySearch Reconciliation — {today}",
        "",
        f"- Extract: `{args.extract.relative_to(REPO)}`",
        f"- GPKG: `{args.gpkg.relative_to(REPO)}`",
        f"- Already linked in GPKG: **{len(already_linked_pids)}** People rows",
        f"- Unlinked People rows reviewed: **{len(unlinked)}**",
        f"- Minimum match score: {args.min_score}",
        "",
        "Each block lists up to 3 candidate FS persons per unlinked GPKG row, sorted by score.",
        "Score is `0.6 * name_similarity + 0.4 * date_proximity` on a 0-1 scale.",
        "",
        "## Proposals",
        "",
    ]
    for r in results:
        lines.append(f"### {r['person_id']} — {r['primary_name']}")
        lines.append(f"GPKG birth: `{r['birth_date']}`  •  death: `{r['death_date']}`  •  branch: `{r['branch']}`")
        lines.append("")
        if not r["candidates"]:
            lines.append("_No candidates above threshold._")
            lines.append("")
            continue
        lines.append("| score | FS PID | FS name | birth | death | reason |")
        lines.append("|---|---|---|---|---|---|")
        for c in r["candidates"]:
            lines.append(
                f"| {c['score']} | `{c['fs_pid']}` | {c['fs_name']} | "
                f"{c['fs_birth_year'] or ''} | {c['fs_death_year'] or ''} | {c['reason']} |"
            )
        lines.append("")
    md_path.write_text("\n".join(lines))

    print(f"Wrote {md_path}")
    print(f"Wrote {json_path}")
    print(f"Reviewed {len(unlinked)} unlinked People rows; {sum(1 for r in results if r['candidates'])} had at least one candidate.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
