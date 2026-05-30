-- =====================================================================
-- LRGDM 0001 — Core schema (entities + vocab + spatial)
--
-- Postgres/PostGIS port of the LRGDM core tables that currently live in
-- src/data/lrgdm.gpkg. Human-readable business keys (P-/PL-/E-/R-/S-/M-)
-- are kept as primary keys because dossiers, citations and URLs reference
-- them. Geometry on `place` (EPSG:4326) is the single source of spatial
-- truth; lat/long are derived at export time via ST_Y/ST_X.
--
-- Run:  psql lrgdm -f db/migrations/0001_core.sql
-- Idempotent-ish: uses IF NOT EXISTS so a re-run won't error.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS postgis;

-- ---------------------------------------------------------------------
-- Controlled vocabularies (seeded in 0004; ETL also tops them up so a
-- load never fails on an unforeseen code). Lookup tables rather than
-- Postgres ENUMs because the vocab evolves and ENUMs are painful to ALTER.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS event_type (
  code        text PRIMARY KEY,
  label       text,
  description text
);

CREATE TABLE IF NOT EXISTS relation_type (
  code  text PRIMARY KEY,
  label text
);

CREATE TABLE IF NOT EXISTS source_type (
  code  text PRIMARY KEY,
  label text
);

-- ---------------------------------------------------------------------
-- updated_at trigger helper
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- place  (the only base table that carries geometry)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS place (
  place_id        text PRIMARY KEY,                 -- 'PL-5244'
  name            text NOT NULL,
  std_name        text,
  geom            geometry(Point, 4326),
  admin_hierarchy text,
  geocode_quality text,                             -- address|cemetery|ward|township|settlement|
                                                    -- county|region|country|unknown (free text on
                                                    -- purpose: never block a load on an odd value)
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS place_geom_gix ON place USING gist (geom);

DROP TRIGGER IF EXISTS place_set_updated_at ON place;
CREATE TRIGGER place_set_updated_at BEFORE UPDATE ON place
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- person
--   * profile_media_id FK is added in 0002 (after `media` exists).
--   * source_summary is RETAINED as a transitional/legacy free-text field
--     (most FS-ingested people only have provenance here, not yet in
--     citations). Do NOT write new provenance here — use source/citation.
--     v_source_summary (0003) is the forward, computed replacement.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS person (
  person_id         text PRIMARY KEY,               -- 'P-0056'
  primary_name      text NOT NULL,
  sex               text CHECK (sex IN ('male','female','unknown')),
  birth_date        text,                           -- genealogical dates stay fuzzy (text + granularity)
  birth_granularity text CHECK (birth_granularity IN ('day','month','year','decade','circa')),
  birth_place_id    text REFERENCES place(place_id),
  death_date        text,
  death_granularity text CHECK (death_granularity IN ('day','month','year','decade','circa')),
  death_place_id    text REFERENCES place(place_id),
  life_confidence   text CHECK (life_confidence IN ('high','med','low')),
  privacy_level     text NOT NULL DEFAULT 'public' CHECK (privacy_level IN ('public','private')),
  branch            text,
  fs_id             text,                           -- FamilySearch PID (identity anchor)
  notes             text,
  profile_media_id  text,                           -- FK added in 0002
  source_summary    text,                           -- LEGACY/transitional (see note above)
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS person_fs_id_ix       ON person (fs_id);
CREATE INDEX IF NOT EXISTS person_birth_place_ix ON person (birth_place_id);
CREATE INDEX IF NOT EXISTS person_death_place_ix ON person (death_place_id);

DROP TRIGGER IF EXISTS person_set_updated_at ON person;
CREATE TRIGGER person_set_updated_at BEFORE UPDATE ON person
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- event   (legacy single-valued Events.PID_People is dropped; every
--          participant goes through event_participant)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS event (
  event_id         text PRIMARY KEY,                -- 'E-0213'
  title            text,
  event_type       text REFERENCES event_type(code),
  date_start       text,
  date_end         text,
  date_granularity text,
  place_id         text REFERENCES place(place_id),
  importance       int,
  confidence       text CHECK (confidence IN ('high','med','low')),
  description      text,
  privacy_level    text NOT NULL DEFAULT 'public' CHECK (privacy_level IN ('public','private')),
  notes            text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS event_place_ix ON event (place_id);
CREATE INDEX IF NOT EXISTS event_type_ix  ON event (event_type);

DROP TRIGGER IF EXISTS event_set_updated_at ON event;
CREATE TRIGGER event_set_updated_at BEFORE UPDATE ON event
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- event_participant  (M:N person <-> event)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS event_participant (
  id        bigserial PRIMARY KEY,
  event_id  text NOT NULL REFERENCES event(event_id) ON DELETE CASCADE,
  person_id text NOT NULL REFERENCES person(person_id),
  role      text,                                   -- self|spouse|child|head_of_household|witness|...
  UNIQUE (event_id, person_id, role)
);
CREATE INDEX IF NOT EXISTS event_participant_person_ix ON event_participant (person_id);

-- ---------------------------------------------------------------------
-- relationship  (person <-> person). Convention: "A is <relation> of B"
--   parent : A is parent of B
--   spouse : symmetric
--   sibling: symmetric
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS relationship (
  rel_id        text PRIMARY KEY,                   -- 'R-0130'
  person_id_a   text NOT NULL REFERENCES person(person_id),
  relation      text NOT NULL REFERENCES relation_type(code),
  person_id_b   text NOT NULL REFERENCES person(person_id),
  start_date    text,
  end_date      text,
  evidence_note text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS relationship_a_ix ON relationship (person_id_a);
CREATE INDEX IF NOT EXISTS relationship_b_ix ON relationship (person_id_b);

DROP TRIGGER IF EXISTS relationship_set_updated_at ON relationship;
CREATE TRIGGER relationship_set_updated_at BEFORE UPDATE ON relationship
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
