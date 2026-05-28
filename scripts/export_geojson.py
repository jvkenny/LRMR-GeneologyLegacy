#!/usr/bin/env python3
"""Export enriched GeoJSON from src/data/lrgdm.gpkg into docs/data/.

The viewer at docs/index.html reads these files. Compared to a straight
table-to-GeoJSON dump, this enriches the person-centric layers by joining
People for sex/branch/fs_id/notes/source_summary and deriving birth_year /
death_year from the free-form birth_date / death_date columns.

Outputs:
  docs/data/places.geojson
  docs/data/people.geojson                  (Person_Locations + People attrs)
  docs/data/birth_location_points.geojson   (+ People attrs)
  docs/data/death_location_points.geojson   (+ People attrs)
  docs/data/birth_to_death_lines_eras.geojson  (+ People attrs)
  docs/data/events.geojson                  (Event_Points + Events + People attrs)
  docs/data/event_participants.geojson      (non-spatial; kept as-is)
  docs/data/manifest.json                   (era list, year bounds, counts, last_updated)

All geometries are built from Places.lat / Places.long (no GPKG-blob parsing),
which is safe because every person/event spatial layer references Places.
"""
from __future__ import annotations

import json
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GPKG = REPO / "src/data/lrgdm.gpkg"
OUT = REPO / "docs/data"

# Era boundaries (right-open intervals). Recomputed in Python from the
# robustly-extracted birth_year, NOT trusted from the GPKG — the cleanup_model
# era SQL uses substr(date, 1, 4) which silently mislabels rows like
# "14 April 1878" as Colonial Era.
ERAS = [
    (1788, "Colonial Era"),
    (1830, "Early Republic"),
    (1865, "Civil War & Reconstruction"),
    (1900, "Gilded Age"),
    (1920, "Progressive Era & WWI"),
    (1940, "Roaring 20s & Great Depression"),
]


def era_for(year):
    if year is None:
        return None
    for cutoff, name in ERAS:
        if year < cutoff:
            return name
    return "Modern"


def personal_era(birth_year, death_year):
    """Return the canonical era a person *belonged to*, not just where their
    birth or death pin happens to land.

    Rule: use the year they turned 25 — the era of their early-adult life.
    Falls back to death_year if they died before 25, and to a 30-year
    look-back if no birth year is known. None if no dates at all.

    This avoids quirks like Elizabeth Polly Palmer (1757–1851) reading as
    "Civil War & Reconstruction" simply because she lived to 94. Her young
    adulthood was Colonial, so that's the era we surface."""
    if birth_year is not None:
        target = birth_year + 25
        if death_year is not None and target > death_year:
            target = death_year
        return era_for(target)
    if death_year is not None:
        return era_for(death_year - 30)
    return None

# Year extractor: handles "1816-06-03", "1759", "circa 1822", "14 November 1741".
YEAR_SQL = """
CASE
  WHEN {col} IS NULL OR {col} = '' THEN NULL
  WHEN substr({col}, 1, 4) GLOB '[12][0-9][0-9][0-9]'
    THEN CAST(substr({col}, 1, 4) AS INTEGER)
  WHEN length({col}) >= 4
       AND substr({col}, length({col}) - 3, 4) GLOB '[12][0-9][0-9][0-9]'
    THEN CAST(substr({col}, length({col}) - 3, 4) AS INTEGER)
  ELSE NULL
END
"""


def year(col: str) -> str:
    return YEAR_SQL.format(col=col).strip()


def feature_point(lon, lat, props):
    return {
        "type": "Feature",
        "geometry": {"type": "Point", "coordinates": [lon, lat]},
        "properties": props,
    }


def feature_line(coords, props):
    return {
        "type": "Feature",
        "geometry": {"type": "LineString", "coordinates": coords},
        "properties": props,
    }


def feature_nogeom(props):
    return {"type": "Feature", "geometry": None, "properties": props}


def fc(features):
    return {"type": "FeatureCollection", "features": features}


def write(path: Path, fc_obj) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w") as fh:
        json.dump(fc_obj, fh, separators=(",", ":"), ensure_ascii=False)
    print(f"  wrote {path.relative_to(REPO)}  ({len(fc_obj['features'])} features)")


def clean(row: sqlite3.Row, drop=("lat", "long")) -> dict:
    """Row → plain dict, dropping coordinate keys we promoted into geometry."""
    return {k: row[k] for k in row.keys() if k not in drop and row[k] is not None}


