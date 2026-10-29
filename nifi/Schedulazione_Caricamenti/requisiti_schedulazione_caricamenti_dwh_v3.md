# Requisiti funzionali per la schedulazione configurabile dei caricamenti DWH

## 1. Scopo del documento

Il presente documento raccoglie e consolida i requisiti definiti finora per la schedulazione configurabile delle elaborazioni di caricamento del Data Warehouse (DWH).

Il documento descrive esclusivamente i requisiti condivisi. Non contiene ancora il modello fisico della tabella, il DDL, il trigger, il codice Python o le procedure di deployment e test.

## 2. Obiettivo

Realizzare un sistema che consenta di configurare su database la schedulazione delle elaborazioni di caricamento del DWH.

Un batch Python viene avviato quotidianamente e deve:

1. collegarsi al database;
2. leggere la configurazione delle elaborazioni da una tabella;
3. individuare l'elaborazione attualmente abilitata;
4. verificare se, in base alla data corrente e alla configurazione presente, l'elaborazione debba essere eseguita;
5. avviare l'elaborazione quando le condizioni previste sono soddisfatte;
6. non avviare l'elaborazione quando le condizioni previste non sono soddisfatte;
7. registrare sulla tabella l'esito dell'elaborazione.

## 3. Tabella di configurazione

La configurazione deve essere memorizzata in una tabella del database semplice da leggere, aggiornare e manutenere.

La tabella deve prevedere:

- una riga per ogni tipo di elaborazione;
- un identificativo univoco dell'elaborazione;
- il tipo di schedulazione;
- i parametri necessari a determinare il giorno pianificato;
- un campo booleano di abilitazione;
- la data dell'ultima esecuzione conclusa con successo;
- il numero di giorni di retry, quando previsto;
- l'esito dell'ultimo tentativo di elaborazione;
- un eventuale messaggio associato all'esito negativo.

La modifica della frequenza, del giorno pianificato, della finestra di retry o dello stato di abilitazione deve poter avvenire tramite configurazione su database, senza richiedere modifiche al codice Python.

## 4. Abilitazione delle elaborazioni

Ogni riga deve contenere un campo booleano che indichi se l'elaborazione è abilitata:

- `TRUE`: elaborazione abilitata;
- `FALSE`: elaborazione disabilitata.

Al momento deve poter essere abilitata una sola elaborazione a livello globale.

Il vincolo deve essere gestito tramite trigger. Quando una riga viene impostata a `TRUE`, il trigger deve disabilitare automaticamente l'eventuale riga precedentemente abilitata, impostandola a `FALSE`.

Di conseguenza, l'abilitazione di una nuova elaborazione non deve essere rifiutata: deve sostituire automaticamente l'elaborazione attiva in precedenza.

## 5. Tipologie di schedulazione

Ogni elaborazione deve poter utilizzare una delle seguenti tipologie di schedulazione:

1. annuale;
2. semestrale;
3. quadrimestrale;
4. trimestrale;
5. bimestrale;
6. mensile;
7. settimanale;
8. quotidiana.

Le schedulazioni devono supportare regole basate sulla posizione del giorno nella settimana e nel periodo di riferimento. Un esempio di regola richiesta è:

> primo sabato della prima settimana di marzo

Questo approccio evita di legare la configurazione esclusivamente a una data fissa o a un numero di giorno del mese e permette di gestire ricorrenze espresse tramite:

- mese di riferimento, quando necessario;
- settimana o occorrenza nel periodo;
- giorno della settimana.

## 6. Convenzione dei giorni della settimana

I giorni della settimana devono essere rappresentati con la seguente convenzione:

| Valore | Giorno |
|---:|---|
| 1 | Lunedì |
| 2 | Martedì |
| 3 | Mercoledì |
| 4 | Giovedì |
| 5 | Venerdì |
| 6 | Sabato |
| 7 | Domenica |

## 7. Schedulazione annuale

Per una schedulazione annuale devono essere configurabili:

- la regola che determina il giorno di esecuzione nell'anno;
- la data dell'ultima esecuzione conclusa con successo;
- il numero massimo di giorni durante i quali ritentare l'elaborazione, qualora non sia ancora stata completata con successo nell'anno corrente.

Esempio di regola annuale:

> primo sabato della prima settimana di marzo

L'elaborazione deve essere avviata quando:

