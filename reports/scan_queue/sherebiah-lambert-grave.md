# Scan review — `sherebiah-lambert-grave`

- **scan_id:** `sherebiah-lambert-grave`
- **inbox_file:** `_drive_originals/Photographs/sherebiahlambertgrave.jpg`
- **media_type:** image (photograph) · **role:** headstone
- **status:** proposed

## Transcription (verbatim)

```
SHEREBIAH LAMBERT
DIED
May 1, 1833.
Æ 74
PAMELIA,
his wife
Died Jan. 16, 1845.
Æ. 77.
```

("Æ" = *aetatis* — age at death. So Sherebiah b. ≈ 1758–1759; Pamelia b. ≈ 1767–1768.)

## Proposed source

| field | value |
|---|---|
| source_type | `grave_marker` *(not a seeded code — see decision below)* |
| title | Grave marker — Sherebiah Lambert & wife Pamelia |
| source_date | 1845 |
| confidence | high |
| repository / url | none (family/personal photograph) |

## Proposed citations

| subject | field | claim | conf | conflict | locator |
|---|---|---|---|---|---|
| P-0105 (Sherebiah Lambert Jr) | death_date | Died 1 May 1833 | high | no | upper inscription |
| P-0105 (Sherebiah Lambert Jr) | birth_date | Æ 74 → b. c. 1758–1759 (consistent w/ recorded 11 Sep 1759) | med | no | 'Æ 74' line |

## Proposed links (extra media_link rows)

| subject | role |
|---|---|
| person P-0105 (Sherebiah Lambert Jr) | headstone |

*(The default media→source link is created automatically by `apply_scan.py`.)*

## Subject matching — how I assigned IDs

- **"SHEREBIAH LAMBERT … Æ 74" → P-0105 (Sherebiah Lambert Jr, b. 11 Sep 1759).**
  Age 74 at an 1833 death implies birth ≈ 1759 — a clean match to Jr. The other
  Sherebiah in the tree, **P-0138 (Sr, b. 28 Mar 1728)**, would have been ~105,
  so the stone is *not* his. High confidence.

## Research leads / uncertainties

1. **"Pamelia, his wife" is NOT linked — no confident match in the tree.**
   She died 16 Jan 1845 aged 77 → b. ≈ 1768. The only nearby name,
   **P-0010 "Permelia (Barnard) Lambert" (b. ≈ 1798, d. 1865)**, is a later,
   different woman (recorded as parent of Abiram Stacy Lambert P-0072). The
   marker's Pamelia appears to be missing from the tree. **Action:** create her
   (deep-dive / manual) as wife of P-0105, then add her death-date citation and
   a second `headstone` link, and re-run.

2. **Duplicate death date across both Sherebiahs (DQ flag).** Both **P-0105**
   and **P-0138** carry `death_date = "1 May 1833"` in the DB. Sr. (b. 1728)
   dying the very same day as his son at age 105 is implausible — looks like a
   copy/merge artifact worth a data-quality pass. This scan supports the 1833
   death belonging to **Jr (P-0105)**.

3. **No place asserted on the stone.** The DB lists death place
   PL-0667 = Canaan, Somerset, Maine for both; the marker itself names no
   location, so I added no place citation. (The monument is presumably in/near
   Canaan — confirm if you want a `place` link.)

4. **`source_type = grave_marker` is not in the seeded vocab.**
   `apply_scan.py` upserts unknown codes, so it will apply as-is. If you'd rather
   stay seeded, change it to `findagrave` or `other`. (I avoided `photo`/
   `death_record` since neither describes a cemetery monument well.)

## To apply

```sh
cd ~/dev/leah-rae-genealogy
# review/correct this .json, flip "status" -> "approved", then:
scripts/backup_db.sh
python3 scripts/apply_scan.py sherebiah-lambert-grave            # dry-run
python3 scripts/apply_scan.py sherebiah-lambert-grave --apply    # commit
```
