# Scan review — `2025-prayer-card-gerald-kenny`

**Status:** `proposed` → review, correct, then set `"status": "approved"` in the JSON and run
`python3 scripts/apply_scan.py 2025-prayer-card-gerald-kenny --apply`.

**File:** `_drive_orginals/Geraldprayercard.pdf` (PDF, 198,967 bytes, sha256 `6d0e9830…`)

---

## ⚠️ Action needed before this fully lands: Gerald isn't in the tree

**Gerald Arthur Kenny is not a `person` in the database.** I did not invent a person_id
or a relationship. As proposed, applying this sidecar creates the **source + media only**
(media linked to the source). Birth/death facts are captured in the transcription but are
**not** attached as `citation` rows, because a citation needs a real `subject_id`.

To capture the genealogical facts properly, the better path is:

1. **Add Gerald as a new person** (e.g. `P-####`, primary_name "Gerald Arthur Kenny",
   birth_date "3 November 1961", death_date "17 October 2025", branch likely "Paternal Kenny").
2. Add `links` / `citations` to this sidecar pointing at his new `person_id`, e.g.
   - citation: `birth_date` = "Born 3 Nov 1961" (high)
   - citation: `death_date` = "At Peace 17 Oct 2025" (high)
   - link: `person:P-#### role=portrait?` no — `document_scan`.
3. Then apply.

**Possible (UNVERIFIED) connection:** the only existing Kenny is **Edward Kenny**
(`P-0053`, b. 23 Mar 1933, d. 13 Jun 1978, Paternal Kenny). Gerald b. 1961 could plausibly
be Edward's son, but **the card says nothing about parentage** — treat this as a research
lead, not a fact, until corroborated (obituary, census, your own knowledge).

> Tell me how Gerald connects and I'll add the person + the birth/death citations and
> re-do this sidecar so it applies cleanly.

---

## Extracted content

| Field | Value |
|---|---|
| Full name | Gerald Arthur Kenny |
| Born | November 3, 1961 |
| Died ("At Peace") | October 17, 2025 |
| Funeral home | Williams-Kampp Funeral Home |
| Iconography | Celtic cross + Irish blessing → Irish Catholic |

### Verbatim transcription
```
In Loving Memory of
Gerald Arthur Kenny
Born  NOVEMBER 3, 1961
At Peace  OCTOBER 17, 2025

[Celtic cross]

May the road rise up to meet you,
May the wind be always at your back,
May the sun shine warm upon your face,
And the rain fall soft upon your fields,
And until we meet again,
May God hold you in the palm of His hand.

Williams-Kampp Funeral Home
```

## Proposed DB writes (as currently in the JSON)
- **source** (`S-####`, type `other`): "Memorial prayer card — Gerald Arthur Kenny (1961–2025)", repository Williams-Kampp Funeral Home, confidence high.
- **media** (`M-####`, type `pdf`): the scanned card, linked to the source as `document_scan`.
- **citations:** none yet (no valid person to attach to — see above).

## Notes / decisions for you
- `source_type` is `other`. Consider adding a dedicated **`prayer_card`** (or `funeral_card`) code — common genealogical artifact. `apply_scan.py` will upsert whatever code is in the JSON.
- Storage backend: with `LRGDM_MEDIA_BACKEND=blob` + `.azure.env` sourced, the original uploads to Blob (`lrgdmmedia885f01/originals`); default `local` copies it under `media/S-####/`.