- la data corrente coincide con il giorno calcolato dalla regola annuale; oppure
- la data corrente rientra nella finestra di retry successiva al giorno pianificato e l'elaborazione non risulta ancora conclusa con successo nell'anno corrente.

L'ultimo giorno della finestra di retry è incluso.

Una volta completata con successo l'elaborazione per l'anno corrente, non devono essere effettuati ulteriori tentativi nello stesso anno.


## 8. Schedulazione semestrale

Per una schedulazione semestrale devono essere configurabili:

- la regola che determina il giorno di esecuzione nel semestre;
- la data dell'ultima esecuzione conclusa con successo;
- il numero massimo di giorni durante i quali ritentare l'elaborazione, qualora non sia ancora stata completata con successo nel semestre corrente.

La schedulazione prevede un'esecuzione ogni sei mesi. Il giorno pianificato deve essere determinato tramite una regola relativa al calendario, basata sul mese di riferimento, sulla settimana o occorrenza nel periodo e sul giorno della settimana.

L'elaborazione deve essere avviata quando:

- la data corrente coincide con il giorno calcolato dalla regola semestrale; oppure
- la data corrente rientra nella finestra di retry successiva al giorno pianificato e l'elaborazione non risulta ancora conclusa con successo nel semestre corrente.

L'ultimo giorno della finestra di retry è incluso.

Una volta completata con successo l'elaborazione per il semestre corrente, non devono essere effettuati ulteriori tentativi nello stesso semestre.

## 9. Schedulazione quadrimestrale

Per una schedulazione quadrimestrale devono essere configurabili:

- la regola che determina il giorno di esecuzione nel quadrimestre;
- la data dell'ultima esecuzione conclusa con successo;
- il numero massimo di giorni durante i quali ritentare l'elaborazione, qualora non sia ancora stata completata con successo nel quadrimestre corrente.

La schedulazione prevede un'esecuzione ogni quattro mesi. Il giorno pianificato deve essere determinato tramite una regola relativa al calendario, basata sul mese di riferimento, sulla settimana o occorrenza nel periodo e sul giorno della settimana.

L'elaborazione deve essere avviata quando:

- la data corrente coincide con il giorno calcolato dalla regola quadrimestrale; oppure
- la data corrente rientra nella finestra di retry successiva al giorno pianificato e l'elaborazione non risulta ancora conclusa con successo nel quadrimestre corrente.

L'ultimo giorno della finestra di retry è incluso.

Una volta completata con successo l'elaborazione per il quadrimestre corrente, non devono essere effettuati ulteriori tentativi nello stesso quadrimestre.

## 10. Schedulazione trimestrale

Per una schedulazione trimestrale devono essere configurabili:

- la regola che determina il giorno di esecuzione nel trimestre;
- la data dell'ultima esecuzione conclusa con successo;
- il numero massimo di giorni durante i quali ritentare l'elaborazione, qualora non sia ancora stata completata con successo nel trimestre corrente.

La schedulazione prevede un'esecuzione ogni tre mesi. Il giorno pianificato deve essere determinato tramite una regola relativa al calendario, basata sul mese di riferimento, sulla settimana o occorrenza nel periodo e sul giorno della settimana.

L'elaborazione deve essere avviata quando:

- la data corrente coincide con il giorno calcolato dalla regola trimestrale; oppure
- la data corrente rientra nella finestra di retry successiva al giorno pianificato e l'elaborazione non risulta ancora conclusa con successo nel trimestre corrente.

L'ultimo giorno della finestra di retry è incluso.

Una volta completata con successo l'elaborazione per il trimestre corrente, non devono essere effettuati ulteriori tentativi nello stesso trimestre.

## 11. Schedulazione bimestrale

Per una schedulazione bimestrale devono essere configurabili:

- la regola che determina il giorno di esecuzione nel bimestre;
- la data dell'ultima esecuzione conclusa con successo;
- il numero massimo di giorni durante i quali ritentare l'elaborazione, qualora non sia ancora stata completata con successo nel bimestre corrente.

La schedulazione prevede un'esecuzione ogni due mesi. Il giorno pianificato deve essere determinato tramite una regola relativa al calendario, basata sul mese di riferimento, sulla settimana o occorrenza nel periodo e sul giorno della settimana.

L'elaborazione deve essere avviata quando:

- la data corrente coincide con il giorno calcolato dalla regola bimestrale; oppure
- la data corrente rientra nella finestra di retry successiva al giorno pianificato e l'elaborazione non risulta ancora conclusa con successo nel bimestre corrente.

