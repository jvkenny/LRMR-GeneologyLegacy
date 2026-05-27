# LRGDM Validation — 2026-05-26

- GPKG: `src/data/lrgdm_v2.gpkg`
- Total findings: **181**

## Summary

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

## People — missing required fields

- `P-0038` (James Willey) has no branch
- `P-0039` (Emily Thorla) has no branch
- `P-0040` (Benjamin Reed) has no branch
- `P-0041` (Sarah Dickerson) has no branch
- `P-0042` (Stephen Reed) has no branch
- `P-0043` (Mary Polly Cook) has no branch
- `P-0044` (Else Alice Bonham) has no branch
- `P-0045` (John Foulk Talley) has no branch
- `P-0046` (Hannah Paulson) has no branch
- `P-0047` (Samuel R Barnard) has no branch
- `P-0048` (Roxana Desire Barnard) has no branch
- `P-0049` (William Polk Willey) has no branch
- `P-0050` (Sarah Dye) has no branch
- `P-0051` (Benjamin Thorla) has no branch
- `P-0052` (Elizabeth Allen) has no branch

## People — duplicate (name, birth year) pairs

- `P-0005` (Benjamin Reed), `P-0040` (Benjamin Reed) share name `benjamin reed` and birth year 1789

## Places — low/missing geocode_quality

