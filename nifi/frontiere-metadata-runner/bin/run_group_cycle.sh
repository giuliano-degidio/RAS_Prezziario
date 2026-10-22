#!/usr/bin/env bash
# Avvia il ciclo completo di FRONTIERE_METADATA_RUNNER da riga di comando:
# start del process group NiFi -> attesa fine frontiere -> attesa fine refresh
# DWH chain 1 -> stop del process group. Vedi scripts/run_group_cycle.py.
set -euo pipefail
PROJECT_DIR=${FMR_PROJECT_DIR:-/opt/etl/frontiere-metadata-runner}
PYTHON=${FMR_PYTHON:-"$PROJECT_DIR/.venv/bin/python"}
export FMR_SECRET_KEY_FILE=${FMR_SECRET_KEY_FILE:-/opt/etl/secrets/fmr-secrets.key}
export FMR_ENCRYPTED_CONFIG=${FMR_ENCRYPTED_CONFIG:-/opt/etl/config/fmr-secrets.json.enc}

exec "$PYTHON" "$PROJECT_DIR/scripts/run_group_cycle.py" \
    --key-file "$FMR_SECRET_KEY_FILE" \
    --encrypted-config "$FMR_ENCRYPTED_CONFIG" \
    "$@"
