#!/usr/bin/env python3
"""Persist closed, allowlisted FMR log segments without changing cycle results."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import stat
import sys
import uuid
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

SOURCE_CODES = {"DWH_SCHEDULER", "DWH_REFRESH", "FRONTIERE_RUNNER"}
LOG_HEADER = re.compile(
    r"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3})\s+([A-Z]+)\s+(.*)$"
)
UUID_VALUE = r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
EXECUTION_UUID = re.compile(
    rf"\b(?:FMR_EXECUTION_UUID|execution_uuid)\s*=\s*({UUID_VALUE})\b",
    re.IGNORECASE,
)
SCHEDULER_RUN_ID = re.compile(
    rf"\bRun\s+({UUID_VALUE})\s+concluso\b", re.IGNORECASE
)
CHAIN_ID = re.compile(r"\bchain_id\s*=\s*(\d+)\b", re.IGNORECASE)
EXIT_CODE = re.compile(r"\bexit(?:ed)?\s+code\s*[:=]?\s*(\d+)\b", re.IGNORECASE)
PROCESS_NAME = re.compile(r"^([A-Za-z0-9_]+)\s+(?:SUCCEEDED|FAILED|SKIPPED)\b")
SECRET_VALUE = re.compile(
    r"(?i)\b(password|passwd|pwd|token|secret|api[_-]?key|client[_-]?secret|authorization)"
    r"(\s*[:=]\s*)(\"[^\"]*\"|'[^']*'|[^\s,;]+)"
)
BEARER_VALUE = re.compile(r"(?i)\bBearer\s+[^\s,;]+")
URL_PASSWORD = re.compile(r"(?i)(://[^:/@\s]+:)[^@/\s]+(@)")
PRIVATE_KEY = re.compile(
    r"-----BEGIN [^-]*PRIVATE KEY-----.*?-----END [^-]*PRIVATE KEY-----",
    re.DOTALL,
)


def configured_sources(scheduler_log_file: str, fmr_log_dir: str) -> dict[str, str]:
    """Build the fixed source allowlist from trusted service configuration."""
    fmr = Path(fmr_log_dir).absolute()
    return {
        "DWH_SCHEDULER": str(Path(scheduler_log_file).absolute()),
        "DWH_REFRESH": str(fmr / "dwh-refresh.log"),
        "FRONTIERE_RUNNER": str(fmr / "frontiere-metadata-runner.log"),
    }


def _regular_file_snapshot(path: str, prefix_length: int | None = None) -> dict:
    file_path = Path(path)
    try:
        path_stat = file_path.lstat()
    except FileNotFoundError:
        return {"status": "MISSING", "size": 0}
    if stat.S_ISLNK(path_stat.st_mode) or not stat.S_ISREG(path_stat.st_mode):
        return {"status": "FAILED", "error_code": "UNSAFE_SOURCE"}

    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    fd = os.open(path, flags)
    try:
        opened = os.fstat(fd)
        if (opened.st_dev, opened.st_ino) != (path_stat.st_dev, path_stat.st_ino):
            return {"status": "FAILED", "error_code": "SOURCE_CHANGED"}
        prefix_length = min(opened.st_size, 4096) if prefix_length is None else prefix_length
        if prefix_length > opened.st_size:
            return {"status": "FAILED", "error_code": "SOURCE_TRUNCATED"}
        prefix = os.pread(fd, prefix_length, 0) if prefix_length else b""
        return {
            "status": "READY",
            "device": opened.st_dev,
            "inode": opened.st_ino,
            "size": opened.st_size,
            "modified_at": datetime.fromtimestamp(
                opened.st_mtime, tz=ZoneInfo("UTC")
            ).isoformat(),
            "prefix_length": prefix_length,
            "prefix_sha256": hashlib.sha256(prefix).hexdigest(),
        }
    finally:
        os.close(fd)


def capture_log_sources(source_paths: dict[str, str]) -> dict:
    if set(source_paths) != SOURCE_CODES:
        raise ValueError("La allowlist deve contenere esattamente i tre source_code previsti")
    files = []
    for source_code, source_path in source_paths.items():
        path = str(Path(source_path).absolute())
        try:
            snapshot = _regular_file_snapshot(path)
        except PermissionError:
            snapshot = {"status": "FAILED", "error_code": "PERMISSION_DENIED"}
        except OSError:
            snapshot = {"status": "FAILED", "error_code": "SOURCE_STAT_FAILED"}
        files.append({"source_code": source_code, "source_path": path, **snapshot})
    return {
        "version": 1,
        "captured_at": datetime.now(ZoneInfo("UTC")).isoformat(),
        "sources": files,
    }


def finalize_log_manifest(
    start_snapshot: dict,
    source_paths: dict[str, str],
    *,
    scheduler_run_id: str | None,
    execution_uuid: str | None,
    cycle_result: str,
    cycle_exit_code: int | None,
    timezone: str = "Europe/Rome",
) -> dict:
    if cycle_result not in {"SUCCESS", "FAILED", "SKIPPED"}:
        raise ValueError("cycle_result non riconosciuto")
    if start_snapshot.get("version") != 1:
        raise ValueError("Versione snapshot non supportata")
    start_by_code = {item["source_code"]: item for item in start_snapshot["sources"]}
    files = []
    for source_code, source_path in source_paths.items():
        normalized_path = str(Path(source_path).absolute())
        start = start_by_code[source_code]
        if start["source_path"] != normalized_path:
            raise ValueError("La allowlist è cambiata durante il ciclo")
        try:
            end = _regular_file_snapshot(
                normalized_path, start.get("prefix_length")
                if start.get("status") == "READY" else None
            )
        except PermissionError:
            end = {"status": "FAILED", "error_code": "PERMISSION_DENIED"}
        except OSError:
            end = {"status": "FAILED", "error_code": "SOURCE_STAT_FAILED"}

        start_status = start["status"]
        end_status = end["status"]
        segment_status = "READY"
        source_device = start.get("device")
        source_inode = start.get("inode")
        offset_start = start.get("size", 0)
        offset_end = end.get("size", 0)
        error_code = None

        if start_status == "FAILED" or end_status == "FAILED":
            segment_status = "FAILED"
            error_code = start.get("error_code") or end.get("error_code")
        elif start_status == "MISSING" and end_status == "MISSING":
            segment_status = "SKIPPED" if cycle_result == "SKIPPED" else "MISSING"
            source_device = source_inode = None
            offset_start = offset_end = 0
        elif start_status == "MISSING" and end_status == "READY":
            source_device, source_inode = end["device"], end["inode"]
            offset_start, offset_end = 0, end["size"]
        elif start_status == "READY" and end_status == "MISSING":
            segment_status = "MISSING"
            error_code = "SOURCE_MISSING_AT_CLOSE"
        elif start_status == "READY" and end_status == "READY":
            same_identity = (start["device"], start["inode"]) == (end["device"], end["inode"])
            prefix_unchanged = (
                end["prefix_length"] >= start["prefix_length"]
                and end["prefix_sha256"] == start["prefix_sha256"]
            )
            if not same_identity or end["size"] < start["size"] or not prefix_unchanged:
                segment_status = "ROTATED"
                error_code = "SOURCE_ROTATED_OR_TRUNCATED"
                offset_end = offset_start
            else:
                offset_end = end["size"]
        else:
            segment_status = "FAILED"
            error_code = "INVALID_SNAPSHOT_STATE"

        files.append({
            "source_code": source_code,
            "source_path": normalized_path,
            "source_device": source_device,
            "source_inode": source_inode,
            "offset_start": offset_start,
            "offset_end": offset_end,
            "modified_at": end.get("modified_at"),
            "segment_status": segment_status,
            "error_code": error_code,
        })

    return {
        "version": 1,
        "captured_at": start_snapshot["captured_at"],
        "closed_at": datetime.now(ZoneInfo("UTC")).isoformat(),
        "timezone": timezone,
        "cycle_result": cycle_result,
        "cycle_exit_code": cycle_exit_code,
        "execution_uuid": _parse_uuid(execution_uuid),
        "scheduler_run_id": _parse_uuid(scheduler_run_id),
        "files": files,
    }


def _parse_uuid(value: str | None) -> uuid.UUID | None:
    if value in (None, ""):
        return None
    try:
        return uuid.UUID(str(value))
    except (ValueError, AttributeError) as exc:
        raise ValueError("UUID non valido nel manifest") from exc


@dataclass
class _CurrentEvent:
    start: int
    end: int
    size: int
    timestamp_text: str | None
    level: str | None
    parts: list[str]
    parse_status: str
    rejected: bool = False


def parse_log_segment(data: bytes, offset_start: int, timezone: str,
                      max_event_bytes: int) -> list[dict]:
    if offset_start < 0 or max_event_bytes < 1:
        raise ValueError("offset o limite evento non valido")
    tz = ZoneInfo(timezone)
    result: list[dict] = []
    current: _CurrentEvent | None = None
    position = offset_start

    def flush() -> None:
        nonlocal current
        if current is None:
            return
        if current.rejected:
            result.append({
                "rejected": True,
                "byte_offset_start": current.start,
                "byte_offset_end": current.end,
            })
            current = None
            return
        timestamp = None
        if current.timestamp_text is not None:
            try:
                naive = datetime.strptime(current.timestamp_text, "%Y-%m-%d %H:%M:%S,%f")
                timestamp = naive.replace(tzinfo=tz)
            except ValueError:
                current.parse_status = "UNPARSED"
        message, redacted = redact_message("\n".join(current.parts))
        result.append({
            "rejected": False,
            "byte_offset_start": current.start,
            "byte_offset_end": current.end,
            "event_timestamp": timestamp,
            "log_level": current.level,
            "message_text": message,
            "parse_status": current.parse_status,
            "is_redacted": redacted,
        })
        current = None

    for raw_line in data.splitlines(keepends=True):
        line_start = position
        position += len(raw_line)
        text = raw_line.decode("utf-8", errors="replace")
        replaced = "\ufffd" in text
        if text.endswith("\n"):
            text = text[:-1]
        if text.endswith("\r"):
            text = text[:-1]
        match = LOG_HEADER.match(text)
        if match:
            flush()
            status = "ENCODING_REPLACED" if replaced else "PARSED"
            current = _CurrentEvent(
                start=line_start,
                end=position,
                size=len(raw_line),
                timestamp_text=match.group(1),
                level=match.group(2),
                parts=[match.group(3)],
                parse_status=status,
            )
        else:
            if current is None:
                current = _CurrentEvent(
                    start=line_start,
                    end=position,
                    size=len(raw_line),
                    timestamp_text=None,
                    level=None,
                    parts=[text],
                    parse_status="ENCODING_REPLACED" if replaced else "UNPARSED",
                )
            else:
                current.end = position
                current.size += len(raw_line)
                if replaced:
                    current.parse_status = "ENCODING_REPLACED"
                if not current.rejected:
                    current.parts.append(text)

        if current is not None and current.size > max_event_bytes:
            current.rejected = True
            current.parts.clear()
    flush()
    return result


def redact_message(message: str) -> tuple[str, bool]:
    redacted = False

    def mask_assignment(match: re.Match) -> str:
        nonlocal redacted
        redacted = True
        return f"{match.group(1)}{match.group(2)}[REDACTED]"

    message = PRIVATE_KEY.sub("[REDACTED PRIVATE KEY]", message)
    if "[REDACTED PRIVATE KEY]" in message:
        redacted = True
    message = URL_PASSWORD.sub(r"\1[REDACTED]\2", message)
    if "[REDACTED]" in message:
        redacted = True
    message = BEARER_VALUE.sub("Bearer [REDACTED]", message)
    if "Bearer [REDACTED]" in message:
        redacted = True
    message = SECRET_VALUE.sub(mask_assignment, message)
    return message, redacted


def _correlation_fields(event: dict, manifest: dict, source_code: str) -> dict:
    message = event["message_text"]
    execution_values = {
        uuid.UUID(value) for value in EXECUTION_UUID.findall(message)
    }
    scheduler_values = {
        uuid.UUID(value) for value in SCHEDULER_RUN_ID.findall(message)
    }
    manifest_execution = _parse_uuid(str(manifest["execution_uuid"]) if manifest.get("execution_uuid") else None)
    manifest_scheduler = _parse_uuid(str(manifest["scheduler_run_id"]) if manifest.get("scheduler_run_id") else None)

    event_execution = next(iter(execution_values)) if len(execution_values) == 1 else None
    event_scheduler = next(iter(scheduler_values)) if len(scheduler_values) == 1 else None
    ambiguous = len(execution_values) > 1 or len(scheduler_values) > 1
    ambiguous |= bool(event_execution and manifest_execution and event_execution != manifest_execution)
    ambiguous |= bool(event_scheduler and manifest_scheduler and event_scheduler != manifest_scheduler)

    if ambiguous:
        correlation = "AMBIGUOUS"
    elif (manifest.get("cycle_result") == "SKIPPED"
          and source_code == "DWH_SCHEDULER" and event_execution is None):
        correlation = "NOT_APPLICABLE"
    elif event_execution or manifest_execution or event_scheduler or manifest_scheduler:
        correlation = "CORRELATED"
    else:
        correlation = "UNCORRELATED"

    chain_match = CHAIN_ID.search(message)
    exit_match = EXIT_CODE.search(message)
    process_match = PROCESS_NAME.search(message)
    return {
        "event_execution_uuid": event_execution,
        "manifest_execution_uuid": manifest_execution,
        "event_scheduler_run_id": event_scheduler,
        "manifest_scheduler_run_id": manifest_scheduler,
        "chain_id": int(chain_match.group(1)) if chain_match else None,
        "process_name": process_match.group(1) if process_match else None,
        "cycle_exit_code": int(exit_match.group(1)) if exit_match else manifest.get("cycle_exit_code"),
        "correlation_status": correlation,
    }


def _event_hash(source_code: str, device: int, inode: int,
                start: int, end: int, message: str) -> str:
    identity = "\0".join((source_code, str(device), str(inode),
                           str(start), str(end), message))
    return hashlib.sha256(identity.encode("utf-8")).hexdigest()


def _read_segment(file_record: dict, max_segment_bytes: int) -> bytes:
    start = file_record["offset_start"]
    end = file_record["offset_end"]
    if end < start:
        raise ValueError("offset_end precede offset_start")
    length = end - start
    if length > max_segment_bytes:
        raise OverflowError("SEGMENT_TOO_LARGE")
    path = file_record["source_path"]
    path_stat = Path(path).lstat()
    if stat.S_ISLNK(path_stat.st_mode) or not stat.S_ISREG(path_stat.st_mode):
        raise PermissionError("La sorgente non è un file regolare autorizzato")
    fd = os.open(path, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
    try:
        opened = os.fstat(fd)
        if (opened.st_dev, opened.st_ino) != (
            file_record["source_device"], file_record["source_inode"]
        ):
            raise FileNotFoundError("SOURCE_ROTATED")
        if opened.st_size < end:
            raise FileNotFoundError("SOURCE_TRUNCATED")
        os.lseek(fd, start, os.SEEK_SET)
        chunks = []
        remaining = length
        while remaining:
            chunk = os.read(fd, min(1024 * 1024, remaining))
            if not chunk:
                raise OSError("Segmento log troncato durante la lettura")
            chunks.append(chunk)
            remaining -= len(chunk)
        return b"".join(chunks)
    finally:
        os.close(fd)


def _insert_audit(conninfo: dict, file_record: dict, manifest: dict,
                  retry_of_ingestion_id: int | None = None) -> int:
    import psycopg

    with psycopg.connect(**conninfo) as conn:
        row = conn.execute(
            "INSERT INTO hcbi_utility.etl_execution_log_ingestion "
            "(source_code, source_path, source_device, source_inode, offset_start, "
            "offset_end, manifest_execution_uuid, scheduler_run_id, cycle_result, "
            "cycle_exit_code, status, retry_of_ingestion_id) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'RUNNING', %s) "
            "RETURNING ingestion_id",
            (file_record["source_code"], file_record["source_path"],
             file_record.get("source_device"), file_record.get("source_inode"),
             file_record["offset_start"], file_record["offset_end"],
             manifest.get("execution_uuid"), manifest.get("scheduler_run_id"),
             manifest["cycle_result"], manifest.get("cycle_exit_code"),
             retry_of_ingestion_id),
        ).fetchone()
        return row[0]


def _update_audit(conninfo: dict, ingestion_id: int, *, status: str,
                  counts: dict, bytes_read: int, error_code: str | None = None,
                  error_message: str | None = None) -> None:
    import psycopg

    with psycopg.connect(**conninfo) as conn:
        conn.execute(
            "UPDATE hcbi_utility.etl_execution_log_ingestion SET "
            "finished_at=clock_timestamp(), status=%s, events_read=%s, "
            "events_inserted=%s, events_duplicate=%s, events_rejected=%s, "
            "bytes_read=%s, error_code=%s, error_message=%s "
            "WHERE ingestion_id=%s",
            (status, counts["read"], counts["inserted"], counts["duplicate"],
             counts["rejected"], bytes_read, error_code,
             error_message[:4000] if error_message else None, ingestion_id),
        )


def _persist_event_batch(conninfo: dict, ingestion_id: int, file_record: dict,
                         manifest: dict, batch: list[dict], timezone: str,
                         current_counts: dict) -> dict:
    import psycopg

    delta = {"read": 0, "inserted": 0, "duplicate": 0, "rejected": 0}
    with psycopg.connect(**conninfo) as conn:
        with conn.transaction():
            for item in batch:
                delta["read"] += 1
                if item["rejected"]:
                    delta["rejected"] += 1
                    continue
                correlation = _correlation_fields(item, manifest, file_record["source_code"])
                message = item["message_text"]
                values = (
                    ingestion_id, file_record["source_code"], file_record["source_path"],
                    file_record["source_device"], file_record["source_inode"],
                    item["byte_offset_start"], item["byte_offset_end"], None, None,
                    item["event_timestamp"], item["log_level"],
                    correlation["event_execution_uuid"],
                    correlation["manifest_execution_uuid"],
                    correlation["event_scheduler_run_id"],
                    correlation["manifest_scheduler_run_id"],
                    correlation["chain_id"], correlation["process_name"],
                    correlation["cycle_exit_code"], correlation["correlation_status"],
                    item["parse_status"], item["is_redacted"], message,
                    _event_hash(file_record["source_code"], file_record["source_device"],
                                file_record["source_inode"], item["byte_offset_start"],
                                item["byte_offset_end"], message),
                )
                inserted = conn.execute(
                    "INSERT INTO hcbi_utility.etl_execution_log_event "
                    "(ingestion_id, source_code, source_path, source_device, source_inode, "
                    "byte_offset_start, byte_offset_end, source_line_start, source_line_end, "
                    "event_timestamp, log_level, event_execution_uuid, manifest_execution_uuid, "
                    "event_scheduler_run_id, manifest_scheduler_run_id, chain_id, process_name, "
                    "cycle_exit_code, correlation_status, parse_status, is_redacted, message_text, "
                    "event_hash) VALUES (" + ", ".join(["%s"] * len(values)) + ") "
                    "ON CONFLICT ON CONSTRAINT uq_etl_execution_log_event_identity DO NOTHING "
                    "RETURNING event_id",
                    values,
                ).fetchone()
                if inserted:
                    delta["inserted"] += 1
                else:
                    delta["duplicate"] += 1
            totals = {key: current_counts[key] + delta[key] for key in current_counts}
            conn.execute(
                "UPDATE hcbi_utility.etl_execution_log_ingestion SET events_read=%s, "
                "events_inserted=%s, events_duplicate=%s, events_rejected=%s "
                "WHERE ingestion_id=%s",
                (totals["read"], totals["inserted"], totals["duplicate"],
                 totals["rejected"], ingestion_id),
            )
    return totals


def _validate_manifest(manifest: dict, source_paths: dict[str, str]) -> None:
    if not isinstance(manifest, dict) or manifest.get("version") != 1:
        raise ValueError("Manifest non valido o versione non supportata")
    if manifest.get("cycle_result") not in {"SUCCESS", "FAILED", "SKIPPED"}:
        raise ValueError("cycle_result non valido")
    if set(source_paths) != SOURCE_CODES:
        raise ValueError("Allowlist incompleta")
    _parse_uuid(str(manifest["scheduler_run_id"]) if manifest.get("scheduler_run_id") else None)
    _parse_uuid(str(manifest["execution_uuid"]) if manifest.get("execution_uuid") else None)
    files = manifest.get("files")
    if not isinstance(files, list) or len(files) != len(SOURCE_CODES):
        raise ValueError("Il manifest deve contenere un segmento per ogni sorgente")
    seen = set()
    for item in files:
        code = item.get("source_code")
        if code not in SOURCE_CODES or code in seen:
            raise ValueError("source_code mancante o duplicato")
        seen.add(code)
        if item.get("source_path") != str(Path(source_paths[code]).absolute()):
            raise ValueError("Percorso non presente nell'allowlist")
        if item.get("segment_status") not in {"READY", "ROTATED", "MISSING", "FAILED", "SKIPPED"}:
            raise ValueError("segment_status non valido")
        start, end = item.get("offset_start"), item.get("offset_end")
        if not isinstance(start, int) or not isinstance(end, int) or start < 0 or end < start:
            raise ValueError("Intervallo byte non valido")
        for name in ("source_device", "source_inode"):
            value = item.get(name)
            if value is not None and (not isinstance(value, int) or value < 0):
                raise ValueError(f"{name} non valido")


def ingest_manifest(conninfo: dict, manifest: dict, source_paths: dict[str, str],
                    *, batch_size: int = 200, max_segment_bytes: int = 64 * 1024 * 1024,
                    max_event_bytes: int = 1024 * 1024,
                    only_source_code: str | None = None,
                    retry_of_ingestion_id: int | None = None) -> list[dict]:
    if batch_size < 1 or max_segment_bytes < 1 or max_event_bytes < 1:
        raise ValueError("Limiti ingestione non validi")
    _validate_manifest(manifest, source_paths)
    if only_source_code is not None and only_source_code not in SOURCE_CODES:
        raise ValueError("source_code di retry non valido")
    outcomes = []
    for file_record in manifest["files"]:
        if only_source_code is not None and file_record["source_code"] != only_source_code:
            continue
        ingestion_id = _insert_audit(
            conninfo, file_record, manifest,
            retry_of_ingestion_id=retry_of_ingestion_id,
        )
        counts = {"read": 0, "inserted": 0, "duplicate": 0, "rejected": 0}
        status = file_record["segment_status"]
        if status == "ROTATED":
            _update_audit(conninfo, ingestion_id, status="ROTATED", counts=counts,
                          bytes_read=0, error_code=file_record.get("error_code") or "SOURCE_ROTATED",
                          error_message="Identità o dimensione della sorgente cambiata; segmento non letto")
            outcomes.append({"source_code": file_record["source_code"], "status": "ROTATED", "ingestion_id": ingestion_id})
            continue
        if status == "MISSING":
            if manifest["cycle_result"] == "SKIPPED":
                terminal = "SKIPPED"
                error_code = None
                error_message = None
            else:
                terminal = "FAILED"
                error_code = "SOURCE_MISSING"
                error_message = "File sorgente assente alla chiusura del ciclo"
            _update_audit(conninfo, ingestion_id, status=terminal, counts=counts,
                          bytes_read=0, error_code=error_code, error_message=error_message)
            outcomes.append({"source_code": file_record["source_code"], "status": terminal, "ingestion_id": ingestion_id})
            continue
        if status == "FAILED":
            _update_audit(conninfo, ingestion_id, status="FAILED", counts=counts,
                          bytes_read=0, error_code=file_record.get("error_code") or "SNAPSHOT_FAILED",
                          error_message="Impossibile acquisire un'identità sicura del file sorgente")
            outcomes.append({"source_code": file_record["source_code"], "status": "FAILED", "ingestion_id": ingestion_id})
            continue
        if file_record["offset_end"] == file_record["offset_start"]:
            _update_audit(conninfo, ingestion_id, status="SKIPPED", counts=counts,
                          bytes_read=0)
            outcomes.append({"source_code": file_record["source_code"], "status": "SKIPPED", "ingestion_id": ingestion_id})
            continue

        totals = counts
        bytes_read = 0
        try:
            data = _read_segment(file_record, max_segment_bytes)
            bytes_read = len(data)
            items = parse_log_segment(data, file_record["offset_start"],
                                      manifest.get("timezone", "Europe/Rome"),
                                      max_event_bytes)
            for start in range(0, len(items), batch_size):
                totals = _persist_event_batch(
                    conninfo, ingestion_id, file_record, manifest,
                    items[start:start + batch_size],
                    manifest.get("timezone", "Europe/Rome"), totals,
                )
            terminal = "SUCCEEDED_WITH_REJECTS" if totals["rejected"] else "SUCCEEDED"
            _update_audit(conninfo, ingestion_id, status=terminal, counts=totals,
                          bytes_read=bytes_read)
            outcomes.append({"source_code": file_record["source_code"],
                             "status": terminal, "ingestion_id": ingestion_id,
                             **totals, "bytes_read": len(data)})
        except FileNotFoundError as exc:
            terminal = "ROTATED" if "SOURCE_ROTATED" in str(exc) else "FAILED"
            code = "SOURCE_ROTATED" if terminal == "ROTATED" else "SOURCE_CHANGED"
            _update_audit(conninfo, ingestion_id, status=terminal, counts=totals,
                          bytes_read=bytes_read, error_code=code, error_message=str(exc))
            outcomes.append({"source_code": file_record["source_code"], "status": terminal, "ingestion_id": ingestion_id})
        except PermissionError as exc:
            _update_audit(conninfo, ingestion_id, status="FAILED", counts=totals,
                          bytes_read=bytes_read, error_code="PERMISSION_DENIED", error_message=str(exc))
            outcomes.append({"source_code": file_record["source_code"], "status": "FAILED", "ingestion_id": ingestion_id})
        except OverflowError as exc:
            _update_audit(conninfo, ingestion_id, status="FAILED", counts=totals,
                          bytes_read=bytes_read, error_code="SEGMENT_TOO_LARGE", error_message=str(exc))
            outcomes.append({"source_code": file_record["source_code"], "status": "FAILED", "ingestion_id": ingestion_id})
        except (OSError, ValueError, UnicodeError) as exc:
            _update_audit(conninfo, ingestion_id, status="FAILED", counts=totals,
                          bytes_read=bytes_read, error_code="READ_OR_PARSE_ERROR", error_message=str(exc))
            outcomes.append({"source_code": file_record["source_code"], "status": "FAILED", "ingestion_id": ingestion_id})
        except Exception as exc:
            _update_audit(conninfo, ingestion_id, status="FAILED", counts=totals,
                          bytes_read=bytes_read, error_code="DATABASE_OR_INTERNAL_ERROR", error_message=str(exc))
            outcomes.append({"source_code": file_record["source_code"], "status": "FAILED", "ingestion_id": ingestion_id})
    return outcomes


def _preview_manifest(manifest: dict, source_paths: dict[str, str],
                      max_segment_bytes: int, max_event_bytes: int) -> list[dict]:
    _validate_manifest(manifest, source_paths)
    results = []
    for file_record in manifest["files"]:
        if file_record["segment_status"] != "READY":
            results.append({"source_code": file_record["source_code"],
                            "status": file_record["segment_status"], "events": 0})
            continue
        if file_record["offset_end"] == file_record["offset_start"]:
            results.append({"source_code": file_record["source_code"], "status": "SKIPPED", "events": 0})
            continue
        data = _read_segment(file_record, max_segment_bytes)
        events = parse_log_segment(data, file_record["offset_start"],
                                   manifest.get("timezone", "Europe/Rome"), max_event_bytes)
        results.append({"source_code": file_record["source_code"],
                        "status": "READY", "events": len(events),
                        "rejected": sum(1 for event in events if event["rejected"]),
                        "bytes_read": len(data)})
    return results


def _manifest_for_retry(record: dict, source_paths: dict[str, str],
                        timezone: str = "Europe/Rome") -> tuple[dict, str]:
    source_code = record["source_code"]
    if source_code not in SOURCE_CODES:
        raise ValueError("Sorgente audit non riconosciuta")
    if record["status"] != "FAILED":
        raise ValueError("Sono recuperabili soltanto tentativi in stato FAILED")
    if record["source_path"] != str(Path(source_paths[source_code]).absolute()):
        raise ValueError("Il percorso audit non corrisponde alla allowlist corrente")
    if record["source_device"] is None or record["source_inode"] is None:
        raise ValueError("Il tentativo non conserva un'identità sorgente recuperabile")
    if record["cycle_result"] not in {"SUCCESS", "FAILED", "SKIPPED"}:
        raise ValueError("L'audit originale non contiene un esito ciclo valido")

    files = []
    for code, path in source_paths.items():
        if code == source_code:
            files.append({
                "source_code": code,
                "source_path": str(Path(path).absolute()),
                "source_device": record["source_device"],
                "source_inode": record["source_inode"],
                "offset_start": record["offset_start"],
                "offset_end": record["offset_end"],
                "segment_status": "READY",
                "error_code": None,
            })
        else:
            files.append({
                "source_code": code,
                "source_path": str(Path(path).absolute()),
                "source_device": None,
                "source_inode": None,
                "offset_start": 0,
                "offset_end": 0,
                "segment_status": "SKIPPED",
                "error_code": None,
            })
    now = datetime.now(ZoneInfo("UTC")).isoformat()
    return ({
        "version": 1,
        "captured_at": now,
        "closed_at": now,
        "timezone": timezone,
        "cycle_result": record["cycle_result"],
        "cycle_exit_code": record["cycle_exit_code"],
        "execution_uuid": record["manifest_execution_uuid"],
        "scheduler_run_id": record["scheduler_run_id"],
        "files": files,
    }, source_code)


def _load_retry_manifest(conninfo: dict, ingestion_id: int,
                         source_paths: dict[str, str], timezone: str) -> tuple[dict, str]:
    import psycopg

    with psycopg.connect(**conninfo) as conn:
        row = conn.execute(
            "SELECT source_code, source_path, source_device, source_inode, "
            "offset_start, offset_end, manifest_execution_uuid, scheduler_run_id, "
            "cycle_result, cycle_exit_code, status "
            "FROM hcbi_utility.etl_execution_log_ingestion WHERE ingestion_id=%s",
            (ingestion_id,),
        ).fetchone()
    if row is None:
        raise ValueError(f"Ingestion {ingestion_id} non trovata")
    columns = (
        "source_code", "source_path", "source_device", "source_inode",
        "offset_start", "offset_end", "manifest_execution_uuid", "scheduler_run_id",
        "cycle_result", "cycle_exit_code", "status",
    )
    return _manifest_for_retry(dict(zip(columns, row)), source_paths, timezone)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    source_group = parser.add_mutually_exclusive_group(required=True)
    source_group.add_argument("--manifest-file")
    source_group.add_argument("--retry-ingestion-id", type=int)
    parser.add_argument("--timezone", default="Europe/Rome")
    parser.add_argument("--key-file", default=os.getenv(
        "FMR_SECRET_KEY_FILE", "/opt/etl/secrets/fmr-secrets.key"))
    parser.add_argument("--encrypted-config", default=os.getenv(
        "FMR_ENCRYPTED_CONFIG", "/opt/etl/config/fmr-secrets.json.enc"))
    parser.add_argument("--scheduler-log-file", default=os.getenv(
        "DWH_SCHEDULER_LOG_FILE", "/opt/etl/log/dwh-scheduler/dwh-scheduler.log"))
    parser.add_argument("--fmr-log-dir", default=os.getenv(
        "FMR_LOG_DIR", "/opt/etl/log/frontiere-metadata-runner"))
    parser.add_argument("--max-segment-bytes", type=int, default=64 * 1024 * 1024)
    parser.add_argument("--max-event-bytes", type=int, default=1024 * 1024)
    parser.add_argument("--batch-size", type=int, default=200)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    try:
        sources = configured_sources(args.scheduler_log_file, args.fmr_log_dir)
        retry_source_code = None
        if args.retry_ingestion_id is not None:
            from secrets_common import decrypt_payload, postgres_conninfo

            payload = decrypt_payload(args.encrypted_config, args.key_file)
            conninfo = postgres_conninfo(
                payload["hcbi"]["jdbc_url"], payload["hcbi"]["username"],
                payload["hcbi"]["password"],
            )
            manifest, retry_source_code = _load_retry_manifest(
                conninfo, args.retry_ingestion_id, sources, args.timezone
            )
        else:
            manifest = json.loads(Path(args.manifest_file).read_text(encoding="utf-8"))
            conninfo = None

        if args.dry_run:
            result = _preview_manifest(manifest, sources,
                                       args.max_segment_bytes, args.max_event_bytes)
        else:
            if conninfo is None:
                from secrets_common import decrypt_payload, postgres_conninfo

                payload = decrypt_payload(args.encrypted_config, args.key_file)
                conninfo = postgres_conninfo(
                    payload["hcbi"]["jdbc_url"], payload["hcbi"]["username"],
                    payload["hcbi"]["password"],
                )
            result = ingest_manifest(
                conninfo, manifest, sources, batch_size=args.batch_size,
                max_segment_bytes=args.max_segment_bytes,
                max_event_bytes=args.max_event_bytes,
                only_source_code=retry_source_code,
                retry_of_ingestion_id=args.retry_ingestion_id,
            )
        print(json.dumps(result, default=str, ensure_ascii=False))
        if any(item.get("status") == "FAILED" for item in result):
            return 5
        if any(item.get("status") == "ROTATED" for item in result):
            return 8
        if any(item.get("rejected", 0) for item in result):
            return 2
        return 0
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        print(f"Manifest/lettura non valida: {exc}", file=sys.stderr)
        return 6


if __name__ == "__main__":
    raise SystemExit(main())