def export_places(con):
    rows = con.execute(
        """
        SELECT place_id, name, std_name, lat, long, admin_hierarchy,
               historical_name, geocode_quality, notes
          FROM Places
         WHERE lat IS NOT NULL AND long IS NOT NULL
        """
    ).fetchall()
    feats = [feature_point(r["long"], r["lat"], clean(r)) for r in rows]
    write(OUT / "places.geojson", fc(feats))


def export_birth_points(con):
    rows = con.execute(
        f"""
        SELECT b.person_id, b.primary_name, b.place_name,
               p.sex, p.branch, p.fs_id, p.notes, p.source_summary,
               p.birth_date, p.death_date,
               {year('p.birth_date')} AS birth_year,
               {year('p.death_date')} AS death_year,
               pl.lat, pl.long, pl.place_id
          FROM birth_location_points b
          LEFT JOIN People p ON p.person_id = b.person_id
          LEFT JOIN Places pl ON pl.place_id = p.birth_place_id
         WHERE pl.lat IS NOT NULL AND pl.long IS NOT NULL
        """
    ).fetchall()
    feats = []
    for r in rows:
        props = clean(r)
        props["era"] = personal_era(r["birth_year"], r["death_year"])
        feats.append(feature_point(r["long"], r["lat"], props))
    write(OUT / "birth_location_points.geojson", fc(feats))


def export_death_points(con):
    rows = con.execute(
        f"""
        SELECT d.person_id, d.primary_name, d.place_name,
               p.sex, p.branch, p.fs_id, p.notes, p.source_summary,
               p.birth_date, p.death_date,
               {year('p.birth_date')} AS birth_year,
               {year('p.death_date')} AS death_year,
               pl.lat, pl.long, pl.place_id
          FROM death_location_points d
          LEFT JOIN People p ON p.person_id = d.person_id
          LEFT JOIN Places pl ON pl.place_id = p.death_place_id
         WHERE pl.lat IS NOT NULL AND pl.long IS NOT NULL
        """
    ).fetchall()
    feats = []
    for r in rows:
        props = clean(r)
        props["era"] = personal_era(r["birth_year"], r["death_year"])
        feats.append(feature_point(r["long"], r["lat"], props))
    write(OUT / "death_location_points.geojson", fc(feats))


def export_lines(con):
    rows = con.execute(
        f"""
        SELECT l.person_id, l.primary_name,
               l.birth_pid, l.death_pid, l.birth_name, l.death_name,
               p.sex, p.branch, p.fs_id, p.notes, p.source_summary,
               p.birth_date, p.death_date,
               {year('p.birth_date')} AS birth_year,
               {year('p.death_date')} AS death_year,
               b.lat AS b_lat, b.long AS b_long,
               d.lat AS d_lat, d.long AS d_long
          FROM birth_to_death_lines_eras l
          LEFT JOIN People p ON p.person_id = l.person_id
          LEFT JOIN Places b ON b.place_id = l.birth_pid
          LEFT JOIN Places d ON d.place_id = l.death_pid
         WHERE b.lat IS NOT NULL AND b.long IS NOT NULL
           AND d.lat IS NOT NULL AND d.long IS NOT NULL
        """
    ).fetchall()
    feats = []
    for r in rows:
        coords = [[r["b_long"], r["b_lat"]], [r["d_long"], r["d_lat"]]]
        props = {
            k: r[k]
            for k in r.keys()
            if k not in ("b_lat", "b_long", "d_lat", "d_long") and r[k] is not None
        }
        by, dy = r["birth_year"], r["death_year"]
        if by and dy:
            props["mid_year"] = (by + dy) // 2
        props["era"] = personal_era(by, dy)
        feats.append(feature_line(coords, props))
    write(OUT / "birth_to_death_lines_eras.geojson", fc(feats))


def export_people(con):
    rows = con.execute(
        f"""
        SELECT pl.PID_Person AS person_id, pl.primary_name, pl.place_id, pl.place_name,
               p.sex, p.branch, p.fs_id, p.notes, p.source_summary,
               p.birth_date, p.death_date, p.birth_place_id, p.death_place_id,
               {year('p.birth_date')} AS birth_year,
               {year('p.death_date')} AS death_year,
               places.lat, places.long
          FROM Person_Locations pl
          LEFT JOIN People p ON p.person_id = pl.PID_Person
          LEFT JOIN Places places ON places.place_id = pl.place_id
         WHERE places.lat IS NOT NULL AND places.long IS NOT NULL
        """
    ).fetchall()
    feats = [feature_point(r["long"], r["lat"], clean(r)) for r in rows]
    write(OUT / "people.geojson", fc(feats))


