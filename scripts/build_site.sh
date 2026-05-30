#!/usr/bin/env bash
# Rebuild public site artifacts (docs/) from the LRGDM Postgres database.
# The DB is local-only, so CI no longer regenerates these — run this locally
# before committing/pushing to deploy. $LRGDM_PG overrides the conninfo.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "==> export GeoJSON from Postgres"
python3 scripts/export_geojson.py
echo "==> generate narrative pages"
python3 scripts/generate_narratives.py
echo "==> done. Review docs/, then commit & push to deploy."
