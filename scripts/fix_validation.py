#!/usr/bin/env python3
"""Apply safe data-quality fixes to lrgdm.gpkg.

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
import sqlite3
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GPKG = REPO / "src/data/lrgdm.gpkg"

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


def plan(conn: sqlite3.Connection) -> dict:
    """Return a dict describing what would change, without writing."""
    out: dict = {}

    # ---- 1. duplicate Places ----
    dup_groups = list(conn.execute(
        "SELECT place_id, COUNT(*) FROM Places "
        "GROUP BY place_id HAVING COUNT(*) > 1"
    ))
    keep_fids: dict[str, int] = {}
    drop_fids: list[int] = []
    for pid, _ in dup_groups:
        fids = [r[0] for r in conn.execute(
            "SELECT fid FROM Places WHERE place_id=? ORDER BY fid", (pid,)
        )]
        keep_fids[pid] = fids[0]
        drop_fids.extend(fids[1:])
    out["places_dedupe"] = {
        "duplicate_place_ids": len(dup_groups),
        "rows_to_drop": len(drop_fids),
        "keep_fids_sample": dict(list(keep_fids.items())[:5]),
    }

    # ---- 2. geocode_quality backfill ----
    quality_updates: list[tuple[str, str, int]] = []
    for fid, place_id, name, gq in conn.execute(
        "SELECT fid, place_id, name, geocode_quality FROM Places "
        "WHERE geocode_quality IS NULL OR TRIM(geocode_quality) = ''"
    ):
        # Skip rows we're about to drop
        if fid in drop_fids:
            continue
        quality_updates.append((place_id, infer_quality(name), fid))
    out["geocode_quality_updates"] = {
        "count": len(quality_updates),
        "sample": [
            (pid, q, fid)
            for (pid, q, fid) in quality_updates[:8]
        ],
    }

    # ---- 3. branch backfill ----
    branch_updates = [
        (r[0], r[1]) for r in conn.execute(
            "SELECT person_id, primary_name FROM People "
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
            "SELECT person_id, primary_name FROM People WHERE branch = 'NULL'"
        )
    ]
    out["null_string_branch"] = {"count": len(nullstr), "rows": nullstr}

    # ---- 5. broken Event place_id refs ----
    place_ids = {r[0] for r in conn.execute("SELECT DISTINCT place_id FROM Places")}
    broken_events = [
        dict(zip(("event_id", "title", "event_type", "place_id", "notes"), r))
        for r in conn.execute(
            "SELECT event_id, title, event_type, place_id, notes "
            "FROM Events WHERE place_id IS NOT NULL AND place_id != ''"
        )
        if r[3] not in place_ids
    ]
    out["broken_event_place_ids"] = {
        "count": len(broken_events),
        "missing_pids": sorted({e["place_id"] for e in broken_events}),
        "sample": broken_events[:5],
    }

    return out, drop_fids, quality_updates, broken_events


def _capture_and_drop_triggers(cur: sqlite3.Cursor, tables: list[str]) -> list[tuple[str, str]]:
    """Snapshot trigger definitions for given tables, drop them, and return the
    captured (name, sql) pairs so the caller can recreate them after writes."""
    captured: list[tuple[str, str]] = []
    for tbl in tables:
        for name, sql in cur.execute(
            "SELECT name, sql FROM sqlite_master WHERE type='trigger' AND tbl_name=?",
            (tbl,),
        ):
            captured.append((name, sql))
    for name, _ in captured:
        cur.execute(f'DROP TRIGGER IF EXISTS "{name}"')
    return captured


def _recreate_triggers(cur: sqlite3.Cursor, captured: list[tuple[str, str]]) -> None:
    for name, sql in captured:
        cur.execute(sql)


def apply_fixes(
    conn: sqlite3.Connection,
    drop_fids: list[int],
    quality_updates: list[tuple[str, str, int]],
    broken_events: list[dict],
) -> dict:
    cur = conn.cursor()

    # The GeoPackage rtree triggers call ST_IsEmpty(), which plain Python
    # sqlite3 doesn't expose. We're only modifying non-geometry columns and
    # deleting whole rows — the rtree stays correct as long as we don't touch
    # geom. So snapshot the triggers, drop them around the writes, then
    # recreate them. Also drop the feature_count triggers and patch
    # gpkg_ogr_contents manually after the deletes.
    saved = _capture_and_drop_triggers(cur, ["Places", "Events"])

    # 1. Dedupe Places
    if drop_fids:
        cur.executemany(
            "DELETE FROM Places WHERE fid = ?",
            [(fid,) for fid in drop_fids],
        )
        # Patch gpkg_ogr_contents feature_count for Places
        new_count = cur.execute("SELECT COUNT(*) FROM Places").fetchone()[0]
        cur.execute(
            "UPDATE gpkg_ogr_contents SET feature_count = ? WHERE table_name = 'Places'",
            (new_count,),
        )
        # Clean rtree entries for deleted fids (rtree triggers were dropped)
        cur.executemany(
            "DELETE FROM rtree_Places_geom WHERE id = ?",
            [(fid,) for fid in drop_fids],
        )

    # 2. geocode_quality
    for place_id, quality, fid in quality_updates:
        cur.execute(
            "UPDATE Places SET geocode_quality = ? WHERE fid = ?",
            (quality, fid),
        )

    # 3. branch backfill
    cur.executemany(
        "UPDATE People SET branch = 'Paternal Reed' WHERE person_id = ?",
        [(pid,) for pid in PATERNAL_REED_BACKFILL],
    )

    # 4. Normalize "NULL" string
    cur.execute("UPDATE People SET branch = NULL WHERE branch = 'NULL'")

    # 5. NULL broken event place_ids, capture in notes
    for ev in broken_events:
        original = ev["place_id"]
        old_notes = (ev["notes"] or "").strip()
        marker = f"[fixup 2026-05-26] place_id was `{original}` (no matching Places row)"
        new_notes = f"{old_notes}\n{marker}".strip() if old_notes else marker
        cur.execute(
            "UPDATE Events SET place_id = NULL, notes = ? WHERE event_id = ?",
            (new_notes, ev["event_id"]),
        )

    _recreate_triggers(cur, saved)
    conn.commit()
    return {
        "places_dropped": len(drop_fids),
        "geocode_quality_set": len(quality_updates),
        "branch_backfilled": len(PATERNAL_REED_BACKFILL),
        "broken_events_nulled": len(broken_events),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    if not GPKG.exists():
        print(f"GPKG not found: {GPKG}", file=sys.stderr)
        return 1

    conn = sqlite3.connect(GPKG)
    pln, drop_fids, quality_updates, broken_events = plan(conn)

    print("== PLAN ==")
    print(f"Places to dedupe        : {pln['places_dedupe']['rows_to_drop']} rows across "
          f"{pln['places_dedupe']['duplicate_place_ids']} place_ids")
    print(f"geocode_quality updates : {pln['geocode_quality_updates']['count']}")
    for pid, q, fid in pln["geocode_quality_updates"]["sample"]:
        print(f"   {pid:>10}  fid={fid}  -> {q}")
    print(f"branch backfill         : {pln['branch_backfill']['count']} (all -> 'Paternal Reed')")
    if pln["branch_backfill"]["unhandled_unbranched_people"]:
        print("   STILL UNBRANCHED after this run:")
        for pid, name in pln["branch_backfill"]["unhandled_unbranched_people"]:
            print(f"     {pid}: {name}")
    print(f"'NULL' string -> NULL   : {pln['null_string_branch']['count']}")
    for pid, name in pln["null_string_branch"]["rows"]:
        print(f"   {pid}: {name}")
    print(f"broken Event FKs to NULL: {pln['broken_event_place_ids']['count']}")
    print(f"   missing place_ids: {pln['broken_event_place_ids']['missing_pids']}")

    if not args.apply:
        print("\n(dry-run) pass --apply to commit.")
        conn.close()
        return 0

    summary = apply_fixes(conn, drop_fids, quality_updates, broken_events)
    conn.close()
    print("\n== APPLIED ==")
    for k, v in summary.items():
        print(f"  {k}: {v}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
