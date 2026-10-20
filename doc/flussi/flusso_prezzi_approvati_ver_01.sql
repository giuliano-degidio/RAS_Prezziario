/* =====================================================================
   FLUSSO PREZZI_APPROVATI
   Target: PostgreSQL 15.9 / 17
   Sorgente operazionale: public.prezzi_approvati
   Grain DWH: una riga per (codice, anno, provincia, addendum).

   Requisiti applicati:
   - campo sorgente derivato_da escluso dall'intero flusso;
   - FK incompleta della DDL sorgente non considerata;
   - caricamento full, non storicizzato;
   - STG ricostruita a ogni esecuzione;
   - DWH riallineato tramite update dei record variati e insert dei nuovi;
   - scarti e duplicati separati nella tabella STG_REJ.

   Dipendenze applicative attese:
   - hcbi_ras.try_integer(text)
   - hcbi_ras.try_smallint(text)
   - hcbi_ras.try_numeric_24_5(text)
   - funzioni/procedure di logging nello schema hcbi_utility
   ===================================================================== */

/* ============================== SEQUENCE ============================== */
CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_prezzi_approvati
    AS bigint
    INCREMENT 1
    START 1
    MINVALUE 1
    CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_prezzi_approvati OWNER TO hcbi_ras;
GRANT ALL ON SEQUENCE hcbi_ras.seq_dwh_prezzi_approvati TO hcbi_ras;
GRANT USAGE, SELECT ON SEQUENCE hcbi_ras.seq_dwh_prezzi_approvati TO hcbi_utility;

/* ============================== FRONTIERA ============================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_prezzi_approvati (
    codice varchar(60),
    anno varchar(100),
    prezzo varchar(100),
    provincia varchar(100),
    data_approvazione timestamp without time zone,
    addendum varchar(20)
);

ALTER TABLE hcbi_ras.frontiera_prezzi_approvati OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.frontiera_prezzi_approvati FROM hcbi_utility;
GRANT ALL ON hcbi_ras.frontiera_prezzi_approvati TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.frontiera_prezzi_approvati TO hcbi_utility;

/* ============================== SRC_TMP ================================ */
CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_prezzi_approvati
(LIKE hcbi_ras.frontiera_prezzi_approvati INCLUDING DEFAULTS);

ALTER TABLE hcbi_ras.src_tmp_prezzi_approvati OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.src_tmp_prezzi_approvati FROM hcbi_utility;
GRANT ALL ON hcbi_ras.src_tmp_prezzi_approvati TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.src_tmp_prezzi_approvati TO hcbi_utility;

CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_prezzi_approvati AS
SELECT btrim(s.codice) AS cd_articolo,
       btrim(s.anno) AS ds_anno,
       btrim(s.prezzo) AS nr_prezzo,
       btrim(s.provincia) AS id_sorgente_provincia,
       s.data_approvazione AS dt_approvazione,
       btrim(s.addendum) AS cd_versione
FROM hcbi_ras.src_tmp_prezzi_approvati s;

ALTER VIEW hcbi_ras.v_src_tmp_prezzi_approvati OWNER TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_src_tmp_prezzi_approvati TO hcbi_utility;

/* ============================== STAGING ================================ */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_prezzi_approvati (
    cd_articolo varchar(60) NOT NULL,
    ds_anno integer NOT NULL,
    nr_prezzo numeric(24,5) NOT NULL,
    id_sorgente_provincia integer NOT NULL,
    dt_approvazione timestamp without time zone NOT NULL,
    cd_versione smallint NOT NULL
);

ALTER TABLE hcbi_ras.stg_prezzi_approvati OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.stg_prezzi_approvati FROM hcbi_utility;
GRANT ALL ON hcbi_ras.stg_prezzi_approvati TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.stg_prezzi_approvati TO hcbi_utility;

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_prezzi_approvati_rej (
    cd_articolo varchar(60),
    ds_anno varchar(100),
    nr_prezzo varchar(100),
    id_sorgente_provincia varchar(100),
    dt_approvazione timestamp without time zone,
    cd_versione varchar(20),
    tx_motivo_scarto varchar(4000),
    dt_scarto timestamp without time zone NOT NULL DEFAULT clock_timestamp()
);

ALTER TABLE hcbi_ras.stg_prezzi_approvati_rej OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.stg_prezzi_approvati_rej FROM hcbi_utility;
GRANT ALL ON hcbi_ras.stg_prezzi_approvati_rej TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.stg_prezzi_approvati_rej TO hcbi_utility;

