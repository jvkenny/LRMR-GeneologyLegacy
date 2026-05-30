#!/usr/bin/env python3
"""Apply safe data-quality fixes to the Postgres `lrgdm` database.

Default mode is --dry-run (print what WOULD change). Pass --apply to commit.

What it fixes (in order, single transaction when --apply):
  1. Places: collapse duplicate place_id rows to one (keeps lowest fid).
  2. Places: set geocode_quality by inferring from name pattern when missing.
  3. People: backfill branch='Paternal Reed' for the 15 unbranched paternal-
     line ancestors (P-0038..P-0052).
  4. People: normalize the literal string "NULL" in branch to real NULL.
  5. Events: NULL out place_id references that point to nonexistent Places;
     append the original ID to Events.notes so the user can repair later.

It does NOT do (these need human judgment):
  - Merge duplicate persons (Benjamin Reed P-0005/P-0040, Sarah Dickerson
    P-0006/P-0041). See --dump-duplicate-persons for context.
  - Delete orphan Places (10 rows).
"""
from __future__ import annotations

import argparse
import re
from psycopg.rows import tuple_row

from lrgdm_db import connect

# ---- geocode_quality inference --------------------------------------------
# Tag the place by its MOST-SPECIFIC token (the first comma-separated part).
# "Chicago, Cook County, IL" → "settlement" (Chicago), not "county" (Cook).
HEAD_PATTERNS: list[tuple[re.Pattern, str]] = [
    (re.compile(r"^\d+\s+[NSEW]?\s*[A-Za-z]"), "address"),         # 1048 Alameda Dr
    (re.compile(r"cemetery", re.I), "cemetery"),
    (re.compile(r"\bchurch\b", re.I), "cemetery"),
    (re.compile(r"\bward\s+\d+", re.I), "ward"),
    (re.compile(r"\btownship\b", re.I), "township"),
    (re.compile(r"\bhundred\b$", re.I), "township"),               # historic, e.g. "Nanticoke Hundred"
    (re.compile(r"\bcounty\b", re.I), "county"),
]

# After the head check, also check the whole string for these (lowest priority).
TAIL_PATTERNS: list[tuple[re.Pattern, str]] = [
    (re.compile(r"cemetery", re.I), "cemetery"),
]


def infer_quality(name: str | None) -> str:
    if not name or not name.strip():
        return "unknown"
    n = name.strip()
    head = n.split(",", 1)[0].strip()

    for pat, tag in HEAD_PATTERNS:
        if pat.search(head):
            return tag

    # Tail patterns catch e.g. "Olive Cemetery, Caldwell, Noble, Ohio"
    for pat, tag in TAIL_PATTERNS:
        if pat.search(n):
            return tag

    commas = n.count(",")
    if commas == 0:
        return "region"        # bare "Ohio", "New York", etc.
    if commas == 1:
        # "Simsbury, Hartford" or "State, Country" — call it settlement-ish
        return "settlement"
    if 2 <= commas <= 4:
        return "settlement"
    return "unknown"


# ---- 15 unbranched paternal-line ancestors --------------------------------
PATERNAL_REED_BACKFILL = {
    "P-0038", "P-0039", "P-0040", "P-0041", "P-0042", "P-0043", "P-0044",
    "P-0045", "P-0046", "P-0047", "P-0048", "P-0049", "P-0050", "P-0051",
    "P-0052",
}


def plan(conn) -> dict:
    """Return a dict describing what would change, without writing."""
    out: dict = {}

    # ---- 1. (Place dedup is obsolete: place_id is the Postgres PK.) ----

    # ---- 2. geocode_quality backfill (keyed by place_id) ----
    quality_updates: list[tuple[str, str]] = []
    for place_id, name in conn.execute(
        "SELECT place_id, name FROM place "
        "WHERE geocode_quality IS NULL OR TRIM(geocode_quality) = ''"
    ):
        quality_updates.append((place_id, infer_quality(name)))
    out["geocode_quality_updates"] = {
        "count": len(quality_updates),
        "sample": quality_updates[:8],
    }

    # ---- 3. branch backfill ----
    branch_updates = [
        (r[0], r[1]) for r in conn.execute(
            "SELECT person_id, primary_name FROM person "
            "WHERE (branch IS NULL OR branch = '') "
        )
    ]
    backfillable = [
        (pid, name) for (pid, name) in branch_updates if pid in PATERNAL_REED_BACKFILL
    ]
    unhandled = [
        (pid, name) for (pid, name) in branch_updates if pid not in PATERNAL_REED_BACKFILL
    ]
    out["branch_backfill"] = {
        "count": len(backfillable),
        "sample": backfillable[:5],
        "unhandled_unbranched_people": unhandled,
    }

    # ---- 4. "NULL" string normalization ----
    nullstr = [
        (r[0], r[1]) for r in conn.execute(
            "SELECT person_id, primary_name FROM person WHERE branch = 'NULL'"
        )
    ]
    out["null_string_branch"] = {"count": len(nullstr), "rows": nullstr}

    # ---- 5. (Broken event place_id refs are obsolete: FKs are enforced.) ----

    return out, quality_updates


def apply_fixes(conn, quality_updates: list[tuple[str, str]]) -> dict:
    cur = conn.cursor()

    # 1. geocode_quality (keyed by place_id; no rtree/contents dance in Postgres)
    for place_id, quality in quality_updates:
        cur.execute(
            "UPDATE place SET geocode_quality = %s WHERE place_id = %s",
            (quality, place_id),
        )

    # 2. branch backfill
    for pid in PATERNAL_REED_BACKFILL:
        cur.execute(
            "UPDATE person SET branch = 'Paternal Reed' WHERE person_id = %s",
            (pid,),
        )

    # 3. Normalize "NULL" string
    cur.execute("UPDATE person SET branch = NULL WHERE branch = 'NULL'")

    conn.commit()
    return {
        "geocode_quality_set": len(quality_updates),
        "branch_backfilled": len(PATERNAL_REED_BACKFILL),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    conn = connect(row_factory=tuple_row)
    pln, quality_updates = plan(conn)

    print("== PLAN ==")
    print(f"geocode_quality updates : {pln['geocode_quality_updates']['count']}")
    for pid, q in pln["geocode_quality_updates"]["sample"]:
        print(f"   {pid:>10}  -> {q}")
    print(f"branch backfill         : {pln['branch_backfill']['count']} (all -> 'Paternal Reed')")
    if pln["branch_backfill"]["unhandled_unbranched_people"]:
        print("   STILL UNBRANCHED after this run:")
        for pid, name in pln["branch_backfill"]["unhandled_unbranched_people"]:
            print(f"     {pid}: {name}")
    print(f"'NULL' string -> NULL   : {pln['null_string_branch']['count']}")
    for pid, name in pln["null_string_branch"]["rows"]:
        print(f"   {pid}: {name}")

    if not args.apply:
        print("\n(dry-run) pass --apply to commit.")
        conn.close()
        return 0

    print("(Tip: run scripts/backup_db.sh first for a pg_dump snapshot.)")
    summary = apply_fixes(conn, quality_updates)
    conn.close()
    print("\n== APPLIED ==")
    for k, v in summary.items():
        print(f"  {k}: {v}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
