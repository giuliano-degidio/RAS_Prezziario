#!/usr/bin/env python3
"""Valuta la schedulazione PostgreSQL e avvia il ciclo NiFi solo se dovuto."""

from __future__ import annotations

import argparse
import codecs
import logging
import os
import selectors
import subprocess
import sys
import time
import uuid
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo


DB_SCHEMA = "hcbi_utility"
LOCK_KEY_CLASS = 92117001
LOCK_KEY_ID = 1
LOCK_HEARTBEAT_SECONDS = 30
FREQUENCY_MONTHS = {
    "ANNUAL": 12,
    "SEMIANNUAL": 6,
    "FOUR_MONTHLY": 4,
    "QUARTERLY": 3,
    "BIMONTHLY": 2,
}
FREQUENCIES = set(FREQUENCY_MONTHS) | {"MONTHLY", "WEEKLY", "DAILY"}


@dataclass(frozen=True)
class Schedule:
    schedule_id: int
    process_code: str
    process_description: str
    enabled: bool
    frequency_code: str
    anchor_month: int | None
    week_ordinal: int | None
    weekday_iso: int | None
    retry_days: int | None
    last_success_period_start: date | None


@dataclass(frozen=True)
class Candidate:
    period_start: date
    period_end: date
    planned_date: date
    allowed_until: date


@dataclass(frozen=True)
class Decision:
    candidate: Candidate | None
    reason: str
    evaluated: tuple[Candidate, ...]


def configure_logging(log_file: str) -> logging.Logger:
    path = Path(log_file)
    path.parent.mkdir(parents=True, exist_ok=True)
    logger = logging.getLogger("dwh_scheduler")
    logger.setLevel(logging.INFO)
    logger.handlers.clear()
    formatter = logging.Formatter("%(asctime)s %(levelname)s %(message)s")
    file_handler = logging.FileHandler(path, encoding="utf-8")
    file_handler.setFormatter(formatter)
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    logger.propagate = False
    return logger


def add_months(value: date, months: int) -> date:
    month_index = value.year * 12 + value.month - 1 + months
    year, month_zero = divmod(month_index, 12)
    return date(year, month_zero + 1, 1)


def planned_weekday_with_rollover(
    year: int, month: int, week_ordinal: int, weekday_iso: int
) -> date:
    if week_ordinal not in range(1, 6):
        raise ValueError("week_ordinal deve essere compreso tra 1 e 5")
    if weekday_iso not in range(1, 8):
        raise ValueError("weekday_iso deve essere compreso tra 1 e 7")

    first_day = date(year, month, 1)
    week_1_monday = first_day - timedelta(days=first_day.isoweekday() - 1)
    candidate = week_1_monday + timedelta(
        weeks=week_ordinal - 1, days=weekday_iso - 1
    )
    return candidate if candidate.month == month else candidate + timedelta(days=7)


def validate_schedule(schedule: Schedule) -> None:
    frequency = schedule.frequency_code
    if frequency not in FREQUENCIES:
        raise ValueError("frequency_code non riconosciuto")
    if frequency == "DAILY":
        values = (schedule.anchor_month, schedule.week_ordinal,
                  schedule.weekday_iso, schedule.retry_days)
        if any(value is not None for value in values):
            raise ValueError("DAILY non ammette parametri calendario o retry")
        return
    if schedule.retry_days is None or schedule.retry_days < 0:
        raise ValueError("retry_days deve essere valorizzato e >= 0")
    if schedule.weekday_iso not in range(1, 8):
        raise ValueError("weekday_iso deve essere compreso tra 1 e 7")
    if frequency == "WEEKLY":
        if schedule.anchor_month is not None or schedule.week_ordinal is not None:
            raise ValueError("WEEKLY non ammette anchor_month o week_ordinal")
        return
    if schedule.week_ordinal not in range(1, 6):
        raise ValueError("week_ordinal deve essere compreso tra 1 e 5")
    if frequency == "MONTHLY":
        if schedule.anchor_month is not None:
            raise ValueError("MONTHLY non ammette anchor_month")
        return
    if schedule.anchor_month not in range(1, 13):
        raise ValueError("anchor_month deve essere compreso tra 1 e 12")


