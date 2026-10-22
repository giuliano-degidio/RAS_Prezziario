#!/usr/bin/env python3
"""Avvia il process group FRONTIERE_METADATA_RUNNER da riga di comando, attende il
completamento dell'intero ciclo (frontiere + refresh DWH chain 1) leggendo le
tabelle di tracciamento hcbi_utility.etl_frontiere_run / etl_dwh_refresh_run, e
ferma il process group al termine (o allo scadere del timeout).
Uso tipico:
cd /opt/etl/frontiere-metadata-runner/
./bin/run_group_cycle.sh --frontiere-timeout 3600 --dwh-timeout 1800
Riusa:
- secrets_common.decrypt_payload / postgres_conninfo (config cifrata condivisa)
- lo stesso pattern di autenticazione REST NiFi di deploy_nifi_flow.py
"""
import argparse
import json
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from datetime import datetime, timezone

import psycopg
from secrets_common import decrypt_payload, postgres_conninfo

CLIENT_ID = str(uuid.uuid4())
TERMINAL_FRONTIERE = {"SUCCEEDED", "FAILED", "SKIPPED"}
TERMINAL_DWH = {"SUCCEEDED", "FAILED", "SKIPPED"}
GROUP_NAME = "FRONTIERE_METADATA_RUNNER"


def api_base(url):
    url = url.rstrip("/")
    if url.endswith("/nifi-api"):
        return url
    if url.endswith("/nifi"):
        return url[:-5] + "/nifi-api"
    return url + "/nifi-api"


class Nifi:
    def __init__(self, cfg):
        self.base = api_base(cfg["base_url"])
        self.ctx = ssl.create_default_context() if cfg["verify_ssl"] else ssl._create_unverified_context()
        self.token = ""
        self.token = self.call("/access/token", "POST", form={"username": cfg["username"], "password": cfg["password"]}, raw=True).decode().strip()

    def call(self, path, method="GET", payload=None, form=None, raw=False):
        headers = {}
        data = None
        if self.token:
            headers["Authorization"] = "Bearer " + self.token
        if form is not None:
            data = urllib.parse.urlencode(form).encode()
            headers["Content-Type"] = "application/x-www-form-urlencoded"
        elif payload is not None:
            data = json.dumps(payload).encode()
            headers["Content-Type"] = "application/json"
        try:
            with urllib.request.urlopen(urllib.request.Request(self.base + path, data=data, method=method, headers=headers), context=self.ctx, timeout=60) as response:
                body = response.read()
        except urllib.error.HTTPError as exc:
            raise RuntimeError(f"{method} {path}: HTTP {exc.code} {exc.read().decode()}") from exc
        return body if raw else (json.loads(body) if body else {})


def find_group_id(nifi, name):
    groups = nifi.call("/flow/process-groups/root").get("processGroupFlow", {}).get("flow", {}).get("processGroups", [])
    for g in groups:
        if g.get("component", {}).get("name") == name:
            return g["component"]["id"]
    raise RuntimeError(f"Process Group '{name}' non trovato sotto root")


def set_group_state(nifi, pg_id, state):
    nifi.call(f"/flow/process-groups/{pg_id}", "PUT", {"id": pg_id, "state": state})


def log(msg):
    print(f"{datetime.now(timezone.utc).isoformat()} {msg}", flush=True)


def poll_frontiere(control, cycle_start, poll_interval, quiet_seconds, phase_timeout):
    deadline = time.monotonic() + phase_timeout
    last_seen_count = -1
    quiet_since = None
    while True:
        with control.cursor() as cur:
            cur.execute(
                "SELECT frontiera_code, status, started_at, ended_at FROM hcbi_utility.etl_frontiere_run "
                "WHERE started_at >= %s ORDER BY started_at",
                (cycle_start,),
            )
            rows = cur.fetchall()
        if rows:
            running = [r for r in rows if r[1] == "RUNNING"]
            if not running:
                if len(rows) != last_seen_count:
                    quiet_since = time.monotonic()
                    last_seen_count = len(rows)
                elif quiet_since is not None and (time.monotonic() - quiet_since) >= quiet_seconds:
                    return rows
            else:
                quiet_since = None
                last_seen_count = len(rows)
        if time.monotonic() >= deadline:
            raise TimeoutError(f"Timeout in attesa fine fase frontiere ({phase_timeout}s); righe viste finora: {len(rows)}")
        time.sleep(poll_interval)


