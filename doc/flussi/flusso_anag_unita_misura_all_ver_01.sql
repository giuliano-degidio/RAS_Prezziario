/* =====================================================================
   FLUSSO ANAG_UNITA_MISURA
   Target tecnico: PostgreSQL 15+
   Pattern di riferimento: flusso_anag_informatori_all_ver_01.sql
   Sorgente operazionale: public.unita_misura
   Schema target: hcbi_ras
   Business key: cd_unita_misura (sorgente: codice)

   Mapping:
     codice              -> cd_unita_misura
     descrizione         -> ds_unita_misura
     decimali            -> nr_decimali
     id                  -> id_sorgente_unita_misura
     last_update         -> dt_last_update
     data_fine_validita  -> dt_fine_validita

   Nota: id_anag_unita_misura e' la surrogate key del DWH.
   ===================================================================== */

/* =====================================================================
   SEQUENCE DWH
   ===================================================================== */
CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_anag_unita_misura
    INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_anag_unita_misura OWNER TO hcbi_ras;
GRANT ALL ON SEQUENCE hcbi_ras.seq_dwh_anag_unita_misura TO hcbi_ras;
GRANT USAGE, SELECT ON SEQUENCE hcbi_ras.seq_dwh_anag_unita_misura TO hcbi_utility;