def next_period_start(schedule: Schedule, period_start: date) -> date:
    if schedule.frequency_code == "DAILY":
        return period_start + timedelta(days=1)
    if schedule.frequency_code == "WEEKLY":
        return period_start + timedelta(days=7)
    months = 1 if schedule.frequency_code == "MONTHLY" else FREQUENCY_MONTHS[schedule.frequency_code]
    return add_months(period_start, months)


def candidate_period_starts(schedule: Schedule, today: date) -> list[date]:
    if schedule.frequency_code == "DAILY":
        latest = today
        previous = today - timedelta(days=1)
    elif schedule.frequency_code == "WEEKLY":
        latest = today - timedelta(days=today.isoweekday() - 1)
        previous = latest - timedelta(days=7)
    elif schedule.frequency_code == "MONTHLY":
        latest = today.replace(day=1)
        previous = add_months(latest, -1)
    else:
        step = FREQUENCY_MONTHS[schedule.frequency_code]
        current_index = today.year * 12 + today.month - 1
        anchor_index = schedule.anchor_month - 1
        latest_index = current_index - ((current_index - anchor_index) % step)
        latest_year, latest_month_zero = divmod(latest_index, 12)
        latest = date(latest_year, latest_month_zero + 1, 1)
        previous = add_months(latest, -step)
    return sorted((previous, latest))


def planned_date(schedule: Schedule, period_start: date) -> date:
    if schedule.frequency_code == "DAILY":
        return period_start
    if schedule.frequency_code == "WEEKLY":
        return period_start + timedelta(days=schedule.weekday_iso - 1)
    return planned_weekday_with_rollover(
        period_start.year, period_start.month,
        schedule.week_ordinal, schedule.weekday_iso,
    )


def evaluate_schedule(schedule: Schedule, today: date) -> Decision:
    validate_schedule(schedule)
    candidates = []
    for start in candidate_period_starts(schedule, today):
        next_start = next_period_start(schedule, start)
        next_planned = planned_date(schedule, next_start)
        planned = planned_date(schedule, start)
        period_end = next_start - timedelta(days=1)
        if schedule.frequency_code == "DAILY":
            allowed_until = planned
        else:
            retry_end = planned + timedelta(days=schedule.retry_days)
            allowed_until = min(retry_end, next_planned - timedelta(days=1))
            if allowed_until < planned:
                allowed_until = planned
        candidate = Candidate(start, period_end, planned, allowed_until)
        candidates.append(candidate)

    for candidate in candidates:
        if (schedule.last_success_period_start is not None
                and candidate.period_start <= schedule.last_success_period_start):
            continue
        if candidate.planned_date <= today <= candidate.allowed_until:
            return Decision(candidate, "data pianificata o finestra retry attiva", tuple(candidates))

    if candidates and schedule.last_success_period_start is not None:
        current = candidates[-1]
        if current.period_start <= schedule.last_success_period_start:
            reason = "periodo corrente gia' completato con successo"
        elif today < current.planned_date:
            reason = "data pianificata non ancora raggiunta"
        else:
            reason = "data pianificata e finestra retry non attive per oggi"
    elif candidates and today < candidates[-1].planned_date:
        reason = "data pianificata non ancora raggiunta"
    else:
        reason = "nessun periodo dovuto oggi o retry scaduto"
    return Decision(None, reason, tuple(candidates))
def invocation_should_run(mode: str, decision: Decision) -> bool:
    if mode == "manual-ui":
        return True
    if mode != "scheduled":
        raise ValueError(f"Modalita' di avvio non riconosciuta: {mode}")
    return decision.candidate is not None



def load_runtime(key_file: str, encrypted_config: str):
    scripts_dir = os.getenv(
        "FMR_RUNNER_SCRIPTS_DIR",
        "/opt/etl/frontiere-metadata-runner/scripts",
    )
    if scripts_dir not in sys.path:
        sys.path.insert(0, scripts_dir)
    from secrets_common import decrypt_payload, postgres_conninfo

    payload = decrypt_payload(encrypted_config, key_file)
    conninfo = postgres_conninfo(
        payload["hcbi"]["jdbc_url"],
        payload["hcbi"]["username"],
        payload["hcbi"]["password"],
    )
    return payload, conninfo


