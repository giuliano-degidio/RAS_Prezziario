/* =====================================================================
   FLUSSO ARTICOLI_INFORMATORI
   Target: PostgreSQL 15.9 / 17
   Sorgente operazionale: public.articoli_informatori
   Alimentazione frontiera: NiFi (fuori ambito di questo script)
   Grain DWH: una riga per (id_informatore, codice_articolo, anno, provincia, addendum).

   Requisiti applicati:
   - target delle FK sorgente non considerati;
   - caricamento full, non storicizzato;
   - STG ricostruita a ogni esecuzione;
   - DWH riallineato tramite update dei record variati e insert dei nuovi;
   - nessuna cancellazione/riciclo delle chiavi assenti dalla fotografia corrente;
   - scarti e duplicati separati nella tabella STG_REJ.

   Dipendenze applicative attese:
   - hcbi_ras.try_integer(text)
   - hcbi_ras.try_smallint(text)
   - hcbi_ras.try_bigint(text)
   - funzioni/procedure di logging nello schema hcbi_utility
   ===================================================================== */

/* ============================== SEQUENCE ============================== */
CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_articoli_informatori
    AS bigint INCREMENT 1 START 1 MINVALUE 1 CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_articoli_informatori OWNER TO hcbi_ras;
GRANT ALL ON SEQUENCE hcbi_ras.seq_dwh_articoli_informatori TO hcbi_ras;
GRANT USAGE, SELECT ON SEQUENCE hcbi_ras.seq_dwh_articoli_informatori TO hcbi_utility;

/* ============================== FRONTIERA ============================= */
CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_articoli_informatori (
    id_informatore varchar(100),
    codice_articolo varchar(60),
    anno varchar(100),
    provincia varchar(100),
    escluso varchar(20),
    addendum varchar(20),
    id varchar(100),
    user_id varchar(100)
);

ALTER TABLE hcbi_ras.frontiera_articoli_informatori OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.frontiera_articoli_informatori FROM hcbi_utility;
GRANT ALL ON hcbi_ras.frontiera_articoli_informatori TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.frontiera_articoli_informatori TO hcbi_utility;

/* ============================== SRC_TMP ================================ */
CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_articoli_informatori
(LIKE hcbi_ras.frontiera_articoli_informatori INCLUDING DEFAULTS);

ALTER TABLE hcbi_ras.src_tmp_articoli_informatori OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.src_tmp_articoli_informatori FROM hcbi_utility;
GRANT ALL ON hcbi_ras.src_tmp_articoli_informatori TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.src_tmp_articoli_informatori TO hcbi_utility;

CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_articoli_informatori AS
SELECT btrim(s.id_informatore) AS id_sorgente_informatore,
       btrim(s.codice_articolo) AS cd_articolo,
       btrim(s.anno) AS ds_anno,
       btrim(s.provincia) AS id_sorgente_provincia,
       btrim(s.escluso) AS fl_escluso,
       btrim(s.addendum) AS cd_versione,
       btrim(s.id) AS id_sorgente_articoli_informatori,
       btrim(s.user_id) AS id_sorgente_utente
FROM hcbi_ras.src_tmp_articoli_informatori s;

ALTER VIEW hcbi_ras.v_src_tmp_articoli_informatori OWNER TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_src_tmp_articoli_informatori TO hcbi_utility;

/* ============================== STAGING ================================ */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_articoli_informatori (
    id_sorgente_informatore integer NOT NULL,
    cd_articolo varchar(60) NOT NULL,
    ds_anno integer NOT NULL,
    id_sorgente_provincia integer NOT NULL,
    fl_escluso smallint NOT NULL,
    cd_versione smallint NOT NULL,
    id_sorgente_articoli_informatori bigint NOT NULL,
    id_sorgente_utente integer,
    CONSTRAINT ck_stg_articoli_informatori_escluso CHECK (fl_escluso IN (0,1))
);

ALTER TABLE hcbi_ras.stg_articoli_informatori OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.stg_articoli_informatori FROM hcbi_utility;
GRANT ALL ON hcbi_ras.stg_articoli_informatori TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.stg_articoli_informatori TO hcbi_utility;

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_articoli_informatori_rej (
    id_sorgente_informatore varchar(100),
    cd_articolo varchar(60),
    ds_anno varchar(100),
    id_sorgente_provincia varchar(100),
    fl_escluso varchar(20),
    cd_versione varchar(20),
    id_sorgente_articoli_informatori varchar(100),
    id_sorgente_utente varchar(100),
    tx_motivo_scarto varchar(4000),
    dt_scarto timestamp without time zone NOT NULL DEFAULT clock_timestamp()
);

