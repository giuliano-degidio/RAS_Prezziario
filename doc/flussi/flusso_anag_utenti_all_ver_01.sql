/* =====================================================================
   FLUSSO ANAG_UTENTI - VERSIONE UNIFORMATA

   Target tecnico: PostgreSQL 15.9 / 17
   Pattern tecnico: PUBBLICAZIONE_ANALISI definitivo
   Sorgente operazionale:
       public."user"

   Mapping:
       user_id      -> id_sorgente_utente
       username     -> cd_username
       email        -> ds_email
       display_name -> ds_nome_visualizzato
       state        -> cd_stato
       usertype     -> cd_tipo_utente

   Chiave logica STG/DWH:
       cd_username
   ===================================================================== */


/* =====================================================================
   SEQUENCE DWH
   ===================================================================== */

CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_anag_utenti
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_anag_utenti
    OWNER TO hcbi_ras;

GRANT ALL
ON SEQUENCE hcbi_ras.seq_dwh_anag_utenti
TO hcbi_ras;

GRANT USAGE, SELECT
ON SEQUENCE hcbi_ras.seq_dwh_anag_utenti
TO hcbi_utility;


/* =====================================================================
   TABELLA FRONTIERA
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_anag_utenti
(
    user_id      VARCHAR(100),
    username     VARCHAR(255),
    email        VARCHAR(255),
    display_name VARCHAR(50),
    state        VARCHAR(20),
    usertype     VARCHAR(25)
);

ALTER TABLE hcbi_ras.frontiera_anag_utenti
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.frontiera_anag_utenti
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.frontiera_anag_utenti
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.frontiera_anag_utenti
TO hcbi_utility;


/* =====================================================================
   TABELLA SRC_TMP
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_anag_utenti
(
    user_id      VARCHAR(100),
    username     VARCHAR(255),
    email        VARCHAR(255),
    display_name VARCHAR(50),
    state        VARCHAR(20),
    usertype     VARCHAR(25)
);

ALTER TABLE hcbi_ras.src_tmp_anag_utenti
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.src_tmp_anag_utenti
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.src_tmp_anag_utenti
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.src_tmp_anag_utenti
TO hcbi_utility;


/* =====================================================================
   VISTA SRC_TMP
   ===================================================================== */

CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_anag_utenti
AS
SELECT
    TRIM(BOTH FROM s.user_id::TEXT)
        AS id_sorgente_utente,

    TRIM(BOTH FROM s.username::TEXT)
        AS cd_username,

    TRIM(BOTH FROM s.email::TEXT)
        AS ds_email,

    TRIM(BOTH FROM s.display_name::TEXT)
        AS ds_nome_visualizzato,

    TRIM(BOTH FROM s.state::TEXT)
        AS cd_stato,

    TRIM(BOTH FROM s.usertype::TEXT)
        AS cd_tipo_utente

FROM hcbi_ras.src_tmp_anag_utenti AS s;

ALTER VIEW hcbi_ras.v_src_tmp_anag_utenti
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_src_tmp_anag_utenti
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_src_tmp_anag_utenti
TO hcbi_utility;


/* =====================================================================
   TABELLA STG
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_utenti
(
    id_sorgente_utente    BIGINT,
    cd_username           VARCHAR(255) NOT NULL,
    ds_email              VARCHAR(255),
    ds_nome_visualizzato  VARCHAR(50),
    cd_stato              SMALLINT,
    cd_tipo_utente        VARCHAR(25)
);

ALTER TABLE hcbi_ras.stg_anag_utenti
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.stg_anag_utenti
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.stg_anag_utenti
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_utenti
TO hcbi_utility;


/* =====================================================================
   TABELLA STG REJECT
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_utenti_rej
(
    id_sorgente_utente    VARCHAR(100),
    cd_username           VARCHAR(255),
    ds_email              VARCHAR(255),
    ds_nome_visualizzato  VARCHAR(50),
    cd_stato              VARCHAR(20),
    cd_tipo_utente        VARCHAR(25),
    tx_motivo_scarto      VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_utenti_rej
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.stg_anag_utenti_rej
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.stg_anag_utenti_rej
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_utenti_rej
TO hcbi_utility;


/* =====================================================================
   TABELLA DWH
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_anag_utenti
(
    id_anag_utente BIGINT NOT NULL
        DEFAULT nextval(
            'hcbi_ras.seq_dwh_anag_utenti'::REGCLASS
        ),

    id_sorgente_utente    BIGINT,
    cd_username           VARCHAR(255) NOT NULL,
    ds_email              VARCHAR(255),
    ds_nome_visualizzato  VARCHAR(50),
    cd_stato              SMALLINT,
    cd_tipo_utente        VARCHAR(25),

    dt_creation           TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT clock_timestamp(),

    tx_creation_by        VARCHAR(4000)
        NOT NULL DEFAULT CURRENT_USER,

    dt_update             TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT clock_timestamp(),

    tx_update_by          VARCHAR(4000)
        NOT NULL DEFAULT CURRENT_USER,

    dt_reciclo            TIMESTAMP WITHOUT TIME ZONE,

    CONSTRAINT pk_dwh_anag_utenti
        PRIMARY KEY (id_anag_utente),

    CONSTRAINT uq_dwh_anag_utenti
        UNIQUE NULLS NOT DISTINCT (cd_username)
);

ALTER TABLE hcbi_ras.dwh_anag_utenti
    OWNER TO hcbi_ras;

GRANT ALL
ON TABLE hcbi_ras.dwh_anag_utenti
TO hcbi_ras;

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE hcbi_ras.dwh_anag_utenti
TO hcbi_utility;


/* =====================================================================
   VISTA DWH
   ===================================================================== */

