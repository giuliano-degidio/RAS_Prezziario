import logging
import os
import sys
import unittest
import uuid
from datetime import date
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

sys.path.insert(
    0,
    str(Path(__file__).resolve().parents[3] / "frontiere-metadata-runner" / "scripts"),
)

import dwh_schedule_runner as runner
from dwh_schedule_runner import (
    Schedule,
    evaluate_schedule,
    invocation_should_run,
    planned_weekday_with_rollover,
)


def schedule(**overrides):
    values = {
        "schedule_id": 1,
        "process_code": "DWH_REFRESH",
        "process_description": "Refresh DWH",
        "enabled": True,
        "frequency_code": "DAILY",
        "anchor_month": None,
        "week_ordinal": None,
        "weekday_iso": None,
        "retry_days": None,
        "last_success_period_start": None,
    }
    values.update(overrides)
    return Schedule(**values)


class ScheduleCalendarTests(unittest.TestCase):
    def test_week_one_rolls_forward_when_weekday_is_outside_month(self):
        self.assertEqual(
            planned_weekday_with_rollover(2020, 3, 1, 6),
            date(2020, 3, 7),
        )

    def test_daily_schedule_advances_to_the_next_day(self):
        decision = evaluate_schedule(schedule(), date(2025, 4, 17))
        self.assertEqual(decision.candidate.planned_date, date(2025, 4, 17))
        self.assertEqual(evaluate_schedule(schedule(), date(2025, 4, 18)).candidate.planned_date,
                         date(2025, 4, 18))

    def test_weekly_retry_window_includes_its_last_day(self):
        weekly = schedule(
            frequency_code="WEEKLY",
            weekday_iso=1,
            retry_days=6,
        )
        decision = evaluate_schedule(weekly, date(2024, 3, 10))
        self.assertEqual(decision.candidate.planned_date, date(2024, 3, 4))
        self.assertEqual(decision.candidate.allowed_until, date(2024, 3, 10))

    def test_retry_expiry_does_not_run_on_the_following_day(self):
        weekly = schedule(
            frequency_code="WEEKLY",
            weekday_iso=1,
            retry_days=0,
        )
        self.assertIsNone(evaluate_schedule(weekly, date(2024, 3, 5)).candidate)

    def test_manual_ui_bypasses_due_date_but_scheduler_does_not(self):
        weekly = schedule(
            frequency_code="WEEKLY",
            weekday_iso=1,
            retry_days=0,
        )
        decision = evaluate_schedule(weekly, date(2024, 3, 5))
        self.assertFalse(invocation_should_run("scheduled", decision))
        self.assertTrue(invocation_should_run("manual-ui", decision))

    def test_monthly_period_rollover_keeps_logical_period(self):
        monthly = schedule(
            frequency_code="MONTHLY",
            week_ordinal=1,
            weekday_iso=1,
            retry_days=3,
        )
        decision = evaluate_schedule(monthly, date(2024, 3, 4))
        self.assertEqual(decision.candidate.period_start, date(2024, 3, 1))
        self.assertEqual(decision.candidate.planned_date, date(2024, 3, 4))

    def test_successful_logical_period_is_not_repeated(self):
        monthly = schedule(
            frequency_code="MONTHLY",
            week_ordinal=1,
            weekday_iso=1,
            retry_days=3,
            last_success_period_start=date(2024, 3, 1),
        )
        self.assertIsNone(evaluate_schedule(monthly, date(2024, 3, 4)).candidate)


class LogIngestionIsolationTests(unittest.TestCase):
    def test_ingestion_failure_does_not_change_scheduler_exit_code(self):
        candidate = runner.Candidate(
            period_start=date(2026, 1, 1),
            period_end=date(2026, 1, 31),
            planned_date=date(2026, 1, 5),
            allowed_until=date(2026, 1, 8),
        )
        schedule_row = schedule()
        decision = runner.Decision(candidate, "due", (candidate,))
        run_id = uuid.uuid4()
        args = SimpleNamespace(
            mode="scheduled",
            requested_by=None,
            scripts_dir="/opt/etl/frontiere-metadata-runner/scripts",
            key_file="/tmp/key",
            encrypted_config="/tmp/config",
            log_file="/tmp/scheduler.log",
            fmr_log_dir="/tmp/fmr-log",
            timezone="Europe/Rome",
            lock_wait_seconds=0,
            lock_poll_seconds=1,
        )
        lock_result = SimpleNamespace(fetchone=lambda: (True,))
        lock_conn = SimpleNamespace(
            execute=lambda *args, **kwargs: lock_result,
            close=lambda: None,
        )
        test_logger = logging.Logger("log-ingestion-test")
        test_logger.addHandler(logging.NullHandler())

        with patch.dict(os.environ, {"FMR_LOG_INGESTION_ENABLED": "true"}), \
             patch.object(runner, "parse_args", return_value=args), \
             patch.object(runner, "configure_logging", return_value=test_logger), \
             patch.object(runner, "load_runtime", return_value=({}, {"dbname": "test"})), \
             patch.object(runner, "connect_db", return_value=lock_conn), \
             patch.object(runner, "reconcile_interrupted_runs"), \
             patch.object(runner, "load_enabled_schedules", return_value=[schedule_row]), \
             patch.object(runner, "evaluate_schedule", return_value=decision), \
             patch.object(runner, "invocation_should_run", return_value=True), \
             patch.object(runner, "start_run", return_value=run_id), \
             patch.object(runner, "run_group_cycle", return_value=7), \
             patch.object(runner, "finish_run") as finish_run, \
             patch("load_execution_logs.capture_log_sources", return_value={"snapshot": True}), \
             patch("load_execution_logs.finalize_log_manifest", return_value={"files": []}), \
             patch("load_execution_logs.ingest_manifest", side_effect=RuntimeError("ingest unavailable")):
            exit_code = runner.main()

        self.assertEqual(exit_code, 7)
        self.assertEqual(finish_run.call_args.args[4], "FAILED")


if __name__ == "__main__":
    unittest.main()
