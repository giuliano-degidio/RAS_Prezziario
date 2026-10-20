/* =====================================================================
   FLUSSO ANAG_PROVINCIA - VERSIONE UNIFORMATA
   Target tecnico: PostgreSQL 15.9 / 17
   Pattern tecnico: PUBBLICAZIONE_ANALISI definitivo
   Sorgente operazionale: public.province
   Schema target: hcbi_ras

   Chiave logica STG/DWH:
       cd_provincia

   Mapping principale:
       id                              -> id_sorgente_provincia
       provincia                       -> cd_provincia
       nome                            -> ds_nome
       id_area_vasta                   -> id_sorgente_area_vasta
       provincia_principale_regionale  -> fl_provincia_principale_regionale
       provincia_principale_area_vasta -> fl_provincia_principale_area_vasta
       anno                            -> anno
       addendum                        -> addendum
   ===================================================================== */


/* =====================================================================
   SEQUENCE
   ===================================================================== */

CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_anag_provincia
    INCREMENT 1
    START 0
    MINVALUE 0
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_anag_provincia
    OWNER TO hcbi_ras;

GRANT ALL ON SEQUENCE hcbi_ras.seq_dwh_anag_provincia
TO hcbi_ras;

GRANT USAGE, SELECT ON SEQUENCE hcbi_ras.seq_dwh_anag_provincia
TO hcbi_utility;


/* =====================================================================
   TABELLA FRONTIERA
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_anag_provincia
(
    id                              VARCHAR(100),
    provincia                       VARCHAR(2),
    nome                            VARCHAR(100),
    id_area_vasta                   VARCHAR(20),
    provincia_principale_regionale VARCHAR(20),
    provincia_principale_area_vasta VARCHAR(20),
    anno                            VARCHAR(20),
    addendum                        VARCHAR(20)
);

ALTER TABLE hcbi_ras.frontiera_anag_provincia
    OWNER TO hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.frontiera_anag_provincia
FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.frontiera_anag_provincia
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.frontiera_anag_provincia
TO hcbi_utility;


/* =====================================================================
   TABELLA SRC_TMP
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_anag_provincia
(
    id                              VARCHAR(100),
    provincia                       VARCHAR(2),
    nome                            VARCHAR(100),
    id_area_vasta                   VARCHAR(20),
    provincia_principale_regionale VARCHAR(20),
    provincia_principale_area_vasta VARCHAR(20),
    anno                            VARCHAR(20),
    addendum                        VARCHAR(20)
);

ALTER TABLE hcbi_ras.src_tmp_anag_provincia
    OWNER TO hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.src_tmp_anag_provincia
FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.src_tmp_anag_provincia
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.src_tmp_anag_provincia
TO hcbi_utility;


/* =====================================================================
   VISTA SRC_TMP
   ===================================================================== */

CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_anag_provincia
AS
SELECT
    TRIM(BOTH FROM s.id::text)
        AS id_sorgente_provincia,

    TRIM(BOTH FROM s.provincia::text)
        AS cd_provincia,

    TRIM(BOTH FROM s.nome::text)
        AS ds_nome,

    TRIM(BOTH FROM s.id_area_vasta::text)
        AS id_sorgente_area_vasta,

    TRIM(BOTH FROM s.provincia_principale_regionale::text)
        AS fl_provincia_principale_regionale,

    TRIM(BOTH FROM s.provincia_principale_area_vasta::text)
        AS fl_provincia_principale_area_vasta,
    TRIM(BOTH FROM s.anno::text) AS anno,
    TRIM(BOTH FROM s.addendum::text) AS addendum

FROM hcbi_ras.src_tmp_anag_provincia AS s;

ALTER VIEW hcbi_ras.v_src_tmp_anag_provincia
    OWNER TO hcbi_ras;

GRANT ALL ON hcbi_ras.v_src_tmp_anag_provincia
TO hcbi_ras;

GRANT SELECT ON hcbi_ras.v_src_tmp_anag_provincia
TO hcbi_utility;


