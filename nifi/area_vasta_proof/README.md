# NiFi proof flow - frontiera_anag_area_vasta

This folder contains a deployable proof flow for NiFi.

## What it does

1. Generates a trigger flowfile.
2. Truncates `hcbi_ras.frontiera_anag_area_vasta` on the `hcbi` database.
3. Executes the query on `rasop`:

```sql
SELECT id::character varying(100) AS id, nome::character varying(100) AS nome
FROM public.aree_vaste
ORDER BY id;
```

4. Inserts the result into `hcbi_ras.frontiera_anag_area_vasta`.

## Files

- `flow_spec.json` - declarative flow manifest
- `deploy_area_vasta.py` - NiFi REST API deployer

## Prerequisites

- NiFi server reachable at `https://192.168.248.135:8443/nifi`
- The PostgreSQL JDBC driver JAR available on disk and readable by NiFi
- Database credentials supplied at deploy time through environment variables

## Environment variables

```bash
export NIFI_BASE_URL='https://192.168.248.135:8443/nifi'
export NIFI_USERNAME='giuldegi'
export NIFI_PASSWORD='***'

export RASOP_JDBC_URL='jdbc:postgresql://192.168.248.135:5432/RAS_Operazionales'
export RASOP_DB_USER='postgres'
export RASOP_DB_PASSWORD='***'

export HCBI_JDBC_URL='jdbc:postgresql://192.168.248.135:5432/hcbi'
export HCBI_DB_USER='hcbi'
export HCBI_DB_PASSWORD='***'

# required if the driver is not already bundled in NiFi
export POSTGRES_JDBC_JAR='/opt/nifi-2.11.0/lib/postgresql-42.7.4.jar'

# set to 1 only if you want SSL verification enabled
export NIFI_VERIFY_SSL=0
```

## Deploy

```bash
python3 deploy_area_vasta.py
```

## After deploy

Open NiFi, locate the process group `POC_FRONTIERA_ANAG_AREA_VASTA`, then start the processors in order.

If the PostgreSQL JDBC driver is not already available in NiFi, download the PostgreSQL JDBC jar, place it in a readable path, and set `POSTGRES_JDBC_JAR` before running the deployer.
