#!/usr/bin/env python3
"""Export enriched GeoJSON from the LRGDM Postgres/PostGIS database into docs/data/.

Source of truth is Postgres (db lrgdm), NOT the legacy GPKG. The viewer at
docs/index.html reads these files. Person-centric layers join `person` for
sex/branch/fs_id/notes/source_summary and derive birth_year / death_year from
the free-form birth_date / death_date columns. Era labels come from the `era`
table (single source of truth, shared with the SQL views).

Outputs (unchanged filenames/keys from the GPKG era):
  docs/data/places.geojson
  docs/data/people.geojson                  (person x place pairs + person attrs)
  docs/data/people_all.json                 (one row per person; search index)
  docs/data/birth_location_points.geojson
  docs/data/death_location_points.geojson
  docs/data/birth_to_death_lines_eras.geojson
  docs/data/events.geojson
  docs/data/event_participants.geojson      (non-spatial)
  docs/data/manifest.json

Connection: $LRGDM_PG (libpq conninfo), default "dbname=lrgdm" (local socket).
Geometry comes from place.geom via ST_X/ST_Y — no GPKG-blob parsing.
"""
from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path

import psycopg
from psycopg.rows import dict_row

REPO = Path(__file__).resolve().parents[1]
OUT = REPO / "docs/data"
CONNINFO = os.environ.get("LRGDM_PG", "dbname=lrgdm")


# --- Era assignment ---------------------------------------------------------
# Boundaries/labels come from the `era` table. The *rule* for which era a
# person belongs to (the year they turned 25) stays here.

def load_eras(cur) -> list[dict]:
    cur.execute(
        "SELECT label, year_start, year_end FROM era ORDER BY sort_order"
    )
    return cur.fetchall()


def era_for(year, eras):
    if year is None:
        return None
    for e in eras:
        lo, hi = e["year_start"], e["year_end"]
        if (lo is None or year >= lo) and (hi is None or year < hi):
            return e["label"]
    return None


def personal_era(birth_year, death_year, eras):
    """The era a person *belonged to* — the year they turned 25 (their early
    adulthood), not just where a birth/death pin lands. Falls back to death
    year if they died before 25, and to a 30-year look-back if no birth year."""
    if birth_year is not None:
        target = birth_year + 25
        if death_year is not None and target > death_year:
            target = death_year
        return era_for(target, eras)
    if death_year is not None:
        return era_for(death_year - 30, eras)
    return None


# --- SQL year extractor (mirrors the legacy GPKG logic: first-4 or last-4) ---
def year(col: str) -> str:
    return f"""
    CASE
      WHEN {col} IS NULL OR {col} = '' THEN NULL
      WHEN substring({col} FROM 1 FOR 4) ~ '^[12][0-9]{{3}}$'
        THEN substring({col} FROM 1 FOR 4)::int
      WHEN length({col}) >= 4
           AND substring({col} FROM length({col}) - 3 FOR 4) ~ '^[12][0-9]{{3}}$'
        THEN substring({col} FROM length({col}) - 3 FOR 4)::int
      ELSE NULL
    END""".strip()


# --- GeoJSON helpers --------------------------------------------------------
def feature_point(lon, lat, props):
    return {"type": "Feature",
            "geometry": {"type": "Point", "coordinates": [lon, lat]},
            "properties": props}


def feature_line(coords, props):
    return {"type": "Feature",
            "geometry": {"type": "LineString", "coordinates": coords},
            "properties": props}


def feature_nogeom(props):
    return {"type": "Feature", "geometry": None, "properties": props}


def fc(features):
    return {"type": "FeatureCollection", "features": features}


def write(path: Path, fc_obj) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w") as fh:
        json.dump(fc_obj, fh, separators=(",", ":"), ensure_ascii=False)
    print(f"  wrote {path.relative_to(REPO)}  ({len(fc_obj['features'])} features)")


def clean(row: dict, drop=("lat", "long")) -> dict:
    return {k: v for k, v in row.items() if k not in drop and v is not None}


# --- Layer exporters --------------------------------------------------------
def export_places(cur):
    cur.execute(
        """
        SELECT place_id, name, std_name, ST_Y(geom) AS lat, ST_X(geom) AS long,
               admin_hierarchy, historical_name, geocode_quality, notes
          FROM place
         WHERE geom IS NOT NULL
         ORDER BY place_id
        """
    )
    feats = [feature_point(r["long"], r["lat"], clean(r)) for r in cur.fetchall()]
    write(OUT / "places.geojson", fc(feats))


