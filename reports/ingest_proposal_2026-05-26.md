# FS Ingest Proposal — 2026-05-26

- To-ingest People: **114**
- To-create Places: **86**
- People with `branch=NULL` after heuristic (need manual assignment): **56**
- Skipped: **18** (proband/spouse, already-linked via fs_id, or living)

## Branch heuristic

Surname → branch mapping is in `scripts/ingest_familysearch.py`. Mapped surnames:
`Reed` → `Paternal Reed`, `Talley` → `Paternal Reed`, `Willey` → `Paternal Reed`, `Thorla` → `Paternal Reed`, `Thorley` → `Paternal Reed`, `Dickerson` → `Paternal Reed`, `Cook` → `Paternal Reed`, `Bonham` → `Paternal Reed`, `Paulson` → `Paternal Reed`, `Paulsen` → `Paternal Reed`, `Poulson` → `Paternal Reed`, `Barnard` → `Paternal Reed`, `Dye` → `Paternal Reed`, `Allen` → `Paternal Reed`, `Lemley` → `Paternal Reed`, `Kenny` → `Paternal Kenny`, `Kroll` → `Paternal Kroll`, `Mariotti` → `Maternal Mariotti`, `Lambert` → `Maternal Lambert`, `Pouliot` → `Pouliot`, `Zika` → `Zika`, `Zíka` → `Zika`, `Niccolai` → `Maternal Mariotti`, `Porciani` → `Maternal Mariotti`, `Dini` → `Maternal Mariotti`, `Pagni` → `Maternal Mariotti`, `Spadoni` → `Maternal Mariotti`, `Giorgi` → `Maternal Mariotti`, `Lenzi` → `Maternal Mariotti`, `Bartoletti` → `Maternal Mariotti`, `Marchi` → `Maternal Mariotti`, `Lapini` → `Maternal Mariotti`, `NICCOLAI` → `Maternal Mariotti`, `PORCIANI` → `Maternal Mariotti`

## New People

