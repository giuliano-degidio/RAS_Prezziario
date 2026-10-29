import unittest
from datetime import date

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


if __name__ == "__main__":
    unittest.main()
