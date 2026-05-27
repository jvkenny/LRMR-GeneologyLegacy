# Web-Mention Miner — Remote Routine Prompt

This is the prompt the LRGDM enrichment routine runs each week. It's checked
into the repo so the routine has a stable, reviewable reference. The actual
routine has this same text embedded in its config.

---

You're running as a scheduled enrichment pass on the LRGDM repo
(github.com/jvkenny/lrgdm). The goal of this run: pick a small batch of John
Kenny's deceased ancestors and search the open web for obituaries, news,
census records, and other mentions that aren't yet captured in the GPKG. You
write findings to markdown — you do NOT touch the GPKG directly.

## What to do

1. `python3 scripts/validate_gpkg.py` — refresh the validation report so the
   PR you open includes the latest baseline.

2. `python3 scripts/next_mining_batch.py --batch-size 5` — get the next 5
   people to mine. The JSON output has each person's name, dates, place names,
   branch, and fs_id (if known).

3. For each person in the batch:
   - Run **WebSearch** with queries like:
     - `"<full name>" obituary <death year>`
     - `"<full name>" <birth place_name>`
     - `"<full name>" <branch family name> genealogy`
     - `"<full name>" census <birth year>`
   - Add 1-2 narrower follow-ups if a first-page result looks promising.
   - For each useful hit, capture the URL, the publication/site, a 1-2 sentence
     summary of what it confirms or adds, and any new facts (dates, places,
     relatives) it provides.
   - Skip obvious irrelevancies (different person with same name). Cross-check
     against the dates/places already in the GPKG.

4. Write the findings to `reports/web_mentions/<person_id>.md`. One file per
   person. Overwrite if the file exists — the freshest pass wins. Each file
   should be self-contained: name + GPKG dates at the top, then a list of
   findings with URLs.

5. If a finding strongly suggests an existing GPKG fact is wrong (e.g., obit
   gives a different death date than what's recorded), note it under a
   `## Discrepancies` section in the file — don't try to "fix" it. John
   reviews and applies.

6. Commit the changes (`reports/validation_<DATE>.md` + the new/updated
   `reports/web_mentions/*.md`) on a new branch named
   `enrichment/<YYYY-MM-DD>` and open a PR titled
   `Weekly enrichment <YYYY-MM-DD>`. The PR body should list each person mined
   and a one-line summary of what was found.

## Boundaries

- Don't write to the GPKG. Don't run `apply_*` scripts. Don't modify
  `src/data/`.
- Don't run the FamilySearch scrape — that's a local-only skill
  (`lrgdm-pedigree-walk`).
- If WebSearch is unavailable or returns nothing for everyone in the batch,
  open the PR anyway with an empty mining section and the validation report —
  John still wants to see the validation diff weekly.
- Keep summaries factual. Don't speculate about relationships or facts not
  supported by a source.
- Respect copyright — quote at most one short fragment (<15 words) per
  source, and always link out to the original.

## Output schema for reports/web_mentions/<person_id>.md

```markdown
# <Primary name> — Web Mentions

- **GPKG person_id:** `<person_id>`
- **Born:** <birth_date> in <birth_place_name>
- **Died:** <death_date> in <death_place_name>
- **Branch:** <branch>
- **Last mined:** <YYYY-MM-DD>

## Findings

### <Source title>
- **URL:** <url>
- **Site:** <publication / domain>
- **What it adds:** <1-2 sentences>
- **New facts (if any):** <bullet list>

(repeat for each finding)

## Discrepancies

(only if any — otherwise omit this section)

- <gpkg fact> vs <source fact> [link]
```
