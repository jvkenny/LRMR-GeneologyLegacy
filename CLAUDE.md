# LRGDM — Operating Guide for Claude Code

This file orients a fresh Claude Code session to the repo. It's the answer to
"what is this thing, what's the data model, and what should I do here."

> **This repo is Postgres-first.** The source of truth is the **Postgres/PostGIS
> database `lrgdm`** (migrated 2026-05-30). Every script reads and writes
> Postgres. The legacy GeoPackage is a frozen pre-migration snapshot under
> `backup_gpkg/` — kept for history, never the live data.

## What this repo is

**LRGDM** = Long Range Genealogy Data Model. John Kenny's personal family
history. Edited in QGIS against Postgres, exported to GeoJSON for a Leaflet
viewer published via GitHub Pages.

- **Repo:** https://github.com/jvkenny/LRMR-GeneologyLegacy
- **Source of truth:** Postgres db **`lrgdm`** (local, `localhost:5432`; app role `lrgdm_rw`)
- **Schema & setup:** `db/README.md` + `db/migrations/0001…0006` (+ `db/load_from_gpkg.sql` ETL)
- **Backups:** `pg_dump` snapshots in `db/backups/*.sql` (committed)
- **Viewer:** `docs/index.html` (Leaflet, GH Pages), fed by `docs/data/*.geojson`
- **Proband:** John Kenny, FamilySearch PID **L274-KNT** (b. 1995)
- **QGIS project:** `~/dev/bwca-trip-2026/qgis/project/LRGDM.qgz` — connect it to the `lrgdm` Postgres connection
- **Legacy snapshot:** `backup_gpkg/lrgdm-legacy-2026-05-30.gpkg` (Git LFS) — frozen pre-migration GeoPackage; never the live data

## Data model (Postgres)

