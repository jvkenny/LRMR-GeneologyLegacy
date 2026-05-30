#!/usr/bin/env python3
"""Merge known duplicate People rows.

Each merge: keep the row with `fs_id` set (FamilySearch is the canonical
identity), but **prefer curated content from the loser** when the winner only
has FS-import boilerplate. Repoint all FKs (Events.PID_People,
EventParticipants.person_id, Relationships.person_id_a, person_id_b) to the
winner, then delete the loser.

Field preference rules per column:
  notes / source_summary
    - If winner's value is empty → use loser's
    - If winner's value starts with the FS-import boilerplate
      ("Imported from FamilySearch") and loser's value is set → use loser's
    - Otherwise keep winner's
  birth_date / death_date
    - If winner's value isn't ISO (e.g. "14 April 1878") and loser's is ISO
      ("1878-04-14") → use loser's
    - Otherwise keep winner's
  birth_place_id / death_place_id
    - If winner's value is NULL or points to a Places row that no longer
      exists, use loser's
    - Otherwise keep winner's (they may both be valid; QGIS edits later)

Use --dry-run (default) to plan, --apply to commit.
"""
from __future__ import annotations

import argparse
from psycopg.rows import tuple_row

from lrgdm_db import connect
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GPKG = REPO / "src/data/lrgdm.gpkg"

MERGES = [
    {"loser": "P-0005", "winner": "P-0040", "label": "Benjamin Reed"},
    {"loser": "P-0006", "winner": "P-0041", "label": "Sarah Dickerson"},
    # 14 dupes surfaced 2026-05-27: each is an original GPKG row (no fs_id)
    # colliding with the same person ingested fresh from the FS extract on
    # 2026-05-26. Winners are the fs-linked rows per the canonical-identity rule.
    {"loser": "P-0003", "winner": "P-0070", "label": "John Talley Reed"},
    {"loser": "P-0011", "winner": "P-0072", "label": "Abiram Stacy Lambert"},
    {"loser": "P-0014", "winner": "P-0092", "label": "Martha L. (Spear) Boles"},
    {"loser": "P-0015", "winner": "P-0138", "label": "Sherebiah Lambert Sr."},
    {"loser": "P-0017", "winner": "P-0105", "label": "Sherebiah Lambert Jr."},
    {"loser": "P-0021", "winner": "P-0064", "label": "John F. Zika"},
    {"loser": "P-0023", "winner": "P-0078", "label": "Paul Pouliot"},
    {"loser": "P-0024", "winner": "P-0076", "label": "Henriette Pouliot"},
    {"loser": "P-0026", "winner": "P-0094", "label": "Julie Audet dit Lapointe"},
    {"loser": "P-0029", "winner": "P-0062", "label": "Earl Wayne Reed"},
    {"loser": "P-0030", "winner": "P-0058", "label": "Isabelle (Zika) Reed"},
    {"loser": "P-0032", "winner": "P-0056", "label": "John R. Reed"},
    {"loser": "P-0034", "winner": "P-0061", "label": "John Foulk Reed"},
    {"loser": "P-0037", "winner": "P-0055", "label": "Leah Rae Mariotti"},
    # PL-0016 and PL-0158 are both Chicago variants (verified 2026-05-27),
    # so this merge is safe.
    {"loser": "P-0022", "winner": "P-0068", "label": "Beatrice Delina Pouliot"},
    # Surfaced by lrgdm-deep-dive-audit on P-0072 (2026-05-28). P-0009 is the
    # original GPKG row (no fs_id, wrong death year 1868); P-0084 is the
    # fs-linked row (fs_id L7XP-Y6P, correct dates 17 Jan 1790 – 15 Dec 1865).
    {"loser": "P-0009", "winner": "P-0084", "label": "David Lambert"},
    # Surfaced by lrgdm-deep-dive on P-0036 (2026-05-28 PM). REVERSE of the
    # usual pattern: both rows carry fs_id LMWG-K6F after the deep-dive apply
    # added it to P-0036. P-0036 is the curated row (ISO dates, 4
    # Relationships, 5+9 Event ties); P-0063 was the FS-extract stub with
    # zero downstream references. Winner = the curated row, loser = the stub.
    {"loser": "P-0063", "winner": "P-0036", "label": "Estelle Gertrude Lambert"},
]


FS_BOILERPLATE = "Imported from FamilySearch"
ISO_DATE = __import__("re").compile(r"^\d{4}-\d{2}-\d{2}$")


def _prefer_curated(winner_v, loser_v):
    """Return the better of two notes/source values.
    Prefers a non-empty curated value over FS-import boilerplate."""
    w = (winner_v or "").strip()
    l = (loser_v or "").strip()
    if not w:
        return l or None
    if w.startswith(FS_BOILERPLATE) and l and not l.startswith(FS_BOILERPLATE):
        return l
    return w


def _prefer_iso_date(winner_v, loser_v):
    """Return the better date value, preferring ISO over free-text."""
    w = (winner_v or "").strip()
    l = (loser_v or "").strip()
    if not w:
        return l or None
    if not ISO_DATE.match(w) and l and ISO_DATE.match(l):
        return l
    return w