def connect_db(conninfo, autocommit=False):
    import psycopg

    return psycopg.connect(
        **conninfo,
        autocommit=autocommit,
        connect_timeout=10,
        keepalives=1,
        keepalives_idle=30,
        application_name="dwh_schedule_runner",
    )


def load_enabled_schedules(conninfo) -> list[Schedule]:
    from psycopg.rows import dict_row

    sql = f"""
        SELECT schedule_id, process_code, process_description, enabled,
               frequency_code, anchor_month, week_ordinal, weekday_iso,
               retry_days, last_success_period_start
          FROM {DB_SCHEMA}.dwh_schedule
         WHERE enabled = true
         ORDER BY schedule_id
    """
    with connect_db(conninfo) as conn:
        with conn.cursor(row_factory=dict_row) as cursor:
            rows = cursor.execute(sql).fetchall()
    return [Schedule(**row) for row in rows]


def reconcile_interrupted_runs(conninfo, logger) -> None:
    message = "Run RUNNING senza processo scheduler attivo; riconciliato all'avvio successivo"
    with connect_db(conninfo) as conn:
        rows = conn.execute(
            f"UPDATE {DB_SCHEMA}.dwh_schedule_run "
            "SET status='FAILED', finished_at=clock_timestamp(), "
            "error_message=left(COALESCE(error_message, %s), 4000) "
            "WHERE status='RUNNING' RETURNING schedule_id",
            (message,),
        ).fetchall()
        if rows:
            conn.execute(
                f"UPDATE {DB_SCHEMA}.dwh_schedule "
                "SET last_attempt_status='FAILED', last_attempt_at=clock_timestamp(), "
                "last_error_message=left(%s, 4000), updated_at=clock_timestamp() "
                "WHERE last_attempt_status='RUNNING'",
                (message,),
            )
    if rows:
        logger.warning("Riconciliati %d tentativi RUNNING interrotti", len(rows))


def insert_terminal_run(conninfo, schedule: Schedule, status: str, message: str,
                        trigger_source: str, requested_by: str | None = None,
                        candidate: Candidate | None = None,
                        update_summary: bool = True) -> None:
    run_id = uuid.uuid4()
    with connect_db(conninfo) as conn:
        conn.execute(
            f"INSERT INTO {DB_SCHEMA}.dwh_schedule_run "
            "(run_id, schedule_id, process_code, planned_date, period_start, "
            "period_end, trigger_source, requested_by, started_at, finished_at, "
            "status, return_code, duration_ms, error_message) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, clock_timestamp(), "
            "clock_timestamp(), %s, 0, 0, %s)",
            (run_id, schedule.schedule_id, schedule.process_code,
             candidate.planned_date if candidate else None,
             candidate.period_start if candidate else None,
             candidate.period_end if candidate else None,
             trigger_source, requested_by, status, message[:4000]),
        )
        if update_summary:
            conn.execute(
                f"UPDATE {DB_SCHEMA}.dwh_schedule "
                "SET last_attempt_at=clock_timestamp(), last_attempt_status=%s, "
                "last_error_message=%s, updated_at=clock_timestamp() "
                "WHERE schedule_id=%s",
                (status, message[:4000], schedule.schedule_id),
            )


def start_run(conninfo, schedule: Schedule, candidate: Candidate | None,
              trigger_source: str, requested_by: str | None) -> uuid.UUID:
    run_id = uuid.uuid4()
    with connect_db(conninfo) as conn:
        conn.execute(
            f"INSERT INTO {DB_SCHEMA}.dwh_schedule_run "
            "(run_id, schedule_id, process_code, planned_date, period_start, "
            "period_end, trigger_source, requested_by, status) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'RUNNING')",
            (run_id, schedule.schedule_id, schedule.process_code,
             candidate.planned_date if candidate else None,
             candidate.period_start if candidate else None,
             candidate.period_end if candidate else None,
             trigger_source, requested_by),
        )
        conn.execute(
            f"UPDATE {DB_SCHEMA}.dwh_schedule "
            "SET last_attempt_at=clock_timestamp(), last_attempt_status='RUNNING', "
            "last_error_message=NULL, updated_at=clock_timestamp() "
            "WHERE schedule_id=%s",
            (schedule.schedule_id,),
        )
    return run_id


