/* =====================================================================
   DIM_MACRO_GRUPPO - DDL E PROCEDURE DI CARICAMENTO
   Target: PostgreSQL 15.9 / 17
   Schema: hcbi_ras

   Sorgente:
       hcbi_ras.dwh_anag_macro_gruppo

   Destinazione:
       hcbi_ras.dim_macro_gruppo

   Grain:
       una riga per ID_ANAG_MACRO_GRUPPO.

   Chiave primaria:
       id_anag_macro_gruppo

   Business key:
       ds_nome

   Attributi:
       ds_nome, ds_plurale

   Strategia:
       SCD Type 1; aggiornamento dei soli record variati; inserimento dei
       nuovi record; nessuna cancellazione.

   Record tecnici:
       0  = NON DISPONIBILE
       -1 = ANAGRAFICA ASSENTE

   Nota:
       la sorgente non espone un codice funzionale separato. Pertanto i
       record tecnici valorizzano entrambi gli attributi descrittivi con
       la relativa descrizione standard.

   Vincolo operativo:
       la tabella di lavoro ha nome fisso; non e' ammessa l'esecuzione
       concorrente della procedura MAIN.
   ===================================================================== */

/* =====================================================================
   TABELLA DIMENSIONALE
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dim_macro_gruppo
(
    id_anag_macro_gruppo BIGINT NOT NULL,
    ds_nome                  VARCHAR(50) NOT NULL,
    ds_plurale               VARCHAR(50),
    dt_creation              TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by           VARCHAR(4000)
        NOT NULL DEFAULT CURRENT_USER,
    dt_update                TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT clock_timestamp(),
    tx_update_by             VARCHAR(4000)
        NOT NULL DEFAULT CURRENT_USER,

    CONSTRAINT pk_dim_macro_gruppo
        PRIMARY KEY (id_anag_macro_gruppo),

    CONSTRAINT uq_dim_macro_gruppo
        UNIQUE NULLS NOT DISTINCT (ds_nome)
)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dim_macro_gruppo OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.dim_macro_gruppo FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.dim_macro_gruppo TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.dim_macro_gruppo TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dim_macro_gruppo IS
    'Dimensione dei macro-gruppi alimentata da HCBI_RAS.DWH_ANAG_MACRO_GRUPPO.';
COMMENT ON COLUMN hcbi_ras.dim_macro_gruppo.id_anag_macro_gruppo IS
    'Chiave primaria mantenuta dalla chiave DWH sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_macro_gruppo.ds_nome IS
    'Nome singolare del macro-gruppo e business key della dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_macro_gruppo.ds_plurale IS
    'Nome plurale facoltativo del macro-gruppo.';
COMMENT ON COLUMN hcbi_ras.dim_macro_gruppo.dt_creation IS
    'Timestamp di creazione del record nella dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_macro_gruppo.tx_creation_by IS
    'Processo che ha creato il record nella dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_macro_gruppo.dt_update IS
    'Timestamp dell ultimo aggiornamento del record.';
COMMENT ON COLUMN hcbi_ras.dim_macro_gruppo.tx_update_by IS
    'Processo che ha eseguito l ultimo aggiornamento.';
COMMENT ON CONSTRAINT pk_dim_macro_gruppo
ON hcbi_ras.dim_macro_gruppo IS
    'Chiave primaria tecnica: id_anag_macro_gruppo.';
COMMENT ON CONSTRAINT uq_dim_macro_gruppo
ON hcbi_ras.dim_macro_gruppo IS
    'Business key della dimensione: ds_nome.';

/* =====================================================================
   RECORD TECNICI
   ===================================================================== */
INSERT INTO hcbi_ras.dim_macro_gruppo
(
    id_anag_macro_gruppo,
    ds_nome,
    ds_plurale,
    dt_creation,
    tx_creation_by,
    dt_update,
    tx_update_by
)
VALUES
(
    0,
    'NON DISPONIBILE',
    'NON DISPONIBILE',
    clock_timestamp(),
    CURRENT_USER,
    clock_timestamp(),
    CURRENT_USER
),
(
    -1,
    'ANAGRAFICA ASSENTE',
    'ANAGRAFICA ASSENTE',
    clock_timestamp(),
    CURRENT_USER,
    clock_timestamp(),
    CURRENT_USER
)
ON CONFLICT ON CONSTRAINT pk_dim_macro_gruppo
DO NOTHING;

