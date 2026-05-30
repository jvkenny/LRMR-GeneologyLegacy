-- =====================================================================
-- LRGDM 0002 — Sources, Citations, Media
--
-- The maturity layer. `source` = a record that exists in the world
-- (census, certificate, obituary, FindAGrave memorial, oral interview).
-- `citation` ties a source to a SPECIFIC claim (a person field, an event,
-- a place, a relationship) with its own confidence + conflict flag — this
-- is the per-fact provenance that today only lives in the deep-dive
-- dossiers. `media` = a digital artifact (scan/photo/PDF) stored on disk;
-- `media_link` attaches it to a source (the scan OF a certificate), a
-- person (a portrait), an event, or a place.
--
-- Citation targeting is POLYMORPHIC (subject_type, subject_id,
-- subject_field). A CHECK constrains subject_type; referential integrity
-- of subject_id is enforced by trigger (Postgres can't FK polymorphically).
-- If you later prefer hard FKs, swap to per-type junctions
-- (person_citation, event_citation, ...) — the view layer hides the choice.
--
-- Run:  psql lrgdm -f db/migrations/0002_sources_media.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- source
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS source (
  source_id     text PRIMARY KEY,                   -- 'S-0001'
  source_type   text REFERENCES source_type(code),  -- census|vital_record|obituary|findagrave|
                                                     -- ssdi|numident|oral_history|newspaper|book|
                                                     -- website|photo|military|marriage_record|...
  title         text NOT NULL,                       -- '1950 US Census — Cicero, ED 104-1'
  informant     text,                                -- e.g. 'John Kenny' for oral history
  repository    text,                                -- 'FamilySearch','DuPage County Recorder',...
  url           text,                                -- ark / memorial / obituary link
  citation      text,                                -- full Evidence-Explained-style citation
  source_date   text,                                -- date the record documents (fuzzy ok)
  accessed_date date,                                -- when it was retrieved
  confidence    text CHECK (confidence IN ('high','med','low')),
  notes         text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS source_type_ix ON source (source_type);

DROP TRIGGER IF EXISTS source_set_updated_at ON source;
CREATE TRIGGER source_set_updated_at BEFORE UPDATE ON source
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- citation  (source -> a specific claim)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS citation (
  citation_id    bigserial PRIMARY KEY,
  source_id      text NOT NULL REFERENCES source(source_id) ON DELETE CASCADE,
  subject_type   text NOT NULL CHECK (subject_type IN ('person','event','place','relationship')),
  subject_id     text NOT NULL,                      -- 'P-0056' / 'E-0213' / 'PL-5244' / 'R-0130'
  subject_field  text,                               -- 'birth_date','death_place',... NULL = whole record
  claim          text,                               -- 'Born 18 Jul 1934, Chicago'
  confidence     text CHECK (confidence IN ('high','med','low')),
  conflicts_flag boolean NOT NULL DEFAULT false,     -- dossier's "Conflicts with GPKG?" column
  locator        text,                               -- 'ED 104-1, line 1', page no., etc.
  created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS citation_subject_ix ON citation (subject_type, subject_id);
CREATE INDEX IF NOT EXISTS citation_source_ix  ON citation (source_id);

-- Polymorphic referential integrity for citation.subject_id.
CREATE OR REPLACE FUNCTION citation_subject_fk() RETURNS trigger AS $$
DECLARE ok boolean;
BEGIN
  EXECUTE format(
    'SELECT EXISTS(SELECT 1 FROM %I WHERE %I = $1)',
    CASE NEW.subject_type
      WHEN 'person' THEN 'person' WHEN 'event' THEN 'event'
      WHEN 'place'  THEN 'place'  WHEN 'relationship' THEN 'relationship' END,
    CASE NEW.subject_type
      WHEN 'person' THEN 'person_id' WHEN 'event' THEN 'event_id'
      WHEN 'place'  THEN 'place_id'  WHEN 'relationship' THEN 'rel_id' END)
  INTO ok USING NEW.subject_id;
  IF NOT ok THEN
    RAISE EXCEPTION 'citation.subject_id % not found in % table', NEW.subject_id, NEW.subject_type;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS citation_subject_fk_trg ON citation;
CREATE TRIGGER citation_subject_fk_trg BEFORE INSERT OR UPDATE ON citation
  FOR EACH ROW EXECUTE FUNCTION citation_subject_fk();

-- ---------------------------------------------------------------------
-- media  (file lives on disk / object store; DB holds metadata + path)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS media (
  media_id      text PRIMARY KEY,                    -- 'M-0001'
  media_type    text CHECK (media_type IN ('image','scan','pdf','audio','video')),
  title         text,
  caption       text,
  file_path     text,                                -- 'media/P-0056/headstone.jpg' or S3 key
  url           text,                                -- if externally hosted
  mime_type     text,
  sha256        text,                                -- integrity / dedupe
  bytes         bigint,
  captured_date text,                                -- genealogical date the artifact was made
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS media_sha256_ix ON media (sha256);

DROP TRIGGER IF EXISTS media_set_updated_at ON media;
CREATE TRIGGER media_set_updated_at BEFORE UPDATE ON media
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- media_link  (M:N media <-> person|event|place|source)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS media_link (
  id           bigserial PRIMARY KEY,
  media_id     text NOT NULL REFERENCES media(media_id) ON DELETE CASCADE,
  subject_type text NOT NULL CHECK (subject_type IN ('person','event','place','source')),
  subject_id   text NOT NULL,
  role         text,                                 -- portrait|document_scan|headstone|gallery
  sort_order   int NOT NULL DEFAULT 0,
  UNIQUE (media_id, subject_type, subject_id, role)
);
CREATE INDEX IF NOT EXISTS media_link_subject_ix ON media_link (subject_type, subject_id);

-- ---------------------------------------------------------------------
-- Now that media exists, wire person.profile_media_id -> media.
-- ---------------------------------------------------------------------
ALTER TABLE person
  DROP CONSTRAINT IF EXISTS person_profile_media_fk,
  ADD  CONSTRAINT person_profile_media_fk
       FOREIGN KEY (profile_media_id) REFERENCES media(media_id);
