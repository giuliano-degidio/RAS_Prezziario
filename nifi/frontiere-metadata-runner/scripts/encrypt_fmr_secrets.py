#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path
from cryptography.fernet import Fernet
from secrets_common import validate_payload

def secure_write(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    try:
        os.write(fd, data)
    finally:
        os.close(fd)
    os.chmod(path, 0o600)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--key-file", default="/opt/etl/secrets/fmr-secrets.key")
    parser.add_argument("--output", default="/opt/etl/config/fmr-secrets.json.enc")
    parser.add_argument("--delete-input", action="store_true")
    args = parser.parse_args()
    payload = validate_payload(json.loads(Path(args.input).read_text(encoding="utf-8")))
    key_path = Path(args.key_file)
    key = key_path.read_bytes().strip() if key_path.exists() else Fernet.generate_key()
    if not key_path.exists():
        secure_write(key_path, key + b"\n")
    token = Fernet(key).encrypt(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    secure_write(args.output, token + b"\n")
    Fernet(key).decrypt(token)
    if args.delete_input:
        Path(args.input).unlink()
    print("[OK] Segreti cifrati e verificati")

if __name__ == "__main__":
    main()
