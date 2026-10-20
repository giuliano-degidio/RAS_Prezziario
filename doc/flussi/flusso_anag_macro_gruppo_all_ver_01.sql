/* =====================================================================
   FLUSSO ANAG_MACRO_GRUPPO
   Target: PostgreSQL 15.9 / 17
   Schema applicativo: hcbi_ras

   Sorgente operazionale dichiarata:
       public.macro_gruppi

   Query di estrazione verso la frontiera:
       SELECT id, nome, plurale
       FROM public.macro_gruppi;

   Mapping:
       id      -> id_sorgente_macro_gruppo
       nome    -> ds_nome
       plurale -> ds_plurale

   Business key:
       ds_nome

   Regole:
       - id sorgente obbligatorio e convertibile in BIGINT;
       - ds_nome obbligatorio, massimo 50 caratteri e univoco;
       - ds_plurale facoltativo e, se valorizzato, massimo 50 caratteri;
       - caricamento full, SCD Type 1, senza delete;
       - le tabelle di lavoro hanno nome fisso: nessuna esecuzione
         concorrente dello stesso flusso.
   ===================================================================== */

/* =====================================================================
   SEQUENCE DWH
   ===================================================================== */
CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_anag_macro_gruppo
    INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_anag_macro_gruppo OWNER TO hcbi_ras;
GRANT ALL ON SEQUENCE hcbi_ras.seq_dwh_anag_macro_gruppo TO hcbi_ras;
GRANT USAGE, SELECT ON SEQUENCE hcbi_ras.seq_dwh_anag_macro_gruppo TO hcbi_utility;

/* =====================================================================
   TABELLA FRONTIERA
   Popolamento esterno mediante la query operazionale documentata sopra.
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_anag_macro_gruppo
(
    id       VARCHAR(100),
    nome     VARCHAR(100),
    plurale  VARCHAR(100)
);

ALTER TABLE hcbi_ras.frontiera_anag_macro_gruppo OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.frontiera_anag_macro_gruppo FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.frontiera_anag_macro_gruppo TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.frontiera_anag_macro_gruppo TO hcbi_utility;

/* =====================================================================
   TABELLA SRC_TMP
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_anag_macro_gruppo
(
    id       VARCHAR(100),
    nome     VARCHAR(100),
    plurale  VARCHAR(100)
);

ALTER TABLE hcbi_ras.src_tmp_anag_macro_gruppo OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.src_tmp_anag_macro_gruppo FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.src_tmp_anag_macro_gruppo TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.src_tmp_anag_macro_gruppo TO hcbi_utility;

/* =====================================================================
   VISTA SRC_TMP
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_anag_macro_gruppo AS
SELECT
    BTRIM(s.id::TEXT)      AS id_sorgente_macro_gruppo,
    BTRIM(s.nome::TEXT)    AS ds_nome,
    BTRIM(s.plurale::TEXT) AS ds_plurale
FROM hcbi_ras.src_tmp_anag_macro_gruppo AS s;

ALTER VIEW hcbi_ras.v_src_tmp_anag_macro_gruppo OWNER TO hcbi_ras;
GRANT ALL ON hcbi_ras.v_src_tmp_anag_macro_gruppo TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_src_tmp_anag_macro_gruppo TO hcbi_utility;

/* =====================================================================
   TABELLA STG
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_macro_gruppo
(
    id_sorgente_macro_gruppo BIGINT NOT NULL,
    ds_nome                      VARCHAR(50) NOT NULL,
    ds_plurale                   VARCHAR(50)
);

ALTER TABLE hcbi_ras.stg_anag_macro_gruppo OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.stg_anag_macro_gruppo FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.stg_anag_macro_gruppo TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_macro_gruppo TO hcbi_utility;

/* =====================================================================
   TABELLA STG REJECT
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_macro_gruppo_rej
(
    id_sorgente_macro_gruppo VARCHAR(100),
    ds_nome                      VARCHAR(100),
    ds_plurale                   VARCHAR(100),
    tx_motivo_scarto             VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_macro_gruppo_rej OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.stg_anag_macro_gruppo_rej FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.stg_anag_macro_gruppo_rej TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_macro_gruppo_rej TO hcbi_utility;

/* =====================================================================
   TABELLA DWH
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_anag_macro_gruppo
(
    id_anag_macro_gruppo     BIGINT NOT NULL DEFAULT nextval(
        'hcbi_ras.seq_dwh_anag_macro_gruppo'::REGCLASS),
    id_sorgente_macro_gruppo BIGINT NOT NULL,
    ds_nome                      VARCHAR(50) NOT NULL,
    ds_plurale                   VARCHAR(50),
    dt_creation                  TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by               VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update                    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_update_by                 VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_reciclo                   TIMESTAMP WITHOUT TIME ZONE,

    CONSTRAINT pk_dwh_anag_macro_gruppo
        PRIMARY KEY (id_anag_macro_gruppo),
    CONSTRAINT uq_dwh_anag_macro_gruppo
        UNIQUE NULLS NOT DISTINCT (ds_nome),
    CONSTRAINT uq_dwh_anag_macro_gruppo_sorgente
        UNIQUE NULLS NOT DISTINCT (id_sorgente_macro_gruppo)
);

ALTER TABLE hcbi_ras.dwh_anag_macro_gruppo OWNER TO hcbi_ras;
GRANT ALL ON TABLE hcbi_ras.dwh_anag_macro_gruppo TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE hcbi_ras.dwh_anag_macro_gruppo TO hcbi_utility;

/* =====================================================================
   VISTA DWH
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_dwh_anag_macro_gruppo AS
SELECT
    s.id_sorgente_macro_gruppo,
    s.ds_nome,
    s.ds_plurale
FROM hcbi_ras.stg_anag_macro_gruppo AS s;

ALTER VIEW hcbi_ras.v_dwh_anag_macro_gruppo OWNER TO hcbi_ras;
GRANT ALL ON hcbi_ras.v_dwh_anag_macro_gruppo TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_dwh_anag_macro_gruppo TO hcbi_utility;

/* =====================================================================
   FUNZIONE DI CONVERSIONE SICURA
   Nota: CREATE OR REPLACE mantiene la funzione condivisa se gia' presente.
   ===================================================================== */