| new id | name | sex | birth | death | branch | fs_id |
|---|---|---|---|---|---|---|
| `P-0053` | Edward Kenny | male | 23 March 1933 | 13 June 1978 | Paternal Kenny | `L274-KLZ` |
| `P-0054` | Phyllis Kroll | female | 1931 | May 2020 | Paternal Kroll | `L274-KGR` |
| `P-0055` | Leah Rae Mariotti | female | 8 September 1936 | 21 July 2025 | Maternal Mariotti | `L274-KT7` |
| `P-0056` | John Ronald Reed Sr | male | 18 July 1934 | 2 May 1995 | Paternal Reed | `LY94-373` |
| `P-0057` | Laura Kroll | female |  |  | Paternal Kroll | `L24Z-SFM` |
| `P-0058` | Isabelle Harriet Zika | female | 3 December 1913 | 13 October 2006 | Zika | `LY94-DBH` |
| `P-0059` | Ugo Mariotti | male | 21 July 1903 | 20 February 1982 | Maternal Mariotti | `PWPQ-D8V` |
| `P-0060` | Lena  A Dini | female | 16 June 1909 | 6 June 1988 | Maternal Mariotti | `L278-SXK` |
| `P-0061` | John Foulk Reed | male | 25 November 1877 | 30 March 1952 | Paternal Reed | `KLGC-TLC` |
| `P-0062` | Earl Wayne Reed Sr | male | 19 July 1899 | 11 April 1974 | Paternal Reed | `M3P5-XF6` |
| `P-0063` | Estella Gertrude Lambert | female | 30 October 1882 | 20 May 1946 | Maternal Lambert | `LMWG-K6F` |
| `P-0064` | John Francis Zika | male | 10 October 1875 | 9 June 1957 | Zika | `L2XV-HRY` |
| `P-0065` | Louis Dini | male | 1873 |  | Maternal Mariotti | `GCKQ-RK3` |
| `P-0066` | Zelinda Pagni | female | 6 September 1874 | 9 November 1936 | Maternal Mariotti | `GCKQ-6RJ` |
| `P-0067` | Leopoldo Mariotti | male | 29 October 1871 | 3 March 1933 | Maternal Mariotti | `PWPW-LPC` |
| `P-0068` | Beatrice Delina Pouliot | female | 14 April 1878 | 1 August 1964 | Pouliot | `LBHY-3B5` |
| `P-0069` | Quintilia Lenzi | female | 23 November 1876 | 9 September 1960 | Maternal Mariotti | `PWP7-JQ8` |
| `P-0070` | John Talley Reed | male | 26 June 1841 | 11 November 1903 | Paternal Reed | `L487-WDC` |
| `P-0071` | Elizabeth Willey | female | 26 June 1846 | 21 December 1880 | Paternal Reed | `KJP4-9R4` |
| `P-0072` | Abiram Stacy Lambert | male | 9 January 1831 | 28 April 1927 | Maternal Lambert | `2WFL-ZVT` |
| `P-0073` | Celestino Dini | male | 23 September 1845 |  | Maternal Mariotti | `GSQJ-M1C` |
| `P-0074` | Helen Amelia Boles | female | 10 June 1849 | 23 January 1939 | *NULL — review* | `29WD-T9P` |
| `P-0075` | Anton Zika | male | 22 July 1848 | 22 December 1924 | Zika | `LKTC-D4S` |
| `P-0076` | Henriette St. Louis | female | 17 October 1840 | 22 January 1890 | *NULL — review* | `MGNK-YL2` |
| `P-0077` | Josephine Riha Veta | female | 22 April 1854 | before 1964 | *NULL — review* | `LBH1-TK2` |
| `P-0078` | Paul Pouliot | male | 24 March 1834 | 10 May 1903 | Pouliot | `96JW-KX5` |
| `P-0079` | Angiolo Pagni | male | 1847 | 3 January 1925 | Maternal Mariotti | `P7P4-4TS` |
| `P-0080` | Maria Emilia Dini | female | 8 June 1843 | 26 November 1913 | Maternal Mariotti | `P99J-6YC` |
| `P-0081` | Cherubina Giorgi | female | 2 July 1844 |  | Maternal Mariotti | `P3YM-9YQ` |
| `P-0082` | Bonam Reed | male | 3 June 1816 | 13 December 1893 | Paternal Reed | `27XF-VBH` |
| `P-0083` | Rebecca Talley | female | 7 November 1822 | 16 July 1911 | Paternal Reed | `L7J3-GVG` |
| `P-0084` | David Lambert | male | 17 January 1790 | 15 December 1865 | Maternal Lambert | `L7XP-Y6P` |
| `P-0085` | Permelia Barnard | female | 12 June 1798 | 15 December 1865 | Paternal Reed | `LDFM-SM7` |
| `P-0086` | Silas A. Boles | male | 28 April 1819 | 3 April 1900 | *NULL — review* | `KN1Q-9L5` |
| `P-0087` | František Zíka | male | 27 April 1801 | 3 July 1872 | Zika | `GWCT-J3K` |
| `P-0088` | Marie Anna Říhová | female | 21 March 1820 | 18 October 1871 | *NULL — review* | `GWCT-VWD` |
| `P-0089` | Františka Klusová | female | before 1840 | before 1950 | *NULL — review* | `GWCT-JQN` |
| `P-0090` | František Říha | male | before 1840 | before 1960 | *NULL — review* | `GS6J-92Z` |
| `P-0091` | Francois Pouliot | male | 20 May 1805 | 13 June 1858 | Pouliot | `KCTF-J6N` |
| `P-0092` | Martha Lovina Spears | female | 25 April 1823 | 24 December 1895 | *NULL — review* | `KN1Q-GH1` |
| `P-0093` | Joseph Filiatrault dit St. Louis | male |  |  | *NULL — review* | `GYV7-TRD` |
| `P-0094` | Julie Audet dit Lapointe | female | 1 March 1812 | 3 April 1894 | *NULL — review* | `96JW-KFH` |
| `P-0095` | Domenico Dini | male | 1806 | 18 October 1888 | Maternal Mariotti | `PMCT-5RX` |
| `P-0096` | Pasqua Rosa Spadoni | female | about 1805 |  | Maternal Mariotti | `GSQJ-4RC` |
| `P-0097` | Henriette Cheffre | female |  |  | *NULL — review* | `GYVW-44Y` |
| `P-0098` | Leopoldo Pagni | male | about 1810 |  | Maternal Mariotti | `P7PW-CCK` |
| `P-0099` | Giovanni Dini | male | 1803 | 22 December 1878 | Maternal Mariotti | `P355-XWC` |
| `P-0100` | Maria Cristiana Niccolai | female | 1807 | 29 September 1870 | Maternal Mariotti | `PMCT-ZRN` |
| `P-0101` | Piera Bellandi | female | about 1815 | after 1872 | *NULL — review* | `PC4W-R8N` |
| `P-0102` | Pellegrino Giorgi | male |  |  | Maternal Mariotti | `P7P4-8PM` |
| `P-0103` | Nancy Walls | female |  |  | *NULL — review* | `K4BN-VM7` |
| `P-0104` | Thomas Spear | male |  |  | *NULL — review* | `K8F2-Y27` |
| `P-0105` | Sherebiah Lambert Jr | male | 11 September 1759 | 1 May 1833 | Maternal Lambert | `LDF8-39B` |
| `P-0106` | Permelia "Millie" Oaks | female | 11 September 1768 | 6 January 1845 | *NULL — review* | `LZNM-W98` |
| `P-0107` | Martin Zíka | male | 7 November 1769 |  | Zika | `L2V1-YHK` |
| `P-0108` | Barbora Michalíčková | female | 2 May 1776 | 7 May 1863 | *NULL — review* | `GWCT-BFG` |
| `P-0109` | František Říha | male | 9 January 1788 | 23 December 1848 | *NULL — review* | `GWCY-7JL` |
| `P-0110` | Pierre Pouliot | male | 28 August 1775 | 8 April 1845 | Pouliot | `KZXQ-XCP` |
| `P-0111` | Therese Denis Lapierre | female | 22 June 1779 | 20 November 1846 | *NULL — review* | `KCYF-LFN` |
| `P-0112` | Michel Olivier Audet | male | 12 March 1778 | 14 November 1848 | *NULL — review* | `MJ8T-X8V` |
| `P-0113` | Marie Louise Tremblay | female | 24 December 1782 | 7 August 1869 | *NULL — review* | `LHJ9-SLF` |
| `P-0114` | Marie Zemanová | female | 10 October 1797 | 19 December 1853 | *NULL — review* | `GWCY-M48` |
| `P-0115` | Pietro Dini | male |  |  | Maternal Mariotti | `P355-FRN` |
| `P-0116` | Elisabetta Giovacchini | female |  |  | *NULL — review* | `P35T-Q4G` |
| `P-0117` | Pier Domenico Spadoni | male | about 1774 | 3 April 1864 | Maternal Mariotti | `GRLV-XZB` |
| `P-0118` | Maria Angiola Ercolini | female | about 1780 |  | *NULL — review* | `GRLV-YDR` |
| `P-0119` | Annunziata Grossi | female |  |  | *NULL — review* | `P99N-599` |
| `P-0120` | MARIA UMILTA' PORCIANI | female | 1787 | 4 November 1854 | Maternal Mariotti | `GBF4-PH4` |
| `P-0121` | Carlo Dini | male |  |  | Maternal Mariotti | `P99N-2W1` |
| `P-0122` | ANGIOLO NICCOLAI | male | 27 February 1780 | 20 December 1862 | Maternal Mariotti | `GBFH-79H` |
| `P-0123` | Priscilla Foulk | female | 3 March 1775 | 3 March 1802 | *NULL — review* | `K262-J62` |
| `P-0124` | Harman Talley | male | 28 April 1775 | 24 August 1858 | Paternal Reed | `L7NJ-XMX` |
| `P-0125` | Sarah Brown | female | 1758 | July 1794 | *NULL — review* | `L8J2-MLN` |
| `P-0126` | Ann Patton | female | about 1760 |  | *NULL — review* | `KVJJ-2F9` |
| `P-0127` | Richard R. Dickerson Sr. | male | 1748 | 1836 | *NULL — review* | `L8J2-M2Y` |
| `P-0128` | Simon Poulson lll | male | 16 October 1752 | 1 October 1801 | *NULL — review* | `KVJJ-262` |
| `P-0129` | Absalom Willey | male | 6 May 1739 | 19 December 1791 | Paternal Reed | `LTCY-1RM` |
| `P-0130` | Margaret Polk | female | 14 November 1741 | 3 January 1816 | *NULL — review* | `GSMH-72F` |
| `P-0131` | Deliverance Owen | female | 13 August 1754 | 1821 | *NULL — review* | `2CND-ZJ7` |
| `P-0132` | Benjamin Dye | male | 1755 | 2 April 1789 | Paternal Reed | `GDZ6-V7D` |
| `P-0133` | John Thomas Thurlow Jr | male | 26 September 1745 | 22 September 1835 | *NULL — review* | `24C5-JCJ` |
| `P-0134` | Asher Allen | male | 22 May 1756 | 5 February 1840 | Paternal Reed | `97RN-BFV` |
| `P-0135` | Elizabeth Lemley | female | 23 June 1756 | 1 May 1792 | Paternal Reed | `M3G6-T7D` |
| `P-0136` | Lydia Hopkins | female | 16 April 1737 | 5 March 1826 | *NULL — review* | `G8SF-YZH` |
| `P-0137` | Elizabeth Polly Palmer | female | 14 November 1757 | 23 July 1851 | *NULL — review* | `2S2L-ZGM` |
| `P-0138` | Sherebiah Lambert Sr. | male | 28 March 1728 | 1 May 1833 | *NULL — review* | `L7NQ-CKX` |
| `P-0139` | Mabel Pinney | female | 30 September 1723 | 1783 | *NULL — review* | `L5ZR-LXX` |
| `P-0140` | Abigail Whitney Rand | female | 14 November 1736 | 1813 | *NULL — review* | `LHKW-2DG` |
| `P-0141` | Edward Ebenezer Barnard | male | 8 September 1710 | 5 February 1783 | Paternal Reed | `L5ZR-PVC` |
| `P-0142` | Deacon Francis Barnard | male | 9 September 1719 | 22 February 1789 | Paternal Reed | `LCB7-QL6` |
| `P-0143` | Lucretia Carroll Pinney | female | 17 January 1722 | 26 October 1773 | *NULL — review* | `LD9K-29K` |
| `P-0144` | Jonathan Abel Oakes | male | 21 August 1717 | 2 December 1784 | *NULL — review* | `LZP7-DSJ` |
| `P-0145` | Jan Zíka | male | 24 May 1729 | 3 August 1810 | Zika | `GWCT-J7B` |
| `P-0146` | Františka Doležalová | female | about 1730 | 29 November 1805 | *NULL — review* | `GWCT-1N1` |
| `P-0147` | Antonín Zeman | male |  |  | *NULL — review* | `GPDL-R79` |
| `P-0148` | František Jan Michalíček | male | 1745 | 1800 | *NULL — review* | `PH93-RMY` |
| `P-0149` | Eva Zemanová | female |  |  | *NULL — review* | `GT5S-14P` |
| `P-0150` | Václav Říha | male |  |  | *NULL — review* | `GPDL-25D` |
| `P-0151` | Magdalena Dufková | female | 1747 |  | *NULL — review* | `PH93-PYK` |
| `P-0152` | Magdalena Říhová | female |  |  | *NULL — review* | `GT5S-PGJ` |
| `P-0153` | Genevieve Godbout | female | 5 March 1753 | 29 May 1810 | *NULL — review* | `LJYN-TJY` |
| `P-0154` | Pierre Pouliot | male | 23 May 1749 | 8 July 1822 | Pouliot | `L4QP-2GB` |
| `P-0155` | Marie Louise St-Mars | female | 26 October 1739 | before 17 March 1792 | *NULL — review* | `L8PT-TR4` |
| `P-0156` | Jacques Denis | male | 18 June 1732 | 6 May 1810 | *NULL — review* | `KK1G-S62` |
| `P-0157` | Marie Angelique Pépin dit Lachance | female | 9 November 1747 | 21 March 1826 | *NULL — review* | `LRD1-TMD` |
| `P-0158` | Guillaume Audet | male | 8 March 1742 | 18 May 1805 | *NULL — review* | `LRQ4-GD9` |
| `P-0159` | Jacques Tremblay | male | 9 November 1744 | 20 January 1810 | *NULL — review* | `KLLJ-SJR` |
| `P-0160` | Marie Angelique Delage | female | 23 October 1738 | 16 June 1810 | *NULL — review* | `KN1W-474` |
| `P-0161` | Giovan Pietro Spadoni | male | 2 April 1725 |  | Maternal Mariotti | `GRL2-KCR` |
| `P-0162` | Maria Pasqua Baldi | female | about 1730 |  | *NULL — review* | `GRLP-TVD` |
| `P-0163` | PIER DOMENICO NICCOLAI | male | 12 March 1761 | 23 December 1846 | Maternal Mariotti | `GBF4-TKM` |
| `P-0164` | UMILTA' GIACOMELLI | female | 1763 | 29 December 1823 | *NULL — review* | `GBFH-HZV` |
| `P-0165` | GIUSEPPE PORCIANI | male |  |  | Maternal Mariotti | `PM4B-PBP` |
| `P-0166` | CATERINA PARLANTI | female |  |  | *NULL — review* | `PM4B-ZZR` |

