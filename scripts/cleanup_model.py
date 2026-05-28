#!/usr/bin/env python3
"""Wave 1 + schema-tightening model cleanup on lrgdm.gpkg.

Stages (in order, with --apply):
  B. Drop 4 stale tables: Birth_Points, Death_Points, Places_points,
     Places_without_People.
  C. Rebuild 6 derived layers from source tables (birth_location_points,
     death_location_points, birth_to_death_lines, birth_to_death_lines_eras,
     Person_Locations, Event_Points). They stay as tables (not views) so QGIS
     handles them natively; this script is the regenerator after any data
     change.
  D. Schema tightening on Places: lat TEXT → REAL, drop redundant PID_Person.
     Similar on People: drop PID_Places_Birth/Death (redundant with
     birth_place_id/death_place_id). On Events: drop PID_Places/PID_People
     (redundant with place_id and EventParticipants).
  E. Add UNIQUE indexes on person_id, place_id, event_id.

Use --dry-run (default) to see the plan. --apply commits.
"""
from __future__ import annotations

import argparse
import sqlite3
import sys
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GPKG = REPO / "src/data/lrgdm.gpkg"

STALE_TABLES = ["Birth_Points", "Death_Points", "Places_points", "Places_without_People"]
DERIVED_TABLES = [
    "birth_location_points",
    "death_location_points",
    "birth_to_death_lines",
    "birth_to_death_lines_eras",
    "Person_Locations",
    "Event_Points",
]


def _year_sql(col: str) -> str:
    """SQL CASE expression that extracts a 4-digit year from messy free-text
    dates. Handles ISO ("1816-06-03"), bare year ("1759"), DMY
    ("14 April 1878"), and modifier prefixes ("circa 1822", "about 1810").
    Returns NULL if no plausible year is present.
    """
    return f"""
        CASE
          WHEN {col} IS NULL OR {col} = '' THEN NULL
          WHEN substr({col}, 1, 4) GLOB '[12][0-9][0-9][0-9]'
            THEN CAST(substr({col}, 1, 4) AS INTEGER)
          WHEN length({col}) >= 4
               AND substr({col}, length({col}) - 3, 4) GLOB '[12][0-9][0-9][0-9]'
            THEN CAST(substr({col}, length({col}) - 3, 4) AS INTEGER)
          ELSE NULL
        END
    """.strip()


def _era_sql(year_expr: str) -> str:
    """SQL CASE that maps a year integer to an era name. Mirrors era_for() in
    scripts/export_geojson.py — keep the boundaries in sync."""
    return f"""
        CASE
          WHEN ({year_expr}) IS NULL THEN NULL
          WHEN ({year_expr}) < 1788 THEN 'Colonial Era'
          WHEN ({year_expr}) < 1830 THEN 'Early Republic'
          WHEN ({year_expr}) < 1865 THEN 'Civil War & Reconstruction'
          WHEN ({year_expr}) < 1900 THEN 'Gilded Age'
          WHEN ({year_expr}) < 1920 THEN 'Progressive Era & WWI'
          WHEN ({year_expr}) < 1940 THEN 'Roaring 20s & Great Depression'
          ELSE 'Modern'
        END
    """.strip()


def capture_triggers(cur: sqlite3.Cursor, table: str) -> list[tuple[str, str]]:
    return [
        (n, s) for (n, s) in cur.execute(
            "SELECT name, sql FROM sqlite_master WHERE type='trigger' AND tbl_name=?",
            (table,),
        )
    ]


def drop_triggers(cur: sqlite3.Cursor, captured: list[tuple[str, str]]) -> None:
    for name, _ in captured:
        cur.execute(f'DROP TRIGGER IF EXISTS "{name}"')


def recreate_triggers(cur: sqlite3.Cursor, captured: list[tuple[str, str]]) -> None:
    for _, sql in captured:
        if sql:
            cur.execute(sql)


def drop_gpkg_table(cur: sqlite3.Cursor, table: str) -> None:
    """Drop a GPKG feature table and clean up its metadata."""
    trigs = capture_triggers(cur, table)
    drop_triggers(cur, trigs)
    # rtree virtual table — dropping the main one cascades to its shadow
    # _node/_parent/_rowid backing tables. We swallow missing-table errors
    # because rtree only exists if the table had geometry.
    try:
        cur.execute(f'DROP TABLE IF EXISTS "rtree_{table}_geom"')
    except sqlite3.OperationalError:
        pass
    cur.execute(f'DROP TABLE IF EXISTS "{table}"')
    for meta_tbl, col in [
        ("gpkg_contents", "table_name"),
        ("gpkg_geometry_columns", "table_name"),
        ("gpkg_ogr_contents", "table_name"),
        ("gpkg_data_columns", "table_name"),
        ("gpkg_extensions", "table_name"),
        ("gpkg_metadata_reference", "table_name"),
    ]:
        try:
            cur.execute(
                f"DELETE FROM {meta_tbl} WHERE {col} = ?",
                (table,),
            )
        except sqlite3.OperationalError:
            pass  # table may not exist