L'ultimo giorno della finestra di retry è incluso.

Una volta completata con successo l'elaborazione per il bimestre corrente, non devono essere effettuati ulteriori tentativi nello stesso bimestre.

## 12. Schedulazione mensile

Per una schedulazione mensile devono essere configurabili:

- la regola che determina il giorno di esecuzione nel mese;
- la data dell'ultima esecuzione conclusa con successo;
- il numero massimo di giorni durante i quali ritentare l'elaborazione, qualora non sia ancora stata completata con successo nel mese corrente.

La schedulazione deve essere espressa tramite una regola relativa al calendario, evitando la dipendenza esclusiva da giorni fissi potenzialmente inesistenti in alcuni mesi, come il giorno 31.

Esempio di regola mensile:

> primo sabato del mese

L'elaborazione deve essere avviata quando:

- la data corrente coincide con il giorno calcolato dalla regola mensile; oppure
- la data corrente rientra nella finestra di retry successiva al giorno pianificato e l'elaborazione non risulta ancora conclusa con successo nel mese corrente.

L'ultimo giorno della finestra di retry è incluso.

Una volta completata con successo l'elaborazione per il mese corrente, non devono essere effettuati ulteriori tentativi nello stesso mese.

## 13. Schedulazione settimanale

Per una schedulazione settimanale devono essere configurabili:

- il giorno della settimana previsto per l'esecuzione, rappresentato con valori da `1` a `7`;
- la data dell'ultima esecuzione conclusa con successo;
- il numero massimo di giorni durante i quali ritentare l'elaborazione, qualora non sia ancora stata completata con successo nella settimana corrente.

L'elaborazione deve essere avviata quando:

- il giorno corrente coincide con il giorno configurato; oppure
- la data corrente rientra nella finestra di retry successiva al giorno pianificato e l'elaborazione non risulta ancora conclusa con successo nella settimana corrente.

L'ultimo giorno della finestra di retry è incluso.

Una volta completata con successo l'elaborazione per la settimana corrente, non devono essere effettuati ulteriori tentativi nella stessa settimana.

## 14. Schedulazione quotidiana

Per una schedulazione quotidiana devono essere gestiti:

- il tipo di schedulazione quotidiana;
- la data dell'ultima esecuzione conclusa con successo.

Per questa tipologia non è previsto un intervallo di retry.

L'elaborazione deve essere avviata una volta al giorno, purché:

- la relativa riga sia abilitata;
- l'elaborazione non risulti già conclusa con successo nella giornata corrente.

## 15. Data dell'ultima esecuzione

Per tutte le tipologie di schedulazione, la data dell'ultima esecuzione indica esclusivamente l'ultima elaborazione conclusa con successo.

Il periodo di riferimento utilizzato per impedire esecuzioni duplicate è:

- anno corrente per la schedulazione annuale;
- semestre corrente per la schedulazione semestrale;
- quadrimestre corrente per la schedulazione quadrimestrale;
- trimestre corrente per la schedulazione trimestrale;
- bimestre corrente per la schedulazione bimestrale;
- mese corrente per la schedulazione mensile;
- settimana corrente per la schedulazione settimanale;
- giorno corrente per la schedulazione quotidiana.

In caso di esecuzione fallita, la data dell'ultima esecuzione conclusa con successo non deve essere aggiornata.

## 16. Finestra di retry

La finestra di retry rappresenta il numero di giorni successivi alla data pianificata durante i quali l'elaborazione può essere nuovamente avviata, se non risulta ancora conclusa con successo nel periodo corrente.

La finestra di retry:

- è prevista per le schedulazioni annuale, semestrale, quadrimestrale, trimestrale, bimestrale, mensile e settimanale;
- non è prevista per la schedulazione quotidiana;
- include il proprio ultimo giorno.

Il valore indica una finestra temporale di ammissibilità dell'esecuzione. Non rappresenta necessariamente il numero massimo di tentativi tecnici effettuabili all'interno della finestra.

## 17. Gestione degli esiti

Al termine di ogni tentativo, la tabella deve riportare l'esito dell'elaborazione.

In caso di successo:

- deve essere registrato l'esito positivo;
- deve essere aggiornata la data dell'ultima esecuzione conclusa con successo.

In caso di errore:

- deve essere registrato l'esito negativo;
- deve essere memorizzato un eventuale messaggio descrittivo dell'errore;
- la data dell'ultima esecuzione conclusa con successo deve rimanere invariata.