## People needing branch assignment

- `P-0074` Helen Amelia Boles (surname `Boles`)
- `P-0076` Henriette St. Louis (surname `Louis`)
- `P-0077` Josephine Riha Veta (surname `Veta`)
- `P-0086` Silas A. Boles (surname `Boles`)
- `P-0088` Marie Anna Říhová (surname `Říhová`)
- `P-0089` Františka Klusová (surname `Klusová`)
- `P-0090` František Říha (surname `Říha`)
- `P-0092` Martha Lovina Spears (surname `Spears`)
- `P-0093` Joseph Filiatrault dit St. Louis (surname `Louis`)
- `P-0094` Julie Audet dit Lapointe (surname `Lapointe`)
- `P-0097` Henriette Cheffre (surname `Cheffre`)
- `P-0101` Piera Bellandi (surname `Bellandi`)
- `P-0103` Nancy Walls (surname `Walls`)
- `P-0104` Thomas Spear (surname `Spear`)
- `P-0106` Permelia "Millie" Oaks (surname `Oaks`)
- `P-0108` Barbora Michalíčková (surname `Michalíčková`)
- `P-0109` František Říha (surname `Říha`)
- `P-0111` Therese Denis Lapierre (surname `Lapierre`)
- `P-0112` Michel Olivier Audet (surname `Audet`)
- `P-0113` Marie Louise Tremblay (surname `Tremblay`)
- `P-0114` Marie Zemanová (surname `Zemanová`)
- `P-0116` Elisabetta Giovacchini (surname `Giovacchini`)
- `P-0118` Maria Angiola Ercolini (surname `Ercolini`)
- `P-0119` Annunziata Grossi (surname `Grossi`)
- `P-0123` Priscilla Foulk (surname `Foulk`)
- `P-0125` Sarah Brown (surname `Brown`)
- `P-0126` Ann Patton (surname `Patton`)
- `P-0127` Richard R. Dickerson Sr. (surname `Dickerson.`)
- `P-0128` Simon Poulson lll (surname `lll`)
- `P-0130` Margaret Polk (surname `Polk`)
- `P-0131` Deliverance Owen (surname `Owen`)
- `P-0133` John Thomas Thurlow Jr (surname `Thurlow`)
- `P-0136` Lydia Hopkins (surname `Hopkins`)
- `P-0137` Elizabeth Polly Palmer (surname `Palmer`)
- `P-0138` Sherebiah Lambert Sr. (surname `Lambert.`)
- `P-0139` Mabel Pinney (surname `Pinney`)
- `P-0140` Abigail Whitney Rand (surname `Rand`)
- `P-0143` Lucretia Carroll Pinney (surname `Pinney`)
- `P-0144` Jonathan Abel Oakes (surname `Oakes`)
- `P-0146` Františka Doležalová (surname `Doležalová`)
- `P-0147` Antonín Zeman (surname `Zeman`)
- `P-0148` František Jan Michalíček (surname `Michalíček`)
- `P-0149` Eva Zemanová (surname `Zemanová`)
- `P-0150` Václav Říha (surname `Říha`)
- `P-0151` Magdalena Dufková (surname `Dufková`)
- `P-0152` Magdalena Říhová (surname `Říhová`)
- `P-0153` Genevieve Godbout (surname `Godbout`)
- `P-0155` Marie Louise St-Mars (surname `St-Mars`)
- `P-0156` Jacques Denis (surname `Denis`)
- `P-0157` Marie Angelique Pépin dit Lachance (surname `Lachance`)
- `P-0158` Guillaume Audet (surname `Audet`)
- `P-0159` Jacques Tremblay (surname `Tremblay`)
- `P-0160` Marie Angelique Delage (surname `Delage`)
- `P-0162` Maria Pasqua Baldi (surname `Baldi`)
- `P-0164` UMILTA' GIACOMELLI (surname `GIACOMELLI`)
- `P-0166` CATERINA PARLANTI (surname `PARLANTI`)

