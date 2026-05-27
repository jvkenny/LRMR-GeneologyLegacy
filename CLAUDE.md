# LRGDM — Operating Guide for Claude Code

This file orients a fresh Claude Code session to the repo. It's the answer to
"what is this thing, what's the data model, and what should I do here."

## What this repo is

**LRGDM** = Long Range Genealogy Data Model. John Kenny's personal family
history, stored as a GeoPackage so it can be edited in QGIS and exported as
GeoJSON for a Leaflet viewer published via GitHub Pages.

- **Repo:** https://github.com/jvkenny/lrgdm
- **Source of truth:** `src/data/lrgdm_v2.gpkg`
- **Viewer:** `docs/index.html` (Leaflet, GH Pages)
- **Proband:** John Kenny, FamilySearch PID **L274-KNT** (b. 1995)
- **QGIS project:** `~/dev/bwca-trip-2026/qgis/project/LRGDM.qgz` *(lives outside
  this repo for legacy reasons)*

## Data model

The schema is **5 core attribute tables + 6 derived spatial layers**. After any
edit to a core table, regenerate the derived layers with
`scripts/cleanup_model.py --apply --skip-stage-b --skip-stage-d --skip-stage-e`
(which leaves only Stage C, the derived rebuild).

### Core tables (edit these)

| Table | What it stores |
|---|---|
| **People** | One row per known person. `person_id` (`P-####`), `primary_name`, `sex`, `birth_date`, `birth_place_id` → Places, `death_date`, `death_place_id` → Places, `branch`, `notes`, `fs_id` (FamilySearch PID), `source_summary`. |
| **Places** | One row per location. `place_id` (`PL-####`), `geom` (POINT WGS84), `name`, `std_name`, `lat` (REAL), `long` (REAL), `admin_hierarchy`, `geocode_quality`. |
| **Events** | Birth, death, marriage, residence, immigration, etc. `event_id` (`E-####`), `event_type`, `date_start`, `date_end`, `date_granularity`, `place_id` → Places, `PID_People` → People (still single-valued; multi-person events should use EventParticipants). |
| **EventParticipants** | Many-to-many for Events with multiple people (witnesses, parents-of, etc.). `event_id` × `person_id` × `role`. |
| **Relationships** | Person-to-person (spouse, parent_of, sibling). `rel_id`, `person_id_a` → People, `relation`, `person_id_b` → People, dates. |

### Derived layers (don't edit; regenerate)

All six are rebuilt by `scripts/cleanup_model.py` from the core tables.

| Layer | What it shows |
|---|---|
| `birth_location_points` | Point per person at birth_place, tagged with era. |
| `death_location_points` | Point per person at death_place, tagged with era. |
| `birth_to_death_lines` | Linestring per person from birth to death point. |
| `birth_to_death_lines_eras` | Same lines + era + birth/death years + mid_year. |
| `Person_Locations` | Every (person, place) pair from People + EventParticipants. |
| `Event_Points` | Every Event materialized at its Place. |

### Identity & FK rules

- `person_id`, `place_id`, `event_id`, `rel_id` all have UNIQUE indexes (added
  in the May 2026 cleanup). Inserts that collide will fail.
- `fs_id` on People is the canonical FamilySearch identity. When a person can
  be matched to the FS pedigree, set this — it becomes the merge anchor.
- Foreign keys are NOT enforced at the schema level (legacy). Run
  `scripts/validate_gpkg.py` to catch broken FKs.

## Scripts (`scripts/`)

