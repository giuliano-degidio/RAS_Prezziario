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
from psycopg import sql
from secrets_common import decrypt_payload, postgres_conninfo

GLOBAL_LOCK_KEY = 724631951
IDENTIFIER = re.compile(r"^[a-z_][a-z0-9_]{0,62}$")
CONFIG_SQL = """
SELECT frontiera_code, description, execution_order, source_service_code,
       source_query, target_schema, target_table, truncate_before_load
FROM hcbi_utility.etl_frontiere_config
WHERE enabled = true
ORDER BY execution_order, frontiera_code
"""

def setup_logging(log_dir):
    path = Path(log_dir)
    path.mkdir(parents=True, exist_ok=True)
    logger = logging.getLogger("fmr.frontiere")
    logger.setLevel(logging.INFO)
    logger.propagate = False
    formatter = logging.Formatter("%(asctime)s %(levelname)s %(message)s")
    file_handler = RotatingFileHandler(path / "frontiere-metadata-runner.log", maxBytes=20_000_000, backupCount=10, encoding="utf-8")
    file_handler.setFormatter(formatter)
    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(formatter)
    logger.handlers[:] = [file_handler, stream_handler]
    return logger

def normalize_query(query):
    text = query.strip().rstrip(";").strip()
    if ";" in text or not re.match(r"^(SELECT|WITH)\b", text, re.IGNORECASE):
        raise ValueError("source_query non valida")
    return text

def fetch_configs(control):
    with control.cursor() as cur:
        cur.execute(CONFIG_SQL)
        names = [d.name for d in cur.description]
        return [dict(zip(names, row)) for row in cur.fetchall()]

