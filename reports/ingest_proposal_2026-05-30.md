# FS Ingest Proposal — 2026-05-30

- To-ingest People: **674**
- To-create Places: **445**
- People with `branch=NULL` after heuristic (need manual assignment): **637**
- Skipped: **56** (proband/spouse, already-linked via fs_id, or living)

## Branch heuristic

Surname → branch mapping is in `scripts/ingest_familysearch.py`. Mapped surnames:
`Reed` → `Paternal Reed`, `Talley` → `Paternal Reed`, `Willey` → `Paternal Reed`, `Thorla` → `Paternal Reed`, `Thorley` → `Paternal Reed`, `Dickerson` → `Paternal Reed`, `Cook` → `Paternal Reed`, `Bonham` → `Paternal Reed`, `Paulson` → `Paternal Reed`, `Paulsen` → `Paternal Reed`, `Poulson` → `Paternal Reed`, `Barnard` → `Paternal Reed`, `Dye` → `Paternal Reed`, `Allen` → `Paternal Reed`, `Lemley` → `Paternal Reed`, `Kenny` → `Paternal Kenny`, `Kroll` → `Paternal Kroll`, `Mariotti` → `Maternal Mariotti`, `Lambert` → `Maternal Lambert`, `Pouliot` → `Pouliot`, `Zika` → `Zika`, `Zíka` → `Zika`, `Niccolai` → `Maternal Mariotti`, `Porciani` → `Maternal Mariotti`, `Dini` → `Maternal Mariotti`, `Pagni` → `Maternal Mariotti`, `Spadoni` → `Maternal Mariotti`, `Giorgi` → `Maternal Mariotti`, `Lenzi` → `Maternal Mariotti`, `Bartoletti` → `Maternal Mariotti`, `Marchi` → `Maternal Mariotti`, `Lapini` → `Maternal Mariotti`, `NICCOLAI` → `Maternal Mariotti`, `PORCIANI` → `Maternal Mariotti`

## New People

