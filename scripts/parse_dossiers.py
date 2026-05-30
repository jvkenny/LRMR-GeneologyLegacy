#!/usr/bin/env python3
"""Backfill the LRGDM database from deep-dive dossiers (reports/deep-dives/*.md).

Moves provenance out of markdown and into the DB:
  * §3 Facts table  -> `source` (deduped by URL/title) + `citation` (per fact,
                       linked to the person, with confidence + conflict flag)
  * §5 Narrative     -> `narrative.body_md`
  * §6 Open leads    -> `research_lead` rows

Idempotent: per person it clears prior dossier-derived citations and leads and
re-inserts; sources are upserted by a stable hash id; narratives upsert by
person_id. Safe to re-run after editing a dossier.

Usage:
  python3 scripts/parse_dossiers.py            # all dossiers
  python3 scripts/parse_dossiers.py P-0056     # one (or several)

Connection: $LRGDM_PG (libpq conninfo), default "dbname=lrgdm".

NOTE: name variants (maiden/nickname) are NOT auto-extracted — dossiers have no
structured names section; person_name stays seeded with primaries, variants
added by hand / from the June 7 records.
"""
from __future__ import annotations

import hashlib
import os
import re
import sys
from datetime import date
from pathlib import Path

import psycopg

REPO = Path(__file__).resolve().parents[1]
DOSSIER_DIR = REPO / "reports" / "deep-dives"
CONNINFO = os.environ.get("LRGDM_PG", "dbname=lrgdm")

URL_RE = re.compile(r"https?://[^\s\)\]<>]+")
CONF_RE = re.compile(r"\b(high|med|medium|low)\b", re.I)


def parse_frontmatter(text):
    m = re.search(r"^---\s*$(.*?)^---\s*$", text, re.MULTILINE | re.DOTALL)
    fm = {}
    if m:
        for line in m.group(1).splitlines():
            if ":" in line:
                k, _, v = line.partition(":")
                fm[k.strip()] = v.strip()
    return fm


def section(text, num):
    """Return the body of '## <num>. ...' up to the next '## ' heading."""
    m = re.search(rf"^## {num}\.[^\n]*\n(.*?)(?=^## |\Z)", text, re.MULTILINE | re.DOTALL)
    return m.group(1) if m else ""


def parse_facts(text):
    """§3 facts table -> list of dicts {fact, source, url, confidence, conflicts}."""
    body = section(text, 3)
    rows = []
    for line in body.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) < 6:
            continue
        if not re.match(r"^\d+$", cells[0]):  # skip header + separator + non-numbered
            continue
        fact, source, url_cell, conf_cell, conflicts = cells[1], cells[2], cells[3], cells[4], cells[5]
        um = URL_RE.search(url_cell) or URL_RE.search(source)
        cm = CONF_RE.search(conf_cell)
        conf = cm.group(1).lower() if cm else None
        if conf == "medium":
            conf = "med"
        rows.append({
            "fact": fact,
            "source": re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", source).strip(),  # strip md links
            "url": um.group(0) if um else None,
            "confidence": conf,
            "conflicts": conflicts.lower().startswith("yes"),
        })
    return rows


def infer_source_type(source_text, url):
    s = source_text.lower()
    table = [
        ("numident", "numident"), ("social security death", "ssdi"), ("ssdi", "ssdi"),
        ("census", "census"), ("obituary", "obituary"), ("findagrave", "findagrave"),
        ("find a grave", "findagrave"), ("birth cert", "birth_certificate"),
        ("death record", "death_record"), ("death cert", "death_record"),
        ("marriage", "marriage_record"), ("newspaper", "newspaper"),
        ("oral history", "oral_history"), ("family testimony", "oral_history"),
        ("testimony", "oral_history"), ("naturalization", "naturalization"),
        ("passenger", "immigration"), ("immigration", "immigration"),
        ("draft", "draft_registration"), ("directory", "directory"),
        ("parish", "church_record"), ("church", "church_record"), ("book", "book"),
    ]
    for needle, code in table:
        if needle in s:
            return code
    return "website" if url else "other"


def source_id_for(url, title):
    key = (url or f"title:{title.lower()}").strip()
    return "S-" + hashlib.sha1(key.encode()).hexdigest()[:8].upper()