CREATE OR REPLACE VIEW hcbi_ras.v_dwh_anag_utenti
AS
SELECT
    s.id_sorgente_utente,
    s.cd_username,
    s.ds_email,
    s.ds_nome_visualizzato,
    s.cd_stato,
    s.cd_tipo_utente
FROM hcbi_ras.stg_anag_utenti AS s;

ALTER VIEW hcbi_ras.v_dwh_anag_utenti
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_dwh_anag_utenti
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_dwh_anag_utenti
TO hcbi_utility;


/* =====================================================================
   FUNZIONI DI CONVERSIONE SICURA
   ===================================================================== */
CREATE OR REPLACE FUNCTION hcbi_ras.try_bigint(p_value text)
RETURNS bigint
LANGUAGE plpgsql
IMMUTABLE
PARALLEL UNSAFE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
SET search_path TO pg_catalog
AS $function$
BEGIN
    RETURN p_value::bigint;
EXCEPTION
    WHEN invalid_text_representation OR numeric_value_out_of_range THEN
        RETURN NULL;
END;
$function$;

ALTER FUNCTION hcbi_ras.try_bigint(text) OWNER TO hcbi_ras;

CREATE OR REPLACE FUNCTION hcbi_ras.try_smallint(p_value text)
RETURNS smallint
LANGUAGE plpgsql
IMMUTABLE
PARALLEL UNSAFE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
SET search_path TO pg_catalog
AS $function$
BEGIN
    RETURN p_value::smallint;
EXCEPTION
    WHEN invalid_text_representation OR numeric_value_out_of_range THEN
        RETURN NULL;
END;
$function$;

ALTER FUNCTION hcbi_ras.try_smallint(text) OWNER TO hcbi_ras;

