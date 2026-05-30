-- =====================================================================
-- LRGDM — one-time ETL: staging (from GPKG) -> normalized schema
--
-- PREREQ: load the GPKG layers into a `staging` schema first with ogr2ogr
-- (names are lower-cased by ogr2ogr's default LAUNDER):
--
--   createdb lrgdm && psql lrgdm -c "CREATE EXTENSION postgis;"
--   psql lrgdm -f db/migrations/0001_core.sql
--   psql lrgdm -f db/migrations/0002_sources_media.sql
--   psql lrgdm -f db/migrations/0003_views.sql
--   psql lrgdm -f db/migrations/0004_seed_lookups.sql
--   ogr2ogr -f PostgreSQL PG:"dbname=lrgdm" src/data/lrgdm.gpkg \
--           -lco SCHEMA=staging -lco LAUNDER=YES \
--           People Places Events EventParticipants Relationships
--   psql lrgdm -f db/load_from_gpkg.sql
--
-- Defensive throughout: broken FKs become NULL (matches the GPKG's own
-- "honestly nulled" convention), confidences/sex are coerced into the
-- allowed sets, and lookups are topped up from the actual data.
-- Re-runnable: ON CONFLICT DO NOTHING on every insert.
-- =====================================================================

BEGIN;

-- 0) Top up controlled vocab from whatever codes the data actually uses
INSERT INTO event_type (code)
  SELECT DISTINCT event_type FROM staging.events
  WHERE event_type IS NOT NULL
  ON CONFLICT (code) DO NOTHING;

INSERT INTO relation_type (code)
  SELECT DISTINCT relation FROM staging.relationships
  WHERE relation IS NOT NULL
  ON CONFLICT (code) DO NOTHING;

-- 1) place — geometry rebuilt from lat/long (independent of ogr2ogr's geom
--    column name); odd geocode_quality values are kept as-is (free text).
INSERT INTO place (place_id, name, std_name, geom, admin_hierarchy, geocode_quality,
                   historical_name, notes, time_valid_from, time_valid_to)
  SELECT s.place_id, s.name, s.std_name,
         CASE WHEN s."long" IS NOT NULL AND s.lat IS NOT NULL
              THEN ST_SetSRID(ST_MakePoint(s."long", s.lat), 4326) END,
         s.admin_hierarchy, s.geocode_quality,
         s.historical_name, s.notes, s.time_valid_from, s.time_valid_to
  FROM staging.places s
  ON CONFLICT (place_id) DO NOTHING;

-- 2) person — coerce sex/confidence/privacy; broken place FKs -> NULL;
--    profile_media_id forced NULL (no media loaded yet); source_summary
--    retained as legacy provenance.
INSERT INTO person (person_id, primary_name, sex, birth_date, birth_place_id,
                    death_date, death_place_id, life_confidence, privacy_level,
                    branch, fs_id, notes, profile_media_id, source_summary)
  SELECT s.person_id, s.primary_name,
         CASE WHEN lower(s.sex) IN ('male','female') THEN lower(s.sex)
              WHEN s.sex IS NULL THEN NULL ELSE 'unknown' END,
         s.birth_date, pb.place_id,
         s.death_date, pd.place_id,
         CASE WHEN lower(s.life_confidence) IN ('high','low') THEN lower(s.life_confidence)
              WHEN lower(s.life_confidence) IN ('med','medium') THEN 'med' END,
         CASE WHEN lower(s.privacy_level) = 'private' THEN 'private' ELSE 'public' END,
         s.branch, s.fs_id, s.notes, NULL, s.source_summary
  FROM staging.people s
  LEFT JOIN place pb ON pb.place_id = s.birth_place_id
  LEFT JOIN place pd ON pd.place_id = s.death_place_id
  ON CONFLICT (person_id) DO NOTHING;

-- 3) event — coerce confidence; broken place FK -> NULL.
INSERT INTO event (event_id, title, event_type, date_start, date_end,
                   date_granularity, place_id, importance, confidence,
                   description, privacy_level, notes)
  SELECT s.event_id, s.title, s.event_type, s.date_start, s.date_end,
         s.date_granularity, pl.place_id, s.importance,
         CASE WHEN lower(s.confidence) IN ('high','low') THEN lower(s.confidence)
              WHEN lower(s.confidence) IN ('med','medium') THEN 'med' END,
         s.description,
         CASE WHEN lower(s.privacy_level) = 'private' THEN 'private' ELSE 'public' END,
         s.notes
  FROM staging.events s
  LEFT JOIN place pl ON pl.place_id = s.place_id
  ON CONFLICT (event_id) DO NOTHING;

-- 4a) event_participant — from the M:N table (only valid person/event pairs).
INSERT INTO event_participant (event_id, person_id, role)
  SELECT s.event_id, s.person_id, NULLIF(s.role, '')
  FROM staging.eventparticipants s
  JOIN event  e ON e.event_id  = s.event_id
  JOIN person p ON p.person_id = s.person_id
  ON CONFLICT (event_id, person_id, role) DO NOTHING;

-- 4b) event_participant — fold legacy Events.PID_People into participants
--     (role 'self') where that person isn't already linked to the event.
INSERT INTO event_participant (event_id, person_id, role)
  SELECT s.event_id, s.pid_people, 'self'
  FROM staging.events s
  JOIN event  e ON e.event_id  = s.event_id
  JOIN person p ON p.person_id = s.pid_people
  WHERE s.pid_people IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM event_participant ep
      WHERE ep.event_id = s.event_id AND ep.person_id = s.pid_people)
  ON CONFLICT (event_id, person_id, role) DO NOTHING;

-- 5) relationship — only pairs where both persons exist.
INSERT INTO relationship (rel_id, person_id_a, relation, person_id_b,
                          start_date, end_date, evidence_note)
  SELECT s.rel_id, s.person_id_a, s.relation, s.person_id_b,
         s.start_date, s.end_date, s.evidence_note
  FROM staging.relationships s
  JOIN person a ON a.person_id = s.person_id_a
  JOIN person b ON b.person_id = s.person_id_b
  ON CONFLICT (rel_id) DO NOTHING;

COMMIT;

-- Quick sanity check after load:
--   SELECT 'person' t, count(*) FROM person
--   UNION ALL SELECT 'place', count(*) FROM place
--   UNION ALL SELECT 'event', count(*) FROM event
--   UNION ALL SELECT 'event_participant', count(*) FROM event_participant
--   UNION ALL SELECT 'relationship', count(*) FROM relationship;
-- Then drop staging:  DROP SCHEMA staging CASCADE;