ALTER TABLE hcbi_ras.stg_articoli_informatori_rej OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.stg_articoli_informatori_rej FROM hcbi_utility;
GRANT ALL ON hcbi_ras.stg_articoli_informatori_rej TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.stg_articoli_informatori_rej TO hcbi_utility;

/* ================================ DWH ================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_articoli_informatori (
    id_articoli_informatori bigint NOT NULL
        DEFAULT nextval('hcbi_ras.seq_dwh_articoli_informatori'::regclass),
    id_sorgente_articoli_informatori bigint NOT NULL,
    id_sorgente_informatore integer NOT NULL,
    cd_articolo varchar(60) NOT NULL,
    ds_anno integer NOT NULL,
    id_sorgente_provincia integer NOT NULL,
    fl_escluso smallint NOT NULL,
    cd_versione smallint NOT NULL,
    id_sorgente_utente integer,
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by varchar(4000) NOT NULL DEFAULT current_user,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by varchar(4000) NOT NULL DEFAULT current_user,
    dt_reciclo timestamp without time zone,
    CONSTRAINT pk_dwh_articoli_informatori PRIMARY KEY (id_articoli_informatori),
    CONSTRAINT uk_dwh_articoli_informatori UNIQUE
        (id_sorgente_informatore, cd_articolo, ds_anno, id_sorgente_provincia, cd_versione),
    CONSTRAINT ck_dwh_articoli_informatori_escluso CHECK (fl_escluso IN (0,1))
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_dwh_articoli_informatori_id_sorgente
    ON hcbi_ras.dwh_articoli_informatori (id_sorgente_articoli_informatori);
CREATE INDEX IF NOT EXISTS ix_dwh_articoli_informatori_articolo
    ON hcbi_ras.dwh_articoli_informatori (cd_articolo, ds_anno, id_sorgente_provincia, cd_versione);
CREATE INDEX IF NOT EXISTS ix_dwh_articoli_informatori_informatore
    ON hcbi_ras.dwh_articoli_informatori (id_sorgente_informatore, ds_anno, id_sorgente_provincia, cd_versione);

ALTER TABLE hcbi_ras.dwh_articoli_informatori OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.dwh_articoli_informatori FROM hcbi_utility;
GRANT ALL ON hcbi_ras.dwh_articoli_informatori TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.dwh_articoli_informatori TO hcbi_utility;

CREATE OR REPLACE VIEW hcbi_ras.v_dwh_articoli_informatori AS
SELECT s.id_sorgente_articoli_informatori,
       s.id_sorgente_informatore,
       s.cd_articolo,
       s.ds_anno,
       s.id_sorgente_provincia,
       s.fl_escluso,
       s.cd_versione,
       s.id_sorgente_utente
FROM hcbi_ras.stg_articoli_informatori s;

ALTER VIEW hcbi_ras.v_dwh_articoli_informatori OWNER TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_dwh_articoli_informatori TO hcbi_utility;

/* ============================ STG INITIALIZE =========================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_articoli_informatori_prc_initialize(
    IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
    IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE v_id_log bigint;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
    INTO v_id_log;

    TRUNCATE TABLE hcbi_ras.stg_articoli_informatori,
                   hcbi_ras.stg_articoli_informatori_rej;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),
                clock_timestamp()::timestamp,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore initialize STG ARTICOLI_INFORMATORI: %',SQLERRM;
END;
$BODY$;

/* ============================== STG MAIN =============================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_articoli_informatori_prc_main(
    IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
    IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
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
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_articoli_informatori_classificata;

    CREATE TABLE hcbi_ras.tmp_articoli_informatori_classificata AS
    WITH src AS MATERIALIZED (
        SELECT f.id_sorgente_informatore,
               f.cd_articolo,
               f.ds_anno,
               f.id_sorgente_provincia,
               f.fl_escluso,
               f.cd_versione,
               f.id_sorgente_articoli_informatori,
               f.id_sorgente_utente,
               NULLIF(btrim(f.id_sorgente_informatore),'') AS informatore_txt,
               NULLIF(btrim(f.cd_articolo),'') AS articolo_txt,
               NULLIF(btrim(f.ds_anno),'') AS anno_txt,
               NULLIF(btrim(f.id_sorgente_provincia),'') AS provincia_txt,
               NULLIF(lower(btrim(f.fl_escluso)),'') AS escluso_txt,
               NULLIF(btrim(f.cd_versione),'') AS addendum_txt,
               NULLIF(btrim(f.id_sorgente_articoli_informatori),'') AS id_txt,
               NULLIF(btrim(f.id_sorgente_utente),'') AS utente_txt
        FROM hcbi_ras.v_src_tmp_articoli_informatori f
    ), cv AS MATERIALIZED (
        SELECT s.*,
               hcbi_ras.try_integer(s.informatore_txt) AS informatore_cv,
               s.articolo_txt AS articolo_cv,
               hcbi_ras.try_integer(s.anno_txt) AS anno_cv,
               hcbi_ras.try_integer(s.provincia_txt) AS provincia_cv,
               CASE s.escluso_txt
                   WHEN '0' THEN 0::smallint
                   WHEN 'false' THEN 0::smallint
                   WHEN 'f' THEN 0::smallint
                   WHEN 'no' THEN 0::smallint
                   WHEN 'n' THEN 0::smallint
                   WHEN '1' THEN 1::smallint
                   WHEN 'true' THEN 1::smallint
                   WHEN 't' THEN 1::smallint
                   WHEN 'yes' THEN 1::smallint
                   WHEN 'y' THEN 1::smallint
                   ELSE NULL::smallint
               END AS escluso_cv,
               hcbi_ras.try_smallint(s.addendum_txt) AS addendum_cv,
               hcbi_ras.try_bigint(s.id_txt) AS id_cv,
               hcbi_ras.try_integer(s.utente_txt) AS utente_cv
        FROM src s
    ), dup AS MATERIALIZED (
        SELECT c.*,
               count(*) OVER (
                   PARTITION BY c.informatore_cv,c.articolo_cv,c.anno_cv,c.provincia_cv,c.addendum_cv
               ) AS duplicate_key_count,
               count(*) OVER (PARTITION BY c.id_cv) AS duplicate_id_count
        FROM cv c
    )
    SELECT d.*,
           CASE
               WHEN d.informatore_txt IS NULL THEN 'id_informatore obbligatorio'
               WHEN d.informatore_cv IS NULL THEN 'id_informatore non convertibile o fuori dominio integer'
               WHEN d.articolo_txt IS NULL THEN 'codice_articolo obbligatorio'
               WHEN length(d.articolo_txt) > 60 THEN 'codice_articolo eccede 60 caratteri'
               WHEN d.anno_txt IS NULL THEN 'anno obbligatorio'
               WHEN d.anno_cv IS NULL THEN 'anno non convertibile o fuori dominio integer'
               WHEN d.provincia_txt IS NULL THEN 'provincia obbligatoria'
               WHEN d.provincia_cv IS NULL THEN 'provincia non convertibile o fuori dominio integer'
               WHEN d.escluso_txt IS NULL THEN 'escluso obbligatorio'
               WHEN d.escluso_cv IS NULL THEN 'escluso non riconosciuto; valori ammessi: 0/1, false/true, f/t, no/yes, n/y'
               WHEN d.addendum_txt IS NULL THEN 'addendum obbligatorio'
               WHEN d.addendum_cv IS NULL THEN 'addendum non convertibile o fuori dominio smallint'
               WHEN d.id_txt IS NULL THEN 'id obbligatorio'
               WHEN d.id_cv IS NULL THEN 'id non convertibile o fuori dominio bigint'
               WHEN d.utente_txt IS NOT NULL AND d.utente_cv IS NULL THEN 'user_id non convertibile o fuori dominio integer'
               WHEN d.duplicate_key_count > 1 THEN 'Chiave duplicata: (id_informatore, codice_articolo, anno, provincia, addendum)'
               WHEN d.duplicate_id_count > 1 THEN 'id sorgente duplicato'
               ELSE NULL
           END::text AS tx_motivo_scarto
    FROM dup d;

    SELECT count(*) INTO v_selected
    FROM hcbi_ras.tmp_articoli_informatori_classificata;

    INSERT INTO hcbi_ras.stg_articoli_informatori (
        id_sorgente_informatore,cd_articolo,ds_anno,id_sorgente_provincia,fl_escluso,cd_versione,
        id_sorgente_articoli_informatori,id_sorgente_utente)
    SELECT informatore_cv,articolo_cv,anno_cv,provincia_cv,escluso_cv,addendum_cv,id_cv,utente_cv
    FROM hcbi_ras.tmp_articoli_informatori_classificata
    WHERE tx_motivo_scarto IS NULL;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_articoli_informatori_rej (
        id_sorgente_informatore,cd_articolo,ds_anno,id_sorgente_provincia,fl_escluso,cd_versione,
        id_sorgente_articoli_informatori,id_sorgente_utente,tx_motivo_scarto)
    SELECT id_sorgente_informatore,cd_articolo,ds_anno,id_sorgente_provincia,fl_escluso,cd_versione,
           id_sorgente_articoli_informatori,id_sorgente_utente,tx_motivo_scarto
    FROM hcbi_ras.tmp_articoli_informatori_classificata
    WHERE tx_motivo_scarto IS NOT NULL;
    GET DIAGNOSTICS v_rejected = ROW_COUNT;

    IF v_selected <> v_inserted + v_rejected THEN
        RAISE EXCEPTION 'Riconciliazione STG non valida: selected=%, inserted=%, rejected=%',
            v_selected,v_inserted,v_rejected;
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rejected,
        'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);

    DROP TABLE hcbi_ras.tmp_articoli_informatori_classificata;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    DROP TABLE IF EXISTS hcbi_ras.tmp_articoli_informatori_classificata;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),
                clock_timestamp()::timestamp,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore main STG ARTICOLI_INFORMATORI: %',SQLERRM;
END;
$BODY$;

/* ============================ STG FINALIZE ============================= */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_articoli_informatori_prc_finalize(
    IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
    IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE v_id_log bigint;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
    INTO v_id_log;
    ANALYZE hcbi_ras.stg_articoli_informatori;
    ANALYZE hcbi_ras.stg_articoli_informatori_rej;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),
                clock_timestamp()::timestamp,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore finalize STG ARTICOLI_INFORMATORI: %',SQLERRM;
