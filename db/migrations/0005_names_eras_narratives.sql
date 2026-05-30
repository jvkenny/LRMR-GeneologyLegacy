-- =====================================================================
-- LRGDM 0005 — person_name, era, narrative, research_lead
--
-- Fills four gaps the GPKG model never had:
--  * person_name   — alternate / maiden / married / nickname / variant names
--                    (primary_name was a single text field; maiden names and
--                    nicknames were being lost).
--  * era           — single source of truth for era boundaries+labels. The
--                    boundaries are the CANONICAL ones from export_geojson.py
--                    (ERAS), and lrgdm_era() is rewritten to read this table,
--                    so the SQL views and the public-site export can no longer
--                    drift. (The *assignment rule* — "the era you belonged to =
--                    the year you turned 25" — stays in export code; this table
--                    fixes only the boundary/label definitions.)
--  * narrative     — the published biography as DB content (authored in the
--                    deep-dive dossier §5; parse_dossiers.py fills body_md).
--  * research_lead — dossier §6 "Open leads" as trackable rows.
--
-- Run:  psql lrgdm -f db/migrations/0005_names_eras_narratives.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- person_name  (person.primary_name stays as the denormalized display name)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS person_name (
  id         bigserial PRIMARY KEY,
  person_id  text NOT NULL REFERENCES person(person_id) ON DELETE CASCADE,
  name_type  text NOT NULL CHECK (name_type IN
               ('primary','birth','married','maiden','nickname','alias','variant')),
  value      text NOT NULL,
  is_primary boolean NOT NULL DEFAULT false,
  notes      text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (person_id, name_type, value)
);
CREATE INDEX IF NOT EXISTS person_name_person_ix ON person_name (person_id);
CREATE INDEX IF NOT EXISTS person_name_value_ix  ON person_name (lower(value));

-- backfill: one 'primary' row per person from the existing primary_name
INSERT INTO person_name (person_id, name_type, value, is_primary)
  SELECT person_id, 'primary', primary_name, true
  FROM person
  ON CONFLICT (person_id, name_type, value) DO NOTHING;

-- ---------------------------------------------------------------------
-- era  (single source of truth; boundaries = export_geojson.py ERAS,
--       right-open intervals: year_start <= yr < year_end)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS era (
  code       text PRIMARY KEY,
  label      text NOT NULL,
  year_start int,                 -- NULL = open lower bound
  year_end   int,                 -- NULL = open upper bound (exclusive)
  sort_order int NOT NULL
);

INSERT INTO era (code, label, year_start, year_end, sort_order) VALUES
  ('colonial',           'Colonial Era',                    NULL, 1788, 1),
  ('early_republic',     'Early Republic',                  1788, 1830, 2),
  ('civil_war',          'Civil War & Reconstruction',      1830, 1865, 3),
  ('gilded_age',         'Gilded Age',                      1865, 1900, 4),
  ('progressive_wwi',    'Progressive Era & WWI',           1900, 1920, 5),
  ('roaring_depression', 'Roaring 20s & Great Depression',  1920, 1940, 6),
  ('modern',             'Modern',                          1940, NULL, 7)
ON CONFLICT (code) DO NOTHING;

-- Rewrite lrgdm_era() to read the table (was a hardcoded CASE in 0003).
-- STABLE (not IMMUTABLE) because it now reads a table.
CREATE OR REPLACE FUNCTION lrgdm_era(yr int) RETURNS text
  LANGUAGE sql STABLE AS $$
  SELECT label FROM era
  WHERE yr IS NOT NULL
    AND (year_start IS NULL OR yr >= year_start)
    AND (year_end   IS NULL OR yr <  year_end)
  ORDER BY sort_order
  LIMIT 1;
$$;

-- ---------------------------------------------------------------------
-- narrative  (one current published biography per person; latest supersedes)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS narrative (
  person_id     text PRIMARY KEY REFERENCES person(person_id) ON DELETE CASCADE,
  dossier_date  date,
  body_md       text,            -- authored in dossier §5; parse_dossiers.py fills this
  rendered_html text,            -- optional cached render
  published     boolean NOT NULL DEFAULT true,
  updated_at    timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS narrative_set_updated_at ON narrative;
CREATE TRIGGER narrative_set_updated_at BEFORE UPDATE ON narrative
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- research_lead  (dossier §6 "Open leads" as trackable rows)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS research_lead (
  id             bigserial PRIMARY KEY,
  person_id      text REFERENCES person(person_id) ON DELETE CASCADE,  -- NULL = general
  category       text,           -- record | person | cross_skill | paywall | other
  description    text NOT NULL,
  status         text NOT NULL DEFAULT 'open'
                   CHECK (status IN ('open','in_progress','done','dropped')),
  source_dossier text,           -- 'P-0056'
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS research_lead_person_ix ON research_lead (person_id);
CREATE INDEX IF NOT EXISTS research_lead_status_ix ON research_lead (status);

DROP TRIGGER IF EXISTS research_lead_set_updated_at ON research_lead;
CREATE TRIGGER research_lead_set_updated_at BEFORE UPDATE ON research_lead
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
