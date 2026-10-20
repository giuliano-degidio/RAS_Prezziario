/* =====================================================================
   FLUSSO ANAG_TIPOLOGIA - VERSIONE UNIFORMATA CON PROVINCIA

   Target tecnico: PostgreSQL 15.9 / 17
   Pattern tecnico: PUBBLICAZIONE_ANALISI definitivo
   Sorgente logica:
       hcbi_ras.v_frontiera_anag_tipologia

   Tabella sorgente fisica:
       hcbi_ras.frontiera_anag_articolo

   Filtro sorgente:
       livello = '1'

   Query sorgente:
       SELECT DISTINCT
           anno,
           addendum,
           codice,
           nome,
           id_sorgente_provincia
       FROM hcbi_ras.frontiera_anag_articolo
       WHERE livello = '1'

   Mapping:
       anno     -> ds_anno
       addendum -> cd_versione
       codice   -> cd_tipologia
       nome     -> ds_tipologia
       id_sorgente_provincia -> id_sorgente_provincia

   Chiave logica:
       ds_anno,
       cd_tipologia,
       cd_versione,
       id_sorgente_provincia
   ===================================================================== */


/* =====================================================================
   SEQUENCE DWH
   ===================================================================== */

CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_anag_tipologia
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_anag_tipologia
    OWNER TO hcbi_ras;

GRANT ALL
ON SEQUENCE hcbi_ras.seq_dwh_anag_tipologia
TO hcbi_ras;

GRANT USAGE, SELECT
ON SEQUENCE hcbi_ras.seq_dwh_anag_tipologia
TO hcbi_utility;


/* =====================================================================
   VISTA FRONTIERA
   ===================================================================== */

CREATE OR REPLACE VIEW hcbi_ras.v_frontiera_anag_tipologia
AS
SELECT DISTINCT
    ar.anno,
    ar.addendum,
    ar.codice,
    ar.nome,
    ar.provincia
FROM hcbi_ras.frontiera_anag_articolo AS ar
WHERE TRIM(ar.livello::TEXT) = '1';

ALTER VIEW hcbi_ras.v_frontiera_anag_tipologia
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_frontiera_anag_tipologia
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_frontiera_anag_tipologia
TO hcbi_utility;


/* =====================================================================
   TABELLA SRC_TMP DERIVATA DA VIEW
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_anag_tipologia_vw
(
    anno        VARCHAR(100),
    addendum    VARCHAR(20),
    codice      VARCHAR(60),
    nome        TEXT,
    provincia VARCHAR(100)
);

ALTER TABLE hcbi_ras.src_tmp_anag_tipologia_vw
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.src_tmp_anag_tipologia_vw
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.src_tmp_anag_tipologia_vw
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.src_tmp_anag_tipologia_vw
TO hcbi_utility;


/* =====================================================================
   VISTA SRC_TMP
   ===================================================================== */

CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_anag_tipologia
AS
SELECT
    TRIM(s.anno::TEXT)
        AS ds_anno,

    TRIM(s.addendum::TEXT)
        AS cd_versione,

    TRIM(s.codice::TEXT)
        AS cd_tipologia,

    TRIM(s.nome::TEXT)
        AS ds_tipologia,

    TRIM(s.provincia::TEXT)
        AS id_sorgente_provincia

FROM hcbi_ras.src_tmp_anag_tipologia_vw AS s;

ALTER VIEW hcbi_ras.v_src_tmp_anag_tipologia
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_src_tmp_anag_tipologia
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_src_tmp_anag_tipologia
TO hcbi_utility;


