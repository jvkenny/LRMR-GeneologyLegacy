-- =====================================================================
-- LRGDM 0006 — restore place columns the first ETL dropped
--
-- The GPKG Places table carried historical_name, notes, and a temporal
-- validity window (time_valid_from / time_valid_to) that 0001's place table
-- omitted. export_geojson.py emits historical_name + notes, and the temporal
-- columns are real genealogical data (when a place existed / was so named).
-- Add them back. load_from_gpkg.sql is updated to populate them on fresh
-- loads; for the already-loaded DB, backfill via ogr2ogr staging (see README).
--
-- Run:  psql lrgdm -f db/migrations/0006_place_extra_cols.sql
-- =====================================================================

ALTER TABLE place
  ADD COLUMN IF NOT EXISTS historical_name text,
  ADD COLUMN IF NOT EXISTS notes           text,
  ADD COLUMN IF NOT EXISTS time_valid_from text,
  ADD COLUMN IF NOT EXISTS time_valid_to   text;
