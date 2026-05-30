#!/usr/bin/env python3
"""Data-quality validator for the LRGDM Postgres database.

Reads the DB, runs a fixed set of consistency checks, and writes a markdown
report to reports/validation_<DATE>.md. Foreign keys are ENFORCED in Postgres,
so the old broken-FK checks are gone — this focuses on the things constraints
can't catch.

Checks:
- person: missing names, sex, branch
- person: birth_date after death_date
- person: duplicate (normalized_name, birth_year) pairs
- person: fs_id referenced more than once
- place: missing/out-of-range coordinates; low/missing geocode_quality; orphans
- event: missing place_id, no participants, date_start > date_end

No writes. Conninfo via $LRGDM_PG (default dbname=lrgdm).
(Filename kept as validate_gpkg.py for backward-compat with existing callers.)
"""
from __future__ import annotations

import argparse
import re
import unicodedata
from collections import defaultdict
from datetime import date
from pathlib import Path

from psycopg.rows import tuple_row

from lrgdm_db import connect

REPO = Path(__file__).resolve().parents[1]


def normalize_name(raw: str | None) -> str:
    if not raw:
        return ""
    s = unicodedata.normalize("NFKD", raw).encode("ascii", "ignore").decode().lower()
    s = re.sub(r"\(.*?\)", " ", s)
    s = re.sub(r"[^a-z\s]", " ", s)
    return " ".join(s.split())


def parse_year(date_str: str | None) -> int | None:
    if not date_str:
        return None
    m = re.search(r"(1[5-9]\d{2}|20\d{2})", date_str)
    return int(m.group(1)) if m else None


def parse_iso(date_str: str | None) -> str | None:
    if not date_str:
        return None
    m = re.match(r"^(\d{4})(?:-(\d{2})(?:-(\d{2}))?)?$", date_str.strip())
    if not m:
        return None
    y, mo, d = m.groups()
    return f"{y}-{mo or '01'}-{d or '01'}"


class Report:
    def __init__(self) -> None:
        self.sections: dict[str, list[str]] = defaultdict(list)
        self.counts: dict[str, int] = defaultdict(int)

    def add(self, section: str, msg: str) -> None:
        self.sections[section].append(msg)
        self.counts[section] += 1

    def total(self) -> int:
        return sum(self.counts.values())


def check_people(cur, rep: Report) -> None:
    cur.execute(
        "SELECT person_id, primary_name, sex, branch, birth_date, death_date, fs_id "
        "FROM person"
    )
    rows = cur.fetchall()
    for pid, name, sex, branch, bd, dd, _ in rows:
        if not name or not name.strip():
            rep.add("missing-fields", f"`{pid}` has no primary_name")
        if not sex:
            rep.add("missing-fields", f"`{pid}` ({name}) has no sex")
        if not branch:
            rep.add("missing-fields", f"`{pid}` ({name}) has no branch")

    for pid, name, _, _, bd, dd, _ in rows:
        bi, di = parse_iso(bd), parse_iso(dd)
        if bi and di and bi > di:
            rep.add("date-order", f"`{pid}` ({name}): birth {bd} is after death {dd}")
        else:
            by, dy = parse_year(bd), parse_year(dd)
            if by and dy and by > dy:
                rep.add("date-order", f"`{pid}` ({name}): birth year {by} > death year {dy}")

    buckets: dict[tuple[str, int | None], list[tuple[str, str]]] = defaultdict(list)
    for pid, name, _, _, bd, _, _ in rows:
        key = (normalize_name(name), parse_year(bd))
        if key[0]:
            buckets[key].append((pid, name))
    for (nm, yr), members in buckets.items():
        if len(members) > 1:
            yr_str = str(yr) if yr is not None else "no birth year"
            ids = ", ".join(f"`{p}` ({n})" for p, n in members)
            rep.add("duplicate-people", f"{ids} share name `{nm}` and birth year {yr_str}")

    fs_buckets: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for pid, name, _, _, _, _, fs_id in rows:
        if fs_id and fs_id.strip():
            fs_buckets[fs_id.strip()].append((pid, name))
    for fs_id, members in fs_buckets.items():
        if len(members) > 1:
            ids = ", ".join(f"`{p}` ({n})" for p, n in members)
            rep.add("fs-id-collision", f"FS PID `{fs_id}` linked to {ids}")