/* =====================================================================
   TABELLA STG
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_provincia
(
    anno                              INTEGER NOT NULL,
    addendum                          INTEGER NOT NULL,
    id_sorgente_provincia              BIGINT NOT NULL,
    cd_provincia                       VARCHAR(2) NOT NULL,
    ds_nome                            VARCHAR(100) NOT NULL,
    id_sorgente_area_vasta             BIGINT,
    fl_provincia_principale_regionale  SMALLINT NOT NULL,
    fl_provincia_principale_area_vasta  SMALLINT NOT NULL
);

ALTER TABLE hcbi_ras.stg_anag_provincia
    OWNER TO hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.stg_anag_provincia
FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.stg_anag_provincia
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_provincia
TO hcbi_utility;


/* =====================================================================
   TABELLA STG REJECT
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_provincia_rej
(
    anno                              VARCHAR(20),
    addendum                          VARCHAR(20),
    id_sorgente_provincia              VARCHAR(100),
    cd_provincia                       VARCHAR(2),
    ds_nome                            VARCHAR(100),
    id_sorgente_area_vasta             VARCHAR(20),
    fl_provincia_principale_regionale  VARCHAR(20),
    fl_provincia_principale_area_vasta  VARCHAR(20),
    tx_motivo_scarto                   VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_provincia_rej
    OWNER TO hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.stg_anag_provincia_rej
FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.stg_anag_provincia_rej
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_provincia_rej
TO hcbi_utility;


/* =====================================================================
   TABELLA DWH
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_anag_provincia
(
    anno                              INTEGER NOT NULL,
    addendum                          INTEGER NOT NULL,
    id_anag_provincia BIGINT NOT NULL
        DEFAULT nextval('hcbi_ras.seq_dwh_anag_provincia'::regclass),

    id_sorgente_provincia              BIGINT NOT NULL,
    cd_provincia                       VARCHAR(2) NOT NULL,
    ds_nome                            VARCHAR(100) NOT NULL,
    id_sorgente_area_vasta             BIGINT,
    fl_provincia_principale_regionale  SMALLINT NOT NULL,
    fl_provincia_principale_area_vasta  SMALLINT NOT NULL,

    dt_creation                        TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT clock_timestamp(),

    tx_creation_by                     VARCHAR(4000)
        NOT NULL DEFAULT CURRENT_USER,

    dt_update                          TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT clock_timestamp(),

    tx_update_by                       VARCHAR(4000)
        NOT NULL DEFAULT CURRENT_USER,

    dt_reciclo                         TIMESTAMP WITHOUT TIME ZONE,

    CONSTRAINT pk_dwh_anag_provincia
        PRIMARY KEY (anno, addendum, id_anag_provincia),

    CONSTRAINT uq_dwh_anag_provincia
        UNIQUE NULLS NOT DISTINCT (anno, addendum, cd_provincia),
    CONSTRAINT uq_dwh_anag_provincia_sorgente
        UNIQUE NULLS NOT DISTINCT (anno, addendum, id_sorgente_provincia)
);

ALTER TABLE hcbi_ras.dwh_anag_provincia
    OWNER TO hcbi_ras;

GRANT ALL ON TABLE hcbi_ras.dwh_anag_provincia
TO hcbi_ras;

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE hcbi_ras.dwh_anag_provincia
TO hcbi_utility;


/* =====================================================================
   VISTA DWH
   ===================================================================== */

CREATE OR REPLACE VIEW hcbi_ras.v_dwh_anag_provincia
AS
SELECT
    s.anno,
    s.addendum,
    s.id_sorgente_provincia,
    s.cd_provincia,
    s.ds_nome,
    s.id_sorgente_area_vasta,
    s.fl_provincia_principale_regionale,
    s.fl_provincia_principale_area_vasta
FROM hcbi_ras.stg_anag_provincia AS s;

ALTER VIEW hcbi_ras.v_dwh_anag_provincia
    OWNER TO hcbi_ras;

GRANT ALL ON hcbi_ras.v_dwh_anag_provincia
TO hcbi_ras;

GRANT SELECT ON hcbi_ras.v_dwh_anag_provincia
TO hcbi_utility;


/* =====================================================================
   FUNZIONI DI CONVERSIONE SICURA
   ===================================================================== */
