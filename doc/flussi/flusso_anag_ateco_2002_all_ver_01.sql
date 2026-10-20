/* =====================================================================
   FLUSSO ANAG_ATECO_2002 - VERSIONE UNIFORMATA

   Target tecnico:
       PostgreSQL 15.9 / 17

   Pattern tecnico:
       PUBBLICAZIONE_ANALISI definitivo

   Sorgente operazionale:
       hcbi_ras.frontiera_anag_ateco_2002
   Mapping:
       cd_ateco_2002 -> cd_ateco_2002
       ds_ateco_2002 -> ds_ateco_2002
   Business key:
       cd_ateco_2002
   Regola di obbligatorieta:
       codice e descrizione sono obbligatori.
   Vincolo operativo:
       le tabelle di lavoro hanno nome fisso; non e' ammessa
       l'esecuzione concorrente dello stesso flusso.
   ===================================================================== */

/* =====================================================================
   SEQUENCE DWH
   ===================================================================== */
CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_anag_ateco_2002
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_anag_ateco_2002
    OWNER TO hcbi_ras;

GRANT ALL
ON SEQUENCE hcbi_ras.seq_dwh_anag_ateco_2002
TO hcbi_ras;

GRANT USAGE, SELECT
ON SEQUENCE hcbi_ras.seq_dwh_anag_ateco_2002
TO hcbi_utility;

/* =====================================================================
   TABELLA FRONTIERA
   Oggetto gia' creato dall'utente: ownership e privilegi.
   ===================================================================== */
