# LRGDM Validation — 2026-05-26

- GPKG: `src/data/lrgdm_v2.gpkg`
- Total findings: **120**

## Summary

| Section | Count |
|---|---:|
| People — missing required fields | 56 |
| People — birth/death date ordering | 0 |
| People — duplicate (name, birth year) pairs | 9 |
| People — fs_id linked to multiple rows | 0 |
| Places — coordinate problems | 0 |
| Places — low/missing geocode_quality | 0 |
| Places — not referenced by any person or event | 11 |
| Events — missing place_id or PID_People | 44 |
| Events — broken foreign keys | 0 |
| Events — date_start after date_end | 0 |
| Relationships — broken foreign keys | 0 |

## People — missing required fields

- `P-0074` (Helen Amelia Boles) has no branch
- `P-0076` (Henriette St. Louis) has no branch
- `P-0077` (Josephine Riha Veta) has no branch
- `P-0086` (Silas A. Boles) has no branch
- `P-0088` (Marie Anna Říhová) has no branch
- `P-0089` (Františka Klusová) has no branch
- `P-0090` (František Říha) has no branch
- `P-0092` (Martha Lovina Spears) has no branch
- `P-0093` (Joseph Filiatrault dit St. Louis) has no branch
- `P-0094` (Julie Audet dit Lapointe) has no branch
- `P-0097` (Henriette Cheffre) has no branch
- `P-0101` (Piera Bellandi) has no branch
- `P-0103` (Nancy Walls) has no branch
- `P-0104` (Thomas Spear) has no branch
- `P-0106` (Permelia "Millie" Oaks) has no branch
- `P-0108` (Barbora Michalíčková) has no branch
- `P-0109` (František Říha) has no branch
- `P-0111` (Therese Denis Lapierre) has no branch
- `P-0112` (Michel Olivier Audet) has no branch
- `P-0113` (Marie Louise Tremblay) has no branch
- `P-0114` (Marie Zemanová) has no branch
- `P-0116` (Elisabetta Giovacchini) has no branch
- `P-0118` (Maria Angiola Ercolini) has no branch
- `P-0119` (Annunziata Grossi) has no branch
- `P-0123` (Priscilla Foulk) has no branch
- `P-0125` (Sarah Brown) has no branch
- `P-0126` (Ann Patton) has no branch
- `P-0127` (Richard R. Dickerson Sr.) has no branch
- `P-0128` (Simon Poulson lll) has no branch
- `P-0130` (Margaret Polk) has no branch
- `P-0131` (Deliverance Owen) has no branch
- `P-0133` (John Thomas Thurlow Jr) has no branch
- `P-0136` (Lydia Hopkins) has no branch
- `P-0137` (Elizabeth Polly Palmer) has no branch
- `P-0138` (Sherebiah Lambert Sr.) has no branch
- `P-0139` (Mabel Pinney) has no branch
- `P-0140` (Abigail Whitney Rand) has no branch
- `P-0143` (Lucretia Carroll Pinney) has no branch
- `P-0144` (Jonathan Abel Oakes) has no branch
- `P-0146` (Františka Doležalová) has no branch
- `P-0147` (Antonín Zeman) has no branch
- `P-0148` (František Jan Michalíček) has no branch
- `P-0149` (Eva Zemanová) has no branch
- `P-0150` (Václav Říha) has no branch
- `P-0151` (Magdalena Dufková) has no branch
- `P-0152` (Magdalena Říhová) has no branch
- `P-0153` (Genevieve Godbout) has no branch
- `P-0155` (Marie Louise St-Mars) has no branch
- `P-0156` (Jacques Denis) has no branch
- `P-0157` (Marie Angelique Pépin dit Lachance) has no branch
- `P-0158` (Guillaume Audet) has no branch
- `P-0159` (Jacques Tremblay) has no branch
- `P-0160` (Marie Angelique Delage) has no branch
- `P-0162` (Maria Pasqua Baldi) has no branch
- `P-0164` (UMILTA' GIACOMELLI) has no branch
- `P-0166` (CATERINA PARLANTI) has no branch

## People — duplicate (name, birth year) pairs

- `P-0003` (John Talley Reed), `P-0070` (John Talley Reed) share name `john talley reed` and birth year 1841
- `P-0034` (John Foulk Reed), `P-0061` (John Foulk Reed) share name `john foulk reed` and birth year 1877
- `P-0011` (Abiram Stacy Lambert), `P-0072` (Abiram Stacy Lambert) share name `abiram stacy lambert` and birth year 1831
- `P-0015` (Sherebiah Lambert Sr.), `P-0138` (Sherebiah Lambert Sr.) share name `sherebiah lambert sr` and birth year 1728
- `P-0017` (Sherebiah Lambert Jr.), `P-0105` (Sherebiah Lambert Jr) share name `sherebiah lambert jr` and birth year 1759
- `P-0023` (Paul Pouliot), `P-0078` (Paul Pouliot) share name `paul pouliot` and birth year 1834
- `P-0025` (François Pouliot), `P-0091` (Francois Pouliot) share name `francois pouliot` and birth year 1805
- `P-0026` (Julie Audet dit Lapointe), `P-0094` (Julie Audet dit Lapointe) share name `julie audet dit lapointe` and birth year 1812
- `P-0037` (Leah Rae Mariotti), `P-0055` (Leah Rae Mariotti) share name `leah rae mariotti` and birth year 1936

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