CREATE OR REPLACE FUNCTION hcbi_ras.try_bigint(p_value text) RETURNS bigint
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog
AS $function$ BEGIN RETURN p_value::bigint; EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END; $function$;
ALTER FUNCTION hcbi_ras.try_bigint(text) OWNER TO hcbi_ras;
CREATE OR REPLACE FUNCTION hcbi_ras.try_integer(p_value text) RETURNS integer
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog
AS $function$ BEGIN RETURN p_value::integer; EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END; $function$;
ALTER FUNCTION hcbi_ras.try_integer(text) OWNER TO hcbi_ras;
CREATE OR REPLACE FUNCTION hcbi_ras.try_boolean_smallint(p_value text) RETURNS smallint
LANGUAGE sql IMMUTABLE PARALLEL SAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog
AS $function$ SELECT CASE lower(btrim(p_value)) WHEN 'true' THEN 1::smallint WHEN 't' THEN 1::smallint WHEN '1' THEN 1::smallint WHEN 'yes' THEN 1::smallint WHEN 'y' THEN 1::smallint WHEN 'false' THEN 0::smallint WHEN 'f' THEN 0::smallint WHEN '0' THEN 0::smallint WHEN 'no' THEN 0::smallint WHEN 'n' THEN 0::smallint ELSE NULL::smallint END; $function$;
ALTER FUNCTION hcbi_ras.try_boolean_smallint(text) OWNER TO hcbi_ras;

