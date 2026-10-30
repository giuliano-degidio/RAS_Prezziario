# Road map — Riversamento dei log NiFi nello schema `hcbi_utility`

## 1. Scopo

Aggiungere al progetto esistente un meccanismo che, al termine di ogni ciclo di elaborazione, acquisisca i contenuti pertinenti dai seguenti file e li persista in tabelle dedicate dello schema `hcbi_utility`:

- `/opt/etl/log/dwh-scheduler/dwh-scheduler.log`
- `/opt/etl/log/frontiere-metadata-runner/dwh-refresh.log`
- `/opt/etl/log/frontiere-metadata-runner/frontiere-metadata-runner.log`

La modifica deve essere **additiva**: non deve alterare la logica, gli esiti, le tabelle di audit, gli script e i processori NiFi esistenti, salvo l'aggiunta del nuovo passo finale e dei relativi artefatti.

## 2. Principi guida

1. **Non regressione**: il ciclo esistente resta invariato fino al suo esito finale.
2. **Disaccoppiamento**: il riversamento dei log è successivo all'elaborazione e non cambia l'esito business già determinato.
3. **Idempotenza**: un nuovo tentativo non duplica eventi già acquisiti.
4. **Restartability**: un caricamento interrotto può essere rilanciato.
5. **Tracciabilità**: ogni tentativo di ingestione è registrato separatamente.
6. **Correlazione esplicita**: si usa `execution_uuid` quando presente; non lo si deduce in modo ambiguo.
7. **Conservazione del contenuto originale**: il messaggio viene conservato senza reinterpretazioni, applicando soltanto eventuali regole approvate di mascheramento dei segreti.
8. **Allowlist**: il componente può leggere esclusivamente i tre percorsi configurati.
9. **Best effort controllato**: il fallimento dell'archiviazione log produce un errore tecnico visibile e recuperabile, ma non retrocede un'elaborazione già conclusa con successo.

## 3. Evidenze ricavate dai log campione

- `dwh-refresh.log` contiene eventi di avvio e conclusione del refresh con `execution_uuid` e `chain_id`; in caso di errore contiene traceback multilinea.
- `frontiere-metadata-runner.log` contiene l'avvio con `execution_uuid`, il caricamento delle configurazioni, gli esiti delle frontiere e un riepilogo finale; anche questo file può contenere traceback multilinea.
- `dwh-scheduler.log` contiene eventi dello scheduler e l'output del runner. Comprende un identificativo del run scheduler distinto dall'`execution_uuid` del ciclo e contiene righe prive di `execution_uuid`.
- Nel campione esistono casi in cui la correlazione tra messaggi scheduler e identificativo dell'esecuzione frontiere non è ricavabile in modo affidabile dal solo testo. La progettazione non deve quindi associare automaticamente righe ambigue a un UUID.

## 4. Perimetro della prima release

### Incluso

- acquisizione dei tre file indicati;
- gestione di eventi singola riga e multilinea;
- persistenza di eventi con e senza `execution_uuid`;
- audit di ogni tentativo;
- deduplicazione;
- filtro temporale e/o per intervallo di byte del ciclo concluso;
- metriche di riconciliazione;
- gestione separata di successo, successo con scarti ed errore;
- comando manuale di recupero per un intervallo o una specifica esecuzione;
- aggiornamento della documentazione tecnica e operativa.

### Escluso dalla prima release

- modifica del formato dei tre log esistenti;
- modifica della logica di frontiere, refresh DWH o scheduler;
- cancellazione o rotazione dei log sorgente;
- acquisizione di `nifi-app.log`, journal systemd o bulletin NiFi;
- dashboard o alerting esterno;
- modifica retroattiva dell'esito del ciclo;
- partizionamento delle tabelle senza evidenze sui volumi.

## 5. Fasi della road map

### Fase 1 — Baseline e congelamento del comportamento corrente

Attività:

- documentare i tre percorsi e i relativi owner/permessi;
- rilevare encoding, rotazione, dimensione tipica e massima, crescita e retention attuale;
- acquisire campioni di successo, fallimento frontiere, fallimento DWH e scheduler senza esecuzione dovuta;
- salvare evidenze del flow NiFi e degli script correnti;
- definire test di regressione del comportamento attuale.

Output:

