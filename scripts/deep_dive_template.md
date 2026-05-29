<!--
Deep Dive Dossier — TEMPLATE

Copy this file to reports/deep-dives/<person_id>.md and fill in the
sections. The lrgdm-deep-dive skill consumes the same structure;
apply_deep_dive.py parses the "Proposed GeoPackage patches" fenced
JSON blocks. Don't rename headings — the apply script is heading-aware.

Replace every <bracketed placeholder>. Delete (or keep empty under a
header) any section that doesn't apply, but don't reorder.
-->

---
person_id: P-XXXX
primary_name: <Full name as in GPKG>
fs_id: <L274-XXX or NULL>
dossier_date: 2026-XX-XX
deepest_ring_reached: <0..6>
researcher: lrgdm-deep-dive skill
---

# Deep Dive — <Primary name> (P-XXXX)

## 1. Person context (GPKG snapshot at dive start)

> The state of the GPKG row BEFORE this deep dive. Don't edit this
> section after Phase 1; the dossier is meant to be diffable against
> truth-at-dive-time.

- **person_id:** `P-XXXX`
- **primary_name:** <name>
- **sex:** <male | female | NULL>
- **birth_date:** <as stored, e.g. "1816-06-03" or "circa 1822" or NULL>
- **birth_place:** <place_id> · <Places.name> · (<lat>, <long>) · `<geocode_quality>`
- **death_date:** <as stored or NULL>
- **death_place:** <place_id> · <Places.name> · (<lat>, <long>) · `<geocode_quality>`
- **branch:** <e.g. "Paternal Reed" or NULL>
- **fs_id:** <L274-XXX or NULL>
- **life_confidence:** <high | med | low | NULL>
- **privacy_level:** <public | private | NULL>
- **notes:** <verbatim Notes field>
- **source_summary:** <verbatim source_summary field>

### Family graph (from Relationships + Events)

| Relation | Other person_id | Other name | Dates | Source |
|---|---|---|---|---|
| parent_of | P-XXXX | <name> | <start>-<end> | <evidence_note> |
| spouse | P-XXXX | <name> | <m. date> | <evidence_note> |

### Existing Events

| event_id | type | date_start | place_id | title |
|---|---|---|---|---|
| E-XXXX | birth | 1816-06-03 | PL-XXXX | Birth of <name> |

### Phase 1 gap list

- [ ] <e.g. "Birth place has geocode_quality=unknown — no admin_hierarchy">
- [ ] <e.g. "source_summary is single-source ('Report'); no URL anchors">
- [ ] <e.g. "No events between birth (1816) and death (1893) — missing the 1850-1880 census run">
- [ ] <e.g. "Parents not in Relationships table">

## 2. Prior shallow research

> Carry-forward from `reports/web_mentions/<person_id>.md` if it exists.
> List the findings and their URLs so this dossier supersedes them.

- <Prior finding 1 + URL + what we kept / discarded>
- <Prior finding 2 + URL + what we kept / discarded>

(If no prior web-mention file, write: `None on file before this dive.`)

## 3. Facts table

> Every fact discovered in Phase 2. Tag confidence per the runbook
> rubric. The `Conflicts with GPKG?` column is `yes` / `no` / `n/a`
> (n/a when the GPKG had no value for that fact yet).

| # | Fact | Source | URL | Confidence | Conflicts with GPKG? |
|---|---|---|---|---|---|
| 1 | <e.g. "Born 3 Jun 1816 in Smyrna, Kent County, Delaware"> | <e.g. "Delaware vital records index, entry 1816-1027"> | <https://...> | high | no |
| 2 | <fact> | <source> | <url> | med | yes (GPKG says "circa 1822", record says 1820-04-12) |

Tally:
- High-confidence facts: <N>
- Medium: <N>
- Low: <N>
- Conflicts flagged: <N>

## 4. Proposed GeoPackage patches

