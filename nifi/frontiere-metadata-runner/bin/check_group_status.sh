#!/usr/bin/env bash
# Mostra lo stato del process group FRONTIERE_METADATA_RUNNER (gruppo, processor,
# bulletin) via REST API NiFi. Vedi scripts/check_group_status.py.
set -euo pipefail
PROJECT_DIR=${FMR_PROJECT_DIR:-/opt/etl/frontiere-metadata-runner}
PYTHON=${FMR_PYTHON:-"$PROJECT_DIR/.venv/bin/python"}
export FMR_SECRET_KEY_FILE=${FMR_SECRET_KEY_FILE:-/opt/etl/secrets/fmr-secrets.key}
export FMR_ENCRYPTED_CONFIG=${FMR_ENCRYPTED_CONFIG:-/opt/etl/config/fmr-secrets.json.enc}

exec "$PYTHON" "$PROJECT_DIR/scripts/check_group_status.py" \
    --key-file "$FMR_SECRET_KEY_FILE" \
    --encrypted-config "$FMR_ENCRYPTED_CONFIG" \
    "$@"
