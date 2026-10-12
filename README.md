# RAS_Prezziario

Sistema di acquisizione, normalizzazione, integrazione e analisi del prezzario regionale.

## Architettura

- PostgreSQL 17
- PL/pgSQL
- NiFi
- Pentaho
- Power BI

## Layer

- SRC_TMP
- STG
- DWH
- DIM
- FCT

## Installazione

psql -U postgres -d ras -f scripts/install.sql
