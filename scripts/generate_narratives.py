#!/usr/bin/env python3
"""Generate public-facing narrative HTML pages from deep-dive dossiers.

Reads `reports/deep-dives/P-*.md`, renders public-facing pages to
`docs/narratives/<person_id>.html`, and writes an index at
`docs/data/narratives_index.json` that the Leaflet viewer fetches to decide
whether to render a "Read full narrative" link in a person popup.

Public output strips technical sections: only the §5 Narrative and the §3
Facts Table sources are surfaced. Each page carries an attribution footer
crediting the AI-assisted research collaboration on the dossier_date.

Run from repo root:
    python3 scripts/generate_narratives.py
"""

import html
import json
import re
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOSSIER_DIR = ROOT / "reports" / "deep-dives"
OUT_DIR = ROOT / "docs" / "narratives"
INDEX_PATH = ROOT / "docs" / "data" / "narratives_index.json"

FRONTMATTER_RE = re.compile(r"^---\s*$(.*?)^---\s*$", re.MULTILINE | re.DOTALL)
SECTION_RE = re.compile(r"^## (\d+)\. ", re.MULTILINE)
URL_RE = re.compile(r"https?://[^\s\)\]<>]+")
CITE_RE = re.compile(r"\[(\d+)\]")
YEAR_RE = re.compile(r"\b(1[6-9]\d\d|20\d\d)\b")


def parse_frontmatter(text):
    m = FRONTMATTER_RE.search(text)
    if not m:
        return {}, text
    fm = {}
    for line in m.group(1).strip().split("\n"):
        if ":" in line:
            k, v = line.split(":", 1)
            fm[k.strip()] = v.strip()
    return fm, text[m.end():].strip()


def split_sections(body):
    parts = SECTION_RE.split(body)
    sections = {}
    for i in range(1, len(parts), 2):
        num = parts[i]
        raw = parts[i + 1] if i + 1 < len(parts) else ""
        # Drop the remainder of the heading line (the section title after "## N. ")
        raw = raw.split("\n", 1)[1] if "\n" in raw else ""
        sections[num] = raw.strip()
    return sections


def parse_facts_table(section_text):
    facts = []
    in_table = False
    for line in section_text.split("\n"):
        line = line.strip()
        if line.startswith("|") and re.search(r"---+", line):
            in_table = True
            continue
        if in_table and line.startswith("|"):
            cols = [c.strip() for c in line.strip("|").split("|")]
            if len(cols) >= 5:
                try:
                    num = int(cols[0])
                except ValueError:
                    continue
                facts.append({
                    "num": num,
                    "fact": cols[1],
                    "source": cols[2],
                    "url_cell": cols[3],
                    "confidence": cols[4],
                })
        elif in_table and not line.startswith("|"):
            break
    return facts


def narrative_paragraphs(section_text):
    paras = []
    for chunk in section_text.split("\n\n"):
        chunk = chunk.strip()
        if not chunk or chunk.startswith("#") or chunk.startswith(">") or chunk.startswith("|"):
            continue
        paras.append(" ".join(chunk.split()))
    return paras


ITALIC_RE = re.compile(r"\*([^*\n]+)\*")


def render_citations(escaped_text):
    text = CITE_RE.sub(
        lambda m: f'<sup><a href="#source-{m.group(1)}" class="cite">[{m.group(1)}]</a></sup>',
        escaped_text,
    )
    text = ITALIC_RE.sub(r"<em>\1</em>", text)
    return text


def person_life_dates(person_id):
    # Source of truth is Postgres (db lrgdm); $LRGDM_PG overrides the conninfo.
    import os
    import psycopg

    with psycopg.connect(os.environ.get("LRGDM_PG", "dbname=lrgdm")) as con:
        row = con.execute(
            "SELECT birth_date, death_date FROM person WHERE person_id=%s",
            (person_id,),
        ).fetchone()
    if not row:
        return ""

    def yr(d):
        if not d:
            return None
        m = YEAR_RE.search(d)
        return m.group(1) if m else None

    b, d = yr(row[0]), yr(row[1])
    if b and d:
        return f"{b} — {d}"
    if b:
        return f"b. {b}"
    if d:
        return f"d. {d}"
    return ""


def format_date_human(iso):
    try:
        return datetime.strptime(iso, "%Y-%m-%d").strftime("%B %-d, %Y")
    except ValueError:
        return iso


