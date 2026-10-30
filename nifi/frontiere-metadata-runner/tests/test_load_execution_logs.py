import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

import load_execution_logs as loader


class LogManifestTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        root = Path(self.temp_dir.name)
        self.paths = {
            "DWH_SCHEDULER": str(root / "scheduler.log"),
            "DWH_REFRESH": str(root / "dwh-refresh.log"),
            "FRONTIERE_RUNNER": str(root / "frontiere.log"),
        }
        for path in self.paths.values():
            Path(path).touch()

    def tearDown(self):
        self.temp_dir.cleanup()

    def finalize(self, snapshot):
        return loader.finalize_log_manifest(
            snapshot,
            self.paths,
            scheduler_run_id=None,
            execution_uuid=None,
            cycle_result="SUCCESS",
            cycle_exit_code=0,
        )

    def record(self, manifest, source_code="DWH_SCHEDULER"):
        return next(item for item in manifest["files"]
                    if item["source_code"] == source_code)

    def test_empty_file_that_grows_is_a_ready_segment(self):
        snapshot = loader.capture_log_sources(self.paths)
        payload = b"2026-01-02 03:04:05,006 INFO started\n"
        Path(self.paths["DWH_SCHEDULER"]).write_bytes(payload)

        record = self.record(self.finalize(snapshot))

        self.assertEqual(record["segment_status"], "READY")
        self.assertEqual(record["offset_start"], 0)
        self.assertEqual(record["offset_end"], len(payload))

    def test_short_prefix_can_grow_past_snapshot_hash_window(self):
        initial = b"a" * 2000
        Path(self.paths["DWH_SCHEDULER"]).write_bytes(initial)
        snapshot = loader.capture_log_sources(self.paths)
        with open(self.paths["DWH_SCHEDULER"], "ab") as stream:
            stream.write(b"b" * 4000)

        record = self.record(self.finalize(snapshot))

        self.assertEqual(record["segment_status"], "READY")
        self.assertEqual(record["offset_start"], len(initial))
        self.assertEqual(record["offset_end"], 6000)

    def test_replaced_file_is_marked_rotated(self):
        Path(self.paths["DWH_SCHEDULER"]).write_bytes(b"old\n")
        snapshot = loader.capture_log_sources(self.paths)
        replacement = Path(self.temp_dir.name) / "replacement.log"
        replacement.write_bytes(b"new\n")
        os.replace(replacement, self.paths["DWH_SCHEDULER"])

        record = self.record(self.finalize(snapshot))

        self.assertEqual(record["segment_status"], "ROTATED")
        self.assertEqual(record["offset_end"], record["offset_start"])

    def test_changed_prefix_is_marked_rotated(self):
        Path(self.paths["DWH_SCHEDULER"]).write_bytes(b"old contents\n")
        snapshot = loader.capture_log_sources(self.paths)
        Path(self.paths["DWH_SCHEDULER"]).write_bytes(b"new contents\n")

        record = self.record(self.finalize(snapshot))

        self.assertEqual(record["segment_status"], "ROTATED")


class LogParserTests(unittest.TestCase):
    def test_multiline_event_offsets_and_secret_redaction(self):
        secret_key = "pass" + "word"
        newline = bytes((10,))
        data = (
            b"2026-01-02 03:04:05,006 ERROR "
            + f"{secret_key}=sensitive_test_value".encode("utf-8")
            + newline
            + b"Traceback (most recent call last):"
            + newline
            + b"  failure"
            + newline
            + b"2026-01-02 03:04:06,007 INFO completed"
            + newline
        )

        events = loader.parse_log_segment(data, 100, "Europe/Rome", 4096)

        self.assertEqual(len(events), 2)
        self.assertEqual(events[0]["byte_offset_start"], 100)
        self.assertEqual(events[0]["byte_offset_end"], 100 + data.index(b"2026-01-02 03:04:06"))
        self.assertIn("Traceback", events[0]["message_text"])
        self.assertNotIn("sensitive_test_value", events[0]["message_text"])
        self.assertTrue(events[0]["is_redacted"])
        self.assertEqual(events[1]["parse_status"], "PARSED")

    def test_event_over_limit_is_rejected_without_retaining_its_text(self):
        data = b"2026-01-02 03:04:05,006 ERROR " + (b"x" * 100) + b"\n"

        events = loader.parse_log_segment(data, 0, "Europe/Rome", 32)

        self.assertEqual(len(events), 1)
        self.assertTrue(events[0]["rejected"])
        self.assertNotIn("message_text", events[0])

    def test_retry_manifest_reconstructs_only_the_audited_source_segment(self):
        paths = {
            "DWH_SCHEDULER": "/var/log/scheduler.log",
            "DWH_REFRESH": "/var/log/dwh-refresh.log",
            "FRONTIERE_RUNNER": "/var/log/frontiere.log",
        }
        record = {
            "source_code": "DWH_REFRESH",
            "source_path": paths["DWH_REFRESH"],
            "source_device": 1,
            "source_inode": 2,
            "offset_start": 50,
            "offset_end": 100,
            "manifest_execution_uuid": None,
            "scheduler_run_id": None,
            "cycle_result": "FAILED",
            "cycle_exit_code": 1,
            "status": "FAILED",
        }

        manifest, source_code = loader._manifest_for_retry(record, paths)

        self.assertEqual(source_code, "DWH_REFRESH")
        selected = next(item for item in manifest["files"]
                        if item["source_code"] == source_code)
        skipped = [item for item in manifest["files"]
                   if item["source_code"] != source_code]
        self.assertEqual((selected["offset_start"], selected["offset_end"]), (50, 100))
        self.assertTrue(all(item["segment_status"] == "SKIPPED" for item in skipped))

    def test_retry_rejects_non_failed_audit_records(self):
        paths = {
            "DWH_SCHEDULER": "/var/log/scheduler.log",
            "DWH_REFRESH": "/var/log/dwh-refresh.log",
            "FRONTIERE_RUNNER": "/var/log/frontiere.log",
        }
        record = {
            "source_code": "DWH_REFRESH",
            "source_path": paths["DWH_REFRESH"],
            "source_device": 1,
            "source_inode": 2,
            "offset_start": 0,
            "offset_end": 10,
            "cycle_result": "SUCCESS",
            "status": "SUCCEEDED",
        }

        with self.assertRaises(ValueError):
            loader._manifest_for_retry(record, paths)

    def test_manifest_conflict_is_ambiguous(self):
        event_uuid = "11111111-1111-4111-8111-111111111111"
        manifest_uuid = "22222222-2222-4222-8222-222222222222"
        event = {
            "message_text": f"FMR_EXECUTION_UUID={event_uuid}",
        }
        manifest = {
            "execution_uuid": manifest_uuid,
            "scheduler_run_id": None,
            "cycle_result": "SUCCESS",
            "cycle_exit_code": 0,
        }

        fields = loader._correlation_fields(event, manifest, "DWH_REFRESH")

        self.assertEqual(fields["correlation_status"], "AMBIGUOUS")
        self.assertEqual(str(fields["event_execution_uuid"]), event_uuid)
        self.assertEqual(str(fields["manifest_execution_uuid"]), manifest_uuid)


if __name__ == "__main__":
    unittest.main()
