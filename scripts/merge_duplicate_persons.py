#!/usr/bin/env python3
"""Merge known duplicate People rows.

Each merge: keep the row with `fs_id` set (FamilySearch is the canonical
identity), copy missing fields (notes, source_summary) from the loser into
the winner, repoint all FKs (Events.PID_People, EventParticipants.person_id,
Relationships.person_id_a, person_id_b) to the winner, then delete the loser.

Merges:
  P-0005 (Benjamin Reed)     -> P-0040 (LZDK-YP8)
  P-0006 (Sarah Dickerson)   -> P-0041 (991N-J11)

Use --dry-run (default) to plan, --apply to commit.
"""
from __future__ import annotations

import argparse
import sqlite3
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GPKG = REPO / "src/data/lrgdm_v2.gpkg"

MERGES = [
    {"loser": "P-0005", "winner": "P-0040", "label": "Benjamin Reed"},
    {"loser": "P-0006", "winner": "P-0041", "label": "Sarah Dickerson"},
]


def _capture_and_drop_triggers(cur, tables):
    captured = []
    for t in tables:
        for n, s in cur.execute(
            "SELECT name, sql FROM sqlite_master WHERE type='trigger' AND tbl_name=?", (t,),
        ):
            captured.append((n, s))
    for n, _ in captured:
        cur.execute(f'DROP TRIGGER IF EXISTS "{n}"')
    return captured


def _recreate(cur, captured):
    for _, sql in captured:
        if sql:
            cur.execute(sql)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    if not GPKG.exists():
        print(f"GPKG not found: {GPKG}", file=sys.stderr)
        return 1
    conn = sqlite3.connect(GPKG)
    cur = conn.cursor()

    for m in MERGES:
        loser, winner = m["loser"], m["winner"]
        l = cur.execute(
            "SELECT person_id, primary_name, notes, source_summary, birth_place_id, death_place_id "
            "FROM People WHERE person_id=?",
            (loser,),
        ).fetchone()
        w = cur.execute(
            "SELECT person_id, primary_name, notes, source_summary, birth_place_id, death_place_id, fs_id "
            "FROM People WHERE person_id=?",
            (winner,),
        ).fetchone()
        if not l or not w:
            print(f"  skip {m['label']}: loser or winner missing", file=sys.stderr)
            continue
        print(f"\n== Merge: {m['label']} ==")
        print(f"  loser  {l[0]}: notes={l[2]!r} source={l[3]!r} birth_pl={l[4]} death_pl={l[5]}")
        print(f"  winner {w[0]}: notes={w[2]!r} source={w[3]!r} birth_pl={w[4]} death_pl={w[5]} fs_id={w[6]}")
        # Plan: merge notes/source if winner is blank
        merged_notes = w[2] or l[2]
        merged_source = w[3] or l[3]
        ev_refs = cur.execute("SELECT COUNT(*) FROM Events WHERE PID_People=?", (loser,)).fetchone()[0]
        ep_refs = cur.execute("SELECT COUNT(*) FROM EventParticipants WHERE person_id=?", (loser,)).fetchone()[0]
        rel_refs = cur.execute(
            "SELECT COUNT(*) FROM Relationships WHERE person_id_a=? OR person_id_b=?", (loser, loser),
        ).fetchone()[0]
        print(f"  will repoint: Events.PID_People={ev_refs}, EventParticipants={ep_refs}, Relationships={rel_refs}")
        print(f"  will set winner.notes={merged_notes!r}")
        print(f"  will set winner.source_summary={merged_source!r}")

    if not args.apply:
        print("\n(dry-run) pass --apply to commit.")
        return 0

    saved = _capture_and_drop_triggers(cur, ["People", "Events"])
    for m in MERGES:
        loser, winner = m["loser"], m["winner"]
        l = cur.execute(
            "SELECT notes, source_summary FROM People WHERE person_id=?", (loser,),
        ).fetchone()
        if not l:
            continue
        # Backfill winner fields if blank
        cur.execute(
            "UPDATE People SET "
            "  notes = COALESCE(NULLIF(TRIM(COALESCE(notes,'')),''), ?), "
            "  source_summary = COALESCE(NULLIF(TRIM(COALESCE(source_summary,'')),''), ?) "
            "WHERE person_id = ?",
            (l[0], l[1], winner),
        )
        # Repoint FKs
        cur.execute("UPDATE Events SET PID_People=? WHERE PID_People=?", (winner, loser))
        cur.execute("UPDATE EventParticipants SET person_id=? WHERE person_id=?", (winner, loser))
        cur.execute("UPDATE Relationships SET person_id_a=? WHERE person_id_a=?", (winner, loser))
        cur.execute("UPDATE Relationships SET person_id_b=? WHERE person_id_b=?", (winner, loser))
        # Delete loser
        cur.execute("DELETE FROM People WHERE person_id=?", (loser,))
    _recreate(cur, saved)

    # Also set the still-missing branch on P-0037 (Maternal Reed lineage via Karen Reed)
    cur.execute(
        "UPDATE People SET branch='Maternal Reed' WHERE person_id='P-0037' AND (branch IS NULL OR branch='')"
    )

    conn.commit()
    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