/* =====================================================================
   TABELLA STG
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_tipologia
(
    ds_anno       INTEGER NOT NULL,
    cd_versione   SMALLINT NOT NULL,
    cd_tipologia  VARCHAR(60) NOT NULL,
    ds_tipologia  TEXT NOT NULL,
    id_sorgente_provincia BIGINT NOT NULL
);

ALTER TABLE hcbi_ras.stg_anag_tipologia
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.stg_anag_tipologia
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.stg_anag_tipologia
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_tipologia
TO hcbi_utility;


/* =====================================================================
   TABELLA STG REJECT
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_tipologia_rej
(
    ds_anno          VARCHAR(100),
    cd_versione      VARCHAR(20),
    cd_tipologia     VARCHAR(60),
    ds_tipologia     TEXT,
    id_sorgente_provincia VARCHAR(100),
    tx_motivo_scarto VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_tipologia_rej
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.stg_anag_tipologia_rej
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.stg_anag_tipologia_rej
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_tipologia_rej
TO hcbi_utility;


/* =====================================================================
   TABELLA DWH
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_anag_tipologia
(
    id_anag_tipologia BIGINT NOT NULL
        DEFAULT nextval(
            'hcbi_ras.seq_dwh_anag_tipologia'::REGCLASS
        ),

    ds_anno       INTEGER NOT NULL,
    cd_versione   SMALLINT NOT NULL,
    cd_tipologia  VARCHAR(60) NOT NULL,
    ds_tipologia  TEXT NOT NULL,
    id_sorgente_provincia BIGINT NOT NULL,

    dt_creation   TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT clock_timestamp(),

    tx_creation_by VARCHAR(4000)
        NOT NULL DEFAULT CURRENT_USER,

    dt_update     TIMESTAMP WITHOUT TIME ZONE
        NOT NULL DEFAULT clock_timestamp(),

    tx_update_by  VARCHAR(4000)
        NOT NULL DEFAULT CURRENT_USER,

    dt_reciclo    TIMESTAMP WITHOUT TIME ZONE,

    CONSTRAINT pk_dwh_anag_tipologia
        PRIMARY KEY (id_anag_tipologia),

    CONSTRAINT uq_dwh_anag_tipologia
        UNIQUE NULLS NOT DISTINCT
        (
            ds_anno,
            cd_tipologia,
            cd_versione,
            id_sorgente_provincia
        )
);

ALTER TABLE hcbi_ras.dwh_anag_tipologia
    OWNER TO hcbi_ras;

GRANT ALL
ON TABLE hcbi_ras.dwh_anag_tipologia
TO hcbi_ras;

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE hcbi_ras.dwh_anag_tipologia
TO hcbi_utility;


/* =====================================================================
   VISTA DWH
   ===================================================================== */

CREATE OR REPLACE VIEW hcbi_ras.v_dwh_anag_tipologia
AS
SELECT
    s.ds_anno,
    s.cd_versione,
    s.cd_tipologia,
    s.ds_tipologia,
    s.id_sorgente_provincia
FROM hcbi_ras.stg_anag_tipologia AS s;

ALTER VIEW hcbi_ras.v_dwh_anag_tipologia
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_dwh_anag_tipologia
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_dwh_anag_tipologia
TO hcbi_utility;


/* =====================================================================
   FUNZIONI DI CONVERSIONE SICURA
   ===================================================================== */
CREATE OR REPLACE FUNCTION hcbi_ras.try_integer(p_value text) RETURNS integer
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog
AS $function$ BEGIN RETURN p_value::integer; EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END; $function$;
ALTER FUNCTION hcbi_ras.try_integer(text) OWNER TO hcbi_ras;
CREATE OR REPLACE FUNCTION hcbi_ras.try_smallint(p_value text) RETURNS smallint
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog
AS $function$ BEGIN RETURN p_value::smallint; EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END; $function$;
ALTER FUNCTION hcbi_ras.try_smallint(text) OWNER TO hcbi_ras;
CREATE OR REPLACE FUNCTION hcbi_ras.try_bigint(p_value text) RETURNS bigint
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog
AS $function$ BEGIN RETURN p_value::bigint; EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END; $function$;
ALTER FUNCTION hcbi_ras.try_bigint(text) OWNER TO hcbi_ras;

