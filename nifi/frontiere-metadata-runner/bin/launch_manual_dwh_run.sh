#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR=${FMR_PROJECT_DIR:-/opt/etl/frontiere-metadata-runner}
PYTHON=${FMR_PYTHON:-"$PROJECT_DIR/.venv/bin/python"}
RUNNER="$PROJECT_DIR/scripts/dwh_schedule_runner.py"

if [[ ! -x "$PYTHON" || ! -f "$RUNNER" ]]; then
    printf 'Runtime scheduler non disponibile: %s\n' "$RUNNER" >&2
    exit 1
fi

nohup "$PYTHON" "$RUNNER" \
    --mode manual-ui \
    --requested-by NiFi-UI \
    --key-file "${FMR_SECRET_KEY_FILE:-/opt/etl/secrets/fmr-secrets.key}" \
    --encrypted-config "${FMR_ENCRYPTED_CONFIG:-/opt/etl/config/fmr-secrets.json.enc}" \
    </dev/null >/dev/null 2>&1 &

printf 'Richiesta manuale accettata (pid=%s); verificare il run in dwh_schedule_run.\n' "$!"
