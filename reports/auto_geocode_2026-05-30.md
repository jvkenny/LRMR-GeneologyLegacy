# Auto-Geocode Proposal — 2026-05-30

- Unmapped People (fs_id set, birth/death place_id NULL): **170**
- People to update: **7**
- New Places to create: **3**
- People with fs_id missing from extract: **27**
- People with no place data in FS: **136**

## People updates

| person_id | name | fs_id | birth_place_id | birth reason | death_place_id | death reason |
|---|---|---|---|---|---|---|
| `P-0606` | Johan Pouliot | `LWV2-QR5` |  |  | `PL-166022` | burial fallback: created new `PL-166022` from FS coords |
| `P-0569` | John Strong | `94RB-17S` |  |  | `PL-67532` | burial fallback: matched existing `PL-67532` |
| `P-0610` | Innocent Audet | `LYSP-RN5` |  |  | `PL-22281` | burial fallback: matched existing `PL-22281` |
| `P-0666` | Jean Roussin | `LTHY-88Y` |  |  | `PL-166023` | burial fallback: created new `PL-166023` from FS coords |
| `P-0670` | André Mouillard | `LZPZ-526` |  |  | `PL-36870` | burial fallback: matched existing `PL-36870` |
| `P-0723` | Jeanne Galiot | `PWHF-K7N` |  | no place in FS | `PL-82185` | burial fallback: matched existing `PL-82185` |
| `P-0778` | Francois de Romilley | `KVL7-KL6` |  |  | `PL-166024` | burial fallback: created new `PL-166024` from FS coords |

## New Places

| place_id | name | lat | long | quality |
|---|---|---|---|---|
| `PL-166022` | Nogent-le-Bernard, Sarthe, France | 48.2359 | 0.4897 | settlement |
| `PL-166023` | L'Ange-Gardien Cemetery, Ange-Gardien, Rouville, Quebec, Canada | 45.35009 | -72.92561 | cemetery |
| `PL-166024` | Le Châtellier, Ille-et-Vilaine, France | 48.415 | -1.2536 | settlement |

## People with fs_id not in FS extract

- `P-0099` Giovanni Dini — fs_id `P355-XWC`
- `P-0146` Františka Doležalová — fs_id `GWCT-1N1`
- `P-0152` Magdalena Říhová — fs_id `GT5S-PGJ`
- `P-0151` Magdalena Dufková — fs_id `PH93-PYK`
- `P-0150` Václav Říha — fs_id `GPDL-25D`
- `P-0149` Eva Zemanová — fs_id `GT5S-14P`
- `P-0148` František Jan Michalíček — fs_id `PH93-RMY`
- `P-0147` Antonín Zeman — fs_id `GPDL-R79`
- `P-0107` Martin Zíka — fs_id `L2V1-YHK`
- `P-0104` Thomas Spear — fs_id `K8F2-Y27`
- `P-0103` Nancy Walls — fs_id `K4BN-VM7`
- `P-0102` Pellegrino Giorgi — fs_id `P7P4-8PM`
- `P-0101` Piera Bellandi — fs_id `PC4W-R8N`
- `P-0098` Leopoldo Pagni — fs_id `P7PW-CCK`
- `P-0097` Henriette Cheffre — fs_id `GYVW-44Y`
- `P-0096` Pasqua Rosa Spadoni — fs_id `GSQJ-4RC`
- `P-0093` Joseph Filiatrault dit St. Louis — fs_id `GYV7-TRD`
- `P-0090` František Říha — fs_id `GS6J-92Z`
- `P-0089` Františka Klusová — fs_id `GWCT-JQN`
- `P-0081` Cherubina Giorgi — fs_id `P3YM-9YQ`
- `P-0077` Josephine Riha Veta — fs_id `LBH1-TK2`
- `P-0073` Celestino Dini — fs_id `GSQJ-M1C`
- `P-0065` Louis Dini — fs_id `GCKQ-RK3`
- `P-0057` Laura Kroll — fs_id `L24Z-SFM`
- `P-0054` Phyllis Kroll — fs_id `L274-KGR`
- `P-0062` Earl Wayne Reed Sr — fs_id `M3P5-XF6`
- `P-0168` John Kenny — fs_id `L274-KNT`

## People with no usable FS place