/* ================================ DWH ================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_prezzi_approvati (
    id_prezzi_approvati bigint NOT NULL
        DEFAULT nextval('hcbi_ras.seq_dwh_prezzi_approvati'::regclass),
    cd_articolo varchar(60) NOT NULL,
    ds_anno integer NOT NULL,
    nr_prezzo numeric(24,5) NOT NULL,
    id_sorgente_provincia integer NOT NULL,
    dt_approvazione timestamp without time zone NOT NULL,
    cd_versione smallint NOT NULL,
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by varchar(4000) NOT NULL DEFAULT current_user,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by varchar(4000) NOT NULL DEFAULT current_user,
    dt_reciclo timestamp without time zone,
    CONSTRAINT pk_dwh_prezzi_approvati PRIMARY KEY (id_prezzi_approvati),
    CONSTRAINT uk_dwh_prezzi_approvati UNIQUE
        (cd_articolo, ds_anno, id_sorgente_provincia, cd_versione)
);

CREATE INDEX IF NOT EXISTS ix_dwh_prezzi_approvati_articolo
    ON hcbi_ras.dwh_prezzi_approvati (cd_articolo, ds_anno, cd_versione);

ALTER TABLE hcbi_ras.dwh_prezzi_approvati OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.dwh_prezzi_approvati FROM hcbi_utility;
GRANT ALL ON hcbi_ras.dwh_prezzi_approvati TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.dwh_prezzi_approvati TO hcbi_utility;

CREATE OR REPLACE VIEW hcbi_ras.v_dwh_prezzi_approvati AS
SELECT s.cd_articolo,
       s.ds_anno,
       s.nr_prezzo,
       s.id_sorgente_provincia,
       s.dt_approvazione,
       s.cd_versione
FROM hcbi_ras.stg_prezzi_approvati s;

ALTER VIEW hcbi_ras.v_dwh_prezzi_approvati OWNER TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_dwh_prezzi_approvati TO hcbi_utility;

/* ============================ STG INITIALIZE =========================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_prezzi_approvati_prc_initialize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name varchar,
    OUT p_result integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
               p_id_chain_log,
               p_id_chain,
               p_id_step,
               p_ds_step_name,
               clock_timestamp()::timestamp,
               clock_timestamp()::timestamp,
               p_ds_step_name)
      INTO v_id_log;

    TRUNCATE TABLE
        hcbi_ras.stg_prezzi_approvati,
        hcbi_ras.stg_prezzi_approvati_rej;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0,
        'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name);

    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                    clock_timestamp()::timestamp,
                    p_ds_step_name);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Errore logging: %', SQLERRM;
            END;
        END IF;

        RAISE WARNING 'Errore initialize STG PREZZI_APPROVATI: %', SQLERRM;
END;
$BODY$;

/* ============================== STG MAIN =============================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_prezzi_approvati_prc_main(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name varchar,
    OUT p_result integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
    v_selected bigint := 0;
    v_inserted bigint := 0;
    v_rejected bigint := 0;
    v_updated bigint := 0;
    v_deleted bigint := 0;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
               p_id_chain_log,
               p_id_chain,
               p_id_step,
               p_ds_step_name,
               clock_timestamp()::timestamp,
               clock_timestamp()::timestamp,
               p_ds_step_name)
      INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_prezzi_approvati_classificata;

    CREATE TABLE hcbi_ras.tmp_prezzi_approvati_classificata AS
    WITH src AS MATERIALIZED (
        SELECT f.cd_articolo,
               f.ds_anno,
               f.nr_prezzo,
               f.id_sorgente_provincia,
               f.dt_approvazione,
               f.cd_versione,
               NULLIF(btrim(f.cd_articolo), '') AS codice_txt,
               NULLIF(btrim(f.ds_anno), '') AS anno_txt,
               NULLIF(btrim(f.nr_prezzo), '') AS prezzo_txt,
               NULLIF(btrim(f.id_sorgente_provincia), '') AS provincia_txt,
               NULLIF(btrim(f.cd_versione), '') AS addendum_txt
        FROM hcbi_ras.v_src_tmp_prezzi_approvati f
    ),
    cv AS MATERIALIZED (
        SELECT s.*,
               s.codice_txt AS codice_cv,
               hcbi_ras.try_integer(s.anno_txt) AS anno_cv,
               hcbi_ras.try_numeric_24_5(replace(s.prezzo_txt, ',', '.')) AS prezzo_cv,
               hcbi_ras.try_integer(s.provincia_txt) AS provincia_cv,
               hcbi_ras.try_smallint(s.addendum_txt) AS addendum_cv
        FROM src s
    ),
    dup AS MATERIALIZED (
        SELECT c.*,
               count(*) OVER (
                   PARTITION BY c.codice_cv,
                                c.anno_cv,
                                c.provincia_cv,
                                c.addendum_cv
               ) AS duplicate_count
        FROM cv c
    )
    SELECT d.*,
           CASE
               WHEN d.codice_txt IS NULL
                   THEN 'codice obbligatorio'
               WHEN length(d.codice_txt) > 60
                   THEN 'codice eccede 60 caratteri'
               WHEN d.anno_txt IS NULL
                   THEN 'anno obbligatorio'
               WHEN d.anno_cv IS NULL
                   THEN 'anno non convertibile o fuori dominio integer'
               WHEN d.prezzo_txt IS NULL
                   THEN 'prezzo obbligatorio'
               WHEN d.prezzo_cv IS NULL
                   THEN 'prezzo non convertibile o fuori dominio numeric(24,5)'
               WHEN d.provincia_txt IS NULL
                   THEN 'provincia obbligatoria'
               WHEN d.provincia_cv IS NULL
                   THEN 'provincia non convertibile o fuori dominio integer'
               WHEN d.dt_approvazione IS NULL
                   THEN 'data_approvazione obbligatoria'
               WHEN d.addendum_txt IS NULL
                   THEN 'addendum obbligatorio'
               WHEN d.addendum_cv IS NULL
                   THEN 'addendum non convertibile o fuori dominio smallint'
               WHEN d.duplicate_count > 1
                   THEN 'Chiave duplicata: (codice, anno, provincia, addendum)'
               ELSE NULL
           END::text AS tx_motivo_scarto
    FROM dup d;

    SELECT count(*)
      INTO v_selected
      FROM hcbi_ras.tmp_prezzi_approvati_classificata;

    INSERT INTO hcbi_ras.stg_prezzi_approvati (
        cd_articolo,
        ds_anno,
        nr_prezzo,
        id_sorgente_provincia,
        dt_approvazione,
        cd_versione)
    SELECT codice_cv,
           anno_cv,
           prezzo_cv,
           provincia_cv,
           dt_approvazione,
           addendum_cv
      FROM hcbi_ras.tmp_prezzi_approvati_classificata
     WHERE tx_motivo_scarto IS NULL;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_prezzi_approvati_rej (
        cd_articolo,
        ds_anno,
        nr_prezzo,
        id_sorgente_provincia,
        dt_approvazione,
        cd_versione,
        tx_motivo_scarto)
    SELECT cd_articolo,
           ds_anno,
           nr_prezzo,
           id_sorgente_provincia,
           dt_approvazione,
           cd_versione,
           tx_motivo_scarto
      FROM hcbi_ras.tmp_prezzi_approvati_classificata
     WHERE tx_motivo_scarto IS NOT NULL;

    GET DIAGNOSTICS v_rejected = ROW_COUNT;

    IF v_selected <> v_inserted + v_rejected THEN
        RAISE EXCEPTION
            'Riconciliazione STG non valida: selected=%, inserted=%, rejected=%',
            v_selected, v_inserted, v_rejected;
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rejected,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name);

    DROP TABLE hcbi_ras.tmp_prezzi_approvati_classificata;
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;
        DROP TABLE IF EXISTS hcbi_ras.tmp_prezzi_approvati_classificata;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                    clock_timestamp()::timestamp,
                    p_ds_step_name);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Errore logging: %', SQLERRM;
            END;
        END IF;

        RAISE WARNING 'Errore main STG PREZZI_APPROVATI: %', SQLERRM;
END;
$BODY$;

/* ============================ STG FINALIZE ============================= */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_prezzi_approvati_prc_finalize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name varchar,
    OUT p_result integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
               p_id_chain_log,
               p_id_chain,
               p_id_step,
               p_ds_step_name,
               clock_timestamp()::timestamp,
               clock_timestamp()::timestamp,
               p_ds_step_name)
      INTO v_id_log;

    ANALYZE hcbi_ras.stg_prezzi_approvati;
    ANALYZE hcbi_ras.stg_prezzi_approvati_rej;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0,
        'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name);

    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                    clock_timestamp()::timestamp,
                    p_ds_step_name);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Errore logging: %', SQLERRM;
            END;
        END IF;

        RAISE WARNING 'Errore finalize STG PREZZI_APPROVATI: %', SQLERRM;
