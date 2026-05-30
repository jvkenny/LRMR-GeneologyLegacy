#!/usr/bin/env python3
"""Auto-geocode People rows that have fs_id but no birth_place_id.

Reads the newest src/data/familysearch/extract_*.json and for each People row
with fs_id set but birth_place_id NULL, looks up the corresponding FS person.
If the FS record has birth.place + birth.lat/lon, either:
  - matches an existing Places row by normalized name, or
  - creates a new Places row using the FS coordinates.

Also handles death_place_id the same way (since fs_id-derived people often
have death info too).

Two-step protocol:
  default              writes reports/auto_geocode_<DATE>.{md,json}
  --apply              commit the place + person updates to Postgres

Derived map layers are live SQL views — no rebuild step.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from datetime import date
from pathlib import Path

from psycopg.rows import tuple_row

from lrgdm_db import connect

REPO = Path(__file__).resolve().parents[1]
EXTRACT_DIR = REPO / "src/data/familysearch"


def normalize_place(name: str | None) -> str:
    if not name:
        return ""
    s = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode().lower()
    s = re.sub(r"\b(united states|usa|u\.s\.|u\.s\.a\.)\b", "usa", s)
    s = re.sub(r"\s+", " ", s)
    s = re.sub(r"\s*,\s*", ", ", s)
    return s.strip()


def infer_place_quality(name: str) -> str:
    if not name:
        return "unknown"
    head = name.split(",", 1)[0].strip()
    if re.match(r"^\d+\s+[NSEW]?\s*[A-Za-z]", head):
        return "address"
    if re.search(r"cemetery", head, re.I):
        return "cemetery"
    if re.search(r"\bward\s+\d+", head, re.I):
        return "ward"
    if re.search(r"\btownship\b", head, re.I):
        return "township"
    if re.search(r"\bhundred\b$", head, re.I):
        return "township"
    if re.search(r"\bcounty\b", head, re.I):
        return "county"
    commas = name.count(",")
    if commas == 0:
        return "region"
    if commas >= 1:
        return "settlement"
    return "unknown"


def load_extract() -> dict:
    candidates = sorted(EXTRACT_DIR.glob("extract_*.json"))
    if not candidates:
        sys.exit(f"No FS extract found in {EXTRACT_DIR}")
    return json.loads(candidates[-1].read_text())


def next_id(conn, table: str, col: str, prefix: str) -> int:
    rows = list(conn.execute(f"SELECT {col} FROM {table} WHERE {col} LIKE %s", (f"{prefix}%",)))
    nums = []
    for r in rows:
        m = re.match(rf"{re.escape(prefix)}(\d+)$", r[0] or "")
        if m:
            nums.append(int(m.group(1)))
    return (max(nums) + 1) if nums else 1


def fmt_id(prefix: str, n: int, width: int = 4) -> str:
    return f"{prefix}{n:0{width}d}"


def plan(conn, extract: dict) -> dict:
    """Build the proposal: place matches, new places, and people updates."""
    fs_by_pid = {p["pid"]: p for p in extract["people"]}

    # Existing places, keyed by normalized name
    existing_places: dict[str, str] = {}
    for place_id, name in conn.execute("SELECT place_id, name FROM place"):
        if name:
            existing_places[normalize_place(name)] = place_id

    # People who need geocoding (fs_id set; birth_place_id OR death_place_id NULL)
    unmapped = list(conn.execute(
        "SELECT person_id, primary_name, fs_id, birth_place_id, death_place_id "
        "FROM person "
        "WHERE fs_id IS NOT NULL AND fs_id != '' "
        "  AND (birth_place_id IS NULL OR birth_place_id = '' "
        "       OR death_place_id IS NULL OR death_place_id = '')"
    ))

    next_pl = next_id(conn, "place", "place_id", "PL-")

    new_places: dict[str, dict] = {}    # keyed by normalized name
    people_updates: list[dict] = []
    no_fs_match: list[dict] = []
    no_place_in_fs: list[dict] = []

    def resolve(ev: dict | None) -> tuple[str | None, str]:
        """Return (place_id, reason) for an FS birth/death event."""
        nonlocal next_pl
        if not ev or not ev.get("place"):
            return None, "no place in FS"
        norm = normalize_place(ev["place"])
        if norm in existing_places:
            return existing_places[norm], f"matched existing `{existing_places[norm]}`"
        if norm in new_places:
            return new_places[norm]["place_id"], f"reused planned new `{new_places[norm]['place_id']}`"
        if ev.get("lat") is None or ev.get("lon") is None:
            return None, "no coords in FS"
        new_pid = fmt_id("PL-", next_pl)
        next_pl += 1
        new_places[norm] = {
            "place_id": new_pid,
            "name": ev["place"],
            "lat": float(ev["lat"]),
            "lon": float(ev["lon"]),
            "quality": infer_place_quality(ev["place"]),
        }
        return new_pid, f"created new `{new_pid}` from FS coords"

    for person_id, primary_name, fs_id, birth_place_id, death_place_id in unmapped:
        fs = fs_by_pid.get(fs_id)
        if not fs:
            no_fs_match.append({"person_id": person_id, "name": primary_name, "fs_id": fs_id})
            continue

        update: dict = {
            "person_id": person_id,
            "primary_name": primary_name,
            "fs_id": fs_id,
            "current_birth_place_id": birth_place_id,
            "current_death_place_id": death_place_id,
        }
        changed = False
        if not birth_place_id:
            pid, reason = resolve(fs.get("birth"))
            update["new_birth_place_id"] = pid
            update["birth_reason"] = reason
            if pid:
                changed = True
        if not death_place_id:
            # Prefer death.place; fall back to burial.place if death lacks coords.
            pid, reason = resolve(fs.get("death"))
            if not pid:
                burial = fs.get("burial")
                if burial and burial.get("place"):
                    pid2, reason2 = resolve(burial)
                    if pid2:
                        pid, reason = pid2, f"burial fallback: {reason2}"
            update["new_death_place_id"] = pid
            update["death_reason"] = reason
            if pid:
                changed = True

        if changed:
            people_updates.append(update)
        else:
            no_place_in_fs.append({
                "person_id": person_id,
                "name": primary_name,
                "fs_id": fs_id,
                "birth_reason": update.get("birth_reason"),
                "death_reason": update.get("death_reason"),
            })

    return {
        "people_updates": people_updates,
        "new_places": new_places,
        "no_fs_match": no_fs_match,
        "no_place_in_fs": no_place_in_fs,
        "unmapped_count": len(unmapped),
    }


def write_reports(plan_out: dict, today: str) -> tuple[Path, Path]:
    reports_dir = REPO / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)
    json_path = reports_dir / f"auto_geocode_{today}.json"
    md_path = reports_dir / f"auto_geocode_{today}.md"

    json_path.write_text(json.dumps({
        "generated": today,
        "unmapped_count": plan_out["unmapped_count"],
        "people_updates_count": len(plan_out["people_updates"]),
        "new_places_count": len(plan_out["new_places"]),
        "no_fs_match_count": len(plan_out["no_fs_match"]),
        "no_place_in_fs_count": len(plan_out["no_place_in_fs"]),
        "people_updates": plan_out["people_updates"],
        "new_places": list(plan_out["new_places"].values()),
        "no_fs_match": plan_out["no_fs_match"],
        "no_place_in_fs": plan_out["no_place_in_fs"],
    }, indent=2))

    lines = [
        f"# Auto-Geocode Proposal — {today}",
        "",
        f"- Unmapped People (fs_id set, birth/death place_id NULL): **{plan_out['unmapped_count']}**",
        f"- People to update: **{len(plan_out['people_updates'])}**",
        f"- New Places to create: **{len(plan_out['new_places'])}**",
        f"- People with fs_id missing from extract: **{len(plan_out['no_fs_match'])}**",
        f"- People with no place data in FS: **{len(plan_out['no_place_in_fs'])}**",
        "",
        "## People updates",
        "",
        "| person_id | name | fs_id | birth_place_id | birth reason | death_place_id | death reason |",
        "|---|---|---|---|---|---|---|",
    ]
    for u in plan_out["people_updates"]:
        bp = u.get("new_birth_place_id") or ""
        br = u.get("birth_reason") or ""
        dp = u.get("new_death_place_id") or ""
        dr = u.get("death_reason") or ""
        lines.append(
            f"| `{u['person_id']}` | {u['primary_name']} | `{u['fs_id']}` | "
            f"{('`'+bp+'`') if bp else ''} | {br} | {('`'+dp+'`') if dp else ''} | {dr} |"
        )

    if plan_out["new_places"]:
        lines += ["", "## New Places", "", "| place_id | name | lat | long | quality |", "|---|---|---|---|---|"]
        for pl in plan_out["new_places"].values():
            lines.append(
                f"| `{pl['place_id']}` | {pl['name']} | {pl['lat']} | {pl['lon']} | {pl['quality']} |"
            )

    if plan_out["no_fs_match"]:
        lines += ["", "## People with fs_id not in FS extract", ""]
        for r in plan_out["no_fs_match"]:
            lines.append(f"- `{r['person_id']}` {r['name']} — fs_id `{r['fs_id']}`")

    if plan_out["no_place_in_fs"]:
        lines += ["", "## People with no usable FS place", ""]
        for r in plan_out["no_place_in_fs"]:
            lines.append(
                f"- `{r['person_id']}` {r['name']} — birth: {r.get('birth_reason')} | death: {r.get('death_reason')}"
            )

    md_path.write_text("\n".join(lines))
    return md_path, json_path


def apply_plan(conn, plan_out: dict, today: str) -> dict:
    cur = conn.cursor()

    # Insert new places (geom built from lat/lon via PostGIS; place has no
    # lat/long columns — coordinates live in geom).
    for pl in plan_out["new_places"].values():
        cur.execute(
            "INSERT INTO place (place_id, name, std_name, geom, geocode_quality, notes) "
            "VALUES (%s, %s, %s, ST_SetSRID(ST_MakePoint(%s, %s), 4326), %s, %s)",
            (pl["place_id"], pl["name"], pl["name"], pl["lon"], pl["lat"],
             pl["quality"], f"Auto-geocoded from FS extract {today}"),
        )

    # Update person birth/death place refs
    for u in plan_out["people_updates"]:
        sets = []
        vals: list = []
        if u.get("new_birth_place_id"):
            sets.append("birth_place_id = %s")
            vals.append(u["new_birth_place_id"])
        if u.get("new_death_place_id"):
            sets.append("death_place_id = %s")
            vals.append(u["new_death_place_id"])
        if not sets:
            continue
        vals.append(u["person_id"])
        cur.execute(f"UPDATE person SET {', '.join(sets)} WHERE person_id = %s", vals)

    conn.commit()

    return {
        "new_places_inserted": len(plan_out["new_places"]),
        "people_updated": len(plan_out["people_updates"]),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    extract = load_extract()
    conn = connect(row_factory=tuple_row)
    plan_out = plan(conn, extract)

    today = date.today().isoformat()
    md, js = write_reports(plan_out, today)
    print(f"Wrote {md}")
    print(f"Wrote {js}")

    print("== PLAN ==")
    print(f"Unmapped People (fs_id, NULL place): {plan_out['unmapped_count']}")
    print(f"People to update                   : {len(plan_out['people_updates'])}")
    print(f"New Places to create               : {len(plan_out['new_places'])}")
    print(f"fs_id not in FS extract            : {len(plan_out['no_fs_match'])}")
    print(f"No usable FS place                 : {len(plan_out['no_place_in_fs'])}")

    if not args.apply:
        print("\n(dry-run) pass --apply to commit.")
        conn.close()
        return 0

    print("(Tip: run scripts/backup_db.sh first for a pg_dump snapshot.)")
    summary = apply_plan(conn, plan_out, today)
    conn.close()

    print("\n== APPLIED ==")
    for k, v in summary.items():
        print(f"  {k}: {v}")
    print("\nNext: run scripts/validate_gpkg.py. (Derived map layers are live views.)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