/* =====================================================================
   TABELLA FRONTIERA
   I campi data sono TIMESTAMP WITHOUT TIME ZONE nativi PostgreSQL.
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_anag_unita_misura
(
    codice               VARCHAR(20),
    descrizione          TEXT,
    decimali             VARCHAR(100),
    id                   VARCHAR(100),
    last_update          TIMESTAMP WITHOUT TIME ZONE,
    data_fine_validita   TIMESTAMP WITHOUT TIME ZONE
);

ALTER TABLE hcbi_ras.frontiera_anag_unita_misura OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.frontiera_anag_unita_misura FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.frontiera_anag_unita_misura TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.frontiera_anag_unita_misura TO hcbi_utility;

/* =====================================================================
   TABELLA SRC_TMP
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_anag_unita_misura
(
    codice               VARCHAR(20),
    descrizione          TEXT,
    decimali             VARCHAR(100),
    id                   VARCHAR(100),
    last_update          TIMESTAMP WITHOUT TIME ZONE,
    data_fine_validita   TIMESTAMP WITHOUT TIME ZONE
);

ALTER TABLE hcbi_ras.src_tmp_anag_unita_misura OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.src_tmp_anag_unita_misura FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.src_tmp_anag_unita_misura TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.src_tmp_anag_unita_misura TO hcbi_utility;

/* =====================================================================
   VISTA SRC_TMP: RINOMINA DEI CAMPI
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_anag_unita_misura AS
SELECT
    TRIM(s.codice::TEXT)             AS cd_unita_misura,
    TRIM(s.descrizione::TEXT)        AS ds_unita_misura,
    TRIM(s.decimali::TEXT)           AS nr_decimali,
    TRIM(s.id::TEXT)                 AS id_sorgente_unita_misura,
    TRIM(s.last_update::TEXT)        AS dt_last_update,
    TRIM(s.data_fine_validita::TEXT) AS dt_fine_validita
FROM hcbi_ras.src_tmp_anag_unita_misura AS s;

ALTER VIEW hcbi_ras.v_src_tmp_anag_unita_misura OWNER TO hcbi_ras;
GRANT ALL ON hcbi_ras.v_src_tmp_anag_unita_misura TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_src_tmp_anag_unita_misura TO hcbi_utility;

/* =====================================================================
   TABELLA STG
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_unita_misura
(
    cd_unita_misura           VARCHAR(20) NOT NULL,
    ds_unita_misura           TEXT,
    nr_decimali               NUMERIC(10,0),
    id_sorgente_unita_misura  INTEGER,
    dt_last_update            TIMESTAMP WITHOUT TIME ZONE,
    dt_fine_validita          TIMESTAMP WITHOUT TIME ZONE
);

ALTER TABLE hcbi_ras.stg_anag_unita_misura OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.stg_anag_unita_misura FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.stg_anag_unita_misura TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.stg_anag_unita_misura TO hcbi_utility;

/* =====================================================================
   TABELLA STG REJECT
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_unita_misura_rej
(
    cd_unita_misura           VARCHAR(20),
    ds_unita_misura           TEXT,
    nr_decimali               VARCHAR(100),
    id_sorgente_unita_misura  VARCHAR(100),
    dt_last_update            TIMESTAMP WITHOUT TIME ZONE,
    dt_fine_validita          TIMESTAMP WITHOUT TIME ZONE,
    tx_motivo_scarto          VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_unita_misura_rej OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.stg_anag_unita_misura_rej FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.stg_anag_unita_misura_rej TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.stg_anag_unita_misura_rej TO hcbi_utility;

/* =====================================================================
   TABELLA DWH
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_anag_unita_misura
(
    id_anag_unita_misura      BIGINT NOT NULL DEFAULT nextval('hcbi_ras.seq_dwh_anag_unita_misura'::REGCLASS),
    cd_unita_misura           VARCHAR(20) NOT NULL,
    ds_unita_misura           TEXT,
    nr_decimali               NUMERIC(10,0),
    id_sorgente_unita_misura  INTEGER,
    dt_last_update            TIMESTAMP WITHOUT TIME ZONE,
    dt_fine_validita          TIMESTAMP WITHOUT TIME ZONE,
    dt_creation               TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by            VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update                 TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_update_by              VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_reciclo                TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT pk_dwh_anag_unita_misura PRIMARY KEY (id_anag_unita_misura),
    CONSTRAINT uq_dwh_anag_unita_misura UNIQUE NULLS NOT DISTINCT (cd_unita_misura)
);

ALTER TABLE hcbi_ras.dwh_anag_unita_misura OWNER TO hcbi_ras;
GRANT ALL ON TABLE hcbi_ras.dwh_anag_unita_misura TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE hcbi_ras.dwh_anag_unita_misura TO hcbi_utility;

/* =====================================================================
   VISTA DWH
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_dwh_anag_unita_misura AS
SELECT
    s.cd_unita_misura,
    s.ds_unita_misura,
    s.nr_decimali,
    s.id_sorgente_unita_misura,
    s.dt_last_update,
    s.dt_fine_validita
FROM hcbi_ras.stg_anag_unita_misura AS s;

ALTER VIEW hcbi_ras.v_dwh_anag_unita_misura OWNER TO hcbi_ras;
GRANT ALL ON hcbi_ras.v_dwh_anag_unita_misura TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_dwh_anag_unita_misura TO hcbi_utility;

/* =====================================================================
   FUNZIONI DI CONVERSIONE SICURA SPECIFICHE DEL FLUSSO
   ===================================================================== */
CREATE OR REPLACE FUNCTION hcbi_ras.try_anag_um_integer(p_value TEXT)
RETURNS INTEGER LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE
RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog AS $function$
BEGIN
    RETURN p_value::INTEGER;
EXCEPTION
    WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION hcbi_ras.try_anag_um_numeric_10_0(p_value TEXT)
RETURNS NUMERIC(10,0) LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE
RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog AS $function$
BEGIN
    RETURN p_value::NUMERIC(10,0);
EXCEPTION
    WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION hcbi_ras.try_anag_um_timestamp(p_value TEXT)
RETURNS TIMESTAMP WITHOUT TIME ZONE LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE
RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog AS $function$
BEGIN
    RETURN p_value::TIMESTAMP WITHOUT TIME ZONE;
EXCEPTION
    WHEN invalid_datetime_format OR datetime_field_overflow THEN RETURN NULL;
END;
$function$;