Full DDL in `db/migrations/`. Human keys (`P-####`, `PL-####`, `E-####`, …)
stay as primary keys. Genealogical dates stay fuzzy (text + `*_granularity`).
**FKs are enforced** (the GPKG's were not).

**Core entities:** `person`, `place` (geometry(Point,4326)), `event`,
`event_participant` (M:N person↔event — the legacy single-valued
`Events.PID_People` is gone), `relationship`.

**Names:** `person_name` (alternate / maiden / married / nickname / variant).
`person.primary_name` stays as the display name.

**Provenance:** `source` (a record in the world) → `citation` (source ↔ a
specific claim, polymorphic target with a trigger-enforced FK, carries
confidence + conflict flag). Replaces free-text `source_summary` blobs
(`person.source_summary` is retained transitional/legacy — don't write new
provenance there).

**Media:** `media` (file on disk under `media/`, Git LFS; path + sha256) ↔
`media_link` (attach to person/event/place/source).

**Content:** `narrative` (published biography, from dossier §5),
`research_lead` (dossier §6 open leads as trackable rows).

**Vocab lookups:** `event_type`, `relation_type`, `source_type`, and `era`
(single source of truth for era boundaries/labels — `lrgdm_era()` reads it).

**Derived map layers are live SQL views** (`v_birth_location_points`,
`v_death_location_points`, `v_birth_to_death_lines`,
`v_birth_to_death_lines_eras`, `v_person_locations`, `v_event_points`, plus
`v_source_summary`, `v_citations_expanded`). They recompute automatically —
**there is no rebuild step** (the old `cleanup_model.py` Stage C is obsolete).
Edit base tables in QGIS; views (read-only) update live.

## Build & deploy the public site

The DB is local-only, so the site is built **locally** and committed (no CI
data step — `.github/workflows/build-data.yml` was removed):

```sh
scripts/build_site.sh        # export_geojson.py + generate_narratives.py, both from Postgres
git add docs && git commit && git push   # GitHub Pages serves the committed docs/
```

Python deps: `psycopg` (`requirements.txt`; Homebrew python is PEP-668 — install
with `--break-system-packages` or a venv). Conninfo via `$LRGDM_PG` (default
`dbname=lrgdm`).

## Scripts (`scripts/`)

All scripts connect through `scripts/lrgdm_db.py` (`$LRGDM_PG`, default
`dbname=lrgdm`). Every one reads/writes **Postgres**. Writers default to
dry-run; pass `--apply` to commit. Run `scripts/backup_db.sh` first for a
`pg_dump` snapshot.

| Script | Purpose |
|---|---|
| `export_geojson.py` | Postgres → `docs/data/*.geojson` (+ manifest, people_all). |
| `generate_narratives.py` | Dossiers + Postgres → `docs/narratives/*.html` + index. |
| `build_site.sh` | Runs both of the above (local site rebuild). |
| `add_media.py` | Add a scan/photo, record + link it (`media`/`media_link`). |
| `parse_dossiers.py` | Dossiers → `source`/`citation`/`narrative`/`research_lead`. |
| `apply_deep_dive.py` | Apply a deep-dive dossier's patches, then backfill provenance via `parse_dossiers`. |
| `ingest_familysearch.py` | Ingest a FamilySearch extract (new `person`/`place` rows). |
| `reconcile_familysearch.py` | Propose `fs_id` matches from an FS extract (read-only). |
| `auto_geocode.py` | Geocode places + fill person birth/death place refs from the FS extract. |
| `auto_branch.py` | Assign `branch` from FS lineage + Relationships. |
| `fix_validation.py` | Safe DQ fixes (geocode_quality, branch backfill). |
| `merge_duplicate_persons.py` | Merge duplicate `person` rows (repoint refs, delete loser). |
| `validate_gpkg.py` | DQ checks → `reports/validation_<DATE>.md` (read-only). Name kept for back-compat; reads Postgres. |
| `next_mining_batch.py` | Pick deceased ancestors to web-mine (read-only). |
| `backup_db.sh` | `pg_dump` snapshot → `db/backups/`. |

Note: the `lrgdm-deep-dive` / `lrgdm-data-quality` / `lrgdm-ingest-fs` /
`lrgdm-pedigree-walk` **skills** invoke these (now Postgres) scripts. The
SKILL.md prose may still mention GPKG/`.bak` conventions — the scripts do the
right thing; treat the prose as advisory until those docs are refreshed.

## FamilySearch refresh

Use the **`lrgdm-pedigree-walk`** skill: open
`https://www.familysearch.org/en/tree/pedigree/landscape/L274-KNT` in the Chrome
MCP browser (logged in as JohnKenny1); it fetches ~132 ancestors via FS's JSON
endpoints to `~/Downloads`; an osascript bypass moves the file into
`src/data/familysearch/` (Bash is sandboxed off `~/Downloads`);
`reconcile_familysearch.py` proposes matches, then `ingest_familysearch.py`
adds new ancestors **to Postgres**.

## Scheduled automation

**Weekly remote routine** ([trig_01Ad4ZrnyND8NWYg89LrjDRb](https://claude.ai/code/routines/trig_01Ad4ZrnyND8NWYg89LrjDRb),
Tue 21:00 America/Chicago, Anthropic cloud): web-mines 5 ancestors, writes
`reports/web_mentions/<person_id>.md`, opens a PR. **The cloud has no access to
the local Postgres**, so it can't read the live tree — it needs rethinking
(hosted DB, or a committed read-only export). Treat its picks as advisory.

**Monthly local reminder** (launchd `com.lrgdm.monthly-refresh-reminder.plist`,
1st @ 09:00) posts an ntfy push to topic `lrgdm` on the hurricane Pi
(http://100.126.34.16:8091/lrgdm) reminding John to run the pedigree refresh.
Restart: `launchctl bootout/bootstrap gui/$(id -u) <plist>`.

## Current state (Postgres, 2026-05-30)

- person **145** · place **199** (99 with notes) · event **211** · event_participant **221** · relationship **37**
- source **48** · citation **75** · narrative **4** · research_lead **84** · person_name **145** · era **7**
- 4 deep-dive dossiers ingested (P-0036, P-0056, P-0059, P-0072)
- FKs enforced; 0 broken references after ETL

## What's next

1. **June 7 records scan** → drop images/scans via `add_media.py`; add maiden/nickname rows to `person_name`.
3. **Photo overlay in the viewer** — surface `media`/`media_link` portraits in `docs/index.html` popups.
4. **Branch assignment** for NULL-branch ancestors; **dedup** remaining duplicate persons (now via SQL against Postgres).
5. **Time-slicing view** — parameterized year filter over the `v_*` layers.

## Key invariants — do not break

- **Postgres `lrgdm` is the source of truth.** The GPKG is frozen; don't edit it expecting the site/DB to follow.
- Edit base tables (in QGIS or SQL); **never edit the `v_*` views** (read-only, recomputed).
- Rebuild the site with `scripts/build_site.sh`, then commit `docs/` — do not hand-edit `docs/data/*.geojson`.
- **Back up with `pg_dump`** to `db/backups/` and commit it (the data is no longer a file in git).
- Never `git push --force` to main (it desyncs the published viewer).
- `media/**` binaries are **Git LFS**-tracked (see `.gitattributes`).

## Memory / context for Claude

Project memory: `~/.claude/projects/-Users-john-dev/memory/project_lrgdm.md` and
`project_lrgdm_postgres_migration.md`. Skills (their scripts now run on
Postgres): `lrgdm-pedigree-walk`, `lrgdm-data-quality`, `lrgdm-deep-dive`,
`lrgdm-ingest-fs`.