> Structured JSON blocks. `apply_deep_dive.py` reads every fenced block
> tagged `json deep-dive-patch`. Schema is documented in the
> [lrgdm-deep-dive SKILL](../../.claude/skills/lrgdm-deep-dive/SKILL.md).
> Do NOT propose patches for conflict rows from §3 unless the new fact
> is `high` confidence AND the GPKG value is `low`/inferred — otherwise
> leave the conflict for John.

### 4.1 Place upserts

```json deep-dive-patch
{
  "op": "upsert_place",
  "match": {"name": "<existing or new place name>"},
  "place": {
    "place_id": "PL-DD-PXXXX-001",
    "name": "<full place name, comma-separated locality, county, state>",
    "std_name": "<full, with country>",
    "lat": 0.0,
    "long": 0.0,
    "admin_hierarchy": "<USA > State > County | Country > Region > Town>",
    "geocode_quality": "<address|cemetery|ward|township|settlement|county|region|unknown>",
    "notes": "Source: <where the geocode came from>"
  },
  "source_url": "https://...",
  "confidence": "high"
}
```

(Repeat one block per place upsert. Use `PL-DD-<personid>-NNN` IDs to
avoid colliding with the GPKG's normal `PL-####` sequence — the apply
script renumbers to the next free `PL-####` at write time.)

### 4.2 New events

```json deep-dive-patch
{
  "op": "insert_event",
  "event": {
    "event_id": "E-DD-PXXXX-001",
    "title": "<short descriptive title>",
    "event_type": "<birth|death|marriage|residence|census|immigration|naturalization|burial|occupation|military|education|other>",
    "date_start": "YYYY-MM-DD",
    "date_end": null,
    "date_granularity": "<day|month|year|decade|circa>",
    "place_ref": {"name": "<must match a Place — existing or a sibling upsert_place>"},
    "confidence": "<high|med|low>",
    "description": "<1-3 sentences of substance>",
    "notes": "Source: <citation>"
  },
  "participants": [
    {"person_id": "P-XXXX", "role": "<self|spouse|head_of_household|child|witness|officiant|other>"}
  ],
  "source_url": "https://...",
  "fact_refs": [1, 2]
}
```

The `fact_refs` array points back to row numbers in §3 so the apply script
(and future re-readers) can trace each event to its sources.

### 4.3 Person updates

```json deep-dive-patch
{
  "op": "update_person",
  "person_id": "P-XXXX",
  "set": {
    "fs_id": "L274-XXX",
    "birth_date": "1816-06-03",
    "birth_place_ref": {"name": "Smyrna, Kent County, Delaware"},
    "death_date": null,
    "death_place_ref": null,
    "branch": null,
    "life_confidence": "high",
    "notes_append": "<one-line addition, prepended with [deep-dive YYYY-MM-DD]>",
    "source_summary_append": "<one-line addition, semicolon-joined to existing>"
  },
  "source_url": "https://...",
  "confidence": "high",
  "fact_refs": [3, 5]
}
```

`*_append` fields are additive — the apply script joins them to the
existing value with a separator (`\n` for `notes_append`, `; ` for
`source_summary_append`). Use `set` for direct replacements; only do
that when the GPKG value was NULL or this dossier's facts table marks
the conflict resolution explicitly.

Permitted keys in `set`:
- `fs_id` (TEXT)
- `birth_date`, `death_date` (TEXT — ISO 8601 preferred)
- `birth_place_ref`, `death_place_ref` (object with `name` matching a
  Place in the GPKG or a sibling `upsert_place` op in this dossier;
  use `null` to clear)
- `branch` (TEXT)
- `life_confidence` (`high|med|low`)
- `privacy_level` (`public|private`)
- `notes_append`, `source_summary_append` (TEXT — additive)
- `sex` (`male|female`) — only set if NULL; do not overwrite

### 4.4 Patch summary (auto-tally — fill in before apply)