ALTER TABLE hcbi_ras.frontiera_anag_ateco_2002 OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.frontiera_anag_ateco_2002 FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.frontiera_anag_ateco_2002 TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.frontiera_anag_ateco_2002 TO hcbi_utility;
/* =====================================================================
   TABELLA SRC_TMP
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_anag_ateco_2002
(
    cd_ateco_2002 character varying(200),
    ds_ateco_2002 character varying(512)
);

ALTER TABLE hcbi_ras.src_tmp_anag_ateco_2002
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.src_tmp_anag_ateco_2002
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.src_tmp_anag_ateco_2002
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.src_tmp_anag_ateco_2002
TO hcbi_utility;

/* =====================================================================
   VISTA SRC_TMP
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_anag_ateco_2002 AS
SELECT
    btrim(s.cd_ateco_2002::text) AS cd_ateco_2002,
    btrim(s.ds_ateco_2002::text) AS ds_ateco_2002
FROM hcbi_ras.src_tmp_anag_ateco_2002 AS s;

ALTER VIEW hcbi_ras.v_src_tmp_anag_ateco_2002
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_src_tmp_anag_ateco_2002
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_src_tmp_anag_ateco_2002
TO hcbi_utility;

/* =====================================================================
   TABELLA STG
   Solo la business key DS_NOME e' NOT NULL.
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_ateco_2002
(
    cd_ateco_2002 character varying(200) NOT NULL,
    ds_ateco_2002 character varying(512) NOT NULL
);

ALTER TABLE hcbi_ras.stg_anag_ateco_2002
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.stg_anag_ateco_2002
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.stg_anag_ateco_2002
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_ateco_2002
TO hcbi_utility;

/* =====================================================================
   TABELLA STG REJECT
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_ateco_2002_rej
(
    cd_ateco_2002 character varying(200),
    ds_ateco_2002 character varying(512),
    tx_motivo_scarto character varying(4000)
);

ALTER TABLE hcbi_ras.stg_anag_ateco_2002_rej
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.stg_anag_ateco_2002_rej
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.stg_anag_ateco_2002_rej
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_ateco_2002_rej
TO hcbi_utility;

/* =====================================================================
   TABELLA DWH
   Solo la business key DS_NOME e' NOT NULL tra gli attributi funzionali.
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_anag_ateco_2002
(
    id_anag_ateco_2002 bigint NOT NULL DEFAULT nextval('hcbi_ras.seq_dwh_anag_ateco_2002'::regclass),
    cd_ateco_2002 character varying(200) NOT NULL,
    ds_ateco_2002 character varying(512) NOT NULL,
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by character varying(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by character varying(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_reciclo timestamp without time zone,
    CONSTRAINT pk_dwh_anag_ateco_2002 PRIMARY KEY (id_anag_ateco_2002),
    CONSTRAINT uq_dwh_anag_ateco_2002 UNIQUE NULLS NOT DISTINCT (cd_ateco_2002)
);

ALTER TABLE hcbi_ras.dwh_anag_ateco_2002
    OWNER TO hcbi_ras;

GRANT ALL
ON TABLE hcbi_ras.dwh_anag_ateco_2002
TO hcbi_ras;

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE hcbi_ras.dwh_anag_ateco_2002
TO hcbi_utility;

/* =====================================================================
   VISTA DWH
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_dwh_anag_ateco_2002 AS
SELECT
    s.cd_ateco_2002,
    s.ds_ateco_2002
FROM hcbi_ras.stg_anag_ateco_2002 AS s;

ALTER VIEW hcbi_ras.v_dwh_anag_ateco_2002
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_dwh_anag_ateco_2002
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_dwh_anag_ateco_2002
TO hcbi_utility;

/* =====================================================================
   PROCEDURA STG INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_ateco_2002_prc_initialize(
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
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    TRUNCATE TABLE hcbi_ras.stg_anag_ateco_2002;
    TRUNCATE TABLE hcbi_ras.stg_anag_ateco_2002_rej;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.v_src_tmp_anag_ateco_2002;

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
                        'Errore nel logging: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_stg_anag_ateco_2002_prc_initialize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_ateco_2002_prc_initialize(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_ateco_2002_prc_initialize(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   PROCEDURA STG MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_ateco_2002_prc_main(
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
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_ateco_2002_classificata;
    CREATE TABLE hcbi_ras.tmp_anag_ateco_2002_classificata AS
    WITH src AS MATERIALIZED (
        SELECT
            f.cd_ateco_2002 AS cd_ateco_2002_raw,
            f.ds_ateco_2002 AS ds_ateco_2002_raw,
            nullif(btrim(f.cd_ateco_2002), '') AS cd_ateco_2002_txt,
            nullif(btrim(f.ds_ateco_2002), '') AS ds_ateco_2002_txt,
            count(*) OVER (
                PARTITION BY nullif(btrim(f.cd_ateco_2002), '')
            ) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_anag_ateco_2002 AS f
    )
    SELECT
        src.*,
        CASE
            WHEN src.cd_ateco_2002_txt IS NULL THEN 'cd_ateco_2002 obbligatorio'
            WHEN src.ds_ateco_2002_txt IS NULL THEN 'ds_ateco_2002 obbligatorio'
            WHEN src.duplicate_count > 1 THEN 'Chiave duplicata nella sorgente: (cd_ateco_2002)'
            WHEN length(src.cd_ateco_2002_txt) > 200 THEN 'cd_ateco_2002 eccede 200 caratteri'
            WHEN length(src.ds_ateco_2002_txt) > 512 THEN 'ds_ateco_2002 eccede 512 caratteri'
            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM src;
    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_anag_ateco_2002_classificata;

    INSERT INTO hcbi_ras.stg_anag_ateco_2002 (
        cd_ateco_2002,
        ds_ateco_2002
    )
    SELECT
        c.cd_ateco_2002_txt,
        c.ds_ateco_2002_txt
    FROM hcbi_ras.tmp_anag_ateco_2002_classificata AS c
    WHERE c.tx_motivo_scarto IS NULL;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_anag_ateco_2002_rej (
        cd_ateco_2002,
        ds_ateco_2002,
        tx_motivo_scarto
    )
    SELECT
        c.cd_ateco_2002_raw,
        c.ds_ateco_2002_raw,
        c.tx_motivo_scarto
    FROM hcbi_ras.tmp_anag_ateco_2002_classificata AS c
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
                );
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_ateco_2002_classificata;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_anag_ateco_2002_classificata;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore nel cleanup: SQLSTATE=%, errore=%',
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
                        'Errore nel logging: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_stg_anag_ateco_2002_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_ateco_2002_prc_main(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_ateco_2002_prc_main(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   PROCEDURA STG FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_ateco_2002_prc_finalize(
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

    ANALYZE hcbi_ras.stg_anag_ateco_2002;
    ANALYZE hcbi_ras.stg_anag_ateco_2002_rej;

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
            'MESSAGE=' || coalesce(v_sqlerrm, ''),
            'DETAIL=' || coalesce(v_sql_detail, ''),
            'HINT=' || coalesce(v_sql_hint, ''),
            'CONTEXT=' || coalesce(v_sql_context, '')
        ), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore nel logging: %', SQLERRM;
            END;
        END IF;
        RAISE WARNING
            'Errore in pkg_stg_anag_ateco_2002_prc_finalize: %',
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_ateco_2002_prc_finalize(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_ateco_2002_prc_finalize(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   PROCEDURA DWH INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_ateco_2002_prc_initialize(
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
            'MESSAGE=' || coalesce(v_sqlerrm, ''),
            'DETAIL=' || coalesce(v_sql_detail, ''),
            'HINT=' || coalesce(v_sql_hint, ''),
            'CONTEXT=' || coalesce(v_sql_context, '')
        ), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore nel logging: %', SQLERRM;
            END;
        END IF;
        RAISE WARNING
            'Errore in pkg_dwh_anag_ateco_2002_prc_initialize: %',
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_ateco_2002_prc_initialize(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_ateco_2002_prc_initialize(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   PROCEDURA DWH MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_ateco_2002_prc_main(
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
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_ateco_2002;

    CREATE TABLE hcbi_ras.tmp_dwh_anag_ateco_2002 AS
    SELECT
        s.cd_ateco_2002,
        s.ds_ateco_2002
    FROM hcbi_ras.v_dwh_anag_ateco_2002 AS s;

    CREATE UNIQUE INDEX tmp_dwh_anag_ateco_2002_uq
    ON hcbi_ras.tmp_dwh_anag_ateco_2002 (cd_ateco_2002)
    NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dwh_anag_ateco_2002;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dwh_anag_ateco_2002;

    UPDATE hcbi_ras.dwh_anag_ateco_2002 AS dwh
       SET ds_ateco_2002 = src.ds_ateco_2002,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dwh_anag_ateco_2002 AS src
     WHERE dwh.cd_ateco_2002 = src.cd_ateco_2002
       AND dwh.ds_ateco_2002 IS DISTINCT FROM src.ds_ateco_2002;
    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_anag_ateco_2002 (
        cd_ateco_2002,
        ds_ateco_2002,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.cd_ateco_2002,
        src.ds_ateco_2002,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_ateco_2002 AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_anag_ateco_2002
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_ateco_2002;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_ateco_2002;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore nel cleanup: SQLSTATE=%, errore=%',
                    SQLSTATE,
                    SQLERRM;
        END;

        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || coalesce(v_sqlerrm, ''),
            'DETAIL=' || coalesce(v_sql_detail, ''),
            'HINT=' || coalesce(v_sql_hint, ''),
            'CONTEXT=' || coalesce(v_sql_context, '')
        ), 4000);

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore nel logging: %', SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dwh_anag_ateco_2002_prc_main: %',
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_ateco_2002_prc_main(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_ateco_2002_prc_main(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   PROCEDURA DWH FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_ateco_2002_prc_finalize(
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

    ANALYZE hcbi_ras.dwh_anag_ateco_2002;

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
            'MESSAGE=' || coalesce(v_sqlerrm, ''),
            'DETAIL=' || coalesce(v_sql_detail, ''),
            'HINT=' || coalesce(v_sql_hint, ''),
            'CONTEXT=' || coalesce(v_sql_context, '')
        ), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore nel logging: %', SQLERRM;
            END;
        END IF;
        RAISE WARNING
            'Errore in pkg_dwh_anag_ateco_2002_prc_finalize: %',
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_ateco_2002_prc_finalize(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_ateco_2002_prc_finalize(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   COMMENTI
   ===================================================================== */
