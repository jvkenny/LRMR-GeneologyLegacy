# LRGDM Validation — 2026-05-30

- Source: Postgres db `lrgdm`
- Total findings: **58**

## Summary

| Section | Count |
|---|---:|
| person — missing required fields | 1 |
| person — birth/death date ordering | 0 |
| person — duplicate (name, birth year) pairs | 0 |
| person — fs_id linked to multiple rows | 0 |
| place — coordinate problems | 0 |
| place — low/missing geocode_quality | 0 |
| place — not referenced by any person or event | 13 |
| event — missing place_id or participants | 44 |
| event — date_start after date_end | 0 |

## person — missing required fields

- `P-0168` (John Kenny) has no branch

## place — not referenced by any person or event

- `PL-0006` (Ohio) not referenced by any person or event
- `PL-0115` (Renrock, Noble, Ohio, United States) not referenced by any person or event
- `PL-0116` (Hunterdon, New Jersey, United States) not referenced by any person or event
- `PL-0147` (Olive Cemetery, Caldwell, Noble, Ohio, United States) not referenced by any person or event
- `PL-0148` (Olive Cemetery, Caldwell, Noble, Ohio, United States) not referenced by any person or event
- `PL-0149` (Olive Cemetery, Caldwell, Noble, Ohio, United States) not referenced by any person or event
- `PL-0150` (Olive Cemetery, Caldwell, Noble, Ohio, United States) not referenced by any person or event
- `PL-0151` (Greene, Pennsylvania, United States) not referenced by any person or event
- `PL-0152` (Greene, Pennsylvania, United States) not referenced by any person or event
- `PL-0153` (Caldwell, Noble, Ohio, United States) not referenced by any person or event
- `PL-0154` (Caldwell, Noble, Ohio, United States) not referenced by any person or event
- `PL-0220` (Seely Township, Guthrie, Iowa, United States) not referenced by any person or event
- `PL-5242` (Genoa, Liguria, Italy) not referenced by any person or event

## event — missing place_id or participants

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