/* =====================================================================
   PROCEDURA STG INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_initialize(IN p_id_chain_log bigint,IN p_id_chain bigint,IN p_id_step bigint,IN p_ds_step_name character varying,OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,hcbi_ras,hcbi_utility AS $BODY$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0; v_updated bigint:=0; v_deleted bigint:=0; v_rec_errors bigint:=0;     v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN p_result:=-1; SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 TRUNCATE hcbi_ras.stg_anag_provincia,hcbi_ras.stg_anag_provincia_rej; SELECT count(*) INTO v_selected FROM hcbi_ras.v_src_tmp_anag_provincia;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name); p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_stg_anag_provincia_prc_initialize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_initialize(bigint,bigint,bigint,character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_initialize(bigint,bigint,bigint,character varying) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_initialize(bigint,bigint,bigint,character varying) IS 'Inizializza STG e REJ del flusso ANAG_PROVINCIA e conta i record sorgente.';

/* =====================================================================
   PROCEDURA STG MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_main(IN p_id_chain_log bigint,IN p_id_chain bigint,IN p_id_step bigint,IN p_ds_step_name character varying,OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,hcbi_ras,hcbi_utility AS $BODY$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0; v_updated bigint:=0; v_deleted bigint:=0; v_rec_errors bigint:=0;     v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN p_result:=-1; SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_anag_provincia_classificata; CREATE TABLE hcbi_ras.tmp_anag_provincia_classificata AS
 WITH src AS MATERIALIZED(SELECT f.anno anno_raw,f.addendum addendum_raw,f.id_sorgente_provincia id_sorgente_provincia_raw,f.cd_provincia cd_provincia_raw,f.ds_nome ds_nome_raw,f.id_sorgente_area_vasta id_sorgente_area_vasta_raw,f.fl_provincia_principale_regionale fl_provincia_principale_regionale_raw,f.fl_provincia_principale_area_vasta fl_provincia_principale_area_vasta_raw,nullif(btrim(f.anno),'') anno_txt,nullif(btrim(f.addendum),'') addendum_txt,nullif(btrim(f.id_sorgente_provincia),'') id_sorgente_provincia_txt,nullif(btrim(f.cd_provincia),'') cd_provincia_txt,nullif(btrim(f.ds_nome),'') ds_nome_txt,nullif(btrim(f.id_sorgente_area_vasta),'') id_sorgente_area_vasta_txt,nullif(btrim(f.fl_provincia_principale_regionale),'') fl_provincia_principale_regionale_txt,nullif(btrim(f.fl_provincia_principale_area_vasta),'') fl_provincia_principale_area_vasta_txt,count(*) OVER(
        PARTITION BY
            nullif(btrim(f.anno),''),
            nullif(btrim(f.addendum),''),
            nullif(btrim(f.cd_provincia),'')
      ) duplicate_count,
      count(*) OVER(
        PARTITION BY
            nullif(btrim(f.anno),''),
            nullif(btrim(f.addendum),''),
            nullif(btrim(f.id_sorgente_provincia),'')
      ) duplicate_source_count
  FROM hcbi_ras.v_src_tmp_anag_provincia f),
 cv AS MATERIALIZED(SELECT s.*,hcbi_ras.try_integer(anno_txt) anno_cv,hcbi_ras.try_integer(addendum_txt) addendum_cv,hcbi_ras.try_bigint(id_sorgente_provincia_txt) id_sorgente_provincia_cv,hcbi_ras.try_bigint(id_sorgente_area_vasta_txt) id_sorgente_area_vasta_cv,hcbi_ras.try_boolean_smallint(fl_provincia_principale_regionale_txt) fl_provincia_principale_regionale_cv,hcbi_ras.try_boolean_smallint(fl_provincia_principale_area_vasta_txt) fl_provincia_principale_area_vasta_cv FROM src s)
 SELECT c.*,CASE WHEN anno_txt IS NULL THEN 'anno obbligatorio' WHEN anno_cv IS NULL THEN 'anno non convertibile in integer' WHEN addendum_txt IS NULL THEN 'addendum obbligatorio' WHEN addendum_cv IS NULL THEN 'addendum non convertibile in integer' WHEN id_sorgente_provincia_txt IS NULL THEN 'id_sorgente_provincia obbligatorio' WHEN id_sorgente_provincia_cv IS NULL THEN 'id_sorgente_provincia non convertibile in bigint' WHEN duplicate_source_count>1 THEN 'Chiave operazionale duplicata: (anno, addendum, id_sorgente_provincia)' WHEN cd_provincia_txt IS NULL THEN 'cd_provincia obbligatorio' WHEN duplicate_count>1 THEN 'Chiave duplicata: (anno, addendum, cd_provincia)' WHEN length(cd_provincia_txt)>2 THEN 'cd_provincia eccede 2 caratteri' WHEN ds_nome_txt IS NULL THEN 'ds_nome obbligatorio' WHEN length(ds_nome_txt)>100 THEN 'ds_nome eccede 100 caratteri' WHEN id_sorgente_area_vasta_txt IS NOT NULL AND id_sorgente_area_vasta_cv IS NULL THEN 'id_sorgente_area_vasta non convertibile in bigint' WHEN fl_provincia_principale_regionale_txt IS NULL THEN 'fl_provincia_principale_regionale obbligatorio' WHEN fl_provincia_principale_regionale_cv IS NULL THEN 'fl_provincia_principale_regionale non convertibile in flag' WHEN fl_provincia_principale_area_vasta_txt IS NULL THEN 'fl_provincia_principale_area_vasta obbligatorio' WHEN fl_provincia_principale_area_vasta_cv IS NULL THEN 'fl_provincia_principale_area_vasta non convertibile in flag' ELSE NULL END::text tx_motivo_scarto FROM cv c;
 SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_anag_provincia_classificata;
 INSERT INTO hcbi_ras.stg_anag_provincia(anno,addendum,id_sorgente_provincia,cd_provincia,ds_nome,id_sorgente_area_vasta,fl_provincia_principale_regionale,fl_provincia_principale_area_vasta) SELECT anno_cv,addendum_cv,id_sorgente_provincia_cv,cd_provincia_txt,ds_nome_txt,id_sorgente_area_vasta_cv,fl_provincia_principale_regionale_cv,fl_provincia_principale_area_vasta_cv FROM hcbi_ras.tmp_anag_provincia_classificata WHERE tx_motivo_scarto IS NULL; GET DIAGNOSTICS v_inserted=ROW_COUNT;
 INSERT INTO hcbi_ras.stg_anag_provincia_rej(anno,addendum,id_sorgente_provincia,cd_provincia,ds_nome,id_sorgente_area_vasta,fl_provincia_principale_regionale,fl_provincia_principale_area_vasta,tx_motivo_scarto) SELECT anno_raw,addendum_raw,id_sorgente_provincia_raw,cd_provincia_raw,ds_nome_raw,id_sorgente_area_vasta_raw,fl_provincia_principale_regionale_raw,fl_provincia_principale_area_vasta_raw,tx_motivo_scarto FROM hcbi_ras.tmp_anag_provincia_classificata WHERE tx_motivo_scarto IS NOT NULL; GET DIAGNOSTICS v_rec_errors=ROW_COUNT;
 IF v_selected<>v_inserted+v_rec_errors THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE=format('Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',v_selected,v_inserted,v_rec_errors); END IF;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name); DROP TABLE hcbi_ras.tmp_anag_provincia_classificata; p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1; BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_anag_provincia_classificata; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_stg_anag_provincia_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_main(bigint,bigint,bigint,character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_main(bigint,bigint,bigint,character varying) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_main(bigint,bigint,bigint,character varying) IS 'Carica STG ANAG_PROVINCIA in modalita set-based, gestisce conversioni, flag, duplicati, scarti e riconciliazione.';

/* =====================================================================
   PROCEDURA STG FINALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_finalize(
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
    v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Finalizzazione PKG_STG_ANAG_PROVINCIA per lo step %',
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

    ANALYZE hcbi_ras.stg_anag_provincia;
    ANALYZE hcbi_ras.stg_anag_provincia_rej;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        0,
        0,
        0,
        0,
        0,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    p_result := 1;

EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_stg_anag_provincia_prc_finalize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_finalize(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_finalize(
    bigint,
    bigint,
    bigint,
    character varying
) TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA DWH INITIALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_provincia_prc_initialize(
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
    v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Inizializzazione PKG_DWH_ANAG_PROVINCIA per lo step %',
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

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        0,
        0,
        0,
        0,
        0,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    p_result := 1;

EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_dwh_anag_provincia_prc_initialize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_provincia_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_anag_provincia_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
) TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA DWH MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_provincia_prc_main(IN p_id_chain_log bigint,IN p_id_chain bigint,IN p_id_step bigint,IN p_ds_step_name character varying,OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,hcbi_ras,hcbi_utility AS $BODY$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0; v_updated bigint:=0; v_deleted bigint:=0; v_rec_errors bigint:=0;     v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN p_result:=-1; SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_provincia; CREATE TABLE hcbi_ras.tmp_dwh_anag_provincia AS SELECT anno,addendum,id_sorgente_provincia,cd_provincia,ds_nome,id_sorgente_area_vasta,fl_provincia_principale_regionale,fl_provincia_principale_area_vasta FROM hcbi_ras.v_dwh_anag_provincia;
 CREATE UNIQUE INDEX tmp_dwh_anag_provincia_uq ON hcbi_ras.tmp_dwh_anag_provincia(anno,addendum,cd_provincia) NULLS NOT DISTINCT;
 CREATE UNIQUE INDEX tmp_dwh_anag_provincia_sorgente_uq ON hcbi_ras.tmp_dwh_anag_provincia(anno,addendum,id_sorgente_provincia) NULLS NOT DISTINCT;
 ANALYZE hcbi_ras.tmp_dwh_anag_provincia; SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_dwh_anag_provincia;
 UPDATE hcbi_ras.dwh_anag_provincia d SET id_sorgente_provincia=src.id_sorgente_provincia,ds_nome=src.ds_nome,id_sorgente_area_vasta=src.id_sorgente_area_vasta,fl_provincia_principale_regionale=src.fl_provincia_principale_regionale,fl_provincia_principale_area_vasta=src.fl_provincia_principale_area_vasta,dt_update=clock_timestamp(),tx_update_by=p_ds_step_name FROM hcbi_ras.tmp_dwh_anag_provincia src WHERE d.anno=src.anno AND d.addendum=src.addendum AND d.cd_provincia=src.cd_provincia AND ROW(d.id_sorgente_provincia,d.ds_nome,d.id_sorgente_area_vasta,d.fl_provincia_principale_regionale,d.fl_provincia_principale_area_vasta) IS DISTINCT FROM ROW(src.id_sorgente_provincia,src.ds_nome,src.id_sorgente_area_vasta,src.fl_provincia_principale_regionale,src.fl_provincia_principale_area_vasta); GET DIAGNOSTICS v_updated=ROW_COUNT;
 INSERT INTO hcbi_ras.dwh_anag_provincia(anno,addendum,id_sorgente_provincia,cd_provincia,ds_nome,id_sorgente_area_vasta,fl_provincia_principale_regionale,fl_provincia_principale_area_vasta,dt_creation,tx_creation_by,dt_update,tx_update_by) SELECT anno,addendum,id_sorgente_provincia,cd_provincia,ds_nome,id_sorgente_area_vasta,fl_provincia_principale_regionale,fl_provincia_principale_area_vasta,clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name FROM hcbi_ras.tmp_dwh_anag_provincia ON CONFLICT ON CONSTRAINT uq_dwh_anag_provincia DO NOTHING; GET DIAGNOSTICS v_inserted=ROW_COUNT;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name); DROP TABLE hcbi_ras.tmp_dwh_anag_provincia; p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1; BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_provincia; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_dwh_anag_provincia_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_provincia_prc_main(bigint,bigint,bigint,character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_anag_provincia_prc_main(bigint,bigint,bigint,character varying) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_provincia_prc_main(bigint,bigint,bigint,character varying) IS 'Materializza la sorgente DWH, aggiorna le province variate, inserisce le nuove e pulisce la tabella di lavoro.';

/* =====================================================================
   PROCEDURA DWH FINALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_provincia_prc_finalize(
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
    v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Finalizzazione PKG_DWH_ANAG_PROVINCIA per lo step %',
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

    ANALYZE hcbi_ras.dwh_anag_provincia;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        0,
        0,
        0,
        0,
        0,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    p_result := 1;

EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_dwh_anag_provincia_prc_finalize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_provincia_prc_finalize(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_anag_provincia_prc_finalize(
    bigint,
    bigint,
    bigint,
    character varying
) TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   COMMENTI
   ===================================================================== */

