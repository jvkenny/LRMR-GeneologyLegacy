# LRGDM — Postgres/PostGIS

Migration target for the LRGDM data model: from the single GeoPackage
(`src/data/lrgdm.gpkg`) to a real Postgres/PostGIS database, primarily to
get a normalized **sources + media** model (the GPKG had neither). The
Leaflet/GitHub-Pages viewer is unchanged — it still reads GeoJSON, now
exported from Postgres.

See also: `~/.claude/.../memory/project_lrgdm_postgres_migration.md`.

## Layout

```
db/
  migrations/
    0001_core.sql          entities + vocab tables + PostGIS geometry
    0002_sources_media.sql  source, citation (polymorphic), media, media_link
    0003_views.sql          derived spatial views (replace cleanup_model Stage C) + provenance views
    0004_seed_lookups.sql   seed event_type / relation_type / source_type
    0005_names_eras_narratives.sql  person_name, era, narrative, research_lead (+ table-driven lrgdm_era)
    0006_place_extra_cols.sql       restore place.historical_name/notes/time_valid_*
  load_from_gpkg.sql        one-time ETL: staging (ogr2ogr) -> normalized schema
  backups/                  pg_dump snapshots (versioning, since the DB isn't a file in git)
  README.md
```

Related scripts (`../scripts/`): `export_geojson.py` (PG → docs/data GeoJSON),
`generate_narratives.py` (dossiers + PG → docs/narratives), `build_site.sh`
(runs both), `add_media.py` (add a scan/photo + link it), `parse_dossiers.py`
(dossiers → source/citation/narrative/research_lead).

## Schema at a glance

- **Entities:** `person`, `place` (geometry), `event`, `event_participant` (M:N), `relationship`.
- **Names:** `person_name` — alternate / maiden / married / nickname / variant (primary_name stays as the display name).
- **Provenance:** `source` (a record in the world) → `citation` (source ↔ a specific claim, with confidence + conflict flag) — replaces free-text `source_summary` blobs.
- **Media:** `media` (file on disk; path + sha256) ↔ `media_link` (attach to person/event/place/source).
- **Content:** `narrative` (published biography, from dossier §5), `research_lead` (dossier §6 open leads as trackable rows).
- **Vocab:** `event_type`, `relation_type`, `source_type`, and `era` (single source of truth for era boundaries/labels — `lrgdm_era()` reads it).
- **Derived = views:** `v_birth_location_points`, `v_death_location_points`, `v_birth_to_death_lines`, `v_birth_to_death_lines_eras`, `v_person_locations`, `v_event_points` — live, no rebuild step. Plus `v_source_summary`, `v_citations_expanded`.

Design notes: human keys (`P-`/`PL-`/`E-`/…) stay as PKs (dossiers reference them); genealogical dates stay fuzzy (text + granularity); citation targeting is polymorphic with a trigger-enforced FK. `person.source_summary` is retained as a transitional/legacy field — new provenance goes through `source`/`citation`.

## Create the database

```bash
# macOS: Postgres.app (bundles PostGIS) is easiest; or Homebrew:
#   brew install postgresql@16 postgis && brew services start postgresql@16

createdb lrgdm
psql lrgdm -c "CREATE EXTENSION postgis;"

# (optional) app role for scripts + QGIS, instead of the superuser
psql lrgdm -c "CREATE ROLE lrgdm_rw LOGIN PASSWORD 'change-me';"
psql lrgdm -c "GRANT ALL ON SCHEMA public TO lrgdm_rw;"

# run migrations in order
for f in db/migrations/*.sql; do psql lrgdm -f "$f"; done
```

## Load existing data from the GPKG

```bash
ogr2ogr -f PostgreSQL PG:"dbname=lrgdm" src/data/lrgdm.gpkg \
        -lco SCHEMA=staging -lco LAUNDER=YES \
        People Places Events EventParticipants Relationships

psql lrgdm -f db/load_from_gpkg.sql
# sanity-check counts (see bottom of that file), then:
psql lrgdm -c "DROP SCHEMA staging CASCADE;"
```

`source`/`citation`/`media` start empty — backfill `source`/`citation` from
the existing deep-dive dossiers (a `parse_dossiers.py`, TBD; P-0056 is the
cleanest first case), and `media` from the June 7 scans.

## Hook up QGIS

1. **Layer → Data Source Manager → PostgreSQL → New** — host `localhost`,
   port `5432`, db `lrgdm`, user `lrgdm_rw` (store the password in QGIS's
   encrypted auth DB, not plaintext). Test Connect.
2. Add **`place`** (the editable geometry layer) plus non-spatial
   `person`/`event` for attribute editing.
3. Add the **`v_*` views** as map layers. For each view: set its **feature
   id** column (`person_id`/`event_id`) in the Add-layers dialog, and QGIS
   will pick up `geom` (4326). Views are **read-only** (expected) — edit the
   base tables and the views update automatically.
4. Re-apply your QML styles (or save default styles to the DB).
5. Point `LRGDM.qgz` at the Postgres connection instead of the `.gpkg`.

## Build & deploy the public site

`export_geojson.py` and `generate_narratives.py` now read **Postgres**
(`$LRGDM_PG`, default `dbname=lrgdm`). Because the DB is local-only, the cloud
auto-export workflow (`.github/workflows/build-data.yml`) has been **removed** —
you rebuild locally, then commit & push (GitHub Pages just serves the committed
`docs/`):

```bash
scripts/build_site.sh        # export_geojson + generate_narratives from Postgres
git add docs && git commit && git push   # deploy
```

Needs `psycopg` (see `../requirements.txt`).

## Versioning / backup (replaces "GPKG-in-LFS")

The DB is no longer a file in git. Snapshot it into `db/backups/` and commit:

```bash
pg_dump -Fp --no-owner --exclude-table-data=spatial_ref_sys lrgdm \
  > db/backups/lrgdm_$(date +%Y%m%d).sql      # plain SQL, git-diffable
```

(`spatial_ref_sys` is the bulky PostGIS SRID table — excluded; the extension
recreates it.) The legacy `src/data/lrgdm.gpkg` is now a frozen historical
artifact, not the source of truth.
