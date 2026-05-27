# LRGDM Validation — 2026-05-27

- GPKG: `src/data/lrgdm_v2.gpkg`
- Total findings: **181** *(carried forward — see note)*

## ⚠ Validation script did not run

`src/data/lrgdm_v2.gpkg` is tracked via Git LFS. In the cloud execution environment the
LFS proxy returns HTTP 502, so the binary could not be fetched and
`scripts/validate_gpkg.py` aborted with `sqlite3.DatabaseError: file is not a database`.

No changes to the GPKG have been committed since the baseline import
(`5473ffb`), so the finding counts below are carried forward verbatim from
`reports/validation_2026-05-26.md`. A fresh diff will appear in the next run
once LFS access is restored (or the GPKG is committed directly rather than via
LFS).

## Summary (carried forward from 2026-05-26)

| Section | Count |
|---|---:|
| People — missing required fields | 15 |
| People — birth/death date ordering | 0 |
| People — duplicate (name, birth year) pairs | 1 |
| People — fs_id linked to multiple rows | 0 |
| Places — coordinate problems | 0 |
| Places — low/missing geocode_quality | 111 |
| Places — not referenced by any person or event | 10 |
| Events — missing place_id or PID_People | 3 |
| Events — broken foreign keys | 41 |
| Events — date_start after date_end | 0 |
| Relationships — broken foreign keys | 0 |

*See `reports/validation_2026-05-26.md` for the full finding details.*