/* =====================================================================
   PROCEDURA STG INITIALIZE
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_initialize(
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

    TRUNCATE TABLE hcbi_ras.stg_anag_utenti;
    TRUNCATE TABLE hcbi_ras.stg_anag_utenti_rej;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.v_src_tmp_anag_utenti;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, v_updated, v_deleted,
        v_rec_errors, 'SUCCESS', clock_timestamp()::timestamp,
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
            'Errore in pkg_stg_anag_utenti_prc_initialize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_initialize(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_initialize(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_initialize(
    bigint, bigint, bigint, character varying
)
IS 'Inizializza STG e REJ del flusso ANAG_UTENTI e registra il numero di record sorgente.';

/* =====================================================================
   PROCEDURA STG MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_main(
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_utenti_classificata;

    CREATE TABLE hcbi_ras.tmp_anag_utenti_classificata AS
    WITH src AS MATERIALIZED (
        SELECT
            f.id_sorgente_utente AS id_sorgente_utente_raw,
            f.cd_username AS cd_username_raw,
            f.ds_email AS ds_email_raw,
            f.ds_nome_visualizzato AS ds_nome_visualizzato_raw,
            f.cd_stato AS cd_stato_raw,
            f.cd_tipo_utente AS cd_tipo_utente_raw,
            nullif(btrim(f.id_sorgente_utente), '') AS id_sorgente_utente_txt,
            nullif(btrim(f.cd_username), '') AS cd_username_txt,
            nullif(btrim(f.ds_email), '') AS ds_email_txt,
            nullif(btrim(f.ds_nome_visualizzato), '') AS ds_nome_visualizzato_txt,
            nullif(btrim(f.cd_stato), '') AS cd_stato_txt,
            nullif(btrim(f.cd_tipo_utente), '') AS cd_tipo_utente_txt,
            count(*) OVER (
                PARTITION BY nullif(btrim(f.cd_username), '')
            ) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_anag_utenti AS f
    ), converted AS MATERIALIZED (
        SELECT
            s.*,
            hcbi_ras.try_bigint(s.id_sorgente_utente_txt) AS id_sorgente_utente_cv,
            hcbi_ras.try_smallint(s.cd_stato_txt) AS cd_stato_cv
        FROM src AS s
    )
    SELECT
        c.*,
        CASE
            WHEN c.cd_username_txt IS NULL THEN
                'cd_username obbligatorio'
            WHEN c.duplicate_count > 1 THEN
                'Chiave duplicata nella sorgente: (cd_username)'
            WHEN length(c.cd_username_txt) > 255 THEN
                'cd_username eccede 255 caratteri'
            WHEN c.id_sorgente_utente_txt IS NOT NULL
             AND c.id_sorgente_utente_cv IS NULL THEN
                'id_sorgente_utente non convertibile in bigint o fuori dominio'
            WHEN c.ds_email_txt IS NOT NULL
             AND length(c.ds_email_txt) > 255 THEN
                'ds_email eccede 255 caratteri'
            WHEN c.ds_nome_visualizzato_txt IS NOT NULL
             AND length(c.ds_nome_visualizzato_txt) > 50 THEN
                'ds_nome_visualizzato eccede 50 caratteri'
            WHEN c.cd_stato_txt IS NOT NULL
             AND c.cd_stato_cv IS NULL THEN
                'cd_stato non convertibile in smallint o fuori dominio'
            WHEN c.cd_tipo_utente_txt IS NOT NULL
             AND length(c.cd_tipo_utente_txt) > 25 THEN
                'cd_tipo_utente eccede 25 caratteri'
            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM converted AS c;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_anag_utenti_classificata;

    INSERT INTO hcbi_ras.stg_anag_utenti (
        id_sorgente_utente,
        cd_username,
        ds_email,
        ds_nome_visualizzato,
        cd_stato,
        cd_tipo_utente
    )
    SELECT
        c.id_sorgente_utente_cv,
        c.cd_username_txt,
        c.ds_email_txt,
        c.ds_nome_visualizzato_txt,
        c.cd_stato_cv,
        c.cd_tipo_utente_txt
    FROM hcbi_ras.tmp_anag_utenti_classificata AS c
    WHERE c.tx_motivo_scarto IS NULL;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_anag_utenti_rej (
        id_sorgente_utente,
        cd_username,
        ds_email,
        ds_nome_visualizzato,
        cd_stato,
        cd_tipo_utente,
        tx_motivo_scarto
    )
    SELECT
        c.id_sorgente_utente_raw,
        c.cd_username_raw,
        c.ds_email_raw,
        c.ds_nome_visualizzato_raw,
        c.cd_stato_raw,
        c.cd_tipo_utente_raw,
        c.tx_motivo_scarto
    FROM hcbi_ras.tmp_anag_utenti_classificata AS c
    WHERE c.tx_motivo_scarto IS NOT NULL;

    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = format(
                    'Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',
                    v_selected, v_inserted, v_rec_errors
                );
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, v_updated, v_deleted,
        v_rec_errors, 'SUCCESS', clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_utenti_classificata;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_anag_utenti_classificata;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante il cleanup: SQLSTATE=%, errore=%',
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
            'Errore in pkg_stg_anag_utenti_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_main(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_main(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_main(
    bigint, bigint, bigint, character varying
)
IS 'Classifica e carica ANAG_UTENTI in modalita set-based, gestisce conversioni, duplicati, scarti e riconciliazione.';

/* =====================================================================
   PROCEDURA STG FINALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_finalize(
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
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Finalizzazione PKG_STG_ANAG_UTENTI per lo step %',
        p_ds_step_name;

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

    ANALYZE hcbi_ras.stg_anag_utenti;
    ANALYZE hcbi_ras.stg_anag_utenti_rej;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        0,
        0,
        0,
        0,
        0,
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
            'Errore in pkg_stg_anag_utenti_prc_finalize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA DWH INITIALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_initialize(
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
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Inizializzazione PKG_DWH_ANAG_UTENTI per lo step %',
        p_ds_step_name;

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
        0,
        0,
        0,
        0,
        0,
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
            'Errore in pkg_dwh_anag_utenti_prc_initialize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA DWH MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_main(
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_utenti;

    CREATE TABLE hcbi_ras.tmp_dwh_anag_utenti AS
    SELECT
        id_sorgente_utente,
        cd_username,
        ds_email,
        ds_nome_visualizzato,
        cd_stato,
        cd_tipo_utente
    FROM hcbi_ras.v_dwh_anag_utenti;

    CREATE UNIQUE INDEX tmp_dwh_anag_utenti_uq
    ON hcbi_ras.tmp_dwh_anag_utenti (cd_username)
    NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dwh_anag_utenti;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dwh_anag_utenti;

    UPDATE hcbi_ras.dwh_anag_utenti AS dwh
       SET id_sorgente_utente = src.id_sorgente_utente,
           ds_email = src.ds_email,
           ds_nome_visualizzato = src.ds_nome_visualizzato,
           cd_stato = src.cd_stato,
           cd_tipo_utente = src.cd_tipo_utente,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dwh_anag_utenti AS src
     WHERE dwh.cd_username = src.cd_username
       AND ROW(
            dwh.id_sorgente_utente,
            dwh.ds_email,
            dwh.ds_nome_visualizzato,
            dwh.cd_stato,
            dwh.cd_tipo_utente
       ) IS DISTINCT FROM ROW(
            src.id_sorgente_utente,
            src.ds_email,
            src.ds_nome_visualizzato,
            src.cd_stato,
            src.cd_tipo_utente
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_anag_utenti (
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
    FROM hcbi_ras.tmp_dwh_anag_utenti AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_anag_utenti
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, v_updated, v_deleted,
        v_rec_errors, 'SUCCESS', clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_utenti;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_utenti;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante il cleanup: SQLSTATE=%, errore=%',
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
            'Errore in pkg_dwh_anag_utenti_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_main(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_main(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_main(
    bigint, bigint, bigint, character varying
)
IS 'Materializza la sorgente DWH, aggiorna gli attributi variati, inserisce i nuovi utenti e pulisce la tabella di lavoro.';

/* =====================================================================
   PROCEDURA DWH FINALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_finalize(
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
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Finalizzazione PKG_DWH_ANAG_UTENTI per lo step %',
        p_ds_step_name;

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

    ANALYZE hcbi_ras.dwh_anag_utenti;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        0,
        0,
        0,
        0,
        0,
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
            'Errore in pkg_dwh_anag_utenti_prc_finalize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   COMMENTI
   ===================================================================== */