def render_narrative_html(paragraphs):
    out = []
    for p in paragraphs:
        out.append(f"      <p>{render_citations(html.escape(p))}</p>")
    return "\n".join(out)


def render_sources_html(facts):
    out = []
    for f in facts:
        urls = URL_RE.findall(f["url_cell"])
        url_html = ""
        if urls:
            links = []
            for u in urls:
                display = u.replace("https://", "").replace("http://", "")
                links.append(
                    f'<a href="{html.escape(u, quote=True)}" target="_blank" '
                    f'rel="noopener noreferrer">{html.escape(display)}</a>'
                )
            url_html = f'<div class="source-url">{" · ".join(links)}</div>'
        conf = f["confidence"].strip()
        conf_html = (
            f'<span class="confidence conf-{re.sub(r"[^a-z]", "", conf.lower())}">{html.escape(conf)}</span>'
            if conf else ""
        )
        out.append(
            f'        <li id="source-{f["num"]}">\n'
            f'          <div class="fact">{html.escape(f["fact"])}{conf_html}</div>\n'
            f'          <div class="source-name">{html.escape(f["source"])}</div>\n'
            f'          {url_html}\n'
            f'        </li>'
        )
    return "\n".join(out)


CSS = """:root {
  --bg: #fefcf8;
  --ink: #1f1b16;
  --ink-dim: #6b6359;
  --warm: #f5ecdf;
  --accent: #8a4a2a;
  --rule: rgba(31, 27, 22, 0.12);
  --max-w: 720px;
}
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; background: var(--bg); color: var(--ink); }
body { font: 17px/1.7 Georgia, "Iowan Old Style", "Apple Garamond", "Times New Roman", serif;
       -webkit-font-smoothing: antialiased; }
header.site { padding: 16px 24px; border-bottom: 1px solid var(--rule); background: var(--bg); }
header.site .back {
  font: 600 14px/1 system-ui, -apple-system, "Segoe UI", sans-serif;
  color: var(--accent); text-decoration: none;
}
header.site .back:hover { text-decoration: underline; }
main { max-width: var(--max-w); margin: 0 auto; padding: 32px 24px 80px; }
.hero h1 { font: 700 36px/1.15 inherit; margin: 0 0 6px; letter-spacing: -0.01em; }
.hero .dates {
  font: 500 15px/1 system-ui, -apple-system, "Segoe UI", sans-serif;
  color: var(--ink-dim); margin: 0 0 36px; font-variant-numeric: tabular-nums;
}
.narrative p { margin: 0 0 1.2em; }
.narrative p:first-child::first-letter {
  font-size: 3.2em; float: left; line-height: 0.9; padding: 6px 8px 0 0;
  color: var(--accent); font-weight: 700;
}
.cite { color: var(--accent); text-decoration: none; font-weight: 600; }
.cite:hover { text-decoration: underline; }
.sources { margin-top: 48px; padding-top: 24px; border-top: 1px solid var(--rule); }
.sources h2 {
  font: 600 14px/1.2 system-ui, -apple-system, "Segoe UI", sans-serif;
  margin: 0 0 20px; letter-spacing: 0.08em; text-transform: uppercase; color: var(--ink-dim);
}
.source-list { padding-left: 1.4em; margin: 0; font: 14px/1.55 system-ui, -apple-system, "Segoe UI", sans-serif; }
.source-list li { margin: 0 0 18px; padding-left: 4px; scroll-margin-top: 80px; }
.source-list li:target { background: var(--warm); padding: 6px 8px; border-radius: 6px; margin-left: -8px; }
.source-list .fact { color: var(--ink); }
.source-list .source-name { color: var(--ink-dim); margin: 4px 0 2px; font-style: italic; }
.source-list a { color: var(--accent); word-break: break-word; }
.source-list .confidence {
  display: inline-block; padding: 1px 7px; border-radius: 8px; margin-left: 6px;
  font-size: 10px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase;
  background: var(--warm); color: var(--ink-dim); vertical-align: middle;
}
.attribution {
  margin-top: 48px; padding-top: 20px; border-top: 1px solid var(--rule);
  font: 13px/1.6 system-ui, -apple-system, "Segoe UI", sans-serif;
  color: var(--ink-dim);
}
.attribution strong { color: var(--ink); }
.attribution a { color: var(--accent); }
.attribution .fs-link {
  display: inline-block; margin-top: 10px; padding: 8px 14px;
  border-radius: 8px; background: var(--accent); color: #fff; text-decoration: none;
  font: 600 12px/1 system-ui, -apple-system, "Segoe UI", sans-serif;
}
.attribution .fs-link:hover { background: #6e3a21; }
@media (max-width: 600px) {
  main { padding: 24px 18px 60px; }
  .hero h1 { font-size: 28px; }
  body { font-size: 16px; }
}
"""

