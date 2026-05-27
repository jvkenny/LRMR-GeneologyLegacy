#!/usr/bin/env python3
"""Data-quality validator for lrgdm_v2.gpkg.

Reads the GPKG, runs a fixed set of consistency checks, and writes a
markdown report to reports/validation_<DATE>.md.

Checks:
- People: rows missing names, sex, branch
- People: birth_date >= death_date
- People: duplicate (normalized_name, birth_year) pairs
- People: fs_id referenced more than once
- Places: rows missing lat/long or with out-of-range coords
- Places: low or missing geocode_quality (configurable)
- Places: orphan Places (place_id never referenced by People birth/death/event)
- Events: missing place_id, missing PID_People, date_start > date_end
- Events: place_id pointing to a non-existent Places row
- Relationships: person_id_a / person_id_b not in People

No writes to the GPKG.
"""
from __future__ import annotations

import argparse
import re
import sqlite3
import sys
import unicodedata
from collections import defaultdict
from datetime import date
from pathlib import Path

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
    """Return a sortable YYYY-MM-DD-ish string when the input looks ISO; else None."""
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


def check_people(conn: sqlite3.Connection, rep: Report) -> None:
    rows = list(conn.execute(
        "SELECT person_id, primary_name, sex, branch, birth_date, death_date, fs_id "
        "FROM People"
    ))

    # Missing fields
    for r in rows:
        pid, name, sex, branch, bd, dd, _ = r
        if not name or not name.strip():
            rep.add("missing-fields", f"`{pid}` has no primary_name")
        if not sex:
            rep.add("missing-fields", f"`{pid}` ({name}) has no sex")
        if not branch:
            rep.add("missing-fields", f"`{pid}` ({name}) has no branch")

    # Birth >= death
    for r in rows:
        pid, name, _, _, bd, dd, _ = r
        bi, di = parse_iso(bd), parse_iso(dd)
        if bi and di and bi > di:
            rep.add("date-order", f"`{pid}` ({name}): birth {bd} is after death {dd}")
        by, dy = parse_year(bd), parse_year(dd)
        if by and dy and by > dy:
            # Already caught above when both parse; this catches partial dates
            if not (bi and di):
                rep.add(
                    "date-order",
                    f"`{pid}` ({name}): birth year {by} > death year {dy}",
                )

    # Duplicate (name, birth_year) pairs
    buckets: dict[tuple[str, int | None], list[tuple[str, str]]] = defaultdict(list)
    for r in rows:
        pid, name, _, _, bd, _, _ = r
        key = (normalize_name(name), parse_year(bd))
        if key[0]:
            buckets[key].append((pid, name))
    for (nm, yr), members in buckets.items():
        if len(members) > 1:
            yr_str = str(yr) if yr is not None else "no birth year"
            ids = ", ".join(f"`{p}` ({n})" for p, n in members)
            rep.add("duplicate-people", f"{ids} share name `{nm}` and birth year {yr_str}")

    # fs_id collisions
    fs_buckets: dict[str, list[tuple[str, str]]] = defaultdict(list)
    for r in rows:
        pid, name, _, _, _, _, fs_id = r
        if fs_id and fs_id.strip():
            fs_buckets[fs_id.strip()].append((pid, name))
    for fs_id, members in fs_buckets.items():
        if len(members) > 1:
            ids = ", ".join(f"`{p}` ({n})" for p, n in members)
            rep.add("fs-id-collision", f"FS PID `{fs_id}` linked to {ids}")


def check_places(conn: sqlite3.Connection, rep: Report, low_quality: set[str]) -> None:
    rows = list(conn.execute(
        "SELECT place_id, name, lat, long, geocode_quality FROM Places"
    ))

    referenced = set()
    for col, tbl in [
        ("birth_place_id", "People"),
        ("death_place_id", "People"),
        ("place_id", "Events"),
    ]:
        for (pl,) in conn.execute(f"SELECT {col} FROM {tbl} WHERE {col} IS NOT NULL AND {col} != ''"):
            referenced.add(pl)

    for pid, name, lat, lon, gq in rows:
        try:
            lat_f = float(lat) if lat not in (None, "") else None
        except (TypeError, ValueError):
            lat_f = None
            rep.add("place-coords", f"`{pid}` ({name}): lat `{lat}` is not numeric")
        try:
            lon_f = float(lon) if lon not in (None, "") else None
        except (TypeError, ValueError):
            lon_f = None
            rep.add("place-coords", f"`{pid}` ({name}): long `{lon}` is not numeric")

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
            rep.add("place-orphan", f"`{pid}` ({name}) not referenced by any Person or Event")


