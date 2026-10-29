# Esempi di inserimento delle schedulazioni DWH

## Scopo e avvertenze

Questo documento raccoglie un esempio `INSERT` per ciascuna frequenza supportata
da `hcbi_utility.dwh_schedule`. I parametri sono dimostrativi: prima di usarne
uno, concordare con il responsabile la frequenza, il mese di ancoraggio, il
giorno, la settimana e la finestra di retry.

Gli otto INSERT usano codici distinti (`DWH_REFRESH_DAILY`, `DWH_REFRESH_WEEKLY`
e così via), quindi rappresentano righe diverse e possono coesistere. Il vincolo
univoco su `process_code` impedisce di duplicare ciascuna riga; l'indice e il
trigger consentono una sola schedulazione abilitata alla volta. Gli esempi
mantengono `enabled = false` per evitare attivazioni accidentali.

Gli esempi presuppongono che le tabelle siano già state create con
`deploy/postgresql/01_create_dwh_schedule.sql`. Non eseguire il contenuto
completo del documento su un ambiente già popolato: gli INSERT non sono
idempotenti. In caso di righe esistenti, aggiornarle con una modifica approvata.

## Significato dei parametri

- `anchor_month`: mese iniziale del ciclo periodico; con `1` il ciclo parte da
  gennaio. Per esempio, una frequenza `QUARTERLY` produce periodi in gennaio,
  aprile, luglio e ottobre.
- `week_ordinal`: settimana del mese (da 1 a 5), con le regole ISO del runner.
- `weekday_iso`: giorno ISO della settimana: `1` lunedì, `2` martedì, ...,
  `7` domenica. Gli esempi mensili usano il primo lunedì (`week_ordinal = 1`,
  `weekday_iso = 1`).
- `retry_days`: giorni di tolleranza inclusivi dopo la data pianificata. Il
  runner non supera la data pianificata del ciclo successivo. Il valore `6` è
  solo un esempio.

Le frequenze che non richiedono un parametro calendario devono avere le colonne
non applicabili impostate a `NULL`, come indicato negli esempi.
Il runner valuta le date usando il fuso `Europe/Rome`.

## DAILY — giornaliera

```sql
INSERT INTO hcbi_utility.dwh_schedule
    (process_code, process_description, enabled, frequency_code,
     anchor_month, week_ordinal, weekday_iso, retry_days)
VALUES
    ('DWH_REFRESH_DAILY', 'Refresh DWH', false, 'DAILY', NULL, NULL, NULL, NULL);
```

## WEEKLY — settimanale

Esempio: ogni lunedì, con sei giorni di retry.

```sql
INSERT INTO hcbi_utility.dwh_schedule
    (process_code, process_description, enabled, frequency_code,
     anchor_month, week_ordinal, weekday_iso, retry_days)
VALUES
    ('DWH_REFRESH_WEEKLY', 'Refresh DWH - settimanale', false, 'WEEKLY',
     NULL, NULL, 1, 6);
```

## MONTHLY — mensile

Esempio: primo lunedì del mese, con sei giorni di retry.

```sql
INSERT INTO hcbi_utility.dwh_schedule
    (process_code, process_description, enabled, frequency_code,
     anchor_month, week_ordinal, weekday_iso, retry_days)
VALUES
    ('DWH_REFRESH_MONTHLY', 'Refresh DWH - mensile', false, 'MONTHLY',
     NULL, 1, 1, 6);
```

## BIMONTHLY — ogni due mesi

Esempio: gennaio, marzo, maggio, luglio, settembre e novembre; primo lunedì.

```sql
INSERT INTO hcbi_utility.dwh_schedule
    (process_code, process_description, enabled, frequency_code,
     anchor_month, week_ordinal, weekday_iso, retry_days)
VALUES
    ('DWH_REFRESH_BIMONTHLY', 'Refresh DWH - bimestrale', false, 'BIMONTHLY',
     1, 1, 1, 6);
```

## QUARTERLY — trimestrale

Esempio: gennaio, aprile, luglio e ottobre; primo lunedì.

```sql
INSERT INTO hcbi_utility.dwh_schedule
    (process_code, process_description, enabled, frequency_code,
     anchor_month, week_ordinal, weekday_iso, retry_days)
VALUES
    ('DWH_REFRESH_QUARTERLY', 'Refresh DWH - trimestrale', false, 'QUARTERLY',
     1, 1, 1, 6);
```

## FOUR_MONTHLY — ogni quattro mesi

Esempio: gennaio, maggio e settembre; primo lunedì.

```sql
INSERT INTO hcbi_utility.dwh_schedule
    (process_code, process_description, enabled, frequency_code,
     anchor_month, week_ordinal, weekday_iso, retry_days)
VALUES
    ('DWH_REFRESH_FOUR_MONTHLY', 'Refresh DWH - quadrimestrale', false, 'FOUR_MONTHLY',
     1, 1, 1, 6);
```

## SEMIANNUAL — semestrale

Esempio: gennaio e luglio; primo lunedì.

```sql
INSERT INTO hcbi_utility.dwh_schedule
    (process_code, process_description, enabled, frequency_code,
     anchor_month, week_ordinal, weekday_iso, retry_days)
VALUES
    ('DWH_REFRESH_SEMIANNUAL', 'Refresh DWH - semestrale', false, 'SEMIANNUAL',
     1, 1, 1, 6);
```

## ANNUAL — annuale

Esempio: gennaio di ogni anno; primo lunedì.

```sql
INSERT INTO hcbi_utility.dwh_schedule
    (process_code, process_description, enabled, frequency_code,
     anchor_month, week_ordinal, weekday_iso, retry_days)
VALUES
    ('DWH_REFRESH_ANNUAL', 'Refresh DWH - annuale', false, 'ANNUAL',
     1, 1, 1, 6);
```

## Verifica dopo l'inserimento

Eseguire questa query dopo aver applicato **uno solo** degli esempi:

```sql
SELECT schedule_id, process_code, process_description, enabled,
       frequency_code, anchor_month, week_ordinal, weekday_iso, retry_days
FROM hcbi_utility.dwh_schedule
WHERE process_code like '%DWH_REFRESH%';
```

La riga è inserita disabilitata. Abilitare la configurazione solo dopo aver
verificato i parametri e concordato l'attivazione; il trigger del database
disabilita automaticamente un'altra schedulazione quando se ne abilita una.
Se il `process_code` scelto esiste già, non ripetere l'`INSERT`: aggiornare
la riga esistente con una modifica approvata.
