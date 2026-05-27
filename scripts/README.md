# LRGDM Enrichment Scripts

Local + scheduled-remote tooling for keeping `src/data/lrgdm.gpkg` healthy and
growing. All scripts are read-only against the GPKG — any DB writes happen via a
separate `apply_*` step after the markdown report is reviewed.

## Inputs & outputs

```
src/data/lrgdm.gpkg              ← source of truth (GeoPackage / SQLite)
src/data/familysearch/extract_*.json ← raw FamilySearch dumps (see SKILL: lrgdm-pedigree-walk)
                ↓
scripts/validate_gpkg.py            → reports/validation_<DATE>.md
scripts/reconcile_familysearch.py   → reports/fs_reconciliation_<DATE>.{md,json}
scripts/next_mining_batch.py        → stdout JSON (consumed by the remote miner routine)
                ↓ (via remote routine, see scripts/MINER_PROMPT.md)
                                    → reports/web_mentions/<person_id>.md
```

## Scripts

### validate_gpkg.py
Runs ~10 consistency checks (missing fields, duplicate persons, broken FKs,
out-of-range coords, low geocode_quality, orphan places). Outputs a markdown
report. Default run:

```sh
python3 scripts/validate_gpkg.py
```

### reconcile_familysearch.py
Proposes `fs_id` matches for People rows that don't have one yet, by scoring
each row against the persons in the newest `src/data/familysearch/extract_*.json`.
Score = `0.6 * name_similarity + 0.4 * date_proximity`. Default run:

```sh
python3 scripts/reconcile_familysearch.py
```

### next_mining_batch.py
Picks the next batch of deceased People to mine for obituary / news / census
mentions. Prioritizes never-mined people, then oldest. Won't re-mine anything
touched within the last 30 days. Used by the remote-routine miner — see
[MINER_PROMPT.md](MINER_PROMPT.md).

```sh
python3 scripts/next_mining_batch.py --batch-size 5
```

## Scheduled execution

The validator and miner run weekly via a Claude Code remote routine (see
`https://claude.ai/code/routines`). The routine pulls the repo, runs both
scripts, commits the reports, and opens a PR. The FamilySearch scrape stays
manual / local because it requires an authenticated browser — invoke the
`lrgdm-pedigree-walk` skill from a Claude Code session on John's Mac.

## Migration path

When the FamilySearch Developer API key is provisioned (see task #8 in John's
working notes), the local Chrome scrape becomes optional. A future
`scripts/fetch_familysearch.py` will use OAuth and produce the same JSON
contract documented in `lrgdm-pedigree-walk`'s SKILL.md.
