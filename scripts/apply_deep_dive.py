#!/usr/bin/env python3
"""Apply a deep-dive dossier's structured patches to the LRGDM Postgres database.

Reads `reports/deep-dives/<person_id>.md`, parses every fenced JSON block
tagged ```json deep-dive-patch, validates the patch set, and on --apply
writes new Places + Events + EventParticipants and updates People rows.

Dry-run by default. Always shows the diff before committing. The derived map
layers are live SQL views, so there is no rebuild step. After --apply commits,
runs parse_dossiers.py to backfill provenance (sources/citations/narrative/
research leads) from the dossier.

Patch op types (schema documented in scripts/deep_dive_template.md):
  - upsert_place       — match by name (or create); generate PL-#### + WKB
  - insert_event       — new row in Events + optional EventParticipants
  - update_person      — set / append fields on an existing People row

Usage:
  python3 scripts/apply_deep_dive.py P-0001              # dry-run
  python3 scripts/apply_deep_dive.py P-0001 --apply      # commit
  python3 scripts/apply_deep_dive.py --dossier path.md   # explicit path
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path
from typing import Any

from psycopg.rows import dict_row, tuple_row

from lrgdm_db import connect

REPO = Path(__file__).resolve().parents[1]
DOSSIERS_DIR = REPO / "reports/deep-dives"
PARSE_DOSSIERS = REPO / "scripts/parse_dossiers.py"

PATCH_BLOCK_RE = re.compile(
    r"```json\s+deep-dive-patch\s*\n(.*?)\n```",
    re.DOTALL,
)

VALID_OPS = {"upsert_place", "insert_event", "update_person"}

PERSON_SETTABLE = {
    "fs_id", "birth_date", "death_date",
    "branch", "life_confidence", "privacy_level", "sex",
}
PERSON_PLACE_REFS = {"birth_place_ref", "death_place_ref"}
PERSON_APPEND = {"notes_append", "source_summary_append"}
PERSON_PLACE_REF_COLUMN = {
    "birth_place_ref": "birth_place_id",
    "death_place_ref": "death_place_id",
}


# ---------------------------------------------------------------------------
# Parse + validate
# ---------------------------------------------------------------------------

@dataclass
class Plan:
    upsert_place: list[dict] = field(default_factory=list)
    insert_event: list[dict] = field(default_factory=list)
    update_person: list[dict] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)
    # Filled in during resolution:
    place_name_to_id: dict[str, str] = field(default_factory=dict)
    new_place_rows: list[dict] = field(default_factory=list)
    new_event_rows: list[dict] = field(default_factory=list)
    new_participant_rows: list[dict] = field(default_factory=list)
    person_updates: list[dict] = field(default_factory=list)


def parse_dossier(text: str) -> tuple[list[dict], list[str]]:
    """Return (patches, errors). One patch per fenced block."""
    patches: list[dict] = []
    errors: list[str] = []
    for i, m in enumerate(PATCH_BLOCK_RE.finditer(text), 1):
        raw = m.group(1).strip()
        try:
            obj = json.loads(raw)
        except json.JSONDecodeError as e:
            errors.append(f"patch block #{i}: invalid JSON — {e}")
            continue
        if not isinstance(obj, dict) or "op" not in obj:
            errors.append(f"patch block #{i}: missing 'op' field")
            continue
        if obj["op"] not in VALID_OPS:
            errors.append(f"patch block #{i}: unknown op '{obj['op']}'")
            continue
        obj["__block_index"] = i
        patches.append(obj)
    return patches, errors


def bucket_patches(patches: list[dict]) -> Plan:
    plan = Plan()
    for p in patches:
        op = p["op"]
        if op == "upsert_place":
            plan.upsert_place.append(p)
        elif op == "insert_event":
            plan.insert_event.append(p)
        elif op == "update_person":
            plan.update_person.append(p)
    return plan


def validate_shapes(plan: Plan) -> None:
    for p in plan.upsert_place:
        idx = p["__block_index"]
        if "place" not in p or not isinstance(p["place"], dict):
            plan.errors.append(f"upsert_place #{idx}: missing 'place' object")
            continue
        place = p["place"]
        for required in ("name",):
            if not place.get(required):
                plan.errors.append(
                    f"upsert_place #{idx}: place.{required} is required"
                )
        if "match" in p and not isinstance(p["match"], dict):
            plan.errors.append(f"upsert_place #{idx}: 'match' must be an object")

    for p in plan.insert_event:
        idx = p["__block_index"]
        ev = p.get("event")
        if not isinstance(ev, dict):
            plan.errors.append(f"insert_event #{idx}: missing 'event' object")
            continue
        for required in ("event_type", "date_start"):
            if not ev.get(required):
                plan.errors.append(
                    f"insert_event #{idx}: event.{required} is required"
                )
        place_ref = ev.get("place_ref")
        if place_ref is not None and not isinstance(place_ref, dict):
            plan.errors.append(
                f"insert_event #{idx}: event.place_ref must be object or null"
            )
        parts = p.get("participants", [])
        if not isinstance(parts, list):
            plan.errors.append(
                f"insert_event #{idx}: participants must be a list"
            )
        for j, part in enumerate(parts):
            if not isinstance(part, dict) or not part.get("person_id"):
                plan.errors.append(
                    f"insert_event #{idx}: participant[{j}] needs person_id"
                )

    for p in plan.update_person:
        idx = p["__block_index"]
        if not p.get("person_id"):
            plan.errors.append(f"update_person #{idx}: person_id required")
            continue
        s = p.get("set", {})
        if not isinstance(s, dict) or not s:
            plan.errors.append(f"update_person #{idx}: 'set' must be non-empty object")
            continue
        unknown = (
            set(s.keys())
            - PERSON_SETTABLE
            - PERSON_PLACE_REFS
            - PERSON_APPEND
        )
        if unknown:
            plan.errors.append(
                f"update_person #{idx}: unknown set keys {sorted(unknown)}"
            )


# ---------------------------------------------------------------------------
# Resolve place_refs against the live Postgres `place` table (the database)
# ---------------------------------------------------------------------------

def _norm(s: str | None) -> str:
    return (s or "").strip().casefold()


def _next_id(conn, table: str, col: str, prefix: str, width: int) -> str:
    """Return the next free ID like 'PL-####' or 'E-####' (Postgres)."""
    n = conn.execute(
        f"SELECT COALESCE(MAX(substring({col} FROM '[0-9]+$')::int), 0) + 1 "
        f"FROM {table} WHERE {col} ~ %s",
        (f"^{prefix}[0-9]+$",),
    ).fetchone()[0]
    return f"{prefix}{n:0{width}d}"


def resolve_places(conn, plan: Plan) -> None:
    """Build plan.place_name_to_id and plan.new_place_rows.

    For each upsert_place op:
      - Try to match an existing Places row by normalized name (head + full).
      - If matched, link to that place_id (no insert).
      - Else, generate the next PL-#### and queue a new row.

    Then for every event with a place_ref, resolve it against the same map.
    Any unresolved ref is an error.
    """
    existing: dict[str, str] = {}
    for pid, name, std_name in conn.execute(
        "SELECT place_id, name, std_name FROM place"
    ):
        if name:
            existing[_norm(name)] = pid
        if std_name:
            existing.setdefault(_norm(std_name), pid)

    next_id = lambda: _next_id(conn, "place", "place_id", "PL-", 4)
    # Track allocations within this run so consecutive new places don't
    # collide (we haven't committed yet so _next_id keeps returning the same).
    allocated: set[str] = set()

    def take_next() -> str:
        candidate = next_id()
        while candidate in allocated:
            m = re.search(r"(\d+)$", candidate)
            n = int(m.group(1)) + 1
            candidate = f"PL-{n:04d}"
        allocated.add(candidate)
        return candidate

    for p in plan.upsert_place:
        place = p["place"]
        match_key = _norm((p.get("match") or {}).get("name") or place["name"])
        canonical_key = _norm(place["name"])
        std_key = _norm(place.get("std_name"))
        hit = (
            existing.get(match_key)
            or existing.get(canonical_key)
            or (existing.get(std_key) if std_key else None)
        )
        if hit:
            plan.place_name_to_id[canonical_key] = hit
            if match_key:
                plan.place_name_to_id[match_key] = hit
            continue
        # New place.
        new_pid = take_next()
        plan.place_name_to_id[canonical_key] = new_pid
        if match_key:
            plan.place_name_to_id[match_key] = new_pid
        # Lat/long feed geom (built in SQL via ST_MakePoint at insert time).
        lat = place.get("lat")
        lon = place.get("long")
        if lat is None and lon is None:
            plan.errors.append(
                f"upsert_place #{p['__block_index']}: '{place['name']}' has no "
                f"lat/long; can't build geometry. Provide coords or match an "
                f"existing place."
            )
        elif not (isinstance(lat, (int, float)) and isinstance(lon, (int, float))):
            plan.errors.append(
                f"upsert_place #{p['__block_index']}: lat/long must both be numeric"
            )
        plan.new_place_rows.append({
            "place_id": new_pid,
            "name": place["name"],
            "std_name": place.get("std_name") or place["name"],
            "lat": lat,
            "long": lon,
            "admin_hierarchy": place.get("admin_hierarchy"),
            "geocode_quality": place.get("geocode_quality") or "unknown",
            "notes": place.get("notes"),
        })

    # Resolve event place_refs.
    for p in plan.insert_event:
        ev = p.get("event") or {}
        ref = ev.get("place_ref")
        if not ref:
            continue
        key = _norm(ref.get("name"))
        if not key:
            plan.errors.append(
                f"insert_event #{p['__block_index']}: place_ref needs 'name'"
            )
            continue
        resolved = plan.place_name_to_id.get(key) or existing.get(key)
        if not resolved:
            plan.errors.append(
                f"insert_event #{p['__block_index']}: place_ref '{ref['name']}' "
                f"doesn't match any existing Place and no upsert_place patch "
                f"creates it in this dossier."
            )
            continue
        ev["__resolved_place_id"] = resolved

    # Resolve person_ref places on update_person.
    for p in plan.update_person:
        s = p.get("set", {})
        for ref_key in PERSON_PLACE_REFS:
            if ref_key not in s:
                continue
            v = s[ref_key]
            if v is None:
                p.setdefault("__resolved_place_ids", {})[ref_key] = None
                continue
            if not isinstance(v, dict) or not v.get("name"):
                plan.errors.append(
                    f"update_person #{p['__block_index']}: {ref_key} must be "
                    f"object with 'name' or null"
                )
                continue
            key = _norm(v["name"])
            resolved = plan.place_name_to_id.get(key) or existing.get(key)
            if not resolved:
                plan.errors.append(
                    f"update_person #{p['__block_index']}: {ref_key}.name "
                    f"'{v['name']}' doesn't match any existing or upserted Place"
                )
                continue
            p.setdefault("__resolved_place_ids", {})[ref_key] = resolved


def resolve_events(conn, plan: Plan) -> None:
    """Renumber dossier E-DD-* IDs to next free E-####, build participant rows."""
    allocated: set[str] = set()

    def take_next() -> str:
        candidate = _next_id(conn, "event", "event_id", "E-", 4)
        while candidate in allocated:
            m = re.search(r"(\d+)$", candidate)
            n = int(m.group(1)) + 1
            candidate = f"E-{n:04d}"
        allocated.add(candidate)
        return candidate

    # Cache valid person_ids so we can flag bad participants.
    valid_people = {r[0] for r in conn.execute("SELECT person_id FROM person")}

    for p in plan.insert_event:
        ev = p["event"]
        new_eid = take_next()
        plan.new_event_rows.append({
            "event_id": new_eid,
            "title": ev.get("title"),
            "event_type": ev.get("event_type"),
            "date_start": ev.get("date_start"),
            "date_end": ev.get("date_end"),
            "date_granularity": ev.get("date_granularity"),
            "place_id": ev.get("__resolved_place_id"),
            "importance": ev.get("importance"),
            "confidence": ev.get("confidence"),
            "description": ev.get("description"),
            "privacy_level": ev.get("privacy_level"),
            "notes": ev.get("notes"),
            "PID_People": None,  # use EventParticipants instead
        })
        for part in p.get("participants", []):
            pid = part.get("person_id")
            if pid not in valid_people:
                plan.errors.append(
                    f"insert_event #{p['__block_index']}: participant person_id "
                    f"'{pid}' not found in People"
                )
                continue
            plan.new_participant_rows.append({
                "event_id": new_eid,
                "person_id": pid,
                "role": part.get("role"),
                "event_type": ev.get("event_type"),
                "title": ev.get("title"),
                "date_start": ev.get("date_start"),
                "date_end": ev.get("date_end"),
                "place_id": ev.get("__resolved_place_id"),
            })