## New Places

| new id | name | lat | long | quality |
|---|---|---|---|---|
| `PL-0155` | County Dublin, Ireland | 53.3522 | -6.26 | county |
| `PL-0158` | Chicago, Cook, Illinois, United States | 41.8853 | -87.6338 | settlement |
| `PL-0159` | Aurora, Kane, Illinois, United States | 41.7606 | -88.32 | settlement |
| `PL-0163` | Glen Ellyn, DuPage, Illinois, United States | 41.8775 | -88.0669 | settlement |
| `PL-0172` | Schaumburg, Cook, Illinois, United States | 42.0333 | -88.0833 | settlement |
| `PL-0178` | Cintolese, Monsummano Terme, Pistoia, Tuscany, Italy | 43.843651 | 10.827214 | settlement |
| `PL-0179` | Cicero, Cook, Illinois, United States | 41.8456 | -87.7539 | settlement |
| `PL-0187` | Berwyn, Cook, Illinois, United States | 41.8506 | -87.7936 | settlement |
| `PL-0196` | Monteith, Guthrie, Iowa, United States | 41.6314 | -94.4283 | settlement |
| `PL-0197` | Davenport, Scott, Iowa, United States | 41.5236 | -90.5775 | settlement |
| `PL-0208` | Guthrie, Iowa, United States | 41.683329 | -94.500559 | settlement |
| `PL-0220` | Seely Township, Guthrie, Iowa, United States | 41.73806 | -94.56944 | township |
| `PL-0233` | Beneschau, Bohemia, Austria | 49.666667 | 14.75 | settlement |
| `PL-0247` | Italy | 43.1 | 12.3 | region |
| `PL-0262` | Spianate, Altopascio, Lucca, Tuscany, Italy | 43.808888 | 10.714703 | settlement |
| `PL-0278` | Cintolese, Monsummano, Pistoia, Tuscany, Italy | 43.843651 | 10.827214 | settlement |
| `PL-0327` | Woodsfield, Monroe, Ohio, United States | 39.763588 | -81.114723 | settlement |
| `PL-0328` | Valley Township, Guthrie, Iowa, United States | 41.64472 | -94.46056 | township |
| `PL-0347` | Noble Township, Morgan, Ohio, United States | 39.78528 | -81.54222 | township |
| `PL-0367` | Salem, Washington Township, Washington, Indiana, United States | 38.6056 | -86.1011 | settlement |
| `PL-0368` | Falls City, Lincoln, Idaho, United States | 42.6806 | -114.4233 | settlement |
| `PL-0390` | Ponte Buggianese, Pistoia, Tuscany, Italy | 43.841 | 10.7476 | settlement |
| `PL-0413` | Hillsdale, Michigan, United States | 41.91695 | -84.62055 | settlement |
| `PL-0506` | Saint-Laurent, L'Île-d'Orléans, Quebec, Canada | 46.8664 | -71.0116 | settlement |
| `PL-0531` | Pescia, Lucca, Tuscany, Italy | 43.9078 | 10.6888 | settlement |
| `PL-0557` | Chiesina Uzzanese, Pistoia, Tuscany, Italy | 43.8415 | 10.719 | settlement |
| `PL-0610` | Wills Creek, Coshocton, Ohio, United States | 40.18 | -81.8508 | settlement |
| `PL-0638` | Morgan, Ohio, United States | 39.616669 | -81.83333 | settlement |
| `PL-0667` | Canaan, Somerset, Maine, United States | 44.7783 | -69.545 | settlement |
| `PL-0668` | Shellsburg, Benton, Iowa, United States | 42.0922 | -91.8717 | settlement |
| `PL-0699` | Rome, Oneida, New York, United States | 43.2196 | -75.4559 | settlement |
| `PL-0731` | Saratoga, New York, United States | 43.1 | -73.85 | settlement |
| `PL-0732` | Bayard, Guthrie, Iowa, United States | 41.8519 | -94.5581 | settlement |
| `PL-0931` | Trumbull, Ohio, United States | 41.31667 | -80.76667 | settlement |
| `PL-1000` | Saint-Jean-Baptiste, Montmorency No. 2, Quebec, Canada | 46.9219 | -70.8892 | settlement |
| `PL-1001` | Saint-Laurent, Montmorency No. 2, Quebec, Canada | 46.8664 | -71.0116 | settlement |
| `PL-1038` | Albinatico, Ponte Buggianese, Buggiano, Lucca, Tuscany, Italy | 43.846949 | 10.759054 | settlement |
| `PL-1039` | Albinatico, Ponte Buggianese, Pistoia, Tuscany, Italy | 43.846949 | 10.759054 | settlement |
| `PL-1230` | Monsummano, Lucca, Tuscany | 43.8722 | 10.8157 | settlement |
| `PL-1426` | Wiscasset, Wiscasset, Lincoln, Massachusetts, United States | 44.00278 | -69.66611 | settlement |
| `PL-1467` | Harvard, Worcester, Massachusetts Bay Colony, British Colonial America | 42.51667 | -71.58333 | settlement |
| `PL-1550` | Vrazdovy Lhotice, Benešov, Czechia | 49.640172 | 15.180023 | settlement |
| `PL-1635` | St-Laurent-de-l'Île-d'Orléans Cemetery, Saint-Laurent, L'Île-d'Orléans, Quebec, Canada | 45.51385 | -73.67387 | cemetery |
| `PL-1765` | Saint-Jean, Orléans, Lower Canada, British North America | 46.9203 | -70.89 | settlement |
| `PL-1810` | Wonschow, Ledeč, Bohemia, Austria | 49.5782 | 15.1364 | settlement |
| `PL-2171` | Montevettolini, Monsummano Terme, Pistoia, Tuscany, Italy | 43.85776 | 10.84366 | settlement |
| `PL-2218` | New Castle, Delaware, British Colonial America | 39.582 | -75.652 | settlement |
| `PL-2219` | Wilmington, New Castle, Delaware, United States | 39.7458 | -75.5469 | settlement |
| `PL-2268` | Piasa, Macoupin, Illinois, United States | 39.1158 | -90.1236 | settlement |
| `PL-2318` | Frederick, Maryland, British Colonial America | 39.467 | -77.4 | settlement |
| `PL-2319` | Washington, Upper Mifflin Township, Cumberland, Pennsylvania, United States | 40.2022 | -77.4783 | settlement |
| `PL-2371` | New Castle, New Castle, Delaware, United States | 39.6619 | -75.5667 | settlement |
| `PL-2424` | Fort Hill, Upper Turkeyfoot Township, Somerset, Pennsylvania, United States | 39.8303 | -79.2728 | settlement |
| `PL-2425` | Liberty, Guernsey, Ohio, United States | 40.1509 | -81.5728 | settlement |
| `PL-2480` | Mill Creek Hundred, New Castle, Delaware, United States | 39.7667 | -75.6833 | township |
| `PL-2536` | Nanticoke Hundred, Sussex, Delaware, British Colonial America | 38.7083 | -75.5083 | township |
| `PL-2593` | Sussex, Delaware, British Colonial America | 38.7 | -75.4167 | settlement |
| `PL-2594` | Morgantown, Monongalia, Virginia, United States | 39.62944 | -79.95611 | settlement |
| `PL-2653` | Rowley, Essex, Massachusetts Bay Colony, British Colonial America | 42.71807 | -70.878 | settlement |
| `PL-2713` | Cranbury Township, Middlesex, New Jersey, United States | 40.3125 | -74.5333 | township |
| `PL-2714` | Greene Township, Washington, Pennsylvania, United States | 39.82152 | -80.01579 | township |
| `PL-2776` | Newbury, Essex, Massachusetts Bay Colony, British Colonial America | 42.77917 | -70.88333 | settlement |
| `PL-2777` | Olive Township, Morgan, Ohio, United States | 39.7311 | -81.515 | township |
| `PL-2841` | Mansfield, Windham, Connecticut Colony, British Colonial America | 41.78833 | -72.22944 | settlement |
| `PL-2842` | Washington, Ohio, United States | 39.50139 | -81.416668 | settlement |
| `PL-2908` | Montgomery, Pennsylvania, United States | 40.211 | -75.368 | settlement |
| `PL-2975` | Billerica, Middlesex, Massachusetts, United States | 42.559 | -71.269 | settlement |
| `PL-2976` | Stoddard, Cheshire, New Hampshire, United States | 43.079 | -72.1149 | settlement |
| `PL-3045` | Highland, Ohio, United States | 39.183329 | -83.616669 | settlement |
| `PL-3115` | York, York, Maine, United States | 43.154 | -70.65 | settlement |
| `PL-3186` | Windsor, Hartford, Connecticut Colony, British Colonial America | 41.85352 | -72.64641 | settlement |
| `PL-3258` | Sangerville, Piscataquis, Maine, United States | 45.1654 | -69.355 | settlement |
| `PL-3331` | Windsor, Hartford, Connecticut, United States | 41.85352 | -72.64641 | settlement |
| `PL-3478` | Wintonbury Parish, Windsor, Hartford, Connecticut Colony, British Colonial America | 41.8442 | -72.7419 | settlement |
| `PL-3553` | Marlborough, Middlesex, Massachusetts Bay Colony, British Colonial America | 42.345829 | -71.552779 | settlement |
| `PL-3854` | Tomice, Benešov, Czechia | 49.64507 | 15.15602 | settlement |
| `PL-4083` | Košetice, Pelhřimov, Czechia | 49.55791 | 15.1156 | settlement |
| `PL-4392` | Saint-Laurent, Montreal, Canada, New France | 45.5141 | -73.6746 | settlement |
| `PL-4471` | Saint-Laurent, Saint-Laurent, Québec, Canada, New France | 46.8664 | -71.0116 | settlement |
| `PL-4472` | Saint-Laurent, Orléans, Lower Canada, British North America | 46.8664 | -71.0116 | settlement |
| `PL-4553` | Saint-Jean, Trois-Rivières, Canada, New France | 46.5564 | -72.116 | settlement |
| `PL-4635` | Saint-Jean-Baptiste, L'Île-d'Orléans, Quebec, Canada | 46.9219 | -70.8892 | settlement |
| `PL-4636` | Saint-Laurent, Québec, Canada, New France | 46.9355 | -70.9547 | settlement |
| `PL-4720` | Saint-Pierre, Saint-Laurent, Québec, Canada, New France | 46.8885 | -71.0751 | settlement |
| `PL-4805` | Île d'Orléans, Montmorency No. 2, Quebec, Canada | 46.9322 | -70.9293 | settlement |
| `PL-5231` | Monsummano Terme, Pistoia, Tuscany, Italy | 43.8715 | 10.8145 | settlement |

