# LRGDM Validation — 2026-05-28

- GPKG: `src/data/lrgdm.gpkg`
- Total findings: **70**

## Summary

| Section | Count |
|---|---:|
| People — missing required fields | 2 |
| People — birth/death date ordering | 0 |
| People — duplicate (name, birth year) pairs | 1 |
| People — fs_id linked to multiple rows | 0 |
| Places — coordinate problems | 0 |
| Places — low/missing geocode_quality | 0 |
| Places — not referenced by any person or event | 12 |
| Events — missing place_id or PID_People | 46 |
| Events — broken foreign keys | 9 |
| Events — date_start after date_end | 0 |
| Relationships — broken foreign keys | 0 |

## People — missing required fields

- `P-0131` (Deliverance Owen) has no branch
- `P-0133` (John Thomas Thurlow Jr) has no branch

## People — duplicate (name, birth year) pairs

- `P-0025` (François Pouliot), `P-0091` (Francois Pouliot) share name `francois pouliot` and birth year 1805

## Places — not referenced by any person or event

- `PL-0006` (Ohio) not referenced by any Person or Event
- `PL-0115` (Renrock, Noble, Ohio, United States) not referenced by any Person or Event
- `PL-0116` (Hunterdon, New Jersey, United States) not referenced by any Person or Event
- `PL-0147` (Olive Cemetery, Caldwell, Noble, Ohio, United States) not referenced by any Person or Event
- `PL-0148` (Olive Cemetery, Caldwell, Noble, Ohio, United States) not referenced by any Person or Event
- `PL-0149` (Olive Cemetery, Caldwell, Noble, Ohio, United States) not referenced by any Person or Event
- `PL-0150` (Olive Cemetery, Caldwell, Noble, Ohio, United States) not referenced by any Person or Event
- `PL-0151` (Greene, Pennsylvania, United States) not referenced by any Person or Event
- `PL-0152` (Greene, Pennsylvania, United States) not referenced by any Person or Event
- `PL-0153` (Caldwell, Noble, Ohio, United States) not referenced by any Person or Event
- `PL-0154` (Caldwell, Noble, Ohio, United States) not referenced by any Person or Event
- `PL-0368` (Falls City, Lincoln, Idaho, United States) not referenced by any Person or Event

## Events — missing place_id or PID_People

- `E-0023` (Event Registration) has no place_id
- `E-0025` (Social Program Application) has no place_id
- `E-0030` (Death of Earl Wayne Reed) has no place_id
- `E-0034` (residence) has no place_id
- `E-0036` (Citizenship) has no place_id
- `E-0054` (Social Program Claim) has no place_id
- `E-0058` (marriage) has no place_id
- `E-0062` (immigration) has no place_id
- `E-0064` (residence) has no place_id
- `E-0067` (residence) has no place_id
- `E-0076` (immigration) has no place_id
- `E-0083` (Death of John Talley Reed) has no place_id
- `E-0085` (residence) has no place_id
- `E-0089` (Birth of Elizabeth (Willey) Reed) has no place_id
- `E-0091` (burial) has no place_id
- `E-0092` (residence) has no place_id
- `E-0093` (residence) has no place_id
- `E-0094` (residence) has no place_id
- `E-0103` (residence) has no place_id
- `E-0104` (residence) has no place_id
- `E-0107` (Pension) has no place_id
- `E-0114` (residence) has no place_id
- `E-0119` (residence) has no place_id
- `E-0120` (residence) has no place_id
- `E-0123` (residence) has no place_id
- `E-0126` (burial) has no place_id
- `E-0127` (residence) has no place_id
- `E-0130` (residence) has no place_id
- `E-0133` (residence) has no place_id
- `E-0134` (Marriage of John Foulk Reed and Estelle Gertrude Lambert) has no place_id
- `E-0176` (residence) has no place_id
- `E-0177` (residence) has no place_id
- `E-0178` (residence) has no place_id
- `E-0179` (residence) has no place_id
- `E-0181` (residence) has no place_id
- `E-0182` (residence) has no place_id
- `E-0183` (residence) has no place_id
- `E-0184` (residence) has no place_id
- `E-0185` (residence) has no place_id
- `E-0186` (residence) has no place_id
- `E-0187` (residence) has no place_id
- `E-0188` (residence) has no place_id
- `E-0190` (residence) has no place_id
- `E-0191` (residence) has no place_id
- `E-0192` (1854 & 1856 Iowa State Census — Canton Twp, Benton Co, IA) has no PID_People
- `E-0193` (Wilson's Raid — Action at Maplesville, AL (Co. L, 3rd Iowa Cavalry)) has no PID_People

## Events — broken foreign keys

- `E-0005` (Marriage of John T. Reed and Elizabeth Willey): PID_People `P-0003` not in People
- `E-0008` (Marriage of Abiram Lambert and Louisa Leach): PID_People `P-0011` not in People
- `E-0008` (Marriage of Abiram Lambert and Louisa Leach): PID_People `P-0037` not in People
- `E-0011` (Marriage of Abiram Lambert and Helen Amelia (Boles) Foote): PID_People `P-0011` not in People
- `E-0014` (Marriage of John F. Zika and Delina B. Pouliot): PID_People `P-0021` not in People
- `E-0014` (Marriage of John F. Zika and Delina B. Pouliot): PID_People `P-0022` not in People
- `E-0018` (Marriage of Earl Wayne Reed and Isabelle Zika): PID_People `P-0029` not in People
- `E-0018` (Marriage of Earl Wayne Reed and Isabelle Zika): PID_People `P-0030` not in People
- `E-0134` (Marriage of John Foulk Reed and Estelle Gertrude Lambert): PID_People `P-0034` not in People