CREATE OR REPLACE FUNCTION hcbi_ras.try_bigint(p_value TEXT)
RETURNS BIGINT
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE
RETURNS NULL ON NULL INPUT SECURITY INVOKER
SET search_path TO pg_catalog
AS $FUNCTION$
BEGIN
    RETURN p_value::BIGINT;
EXCEPTION
    WHEN invalid_text_representation OR numeric_value_out_of_range THEN
        RETURN NULL;
END;
$FUNCTION$;

ALTER FUNCTION hcbi_ras.try_bigint(TEXT) OWNER TO hcbi_ras;

/* =====================================================================
   STG INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_macro_gruppo_prc_initialize(
    IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT; v_selected BIGINT:=0; v_inserted BIGINT:=0;
    v_updated BIGINT:=0; v_deleted BIGINT:=0; v_rec_errors BIGINT:=0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result:=-1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;

    TRUNCATE TABLE hcbi_ras.src_tmp_anag_macro_gruppo,
        hcbi_ras.stg_anag_macro_gruppo,
        hcbi_ras.stg_anag_macro_gruppo_rej;

    INSERT INTO hcbi_ras.src_tmp_anag_macro_gruppo(id,nome,plurale)
    SELECT f.id,f.nome,f.plurale
    FROM hcbi_ras.frontiera_anag_macro_gruppo AS f;
    GET DIAGNOSTICS v_inserted=ROW_COUNT;
    v_selected:=v_inserted;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    p_result:=1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result:=-1;
    v_log_error:=LEFT(CONCAT_WS(E'\n',
        'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500),
        CASE WHEN NULLIF(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||LEFT(v_sql_detail,1000) END,
        CASE WHEN NULLIF(v_sql_hint,'') IS NOT NULL THEN 'HINT='||LEFT(v_sql_hint,500) END,
        CASE WHEN NULLIF(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||LEFT(v_sql_context,800) END),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
        END;
    END IF;
    RAISE WARNING 'Errore in pkg_stg_anag_macro_gruppo_prc_initialize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_macro_gruppo_prc_initialize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_macro_gruppo_prc_initialize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;

/* =====================================================================
   STG MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_macro_gruppo_prc_main(
    IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT; v_selected BIGINT:=0; v_inserted BIGINT:=0;
    v_updated BIGINT:=0; v_deleted BIGINT:=0; v_rec_errors BIGINT:=0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result:=-1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_macro_gruppo_classificata;
    CREATE TABLE hcbi_ras.tmp_anag_macro_gruppo_classificata AS
    WITH src AS MATERIALIZED
    (
        SELECT
            f.id_sorgente_macro_gruppo AS id_raw,
            f.ds_nome AS nome_raw,
            f.ds_plurale AS plurale_raw,
            NULLIF(BTRIM(f.id_sorgente_macro_gruppo),'') AS id_txt,
            NULLIF(BTRIM(f.ds_nome),'') AS nome_txt,
            NULLIF(BTRIM(f.ds_plurale),'') AS plurale_txt,
            COUNT(*) OVER (PARTITION BY NULLIF(BTRIM(f.ds_nome),'')) AS nome_duplicate_count,
            COUNT(*) OVER (PARTITION BY NULLIF(BTRIM(f.id_sorgente_macro_gruppo),'')) AS id_duplicate_count
        FROM hcbi_ras.v_src_tmp_anag_macro_gruppo AS f
    ), converted AS MATERIALIZED
    (
        SELECT s.*,hcbi_ras.try_bigint(s.id_txt) AS id_cv
        FROM src AS s
    )
    SELECT
        c.*,
        CASE
            WHEN c.id_txt IS NULL THEN 'id_sorgente_macro_gruppo obbligatorio'
            WHEN c.id_cv IS NULL THEN 'id_sorgente_macro_gruppo non convertibile in bigint o fuori dominio'
            WHEN c.nome_txt IS NULL THEN 'ds_nome obbligatorio'
            WHEN LENGTH(c.nome_txt)>50 THEN 'ds_nome eccede 50 caratteri'
            WHEN LENGTH(c.plurale_txt)>50 THEN 'ds_plurale eccede 50 caratteri'
            WHEN c.nome_duplicate_count>1 THEN 'Chiave duplicata nella sorgente: (ds_nome)'
            WHEN c.id_duplicate_count>1 THEN 'Identificativo sorgente duplicato: (id_sorgente_macro_gruppo)'
            ELSE NULL
        END::TEXT AS tx_motivo_scarto
    FROM converted AS c;

    SELECT COUNT(*) INTO v_selected
    FROM hcbi_ras.tmp_anag_macro_gruppo_classificata;

    INSERT INTO hcbi_ras.stg_anag_macro_gruppo
        (id_sorgente_macro_gruppo,ds_nome,ds_plurale)
    SELECT c.id_cv,c.nome_txt,c.plurale_txt
    FROM hcbi_ras.tmp_anag_macro_gruppo_classificata AS c
    WHERE c.tx_motivo_scarto IS NULL;
    GET DIAGNOSTICS v_inserted=ROW_COUNT;

    INSERT INTO hcbi_ras.stg_anag_macro_gruppo_rej
        (id_sorgente_macro_gruppo,ds_nome,ds_plurale,tx_motivo_scarto)
    SELECT c.id_raw,c.nome_raw,c.plurale_raw,c.tx_motivo_scarto
    FROM hcbi_ras.tmp_anag_macro_gruppo_classificata AS c
    WHERE c.tx_motivo_scarto IS NOT NULL;
    GET DIAGNOSTICS v_rec_errors=ROW_COUNT;

    IF v_selected<>v_inserted+v_rec_errors THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE=FORMAT('Riconciliazione STG non valida: selected=%s, inserted=%s, rejected=%s',
                v_selected,v_inserted,v_rec_errors);
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_macro_gruppo_classificata;
    p_result:=1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result:=-1;
    BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_anag_macro_gruppo_classificata;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
    END;
    v_log_error:=LEFT(CONCAT_WS(E'\n',
        'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500),
        CASE WHEN NULLIF(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||LEFT(v_sql_detail,1000) END,
        CASE WHEN NULLIF(v_sql_hint,'') IS NOT NULL THEN 'HINT='||LEFT(v_sql_hint,500) END,
        CASE WHEN NULLIF(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||LEFT(v_sql_context,800) END),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
        END;
    END IF;
    RAISE WARNING 'Errore in pkg_stg_anag_macro_gruppo_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_macro_gruppo_prc_main(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_macro_gruppo_prc_main(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;

/* =====================================================================
   STG FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_macro_gruppo_prc_finalize(
    IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT; v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result:=-1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;
    ANALYZE hcbi_ras.src_tmp_anag_macro_gruppo;
    ANALYZE hcbi_ras.stg_anag_macro_gruppo;
    ANALYZE hcbi_ras.stg_anag_macro_gruppo_rej;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    p_result:=1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result:=-1;
    v_log_error:=LEFT(CONCAT_WS(E'\n','SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500)),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore in pkg_stg_anag_macro_gruppo_prc_finalize: %',v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_macro_gruppo_prc_finalize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_macro_gruppo_prc_finalize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;

/* =====================================================================
   DWH INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_macro_gruppo_prc_initialize(
    IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT; v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result:=-1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    p_result:=1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result:=-1;
    v_log_error:=LEFT(CONCAT_WS(E'\n','SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500)),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore in pkg_dwh_anag_macro_gruppo_prc_initialize: %',v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_macro_gruppo_prc_initialize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_anag_macro_gruppo_prc_initialize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;

/* =====================================================================
   DWH MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_macro_gruppo_prc_main(
    IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT; v_selected BIGINT:=0; v_inserted BIGINT:=0;
    v_updated BIGINT:=0; v_deleted BIGINT:=0; v_rec_errors BIGINT:=0;
    v_matched BIGINT:=0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result:=-1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_macro_gruppo;
    CREATE TABLE hcbi_ras.tmp_dwh_anag_macro_gruppo AS
    SELECT s.id_sorgente_macro_gruppo,s.ds_nome,s.ds_plurale
    FROM hcbi_ras.v_dwh_anag_macro_gruppo AS s;

    CREATE UNIQUE INDEX tmp_dwh_anag_macro_gruppo_uq
        ON hcbi_ras.tmp_dwh_anag_macro_gruppo(ds_nome) NULLS NOT DISTINCT;
    CREATE UNIQUE INDEX tmp_dwh_anag_macro_gruppo_src_uq
        ON hcbi_ras.tmp_dwh_anag_macro_gruppo(id_sorgente_macro_gruppo)
        NULLS NOT DISTINCT;
    ANALYZE hcbi_ras.tmp_dwh_anag_macro_gruppo;

    SELECT COUNT(*) INTO v_selected
    FROM hcbi_ras.tmp_dwh_anag_macro_gruppo;

    UPDATE hcbi_ras.dwh_anag_macro_gruppo AS d
       SET id_sorgente_macro_gruppo=src.id_sorgente_macro_gruppo,
           ds_plurale=src.ds_plurale,
           dt_update=clock_timestamp(),
           tx_update_by=p_ds_step_name
      FROM hcbi_ras.tmp_dwh_anag_macro_gruppo AS src
     WHERE d.ds_nome=src.ds_nome
       AND ROW(d.id_sorgente_macro_gruppo,d.ds_plurale)
           IS DISTINCT FROM ROW(src.id_sorgente_macro_gruppo,src.ds_plurale);
    GET DIAGNOSTICS v_updated=ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_anag_macro_gruppo
    (id_sorgente_macro_gruppo,ds_nome,ds_plurale,
     dt_creation,tx_creation_by,dt_update,tx_update_by)
    SELECT src.id_sorgente_macro_gruppo,src.ds_nome,src.ds_plurale,
           clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_macro_gruppo AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_anag_macro_gruppo DO NOTHING;
    GET DIAGNOSTICS v_inserted=ROW_COUNT;

    SELECT COUNT(*) INTO v_matched
    FROM hcbi_ras.dwh_anag_macro_gruppo AS d
    INNER JOIN hcbi_ras.tmp_dwh_anag_macro_gruppo AS src
        ON src.ds_nome=d.ds_nome;

    IF v_selected<>v_matched THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE=FORMAT('Riconciliazione DWH non valida: selected=%s, matched=%s',
                v_selected,v_matched);
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_macro_gruppo;
    p_result:=1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result:=-1;
    BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_macro_gruppo;
    EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: %',SQLERRM; END;
    v_log_error:=LEFT(CONCAT_WS(E'\n','SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500)),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore in pkg_dwh_anag_macro_gruppo_prc_main: %',v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_macro_gruppo_prc_main(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_anag_macro_gruppo_prc_main(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;

/* =====================================================================
   DWH FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_macro_gruppo_prc_finalize(
    IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT; v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result:=-1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;
    ANALYZE hcbi_ras.dwh_anag_macro_gruppo;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    p_result:=1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result:=-1;
    v_log_error:=LEFT(CONCAT_WS(E'\n','SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500)),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore in pkg_dwh_anag_macro_gruppo_prc_finalize: %',v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_macro_gruppo_prc_finalize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_anag_macro_gruppo_prc_finalize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;

/* =====================================================================
   COMMENTI
   ===================================================================== */
