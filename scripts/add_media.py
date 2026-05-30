#!/usr/bin/env python3
"""Add a media file (scan / photo / PDF) to the LRGDM database.

Copies the file into media/<subject_id>/, records it in the `media` table
(with sha256 / size / mime), and links it to a person / event / place / source
via `media_link`. Dedupes by sha256 — re-adding the same bytes reuses the
existing media row and just adds the link.

Usage:
  python3 scripts/add_media.py FILE --link SUBJECT --role ROLE [opts]

  SUBJECT = <type>:<id>, e.g.  person:P-0056  source:S-0001  place:PL-5244
  ROLE    = portrait | document_scan | headstone | gallery | ...

Options:
  --title TEXT     --caption TEXT     --captured-date TEXT (e.g. 1956)
  --type TYPE      override media_type (image|scan|pdf|audio|video)
  --dry-run        show what would happen, write nothing

Examples:
  python3 scripts/add_media.py ~/scans/john_dd214.pdf \
      --link person:P-0056 --role document_scan --title "DD-214" --type scan
  python3 scripts/add_media.py ~/photos/leah.jpg \
      --link person:P-0055 --role portrait

Connection: $LRGDM_PG (libpq conninfo), default "dbname=lrgdm".
"""
from __future__ import annotations

import argparse
import hashlib
import mimetypes
import os
import re
import shutil
import sys
from pathlib import Path

import psycopg

REPO = Path(__file__).resolve().parents[1]
MEDIA_DIR = REPO / "media"
CONNINFO = os.environ.get("LRGDM_PG", "dbname=lrgdm")

SUBJECT_TABLE = {
    "person": ("person", "person_id"),
    "event": ("event", "event_id"),
    "place": ("place", "place_id"),
    "source": ("source", "source_id"),
}


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def media_type_for(mime: str | None, ext: str) -> str:
    if mime:
        if mime.startswith("image/"):
            return "image"
        if mime == "application/pdf":
            return "pdf"
        if mime.startswith("audio/"):
            return "audio"
        if mime.startswith("video/"):
            return "video"
    return {"tif": "scan", "tiff": "scan", "pdf": "pdf"}.get(ext.lower(), "image")


def next_media_id(cur) -> str:
    cur.execute(
        "SELECT COALESCE(MAX(substring(media_id FROM 3)::int), 0) + 1 FROM media "
        "WHERE media_id ~ '^M-[0-9]+$'"
    )
    return f"M-{cur.fetchone()[0]:04d}"


def main() -> int:
    ap = argparse.ArgumentParser(description="Add a media file to the LRGDM DB.")
    ap.add_argument("file", type=Path)
    ap.add_argument("--link", required=True, help="<type>:<id>, e.g. person:P-0056")
    ap.add_argument("--role", default="gallery")
    ap.add_argument("--title")
    ap.add_argument("--caption")
    ap.add_argument("--captured-date", dest="captured_date")
    ap.add_argument("--type", dest="media_type")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    src = args.file.expanduser()
    if not src.is_file():
        print(f"ERROR: not a file: {src}", file=sys.stderr)
        return 1
    if ":" not in args.link:
        print("ERROR: --link must be <type>:<id> (e.g. person:P-0056)", file=sys.stderr)
        return 1
    subj_type, subj_id = args.link.split(":", 1)
    if subj_type not in SUBJECT_TABLE:
        print(f"ERROR: subject type must be one of {list(SUBJECT_TABLE)}", file=sys.stderr)
        return 1

    digest = sha256_of(src)
    size = src.stat().st_size
    ext = src.suffix.lstrip(".")
    mime, _ = mimetypes.guess_type(src.name)
    mtype = args.media_type or media_type_for(mime, ext)
    safe_name = re.sub(r"[^A-Za-z0-9._-]", "_", src.name)

    with psycopg.connect(CONNINFO) as con:
        cur = con.cursor()

        table, idcol = SUBJECT_TABLE[subj_type]
        cur.execute(f"SELECT 1 FROM {table} WHERE {idcol} = %s", (subj_id,))
        if not cur.fetchone():
            print(f"ERROR: {subj_type} {subj_id} not found in {table}", file=sys.stderr)
            return 1

        # dedupe by content
        cur.execute("SELECT media_id, file_path FROM media WHERE sha256 = %s", (digest,))
        existing = cur.fetchone()
        if existing:
            media_id, dest_rel = existing[0], existing[1]
            print(f"= media exists ({media_id}, same sha256) — reusing, adding link only")
            new_media = False
        else:
            media_id = next_media_id(cur)
            dest_rel = f"media/{subj_id}/{safe_name}"
            new_media = True

        print(f"  file        {src}")
        print(f"  media_id    {media_id}  ({mtype}, {size} bytes, sha {digest[:12]}…)")
        print(f"  stored at   {dest_rel}")
        print(f"  link        {subj_type}:{subj_id}  role={args.role}")

        if args.dry_run:
            print("(dry-run) nothing written.")
            return 0

        if new_media:
            dest = REPO / dest_rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dest)
            cur.execute(
                """INSERT INTO media (media_id, media_type, title, caption, file_path,
                                      mime_type, sha256, bytes, captured_date)
                   VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
                (media_id, mtype, args.title, args.caption, dest_rel,
                 mime, digest, size, args.captured_date),
            )

        cur.execute(
            """INSERT INTO media_link (media_id, subject_type, subject_id, role)
               VALUES (%s,%s,%s,%s)
               ON CONFLICT (media_id, subject_type, subject_id, role) DO NOTHING""",
            (media_id, subj_type, subj_id, args.role),
        )
        con.commit()
        print(f"✓ linked {media_id} → {subj_type}:{subj_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
