#!/usr/bin/env python3
"""Mostra lo stato corrente del process group FRONTIERE_METADATA_RUNNER (e dei
suoi processor) leggendo la REST API di NiFi: stato del gruppo, stato/thread
attivi/code di ogni processor, bulletin recenti. Pensato per diagnosi rapida da
riga di comando, in alternativa/complemento alla UI NiFi.

Riusa lo stesso client REST (Nifi/api_base) di deploy_nifi_flow.py e
run_group_cycle.py.
"""
import argparse
import json
import ssl
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

from secrets_common import decrypt_payload

CLIENT_ID = str(uuid.uuid4())
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


def print_snapshot(nifi, pg_id):
    flow = nifi.call(f"/flow/process-groups/{pg_id}").get("processGroupFlow", {}).get("flow", {})
    pg_status = nifi.call(f"/flow/process-groups/{pg_id}/status").get("processGroupStatus", {}).get("aggregateSnapshot", {})
    print(f"Process Group: queued={pg_status.get('queuedCount')} ({pg_status.get('queuedSize')}), "
          f"activeThreadCount={pg_status.get('activeThreadCount')}, bytesIn={pg_status.get('bytesIn')}, bytesOut={pg_status.get('bytesOut')}")
    print(f"{'PROCESSOR':<32} {'STATE':<10} {'ACTIVE':<7} {'QUEUED IN':<10} {'TASKS':<7} {'LAST RUN'}")
    for p in flow.get("processors", []):
        comp = p["component"]
        status = nifi.call(f"/processors/{comp['id']}/status").get("processorStatus", {}).get("aggregateSnapshot", {})
        print(f"{comp['name']:<32} {comp['state']:<10} {status.get('activeThreadCount', 0):<7} "
              f"{status.get('input', '-'):<10} {status.get('tasks', '-'):<7} {status.get('executionDuration', status.get('averageLineageDuration', '-'))}")
    bulletins = nifi.call(f"/flow/process-groups/{pg_id}/bulletins").get("bulletinBoard", {}).get("bulletins", [])
    if bulletins:
        print("\nBulletin recenti:")
        for b in bulletins[-10:]:
            m = b.get("bulletin", {})
            print(f"  [{m.get('timestamp')}] {m.get('level')} {m.get('sourceName')}: {m.get('message')}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--key-file", default="/opt/etl/secrets/fmr-secrets.key")
    parser.add_argument("--encrypted-config", default="/opt/etl/config/fmr-secrets.json.enc")
    parser.add_argument("--pg-name", default=GROUP_NAME)
    parser.add_argument("--pg-id", default=None)
    parser.add_argument("--watch", type=float, default=0.0, help="Se >0, ripete ogni N secondi (Ctrl+C per uscire)")
    args = parser.parse_args()

    payload = decrypt_payload(args.encrypted_config, args.key_file)
    nifi = Nifi(payload["nifi"])
    pg_id = args.pg_id or find_group_id(nifi, args.pg_name)

    while True:
        print(f"=== {args.pg_name} ({pg_id}) ===")
        print_snapshot(nifi, pg_id)
        if args.watch <= 0:
            break
        print()
        time.sleep(args.watch)


if __name__ == "__main__":
    raise SystemExit(main())