PAGE_TEMPLATE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{title} — Narrative</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="A researched biographical narrative for {title}, part of the Leah Rae Mariotti-Reed Genealogy Legacy.">
<style>
{css}
</style>
</head>
<body>
<header class="site">
  <a href="../" class="back">← Back to the map</a>
</header>
<script>
  // When this page is loaded inside the map viewer's modal iframe, hide the
  // "Back to the map" header — the close button on the overlay handles that.
  if (window.self !== window.top) document.documentElement.classList.add('embedded');
</script>
<style>
  html.embedded header.site {{ display: none; }}
  html.embedded main {{ padding-top: 36px; }}
  html.embedded .hero h1 {{ padding-right: 56px; }}
</style>
<main>
  <article>
    <header class="hero">
      <h1>{title}</h1>
      <p class="dates">{life_dates}</p>
    </header>

    <section class="narrative">
{narrative_html}
    </section>

    <section class="sources">
      <h2>Sources</h2>
      <ol class="source-list">
{sources_html}
      </ol>
    </section>

    <footer class="attribution">
      <p>This narrative was researched and drafted by <strong>Claude</strong> (Anthropic) in partnership with <strong>John Kenny</strong> on {dossier_date_human}. Every fact in the narrative is anchored to the citations above. This is one of a growing series of AI-assisted ancestor biographies; the underlying research dossier — with confidence tags, conflicts, and open leads — lives in the <a href="https://github.com/jvkenny/LRMR-GeneologyLegacy" target="_blank" rel="noopener">project repository</a>.</p>
      {fs_link_html}
    </footer>
  </article>
</main>
</body>
</html>
"""


def render_page(fm, facts, paragraphs, life_dates):
    title = fm.get("primary_name", "Unknown")
    fs_id = fm.get("fs_id", "").strip()
    fs_link_html = ""
    if fs_id and fs_id.upper() != "NULL":
        fs_link_html = (
            f'<p><a class="fs-link" '
            f'href="https://www.familysearch.org/tree/person/details/{html.escape(fs_id, quote=True)}" '
            f'target="_blank" rel="noopener noreferrer">View on FamilySearch ↗</a></p>'
        )
    return PAGE_TEMPLATE.format(
        title=html.escape(title),
        life_dates=html.escape(life_dates),
        css=CSS,
        narrative_html=render_narrative_html(paragraphs),
        sources_html=render_sources_html(facts),
        dossier_date_human=html.escape(format_date_human(fm.get("dossier_date", ""))),
        fs_link_html=fs_link_html,
    )


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    INDEX_PATH.parent.mkdir(parents=True, exist_ok=True)

    index = {}
    written = 0
    for path in sorted(DOSSIER_DIR.glob("P-*.md")):
        text = path.read_text()
        fm, body = parse_frontmatter(text)
        sections = split_sections(body)
        facts = parse_facts_table(sections.get("3", ""))
        paragraphs = narrative_paragraphs(sections.get("5", ""))
        if not paragraphs:
            print(f"  ! {path.name}: empty narrative — skipping", file=sys.stderr)
            continue
        pid = fm.get("person_id", path.stem)
        page = render_page(fm, facts, paragraphs, person_life_dates(pid))
        (OUT_DIR / f"{pid}.html").write_text(page)
        index[pid] = {
            "url": f"narratives/{pid}.html",
            "dossier_date": fm.get("dossier_date", ""),
            "primary_name": fm.get("primary_name", ""),
        }
        written += 1
        print(f"  + {pid}.html  ({fm.get('primary_name', '?')})")

    INDEX_PATH.write_text(json.dumps(index, indent=2, sort_keys=True) + "\n")
    print(f"\nWrote {written} narrative page(s) → {OUT_DIR.relative_to(ROOT)}")
    print(f"Wrote index → {INDEX_PATH.relative_to(ROOT)} ({len(index)} entries)")


if __name__ == "__main__":
    main()