COMMENT ON TABLE hcbi_ras.frontiera_anag_ateco_2002
IS 'Frontiera del flusso ANAG_ATECO_2002.';

COMMENT ON TABLE hcbi_ras.src_tmp_anag_ateco_2002
IS 'Tabella temporanea sorgente del flusso ANAG_ATECO_2002.';

COMMENT ON TABLE hcbi_ras.stg_anag_ateco_2002
IS 'Staging del flusso ANAG_ATECO_2002.';

COMMENT ON TABLE hcbi_ras.stg_anag_ateco_2002_rej
IS 'Record scartati del flusso ANAG_ATECO_2002.';

COMMENT ON TABLE hcbi_ras.dwh_anag_ateco_2002
IS 'DWH del flusso ANAG_ATECO_2002.';

COMMENT ON COLUMN hcbi_ras.stg_anag_ateco_2002.cd_ateco_2002
IS 'Codice ATECO 2002 e business key del flusso.';

COMMENT ON COLUMN hcbi_ras.stg_anag_ateco_2002.ds_ateco_2002
IS 'Nome dell''area vasta e business key del flusso.';

COMMENT ON CONSTRAINT uq_dwh_anag_ateco_2002
ON hcbi_ras.dwh_anag_ateco_2002
IS 'Business key del flusso ANAG_ATECO_2002: cd_ateco_2002.';
