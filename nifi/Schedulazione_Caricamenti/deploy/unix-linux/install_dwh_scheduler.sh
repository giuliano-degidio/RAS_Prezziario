#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID} -ne 0 ]]; then
    printf 'Eseguire come root o tramite sudo.\n' >&2
    exit 1
fi

SERVICE_USER=nifi
PROJECT_DIR=/opt/etl/frontiere-metadata-runner
SOURCE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
NIFI_DEPLOY_HELPER="$SOURCE_DIR/../nifi/deploy_manual_launcher.py"

if [[ ! -f "$NIFI_DEPLOY_HELPER" ]]; then
    printf 'Helper di deploy NiFi non trovato: %s\n' "$NIFI_DEPLOY_HELPER" >&2
    exit 1
fi
if ! getent passwd "$SERVICE_USER" >/dev/null; then
    printf 'Utente di servizio non trovato: %s\n' "$SERVICE_USER" >&2
    exit 1
fi
if [[ ! -x "$PROJECT_DIR/.venv/bin/python" ]]; then
    printf 'Virtualenv FMR assente: %s/.venv/bin/python\n' "$PROJECT_DIR" >&2
    exit 1
fi
if [[ ! -x "$PROJECT_DIR/bin/run_group_cycle.sh" || ! -f "$PROJECT_DIR/scripts/secrets_common.py" ]]; then
    printf 'Installazione frontiere-metadata-runner incompleta in %s\n' "$PROJECT_DIR" >&2
    exit 1
fi
if [[ ! -d "$PROJECT_DIR/bin" ]]; then
    printf 'Directory bin FMR assente: %s/bin\n' "$PROJECT_DIR" >&2
    exit 1
fi

SERVICE_GROUP=nifi
install -d -m 0750 -o "$SERVICE_USER" -g "$SERVICE_GROUP" \
    /opt/etl/log/dwh-scheduler "$PROJECT_DIR/scripts"
install -m 0750 -o "$SERVICE_USER" -g "$SERVICE_GROUP" \
    "$SOURCE_DIR/dwh_schedule_runner.py" \
    "$PROJECT_DIR/scripts/dwh_schedule_runner.py"
install -m 0644 "$SOURCE_DIR/dwh-scheduler.service" \
    /etc/systemd/system/dwh-scheduler.service
install -m 0750 -o "$SERVICE_USER" -g "$SERVICE_GROUP" \
    "$SOURCE_DIR/launch_manual_dwh_run.sh" \
    "$PROJECT_DIR/bin/launch_manual_dwh_run.sh"
install -m 0750 -o "$SERVICE_USER" -g "$SERVICE_GROUP" \
    "$NIFI_DEPLOY_HELPER" \
    "$PROJECT_DIR/scripts/deploy_manual_launcher.py"
install -m 0644 "$SOURCE_DIR/dwh-scheduler.timer" \
    /etc/systemd/system/dwh-scheduler.timer
install -m 0644 "$SOURCE_DIR/dwh-scheduler.logrotate" \
    /etc/logrotate.d/dwh-scheduler

if [[ ! -e /etc/sysconfig/dwh-scheduler ]]; then
    install -m 0644 "$SOURCE_DIR/dwh-scheduler.env.example" \
        /etc/sysconfig/dwh-scheduler
    printf 'Creato /etc/sysconfig/dwh-scheduler: verificarlo prima di abilitare il timer.\n'
else
    printf 'Preservato /etc/sysconfig/dwh-scheduler esistente.\n'
fi

systemctl daemon-reload
printf '[OK] File installati; timer NON abilitato e servizio NON avviato.\n'