def finish_run(conninfo, run_id: uuid.UUID, schedule: Schedule,
               candidate: Candidate | None, status: str, return_code: int,
               duration_ms: int, message: str | None) -> None:
    message = message[:4000] if message else None
    with connect_db(conninfo) as conn:
        conn.execute(
            f"UPDATE {DB_SCHEMA}.dwh_schedule_run "
            "SET finished_at=clock_timestamp(), status=%s, return_code=%s, "
            "duration_ms=%s, error_message=%s WHERE run_id=%s",
            (status, return_code, duration_ms, message, run_id),
        )
        if status == "SUCCESS" and candidate is not None:
            conn.execute(
                f"UPDATE {DB_SCHEMA}.dwh_schedule "
                "SET last_success_at=clock_timestamp(), last_success_period_start=%s, "
                "last_attempt_at=clock_timestamp(), last_attempt_status='SUCCESS', "
                "last_error_message=NULL, updated_at=clock_timestamp() "
                "WHERE schedule_id=%s",
                (candidate.period_start, schedule.schedule_id),
            )
        elif status == "SUCCESS":
            conn.execute(
                f"UPDATE {DB_SCHEMA}.dwh_schedule "
                "SET last_attempt_at=clock_timestamp(), last_attempt_status='SUCCESS', "
                "last_error_message=NULL, updated_at=clock_timestamp() "
                "WHERE schedule_id=%s",
                (schedule.schedule_id,),
            )
        else:
            conn.execute(
                f"UPDATE {DB_SCHEMA}.dwh_schedule "
                "SET last_attempt_at=clock_timestamp(), last_attempt_status='FAILED', "
                "last_error_message=%s, updated_at=clock_timestamp() "
                "WHERE schedule_id=%s",
                (message, schedule.schedule_id),
            )


def stop_nifi_group(payload, pg_name: str, logger) -> None:
    scripts_dir = os.getenv(
        "FMR_RUNNER_SCRIPTS_DIR",
        "/opt/etl/frontiere-metadata-runner/scripts",
    )
    if scripts_dir not in sys.path:
        sys.path.insert(0, scripts_dir)
    from run_group_cycle import Nifi, find_group_id, set_group_state

    nifi = Nifi(payload["nifi"])
    group_id = find_group_id(nifi, pg_name)
    set_group_state(nifi, group_id, "STOPPED")
    logger.info("Process Group %s fermato dal runner", pg_name)