/* =====================================================================
   PROCEDURA INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_macro_gruppo_prc_initialize(
    IN p_id_chain_log BIGINT,
    IN p_id_chain BIGINT,
    IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING,
    OUT p_result INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT;
    v_selected BIGINT := 0;
    v_inserted BIGINT := 0;
    v_updated BIGINT := 0;
    v_deleted BIGINT := 0;
    v_rec_errors BIGINT := 0;
    v_sqlstate TEXT;
    v_sqlerrm TEXT;
    v_sql_detail TEXT;
    v_sql_hint TEXT;
    v_sql_context TEXT;
    v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::TIMESTAMP,
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    )
    INTO v_id_log;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    );

    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_sqlerrm = MESSAGE_TEXT,
            v_sql_detail = PG_EXCEPTION_DETAIL,
            v_sql_hint = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;

        p_result := -1;
        v_log_error := LEFT(CONCAT_WS(E'\n',
            'SQLSTATE=' || COALESCE(v_sqlstate, ''),
            'MESSAGE=' || LEFT(COALESCE(v_sqlerrm, ''), 1500),
            CASE WHEN NULLIF(v_sql_detail, '') IS NOT NULL
                THEN 'DETAIL=' || LEFT(v_sql_detail, 1000) END,
            CASE WHEN NULLIF(v_sql_hint, '') IS NOT NULL
                THEN 'HINT=' || LEFT(v_sql_hint, 500) END,
            CASE WHEN NULLIF(v_sql_context, '') IS NOT NULL
                THEN 'CONTEXT=' || LEFT(v_sql_context, 800) END
        ), 4000);

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::TIMESTAMP,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore durante il logging: SQLSTATE=%, errore=%',
                        SQLSTATE, SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dim_macro_gruppo_prc_initialize. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_macro_gruppo_prc_initialize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_macro_gruppo_prc_initialize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_macro_gruppo_prc_initialize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) IS 'Inizializza il caricamento DIM_MACRO_GRUPPO e registra l esecuzione nel log.';

/* =====================================================================
   PROCEDURA MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_macro_gruppo_prc_main(
    IN p_id_chain_log BIGINT,
    IN p_id_chain BIGINT,
    IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING,
    OUT p_result INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT;
    v_selected BIGINT := 0;
    v_inserted BIGINT := 0;
    v_updated BIGINT := 0;
    v_deleted BIGINT := 0;
    v_rec_errors BIGINT := 0;
    v_matched BIGINT := 0;
    v_sqlstate TEXT;
    v_sqlerrm TEXT;
    v_sql_detail TEXT;
    v_sql_hint TEXT;
    v_sql_context TEXT;
    v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::TIMESTAMP,
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    )
    INTO v_id_log;

    IF NOT EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_macro_gruppo
        WHERE id_anag_macro_gruppo = 0
    ) OR NOT EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_macro_gruppo
        WHERE id_anag_macro_gruppo = -1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'Record tecnici 0 e/o -1 non presenti in DIM_MACRO_GRUPPO',
                HINT = 'Eseguire l insert dei record tecnici prima della procedura MAIN.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dwh_anag_macro_gruppo
        GROUP BY id_anag_macro_gruppo
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'Chiave DWH non deterministica: ID_ANAG_MACRO_GRUPPO duplicato';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dwh_anag_macro_gruppo
        GROUP BY ds_nome
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'Business key DWH non deterministica: DS_NOME duplicato';
    END IF;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_macro_gruppo;

    CREATE TABLE hcbi_ras.tmp_dim_macro_gruppo AS
    SELECT
        src.id_anag_macro_gruppo,
        src.ds_nome,
        src.ds_plurale
    FROM hcbi_ras.dwh_anag_macro_gruppo AS src;

    CREATE UNIQUE INDEX tmp_dim_macro_gruppo_pk
        ON hcbi_ras.tmp_dim_macro_gruppo
        (id_anag_macro_gruppo)
        NULLS NOT DISTINCT;

    CREATE UNIQUE INDEX tmp_dim_macro_gruppo_bk
        ON hcbi_ras.tmp_dim_macro_gruppo
        (ds_nome)
        NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_macro_gruppo;

    SELECT COUNT(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dim_macro_gruppo;

    UPDATE hcbi_ras.dim_macro_gruppo AS d
       SET ds_nome = src.ds_nome,
           ds_plurale = src.ds_plurale,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_macro_gruppo AS src
     WHERE d.id_anag_macro_gruppo = src.id_anag_macro_gruppo
       AND ROW(d.ds_nome, d.ds_plurale)
           IS DISTINCT FROM
           ROW(src.ds_nome, src.ds_plurale);

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_macro_gruppo
    (
        id_anag_macro_gruppo,
        ds_nome,
        ds_plurale,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_anag_macro_gruppo,
        src.ds_nome,
        src.ds_plurale,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dim_macro_gruppo AS src
    ON CONFLICT ON CONSTRAINT pk_dim_macro_gruppo
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    SELECT COUNT(*)
    INTO v_matched
    FROM hcbi_ras.dim_macro_gruppo AS d
    INNER JOIN hcbi_ras.tmp_dim_macro_gruppo AS src
        ON src.id_anag_macro_gruppo = d.id_anag_macro_gruppo;

    IF v_selected <> v_matched THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = FORMAT(
                    'Riconciliazione DIM_MACRO_GRUPPO non valida: selected=%s, matched=%s',
                    v_selected,
                    v_matched
                ),
                DETAIL = 'Non tutte le chiavi DWH risultano presenti nella dimensione.';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_macro_gruppo;
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_sqlerrm = MESSAGE_TEXT,
            v_sql_detail = PG_EXCEPTION_DETAIL,
            v_sql_hint = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;

        p_result := -1;

        BEGIN
            DROP TABLE IF EXISTS hcbi_ras.tmp_dim_macro_gruppo;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante il cleanup: SQLSTATE=%, errore=%',
                    SQLSTATE, SQLERRM;
        END;

        v_log_error := LEFT(CONCAT_WS(E'\n',
            'SQLSTATE=' || COALESCE(v_sqlstate, ''),
            'MESSAGE=' || LEFT(COALESCE(v_sqlerrm, ''), 1500),
            CASE WHEN NULLIF(v_sql_detail, '') IS NOT NULL
                THEN 'DETAIL=' || LEFT(v_sql_detail, 1000) END,
            CASE WHEN NULLIF(v_sql_hint, '') IS NOT NULL
                THEN 'HINT=' || LEFT(v_sql_hint, 500) END,
            CASE WHEN NULLIF(v_sql_context, '') IS NOT NULL
                THEN 'CONTEXT=' || LEFT(v_sql_context, 800) END
        ), 4000);

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::TIMESTAMP,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore durante il logging: SQLSTATE=%, errore=%',
                        SQLSTATE, SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dim_macro_gruppo_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_macro_gruppo_prc_main(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_macro_gruppo_prc_main(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_macro_gruppo_prc_main(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) IS 'Carica DIM_MACRO_GRUPPO dalla DWH con strategia SCD Type 1, senza delete.';

/* =====================================================================
   PROCEDURA FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_macro_gruppo_prc_finalize(
    IN p_id_chain_log BIGINT,
    IN p_id_chain BIGINT,
    IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING,
    OUT p_result INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT;
    v_selected BIGINT := 0;
    v_inserted BIGINT := 0;
    v_updated BIGINT := 0;
    v_deleted BIGINT := 0;
    v_rec_errors BIGINT := 0;
    v_sqlstate TEXT;
    v_sqlerrm TEXT;
    v_sql_detail TEXT;
    v_sql_hint TEXT;
    v_sql_context TEXT;
    v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::TIMESTAMP,
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    )
    INTO v_id_log;

    ANALYZE hcbi_ras.dim_macro_gruppo;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    );

    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_sqlerrm = MESSAGE_TEXT,
            v_sql_detail = PG_EXCEPTION_DETAIL,
            v_sql_hint = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;

        p_result := -1;
        v_log_error := LEFT(CONCAT_WS(E'\n',
            'SQLSTATE=' || COALESCE(v_sqlstate, ''),
            'MESSAGE=' || LEFT(COALESCE(v_sqlerrm, ''), 1500),
            CASE WHEN NULLIF(v_sql_detail, '') IS NOT NULL
                THEN 'DETAIL=' || LEFT(v_sql_detail, 1000) END,
            CASE WHEN NULLIF(v_sql_hint, '') IS NOT NULL
                THEN 'HINT=' || LEFT(v_sql_hint, 500) END,
            CASE WHEN NULLIF(v_sql_context, '') IS NOT NULL
                THEN 'CONTEXT=' || LEFT(v_sql_context, 800) END
        ), 4000);

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::TIMESTAMP,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore durante il logging: SQLSTATE=%, errore=%',
                        SQLSTATE, SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dim_macro_gruppo_prc_finalize. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_macro_gruppo_prc_finalize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_macro_gruppo_prc_finalize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_macro_gruppo_prc_finalize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) IS 'Finalizza il caricamento DIM_MACRO_GRUPPO e aggiorna le statistiche.';

/* =====================================================================
   TEST POST-DEPLOYMENT
   ===================================================================== */