COMMENT ON TABLE hcbi_ras.frontiera_anag_provincia
IS 'Frontiera del flusso ANAG_PROVINCIA';

COMMENT ON TABLE hcbi_ras.src_tmp_anag_provincia
IS 'Tabella temporanea sorgente del flusso ANAG_PROVINCIA';

COMMENT ON TABLE hcbi_ras.stg_anag_provincia
IS 'Staging del flusso ANAG_PROVINCIA';

COMMENT ON TABLE hcbi_ras.stg_anag_provincia_rej
IS 'Record scartati del flusso ANAG_PROVINCIA';

COMMENT ON TABLE hcbi_ras.dwh_anag_provincia
IS 'DWH del flusso ANAG_PROVINCIA';

COMMENT ON VIEW hcbi_ras.v_src_tmp_anag_provincia
IS 'Vista di conversione della sorgente temporanea ANAG_PROVINCIA';

COMMENT ON VIEW hcbi_ras.v_dwh_anag_provincia
IS 'Vista di raccordo tra STG_ANAG_PROVINCIA e DWH_ANAG_PROVINCIA';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_initialize(
    bigint, bigint, bigint, character varying
)
IS 'Inizializza le tabelle STG_ANAG_PROVINCIA e STG_ANAG_PROVINCIA_REJ, gestisce i duplicati e registra l''esecuzione nel log.';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_main(
    bigint, bigint, bigint, character varying
)
IS 'Converte e carica i dati nella tabella STG_ANAG_PROVINCIA registrando gli scarti nella tabella REJ.';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_provincia_prc_finalize(
    bigint, bigint, bigint, character varying
)
IS 'Finalizza il caricamento STG_ANAG_PROVINCIA e aggiorna le statistiche.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_provincia_prc_initialize(
    bigint, bigint, bigint, character varying
)
IS 'Inizializza il flusso DWH_ANAG_PROVINCIA e registra l''esecuzione nel log.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_provincia_prc_main(
    bigint, bigint, bigint, character varying
)
IS 'Carica DWH_ANAG_PROVINCIA dalla tabella STG aggiornando i record esistenti e inserendo i nuovi.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_provincia_prc_finalize(
    bigint, bigint, bigint, character varying
)
IS 'Finalizza il flusso DWH_ANAG_PROVINCIA e aggiorna le statistiche.';
COMMENT ON CONSTRAINT uq_dwh_anag_provincia ON hcbi_ras.dwh_anag_provincia IS 'Business key del flusso ANAG_PROVINCIA: anno, addendum, cd_provincia.';
COMMENT ON CONSTRAINT uq_dwh_anag_provincia_sorgente ON hcbi_ras.dwh_anag_provincia IS 'Chiave operazionale del flusso ANAG_PROVINCIA: anno, addendum, id_sorgente_provincia.';