END;
$BODY$;

/* ============================= DWH INIT ================================ */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_articoli_informatori_prc_initialize(
    IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
    IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE v_id_log bigint;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
    INTO v_id_log;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),
                clock_timestamp()::timestamp,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore initialize DWH ARTICOLI_INFORMATORI: %',SQLERRM;
END;
$BODY$;

/* ============================== DWH MAIN =============================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_articoli_informatori_prc_main(
    IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
    IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
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
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
    INTO v_id_log;

    SELECT count(*) INTO v_selected
    FROM hcbi_ras.v_dwh_articoli_informatori;

    UPDATE hcbi_ras.dwh_articoli_informatori d
       SET id_sorgente_articoli_informatori = s.id_sorgente_articoli_informatori,
           fl_escluso = s.fl_escluso,
           id_sorgente_utente = s.id_sorgente_utente,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.v_dwh_articoli_informatori s
     WHERE d.id_sorgente_informatore = s.id_sorgente_informatore
       AND d.cd_articolo = s.cd_articolo
       AND d.ds_anno = s.ds_anno
       AND d.id_sorgente_provincia = s.id_sorgente_provincia
       AND d.cd_versione = s.cd_versione
       AND ROW(d.id_sorgente_articoli_informatori,d.fl_escluso,d.id_sorgente_utente)
           IS DISTINCT FROM
           ROW(s.id_sorgente_articoli_informatori,s.fl_escluso,s.id_sorgente_utente);
    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_articoli_informatori (
        id_sorgente_articoli_informatori,id_sorgente_informatore,cd_articolo,
        ds_anno,id_sorgente_provincia,fl_escluso,cd_versione,id_sorgente_utente,
        tx_creation_by,tx_update_by)
    SELECT s.id_sorgente_articoli_informatori,s.id_sorgente_informatore,s.cd_articolo,
           s.ds_anno,s.id_sorgente_provincia,s.fl_escluso,s.cd_versione,s.id_sorgente_utente,
           p_ds_step_name,p_ds_step_name
    FROM hcbi_ras.v_dwh_articoli_informatori s
    ON CONFLICT (id_sorgente_informatore,cd_articolo,ds_anno,id_sorgente_provincia,cd_versione)
    DO NOTHING;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_errors,
        'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),
                clock_timestamp()::timestamp,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore main DWH ARTICOLI_INFORMATORI: %',SQLERRM;
END;
$BODY$;

/* ============================ DWH FINALIZE ============================= */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_articoli_informatori_prc_finalize(
    IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
    IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE v_id_log bigint;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
    INTO v_id_log;
    ANALYZE hcbi_ras.dwh_articoli_informatori;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),
                clock_timestamp()::timestamp,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore finalize DWH ARTICOLI_INFORMATORI: %',SQLERRM;
