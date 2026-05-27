# FS Ingest Proposal — 2026-05-26

- To-ingest People: **0**
- To-create Places: **0**
- People with `branch=NULL` after heuristic (need manual assignment): **0**
- Skipped: **132** (proband/spouse, already-linked via fs_id, or living)

## Branch heuristic

Surname → branch mapping is in `scripts/ingest_familysearch.py`. Mapped surnames:
`Reed` → `Paternal Reed`, `Talley` → `Paternal Reed`, `Willey` → `Paternal Reed`, `Thorla` → `Paternal Reed`, `Thorley` → `Paternal Reed`, `Dickerson` → `Paternal Reed`, `Cook` → `Paternal Reed`, `Bonham` → `Paternal Reed`, `Paulson` → `Paternal Reed`, `Paulsen` → `Paternal Reed`, `Poulson` → `Paternal Reed`, `Barnard` → `Paternal Reed`, `Dye` → `Paternal Reed`, `Allen` → `Paternal Reed`, `Lemley` → `Paternal Reed`, `Kenny` → `Paternal Kenny`, `Kroll` → `Paternal Kroll`, `Mariotti` → `Maternal Mariotti`, `Lambert` → `Maternal Lambert`, `Pouliot` → `Pouliot`, `Zika` → `Zika`, `Zíka` → `Zika`, `Niccolai` → `Maternal Mariotti`, `Porciani` → `Maternal Mariotti`, `Dini` → `Maternal Mariotti`, `Pagni` → `Maternal Mariotti`, `Spadoni` → `Maternal Mariotti`, `Giorgi` → `Maternal Mariotti`, `Lenzi` → `Maternal Mariotti`, `Bartoletti` → `Maternal Mariotti`, `Marchi` → `Maternal Mariotti`, `Lapini` → `Maternal Mariotti`, `NICCOLAI` → `Maternal Mariotti`, `PORCIANI` → `Maternal Mariotti`

## New People

| new id | name | sex | birth | death | branch | fs_id |
|---|---|---|---|---|---|---|

## Skipped

- `L274-KK8` Gerald Kenny — living (privacy)
- `PQCN-4WD` Celine Wysgalla — proband or spouse
- `L274-KLZ` Edward Kenny — already linked via fs_id
- `L274-K2C` Karen Reed - Kenny — living (privacy)
- `L274-KNT` John Kenny — proband or spouse
- `L274-KGR` Phyllis Kroll — already linked via fs_id
- `L274-KT7` Leah Rae Mariotti — already linked via fs_id
- `LY94-373` John Ronald Reed Sr — already linked via fs_id
- `L24Z-SFM` Laura Kroll — already linked via fs_id
- `LY94-DBH` Isabelle Harriet Zika — already linked via fs_id
- `PWPQ-D8V` Ugo Mariotti — already linked via fs_id
- `L278-SXK` Lena  A Dini — already linked via fs_id
- `KLGC-TLC` John Foulk Reed — already linked via fs_id
- `M3P5-XF6` Earl Wayne Reed Sr — already linked via fs_id
- `LMWG-K6F` Estella Gertrude Lambert — already linked via fs_id
- `L2XV-HRY` John Francis Zika — already linked via fs_id
- `GCKQ-RK3` Louis Dini — already linked via fs_id
- `GCKQ-6RJ` Zelinda Pagni — already linked via fs_id
- `PWPW-LPC` Leopoldo Mariotti — already linked via fs_id
- `LBHY-3B5` Beatrice Delina Pouliot — already linked via fs_id
- `PWP7-JQ8` Quintilia Lenzi — already linked via fs_id
- `L487-WDC` John Talley Reed — already linked via fs_id
- `KJP4-9R4` Elizabeth Willey — already linked via fs_id
- `2WFL-ZVT` Abiram Stacy Lambert — already linked via fs_id
- `GSQJ-M1C` Celestino Dini — already linked via fs_id
- `29WD-T9P` Helen Amelia Boles — already linked via fs_id
- `LKTC-D4S` Anton Zika — already linked via fs_id
- `MGNK-YL2` Henriette St. Louis — already linked via fs_id
- `LBH1-TK2` Josephine Riha Veta — already linked via fs_id
- `96JW-KX5` Paul Pouliot — already linked via fs_id
- _... and 102 more_