def export_birth_points(cur, eras):
    cur.execute(
        f"""
        SELECT p.person_id, p.primary_name, pl.name AS place_name,
               p.sex, p.branch, p.fs_id, p.notes, p.source_summary,
               p.birth_date, p.death_date,
               {year('p.birth_date')} AS birth_year,
               {year('p.death_date')} AS death_year,
               ST_Y(pl.geom) AS lat, ST_X(pl.geom) AS long, pl.place_id
          FROM person p
          JOIN place pl ON pl.place_id = p.birth_place_id
         WHERE pl.geom IS NOT NULL
         ORDER BY p.person_id
        """
    )
    feats = []
    for r in cur.fetchall():
        props = clean(r)
        props["era"] = personal_era(r["birth_year"], r["death_year"], eras)
        feats.append(feature_point(r["long"], r["lat"], props))
    write(OUT / "birth_location_points.geojson", fc(feats))


def export_death_points(cur, eras):
    cur.execute(
        f"""
        SELECT p.person_id, p.primary_name, pl.name AS place_name,
               p.sex, p.branch, p.fs_id, p.notes, p.source_summary,
               p.birth_date, p.death_date,
               {year('p.birth_date')} AS birth_year,
               {year('p.death_date')} AS death_year,
               ST_Y(pl.geom) AS lat, ST_X(pl.geom) AS long, pl.place_id
          FROM person p
          JOIN place pl ON pl.place_id = p.death_place_id
         WHERE pl.geom IS NOT NULL
         ORDER BY p.person_id
        """
    )
    feats = []
    for r in cur.fetchall():
        props = clean(r)
        props["era"] = personal_era(r["birth_year"], r["death_year"], eras)
        feats.append(feature_point(r["long"], r["lat"], props))
    write(OUT / "death_location_points.geojson", fc(feats))


def export_lines(cur, eras):
    cur.execute(
        f"""
        SELECT p.person_id, p.primary_name,
               p.birth_place_id AS birth_pid, p.death_place_id AS death_pid,
               b.name AS birth_name, d.name AS death_name,
               p.sex, p.branch, p.fs_id, p.notes, p.source_summary,
               p.birth_date, p.death_date,
               {year('p.birth_date')} AS birth_year,
               {year('p.death_date')} AS death_year,
               ST_Y(b.geom) AS b_lat, ST_X(b.geom) AS b_long,
               ST_Y(d.geom) AS d_lat, ST_X(d.geom) AS d_long
          FROM person p
          JOIN place b ON b.place_id = p.birth_place_id
          JOIN place d ON d.place_id = p.death_place_id
         WHERE b.geom IS NOT NULL AND d.geom IS NOT NULL
         ORDER BY p.person_id
        """
    )
    feats = []
    for r in cur.fetchall():
        coords = [[r["b_long"], r["b_lat"]], [r["d_long"], r["d_lat"]]]
        props = {k: v for k, v in r.items()
                 if k not in ("b_lat", "b_long", "d_lat", "d_long") and v is not None}
        by, dy = r["birth_year"], r["death_year"]
        if by and dy:
            props["mid_year"] = (by + dy) // 2
        props["era"] = personal_era(by, dy, eras)
        feats.append(feature_line(coords, props))
    write(OUT / "birth_to_death_lines_eras.geojson", fc(feats))


def export_people(cur, eras):
    # One row per (person, place) the person is tied to (birth/death/event),
    # mirroring the legacy Person_Locations layer.
    cur.execute(
        f"""
        SELECT DISTINCT ON (pl.person_id, pl.place_id)
               pl.person_id, p.primary_name, pl.place_id, plc.name AS place_name,
               p.sex, p.branch, p.fs_id, p.notes, p.source_summary,
               p.birth_date, p.death_date, p.birth_place_id, p.death_place_id,
               {year('p.birth_date')} AS birth_year,
               {year('p.death_date')} AS death_year,
               ST_Y(plc.geom) AS lat, ST_X(plc.geom) AS long
          FROM v_person_locations pl
          JOIN person p   ON p.person_id = pl.person_id
          JOIN place plc  ON plc.place_id = pl.place_id
         WHERE plc.geom IS NOT NULL
         ORDER BY pl.person_id, pl.place_id
        """
    )
    feats = [feature_point(r["long"], r["lat"], clean(r)) for r in cur.fetchall()]
    write(OUT / "people.geojson", fc(feats))


def export_events(cur):
    # One row per geocoded event, with its representative person (the 'self'
    # participant — the old Events.PID_People), mirroring Event_Points.
    cur.execute(
        f"""
        SELECT e.event_id, sp.person_id, sp.primary_name, e.event_type,
               e.title, e.date_start, e.date_end, e.place_id, pl.name AS place_name,
               e.importance, e.confidence, e.description,
               e.date_granularity, e.notes AS event_notes,
               {year('e.date_start')} AS event_year,
               sp.sex, sp.branch, sp.fs_id,
               ST_Y(pl.geom) AS lat, ST_X(pl.geom) AS long
          FROM event e
          JOIN place pl ON pl.place_id = e.place_id
          LEFT JOIN LATERAL (
            SELECT pr.person_id, pr.primary_name, pr.sex, pr.branch, pr.fs_id
              FROM event_participant ep
              JOIN person pr ON pr.person_id = ep.person_id
             WHERE ep.event_id = e.event_id
             ORDER BY (ep.role = 'self') DESC, ep.id
             LIMIT 1
          ) sp ON true
         WHERE pl.geom IS NOT NULL
         ORDER BY e.event_id
        """
    )
    feats = [feature_point(r["long"], r["lat"], clean(r)) for r in cur.fetchall()]
    write(OUT / "events.geojson", fc(feats))