| new id | name | sex | birth | death | branch | fs_id |
|---|---|---|---|---|---|---|
| `P-0169` | Benjamin Reed | male | 24 March 1734 |  | Paternal Reed | `PZ8T-G62` |
| `P-0170` | Jemima Green | female | 2 August 1742 | 4 April 1800 | *NULL — review* | `K2Q9-B41` |
| `P-0171` | Hezekiah Bonham III | male | 1725 | 1763 | Paternal Reed | `L63D-BWR` |
| `P-0172` | Martha Runyan | female | 1735 | 1771 | *NULL — review* | `GPV5-LPL` |
| `P-0173` | John Dickerson | male | 11 February 1721 | 15 March 1785 | Paternal Reed | `9V31-GLZ` |
| `P-0174` | Mary Ruth Adams | female | 1723 | December 1807 | *NULL — review* | `LC52-2T8` |
| `P-0175` | Gideon Dickerson | male |  |  | Paternal Reed | `LVFW-SXF` |
| `P-0176` | Eliza Gunn | female |  |  | *NULL — review* | `LVFW-SKJ` |
| `P-0177` | Joseph Green Sr | male | 1698 | 12 March 1784 | *NULL — review* | `L89C-MQM` |
| `P-0178` | Elizabeth Ann Mershon | female | 22 June 1714 | 12 March 1784 | *NULL — review* | `LHWH-LMJ` |
| `P-0179` | Hezekiah Bonham Jr. II | male | 1701 | 16 April 1763 | *NULL — review* | `LC8B-QNB` |
| `P-0180` | Martha Runyon | female | June 1704 | 1753 | *NULL — review* | `LHZY-DBH` |
| `P-0181` | Vincent Runyon Sr. | male | 4 April 1702 | 27 October 1770 | *NULL — review* | `LCSB-PC6` |
| `P-0182` | Alice Curtis | female | 1704 | 1742 | *NULL — review* | `9VCV-ZVJ` |
| `P-0183` | Henry Dickerson | male | about 1685 | 1785 | Paternal Reed | `LRQZ-QDQ` |
| `P-0184` | Sabrina Susannah Sarratt | female | 1685 | 1765 | *NULL — review* | `P953-QT9` |
| `P-0185` | William Green | male | about 1670 | 16 June 1722 | *NULL — review* | `LZJW-1PW` |
| `P-0186` | Joanna Reeder | female | 13 June 1669 | after 12 September 1734 | *NULL — review* | `L6C6-5ZF` |
| `P-0187` | Henry Mershon II | male | 10 October 1672 | 20 September 1738 | *NULL — review* | `M576-6ZZ` |
| `P-0188` | Hannah Haughton | female | 1 January 1679 | 20 October 1738 | *NULL — review* | `LCVZ-VBH` |
| `P-0189` | Hezekiah Bonham Sr | male | 6 May 1667 | 27 January 1738 | Paternal Reed | `LDMF-GFZ` |
| `P-0190` | Ann Hunt | female | 1680 |  | *NULL — review* | `LL97-K91` |
| `P-0191` | Thomas Runyan | male | about 1673 | before 16 April 1753 | *NULL — review* | `LZZ3-XNG` |
| `P-0192` | Martha Dunn | female | 13 July 1681 | after 16 April 1753 | *NULL — review* | `LZLX-LY2` |
| `P-0193` | Thomas Curtis | male | 7 September 1659 | May 1748 | *NULL — review* | `LCTH-XG8` |
| `P-0194` | Elizabeth Ellis | female | 3 February 1670 | 1732 | *NULL — review* | `KCHF-7GN` |
| `P-0195` | Thomas Dickerson Sr. | male | 1657 | 18 January 1724 | *NULL — review* | `MKBD-SW7` |
| `P-0196` | Elizabeth Isabella Gambray | female | 6 December 1646 | 1713 | *NULL — review* | `GWS9-1ND` |
| `P-0197` | Joseph Jacques Surratt | male | 14 September 1662 | 18 January 1715 | *NULL — review* | `P953-M6F` |
| `P-0198` | Katherine Moreland Short | female | 1665 | 1717 | *NULL — review* | `G1HB-F53` |
| `P-0199` | John Willey | male | 1708 | 1742 | Paternal Reed | `P3WB-9J8` |
| `P-0200` | Priscilla Margaret Polk | female | 1711 | May 1759 | *NULL — review* | `L83N-ZQJ` |
| `P-0201` | Lt. James Knox Polk | male | 17 May 1719 | April 1771 | *NULL — review* | `LYMN-M4P` |
| `P-0202` | Mary Elizabeth Cottman | female | 1723 | 1744 | *NULL — review* | `GNKY-W1K` |
| `P-0203` | James O Dye | male | 1 January 1720 | 6 April 1764 | Paternal Reed | `LK4Y-B4R` |
| `P-0204` | Sarah J. Leach | female | 1 January 1724 | 31 October 1765 | *NULL — review* | `LZNC-CZM` |
| `P-0205` | Johann Esaias Lämlein | male | from 1712 to 1722 | about 26 August 1784 | *NULL — review* | `G9XJ-HVK` |
| `P-0206` | Catherine | female | 1724 | 1825 | *NULL — review* | `GH81-42P` |
| `P-0207` | Willey | male |  |  | Paternal Reed | `GKZL-6GJ` |
| `P-0208` | Ephraim Polk | male | 1671 | 1739 | *NULL — review* | `GNKY-7BR` |
| `P-0209` | Elizabeth Williams | female | 29 May 1674 | 24 March 1773 | *NULL — review* | `LV64-MGL` |
| `P-0210` | Benjamin Cottman III. | male | 1696 | 26 April 1767 | *NULL — review* | `LYGX-BZ5` |
| `P-0211` | Frances Brown | female | 1700 | August 1796 | *NULL — review* | `MZ2L-6KB` |
| `P-0212` | John Laurence Dye | male | 1 October 1687 | 8 March 1751 | Paternal Reed | `PWWX-6Z8` |
| `P-0213` | Anna Moor | female | 1687 |  | *NULL — review* | `PWY1-P89` |
| `P-0214` | Friderich Lemlein | male | about 1685 | after 1734 | *NULL — review* | `G5MP-9Y8` |
| `P-0215` | Maria Magdalena Waltz | female | about 1685 |  | *NULL — review* | `G58G-Z7Z` |
| `P-0216` | Capt. Robert Bruce Pollock | male | before 1625 | 5 June 1704 | *NULL — review* | `LR2V-J76` |
| `P-0217` | Magdalen Tasker | female | 1634 | March 1726 | *NULL — review* | `LBJN-L9R` |
| `P-0218` | Charles Williams | male | 1653 | 8 February 1737 | *NULL — review* | `K2NK-VHL` |
| `P-0219` | Mary Walston | female | 1657 | 10 September 1678 | *NULL — review* | `G4FX-4S1` |
| `P-0220` | Benjamin Cottman II | male | 29 March 1675 | 27 February 1748 | *NULL — review* | `LTCJ-1MS` |
| `P-0221` | Elizabeth Hardy | female | 25 November 1667 | 1715 | *NULL — review* | `LTCJ-BFB` |
| `P-0222` | Mr. Brown | male | about 1675 |  | *NULL — review* | `KZC8-4KS` |
| `P-0223` | Mrs. Brown | female | about 1679 |  | *NULL — review* | `K864-KBW` |
| `P-0224` | Hans Lauretzen Duyts | male | 23 September 1644 | 1708 | *NULL — review* | `P637-KJG` |
| `P-0225` | Sarah Hance Vincent-Fountaine | female | 28 February 1662 | 1740 | *NULL — review* | `P63Q-GWM` |
| `P-0226` | William Moor | male |  |  | *NULL — review* | `PC23-6D1` |
| `P-0227` | Annetje Jans | female |  |  | *NULL — review* | `PC23-C9X` |
| `P-0228` | Lämmlein | male |  |  | *NULL — review* | `G5NK-N9N` |
| `P-0229` | William Talley Jr. | male | 27 January 1747 | 9 May 1812 | *NULL — review* | `26KN-HXJ` |
| `P-0230` | Dinah Stille | female | 27 February 1751 | 9 May 1812 | *NULL — review* | `26KN-HV3` |
| `P-0231` | John Foulk | male | 22 April 1735 | 8 November 1820 | *NULL — review* | `L7NJ-F7S` |
| `P-0232` | Sarah Talley | female | 9 February 1736 | 6 September 1822 | Paternal Reed | `L7NJ-FCV` |
| `P-0233` | Simon Poulson Jr. | male | about 1724 | about 1764 | *NULL — review* | `KLC9-LP9` |
| `P-0234` | Eleanor West | female | 29 March 1721 | 29 April 1790 | *NULL — review* | `LT9F-VVQ` |
| `P-0235` | George Patton | male | about 1731 |  | *NULL — review* | `KLVC-1JH` |
| `P-0236` | Maria Sinnexon | female | 5 October 1733 |  | *NULL — review* | `KGQ1-9RF` |
| `P-0237` | Pvt. - MD William Talley Sr. | male | January 1714 | 17 August 1790 | *NULL — review* | `K26G-SJP` |
| `P-0238` | Hannah Grubb | female | 1717 | 1747 | *NULL — review* | `GZVK-3YJ` |
| `P-0239` | Jonathan Stille | male | 1709 | 21 April 1765 | *NULL — review* | `LZD4-GHS` |
| `P-0240` | Maria Magdalena Vandever | female | 5 November 1718 | 21 April 1765 | *NULL — review* | `2HMS-F2N` |
| `P-0241` | Stephen Foulk | male | 1704 | before 16 August 1787 | *NULL — review* | `LXQV-JGS` |
| `P-0242` | Esther Willis | female | 1708 | 1786 | *NULL — review* | `L69N-KXQ` |
| `P-0243` | Simon Poulson Sr | male | about 1690 |  | Paternal Reed | `2MRH-LLN` |
| `P-0244` | Mrs. Simon Poulson | female | about 1695 |  | Paternal Reed | `41RC-XBL` |
| `P-0245` | Thomas West | male | about 1689 | about 1743 | *NULL — review* | `LS6W-Z5H` |
| `P-0246` | Mary 'Jenny' Deane | female | about 1682 | about 1738 | *NULL — review* | `LKGD-4G7` |
| `P-0247` | Brewer Sinnexson | male | about 1703 | March 1756 | *NULL — review* | `LHQ3-XSN` |
| `P-0248` | Brita Hendrickson | female | 1705 | 27 March 1755 | *NULL — review* | `L41T-MWV` |
| `P-0249` | Thomas Talley | male | about 1689 | 1781 | Paternal Reed | `LH7D-M4Q` |
| `P-0250` | Elenger Johnson | female | 1691 | 1732 | *NULL — review* | `LH7D-M8W` |
| `P-0251` | Joseph Grubb | male | 11 November 1685 | 14 March 1747 | *NULL — review* | `L5V7-JFK` |
| `P-0252` | Elizabeth Perkins | female | 1685 | 14 March 1746 | *NULL — review* | `MFWS-62F` |
| `P-0253` | Jacob Anderson Stille Sr | male | 1680 | 6 February 1774 | *NULL — review* | `LBSF-V5X` |
| `P-0254` | Rebecca Charlesdotter Springer | female | 1 June 1689 | 10 October 1764 | *NULL — review* | `L437-PH3` |
| `P-0255` | Jacob Corneliusson Vandever | male | 1682 | 16 November 1739 | *NULL — review* | `LZX4-Z76` |
| `P-0256` | Maria Stedham | female | 1693 | 24 November 1764 | *NULL — review* | `LTHX-N76` |
| `P-0257` | William Foulk | male | about 1680 | 1720 | *NULL — review* | `LHDG-FY2` |
| `P-0258` | Elizabeth Cope | female | about 1680 | 23 January 1765 | *NULL — review* | `GQYG-K92` |
| `P-0259` | John Willis I | male | 6 March 1669 | 1745 | *NULL — review* | `L6MV-B1L` |
| `P-0260` | Esther Brinton | female | 9 October 1675 | 1715 | *NULL — review* | `L8M3-DPD` |
| `P-0261` | Bengt Paulson | male | 1657 | 9 September 1728 | Paternal Reed | `LHC7-YXX` |
| `P-0262` | Margareta Johansson | female | 9 September 1658 | September 1728 | *NULL — review* | `LJB3-5Y4` |
| `P-0263` | Major Thomas William West | male | about 1643 | 1735 | *NULL — review* | `MPYS-5C2` |
| `P-0264` | Rachel Gilpin | female | 14 April 1660 | 12 December 1700 | *NULL — review* | `9KZY-SL1` |
| `P-0265` | John Deane Alscollins | male | about 1632 | about 1693 | *NULL — review* | `21RR-LSH` |
| `P-0266` | Ellinor Wilson | female | 14 December 1654 | 9 November 1694 | *NULL — review* | `MYB3-ST8` |
| `P-0267` | James Sinnexon | male | 1669 | 1773 | *NULL — review* | `LVYM-N9X` |
| `P-0268` | Dorcas Harmensen | female | 1674 | 13 November 1723 | *NULL — review* | `LVYM-JQG` |
| `P-0269` | Johan "John" Hendrickson | male | 1663 | 7 November 1745 | *NULL — review* | `9KFZ-S4B` |
| `P-0270` | Brigitta Mattson | female | 1674 | 11 June 1750 | *NULL — review* | `G9FQ-SBX` |
| `P-0271` | John Thurlow Sr | male | 5 October 1726 | after 1790 | *NULL — review* | `LCMC-J5V` |
| `P-0272` | Ruth Stevens | female | 20 February 1724 | 1764 | *NULL — review* | `MN82-GKV` |
| `P-0273` | William Owen | male | 1733 | 29 June 1804 | *NULL — review* | `PMGG-6X8` |
| `P-0274` | Elizabeth Davis | female | 1738 | 3 May 1819 | *NULL — review* | `LYP7-2BX` |
| `P-0275` | Phineas Allen | male | 24 July 1731 | 21 December 1776 | Paternal Reed | `LCXK-MX4` |
| `P-0276` | Elizabeth Sargent | female | 5 February 1734 | 28 December 1776 | *NULL — review* | `MGKK-MV1` |
| `P-0277` | Joshua Palmer | male | 14 April 1731 | November 1758 | *NULL — review* | `KLYC-GFM` |
| `P-0278` | Ruth Sargeant | female | 14 October 1732 | 29 August 1808 | *NULL — review* | `KG8Z-TC9` |
| `P-0279` | Thomas Thurlo | male | 11 December 1701 | 28 October 1789 | *NULL — review* | `LJLB-GM4` |
| `P-0280` | Joanna Pike | female | 17 December 1700 | 21 December 1759 | *NULL — review* | `PZHH-861` |
| `P-0281` | John Stevens Jr. | male | 22 March 1674 | 8 November 1728 | *NULL — review* | `L5XW-3KG` |
| `P-0282` | Mary Bartlett | female | 17 April 1682 | February 1725 | *NULL — review* | `L1PQ-KP7` |
| `P-0283` | Robert Henry Owens | male | 1693 | 10 March 1750 | *NULL — review* | `PMGP-VXC` |
| `P-0284` | Patience Clifton | female | about 1700 | before 29 December 1759 | *NULL — review* | `L414-DDK` |
| `P-0285` | Timothy Allen | male | 22 February 1691 | 10 May 1755 | Paternal Reed | `94QS-95F` |
| `P-0286` | Rachel Bushnell | female | 27 October 1692 | 23 September 1774 | *NULL — review* | `LCCY-PKB` |
| `P-0287` | Isaac Sargeant | male | 24 February 1699 | 20 April 1742 | *NULL — review* | `LC53-ZCB` |
| `P-0288` | Anna Wood | female | 11 April 1700 | 30 July 1792 | *NULL — review* | `LZ6Y-SJV` |
| `P-0289` | Stephen Palmer | male | 1 May 1709 | 30 October 1775 | *NULL — review* | `KPWT-YYX` |
| `P-0290` | Elizabeth Quimby | female | 1707 | 18 October 1776 | *NULL — review* | `KPWT-YRD` |
| `P-0291` | George Thurlo | male | 12 March 1671 | 17 January 1713 | *NULL — review* | `LBRX-ZQS` |
| `P-0292` | Mary Adams | female | 16 January 1672 | 17 January 1714 | *NULL — review* | `L5ZC-FL8` |
| `P-0293` | John Pike | male | 28 December 1671 | 13 August 1752 | *NULL — review* | `L4HS-H16` |
| `P-0294` | Lydia Coffin | female | 22 April 1662 | 25 March 1719 | *NULL — review* | `LDLP-BCZ` |
| `P-0295` | John Stevens Sr | male | 19 November 1650 | 6 April 1725 | *NULL — review* | `LYB4-9D7` |
| `P-0296` | Mary Chase | female | 3 February 1650 | 6 April 1725 | *NULL — review* | `LYB4-QFV` |
| `P-0297` | Christopher Bartlett II | male | 11 June 1655 | 14 April 1711 | *NULL — review* | `LKTJ-ZMV` |
| `P-0298` | Deborah Weed | female | 15 June 1659 | 6 June 1726 | *NULL — review* | `LYJF-YHT` |
| `P-0299` | Robert Owens | male |  |  | *NULL — review* | `GVD6-NC3` |
| `P-0300` | Ann Lecompte | female | 1675 | 26 October 1767 | *NULL — review* | `GVD6-ZD3` |
| `P-0301` | Jonathan Clifton | male | 1684 | February 1732 | *NULL — review* | `PMG5-KP6` |
| `P-0302` | Mary Woodgate | female | August 1676 | 1770 | *NULL — review* | `LJ5V-V3J` |
| `P-0303` | Samuel Allen III | male | 4 December 1660 | 28 June 1750 | Paternal Reed | `LTTF-WCP` |
| `P-0304` | Rebecca Cary | female | 30 March 1665 | 29 October 1697 | *NULL — review* | `LHR8-N3T` |
| `P-0305` | Joseph Bushnell | male | 2 May 1651 | 23 December 1746 | *NULL — review* | `LZ4J-XY3` |
| `P-0306` | Mary Leffingwell | female | 10 December 1654 | 31 March 1745 | *NULL — review* | `MM2G-NS6` |
| `P-0307` | John Sargeant II | male | 10 February 1664 | 16 April 1755 | *NULL — review* | `L6NB-QQM` |
| `P-0308` | Mary Linnell | female | 15 December 1666 | 16 April 1755 | *NULL — review* | `LXSD-FMZ` |
| `P-0309` | Thomas Wood II | male | 10 August 1658 | 1 December 1702 | *NULL — review* | `LR5W-6ZV` |
| `P-0310` | Mary Hunt | female | 28 September 1664 | 7 November 1754 | *NULL — review* | `FYWM-4VF` |
| `P-0311` | Nehemiah Palmer Jr | male | 8 July 1677 | 1735 | *NULL — review* | `L4BH-JD9` |
| `P-0312` | Jerusha Saxton | female | 1683 | 1751 | *NULL — review* | `LZFX-CPJ` |
| `P-0313` | François Pouliot | male | 27 February 1708 | 29 March 1785 | Pouliot | `L4QP-LDQ` |
| `P-0314` | Marie Madeleine Chabot | female | 15 January 1719 | 23 April 1767 | *NULL — review* | `LZVT-5T3` |
| `P-0315` | Antoine Godebout | male | 15 January 1722 | 24 November 1797 | *NULL — review* | `LC7N-PYN` |
| `P-0316` | Marie Anne Leclerc | female | 1727 | 23 March 1812 | *NULL — review* | `LC7N-PYJ` |
| `P-0317` | Jacque Denis | male |  | 16 April 1758 | *NULL — review* | `L8PT-Y8W` |
| `P-0318` | Véronique Mathieu | female | 18 January 1704 | 29 July 1759 | *NULL — review* | `LHKW-3LD` |
| `P-0319` | Pierre Cinq-Mars dit Gobelin | male | 22 April 1698 | 22 October 1775 | *NULL — review* | `LH35-2MF` |
| `P-0320` | Genevieve Belanger | female | 31 December 1709 | 28 January 1785 | *NULL — review* | `L8PT-TY4` |
| `P-0321` | Jean Pouliot | male | 20 December 1674 | 1 June 1745 | Pouliot | `9WB4-TJK` |
| `P-0322` | Magdelaine Odet | female | 18 September 1677 | 8 November 1761 | *NULL — review* | `LT94-67F` |
| `P-0323` | Jean Chabot | male | 17 September 1693 | 6 November 1755 | *NULL — review* | `KHQ9-XVW` |
| `P-0324` | Marie Madelaine Dufresne | female | 17 June 1694 | 10 October 1736 | *NULL — review* | `LZVT-5SJ` |
| `P-0325` | Antoine Godebout | male | 27 August 1693 | 15 September 1749 | *NULL — review* | `M8B2-8NV` |
| `P-0326` | Genevieve Rouleau | female | 21 November 1696 | 17 December 1776 | *NULL — review* | `27C9-VD9` |
| `P-0327` | Jean Le Clerc | male | about April 1694 | 9 June 1772 | *NULL — review* | `MJFB-GQW` |
| `P-0328` | Marie Madeleine Gosselin | female | 22 May 1700 | 5 April 1750 | *NULL — review* | `LZFD-HBW` |
| `P-0329` | Pierre Denys | male | 10 April 1662 | 18 September 1727 | *NULL — review* | `LV7V-ZX9` |
| `P-0330` | Marie Godin | female | 27 April 1662 | about October 1733 | *NULL — review* | `LTN2-G8G` |
| `P-0331` | Rene Mathieu | male | 13 June 1674 | 16 October 1730 | *NULL — review* | `LHDT-9X4` |
| `P-0332` | Genevieve Roussin | female | 19 February 1681 | 21 March 1767 | *NULL — review* | `L8PT-YFM` |
| `P-0333` | Marc Antoine Cinq-Mars dit Gobelin | male | 1641 | 12 October 1699 | *NULL — review* | `ML69-RLT` |
| `P-0334` | Francoise Chapelain | female | 3 January 1673 | 6 November 1741 | *NULL — review* | `L8PT-B83` |
| `P-0335` | Charles Bélanger | male | 3 July 1668 | 11 November 1747 | *NULL — review* | `LVBN-5QW` |
| `P-0336` | Geneviefve Gagnon | female | 4 March 1674 | 28 April 1749 | *NULL — review* | `LK4H-84N` |
| `P-0337` | Charles Pouliot | male | about April 1628 | about 6 August 1699 | Pouliot | `LRS7-9X7` |
| `P-0338` | Francoise Le Mosnier | female | 13 September 1653 | 18 January 1703 | *NULL — review* | `L17K-D6M` |
| `P-0339` | Nicollas Audet | male | about July 1637 | 9 December 1700 | *NULL — review* | `LTF4-G5B` |
| `P-0340` | Magdeleine Després | female | 2 August 1656 | 18 December 1712 | *NULL — review* | `LTF4-PNJ` |
| `P-0341` | Jean Chabot | male | 2 November 1667 | 14 September 1727 | *NULL — review* | `LZL1-9H1` |
| `P-0342` | Eléonore Enaud | female | 5 March 1673 | 21 May 1746 | *NULL — review* | `LZ2X-HZ5` |
| `P-0343` | Pierre Dufresne | male | 25 September 1669 | about 5 November 1740 | *NULL — review* | `LCTK-JCB` |
| `P-0344` | Marie Madelaine Crespeau | female | 1 December 1675 | 17 April 1748 | *NULL — review* | `LRJ7-WGC` |
| `P-0345` | Antoine Godbout | male | 16 November 1669 | April 1742 | *NULL — review* | `LHJQ-F3D` |
| `P-0346` | Marguerite Labrecque | female | about 1669 | 19 October 1748 | *NULL — review* | `LH5T-8SK` |
| `P-0347` | Guillaume Rouleau | male | 27 April 1662 | 6 March 1703 | *NULL — review* | `PS2Y-M8D` |
| `P-0348` | Catherine Dufresne | female | 7 February 1668 | 14 January 1711 | *NULL — review* | `L6NK-LCZ` |
| `P-0349` | Pierre Le Clerc | male | about January 1659 | 25 January 1736 | *NULL — review* | `LC7N-PNK` |
| `P-0350` | Elisabeth Rondeau | female | 19 October 1670 | 7 November 1746 | *NULL — review* | `LJJC-CZ4` |
| `P-0351` | Ignace Gosselin | male | 13 February 1654 | 10 April 1727 | *NULL — review* | `LCRL-SSC` |
| `P-0352` | Marie Anne Raté | female | 13 February 1665 | 25 May 1729 | *NULL — review* | `L1C5-DLC` |
| `P-0353` | Blaise Denys | male | 1630 | 1687 | *NULL — review* | `LV7V-ZBL` |
| `P-0354` | Jeanne la Ponche | female |  | before 8 October 1687 | *NULL — review* | `LV7V-8MT` |
| `P-0355` | Charles Godin | male | about 1630 | after 1 December 1706 | *NULL — review* | `LYXS-JG5` |
| `P-0356` | Marie Boucher | female | about April 1644 | about July 1730 | *NULL — review* | `LY6R-WLM` |
| `P-0357` | Jean Mathieu | male | about 1637 | 29 April 1699 | *NULL — review* | `LJ2N-6WN` |
| `P-0358` | Anne LeTartre | female | about 27 December 1651 | 12 April 1696 | *NULL — review* | `LVJ1-YJQ` |
| `P-0359` | Nicolas Roussin | male | about 10 March 1635 | 6 March 1697 | *NULL — review* | `LVCQ-W56` |
| `P-0360` | Marie Magdelaine Tremblé | female | 9 July 1658 | 9 April 1736 | *NULL — review* | `L26G-51P` |
| `P-0361` | Pierre Gobelin | male | 1620 |  | *NULL — review* | `2S22-JJD` |
| `P-0362` | Madeleine Labelle | female | 1624 |  | *NULL — review* | `2S22-JJY` |
| `P-0363` | Bernard Chaplain | male | about 1651 | 25 November 1734 | *NULL — review* | `LCXR-PJ8` |
| `P-0364` | Leonore Mouillard | female | about 1659 | about 2 December 1739 | *NULL — review* | `MZ4D-28Z` |
| `P-0365` | Charles Belanger | male | about 19 August 1640 | 14 December 1692 | *NULL — review* | `LRTX-7LB` |
| `P-0366` | Barbe Delphine Cloustier | female | about 11 January 1650 | 24 April 1711 | *NULL — review* | `LR39-654` |
| `P-0367` | Pierre Gagnon | male | about 1646 | 10 August 1687 | *NULL — review* | `LVBN-TRS` |
| `P-0368` | Barbe Fortin | female | 21 October 1654 | 26 August 1737 | *NULL — review* | `L5Y9-PD8` |
| `P-0369` | Sergeant Joseph Barnard | male | 20 June 1681 | 12 July 1736 | Paternal Reed | `G7GV-Q4N` |
| `P-0370` | Abigail Griswold | female | 3 August 1685 | 5 June 1747 | *NULL — review* | `LCFC-L7P` |
| `P-0371` | Nathaniel Pinney | male | 18 August 1695 | before 7 October 1735 | *NULL — review* | `LZ6X-P5C` |
| `P-0372` | Elizabeth Carrier | female | 3 June 1695 | after 7 October 1735 | *NULL — review* | `L71T-M3G` |
| `P-0373` | Hamphrey Nathaniel Pinney | male | 5 September 1694 | after 1737 | *NULL — review* | `L5ZR-5GK` |
| `P-0374` | Abigail Deming | female | 21 January 1700 | 6 June 1773 | *NULL — review* | `L5ZR-K54` |
| `P-0375` | Joseph Bernard | male | 1 January 1652 | 6 September 1695 | *NULL — review* | `L457-H8Q` |
| `P-0376` | Sarah Strong | female | 4 March 1656 | 10 February 1733 | *NULL — review* | `L6R7-RBX` |
| `P-0377` | Edward Griswold | male | 19 March 1661 | 30 May 1688 | *NULL — review* | `LZGX-YG7` |
| `P-0378` | Abigail Williams | female | 31 May 1658 | 16 September 1690 | *NULL — review* | `LHXN-W6M` |
| `P-0379` | Nathaniel Pinney II | male | 11 May 1671 | 1 January 1764 | *NULL — review* | `LX7J-XWZ` |
| `P-0380` | Martha Thrall | female | 31 May 1673 | 15 November 1715 | *NULL — review* | `LX7J-XC7` |
| `P-0381` | Richard Carrier | male | 19 July 1674 | 16 November 1749 | *NULL — review* | `L8BG-MPW` |
| `P-0382` | Elizabeth Sessions | female | 4 April 1673 | 6 March 1704 | *NULL — review* | `LZ38-XL4` |
| `P-0383` | Isaac Pinney | male | 24 February 1663 | 6 October 1709 | *NULL — review* | `LX72-R52` |
| `P-0384` | Sarah Clark | female | 7 August 1663 | 25 May 1751 | *NULL — review* | `LZPR-4HZ` |
| `P-0385` | Jacob Deming | male | 26 August 1670 | 23 January 1712 | *NULL — review* | `DK3Q-319` |
| `P-0386` | Elizabeth Edwards | female | 11 September 1674 | 1709 | *NULL — review* | `L588-R34` |
| `P-0387` | Francis Barnard | male | about 1624 | 3 February 1698 | Paternal Reed | `2S4G-PGP` |
| `P-0388` | Hannah Merrill | female | about 1628 | 17 September 1675 | *NULL — review* | `GDNX-91R` |
| `P-0389` | John Strong | male | 10 June 1605 | 14 April 1699 | *NULL — review* | `LHN6-VQW` |
| `P-0390` | Abigail Ford | female | about 8 October 1619 | 6 July 1688 | *NULL — review* | `971N-SXM` |
| `P-0391` | George Griswold | male | 19 May 1633 | 3 September 1704 | *NULL — review* | `9H7S-R2T` |
| `P-0392` | Mary Holcombe | female | about 1636 | 4 April 1708 | *NULL — review* | `KNX6-H1Y` |
| `P-0393` | John Williams | male | 24 May 1618 | 14 May 1712 | *NULL — review* | `MZ6X-YTJ` |
| `P-0394` | Mary Burlly | female | 1616 | 17 April 1681 | *NULL — review* | `LYR4-Y2M` |
| `P-0395` | Samuel Pinney I | male | 30 March 1635 | 1681 | *NULL — review* | `LZV8-G2P` |
| `P-0396` | Joyce Bissell | female | 21 May 1641 | 1689 | *NULL — review* | `L6KP-5JN` |
| `P-0397` | Timothy Thrall | male | 25 July 1641 | 7 June 1697 | *NULL — review* | `LV46-1PB` |
| `P-0398` | Deborah Gunn | female | 21 February 1641 | 17 January 1694 | *NULL — review* | `LYW5-13Z` |
| `P-0399` | Thomas Carrier | male | 1626 | 16 May 1735 | *NULL — review* | `K2RQ-CTK` |
| `P-0400` | Martha Allen (Allin) Carrier | female | 1643 | 5 August 1692 | *NULL — review* | `P6QZ-F5J` |
| `P-0401` | Alexander Sessions | male | 14 February 1645 | 26 February 1689 | *NULL — review* | `L83J-NVL` |
| `P-0402` | Elizabeth Spofford | female | 14 December 1646 | 16 June 1747 | *NULL — review* | `L48D-1DM` |
| `P-0403` | Capt. Daniel Clark | male | before 8 June 1623 | 12 August 1710 | *NULL — review* | `L5RG-L91` |
| `P-0404` | Mary Newberry | female | 22 October 1626 | 29 August 1688 | *NULL — review* | `LZ5P-B9Z` |
| `P-0405` | John Deming | male | 9 September 1638 | 23 January 1712 | *NULL — review* | `LR68-817` |
| `P-0406` | Mary Mygatt | female | 4 December 1637 | 4 September 1714 | *NULL — review* | `LZYB-DM2` |
| `P-0407` | Richard Edwards | male | 1 May 1647 | 20 April 1718 | *NULL — review* | `LRJ6-72K` |
| `P-0408` | Elizabeth Tuttle | female | about 1645 | September 1691 | *NULL — review* | `9XY5-DMR` |
| `P-0409` | Joseph Audet-dit-Lapointe | male | 24 February 1704 | 16 December 1788 | *NULL — review* | `G7Q5-44F` |
| `P-0410` | Marie Anne Therrien | female | 16 January 1723 | 27 December 1759 | *NULL — review* | `LZX1-22C` |
| `P-0411` | Charles Delage | male | 25 October 1698 | 28 November 1749 | *NULL — review* | `K8R9-DGV` |
| `P-0412` | Marie Josephe Plante | female | about 1708 | 10 August 1781 | *NULL — review* | `LVNN-QC4` |
| `P-0413` | Jacques Tremblay | male | 30 August 1702 | 18 August 1769 | *NULL — review* | `LRS1-YC3` |
| `P-0414` | Marie Angélique Quentin dit Cantin | female | 8 March 1707 | 17 November 1749 | *NULL — review* | `LDSS-3FG` |
| `P-0415` | Gervais Pépin dit Lachance | male | 30 October 1714 | 21 June 1789 | *NULL — review* | `LRD5-K2F` |
| `P-0416` | Marie Angélique Blouin | female | 10 February 1721 | 20 March 1809 | *NULL — review* | `L71K-1M4` |
| `P-0417` | Nicolas Odet | male | 1680 | before 17 March 1732 | *NULL — review* | `G81J-4TG` |
| `P-0418` | Jeanne Pouliot | female | 7 October 1678 | about January 1759 | Pouliot | `LWV2-3FZ` |
| `P-0419` | Barthélémy Terrien | male | 10 March 1694 | 5 March 1743 | *NULL — review* | `L5P3-FJM` |
| `P-0420` | Marguerite Fontaine | female | 28 February 1693 | 4 May 1777 | *NULL — review* | `LDMY-YDH` |
| `P-0421` | Charles Delage | male | 19 April 1672 | 19 July 1748 | *NULL — review* | `LVN7-PGK` |
| `P-0422` | Marie Anne Manseau | female | 26 October 1675 | 20 March 1703 | *NULL — review* | `LZXX-VRT` |
| `P-0423` | Georges Plante | male | 26 August 1659 | 17 February 1718 | *NULL — review* | `LVN7-XST` |
| `P-0424` | Margueritte Crepeau | female | 11 March 1669 | about 1745 | *NULL — review* | `LTH9-5ZC` |
| `P-0425` | Jacques Tremblay | male | 18 June 1664 | 28 March 1741 | *NULL — review* | `LVC1-1ZX` |
| `P-0426` | Agathe Lacroix | female | 13 January 1675 | 23 April 1742 | *NULL — review* | `LVZM-M94` |
| `P-0427` | Louis Quentin | male | 27 December 1675 |  | *NULL — review* | `L63T-L1S` |
| `P-0428` | Marie Matthieu | female | 23 December 1682 | 15 July 1771 | *NULL — review* | `L63T-L1P` |
| `P-0429` | Jan Pepin | male | 29 March 1664 | about 1734 | *NULL — review* | `LR33-SSZ` |
| `P-0430` | Madeleine Fontaine | female | 2 June 1688 | 5 August 1768 | *NULL — review* | `LZKL-ZND` |
| `P-0431` | Jacque Belouyn | male | 2 April 1676 | 15 January 1744 | *NULL — review* | `LVN7-YMR` |
| `P-0432` | Marie Geneviève Plante | female | 21 January 1693 | October 1765 | *NULL — review* | `LVN7-T1M` |
| `P-0433` | Pierre Terrien | male | 1 November 1640 | 12 September 1706 | *NULL — review* | `LRBF-PM3` |
| `P-0434` | Gabrielle Minaud | female | about 1655 | 25 November 1707 | *NULL — review* | `L5D9-R4D` |
| `P-0435` | Estienne de Fontaine | male | about 24 February 1659 | about 22 May 1739 | *NULL — review* | `L5NN-2QT` |
| `P-0436` | Marie Conil | female | about 27 September 1665 | about 1 July 1737 | *NULL — review* | `LVJ1-ZM1` |
| `P-0437` | Nicolas Delage | male | about 1637 | before 22 July 1686 | *NULL — review* | `L871-PK9` |
| `P-0438` | Marie Petit | female | 28 June 1637 | 19 December 1708 | *NULL — review* | `LY41-PL9` |
| `P-0439` | Jacques Manseau | male | 16 February 1633 | 25 June 1711 | *NULL — review* | `LB9C-F1N` |
| `P-0440` | Marguerite Latouche | female | 1652 | 21 May 1732 | *NULL — review* | `LB9C-4LQ` |
| `P-0441` | Jean Plante | male | about 1626 | 29 March 1706 | *NULL — review* | `LRHS-WNS` |
| `P-0442` | Françoise Boucher | female | about June 1636 | 18 April 1711 | *NULL — review* | `L24C-3RJ` |
| `P-0443` | Maurice Créspeau | male | about November 1637 | 8 September 1704 | *NULL — review* | `L7BH-YGT` |
| `P-0444` | Margueritte La Verdure | female | about 1640 | 22 August 1727 | *NULL — review* | `LVN7-47C` |
| `P-0445` | François-Normand Lacroix | male | 21 October 1642 | 27 August 1710 | *NULL — review* | `KD9P-Q4C` |
| `P-0446` | Anne Gangner | female | about October 1653 |  | *NULL — review* | `LZLP-PC2` |
| `P-0447` | Nicolas Quentin | male | about 4 November 1633 | 27 May 1683 | *NULL — review* | `LRMD-519` |
| `P-0448` | Magdelaine Roulois | female | about 1648 | after 24 July 1707 | *NULL — review* | `LJNB-RQH` |
| `P-0449` | Anthoine Pepin | male | 10 April 1636 | about 23 January 1703 | *NULL — review* | `L4R8-LG9` |
| `P-0450` | Marie Taiste | female | about 1638 | about 11 September 1701 | *NULL — review* | `L2D4-M3L` |
| `P-0451` | Emeri Beglouin | male | about April 1640 | 14 July 1707 | *NULL — review* | `LB2F-WNH` |
| `P-0452` | Marie Careau | female | 20 March 1655 | 10 February 1722 | *NULL — review* | `LVN7-Y1D` |
| `P-0453` | PASQUINO NICCOLAI | male | 19 July 1718 | 9 September 1798 | Maternal Mariotti | `PM4B-L5J` |
| `P-0454` | ELISABETTA BONAGUIDI | female | 30 May 1727 | 4 November 1805 | *NULL — review* | `PM4B-FHC` |
| `P-0455` | GIUSEPPE GIACOMELLI | male |  |  | *NULL — review* | `P9YH-1TL` |
| `P-0456` | ANGIOLA CASSANESI | female |  |  | *NULL — review* | `P9YC-4LF` |
| `P-0457` | FRANCESCO NICCOLAI | male | 27 February 1691 |  | Maternal Mariotti | `PM4B-XGN` |
| `P-0458` | MARIA ANGIOLA BARONTI | female |  |  | *NULL — review* | `PM4B-4W6` |
| `P-0459` | MARIANO BONAGUIDI | male | 29 January 1688 |  | *NULL — review* | `P4N7-V6K` |
| `P-0460` | CATERINA PAPINI | female | 20 January 1699 |  | *NULL — review* | `PHMQ-Z3K` |
| `P-0461` | PASQUINO NICCOLAI | male | 18 March 1657 |  | Maternal Mariotti | `PM4B-6L4` |
| `P-0462` | FIORE MARIOTTI | female | 1664 | 22 August 1734 | *NULL — review* | `PM4B-PFF` |
| `P-0463` | GIOVANNI BONAGUIDI | male | 1656 | 13 March 1726 | *NULL — review* | `PHMQ-Q3F` |
| `P-0464` | MARIA ANGELA STEFANELLI | female | 1668 | 1738 | *NULL — review* | `PHMQ-J5N` |
| `P-0465` | Pasquino Papini | male |  |  | *NULL — review* | `PHMN-GG2` |
| `P-0466` | Barbera Simoni | female |  |  | *NULL — review* | `PHMJ-95S` |
| `P-0467` | Green | male |  |  | *NULL — review* | `PMJJ-SV4` |
| `P-0468` | John Reeder Jr | male | 29 January 1645 | 9 May 1694 | *NULL — review* | `LZG8-HGR` |
| `P-0469` | Joanna Burroughs | female | 1650 | 9 May 1694 | *NULL — review* | `LDXB-GKK` |
| `P-0470` | Henri Marchand I | male | 10 October 1648 | 1685 | *NULL — review* | `L5KN-S9J` |
| `P-0471` | Mary Ruscoe | female | 1654 | 1685 | *NULL — review* | `LV3J-NGZ` |
| `P-0472` | John Houghton | male | 28 February 1655 | 4 January 1710 | *NULL — review* | `LB4K-3K6` |
| `P-0473` | Dyna Philips | female | 18 September 1657 | October 1738 | *NULL — review* | `LB4K-WDS` |
| `P-0474` | Nicholas Bonham | male | 30 June 1630 | 20 July 1684 | Paternal Reed | `MM4L-JLD` |
| `P-0475` | Hannah Fuller | female | 8 October 1636 | 1 January 1686 | *NULL — review* | `LXS4-8L3` |
| `P-0476` | Vincent Rongnion | male | 2 March 1645 | 11 November 1713 | *NULL — review* | `LR9C-ZFS` |
| `P-0477` | Anna Martha Boutcher | female | about 1650 | 2 February 1737 | *NULL — review* | `MX1Y-F86` |
| `P-0478` | Hugh Dunn | male | 18 November 1642 | 14 November 1694 | *NULL — review* | `LVXN-8NR` |
| `P-0479` | Elizabeth Drake | female | 25 December 1653 | 8 August 1711 | *NULL — review* | `K2SJ-LN2` |
| `P-0480` | John Curtis | male | 8 September 1635 | 1 February 1695 | *NULL — review* | `LZN3-S98` |
| `P-0481` | Anne Revell | female | 9 December 1627 | 2 October 1687 | *NULL — review* | `M5NP-BKH` |
| `P-0482` | Thomas Ellis | male | about 25 March 1628 | May 1682 | *NULL — review* | `L4JQ-657` |
| `P-0483` | Hannah Hebden Hugh | female | 1635 | 17 September 1678 | *NULL — review* | `P4R4-C2W` |
| `P-0484` | William Ambrose Dickerson | male | 12 August 1623 | 1662 | Paternal Reed | `27SD-FR4` |
| `P-0485` | Elizabeth Trundle | female | 1621 | 1661 | *NULL — review* | `G1HY-1LX` |
| `P-0486` | Richard Gambray | male | about 1620 |  | *NULL — review* | `MJF9-TNJ` |
| `P-0487` | Missy Nae O'Dell | female | about 1625 |  | *NULL — review* | `4N6S-NTL` |
| `P-0488` | Isaac Baptiste "Sarratt" | male | about 1605 | 19 February 1683 | *NULL — review* | `G9DC-YKP` |
| `P-0489` | Nicole Oudinot | female | 14 July 1618 | 30 August 1681 | *NULL — review* | `L6FD-7P1` |
| `P-0490` | William C Short | male | 1634 | 16 March 1675 | *NULL — review* | `LK7T-P67` |
| `P-0491` | Mary Elisabeth Nash | female | 13 April 1635 | 31 August 1689 | *NULL — review* | `G92W-VG2` |
| `P-0492` | Pål Persson | male | 1621 | before 1671 | *NULL — review* | `G6LC-TXK` |
| `P-0493` | Margareta Olofsdotter | female | 1620 | 1674 | *NULL — review* | `LJLF-7HD` |
| `P-0494` | Simon Johnsson | male | about 1620 |  | *NULL — review* | `KX56-51J` |
| `P-0495` | ? | female |  |  | *NULL — review* | `CCG4-3YQ` |
| `P-0496` | William Thomas West | male | 5 November 1616 | 17 January 1696 | *NULL — review* | `L6MZ-7W4` |
| `P-0497` | Elizabeth Middlemore | female | about 1615 | 18 January 1684 | *NULL — review* | `LCRK-HLX` |
| `P-0498` | Thomas Gilpin | male | 1620 | 3 February 1682 | *NULL — review* | `L8SS-GZT` |
| `P-0499` | Joan Bartholomew | female | 1625 | 21 January 1700 | *NULL — review* | `WYFX-JNF` |
| `P-0500` | Aaron Deane | male | about 1602 | 9 March 1676 | *NULL — review* | `MZ95-4QQ` |
| `P-0501` | Rebecca Gardyne | female | about 1602 | July 1643 | *NULL — review* | `MZ95-4QH` |
| `P-0502` | John Wilson | male |  | about 1690 | *NULL — review* | `MM6Y-RMF` |
| `P-0503` | Elsabeth Atkinson | female | about 1633 | about 1686 | *NULL — review* | `MXDW-Q39` |
| `P-0504` | Broer Sinnicksson | male | about 1650 | 30 November 1708 | *NULL — review* | `LVYM-PNQ` |
| `P-0505` | Sophia Pålsdotter | female | 1635 | 9 December 1717 | *NULL — review* | `L5FN-R1Y` |
| `P-0506` | Jan Harmansen | male | about 1640 | 1695 | *NULL — review* | `2DT2-LMQ` |
| `P-0507` | Catherina Corderus | female | about 1632 | 1 December 1716 | *NULL — review* | `KHTY-YF7` |
| `P-0508` | Hendrick Eigil Jacobsson | male | 1636 | 5 May 1704 | *NULL — review* | `KC1C-YJJ` |
| `P-0509` | Gertrude Hendricksdotter | female | 1632 | 27 December 1685 | *NULL — review* | `K8QB-54M` |
| `P-0510` | Peter Mattson Dalbo | male |  |  | *NULL — review* | `PDGY-165` |
| `P-0511` | Catherine Rambo | female | 1655 | 1708 | *NULL — review* | `L78Y-J66` |
| `P-0512` | William Talley | male | 1660 | about 1700 | Paternal Reed | `LVP9-SGG` |
| `P-0513` | Elinor Jansen | female | about 1645 | after 21 November 1721 | *NULL — review* | `GG27-TPH` |
| `P-0514` | John Grubb Sr. | male | before 16 August 1652 | 4 April 1708 | *NULL — review* | `MYRD-6JG` |
| `P-0515` | Frances | female | about 1660 | 12 February 1708 | *NULL — review* | `LYHL-RQS` |
| `P-0516` | Anders Olofsson Stille | male | 1639 | before 1693 | *NULL — review* | `LRSN-KZ3` |
| `P-0517` | Annettje Perterse von Cowenhoven | female | 1644 | 1698 | *NULL — review* | `G7D6-P5V` |
| `P-0518` | Carl Christopher Springer | male | 6 November 1658 | 26 May 1738 | *NULL — review* | `M4WS-9GL` |
| `P-0519` | Margietje Maria Hendricksdotter | female | 1658 | 15 March 1727 | *NULL — review* | `LDM1-XBB` |
| `P-0520` | Cornelius Vandeveer | male | February 1659 | 18 December 1712 | *NULL — review* | `LVJ8-67G` |
| `P-0521` | Margareta Fransson Van De  Ver | female | about 1658 | 12 January 1763 | *NULL — review* | `LZ4J-CFJ` |
| `P-0522` | Adam Stidham | male | about 1660 | 21 January 1695 | *NULL — review* | `LTYD-JY8` |
| `P-0523` | Katherine Karin | female | 1662 | 21 November 1739 | *NULL — review* | `MV9N-595` |
| `P-0524` | Owen Foulke | male | about 1650 | 5 August 1695 | *NULL — review* | `LHKT-VK6` |
| `P-0525` | Sarah Elinor Morgan | female | 1655 | 1720 | *NULL — review* | `P3MB-WRQ` |
| `P-0526` | Oliver Cope | male | 13 March 1647 | after 21 May 1697 | *NULL — review* | `L8YT-Y4C` |
| `P-0527` | Rebecca Crooke | female | about 1647 | 1728 | *NULL — review* | `9X5H-MBT` |
| `P-0528` | William Brinton Sr | male | 1 December 1630 | 20 October 1700 | *NULL — review* | `KNDB-5MF` |
| `P-0529` | Ann Bagley | female | 27 April 1634 | 5 April 1699 | *NULL — review* | `KNW3-434` |
| `P-0530` | Laurens Duyts | male | 1610 |  | *NULL — review* | `GVVB-R3C` |
| `P-0531` | Grietje\Ijtje\Ytie (Jans\Jansen) Dye\ Duytszen\Duyts | female | 1620 | from 25 November 1658 to 1662 | *NULL — review* | `P63W-W74` |
| `P-0532` | Robert Bruce Pollock | male | 1606 | 1660 | *NULL — review* | `GRQP-X78` |
| `P-0533` | Jean Crawford | female | 1606 |  | *NULL — review* | `P7BB-7CY` |
| `P-0534` | Roger Tasker | male | 1606 | 1688 | *NULL — review* | `PZTX-N47` |
| `P-0535` | Magdalen Porter | female | 1610 | from 1660 to 1700 | *NULL — review* | `G26R-N8P` |
| `P-0536` | Alexander Williams | male | about 1626 | before 11 August 1687 | *NULL — review* | `9WPV-XJ7` |
| `P-0537` | Ruth Ann Tackling | female | about 1628 |  | *NULL — review* | `LWFV-JX5` |
| `P-0538` | Nehemiah Covington | male | 1628 | 9 June 1681 | *NULL — review* | `LKTH-SXT` |
| `P-0539` | Mary Vaughan | female | 1627 | 1 April 1667 | *NULL — review* | `GL5B-VLY` |
| `P-0540` | Benjamin Cottman | male | 24 May 1651 | 29 March 1703 | *NULL — review* | `LTCJ-LJG` |
| `P-0541` | Mary Hudnall | female | April 1643 | September 1684 | *NULL — review* | `LBJY-GYQ` |
| `P-0542` | Robert Hardy | male | 1646 | August 1679 | *NULL — review* | `G5GJ-WNB` |
| `P-0543` | Mary Ann Olcott Moon | female | about 1648 |  | *NULL — review* | `LHPQ-PQ5` |
| `P-0544` | Deacon Samuel Allen Jr. of Bridgewater | male | about 1632 | before December 1705 | *NULL — review* | `LYNR-7QR` |
| `P-0545` | Sarah Partridge | female | 2 September 1639 | 7 August 1722 | *NULL — review* | `LHQY-8KR` |
| `P-0546` | John Cary | male | 4 December 1610 | 31 October 1681 | *NULL — review* | `L5RC-VH1` |
| `P-0547` | Elizabeth Godfrey | female | about 1620 | 1 November 1680 | *NULL — review* | `LVG2-1ZL` |
| `P-0548` | Richard Bushnell Sr | male | April 1623 | 17 July 1660 | *NULL — review* | `M38Y-9YX` |
| `P-0549` | Mary Marvin | female | before 16 December 1628 | 26 March 1713 | *NULL — review* | `LHNF-XSS` |
| `P-0550` | Lt. Thomas Leffingwell Jr. | male | about March 1624 | 28 March 1714 | *NULL — review* | `KZ9Q-314` |
| `P-0551` | Mary White | female | 11 March 1626 | 6 February 1711 | *NULL — review* | `LC41-RL8` |
| `P-0552` | John Sargent | male | before 8 December 1639 | 9 September 1716 | *NULL — review* | `LL9V-87D` |
| `P-0553` | Deborah Hyllier | female | 30 October 1643 | 20 April 1669 | *NULL — review* | `LL9K-4V1` |
| `P-0554` | David Linnell | male | 9 March 1622 | 14 November 1688 | *NULL — review* | `LRH7-YLY` |
| `P-0555` | Hannah Shelley | female | 2 July 1637 | 5 April 1709 | *NULL — review* | `L6S4-FC8` |
| `P-0556` | Thomas Wood I | male | before 29 April 1632 | 12 September 1687 | *NULL — review* | `LY7R-F1C` |
| `P-0557` | Ann Hobkinson | female | 23 March 1628 | 29 December 1714 | *NULL — review* | `LRF7-6K7` |
| `P-0558` | Nehemiah Hunt, Sr. | male | 1631 | 6 March 1718 | *NULL — review* | `LZJM-6B3` |
| `P-0559` | Mary Toll | female | 8 December 1643 | 29 August 1727 | *NULL — review* | `LKKM-N84` |
| `P-0560` | Lieutenant Nehemiah Palmer Sr. | male | 2 November 1637 | 17 February 1717 | *NULL — review* | `LRLZ-5QR` |
| `P-0561` | Hannah Stanton | female | 21 March 1644 | 17 October 1727 | *NULL — review* | `LVF6-HFJ` |
| `P-0562` | Captain Joseph Saxton | male | 9 May 1656 | 18 July 1715 | *NULL — review* | `L63R-722` |
| `P-0563` | Hannah Denison | female | 20 May 1643 | 18 October 1715 | *NULL — review* | `L67T-MBL` |
| `P-0564` | Lucretia Pinney Carroll | female | 17 January 1723 | 16 February 1805 | *NULL — review* | `GL5H-K17` |
| `P-0565` | Sir Francis Bernard II | male | about 1558 | November 1630 | *NULL — review* | `LZZQ-9QY` |
| `P-0566` | Mary Woolhouse | female | about 1584 | about 1656 | *NULL — review* | `M9KZ-LY2` |
| `P-0567` | Mathew Merrill | male | about 1596 |  | *NULL — review* | `PSGN-9Q8` |
| `P-0568` | Isabell Freeman | female | about 1598 | about 1637 | *NULL — review* | `KCL6-G9K` |
| `P-0569` | John Strong | male | about 1585 | 14 June 1613 | *NULL — review* | `94RB-17S` |
| `P-0570` | Mrs. John Strong | female | 1586 | 24 April 1654 | *NULL — review* | `M4MX-3Q3` |
| `P-0571` | Thomas Ford of Bridport | male | about 1591 | 9 November 1676 | *NULL — review* | `LZV6-VDJ` |
| `P-0572` | Elizabeth Charde | female | about 1589 | 18 April 1643 | *NULL — review* | `9DTT-B4C` |
| `P-0573` | Edward Griswold | male | 26 July 1607 | 30 August 1690 | *NULL — review* | `9QSM-2DZ` |
| `P-0574` | Margaret | female | 1610 | 23 August 1670 | *NULL — review* | `MJFK-SCQ` |
| `P-0575` | Thomas Holcombe | male | about 1609 | 7 September 1657 | *NULL — review* | `L18L-Q7C` |
| `P-0576` | Elizabeth | female | 11 November 1617 | 7 October 1679 | *NULL — review* | `LB9F-FGD` |
| `P-0577` | Robert Williams | male | 29 May 1580 | 4 April 1622 | *NULL — review* | `MSVW-XF2` |
| `P-0578` | Elizabeth Stratton | female | 27 August 1581 | 28 July 1674 | *NULL — review* | `GDXR-7D7` |
| `P-0579` | Sir Humphrey Pinney | male | 20 November 1605 | 20 August 1683 | *NULL — review* | `L19S-RZC` |
| `P-0580` | Mary Hull | female | 27 July 1618 | 18 August 1684 | *NULL — review* | `K8V8-14J` |
| `P-0581` | John Bissell | male | 30 October 1591 | 3 October 1677 | *NULL — review* | `LRLL-MDP` |
| `P-0582` | unknown | female | about 1593 | 21 May 1641 | *NULL — review* | `M2X9-3ZF` |
| `P-0583` | William Thrall | male | August 1605 | 3 August 1679 | *NULL — review* | `LV95-7MM` |
| `P-0584` | Elizabeth Goode | female | 1605 | 30 July 1676 | *NULL — review* | `94NR-T21` |
| `P-0585` | Thomas Gunn | male | about 1605 | 26 February 1680 | *NULL — review* | `LZPM-4YG` |
| `P-0586` | Elizabeth | female |  | about 28 November 1678 | *NULL — review* | `GZ18-J98` |
| `P-0587` | Richard (Rici) Morgan de Ryppon | male | 1609 | 1649 | *NULL — review* | `P6QZ-LRX` |
| `P-0588` | Mrs. Uknown Morgan | female |  |  | *NULL — review* | `P6QZ-H38` |
| `P-0589` | Andrew Allen | male | 21 March 1613 | 24 October 1690 | Paternal Reed | `LRQ4-5P4` |
| `P-0590` | Samuel Sessions | male | 1614 | 1706 | *NULL — review* | `MSM9-3XP` |
| `P-0591` | Mrs. Lucille Sessions | female | about 1624 |  | *NULL — review* | `GSQ3-3Z4` |
| `P-0592` | John Spofford II | male | 21 April 1611 | before 6 November 1678 | *NULL — review* | `LR2W-6B1` |
| `P-0593` | Elizabeth Scott | female | 18 November 1623 | 10 February 1691 | *NULL — review* | `LZPQ-RHG` |
| `P-0594` | Sabbath Clark | male | 1587 | 30 March 1663 | *NULL — review* | `LC2Q-PGR` |
| `P-0595` | Elizabeth Overton | female | November 1592 | September 1656 | *NULL — review* | `LHTR-P82` |
| `P-0596` | Captain Thomas Newberry | male | 10 November 1594 | from 17 December 1635 to 28 January 1636 | *NULL — review* | `MPJ4-G24` |
| `P-0597` | Joane Dabinott | female | about 1600 | 19 February 1629 | *NULL — review* | `LRR9-THB` |
| `P-0598` | John Deming | male | about 1610 | 21 November 1705 | *NULL — review* | `LW19-D2X` |
| `P-0599` | Honor Treat | female | 19 March 1615 | 21 November 1705 | *NULL — review* | `9CQT-Z1N` |
| `P-0600` | Joseph Mygatt | male | 31 August 1596 | 7 December 1680 | *NULL — review* | `LCMG-FPB` |
| `P-0601` | Ann LNU | female | 1596 | 4 March 1686 | *NULL — review* | `G3L4-B35` |
| `P-0602` | William Edwards | male | 1618 | 4 December 1680 | *NULL — review* | `LT7K-C5G` |
| `P-0603` | Agnes Harris | female | 6 April 1604 | 1705 | *NULL — review* | `937M-96Z` |
| `P-0604` | William Tuttle | male | 26 December 1607 | 16 June 1673 | *NULL — review* | `LZV6-7D9` |
| `P-0605` | Elizabeth | female | 1609 | 31 December 1684 | *NULL — review* | `M7X2-6TY` |
| `P-0606` | Johan Pouliot | male |  |  | Pouliot | `LWV2-QR5` |
| `P-0607` | Jeanne Josse | female |  | after 5 June 1667 | *NULL — review* | `L6LK-2H8` |
| `P-0608` | Mathurin Le Monnier | male | about 22 April 1619 | after 9 October 1676 | *NULL — review* | `LVD4-CBY` |
| `P-0609` | Francoise Faffart | female | about 1624 | 13 January 1702 | *NULL — review* | `LR2B-X2Q` |
| `P-0610` | Innocent Audet | male | 26 March 1614 |  | *NULL — review* | `LYSP-RN5` |
| `P-0611` | Vincende Roy | female |  | before 10 January 1645 | *NULL — review* | `LYXP-148` |
| `P-0612` | Francois Despres | male | 11 March 1531 |  | *NULL — review* | `GD74-DWY` |
| `P-0613` | Madeleine Legrand | female | 1525 |  | *NULL — review* | `GD74-WY3` |
| `P-0614` | Mathurin Chabot | male | about 18 August 1637 | 12 June 1696 | *NULL — review* | `GMNX-ZPD` |
| `P-0615` | Marie Mesange | female | about 4 April 1643 | 13 March 1692 | *NULL — review* | `9SLR-TSY` |
| `P-0616` | Michel Enaud | male | 1636 | 3 September 1701 | *NULL — review* | `LRJ7-8WS` |
| `P-0617` | Geneviève Eleonore Macré | female | 1636 | about 12 December 1700 | *NULL — review* | `LRPY-S44` |
| `P-0618` | Pierre Dufraisne | male | about 1627 | 29 November 1687 | *NULL — review* | `9S3W-MFB` |
| `P-0619` | Anne Patin | female | about 1634 | about 29 November 1700 | *NULL — review* | `9WFC-SZ3` |
| `P-0620` | Nicolas Godbout | male | 17 May 1635 | 5 September 1674 | *NULL — review* | `LCXC-XY1` |
| `P-0621` | Marie Marthe Bourgoin | female | 22 February 1638 | 19 December 1682 | *NULL — review* | `LB91-VFM` |
| `P-0622` | Pierre BRULON | male | 10 January 1637 | January 1678 | *NULL — review* | `PH84-Y3T` |
| `P-0623` | Janne Baillargent | female | 4 May 1651 | 19 August 1729 | *NULL — review* | `LKSD-MVW` |
| `P-0624` | Gabriel Rouleau dit Sanssoucy | male | 1618 | 22 February 1673 | *NULL — review* | `GSZD-7CT` |
| `P-0625` | Mathurine Leroux | female | 18 March 1635 | 1 February 1708 | *NULL — review* | `KHDK-896` |
| `P-0626` | Jean Le Clerc | male | about 24 August 1635 | about 1680 | *NULL — review* | `LTY4-Q4Q` |
| `P-0627` | Marie Blanquet | female | about 31 August 1631 | 10 September 1709 | *NULL — review* | `LT3W-WSZ` |
| `P-0628` | Thomas Rondeau | male | about 1638 | 10 November 1721 | *NULL — review* | `LVLX-MKX` |
| `P-0629` | Andrée Remondiere | female | about 1651 | 21 November 1702 | *NULL — review* | `LK99-VYZ` |
| `P-0630` | Gabriel Gosselin | male | 1621 | about July 1697 | *NULL — review* | `L7FH-H5N` |
| `P-0631` | Françoise Lelievre | female | 1632 | 27 September 1677 | *NULL — review* | `LZVW-DK3` |
| `P-0632` | Jacques Raté | male | about March 1630 | 8 April 1699 | *NULL — review* | `LBBX-7VK` |
| `P-0633` | Anne Martin | female | about March 1645 | 14 January 1717 | *NULL — review* | `LKN3-TLP` |
| `P-0634` | André Terrien | male | 29 October 1611 | 29 October 1661 | *NULL — review* | `LR3J-8CQ` |
| `P-0635` | Marie Anne Foucault | female | 1615 | 17 May 1670 | *NULL — review* | `LYCV-JGN` |
| `P-0636` | Jean Mignault | male | about 1620 | about 22 July 1665 | *NULL — review* | `LVRN-BGF` |
| `P-0637` | Marie Louise Cloutier | female | about 1631 | 15 January 1711 | *NULL — review* | `GCM1-FQM` |
| `P-0638` | Jacque de Fontaine | male | about 1625 | after 8 February 1683 | *NULL — review* | `LJ5F-D2F` |
| `P-0639` | Jeanne Collinet | female | about 1627 | 20 October 1686 | *NULL — review* | `LJ5F-DLP` |
| `P-0640` | Pierre Conille | male | 14 March 1644 | 1669 | *NULL — review* | `LCJN-QV8` |
| `P-0641` | Marie Giton | female | about 1649 | 17 January 1708 | *NULL — review* | `LRMM-24S` |
| `P-0642` | Jacques Delage | male | about 1605 | before 10 October 1669 | *NULL — review* | `K4PT-CML` |
| `P-0643` | Marguerite | female | 1609 | after 1642 | *NULL — review* | `KT4Z-VT2` |
| `P-0644` | Eustache Petit | male | about 1608 | 10 October 1669 | *NULL — review* | `KGCL-LH9` |
| `P-0645` | Barbe Cochois | female | about 1618 |  | *NULL — review* | `LDMY-1B7` |
| `P-0646` | Etienne Fontenay Manseau | male | 1606 | 21 September 1673 | *NULL — review* | `LQR5-S8N` |
| `P-0647` | Marie MÉTAYER | female |  |  | *NULL — review* | `LDSS-WJM` |
| `P-0648` | Jean Latouche | male | 6 September 1632 | 26 December 1689 | *NULL — review* | `KV2P-G34` |
| `P-0649` | Marie Tevellon | female | 1630 | 1673 | *NULL — review* | `G3Z3-V4Q` |
| `P-0650` | Nicolas Plante | male | 27 September 1583 | 21 May 1647 | *NULL — review* | `LR9H-CLZ` |
| `P-0651` | Elizabeth Chauvin | female | 1601 | 14 February 1646 | *NULL — review* | `L121-V1Y` |
| `P-0652` | Marin Boucher | male | about 1587 | 29 March 1671 | *NULL — review* | `LTZN-HKC` |
| `P-0653` | Perrine Malet | female | about 1604 | 24 August 1687 | *NULL — review* | `LT4B-PJ7` |
| `P-0654` | Jehan Créspeau | male | 28 February 1614 | after 12 October 1665 | *NULL — review* | `LXSZ-MWK` |
| `P-0655` | Suzanne Fumoleau | female | 25 April 1613 | 12 November 1643 | *NULL — review* | `L417-4LN` |
| `P-0656` | Martin La Verdure | male |  | after 12 October 1665 | *NULL — review* | `L6QM-TVM` |
| `P-0657` | Jacline Le Liot | female | 1620 | 12 October 1665 | *NULL — review* | `LVN7-CX8` |
| `P-0658` | François Marsan Laponche | male | 1600 | 1691 | *NULL — review* | `GWLN-889` |
| `P-0659` | Françoise Lapierre | female | 1594 | 1645 | *NULL — review* | `PM5Y-BQD` |
| `P-0660` | Jacques Godin | male | about 1605 |  | *NULL — review* | `LT5F-2PQ` |
| `P-0661` | Marguerite Nicole | female | about 1605 |  | *NULL — review* | `LRTN-KMH` |
| `P-0662` | Jean Jacob Mathieu | male | 16 February 1610 | 29 April 1699 | *NULL — review* | `LTRJ-WM4` |
| `P-0663` | Isabelle Monnachau | female | 1615 | 19 November 1669 | *NULL — review* | `LTRJ-5X8` |
| `P-0664` | René Letartre | male | about 1626 | about 2 September 1699 | *NULL — review* | `LF72-TFZ` |
| `P-0665` | Louise Goulet | female | about August 1628 | after 6 October 1696 | *NULL — review* | `KN8P-Y6F` |
| `P-0666` | Jean Roussin | male | about 3 October 1597 | about 1682 | *NULL — review* | `LTHY-88Y` |
| `P-0667` | Madeleine Giguère | female | 26 May 1605 | before 3 April 1650 | *NULL — review* | `LTHY-QYC` |
| `P-0668` | Loys ou Louis Chappellain | male | 19 September 1617 | 1 February 1700 | *NULL — review* | `LTZ5-694` |
| `P-0669` | Francoise Dechaux | female | about 1621 | 25 January 1695 | *NULL — review* | `LTZ5-6VP` |
| `P-0670` | André Mouillard | male |  |  | *NULL — review* | `LZPZ-526` |
| `P-0671` | Sebastienne | female |  | after 9 November 1671 | *NULL — review* | `LZZ2-PTX` |
| `P-0672` | Francois Bellanger | male | about 1612 | after 25 October 1685 | *NULL — review* | `LRR2-WFV` |
| `P-0673` | Marie Guyon | female | about March 1624 | 29 August 1696 | *NULL — review* | `LRCV-FXH` |
| `P-0674` | Zacharie Cloustier | male | about 16 August 1617 | 3 February 1708 | *NULL — review* | `LBNL-4LN` |
| `P-0675` | Magdeleine Aymart | female | about 1 August 1626 | 28 May 1708 | *NULL — review* | `LT5N-95W` |
| `P-0676` | Pierre Gagnon | male | about February 1612 | 17 April 1699 | *NULL — review* | `LVNP-921` |
| `P-0677` | Vincente des Varieux | female | about 1624 | 2 January 1695 | *NULL — review* | `LZRK-9N9` |
| `P-0678` | Julien Fortin | male | 9 February 1621 | after 18 June 1689 | *NULL — review* | `LBHP-HWL` |
| `P-0679` | Genevieve De Lamare | female | about 13 October 1636 | about 5 November 1709 | *NULL — review* | `9V89-S2M` |
| `P-0680` | François LaCroix | male | 1610 | 24 August 1670 | *NULL — review* | `L5RT-PYD` |
| `P-0681` | Jeanne Therese Huot | female | 22 February 1612 | 27 August 1710 | *NULL — review* | `LV9Y-VJV` |
| `P-0682` | Louys Gasnier | male | about 13 September 1612 | after 2 February 1660 | *NULL — review* | `LT37-5J3` |
| `P-0683` | Marie Michel | female | about 1615 | 12 November 1687 | *NULL — review* | `LYKT-S6Q` |
| `P-0684` | Louys Quentin | male | 1603 |  | *NULL — review* | `LR2F-1R4` |
| `P-0685` | Marie Des Monceaux | female | 1 April 1613 |  | *NULL — review* | `L6HX-4FL` |
| `P-0686` | Michel Roulois | male | about 1622 | 12 October 1690 | *NULL — review* | `LJNB-TND` |
| `P-0687` | Jehanne Masline | female | about 25 July 1625 | 4 January 1689 | *NULL — review* | `MBXN-CF9` |
| `P-0688` | Andre Pepin | male | about 1610 |  | *NULL — review* | `LBV4-RVS` |
| `P-0689` | Jeanne Chevalier | female | 12 September 1612 |  | *NULL — review* | `MXC6-3PS` |
| `P-0690` | Jean Teste | male | about 1610 | 1652 | *NULL — review* | `K4B5-K2B` |
| `P-0691` | Louise Talonneau | female | 1611 | after 1656 | *NULL — review* | `MXR7-DS2` |
| `P-0692` | Andre Beglouin | male | 1615 |  | *NULL — review* | `LVDX-TRB` |
| `P-0693` | Françoise Touzelet | female |  |  | *NULL — review* | `LV4M-NGZ` |
| `P-0694` | Louys Carreau | male | about 1622 | 24 May 1693 | *NULL — review* | `LBJW-2LC` |
| `P-0695` | Jeanne Le Rouge | female | about 24 June 1628 | about 9 March 1696 | *NULL — review* | `LR82-XN2` |
| `P-0696` | Maria Caterina Cecchi | female | about 1730 | about 1765 | *NULL — review* | `GRL5-QZN` |
| `P-0697` | FRANCESCO NICCOLAI | male | 1 September 1616 | 11 August 1687 | Maternal Mariotti | `GYT2-Q63` |
| `P-0698` | PIERA ARCANGELI | female | 17 September 1627 | 30 July 1699 | *NULL — review* | `PM4B-B85` |
| `P-0699` | Domenico Mariotti | male | 10 September 1617 |  | Maternal Mariotti | `PHWR-ZC6` |
| `P-0700` | Giovanna | female |  |  | *NULL — review* | `PHWR-62J` |
| `P-0701` | BARTOLOMEO BONAGUIDI | male |  |  | *NULL — review* | `PHMQ-74N` |
| `P-0702` | LISABETTA RICCI | female |  | 13 January 1691 | *NULL — review* | `PHMQ-ZWS` |
| `P-0703` | Bartolomeo Stefanelli | male |  |  | *NULL — review* | `PHMN-B3F` |
| `P-0704` | Lisabetta | female | 1664 |  | *NULL — review* | `PHMJ-3D5` |
| `P-0705` | Michel Louis Pouillot Boullard | male | 27 May 1580 | 6 January 1644 | *NULL — review* | `P3JH-NG2` |
| `P-0706` | Jacqueline Laurens | female | 1584 | 1615 | *NULL — review* | `P3JH-MHN` |
| `P-0707` | Mathurin Joseph  Chevallier | male | 1580 | 1625 | *NULL — review* | `P3JH-HX8` |
| `P-0708` | Anne Marie Meronache Mesange EOL | female | about 1585 | 15 December 1625 | *NULL — review* | `P3J4-BMV` |
| `P-0709` | Rene Le Monnier | male | about 1579 | after 3 November 1647 | *NULL — review* | `LTRG-TLZ` |
| `P-0710` | Marie Le Roux | female | 3 February 1579 |  | *NULL — review* | `LRSQ-6B4` |
| `P-0711` | Jean Fafart | male |  |  | *NULL — review* | `LRJN-SYY` |
| `P-0712` | Elisabeth Tibou | female |  | after 3 November 1647 | *NULL — review* | `LR15-YH4` |
| `P-0713` | Jeanne Anna Magdalena Le Rouge Lue Roig | female | 6 September 1565 | 28 November 1618 | *NULL — review* | `P3J4-G9H` |
| `P-0714` | Jehan Le Roux | male | 1545 | 1583 | *NULL — review* | `PCX7-9TF` |
| `P-0715` | Guyonne Bourgault | female | 1555 | 1583 | *NULL — review* | `PCXQ-J9C` |
| `P-0716` | Michaellis Roig | male | about 1540 |  | *NULL — review* | `P3PX-KGZ` |
| `P-0717` | Anne Roig | female |  |  | *NULL — review* | `P3PX-BB1` |
| `P-0718` | Jean Chabot | male | about 1607 | 6 July 1653 | *NULL — review* | `LB5Y-7V4` |
| `P-0719` | Jeanne Rodé | female | 26 March 1619 | about 16 October 1664 | *NULL — review* | `LZN1-56V` |
| `P-0720` | Robert Mesange | male | about 1620 | after 17 November 1661 | *NULL — review* | `LZ6K-PWS` |
| `P-0721` | Madeleine Le Houx | female | November 1620 | after 17 November 1661 | *NULL — review* | `LRKZ-JMP` |
| `P-0722` | Yves Henault | male | 1600 | 8 August 1662 | *NULL — review* | `PWHF-6JL` |
| `P-0723` | Jeanne Galiot | female | 1605 | 8 August 1662 | *NULL — review* | `PWHF-K7N` |
| `P-0724` | Jean Macre | male | 1605 |  | *NULL — review* | `LR5M-DCV` |
| `P-0725` | Barbe Landry | female | 1600 |  | *NULL — review* | `LRJ7-DPY` |
| `P-0726` | Jacques Chabot | male | 10 April 1568 | 6 July 1653 | *NULL — review* | `LHD5-B7C` |
| `P-0727` | Jeanne Jacques | female | 1578 | 1662 | *NULL — review* | `GW8L-6KC` |
| `P-0728` | Denis Rodé | male | about 1595 | 10 March 1650 | *NULL — review* | `MVJN-XGN` |
| `P-0729` | Françoise Gouin | female | about 1596 | 10 March 1650 | *NULL — review* | `MVJN-XG5` |
| `P-0730` | Robert Mesange | male | 1571 |  | *NULL — review* | `KCPJ-DYL` |
| `P-0731` | Madeleine Jahan | female | 1573 |  | *NULL — review* | `KLY3-NWS` |
| `P-0732` | Jaques Le Houx | male | about 1580 | 16 February 1680 | *NULL — review* | `LY4L-ZK2` |
| `P-0733` | Marie Meilleur | female | about 1596 | before 9 February 1633 | *NULL — review* | `LRB2-H8W` |
| `P-0734` | End Henault ( Enaud ) | male |  |  | *NULL — review* | `PZ4L-QVG` |
| `P-0735` | End Galiot | male |  |  | *NULL — review* | `PZ42-D1C` |
| `P-0736` | Jacques Chabot | male | 28 October 1548 | 1596 | *NULL — review* | `L1R3-TPG` |
| `P-0737` | Anne Auphily | female | 1550 | 1573 | *NULL — review* | `KZVQ-JT5` |
| `P-0738` | Pierre Jacques | male | 1550 | 1612 | *NULL — review* | `2DXL-RZ2` |
| `P-0739` | Jeanne Dissert | female | 1555 | 1612 | *NULL — review* | `2DXL-R47` |
| `P-0740` | Jean Rodé | male | 1580 | 1634 | *NULL — review* | `GY4V-3TK` |
| `P-0741` | Françoise Galland | female | 1585 | 1605 | *NULL — review* | `GDVN-HVT` |
| `P-0742` | Thomas Nicolas Lehoux | male | 1560 | 1599 | *NULL — review* | `GP7D-F87` |
| `P-0743` | Jacqueline Geffray | female | about 1564 | 17 April 1649 | *NULL — review* | `GL38-F8X` |
| `P-0744` | Jehan Audet | male | 1580 | 13 February 1634 | *NULL — review* | `MLFS-BY2` |
| `P-0745` | Andrée Barreau | female | 1580 | 1641 | *NULL — review* | `GLQW-5WP` |
| `P-0746` | Pierre Roy | male | about 1578 | 27 June 1643 | *NULL — review* | `L6PX-DXX` |
| `P-0747` | Perrine Boutin | female | 15 September 1586 | 23 August 1631 | *NULL — review* | `G2NV-QD3` |
| `P-0748` | Etienne Jehan Barreau | male | 21 January 1556 | November 1614 | *NULL — review* | `GR6X-P9M` |
| `P-0749` | Antoinette Picard | female | 15 January 1560 | 1615 | *NULL — review* | `GKTC-JSZ` |
| `P-0750` | Jean Louis Boutin | male | 1544 | 1597 | *NULL — review* | `L2TV-4BJ` |
| `P-0751` | Marie Louise Germont | female | 1544 | 1599 | *NULL — review* | `L63F-W79` |
| `P-0752` | Louis Barreau | male | 1529 |  | *NULL — review* | `GPMT-QJ6` |
| `P-0753` | Charlotte Giton | female |  |  | *NULL — review* | `GPMT-4TJ` |
| `P-0754` | AnSe | female |  |  | *NULL — review* | `GR6X-Y4Z` |
| `P-0755` | Louis Boutin | male | 1521 | 1549 | *NULL — review* | `L63F-W7Y` |
| `P-0756` | Marie Guillebault | female | 1519 | 1563 | *NULL — review* | `L63F-WHP` |
| `P-0757` | Pierre Roux Dufresne | male | 1600 | 1635 | *NULL — review* | `GD74-CN6` |
| `P-0758` | Phoébé Pique | female | 1600 | 1645 | *NULL — review* | `P3NH-Z2J` |
| `P-0759` | Louis Patin | male | 12 September 1600 | 1634 | *NULL — review* | `GD74-MDW` |
| `P-0760` | Louise Magnan | female | 1602 | 1634 | *NULL — review* | `P3N4-VG7` |
| `P-0761` | Loys Dufresnoy | male | about 1580 | before October 1601 | *NULL — review* | `P3N4-KRY` |
| `P-0762` | Marie Pirenne | female | about 1580 | before 1621 | *NULL — review* | `P3NH-3F8` |
| `P-0763` | Pieter Pierre Pattyn | male | about 1568 | 15 October 1629 | *NULL — review* | `GDQJ-9HK` |
| `P-0764` | Catharine de Bouchette | female | 1568 | 26 January 1646 | *NULL — review* | `L5YL-63F` |
| `P-0765` | Paul Crepeau | male | 1573 | 1653 | *NULL — review* | `GCXL-JBQ` |
| `P-0766` | Marie Rose Claire Audet | female | 28 August 1582 | 4 January 1675 | *NULL — review* | `GPCG-TLK` |
| `P-0767` | Louis Fumolloau | male | about 1580 | 15 December 1628 | *NULL — review* | `GPCG-RVJ` |
| `P-0768` | Marie Jouet | female | 1585 |  | *NULL — review* | `PQBF-GLP` |
| `P-0769` | Verdière | male |  |  | *NULL — review* | `GR84-KPX` |
| `P-0770` | Marie Jean Granjean | female | 15 July 1599 | 1654 | *NULL — review* | `GR84-WKT` |
| `P-0771` | Joseph Laliot Leliot Le Cat | male | 1585 |  | *NULL — review* | `G666-QLF` |
| `P-0772` | Marie Leliot | female | 1595 |  | *NULL — review* | `G666-M85` |
| `P-0773` | Denis Pattyn | male | about 1518 | about 1600 | *NULL — review* | `GDQJ-W4L` |
| `P-0774` | Catherine Van Paemele | female | 1526 |  | *NULL — review* | `GDQJ-Z27` |
| `P-0775` | Jean Van Bouchette | male | 1540 | 1633 | *NULL — review* | `GH81-ZVQ` |
| `P-0776` | Catherine | female | about 1543 |  | *NULL — review* | `GLQV-4ZD` |
| `P-0777` | Maurice Crepeau | male | 25 November 1537 | 8 September 1604 | *NULL — review* | `GD74-H6K` |
| `P-0778` | Francois de Romilley | male | about 1550 |  | *NULL — review* | `KVL7-KL6` |
| `P-0779` | Jacquemine de Servaude | female | about 1550 |  | *NULL — review* | `KVL7-KG3` |
| `P-0780` | Michel Godebout | male | 24 March 1605 | 1680 | *NULL — review* | `LJH5-Y3H` |
| `P-0781` | Colette Caron | female | 1605 | 1680 | *NULL — review* | `LJHP-YK7` |
| `P-0782` | Jean Bourgoin | male | 23 September 1618 | 15 October 1646 | *NULL — review* | `MNT4-YMN` |
| `P-0783` | Marie Lefebvre | female |  | after 9 January 1662 | *NULL — review* | `LH7D-GYT` |
| `P-0784` | Pierre Burlon | male |  |  | *NULL — review* | `98BW-MZZ` |
| `P-0785` | Jeanne Danet | female |  |  | *NULL — review* | `98BW-MZ8` |
| `P-0786` | Jean Baillargeon | male | about 1612 | 1681 | *NULL — review* | `L52G-39Z` |
| `P-0787` | Marguerite Guillebourdeau | female | about 1620 | 20 October 1662 | *NULL — review* | `G8C2-PGX` |
| `P-0788` | Nicolas Godbout | male | 1573 | 1660 | *NULL — review* | `G1VT-9TD` |
| `P-0789` | Suzanne Gaudebout | female | 1565 | 1670 | *NULL — review* | `G1VT-9ZW` |
| `P-0790` | Gemmet Bourgoin | male | about 1590 |  | *NULL — review* | `G1VT-LHQ` |
| `P-0791` | Marie Bedu | female | 1600 | 1645 | *NULL — review* | `PSYY-JF9` |
| `P-0792` | Jean Le Fèbvre | male | about 1575 | December 1646 | *NULL — review* | `GQWL-8YB` |
| `P-0793` | Jeanne Doubleau | female | about 1580 | December 1646 | *NULL — review* | `LR9B-KDH` |
| `P-0794` | Louis Baillargeon | male | 1580 | 20 November 1649 | *NULL — review* | `GGXT-NTX` |
| `P-0795` | Marthe Fovier | female | 1585 | 1650 | *NULL — review* | `LT7K-55D` |
| `P-0796` | Louis Guillebourday | male | 1585 | 1631 | *NULL — review* | `LR9S-VR2` |
| `P-0797` | Marie Maguin | female | 1601 | 1650 | *NULL — review* | `KDW6-L2Q` |
| `P-0798` | Michel Godbout | male | 1527 | about 1580 | *NULL — review* | `PSYY-VLF` |
| `P-0799` | Jeanne Gay | female | 1531 |  | *NULL — review* | `KLQC-88V` |
| `P-0800` | Edward Bedu | male | 24 March 1570 |  | *NULL — review* | `G1VT-HNZ` |
| `P-0801` | Rollin Lefèbvre | male | 1550 |  | *NULL — review* | `GZV8-FR2` |
| `P-0802` | Marguerite Louise Prevost | female | 26 June 1562 | 14 April 1612 | *NULL — review* | `GZV8-V8W` |
| `P-0803` | Nicolas Pierre Doubleau | male | about 1550 | about 1620 | *NULL — review* | `G1VT-9CN` |
| `P-0804` | Jeanne | female | about 1560 | about 1650 | *NULL — review* | `PSYY-KKG` |
| `P-0805` | Francois Charles Baillargeon | male | 1560 |  | *NULL — review* | `GYTG-L4S` |
| `P-0806` | Marie Anne Bouffard | female | 1562 | 20 November 1649 | *NULL — review* | `GYTG-LPP` |
| `P-0807` | Ancetre Maguin | male | about 1585 |  | *NULL — review* | `L6QM-TDY` |
| `P-0808` | Madame Maguin | female |  |  | *NULL — review* | `L6QM-T6C` |
| `P-0809` | Sébastien Rouleau | male | 1598 | 1618 | *NULL — review* | `GM5J-KFN` |
| `P-0810` | Catherine Sauvage | female | 1598 | 29 July 1618 | *NULL — review* | `GM5J-3RC` |
| `P-0811` | Anthoine Leroux | male | about 1610 |  | *NULL — review* | `GDRV-PVR` |
| `P-0812` | Jeanne Jouary | female | 16 April 1607 | 1655 | *NULL — review* | `LYXW-2GG` |
| `P-0813` | Antoine Rouleau | male | 1575 | 1673 | *NULL — review* | `GHNH-FBM` |
| `P-0814` | Jeanne Genevieve Godbout | female | about 1578 |  | *NULL — review* | `LWBB-W1S` |
| `P-0815` | Jacques Sauvage II | male | 1575 | 1672 | *NULL — review* | `LHTM-SR2` |
| `P-0816` | Marie Catherine Jean dite Vien | female | 1576 | 1670 | *NULL — review* | `GHNH-GX5` |
| `P-0817` | Pierre Le Roux | male | about 1585 |  | *NULL — review* | `GLSW-814` |
| `P-0818` | Guillame Joiry | male | 1590 | 1619 | *NULL — review* | `GZ2G-HLF` |
| `P-0819` | Marthurine Mercier | female | 1595 | 19 May 1635 | *NULL — review* | `GZ2G-NWJ` |
| `P-0820` | Antoine Rouleau | male | 1549 | 1598 | *NULL — review* | `G11S-V4F` |
| `P-0821` | Genevieve Godbout | female | 1545 | after 1598 | *NULL — review* | `G113-9BQ` |
| `P-0822` | Antoine Godbout | male | 1515 |  | *NULL — review* | `G1F5-87Y` |
| `P-0823` | Elizabeth Godbout | female | 1519 |  | *NULL — review* | `G1F5-S67` |
| `P-0824` | Guillaume Joiry | male | 1565 |  | *NULL — review* | `GZGB-MD9` |
| `P-0825` | Roulline Nogues | female | 1570 | 1612 | *NULL — review* | `GZGY-B5V` |
| `P-0826` | Andre Jacques Mercier | male | 5 November 1570 | 18 October 1676 | *NULL — review* | `G3TX-JKG` |
| `P-0827` | Marie Roberte Cornilleau | female | 1570 | 12 January 1627 | *NULL — review* | `LVZM-Q7B` |
| `P-0828` | FILIPPO BONAGUIDI | male |  |  | *NULL — review* | `PHMQ-1KC` |
| `P-0829` | BARTOLOMEO RICCI | male |  |  | *NULL — review* | `PHMQ-LNW` |
| `P-0830` | PASQUINO NICCOLAI | male | 1570 | 29 April 1631 | Maternal Mariotti | `GYT2-2ZH` |
| `P-0831` | Maria | female |  | 27 February 1641 | *NULL — review* | `PMCB-26H` |
| `P-0832` | Santi Arcangeli | male | 27 June 1596 | 5 December 1672 | *NULL — review* | `P4N7-2J4` |
| `P-0833` | Pasqua | female |  |  | *NULL — review* | `PHMC-P6X` |
| `P-0834` | BASTIANO NICCOLAI | male | 1545 | 10 October 1619 | Maternal Mariotti | `PM4B-675` |
| `P-0835` | Salvadore Arcangeli | male |  | 11 February 1641 | *NULL — review* | `P4N7-H6G` |
| `P-0836` | Maria Domenica | female |  | 28 July 1659 | *NULL — review* | `PHMH-BKX` |
| `P-0837` | Domenico | male |  |  | *NULL — review* | `PHMC-N1W` |
| `P-0838` | Bartolomeo Niccolai | male | 1520 |  | Maternal Mariotti | `GYT2-F1T` |
| `P-0839` | Elena | female |  |  | *NULL — review* | `GYT2-ZF5` |
| `P-0840` | Giorgio Arcangeli | male |  |  | *NULL — review* | `PHMC-7P1` |
| `P-0841` | Francesco da Momigno | male |  |  | *NULL — review* | `PHMC-FPP` |
| `P-0842` | Salvatore Arcangeli | male |  |  | *NULL — review* | `PHMC-K3B` |

