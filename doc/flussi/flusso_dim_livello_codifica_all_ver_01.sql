/* =====================================================================
   DIM_LIVELLO_CODIFICA - DDL E PROCEDURE DI CARICAMENTO
   Target: PostgreSQL 15.9 / 17
   Schema: hcbi_ras

   Sorgente:
       hcbi_ras.dwh_anag_livello_codifica

   Destinazione:
       hcbi_ras.dim_livello_codifica

   Grain:
       una riga per ID_ANAG_LIVELLO_CODIFICA.

   Chiave primaria:
       id_anag_livello_codifica

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
CREATE TABLE IF NOT EXISTS hcbi_ras.dim_livello_codifica
(
    id_anag_livello_codifica BIGINT NOT NULL,
    ds_nome                  VARCHAR(50) NOT NULL,
    ds_plurale               VARCHAR(50) NOT NULL,
    dt_creation              TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by           VARCHAR(4000)
        NOT NULL DEFAULT CURRENT_USER,
    dt_update                TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT clock_timestamp(),
    tx_update_by             VARCHAR(4000)
        NOT NULL DEFAULT CURRENT_USER,

    CONSTRAINT pk_dim_livello_codifica
        PRIMARY KEY (id_anag_livello_codifica),

    CONSTRAINT uq_dim_livello_codifica
        UNIQUE NULLS NOT DISTINCT (ds_nome)
)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dim_livello_codifica OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.dim_livello_codifica FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.dim_livello_codifica TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.dim_livello_codifica TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dim_livello_codifica IS
    'Dimensione dei livelli di codifica alimentata da HCBI_RAS.DWH_ANAG_LIVELLO_CODIFICA.';
COMMENT ON COLUMN hcbi_ras.dim_livello_codifica.id_anag_livello_codifica IS
    'Chiave primaria mantenuta dalla chiave DWH sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_livello_codifica.ds_nome IS
    'Nome singolare del livello di codifica e business key della dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_livello_codifica.ds_plurale IS
    'Nome plurale del livello di codifica.';
COMMENT ON COLUMN hcbi_ras.dim_livello_codifica.dt_creation IS
    'Timestamp di creazione del record nella dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_livello_codifica.tx_creation_by IS
    'Processo che ha creato il record nella dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_livello_codifica.dt_update IS
    'Timestamp dell ultimo aggiornamento del record.';
COMMENT ON COLUMN hcbi_ras.dim_livello_codifica.tx_update_by IS
    'Processo che ha eseguito l ultimo aggiornamento.';
COMMENT ON CONSTRAINT pk_dim_livello_codifica
ON hcbi_ras.dim_livello_codifica IS
    'Chiave primaria tecnica: id_anag_livello_codifica.';
COMMENT ON CONSTRAINT uq_dim_livello_codifica
ON hcbi_ras.dim_livello_codifica IS
    'Business key della dimensione: ds_nome.';

/* =====================================================================
   RECORD TECNICI
   ===================================================================== */