## Skipped

- `L274-KK8` Gerald Kenny — living (privacy)
- `PQCN-4WD` Celine Wysgalla — proband or spouse
- `L274-K2C` Karen Reed - Kenny — living (privacy)
- `L274-KNT` John Kenny — proband or spouse
- `LCTG-MNQ` James Willey — already linked via fs_id
- `LCTG-MKP` Emily Thorla — already linked via fs_id
- `2MRH-9JF` Hannah Paulson — already linked via fs_id
- `L7NJ-1S1` John Foulk Talley — already linked via fs_id
- `LHW8-G58` William Polk Willey — already linked via fs_id
- `991N-J11` Sarah Dickerson — already linked via fs_id
- `278F-M4D` Sarah Dye — already linked via fs_id
- `LZDK-YP8` Benjamin Reed — already linked via fs_id
- `KLYD-X1Q` Benjamin Thorla — already linked via fs_id
- `2S2L-ZYQ` Elizabeth Allen — already linked via fs_id
- `L5ZT-BM5` Roxana Desire Barnard — already linked via fs_id
- `LHFS-KPJ` Samuel R Barnard — already linked via fs_id
- `LCJK-F8G` Else Alice Bonham — already linked via fs_id
- `LC5Y-HJ1` Stephen Reed — already linked via fs_id