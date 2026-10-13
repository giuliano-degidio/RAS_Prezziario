# NIFI DWH ROADMAP

## Obiettivo
Usare Apache NiFi come livello di orchestrazione e trasferimento dati per spostare i dati dal database operazionale `rasop` al progetto `hcbi`, mantenendo separati trasporto, controlli e trasformazioni di dominio.

La logica di business resta nel perimetro DWH Flowforge: NiFi trasporta e standardizza il flusso, mentre mapping, conversioni e regole di caricamento restano documentate e governate nel repository.

## Contesto
- Sorgente operazionale: PostgreSQL `rasop`
- Target DWH: PostgreSQL `hcbi`
- Oggetti sorgente/target: tabelle `frontiera_*` e relative strutture di staging del progetto
- Vincolo: non inventare mapping o conversioni non verificate; ogni trasformazione deve essere tracciabile

## Roadmap funzionale

### Fase 1 - Analisi tecnica
1. Inventario tabelle sorgente e target.
2. Definizione mapping per gruppo di tabelle.
3. Identificazione campi da convertire, campi statici e chiavi.
4. Classificazione dei flussi:
   - anagrafiche statiche
   - importazioni da file Excel
   - tabelle derivate/calcolate
   - tabelle di pubblicazione

### Fase 2 - Installazione NiFi
1. Installare Java compatibile con la versione di NiFi scelta.
2. Installare Apache NiFi su un server dedicato.
3. Configurare TLS/HTTPS e utente amministrativo.
4. Installare i driver JDBC PostgreSQL per sorgente e target.
5. Configurare accesso di rete verso i due database.
6. Predisporre filesystem per flowfile, content repository e provenance repository.

### Fase 3 - Progettazione dei flow
Per ogni gruppo di tabelle:
1. estrazione da `rasop`;
2. trasformazione tipo-record/cast;
3. validazione tecnica;
4. caricamento su `hcbi`;
5. log e riconciliazione row count.

### Fase 4 - Esecuzione controllata
1. Flussi per le tabelle statiche.
2. Flussi per le tabelle con conversioni semplici.
3. Flussi con gestione eccezioni e scarti.
4. Verifica a campione con confronti tra sorgente e target.

### Fase 5 - Industrializzazione
1. Scheduler o trigger di esecuzione.
2. Notifiche su errore.
3. Retry e backpressure.
4. Monitoraggio operativo.
5. Documentazione di runbook e rollback.

## Pattern tecnico consigliato
- `QueryDatabaseTableRecord` o `GenerateTableFetch` per lettura da PostgreSQL
- `PutDatabaseRecord` o `PutSQL` per scrittura su PostgreSQL
- `UpdateRecord` / `ConvertRecord` per conversioni e cast
- `RouteOnAttribute` per instradare record validi e non validi
- `LogAttribute` e provenance per audit tecnico

## Regole di progetto
- usare Parameter Context per host, database, schema, user e password;
- non hardcodare segreti nei flow;
- separare ambienti dev/test/prod;
- mantenere naming coerente con `dwh-flowforge-architect`;
- per ogni tappa mantenere conteggi, errori e riconciliazione.

## Cosa serve per installare NiFi Server
- Server Linux dedicato o VM
- Java compatibile con la versione NiFi selezionata
- almeno 8 GB RAM (16 GB consigliati se i volumi crescono)
- SSD per repository e code
- accesso di rete ai database PostgreSQL sorgente e target
- driver JDBC PostgreSQL
- certificati TLS se si usa HTTPS (raccomandato)
- utente di servizio non privilegiato
- policy di backup per configurazione e flow definition
- eventuale ZooKeeper solo se si decide di usare un cluster NiFi

## Deliverable attesi
- elenco flussi NiFi per gruppo di tabelle
- specifica dei Parameter Context
- inventario delle connessioni JDBC
- schema dei controlli e della riconciliazione
- runbook di installazione e avvio

## Nota operativa
Questa roadmap non sostituisce la logica DWH: NiFi è il trasporto e il controllo di primo livello, mentre la semantica di business resta nel progetto `RAS_Prezziario` e nella specifica `dwh_flowforge_architect`.