/* =====================================================================
   PROCEDURA STG INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_unita_misura_prc_initialize(
    IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility AS $BODY$
DECLARE
    v_id_log BIGINT; v_selected BIGINT := 0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT; v_sql_hint TEXT;
    v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::TIMESTAMP, clock_timestamp()::TIMESTAMP, p_ds_step_name)
    INTO v_id_log;

    TRUNCATE hcbi_ras.stg_anag_unita_misura, hcbi_ras.stg_anag_unita_misura_rej;
    SELECT COUNT(*) INTO v_selected FROM hcbi_ras.v_src_tmp_anag_unita_misura;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, 0, 0, 0, 0, 'SUCCESS',
        clock_timestamp()::TIMESTAMP, p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE, v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL, v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    v_log_error := LEFT(CONCAT_WS(E'\n', 'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||COALESCE(v_sqlerrm,''), 'DETAIL='||COALESCE(v_sql_detail,''),
        'HINT='||COALESCE(v_sql_hint,''), 'CONTEXT='||COALESCE(v_sql_context,'')), 4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log, 'FAILED', v_log_error, clock_timestamp()::TIMESTAMP, p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %', SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore in pkg_stg_anag_unita_misura_prc_initialize: %', v_sqlerrm;
END;
$BODY$;

/* =====================================================================
   PROCEDURA STG MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_unita_misura_prc_main(
    IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility AS $BODY$
DECLARE
    v_id_log BIGINT; v_selected BIGINT := 0; v_inserted BIGINT := 0;
    v_rec_errors BIGINT := 0; v_sqlstate TEXT; v_sqlerrm TEXT;
    v_sql_detail TEXT; v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::TIMESTAMP, clock_timestamp()::TIMESTAMP, p_ds_step_name)
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_unita_misura_classificata;
    CREATE TABLE hcbi_ras.tmp_anag_unita_misura_classificata AS
    WITH src AS MATERIALIZED (
        SELECT
            f.cd_unita_misura AS cd_unita_misura_raw,
            f.ds_unita_misura AS ds_unita_misura_raw,
            f.nr_decimali AS nr_decimali_raw,
            f.id_sorgente_unita_misura AS id_sorgente_unita_misura_raw,
            f.dt_last_update AS dt_last_update_raw,
            f.dt_fine_validita AS dt_fine_validita_raw,
            NULLIF(BTRIM(f.cd_unita_misura::TEXT), '') AS cd_unita_misura_txt,
            NULLIF(BTRIM(f.ds_unita_misura::TEXT), '') AS ds_unita_misura_txt,
            NULLIF(BTRIM(f.nr_decimali::TEXT), '') AS nr_decimali_txt,
            NULLIF(BTRIM(f.id_sorgente_unita_misura::TEXT), '') AS id_sorgente_unita_misura_txt,
            NULLIF(BTRIM(f.dt_last_update::TEXT), '') AS dt_last_update_txt,
            NULLIF(BTRIM(f.dt_fine_validita::TEXT), '') AS dt_fine_validita_txt,
            COUNT(*) OVER (PARTITION BY NULLIF(BTRIM(f.cd_unita_misura::TEXT), '')) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_anag_unita_misura AS f
    ), cv AS MATERIALIZED (
        SELECT s.*,
            hcbi_ras.try_anag_um_numeric_10_0(nr_decimali_txt) AS nr_decimali_cv,
            hcbi_ras.try_anag_um_integer(id_sorgente_unita_misura_txt) AS id_sorgente_unita_misura_cv,
            hcbi_ras.try_anag_um_timestamp(dt_last_update_txt) AS dt_last_update_cv,
            hcbi_ras.try_anag_um_timestamp(dt_fine_validita_txt) AS dt_fine_validita_cv
        FROM src AS s
    )
    SELECT c.*,
        CASE
            WHEN cd_unita_misura_txt IS NULL THEN 'cd_unita_misura obbligatorio'
            WHEN LENGTH(cd_unita_misura_txt) > 20 THEN 'cd_unita_misura supera 20 caratteri'
            WHEN duplicate_count > 1 THEN 'Chiave duplicata: cd_unita_misura'
            WHEN nr_decimali_txt IS NOT NULL AND nr_decimali_cv IS NULL
                THEN 'nr_decimali non convertibile o fuori dominio NUMERIC(10,0)'
            WHEN id_sorgente_unita_misura_txt IS NOT NULL AND id_sorgente_unita_misura_cv IS NULL
                THEN 'id_sorgente_unita_misura non convertibile o fuori dominio INTEGER'
            WHEN dt_last_update_txt IS NOT NULL AND dt_last_update_cv IS NULL
                THEN 'dt_last_update non convertibile'
            WHEN dt_fine_validita_txt IS NOT NULL AND dt_fine_validita_cv IS NULL
                THEN 'dt_fine_validita non convertibile'
            ELSE NULL
        END::TEXT AS tx_motivo_scarto
    FROM cv AS c;

    SELECT COUNT(*) INTO v_selected FROM hcbi_ras.tmp_anag_unita_misura_classificata;

    INSERT INTO hcbi_ras.stg_anag_unita_misura (
        cd_unita_misura, ds_unita_misura, nr_decimali,
        id_sorgente_unita_misura, dt_last_update, dt_fine_validita)
    SELECT cd_unita_misura_txt, ds_unita_misura_txt, nr_decimali_cv,
        id_sorgente_unita_misura_cv, dt_last_update_cv, dt_fine_validita_cv
    FROM hcbi_ras.tmp_anag_unita_misura_classificata
    WHERE tx_motivo_scarto IS NULL;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_anag_unita_misura_rej (
        cd_unita_misura, ds_unita_misura, nr_decimali,
        id_sorgente_unita_misura, dt_last_update, dt_fine_validita, tx_motivo_scarto)
    SELECT cd_unita_misura_raw, ds_unita_misura_raw, nr_decimali_raw,
        id_sorgente_unita_misura_raw, dt_last_update_raw, dt_fine_validita_raw, tx_motivo_scarto
    FROM hcbi_ras.tmp_anag_unita_misura_classificata
    WHERE tx_motivo_scarto IS NOT NULL;
    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION 'Riconciliazione non valida: selected=%, inserted=%, rejected=%',
            v_selected, v_inserted, v_rec_errors;
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, 0, 0, v_rec_errors, 'SUCCESS',
        clock_timestamp()::TIMESTAMP, p_ds_step_name);
    DROP TABLE hcbi_ras.tmp_anag_unita_misura_classificata;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE, v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL, v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_anag_unita_misura_classificata;
    EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: %', SQLERRM; END;
    v_log_error := LEFT(CONCAT_WS(E'\n', 'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||COALESCE(v_sqlerrm,''), 'DETAIL='||COALESCE(v_sql_detail,''),
        'HINT='||COALESCE(v_sql_hint,''), 'CONTEXT='||COALESCE(v_sql_context,'')), 4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log, 'FAILED', v_log_error, clock_timestamp()::TIMESTAMP, p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %', SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore in pkg_stg_anag_unita_misura_prc_main: %', v_sqlerrm;
END;
$BODY$;

/* =====================================================================
   PROCEDURA STG FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_unita_misura_prc_finalize(
    IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility AS $BODY$
DECLARE
    v_id_log BIGINT; v_sqlerrm TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::TIMESTAMP, clock_timestamp()::TIMESTAMP, p_ds_step_name)
    INTO v_id_log;
    ANALYZE hcbi_ras.stg_anag_unita_misura;
    ANALYZE hcbi_ras.stg_anag_unita_misura_rej;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS', clock_timestamp()::TIMESTAMP, p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    v_sqlerrm := SQLERRM; p_result := -1; v_log_error := LEFT(v_sqlerrm, 4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log, 'FAILED', v_log_error, clock_timestamp()::TIMESTAMP, p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %', SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore in pkg_stg_anag_unita_misura_prc_finalize: %', v_sqlerrm;
END;
$BODY$;

/* =====================================================================
   PROCEDURA DWH INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_unita_misura_prc_initialize(
    IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility AS $BODY$
DECLARE
    v_id_log BIGINT; v_sqlerrm TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::TIMESTAMP, clock_timestamp()::TIMESTAMP, p_ds_step_name)
    INTO v_id_log;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS', clock_timestamp()::TIMESTAMP, p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    v_sqlerrm := SQLERRM; p_result := -1; v_log_error := LEFT(v_sqlerrm, 4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log, 'FAILED', v_log_error, clock_timestamp()::TIMESTAMP, p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %', SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore in pkg_dwh_anag_unita_misura_prc_initialize: %', v_sqlerrm;
END;
$BODY$;

/* =====================================================================
   PROCEDURA DWH MAIN
   Caricamento Type 1: update dei record variati e insert dei nuovi.
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_unita_misura_prc_main(
    IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility AS $BODY$
DECLARE
    v_id_log BIGINT; v_selected BIGINT := 0; v_inserted BIGINT := 0;
    v_updated BIGINT := 0; v_sqlstate TEXT; v_sqlerrm TEXT;
    v_sql_detail TEXT; v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::TIMESTAMP, clock_timestamp()::TIMESTAMP, p_ds_step_name)
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_unita_misura;
    CREATE TABLE hcbi_ras.tmp_dwh_anag_unita_misura AS
    SELECT cd_unita_misura, ds_unita_misura, nr_decimali,
        id_sorgente_unita_misura, dt_last_update, dt_fine_validita
    FROM hcbi_ras.v_dwh_anag_unita_misura;

    CREATE UNIQUE INDEX tmp_dwh_anag_unita_misura_uq
        ON hcbi_ras.tmp_dwh_anag_unita_misura (cd_unita_misura) NULLS NOT DISTINCT;

    SELECT COUNT(*) INTO v_selected FROM hcbi_ras.tmp_dwh_anag_unita_misura;

    UPDATE hcbi_ras.dwh_anag_unita_misura AS d
    SET ds_unita_misura = src.ds_unita_misura,
        nr_decimali = src.nr_decimali,
        id_sorgente_unita_misura = src.id_sorgente_unita_misura,
        dt_last_update = src.dt_last_update,
        dt_fine_validita = src.dt_fine_validita,
        dt_update = clock_timestamp(),
        tx_update_by = p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_unita_misura AS src
    WHERE d.cd_unita_misura = src.cd_unita_misura
      AND (d.ds_unita_misura IS DISTINCT FROM src.ds_unita_misura
        OR d.nr_decimali IS DISTINCT FROM src.nr_decimali
        OR d.id_sorgente_unita_misura IS DISTINCT FROM src.id_sorgente_unita_misura
        OR d.dt_last_update IS DISTINCT FROM src.dt_last_update
        OR d.dt_fine_validita IS DISTINCT FROM src.dt_fine_validita);
    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_anag_unita_misura (
        cd_unita_misura, ds_unita_misura, nr_decimali,
        id_sorgente_unita_misura, dt_last_update, dt_fine_validita,
        dt_creation, tx_creation_by, dt_update, tx_update_by)
    SELECT src.cd_unita_misura, src.ds_unita_misura, src.nr_decimali,
        src.id_sorgente_unita_misura, src.dt_last_update, src.dt_fine_validita,
        clock_timestamp(), p_ds_step_name, clock_timestamp(), p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_unita_misura AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_anag_unita_misura DO NOTHING;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, v_updated, 0, 0, 'SUCCESS',
        clock_timestamp()::TIMESTAMP, p_ds_step_name);
    DROP TABLE hcbi_ras.tmp_dwh_anag_unita_misura;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE, v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL, v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_unita_misura;
    EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: %', SQLERRM; END;
    v_log_error := LEFT(CONCAT_WS(E'\n', 'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||COALESCE(v_sqlerrm,''), 'DETAIL='||COALESCE(v_sql_detail,''),
        'HINT='||COALESCE(v_sql_hint,''), 'CONTEXT='||COALESCE(v_sql_context,'')), 4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log, 'FAILED', v_log_error, clock_timestamp()::TIMESTAMP, p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %', SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore in pkg_dwh_anag_unita_misura_prc_main: %', v_sqlerrm;
END;
$BODY$;

/* =====================================================================
   PROCEDURA DWH FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_unita_misura_prc_finalize(
    IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility AS $BODY$
DECLARE
    v_id_log BIGINT; v_sqlerrm TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::TIMESTAMP, clock_timestamp()::TIMESTAMP, p_ds_step_name)
    INTO v_id_log;
    ANALYZE hcbi_ras.dwh_anag_unita_misura;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS', clock_timestamp()::TIMESTAMP, p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    v_sqlerrm := SQLERRM; p_result := -1; v_log_error := LEFT(v_sqlerrm, 4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log, 'FAILED', v_log_error, clock_timestamp()::TIMESTAMP, p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %', SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore in pkg_dwh_anag_unita_misura_prc_finalize: %', v_sqlerrm;
END;
$BODY$;

/* =====================================================================
   OWNER E GRANT PROCEDURE
   ===================================================================== */