| Script | Purpose | Writes to GPKG? |
|---|---|---|
| `validate_gpkg.py` | DQ checks → `reports/validation_<DATE>.md`. | no |
| `reconcile_familysearch.py` | Propose fs_id matches from FS extract → `reports/fs_reconciliation_<DATE>.{md,json}`. | no |
| `next_mining_batch.py` | Pick next 5 deceased ancestors to web-mine → stdout JSON. | no |
| `fix_validation.py` | Safe fixes: dedupe Places, set geocode_quality, backfill branch, null broken FKs. `--apply` to commit. | yes |
| `cleanup_model.py` | Drop stale layers, rebuild derived layers, tighten schema, add UNIQUE indexes. `--apply`. Stage flags to skip parts. | yes |
| `merge_duplicate_persons.py` | Merge known-duplicate People rows (kept-list is hardcoded). `--apply`. | yes |
| `MINER_PROMPT.md` | The prompt the weekly remote-routine miner uses. Read-only reference. | n/a |
| `README.md` | Top-level scripts doc. | n/a |

**Convention:** any script that writes to the GPKG must default to `--dry-run`
and require `--apply` to commit. Always `cp lrgdm_v2.gpkg lrgdm_v2.gpkg.bak`
before applying.

**SQLite/GPKG gotcha:** GeoPackage rtree triggers call `ST_IsEmpty()`, which
plain Python `sqlite3` doesn't expose. If a script needs to UPDATE non-geom
columns on Places, snapshot the rtree triggers, drop them, do the writes,
then recreate. `fix_validation.py` and `cleanup_model.py` already do this.

## Workflows

### Refresh the pedigree from FamilySearch

Use the **`lrgdm-pedigree-walk`** skill. Quick sketch:
1. Open `https://www.familysearch.org/en/tree/pedigree/landscape/L274-KNT`
   in the Chrome MCP browser (you must be logged in as JohnKenny1).
2. The skill kicks off a background fetch of 132 ancestors via FS's internal
   JSON endpoints, dedupes, downloads to `~/Downloads`.