def run_group_cycle(lock_conn, payload, args, logger) -> int:
    project_dir = Path(args.project_dir)
    command = [
        str(project_dir / "bin/run_group_cycle.sh"),
        "--pg-name", args.process_group,
        "--frontiere-timeout", str(args.frontiere_timeout),
        "--dwh-timeout", str(args.dwh_timeout),
        "--poll-interval", str(args.poll_interval),
        "--quiet-seconds", str(args.quiet_seconds),
    ]
    environment = os.environ.copy()
    environment.update({
        "FMR_PROJECT_DIR": str(project_dir),
        "FMR_PYTHON": args.python_path,
        "FMR_SECRET_KEY_FILE": args.key_file,
        "FMR_ENCRYPTED_CONFIG": args.encrypted_config,
        "FMR_LOG_DIR": args.fmr_log_dir,
    })
    logger.info("Avvio runner NiFi: %s", " ".join(command))
    process = subprocess.Popen(
        command, cwd=str(project_dir), env=environment,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, bufsize=0,
    )
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)
    decoder = codecs.getincrementaldecoder("utf-8")("replace")
    pending = ""
    last_lock_check = time.monotonic()
    try:
        while True:
            for key, _ in selector.select(timeout=1):
                chunk = os.read(key.fd, 4096)
                if not chunk:
                    selector.unregister(key.fileobj)
                    pending += decoder.decode(b"", final=True)
                    if pending:
                        logger.info("[run_group_cycle] %s", pending.rstrip())
                        pending = ""
                    continue
                pending += decoder.decode(chunk)
                while "\n" in pending:
                    line, pending = pending.split("\n", 1)
                    logger.info("[run_group_cycle] %s", line.rstrip())

            if process.poll() is not None and not selector.get_map():
                break
            if time.monotonic() - last_lock_check >= LOCK_HEARTBEAT_SECONDS:
                last_lock_check = time.monotonic()
                try:
                    lock_conn.execute("SELECT 1")
                except Exception:
                    logger.exception("Connessione lock persa durante il ciclo NiFi")
                    try:
                        stop_nifi_group(payload, args.process_group, logger)
                    except Exception:
                        logger.exception("Impossibile fermare il Process Group NiFi")
                    process.terminate()
                    try:
                        process.wait(timeout=30)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
                    return 1
        if pending:
            logger.info("[run_group_cycle] %s", pending.rstrip())
        return process.wait()
    finally:
        selector.close()
        if process.stdout is not None:
            process.stdout.close()


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("scheduled", "manual-ui"),
                        default="scheduled")
    parser.add_argument("--requested-by")
    parser.add_argument("--lock-wait-seconds", type=int, default=int(os.getenv(
        "DWH_SCHEDULER_LOCK_WAIT_SECONDS", "7200")))
    parser.add_argument("--lock-poll-seconds", type=int, default=int(os.getenv(
        "DWH_SCHEDULER_LOCK_POLL_SECONDS", "15")))
    parser.add_argument("--manual-group", default="DWH_MANUAL_LAUNCH")
    parser.add_argument("--project-dir", default=os.getenv(
        "FMR_PROJECT_DIR", "/opt/etl/frontiere-metadata-runner"))
    parser.add_argument("--python-path", default=os.getenv(
        "FMR_PYTHON", "/opt/etl/frontiere-metadata-runner/.venv/bin/python"))
    parser.add_argument("--scripts-dir", default=os.getenv(
        "FMR_RUNNER_SCRIPTS_DIR", "/opt/etl/frontiere-metadata-runner/scripts"))
    parser.add_argument("--key-file", default=os.getenv(
        "FMR_SECRET_KEY_FILE", "/opt/etl/secrets/fmr-secrets.key"))
    parser.add_argument("--encrypted-config", default=os.getenv(
        "FMR_ENCRYPTED_CONFIG", "/opt/etl/config/fmr-secrets.json.enc"))
    parser.add_argument("--fmr-log-dir", default=os.getenv(
        "FMR_LOG_DIR", "/opt/etl/log/frontiere-metadata-runner"))
    parser.add_argument("--log-file", default=os.getenv(
        "DWH_SCHEDULER_LOG_FILE", "/opt/etl/log/dwh-scheduler/dwh-scheduler.log"))
    parser.add_argument("--timezone", default=os.getenv(
        "DWH_SCHEDULER_TIMEZONE", "Europe/Rome"))
    parser.add_argument("--process-group", default=os.getenv(
        "FMR_PROCESS_GROUP", "FRONTIERE_METADATA_RUNNER"))
    parser.add_argument("--frontiere-timeout", type=int, default=int(os.getenv(
        "FMR_FRONTIERE_TIMEOUT", "3600")))
    parser.add_argument("--dwh-timeout", type=int, default=int(os.getenv(
        "FMR_DWH_TIMEOUT", "1800")))
    parser.add_argument("--poll-interval", type=int, default=int(os.getenv(
        "FMR_POLL_INTERVAL", "5")))
    parser.add_argument("--quiet-seconds", type=int, default=int(os.getenv(
        "FMR_QUIET_SECONDS", "10")))
    args = parser.parse_args()
    if args.lock_wait_seconds < 0 or args.lock_poll_seconds < 1:
        parser.error("lock wait must be non-negative and lock poll must be positive")
    return args