## People needing branch assignment

- `P-0170` Jemima Green (surname `Green`)
- `P-0172` Martha Runyan (surname `Runyan`)
- `P-0174` Mary Ruth Adams (surname `Adams`)
- `P-0176` Eliza Gunn (surname `Gunn`)
- `P-0177` Joseph Green Sr (surname `Green`)
- `P-0178` Elizabeth Ann Mershon (surname `Mershon`)
- `P-0179` Hezekiah Bonham Jr. II (surname `Bonham.`)
- `P-0180` Martha Runyon (surname `Runyon`)
- `P-0181` Vincent Runyon Sr. (surname `Runyon.`)
- `P-0182` Alice Curtis (surname `Curtis`)
- `P-0184` Sabrina Susannah Sarratt (surname `Sarratt`)
- `P-0185` William Green (surname `Green`)
- `P-0186` Joanna Reeder (surname `Reeder`)
- `P-0187` Henry Mershon II (surname `Mershon`)
- `P-0188` Hannah Haughton (surname `Haughton`)
- `P-0190` Ann Hunt (surname `Hunt`)
- `P-0191` Thomas Runyan (surname `Runyan`)
- `P-0192` Martha Dunn (surname `Dunn`)
- `P-0193` Thomas Curtis (surname `Curtis`)
- `P-0194` Elizabeth Ellis (surname `Ellis`)
- `P-0195` Thomas Dickerson Sr. (surname `Dickerson.`)
- `P-0196` Elizabeth Isabella Gambray (surname `Gambray`)
- `P-0197` Joseph Jacques Surratt (surname `Surratt`)
- `P-0198` Katherine Moreland Short (surname `Short`)
- `P-0200` Priscilla Margaret Polk (surname `Polk`)
- `P-0201` Lt. James Knox Polk (surname `Polk`)
- `P-0202` Mary Elizabeth Cottman (surname `Cottman`)
- `P-0204` Sarah J. Leach (surname `Leach`)
- `P-0205` Johann Esaias Lämlein (surname `Lämlein`)
- `P-0206` Catherine (surname `Catherine`)
- `P-0208` Ephraim Polk (surname `Polk`)
- `P-0209` Elizabeth Williams (surname `Williams`)
- `P-0210` Benjamin Cottman III. (surname `Cottman.`)
- `P-0211` Frances Brown (surname `Brown`)
- `P-0213` Anna Moor (surname `Moor`)
- `P-0214` Friderich Lemlein (surname `Lemlein`)
- `P-0215` Maria Magdalena Waltz (surname `Waltz`)
- `P-0216` Capt. Robert Bruce Pollock (surname `Pollock`)
- `P-0217` Magdalen Tasker (surname `Tasker`)
- `P-0218` Charles Williams (surname `Williams`)
- `P-0219` Mary Walston (surname `Walston`)
- `P-0220` Benjamin Cottman II (surname `Cottman`)
- `P-0221` Elizabeth Hardy (surname `Hardy`)
- `P-0222` Mr. Brown (surname `Brown`)
- `P-0223` Mrs. Brown (surname `Brown`)
- `P-0224` Hans Lauretzen Duyts (surname `Duyts`)
- `P-0225` Sarah Hance Vincent-Fountaine (surname `Vincent-Fountaine`)
- `P-0226` William Moor (surname `Moor`)
- `P-0227` Annetje Jans (surname `Jans`)
- `P-0228` Lämmlein (surname `Lämmlein`)
- `P-0229` William Talley Jr. (surname `Talley.`)
- `P-0230` Dinah Stille (surname `Stille`)
- `P-0231` John Foulk (surname `Foulk`)
- `P-0233` Simon Poulson Jr. (surname `Poulson.`)
- `P-0234` Eleanor West (surname `West`)
- `P-0235` George Patton (surname `Patton`)
- `P-0236` Maria Sinnexon (surname `Sinnexon`)
- `P-0237` Pvt. - MD William Talley Sr. (surname `Talley.`)
- `P-0238` Hannah Grubb (surname `Grubb`)
- `P-0239` Jonathan Stille (surname `Stille`)
- `P-0240` Maria Magdalena Vandever (surname `Vandever`)
- `P-0241` Stephen Foulk (surname `Foulk`)
- `P-0242` Esther Willis (surname `Willis`)
- `P-0245` Thomas West (surname `West`)
- `P-0246` Mary 'Jenny' Deane (surname `Deane`)
- `P-0247` Brewer Sinnexson (surname `Sinnexson`)
- `P-0248` Brita Hendrickson (surname `Hendrickson`)
- `P-0250` Elenger Johnson (surname `Johnson`)
- `P-0251` Joseph Grubb (surname `Grubb`)
- `P-0252` Elizabeth Perkins (surname `Perkins`)
- `P-0253` Jacob Anderson Stille Sr (surname `Stille`)
- `P-0254` Rebecca Charlesdotter Springer (surname `Springer`)
- `P-0255` Jacob Corneliusson Vandever (surname `Vandever`)
- `P-0256` Maria Stedham (surname `Stedham`)
- `P-0257` William Foulk (surname `Foulk`)
- `P-0258` Elizabeth Cope (surname `Cope`)
- `P-0259` John Willis I (surname `I`)
- `P-0260` Esther Brinton (surname `Brinton`)
- `P-0262` Margareta Johansson (surname `Johansson`)
- `P-0263` Major Thomas William West (surname `West`)
- `P-0264` Rachel Gilpin (surname `Gilpin`)
- `P-0265` John Deane Alscollins (surname `Alscollins`)
- `P-0266` Ellinor Wilson (surname `Wilson`)
- `P-0267` James Sinnexon (surname `Sinnexon`)
- `P-0268` Dorcas Harmensen (surname `Harmensen`)
- `P-0269` Johan "John" Hendrickson (surname `Hendrickson`)
- `P-0270` Brigitta Mattson (surname `Mattson`)
- `P-0271` John Thurlow Sr (surname `Thurlow`)
- `P-0272` Ruth Stevens (surname `Stevens`)
- `P-0273` William Owen (surname `Owen`)
- `P-0274` Elizabeth Davis (surname `Davis`)
- `P-0276` Elizabeth Sargent (surname `Sargent`)
- `P-0277` Joshua Palmer (surname `Palmer`)
- `P-0278` Ruth Sargeant (surname `Sargeant`)
- `P-0279` Thomas Thurlo (surname `Thurlo`)
- `P-0280` Joanna Pike (surname `Pike`)
- `P-0281` John Stevens Jr. (surname `Stevens.`)
- `P-0282` Mary Bartlett (surname `Bartlett`)
- `P-0283` Robert Henry Owens (surname `Owens`)
- `P-0284` Patience Clifton (surname `Clifton`)
- `P-0286` Rachel Bushnell (surname `Bushnell`)
- `P-0287` Isaac Sargeant (surname `Sargeant`)
- `P-0288` Anna Wood (surname `Wood`)
- `P-0289` Stephen Palmer (surname `Palmer`)
- `P-0290` Elizabeth Quimby (surname `Quimby`)
- `P-0291` George Thurlo (surname `Thurlo`)
- `P-0292` Mary Adams (surname `Adams`)
- `P-0293` John Pike (surname `Pike`)
- `P-0294` Lydia Coffin (surname `Coffin`)
- `P-0295` John Stevens Sr (surname `Stevens`)
- `P-0296` Mary Chase (surname `Chase`)
- `P-0297` Christopher Bartlett II (surname `Bartlett`)
- `P-0298` Deborah Weed (surname `Weed`)
- `P-0299` Robert Owens (surname `Owens`)
- `P-0300` Ann Lecompte (surname `Lecompte`)
- `P-0301` Jonathan Clifton (surname `Clifton`)
- `P-0302` Mary Woodgate (surname `Woodgate`)
- `P-0304` Rebecca Cary (surname `Cary`)
- `P-0305` Joseph Bushnell (surname `Bushnell`)
- `P-0306` Mary Leffingwell (surname `Leffingwell`)
- `P-0307` John Sargeant II (surname `Sargeant`)
- `P-0308` Mary Linnell (surname `Linnell`)
- `P-0309` Thomas Wood II (surname `Wood`)
- `P-0310` Mary Hunt (surname `Hunt`)
- `P-0311` Nehemiah Palmer Jr (surname `Palmer`)
- `P-0312` Jerusha Saxton (surname `Saxton`)
- `P-0314` Marie Madeleine Chabot (surname `Chabot`)
- `P-0315` Antoine Godebout (surname `Godebout`)
- `P-0316` Marie Anne Leclerc (surname `Leclerc`)
- `P-0317` Jacque Denis (surname `Denis`)
- `P-0318` Véronique Mathieu (surname `Mathieu`)
- `P-0319` Pierre Cinq-Mars dit Gobelin (surname `Gobelin`)
- `P-0320` Genevieve Belanger (surname `Belanger`)
- `P-0322` Magdelaine Odet (surname `Odet`)
- `P-0323` Jean Chabot (surname `Chabot`)
- `P-0324` Marie Madelaine Dufresne (surname `Dufresne`)
- `P-0325` Antoine Godebout (surname `Godebout`)
- `P-0326` Genevieve Rouleau (surname `Rouleau`)
- `P-0327` Jean Le Clerc (surname `Clerc`)
- `P-0328` Marie Madeleine Gosselin (surname `Gosselin`)
- `P-0329` Pierre Denys (surname `Denys`)
- `P-0330` Marie Godin (surname `Godin`)
- `P-0331` Rene Mathieu (surname `Mathieu`)
- `P-0332` Genevieve Roussin (surname `Roussin`)
- `P-0333` Marc Antoine Cinq-Mars dit Gobelin (surname `Gobelin`)
- `P-0334` Francoise Chapelain (surname `Chapelain`)
- `P-0335` Charles Bélanger (surname `Bélanger`)
- `P-0336` Geneviefve Gagnon (surname `Gagnon`)
- `P-0338` Francoise Le Mosnier (surname `Mosnier`)
- `P-0339` Nicollas Audet (surname `Audet`)
- `P-0340` Magdeleine Després (surname `Després`)
- `P-0341` Jean Chabot (surname `Chabot`)
- `P-0342` Eléonore Enaud (surname `Enaud`)
- `P-0343` Pierre Dufresne (surname `Dufresne`)
- `P-0344` Marie Madelaine Crespeau (surname `Crespeau`)
- `P-0345` Antoine Godbout (surname `Godbout`)
- `P-0346` Marguerite Labrecque (surname `Labrecque`)
- `P-0347` Guillaume Rouleau (surname `Rouleau`)
- `P-0348` Catherine Dufresne (surname `Dufresne`)
- `P-0349` Pierre Le Clerc (surname `Clerc`)
- `P-0350` Elisabeth Rondeau (surname `Rondeau`)
- `P-0351` Ignace Gosselin (surname `Gosselin`)
- `P-0352` Marie Anne Raté (surname `Raté`)
- `P-0353` Blaise Denys (surname `Denys`)
- `P-0354` Jeanne la Ponche (surname `Ponche`)
- `P-0355` Charles Godin (surname `Godin`)
- `P-0356` Marie Boucher (surname `Boucher`)
- `P-0357` Jean Mathieu (surname `Mathieu`)
- `P-0358` Anne LeTartre (surname `LeTartre`)
- `P-0359` Nicolas Roussin (surname `Roussin`)
- `P-0360` Marie Magdelaine Tremblé (surname `Tremblé`)
- `P-0361` Pierre Gobelin (surname `Gobelin`)
- `P-0362` Madeleine Labelle (surname `Labelle`)
- `P-0363` Bernard Chaplain (surname `Chaplain`)
- `P-0364` Leonore Mouillard (surname `Mouillard`)
- `P-0365` Charles Belanger (surname `Belanger`)
- `P-0366` Barbe Delphine Cloustier (surname `Cloustier`)
- `P-0367` Pierre Gagnon (surname `Gagnon`)
- `P-0368` Barbe Fortin (surname `Fortin`)
- `P-0370` Abigail Griswold (surname `Griswold`)
- `P-0371` Nathaniel Pinney (surname `Pinney`)
- `P-0372` Elizabeth Carrier (surname `Carrier`)
- `P-0373` Hamphrey Nathaniel Pinney (surname `Pinney`)
- `P-0374` Abigail Deming (surname `Deming`)
- `P-0375` Joseph Bernard (surname `Bernard`)
- `P-0376` Sarah Strong (surname `Strong`)
- `P-0377` Edward Griswold (surname `Griswold`)
- `P-0378` Abigail Williams (surname `Williams`)
- `P-0379` Nathaniel Pinney II (surname `Pinney`)
- `P-0380` Martha Thrall (surname `Thrall`)
- `P-0381` Richard Carrier (surname `Carrier`)
- `P-0382` Elizabeth Sessions (surname `Sessions`)
- `P-0383` Isaac Pinney (surname `Pinney`)
- `P-0384` Sarah Clark (surname `Clark`)
- `P-0385` Jacob Deming (surname `Deming`)
- `P-0386` Elizabeth Edwards (surname `Edwards`)
- `P-0388` Hannah Merrill (surname `Merrill`)
- `P-0389` John Strong (surname `Strong`)
- `P-0390` Abigail Ford (surname `Ford`)
- `P-0391` George Griswold (surname `Griswold`)
- `P-0392` Mary Holcombe (surname `Holcombe`)
- `P-0393` John Williams (surname `Williams`)
- `P-0394` Mary Burlly (surname `Burlly`)
- `P-0395` Samuel Pinney I (surname `I`)
- `P-0396` Joyce Bissell (surname `Bissell`)
- `P-0397` Timothy Thrall (surname `Thrall`)
- `P-0398` Deborah Gunn (surname `Gunn`)
- `P-0399` Thomas Carrier (surname `Carrier`)
- `P-0400` Martha Allen (Allin) Carrier (surname `Carrier`)
- `P-0401` Alexander Sessions (surname `Sessions`)
- `P-0402` Elizabeth Spofford (surname `Spofford`)
- `P-0403` Capt. Daniel Clark (surname `Clark`)
- `P-0404` Mary Newberry (surname `Newberry`)
- `P-0405` John Deming (surname `Deming`)
- `P-0406` Mary Mygatt (surname `Mygatt`)
- `P-0407` Richard Edwards (surname `Edwards`)
- `P-0408` Elizabeth Tuttle (surname `Tuttle`)
- `P-0409` Joseph Audet-dit-Lapointe (surname `Audet-dit-Lapointe`)
- `P-0410` Marie Anne Therrien (surname `Therrien`)
- `P-0411` Charles Delage (surname `Delage`)
- `P-0412` Marie Josephe Plante (surname `Plante`)
- `P-0413` Jacques Tremblay (surname `Tremblay`)
- `P-0414` Marie Angélique Quentin dit Cantin (surname `Cantin`)
- `P-0415` Gervais Pépin dit Lachance (surname `Lachance`)
- `P-0416` Marie Angélique Blouin (surname `Blouin`)
- `P-0417` Nicolas Odet (surname `Odet`)
- `P-0419` Barthélémy Terrien (surname `Terrien`)
- `P-0420` Marguerite Fontaine (surname `Fontaine`)
- `P-0421` Charles Delage (surname `Delage`)
- `P-0422` Marie Anne Manseau (surname `Manseau`)
- `P-0423` Georges Plante (surname `Plante`)
- `P-0424` Margueritte Crepeau (surname `Crepeau`)
- `P-0425` Jacques Tremblay (surname `Tremblay`)
- `P-0426` Agathe Lacroix (surname `Lacroix`)
- `P-0427` Louis Quentin (surname `Quentin`)
- `P-0428` Marie Matthieu (surname `Matthieu`)
- `P-0429` Jan Pepin (surname `Pepin`)
- `P-0430` Madeleine Fontaine (surname `Fontaine`)
- `P-0431` Jacque Belouyn (surname `Belouyn`)
- `P-0432` Marie Geneviève Plante (surname `Plante`)
- `P-0433` Pierre Terrien (surname `Terrien`)
- `P-0434` Gabrielle Minaud (surname `Minaud`)
- `P-0435` Estienne de Fontaine (surname `Fontaine`)
- `P-0436` Marie Conil (surname `Conil`)
- `P-0437` Nicolas Delage (surname `Delage`)
- `P-0438` Marie Petit (surname `Petit`)
- `P-0439` Jacques Manseau (surname `Manseau`)
- `P-0440` Marguerite Latouche (surname `Latouche`)
- `P-0441` Jean Plante (surname `Plante`)
- `P-0442` Françoise Boucher (surname `Boucher`)
- `P-0443` Maurice Créspeau (surname `Créspeau`)
- `P-0444` Margueritte La Verdure (surname `Verdure`)
- `P-0445` François-Normand Lacroix (surname `Lacroix`)
- `P-0446` Anne Gangner (surname `Gangner`)
- `P-0447` Nicolas Quentin (surname `Quentin`)
- `P-0448` Magdelaine Roulois (surname `Roulois`)
- `P-0449` Anthoine Pepin (surname `Pepin`)
- `P-0450` Marie Taiste (surname `Taiste`)
- `P-0451` Emeri Beglouin (surname `Beglouin`)
- `P-0452` Marie Careau (surname `Careau`)
- `P-0454` ELISABETTA BONAGUIDI (surname `BONAGUIDI`)
- `P-0455` GIUSEPPE GIACOMELLI (surname `GIACOMELLI`)
- `P-0456` ANGIOLA CASSANESI (surname `CASSANESI`)
- `P-0458` MARIA ANGIOLA BARONTI (surname `BARONTI`)
- `P-0459` MARIANO BONAGUIDI (surname `BONAGUIDI`)
- `P-0460` CATERINA PAPINI (surname `PAPINI`)
- `P-0462` FIORE MARIOTTI (surname `MARIOTTI`)
- `P-0463` GIOVANNI BONAGUIDI (surname `BONAGUIDI`)
- `P-0464` MARIA ANGELA STEFANELLI (surname `STEFANELLI`)
- `P-0465` Pasquino Papini (surname `Papini`)
- `P-0466` Barbera Simoni (surname `Simoni`)
- `P-0467` Green (surname `Green`)
- `P-0468` John Reeder Jr (surname `Reeder`)
- `P-0469` Joanna Burroughs (surname `Burroughs`)
- `P-0470` Henri Marchand I (surname `I`)
- `P-0471` Mary Ruscoe (surname `Ruscoe`)
- `P-0472` John Houghton (surname `Houghton`)
- `P-0473` Dyna Philips (surname `Philips`)
- `P-0475` Hannah Fuller (surname `Fuller`)
- `P-0476` Vincent Rongnion (surname `Rongnion`)
- `P-0477` Anna Martha Boutcher (surname `Boutcher`)
- `P-0478` Hugh Dunn (surname `Dunn`)
- `P-0479` Elizabeth Drake (surname `Drake`)
- `P-0480` John Curtis (surname `Curtis`)
- `P-0481` Anne Revell (surname `Revell`)
- `P-0482` Thomas Ellis (surname `Ellis`)
- `P-0483` Hannah Hebden Hugh (surname `Hugh`)
- `P-0485` Elizabeth Trundle (surname `Trundle`)
- `P-0486` Richard Gambray (surname `Gambray`)
- `P-0487` Missy Nae O'Dell (surname `O'Dell`)
- `P-0488` Isaac Baptiste "Sarratt" (surname `"Sarratt"`)
- `P-0489` Nicole Oudinot (surname `Oudinot`)
- `P-0490` William C Short (surname `Short`)
- `P-0491` Mary Elisabeth Nash (surname `Nash`)
- `P-0492` Pål Persson (surname `Persson`)
- `P-0493` Margareta Olofsdotter (surname `Olofsdotter`)
- `P-0494` Simon Johnsson (surname `Johnsson`)
- `P-0495` ? (surname `?`)
- `P-0496` William Thomas West (surname `West`)
- `P-0497` Elizabeth Middlemore (surname `Middlemore`)
- `P-0498` Thomas Gilpin (surname `Gilpin`)
- `P-0499` Joan Bartholomew (surname `Bartholomew`)
- `P-0500` Aaron Deane (surname `Deane`)
- `P-0501` Rebecca Gardyne (surname `Gardyne`)
- `P-0502` John Wilson (surname `Wilson`)
- `P-0503` Elsabeth Atkinson (surname `Atkinson`)
- `P-0504` Broer Sinnicksson (surname `Sinnicksson`)
- `P-0505` Sophia Pålsdotter (surname `Pålsdotter`)
- `P-0506` Jan Harmansen (surname `Harmansen`)
- `P-0507` Catherina Corderus (surname `Corderus`)
- `P-0508` Hendrick Eigil Jacobsson (surname `Jacobsson`)
- `P-0509` Gertrude Hendricksdotter (surname `Hendricksdotter`)
- `P-0510` Peter Mattson Dalbo (surname `Dalbo`)
- `P-0511` Catherine Rambo (surname `Rambo`)
- `P-0513` Elinor Jansen (surname `Jansen`)
- `P-0514` John Grubb Sr. (surname `Grubb.`)
- `P-0515` Frances (surname `Frances`)
- `P-0516` Anders Olofsson Stille (surname `Stille`)
- `P-0517` Annettje Perterse von Cowenhoven (surname `Cowenhoven`)
- `P-0518` Carl Christopher Springer (surname `Springer`)
- `P-0519` Margietje Maria Hendricksdotter (surname `Hendricksdotter`)
- `P-0520` Cornelius Vandeveer (surname `Vandeveer`)
- `P-0521` Margareta Fransson Van De  Ver (surname `Ver`)
- `P-0522` Adam Stidham (surname `Stidham`)
- `P-0523` Katherine Karin (surname `Karin`)
- `P-0524` Owen Foulke (surname `Foulke`)
- `P-0525` Sarah Elinor Morgan (surname `Morgan`)
- `P-0526` Oliver Cope (surname `Cope`)
- `P-0527` Rebecca Crooke (surname `Crooke`)
- `P-0528` William Brinton Sr (surname `Brinton`)
- `P-0529` Ann Bagley (surname `Bagley`)
- `P-0530` Laurens Duyts (surname `Duyts`)
- `P-0531` Grietje\Ijtje\Ytie (Jans\Jansen) Dye\ Duytszen\Duyts (surname `Duytszen\Duyts`)
- `P-0532` Robert Bruce Pollock (surname `Pollock`)
- `P-0533` Jean Crawford (surname `Crawford`)
- `P-0534` Roger Tasker (surname `Tasker`)
- `P-0535` Magdalen Porter (surname `Porter`)
- `P-0536` Alexander Williams (surname `Williams`)
- `P-0537` Ruth Ann Tackling (surname `Tackling`)
- `P-0538` Nehemiah Covington (surname `Covington`)
- `P-0539` Mary Vaughan (surname `Vaughan`)
- `P-0540` Benjamin Cottman (surname `Cottman`)
- `P-0541` Mary Hudnall (surname `Hudnall`)
- `P-0542` Robert Hardy (surname `Hardy`)
- `P-0543` Mary Ann Olcott Moon (surname `Moon`)
- `P-0544` Deacon Samuel Allen Jr. of Bridgewater (surname `Bridgewater`)
- `P-0545` Sarah Partridge (surname `Partridge`)
- `P-0546` John Cary (surname `Cary`)
- `P-0547` Elizabeth Godfrey (surname `Godfrey`)
- `P-0548` Richard Bushnell Sr (surname `Bushnell`)
- `P-0549` Mary Marvin (surname `Marvin`)
- `P-0550` Lt. Thomas Leffingwell Jr. (surname `Leffingwell.`)
- `P-0551` Mary White (surname `White`)
- `P-0552` John Sargent (surname `Sargent`)
- `P-0553` Deborah Hyllier (surname `Hyllier`)
- `P-0554` David Linnell (surname `Linnell`)
- `P-0555` Hannah Shelley (surname `Shelley`)
- `P-0556` Thomas Wood I (surname `I`)
- `P-0557` Ann Hobkinson (surname `Hobkinson`)
- `P-0558` Nehemiah Hunt, Sr. (surname `Hunt,.`)
- `P-0559` Mary Toll (surname `Toll`)
- `P-0560` Lieutenant Nehemiah Palmer Sr. (surname `Palmer.`)
- `P-0561` Hannah Stanton (surname `Stanton`)
- `P-0562` Captain Joseph Saxton (surname `Saxton`)
- `P-0563` Hannah Denison (surname `Denison`)
- `P-0564` Lucretia Pinney Carroll (surname `Carroll`)
- `P-0565` Sir Francis Bernard II (surname `Bernard`)
- `P-0566` Mary Woolhouse (surname `Woolhouse`)
- `P-0567` Mathew Merrill (surname `Merrill`)
- `P-0568` Isabell Freeman (surname `Freeman`)
- `P-0569` John Strong (surname `Strong`)
- `P-0570` Mrs. John Strong (surname `Strong`)
- `P-0571` Thomas Ford of Bridport (surname `Bridport`)
- `P-0572` Elizabeth Charde (surname `Charde`)
- `P-0573` Edward Griswold (surname `Griswold`)
- `P-0574` Margaret (surname `Margaret`)
- `P-0575` Thomas Holcombe (surname `Holcombe`)
- `P-0576` Elizabeth (surname `Elizabeth`)
- `P-0577` Robert Williams (surname `Williams`)
- `P-0578` Elizabeth Stratton (surname `Stratton`)
- `P-0579` Sir Humphrey Pinney (surname `Pinney`)
- `P-0580` Mary Hull (surname `Hull`)
- `P-0581` John Bissell (surname `Bissell`)
- `P-0582` unknown (surname `unknown`)
- `P-0583` William Thrall (surname `Thrall`)
- `P-0584` Elizabeth Goode (surname `Goode`)
- `P-0585` Thomas Gunn (surname `Gunn`)
- `P-0586` Elizabeth (surname `Elizabeth`)
- `P-0587` Richard (Rici) Morgan de Ryppon (surname `Ryppon`)
- `P-0588` Mrs. Uknown Morgan (surname `Morgan`)
- `P-0590` Samuel Sessions (surname `Sessions`)
- `P-0591` Mrs. Lucille Sessions (surname `Sessions`)
- `P-0592` John Spofford II (surname `Spofford`)
- `P-0593` Elizabeth Scott (surname `Scott`)
- `P-0594` Sabbath Clark (surname `Clark`)
- `P-0595` Elizabeth Overton (surname `Overton`)
- `P-0596` Captain Thomas Newberry (surname `Newberry`)
- `P-0597` Joane Dabinott (surname `Dabinott`)
- `P-0598` John Deming (surname `Deming`)
- `P-0599` Honor Treat (surname `Treat`)
- `P-0600` Joseph Mygatt (surname `Mygatt`)
- `P-0601` Ann LNU (surname `LNU`)
- `P-0602` William Edwards (surname `Edwards`)
- `P-0603` Agnes Harris (surname `Harris`)
- `P-0604` William Tuttle (surname `Tuttle`)
- `P-0605` Elizabeth (surname `Elizabeth`)
- `P-0607` Jeanne Josse (surname `Josse`)
- `P-0608` Mathurin Le Monnier (surname `Monnier`)
- `P-0609` Francoise Faffart (surname `Faffart`)
- `P-0610` Innocent Audet (surname `Audet`)
- `P-0611` Vincende Roy (surname `Roy`)
- `P-0612` Francois Despres (surname `Despres`)
- `P-0613` Madeleine Legrand (surname `Legrand`)
- `P-0614` Mathurin Chabot (surname `Chabot`)
- `P-0615` Marie Mesange (surname `Mesange`)
- `P-0616` Michel Enaud (surname `Enaud`)
- `P-0617` Geneviève Eleonore Macré (surname `Macré`)
- `P-0618` Pierre Dufraisne (surname `Dufraisne`)
- `P-0619` Anne Patin (surname `Patin`)
- `P-0620` Nicolas Godbout (surname `Godbout`)
- `P-0621` Marie Marthe Bourgoin (surname `Bourgoin`)
- `P-0622` Pierre BRULON (surname `BRULON`)
- `P-0623` Janne Baillargent (surname `Baillargent`)
- `P-0624` Gabriel Rouleau dit Sanssoucy (surname `Sanssoucy`)
- `P-0625` Mathurine Leroux (surname `Leroux`)
- `P-0626` Jean Le Clerc (surname `Clerc`)
- `P-0627` Marie Blanquet (surname `Blanquet`)
- `P-0628` Thomas Rondeau (surname `Rondeau`)
- `P-0629` Andrée Remondiere (surname `Remondiere`)
- `P-0630` Gabriel Gosselin (surname `Gosselin`)
- `P-0631` Françoise Lelievre (surname `Lelievre`)
- `P-0632` Jacques Raté (surname `Raté`)
- `P-0633` Anne Martin (surname `Martin`)
- `P-0634` André Terrien (surname `Terrien`)
- `P-0635` Marie Anne Foucault (surname `Foucault`)
- `P-0636` Jean Mignault (surname `Mignault`)
- `P-0637` Marie Louise Cloutier (surname `Cloutier`)
- `P-0638` Jacque de Fontaine (surname `Fontaine`)
- `P-0639` Jeanne Collinet (surname `Collinet`)
- `P-0640` Pierre Conille (surname `Conille`)
- `P-0641` Marie Giton (surname `Giton`)
- `P-0642` Jacques Delage (surname `Delage`)
- `P-0643` Marguerite (surname `Marguerite`)
- `P-0644` Eustache Petit (surname `Petit`)
- `P-0645` Barbe Cochois (surname `Cochois`)
- `P-0646` Etienne Fontenay Manseau (surname `Manseau`)
- `P-0647` Marie MÉTAYER (surname `MÉTAYER`)
- `P-0648` Jean Latouche (surname `Latouche`)
- `P-0649` Marie Tevellon (surname `Tevellon`)
- `P-0650` Nicolas Plante (surname `Plante`)
- `P-0651` Elizabeth Chauvin (surname `Chauvin`)
- `P-0652` Marin Boucher (surname `Boucher`)
- `P-0653` Perrine Malet (surname `Malet`)
- `P-0654` Jehan Créspeau (surname `Créspeau`)
- `P-0655` Suzanne Fumoleau (surname `Fumoleau`)
- `P-0656` Martin La Verdure (surname `Verdure`)
- `P-0657` Jacline Le Liot (surname `Liot`)
- `P-0658` François Marsan Laponche (surname `Laponche`)
- `P-0659` Françoise Lapierre (surname `Lapierre`)
- `P-0660` Jacques Godin (surname `Godin`)
- `P-0661` Marguerite Nicole (surname `Nicole`)
- `P-0662` Jean Jacob Mathieu (surname `Mathieu`)
- `P-0663` Isabelle Monnachau (surname `Monnachau`)
- `P-0664` René Letartre (surname `Letartre`)
- `P-0665` Louise Goulet (surname `Goulet`)
- `P-0666` Jean Roussin (surname `Roussin`)
- `P-0667` Madeleine Giguère (surname `Giguère`)
- `P-0668` Loys ou Louis Chappellain (surname `Chappellain`)
- `P-0669` Francoise Dechaux (surname `Dechaux`)
- `P-0670` André Mouillard (surname `Mouillard`)
- `P-0671` Sebastienne (surname `Sebastienne`)
- `P-0672` Francois Bellanger (surname `Bellanger`)
- `P-0673` Marie Guyon (surname `Guyon`)
- `P-0674` Zacharie Cloustier (surname `Cloustier`)
- `P-0675` Magdeleine Aymart (surname `Aymart`)
- `P-0676` Pierre Gagnon (surname `Gagnon`)
- `P-0677` Vincente des Varieux (surname `Varieux`)
- `P-0678` Julien Fortin (surname `Fortin`)
- `P-0679` Genevieve De Lamare (surname `Lamare`)
- `P-0680` François LaCroix (surname `LaCroix`)
- `P-0681` Jeanne Therese Huot (surname `Huot`)
- `P-0682` Louys Gasnier (surname `Gasnier`)
- `P-0683` Marie Michel (surname `Michel`)
- `P-0684` Louys Quentin (surname `Quentin`)
- `P-0685` Marie Des Monceaux (surname `Monceaux`)
- `P-0686` Michel Roulois (surname `Roulois`)
- `P-0687` Jehanne Masline (surname `Masline`)
- `P-0688` Andre Pepin (surname `Pepin`)
- `P-0689` Jeanne Chevalier (surname `Chevalier`)
- `P-0690` Jean Teste (surname `Teste`)
- `P-0691` Louise Talonneau (surname `Talonneau`)
- `P-0692` Andre Beglouin (surname `Beglouin`)
- `P-0693` Françoise Touzelet (surname `Touzelet`)
- `P-0694` Louys Carreau (surname `Carreau`)
- `P-0695` Jeanne Le Rouge (surname `Rouge`)
- `P-0696` Maria Caterina Cecchi (surname `Cecchi`)
- `P-0698` PIERA ARCANGELI (surname `ARCANGELI`)
- `P-0700` Giovanna (surname `Giovanna`)
- `P-0701` BARTOLOMEO BONAGUIDI (surname `BONAGUIDI`)
- `P-0702` LISABETTA RICCI (surname `RICCI`)
- `P-0703` Bartolomeo Stefanelli (surname `Stefanelli`)
- `P-0704` Lisabetta (surname `Lisabetta`)
- `P-0705` Michel Louis Pouillot Boullard (surname `Boullard`)
- `P-0706` Jacqueline Laurens (surname `Laurens`)
- `P-0707` Mathurin Joseph  Chevallier (surname `Chevallier`)
- `P-0708` Anne Marie Meronache Mesange EOL (surname `EOL`)
- `P-0709` Rene Le Monnier (surname `Monnier`)
- `P-0710` Marie Le Roux (surname `Roux`)
- `P-0711` Jean Fafart (surname `Fafart`)
- `P-0712` Elisabeth Tibou (surname `Tibou`)
- `P-0713` Jeanne Anna Magdalena Le Rouge Lue Roig (surname `Roig`)
- `P-0714` Jehan Le Roux (surname `Roux`)
- `P-0715` Guyonne Bourgault (surname `Bourgault`)
- `P-0716` Michaellis Roig (surname `Roig`)
- `P-0717` Anne Roig (surname `Roig`)
- `P-0718` Jean Chabot (surname `Chabot`)
- `P-0719` Jeanne Rodé (surname `Rodé`)
- `P-0720` Robert Mesange (surname `Mesange`)
- `P-0721` Madeleine Le Houx (surname `Houx`)
- `P-0722` Yves Henault (surname `Henault`)
- `P-0723` Jeanne Galiot (surname `Galiot`)
- `P-0724` Jean Macre (surname `Macre`)
- `P-0725` Barbe Landry (surname `Landry`)
- `P-0726` Jacques Chabot (surname `Chabot`)
- `P-0727` Jeanne Jacques (surname `Jacques`)
- `P-0728` Denis Rodé (surname `Rodé`)
- `P-0729` Françoise Gouin (surname `Gouin`)
- `P-0730` Robert Mesange (surname `Mesange`)
- `P-0731` Madeleine Jahan (surname `Jahan`)
- `P-0732` Jaques Le Houx (surname `Houx`)
- `P-0733` Marie Meilleur (surname `Meilleur`)
- `P-0734` End Henault ( Enaud ) (surname `Henault`)
- `P-0735` End Galiot (surname `Galiot`)
- `P-0736` Jacques Chabot (surname `Chabot`)
- `P-0737` Anne Auphily (surname `Auphily`)
- `P-0738` Pierre Jacques (surname `Jacques`)
- `P-0739` Jeanne Dissert (surname `Dissert`)
- `P-0740` Jean Rodé (surname `Rodé`)
- `P-0741` Françoise Galland (surname `Galland`)
- `P-0742` Thomas Nicolas Lehoux (surname `Lehoux`)
- `P-0743` Jacqueline Geffray (surname `Geffray`)
- `P-0744` Jehan Audet (surname `Audet`)
- `P-0745` Andrée Barreau (surname `Barreau`)
- `P-0746` Pierre Roy (surname `Roy`)
- `P-0747` Perrine Boutin (surname `Boutin`)
- `P-0748` Etienne Jehan Barreau (surname `Barreau`)
- `P-0749` Antoinette Picard (surname `Picard`)
- `P-0750` Jean Louis Boutin (surname `Boutin`)
- `P-0751` Marie Louise Germont (surname `Germont`)
- `P-0752` Louis Barreau (surname `Barreau`)
- `P-0753` Charlotte Giton (surname `Giton`)
- `P-0754` AnSe (surname `AnSe`)
- `P-0755` Louis Boutin (surname `Boutin`)
- `P-0756` Marie Guillebault (surname `Guillebault`)
- `P-0757` Pierre Roux Dufresne (surname `Dufresne`)
- `P-0758` Phoébé Pique (surname `Pique`)
- `P-0759` Louis Patin (surname `Patin`)
- `P-0760` Louise Magnan (surname `Magnan`)
- `P-0761` Loys Dufresnoy (surname `Dufresnoy`)
- `P-0762` Marie Pirenne (surname `Pirenne`)
- `P-0763` Pieter Pierre Pattyn (surname `Pattyn`)
- `P-0764` Catharine de Bouchette (surname `Bouchette`)
- `P-0765` Paul Crepeau (surname `Crepeau`)
- `P-0766` Marie Rose Claire Audet (surname `Audet`)
- `P-0767` Louis Fumolloau (surname `Fumolloau`)
- `P-0768` Marie Jouet (surname `Jouet`)
- `P-0769` Verdière (surname `Verdière`)
- `P-0770` Marie Jean Granjean (surname `Granjean`)
- `P-0771` Joseph Laliot Leliot Le Cat (surname `Cat`)
- `P-0772` Marie Leliot (surname `Leliot`)
- `P-0773` Denis Pattyn (surname `Pattyn`)
- `P-0774` Catherine Van Paemele (surname `Paemele`)
- `P-0775` Jean Van Bouchette (surname `Bouchette`)
- `P-0776` Catherine (surname `Catherine`)
- `P-0777` Maurice Crepeau (surname `Crepeau`)
- `P-0778` Francois de Romilley (surname `Romilley`)
- `P-0779` Jacquemine de Servaude (surname `Servaude`)
- `P-0780` Michel Godebout (surname `Godebout`)
- `P-0781` Colette Caron (surname `Caron`)
- `P-0782` Jean Bourgoin (surname `Bourgoin`)
- `P-0783` Marie Lefebvre (surname `Lefebvre`)
- `P-0784` Pierre Burlon (surname `Burlon`)
- `P-0785` Jeanne Danet (surname `Danet`)
- `P-0786` Jean Baillargeon (surname `Baillargeon`)
- `P-0787` Marguerite Guillebourdeau (surname `Guillebourdeau`)
- `P-0788` Nicolas Godbout (surname `Godbout`)
- `P-0789` Suzanne Gaudebout (surname `Gaudebout`)
- `P-0790` Gemmet Bourgoin (surname `Bourgoin`)
- `P-0791` Marie Bedu (surname `Bedu`)
- `P-0792` Jean Le Fèbvre (surname `Fèbvre`)
- `P-0793` Jeanne Doubleau (surname `Doubleau`)
- `P-0794` Louis Baillargeon (surname `Baillargeon`)
- `P-0795` Marthe Fovier (surname `Fovier`)
- `P-0796` Louis Guillebourday (surname `Guillebourday`)
- `P-0797` Marie Maguin (surname `Maguin`)
- `P-0798` Michel Godbout (surname `Godbout`)
- `P-0799` Jeanne Gay (surname `Gay`)
- `P-0800` Edward Bedu (surname `Bedu`)
- `P-0801` Rollin Lefèbvre (surname `Lefèbvre`)
- `P-0802` Marguerite Louise Prevost (surname `Prevost`)
- `P-0803` Nicolas Pierre Doubleau (surname `Doubleau`)
- `P-0804` Jeanne (surname `Jeanne`)
- `P-0805` Francois Charles Baillargeon (surname `Baillargeon`)
- `P-0806` Marie Anne Bouffard (surname `Bouffard`)
- `P-0807` Ancetre Maguin (surname `Maguin`)
- `P-0808` Madame Maguin (surname `Maguin`)
- `P-0809` Sébastien Rouleau (surname `Rouleau`)
- `P-0810` Catherine Sauvage (surname `Sauvage`)
- `P-0811` Anthoine Leroux (surname `Leroux`)
- `P-0812` Jeanne Jouary (surname `Jouary`)
- `P-0813` Antoine Rouleau (surname `Rouleau`)
- `P-0814` Jeanne Genevieve Godbout (surname `Godbout`)
- `P-0815` Jacques Sauvage II (surname `Sauvage`)
- `P-0816` Marie Catherine Jean dite Vien (surname `Vien`)
- `P-0817` Pierre Le Roux (surname `Roux`)
- `P-0818` Guillame Joiry (surname `Joiry`)
- `P-0819` Marthurine Mercier (surname `Mercier`)
- `P-0820` Antoine Rouleau (surname `Rouleau`)
- `P-0821` Genevieve Godbout (surname `Godbout`)
- `P-0822` Antoine Godbout (surname `Godbout`)
- `P-0823` Elizabeth Godbout (surname `Godbout`)
- `P-0824` Guillaume Joiry (surname `Joiry`)
- `P-0825` Roulline Nogues (surname `Nogues`)
- `P-0826` Andre Jacques Mercier (surname `Mercier`)
- `P-0827` Marie Roberte Cornilleau (surname `Cornilleau`)
- `P-0828` FILIPPO BONAGUIDI (surname `BONAGUIDI`)
- `P-0829` BARTOLOMEO RICCI (surname `RICCI`)
- `P-0831` Maria (surname `Maria`)
- `P-0832` Santi Arcangeli (surname `Arcangeli`)
- `P-0833` Pasqua (surname `Pasqua`)
- `P-0835` Salvadore Arcangeli (surname `Arcangeli`)
- `P-0836` Maria Domenica (surname `Domenica`)
- `P-0837` Domenico (surname `Domenico`)
- `P-0839` Elena (surname `Elena`)
- `P-0840` Giorgio Arcangeli (surname `Arcangeli`)
- `P-0841` Francesco da Momigno (surname `Momigno`)
- `P-0842` Salvatore Arcangeli (surname `Arcangeli`)

## New Places

| new id | name | lat | long | quality |
|---|---|---|---|---|
| `PL-5245` | Hopewell Township, Hunterdon, New Jersey, United States | 40.3889 | -74.7644 | township |
| `PL-5247` | Trenton, Mercer, New Jersey, United States | 40.2233 | -74.7642 | settlement |
| `PL-5248` | Hopewell Township, Hunterdon, New Jersey, British Colonial America | 40.3889 | -74.7644 | township |
| `PL-5252` | Hunterdon, New Jersey, British Colonial America | 40.56667 | -74.93333 | settlement |
| `PL-5257` | New Jersey, British Colonial America | 40.17 | -74.5 | settlement |
| `PL-5263` | Morris Township, Washington, Pennsylvania, United States | 40.037 | -80.294 | township |
| `PL-5270` | Frederick, Frederick, Maryland, United States | 39.41417 | -77.41083 | settlement |
| `PL-5299` | Maidenhead, Maidenhead Township, Hunterdon, New Jersey, United States | 40.2972 | -74.73 | settlement |
| `PL-5300` | Burlington, New Jersey, United States | 39.88333 | -74.64167 | settlement |
| `PL-5310` | Woodbridge Township, Middlesex, New Jersey, United States | 40.5667 | -74.2917 | township |
| `PL-5311` | Hopewell Township, Mercer, New Jersey, United States | 40.3889 | -74.7644 | township |
| `PL-5356` | Charles, Maryland, British Colonial America | 38.517 | -76.65 | settlement |
| `PL-5357` | Montgomery, Maryland, United States | 39.15 | -77.2 | settlement |
| `PL-5371` | St Pauls Parish, Prince George's, Maryland, United States | 38.549998 | -76.58333 | settlement |
| `PL-5372` | Prince George, Virginia, United States | 37.1819 | -77.2209 | settlement |
| `PL-5388` | England | 52.4379 | -1.6496 | region |
| `PL-5389` | Trenton, Hunterdon, New Jersey, British Colonial America | 40.2233 | -74.7642 | settlement |
| `PL-5407` | Newtown, Queens, New York Colony, British Colonial America | 40.738 | -73.8801 | settlement |
| `PL-5426` | Caen, Calvados, France | 49.184 | -0.368 | settlement |
| `PL-5446` | Elmhurst, Queens, New York City, New York, United States | 40.738 | -73.8801 | settlement |
| `PL-5447` | Princeton Township, Mercer, New Jersey, United States | 40.3667 | -74.675 | township |
| `PL-5469` | Piscataway Township, Middlesex, New Jersey, British Colonial America | 40.5417 | -74.4667 | township |
| `PL-5470` | Piscataway, Middlesex, New Jersey, British Colonial America | 40.4992 | -74.3994 | settlement |
| `PL-5494` | Piscataway, Middlesex, New Jersey, United States | 40.4992 | -74.3994 | settlement |
| `PL-5519` | Hopewell, Hopewell Township, Hunterdon, New Jersey, British Colonial America | 40.3892 | -74.7622 | settlement |
| `PL-5570` | North Wingfield, Derbyshire, England, United Kingdom | 53.1837 | -1.3887 | settlement |
| `PL-5571` | Mansfield, Burlington, New Jersey, United States | 40.0806 | -74.7184 | settlement |
| `PL-5599` | Pontefract, Yorkshire, England, United Kingdom | 53.691001 | -1.312 | settlement |
| `PL-5600` | New Jersey, United States | 40.17 | -74.5 | settlement |
| `PL-5630` | Prince George's, Maryland, British Colonial America | 38.832999 | -76.849999 | settlement |
| `PL-5661` | Prince George's, Maryland, United States | 38.833 | -76.85 | settlement |
| `PL-5693` | Avize, Marne, France | 48.9711 | 4.0048 | settlement |
| `PL-5726` | Scotland, United Kingdom | 56.81674 | -4.18396 | settlement |
| `PL-5760` | Somerset, Maryland, United States | 38.0801 | -75.8535 | settlement |
| `PL-5795` | Morgantown, Fauquier, Virginia, United States | 38.8456 | -77.8792 | settlement |
| `PL-5831` | Somerset, Maryland, British Colonial America | 38.08007 | -75.85347 | settlement |
| `PL-5832` | Frederick, Frederick, Maryland, British Colonial America | 39.2386 | -77.2797 | settlement |
| `PL-5907` | Richmond, New York Colony, British Colonial America | 40.58333 | -74.15 | settlement |
| `PL-5908` | Perth Amboy, Middlesex, New Jersey, British Colonial America | 40.5203 | -74.2722 | settlement |
| `PL-5948` | Cranbury, Cranbury Township, Middlesex, New Jersey, United States | 40.3135 | -74.5202 | settlement |
| `PL-5989` | Württemberg, Germany | 48.5727 | 9.0533 | settlement |
| `PL-5990` | Winchester, Frederick, Virginia, United States | 39.1838 | -78.1645 | settlement |
| `PL-6033` | Manheim, Bergheim, North Rhine-Westphalia, Germany | 50.8833 | 6.6 | settlement |
| `PL-6120` | County Donegal, Ireland | 54.91084 | -7.90151 | county |
| `PL-6121` | Maryland, British Colonial America | 39 | -76.7 | settlement |
| `PL-6167` | Crisfield, Somerset, Maryland, United States | 37.9833 | -75.8542 | settlement |
| `PL-6168` | Charles, Maryland, United States | 38.483 | -76.983 | settlement |
| `PL-6216` | Philadelphia, Pennsylvania, British Colonial America | 40 | -75.116 | settlement |
| `PL-6217` | Philadelphia, Pennsylvania, United States | 39.9522 | -75.1642 | settlement |
| `PL-6267` | Philadelphia, Philadelphia, Pennsylvania, British Colonial America | 39.9522 | -75.1642 | settlement |
| `PL-6268` | Cheltenham Township, Montgomery, Pennsylvania, United States | 40.0786 | -75.1383 | township |
| `PL-6320` | Richmond, Richmond, New York, United States | 40.5739 | -74.1308 | settlement |
| `PL-6321` | Perth Amboy, Middlesex, New Jersey, United States | 40.52028 | -74.27222 | settlement |
| `PL-6375` | New York Colony, British Colonial America | 43 | -75.5 | settlement |
| `PL-6430` | Untermünkheim, Hall, Württemberg, Germany | 49.1547 | 9.734 | settlement |
| `PL-6486` | Hall, Württemberg, Germany | 49.1633 | 9.9 | settlement |
| `PL-6543` | Donegal, Donegal, County Donegal, Ireland | 54.65494 | -8.0999 | settlement |
| `PL-6544` | District 11, Somerset, Maryland, British Colonial America | 38.17583 | -75.89028 | settlement |
| `PL-6603` | Cavanacor, Clonleigh, County Donegal, Ireland | 54.84831 | -7.51561 | settlement |
| `PL-6663` | Queen Anne Parish, Prince George's, Maryland, British Colonial America | 38.88333 | -76.566659 | settlement |
| `PL-6904` | Philadelphia Monthly Meeting, Philadelphia, Philadelphia, Pennsylvania, United States | 39.95608 | -75.1651 | settlement |
| `PL-7027` | Harlem, New York County, New York, United States | 40.8078 | -73.9458 | settlement |
| `PL-7028` | Richmond, Staten Island, New York City, New York, United States | 40.5739 | -74.1308 | settlement |
| `PL-7092` | Brooklyn, New York City, New York, United States | 40.636 | -73.951 | settlement |
| `PL-7349` | Brandywine Hundred, New Castle, Delaware, British Colonial America | 39.7917 | -75.5167 | township |
| `PL-7350` | Brandywine Hundred, New Castle, Delaware, United States | 39.7916 | -75.5165 | township |
| `PL-7483` | Delaware, British Colonial America | 39 | -75.5 | settlement |
| `PL-7685` | Concord, Leacock Township, Lancaster, Pennsylvania, British Colonial America | 40.0222 | -76.1311 | settlement |
| `PL-7890` | Marcus Hook, Delaware, Pennsylvania, United States | 39.8208 | -75.4136 | settlement |
| `PL-8029` | Christiana Hundred, New Castle, Delaware, British Colonial America | 39.7917 | -75.6 | township |
| `PL-8170` | Chester, Pennsylvania, British Colonial America | 39.988 | -75.718 | settlement |
| `PL-8171` | Bethel Township, Chester, Pennsylvania, United States | 39.8487 | -75.4856 | township |
| `PL-8244` | Westbury, Nassau, New York, United States | 40.7667 | -73.5667 | settlement |
| `PL-8318` | Norway | 62 | 10 | region |
| `PL-8467` | Buckinghamshire, England | 51.76274 | -0.65918 | settlement |
| `PL-8468` | Wilmington, Delaware, British Colonial America | 39.7458 | -75.5469 | settlement |
| `PL-8545` | Shoreditch, Middlesex, England | 51.5333 | -0.0833 | settlement |
| `PL-8623` | Pee Dee, Montgomery, North Carolina, United States | 35.2675 | -80.0433 | settlement |
| `PL-8936` | Grubbs Landing, New Castle, Delaware, British Colonial America | 39.7861 | -75.4694 | settlement |
| `PL-8937` | Brandywine MM, New Castle, Delaware, British Colonial America | 39.783329 | -75.5 | settlement |
| `PL-9098` | Christiana, Delaware, British Colonial America | 39.665 | -75.6603 | settlement |
| `PL-9180` | Williamsburg, New Castle, Delaware, United States | 39.5853 | -75.6847 | settlement |
| `PL-9427` | Bethel Township, Chester, Pennsylvania, British Colonial America | 39.8487 | -75.4856 | township |
| `PL-9511` | Naaman, New Castle, Delaware, British Colonial America | 39.8119 | -75.4442 | settlement |
| `PL-9596` | Shoreditch, Hackney, London, England, United Kingdom | 51.533332 | -0.083333 | settlement |
| `PL-9597` | Thornbury Township, Chester, Pennsylvania, British Colonial America | 39.9269 | -75.4989 | township |
| `PL-9684` | Sedgley, Staffordshire, England, United Kingdom | 52.541 | -2.1221 | settlement |
| `PL-9772` | Newark, Delaware, British Colonial America | 39.6836 | -75.75 | settlement |
| `PL-9949` | Long Crendon, Buckinghamshire, England | 51.7737 | -1.0021 | settlement |
| `PL-10039` | Warborough, Oxfordshire, England | 51.6387 | -1.1366 | settlement |
| `PL-10040` | Uxbridge, Hillingdon, London, England, United Kingdom | 51.5489 | -0.48 | settlement |
| `PL-10132` | Towersey, Buckinghamshire, England | 51.7399 | -0.9344 | settlement |
| `PL-10593` | New Castle, New Hampshire, British Colonial America | 43.06306 | -70.71528 | settlement |
| `PL-10687` | Newbury, Essex, Massachusetts, United States | 42.77917 | -70.88333 | settlement |
| `PL-10688` | Massachusetts, United States | 42.25 | -71.5 | settlement |
| `PL-10784` | Haverhill, Essex, Massachusetts, United States | 42.776 | -71.078 | settlement |
| `PL-10881` | Delaware, United States | 39 | -75.5 | settlement |
| `PL-10979` | Middleton, Warwickshire, England, United Kingdom | 52.5834 | -1.7398 | settlement |
| `PL-11078` | Norwich, New London, Connecticut Colony, British Colonial America | 41.55028 | -72.08806 | settlement |
| `PL-11079` | Mansfield, Tolland, Connecticut, United States | 41.80145 | -72.24253 | settlement |
| `PL-11180` | Mansfield, Windham, Connecticut, United States | 41.78833 | -72.22944 | settlement |
| `PL-11282` | Coventry, Windham, Connecticut Colony, British Colonial America | 41.784399 | -72.339399 | settlement |
| `PL-11691` | Andover, Essex, Massachusetts Bay Colony, British Colonial America | 42.6567 | -71.141 | settlement |
| `PL-11898` | Maryland, United States | 39 | -76.7 | settlement |
| `PL-11899` | Worcester, Maryland, United States | 38.2 | -75.38333 | settlement |
| `PL-12110` | Bridgewater, Plymouth, Massachusetts Bay Colony, British Colonial America | 41.96667 | -70.966669 | settlement |
| `PL-12323` | Malden, Middlesex, Massachusetts Bay Colony, British Colonial America | 42.4258 | -71.0657 | settlement |
| `PL-12431` | Rowley, Essex, Massachusetts, United States | 42.71807 | -70.878 | settlement |
| `PL-12540` | Stonington, New London, Connecticut Colony, British Colonial America | 41.336 | -71.9054 | settlement |
| `PL-12541` | Windham, Connecticut Colony, British Colonial America | 41.829999 | -72 | settlement |
| `PL-12652` | Amesbury, Essex, Massachusetts Bay Colony, British Colonial America | 42.85 | -70.95 | settlement |
| `PL-12764` | Newburyport, Essex, Massachusetts Bay Colony, British Colonial America | 42.799998 | -70.88333 | settlement |
| `PL-13213` | Newbury, Massachusetts Bay Colony, British Colonial America | 42.77917 | -70.88333 | settlement |
| `PL-13214` | Haverhill, Essex, Massachusetts Bay Colony, British Colonial America | 42.776 | -71.078 | settlement |
| `PL-13557` | Amesbury, Essex, Massachusetts, United States | 42.85 | -70.95 | settlement |
| `PL-13788` | Dorchester, Maryland, United States | 38.46667 | -76 | settlement |
| `PL-13905` | Nottinghamshire, England, United Kingdom | 53.11546 | -1.02722 | settlement |
| `PL-14023` | Buxted, Sussex, England, United Kingdom | 50.9903 | 0.1332 | settlement |
| `PL-14378` | Saybrook, New London, Connecticut Colony, British Colonial America | 41.2959 | -72.3786 | settlement |
| `PL-14617` | Barnstable, Barnstable, Plymouth Colony, British Colonial America | 41.70202 | -70.30558 | settlement |
| `PL-14618` | Mansfield Four Corners, Mansfield, Tolland, Connecticut, United States | 41.8272 | -72.2667 | settlement |
| `PL-14982` | Concord, Middlesex, Massachusetts Bay Colony, British Colonial America | 42.46667 | -71.36667 | settlement |
| `PL-15105` | Stonington, New London, Connecticut, United States | 41.3364 | -71.9066 | settlement |
| `PL-15967` | L'Ange-Gardien, Québec, Canada, New France | 46.9159 | -71.0936 | settlement |
| `PL-16092` | Île d'Orléans, Montmorency No. 2, Canada East, British North America | 46.9322 | -70.9293 | settlement |
| `PL-16218` | Chateau Richer, Montmorency No. 1, Quebec, Canada | 46.9697 | -71.0178 | settlement |
| `PL-16219` | Montmorency No. 2, Quebec, Canada | 46.9167 | -70.9667 | settlement |
| `PL-16347` | Sainte-Famille, Saint-Laurent, Québec, Canada, New France | 46.9731 | -70.9631 | settlement |
| `PL-16476` | Saint-Jean-Baptiste, Saint-Laurent, Québec, Canada, New France | 46.9204 | -70.89 | settlement |
| `PL-17122` | Saint-Paul-de-l'Arbre-Sec, Saint-Laurent, Québec, Canada, New France | 46.8604 | -71.0052 | settlement |
| `PL-17123` | Saint-Laurent, Île d'Orléans, Quebec, British North America | 46.8664 | -71.0116 | settlement |
| `PL-17386` | Layrac, Lot-et-Garonne, France | 44.1363 | 0.6594 | settlement |
| `PL-17519` | Chateau Richer, Québec, Canada, New France | 46.9701 | -71.018 | settlement |
| `PL-17653` | L'Ange-Gardien, Montmorency No. 1, Quebec, Canada | 46.9173 | -71.0899 | settlement |
| `PL-17922` | Savignies, Oise, France | 49.4658 | 1.9648 | settlement |
| `PL-18328` | Cap-Tourmente, Québec, Canada, New France | 47.0662 | -70.8098 | settlement |
| `PL-18465` | Saint-Cosme-en-Vairais, Sarthe, France | 48.2739 | 0.46 | settlement |
| `PL-18603` | Sainte-Anne-de-Beaupré, Québec, Canada, New France | 47.0167 | -70.9462 | settlement |
| `PL-18742` | Maulais, Poitou, France | 46.9319 | -0.1665 | settlement |
| `PL-18882` | Saint-Sauveur, Paris, France | 48.86889 | 2.35194 | settlement |
| `PL-19023` | Sainte-Famille, L'Île-d'Orléans, Quebec, Canada | 46.9731 | -70.9631 | settlement |
| `PL-19024` | Saint-Laurent-de-l'Île-d'Orléans, L'Île-d'Orléans, Quebec, Canada | 46.8664 | -71.0116 | settlement |
| `PL-19593` | Quebec City, Quebec, Canada East, British North America | 46.8141 | -71.2068 | settlement |
| `PL-19737` | Québec, Canada, New France | 46.8135 | -71.2074 | settlement |
| `PL-19882` | Chateau Richer, La Côte-de-Beaupré, Quebec, Canada | 46.9697 | -71.0178 | settlement |
| `PL-20173` | Ocqueville, Normandy, France | 49.8012 | 0.6902 | settlement |
| `PL-20612` | Notre-Dame de Québec, Quebec City, Québec, Canada, New France | 46.8138 | -71.2061 | settlement |
| `PL-20907` | Gascony, France | 43.977 | -0.176 | settlement |
| `PL-21056` | Beaumais, Normandy, France | 49.8549 | 1.1208 | settlement |
| `PL-21206` | Quebec City, Québec, Canada, New France | 46.8141 | -71.2068 | settlement |
| `PL-21357` | Coulonges, Angoumois, France | 45.8334 | 0.0917 | settlement |
| `PL-21509` | Normandel, Perche, France | 48.6469 | 0.7144 | settlement |
| `PL-21662` | Saint-Aubin, Tourouvre, Orne, France | 48.5906 | 0.6518 | settlement |
| `PL-21969` | Oise, France | 49.5 | 2.5 | settlement |
| `PL-21970` | Savigny, Saône-et-Loire, France | 46.86757 | 4.153691 | settlement |
| `PL-22281` | France | 46 | 2 | region |
| `PL-22282` | Deschambault, Québec, Canada, New France | 46.648 | -71.9311 | settlement |
| `PL-23068` | Notre-Dame-de-Bon-Secours, Québec, Canada, New France | 47.1267 | -70.3734 | settlement |
| `PL-23227` | Deerfield, Hampshire, Massachusetts Bay Colony, British Colonial America | 42.533329 | -72.616669 | settlement |
| `PL-23387` | Westfield, Hampshire, Massachusetts Bay Colony, British Colonial America | 42.12588 | -72.75 | settlement |
| `PL-24028` | Hartford, Hartford, Connecticut Colony, British Colonial America | 41.7658 | -72.6839 | settlement |
| `PL-24351` | Windsor, Connecticut Colony, British Colonial America | 41.85352 | -72.64641 | settlement |
| `PL-25000` | Simsbury, Hartford, Connecticut Colony, British Colonial America | 41.8706 | -72.8258 | settlement |
| `PL-25164` | Billerica, Middlesex, Massachusetts Bay Colony, British Colonial America | 42.55895 | -71.26898 | settlement |
| `PL-25165` | Colchester, New London, Connecticut, United States | 41.5744 | -72.3328 | settlement |
| `PL-25331` | New London, Connecticut Colony, British Colonial America | 41.48333 | -72.06667 | settlement |
| `PL-25830` | Wethersfield, Hartford, Connecticut Colony, British Colonial America | 41.70111 | -72.67 | settlement |
| `PL-25998` | Hartford, Connecticut Colony, British Colonial America | 41.81 | -72.73 | settlement |
| `PL-25999` | Rhode Island, British Colonial America | 41.7 | -71.5 | settlement |
| `PL-26169` | Boston, Massachusetts Bay Colony, British Colonial America | 42.36046 | -71.05912 | settlement |
| `PL-26170` | Hadley, Hampshire, Massachusetts Bay Colony, British Colonial America | 42.34383 | -72.58795 | settlement |
| `PL-26513` | Taunton, Somerset, England | 51.0158 | -3.1073 | settlement |
| `PL-26514` | Northampton, Hampshire, Massachusetts Bay Colony, British Colonial America | 42.32558 | -72.64143 | settlement |
| `PL-26688` | Bridport, Dorset, England | 50.7334 | -2.7567 | settlement |
| `PL-26863` | Kenilworth, Warwickshire, England | 52.35 | -1.5811 | settlement |
| `PL-27039` | Dorchester, Suffolk, Massachusetts Bay Colony, British Colonial America | 42.3028 | -71.06796 | settlement |
| `PL-27216` | London, England | 51.5087 | -0.1289 | settlement |
| `PL-27571` | Connecticut Panhandle, New York Colony, British Colonial America | 41.116998 | -73.498998 | settlement |
| `PL-28284` | Wales | 52.33022 | -3.76641 | region |
| `PL-28285` | Colchester, Hartford, Connecticut Colony, British Colonial America | 41.5744 | -72.3328 | settlement |
| `PL-28466` | Ashfield, Franklin, Massachusetts, United States | 42.5272 | -72.7894 | settlement |
| `PL-28467` | Salem, Essex, Massachusetts, United States | 42.512 | -70.908 | settlement |
| `PL-28650` | Rowley, Massachusetts Bay Colony, British Colonial America | 42.71807 | -70.878 | settlement |
| `PL-29017` | Tarvin, Cheshire, England | 53.1957 | -2.7628 | settlement |
| `PL-29018` | Suffield, Hartford, Connecticut Colony, British Colonial America | 41.98333 | -72.69167 | settlement |
| `PL-29204` | Marshwood, Dorset, England | 50.7929 | -2.8856 | settlement |
| `PL-29949` | New Haven, Connecticut Colony, British Colonial America | 41.35 | -72.9 | settlement |
| `PL-30324` | Saint-Joseph, Deschambault, Québec, Canada, New France | 46.64792 | -71.92771 | settlement |
| `PL-30701` | Île-d'Orléans, Canada, New France | 46.913 | -70.9667 | settlement |
| `PL-32214` | Saint-Jean-Baptiste, District Judiciaire de Québec, Quebec, British North America | 46.9203 | -70.89 | settlement |
| `PL-33735` | Charlesbourg, Québec, Canada, New France | 46.861 | -71.2703 | settlement |
| `PL-34500` | Île d'Orléans, Québec, Canada, New France | 46.9322 | -70.9293 | settlement |
| `PL-34693` | La Rochelle, Aunis, France | 46.1603 | -1.1507 | settlement |
| `PL-34887` | Notre-Dame-de-Cougnes, La Rochelle, Aunis, France | 46.1638 | -1.1461 | settlement |
| `PL-35082` | Isle Dieu, Poitou, France | 46.7098 | -2.3479 | settlement |
| `PL-35473` | Charente, France | 45.667 | 0.0833 | settlement |
| `PL-35670` | Saint-Benoît, Seine-et-Oise, France | 48.67528 | 1.911611 | settlement |
| `PL-35868` | Maillezais, Vendée, France | 46.3714 | -0.7391 | settlement |
| `PL-36067` | Rennes, Brittany, France | 48.1667 | -1.6667 | settlement |
| `PL-36267` | Laleu, Aunis, France | 46.1685 | -1.1992 | settlement |
| `PL-36668` | Saint-Germain-de-Prinçay, Vendée, France | 46.7212 | -1.0215 | settlement |
| `PL-36870` | Paris, France | 48.8667 | 2.3333 | settlement |
| `PL-37073` | Estouteville-Écalles, Seine-Maritime, France | 49.5898 | 1.3138 | settlement |
| `PL-37480` | Normandy, France | 49.06 | -0.11 | settlement |
| `PL-37889` | Le Havre, Normandy, France | 49.4943 | 0.1085 | settlement |
| `PL-38095` | Angoumois, France | 45.8 | 0.2 | settlement |
| `PL-38302` | Étusson, Deux-Sèvres, France | 47.01464 | -0.51429 | settlement |
| `PL-38717` | Monsummano, Lucca, Tuscany, Italy | 43.8722 | 10.8157 | settlement |
| `PL-42254` | At Sea | 30 | -40 | region |
| `PL-42464` | Norwalk, Fairfield, Connecticut Colony, British Colonial America | 41.120848 | -73.423349 | settlement |
| `PL-42465` | Family, Glacier, Montana, United States | 48.4819 | -112.7436 | settlement |
| `PL-42677` | Lancaster, Middlesex, Massachusetts Bay Colony, British Colonial America | 42.45704 | -71.67285 | settlement |
| `PL-42678` | Princeton, Somerset, New Jersey, British Colonial America | 40.3503 | -74.6594 | settlement |
| `PL-42892` | Colonels Island, Suffolk, New York Colony, British Colonial America | 40.91722 | -72.635829 | settlement |
| `PL-42893` | Stony Brook, Mercer, New Jersey, United States | 40.3167 | -74.6667 | settlement |
| `PL-43109` | Stanway Hall, Essex, England | 51.88333 | 0.81666 | settlement |
| `PL-43326` | Scituate, Plymouth Colony, British Colonial America | 42.21667 | -70.78333 | settlement |
| `PL-43544` | Poitiers, Vienne, France | 46.57427 | 0.3119 | settlement |
| `PL-43763` | Hertfordshire, England | 51.83747 | -0.18951 | settlement |
| `PL-43983` | County Tipperary, Ireland | 52.6 | -7.915 | county |
| `PL-43984` | Woodbridge Township, Middlesex, New Jersey, British Colonial America | 40.5667 | -74.2917 | township |
| `PL-44427` | North Wingfield, Derbyshire, England | 53.1833 | -1.3889 | settlement |
| `PL-44428` | Springfield, Burlington, New Jersey, British Colonial America | 40.0367 | -74.694 | settlement |
| `PL-44652` | Morton, Derbyshire, England | 53.1382 | -1.3888 | settlement |
| `PL-44653` | Mansfield Township, Burlington, New Jersey, British Colonial America | 39.8833 | -74.6418 | township |
| `PL-44879` | Norfolk, England | 52.678269 | 0.972589 | settlement |
| `PL-44880` | Burlington, Burlington, New Jersey, British Colonial America | 40.07833 | -74.85278 | settlement |
| `PL-45108` | Little Dunmow, Essex, England, United Kingdom | 51.8692 | 0.3657 | settlement |
| `PL-45109` | Burlington, Burlington, New Jersey, United States | 40.0783 | -74.8528 | settlement |
| `PL-45339` | Brampton, Suffolk, England | 52.383 | 1.5803 | settlement |
| `PL-45570` | England, United Kingdom | 52.4379 | -1.6496 | settlement |
| `PL-46495` | Mareuil-le-Port, Marne, France | 49.082 | 3.7453 | settlement |
| `PL-46728` | Burntisland, Fife, Scotland | 56.0583 | -3.2328 | settlement |
| `PL-46729` | Prince George, British Columbia, British North America | 53.9167 | -122.7667 | settlement |
| `PL-46964` | Harberton, Devon, England, United Kingdom | 50.4158 | -3.7231 | settlement |
| `PL-47200` | Visnum, Värmland, Sweden | 59.133333 | 14.166666 | settlement |
| `PL-47437` | Liden, Västernorrland, Sweden | 62.7 | 16.8 | settlement |
| `PL-47438` | Backen, Liden, Västernorrland, Sweden | 62.683333 | 16.816666 | settlement |
| `PL-47677` | Finland | 64 | 26.5 | region |
| `PL-48395` | Conistone, Yorkshire, England | 54.0994 | -2.0275 | settlement |
| `PL-48396` | Buckingham, Buckinghamshire, England | 52 | -0.9878 | settlement |
| `PL-48879` | Shillingford, Oxfordshire, England | 51.61667 | -1.13333 | settlement |
| `PL-49848` | West Boldon, Durham, England | 54.9434 | -1.4501 | settlement |
| `PL-50335` | Bernshammar, Hed, Västmanland, Sweden | 59.666666 | 15.75 | settlement |
| `PL-51068` | Fryksdal, Värmland, Sweden | 59.7287 | 13.2156 | settlement |
| `PL-51069` | Christiana, New Castle, Delaware, United States | 39.665 | -75.6603 | settlement |
| `PL-51808` | Pennsylvania, British Colonial America | 40.296 | -75.509 | settlement |
| `PL-51809` | Gloucester, New Jersey, United States | 39.73333 | -75.13333 | settlement |
| `PL-52058` | Beccles, Suffolk, England, United Kingdom | 52.4596 | 1.5657 | settlement |
| `PL-52557` | Stoke Climsland, Cornwall, England | 50.548 | -4.3158 | settlement |
| `PL-52808` | Chester, Pennsylvania, United States | 39.988 | -75.718 | settlement |
| `PL-53060` | Länna, Uppsala, Sweden | 59.8737 | 17.9611 | settlement |
| `PL-53313` | New Amsterdam, New Netherland | 40.714 | -74 | settlement |
| `PL-53314` | New York County, New York Colony, British Colonial America | 40.78333 | -73.96667 | county |
| `PL-53569` | Klara, Stockholm, Sweden | 59.331 | 18.0617 | settlement |
| `PL-54590` | New Sweden, Sweden | 39.7 | -75.667 | settlement |
| `PL-55103` | Merionethshire, Wales | 52.747064 | -3.877533 | settlement |
| `PL-55361` | Wales, United Kingdom | 52.33022 | -3.76641 | settlement |
| `PL-55620` | Avebury, Wiltshire, England | 51.41667 | -1.86667 | settlement |
| `PL-55880` | Bradford Hills, West Whiteland Township, Chester, Pennsylvania, United States | 40.0031 | -75.6483 | settlement |
| `PL-56141` | Staffordshire, England, United Kingdom | 52.77951 | -1.91711 | settlement |
| `PL-56142` | Birmingham Township, Chester, Pennsylvania, British Colonial America | 39.9083 | -75.6156 | township |
| `PL-56405` | Sedgley, Staffordshire, England | 52.540435 | -2.123044 | settlement |
| `PL-56669` | Netherlands | 52.5 | 5.75 | region |
| `PL-56934` | Oldenburg, Lower Saxony, Germany | 53.1389 | 8.2137 | settlement |
| `PL-57200` | Ireland | 53 | -8 | region |
| `PL-58797` | Covington, Huntingdonshire, England | 52.324 | -0.4508 | settlement |
| `PL-59065` | St Andrew's Church, Holborn, Middlesex, England | 51.517009 | -0.106836 | settlement |
| `PL-59334` | Great Yarmouth, Norfolk, England, United Kingdom | 52.5979 | 1.7303 | settlement |
| `PL-59604` | Great Berkhampstead, Hertfordshire, England | 51.775011 | -0.564327 | settlement |
| `PL-59875` | Blyth, Nottinghamshire, England, United Kingdom | 53.3771 | -1.0618 | settlement |
| `PL-60418` | Braintree, Massachusetts Bay Colony, British Colonial America | 42.20928 | -71.00637 | settlement |
| `PL-60419` | Bridgewater, Plymouth Colony, British Colonial America | 41.9667 | -70.9667 | settlement |
| `PL-60693` | Duxbury, Plymouth Colony, British Colonial America | 42.03333 | -70.71667 | settlement |
| `PL-60968` | Bristol, England | 51.4551 | -2.5882 | settlement |
| `PL-61519` | Horsham, Sussex, England | 51.0628 | -0.3264 | settlement |
| `PL-61520` | Norwalk, Connecticut Colony, British Colonial America | 41.120848 | -73.423349 | settlement |
| `PL-61798` | Great Bentley, Essex, England | 51.8574 | 1.0619 | settlement |
| `PL-62077` | White Colne, Essex, England | 51.9282 | 0.7224 | settlement |
| `PL-62357` | Cranbrook, Kent, England | 51.0968 | 0.5376 | settlement |
| `PL-62638` | Charlestown, Massachusetts Bay Colony, British Colonial America | 42.37778 | -71.0625 | settlement |
| `PL-62920` | Yarmouth, Barnstable, Massachusetts Bay Colony, British Colonial America | 41.704169 | -70.230558 | settlement |
| `PL-63203` | Scituate, Plymouth, Massachusetts Bay Colony, British Colonial America | 42.21667 | -70.78333 | settlement |
| `PL-63204` | Barnstable, Barnstable, Massachusetts Bay Colony, British Colonial America | 41.683329 | -70.366669 | settlement |
| `PL-63773` | Market Harborough, Leicestershire, England | 52.4767 | -0.9215 | settlement |
| `PL-64059` | Kildwick, Yorkshire, England | 53.9116 | -1.9891 | settlement |
| `PL-64632` | Sudbury, Middlesex, Massachusetts Bay Colony, British Colonial America | 42.38333 | -71.416669 | settlement |
| `PL-65494` | Boston, Suffolk, Massachusetts Bay Colony, British Colonial America | 42.36046 | -71.05912 | settlement |
| `PL-65783` | Roxbury, Massachusetts Bay Colony, British Colonial America | 42.325 | -71.09583 | settlement |
| `PL-66362` | Kingsthorpe, Northamptonshire, England | 52.2613 | -0.9047 | settlement |
| `PL-66653` | Glapwell, Derbyshire, England | 53.18971 | -1.28386 | settlement |
| `PL-66945` | Downham, Cambridgeshire, England | 52.43333 | 0.25 | settlement |
| `PL-67238` | Ely, Cambridgeshire, England | 52.3995 | 0.2625 | settlement |
| `PL-67532` | Somerset, England | 51.11974 | -2.899999 | settlement |
| `PL-67827` | Chard, Somerset, England | 50.8715 | -2.9642 | settlement |
| `PL-68123` | Dorset, England | 50.765999 | -2.14508 | settlement |
| `PL-68716` | Killingworth, New London, Connecticut Colony, British Colonial America | 41.3581 | -72.5649 | settlement |
| `PL-69608` | Devon, England, United Kingdom | 50.73646 | -3.718869 | settlement |
| `PL-69907` | Bermondsey, Surrey, England | 51.4927 | -0.0666 | settlement |
| `PL-70506` | Keynsham, Somerset, England | 51.4158 | -2.5032 | settlement |
| `PL-70807` | Crewkerne, Somerset, England | 50.8841 | -2.7961 | settlement |
| `PL-71109` | Somerset, England, United Kingdom | 51.11974 | -2.899999 | settlement |
| `PL-72016` | Staffordshire, England | 52.77951 | -1.91711 | settlement |
| `PL-72320` | Devon, England | 50.73646 | -3.718869 | settlement |
| `PL-72321` | Westfield, Massachusetts Bay Colony, British Colonial America | 42.12588 | -72.75 | settlement |
| `PL-73542` | Grantham, Lincolnshire, England, United Kingdom | 52.9119 | -0.6426 | settlement |
| `PL-73543` | Andover, Essex, Massachusetts, United States | 42.6567 | -71.141 | settlement |
| `PL-73851` | Shipton, Gloucestershire, England | 51.85 | -1.933333 | settlement |
| `PL-74160` | Wantage, Berkshire, England | 51.5891 | -1.4265 | settlement |
| `PL-74470` | Toddington, Bedfordshire, England | 51.9486 | -0.5326 | settlement |
| `PL-74781` | Rattlesden, Suffolk, England | 52.1934 | 0.8942 | settlement |
| `PL-74782` | Bradford, Essex, Massachusetts Bay Colony, British Colonial America | 42.76944 | -71.07639 | settlement |
| `PL-75095` | Burton upon Trent, Staffordshire, England | 52.8146 | -1.6365 | settlement |
| `PL-75409` | Bedworth, Warwickshire, England | 52.4815 | -1.4691 | settlement |
| `PL-75724` | Axminster, Devon, England | 50.783332 | -2.983333 | settlement |
| `PL-75725` | Dorchester, Massachusetts Bay Colony, British Colonial America | 42.3028 | -71.06796 | settlement |
| `PL-76042` | Yarcombe, Devon, England | 50.8791 | -3.0763 | settlement |
| `PL-76043` | Dorset, England, United Kingdom | 50.765999 | -2.14508 | settlement |
| `PL-76680` | Pitminster, Somerset, England | 50.9671 | -3.1141 | settlement |
| `PL-77000` | Coggeshall, Essex, England | 51.8713 | 0.6924 | settlement |
| `PL-77961` | Barnstaple, Devon, England | 51.0784 | -4.0593 | settlement |
| `PL-78283` | Ringstead, Northamptonshire, England | 52.3626 | -0.5507 | settlement |
| `PL-78284` | Newhaven Towne, New Haven, Connecticut Colony, British Colonial America | 41.31 | -72.9242 | settlement |
| `PL-79577` | Clermont-Créans, Maine, France | 47.7172 | -0.0159 | settlement |
| `PL-80226` | Saint-Pierre-des-Échaubrognes, Deux-Sèvres, France | 46.98987 | -0.74336 | settlement |
| `PL-81527` | Nalliers, Vendée, France | 46.4709 | -1.0255 | settlement |
| `PL-81528` | Hôtel-Dieu, Quebec City, Québec, Canada, New France | 46.8152 | -71.2106 | settlement |
| `PL-81856` | La Ventrouze, Orne, France | 48.6106 | 0.6962 | settlement |
| `PL-82185` | Vannes, Morbihan, France | 47.6574 | -2.7597 | settlement |
| `PL-82186` | Quebec City, Quebec, Canada | 46.8141 | -71.2068 | settlement |
| `PL-82517` | Notre-Dame-du-Rocher, Orne, France | 48.7958 | -0.4053 | settlement |
| `PL-82849` | Dieppe, Normandy, France | 49.922 | 1.0816 | settlement |
| `PL-83182` | Dieppe, Seine-Maritime, France | 49.922 | 1.0816 | settlement |
| `PL-83516` | Berneval-le-Grand, Seine-Maritime, France | 49.9551 | 1.1877 | settlement |
| `PL-84185` | Bordeaux, Gironde, France | 44.8373 | -0.576 | settlement |
| `PL-84186` | Sainte-Famille, Québec, Canada, New France | 46.9738 | -70.9621 | settlement |
| `PL-84859` | Tourouvre, Orne, France | 48.5911 | 0.6522 | settlement |
| `PL-85197` | La Rochelle, Charente-Maritime, France | 46.1603 | -1.1507 | settlement |
| `PL-85536` | Saint-Rémy, Dieppe, Normandy, France | 49.925 | 1.07361 | settlement |
| `PL-85876` | Saint-Vaast-d'Équiqueville, Seine-Maritime, France | 49.81813 | 1.26364 | settlement |
| `PL-86217` | Sainte-Soule, Aunis, France | 46.1857 | -1.0094 | settlement |
| `PL-86900` | Combray, Calvados, France | 48.9505 | -0.439 | settlement |
| `PL-87243` | Nancy, Meurthe-et-Moselle, France | 48.6908 | 6.1825 | settlement |
| `PL-87244` | Saint-François, Saint-Laurent, Québec, Canada, New France | 47.0021 | -70.8126 | settlement |
| `PL-88965` | Fontenay-le-Comte, Vendée, France | 46.4658 | -0.8051 | settlement |
| `PL-89656` | L'Ile-d'Yeu, Vendée, France | 46.723 | -2.3503 | settlement |
| `PL-90695` | La Rochelle, Charente-Inférieure, France | 46.1603 | -1.1507 | settlement |
| `PL-91043` | Saintonge, Charente-Maritime, France | 45.83333 | -0.5 | settlement |
| `PL-91392` | Segonzac, Charente, France | 45.618 | -0.2185 | settlement |
| `PL-92440` | Le Comte, Ardèche, France | 45.074213 | 4.488274 | settlement |
| `PL-93141` | Rennes, Ille-et-Vilaine, France | 48.108 | -1.6767 | settlement |
| `PL-93844` | Laleu, La Rochelle, Charente-Maritime, France | 46.1685 | -1.1992 | settlement |
| `PL-93845` | Saint-Pierre-d'Oléron, Aunis, France | 45.9437 | -1.3055 | settlement |
| `PL-94552` | Mortagne-au-Perche, Perche, France | 48.5214 | 0.547 | settlement |
| `PL-94907` | Courgeoût, Orne, France | 48.5081 | 0.4881 | settlement |
| `PL-95263` | Luçon, Vendée, France | 46.4547 | -1.1664 | settlement |
| `PL-95620` | Luçon, Poitou, France | 46.4547 | -1.167 | settlement |
| `PL-96335` | Champs-Sur-Marne, Seine-et-Marne, France | 48.856 | 2.5904 | settlement |
| `PL-96694` | Goes, Zeeland, Netherlands | 51.503996 | 3.890645 | settlement |
| `PL-97054` | Saint-Laurent, Cher, France | 47.2247 | 2.2019 | settlement |
| `PL-98135` | Arrondissement d'Angoulême, Charente, France | 45.667 | 0.0833 | settlement |
| `PL-98136` | Angoulême, Charente, France | 45.649 | 0.1577 | settlement |
| `PL-98861` | Charencey, Perche, France | 48.6268 | 0.7371 | settlement |
| `PL-99225` | La Poterie-au-Perche, Perche, France | 48.6271 | 0.7204 | settlement |
| `PL-99590` | Saint-Aubin, Tourouvre, Perche, France | 48.5906 | 0.6518 | settlement |
| `PL-100321` | Vienne, France | 46.4654 | 0.4926 | settlement |
| `PL-100688` | Lubersac, Brive-la-Gaillarde, Corrèze, France | 45.45279 | 1.388569 | settlement |
| `PL-101790` | Diocese of Lisieux, France | 49.0664 | 0.1786 | settlement |
| `PL-102159` | Cap-Saint-Ignace, Québec, Canada, New France | 47.0355 | -70.4584 | settlement |
| `PL-102898` | Niort, Poitou, France | 46.328 | -0.4474 | settlement |
| `PL-103269` | Perche, France | 46.6351 | 2.5756 | settlement |
| `PL-103641` | Saint-Vincent-Cramesnil, Seine-Maritime, France | 49.505 | 0.3628 | settlement |
| `PL-104386` | Bréval, Yvelines, France | 48.946 | 1.534 | settlement |
| `PL-104760` | Rouen, Seine-Maritime, France | 49.5 | 1 | settlement |
| `PL-105135` | Canada, New France | 47.6328 | -76.0408 | settlement |
| `PL-105886` | Saint-Martin-du-Vieux-Bellême, Orne, France | 48.382 | 0.5448 | settlement |
| `PL-106263` | Gonneville-sur-Honfleur, Calvados, France | 49.3844 | 0.245 | settlement |
| `PL-106641` | Honfleur, Normandy, France | 49.4195 | 0.2326 | settlement |
| `PL-107020` | Saint-Pierre-des-Ormes, Sarthe, France | 48.3067 | 0.4216 | settlement |
| `PL-108537` | Salles, Angoumois, France | 45.9585 | 0.1634 | settlement |
| `PL-108538` | Marseille-en-Beauvaisis, Oise, France | 49.5747 | 1.9558 | settlement |
| `PL-110444` | Joinville, Haute-Marne, France | 48.4425 | 5.1403 | settlement |
| `PL-113501` | Montecatini di Val Di Nievole, Lucca, Tuscany | 43.8967 | 10.7929 | settlement |
| `PL-114268` | Valence, Charente, France | 45.8892 | 0.308 | settlement |
| `PL-115037` | Sarthe, France | 48 | 0.0833 | settlement |
| `PL-115038` | Maine-de-Boixe, Charente, France | 45.8493 | 0.1752 | settlement |
| `PL-115425` | Mirebeau, Vienne, France | 46.7855 | 0.1819 | settlement |
| `PL-116200` | Le Mans, Sarthe, France | 47.9953 | 0.203 | settlement |
| `PL-117365` | Flaçà, Girona, Catalonia, Spain | 42.0469 | 2.9581 | settlement |
| `PL-117366` | Cesson-Sévigné, Ille-et-Vilaine, France | 48.1211 | -1.6026 | settlement |
| `PL-117757` | Anjou, France | 45.3459 | 4.8813 | settlement |
| `PL-118540` | Spain | 40.43 | -4 | region |
| `PL-120893` | Vannes, Brittany, France | 47.6574 | -2.7597 | settlement |
| `PL-121680` | Villaines-les-Rochers, Indre-et-Loire, France | 47.2219 | 0.4978 | settlement |
| `PL-122075` | Île-de-France, France | 48.87471 | 2.5002 | settlement |
| `PL-122471` | La Rochelle-Normande, Manche, France | 48.7645 | -1.4339 | settlement |
| `PL-124848` | La Ventrouze, Normandy, France | 48.6106 | 0.6962 | settlement |
| `PL-125246` | Tourouvre, Perche, France | 48.5911 | 0.6522 | settlement |
| `PL-128033` | Château-Landon, Seine-et-Marne, France | 48.15 | 2.6983 | settlement |
| `PL-128433` | Gâtinais, France | 48.122 | 2.591 | settlement |
| `PL-129634` | Taizé, Deux-Sèvres, France | 46.3147 | 0.0373 | settlement |
| `PL-130036` | Deux-Sèvres, France | 46.5 | -0.25 | settlement |
| `PL-130439` | Archdiocese of Poitiers, France | 46.58468 | 0.33644 | settlement |
| `PL-130440` | Maulais, Deux-Sèvres, France | 46.9319 | -0.1665 | settlement |
| `PL-131249` | Batilly-en-Gâtinais, Loiret, France | 48.074 | 2.3805 | settlement |
| `PL-132060` | Poitou, Charente-Maritime, France | 46.66666 | -0.5 | settlement |
| `PL-132467` | Saint-Hilaire, Deux-Sèvres, France | 46.21997 | -0.150574 | settlement |
| `PL-132468` | Poitou-Charentes, France | 46.083 | 0.167 | settlement |
| `PL-135325` | King's Castle, St. Anne's Shandon, County Cork, Ireland | 51.9 | -8.46666 | settlement |
| `PL-135735` | Moirans, Isère, France | 45.3269 | 5.5645 | settlement |
| `PL-137376` | Menen, West Flanders, Belgium | 50.7942 | 3.1223 | settlement |
| `PL-137377` | Pittem, West Flanders, Belgium | 50.995 | 3.2676 | settlement |
| `PL-140262` | Champagne, France | 48.764 | 1.56 | settlement |
| `PL-141089` | Saint-Nicolas-des-Champs, Paris, France | 48.8656 | 2.3537 | settlement |
| `PL-142746` | West Flanders, Belgium | 51 | 3 | settlement |
| `PL-143162` | Les Roches, Brantôme en Périgord, Dordogne, France | 45.36439 | 0.68121 | settlement |
| `PL-143163` | Saint Pierre, Roussillon, Quebec, Canada | 45.3833 | -73.5667 | settlement |
| `PL-143581` | Hamelin, Manche, France | 48.5447 | -1.2081 | settlement |
| `PL-144000` | Parcé, Ille-et-Vilaine, France | 48.2733 | -1.2006 | settlement |
| `PL-145258` | Sainte-Gemme, Cher, France | 47.3943 | 2.8149 | settlement |
| `PL-145259` | Orne, France | 48.67 | 0.08 | settlement |
| `PL-145681` | Paris, Seine, France | 48.86667 | 2.33333 | settlement |
| `PL-146948` | Londigny, Charente, France | 46.0838 | 0.1345 | settlement |
| `PL-147372` | Marçay, Vienne, France | 46.4627 | 0.2298 | settlement |
| `PL-148221` | France Mission, France | 46.8806 | 2.5121 | settlement |
| `PL-149497` | Condé-sur-l'Escaut, Nord, France | 50.4483 | 3.5935 | settlement |
| `PL-149498` | Reims, Marne, France | 49.166666 | 4.083333 | settlement |
| `PL-150353` | Angoulême, Angoumois, France | 45.649 | 0.1577 | settlement |
| `PL-151210` | Marçay, Indre-et-Loire, France | 47.1 | 0.2178 | settlement |
| `PL-151640` | Tours-sur-Meymont, Puy-de-Dôme, France | 45.6733 | 3.5752 | settlement |
| `PL-151641` | Vivonne, Vienne, France | 46.4263 | 0.2612 | settlement |
| `PL-155090` | Villefagnan, Charente, France | 46.0135 | 0.0819 | settlement |
| `PL-157683` | Aytré, Aunis, France | 46.1324 | -1.1143 | settlement |
| `PL-159416` | Tourville-sur-Odon, Calvados, France | 49.1417 | -0.5008 | settlement |
| `PL-159417` | Acigné, Ille-et-Vilaine, France | 48.1318 | -1.5357 | settlement |
| `PL-160288` | Aunis, France | 47.2343 | -0.0415 | settlement |
| `PL-160725` | Bois, Doubs, France | 47.36472 | 6.406064 | settlement |
| `PL-160726` | Saint-Hilaire, Maine-et-Loire, France | 47.12727 | -0.549294 | settlement |
| `PL-161165` | Saint-Hilaire-du-Bois, Charente-Maritime, France | 45.4181 | -0.4944 | settlement |
| `PL-163361` | Montreuil, Seine-Saint-Denis, France | 48.858 | 2.4371 | settlement |
| `PL-163802` | Bretagne, Territoire de Belfort, France | 47.5949 | 6.9963 | settlement |
| `PL-163803` | Bretagne-de-Marsan, Landes, France | 43.8474 | -0.45979 | settlement |
| `PL-164246` | Tourouvre, Tourouvre au Perche, Orne, France | 48.591098 | 0.6522 | settlement |
| `PL-165576` | Collodi, Pescia, Florence, Tuscany | 43.89837 | 10.65498 | settlement |
| `PL-166021` | Montevettolini, Monsummano, Pistoia, Tuscany, Italy | 43.857756 | 10.843658 | settlement |

## Skipped

- `LZDK-YP8` Benjamin Reed — already linked via fs_id
- `991N-J11` Sarah Dickerson — already linked via fs_id
- `L7NJ-1S1` John Foulk Talley — already linked via fs_id
- `2MRH-9JF` Hannah Paulson — already linked via fs_id
- `LHW8-G58` William Polk Willey — already linked via fs_id
- `278F-M4D` Sarah Dye — already linked via fs_id
- `KLYD-X1Q` Benjamin Thorla — already linked via fs_id
- `2S2L-ZYQ` Elizabeth Allen — already linked via fs_id
- `LHFS-KPJ` Samuel R Barnard — already linked via fs_id
- `L5ZT-BM5` Roxana Desire Barnard — already linked via fs_id
- `KZXQ-XCP` Pierre Pouliot — already linked via fs_id
- `KCYF-LFN` Therese Denis Lapierre — already linked via fs_id
- `MJ8T-X8V` Michel Olivier Audet — already linked via fs_id
- `LHJ9-SLF` Marie Louise Tremblay — already linked via fs_id
- `P355-FRN` Pietro Dini — already linked via fs_id
- `P35T-Q4G` Elisabetta Giovacchini — already linked via fs_id
- `GRLV-XZB` Pier Domenico Spadoni — already linked via fs_id
- `GRLV-YDR` Maria Angiola Ercolini — already linked via fs_id
- `P99N-2W1` Carlo Dini — already linked via fs_id
- `P99N-599` Annunziata Grossi — already linked via fs_id
- `GBFH-79H` ANGIOLO NICCOLAI — already linked via fs_id
- `GBF4-PH4` MARIA UMILTA' PORCIANI — already linked via fs_id
- `LC5Y-HJ1` Stephen Reed — already linked via fs_id
- `LCJK-F8G` Else Alice Bonham — already linked via fs_id
- `L8J2-M2Y` Richard R. Dickerson Sr. — already linked via fs_id
- `L8J2-MLN` Sarah Brown — already linked via fs_id
- `L7NJ-XMX` Harman Talley — already linked via fs_id
- `K262-J62` Priscilla Foulk — already linked via fs_id
- `KVJJ-262` Simon Poulson lll — already linked via fs_id
- `KVJJ-2F9` Ann Patton — already linked via fs_id
- _... and 26 more_