def run_one(cfg, control, hcbi_info, rasop_info, batch_size, execution_uuid, logger):
    code = cfg["frontiera_code"]
    with control.cursor() as cur:
        cur.execute("INSERT INTO hcbi_utility.etl_frontiere_run(frontiera_code,status,nifi_flowfile_uuid) VALUES(%s,'RUNNING',%s) RETURNING run_id", (code, execution_uuid))
        run_id = cur.fetchone()[0]
        cur.execute("INSERT INTO hcbi_utility.etl_frontiere_execution_lock(frontiera_code,run_id) VALUES(%s,%s) ON CONFLICT DO NOTHING RETURNING run_id", (code, run_id))
        locked = cur.fetchone() is not None
    if not locked:
        with control.cursor() as cur:
            cur.execute("UPDATE hcbi_utility.etl_frontiere_run SET ended_at=clock_timestamp(),status='SKIPPED',warning_message='Lock non acquisito' WHERE run_id=%s", (run_id,))
        logger.warning("%s SKIPPED", code)
        return "SKIPPED"
    rows_read = rows_written = 0
    try:
        if cfg["source_service_code"] != "RASOP" or cfg["target_schema"] != "hcbi_ras" or cfg["truncate_before_load"] is not True or not IDENTIFIER.fullmatch(cfg["target_table"]):
            raise ValueError("Configurazione non valida")
        query = normalize_query(cfg["source_query"])
        with psycopg.connect(**rasop_info) as source, psycopg.connect(**hcbi_info) as target:
            with source.cursor() as src, target.cursor() as dst:
                dst.execute(sql.SQL("TRUNCATE TABLE {}.{}").format(sql.Identifier("hcbi_ras"), sql.Identifier(cfg["target_table"])))
                src.execute(query)
                columns = [d.name for d in src.description]
                if not columns or len(columns) != len(set(columns)):
                    raise RuntimeError("Colonne sorgente assenti o duplicate")
                insert_sql = sql.SQL("INSERT INTO {}.{} ({}) VALUES ({})").format(sql.Identifier("hcbi_ras"), sql.Identifier(cfg["target_table"]), sql.SQL(",").join(map(sql.Identifier, columns)), sql.SQL(",").join(sql.Placeholder() for _ in columns))
                while True:
                    batch = src.fetchmany(batch_size)
                    if not batch:
                        break
                    rows_read += len(batch)
                    dst.executemany(insert_sql, batch)
                    rows_written += len(batch)
            target.commit()
        warning = "La query sorgente ha restituito zero righe" if rows_read == 0 else None
        with control.cursor() as cur:
            cur.execute("UPDATE hcbi_utility.etl_frontiere_run SET ended_at=clock_timestamp(),status='SUCCEEDED',rows_read=%s,rows_written=%s,warning_message=%s WHERE run_id=%s", (rows_read, rows_written, warning, run_id))
        logger.info("%s SUCCEEDED: lette=%s scritte=%s", code, rows_read, rows_written)
        return "SUCCEEDED"
    except Exception as exc:
        with control.cursor() as cur:
            cur.execute("UPDATE hcbi_utility.etl_frontiere_run SET ended_at=clock_timestamp(),status='FAILED',rows_read=%s,rows_written=%s,error_message=%s WHERE run_id=%s", (rows_read, rows_written, f"{type(exc).__name__}: {exc}"[:4000], run_id))
        logger.exception("%s FAILED", code)
        return "FAILED"
    finally:
        with control.cursor() as cur:
            cur.execute("DELETE FROM hcbi_utility.etl_frontiere_execution_lock WHERE frontiera_code=%s AND run_id=%s", (code, run_id))

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--key-file", default=os.getenv("FMR_SECRET_KEY_FILE", "/opt/etl/secrets/fmr-secrets.key"))
    parser.add_argument("--encrypted-config", default=os.getenv("FMR_ENCRYPTED_CONFIG", "/opt/etl/config/fmr-secrets.json.enc"))
    parser.add_argument("--log-dir", default=os.getenv("FMR_LOG_DIR", "/opt/etl/log/frontiere-metadata-runner"))
    parser.add_argument("--batch-size", type=int, default=1000)
    args = parser.parse_args()
    execution_uuid = str(uuid.uuid4())
    logger = setup_logging(args.log_dir)
    logger.info("Avvio FRONTIERE_METADATA_RUNNER: execution_uuid=%s", execution_uuid)
    summary = {"SUCCEEDED": 0, "FAILED": 0, "SKIPPED": 0}
    try:
        payload = decrypt_payload(args.encrypted_config, args.key_file)
        hcbi = postgres_conninfo(payload["hcbi"]["jdbc_url"], payload["hcbi"]["username"], payload["hcbi"]["password"])
        rasop = postgres_conninfo(payload["rasop"]["jdbc_url"], payload["rasop"]["username"], payload["rasop"]["password"])
        with psycopg.connect(**hcbi, autocommit=True) as control:
            with control.cursor() as cur:
                cur.execute("SELECT pg_try_advisory_lock(%s)", (GLOBAL_LOCK_KEY,))
                if not cur.fetchone()[0]:
                    logger.warning("Runner frontiere gia attivo")
                    return 1
            try:
                configs = fetch_configs(control)
                logger.info("Configurazioni attive caricate: %s", len(configs))
                for cfg in configs:
                    status = run_one(cfg, control, hcbi, rasop, args.batch_size, execution_uuid, logger)
                    summary[status] += 1
            finally:
                with control.cursor() as cur:
                    cur.execute("SELECT pg_advisory_unlock(%s)", (GLOBAL_LOCK_KEY,))
    except Exception:
        logger.exception("Errore iniziale runner frontiere")
        return 1
    logger.info("Riepilogo: execution_uuid=%s SUCCEEDED=%s FAILED=%s SKIPPED=%s", execution_uuid, summary["SUCCEEDED"], summary["FAILED"], summary["SKIPPED"])
    if summary["FAILED"] or summary["SKIPPED"]:
        return 2
    # Marker machine-readable, ultimo output su stdout, consumato dallo step DWH.
    print(f"FMR_EXECUTION_UUID={execution_uuid}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
