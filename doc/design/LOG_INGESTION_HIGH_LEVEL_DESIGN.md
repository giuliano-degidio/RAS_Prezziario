# Design e implementazione — Riversamento dei log NiFi in PostgreSQL

## Obiettivo

Aggiungere al ciclo DWH una raccolta post-esecuzione dei soli segmenti nuovi dei tre log applicativi. L'esito business del runner resta autorevole: un errore, un timeout o un'interruzione dell'ingestione log viene registrato separatamente e non cambia l'exit code già determinato per il ciclo.

## Sorgenti e confini

La allowlist è costruita dal runner, non dal FlowFile né da argomenti arbitrari:

| Codice | Percorso predefinito |
|---|---|
| `DWH_SCHEDULER` | `/opt/etl/log/dwh-scheduler/dwh-scheduler.log` |
| `DWH_REFRESH` | `/opt/etl/log/frontiere-metadata-runner/dwh-refresh.log` |
| `FRONTIERE_RUNNER` | `/opt/etl/log/frontiere-metadata-runner/frontiere-metadata-runner.log` |

Il runner acquisisce device, inode, dimensione e fingerprint del prefisso dopo aver acquisito il lock globale. A ciclo terminato, prima di rilasciare il lock, determina l'intervallo finale. Legge il segmento solo se l'identità della sorgente e il prefisso sono rimasti coerenti; una rotazione o un troncamento viene classificato senza leggere dati di identità incerta. I log storici non vengono importati automaticamente.

## Flusso runtime

1. `dwh_schedule_runner.py` determina il normale esito `SUCCESS`, `FAILED` o `SKIPPED` e conserva il return code.
2. Se `FMR_LOG_INGESTION_ENABLED=true`, cattura gli snapshot iniziali dei tre file.
3. Al termine crea un manifest in memoria con offset, identificativi disponibili ed esito del ciclo.
4. `load_execution_logs.py` valida l'allowlist, legge il segmento, ricompone gli eventi multilinea, redige pattern noti, estrae metadati e scrive eventi/audit in transazioni per batch.
5. Il lock viene rilasciato dopo lo snapshot finale e il tentativo di ingestione, evitando che un nuovo ciclo si sovrapponga ai confini acquisiti.

La configurazione predefinita è disabilitata. L'abilitazione richiede l'applicazione preventiva di entrambi i DDL e la verifica dei privilegi dell'utenza HCBI configurata nel file cifrato.

## Modello dati

- `hcbi_utility.etl_execution_log_ingestion`: un record per tentativo e singolo segmento di file; conserva offset, identità, esito ciclo, contatori, stato ed errori. Il campo `retry_of_ingestion_id` collega i retry.
- `hcbi_utility.etl_execution_log_event`: un record per evento logico, con offset byte, timestamp, livello, identificativi, stato di correlazione, stato del parsing, flag di redazione e testo.

Ordine DDL: prima `ddl/hcbi_utility/table/etl_execution_log_ingestion.sql`, poi `ddl/hcbi_utility/table/etl_execution_log_event.sql`. Le query di controllo sono in `nifi/frontiere-metadata-runner/sql/03_verify_log_ingestion.sql`. Gli script assegnano ownership a `hcbi_utility` e grant al ruolo applicativo `hcbi_ras`, secondo la convenzione esistente; il DBA deve confermare che l'utente di connessione HCBI erediti tali privilegi.

La deduplicazione usa codice sorgente, device/inode, intervallo byte e hash del messaggio. Per ogni tentativo vale `events_read = events_inserted + events_duplicate + events_rejected`. I batch sono atomici: un errore non lascia conteggi diversi dagli eventi committati.

## Parsing e protezione dei dati

Una nuova intestazione con timestamp e livello apre un evento; le righe successive senza intestazione restano nel messaggio precedente. Le righe vengono decodificate UTF-8 con sostituzione esplicita degli errori. Gli eventi oltre il limite configurato sono scartati e contati senza salvarne il testo. L'identificazione di UUID e altri campi è testuale e prudenziale: valori discordanti sono `AMBIGUOUS`, assenza di identificatori è `UNCORRELATED`; non si deduce una correlazione dalla sola vicinanza temporale.

Il modulo maschera pattern noti per credenziali, token, password in URL e chiavi private. La redazione non sostituisce la revisione dei formati di log: non devono comunque essere registrati segreti applicativi.

## Installazione e attivazione

1. Applicare i due DDL PostgreSQL nell'ordine indicato, con `ON_ERROR_STOP`, e controllare grants e tabelle con lo script di verifica.
2. Distribuire `dwh_schedule_runner.py` e `load_execution_logs.py` con `install_dwh_scheduler.sh`; l'installer copia i file ma non avvia il service né abilita il timer.
3. Verificare che l'utenza `nifi` possa leggere i tre log e il file cifrato e che il virtualenv contenga `psycopg`.
4. Lasciare `FMR_LOG_INGESTION_ENABLED=false` durante il collaudo iniziale. Abilitare in `/etc/sysconfig/dwh-scheduler` solo dopo il collaudo autorizzato.
5. Verificare l'audit e gli eventi per un ciclo controllato. In caso di errore di ingestione, controllare `error_code`, permessi, rotazione e dimensioni.

Questa implementazione non cambia i processor o il JSON del Process Group NiFi: il punto di integrazione è il runner esterno che già conosce inizio e fine del ciclo. Nessun DDL, deploy o run live è eseguito da questa documentazione.

## Recupero e rollback

Per un audit `FAILED`, il loader può ricostruire il solo segmento originale dal suo `ingestion_id`, ma solo se path, device/inode e intervallo sono ancora accessibili. Prima eseguire il dry-run:

```bash
sudo -u nifi /opt/etl/frontiere-metadata-runner/.venv/bin/python \
  /opt/etl/frontiere-metadata-runner/scripts/load_execution_logs.py \
  --retry-ingestion-id <INGESTION_ID> --dry-run
```

Dopo aver esaminato il risultato, il retry effettivo usa lo stesso comando senza `--dry-run`. Il retry riguarda esclusivamente lo stato `FAILED`; gli eventi già inseriti sono riconosciuti come duplicati e il nuovo audit punta al tentativo originale. Segmenti ruotati o con identità non disponibile non sono recuperabili tramite questo comando.

Per disabilitare la funzione riportare `FMR_LOG_INGESTION_ENABLED=false`; non occorre fermare NiFi. Le tabelle e i dati acquisiti si conservano. La rimozione del DDL è un change separato e non fa parte del rollback applicativo.

## Verifiche locali

I test unitari del parser e dei confini sono in `nifi/frontiere-metadata-runner/tests/test_load_execution_logs.py`; i test di calendario scheduler restano in `nifi/Schedulazione_Caricamenti/deploy/unix-linux/test_dwh_schedule_runner.py`. I test locali non richiedono né contattano PostgreSQL o NiFi.
