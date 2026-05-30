#!/usr/bin/env bash
# Local backup of the LRGDM Postgres database -> db/backups/lrgdm_<date>.sql
# Plain SQL (git-diffable). Excludes the bulky PostGIS spatial_ref_sys data.
# Run manually before edits/migrations; wire to a scheduler later if desired.
#   LRGDM_PGDB overrides the db name (default: lrgdm).
set -euo pipefail
cd "$(dirname "$0")/.."
DB="${LRGDM_PGDB:-lrgdm}"
STAMP="$(date +%Y-%m-%d)"
OUT="db/backups/lrgdm_${STAMP}.sql"
mkdir -p db/backups
pg_dump -Fp --no-owner --exclude-table-data=spatial_ref_sys "$DB" > "$OUT"
echo "wrote $OUT ($(wc -l < "$OUT" | tr -d ' ') lines, $(du -h "$OUT" | cut -f1))"