3. The osascript bypass moves the file into `src/data/familysearch/`
   (Claude Code's Bash is sandboxed off `~/Downloads` on this Mac).
4. `python3 scripts/reconcile_familysearch.py` produces match proposals.

### Apply the proposed fs_id matches

Currently manual — open `reports/fs_reconciliation_<DATE>.md`, copy the
PIDs you accept, run UPDATEs directly. A future `apply_familysearch_matches.py`
will automate this.

### Validate + cleanup pass

```sh
python3 scripts/validate_gpkg.py                     # see findings
cp src/data/lrgdm_v2.gpkg src/data/lrgdm_v2.gpkg.bak # always
python3 scripts/fix_validation.py --apply            # safe fixes
python3 scripts/validate_gpkg.py                     # confirm reduction
```

### Regenerate derived spatial layers after editing core tables

```sh
python3 scripts/cleanup_model.py --apply \
    --skip-stage-b --skip-stage-d --skip-stage-e
```

This drops + recreates `birth_location_points`, `death_location_points`,
`birth_to_death_lines`, `birth_to_death_lines_eras`, `Person_Locations`,
`Event_Points`. The QGIS project will need a reload (or QGIS restart) to
pick them up if it's open.

## Scheduled automation

Two complementary scheduled tasks:

**Weekly remote routine** ([trig_01Ad4ZrnyND8NWYg89LrjDRb](https://claude.ai/code/routines/trig_01Ad4ZrnyND8NWYg89LrjDRb))
fires every **Tuesday 21:00 America/Chicago** in Anthropic's cloud and:
1. Runs the validator (commits `reports/validation_<DATE>.md`).
2. Picks 5 ancestors via `next_mining_batch.py`, web-searches each for obit /
   news / census mentions.
3. Writes `reports/web_mentions/<person_id>.md`.
4. Opens a PR titled `Weekly enrichment <DATE>`.

This routine runs in the cloud — it has no access to the local Chrome
session, so the FamilySearch scrape stays manual.

**Monthly local reminder** (launchd job
`~/Library/LaunchAgents/com.lrgdm.monthly-refresh-reminder.plist`) fires on
the **1st of every month at 09:00 America/Chicago** and posts an ntfy push to
the `lrgdm` topic on the hurricane Pi (http://100.126.34.16:8091/lrgdm). The
notification reminds John to:
1. Open Chrome, confirm logged into FamilySearch.
2. Ask Claude to run the `lrgdm-pedigree-walk` skill.
3. Follow with `lrgdm-ingest-fs` to merge any new ancestors.

The local job is just a reminder — actually invoking the skill requires John
to be in a Claude Code session, since the scrape and ingest are interactive.

Stop/restart the local job:
```sh
launchctl bootout  gui/$(id -u) ~/Library/LaunchAgents/com.lrgdm.monthly-refresh-reminder.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.lrgdm.monthly-refresh-reminder.plist
```

## Current state (May 2026 cleanup + ingest snapshot)

- People: **162** (48 from before, +114 ingested from FS extract on 2026-05-26)
- Places: **187** (101 + 86 new from ingest)
- Events: 191
- EventParticipants: 141
- Relationships: 36
- FS extract on disk: 132 ancestors of L274-KNT (8 generations)
- People with `fs_id` set: **129** out of the 132 FS pids
- Last validator run: **120 findings**
  - 56 People with `branch=NULL` (surname heuristic gaps — see
    `reports/ingest_proposal_<DATE>.md` for the list, bulk-assign manually)
  - 9 duplicate (name, birth year) pairs — FS persons that match existing
    GPKG rows which didn't yet have `fs_id` set. Resolve by extending
    `MERGES` in `scripts/merge_duplicate_persons.py` and running.
  - 11 orphan Places (down from 10 — most pre-ingest orphans now have owners)
  - 44 Events with `place_id` nulled out (broken FKs we honestly cleaned —
    each one has its original `PL-####` recorded in `Events.notes`)

## What's next

1. **Assign branches to the 56 NULL-branch ancestors.** Open
   `reports/ingest_proposal_<DATE>.md`, look at the "People needing branch
   assignment" section. Most are Czech (Říha, Zíka, Zemanová, etc. — likely
   Kroll paternal-grandmother lineage extending into Bohemia) or
   French-Canadian (Tremblay, Audet, Lapointe — probably Pouliot). Bulk-update
   via SQL or extend `SURNAME_BRANCH_MAP` in `scripts/ingest_familysearch.py`
   and re-run the ingest on a fresh extract.
2. **Merge the 9 new person dupes.** The ingest collided with existing GPKG
   rows that didn't have `fs_id`. Extend `MERGES` in
   `scripts/merge_duplicate_persons.py` with the new pairs. The fs-linked row
   should be the winner (consistent with prior dedup).
3. **Apply the reconciliation matches.** Open
   `reports/fs_reconciliation_<DATE>.md` and apply the high-confidence
   matches BEFORE the next FS ingest — otherwise we'll keep creating dupes
   on each ingest pass.
4. **Resolve the 44 nulled Events.** Each one has its original broken
   `PL-####` in `Events.notes`. Some are real places that were lost in a past
   dedup; some are events that no longer have a useful location. Manual.
5. **Photo overlay in the viewer.** FS extract gives `portraitUrl` per
   person; thread it into `docs/index.html` popups.
6. **Time-slicing view.** Parameterized year filter on the derived layers
   ("who was alive where in 1860?"). Pure SQL once the data is clean.

## Key invariants — do not break

- Never edit derived layers directly. They get blown away by the next
  cleanup_model run.
- Never UPDATE Places.geom without going through QGIS or a spatialite-aware
  pipeline. Python `sqlite3` can't keep the rtree consistent.
- Never `git push --force` to main — the GH workflow auto-exports GeoJSON
  on every push, and a force-push can desync the published viewer.
- `src/data/lrgdm_v2.gpkg` is **Git LFS-tracked**. `git lfs status` should
  show it as managed.

## Memory / context for Claude

Project memory: `~/.claude/projects/-Users-john-dev/memory/project_lrgdm.md`.
Skills: `~/.claude/skills/lrgdm-pedigree-walk/SKILL.md` and
`~/.claude/skills/lrgdm-data-quality/SKILL.md`.