def poll_dwh(control, cycle_start, poll_interval, phase_timeout):
    deadline = time.monotonic() + phase_timeout
    while True:
        with control.cursor() as cur:
            cur.execute(
                "SELECT execution_uuid, chain_id, status, started_at, ended_at, error_message "
                "FROM hcbi_utility.etl_dwh_refresh_run WHERE started_at >= %s ORDER BY started_at DESC LIMIT 1",
                (cycle_start,),
            )
            row = cur.fetchone()
        if row is not None and row[2] in TERMINAL_DWH:
            return row
        if time.monotonic() >= deadline:
            if row is None:
                raise TimeoutError(f"Timeout: nessuna riga in etl_dwh_refresh_run dopo {phase_timeout}s (il refresh DWH potrebbe non essere mai partito)")
            raise TimeoutError(f"Timeout in attesa fine refresh DWH ({phase_timeout}s), stato attuale: {row[2]}")
        time.sleep(poll_interval)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--key-file", default="/opt/etl/secrets/fmr-secrets.key")
    parser.add_argument("--encrypted-config", default="/opt/etl/config/fmr-secrets.json.enc")
    parser.add_argument("--pg-name", default=GROUP_NAME, help="Nome del process group NiFi (default: %(default)s)")
    parser.add_argument("--pg-id", default=None, help="ID del process group NiFi; se omesso viene risolto per nome sotto root")
    parser.add_argument("--poll-interval", type=float, default=5.0, help="Secondi tra un poll e l'altro (default: %(default)s)")
    parser.add_argument("--quiet-seconds", type=float, default=10.0, help="Secondi di quiete senza nuove righe/RUNNING prima di considerare chiusa la fase frontiere (default: %(default)s)")
    parser.add_argument("--frontiere-timeout", type=float, default=3600.0, help="Timeout massimo fase frontiere in secondi (default: %(default)s)")
    parser.add_argument("--dwh-timeout", type=float, default=1800.0, help="Timeout massimo fase refresh DWH in secondi (default: %(default)s)")
    parser.add_argument("--no-stop", action="store_true", help="Non fermare il process group al termine (solo per debug)")
    args = parser.parse_args()

    payload = decrypt_payload(args.encrypted_config, args.key_file)
    hcbi = postgres_conninfo(payload["hcbi"]["jdbc_url"], payload["hcbi"]["username"], payload["hcbi"]["password"])
    nifi = Nifi(payload["nifi"])
    pg_id = args.pg_id or find_group_id(nifi, args.pg_name)
    log(f"Process Group risolto: {args.pg_name} ({pg_id})")

    exit_code = 0
    with psycopg.connect(**hcbi, autocommit=True) as control:
        with control.cursor() as cur:
            cur.execute("SELECT clock_timestamp()")
            cycle_start = cur.fetchone()[0]
        log(f"Cycle start (clock DB): {cycle_start.isoformat()}")

        log("Avvio process group (state=RUNNING)...")
        set_group_state(nifi, pg_id, "RUNNING")

        try:
            frontiere_rows = poll_frontiere(control, cycle_start, args.poll_interval, args.quiet_seconds, args.frontiere_timeout)
            summary = {}
            for r in frontiere_rows:
                summary[r[1]] = summary.get(r[1], 0) + 1
            log(f"Fase frontiere conclusa: {len(frontiere_rows)} run, riepilogo={summary}")
            for code, status, started_at, ended_at in frontiere_rows:
                if status != "SUCCEEDED":
                    log(f"  - {code}: {status} (started={started_at}, ended={ended_at})")

            if summary.get("FAILED", 0) or summary.get("SKIPPED", 0):
                log("Almeno una frontiera non e' SUCCEEDED: il refresh DWH chain 1 non viene avviato da run_frontiere.py (exit code != 0).")
                exit_code = 3
            else:
                log("Tutte le frontiere SUCCEEDED, attendo l'esecuzione del refresh DWH chain 1...")
                dwh_row = poll_dwh(control, cycle_start, args.poll_interval, args.dwh_timeout)
                execution_uuid, chain_id, status, started_at, ended_at, error_message = dwh_row
                log(f"Refresh DWH concluso: execution_uuid={execution_uuid} chain_id={chain_id} status={status} (started={started_at}, ended={ended_at})")
                if status != "SUCCEEDED":
                    log(f"Dettaglio errore: {error_message}")
                    exit_code = 4
        except TimeoutError as exc:
            log(f"[TIMEOUT] {exc}")
            exit_code = 5
        except Exception as exc:
            log(f"[ERRORE] {type(exc).__name__}: {exc}")
            exit_code = 6

    if not args.no_stop:
        log("Arresto process group (state=STOPPED)...")
        try:
            set_group_state(nifi, pg_id, "STOPPED")
        except Exception as exc:
            log(f"[ATTENZIONE] impossibile fermare il process group: {exc}")
            exit_code = exit_code or 7
    else:
        log("Process group lasciato RUNNING (--no-stop).")

    log(f"Ciclo terminato con exit_code={exit_code}")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
