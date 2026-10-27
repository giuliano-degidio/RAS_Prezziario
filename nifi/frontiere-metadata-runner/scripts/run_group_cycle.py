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
import os
import re
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid
from datetime import datetime, timezone
from pathlib import Path

import psycopg
from secrets_common import decrypt_payload, postgres_conninfo

CLIENT_ID = str(uuid.uuid4())
TERMINAL_FRONTIERE = {"SUCCEEDED", "FAILED", "SKIPPED"}
DWH_START_PATTERN = re.compile(r"Avvio DWH refresh: execution_uuid=([0-9a-fA-F-]{36})\s+chain_id=(\d+)")
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


HEARTBEAT_SECONDS = 60.0


class RotatingLogTail:
    """Legge solo le righe aggiunte dopo l'istante di inizializzazione, anche dopo rollover."""

    def __init__(self, path):
        self.path = Path(path)
        self.offsets = {}
        self.pending = {}
        self.execution_uuid = None
        self._snapshot_existing_files()

    def _files(self):
        return [self.path] + sorted(self.path.parent.glob(self.path.name + ".*"))

    def _snapshot_existing_files(self):
        seen = set()
        for path in self._files():
            try:
                with path.open("rb") as stream:
                    stat = os.fstat(stream.fileno())
            except FileNotFoundError:
                continue
            identity = (stat.st_dev, stat.st_ino)
            if identity not in seen:
                self.offsets[identity] = stat.st_size
                self.pending[identity] = b""
                seen.add(identity)

    def read_new_lines(self):
        lines = []
        seen = set()
        for path in self._files():
            try:
                with path.open("rb") as stream:
                    stat = os.fstat(stream.fileno())
                    identity = (stat.st_dev, stat.st_ino)
                    if identity in seen:
                        continue
                    seen.add(identity)
                    offset = self.offsets.get(identity, 0)
                    if stat.st_size < offset:
                        offset = 0
                        self.pending[identity] = b""
                    stream.seek(offset)
                    chunk = stream.read()
                    self.offsets[identity] = stream.tell()
            except FileNotFoundError:
                continue

            parts = (self.pending.get(identity, b"") + chunk).split(b"\n")
            self.pending[identity] = parts.pop()
            lines.extend(part.decode("utf-8", errors="replace").rstrip("\r") for part in parts)
        for line in lines:
            match = DWH_START_PATTERN.search(line)
            if not match or int(match.group(2)) != 1:
                continue
            found_uuid = str(uuid.UUID(match.group(1)))
            if self.execution_uuid is None:
                self.execution_uuid = found_uuid
                log(f"Avvio DWH rilevato nel log: execution_uuid={self.execution_uuid}")
            elif self.execution_uuid != found_uuid:
                raise RuntimeError(
                    "Rilevati più execution_uuid DWH nel log dopo l'avvio del gruppo; "
                    "impossibile correlare il ciclo in modo univoco"
                )
        return lines


def _connect_short(hcbi_conninfo):
    # Connessione breve per singolo poll: evita di tenere aperta per ore una
    # connessione che un firewall/NAT potrebbe droppare silenziosamente,
    # lasciando lo script bloccato su un socket morto senza alcun errore.
    return psycopg.connect(**hcbi_conninfo, autocommit=True, connect_timeout=10)


def poll_frontiere(hcbi_conninfo, cycle_start, dwh_log, poll_interval, quiet_seconds, phase_timeout):
    deadline = time.monotonic() + phase_timeout
    last_seen_count = -1
    quiet_since = None
    last_heartbeat = time.monotonic()
    while True:
        dwh_log.read_new_lines()
        try:
            with _connect_short(hcbi_conninfo) as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        "SELECT frontiera_code, status, started_at, ended_at FROM hcbi_utility.etl_frontiere_run "
                        "WHERE started_at >= %s ORDER BY started_at",
                        (cycle_start,),
                    )
                    rows = cur.fetchall()
        except psycopg.OperationalError as exc:
            log(f"[WARN] errore di connessione durante il poll frontiere, ritento: {exc}")
            rows = []
        if not rows and dwh_log.execution_uuid is not None:
            log(
                "Nessun log frontiere disponibile, ma il log DWH conferma il completamento "
                f"del runner: execution_uuid={dwh_log.execution_uuid}"
            )
            return rows
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
        if time.monotonic() - last_heartbeat >= HEARTBEAT_SECONDS:
            running_count = len([r for r in rows if r[1] == "RUNNING"]) if rows else 0
            log(f"[heartbeat] fase frontiere: {len(rows)} run viste finora ({running_count} RUNNING), in attesa...")
            last_heartbeat = time.monotonic()
        if time.monotonic() >= deadline:
            raise TimeoutError(f"Timeout in attesa fine fase frontiere ({phase_timeout}s); righe viste finora: {len(rows)}")
        time.sleep(poll_interval)


