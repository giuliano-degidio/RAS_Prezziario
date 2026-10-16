#!/usr/bin/env python3
import argparse
import logging
import os
import re
import sys
import uuid
from pathlib import Path
from logging.handlers import RotatingFileHandler
import psycopg
from secrets_common import decrypt_payload, postgres_conninfo

CHAIN_ID = 1
DWH_LOCK_KEY = 724631952
UUID_PATTERN = re.compile(r"FMR_EXECUTION_UUID=([0-9a-fA-F-]{36})")

def setup_logging(log_dir):
    path = Path(log_dir)
    path.mkdir(parents=True, exist_ok=True)
    logger = logging.getLogger("fmr.dwh")
    logger.setLevel(logging.INFO)
    logger.propagate = False
    formatter = logging.Formatter("%(asctime)s %(levelname)s %(message)s")
    file_handler = RotatingFileHandler(path / "dwh-refresh.log", maxBytes=20_000_000, backupCount=10, encoding="utf-8")
    file_handler.setFormatter(formatter)
    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(formatter)
    logger.handlers[:] = [file_handler, stream_handler]
    return logger

def read_execution_uuid():
    content = sys.stdin.read()
    matches = UUID_PATTERN.findall(content)
    if not matches:
        raise ValueError("Execution UUID non trovato nell'output del runner frontiere")
    value = str(uuid.UUID(matches[-1]))
    return value

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--key-file", default=os.getenv("FMR_SECRET_KEY_FILE", "/opt/etl/secrets/fmr-secrets.key"))
    parser.add_argument("--encrypted-config", default=os.getenv("FMR_ENCRYPTED_CONFIG", "/opt/etl/config/fmr-secrets.json.enc"))
    parser.add_argument("--log-dir", default=os.getenv("FMR_LOG_DIR", "/opt/etl/log/frontiere-metadata-runner"))
    args = parser.parse_args()
    logger = setup_logging(args.log_dir)
    try:
        execution_uuid = read_execution_uuid()
    except Exception:
        logger.exception("Impossibile determinare execution_uuid dal FlowFile in ingresso")
        return 1

    logger.info("Avvio DWH refresh: execution_uuid=%s chain_id=%s", execution_uuid, CHAIN_ID)
    run_id = None
    try:
        payload = decrypt_payload(args.encrypted_config, args.key_file)
        hcbi = postgres_conninfo(payload["hcbi"]["jdbc_url"], payload["hcbi"]["username"], payload["hcbi"]["password"])
        # autocommit=True: nessuna transazione esplicita, nessun COMMIT/ROLLBACK nello script.
        # La procedura gestisce autonomamente le proprie transazioni.
        with psycopg.connect(**hcbi, autocommit=True) as conn:
            with conn.cursor() as cur:
                cur.execute("INSERT INTO hcbi_utility.etl_dwh_refresh_run(execution_uuid,chain_id,status) VALUES(%s,%s,'RUNNING') RETURNING run_id", (execution_uuid, CHAIN_ID))
                run_id = cur.fetchone()[0]
                cur.execute("SELECT pg_try_advisory_lock(%s)", (DWH_LOCK_KEY,))
                if not cur.fetchone()[0]:
                    cur.execute("UPDATE hcbi_utility.etl_dwh_refresh_run SET ended_at=clock_timestamp(),status='SKIPPED',error_message=NULL WHERE run_id=%s", (run_id,))
                    logger.warning("DWH refresh SKIPPED: chain 1 gia in esecuzione")
                    return 2
                # Il lock e di sessione e viene rilasciato automaticamente chiudendo conn.
                cur.execute("CALL hcbi_utility.prc_execute_chain(%s)", (CHAIN_ID,))
                cur.execute("UPDATE hcbi_utility.etl_dwh_refresh_run SET ended_at=clock_timestamp(),status='SUCCEEDED' WHERE run_id=%s", (run_id,))
        logger.info("DWH refresh SUCCEEDED: execution_uuid=%s chain_id=%s", execution_uuid, CHAIN_ID)
        return 0
    except Exception as exc:
        message = f"{type(exc).__name__}: {exc}"[:4000]
        logger.exception("DWH refresh FAILED: execution_uuid=%s chain_id=%s", execution_uuid, CHAIN_ID)
        if run_id is not None:
            try:
                payload = decrypt_payload(args.encrypted_config, args.key_file)
                hcbi = postgres_conninfo(payload["hcbi"]["jdbc_url"], payload["hcbi"]["username"], payload["hcbi"]["password"])
                with psycopg.connect(**hcbi, autocommit=True) as log_conn:
                    with log_conn.cursor() as cur:
                        cur.execute("UPDATE hcbi_utility.etl_dwh_refresh_run SET ended_at=clock_timestamp(),status='FAILED',error_message=%s WHERE run_id=%s", (message, run_id))
            except Exception:
                logger.exception("Impossibile aggiornare il log DWH FAILED")
        return 2

if __name__ == "__main__":
    raise SystemExit(main())