/* T01 - Struttura. Atteso: 7 colonne. */
-- SELECT column_name,data_type,is_nullable
-- FROM information_schema.columns
-- WHERE table_schema='hcbi_ras'
--   AND table_name='dim_macro_gruppo'
-- ORDER BY ordinal_position;

/* T02 - Record tecnici. Atteso: due righe. */
-- SELECT id_anag_macro_gruppo,ds_nome,ds_plurale
-- FROM hcbi_ras.dim_macro_gruppo
-- WHERE id_anag_macro_gruppo IN (0,-1)
-- ORDER BY id_anag_macro_gruppo;

/* T03 - Duplicati PK. Atteso: zero righe. */
-- SELECT id_anag_macro_gruppo,COUNT(*)
-- FROM hcbi_ras.dim_macro_gruppo
-- GROUP BY id_anag_macro_gruppo
-- HAVING COUNT(*)>1;

/* T04 - Duplicati business key. Atteso: zero righe. */
-- SELECT ds_nome,COUNT(*)
-- FROM hcbi_ras.dim_macro_gruppo
-- GROUP BY ds_nome
-- HAVING COUNT(*)>1;

/* T05 - Campi obbligatori NULL. Atteso: zero. */
-- SELECT COUNT(*) AS record_non_validi
-- FROM hcbi_ras.dim_macro_gruppo
-- WHERE id_anag_macro_gruppo IS NULL
--    OR ds_nome IS NULL
--    OR dt_creation IS NULL
--    OR tx_creation_by IS NULL
--    OR dt_update IS NULL
--    OR tx_update_by IS NULL;