END;
$BODY$;

/* ============================= DWH INIT ================================ */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_prezzi_approvati_prc_initialize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name varchar,
    OUT p_result integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
               p_id_chain_log,
               p_id_chain,
               p_id_step,
               p_ds_step_name,
               clock_timestamp()::timestamp,
               clock_timestamp()::timestamp,
               p_ds_step_name)
      INTO v_id_log;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0,
        'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name);

    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                    clock_timestamp()::timestamp,
                    p_ds_step_name);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Errore logging: %', SQLERRM;
            END;
        END IF;

        RAISE WARNING 'Errore initialize DWH PREZZI_APPROVATI: %', SQLERRM;
END;
$BODY$;

/* ============================== DWH MAIN =============================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_prezzi_approvati_prc_main(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name varchar,
    OUT p_result integer)
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
    v_errors bigint := 0;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
               p_id_chain_log,
               p_id_chain,
               p_id_step,
               p_ds_step_name,
               clock_timestamp()::timestamp,
               clock_timestamp()::timestamp,
               p_ds_step_name)
      INTO v_id_log;

    SELECT count(*)
      INTO v_selected
      FROM hcbi_ras.v_dwh_prezzi_approvati;

    UPDATE hcbi_ras.dwh_prezzi_approvati d
       SET nr_prezzo = s.nr_prezzo,
           dt_approvazione = s.dt_approvazione,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.v_dwh_prezzi_approvati s
     WHERE d.cd_articolo = s.cd_articolo
       AND d.ds_anno = s.ds_anno
       AND d.id_sorgente_provincia = s.id_sorgente_provincia
       AND d.cd_versione = s.cd_versione
       AND ROW(d.nr_prezzo, d.dt_approvazione)
           IS DISTINCT FROM
           ROW(s.nr_prezzo, s.dt_approvazione);

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_prezzi_approvati (
        cd_articolo,
        ds_anno,
        nr_prezzo,
        id_sorgente_provincia,
        dt_approvazione,
        cd_versione,
        tx_creation_by,
        tx_update_by)
    SELECT s.cd_articolo,
           s.ds_anno,
           s.nr_prezzo,
           s.id_sorgente_provincia,
           s.dt_approvazione,
           s.cd_versione,
           p_ds_step_name,
           p_ds_step_name
      FROM hcbi_ras.v_dwh_prezzi_approvati s
    ON CONFLICT (cd_articolo, ds_anno, id_sorgente_provincia, cd_versione)
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name);

    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                    clock_timestamp()::timestamp,
                    p_ds_step_name);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Errore logging: %', SQLERRM;
            END;
        END IF;

        RAISE WARNING 'Errore main DWH PREZZI_APPROVATI: %', SQLERRM;
END;
$BODY$;

/* ============================ DWH FINALIZE ============================= */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_prezzi_approvati_prc_finalize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name varchar,
    OUT p_result integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
               p_id_chain_log,
               p_id_chain,
               p_id_step,
               p_ds_step_name,
               clock_timestamp()::timestamp,
               clock_timestamp()::timestamp,
               p_ds_step_name)
      INTO v_id_log;

    ANALYZE hcbi_ras.dwh_prezzi_approvati;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0,
        'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name);

    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                    clock_timestamp()::timestamp,
                    p_ds_step_name);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Errore logging: %', SQLERRM;
            END;
        END IF;

        RAISE WARNING 'Errore finalize DWH PREZZI_APPROVATI: %', SQLERRM;
