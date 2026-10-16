#!/usr/bin/env python3
import argparse
import psycopg
from secrets_common import decrypt_payload, postgres_conninfo

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--connect", action="store_true")
    parser.add_argument("--key-file", default="/opt/etl/secrets/fmr-secrets.key")
    parser.add_argument("--encrypted-config", default="/opt/etl/config/fmr-secrets.json.enc")
    args = parser.parse_args()
    payload = decrypt_payload(args.encrypted_config, args.key_file)
    for name in ("hcbi", "rasop"):
        section = payload[name]
        conninfo = postgres_conninfo(section["jdbc_url"], section["username"], section["password"])
        if args.connect:
            with psycopg.connect(**conninfo, connect_timeout=10) as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT current_database(), current_user")
                    print(f"[OK] {name}: {cur.fetchone()}")
    print("[OK] Configurazione cifrata valida")

if __name__ == "__main__":
    main()
