-- PostgreSQL 17 - schedulazione del refresh DWH avviato tramite NiFi.
-- Eseguire come amministratore DB dopo backup e verifica preliminare.
-- Lo script non crea schema: hcbi_utility deve gia' esistere.
BEGIN;

CREATE TABLE hcbi_utility.dwh_schedule (
    schedule_id                 bigint GENERATED ALWAYS AS IDENTITY,
    process_code                varchar(100) NOT NULL,
    process_description         varchar(500) NOT NULL,
    enabled                     boolean NOT NULL DEFAULT false,
    frequency_code              varchar(20) NOT NULL,
    anchor_month                smallint,
    week_ordinal                smallint,
    weekday_iso                 smallint,
    retry_days                  smallint,
    last_success_at             timestamptz,
    last_success_period_start   date,
    last_attempt_at             timestamptz,
    last_attempt_status         varchar(20),
    last_error_message          varchar(4000),
    created_at                  timestamptz NOT NULL DEFAULT clock_timestamp(),
    updated_at                  timestamptz NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_dwh_schedule PRIMARY KEY (schedule_id),
    CONSTRAINT uq_dwh_schedule_process UNIQUE (process_code),
    CONSTRAINT ck_dwh_schedule_frequency CHECK (frequency_code IN (
        'ANNUAL', 'SEMIANNUAL', 'FOUR_MONTHLY', 'QUARTERLY',
        'BIMONTHLY', 'MONTHLY', 'WEEKLY', 'DAILY'
    )),
    CONSTRAINT ck_dwh_schedule_anchor CHECK (
        anchor_month IS NULL OR anchor_month BETWEEN 1 AND 12
    ),
    CONSTRAINT ck_dwh_schedule_week CHECK (
        week_ordinal IS NULL OR week_ordinal BETWEEN 1 AND 5
    ),
    CONSTRAINT ck_dwh_schedule_weekday CHECK (
        weekday_iso IS NULL OR weekday_iso BETWEEN 1 AND 7
    ),
    CONSTRAINT ck_dwh_schedule_retry CHECK (
        retry_days IS NULL OR retry_days >= 0
    ),
    CONSTRAINT ck_dwh_schedule_status CHECK (
        last_attempt_status IS NULL OR
        last_attempt_status IN ('RUNNING', 'SUCCESS', 'FAILED', 'SKIPPED')
    ),
    CONSTRAINT ck_dwh_schedule_shape CHECK (
        (frequency_code = 'DAILY'
         AND anchor_month IS NULL AND week_ordinal IS NULL
         AND weekday_iso IS NULL AND retry_days IS NULL)
        OR
        (frequency_code = 'WEEKLY'
         AND anchor_month IS NULL AND week_ordinal IS NULL
         AND weekday_iso IS NOT NULL AND retry_days IS NOT NULL)
        OR
        (frequency_code = 'MONTHLY'
         AND anchor_month IS NULL AND week_ordinal IS NOT NULL
         AND weekday_iso IS NOT NULL AND retry_days IS NOT NULL)
        OR
        (frequency_code IN (
            'ANNUAL', 'SEMIANNUAL', 'FOUR_MONTHLY', 'QUARTERLY', 'BIMONTHLY'
         )
         AND anchor_month IS NOT NULL AND week_ordinal IS NOT NULL
         AND weekday_iso IS NOT NULL AND retry_days IS NOT NULL)
    )
);

-- Vincolo difensivo: al massimo una riga abilitata anche in caso di errori
-- applicativi o di concorrenza durante l'aggiornamento della configurazione.
CREATE UNIQUE INDEX uq_dwh_schedule_one_enabled
    ON hcbi_utility.dwh_schedule ((enabled))
    WHERE enabled;

CREATE TABLE hcbi_utility.dwh_schedule_run (
    run_id          uuid PRIMARY KEY,
    schedule_id     bigint NOT NULL
                    REFERENCES hcbi_utility.dwh_schedule(schedule_id),
    process_code    varchar(100) NOT NULL,
    planned_date    date,
    trigger_source  varchar(20) NOT NULL DEFAULT 'SCHEDULED',
    requested_by    varchar(255),
    period_start    date,
    period_end      date,
    started_at      timestamptz NOT NULL DEFAULT clock_timestamp(),
    finished_at     timestamptz,
    status          varchar(20) NOT NULL,
    return_code     integer,
    duration_ms     bigint,
    error_message   varchar(4000),
    CONSTRAINT ck_dwh_schedule_run_trigger_source CHECK (
        trigger_source IN ('SCHEDULED', 'MANUAL_UI')
    ),
    CONSTRAINT ck_dwh_schedule_run_status CHECK (
        status IN ('RUNNING', 'SUCCESS', 'FAILED', 'SKIPPED')
    ),
    CONSTRAINT ck_dwh_schedule_run_duration CHECK (
        duration_ms IS NULL OR duration_ms >= 0
    ),
    CONSTRAINT ck_dwh_schedule_run_lifecycle CHECK (
        (status = 'RUNNING' AND finished_at IS NULL AND return_code IS NULL)
        OR
        (status <> 'RUNNING' AND finished_at IS NOT NULL)
    ),
    CONSTRAINT ck_dwh_schedule_run_dates CHECK (
        period_end IS NULL OR period_start IS NULL OR period_end >= period_start
    )
);

CREATE INDEX ix_dwh_schedule_run_schedule_started
    ON hcbi_utility.dwh_schedule_run (schedule_id, started_at DESC);
CREATE INDEX ix_dwh_schedule_run_status_started
    ON hcbi_utility.dwh_schedule_run (status, started_at DESC);

-- Quando si abilita una configurazione, disabilita automaticamente la
-- precedente. L'indice parziale resta la garanzia finale di unicita'.
CREATE OR REPLACE FUNCTION hcbi_utility.fn_dwh_schedule_enable_exclusive()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.enabled AND (TG_OP = 'INSERT' OR OLD.enabled IS DISTINCT FROM NEW.enabled) THEN
        UPDATE hcbi_utility.dwh_schedule
           SET enabled = false,
               updated_at = clock_timestamp()
         WHERE enabled = true
           AND schedule_id IS DISTINCT FROM NEW.schedule_id;
    END IF;
    NEW.updated_at := clock_timestamp();
    RETURN NEW;
END;
$function$;

CREATE TRIGGER trg_dwh_schedule_enable_exclusive
BEFORE INSERT OR UPDATE ON hcbi_utility.dwh_schedule
FOR EACH ROW
EXECUTE FUNCTION hcbi_utility.fn_dwh_schedule_enable_exclusive();

GRANT USAGE ON SCHEMA hcbi_utility TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE
    ON hcbi_utility.dwh_schedule, hcbi_utility.dwh_schedule_run TO hcbi_ras;
GRANT USAGE, SELECT ON SEQUENCE hcbi_utility.dwh_schedule_schedule_id_seq TO hcbi_ras;
GRANT EXECUTE ON FUNCTION hcbi_utility.fn_dwh_schedule_enable_exclusive() TO hcbi_ras;

COMMIT;