def resolve_person_updates(conn, plan: Plan) -> None:
    """Build the SQL update payloads, including append-to-existing logic."""
    by_pid: dict[str, dict] = {}
    with conn.cursor(row_factory=dict_row) as dcur:
        dcur.execute("SELECT person_id, notes, source_summary, sex FROM person")
        for r in dcur.fetchall():
            by_pid[r["person_id"]] = dict(r)

    for p in plan.update_person:
        pid = p["person_id"]
        if pid not in by_pid:
            plan.errors.append(
                f"update_person #{p['__block_index']}: person_id '{pid}' not in People"
            )
            continue
        current = by_pid[pid]
        s = p["set"]
        updates: dict[str, Any] = {}

        for k in PERSON_SETTABLE:
            if k not in s:
                continue
            if k == "sex" and current.get("sex"):
                # Don't overwrite a non-null sex — template said so.
                continue
            updates[k] = s[k]

        for k in PERSON_PLACE_REFS:
            if k in s:
                col = PERSON_PLACE_REF_COLUMN[k]
                updates[col] = (p.get("__resolved_place_ids") or {}).get(k)

        if "notes_append" in s and s["notes_append"]:
            tag = f"[deep-dive {date.today().isoformat()}]"
            # Idempotent: don't double-prepend if the dossier text already carries a tag.
            raw = re.sub(r"^\[deep-dive \d{4}-\d{2}-\d{2}\]\s*", "", s["notes_append"].strip())
            line = f"{tag} {raw}".strip()
            existing = (current.get("notes") or "").strip()
            updates["notes"] = f"{existing}\n{line}".strip() if existing else line

        if "source_summary_append" in s and s["source_summary_append"]:
            line = s["source_summary_append"].strip()
            existing = (current.get("source_summary") or "").strip()
            updates["source_summary"] = (
                f"{existing}; {line}".strip("; ") if existing else line
            )

        if not updates:
            # Nothing actionable (maybe all keys were no-ops); skip silently.
            continue

        plan.person_updates.append({
            "person_id": pid,
            "columns": updates,
            "block_index": p["__block_index"],
        })


