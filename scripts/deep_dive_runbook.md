# Deep Dive Runbook — LRGDM single-person research

Companion reference for the `lrgdm-deep-dive` skill. The skill orchestrates;
this doc says **what to search, in what order, with what queries, and when
to stop**. Don't read this end-to-end every time — jump to the ring you
need.

> **Quick links inside this doc:** [Source priority](#source-priority) · [Confidence rubric](#confidence-rubric) · [Search order](#search-order--the-six-rings) · [Conflict handling](#handling-conflicts) · [Bounding rules](#bounding-rules)

---

## Source priority

Higher = more authoritative. When two sources conflict, prefer the higher
class. Each class maps to a default confidence tag, but a specific source
can override (e.g., a transcribed church register is class 1 but, if the
scan is missing, drops to `med`).

| Class | Type | Default confidence | Examples |
|---|---|---|---|
| 1 | Primary contemporaneous vital | `high` | Birth/death certs, church baptism/marriage/burial registers, original probate, original deeds. |
| 2 | Primary contemporaneous narrative | `high` | Original newspaper obituary (with date + page scan), passenger manifest, draft registration, naturalization paper, census image. |
| 3 | Government/clerical index | `med` | State death indexes (no image), SSDI, county marriage indexes, Find My Past transcriptions. |
| 4 | Modern secondary | `med` | FindAGrave with stone photo, published compiled genealogy, peer-reviewed journal article. |
| 5 | User-contributed | `med` if cross-confirmed, else `low` | FamilySearch attached source citations (with link to a class 1-3 underneath), Ancestry trees, WikiTree, RootsWeb. |
| 6 | Inferred | `low` | "Must have been in X in 1880 because his son was born there." Reasoned, not sourced. |
| 7 | Anecdotal | `low` | Family stories, undated photos, single-source user trees. |

A "fact" with no source is not a fact — it's an open lead. Don't put it in
the facts table; put it in **Open leads**.

---

## Confidence rubric

The skill's facts table uses three buckets. Tag every fact.

- **`high`** — class 1 or 2 with a verifiable URL or archive citation, plus
  agreement with at least one other independent source OR a clear original
  scan/image you've examined. If a single class-1 source can't be
  cross-confirmed (e.g., only the church register exists), `high` is still
  acceptable — but say so in the source notes.
- **`med`** — class 3 or 4, OR a class 1-2 source you couldn't view the
  image for (transcription only). The fact is probably right but a careful
  researcher would want to see the original.
- **`low`** — class 5-7, inferred, or any single-thread chain (one
  user-tree → propagated everywhere). Useful as a lead, not as a citation.

When in doubt, downgrade. It's better to mark a `high` fact as `med` than
to anchor a future patch on something that turns out to be a copy-paste of
the same user tree across ten sites.

---

## Search order — the six rings

Each ring builds on the prior. Don't skip rings — even if Ring 3 gave you a
beautiful obit, do Ring 4 too. The point of a deep dive is to be thorough.

### Ring 0 — FamilySearch attached records

Run **only if** `fs_id` is set on the person.

- URL: `https://www.familysearch.org/tree/person/sources/<fs_id>`
- Use the Chrome MCP (`mcp__Claude_in_Chrome__*`) — you need to be logged
  in. The `lrgdm-pedigree-walk` skill documents the login/session pattern.
- For each attached source, capture: source title, type (record set), date,
  place, URL, what facts it confirms.
- Record the FamilySearch attached-source count vs. how many you actually
  inspected. (`sourceCount: 12, inspected: 12` is good; `12 / 3` is a
  follow-up.)

If the person has no `fs_id`, skip to Ring 1 and note in Open Leads that
this person is a candidate for FS reconciliation.

### Ring 1 — Vital records & burial

Anchor: full name + birth year ± 2 + death year ± 2 + last known county.

| Source | Query pattern | Notes |
|---|---|---|
| FindAGrave | `site:findagrave.com "<full name>" <death year>` | Look for stone photo; cross-link spouse / parents from memorial page. |
| BillionGraves | `site:billiongraves.com "<full name>"` | Less coverage than FindAGrave but better in some western states. |
| State death index | `<state> death index "<surname>" <death year>` | Iowa, Ohio, Illinois, Delaware all have free online indexes. |
| County recorder | `"<county>" county recorder marriage <surname>` | Marriages are often indexed even when births aren't. |
| Parish records | `"<parish>" baptism register <year range>` | For Catholic ancestors — Czech, Italian, French-Canadian, Irish lines. |

For pre-1900 / European ancestors the parish register often IS the birth
record. Don't expect a state birth cert before ~1908 for most US states.

### Ring 2 — Census

US federal census coverage: **1790, 1800, 1810, 1820, 1830, 1840, 1850,
1860, 1870, 1880, 1900, 1910, 1920, 1930, 1940, 1950**. (1890 mostly lost
in the 1921 fire.) State censuses (Iowa, New York, Wisconsin, Kansas)
fill some gaps.

For each census the person should appear in based on lifespan:

- Search FamilySearch's record browser: filter by name + birth year ± 5 +
  state. Don't trust the name index alone — read the household.
- Capture: enumeration date, ED #, page #, household composition (every
  person in the dwelling, with age and relation), occupation, property
  value, birthplace (theirs + parents' — the post-1880 censuses ask).
- Cross-link with siblings/parents/spouse already in the database. A census
  entry for a parent often resolves a child's birth-place.
- **Neighbors matter.** Same-surname neighbors are often cousins. A
  brother-in-law two doors down explains a marriage. Record them as Open
  Leads, not as facts about your person.

### Ring 3 — Newspapers

Anchor by death year + town for obituaries; by marriage year for wedding
notices; by lifespan + town for mentions.

| Archive | Coverage | Access |
|---|---|---|
| Chronicling America (loc.gov) | US, 1690-1963 | Free. Best for pre-1923. |
| NYS Historic Newspapers | New York state | Free. |
| Iowa Digital Newspaper Project | Iowa | Free. |
| Illinois Digital Newspaper Collections | IL | Free. |
| FultonHistory.com | NY + scattered | Free, ugly, search via Google. |
| newspapers.com | Massive | Subscription. Ask John before assuming access. |
| GenealogyBank | Strong on obits | Subscription; free preview snippets. |

Query templates:
- `"<full name>" obituary <death year>`
- `"<full name>" "<town>" <death year>`
- `"Mrs. <husband first> <surname>" <town>` — pre-1970s women often only
  appear under their husband's name in print.
- `"<surname>" "<town>" <year ± 2>` — for unindexed mention scanning.

For each hit, capture: publication title, date, page #, column, the actual
text (one short quoted fragment ≤ 15 words for context — copyright), and
the URL or archive ID. If it's a paywall preview, still record it with
`(paywalled — preview only)` so John can decide whether to subscribe.

### Ring 4 — Migration & immigration

Especially important for the Czech (Říha, Zíka, Zemanová), Irish (Kenny),
French-Canadian (Pouliot, Tremblay, Audet, Lapointe), and German lines.

| Source | What it gives |
|---|---|
| Castle Garden (1820-1892) | NYC arrivals pre-Ellis. |
| Ellis Island (1892-1957) | NYC arrivals; manifest scans on FS. |
| Border crossings (US/Canada, US/Mexico) | Big for French-Canadian back-and-forth. |
| WWI draft (1917-1918) | All US men born 1872-1900 — physical description, employer, nearest relative. |
| WWII draft "Old Man's" (1942) | Men born 1877-1897. |
| Naturalization (declaration + petition) | Often gives village of origin & arrival ship + date. |
| Passport applications | After ~1906, includes a photo. |

Query template: `"<full name>" passenger arrival <year range>`, or browse
FS's Historical Records → Migration.

When you find a manifest: capture the ship name, port of departure, port
of arrival, arrival date, age at arrival, accompanying family members,
last residence, intended destination. The intended destination often
points at a relative already in the US — record as Open Lead.

### Ring 5 — Local & ethnic context

For non-US-born ancestors, the local/parish history is often the only
path past the immigration event. Examples:

- **Czech lines** (Říha, Zíka, Zemanová, Kroll-side): try
  `actapublica.eu`, the Czech regional archives' parish register portal.
  Free, scans included. Bohemia is well-digitized.
- **French-Canadian** (Pouliot, Tremblay, Audet, Lapointe): the PRDH
  database (paywalled) and Drouin Collection on Ancestry. FamilySearch
  has indexed Quebec Catholic parish records back to ~1621.
- **Irish** (Kenny): Catholic parish registers on NLI's
  registers.nli.ie — free, browse by parish.
- **Italian** (Mariotti): Antenati state archive portal — free, scans
  of civil records 1809-1910.
- **German**: Archion (paywalled, Protestant) and Matricula (free,
  Catholic).

### Ring 6 — Historical context

**Not light — load-bearing.** The §5 narrative is the public-facing
artifact (rendered to `docs/narratives/<person_id>.html` by
`scripts/generate_narratives.py`), and the brief is dual-purpose:
tell the individual's story *and* their place in the human story of the
era. Ring 6 supplies the second of those.

Sketch at least one piece of contemporaneous context per decade of the
person's adult life:

- What war / treaty / panic / migration wave / technological shift was
  shaping their region during this decade?
- Who was president, who was the dominant cultural voice, what was the
  defining cultural moment of the year?
- For each major move: what made that destination attractive in that
  specific year? (Land warrants, irrigation projects, gold rushes, the
  Homestead Act, the railroad reaching town, a religious revival, etc.)
- For their death year specifically: what did the spring of that year
  look like nationally? Who else famously died or was born?

Don't cite "the 1860s in general" as a source for anything specific —
but a quick WebSearch per era (e.g. "1907 Iowa farm economy",
"Twin Falls Idaho 1915 irrigation") gives you the load-bearing one-liners.
Weave these into the narrative; don't quarantine them in a closing
context paragraph.

---

## Handling conflicts

When a record disagrees with the database (or with another record):

1. **Record both.** The facts table has a `Conflicts?` column —
   set it to `yes` and list the conflicting database fact.
2. **Don't auto-patch over the database value** with an `update_person` op.
   Surface the conflict in the narrative and let John decide.
3. **Resolution rules of thumb** (apply judgment):
   - Class 1 source overrides class 4-7 every time.
   - Original > transcribed > indexed.
   - Closer-in-time to the event > later. (Obituary > 50-years-later
     descendant tree.)
   - Self-reported > derived. (A passport application is the person
     stating their own birth date; a great-grandchild's family tree is not.)
   - For dates with `circa` or year-only, a more-specific newer source is
     fine to propose — but tag as `med` unless it's a class-1 image.
4. **Same-fact, multiple-source agreement** is the gold standard. A birth
   date confirmed by census × 3, draft card, and tombstone is `high` even
   if the original cert is missing.

---

## Bounding rules

These exist so the deep dive **terminates**. Apply them ruthlessly.

- **Six rings max.** Don't invent a Ring 7. Open Leads is the parking lot.
- **20 sourced facts** is the target ceiling for the facts table. If a
  person has 50 sourced facts worth recording, do two passes — write
  the dossier at fact #20, then a second pass focused on the long tail.
- **Per-ring source cap:** ~5 sources per ring is plenty for one dossier.
  Beyond that you're collecting duplicates. (Five obits all sourced from
  the same original AP wire isn't five sources, it's one.)
- **Time budget:** ~60 minutes wall-clock in Phase 2. If you're still
  searching at 60+, stop, write what you have, and put the rest in Open
  Leads.
- **Stop conditions before the cap:**
  - All gaps from Phase 1 are filled (birth, death, both places, at least
    one census per decade of adult life, at least one ring-3 newspaper hit).
  - Dossier has at least 8 `high`-confidence facts and a coherent narrative.
  - You've exhausted reachable open archives and the next step would be a
    paywalled subscription John hasn't confirmed.
- **Living people:** stop immediately. See the skill's "Bounding rules"
  section for the privacy stop.

---

## What to do when you find a new person

Census neighbors, obit-listed children, manifest-listed traveling
companions — these all introduce people. The deep dive is for ONE person.
Don't materialize new People rows for them in this dossier.

Instead:
- If they're clearly a direct ancestor and we just missed them, add to
  Open Leads with a note: "candidate for FS reconciliation / new ingest".
- If they're a sibling/spouse/child of the dive subject, log them in Open
  Leads with their tie. The next deep dive on the subject's family unit
  picks them up.

The exception: a **direct parent** of the subject that's missing from the
database and is confirmed by a class-1 source can get an `insert_event`
("birth event for subject names parent X") *plus* an Open Lead to add the
parent properly. Don't create the parent's People row from a deep dive.