- inventario sorgenti log;
- baseline funzionale;
- matrice dei casi osservati;
- checklist di non regressione.

Criterio di uscita:

- un ciclo corrente è riproducibile e verificabile prima di introdurre l'aggiunta.

### Fase 2 — Contratto di ingestione

Attività:

- definire le regole di riconoscimento dell'inizio evento: timestamp + livello log;
- definire l'aggregazione delle righe di traceback nel precedente evento;
- classificare ogni record come `CORRELATED`, `UNCORRELATED` o `AMBIGUOUS`;
- stabilire il perimetro di lettura mediante offset iniziale/finale e snapshot del file;
- definire l'identità deterministica dell'evento;
- definire limiti configurabili per dimensione file, dimensione evento e numero eventi per batch;
- definire le regole di mascheramento, senza applicarle finché non validate su campioni reali.

Output:

- specifica del parser;
- contratto input/output;
- catalogo degli errori e degli exit code.

Criterio di uscita:

- ogni riga dei campioni è riconciliabile come acquisita, duplicata o scartata.

### Fase 3 — Modello dati e DDL

Attività:

- creare la tabella eventi `hcbi_utility.etl_execution_log_event`;
- creare la tabella audit `hcbi_utility.etl_execution_log_ingestion`;
- definire PK, FK, check constraint e indice univoco di idempotenza;
- definire grant minimi per l'utenza applicativa;
- predisporre query di verifica e riconciliazione;
- verificare il comportamento con `execution_uuid` nullo.

Output:

- DDL versionate;
- script di grant;
- query di verifica;
- dizionario dati.

Criterio di uscita:

- DDL applicabili e reversibili in ambiente di test, con vincoli validati.

### Fase 4 — Componente di acquisizione

Artefatto proposto:

`nifi/frontiere-metadata-runner/scripts/load_execution_logs.py`

Attività:

- lettura esclusiva da allowlist;
- apertura sicura e snapshot dei metadati del file;
- lettura dell'intervallo assegnato al ciclo;
- parsing degli eventi multilinea;
- estrazione di timestamp, livello, UUID e altri identificativi presenti;
- calcolo dell'hash deterministico;
- inserimento in batch con gestione dei conflitti;
- registrazione dell'audit;
- gestione transazionale e degli errori;
- modalità `--dry-run` e comando di backfill controllato.

Output:

- script;
- configurazione;
- test unitari;
- guida di esecuzione manuale.

Criterio di uscita:

- riesecuzione dello stesso input senza duplicati e con riconciliazione completa.

### Fase 5 — Integrazione additiva

Soluzione preferita:

- aggiungere l'invocazione dell'archiviatore nel livello esterno che conosce l'inizio e la fine del ciclo, dopo che l'esito corrente è già stato determinato;
- non inserire scritture DB aggiuntive nei percorsi applicativi di frontiere e DWH;
- non modificare il significato degli exit code esistenti;
- registrare separatamente l'esito dell'archiviazione.

Attività:

- acquisire gli offset iniziali dei tre file prima dell'avvio del ciclo;
- acquisire gli offset finali dopo l'arresto/conclusione del ciclo;
- invocare il nuovo componente con manifest per file, offset e identificativi noti;
- aggiungere il percorso tecnico di errore senza retry infinito;
- predisporre comando di recupero per audit `FAILED` o `RUNNING` obsoleto.

Output:

- integrazione additiva nel runner/deploy;
- manifest di ingestione;
- percorso di recupero operativo.

Criterio di uscita:

- l'esito del ciclo è identico con archiviatore abilitato o disabilitato.

### Fase 6 — Test e collaudo

Eseguire almeno:

- happy path;
- fallimento frontiera con traceback;
- fallimento DWH con traceback;
- scheduler senza processo dovuto;
- riga senza UUID;
- UUID discordanti o ambigui;
- file vuoto, assente o non leggibile;
- rotazione durante la lettura;
- evento multilinea;
- caratteri non ASCII;
- rilancio identico;
- interruzione dopo inserimento parziale;
- DB non disponibile;
- due invocazioni concorrenti;
- evento oltre il limite configurato;
- verifica della non regressione del flow esistente.

Output:

- piano e verbale di test;
- evidenze SQL e log;
- esito della riconciliazione.

Criterio di uscita:

