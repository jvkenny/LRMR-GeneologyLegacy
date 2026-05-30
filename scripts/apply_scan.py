#!/usr/bin/env python3
"""Apply an approved scan review-sidecar to the LRGDM Postgres database.

Phase-0 of the document-digitization ingest pipeline. Reads an approved review
JSON from ``reports/scan_queue/<scan_id>.json`` (written by the
``lrgdm-ingest-scans`` skill, which does the vision/transcription work), then
deterministically — **no model calls** — writes the provenance rows and stores
the original artifact:

  1. mints / upserts a ``source`` row (sequential ``S-####``),
  2. dedupes the inbox file by sha256 against ``media``; mints ``M-####`` if new,
  3. stores the original (local copy under ``media/<source_id>/`` OR a blob
     upload, depending on ``LRGDM_MEDIA_BACKEND``),
  4. inserts the ``media`` row,
  5. links media → the new source (default ``media_link``) plus any extra
     ``links[]``,
  6. inserts a ``citation`` row per ``citations[]`` entry (the polymorphic FK
     trigger validates each ``subject_id``).

Everything is one transaction; dry-run by default.

Usage:
  python3 scripts/apply_scan.py <scan_id>            # dry-run (default)
  python3 scripts/apply_scan.py <scan_id> --apply    # commit
  python3 scripts/apply_scan.py --all                # dry-run every approved sidecar
  python3 scripts/apply_scan.py --all --apply        # commit all approved sidecars

Storage backend (pluggable so this works before Azure exists):
  LRGDM_MEDIA_BACKEND = local (default) | blob
    local : copy into media/<source_id>/<safename>; media.file_path set, url NULL.
    blob  : upload via `az storage blob upload`; media.url = blob URL,
            media.file_path = blob key. Requires:
              LRGDM_BLOB_ACCOUNT     (storage account name)
              LRGDM_BLOB_CONTAINER   (container name)
              LRGDM_BLOB_PREFIX      (optional key prefix, e.g. "scans")
            If backend=blob but these are unset, FAILS CLEARLY (no silent fallback).

Examples:
  # Review then apply a single scanned marriage certificate:
  python3 scripts/apply_scan.py 1956-marriage-cert-kenny           # see the plan
  scripts/backup_db.sh                                             # snapshot first
  python3 scripts/apply_scan.py 1956-marriage-cert-kenny --apply   # commit

Connection: $LRGDM_PG (libpq conninfo), default "dbname=lrgdm" (via lrgdm_db).

Source-id scheme: sequential **S-####** (zero-padded), minted like media's
M-#### (MAX+1 over existing S-#### ids). Human-scanned home records have no
stable external URL to hash, so the sha1-hash style "S-XXXXXXXX" that
parse_dossiers.py uses for web sources is a poor fit here — a clean sequential
id reads better in the UI and never collides with the hash-style ids (different
character class). Upsert is by source_id, so re-applying a sidecar is idempotent
for the source row.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

from lrgdm_db import connect, next_id

REPO = Path(__file__).resolve().parents[1]
SCAN_QUEUE_DIR = REPO / "reports" / "scan_queue"
MEDIA_DIR = REPO / "media"

# media_link / citation subject targets (table, id-column) — mirrors add_media.
MEDIA_LINK_TABLE = {
    "person": ("person", "person_id"),
    "event": ("event", "event_id"),
    "place": ("place", "place_id"),
    "source": ("source", "source_id"),
}
CITATION_SUBJECTS = {"person", "event", "place", "relationship"}


# ---------------------------------------------------------------------------
# Helpers (mirror add_media.py patterns)
# ---------------------------------------------------------------------------

def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def next_source_id(cur) -> str:
    """Next sequential 4-digit S-#### id.

    Mirrors add_media's next_media_id, but deliberately scoped to *exactly four
    digits* (``^S-[0-9]{4}$``). parse_dossiers.py mints web-source ids as 8-char
    sha1 hashes (``S-XXXXXXXX``), some of which are all-numeric (e.g.
    ``S-41743962``); a naive ``^S-[0-9]+$`` MAX would treat those as sequence
    numbers and jump the counter into the millions. The 4-digit window keeps the
    two id spaces from interfering — hash ids are 8 chars, ours are 4.
    """
    cur.execute(
        "SELECT COALESCE(MAX(substring(source_id FROM 3)::int), 0) + 1 AS n "
        "FROM source WHERE source_id ~ '^S-[0-9]{4}$'"
    )
    row = cur.fetchone()
    n = row[0] if isinstance(row, (tuple, list)) else next(iter(row.values()))
    return f"S-{n:04d}"


def safe_name(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]", "_", name)


def _rel(p: Path) -> str:
    try:
        return str(p.relative_to(REPO))
    except ValueError:
        return str(p)


# ---------------------------------------------------------------------------
# Sidecar loading / validation
# ---------------------------------------------------------------------------

class SidecarError(Exception):
    pass


def load_sidecar(scan_id: str) -> dict[str, Any]:
    path = SCAN_QUEUE_DIR / f"{scan_id}.json"
    if not path.is_file():
        raise SidecarError(f"no sidecar at {_rel(path)}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        raise SidecarError(f"{_rel(path)}: invalid JSON — {e}") from e
    if not isinstance(data, dict):
        raise SidecarError(f"{_rel(path)}: top-level JSON must be an object")
    data.setdefault("scan_id", scan_id)
    return data


def validate_sidecar(data: dict[str, Any]) -> list[str]:
    """Static shape checks (no DB). Returns a list of error strings."""
    errs: list[str] = []
    scan = data.get("scan")
    if not isinstance(scan, dict) or not scan.get("inbox_file"):
        errs.append("scan.inbox_file is required")
    source = data.get("source")
    if not isinstance(source, dict):
        errs.append("source object is required")
    elif not source.get("title"):
        errs.append("source.title is required (NOT NULL)")
    media = data.get("media")
    if media is not None and not isinstance(media, dict):
        errs.append("media must be an object")

    for i, link in enumerate(data.get("links") or []):
        if not isinstance(link, dict):
            errs.append(f"links[{i}] must be an object")
            continue
        st = link.get("subject_type")
        if st not in MEDIA_LINK_TABLE:
            errs.append(f"links[{i}].subject_type must be one of {sorted(MEDIA_LINK_TABLE)}")
        if not link.get("subject_id"):
            errs.append(f"links[{i}].subject_id is required")

    for i, c in enumerate(data.get("citations") or []):
        if not isinstance(c, dict):
            errs.append(f"citations[{i}] must be an object")
            continue
        if c.get("subject_type") not in CITATION_SUBJECTS:
            errs.append(f"citations[{i}].subject_type must be one of {sorted(CITATION_SUBJECTS)}")
        if not c.get("subject_id"):
            errs.append(f"citations[{i}].subject_id is required")
        conf = c.get("confidence")
        if conf is not None and conf not in ("high", "med", "low"):
            errs.append(f"citations[{i}].confidence must be high|med|low or null")
    return errs


# ---------------------------------------------------------------------------
# Storage backends
# ---------------------------------------------------------------------------

def _blob_config() -> dict[str, str]:
    """Read + validate blob env. Raises SidecarError if backend=blob but unset."""
    account = os.environ.get("LRGDM_BLOB_ACCOUNT")
    container = os.environ.get("LRGDM_BLOB_CONTAINER")
    prefix = os.environ.get("LRGDM_BLOB_PREFIX", "").strip("/")
    missing = [n for n, v in (("LRGDM_BLOB_ACCOUNT", account),
                              ("LRGDM_BLOB_CONTAINER", container)) if not v]
    if missing:
        raise SidecarError(
            "LRGDM_MEDIA_BACKEND=blob but required env unset: "
            + ", ".join(missing)
            + ". Set them or use LRGDM_MEDIA_BACKEND=local. (No silent fallback.)"
        )
    return {"account": account, "container": container, "prefix": prefix}


def plan_storage(source_id: str, src: Path) -> dict[str, Any]:
    """Compute where the original will land, per the configured backend.

    Returns {backend, file_path, url, blob_key?} WITHOUT moving anything yet so
    the dry-run plan is accurate. Raises SidecarError on misconfiguration.
    """
    backend = os.environ.get("LRGDM_MEDIA_BACKEND", "local").lower()
    name = safe_name(src.name)
    if backend == "local":
        return {
            "backend": "local",
            "file_path": f"media/{source_id}/{name}",
            "url": None,
        }
    if backend == "blob":
        cfg = _blob_config()
        key_parts = [p for p in (cfg["prefix"], source_id, name) if p]
        blob_key = "/".join(key_parts)
        url = (
            f"https://{cfg['account']}.blob.core.windows.net/"
            f"{cfg['container']}/{blob_key}"
        )
        return {
            "backend": "blob",
            "file_path": blob_key,   # store the key in file_path
            "url": url,
            "blob_key": blob_key,
            "container": cfg["container"],
            "account": cfg["account"],
        }
    raise SidecarError(
        f"unknown LRGDM_MEDIA_BACKEND={backend!r} (use 'local' or 'blob')"
    )


def commit_storage(plan: dict[str, Any], src: Path) -> None:
    """Actually move/upload the original. Only called under --apply for new media."""
    if plan["backend"] == "local":
        dest = REPO / plan["file_path"]
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        return
    # blob: prefer azure-storage-blob if importable, else shell out to `az`.
    # This path is intentionally guarded — it can't be exercised until Azure
    # exists; local mode is the fully-tested default.
    try:
        from azure.storage.blob import BlobServiceClient  # type: ignore

        account_url = f"https://{plan['account']}.blob.core.windows.net"
        # Uses DefaultAzureCredential / connection via env; az login or
        # AZURE_STORAGE_CONNECTION_STRING expected to be configured.
        conn_str = os.environ.get("AZURE_STORAGE_CONNECTION_STRING")
        if conn_str:
            svc = BlobServiceClient.from_connection_string(conn_str)
        else:
            from azure.identity import DefaultAzureCredential  # type: ignore

            svc = BlobServiceClient(account_url, credential=DefaultAzureCredential())
        blob = svc.get_blob_client(container=plan["container"], blob=plan["blob_key"])
        with src.open("rb") as fh:
            blob.upload_blob(fh, overwrite=True)
        return
    except ImportError:
        pass
    # Fallback: shell out to the Azure CLI.
    cmd = [
        "az", "storage", "blob", "upload",
        "--account-name", plan["account"],
        "--container-name", plan["container"],
        "--name", plan["blob_key"],
        "--file", str(src),
        "--overwrite", "true",
    ]
    print(f"+ {' '.join(cmd)}")
    rc = subprocess.call(cmd)
    if rc != 0:
        raise SidecarError(f"`az storage blob upload` failed (exit {rc})")


# ---------------------------------------------------------------------------
# Per-scan processing
# ---------------------------------------------------------------------------

def media_type_for(mime: str | None, declared: str | None, ext: str) -> str:
    if declared in ("image", "scan", "pdf", "audio", "video"):
        return declared
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


def process(con, data: dict[str, Any], *, apply: bool) -> int:
    """Plan (and optionally apply) one sidecar. Returns 0 ok, non-zero on error.

    All writes happen inside the caller's transaction; we never commit here.
    """
    scan_id = data["scan_id"]
    print(f"\n== scan: {scan_id} ==")

    shape_errs = validate_sidecar(data)
    if shape_errs:
        print("!! sidecar errors (apply blocked):")
        for e in shape_errs:
            print(f"   - {e}")
        return 2

    status = data.get("status")
    scan = data["scan"]
    source = data["source"]
    media = data.get("media") or {}

    src = (REPO / scan["inbox_file"]).resolve()
    if not src.is_file():
        print(f"!! inbox file not found: {scan['inbox_file']}")
        return 2

    cur = con.cursor()

    # --- integrity: hash + size (recomputed, authoritative) ---
    digest = sha256_of(src)
    size = src.stat().st_size
    ext = src.suffix.lstrip(".")
    mime = scan.get("mime_type")
    mtype = media_type_for(mime, scan.get("media_type"), ext)

    # --- dedupe media by content (mirror add_media) ---
    cur.execute("SELECT media_id, file_path FROM media WHERE sha256 = %s", (digest,))
    row = cur.fetchone()
    existing_media = (row[0], row[1]) if row else None

    # --- mint source_id (sequential S-####) ---
    source_id = next_source_id(cur)

    # --- storage plan (must compute before printing) ---
    try:
        if existing_media:
            storage = {"backend": "(reuse)", "file_path": existing_media[1], "url": None}
        else:
            storage = plan_storage(source_id, src)
    except SidecarError as e:
        print(f"!! storage error: {e}")
        return 2

    if existing_media:
        media_id = existing_media[0]
        print(f"= media exists ({media_id}, same sha256) — reusing, no re-upload")
    else:
        media_id = next_id(cur, "media", "media_id", "M-")

    # --- plan printout ---
    stype = source.get("source_type") or "other"
    print(f"  source      {source_id}  [{stype}]  {source.get('title')}")
    print(f"  media       {media_id}  ({mtype}, {size} bytes, sha {digest[:12]}…)")
    print(f"  backend     {storage['backend']}")
    print(f"  stored at   {storage['file_path']}" + (f"  url={storage['url']}" if storage.get("url") else ""))
    default_role = media.get("role") or "document_scan"
    print(f"  link        media:{media_id} -> source:{source_id}  role={default_role}")
    for link in data.get("links") or []:
        print(f"  link        media:{media_id} -> {link['subject_type']}:{link['subject_id']}  role={link.get('role') or default_role}")
    cites = data.get("citations") or []
    print(f"  citations   {len(cites)} -> source:{source_id}")
    for c in cites:
        print(f"                {c['subject_type']}:{c['subject_id']} "
              f"[{c.get('subject_field') or 'whole'}] {c.get('confidence') or '?'} "
              f"{'(CONFLICT)' if c.get('conflicts_flag') else ''} — {(c.get('claim') or '')[:60]}")

    if not apply:
        if status != "approved":
            print(f"  status      {status!r} (must be \"approved\" before --apply)")
        print("  (dry-run) nothing written.")
        return 0

    # --- apply guard: only approved sidecars commit ---
    if status != "approved":
        print(f"!! status is {status!r}, not \"approved\" — refusing to apply. "
              "Review the sidecar and flip status, then re-run.")
        return 2

    # --- 1. upsert source (mirror parse_dossiers ON CONFLICT) ---
    cur.execute("INSERT INTO source_type (code) VALUES (%s) ON CONFLICT DO NOTHING", (stype,))
    notes = source.get("notes")
    transcription = (data.get("transcription") or "").strip()
    if transcription:
        block = f"[transcription {scan_id}]\n{transcription}"
        notes = f"{notes}\n\n{block}" if notes else block
    cur.execute(
        """INSERT INTO source (source_id, source_type, title, informant, repository,
                               url, citation, source_date, accessed_date, confidence, notes)
           VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
           ON CONFLICT (source_id) DO UPDATE SET
             source_type=EXCLUDED.source_type, title=EXCLUDED.title,
             informant=EXCLUDED.informant, repository=EXCLUDED.repository,
             url=EXCLUDED.url, citation=EXCLUDED.citation,
             source_date=EXCLUDED.source_date, accessed_date=EXCLUDED.accessed_date,
             confidence=EXCLUDED.confidence, notes=EXCLUDED.notes""",
        (source_id, stype, source.get("title"), source.get("informant"),
         source.get("repository"), source.get("url"), source.get("citation"),
         source.get("source_date"), source.get("accessed_date"),
         source.get("confidence"), notes),
    )

    # --- 2./3. store original + insert media (only if new) ---
    if not existing_media:
        commit_storage(storage, src)
        cur.execute(
            """INSERT INTO media (media_id, media_type, title, caption, file_path,
                                  url, mime_type, sha256, bytes, captured_date)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
            (media_id, mtype, media.get("title"), media.get("caption"),
             storage["file_path"], storage.get("url"), mime, digest, size,
             media.get("captured_date")),
        )

    # --- 4. default link media -> source, plus extra links ---
    cur.execute(
        """INSERT INTO media_link (media_id, subject_type, subject_id, role)
           VALUES (%s,'source',%s,%s)
           ON CONFLICT (media_id, subject_type, subject_id, role) DO NOTHING""",
        (media_id, source_id, default_role),
    )
    for link in data.get("links") or []:
        cur.execute(
            """INSERT INTO media_link (media_id, subject_type, subject_id, role)
               VALUES (%s,%s,%s,%s)
               ON CONFLICT (media_id, subject_type, subject_id, role) DO NOTHING""",
            (media_id, link["subject_type"], link["subject_id"],
             link.get("role") or default_role),
        )

    # --- 5. citations (polymorphic trigger validates subject_id) ---
    for c in cites:
        cur.execute(
            """INSERT INTO citation (source_id, subject_type, subject_id,
                                     subject_field, claim, confidence,
                                     conflicts_flag, locator)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s)""",
            (source_id, c["subject_type"], c["subject_id"], c.get("subject_field"),
             c.get("claim"), c.get("confidence"),
             bool(c.get("conflicts_flag", False)), c.get("locator")),
        )

    print(f"  ✓ applied {scan_id}: source {source_id}, media {media_id}, "
          f"{len(cites)} citation(s)")
    return 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def discover_scan_ids() -> list[str]:
    return sorted(p.stem for p in SCAN_QUEUE_DIR.glob("*.json"))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("scan_id", nargs="?", help="e.g. 1956-marriage-cert-kenny")
    ap.add_argument("--all", action="store_true",
                    help="Process every sidecar in reports/scan_queue/.")
    ap.add_argument("--apply", action="store_true",
                    help="Commit changes (default is dry-run).")
    args = ap.parse_args()

    if args.all and args.scan_id:
        print("ERROR: pass either <scan_id> or --all, not both", file=sys.stderr)
        return 1
    if not args.all and not args.scan_id:
        print("ERROR: pass a <scan_id> or --all", file=sys.stderr)
        return 1

    scan_ids = discover_scan_ids() if args.all else [args.scan_id]
    if not scan_ids:
        print("No sidecars in reports/scan_queue/.")
        return 1

    # Load + statically validate all before touching the DB.
    sidecars: list[dict[str, Any]] = []
    for sid in scan_ids:
        try:
            sidecars.append(load_sidecar(sid))
        except SidecarError as e:
            print(f"ERROR: {e}", file=sys.stderr)
            return 1

    if args.apply:
        print("(Tip: run scripts/backup_db.sh first for a pg_dump snapshot. "
              "This apply is one transaction — it rolls back on error.)")

    # Single transaction across all selected sidecars.
    con = connect()
    try:
        rc_total = 0
        for data in sidecars:
            rc = process(con, data, apply=args.apply)
            rc_total = rc_total or rc
        if args.apply and rc_total == 0:
            con.commit()
            print("\n== COMMITTED ==")
        elif args.apply:
            con.rollback()
            print("\n!! errors above — transaction rolled back, nothing written.")
        else:
            con.rollback()  # dry-run minted ids etc.; discard
            print("\n(dry-run) pass --apply to commit.")
        return rc_total
    finally:
        con.close()


if __name__ == "__main__":
    raise SystemExit(main())