def _prefer_resolvable_place(cur, winner_v, loser_v):
    """Return the better place_id, preferring one that resolves in Places."""
    if not winner_v:
        return loser_v
    n = cur.execute("SELECT COUNT(*) FROM place WHERE place_id=%s", (winner_v,)).fetchone()[0]
    if n == 0 and loser_v:
        nl = cur.execute("SELECT COUNT(*) FROM place WHERE place_id=%s", (loser_v,)).fetchone()[0]
        if nl > 0:
            return loser_v
    return winner_v


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()
    conn = connect(row_factory=tuple_row)
    cur = conn.cursor()

    plans = []  # cache merged values to reuse during --apply
    for m in MERGES:
        loser, winner = m["loser"], m["winner"]
        l = cur.execute(
            "SELECT person_id, primary_name, notes, source_summary, birth_date, death_date, "
            "       birth_place_id, death_place_id "
            "FROM person WHERE person_id=%s",
            (loser,),
        ).fetchone()
        w = cur.execute(
            "SELECT person_id, primary_name, notes, source_summary, birth_date, death_date, "
            "       birth_place_id, death_place_id, fs_id "
            "FROM person WHERE person_id=%s",
            (winner,),
        ).fetchone()
        if not l or not w:
            print(f"  skip {m['label']}: loser or winner missing", file=sys.stderr)
            plans.append(None)
            continue
        merged = {
            "notes":           _prefer_curated(w[2], l[2]),
            "source_summary":  _prefer_curated(w[3], l[3]),
            "birth_date":      _prefer_iso_date(w[4], l[4]),
            "death_date":      _prefer_iso_date(w[5], l[5]),
            "birth_place_id":  _prefer_resolvable_place(cur, w[6], l[6]),
            "death_place_id":  _prefer_resolvable_place(cur, w[7], l[7]),
        }
        ep_refs = cur.execute("SELECT COUNT(*) FROM event_participant WHERE person_id=%s", (loser,)).fetchone()[0]
        rel_refs = cur.execute(
            "SELECT COUNT(*) FROM relationship WHERE person_id_a=%s OR person_id_b=%s", (loser, loser),
        ).fetchone()[0]
        print(f"\n== Merge: {m['label']} ==")
        print(f"  loser  {l[0]}: notes={l[2]!r}")
        print(f"               source={l[3]!r} birth_date={l[4]!r} birth_pl={l[6]}")
        print(f"  winner {w[0]} (fs_id={w[8]!r})")
        print(f"               notes={w[2]!r}")
        print(f"               source={w[3]!r} birth_date={w[4]!r} birth_pl={w[6]}")
        print(f"  → repoint: event_participant={ep_refs}, relationship={rel_refs}")
        print(f"  → set winner.notes={merged['notes']!r}")
        print(f"  → set winner.source_summary={merged['source_summary']!r}")
        if merged['birth_date'] != w[4]:
            print(f"  → set winner.birth_date={merged['birth_date']!r}")
        if merged['death_date'] != w[5]:
            print(f"  → set winner.death_date={merged['death_date']!r}")
        if merged['birth_place_id'] != w[6]:
            print(f"  → set winner.birth_place_id={merged['birth_place_id']!r}")
        if merged['death_place_id'] != w[7]:
            print(f"  → set winner.death_place_id={merged['death_place_id']!r}")
        plans.append(merged)

    if not args.apply:
        print("\n(dry-run) pass --apply to commit.")
        return 0

    for m, merged in zip(MERGES, plans):
        if merged is None:
            continue
        loser, winner = m["loser"], m["winner"]
        # Repoint the loser's references to the winner first (FKs are enforced),
        # then delete the loser. ON CONFLICT guards the participant unique index.
        cur.execute(
            "UPDATE event_participant SET person_id=%s WHERE person_id=%s "
            "AND NOT EXISTS (SELECT 1 FROM event_participant e2 "
            "  WHERE e2.event_id=event_participant.event_id AND e2.person_id=%s "
            "  AND e2.role IS NOT DISTINCT FROM event_participant.role)",
            (winner, loser, winner),
        )
        cur.execute("DELETE FROM event_participant WHERE person_id=%s", (loser,))
        cur.execute("UPDATE relationship SET person_id_a=%s WHERE person_id_a=%s", (winner, loser))
        cur.execute("UPDATE relationship SET person_id_b=%s WHERE person_id_b=%s", (winner, loser))
        cur.execute(
            "UPDATE person SET "
            "  notes = %s, source_summary = %s, birth_date = %s, death_date = %s, "
            "  birth_place_id = %s, death_place_id = %s "
            "WHERE person_id = %s",
            (
                merged["notes"], merged["source_summary"],
                merged["birth_date"], merged["death_date"],
                merged["birth_place_id"], merged["death_place_id"],
                winner,
            ),
        )
        cur.execute("DELETE FROM person WHERE person_id=%s", (loser,))

    # Also set the still-missing branch on P-0037 (Maternal Reed lineage via Karen Reed)
    cur.execute(
        "UPDATE person SET branch='Maternal Reed' WHERE person_id='P-0037' AND (branch IS NULL OR branch='')"
    )

    conn.commit()
    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
