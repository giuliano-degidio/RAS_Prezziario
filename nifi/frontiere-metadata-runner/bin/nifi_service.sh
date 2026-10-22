#!/usr/bin/env bash
# Wrapper per gestire il servizio systemd di NiFi (nifi.service) installato
# sotto /opt/nifi-2.11.0. Richiede privilegi sudo per start/stop/restart.
#
# Uso:
#   bin/nifi_service.sh start|stop|restart|status|enable|disable|logs [N]
set -euo pipefail
SERVICE=${NIFI_SERVICE_NAME:-nifi.service}
ACTION=${1:-}

usage() {
    echo "Uso: $0 start|stop|restart|status|enable|disable|logs [N]" >&2
    exit 1
}

[ -n "$ACTION" ] || usage

case "$ACTION" in
    start|stop|restart)
        echo "[INFO] systemctl $ACTION $SERVICE"
        sudo systemctl "$ACTION" "$SERVICE"
        sleep 2
        sudo systemctl --no-pager status "$SERVICE" | head -5
        ;;
    status)
        sudo systemctl --no-pager status "$SERVICE"
        ;;
    enable|disable)
        sudo systemctl "$ACTION" "$SERVICE"
        ;;
    logs)
        LINES=${2:-200}
        sudo journalctl -u "$SERVICE" -n "$LINES" --no-pager
        ;;
    *)
        usage
        ;;
esac