/* =====================================================================
   PROCEDURA STG INITIALIZE
   */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_initialize(IN p_id_chain_log bigint,IN p_id_chain bigint,IN p_id_step bigint,IN p_ds_step_name character varying,OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,hcbi_ras,hcbi_utility AS $BODY$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0; v_updated bigint:=0; v_deleted bigint:=0; v_rec_errors bigint:=0;     v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 TRUNCATE hcbi_ras.src_tmp_anag_tipologia_vw,hcbi_ras.stg_anag_tipologia,hcbi_ras.stg_anag_tipologia_rej;
 INSERT INTO hcbi_ras.src_tmp_anag_tipologia_vw(anno,addendum,codice,nome,provincia)
 SELECT anno,addendum,codice,nome,provincia FROM hcbi_ras.v_frontiera_anag_tipologia;
 GET DIAGNOSTICS v_inserted=ROW_COUNT; v_selected:=v_inserted;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name); p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_stg_anag_tipologia_prc_initialize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_initialize(bigint,bigint,bigint,character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_initialize(bigint,bigint,bigint,character varying) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_initialize(bigint,bigint,bigint,character varying) IS 'Alimenta SRC_TMP dalla vista di frontiera includendo id_sorgente_provincia e inizializza STG e REJ.';

/* =====================================================================
   PROCEDURA STG MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_main(IN p_id_chain_log bigint,IN p_id_chain bigint,IN p_id_step bigint,IN p_ds_step_name character varying,OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,hcbi_ras,hcbi_utility AS $BODY$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0; v_updated bigint:=0; v_deleted bigint:=0; v_rec_errors bigint:=0;     v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_anag_tipologia_classificata;
 CREATE TABLE hcbi_ras.tmp_anag_tipologia_classificata AS
 WITH src AS MATERIALIZED(SELECT f.ds_anno ds_anno_raw,f.cd_versione cd_versione_raw,f.cd_tipologia cd_tipologia_raw,f.ds_tipologia ds_tipologia_raw,f.id_sorgente_provincia id_sorgente_provincia_raw,nullif(btrim(f.ds_anno),'') ds_anno_txt,nullif(btrim(f.cd_versione),'') cd_versione_txt,nullif(btrim(f.cd_tipologia),'') cd_tipologia_txt,nullif(btrim(f.ds_tipologia),'') ds_tipologia_txt,nullif(btrim(f.id_sorgente_provincia),'') id_sorgente_provincia_txt,count(*) OVER(PARTITION BY nullif(btrim(f.ds_anno),''),nullif(btrim(f.cd_tipologia),''),nullif(btrim(f.cd_versione),''),nullif(btrim(f.id_sorgente_provincia),'')) duplicate_count FROM hcbi_ras.v_src_tmp_anag_tipologia f),
 cv AS MATERIALIZED(SELECT s.*,hcbi_ras.try_integer(ds_anno_txt) ds_anno_cv,hcbi_ras.try_smallint(cd_versione_txt) cd_versione_cv,hcbi_ras.try_bigint(id_sorgente_provincia_txt) id_sorgente_provincia_cv FROM src s)
 SELECT c.*,CASE WHEN duplicate_count>1 THEN 'Chiave duplicata: (ds_anno, cd_tipologia, cd_versione, id_sorgente_provincia)' WHEN ds_anno_txt IS NULL THEN 'ds_anno obbligatorio' WHEN ds_anno_cv IS NULL THEN 'ds_anno non convertibile' WHEN cd_versione_txt IS NULL THEN 'cd_versione obbligatorio' WHEN cd_versione_cv IS NULL THEN 'cd_versione non convertibile' WHEN cd_tipologia_txt IS NULL THEN 'cd_tipologia obbligatorio' WHEN length(cd_tipologia_txt)>60 THEN 'cd_tipologia eccede 60 caratteri' WHEN ds_tipologia_txt IS NULL THEN 'ds_tipologia obbligatorio' WHEN id_sorgente_provincia_txt IS NULL THEN 'id_sorgente_provincia obbligatorio' WHEN id_sorgente_provincia_cv IS NULL THEN 'id_sorgente_provincia non convertibile in bigint' ELSE NULL END::text tx_motivo_scarto FROM cv c;
 SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_anag_tipologia_classificata;
 INSERT INTO hcbi_ras.stg_anag_tipologia(ds_anno,cd_versione,cd_tipologia,ds_tipologia,id_sorgente_provincia) SELECT ds_anno_cv,cd_versione_cv,cd_tipologia_txt,ds_tipologia_txt,id_sorgente_provincia_cv FROM hcbi_ras.tmp_anag_tipologia_classificata WHERE tx_motivo_scarto IS NULL; GET DIAGNOSTICS v_inserted=ROW_COUNT;
 INSERT INTO hcbi_ras.stg_anag_tipologia_rej(ds_anno,cd_versione,cd_tipologia,ds_tipologia,id_sorgente_provincia,tx_motivo_scarto) SELECT ds_anno_raw,cd_versione_raw,cd_tipologia_raw,ds_tipologia_raw,id_sorgente_provincia_raw,tx_motivo_scarto FROM hcbi_ras.tmp_anag_tipologia_classificata WHERE tx_motivo_scarto IS NOT NULL; GET DIAGNOSTICS v_rec_errors=ROW_COUNT;
 IF v_selected<>v_inserted+v_rec_errors THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE=format('Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',v_selected,v_inserted,v_rec_errors); END IF;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name); DROP TABLE hcbi_ras.tmp_anag_tipologia_classificata; p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1; BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_anag_tipologia_classificata; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_stg_anag_tipologia_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_main(bigint,bigint,bigint,character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_main(bigint,bigint,bigint,character varying) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_main(bigint,bigint,bigint,character varying) IS 'Carica STG in modalita set-based includendo la provincia nella business key, gestisce scarti e riconciliazione.';

/* =====================================================================
   PROCEDURA STG FINALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_finalize(
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
    v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Finalizzazione PKG_STG_ANAG_TIPOLOGIA per lo step %',
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

    ANALYZE hcbi_ras.src_tmp_anag_tipologia_vw;
    ANALYZE hcbi_ras.stg_anag_tipologia;
    ANALYZE hcbi_ras.stg_anag_tipologia_rej;

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

EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_stg_anag_tipologia_prc_finalize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA DWH INITIALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_tipologia_prc_initialize(
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
    v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Inizializzazione PKG_DWH_ANAG_TIPOLOGIA per lo step %',
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

EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_dwh_anag_tipologia_prc_initialize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_tipologia_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_tipologia_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA DWH MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_tipologia_prc_main(IN p_id_chain_log bigint,IN p_id_chain bigint,IN p_id_step bigint,IN p_ds_step_name character varying,OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,hcbi_ras,hcbi_utility AS $BODY$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0; v_updated bigint:=0; v_deleted bigint:=0; v_rec_errors bigint:=0;     v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN p_result:=-1; SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_tipologia; CREATE TABLE hcbi_ras.tmp_dwh_anag_tipologia AS SELECT ds_anno,cd_versione,cd_tipologia,ds_tipologia,id_sorgente_provincia FROM hcbi_ras.v_dwh_anag_tipologia;
 CREATE UNIQUE INDEX tmp_dwh_anag_tipologia_uq ON hcbi_ras.tmp_dwh_anag_tipologia(ds_anno,cd_tipologia,cd_versione,id_sorgente_provincia) NULLS NOT DISTINCT; ANALYZE hcbi_ras.tmp_dwh_anag_tipologia; SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_dwh_anag_tipologia;
 UPDATE hcbi_ras.dwh_anag_tipologia d SET ds_tipologia=t.ds_tipologia,dt_update=clock_timestamp(),tx_update_by=p_ds_step_name FROM hcbi_ras.tmp_dwh_anag_tipologia t WHERE d.ds_anno=t.ds_anno AND d.cd_tipologia=t.cd_tipologia AND d.cd_versione=t.cd_versione AND d.id_sorgente_provincia=t.id_sorgente_provincia AND d.ds_tipologia IS DISTINCT FROM t.ds_tipologia; GET DIAGNOSTICS v_updated=ROW_COUNT;
 INSERT INTO hcbi_ras.dwh_anag_tipologia(ds_anno,cd_versione,cd_tipologia,ds_tipologia,id_sorgente_provincia,dt_creation,tx_creation_by,dt_update,tx_update_by) SELECT ds_anno,cd_versione,cd_tipologia,ds_tipologia,id_sorgente_provincia,clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name FROM hcbi_ras.tmp_dwh_anag_tipologia ON CONFLICT ON CONSTRAINT uq_dwh_anag_tipologia DO NOTHING; GET DIAGNOSTICS v_inserted=ROW_COUNT;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name); DROP TABLE hcbi_ras.tmp_dwh_anag_tipologia; p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1; BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_tipologia; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_dwh_anag_tipologia_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_tipologia_prc_main(bigint,bigint,bigint,character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_anag_tipologia_prc_main(bigint,bigint,bigint,character varying) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_tipologia_prc_main(bigint,bigint,bigint,character varying) IS 'Materializza il DWH e usa la provincia come componente della business key.';

/* =====================================================================
   PROCEDURA DWH FINALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_tipologia_prc_finalize(
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
    v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Finalizzazione PKG_DWH_ANAG_TIPOLOGIA per lo step %',
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

    ANALYZE hcbi_ras.dwh_anag_tipologia;

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

EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_dwh_anag_tipologia_prc_finalize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_tipologia_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_tipologia_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   COMMENTI
   ===================================================================== */

COMMENT ON VIEW hcbi_ras.v_frontiera_anag_tipologia
IS 'Vista di frontiera del flusso ANAG_TIPOLOGIA ottenuta dagli articoli di livello 1.';

COMMENT ON TABLE hcbi_ras.src_tmp_anag_tipologia_vw
IS 'Tabella temporanea del flusso ANAG_TIPOLOGIA alimentata dalla vista di frontiera.';

COMMENT ON TABLE hcbi_ras.stg_anag_tipologia
IS 'Staging del flusso ANAG_TIPOLOGIA';

COMMENT ON TABLE hcbi_ras.stg_anag_tipologia_rej
IS 'Record scartati del flusso ANAG_TIPOLOGIA';

COMMENT ON TABLE hcbi_ras.dwh_anag_tipologia
IS 'DWH del flusso ANAG_TIPOLOGIA';

COMMENT ON VIEW hcbi_ras.v_src_tmp_anag_tipologia
IS 'Vista di conversione della tabella temporanea ANAG_TIPOLOGIA.';

COMMENT ON VIEW hcbi_ras.v_dwh_anag_tipologia
IS 'Vista di raccordo tra STG_ANAG_TIPOLOGIA e DWH_ANAG_TIPOLOGIA.';

COMMENT ON COLUMN hcbi_ras.stg_anag_tipologia.ds_anno
IS 'Anno della tipologia.';

COMMENT ON COLUMN hcbi_ras.stg_anag_tipologia.cd_versione
IS 'Addendum/versione della tipologia.';

COMMENT ON COLUMN hcbi_ras.stg_anag_tipologia.cd_tipologia
IS 'Codice della tipologia.';

COMMENT ON COLUMN hcbi_ras.stg_anag_tipologia.ds_tipologia
IS 'Descrizione della tipologia.';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Alimenta la tabella temporanea dalla vista di frontiera, inizializza le tabelle STG e REJ e identifica i duplicati logici.';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_main(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Converte e carica i dati nella tabella STG_ANAG_TIPOLOGIA registrando gli scarti nella tabella REJ.';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_tipologia_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Finalizza il caricamento STG_ANAG_TIPOLOGIA e aggiorna le statistiche.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_tipologia_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Inizializza il flusso DWH_ANAG_TIPOLOGIA e registra l''esecuzione nel log.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_tipologia_prc_main(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Carica DWH_ANAG_TIPOLOGIA dalla tabella STG aggiornando i record esistenti e inserendo i nuovi.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_tipologia_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Finalizza il flusso DWH_ANAG_TIPOLOGIA e aggiorna le statistiche.';
COMMENT ON COLUMN hcbi_ras.stg_anag_tipologia.id_sorgente_provincia IS 'Identificativo sorgente della provincia letto da frontiera_anag_articolo.';
COMMENT ON COLUMN hcbi_ras.dwh_anag_tipologia.id_sorgente_provincia IS 'Identificativo sorgente della provincia e componente della business key.';
COMMENT ON CONSTRAINT uq_dwh_anag_tipologia ON hcbi_ras.dwh_anag_tipologia IS 'Business key: ds_anno, cd_tipologia, cd_versione, id_sorgente_provincia.';