def parse_leads(text):
    """§6 Open leads -> list of {category, description, status}."""
    body = section(text, 6)
    leads = []
    category = "other"
    for line in body.splitlines():
        h = re.match(r"^###\s+(.*)", line.strip())
        if h:
            label = h.group(1).lower()
            if "record" in label:
                category = "record"
            elif "people" in label or "person" in label:
                category = "person"
            elif "cross-skill" in label or "follow-up" in label:
                category = "cross_skill"
            elif "wall" in label or "paywall" in label:
                category = "paywall"
            else:
                category = "other"
            continue
        m = re.match(r"^- \[( |x|X)\]\s+(.*)", line.strip())
        if m:
            desc = re.sub(r"\*\*|\*", "", m.group(2)).strip()
            if desc:
                leads.append({
                    "category": category,
                    "description": desc[:1000],
                    "status": "done" if m.group(1).lower() == "x" else "open",
                })
    return leads


def narrative_md(text):
    body = section(text, 5)
    lines = [ln for ln in body.splitlines() if not ln.lstrip().startswith(">")]
    return "\n".join(lines).strip()


def process(cur, path: Path):
    text = path.read_text()
    fm = parse_frontmatter(text)
    pid = fm.get("person_id")
    if not pid:
        print(f"  skip {path.name}: no person_id in frontmatter")
        return (0, 0, 0, 0)
    cur.execute("SELECT 1 FROM person WHERE person_id=%s", (pid,))
    if not cur.fetchone():
        print(f"  skip {pid}: not in person table")
        return (0, 0, 0, 0)
    try:
        ddate = date.fromisoformat(fm.get("dossier_date", "")) if fm.get("dossier_date") else None
    except ValueError:
        ddate = None

    # ---- sources + citations (idempotent: clear this person's citations) ----
    cur.execute("DELETE FROM citation WHERE subject_type='person' AND subject_id=%s", (pid,))
    facts = parse_facts(text)
    n_src = n_cit = 0
    for f in facts:
        sid = source_id_for(f["url"], f["source"])
        stype = infer_source_type(f["source"], f["url"])
        cur.execute("INSERT INTO source_type (code) VALUES (%s) ON CONFLICT DO NOTHING", (stype,))
        cur.execute(
            """INSERT INTO source (source_id, source_type, title, url, confidence)
               VALUES (%s,%s,%s,%s,%s)
               ON CONFLICT (source_id) DO UPDATE
                 SET title = EXCLUDED.title, url = COALESCE(EXCLUDED.url, source.url)""",
            (sid, stype, f["source"][:500], f["url"], f["confidence"]),
        )
        n_src += cur.rowcount
        cur.execute(
            """INSERT INTO citation (source_id, subject_type, subject_id, claim,
                                     confidence, conflicts_flag)
               VALUES (%s,'person',%s,%s,%s,%s)""",
            (sid, pid, f["fact"][:2000], f["confidence"], f["conflicts"]),
        )
        n_cit += 1

    # ---- narrative (upsert) ----
    body_md = narrative_md(text)
    if body_md:
        cur.execute(
            """INSERT INTO narrative (person_id, dossier_date, body_md, published)
               VALUES (%s,%s,%s,true)
               ON CONFLICT (person_id) DO UPDATE
                 SET dossier_date=EXCLUDED.dossier_date, body_md=EXCLUDED.body_md""",
            (pid, ddate, body_md),
        )

    # ---- research leads (idempotent: clear this dossier's leads) ----
    cur.execute("DELETE FROM research_lead WHERE source_dossier=%s", (pid,))
    leads = parse_leads(text)
    for ld in leads:
        cur.execute(
            """INSERT INTO research_lead (person_id, category, description, status, source_dossier)
               VALUES (%s,%s,%s,%s,%s)""",
            (pid, ld["category"], ld["description"], ld["status"], pid),
        )

    print(f"  {pid}: {n_cit} citations, {len(facts)} facts, "
          f"narrative={'yes' if body_md else 'no'}, {len(leads)} leads")
    return (1, n_cit, 1 if body_md else 0, len(leads))


def main() -> int:
    wanted = sys.argv[1:]
    paths = sorted(DOSSIER_DIR.glob("P-*.md"))
    if wanted:
        paths = [p for p in paths if p.stem in wanted]
    if not paths:
        print("No matching dossiers.")
        return 1
    with psycopg.connect(CONNINFO) as con:
        cur = con.cursor()
        tot = [0, 0, 0, 0]
        for p in paths:
            r = process(cur, p)
            tot = [a + b for a, b in zip(tot, r)]
        con.commit()
    print(f"done. {tot[0]} dossiers → {tot[1]} citations, {tot[2]} narratives, {tot[3]} leads")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
