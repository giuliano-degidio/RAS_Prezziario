#!/usr/bin/env python3
"""Create the NiFi UI entry point for a manual DWH refresh request."""

from __future__ import annotations

import argparse
import os
import sys
import uuid


GROUP_NAME = "DWH_MANUAL_LAUNCH"
BUSINESS_GROUP_NAME = "FRONTIERE_METADATA_RUNNER"
CLIENT_ID = str(uuid.uuid4())
PROJECT_DIR = "/opt/etl/frontiere-metadata-runner"


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--scripts-dir", default=os.getenv(
        "FMR_RUNNER_SCRIPTS_DIR", f"{PROJECT_DIR}/scripts"))
    parser.add_argument("--key-file", default=os.getenv(
        "FMR_SECRET_KEY_FILE", "/opt/etl/secrets/fmr-secrets.key"))
    parser.add_argument("--encrypted-config", default=os.getenv(
        "FMR_ENCRYPTED_CONFIG", "/opt/etl/config/fmr-secrets.json.enc"))
    return parser.parse_args()


def create_processor(nifi, group_id, name, processor_type, x, y, properties,
                     auto_terminated):
    entity = nifi.call(
        f"/process-groups/{group_id}/processors",
        "POST",
        {
            "revision": {"clientId": CLIENT_ID, "version": 0},
            "component": {
                "name": name,
                "type": processor_type,
                "position": {"x": x, "y": y},
                "config": {
                    "schedulingStrategy": "TIMER_DRIVEN",
                    "schedulingPeriod": "1 day",
                    "concurrentlySchedulableTaskCount": 1,
                    "properties": properties,
                    "autoTerminatedRelationships": auto_terminated,
                },
            },
        },
    )
    return entity["component"]["id"]


def connect(nifi, group_id, source_id, destination_id, relationship):
    return nifi.call(
        f"/process-groups/{group_id}/connections",
        "POST",
        {
            "revision": {"clientId": CLIENT_ID, "version": 0},
            "component": {
                "source": {
                    "id": source_id,
                    "type": "PROCESSOR",
                    "groupId": group_id,
                },
                "destination": {
                    "id": destination_id,
                    "type": "PROCESSOR",
                    "groupId": group_id,
                },
                "selectedRelationships": [relationship],
                "flowFileExpiration": "5 min",
                "backPressureObjectThreshold": 1,
                "backPressureDataSizeThreshold": "1 MB",
            },
        },
    )


def main() -> None:
    args = parse_args()
    if args.scripts_dir not in sys.path:
        sys.path.insert(0, args.scripts_dir)
    from run_group_cycle import Nifi, find_group_id
    from secrets_common import decrypt_payload

    payload = decrypt_payload(args.encrypted_config, args.key_file)
    nifi = Nifi(payload["nifi"])
    find_group_id(nifi, BUSINESS_GROUP_NAME)

    root_flow = nifi.call("/flow/process-groups/root").get(
        "processGroupFlow", {}).get("flow", {})
    existing = [
        group.get("component", {}).get("name")
        for group in root_flow.get("processGroups", [])
    ]
    if GROUP_NAME in existing:
        raise RuntimeError(
            f"Process Group {GROUP_NAME} gia' presente; verificarlo nella UI"
        )

    group = nifi.call(
        "/process-groups/root/process-groups",
        "POST",
        {
            "revision": {"clientId": CLIENT_ID, "version": 0},
            "component": {
                "name": GROUP_NAME,
                "position": {"x": 0, "y": 600},
                "comments": (
                    "Avvio manuale one-shot. Il runner acquisisce il lock, "
                    "registra l'origine MANUAL_UI e ferma questo gruppo."
                ),
            },
        },
    )["component"]
    group_id = group["id"]

    trigger_id = create_processor(
        nifi, group_id, "Richiesta manuale",
        "org.apache.nifi.processors.standard.GenerateFlowFile",
        0, 0,
        {
            "File Size": "0B",
            "Batch Size": "1",
            "Unique FlowFiles": "false",
            "Custom Text": "DWH manual request",
            "Character Set": "UTF-8",
            "Data Format": "Text",
        },
        [],
    )
    runner_id = create_processor(
        nifi, group_id, "Richiama orchestratore scheduler",
        "org.apache.nifi.processors.standard.ExecuteStreamCommand",
        360, 0,
        {
            "Command Path": f"{PROJECT_DIR}/bin/launch_manual_dwh_run.sh",
            "Command Arguments Strategy": "Command Arguments Property",
            "Command Arguments": "",
            "Argument Delimiter": ";",
            "Working Directory": PROJECT_DIR,
            "Ignore STDIN": "true",
            "FMR_PROJECT_DIR": PROJECT_DIR,
            "FMR_PYTHON": f"{PROJECT_DIR}/.venv/bin/python",
            "FMR_RUNNER_SCRIPTS_DIR": f"{PROJECT_DIR}/scripts",
            "FMR_SECRET_KEY_FILE": args.key_file,
            "FMR_ENCRYPTED_CONFIG": args.encrypted_config,
            "FMR_LOG_DIR": "/opt/etl/log/frontiere-metadata-runner",
            "DWH_SCHEDULER_LOG_FILE": "/opt/etl/log/dwh-scheduler/dwh-scheduler.log",
        },
        ["original", "output stream", "nonzero status"],
    )
    connect(nifi, group_id, trigger_id, runner_id, "success")
    print(f"[OK] Process Group creato e lasciato STOPPED: {GROUP_NAME} ({group_id})")
    print("[OK] Avviare il gruppo dalla UI solo per una richiesta manuale.")


if __name__ == "__main__":
    main()
