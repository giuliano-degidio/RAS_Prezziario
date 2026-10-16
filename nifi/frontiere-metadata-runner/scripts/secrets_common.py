#!/usr/bin/env python3
import json
from pathlib import Path
from urllib.parse import urlparse, unquote
from cryptography.fernet import Fernet, InvalidToken

REQUIRED = {
    "nifi": ("base_url", "username", "password", "verify_ssl"),
    "rasop": ("jdbc_url", "username", "password"),
    "hcbi": ("jdbc_url", "username", "password"),
}

def validate_payload(payload):
    if not isinstance(payload, dict):
        raise ValueError("Il payload deve essere un oggetto JSON")
    for section, keys in REQUIRED.items():
        node = payload.get(section)
        if not isinstance(node, dict):
            raise ValueError(f"Sezione mancante o non valida: {section}")
        for key in keys:
            value = node.get(key)
            if value in (None, ""):
                raise ValueError(f"Valore mancante: {section}.{key}")
            if isinstance(value, str) and (value == "CHANGE_ME" or "_HOST" in value):
                raise ValueError(f"Placeholder non sostituito: {section}.{key}")
    if not isinstance(payload["nifi"]["verify_ssl"], bool):
        raise ValueError("nifi.verify_ssl deve essere true o false")
    return payload

def decrypt_payload(encrypted_path, key_path):
    key = Path(key_path).read_bytes().strip()
    token = Path(encrypted_path).read_bytes().strip()
    try:
        raw = Fernet(key).decrypt(token)
    except InvalidToken as exc:
        raise ValueError("Chiave o file cifrato non validi") from exc
    return validate_payload(json.loads(raw.decode("utf-8")))

def postgres_conninfo(jdbc_url, username, password):
    prefix = "jdbc:postgresql://"
    if not jdbc_url.startswith(prefix):
        raise ValueError("JDBC URL PostgreSQL non valido")
    parsed = urlparse("postgresql://" + jdbc_url[len(prefix):])
    if not parsed.hostname or not parsed.path.strip("/"):
        raise ValueError("JDBC URL PostgreSQL incompleto")
    params = {
        "host": parsed.hostname,
        "port": parsed.port or 5432,
        "dbname": unquote(parsed.path.strip("/")),
        "user": username,
        "password": password,
    }
    if parsed.query:
        for pair in parsed.query.split("&"):
            if "=" in pair:
                key, value = pair.split("=", 1)
                if key in {"sslmode", "connect_timeout", "application_name"}:
                    params[key] = unquote(value)
    return params