# ---------------------------------------------------------------------------
# Apply
# ---------------------------------------------------------------------------

def apply_plan(conn, plan: Plan) -> dict:
    cur = conn.cursor()

    # --- Insert new places (geom built from lat/long via PostGIS) ---
    for row in plan.new_place_rows:
        cur.execute(
            "INSERT INTO place "
            "(place_id, name, std_name, geom, admin_hierarchy, geocode_quality, notes) "
            "VALUES (%s, %s, %s, "
            "  CASE WHEN %s IS NOT NULL AND %s IS NOT NULL "
            "       THEN ST_SetSRID(ST_MakePoint(%s, %s), 4326) END, "
            "  %s, %s, %s)",
            (
                row["place_id"], row["name"], row["std_name"],
                row["long"], row["lat"], row["long"], row["lat"],
                row["admin_hierarchy"], row["geocode_quality"], row["notes"],
            ),
        )

    # --- Insert new events (no PID_People; participants are separate) ---
    for row in plan.new_event_rows:
        cur.execute(
            "INSERT INTO event "
            "(event_id, title, event_type, date_start, date_end, date_granularity, "
            " place_id, importance, confidence, description, privacy_level, notes) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            (
                row["event_id"], row["title"], row["event_type"],
                row["date_start"], row["date_end"], row["date_granularity"],
                row["place_id"], row["importance"], row["confidence"],
                row["description"], row["privacy_level"], row["notes"],
            ),
        )

    # --- Insert event participants (slim: event_id, person_id, role) ---
    for row in plan.new_participant_rows:
        cur.execute(
            "INSERT INTO event_participant (event_id, person_id, role) "
            "VALUES (%s, %s, %s) "
            "ON CONFLICT (event_id, person_id, role) DO NOTHING",
            (row["event_id"], row["person_id"], row["role"]),
        )

    # --- Update person ---
    for up in plan.person_updates:
        cols = up["columns"]
        if not cols:
            continue
        set_clause = ", ".join(f"{c} = %s" for c in cols)
        params = list(cols.values()) + [up["person_id"]]
        cur.execute(f"UPDATE person SET {set_clause} WHERE person_id = %s", params)

    conn.commit()

    return {
        "places_inserted": len(plan.new_place_rows),
        "events_inserted": len(plan.new_event_rows),
        "participants_inserted": len(plan.new_participant_rows),
        "people_updated": len(plan.person_updates),
    }


