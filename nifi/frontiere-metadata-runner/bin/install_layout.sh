#!/usr/bin/env bash
set -euo pipefail
ROOT=/opt/etl; PROJECT=$ROOT/frontiere-metadata-runner; USER=${FMR_SERVICE_USER:-nifi}; GROUP=${FMR_SERVICE_GROUP:-nifi}; SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
install -d -m 0750 -o "$USER" -g "$GROUP" "$ROOT" "$ROOT/log" "$ROOT/log/frontiere-metadata-runner" "$PROJECT"
install -d -m 0700 -o "$USER" -g "$GROUP" "$ROOT/config" "$ROOT/secrets"
cp -R "$SRC/bin" "$PROJECT/"
cp -R "$SRC/scripts" "$SRC/sql" "$SRC/config" "$PROJECT/"
cp "$SRC/requirements.txt" "$SRC/README.md" "$PROJECT/"
chown -R "$USER:$GROUP" "$PROJECT"
find "$PROJECT" -type d -exec chmod 0750 {} \;
find "$PROJECT" -type f -exec chmod 0640 {} \;
chmod 0750 "$PROJECT/scripts/"*.py
chmod 0750 "$PROJECT/bin/"*.sh
echo "[OK] File installati in $PROJECT"