def check_places(cur, rep: Report, low_quality: set[str]) -> None:
    cur.execute(
        "SELECT place_id, name, ST_Y(geom), ST_X(geom), geocode_quality FROM place"
    )
    rows = cur.fetchall()

    referenced = set()
    for col, tbl in [("birth_place_id", "person"), ("death_place_id", "person"),
                     ("place_id", "event")]:
        cur.execute(f"SELECT {col} FROM {tbl} WHERE {col} IS NOT NULL")
        referenced.update(r[0] for r in cur.fetchall())

    for pid, name, lat_f, lon_f, gq in rows:
        if lat_f is None or lon_f is None:
            rep.add("place-coords", f"`{pid}` ({name}) missing coordinates")
        else:
            if not (-90 <= lat_f <= 90):
                rep.add("place-coords", f"`{pid}` ({name}): lat {lat_f} out of range")
            if not (-180 <= lon_f <= 180):
                rep.add("place-coords", f"`{pid}` ({name}): long {lon_f} out of range")
        if gq is None or not str(gq).strip():
            rep.add("place-quality", f"`{pid}` ({name}) has no geocode_quality")
        elif str(gq).strip().lower() in low_quality:
            rep.add("place-quality", f"`{pid}` ({name}) has low geocode_quality=`{gq}`")
        if pid not in referenced:
            rep.add("place-orphan", f"`{pid}` ({name}) not referenced by any person or event")


def check_events(cur, rep: Report) -> None:
    cur.execute("SELECT DISTINCT event_id FROM event_participant")
    with_participants = {r[0] for r in cur.fetchall()}
    cur.execute("SELECT event_id, title, event_type, date_start, date_end, place_id FROM event")
    for eid, title, et, ds, de, place_id in cur.fetchall():
        if not place_id:
            rep.add("event-missing", f"`{eid}` ({title or et}) has no place_id")
        if eid not in with_participants:
            rep.add("event-missing", f"`{eid}` ({title or et}) has no participants")
        si, ei = parse_iso(ds), parse_iso(de)
        if si and ei and si > ei:
            rep.add("event-date-order", f"`{eid}` ({title or et}): date_start {ds} > date_end {de}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out-dir", type=Path, default=REPO / "reports")
    ap.add_argument(
        "--low-quality",
        default="approximate,unknown,low,poor",
        help="Comma-separated geocode_quality values treated as low",
    )
    args = ap.parse_args()

    low_quality = {s.strip().lower() for s in args.low_quality.split(",") if s.strip()}
    rep = Report()
    with connect(row_factory=tuple_row) as conn:
        cur = conn.cursor()
        check_people(cur, rep)
        check_places(cur, rep, low_quality)
        check_events(cur, rep)

    today = date.today().isoformat()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    out = args.out_dir / f"validation_{today}.md"

    section_titles = {
        "missing-fields": "person — missing required fields",
        "date-order": "person — birth/death date ordering",
        "duplicate-people": "person — duplicate (name, birth year) pairs",
        "fs-id-collision": "person — fs_id linked to multiple rows",
        "place-coords": "place — coordinate problems",
        "place-quality": "place — low/missing geocode_quality",
        "place-orphan": "place — not referenced by any person or event",
        "event-missing": "event — missing place_id or participants",
        "event-date-order": "event — date_start after date_end",
    }

    lines = [
        f"# LRGDM Validation — {today}",
        "",
        "- Source: Postgres db `lrgdm`",
        f"- Total findings: **{rep.total()}**",
        "",
        "## Summary",
        "",
        "| Section | Count |",
        "|---|---:|",
    ]
    for key, title in section_titles.items():
        lines.append(f"| {title} | {rep.counts[key]} |")
    lines.append("")

    for key, title in section_titles.items():
        items = rep.sections.get(key) or []
        if not items:
            continue
        lines.append(f"## {title}")
        lines.append("")
        for item in items:
            lines.append(f"- {item}")
        lines.append("")

    if rep.total() == 0:
        lines.append("_No issues found. Nice._")

    out.write_text("\n".join(lines))
    print(f"Wrote {out}")
    print(f"Total findings: {rep.total()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