# ---------------------------------------------------------------------------
# CLI / orchestration
# ---------------------------------------------------------------------------

def find_dossier(person_id: str | None, explicit: Path | None) -> Path:
    if explicit:
        return explicit
    if not person_id:
        raise SystemExit("Need a person_id (e.g. P-0001) or --dossier <path>")
    candidate = DOSSIERS_DIR / f"{person_id}.md"
    if not candidate.exists():
        raise SystemExit(f"No dossier at {candidate}")
    return candidate


def _rel(p: Path) -> str:
    try:
        return str(p.relative_to(REPO))
    except ValueError:
        return str(p)


def print_plan(plan: Plan, dossier: Path) -> None:
    print(f"== Deep-dive apply plan ==")
    print(f"Dossier  : {_rel(dossier)}")
    print(f"Places   : {len(plan.new_place_rows)} new, "
          f"{sum(1 for p in plan.upsert_place) - len(plan.new_place_rows)} "
          f"matched to existing")
    print(f"Events   : {len(plan.new_event_rows)} new")
    print(f"Parts.   : {len(plan.new_participant_rows)} EventParticipants rows")
    print(f"People   : {len(plan.person_updates)} update statements")
    if plan.new_place_rows:
        print("\n  New Places:")
        for r in plan.new_place_rows[:10]:
            print(f"    {r['place_id']:>9}  {r['name']}  "
                  f"({r['lat']}, {r['long']})  [{r['geocode_quality']}]")
        if len(plan.new_place_rows) > 10:
            print(f"    ... +{len(plan.new_place_rows) - 10} more")
    if plan.new_event_rows:
        print("\n  New Events:")
        for r in plan.new_event_rows[:10]:
            print(f"    {r['event_id']:>9}  {r['event_type']:>12}  "
                  f"{r['date_start'] or '?':>10}  {r['title'] or ''}")
        if len(plan.new_event_rows) > 10:
            print(f"    ... +{len(plan.new_event_rows) - 10} more")
    if plan.person_updates:
        print("\n  Person updates:")
        for u in plan.person_updates:
            cols = ", ".join(f"{c}=…" for c in u["columns"])
            print(f"    {u['person_id']}: {cols}")
    if plan.errors:
        print("\n!! Validation errors (apply blocked):")
        for e in plan.errors:
            print(f"   - {e}")