def check_events(conn: sqlite3.Connection, rep: Report) -> None:
    place_ids = {p[0] for p in conn.execute("SELECT place_id FROM Places")}
    person_ids = {p[0] for p in conn.execute("SELECT person_id FROM People")}

    for r in conn.execute(
        "SELECT event_id, title, event_type, date_start, date_end, place_id, PID_People "
        "FROM Events"
    ):
        eid, title, et, ds, de, place_id, pid_people = r
        if not place_id:
            rep.add("event-missing", f"`{eid}` ({title or et}) has no place_id")
        elif place_id not in place_ids:
            rep.add("event-broken-fk", f"`{eid}` ({title or et}): place_id `{place_id}` not in Places")

        if not pid_people:
            rep.add("event-missing", f"`{eid}` ({title or et}) has no PID_People")
        else:
            # Some Events.PID_People are pipe-delimited or comma-delimited
            tokens = [t.strip() for t in re.split(r"[|,;]", pid_people) if t.strip()]
            for t in tokens:
                if t not in person_ids:
                    rep.add(
                        "event-broken-fk",
                        f"`{eid}` ({title or et}): PID_People `{t}` not in People",
                    )

        si, ei = parse_iso(ds), parse_iso(de)
        if si and ei and si > ei:
            rep.add("event-date-order", f"`{eid}` ({title or et}): date_start {ds} > date_end {de}")


def check_relationships(conn: sqlite3.Connection, rep: Report) -> None:
    person_ids = {p[0] for p in conn.execute("SELECT person_id FROM People")}
    for rel_id, pa, rel, pb in conn.execute(
        "SELECT rel_id, person_id_a, relation, person_id_b FROM Relationships"
    ):
        if pa and pa not in person_ids:
            rep.add("rel-broken-fk", f"`{rel_id}`: person_id_a `{pa}` not in People")
        if pb and pb not in person_ids:
            rep.add("rel-broken-fk", f"`{rel_id}`: person_id_b `{pb}` not in People")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--gpkg", type=Path, default=REPO / "src/data/lrgdm_v2.gpkg")
    ap.add_argument("--out-dir", type=Path, default=REPO / "reports")
    ap.add_argument(
        "--low-quality",
        default="approximate,unknown,low,poor",
        help="Comma-separated geocode_quality values treated as low",
    )
    args = ap.parse_args()

    if not args.gpkg.exists():
        print(f"GPKG not found: {args.gpkg}", file=sys.stderr)
        return 1

    low_quality = {s.strip().lower() for s in args.low_quality.split(",") if s.strip()}
    conn = sqlite3.connect(args.gpkg)

    rep = Report()
    check_people(conn, rep)
    check_places(conn, rep, low_quality)
    check_events(conn, rep)
    check_relationships(conn, rep)
    conn.close()

    today = date.today().isoformat()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    out = args.out_dir / f"validation_{today}.md"

    section_titles = {
        "missing-fields": "People — missing required fields",
        "date-order": "People — birth/death date ordering",
        "duplicate-people": "People — duplicate (name, birth year) pairs",
        "fs-id-collision": "People — fs_id linked to multiple rows",
        "place-coords": "Places — coordinate problems",
        "place-quality": "Places — low/missing geocode_quality",
        "place-orphan": "Places — not referenced by any person or event",
        "event-missing": "Events — missing place_id or PID_People",
        "event-broken-fk": "Events — broken foreign keys",
        "event-date-order": "Events — date_start after date_end",
        "rel-broken-fk": "Relationships — broken foreign keys",
    }

    lines = [
        f"# LRGDM Validation — {today}",
        "",
        f"- GPKG: `{args.gpkg.relative_to(REPO)}`",
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