COMMENT ON TABLE hcbi_ras.frontiera_anag_macro_gruppo IS
    'Frontiera del flusso ANAG_MACRO_GRUPPO.';
COMMENT ON TABLE hcbi_ras.src_tmp_anag_macro_gruppo IS
    'Tabella sorgente temporanea del flusso ANAG_MACRO_GRUPPO.';
COMMENT ON TABLE hcbi_ras.stg_anag_macro_gruppo IS
    'Staging validata del flusso ANAG_MACRO_GRUPPO.';
COMMENT ON TABLE hcbi_ras.stg_anag_macro_gruppo_rej IS
    'Record scartati del flusso ANAG_MACRO_GRUPPO.';
COMMENT ON TABLE hcbi_ras.dwh_anag_macro_gruppo IS
    'DWH del flusso ANAG_MACRO_GRUPPO.';
COMMENT ON CONSTRAINT uq_dwh_anag_macro_gruppo
ON hcbi_ras.dwh_anag_macro_gruppo IS
    'Business key del flusso ANAG_MACRO_GRUPPO: ds_nome.';
COMMENT ON CONSTRAINT uq_dwh_anag_macro_gruppo_sorgente
ON hcbi_ras.dwh_anag_macro_gruppo IS
    'Candidate key sorgente: id_sorgente_macro_gruppo.';