def backfill_provenance(person_id: str | None) -> int:
    """Run parse_dossiers.py for this person so the dossier's §3 facts become
    source/citation rows and §5/§6 become narrative/research_lead. Derived map
    layers are live SQL views — no rebuild step is needed."""
    if not PARSE_DOSSIERS.exists() or not person_id:
        return 0
    cmd = [sys.executable, str(PARSE_DOSSIERS), person_id]
    print(f"\n+ {' '.join(cmd)}")
    return subprocess.call(cmd, cwd=REPO)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("person_id", nargs="?", help="e.g. P-0001")
    ap.add_argument("--dossier", type=Path, help="Explicit path to dossier .md")
    ap.add_argument("--apply", action="store_true",
                    help="Commit changes (default is dry-run).")
    ap.add_argument("--no-backfill", action="store_true",
                    help="Skip the parse_dossiers provenance backfill after apply.")
    args = ap.parse_args()

    dossier = find_dossier(args.person_id, args.dossier)
    text = dossier.read_text(encoding="utf-8")
    patches, parse_errors = parse_dossier(text)
    if not patches:
        print(f"No deep-dive-patch blocks found in {dossier}")
        for e in parse_errors:
            print(f"  - {e}")
        return 0 if not parse_errors else 2

    plan = bucket_patches(patches)
    plan.errors.extend(parse_errors)
    validate_shapes(plan)

    conn = connect(row_factory=tuple_row)
    resolve_places(conn, plan)
    resolve_events(conn, plan)
    resolve_person_updates(conn, plan)

    print_plan(plan, dossier)

    if plan.errors:
        conn.close()
        return 2

    if not args.apply:
        print("\n(dry-run) pass --apply to commit.")
        conn.close()
        return 0

    print("\n(Tip: run scripts/backup_db.sh first for a pg_dump snapshot. "
          "This apply is transactional — it rolls back on error.)")
    summary = apply_plan(conn, plan)
    conn.close()

    print("\n== APPLIED ==")
    for k, v in summary.items():
        print(f"  {k}: {v}")

    pid = args.person_id or dossier.stem
    if not args.no_backfill:
        rc = backfill_provenance(pid)
        if rc != 0:
            print(f"\nWARN: provenance backfill exited with code {rc}")
            return rc
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