- nessuna regressione e formula `letti = inseriti + duplicati + scartati` rispettata per ogni file.

### Fase 7 — Deploy controllato

Ordine:

1. backup/restore point degli oggetti interessati;
2. applicazione DDL e grant;
3. deploy dello script senza attivazione automatica;
4. dry-run sui campioni;
5. test DB con utenza applicativa;
6. attivazione additiva nel runner/flow;
7. esecuzione controllata;
8. riconciliazione filesystem/database/audit;
9. monitoraggio iniziale;
10. chiusura con evidenze.

Rollback:

- disabilitare esclusivamente il nuovo passo;
- ripristinare la versione precedente del runner/flow;
- mantenere le tabelle e i dati acquisiti;
- rimuovere gli oggetti DB solo con change separato e previa esportazione.

### Fase 8 — Esercizio e stabilizzazione

Controlli operativi:

- audit `RUNNING` non conclusi;
- tentativi `FAILED`;
- record `AMBIGUOUS` o `UNCORRELATED`;
- scostamenti di riconciliazione;
- crescita delle tabelle;
- durata e dimensione dei batch;
- duplicati;
- file non leggibili o ruotati;
- backlog da recuperare.

## 6. Documentazione da creare o aggiornare

### Da creare

- `doc/design/LOG_INGESTION_HIGH_LEVEL_DESIGN.md`
- `ddl/hcbi_utility/table/etl_execution_log_event.sql`
- `ddl/hcbi_utility/table/etl_execution_log_ingestion.sql`
- `nifi/frontiere-metadata-runner/sql/verify_log_ingestion.sql`
- `nifi/frontiere-metadata-runner/tests/test_log_ingestion.md`
- runbook operativo per retry, backfill e diagnosi.

### Da aggiornare

- manuale operativo di sviluppo moduli: architettura, tabelle, correlazione, monitoraggio e troubleshooting;
- manuale di deploy NiFi: prerequisiti, file, permessi, DDL, attivazione, verifica e rollback;
- README del frontiere metadata runner: opzioni, exit code, idempotenza e recovery;
- script di deploy del flow: aggiunta del nuovo componente senza sostituzione implicita degli oggetti esistenti;
- riepilogo cronologico del progetto;
- inventario delle configurazioni e dei segreti, senza riportare valori sensibili.

## 7. Rischi e mitigazioni

- **Correlazione errata dello scheduler**: conservare eventi non correlati e vietare associazioni per sola prossimità temporale.
- **Rotazione del file**: usare device/inode, dimensione e offset; in caso di cambio registrare il file come nuovo segmento.
- **Duplicazione al retry**: hash deterministico e vincolo univoco.
- **Evento multilinea spezzato**: parser stateful basato sull'intestazione timestamp/livello.
- **Errore archiviatore che modifica il ciclo**: invocazione successiva alla determinazione dell'esito e stato tecnico separato.
- **Crescita DB**: misurare prima di definire retention, indici aggiuntivi o partizionamento.
- **Dati sensibili**: scansione dei campioni, allowlist di mascheramento e privilegi minimi.
- **Concorrenza**: chiave univoca, transazioni brevi e lock logico sul manifest.

## 8. Decisioni assunte

- prima release con tutti i livelli `INFO`, `WARNING` ed `ERROR` presenti nei segmenti pertinenti;
- inclusione dei traceback come parte dell'evento che li precede;
- eventi senza UUID conservati, ma marcati non correlati;
- riversamento non bloccante rispetto all'esito business;
- nessuna cancellazione automatica dei file sorgente;
- nessuna retention DB fissata senza dati di volumetria e requisiti operativi;
- nessun partizionamento iniziale senza misure;
- nessuna associazione temporale automatica tra scheduler run ed execution UUID.

## 9. Criteri complessivi di accettazione

- i tre file sono acquisiti per il solo intervallo del ciclo;
- tutti gli eventi sono riconciliati;
- i traceback restano leggibili;
- la riesecuzione non genera duplicati;
- gli eventi ambigui non ricevono correlazioni arbitrarie;
- il fallimento del nuovo componente è recuperabile e non cambia l'esito business;
- disabilitando l'aggiunta, il comportamento precedente resta invariato;
- documentazione, DDL, test, deploy e rollback sono versionati.