/* T06 - Chiavi DWH non caricate. Atteso: zero. */
-- SELECT COUNT(*) AS chiavi_non_caricate
-- FROM hcbi_ras.dwh_anag_macro_gruppo AS src
-- LEFT JOIN hcbi_ras.dim_macro_gruppo AS d
--   ON d.id_anag_macro_gruppo=src.id_anag_macro_gruppo
-- WHERE d.id_anag_macro_gruppo IS NULL;

/* T07 - Coerenza degli attributi DWH-DIM. Atteso: zero. */
-- SELECT COUNT(*) AS record_non_coerenti
-- FROM hcbi_ras.dwh_anag_macro_gruppo AS src
-- INNER JOIN hcbi_ras.dim_macro_gruppo AS d
--   ON d.id_anag_macro_gruppo=src.id_anag_macro_gruppo
-- WHERE ROW(d.ds_nome,d.ds_plurale)
--       IS DISTINCT FROM ROW(src.ds_nome,src.ds_plurale);

/* T08 - Righe DIM non provenienti dalla DWH.
   Atteso: solo i record tecnici 0 e -1, salvo record storici mantenuti
   dalla regola di non cancellazione. */
-- SELECT d.id_anag_macro_gruppo,d.ds_nome,d.ds_plurale
-- FROM hcbi_ras.dim_macro_gruppo AS d
-- LEFT JOIN hcbi_ras.dwh_anag_macro_gruppo AS src
--   ON src.id_anag_macro_gruppo=d.id_anag_macro_gruppo
-- WHERE src.id_anag_macro_gruppo IS NULL
-- ORDER BY d.id_anag_macro_gruppo;

/* T09 - Idempotenza.
   Rilanciare INITIALIZE, MAIN e FINALIZE senza modificare la DWH.
   Atteso nel log della MAIN: inserted=0 e updated=0. */
-- SELECT COUNT(*) AS numero_record,MAX(dt_update) AS ultimo_aggiornamento
-- FROM hcbi_ras.dim_macro_gruppo;
