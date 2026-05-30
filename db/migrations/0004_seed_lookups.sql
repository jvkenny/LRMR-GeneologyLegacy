-- =====================================================================
-- LRGDM 0004 — Seed controlled vocabularies
--
-- Seeds event_type / relation_type / source_type. ON CONFLICT DO NOTHING
-- so it's safe to re-run and safe alongside the ETL (load_from_gpkg.sql),
-- which also tops these up from whatever codes the GPKG actually contains.
--
-- Run:  psql lrgdm -f db/migrations/0004_seed_lookups.sql
-- =====================================================================

INSERT INTO event_type (code, label, description) VALUES
  ('birth',         'Birth',            'Birth event'),
  ('death',         'Death',            'Death event'),
  ('marriage',      'Marriage',         'Marriage / union'),
  ('divorce',       'Divorce',          'Dissolution of marriage'),
  ('residence',     'Residence',        'Place of residence at a point in time'),
  ('census',        'Census',           'Census enumeration'),
  ('immigration',   'Immigration',      'Arrival / passenger manifest'),
  ('naturalization','Naturalization',   'Citizenship / naturalization'),
  ('burial',        'Burial',           'Burial / interment'),
  ('baptism',       'Baptism',          'Baptism / christening'),
  ('occupation',    'Occupation',       'Employment / occupation'),
  ('military',      'Military service', 'Military service or enlistment'),
  ('education',     'Education',        'Schooling / enrollment'),
  ('custom',        'Custom',           'Other / uncategorised event'),
  ('other',         'Other',            'Other event')
ON CONFLICT (code) DO NOTHING;

INSERT INTO relation_type (code, label) VALUES
  ('parent',  'Parent of'),
  ('spouse',  'Spouse of'),
  ('sibling', 'Sibling of')
ON CONFLICT (code) DO NOTHING;

INSERT INTO source_type (code, label) VALUES
  ('census',             'Census'),
  ('vital_record',       'Vital record'),
  ('birth_certificate',  'Birth certificate'),
  ('death_record',       'Death record'),
  ('marriage_record',    'Marriage record'),
  ('obituary',           'Obituary'),
  ('findagrave',         'FindAGrave memorial'),
  ('ssdi',               'Social Security Death Index'),
  ('numident',           'SS NUMIDENT'),
  ('oral_history',       'Oral history / family testimony'),
  ('newspaper',          'Newspaper'),
  ('book',               'Book / compiled genealogy'),
  ('website',            'Website / online tree'),
  ('photo',              'Photograph'),
  ('military',           'Military record'),
  ('immigration',        'Immigration / passenger record'),
  ('naturalization',     'Naturalization record'),
  ('directory',          'City / business directory'),
  ('church_record',      'Church / parish record'),
  ('draft_registration', 'Draft / Selective Service registration'),
  ('other',              'Other')
ON CONFLICT (code) DO NOTHING;