def export_events(con):
    rows = con.execute(
        f"""
        SELECT ep.event_id, ep.person_id, ep.primary_name, ep.event_type,
               ep.title, ep.date_start, ep.date_end, ep.place_id, ep.place_name,
               ev.importance, ev.confidence, ev.description,
               ev.date_granularity, ev.notes AS event_notes,
               {year('ep.date_start')} AS event_year,
               p.sex, p.branch, p.fs_id,
               places.lat, places.long
          FROM Event_Points ep
          LEFT JOIN Events ev ON ev.event_id = ep.event_id
          LEFT JOIN People p ON p.person_id = ep.person_id
          LEFT JOIN Places places ON places.place_id = ep.place_id
         WHERE places.lat IS NOT NULL AND places.long IS NOT NULL
        """
    ).fetchall()
    feats = [feature_point(r["long"], r["lat"], clean(r)) for r in rows]
    write(OUT / "events.geojson", fc(feats))


def export_people_all(con):
    """One row per person (regardless of whether they have a map location).
    Drives the viewer's search index and the 'without map location' list."""
    rows = con.execute(
        f"""
        SELECT p.person_id, p.primary_name, p.sex, p.branch, p.fs_id,
               p.birth_date, p.death_date, p.notes, p.source_summary,
               p.birth_place_id, p.death_place_id,
               {year('p.birth_date')} AS birth_year,
               {year('p.death_date')} AS death_year,
               bp.name AS birth_place_name, bp.lat AS birth_lat, bp.long AS birth_long,
               dp.name AS death_place_name, dp.lat AS death_lat, dp.long AS death_long
          FROM People p
          LEFT JOIN Places bp ON bp.place_id = p.birth_place_id
          LEFT JOIN Places dp ON dp.place_id = p.death_place_id
         ORDER BY p.person_id
        """
    ).fetchall()
    people = []
    for r in rows:
        d = {k: r[k] for k in r.keys() if r[k] is not None}
        d["era"] = personal_era(r["birth_year"], r["death_year"])
        d["has_birth_point"] = r["birth_lat"] is not None and r["birth_long"] is not None
        d["has_death_point"] = r["death_lat"] is not None and r["death_long"] is not None
        people.append(d)
    out = OUT / "people_all.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"people": people}, separators=(",", ":"), ensure_ascii=False))
    print(f"  wrote {out.relative_to(REPO)}  ({len(people)} rows)")


def export_event_participants(con):
    rows = con.execute(
        """
        SELECT event_id, person_id, role, event_type, title, date_start, place_id
          FROM EventParticipants
        """
    ).fetchall()
    feats = [feature_nogeom({k: r[k] for k in r.keys() if r[k] is not None}) for r in rows]
    write(OUT / "event_participants.geojson", fc(feats))


def export_manifest(con):
    eras = [
        row[0]
        for row in con.execute(
            "SELECT DISTINCT era FROM birth_location_points "
            "UNION SELECT DISTINCT era FROM death_location_points "
            "ORDER BY 1"
        ).fetchall()
        if row[0]
    ]
    year_min, year_max = con.execute(
        "SELECT MIN(birth_year), MAX(death_year) FROM birth_to_death_lines_eras "
        "WHERE birth_year IS NOT NULL"
    ).fetchone()
    person_count = con.execute("SELECT COUNT(*) FROM People").fetchone()[0]
    place_count = con.execute("SELECT COUNT(*) FROM Places").fetchone()[0]
    event_count = con.execute("SELECT COUNT(*) FROM Events").fetchone()[0]
    branches = [
        row[0]
        for row in con.execute(
            "SELECT branch, COUNT(*) FROM People WHERE branch IS NOT NULL "
            "GROUP BY branch ORDER BY COUNT(*) DESC"
        ).fetchall()
    ]
    manifest = {
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "proband_fs_id": "L274-KNT",
        "year_min": year_min,
        "year_max": year_max,
        "eras": eras,
        "branches": branches,
        "person_count": person_count,
        "place_count": place_count,
        "event_count": event_count,
    }
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"  wrote {(OUT / 'manifest.json').relative_to(REPO)}")


def main() -> int:
    if not GPKG.exists():
        print(f"ERROR: {GPKG} not found", flush=True)
        return 1
    print(f"Reading {GPKG.relative_to(REPO)} → {OUT.relative_to(REPO)}/")
    con = sqlite3.connect(GPKG)
    con.row_factory = sqlite3.Row
    try:
        export_places(con)
        export_people(con)
        export_people_all(con)
        export_birth_points(con)
        export_death_points(con)
        export_lines(con)
        export_events(con)
        export_event_participants(con)
        export_manifest(con)
    finally:
        con.close()
    print("done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