def register_gpkg_feature_table(cur: sqlite3.Cursor, table: str, geom_type: str, srs_id: int = 4326) -> None:
    """Register a freshly-created table in the GPKG metadata so QGIS picks it
    up as a spatial layer."""
    cur.execute(
        "INSERT OR REPLACE INTO gpkg_contents "
        "(table_name, data_type, identifier, description, last_change, "
        " min_x, min_y, max_x, max_y, srs_id) "
        "VALUES (?, 'features', ?, '', strftime('%Y-%m-%dT%H:%M:%fZ','now'), "
        " NULL, NULL, NULL, NULL, ?)",
        (table, table, srs_id),
    )
    cur.execute(
        "INSERT OR REPLACE INTO gpkg_geometry_columns "
        "(table_name, column_name, geometry_type_name, srs_id, z, m) "
        "VALUES (?, 'geom', ?, ?, 0, 0)",
        (table, geom_type, srs_id),
    )
    n = cur.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
    cur.execute(
        "INSERT OR REPLACE INTO gpkg_ogr_contents (table_name, feature_count) VALUES (?, ?)",
        (table, n),
    )


def rebuild_derived(cur: sqlite3.Cursor) -> dict:
    """Drop and recreate the 6 derived spatial layers from the source tables."""
    results: dict[str, int] = {}

    for tbl in DERIVED_TABLES:
        drop_gpkg_table(cur, tbl)

    # ---- birth_location_points ----
    cur.execute(
        '''CREATE TABLE "birth_location_points" (
            fid INTEGER PRIMARY KEY AUTOINCREMENT,
            geom POINT,
            person_id TEXT,
            primary_name TEXT,
            era TEXT,
            place_name TEXT
        )'''
    )
    cur.execute(
        f'''INSERT INTO "birth_location_points" (geom, person_id, primary_name, era, place_name)
           SELECT p.geom, pe.person_id, pe.primary_name,
                  {_era_sql(_year_sql("pe.birth_date"))} AS era,
                  p.name
             FROM People pe
             JOIN Places p ON p.place_id = pe.birth_place_id
            WHERE p.geom IS NOT NULL'''
    )
    register_gpkg_feature_table(cur, "birth_location_points", "POINT")
    results["birth_location_points"] = cur.execute('SELECT COUNT(*) FROM "birth_location_points"').fetchone()[0]

    # ---- death_location_points ----
    cur.execute(
        '''CREATE TABLE "death_location_points" (
            fid INTEGER PRIMARY KEY AUTOINCREMENT,
            geom POINT,
            person_id TEXT,
            primary_name TEXT,
            era TEXT,
            place_name TEXT
        )'''
    )
    cur.execute(
        f'''INSERT INTO "death_location_points" (geom, person_id, primary_name, era, place_name)
           SELECT p.geom, pe.person_id, pe.primary_name,
                  {_era_sql(_year_sql("pe.death_date"))} AS era,
                  p.name
             FROM People pe
             JOIN Places p ON p.place_id = pe.death_place_id
            WHERE p.geom IS NOT NULL'''
    )
    register_gpkg_feature_table(cur, "death_location_points", "POINT")
    results["death_location_points"] = cur.execute('SELECT COUNT(*) FROM "death_location_points"').fetchone()[0]

    # ---- birth_to_death_lines ----
    # Build a linestring per person from birth point to death point. SQLite
    # doesn't natively make a linestring — we craft the WKB byte string with
    # the GPKG header.
    cur.execute(
        '''CREATE TABLE "birth_to_death_lines" (
            fid INTEGER PRIMARY KEY AUTOINCREMENT,
            geom LINESTRING,
            person_id TEXT,
            birth_place TEXT,
            death_place TEXT
        )'''
    )
    # Use Python to construct the line geometry rows (need to encode WKB).
    import struct
    def make_linestring_gpkg_wkb(x1: float, y1: float, x2: float, y2: float, srs_id: int = 4326) -> bytes:
        # GPKG binary header: magic 'GP', version 0, flags 0x01 (envelope=0, little-endian),
        # srs_id (int32 LE), then standard WKB.
        flags = 0x01  # little-endian, no envelope
        header = b"GP" + bytes([0, flags]) + struct.pack("<i", srs_id)
        # WKB: byte_order=1 (LE), geom_type=2 (LineString), num_points=2, then x,y pairs
        wkb = struct.pack("<BII", 1, 2, 2) + struct.pack("<dddd", x1, y1, x2, y2)
        return header + wkb

    line_rows = cur.execute(
        '''SELECT pe.person_id, pe.primary_name,
                  CAST(pb.long AS REAL) AS bx, CAST(pb.lat AS REAL) AS by,
                  CAST(pd.long AS REAL) AS dx, CAST(pd.lat AS REAL) AS dy,
                  pe.birth_date, pe.death_date,
                  pb.name AS bname, pd.name AS dname,
                  pb.place_id AS bpid, pd.place_id AS dpid
             FROM People pe
             JOIN Places pb ON pb.place_id = pe.birth_place_id
             JOIN Places pd ON pd.place_id = pe.death_place_id
            WHERE pb.lat IS NOT NULL AND pb.long IS NOT NULL
              AND pd.lat IS NOT NULL AND pd.long IS NOT NULL'''
    ).fetchall()
    for r in line_rows:
        pid, name, bx, by, dx, dy, bd, dd, bname, dname, bpid, dpid = r
        if None in (bx, by, dx, dy):
            continue
        wkb = make_linestring_gpkg_wkb(bx, by, dx, dy)
        cur.execute(
            'INSERT INTO "birth_to_death_lines" (geom, person_id, birth_place, death_place) VALUES (?, ?, ?, ?)',
            (wkb, pid, bname, dname),
        )
    register_gpkg_feature_table(cur, "birth_to_death_lines", "LINESTRING")
    results["birth_to_death_lines"] = cur.execute('SELECT COUNT(*) FROM "birth_to_death_lines"').fetchone()[0]

    # ---- birth_to_death_lines_eras (same geometry + era classification) ----
    cur.execute(
        '''CREATE TABLE "birth_to_death_lines_eras" (
            fid INTEGER PRIMARY KEY AUTOINCREMENT,
            geom LINESTRING,
            person_id TEXT,
            primary_name TEXT,
            birth_year INTEGER,
            death_year INTEGER,
            mid_year INTEGER,
            era TEXT,
            birth_pid TEXT,
            death_pid TEXT,
            birth_name TEXT,
            death_name TEXT
        )'''
    )

    def era_for(year):
        if year is None:
            return "Unknown"
        if year < 1788: return "Colonial Era"
        if year < 1830: return "Early Republic"
        if year < 1865: return "Civil War & Reconstruction"
        if year < 1900: return "Gilded Age"
        if year < 1920: return "Progressive Era & WWI"
        if year < 1940: return "Roaring 20s & Great Depression"
        return "Modern"

    def parse_year(s):
        """Robustly extract a 4-digit year from a free-text date.
        Mirrors _year_sql() above and era_for() in export_geojson.py."""
        if not s:
            return None
        s = str(s)
        head = s[:4]
        if len(head) == 4 and head.isdigit() and head[0] in "12":
            return int(head)
        if len(s) >= 4:
            tail = s[-4:]
            if tail.isdigit() and tail[0] in "12":
                return int(tail)
        return None

    for r in line_rows:
        pid, name, bx, by, dx, dy, bd, dd, bname, dname, bpid, dpid = r
        if None in (bx, by, dx, dy):
            continue
        wkb = make_linestring_gpkg_wkb(bx, by, dx, dy)
        byear = parse_year(bd)
        dyear = parse_year(dd)
        myear = ((byear or 0) + (dyear or 0)) // 2 if byear and dyear else (byear or dyear)
        cur.execute(
            '''INSERT INTO "birth_to_death_lines_eras" (geom, person_id, primary_name, birth_year, death_year, mid_year, era, birth_pid, death_pid, birth_name, death_name)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
            (wkb, pid, name, byear, dyear, myear, era_for(myear), bpid, dpid, bname, dname),
        )
    register_gpkg_feature_table(cur, "birth_to_death_lines_eras", "LINESTRING")
    results["birth_to_death_lines_eras"] = cur.execute('SELECT COUNT(*) FROM "birth_to_death_lines_eras"').fetchone()[0]

    # ---- Person_Locations: every (person, place) pair from any event ----
    cur.execute(
        '''CREATE TABLE "Person_Locations" (
            fid INTEGER PRIMARY KEY AUTOINCREMENT,
            geom POINT,
            PID_Person TEXT,
            primary_name TEXT,
            place_id TEXT,
            place_name TEXT
        )'''
    )
    cur.execute(
        '''INSERT INTO "Person_Locations" (geom, PID_Person, primary_name, place_id, place_name)
           SELECT DISTINCT p.geom, pe.person_id, pe.primary_name, p.place_id, p.name
             FROM People pe
             JOIN Places p ON p.place_id IN (pe.birth_place_id, pe.death_place_id)
            WHERE p.geom IS NOT NULL
           UNION ALL
           SELECT DISTINCT p.geom, ep.person_id, pe.primary_name, p.place_id, p.name
             FROM EventParticipants ep
             JOIN People pe ON pe.person_id = ep.person_id
             JOIN Places p ON p.place_id = ep.place_id
            WHERE p.geom IS NOT NULL'''
    )
    register_gpkg_feature_table(cur, "Person_Locations", "POINT")
    results["Person_Locations"] = cur.execute('SELECT COUNT(*) FROM "Person_Locations"').fetchone()[0]

    # ---- Event_Points: each Event materialized at its Place ----
    cur.execute(
        '''CREATE TABLE "Event_Points" (
            fid INTEGER PRIMARY KEY AUTOINCREMENT,
            geom POINT,
            event_id TEXT,
            person_id TEXT,
            primary_name TEXT,
            event_type TEXT,
            title TEXT,
            date_start TEXT,
            date_end TEXT,
            place_id TEXT,
            place_name TEXT
        )'''
    )
    cur.execute(
        '''INSERT INTO "Event_Points" (geom, event_id, person_id, primary_name, event_type, title, date_start, date_end, place_id, place_name)
           SELECT p.geom, e.event_id, e.PID_People, pe.primary_name, e.event_type, e.title, e.date_start, e.date_end, p.place_id, p.name
             FROM Events e
             JOIN Places p ON p.place_id = e.place_id
        LEFT JOIN People pe ON pe.person_id = e.PID_People
            WHERE p.geom IS NOT NULL'''
    )
    register_gpkg_feature_table(cur, "Event_Points", "POINT")
    results["Event_Points"] = cur.execute('SELECT COUNT(*) FROM "Event_Points"').fetchone()[0]

    return results


def tighten_schema(cur: sqlite3.Cursor) -> dict:
    """Rebuild Places, People, Events with cleaner schemas.

    - Places.lat: TEXT -> REAL; drop PID_Person (redundant)
    - People: drop PID_Places_Birth, PID_Places_Death (redundant with
      birth_place_id, death_place_id)
    - Events: drop PID_Places, PID_People (redundant with place_id and
      EventParticipants)
    """
    out: dict[str, int] = {}

    # ---- Places ----
    places_trigs = capture_triggers(cur, "Places")
    drop_triggers(cur, places_trigs)
    cur.execute(
        '''CREATE TABLE "Places_new" (
            fid INTEGER PRIMARY KEY AUTOINCREMENT,
            geom POINT,
            place_id TEXT,
            name TEXT,
            std_name TEXT,
            lat REAL,
            long REAL,
            admin_hierarchy TEXT,
            historical_name TEXT,
            geocode_quality TEXT,
            time_valid_from TEXT,
            time_valid_to TEXT,
            notes TEXT
        )'''
    )
    cur.execute(
        '''INSERT INTO "Places_new" (geom, place_id, name, std_name, lat, long, admin_hierarchy, historical_name, geocode_quality, time_valid_from, time_valid_to, notes)
           SELECT geom, place_id, name, std_name,
                  CAST(lat AS REAL), CAST(long AS REAL),
                  admin_hierarchy, historical_name, geocode_quality, time_valid_from, time_valid_to, notes
             FROM Places'''
    )
    cur.execute('DROP TABLE "Places"')
    cur.execute('ALTER TABLE "Places_new" RENAME TO "Places"')
    # Recreate triggers from saved definitions (the table-name reference still resolves)
    recreate_triggers(cur, places_trigs)
    out["Places_rebuilt"] = cur.execute('SELECT COUNT(*) FROM "Places"').fetchone()[0]

    # ---- People ----
    people_trigs = capture_triggers(cur, "People")
    drop_triggers(cur, people_trigs)
    cur.execute(
        '''CREATE TABLE "People_new" (
            fid INTEGER PRIMARY KEY AUTOINCREMENT,
            person_id TEXT,
            primary_name TEXT,
            sex TEXT,
            birth_date TEXT,
            birth_place_id TEXT,
            death_date TEXT,
            death_place_id TEXT,
            life_confidence TEXT,
            privacy_level TEXT,
            branch TEXT,
            notes TEXT,
            profile_media_id TEXT,
            source_summary TEXT,
            fs_id TEXT
        )'''
    )
    cur.execute(
        '''INSERT INTO "People_new" (person_id, primary_name, sex, birth_date, birth_place_id, death_date, death_place_id, life_confidence, privacy_level, branch, notes, profile_media_id, source_summary, fs_id)
           SELECT person_id, primary_name, sex, birth_date, birth_place_id, death_date, death_place_id, life_confidence, privacy_level, branch, notes, profile_media_id, source_summary, fs_id
             FROM People'''
    )
    cur.execute('DROP TABLE "People"')
    cur.execute('ALTER TABLE "People_new" RENAME TO "People"')
    recreate_triggers(cur, people_trigs)
    out["People_rebuilt"] = cur.execute('SELECT COUNT(*) FROM "People"').fetchone()[0]

    # ---- Events ----
    events_trigs = capture_triggers(cur, "Events")
    drop_triggers(cur, events_trigs)
    cur.execute(
        '''CREATE TABLE "Events_new" (
            fid INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id TEXT,
            title TEXT,
            event_type TEXT,
            date_start TEXT,
            date_end TEXT,
            date_granularity TEXT,
            place_id TEXT,
            importance INTEGER,
            confidence TEXT,
            description TEXT,
            privacy_level TEXT,
            notes TEXT,
            PID_People TEXT
        )'''
    )
    # Keep PID_People for now because Event_Points view uses it. Will retire later
    # when we fully move to EventParticipants junction.
    cur.execute(
        '''INSERT INTO "Events_new" (event_id, title, event_type, date_start, date_end, date_granularity, place_id, importance, confidence, description, privacy_level, notes, PID_People)
           SELECT event_id, title, event_type, date_start, date_end, date_granularity, place_id, importance, confidence, description, privacy_level, notes, PID_People
             FROM Events'''
    )
    cur.execute('DROP TABLE "Events"')
    cur.execute('ALTER TABLE "Events_new" RENAME TO "Events"')
    recreate_triggers(cur, events_trigs)
    out["Events_rebuilt"] = cur.execute('SELECT COUNT(*) FROM "Events"').fetchone()[0]

    return out


def add_unique_indexes(cur: sqlite3.Cursor) -> dict:
    """Add UNIQUE indexes on identity columns. After this, duplicate row
    inserts will fail at write time instead of silently piling up."""
    out: dict[str, str] = {}
    for tbl, col in [
        ("People", "person_id"),
        ("Places", "place_id"),
        ("Events", "event_id"),
        ("Relationships", "rel_id"),
    ]:
        idx_name = f"ux_{tbl.lower()}_{col}"
        # Skip rows with NULL ids
        cur.execute(
            f'CREATE UNIQUE INDEX IF NOT EXISTS "{idx_name}" ON "{tbl}" ("{col}") WHERE "{col}" IS NOT NULL'
        )
        out[idx_name] = "created"
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--skip-stage-b", action="store_true", help="skip dropping stale tables")
    ap.add_argument("--skip-stage-c", action="store_true", help="skip derived rebuild")
    ap.add_argument("--skip-stage-d", action="store_true", help="skip schema tightening")
    ap.add_argument("--skip-stage-e", action="store_true", help="skip UNIQUE indexes")
    args = ap.parse_args()

    if not GPKG.exists():
        print(f"GPKG not found: {GPKG}", file=sys.stderr)
        return 1

    conn = sqlite3.connect(GPKG)
    cur = conn.cursor()

    print("== PLAN ==")
    if not args.skip_stage_b:
        print(f"  B. drop stale tables: {STALE_TABLES}")
    if not args.skip_stage_c:
        print(f"  C. rebuild derived tables: {DERIVED_TABLES}")
    if not args.skip_stage_d:
        print("  D. tighten schema: Places.lat REAL, drop redundant PID_* columns")
    if not args.skip_stage_e:
        print("  E. add UNIQUE indexes on identity columns")

    if not args.apply:
        print("\n(dry-run) pass --apply to commit.")
        conn.close()
        return 0

    print("\n== APPLY ==")
    if not args.skip_stage_b:
        for t in STALE_TABLES:
            drop_gpkg_table(cur, t)
        print(f"  B. dropped {len(STALE_TABLES)} stale tables")

    if not args.skip_stage_d:
        out = tighten_schema(cur)
        print(f"  D. schema tightening: {out}")

    if not args.skip_stage_c:
        out = rebuild_derived(cur)
        print(f"  C. derived rebuild: {out}")

    if not args.skip_stage_e:
        out = add_unique_indexes(cur)
        print(f"  E. unique indexes: {list(out.keys())}")

    conn.commit()
    conn.close()
    print(f"\nDone. Re-run scripts/validate_gpkg.py.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
