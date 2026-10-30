# Runbook — Ingestione dei log FMR in PostgreSQL

## Ambito

Questo runbook riguarda il riversamento opzionale dei log del ciclo scheduler/FMR nelle tabelle `hcbi_utility.etl_execution_log_ingestion` e `hcbi_utility.etl_execution_log_event`. Non modifica il deploy o la configurazione dei Process Group NiFi.

Sorgenti lette:

- `/opt/etl/log/dwh-scheduler/dwh-scheduler.log`
- `/opt/etl/log/frontiere-metadata-runner/dwh-refresh.log`
- `/opt/etl/log/frontiere-metadata-runner/frontiere-metadata-runner.log`

Il sistema non cancella i file, non li ruota e non importa automaticamente lo storico precedente all'attivazione.

## Prerequisiti e attivazione

1. Applicare nell'ordine `ddl/hcbi_utility/table/etl_execution_log_ingestion.sql` e `ddl/hcbi_utility/table/etl_execution_log_event.sql` con una utenza DBA.
2. Verificare tabelle e audit con `nifi/frontiere-metadata-runner/sql/03_verify_log_ingestion.sql` e confermare che il login HCBI abbia i grant del ruolo `hcbi_ras`.
3. Distribuire i file tramite `nifi/Schedulazione_Caricamenti/deploy/unix-linux/install_dwh_scheduler.sh`. L'installer non abilita timer o service e conserva `/etc/sysconfig/dwh-scheduler` già esistente.
4. Verificare che l'utente di servizio possa leggere tutti i file log e che il virtualenv disponga di `psycopg`.
5. Dopo un collaudo autorizzato, impostare `FMR_LOG_INGESTION_ENABLED=true` in `/etc/sysconfig/dwh-scheduler`. Il valore iniziale è `false`.

Il valore viene letto a ogni avvio del servizio. Non serve riavviare NiFi; il successivo ciclo scheduler userà la nuova impostazione.

## Monitoraggio

Ultimi tentativi:

```sql
SELECT ingestion_id, source_code, scheduler_run_id, cycle_result, status,
       events_read, events_inserted, events_duplicate, events_rejected,
       bytes_read, error_code, error_message, started_at, finished_at
FROM hcbi_utility.etl_execution_log_ingestion
ORDER BY started_at DESC
LIMIT 50;
```

Riconciliazione e classificazione:

```sql
SELECT source_code, status,
       sum(events_read) AS events_read,
       sum(events_inserted) AS events_inserted,
       sum(events_duplicate) AS events_duplicate,
       sum(events_rejected) AS events_rejected,
       sum(bytes_read) AS bytes_read
FROM hcbi_utility.etl_execution_log_ingestion
GROUP BY source_code, status
ORDER BY source_code, status;

SELECT source_code, correlation_status, parse_status, count(*) AS event_count
FROM hcbi_utility.etl_execution_log_event
GROUP BY source_code, correlation_status, parse_status
ORDER BY source_code, correlation_status, parse_status;
```

Per ogni audit terminale controllare `events_read = events_inserted + events_duplicate + events_rejected`. `ROTATED` significa che il segmento non è stato letto perché identità o contenuto iniziale del file sono cambiati. `SKIPPED` è atteso per segmenti vuoti o quando non c'è un ciclo da correlare. Errori ingestione sono distinti dall'esito in `dwh_schedule_run`.

## Diagnosi

| Segnale | Verifica |
|---|---|
| `SOURCE_MISSING`, `PERMISSION_DENIED` | Controllare percorso, mount e permessi come utente `nifi`; non modificare l'allowlist per includere percorsi arbitrari. |
| `SOURCE_ROTATED_OR_TRUNCATED`, stato `ROTATED` | Verificare logrotate e rotazione applicativa. Non riutilizzare offset su un file di identità diversa. |
| `SEGMENT_TOO_LARGE` | Il segmento supera 64 MiB per default. Valutare in change separato limiti e frequenza di esecuzione. |
| `SUCCEEDED_WITH_REJECTS` | Gli eventi oltre 1 MiB sono stati contati come scarti senza salvarne il testo. Correggere il formato/logging o approvare un limite differente. |
| errori DB | Controllare disponibilità PostgreSQL, DDL, ruolo effettivo del login e privilegi sulle tabelle e sequence. |

I pattern di redazione noti non costituiscono una garanzia per qualunque formato di segreto: non introdurre credenziali nei log sorgente.

## Retry controllato

Il retry automatico non è eseguito dal scheduler. Per un audit `FAILED`, il loader ricostruisce solo sorgente, device/inode, offset e metadati dal record esistente; rifiuta stati diversi da `FAILED`, identità mancanti o percorsi non allowlisted. La sorgente originale deve essere ancora disponibile allo stesso path con lo stesso device/inode e una dimensione che copra `offset_end`.

Prima effettuare un dry-run:

```bash
sudo -u nifi /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  /opt/etl/frontiere-metadata-runner/scripts/load_execution_logs.py \
  --retry-ingestion-id <INGESTION_ID> --dry-run
```

Esaminare sorgente, byte, numero eventi e scarti nell'output. Se coerente, eseguire il retry rimuovendo `--dry-run`. Il nuovo audit valorizza `retry_of_ingestion_id`; eventi già inseriti sono conteggiati come duplicati. Non usare il retry per tentativi `ROTATED`: i byte originali non sono più garantiti.

## Disabilitazione e rollback

Impostare `FMR_LOG_INGESTION_ENABLED=false` in `/etc/sysconfig/dwh-scheduler`; il passo non verrà eseguito dal successivo avvio. Il ciclo NiFi e il suo exit code continuano a essere determinati come prima. Conservare tabelle, audit e file sorgente. La rimozione DDL non fa parte del rollback ordinario e richiede un change DBA separato con backup dei dati.