END;
$BODY$;

/* ========================= OWNER / EXECUTE / COMMENT =================== */
ALTER PROCEDURE hcbi_ras.pkg_stg_articoli_informatori_prc_initialize(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_stg_articoli_informatori_prc_main(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_stg_articoli_informatori_prc_finalize(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dwh_articoli_informatori_prc_initialize(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dwh_articoli_informatori_prc_main(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dwh_articoli_informatori_prc_finalize(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_articoli_informatori_prc_initialize(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_articoli_informatori_prc_main(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_articoli_informatori_prc_finalize(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_articoli_informatori_prc_initialize(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_articoli_informatori_prc_main(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_articoli_informatori_prc_finalize(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;

COMMENT ON TABLE hcbi_ras.frontiera_articoli_informatori IS 'Frontiera del flusso ARTICOLI_INFORMATORI, alimentata da NiFi';
COMMENT ON TABLE hcbi_ras.src_tmp_articoli_informatori IS 'Sorgente temporanea del flusso ARTICOLI_INFORMATORI';
COMMENT ON TABLE hcbi_ras.stg_articoli_informatori IS 'Staging valida del flusso ARTICOLI_INFORMATORI';
COMMENT ON TABLE hcbi_ras.stg_articoli_informatori_rej IS 'Record scartati del flusso ARTICOLI_INFORMATORI';
COMMENT ON TABLE hcbi_ras.dwh_articoli_informatori IS 'DWH non storicizzato del flusso ARTICOLI_INFORMATORI';
COMMENT ON CONSTRAINT uk_dwh_articoli_informatori ON hcbi_ras.dwh_articoli_informatori
    IS 'Business key: id_sorgente_informatore, cd_articolo, ds_anno, id_sorgente_provincia, cd_versione';

/* ================================ TEST =================================
-- 1. Pre-check dipendenze:
SELECT to_regprocedure('hcbi_ras.try_integer(text)') AS try_integer,
       to_regprocedure('hcbi_ras.try_smallint(text)') AS try_smallint,
       to_regprocedure('hcbi_ras.try_bigint(text)') AS try_bigint;

-- 2. Verifica struttura oggetti:
SELECT to_regclass('hcbi_ras.frontiera_articoli_informatori') AS frontiera,
       to_regclass('hcbi_ras.src_tmp_articoli_informatori') AS src_tmp,
       to_regclass('hcbi_ras.stg_articoli_informatori') AS stg,
       to_regclass('hcbi_ras.stg_articoli_informatori_rej') AS stg_rej,
       to_regclass('hcbi_ras.dwh_articoli_informatori') AS dwh;

-- 3. Riconciliazione STG, atteso input = validi + scarti:
SELECT (SELECT count(*) FROM hcbi_ras.v_src_tmp_articoli_informatori) AS input,
       (SELECT count(*) FROM hcbi_ras.stg_articoli_informatori) AS validi,
       (SELECT count(*) FROM hcbi_ras.stg_articoli_informatori_rej) AS scarti;

-- 4. Duplicati STG valida, atteso zero righe:
SELECT id_sorgente_informatore,cd_articolo,ds_anno,id_sorgente_provincia,cd_versione,count(*)
FROM hcbi_ras.stg_articoli_informatori
GROUP BY 1,2,3,4,5 HAVING count(*) > 1;

-- 5. Duplicati DWH, atteso zero righe:
SELECT id_sorgente_informatore,cd_articolo,ds_anno,id_sorgente_provincia,cd_versione,count(*)
FROM hcbi_ras.dwh_articoli_informatori
GROUP BY 1,2,3,4,5 HAVING count(*) > 1;

-- 6. Distribuzione scarti:
SELECT tx_motivo_scarto,count(*) AS numero_scarti
FROM hcbi_ras.stg_articoli_informatori_rej
GROUP BY tx_motivo_scarto
ORDER BY numero_scarti DESC,tx_motivo_scarto;

-- 7. Confronto STG/DWH, atteso zero righe dopo DWH main:
SELECT s.*
FROM hcbi_ras.stg_articoli_informatori s
LEFT JOIN hcbi_ras.dwh_articoli_informatori d
  ON d.id_sorgente_informatore = s.id_sorgente_informatore
 AND d.cd_articolo = s.cd_articolo
 AND d.ds_anno = s.ds_anno
 AND d.id_sorgente_provincia = s.id_sorgente_provincia
 AND d.cd_versione = s.cd_versione
WHERE d.id_articoli_informatori IS NULL
   OR ROW(d.id_sorgente_articoli_informatori,d.fl_escluso,d.id_sorgente_utente)
      IS DISTINCT FROM
      ROW(s.id_sorgente_articoli_informatori,s.fl_escluso,s.id_sorgente_utente);

-- 8. Idempotenza:
-- Rieseguire pkg_dwh_articoli_informatori_prc_main senza cambiare STG.
-- Attesi nel log: inserted = 0 e updated = 0.
======================================================================== */
