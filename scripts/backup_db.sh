#!/usr/bin/env bash
# Backup the LRGDM Postgres database BEFORE any change is made to it.
#
# Two-tier, by design:
#   1. LOCAL  : db/backups/lrgdm_<date>.sql  (plain SQL, git-diffable, latest-of-day)
#   2. AZURE  : uploaded to Blob container `db-backups/` with a UNIQUE timestamp
#               (lrgdm_<datetime>.sql) so every pre-change snapshot is retained
#               offsite. Blob does NOT need the Azure Postgres server running.
#
# This is the STANDARD pre-change backup. Every DB-mutating path (apply_scan.py,
# deep-dive apply, migrations, manual edits) should run this first. The Azure
# push is REQUIRED by default — honoring "always back up to Azure before changes".
#
# Env:
#   LRGDM_PGDB              db name (default: lrgdm)
#   LRGDM_BACKUP_SKIP_AZURE=1   skip the Azure push (offline escape hatch; loud warning)
#   .azure.env             sourced if present for LRGDM_BLOB_ACCOUNT (+ region/rg)
set -euo pipefail
cd "$(dirname "$0")/.."

DB="${LRGDM_PGDB:-lrgdm}"
DATE="$(date +%Y-%m-%d)"
DATETIME="$(date +%Y-%m-%dT%H%M%S)"
OUT="db/backups/lrgdm_${DATE}.sql"
mkdir -p db/backups

# --- 1. local dump ---
pg_dump -Fp --no-owner --exclude-table-data=spatial_ref_sys "$DB" > "$OUT"
echo "wrote $OUT ($(wc -l < "$OUT" | tr -d ' ') lines, $(du -h "$OUT" | cut -f1))"

# --- 2. push to Azure Blob (offsite, timestamped, retained) ---
if [ "${LRGDM_BACKUP_SKIP_AZURE:-0}" = "1" ]; then
  echo "!! LRGDM_BACKUP_SKIP_AZURE=1 — skipping Azure backup. Local-only snapshot." >&2
  exit 0
fi

[ -f .azure.env ] && { set -a; . ./.azure.env; set +a; }
ACCT="${LRGDM_BLOB_ACCOUNT:-}"
if [ -z "$ACCT" ]; then
  echo "ERROR: LRGDM_BLOB_ACCOUNT unset (no .azure.env?). Cannot back up to Azure." >&2
  echo "       Set LRGDM_BACKUP_SKIP_AZURE=1 to proceed local-only (NOT recommended)." >&2
  exit 1
fi

BLOB_KEY="lrgdm_${DATETIME}.sql"
if az storage blob upload \
     --account-name "$ACCT" --container-name db-backups \
     --name "$BLOB_KEY" --file "$OUT" --overwrite false -o none 2>/tmp/lrgdm_bkup_az.err; then
  echo "↑ azure: db-backups/${BLOB_KEY}  (account ${ACCT})"
else
  echo "ERROR: Azure Blob backup FAILED — refusing to proceed (changes should not be made without an offsite backup)." >&2
  echo "       Fix connectivity/auth, or re-run with LRGDM_BACKUP_SKIP_AZURE=1 to override." >&2
  sed 's/^/       az: /' /tmp/lrgdm_bkup_az.err >&2 || true
  exit 1
fi