def export_people_all(cur, eras):
    cur.execute(
        f"""
        SELECT p.person_id, p.primary_name, p.sex, p.branch, p.fs_id,
               p.birth_date, p.death_date, p.notes, p.source_summary,
               p.birth_place_id, p.death_place_id,
               {year('p.birth_date')} AS birth_year,
               {year('p.death_date')} AS death_year,
               bp.name AS birth_place_name, ST_Y(bp.geom) AS birth_lat, ST_X(bp.geom) AS birth_long,
               dp.name AS death_place_name, ST_Y(dp.geom) AS death_lat, ST_X(dp.geom) AS death_long
          FROM person p
          LEFT JOIN place bp ON bp.place_id = p.birth_place_id
          LEFT JOIN place dp ON dp.place_id = p.death_place_id
         ORDER BY p.person_id
        """
    )
    people = []
    for r in cur.fetchall():
        d = {k: v for k, v in r.items() if v is not None}
        d["era"] = personal_era(r["birth_year"], r["death_year"], eras)
        d["has_birth_point"] = r["birth_lat"] is not None and r["birth_long"] is not None
        d["has_death_point"] = r["death_lat"] is not None and r["death_long"] is not None
        people.append(d)
    out = OUT / "people_all.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"people": people}, separators=(",", ":"), ensure_ascii=False))
    print(f"  wrote {out.relative_to(REPO)}  ({len(people)} rows)")


def export_event_participants(cur):
    cur.execute(
        """
        SELECT ep.event_id, ep.person_id, ep.role,
               e.event_type, e.title, e.date_start, e.place_id
          FROM event_participant ep
          JOIN event e ON e.event_id = ep.event_id
         ORDER BY ep.event_id, ep.person_id
        """
    )
    feats = [feature_nogeom({k: v for k, v in r.items() if v is not None})
             for r in cur.fetchall()]
    write(OUT / "event_participants.geojson", fc(feats))


def export_manifest(cur, eras):
    # eras actually present among birth/death points, in canonical order
    present = set()
    for col in ("birth_place_id", "death_place_id"):
        cur.execute(
            f"""
            SELECT {year('p.birth_date')} AS by, {year('p.death_date')} AS dy
              FROM person p JOIN place pl ON pl.place_id = p.{col}
             WHERE pl.geom IS NOT NULL
            """
        )
        for r in cur.fetchall():
            e = personal_era(r["by"], r["dy"], eras)
            if e:
                present.add(e)
    era_order = [e["label"] for e in eras]
    present_eras = [lbl for lbl in era_order if lbl in present]

    cur.execute(
        f"""
        SELECT min({year('birth_date')}) AS ymin, max({year('death_date')}) AS ymax
          FROM person
        """
    )
    row = cur.fetchone()
    year_min, year_max = row["ymin"], row["ymax"]

    cur.execute("SELECT count(*) AS c FROM person")
    person_count = cur.fetchone()["c"]
    cur.execute("SELECT count(*) AS c FROM place")
    place_count = cur.fetchone()["c"]
    cur.execute("SELECT count(*) AS c FROM event")
    event_count = cur.fetchone()["c"]
    cur.execute(
        "SELECT branch FROM person WHERE branch IS NOT NULL "
        "GROUP BY branch ORDER BY count(*) DESC"
    )
    branches = [r["branch"] for r in cur.fetchall()]

    manifest = {
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "proband_fs_id": "L274-KNT",
        "year_min": year_min,
        "year_max": year_max,
        "eras": present_eras,
        "branches": branches,
        "person_count": person_count,
        "place_count": place_count,
        "event_count": event_count,
    }
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"  wrote {(OUT / 'manifest.json').relative_to(REPO)}")


def main() -> int:
    print(f"Reading Postgres ({CONNINFO}) → {OUT.relative_to(REPO)}/")
    with psycopg.connect(CONNINFO, row_factory=dict_row) as con:
        with con.cursor() as cur:
            eras = load_eras(cur)
            export_places(cur)
            export_people(cur, eras)
            export_people_all(cur, eras)
            export_birth_points(cur, eras)
            export_death_points(cur, eras)
            export_lines(cur, eras)
            export_events(cur)
            export_event_participants(cur)
            export_manifest(cur, eras)
    print("done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