INSERT INTO hcbi_ras.dim_livello_codifica
(
    id_anag_livello_codifica,
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
ON CONFLICT ON CONSTRAINT pk_dim_livello_codifica
DO NOTHING;

/* =====================================================================
   PROCEDURA INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_livello_codifica_prc_initialize(
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
            'Errore in pkg_dim_livello_codifica_prc_initialize. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_livello_codifica_prc_initialize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_livello_codifica_prc_initialize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_livello_codifica_prc_initialize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) IS 'Inizializza il caricamento DIM_LIVELLO_CODIFICA e registra l esecuzione nel log.';

/* =====================================================================
   PROCEDURA MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_livello_codifica_prc_main(
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
        FROM hcbi_ras.dim_livello_codifica
        WHERE id_anag_livello_codifica = 0
    ) OR NOT EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_livello_codifica
        WHERE id_anag_livello_codifica = -1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'Record tecnici 0 e/o -1 non presenti in DIM_LIVELLO_CODIFICA',
                HINT = 'Eseguire l insert dei record tecnici prima della procedura MAIN.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dwh_anag_livello_codifica
        GROUP BY id_anag_livello_codifica
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'Chiave DWH non deterministica: ID_ANAG_LIVELLO_CODIFICA duplicato';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dwh_anag_livello_codifica
        GROUP BY ds_nome
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = 'Business key DWH non deterministica: DS_NOME duplicato';
    END IF;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_livello_codifica;

    CREATE TABLE hcbi_ras.tmp_dim_livello_codifica AS
    SELECT
        src.id_anag_livello_codifica,
        src.ds_nome,
        src.ds_plurale
    FROM hcbi_ras.dwh_anag_livello_codifica AS src;

    CREATE UNIQUE INDEX tmp_dim_livello_codifica_pk
        ON hcbi_ras.tmp_dim_livello_codifica
        (id_anag_livello_codifica)
        NULLS NOT DISTINCT;

    CREATE UNIQUE INDEX tmp_dim_livello_codifica_bk
        ON hcbi_ras.tmp_dim_livello_codifica
        (ds_nome)
        NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_livello_codifica;

    SELECT COUNT(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dim_livello_codifica;

    UPDATE hcbi_ras.dim_livello_codifica AS d
       SET ds_nome = src.ds_nome,
           ds_plurale = src.ds_plurale,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_livello_codifica AS src
     WHERE d.id_anag_livello_codifica = src.id_anag_livello_codifica
       AND ROW(d.ds_nome, d.ds_plurale)
           IS DISTINCT FROM
           ROW(src.ds_nome, src.ds_plurale);

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_livello_codifica
    (
        id_anag_livello_codifica,
        ds_nome,
        ds_plurale,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_anag_livello_codifica,
        src.ds_nome,
        src.ds_plurale,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dim_livello_codifica AS src
    ON CONFLICT ON CONSTRAINT pk_dim_livello_codifica
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    SELECT COUNT(*)
    INTO v_matched
    FROM hcbi_ras.dim_livello_codifica AS d
    INNER JOIN hcbi_ras.tmp_dim_livello_codifica AS src
        ON src.id_anag_livello_codifica = d.id_anag_livello_codifica;

    IF v_selected <> v_matched THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = FORMAT(
                    'Riconciliazione DIM_LIVELLO_CODIFICA non valida: selected=%s, matched=%s',
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_livello_codifica;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dim_livello_codifica;
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
            'Errore in pkg_dim_livello_codifica_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_livello_codifica_prc_main(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_livello_codifica_prc_main(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_livello_codifica_prc_main(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) IS 'Carica DIM_LIVELLO_CODIFICA dalla DWH con strategia SCD Type 1, senza delete.';

/* =====================================================================
   PROCEDURA FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_livello_codifica_prc_finalize(
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

    ANALYZE hcbi_ras.dim_livello_codifica;

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
            'Errore in pkg_dim_livello_codifica_prc_finalize. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_livello_codifica_prc_finalize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_livello_codifica_prc_finalize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_livello_codifica_prc_finalize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) IS 'Finalizza il caricamento DIM_LIVELLO_CODIFICA e aggiorna le statistiche.';

/* =====================================================================
   TEST POST-DEPLOYMENT
   ===================================================================== */

/* T01 - Struttura. Atteso: 7 colonne. */
-- SELECT column_name,data_type,is_nullable
-- FROM information_schema.columns
-- WHERE table_schema='hcbi_ras'
--   AND table_name='dim_livello_codifica'
-- ORDER BY ordinal_position;

/* T02 - Record tecnici. Atteso: due righe. */
-- SELECT id_anag_livello_codifica,ds_nome,ds_plurale
-- FROM hcbi_ras.dim_livello_codifica
-- WHERE id_anag_livello_codifica IN (0,-1)
-- ORDER BY id_anag_livello_codifica;

/* T03 - Duplicati PK. Atteso: zero righe. */
-- SELECT id_anag_livello_codifica,COUNT(*)
-- FROM hcbi_ras.dim_livello_codifica
-- GROUP BY id_anag_livello_codifica
-- HAVING COUNT(*)>1;

/* T04 - Duplicati business key. Atteso: zero righe. */
-- SELECT ds_nome,COUNT(*)
-- FROM hcbi_ras.dim_livello_codifica
-- GROUP BY ds_nome
-- HAVING COUNT(*)>1;

/* T05 - Campi obbligatori NULL. Atteso: zero. */
-- SELECT COUNT(*) AS record_non_validi
-- FROM hcbi_ras.dim_livello_codifica
-- WHERE id_anag_livello_codifica IS NULL
--    OR ds_nome IS NULL
--    OR ds_plurale IS NULL
--    OR dt_creation IS NULL
--    OR tx_creation_by IS NULL
--    OR dt_update IS NULL
--    OR tx_update_by IS NULL;

/* T06 - Chiavi DWH non caricate. Atteso: zero. */
-- SELECT COUNT(*) AS chiavi_non_caricate
-- FROM hcbi_ras.dwh_anag_livello_codifica AS src
-- LEFT JOIN hcbi_ras.dim_livello_codifica AS d
--   ON d.id_anag_livello_codifica=src.id_anag_livello_codifica
-- WHERE d.id_anag_livello_codifica IS NULL;

/* T07 - Coerenza degli attributi DWH-DIM. Atteso: zero. */
-- SELECT COUNT(*) AS record_non_coerenti
-- FROM hcbi_ras.dwh_anag_livello_codifica AS src
-- INNER JOIN hcbi_ras.dim_livello_codifica AS d
--   ON d.id_anag_livello_codifica=src.id_anag_livello_codifica
-- WHERE ROW(d.ds_nome,d.ds_plurale)
--       IS DISTINCT FROM ROW(src.ds_nome,src.ds_plurale);

/* T08 - Righe DIM non provenienti dalla DWH.
   Atteso: solo i record tecnici 0 e -1, salvo record storici mantenuti
   dalla regola di non cancellazione. */
-- SELECT d.id_anag_livello_codifica,d.ds_nome,d.ds_plurale
-- FROM hcbi_ras.dim_livello_codifica AS d
-- LEFT JOIN hcbi_ras.dwh_anag_livello_codifica AS src
--   ON src.id_anag_livello_codifica=d.id_anag_livello_codifica
-- WHERE src.id_anag_livello_codifica IS NULL
-- ORDER BY d.id_anag_livello_codifica;

/* T09 - Idempotenza.
   Rilanciare INITIALIZE, MAIN e FINALIZE senza modificare la DWH.
   Atteso nel log della MAIN: inserted=0 e updated=0. */
-- SELECT COUNT(*) AS numero_record,MAX(dt_update) AS ultimo_aggiornamento
-- FROM hcbi_ras.dim_livello_codifica;