END;
$BODY$;

/* ========================= OWNER / EXECUTE / COMMENT =================== */
ALTER PROCEDURE hcbi_ras.pkg_stg_prezzi_approvati_prc_initialize(bigint,bigint,bigint,varchar)
    OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_stg_prezzi_approvati_prc_main(bigint,bigint,bigint,varchar)
    OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_stg_prezzi_approvati_prc_finalize(bigint,bigint,bigint,varchar)
    OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dwh_prezzi_approvati_prc_initialize(bigint,bigint,bigint,varchar)
    OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dwh_prezzi_approvati_prc_main(bigint,bigint,bigint,varchar)
    OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dwh_prezzi_approvati_prc_finalize(bigint,bigint,bigint,varchar)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_prezzi_approvati_prc_initialize(bigint,bigint,bigint,varchar)
    TO hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_prezzi_approvati_prc_main(bigint,bigint,bigint,varchar)
    TO hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_prezzi_approvati_prc_finalize(bigint,bigint,bigint,varchar)
    TO hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_prezzi_approvati_prc_initialize(bigint,bigint,bigint,varchar)
    TO hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_prezzi_approvati_prc_main(bigint,bigint,bigint,varchar)
    TO hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_prezzi_approvati_prc_finalize(bigint,bigint,bigint,varchar)
    TO hcbi_ras, hcbi_utility;