## 18. Flusso decisionale del batch giornaliero

A ogni avvio quotidiano, il batch Python deve:

1. collegarsi al database;
2. leggere la configurazione;
3. individuare l'unica elaborazione abilitata;
4. identificare il tipo di schedulazione;
5. calcolare la data pianificata in base alla regola configurata;
6. confrontare la data corrente con la data pianificata;
7. verificare la data dell'ultima esecuzione conclusa con successo;
8. verificare, se prevista, la finestra di retry;
9. decidere se avviare l'elaborazione;
10. registrare l'esito del tentativo;
11. aggiornare la data dell'ultima esecuzione conclusa con successo solo in caso di esito positivo.

L'elaborazione non deve essere avviata quando:

- la riga non è abilitata;
- non è ancora stata raggiunta la data pianificata;
- la finestra di retry è terminata;
- l'elaborazione risulta già conclusa con successo nel periodo di riferimento;
- per la schedulazione quotidiana, l'elaborazione risulta già conclusa con successo nella giornata corrente.

## 19. Gestione delle esecuzioni concorrenti

La prevenzione delle esecuzioni concorrenti del caricamento DWH è demandata alla runtime del batch di elaborazione.

Se viene avviata una seconda istanza mentre un'altra elaborazione è già in esecuzione, la seconda istanza rileva la concorrenza e si arresta automaticamente.

Questo comportamento costituisce un vincolo esterno già previsto per il batch DWH. Il presente requisito non definisce ulteriori meccanismi di locking applicativo o sul database.

## 20. Vincoli funzionali consolidati

La soluzione deve rispettare i seguenti vincoli:

- deve esistere una sola riga per ogni elaborazione;
- ogni riga deve avere una tipologia di schedulazione valida;
- il campo di abilitazione deve essere obbligatorio;
- una sola elaborazione può essere abilitata globalmente;
- l'abilitazione di una nuova riga deve disabilitare automaticamente quella precedentemente attiva;
- la schedulazione annuale deve avere una regola annuale valida;
- la schedulazione semestrale deve avere una regola semestrale valida;
- la schedulazione quadrimestrale deve avere una regola quadrimestrale valida;
- la schedulazione trimestrale deve avere una regola trimestrale valida;
- la schedulazione bimestrale deve avere una regola bimestrale valida;
- la schedulazione mensile deve avere una regola mensile valida;
- la schedulazione settimanale deve indicare un giorno compreso tra `1` e `7`;
- le schedulazioni annuale, semestrale, quadrimestrale, trimestrale, bimestrale, mensile e settimanale devono prevedere una finestra di retry;
- la schedulazione quotidiana non deve prevedere una finestra di retry;
- l'ultimo giorno della finestra di retry deve essere considerato valido;
- la data dell'ultima esecuzione deve riferirsi esclusivamente a un'esecuzione conclusa con successo;
- un errore non deve modificare la data dell'ultima esecuzione conclusa con successo;
- l'esito negativo e l'eventuale messaggio di errore devono essere registrati sulla tabella.

## 21. Requisiti di manutenibilità

La configurazione deve essere:

- centralizzata in una sola tabella;
- composta da una sola riga per elaborazione;
- leggibile e modificabile senza intervenire sul codice Python;
- sufficientemente espressiva da rappresentare schedulazioni relative al calendario;
- utilizzabile dal batch per determinare in modo univoco se avviare o meno l'elaborazione.

## 22. Perimetro della fase successiva

Restano da definire nella successiva fase di progettazione tecnica:

- il database target e la relativa versione;
- il modello fisico della tabella e i tipi di dato;
- la rappresentazione tecnica delle regole di calendario;
- il comportamento per eventuali regole il cui giorno calcolato oltrepassi il periodo di riferimento durante la finestra di retry;
- la distinzione tra esito dell'ultimo tentativo e dati dell'ultimo successo;
- la lunghezza massima e la gestione del messaggio di errore;
- il comportamento in assenza di righe abilitate;
- il comportamento in presenza di configurazioni non valide;
- il DDL del trigger di abilitazione esclusiva;
- la logica Python di valutazione della schedulazione;
- i criteri di logging, audit, test, deployment e rollback.

## 23. Stato del documento

Il documento rappresenta la versione consolidata dei requisiti discussi finora, comprensiva delle otto tipologie di schedulazione definite.