/* =====================================================================
   QUERY DI ESTRAZIONE OPERAZIONALE
   ===================================================================== */
-- SELECT
--     p.id::character varying(100) AS id,
--     p.provincia,
--     p.nome,
--     p.id_area_vasta::character varying(20) AS id_area_vasta,
--     p.provincia_principale_regionale::character varying(20)
--         AS provincia_principale_regionale,
--     p.provincia_principale_area_vasta::character varying(20)
--         AS provincia_principale_area_vasta,
--     p.anno::character varying(20) AS anno,
--     p.addendum::character varying(20) AS addendum
-- FROM public.province AS p;


/* =====================================================================
   TEST CHIAVE OPERAZIONALE
   ===================================================================== */
/* Atteso: zero righe in STG. */
-- SELECT anno, addendum, id_sorgente_provincia, count(*) AS numero_record
-- FROM hcbi_ras.stg_anag_provincia
-- GROUP BY anno, addendum, id_sorgente_provincia
-- HAVING count(*) > 1;

/* Atteso: zero righe nel DWH. */
-- SELECT anno, addendum, id_sorgente_provincia, count(*) AS numero_record
-- FROM hcbi_ras.dwh_anag_provincia
-- GROUP BY anno, addendum, id_sorgente_provincia
-- HAVING count(*) > 1;
