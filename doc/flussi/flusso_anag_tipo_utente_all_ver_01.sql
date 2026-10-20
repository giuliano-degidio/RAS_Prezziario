/* =====================================================================
   FLUSSO ANAG_TIPO_UTENTE - VERSIONE UNIFORMATA

   Target tecnico dichiarato dal flusso modello:
       PostgreSQL 15.9 / 17

   Sorgente logica:
       hcbi_ras.v_frontiera_anag_tipo_utente

   Sorgente fisica:
       hcbi_ras.frontiera_anag_utenti

   Query sorgente:
       SELECT DISTINCT usertype
       FROM hcbi_ras.frontiera_anag_utenti

   Mapping:
       usertype -> ds_tipo_utente

   Business key:
       ds_tipo_utente

   Vincolo operativo:
       le tabelle di lavoro persistenti hanno nome fisso;
       non e' ammessa l'esecuzione concorrente dello stesso flusso.
   ===================================================================== */

/* =====================================================================
   SEQUENCE DWH
   ===================================================================== */
CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_anag_tipo_utente
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_anag_tipo_utente
    OWNER TO hcbi_ras;

GRANT ALL
ON SEQUENCE hcbi_ras.seq_dwh_anag_tipo_utente
TO hcbi_ras;

GRANT USAGE, SELECT
ON SEQUENCE hcbi_ras.seq_dwh_anag_tipo_utente
TO hcbi_utility;

