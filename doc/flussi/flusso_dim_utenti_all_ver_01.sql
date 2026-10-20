/* =====================================================================
   DIM_UTENTI - DDL E PROCEDURE DI CARICAMENTO
   Target: PostgreSQL 15.9 / 17
   Pattern: flusso_dim_unita_misura_all_ver_01.sql
   Sorgente: hcbi_ras.dwh_anag_utenti
   Destinazione: hcbi_ras.dim_utenti
   Grain: una riga per ID_ANAG_UTENTE.
   Chiave primaria: id_anag_utente
   Business key ereditata: cd_username
   Strategia: SCD Type 1, nessun delete.

   Informazioni verificate dalla DDL sorgente:
     id_anag_utente       BIGINT NOT NULL
     id_sorgente_utente   BIGINT
     cd_username          VARCHAR(255) NOT NULL
     ds_email             VARCHAR(255)
     ds_nome_visualizzato VARCHAR(50)
     cd_stato             SMALLINT
     cd_tipo_utente       VARCHAR(25)

   Assunzioni da validare:
     1. id_anag_utente viene mantenuto uguale alla chiave DWH.
     2. cd_username resta univoco nella dimensione.
     3. Non e' richiesta storicizzazione SCD Type 2.
     4. Non sono richiesti delete fisici/logici per assenza dalla sorgente.
     5. La tabella di lavoro ha nome fisso e la MAIN non viene eseguita
        in concorrenza.
   ===================================================================== */

/* =====================================================================
   TABELLA DIMENSIONALE
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dim_utenti
(
    id_anag_utente       BIGINT NOT NULL,
    id_sorgente_utente   BIGINT,
    cd_username          VARCHAR(255) NOT NULL,
    ds_email             VARCHAR(255),
    ds_nome_visualizzato VARCHAR(50),
    cd_stato             SMALLINT,
    cd_tipo_utente       VARCHAR(25),
    dt_creation          TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by       VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update            TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_update_by         VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT pk_dim_utenti PRIMARY KEY (id_anag_utente),
    CONSTRAINT uq_dim_utenti UNIQUE NULLS NOT DISTINCT (cd_username)
)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dim_utenti OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.dim_utenti FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.dim_utenti TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.dim_utenti TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dim_utenti IS
    'Dimensione utenti alimentata da HCBI_RAS.DWH_ANAG_UTENTI.';
COMMENT ON COLUMN hcbi_ras.dim_utenti.id_anag_utente IS
    'Chiave primaria mantenuta dalla chiave DWH sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_utenti.id_sorgente_utente IS
    'Identificativo dell utente nel sistema sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_utenti.cd_username IS
    'Username e business key della dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_utenti.ds_email IS
    'Indirizzo email dell utente.';
COMMENT ON COLUMN hcbi_ras.dim_utenti.ds_nome_visualizzato IS
    'Nome visualizzato dell utente.';
COMMENT ON COLUMN hcbi_ras.dim_utenti.cd_stato IS
    'Stato dell utente.';
COMMENT ON COLUMN hcbi_ras.dim_utenti.cd_tipo_utente IS
    'Tipologia dell utente.';
COMMENT ON COLUMN hcbi_ras.dim_utenti.dt_creation IS
    'Timestamp di creazione del record nella dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_utenti.tx_creation_by IS
    'Processo che ha creato il record nella dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_utenti.dt_update IS
    'Timestamp dell ultimo aggiornamento del record nella dimensione.';
COMMENT ON COLUMN hcbi_ras.dim_utenti.tx_update_by IS
    'Processo che ha eseguito l ultimo aggiornamento.';
COMMENT ON CONSTRAINT pk_dim_utenti ON hcbi_ras.dim_utenti IS
    'Chiave primaria: id_anag_utente.';
COMMENT ON CONSTRAINT uq_dim_utenti ON hcbi_ras.dim_utenti IS
    'Business key: cd_username.';

/* =====================================================================
   PROCEDURA INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_utenti_prc_initialize(
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

    /* Nessuna inizializzazione applicativa richiesta. */
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
            'Errore in pkg_dim_utenti_prc_initialize. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_utenti_prc_initialize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_utenti_prc_initialize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_utenti_prc_initialize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) IS 'Inizializza il caricamento DIM_UTENTI e registra l esecuzione nel log.';