COMMENT ON TABLE hcbi_ras.frontiera_anag_utenti
IS 'Frontiera del flusso ANAG_UTENTI';

COMMENT ON TABLE hcbi_ras.src_tmp_anag_utenti
IS 'Tabella temporanea sorgente del flusso ANAG_UTENTI';

COMMENT ON TABLE hcbi_ras.stg_anag_utenti
IS 'Staging del flusso ANAG_UTENTI';

COMMENT ON TABLE hcbi_ras.stg_anag_utenti_rej
IS 'Record scartati del flusso ANAG_UTENTI';

COMMENT ON TABLE hcbi_ras.dwh_anag_utenti
IS 'DWH del flusso ANAG_UTENTI';

COMMENT ON VIEW hcbi_ras.v_src_tmp_anag_utenti
IS 'Vista di conversione della sorgente temporanea ANAG_UTENTI';

COMMENT ON VIEW hcbi_ras.v_dwh_anag_utenti
IS 'Vista di raccordo tra STG_ANAG_UTENTI e DWH_ANAG_UTENTI';

COMMENT ON COLUMN hcbi_ras.stg_anag_utenti.id_sorgente_utente
IS 'Identificativo dell''utente nella sorgente operazionale';

COMMENT ON COLUMN hcbi_ras.stg_anag_utenti.cd_username
IS 'Username dell''utente';

COMMENT ON COLUMN hcbi_ras.stg_anag_utenti.ds_email
IS 'Indirizzo email dell''utente';

COMMENT ON COLUMN hcbi_ras.stg_anag_utenti.ds_nome_visualizzato
IS 'Nome visualizzato dell''utente';

COMMENT ON COLUMN hcbi_ras.stg_anag_utenti.cd_stato
IS 'Stato dell''utente';

COMMENT ON COLUMN hcbi_ras.stg_anag_utenti.cd_tipo_utente
IS 'Tipologia dell''utente';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Inizializza le tabelle STG_ANAG_UTENTI e STG_ANAG_UTENTI_REJ, gestisce i duplicati e registra l''esecuzione nel log.';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_main(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Converte e carica i dati nella tabella STG_ANAG_UTENTI registrando gli scarti nella tabella REJ.';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_utenti_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Finalizza il caricamento STG_ANAG_UTENTI e aggiorna le statistiche.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Inizializza il flusso DWH_ANAG_UTENTI e registra l''esecuzione nel log.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_main(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Carica DWH_ANAG_UTENTI dalla tabella STG aggiornando i record esistenti e inserendo i nuovi.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Finalizza il flusso DWH_ANAG_UTENTI e aggiorna le statistiche.';
COMMENT ON CONSTRAINT uq_dwh_anag_utenti
ON hcbi_ras.dwh_anag_utenti
IS 'Business key del flusso ANAG_UTENTI: cd_username.';