- `PL-0015` (Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0015` (Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0015` (Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0015` (Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0015` (Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0015` (Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0015` (Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0016` (Chicago, Cook County, Illinois, USA) has no geocode_quality
- `PL-0016` (Chicago, Cook County, Illinois, USA) has no geocode_quality
- `PL-0016` (Chicago, Cook County, Illinois, USA) has no geocode_quality
- `PL-0016` (Chicago, Cook County, Illinois, USA) has no geocode_quality
- `PL-0016` (Chicago, Cook County, Illinois, USA) has no geocode_quality
- `PL-0016` (Chicago, Cook County, Illinois, USA) has no geocode_quality
- `PL-0016` (Chicago, Cook County, Illinois, USA) has no geocode_quality
- `PL-0017` (Glen Ellyn, DuPage County, Illinois, USA) has no geocode_quality
- `PL-0019` (Cicero Town, Cicero Township, Cook County, Illinois, USA) has no geocode_quality
- `PL-0020` (Bedford, Taylor County, Iowa, USA) has no geocode_quality
- `PL-0021` (1048 Alameda Dr, Aurora, IL 60506, USA) has no geocode_quality
- `PL-0022` (Valley Township, Guthrie Center city, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0022` (Valley Township, Guthrie Center city, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0023` (Waukesha, Waukesha County, Wisconsin, USA) has no geocode_quality
- `PL-0024` (Cicero, Cook County, Illinois, USA) has no geocode_quality
- `PL-0026` (4N711 Medinah Road, Addison, DuPage County, Illinois, USA) has no geocode_quality
- `PL-0028` (Schaumburg Township, Cook County, Illinois, USA) has no geocode_quality
- `PL-0029` (Glen Oak Cemetery, Proviso Township, Cook County, Illinois, USA) has no geocode_quality
- `PL-0030` (Aurora Ward 2, Kane County, Illinois, USA) has no geocode_quality
- `PL-0030` (Aurora Ward 2, Kane County, Illinois, USA) has no geocode_quality
- `PL-0031` (Cook County, Illinois, USA) has no geocode_quality
- `PL-0031` (Cook County, Illinois, USA) has no geocode_quality
- `PL-0032` (Monteith, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0032` (Monteith, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0032` (Monteith, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0032` (Monteith, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0033` (Davenport, Scott County, Iowa, USA) has no geocode_quality
- `PL-0034` (Oakdale Memorial Gardens Cemetery, Davenport, Scott County, Iowa, USA) has no geocode_quality
- `PL-0035` (Jackson Township, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0035` (Jackson Township, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0035` (Jackson Township, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0035` (Jackson Township, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0035` (Jackson Township, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0036` (Niagara Falls, Niagara County, New York, USA) has no geocode_quality
- `PL-0037` (Ward 6, Davenport City, Scott County, Iowa, USA) has no geocode_quality
- `PL-0038` (Seely Township, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0038` (Seely Township, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0039` (Prairie Home Cemetery, Waukesha, Waukesha County, Wisconsin, USA) has no geocode_quality
- `PL-0041` (Sioux Falls Ward 11, Minnehaha County, South Dakota, USA) has no geocode_quality
- `PL-0042` (VraÅ¾dovy Lhotice #16, BeneÅ¡ov, Bohemia, Austria) has no geocode_quality
- `PL-0044` (Aurora Township, Kane County, Illinois, USA) has no geocode_quality
- `PL-0046` (6 S Leamington Ave, Chicago, Cook County, Illinois, USA) has no geocode_quality
- `PL-0047` (Oakridge Cemetery, Hillside, Cook County, Illinois, USA) has no geocode_quality
- `PL-0048` (Saint-Laurent-de-L'ÃŽle-d'OrlÃ©ans, L'ÃŽle-d'OrlÃ©ans, QuÃ©bec, Canada) has no geocode_quality
- `PL-0049` (New York, USA) has no geocode_quality
- `PL-0050` (Woodsfield, Monroe County, Ohio, USA) has no geocode_quality
- `PL-0053` (Valley Township, Guthrie Center, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0058` (Salem, Washington County, Indiana, USA) has no geocode_quality
- `PL-0059` (Falls City, Jerome County, Idaho, USA) has no geocode_quality
- `PL-0060` (Twin Falls, Twin Falls County, Idaho, USA) has no geocode_quality
- `PL-0061` (Clay Township, Howard County, Indiana, USA) has no geocode_quality
- `PL-0062` (Franklin Township, Grundy County, Missouri, USA) has no geocode_quality
- `PL-0063` (Union Township, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0065` (Guthrie Center, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0066` (Rollin, Lenawee County, Michigan, USA) has no geocode_quality
- `PL-0067` (Violet Hill Cemetery, Perry, Dallas County, Iowa, USA) has no geocode_quality
- `PL-0068` (Mt Vernon, Franklin Township, Linn County, Iowa, USA) has no geocode_quality
- `PL-0069` (Ward 4, Cedar Rapids, Linn County, Iowa, USA) has no geocode_quality
- `PL-0070` (Wills Creek, Coshocton County, Ohio, USA) has no geocode_quality
- `PL-0072` (Ohio, USA) has no geocode_quality
- `PL-0072` (Ohio, USA) has no geocode_quality
- `PL-0074` (Talley Town, Morgan County, Ohio, USA) has no geocode_quality
- `PL-0075` (Guthrie Center city, Valley Township, Guthrie County, Iowa, USA) has no geocode_quality
- `PL-0078` (Adams, Washington, Ohio, United States) has no geocode_quality
- `PL-0079` (Airington Cemetery, Bristol Township, Morgan County, Ohio, United States) has no geocode_quality
- `PL-0080` (Bloom Township, Morgan, Ohio, United States) has no geocode_quality
- `PL-0081` (Brandywine, New Castle, Delaware, United States) has no geocode_quality
- `PL-0082` (Caldwell, Noble, Ohio, United States) has no geocode_quality
- `PL-0083` (Cambridge Township, Guernsey, Ohio, United States) has no geocode_quality
- `PL-0084` (Connecticut, United States) has no geocode_quality
- `PL-0085` (Greene, Pennsylvania, United States) has no geocode_quality
- `PL-0086` (Greenwood Cemetery, Zanesville, Muskingum, Ohio, United States) has no geocode_quality
- `PL-0087` (Guernsey, Ohio, United States) has no geocode_quality
- `PL-0088` (Hopewell Township, Hunterdon, New Jerse) has no geocode_quality
- `PL-0089` (Hunterdon, New Jersey) has no geocode_quality
- `PL-0090` (Hunterdon, New Jersey, United States) has no geocode_quality
- `PL-0096` (Lebanon, Grafton, New Hampshire, United States) has no geocode_quality
- `PL-0097` (Nanticoke Hundred, Sussex, Delaware, United States) has no geocode_quality
- `PL-0098` (New Castle, Delaware, United States) has no geocode_quality
- `PL-0099` (New Hampshire, United States) has no geocode_quality
- `PL-0100` (Newport, Hunterdon, New Jersey, United States) has no geocode_quality
- `PL-0101` (Noble, Ohio, United States) has no geocode_quality
- `PL-0103` (Olive Cemetery, Caldwell, Noble, Ohio, United States) has no geocode_quality
- `PL-0104` (Pennington Presbyterian Church Cemetery, Pennington, Mercer, New Jersey, United States) has no geocode_quality
- `PL-0105` (Renrock, Noble, Ohio, United States) has no geocode_quality
- `PL-0106` (Shafer Cemetery, Jackson Township, Noble, Ohio, United States) has no geocode_quality
- `PL-0107` (Shafers Church Cemetery, Macksburg, Noble, Ohio, United States) has no geocode_quality
- `PL-0108` (Simsbury, Hartford) has no geocode_quality
- `PL-0109` (Simsbury, Hartford, Connecticut, United States) has no geocode_quality
- `PL-0110` (Upper Lowell, Noble, Ohio, United States) has no geocode_quality
- `PL-0111` (Upper Lowell, Washington, Ohio, United States) has no geocode_quality
- `PL-0112` (Washington Township, Muskingum, Ohio, United States) has no geocode_quality
- `PL-0113` (Washington, Pennsylvania, United States) has no geocode_quality
- `PL-0114` (Windsor, Hartford, Connecticut) has no geocode_quality
- `PL-0115` (Renrock, Noble, Ohio, United States) has no geocode_quality
- `PL-0116` (Hunterdon, New Jersey, United States) has no geocode_quality
- `PL-0147` (Olive Cemetery, Caldwell, Noble, Ohio, United States) has no geocode_quality
- `PL-0148` (Olive Cemetery, Caldwell, Noble, Ohio, United States) has no geocode_quality
- `PL-0149` (Olive Cemetery, Caldwell, Noble, Ohio, United States) has no geocode_quality
- `PL-0150` (Olive Cemetery, Caldwell, Noble, Ohio, United States) has no geocode_quality
- `PL-0151` (Greene, Pennsylvania, United States) has no geocode_quality
- `PL-0152` (Greene, Pennsylvania, United States) has no geocode_quality
- `PL-0153` (Caldwell, Noble, Ohio, United States) has no geocode_quality
- `PL-0154` (Caldwell, Noble, Ohio, United States) has no geocode_quality

## Places — not referenced by any person or event

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

- `E-0025` (Social Program Application) has no place_id
- `E-0030` (Death of Earl Wayne Reed) has no place_id
- `E-0054` (Social Program Claim) has no place_id

## Events — broken foreign keys

- `E-0023` (Event Registration): place_id `PL-0018` not in Places
- `E-0034` (residence): place_id `PL-0025` not in Places
- `E-0036` (Citizenship): place_id `PL-0027` not in Places
- `E-0058` (marriage): place_id `PL-0040` not in Places
- `E-0062` (immigration): place_id `PL-0027` not in Places
- `E-0064` (residence): place_id `PL-0043` not in Places
- `E-0067` (residence): place_id `PL-0045` not in Places
- `E-0076` (immigration): place_id `PL-0027` not in Places
- `E-0083` (Death of John Talley Reed): place_id `PL-0051` not in Places
- `E-0085` (residence): place_id `PL-0052` not in Places
- `E-0089` (Birth of Elizabeth (Willey) Reed): place_id `PL-0054` not in Places
- `E-0091` (burial): place_id `PL-0055` not in Places
- `E-0092` (residence): place_id `PL-0056` not in Places
- `E-0093` (residence): place_id `PL-0052` not in Places
- `E-0094` (residence): place_id `PL-0057` not in Places
- `E-0103` (residence): place_id `PL-0064` not in Places
- `E-0104` (residence): place_id `PL-0064` not in Places
- `E-0107` (Pension): place_id `PL-0027` not in Places
- `E-0114` (residence): place_id `PL-0051` not in Places
- `E-0119` (residence): place_id `PL-0071` not in Places
- `E-0120` (residence): place_id `PL-0052` not in Places
- `E-0123` (residence): place_id `PL-0073` not in Places
- `E-0126` (burial): place_id `PL-0055` not in Places
- `E-0127` (residence): place_id `PL-0052` not in Places
- `E-0130` (residence): place_id `PL-0073` not in Places
- `E-0133` (residence): place_id `PL-0073` not in Places
- `E-0134` (Marriage of John Foulk Reed and Estelle Gertrude Lambert): place_id `PL-0040` not in Places
- `E-0176` (residence): place_id `PL-0094` not in Places
- `E-0177` (residence): place_id `PL-0092` not in Places
- `E-0178` (residence): place_id `PL-0092` not in Places
- `E-0179` (residence): place_id `PL-0095` not in Places
- `E-0181` (residence): place_id `PL-0094` not in Places
- `E-0182` (residence): place_id `PL-0092` not in Places
- `E-0183` (residence): place_id `PL-0092` not in Places
- `E-0184` (residence): place_id `PL-0095` not in Places
- `E-0185` (residence): place_id `PL-0095` not in Places
- `E-0186` (residence): place_id `PL-0091` not in Places
- `E-0187` (residence): place_id `PL-0092` not in Places
- `E-0188` (residence): place_id `PL-0102` not in Places
- `E-0190` (residence): place_id `PL-0093` not in Places
- `E-0191` (residence): place_id `PL-0094` not in Places
