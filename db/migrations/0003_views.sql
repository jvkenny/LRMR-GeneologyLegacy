-- =====================================================================
-- LRGDM 0003 — Derived views (spatial + provenance)
--
-- These views REPLACE the six materialized "derived layers" the GPKG
-- regenerated with cleanup_model.py (birth_location_points,
-- death_location_points, birth_to_death_lines, birth_to_death_lines_eras,
-- Person_Locations, Event_Points). In PostGIS they are live: edit a place
-- or a birth_place_id and the geometry updates automatically — no rebuild
-- step. QGIS consumes the v_* views; export_geojson.py dumps them.
--
-- For QGIS: each spatial view exposes a stable id column (person_id /
-- event_id) to use as the layer's feature id, and a geom typed as
-- geometry(...,4326).
--
-- Run:  psql lrgdm -f db/migrations/0003_views.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- Small helpers for fuzzy genealogical dates -> year / era
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION lrgdm_year(d text) RETURNS int
  LANGUAGE sql IMMUTABLE AS $$
  SELECT NULLIF(substring(d FROM '\d{4}'), '')::int;
$$;

CREATE OR REPLACE FUNCTION lrgdm_era(yr int) RETURNS text
  LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN yr IS NULL   THEN 'Unknown'
    WHEN yr < 1700    THEN 'Colonial & earlier'
    WHEN yr < 1800    THEN '18th century'
    WHEN yr < 1850    THEN 'Early 19th century'
    WHEN yr < 1900    THEN 'Late 19th century'
    WHEN yr < 1946    THEN 'Early 20th century'
    ELSE                   'Postwar'
  END;
$$;  -- buckets are tunable; chosen for a US family tree map legend

-- ---------------------------------------------------------------------
-- Birth / death points
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_birth_location_points AS
  SELECT p.person_id, p.primary_name, p.birth_date,
         lrgdm_year(p.birth_date)               AS birth_year,
         lrgdm_era(lrgdm_year(p.birth_date))     AS era,
         p.privacy_level, pl.geom
  FROM person p
  JOIN place pl ON pl.place_id = p.birth_place_id
  WHERE pl.geom IS NOT NULL;

CREATE OR REPLACE VIEW v_death_location_points AS
  SELECT p.person_id, p.primary_name, p.death_date,
         lrgdm_year(p.death_date)               AS death_year,
         lrgdm_era(lrgdm_year(p.death_date))     AS era,
         p.privacy_level, pl.geom
  FROM person p
  JOIN place pl ON pl.place_id = p.death_place_id
  WHERE pl.geom IS NOT NULL;

-- ---------------------------------------------------------------------
-- Birth -> death lines (plain + era-tagged)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_birth_to_death_lines AS
  SELECT p.person_id, p.primary_name,
         ST_MakeLine(b.geom, d.geom)::geometry(LineString,4326) AS geom
  FROM person p
  JOIN place b ON b.place_id = p.birth_place_id
  JOIN place d ON d.place_id = p.death_place_id
  WHERE b.geom IS NOT NULL AND d.geom IS NOT NULL
    AND NOT ST_Equals(b.geom, d.geom);

CREATE OR REPLACE VIEW v_birth_to_death_lines_eras AS
  SELECT p.person_id, p.primary_name,
         lrgdm_year(p.birth_date) AS birth_year,
         lrgdm_year(p.death_date) AS death_year,
         (lrgdm_year(p.birth_date) + lrgdm_year(p.death_date)) / 2 AS mid_year,
         lrgdm_era((lrgdm_year(p.birth_date) + lrgdm_year(p.death_date)) / 2) AS era,
         ST_MakeLine(b.geom, d.geom)::geometry(LineString,4326) AS geom
  FROM person p
  JOIN place b ON b.place_id = p.birth_place_id
  JOIN place d ON d.place_id = p.death_place_id
  WHERE b.geom IS NOT NULL AND d.geom IS NOT NULL
    AND NOT ST_Equals(b.geom, d.geom);

-- ---------------------------------------------------------------------
-- Event points + participant-resolved events
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_event_points AS
  SELECT e.event_id, e.title, e.event_type, e.date_start, e.date_end,
         e.confidence, e.privacy_level, pl.geom
  FROM event e
  JOIN place pl ON pl.place_id = e.place_id
  WHERE pl.geom IS NOT NULL;

CREATE OR REPLACE VIEW v_event_participants AS
  SELECT ep.id, ep.event_id, e.title, e.event_type, e.date_start,
         ep.person_id, p.primary_name, ep.role, pl.geom
  FROM event_participant ep
  JOIN event  e  ON e.event_id  = ep.event_id
  JOIN person p  ON p.person_id = ep.person_id
  LEFT JOIN place pl ON pl.place_id = e.place_id;

-- ---------------------------------------------------------------------
-- Person_Locations: every (person, place) pair — from birth, death, and
-- event participation — for the "everywhere this person appears" layer.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_person_locations AS
  SELECT p.person_id, p.primary_name, 'birth'::text AS role, pl.place_id, pl.geom
    FROM person p JOIN place pl ON pl.place_id = p.birth_place_id WHERE pl.geom IS NOT NULL
  UNION
  SELECT p.person_id, p.primary_name, 'death'::text, pl.place_id, pl.geom
    FROM person p JOIN place pl ON pl.place_id = p.death_place_id WHERE pl.geom IS NOT NULL
  UNION
  SELECT ep.person_id, p.primary_name, COALESCE(NULLIF(ep.role,''),'event'), pl.place_id, pl.geom
    FROM event_participant ep
    JOIN event e   ON e.event_id  = ep.event_id
    JOIN person p  ON p.person_id = ep.person_id
    JOIN place pl  ON pl.place_id = e.place_id
   WHERE pl.geom IS NOT NULL;

-- ---------------------------------------------------------------------
-- Provenance views
-- ---------------------------------------------------------------------
-- Forward replacement for the legacy person.source_summary free-text:
CREATE OR REPLACE VIEW v_source_summary AS
  SELECT c.subject_id AS person_id,
         string_agg(DISTINCT s.title, '; ' ORDER BY s.title) AS source_summary,
         count(*) AS citation_count
  FROM citation c
  JOIN source s ON s.source_id = c.source_id
  WHERE c.subject_type = 'person'
  GROUP BY c.subject_id;

-- Convenience: every citation joined to its source, for review/export.
CREATE OR REPLACE VIEW v_citations_expanded AS
  SELECT c.citation_id, c.subject_type, c.subject_id, c.subject_field, c.claim,
         c.confidence, c.conflicts_flag, c.locator,
         s.source_id, s.source_type, s.title AS source_title, s.repository, s.url
  FROM citation c
  JOIN source s ON s.source_id = c.source_id;
