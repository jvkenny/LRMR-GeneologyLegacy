# LRGDM Enrichment Scripts

Local tooling for keeping the LRGDM family-history data healthy and growing.

**The source of truth is the Postgres/PostGIS database `lrgdm`** (migrated
2026-05-30). Every script reads and writes Postgres through
`scripts/lrgdm_db.py` (`connect()`), which reads its conninfo from `$LRGDM_PG`
(default `dbname=lrgdm`). The GeoPackage under `backup_gpkg/` is a frozen
pre-migration snapshot — never the live data.

See the repo-root `CLAUDE.md` for the full data model and architecture.

## Conventions

- **Writers are dry-run by default.** They emit a markdown/JSON proposal to
  `reports/` and only mutate Postgres when you pass `--apply`.
- **Back up first.** Run `scripts/backup_db.sh` for a `pg_dump` snapshot into
  `db/backups/` before any `--apply`.
- **Derived map layers are live SQL views** (`v_birth_location_points`,
  `v_birth_to_death_lines`, etc.). They recompute automatically — there is **no
  rebuild step**.
- The public site is built **locally** and committed (no CI data step). Run
  `scripts/build_site.sh`, then commit `docs/`.

## Scripts

| Script | Purpose |
|---|---|
| `lrgdm_db.py` | Shared `connect()` helper — every script's Postgres entry point (`$LRGDM_PG`). |
| `export_geojson.py` | Postgres → `docs/data/*.geojson` (+ manifest, people_all). |
| `generate_narratives.py` | Deep-dive dossiers + Postgres → `docs/narratives/*.html` + index. |
| `build_site.sh` | Runs `export_geojson.py` + `generate_narratives.py` (local site rebuild). |
| `add_media.py` | Record a scan/photo and link it (`media` / `media_link`). |
| `parse_dossiers.py` | Dossiers → `source` / `citation` / `narrative` / `research_lead`. |
| `apply_deep_dive.py` | Apply a deep-dive dossier's patches, then backfill provenance via `parse_dossiers`. |
| `ingest_familysearch.py` | Ingest a FamilySearch extract (new `person` / `place` rows). |
| `reconcile_familysearch.py` | Propose `fs_id` matches from an FS extract (read-only). |
| `auto_geocode.py` | Geocode places + fill person birth/death place refs from the FS extract. |
| `auto_branch.py` | Assign `branch` from FS lineage + `relationship` rows. |
| `fix_validation.py` | Safe DQ fixes (geocode_quality, branch backfill). |
| `merge_duplicate_persons.py` | Merge duplicate `person` rows (repoint refs, delete loser). |
| `validate_gpkg.py` | DQ checks → `reports/validation_<DATE>.md` (read-only). Name kept for back-compat; reads Postgres. |
| `next_mining_batch.py` | Pick deceased ancestors to web-mine (read-only). |
| `backup_db.sh` | `pg_dump` snapshot → `db/backups/`. |

## Typical workflows

```sh
# Validate the database
python3 scripts/validate_gpkg.py            # → reports/validation_<DATE>.md

# Apply safe data-quality fixes (dry-run first, then commit)
python3 scripts/fix_validation.py           # preview
scripts/backup_db.sh                        # snapshot before writing
python3 scripts/fix_validation.py --apply   # commit to Postgres

# Grow the tree from a FamilySearch extract
python3 scripts/reconcile_familysearch.py   # propose fs_id matches (read-only)
python3 scripts/ingest_familysearch.py      # preview new person/place rows
python3 scripts/ingest_familysearch.py --apply

# Rebuild and publish the public site
scripts/build_site.sh
git add docs && git commit && git push
```

## FamilySearch refresh

The FamilySearch pedigree scrape is manual/local because it needs an
authenticated browser — invoke the `lrgdm-pedigree-walk` skill from a Claude
Code session on John's Mac. It writes `src/data/familysearch/extract_*.json`,
which `reconcile_familysearch.py`, `ingest_familysearch.py`, `auto_geocode.py`,
and `auto_branch.py` consume.