def poll_dwh(hcbi_conninfo, dwh_log, poll_interval, phase_timeout):
    deadline = time.monotonic() + phase_timeout
    last_heartbeat = time.monotonic()
    while True:
        dwh_log.read_new_lines()
        execution_uuid = dwh_log.execution_uuid

        row = None
        try:
            if execution_uuid is not None:
                with _connect_short(hcbi_conninfo) as conn:
                    with conn.cursor() as cur:
                        cur.execute(
                            "SELECT execution_uuid, chain_id, status, started_at, ended_at, error_message "
                            "FROM hcbi_utility.etl_dwh_refresh_run "
                            "WHERE execution_uuid = %s AND chain_id = %s "
                            "ORDER BY started_at DESC LIMIT 1",
                            (execution_uuid, 1),
                        )
                        row = cur.fetchone()
        except psycopg.OperationalError as exc:
            log(f"[WARN] errore di connessione durante il poll DWH, ritento: {exc}")
        if row is not None and row[4] is not None:
            return row
        if time.monotonic() - last_heartbeat >= HEARTBEAT_SECONDS:
            if execution_uuid is None:
                state = "in attesa della riga di avvio nel log DWH"
            elif row is None:
                state = f"execution_uuid={execution_uuid}, nessuna riga DB ancora"
            else:
                state = f"execution_uuid={execution_uuid}, status={row[2]}, ended_at={row[4]}"
            log(f"[heartbeat] fase DWH: {state}, in attesa...")
            last_heartbeat = time.monotonic()
        if time.monotonic() >= deadline:
            if execution_uuid is None:
                raise TimeoutError(
                    f"Timeout: nessuna riga 'Avvio DWH refresh' nel log {dwh_log.path} "
                    f"dopo {phase_timeout}s"
                )
            if row is None:
                raise TimeoutError(
                    f"Timeout: nessuna riga in etl_dwh_refresh_run per execution_uuid={execution_uuid}"
                )
            raise TimeoutError(
                f"Timeout in attesa di ended_at per execution_uuid={execution_uuid}; "
                f"status attuale={row[2]}"
            )
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
    parser.add_argument(
        "--dwh-log-file",
        default=os.path.join(os.getenv("FMR_LOG_DIR", "/opt/etl/log/frontiere-metadata-runner"), "dwh-refresh.log"),
        help="Path del log DWH (default: %(default)s)",
    )
    parser.add_argument("--no-stop", action="store_true", help="Non fermare il process group al termine (solo per debug)")
    args = parser.parse_args()

    payload = decrypt_payload(args.encrypted_config, args.key_file)
    hcbi = postgres_conninfo(payload["hcbi"]["jdbc_url"], payload["hcbi"]["username"], payload["hcbi"]["password"])
    nifi = Nifi(payload["nifi"])
    pg_id = args.pg_id or find_group_id(nifi, args.pg_name)
    log(f"Process Group risolto: {args.pg_name} ({pg_id})")

    exit_code = 0
    with _connect_short(hcbi) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT clock_timestamp()")
            cycle_start = cur.fetchone()[0]
    log(f"Cycle start (clock DB): {cycle_start.isoformat()}")
    dwh_log = RotatingLogTail(args.dwh_log_file)
    log(f"Log DWH monitorato: {dwh_log.path}")

    log("Avvio process group (state=RUNNING)...")
    set_group_state(nifi, pg_id, "RUNNING")

    try:
        frontiere_rows = poll_frontiere(
            hcbi,
            cycle_start,
            dwh_log,
            args.poll_interval,
            args.quiet_seconds,
            args.frontiere_timeout,
        )
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
            dwh_row = poll_dwh(hcbi, dwh_log, args.poll_interval, args.dwh_timeout)
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