- upsert_place ops: <N>
- insert_event ops: <N>
- insert_participant ops embedded in events: <N>
- update_person ops: <N>
- Estimated new Places after match-or-create: <N>
- Estimated new Events: <N>

## 5. Narrative — Life story

> 4-6 paragraphs of plain prose, no markdown headers inside,
> no bullets. **This section is the public-facing artifact.** It is
> rendered to `docs/narratives/<person_id>.html` by
> `scripts/generate_narratives.py` and surfaced from the Leaflet viewer's
> person popups via a "Read full narrative" button. Treat it as a piece of
> readable nonfiction, not a research summary.
>
> **Historical weaving is required, not optional.** Every narrative
> should tell two stories at once: the personal life and its place in the
> human story of the era. Weave Ring 6 context throughout — what was the
> nation, the state, the town doing at each turn of this person's life?
> What war, treaty, market panic, migration wave, technological shift, or
> cultural moment frames each decade? Don't isolate the history into a
> single "context paragraph" at the end. Let it sit alongside the
> biography so a reader senses the era pressing in on the person.
>
> Cite every concrete fact inline as `[1]`, `[2]` referring to row
> numbers in §3. Historical context that's a matter of general
> knowledge (e.g. "the Civil War began in 1861") doesn't need a
> citation; specific claims about *this* person always do. Markdown
> italics (`*title*`) are rendered as `<em>`; everything else is plain
> prose.

<Paragraph 1 — birth and family of origin, set against the era's
political/cultural moment (presidency, recent treaty/conflict, the
ethnic and religious complexion of the home county).>

<Paragraph 2 — childhood and early adulthood: migration, marriage, the
forces (economic, religious, political) shaping their generation's
choices.>

<Paragraph 3 — main adult life: occupation, place, children — interleaved
with the era's defining events (war, panic, technological shift) as they
touched this person's geography.>

<Paragraph 4 — late life: the Gilded Age, Progressive era, Reconstruction,
whatever frames the back third of the life. Weave in the long structural
forces (railroads, irrigation, immigration waves) that shaped where and
how they ended up.>

<Paragraph 5 — death and aftermath. Place the year of death in its world:
what the country looked like the spring they died, who survived them,
where they were buried, and what became of the spouse or children.>

<Paragraph 6, optional — only if needed to close a thread (e.g. a
remarriage or a descendant's later prominence).>

## 6. Open leads

> Things this dive deliberately did NOT chase. Future passes start here.

### Records to chase
- [ ] <e.g. "1870 census — couldn't find on FS, may exist in HeritageQuest behind library card">
- [ ] <e.g. "Probate file — Guthrie County, Iowa, ~1893; not online, county courthouse only">

### People discovered but not materialized
- [ ] <e.g. "Census neighbor 'J. Talley' (1850 Noble Co OH) likely Rebecca's brother — candidate for new People row">
- [ ] <e.g. "Obituary names surviving son 'William Reed of Stuart' — may or may not be P-0042 William T. Reed">

### Cross-skill follow-ups
- [ ] FS reconciliation: <if fs_id was NULL and you found a likely FS PID, name it here so `reconcile_familysearch.py` can score it>
- [ ] Place dedupe: <if you discovered an existing Place that's almost-but-not-quite a match for a place you upserted>
- [ ] Merge candidate: <if you found evidence this person and another P-#### are the same — DO NOT merge here; flag for `merge_duplicate_persons.py`>

### Paywalls hit
- [ ] <site, what you would have learned, ~cost>

## 7. Provenance

- Dive ran via: `lrgdm-deep-dive` skill, dossier_date <date>
- Phases completed: <list, e.g. "1, 2, 3 — Phase 4 awaiting John's review">
- Search tools used: <WebSearch | WebFetch | Chrome MCP | local FS extract>
- Wall-clock spent in Phase 2: <approx minutes>
- Stop reason: <"hit 20-fact cap" | "exhausted reachable sources" | "time budget" | "user interrupted">
