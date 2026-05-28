# People without map locations — 2026-05-27

After merging 14 duplicate persons, the viewer can plot 118 of 148 People as
birth points. The remaining **30 people** are missing from the map for two reasons:

## 20 people — no `birth_place_id` set (FS-ingested, place not parsed)

All ingested from FamilySearch on 2026-05-26. The FS portrait-pedigree endpoint
returned the names but no birth place, or the place couldn't be reconciled.
Action: scrape `/service/tree/tree-data/v8/person/{PID}/details` for each fs_id
and add a Places row + set birth_place_id.

| person_id | name | fs_id | birth |
|---|---|---|---|
| P-0054 | Phyllis Kroll | L274-KGR | 1931 |
| P-0057 | Laura Kroll | L24Z-SFM |  |
| P-0093 | Joseph Filiatrault dit St. Louis | GYV7-TRD |  |
| P-0097 | Henriette Cheffre | GYVW-44Y |  |
| P-0098 | Leopoldo Pagni | P7PW-CCK | about 1810 |
| P-0099 | Giovanni Dini | P355-XWC | 1803 |
| P-0101 | Piera Bellandi | PC4W-R8N | about 1815 |
| P-0102 | Pellegrino Giorgi | P7P4-8PM |  |
| P-0103 | Nancy Walls | K4BN-VM7 |  |
| P-0104 | Thomas Spear | K8F2-Y27 |  |
| P-0115 | Pietro Dini | P355-FRN |  |
| P-0116 | Elisabetta Giovacchini | P35T-Q4G |  |
| P-0117 | Pier Domenico Spadoni | GRLV-XZB | about 1774 |
| P-0118 | Maria Angiola Ercolini | GRLV-YDR | about 1780 |
| P-0119 | Annunziata Grossi | P99N-599 |  |
| P-0146 | Františka Doležalová | GWCT-1N1 | about 1730 |
| P-0147 | Antonín Zeman | GPDL-R79 |  |
| P-0149 | Eva Zemanová | GT5S-14P |  |
| P-0150 | Václav Říha | GPDL-25D |  |
| P-0152 | Magdalena Říhová | GT5S-PGJ |  |

## 10 people — `birth_place_id` orphaned (Place deleted)

Original (pre-FS-ingest) rows whose birth_place_id points to a Places row that
no longer exists (was deleted in a prior Places dedup pass). Action: look up
the place name in Events.notes (which preserves the original PL-####) or
manually re-geocode.

| person_id | name | branch | orphan place_id |
|---|---|---|---|
| P-0004 | Elizabeth (Willey) Reed | Paternal Reed by marriage | PL-0054 |
| P-0009 | David Lambert | Maternal Lambert | PL-0076 |
| P-0010 | Parmelia (Barnard) Lambert | Maternal Lambert | PL-0076 |
| P-0013 | Silas P. Boles | Maternal Lambert | PL-0076 |
| P-0016 | Lydia A. (Hopkins) Lambert | Maternal Lambert | PL-0076 |
| P-0018 | Permelia M. Oak | Maternal Lambert | PL-0076 |
| P-0025 | François Pouliot | Pouliot | PL-0076 |
| P-0027 | Joseph Filiatrault dit St. Louis | Pouliot | PL-0076 |
| P-0028 | Henriette (Cheffre) Filiatrault | Pouliot | PL-0076 |
| P-0035 | Emma Rebecca Reed | Paternal Reed | PL-0076 |