ALTER PROCEDURE hcbi_ras.pkg_stg_anag_unita_misura_prc_initialize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_stg_anag_unita_misura_prc_main(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_stg_anag_unita_misura_prc_finalize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_unita_misura_prc_initialize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_unita_misura_prc_main(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_unita_misura_prc_finalize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_unita_misura_prc_initialize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC, hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_unita_misura_prc_main(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC, hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_unita_misura_prc_finalize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC, hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_anag_unita_misura_prc_initialize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC, hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_anag_unita_misura_prc_main(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC, hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_anag_unita_misura_prc_finalize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   COMMENTI
   ===================================================================== */
COMMENT ON TABLE hcbi_ras.frontiera_anag_unita_misura IS 'Frontiera del flusso ANAG_UNITA_MISURA';
COMMENT ON TABLE hcbi_ras.src_tmp_anag_unita_misura IS 'Tabella temporanea sorgente del flusso ANAG_UNITA_MISURA';
COMMENT ON TABLE hcbi_ras.stg_anag_unita_misura IS 'Staging del flusso ANAG_UNITA_MISURA';
COMMENT ON TABLE hcbi_ras.stg_anag_unita_misura_rej IS 'Record scartati del flusso ANAG_UNITA_MISURA';
COMMENT ON TABLE hcbi_ras.dwh_anag_unita_misura IS 'DWH del flusso ANAG_UNITA_MISURA';
COMMENT ON VIEW hcbi_ras.v_src_tmp_anag_unita_misura IS 'Vista di rinomina della sorgente temporanea ANAG_UNITA_MISURA';
COMMENT ON VIEW hcbi_ras.v_dwh_anag_unita_misura IS 'Vista di raccordo tra STG e DWH per ANAG_UNITA_MISURA';
COMMENT ON CONSTRAINT uq_dwh_anag_unita_misura ON hcbi_ras.dwh_anag_unita_misura IS 'Business key: cd_unita_misura.';

/* =====================================================================
   QUERY DI CARICAMENTO DELLA FRONTIERA DALLA SORGENTE OPERAZIONALE
   Eseguire nel contesto in cui public.unita_misura e hcbi_ras siano
   raggiungibili nella stessa istanza/database. Se l'estrazione avviene
   tramite connettore esterno, usare questo SELECT come mapping sorgente.
   =====================================================================

TRUNCATE TABLE hcbi_ras.frontiera_anag_unita_misura;

INSERT INTO hcbi_ras.frontiera_anag_unita_misura
    (codice, descrizione, decimali, id, last_update, data_fine_validita)
SELECT
    u.codice,
    u.descrizione,
    u.decimali::TEXT,
    u.id::TEXT,
    u.last_update,
    u.data_fine_validita
FROM public.unita_misura AS u;

*/