/* =====================================================================
   VISTA FRONTIERA
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_frontiera_anag_tipo_utente AS
SELECT DISTINCT
    u.usertype
FROM hcbi_ras.frontiera_anag_utenti AS u;

ALTER VIEW hcbi_ras.v_frontiera_anag_tipo_utente
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_frontiera_anag_tipo_utente
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_frontiera_anag_tipo_utente
TO hcbi_utility;

COMMENT ON VIEW hcbi_ras.v_frontiera_anag_tipo_utente
IS 'Vista di frontiera del flusso ANAG_TIPO_UTENTE ottenuta dai valori distinti di USERTYPE.';

/* =====================================================================
   TABELLA SRC_TMP DERIVATA DA VIEW
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_anag_tipo_utente_vw
(
    usertype character varying(100) COLLATE pg_catalog."default"
)
TABLESPACE pg_default;

ALTER TABLE hcbi_ras.src_tmp_anag_tipo_utente_vw
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.src_tmp_anag_tipo_utente_vw
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.src_tmp_anag_tipo_utente_vw
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.src_tmp_anag_tipo_utente_vw
TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.src_tmp_anag_tipo_utente_vw
IS 'Tabella temporanea del flusso ANAG_TIPO_UTENTE alimentata dalla vista di frontiera.';

/* =====================================================================
   VISTA SRC_TMP
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_anag_tipo_utente AS
SELECT
    btrim(s.usertype::text) AS ds_tipo_utente
FROM hcbi_ras.src_tmp_anag_tipo_utente_vw AS s;

ALTER VIEW hcbi_ras.v_src_tmp_anag_tipo_utente
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_src_tmp_anag_tipo_utente
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_src_tmp_anag_tipo_utente
TO hcbi_utility;

COMMENT ON VIEW hcbi_ras.v_src_tmp_anag_tipo_utente
IS 'Vista normalizzata della tabella temporanea ANAG_TIPO_UTENTE.';

/* =====================================================================
   TABELLA STG
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_tipo_utente
(
    ds_tipo_utente character varying(100)
        COLLATE pg_catalog."default" NOT NULL
)
TABLESPACE pg_default;

ALTER TABLE hcbi_ras.stg_anag_tipo_utente
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.stg_anag_tipo_utente
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.stg_anag_tipo_utente
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_tipo_utente
TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.stg_anag_tipo_utente
IS 'Staging del flusso ANAG_TIPO_UTENTE.';

COMMENT ON COLUMN hcbi_ras.stg_anag_tipo_utente.ds_tipo_utente
IS 'Tipologia dell''utente.';

/* =====================================================================
   TABELLA STG REJECT
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_tipo_utente_rej
(
    ds_tipo_utente character varying(100)
        COLLATE pg_catalog."default",
    tx_motivo_scarto character varying(4000)
        COLLATE pg_catalog."default"
)
TABLESPACE pg_default;

ALTER TABLE hcbi_ras.stg_anag_tipo_utente_rej
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.stg_anag_tipo_utente_rej
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.stg_anag_tipo_utente_rej
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_tipo_utente_rej
TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.stg_anag_tipo_utente_rej
IS 'Record scartati del flusso ANAG_TIPO_UTENTE.';

/* =====================================================================
   TABELLA DWH
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_anag_tipo_utente
(
    id_anag_tipo_utente bigint NOT NULL
        DEFAULT nextval(
            'hcbi_ras.seq_dwh_anag_tipo_utente'::regclass
        ),
    ds_tipo_utente character varying(100)
        COLLATE pg_catalog."default" NOT NULL,
    dt_creation timestamp without time zone
        NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by character varying(4000)
        COLLATE pg_catalog."default"
        NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone
        NOT NULL DEFAULT clock_timestamp(),
    tx_update_by character varying(4000)
        COLLATE pg_catalog."default"
        NOT NULL DEFAULT CURRENT_USER,
    dt_reciclo timestamp without time zone,
    CONSTRAINT pk_dwh_anag_tipo_utente
        PRIMARY KEY (id_anag_tipo_utente),
    CONSTRAINT uq_dwh_anag_tipo_utente
        UNIQUE NULLS NOT DISTINCT (ds_tipo_utente)
)
TABLESPACE pg_default;

ALTER TABLE hcbi_ras.dwh_anag_tipo_utente
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.dwh_anag_tipo_utente
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.dwh_anag_tipo_utente
TO hcbi_ras;

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE hcbi_ras.dwh_anag_tipo_utente
TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dwh_anag_tipo_utente
IS 'DWH del flusso ANAG_TIPO_UTENTE.';

COMMENT ON COLUMN hcbi_ras.dwh_anag_tipo_utente.ds_tipo_utente
IS 'Tipologia dell''utente.';

COMMENT ON CONSTRAINT uq_dwh_anag_tipo_utente
ON hcbi_ras.dwh_anag_tipo_utente
IS 'Business key del flusso ANAG_TIPO_UTENTE.';

/* =====================================================================
   VISTA DWH
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_dwh_anag_tipo_utente AS
SELECT
    s.ds_tipo_utente
FROM hcbi_ras.stg_anag_tipo_utente AS s;

ALTER VIEW hcbi_ras.v_dwh_anag_tipo_utente
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_dwh_anag_tipo_utente
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_dwh_anag_tipo_utente
TO hcbi_utility;

COMMENT ON VIEW hcbi_ras.v_dwh_anag_tipo_utente
IS 'Vista di raccordo tra STG_ANAG_TIPO_UTENTE e DWH_ANAG_TIPO_UTENTE.';

/* =====================================================================
   PROCEDURA STG INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_tipo_utente_prc_initialize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name character varying,
    OUT p_result integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
    v_selected bigint := 0;
    v_inserted bigint := 0;
    v_updated bigint := 0;
    v_deleted bigint := 0;
    v_rec_errors bigint := 0;
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Inizializzazione PKG_STG_ANAG_TIPO_UTENTE per lo step %',
        p_ds_step_name;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    TRUNCATE TABLE hcbi_ras.src_tmp_anag_tipo_utente_vw;
    TRUNCATE TABLE hcbi_ras.stg_anag_tipo_utente;
    TRUNCATE TABLE hcbi_ras.stg_anag_tipo_utente_rej;

    INSERT INTO hcbi_ras.src_tmp_anag_tipo_utente_vw (
        usertype
    )
    SELECT
        f.usertype
    FROM hcbi_ras.v_frontiera_anag_tipo_utente AS f;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;
    v_selected := v_inserted;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
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

        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
                CASE WHEN nullif(v_sql_detail, '') IS NOT NULL
                    THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
                CASE WHEN nullif(v_sql_hint, '') IS NOT NULL
                    THEN 'HINT=' || left(v_sql_hint, 500) END,
                CASE WHEN nullif(v_sql_context, '') IS NOT NULL
                    THEN 'CONTEXT=' || left(v_sql_context, 800) END
            ),
            4000
        );

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::timestamp,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore durante la registrazione del log: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_stg_anag_tipo_utente_prc_initialize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_tipo_utente_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_tipo_utente_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_tipo_utente_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
)
IS 'Svuota SRC_TMP, STG e REJ, alimenta la SRC_TMP dalla vista di frontiera e registra i conteggi nel log.';

/* =====================================================================
   PROCEDURA STG MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_tipo_utente_prc_main(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name character varying,
    OUT p_result integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
    v_selected bigint := 0;
    v_inserted bigint := 0;
    v_updated bigint := 0;
    v_deleted bigint := 0;
    v_rec_errors bigint := 0;
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Avvio PKG_STG_ANAG_TIPO_UTENTE per lo step %',
        p_ds_step_name;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_tipo_utente_classificata;

    CREATE TABLE hcbi_ras.tmp_anag_tipo_utente_classificata AS
    WITH src AS MATERIALIZED (
        SELECT
            f.ds_tipo_utente AS ds_tipo_utente_raw,
            nullif(btrim(f.ds_tipo_utente), '') AS ds_tipo_utente_txt,
            count(*) OVER (
                PARTITION BY nullif(btrim(f.ds_tipo_utente), '')
            ) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_anag_tipo_utente AS f
    )
    SELECT
        s.ds_tipo_utente_raw,
        s.ds_tipo_utente_txt,
        s.duplicate_count,
        CASE
            WHEN s.ds_tipo_utente_txt IS NULL THEN
                'ds_tipo_utente obbligatorio'
            WHEN length(s.ds_tipo_utente_txt) > 100 THEN
                'ds_tipo_utente eccede la lunghezza massima di 100 caratteri'
            WHEN s.duplicate_count > 1 THEN
                'Chiave duplicata nella sorgente: (ds_tipo_utente)'
            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM src AS s;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_anag_tipo_utente_classificata;

    INSERT INTO hcbi_ras.stg_anag_tipo_utente (
        ds_tipo_utente
    )
    SELECT
        c.ds_tipo_utente_txt
    FROM hcbi_ras.tmp_anag_tipo_utente_classificata AS c
    WHERE c.tx_motivo_scarto IS NULL;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_anag_tipo_utente_rej (
        ds_tipo_utente,
        tx_motivo_scarto
    )
    SELECT
        c.ds_tipo_utente_raw,
        c.tx_motivo_scarto
    FROM hcbi_ras.tmp_anag_tipo_utente_classificata AS c
    WHERE c.tx_motivo_scarto IS NOT NULL;

    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = format(
                    'Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',
                    v_selected,
                    v_inserted,
                    v_rec_errors
                ),
                DETAIL =
                    'Il numero di record letti non coincide con la somma dei record caricati e scartati.',
                HINT =
                    'Verificare la classificazione e gli INSERT verso STG e REJ.';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_tipo_utente_classificata;

    p_result := 1;

    RAISE NOTICE
        'Fine PKG_STG_ANAG_TIPO_UTENTE: selected=%, inserted=%, rejected=%',
        v_selected,
        v_inserted,
        v_rec_errors;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_anag_tipo_utente_classificata;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante la pulizia della tabella di lavoro: SQLSTATE=%, errore=%',
                    SQLSTATE,
                    SQLERRM;
        END;

        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
                CASE WHEN nullif(v_sql_detail, '') IS NOT NULL
                    THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
                CASE WHEN nullif(v_sql_hint, '') IS NOT NULL
                    THEN 'HINT=' || left(v_sql_hint, 500) END,
                CASE WHEN nullif(v_sql_context, '') IS NOT NULL
                    THEN 'CONTEXT=' || left(v_sql_context, 800) END
            ),
            4000
        );

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::timestamp,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore durante la registrazione del log: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_stg_anag_tipo_utente_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_tipo_utente_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_tipo_utente_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_tipo_utente_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
IS 'Classifica e carica in modalita set-based ANAG_TIPO_UTENTE, identifica valori mancanti, lunghezze non valide e duplicati, registra gli scarti e riconcilia i conteggi.';

/* =====================================================================
   PROCEDURA STG FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_tipo_utente_prc_finalize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name character varying,
    OUT p_result integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    ANALYZE hcbi_ras.src_tmp_anag_tipo_utente_vw;
    ANALYZE hcbi_ras.stg_anag_tipo_utente;
    ANALYZE hcbi_ras.stg_anag_tipo_utente_rej;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS',
        clock_timestamp()::timestamp,
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
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
            CASE WHEN nullif(v_sql_detail, '') IS NOT NULL THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
            CASE WHEN nullif(v_sql_hint, '') IS NOT NULL THEN 'HINT=' || left(v_sql_hint, 500) END,
            CASE WHEN nullif(v_sql_context, '') IS NOT NULL THEN 'CONTEXT=' || left(v_sql_context, 800) END
        ), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore durante la registrazione del log: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_stg_anag_tipo_utente_prc_finalize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_tipo_utente_prc_finalize(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_tipo_utente_prc_finalize(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_tipo_utente_prc_finalize(
    bigint, bigint, bigint, character varying
)
IS 'Finalizza il caricamento STG_ANAG_TIPO_UTENTE e aggiorna le statistiche.';

/* =====================================================================
   PROCEDURA DWH INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_tipo_utente_prc_initialize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name character varying,
    OUT p_result integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS',
        clock_timestamp()::timestamp,
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
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
            CASE WHEN nullif(v_sql_detail, '') IS NOT NULL THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
            CASE WHEN nullif(v_sql_hint, '') IS NOT NULL THEN 'HINT=' || left(v_sql_hint, 500) END,
            CASE WHEN nullif(v_sql_context, '') IS NOT NULL THEN 'CONTEXT=' || left(v_sql_context, 800) END
        ), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore durante la registrazione del log: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_dwh_anag_tipo_utente_prc_initialize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_tipo_utente_prc_initialize(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_tipo_utente_prc_initialize(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_tipo_utente_prc_initialize(
    bigint, bigint, bigint, character varying
)
IS 'Inizializza il flusso DWH_ANAG_TIPO_UTENTE e registra l''esecuzione nel log.';

/* =====================================================================
   PROCEDURA DWH MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_tipo_utente_prc_main(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name character varying,
    OUT p_result integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
    v_selected bigint := 0;
    v_inserted bigint := 0;
    v_updated bigint := 0;
    v_deleted bigint := 0;
    v_rec_errors bigint := 0;
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_tipo_utente;

    CREATE TABLE hcbi_ras.tmp_dwh_anag_tipo_utente AS
    SELECT
        s.ds_tipo_utente
    FROM hcbi_ras.v_dwh_anag_tipo_utente AS s;

    CREATE UNIQUE INDEX tmp_dwh_anag_tipo_utente_uq
    ON hcbi_ras.tmp_dwh_anag_tipo_utente (
        ds_tipo_utente
    ) NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dwh_anag_tipo_utente;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dwh_anag_tipo_utente;

    /* Il flusso contiene esclusivamente la business key e non possiede
       attributi descrittivi modificabili. Non sono pertanto previsti
       aggiornamenti DWH per record gia' esistenti. */
    v_updated := 0;

    INSERT INTO hcbi_ras.dwh_anag_tipo_utente (
        ds_tipo_utente,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.ds_tipo_utente,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_tipo_utente AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_anag_tipo_utente
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_tipo_utente;

    p_result := 1;

    RAISE NOTICE
        'Fine PKG_DWH_ANAG_TIPO_UTENTE: selected=%, inserted=%, updated=%',
        v_selected,
        v_inserted,
        v_updated;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_tipo_utente;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante la pulizia della tabella di lavoro: SQLSTATE=%, errore=%',
                    SQLSTATE,
                    SQLERRM;
        END;

        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
                CASE WHEN nullif(v_sql_detail, '') IS NOT NULL
                    THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
                CASE WHEN nullif(v_sql_hint, '') IS NOT NULL
                    THEN 'HINT=' || left(v_sql_hint, 500) END,
                CASE WHEN nullif(v_sql_context, '') IS NOT NULL
                    THEN 'CONTEXT=' || left(v_sql_context, 800) END
            ),
            4000
        );

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore durante la registrazione del log: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;

        RAISE WARNING 'Errore in pkg_dwh_anag_tipo_utente_prc_main. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_tipo_utente_prc_main(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_tipo_utente_prc_main(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_tipo_utente_prc_main(
    bigint, bigint, bigint, character varying
)
IS 'Materializza la sorgente DWH, verifica l''unicita della business key, inserisce i nuovi tipi utente e rimuove la tabella di lavoro anche in caso di errore.';

/* =====================================================================
   PROCEDURA DWH FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_tipo_utente_prc_finalize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name character varying,
    OUT p_result integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    ANALYZE hcbi_ras.dwh_anag_tipo_utente;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS',
        clock_timestamp()::timestamp,
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
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
            CASE WHEN nullif(v_sql_detail, '') IS NOT NULL THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
            CASE WHEN nullif(v_sql_hint, '') IS NOT NULL THEN 'HINT=' || left(v_sql_hint, 500) END,
            CASE WHEN nullif(v_sql_context, '') IS NOT NULL THEN 'CONTEXT=' || left(v_sql_context, 800) END
        ), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore durante la registrazione del log: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_dwh_anag_tipo_utente_prc_finalize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_tipo_utente_prc_finalize(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_tipo_utente_prc_finalize(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_tipo_utente_prc_finalize(
    bigint, bigint, bigint, character varying
)
IS 'Finalizza il flusso DWH_ANAG_TIPO_UTENTE e aggiorna le statistiche.';