/* =====================================================================
   TEST POST-DEPLOYMENT
   ===================================================================== */

/* T01 - Duplicati sulla business key in DWH. Atteso: zero righe. */
-- SELECT ds_nome,COUNT(*)
-- FROM hcbi_ras.dwh_anag_macro_gruppo
-- GROUP BY ds_nome HAVING COUNT(*)>1;

/* T02 - Duplicati sull'identificativo sorgente. Atteso: zero righe. */
-- SELECT id_sorgente_macro_gruppo,COUNT(*)
-- FROM hcbi_ras.dwh_anag_macro_gruppo
-- GROUP BY id_sorgente_macro_gruppo HAVING COUNT(*)>1;

/* T03 - Campi obbligatori NULL. Atteso: zero. */
-- SELECT COUNT(*) AS record_non_validi
-- FROM hcbi_ras.dwh_anag_macro_gruppo
-- WHERE id_sorgente_macro_gruppo IS NULL
--    OR ds_nome IS NULL;

/* T04 - Riconciliazione STG-DWH. Atteso: zero. */
-- SELECT COUNT(*) AS record_stg_non_presenti
-- FROM hcbi_ras.stg_anag_macro_gruppo s
-- LEFT JOIN hcbi_ras.dwh_anag_macro_gruppo d ON d.ds_nome=s.ds_nome
-- WHERE d.id_anag_macro_gruppo IS NULL;

/* T05 - Coerenza attributi STG-DWH. Atteso: zero. */
-- SELECT COUNT(*) AS record_non_coerenti
-- FROM hcbi_ras.stg_anag_macro_gruppo s
-- JOIN hcbi_ras.dwh_anag_macro_gruppo d ON d.ds_nome=s.ds_nome
-- WHERE ROW(d.id_sorgente_macro_gruppo,d.ds_plurale)
--       IS DISTINCT FROM ROW(s.id_sorgente_macro_gruppo,s.ds_plurale);

/* T06 - Riconciliazione frontiera. */
-- SELECT
--   (SELECT COUNT(*) FROM hcbi_ras.frontiera_anag_macro_gruppo) AS frontiera,
--   (SELECT COUNT(*) FROM hcbi_ras.stg_anag_macro_gruppo) AS validi,
--   (SELECT COUNT(*) FROM hcbi_ras.stg_anag_macro_gruppo_rej) AS scarti;
