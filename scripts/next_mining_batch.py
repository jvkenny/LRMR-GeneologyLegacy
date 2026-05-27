#!/usr/bin/env python3
"""Pick the next batch of People to mine for obituary/news/census mentions.

Selection logic:
- Deceased only (don't mine living people)
- Has a clear birth or death year (we need a date anchor for searches)
- Hasn't been mined recently (no file in reports/web_mentions/<person_id>.md
  modified within the last MIN_DAYS_BETWEEN_MINES days)
- Higher priority for: more sources already on record (means we have something to
  reconcile against), older death dates (likely public-domain obits available)

Output: JSON to stdout with the batch (default 5 people).
"""
from __future__ import annotations

import argparse
import json
import re
import sqlite3
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MENTIONS_DIR = REPO / "reports" / "web_mentions"
MIN_DAYS_BETWEEN_MINES = 30


def parse_year(s: str | None) -> int | None:
    if not s:
        return None
    m = re.search(r"(1[5-9]\d{2}|20\d{2})", s)
    return int(m.group(1)) if m else None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--gpkg", type=Path, default=REPO / "src/data/lrgdm.gpkg")
    ap.add_argument("--batch-size", type=int, default=5)
    args = ap.parse_args()

    if not args.gpkg.exists():
        print(json.dumps({"error": f"GPKG not found: {args.gpkg}"}), file=sys.stderr)
        return 1

    MENTIONS_DIR.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(args.gpkg)
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT person_id, primary_name, sex, birth_date, death_date, branch, "
        "       birth_place_id, death_place_id, fs_id, source_summary, notes "
        "FROM People WHERE birth_date IS NOT NULL OR death_date IS NOT NULL"
    ).fetchall()

    # Hydrate place names
    places = {p["place_id"]: p["name"] for p in conn.execute("SELECT place_id, name FROM Places")}
    conn.close()

    cutoff = date.today() - timedelta(days=MIN_DAYS_BETWEEN_MINES)
    candidates = []
    for r in rows:
        d = dict(r)
        by, dy = parse_year(d["birth_date"]), parse_year(d["death_date"])
        if by is None and dy is None:
            continue
        # Skip apparently-living (no death_date AND birth recent)
        if not d["death_date"] and by and by > date.today().year - 90:
            continue
        mention_file = MENTIONS_DIR / f"{d['person_id']}.md"
        if mention_file.exists():
            mtime = datetime.fromtimestamp(mention_file.stat().st_mtime).date()
            if mtime > cutoff:
                continue
            last_mined = mtime.isoformat()
        else:
            last_mined = None
        d["birth_place_name"] = places.get(d["birth_place_id"])
        d["death_place_name"] = places.get(d["death_place_id"])
        d["birth_year"] = by
        d["death_year"] = dy
        d["last_mined"] = last_mined
        candidates.append(d)

    # Priority: never-mined first, then oldest death year, then most sources
    candidates.sort(
        key=lambda c: (
            c["last_mined"] is not None,  # never-mined first
            c["last_mined"] or "",        # then oldest re-mine
            -(c["death_year"] or c["birth_year"] or 0),  # oldest first
        ),
    )

    batch = candidates[: args.batch_size]
    print(json.dumps({
        "generated": date.today().isoformat(),
        "batch_size": len(batch),
        "total_eligible": len(candidates),
        "people": [
            {
                "person_id": p["person_id"],
                "primary_name": p["primary_name"],
                "sex": p["sex"],
                "birth_date": p["birth_date"],
                "death_date": p["death_date"],
                "birth_place_name": p["birth_place_name"],
                "death_place_name": p["death_place_name"],
                "branch": p["branch"],
                "fs_id": p["fs_id"],
                "source_summary": p["source_summary"],
                "last_mined": p["last_mined"],
            }
            for p in batch
        ],
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