/* =====================================================================
   PROCEDURA MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_utenti_prc_main(
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

    /*
       Materializzazione della sorgente DWH. I campi tecnici della DWH
       non vengono trasferiti nella dimensione.
    */
    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_utenti;

    CREATE TABLE hcbi_ras.tmp_dim_utenti AS
    SELECT
        src.id_anag_utente,
        src.id_sorgente_utente,
        src.cd_username,
        src.ds_email,
        src.ds_nome_visualizzato,
        src.cd_stato,
        src.cd_tipo_utente
    FROM hcbi_ras.dwh_anag_utenti AS src;

    /* Verifica preventiva della primary key sorgente. */
    CREATE UNIQUE INDEX tmp_dim_utenti_pk
        ON hcbi_ras.tmp_dim_utenti (id_anag_utente)
        NULLS NOT DISTINCT;

    /* Verifica preventiva della business key sorgente. */
    CREATE UNIQUE INDEX tmp_dim_utenti_bk
        ON hcbi_ras.tmp_dim_utenti (cd_username)
        NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_utenti;

    SELECT COUNT(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dim_utenti;

    /* Aggiornamento SCD Type 1 dei soli attributi variati. */
    UPDATE hcbi_ras.dim_utenti AS d
       SET id_sorgente_utente = src.id_sorgente_utente,
           cd_username = src.cd_username,
           ds_email = src.ds_email,
           ds_nome_visualizzato = src.ds_nome_visualizzato,
           cd_stato = src.cd_stato,
           cd_tipo_utente = src.cd_tipo_utente,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_utenti AS src
     WHERE d.id_anag_utente = src.id_anag_utente
       AND ROW(
            d.id_sorgente_utente,
            d.cd_username,
            d.ds_email,
            d.ds_nome_visualizzato,
            d.cd_stato,
            d.cd_tipo_utente
       ) IS DISTINCT FROM ROW(
            src.id_sorgente_utente,
            src.cd_username,
            src.ds_email,
            src.ds_nome_visualizzato,
            src.cd_stato,
            src.cd_tipo_utente
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_utenti
    (
        id_anag_utente,
        id_sorgente_utente,
        cd_username,
        ds_email,
        ds_nome_visualizzato,
        cd_stato,
        cd_tipo_utente,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_anag_utente,
        src.id_sorgente_utente,
        src.cd_username,
        src.ds_email,
        src.ds_nome_visualizzato,
        src.cd_stato,
        src.cd_tipo_utente,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dim_utenti AS src
    ON CONFLICT ON CONSTRAINT pk_dim_utenti
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    /*
       Riconciliazione per chiave primaria: ogni riga della sorgente deve
       risultare presente nella dimensione dopo UPDATE e INSERT.
    */
    SELECT COUNT(*)
    INTO v_matched
    FROM hcbi_ras.dim_utenti AS d
    INNER JOIN hcbi_ras.tmp_dim_utenti AS src
        ON src.id_anag_utente = d.id_anag_utente;

    IF v_selected <> v_matched THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = FORMAT(
                    'Riconciliazione DIM_UTENTI non valida: selected=%s, matched=%s',
                    v_selected,
                    v_matched
                ),
                DETAIL =
                    'Non tutte le chiavi ID_ANAG_UTENTE della sorgente risultano presenti nella dimensione.';
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_utenti;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dim_utenti;
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
            'Errore in pkg_dim_utenti_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_utenti_prc_main(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_utenti_prc_main(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_utenti_prc_main(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) IS 'Materializza DWH_ANAG_UTENTI, verifica PK e business key, aggiorna i record variati e inserisce i nuovi record in DIM_UTENTI.';

/* =====================================================================
   PROCEDURA FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_utenti_prc_finalize(
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

    ANALYZE hcbi_ras.dim_utenti;

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
            'Errore in pkg_dim_utenti_prc_finalize. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_utenti_prc_finalize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_utenti_prc_finalize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_utenti_prc_finalize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) IS 'Finalizza il caricamento DIM_UTENTI e aggiorna le statistiche.';

/* =====================================================================
   TEST DI VERIFICA POST-DEPLOYMENT
   ===================================================================== */

/* 1. Verifica duplicati sulla PK sorgente. */
-- SELECT id_anag_utente, COUNT(*)
-- FROM hcbi_ras.dwh_anag_utenti
-- GROUP BY id_anag_utente
-- HAVING COUNT(*) > 1;

/* 2. Verifica duplicati sulla business key sorgente. */
-- SELECT cd_username, COUNT(*)
-- FROM hcbi_ras.dwh_anag_utenti
-- GROUP BY cd_username
-- HAVING COUNT(*) > 1;

/* 3. Riconciliazione delle chiavi DWH verso DIM. */
-- SELECT COUNT(*) AS chiavi_dwh_non_presenti_in_dim
-- FROM hcbi_ras.dwh_anag_utenti AS src
-- LEFT JOIN hcbi_ras.dim_utenti AS d
--     ON d.id_anag_utente = src.id_anag_utente
-- WHERE d.id_anag_utente IS NULL;

/* 4. Verifica anomalie sulla business key della DIM. */
-- SELECT cd_username, COUNT(*)
-- FROM hcbi_ras.dim_utenti
-- GROUP BY cd_username
-- HAVING COUNT(*) > 1;
