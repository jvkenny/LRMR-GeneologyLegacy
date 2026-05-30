# media/_inbox — raw scan staging area

Drop raw scans / photos of historical documents here (e.g. the June 7 records
scan). This is a **staging area**, not storage.

## How it works

1. Drop image / PDF files into this folder.
2. Run the **`lrgdm-ingest-scans`** skill in a Claude Code session. It reads each
   file with the Read tool (vision), transcribes it, extracts structured fields,
   and writes a review sidecar (`<scan_id>.json` + `<scan_id>.md`) to
   `reports/scan_queue/`.
3. Review / correct the sidecar, flip `status` to `"approved"`, then run
   `python3 scripts/apply_scan.py <scan_id> --apply`. That deterministic writer
   creates the `source` / `media` / `media_link` / `citation` rows and stores
   the original (locally under `media/<source_id>/` or in blob storage).

## Originals are NOT committed

The binaries dropped here are **not** version-controlled — `.gitignore` excludes
image / PDF binaries under `media/_inbox/` (only this README and `.gitkeep` are
tracked). Once a scan is applied, `apply_scan.py` copies the original into its
permanent home (`media/<source_id>/`, which **is** Git LFS-tracked) or uploads it
to blob storage. After a scan is applied you can delete it from the inbox.

The inbox is intentionally not LFS-tracked: it is a scratch drop-zone, not the
durable media store.