- `P-0118` Maria Angiola Ercolini — birth: no place in FS | death: None
- `P-0117` Pier Domenico Spadoni — birth: no place in FS | death: None
- `P-0166` CATERINA PARLANTI — birth: None | death: no place in FS
- `P-0165` GIUSEPPE PORCIANI — birth: None | death: no place in FS
- `P-0139` Mabel Pinney — birth: None | death: no place in FS
- `P-0126` Ann Patton — birth: None | death: no place in FS
- `P-0121` Carlo Dini — birth: None | death: no place in FS
- `P-0119` Annunziata Grossi — birth: no place in FS | death: no place in FS
- `P-0116` Elisabetta Giovacchini — birth: no place in FS | death: no place in FS
- `P-0115` Pietro Dini — birth: no place in FS | death: no place in FS
- `P-0175` Gideon Dickerson — birth: no place in FS | death: no place in FS
- `P-0207` Willey — birth: no place in FS | death: no place in FS
- `P-0244` Mrs. Simon Poulson — birth: None | death: no place in FS
- `P-0784` Pierre Burlon — birth: no place in FS | death: no place in FS
- `P-0785` Jeanne Danet — birth: no place in FS | death: no place in FS
- `P-0457` FRANCESCO NICCOLAI — birth: None | death: no place in FS
- `P-0461` PASQUINO NICCOLAI — birth: None | death: no place in FS
- `P-0588` Mrs. Uknown Morgan — birth: no place in FS | death: no place in FS
- `P-0645` Barbe Cochois — birth: no place in FS | death: no place in FS
- `P-0699` Domenico Mariotti — birth: None | death: no place in FS
- `P-0838` Bartolomeo Niccolai — birth: no place in FS | death: no place in FS
- `P-0176` Eliza Gunn — birth: no place in FS | death: no place in FS
- `P-0206` Catherine — birth: None | death: no place in FS
- `P-0213` Anna Moor — birth: None | death: no place in FS
- `P-0214` Friderich Lemlein — birth: None | death: no place in FS
- `P-0215` Maria Magdalena Waltz — birth: None | death: no place in FS
- `P-0222` Mr. Brown — birth: None | death: no place in FS
- `P-0223` Mrs. Brown — birth: None | death: no place in FS
- `P-0226` William Moor — birth: no place in FS | death: no place in FS
- `P-0227` Annetje Jans — birth: no place in FS | death: no place in FS
- `P-0228` Lämmlein — birth: no place in FS | death: no place in FS
- `P-0235` George Patton — birth: None | death: no place in FS
- `P-0236` Maria Sinnexon — birth: None | death: no place in FS
- `P-0274` Elizabeth Davis — birth: no place in FS | death: None
- `P-0284` Patience Clifton — birth: no place in FS | death: None
- `P-0299` Robert Owens — birth: no place in FS | death: no place in FS
- `P-0317` Jacque Denis — birth: no place in FS | death: None
- `P-0344` Marie Madelaine Crespeau — birth: no place in FS | death: None
- `P-0353` Blaise Denys — birth: None | death: no place in FS
- `P-0354` Jeanne la Ponche — birth: None | death: no place in FS
- `P-0372` Elizabeth Carrier — birth: None | death: no place in FS
- `P-0394` Mary Burlly — birth: no place in FS | death: None
- `P-0408` Elizabeth Tuttle — birth: None | death: no place in FS
- `P-0429` Jan Pepin — birth: None | death: no place in FS
- `P-0446` Anne Gangner — birth: None | death: no place in FS
- `P-0448` Magdelaine Roulois — birth: None | death: no place in FS
- `P-0455` GIUSEPPE GIACOMELLI — birth: None | death: no place in FS
- `P-0456` ANGIOLA CASSANESI — birth: no place in FS | death: no place in FS
- `P-0458` MARIA ANGIOLA BARONTI — birth: None | death: no place in FS
- `P-0459` MARIANO BONAGUIDI — birth: None | death: no place in FS
- `P-0460` CATERINA PAPINI — birth: None | death: no place in FS
- `P-0465` Pasquino Papini — birth: None | death: no place in FS
- `P-0466` Barbera Simoni — birth: None | death: no place in FS
- `P-0467` Green — birth: no place in FS | death: no place in FS
- `P-0486` Richard Gambray — birth: None | death: no place in FS
- `P-0487` Missy Nae O'Dell — birth: None | death: no place in FS
- `P-0494` Simon Johnsson — birth: None | death: no place in FS
- `P-0495` ? — birth: no place in FS | death: no place in FS
- `P-0498` Thomas Gilpin — birth: no place in FS | death: None
- `P-0502` John Wilson — birth: no place in FS | death: None
- `P-0503` Elsabeth Atkinson — birth: None | death: no place in FS
- `P-0506` Jan Harmansen — birth: None | death: no place in FS
- `P-0510` Peter Mattson Dalbo — birth: no place in FS | death: no place in FS
- `P-0513` Elinor Jansen — birth: no place in FS | death: None
- `P-0530` Laurens Duyts — birth: None | death: no place in FS
- `P-0533` Jean Crawford — birth: None | death: no place in FS
- `P-0537` Ruth Ann Tackling — birth: None | death: no place in FS
- `P-0541` Mary Hudnall — birth: None | death: no coords in FS
- `P-0543` Mary Ann Olcott Moon — birth: None | death: no place in FS
- `P-0558` Nehemiah Hunt, Sr. — birth: no place in FS | death: None
- `P-0567` Mathew Merrill — birth: None | death: no place in FS
- `P-0568` Isabell Freeman — birth: None | death: no place in FS
- `P-0575` Thomas Holcombe — birth: no place in FS | death: None
- `P-0591` Mrs. Lucille Sessions — birth: None | death: no place in FS
- `P-0626` Jean Le Clerc — birth: None | death: no place in FS
- `P-0647` Marie MÉTAYER — birth: no place in FS | death: no place in FS
- `P-0658` François Marsan Laponche — birth: None | death: no place in FS
- `P-0659` Françoise Lapierre — birth: None | death: no place in FS
- `P-0661` Marguerite Nicole — birth: None | death: no place in FS
- `P-0689` Jeanne Chevalier — birth: None | death: no place in FS
- `P-0700` Giovanna — birth: no place in FS | death: no place in FS
- `P-0701` BARTOLOMEO BONAGUIDI — birth: None | death: no place in FS
- `P-0702` LISABETTA RICCI — birth: None | death: no place in FS
- `P-0703` Bartolomeo Stefanelli — birth: None | death: no place in FS
- `P-0704` Lisabetta — birth: None | death: no place in FS
- `P-0711` Jean Fafart — birth: None | death: no place in FS
- `P-0716` Michaellis Roig — birth: None | death: no place in FS
- `P-0717` Anne Roig — birth: None | death: no place in FS
- `P-0720` Robert Mesange — birth: no place in FS | death: None
- `P-0722` Yves Henault — birth: None | death: no place in FS
- `P-0724` Jean Macre — birth: None | death: no place in FS
- `P-0725` Barbe Landry — birth: None | death: no place in FS
- `P-0728` Denis Rodé — birth: None | death: no place in FS
- `P-0729` Françoise Gouin — birth: None | death: no place in FS
- `P-0730` Robert Mesange — birth: None | death: no place in FS
- `P-0731` Madeleine Jahan — birth: None | death: no place in FS
- `P-0734` End Henault ( Enaud ) — birth: no place in FS | death: no place in FS
- `P-0735` End Galiot — birth: no place in FS | death: no place in FS
- `P-0737` Anne Auphily — birth: None | death: no place in FS
- `P-0738` Pierre Jacques — birth: no place in FS | death: no place in FS
- `P-0740` Jean Rodé — birth: None | death: no place in FS
- `P-0752` Louis Barreau — birth: None | death: no place in FS
- `P-0753` Charlotte Giton — birth: no place in FS | death: no place in FS
- `P-0754` AnSe — birth: no place in FS | death: no place in FS
- `P-0762` Marie Pirenne — birth: None | death: no place in FS
- `P-0765` Paul Crepeau — birth: None | death: no place in FS
- `P-0768` Marie Jouet — birth: None | death: no place in FS
- `P-0769` Verdière — birth: no place in FS | death: no place in FS
- `P-0771` Joseph Laliot Leliot Le Cat — birth: None | death: no place in FS
- `P-0772` Marie Leliot — birth: None | death: no place in FS
- `P-0776` Catherine — birth: None | death: no place in FS
- `P-0779` Jacquemine de Servaude — birth: None | death: no place in FS
- `P-0790` Gemmet Bourgoin — birth: None | death: no place in FS
- `P-0800` Edward Bedu — birth: None | death: no place in FS
- `P-0801` Rollin Lefèbvre — birth: None | death: no place in FS
- `P-0804` Jeanne — birth: None | death: no place in FS
- `P-0807` Ancetre Maguin — birth: None | death: no place in FS
- `P-0808` Madame Maguin — birth: no place in FS | death: no place in FS
- `P-0809` Sébastien Rouleau — birth: no place in FS | death: None
- `P-0811` Anthoine Leroux — birth: None | death: no place in FS
- `P-0812` Jeanne Jouary — birth: None | death: no place in FS
- `P-0813` Antoine Rouleau — birth: no place in FS | death: no place in FS
- `P-0814` Jeanne Genevieve Godbout — birth: None | death: no place in FS
- `P-0817` Pierre Le Roux — birth: None | death: no place in FS
- `P-0822` Antoine Godbout — birth: None | death: no place in FS
- `P-0823` Elizabeth Godbout — birth: None | death: no place in FS
- `P-0828` FILIPPO BONAGUIDI — birth: no place in FS | death: no place in FS
- `P-0829` BARTOLOMEO RICCI — birth: None | death: no place in FS
- `P-0831` Maria — birth: no place in FS | death: None
- `P-0833` Pasqua — birth: no place in FS | death: no place in FS
- `P-0835` Salvadore Arcangeli — birth: no place in FS | death: None
- `P-0837` Domenico — birth: no place in FS | death: no place in FS
- `P-0839` Elena — birth: no place in FS | death: no place in FS
- `P-0840` Giorgio Arcangeli — birth: no place in FS | death: no place in FS
- `P-0841` Francesco da Momigno — birth: no place in FS | death: no place in FS
- `P-0842` Salvatore Arcangeli — birth: no place in FS | death: no place in FS