def main() -> int:
    args = parse_args()
    logger = configure_logging(args.log_file)
    lock_conn = None
    payload = None
    conninfo = None
    schedule = None
    candidate = None
    run_id = None
    run_started = None
    trigger_source = "SCHEDULED" if args.mode == "scheduled" else "MANUAL_UI"
    requested_by = args.requested_by if args.mode == "manual-ui" else None
    try:
        os.environ["FMR_RUNNER_SCRIPTS_DIR"] = args.scripts_dir
        payload, conninfo = load_runtime(args.key_file, args.encrypted_config)
        if args.mode == "manual-ui":
            stop_nifi_group(payload, args.manual_group, logger)

        lock_conn = connect_db(conninfo, autocommit=True)
        acquired = lock_conn.execute(
            "SELECT pg_try_advisory_lock(%s, %s)",
            (LOCK_KEY_CLASS, LOCK_KEY_ID),
        ).fetchone()[0]
        lock_deadline = time.monotonic() + args.lock_wait_seconds
        while (not acquired and args.mode == "scheduled"
               and time.monotonic() < lock_deadline):
            logger.info("Lock occupato; attendo %s secondi prima di riprovare",
                        args.lock_poll_seconds)
            time.sleep(min(args.lock_poll_seconds,
                           max(0, lock_deadline - time.monotonic())))
            acquired = lock_conn.execute(
                "SELECT pg_try_advisory_lock(%s, %s)",
                (LOCK_KEY_CLASS, LOCK_KEY_ID),
            ).fetchone()[0]
        if not acquired:
            logger.warning("Richiesta %s rifiutata: lock globale gia' detenuto",
                           trigger_source)
            schedules = load_enabled_schedules(conninfo)
            if len(schedules) == 1:
                insert_terminal_run(
                    conninfo, schedules[0], "SKIPPED",
                    "Richiesta non avviata: esiste un'altra esecuzione attiva",
                    trigger_source, requested_by, update_summary=False,
                )
            return 75 if args.mode == "manual-ui" else 0

        reconcile_interrupted_runs(conninfo, logger)
        schedules = load_enabled_schedules(conninfo)
        if len(schedules) != 1:
            logger.error("Attese esattamente una schedulazione abilitata; trovate %d",
                         len(schedules))
            return 2
        schedule = schedules[0]
        now = datetime.now(ZoneInfo(args.timezone))
        decision = evaluate_schedule(schedule, now.date())
        candidate = decision.candidate
        if not invocation_should_run(args.mode, decision):
            message = "SKIPPED: " + decision.reason
            logger.info("Processo %s non dovuto: %s",
                        schedule.process_code, decision.reason)
            insert_terminal_run(
                conninfo, schedule, "SKIPPED", message,
                trigger_source, requested_by,
            )
            return 0

        if args.mode == "manual-ui":
            if candidate is None:
                logger.info("Avvio manuale UI del processo %s; nessun periodo dovuto oggi",
                            schedule.process_code)
            else:
                logger.info("Avvio manuale UI del processo %s per il periodo %s",
                            schedule.process_code, candidate.period_start)
        else:
            logger.info(
                "Processo %s dovuto: planned=%s period=%s..%s",
                schedule.process_code, candidate.planned_date,
                candidate.period_start, candidate.period_end,
            )

        run_started = time.monotonic()
        run_id = start_run(
            conninfo, schedule, candidate, trigger_source, requested_by
        )
        return_code = run_group_cycle(lock_conn, payload, args, logger)
        duration_ms = int((time.monotonic() - run_started) * 1000)
        status = "SUCCESS" if return_code == 0 else "FAILED"
        message = None if return_code == 0 else f"run_group_cycle exit code {return_code}"
        finish_run(conninfo, run_id, schedule, candidate, status,
                   return_code, duration_ms, message)
        logger.info("Run %s concluso con stato %s", run_id, status)
        return return_code
    except Exception as exc:
        logger.exception("Errore scheduler: %s", exc)
        if schedule is not None and conninfo is not None:
            message = f"Errore scheduler: {exc}"
            try:
                if run_id is not None:
                    duration_ms = int((time.monotonic() - run_started) * 1000)
                    finish_run(conninfo, run_id, schedule, candidate,
                               "FAILED", 1, duration_ms, message)
                else:
                    insert_terminal_run(
                        conninfo, schedule, "FAILED", message,
                        trigger_source, requested_by, candidate,
                    )
            except Exception:
                logger.exception("Impossibile registrare l'esito FAILED nel database")
        return 1
    finally:
        if lock_conn is not None:
            try:
                lock_conn.close()
            except Exception:
                logger.exception("Errore chiudendo la connessione del lock")


if __name__ == "__main__":
    raise SystemExit(main())