COMMENT ON TABLE hcbi_ras.frontiera_prezzi_approvati
    IS 'Frontiera del flusso PREZZI_APPROVATI';
COMMENT ON TABLE hcbi_ras.src_tmp_prezzi_approvati
    IS 'Sorgente temporanea del flusso PREZZI_APPROVATI';
COMMENT ON TABLE hcbi_ras.stg_prezzi_approvati
    IS 'Staging valida del flusso PREZZI_APPROVATI';
COMMENT ON TABLE hcbi_ras.stg_prezzi_approvati_rej
    IS 'Record scartati del flusso PREZZI_APPROVATI';
COMMENT ON TABLE hcbi_ras.dwh_prezzi_approvati
    IS 'DWH non storicizzato del flusso PREZZI_APPROVATI';

/* ================================ TEST =================================
-- 1. Pre-check dipendenze di conversione:
SELECT to_regprocedure('hcbi_ras.try_integer(text)') AS try_integer,
       to_regprocedure('hcbi_ras.try_smallint(text)') AS try_smallint,
       to_regprocedure('hcbi_ras.try_numeric_24_5(text)') AS try_numeric_24_5;

-- 2. Verifica struttura oggetti:
SELECT to_regclass('hcbi_ras.frontiera_prezzi_approvati') AS frontiera,
       to_regclass('hcbi_ras.src_tmp_prezzi_approvati') AS src_tmp,
       to_regclass('hcbi_ras.stg_prezzi_approvati') AS stg,
       to_regclass('hcbi_ras.stg_prezzi_approvati_rej') AS stg_rej,
       to_regclass('hcbi_ras.dwh_prezzi_approvati') AS dwh;

-- 3. Riconciliazione STG:
SELECT (SELECT count(*) FROM hcbi_ras.v_src_tmp_prezzi_approvati) AS input,
       (SELECT count(*) FROM hcbi_ras.stg_prezzi_approvati) AS validi,
       (SELECT count(*) FROM hcbi_ras.stg_prezzi_approvati_rej) AS scarti;
-- Atteso: input = validi + scarti.

-- 4. Duplicati nella STG valida, atteso zero righe:
SELECT cd_articolo,
       ds_anno,
       id_sorgente_provincia,
       cd_versione,
       count(*)
FROM hcbi_ras.stg_prezzi_approvati
GROUP BY cd_articolo, ds_anno, id_sorgente_provincia, cd_versione
HAVING count(*) > 1;

-- 5. Duplicati nel DWH, atteso zero righe:
SELECT cd_articolo,
       ds_anno,
       id_sorgente_provincia,
       cd_versione,
       count(*)
FROM hcbi_ras.dwh_prezzi_approvati
GROUP BY cd_articolo, ds_anno, id_sorgente_provincia, cd_versione
HAVING count(*) > 1;

-- 6. Verifica dei record scartati:
SELECT tx_motivo_scarto,
       count(*) AS numero_scarti
FROM hcbi_ras.stg_prezzi_approvati_rej
GROUP BY tx_motivo_scarto
ORDER BY numero_scarti DESC, tx_motivo_scarto;

-- 7. Idempotenza:
-- Rieseguire pkg_dwh_prezzi_approvati_prc_main senza cambiare la STG.
-- Attesi nel log: inserted = 0 e updated = 0.

-- 8. Confronto STG/DWH sulla chiave naturale e sugli attributi:
SELECT s.*
FROM hcbi_ras.stg_prezzi_approvati s
LEFT JOIN hcbi_ras.dwh_prezzi_approvati d
  ON d.cd_articolo = s.cd_articolo
 AND d.ds_anno = s.ds_anno
 AND d.id_sorgente_provincia = s.id_sorgente_provincia
 AND d.cd_versione = s.cd_versione
WHERE d.id_prezzi_approvati IS NULL
   OR ROW(d.nr_prezzo, d.dt_approvazione)
      IS DISTINCT FROM
      ROW(s.nr_prezzo, s.dt_approvazione);
-- Atteso dopo il main DWH: zero righe.

-- Nota sulla semantica full:
-- in coerenza con il pattern PREZZI_RILEVATI, il main DWH non elimina né
-- ricicla le chiavi assenti dalla fotografia corrente. La propagazione delle
-- cancellazioni richiede una regola funzionale esplicita non inclusa qui.
======================================================================== */
