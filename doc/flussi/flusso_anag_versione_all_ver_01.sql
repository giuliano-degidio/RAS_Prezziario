/* =====================================================================
   FLUSSO ANAG_VERSIONE - VERSIONE UNIFORMATA CON PROVINCIA

   Target tecnico: PostgreSQL 15.9 / 17
   Pattern tecnico: PUBBLICAZIONE_ANALISI definitivo
   Sorgente:
       public.anni

   Tabella frontiera:
       hcbi_ras.frontiera_anni

   Chiave logica:
       ds_anno_pubblicazione,
       cd_versione,
       id_sorgente_provincia

   Nota:
       i campi booleani nei livelli STG e DWH sono rappresentati come:

           0 = FALSE
           1 = TRUE

       I seguenti campi vengono acquisiti in frontiera e SRC_TMP, ma
       non vengono trasferiti nei livelli STG, REJ, DWH e nelle viste:

           llpp_homepage_title_de
           llpp_homepage_description_de
           preferenze_esportazione
           impostazioni_prezzi
   ===================================================================== */


/* =====================================================================
   SEQUENCE
   ===================================================================== */

CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_anag_versione
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_anag_versione
    OWNER TO hcbi_ras;

GRANT ALL
ON SEQUENCE hcbi_ras.seq_dwh_anag_versione
TO hcbi_ras;

GRANT USAGE, SELECT
ON SEQUENCE hcbi_ras.seq_dwh_anag_versione
TO hcbi_utility;


/* =====================================================================
   TABELLA FRONTIERA
   ===================================================================== */

-- Table: hcbi_ras.frontiera_anni

-- DROP TABLE IF EXISTS hcbi_ras.frontiera_anni;

CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_anni
(
    anno character varying(100) COLLATE pg_catalog."default",
    addendum character varying(20) COLLATE pg_catalog."default",
    addendum_name text COLLATE pg_catalog."default",
    scostamento_1_visibile character varying(20) COLLATE pg_catalog."default",
    scostamento_2_visibile character varying(20) COLLATE pg_catalog."default",
    scostamento_3_visibile character varying(20) COLLATE pg_catalog."default",
    scostamento_4_visibile character varying(20) COLLATE pg_catalog."default",
    spese_generali character varying(100) COLLATE pg_catalog."default",
    utile_impresa character varying(100) COLLATE pg_catalog."default",
    llpp_homepage_title text COLLATE pg_catalog."default",
    llpp_homepage_description text COLLATE pg_catalog."default",
    di_cui_analisi character varying(100) COLLATE pg_catalog."default",
    pubblicazione_regionale character varying(20) COLLATE pg_catalog."default",
    llpp_homepage_title_de text COLLATE pg_catalog."default",
    llpp_homepage_description_de text COLLATE pg_catalog."default",
    scostamento_5_visibile character varying(20) COLLATE pg_catalog."default",
    preferenze_esportazione text COLLATE pg_catalog."default",
    id character varying(100) COLLATE pg_catalog."default",
    impostazioni_prezzi text COLLATE pg_catalog."default",
    mostra_annotazioni character varying(20) COLLATE pg_catalog."default",
    mostra_struttura_analisi character varying(20) COLLATE pg_catalog."default",
    is_errata_corrige character varying(20) COLLATE pg_catalog."default",
    mostra_cam character varying(20) COLLATE pg_catalog."default",
    id_sorgente_provincia numeric NOT NULL DEFAULT 0
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.frontiera_anni
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.frontiera_anni FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.frontiera_anni TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.frontiera_anni TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.frontiera_anni
    IS 'Frontiera del flusso ANAG_VERSIONE';


/* =====================================================================
   TABELLA SRC_TMP
   ===================================================================== */
-- Table: hcbi_ras.src_tmp_anag_versione

-- DROP TABLE IF EXISTS hcbi_ras.src_tmp_anag_versione;

CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_anag_versione
(
    anno character varying(100) COLLATE pg_catalog."default",
    addendum character varying(20) COLLATE pg_catalog."default",
    addendum_name text COLLATE pg_catalog."default",
    scostamento_1_visibile character varying(20) COLLATE pg_catalog."default",
    scostamento_2_visibile character varying(20) COLLATE pg_catalog."default",
    scostamento_3_visibile character varying(20) COLLATE pg_catalog."default",
    scostamento_4_visibile character varying(20) COLLATE pg_catalog."default",
    spese_generali character varying(100) COLLATE pg_catalog."default",
    utile_impresa character varying(100) COLLATE pg_catalog."default",
    llpp_homepage_title text COLLATE pg_catalog."default",
    llpp_homepage_description text COLLATE pg_catalog."default",
    di_cui_analisi character varying(100) COLLATE pg_catalog."default",
    pubblicazione_regionale character varying(20) COLLATE pg_catalog."default",
    llpp_homepage_title_de text COLLATE pg_catalog."default",
    llpp_homepage_description_de text COLLATE pg_catalog."default",
    scostamento_5_visibile character varying(20) COLLATE pg_catalog."default",
    preferenze_esportazione text COLLATE pg_catalog."default",
    id character varying(100) COLLATE pg_catalog."default",
    impostazioni_prezzi text COLLATE pg_catalog."default",
    mostra_annotazioni character varying(20) COLLATE pg_catalog."default",
    mostra_struttura_analisi character varying(20) COLLATE pg_catalog."default",
    is_errata_corrige character varying(20) COLLATE pg_catalog."default",
    mostra_cam character varying(20) COLLATE pg_catalog."default",
    provincia character varying(20) COLLATE pg_catalog."default" DEFAULT '0'::character varying
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.src_tmp_anag_versione
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.src_tmp_anag_versione FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.src_tmp_anag_versione TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.src_tmp_anag_versione TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.src_tmp_anag_versione
    IS 'Tabella temporanea sorgente del flusso ANAG_VERSIONE';

/* =====================================================================
   VISTA SRC_TMP
   ===================================================================== */
-- View: hcbi_ras.v_src_tmp_anag_versione

-- DROP VIEW hcbi_ras.v_src_tmp_anag_versione;

CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_anag_versione
 AS
 SELECT TRIM(BOTH FROM s.anno::text) AS ds_anno_pubblicazione,
    TRIM(BOTH FROM s.addendum::text) AS cd_versione,
    TRIM(BOTH FROM s.addendum_name) AS ds_versione,
    TRIM(BOTH FROM s.scostamento_1_visibile::text) AS fl_scostamento_1_visibile,
    TRIM(BOTH FROM s.scostamento_2_visibile::text) AS fl_scostamento_2_visibile,
    TRIM(BOTH FROM s.scostamento_3_visibile::text) AS fl_scostamento_3_visibile,
    TRIM(BOTH FROM s.scostamento_4_visibile::text) AS fl_scostamento_4_visibile,
    TRIM(BOTH FROM s.spese_generali::text) AS nr_spese_generali,
    TRIM(BOTH FROM s.utile_impresa::text) AS nr_utile_impresa,
    TRIM(BOTH FROM s.llpp_homepage_title) AS ds_llpp_homepage_title,
    TRIM(BOTH FROM s.llpp_homepage_description) AS ds_llpp_homepage_description,
    TRIM(BOTH FROM s.di_cui_analisi::text) AS nr_di_cui_analisi,
    TRIM(BOTH FROM s.pubblicazione_regionale::text) AS fl_pubblicazione_regionale,
    TRIM(BOTH FROM s.scostamento_5_visibile::text) AS fl_scostamento_5_visibile,
    TRIM(BOTH FROM s.id::text) AS id_sorgente_versione,
    TRIM(BOTH FROM s.mostra_annotazioni::text) AS fl_mostra_annotazioni,
    TRIM(BOTH FROM s.mostra_struttura_analisi::text) AS fl_mostra_struttura_analisi,
    TRIM(BOTH FROM s.is_errata_corrige::text) AS fl_is_errata_corrige,
    TRIM(BOTH FROM s.mostra_cam::text) AS fl_mostra_cam,
    TRIM(BOTH FROM s.provincia::text) AS id_sorgente_provincia
   FROM hcbi_ras.src_tmp_anag_versione s;

ALTER TABLE hcbi_ras.v_src_tmp_anag_versione
    OWNER TO hcbi_ras;
COMMENT ON VIEW hcbi_ras.v_src_tmp_anag_versione
    IS 'Vista di conversione della sorgente temporanea ANAG_VERSIONE';

GRANT ALL ON TABLE hcbi_ras.v_src_tmp_anag_versione TO hcbi_ras;
GRANT SELECT ON TABLE hcbi_ras.v_src_tmp_anag_versione TO hcbi_utility;


/* =====================================================================
   TABELLA STG
   ===================================================================== */
-- Table: hcbi_ras.stg_anag_versione

-- DROP TABLE IF EXISTS hcbi_ras.stg_anag_versione;

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_versione
(
    ds_anno_pubblicazione integer NOT NULL,
    cd_versione smallint NOT NULL,
    ds_versione text COLLATE pg_catalog."default",
    fl_scostamento_1_visibile smallint NOT NULL,
    fl_scostamento_2_visibile smallint NOT NULL,
    fl_scostamento_3_visibile smallint NOT NULL,
    fl_scostamento_4_visibile smallint NOT NULL,
    fl_scostamento_5_visibile smallint NOT NULL,
    nr_spese_generali numeric(10,5) NOT NULL,
    nr_utile_impresa numeric(10,5) NOT NULL,
    nr_di_cui_analisi numeric(10,5) NOT NULL,
    ds_llpp_homepage_title text COLLATE pg_catalog."default",
    ds_llpp_homepage_description text COLLATE pg_catalog."default",
    fl_pubblicazione_regionale smallint NOT NULL,
    id_sorgente_versione bigint NOT NULL,
    fl_mostra_annotazioni smallint NOT NULL,
    fl_mostra_struttura_analisi smallint NOT NULL,
    fl_is_errata_corrige smallint NOT NULL,
    fl_mostra_cam smallint NOT NULL,
    id_sorgente_provincia numeric(10,0) NOT NULL DEFAULT 0
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.stg_anag_versione
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.stg_anag_versione FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.stg_anag_versione TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.stg_anag_versione TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.stg_anag_versione
    IS 'Staging del flusso ANAG_VERSIONE';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.ds_anno_pubblicazione
    IS 'Anno della versione';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.cd_versione
    IS 'Addendum/versione';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.ds_versione
    IS 'Descrizione della versione';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_scostamento_1_visibile
    IS 'Indicatore scostamento 1: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_scostamento_2_visibile
    IS 'Indicatore scostamento 2: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_scostamento_3_visibile
    IS 'Indicatore scostamento 3: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_scostamento_4_visibile
    IS 'Indicatore scostamento 4: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_scostamento_5_visibile
    IS 'Indicatore scostamento 5: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_pubblicazione_regionale
    IS 'Indicatore pubblicazione regionale: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.id_sorgente_versione
    IS 'Identificativo della versione nella sorgente operazionale';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_is_errata_corrige
    IS 'Indicatore errata corrige: 0 falso, 1 vero';
/* =====================================================================
   TABELLA STG REJECT
   ===================================================================== */
-- Table: hcbi_ras.stg_anag_versione_rej

-- DROP TABLE IF EXISTS hcbi_ras.stg_anag_versione_rej;

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_versione_rej
(
    ds_anno_pubblicazione character varying(100) COLLATE pg_catalog."default",
    cd_versione character varying(20) COLLATE pg_catalog."default",
    ds_versione text COLLATE pg_catalog."default",
    fl_scostamento_1_visibile character varying(20) COLLATE pg_catalog."default",
    fl_scostamento_2_visibile character varying(20) COLLATE pg_catalog."default",
    fl_scostamento_3_visibile character varying(20) COLLATE pg_catalog."default",
    fl_scostamento_4_visibile character varying(20) COLLATE pg_catalog."default",
    fl_scostamento_5_visibile character varying(20) COLLATE pg_catalog."default",
    nr_spese_generali character varying(100) COLLATE pg_catalog."default",
    nr_utile_impresa character varying(100) COLLATE pg_catalog."default",
    nr_di_cui_analisi character varying(100) COLLATE pg_catalog."default",
    ds_llpp_homepage_title text COLLATE pg_catalog."default",
    ds_llpp_homepage_description text COLLATE pg_catalog."default",
    fl_pubblicazione_regionale character varying(20) COLLATE pg_catalog."default",
    id_sorgente_versione character varying(100) COLLATE pg_catalog."default",
    fl_mostra_annotazioni character varying(20) COLLATE pg_catalog."default",
    fl_mostra_struttura_analisi character varying(20) COLLATE pg_catalog."default",
    fl_is_errata_corrige character varying(20) COLLATE pg_catalog."default",
    fl_mostra_cam character varying(20) COLLATE pg_catalog."default",
    tx_motivo_scarto character varying(4000) COLLATE pg_catalog."default",
    id_sorgente_provincia character varying(20) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.stg_anag_versione_rej
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.stg_anag_versione_rej FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.stg_anag_versione_rej TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.stg_anag_versione_rej TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.stg_anag_versione_rej
    IS 'Record scartati del flusso ANAG_VERSIONE';
	
/* =====================================================================
   TABELLA DWH
   ===================================================================== */

-- Table: hcbi_ras.dwh_anag_versione

-- DROP TABLE IF EXISTS hcbi_ras.dwh_anag_versione;

CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_anag_versione
(
    id_anag_versione bigint NOT NULL DEFAULT nextval('hcbi_ras.seq_dwh_anag_versione'::regclass),
    ds_anno_pubblicazione integer NOT NULL,
    cd_versione smallint NOT NULL,
    ds_versione text COLLATE pg_catalog."default",
    fl_scostamento_1_visibile smallint NOT NULL,
    fl_scostamento_2_visibile smallint NOT NULL,
    fl_scostamento_3_visibile smallint NOT NULL,
    fl_scostamento_4_visibile smallint NOT NULL,
    fl_scostamento_5_visibile smallint NOT NULL,
    nr_spese_generali numeric(10,5) NOT NULL,
    nr_utile_impresa numeric(10,5) NOT NULL,
    nr_di_cui_analisi numeric(10,5) NOT NULL,
    ds_llpp_homepage_title text COLLATE pg_catalog."default",
    ds_llpp_homepage_description text COLLATE pg_catalog."default",
    fl_pubblicazione_regionale smallint NOT NULL,
    id_sorgente_versione bigint NOT NULL,
    fl_mostra_annotazioni smallint NOT NULL,
    fl_mostra_struttura_analisi smallint NOT NULL,
    fl_is_errata_corrige smallint NOT NULL,
    fl_mostra_cam smallint NOT NULL,
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by character varying(4000) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by character varying(4000) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
    dt_reciclo timestamp without time zone,
    id_sorgente_provincia numeric(10,0) NOT NULL DEFAULT 0,
    CONSTRAINT pk_dwh_anag_versione PRIMARY KEY (id_anag_versione),
    CONSTRAINT uq_dwh_anag_versione UNIQUE NULLS NOT DISTINCT (ds_anno_pubblicazione, cd_versione, id_sorgente_provincia)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dwh_anag_versione
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.dwh_anag_versione FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.dwh_anag_versione TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.dwh_anag_versione TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dwh_anag_versione
    IS 'DWH del flusso ANAG_VERSIONE';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_1_visibile
    IS 'Indicatore scostamento 1: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_2_visibile
    IS 'Indicatore scostamento 2: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_3_visibile
    IS 'Indicatore scostamento 3: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_4_visibile
    IS 'Indicatore scostamento 4: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_5_visibile
    IS 'Indicatore scostamento 5: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_pubblicazione_regionale
    IS 'Indicatore pubblicazione regionale: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_is_errata_corrige
    IS 'Indicatore errata corrige: 0 falso, 1 vero';
/* =====================================================================
   VISTA DWH
   ===================================================================== */
-- View: hcbi_ras.v_dwh_anag_versione

-- DROP VIEW hcbi_ras.v_dwh_anag_versione;

CREATE OR REPLACE VIEW hcbi_ras.v_dwh_anag_versione
 AS
 SELECT s.ds_anno_pubblicazione,
    s.cd_versione,
    s.ds_versione,
    s.fl_scostamento_1_visibile,
    s.fl_scostamento_2_visibile,
    s.fl_scostamento_3_visibile,
    s.fl_scostamento_4_visibile,
    s.fl_scostamento_5_visibile,
    s.nr_spese_generali,
    s.nr_utile_impresa,
    s.nr_di_cui_analisi,
    s.ds_llpp_homepage_title,
    s.ds_llpp_homepage_description,
    s.fl_pubblicazione_regionale,
    s.id_sorgente_versione,
    s.fl_mostra_annotazioni,
    s.fl_mostra_struttura_analisi,
    s.fl_is_errata_corrige,
    s.fl_mostra_cam,
    s.id_sorgente_provincia
   FROM hcbi_ras.stg_anag_versione s;

ALTER TABLE hcbi_ras.v_dwh_anag_versione
    OWNER TO hcbi_ras;
COMMENT ON VIEW hcbi_ras.v_dwh_anag_versione
    IS 'Vista di raccordo tra STG_ANAG_VERSIONE e DWH_ANAG_VERSIONE';

GRANT ALL ON TABLE hcbi_ras.v_dwh_anag_versione TO hcbi_ras;
GRANT SELECT ON TABLE hcbi_ras.v_dwh_anag_versione TO hcbi_utility;


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
CREATE OR REPLACE FUNCTION hcbi_ras.try_numeric_10_0(p_value text) RETURNS numeric(10,0)
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog
AS $function$ BEGIN RETURN p_value::numeric(10,0); EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END; $function$;
ALTER FUNCTION hcbi_ras.try_numeric_10_0(text) OWNER TO hcbi_ras;
CREATE OR REPLACE FUNCTION hcbi_ras.try_numeric_10_5(p_value text) RETURNS numeric(10,5)
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog
AS $function$ BEGIN RETURN replace(p_value,',','.')::numeric(10,5); EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END; $function$;
ALTER FUNCTION hcbi_ras.try_numeric_10_5(text) OWNER TO hcbi_ras;
CREATE OR REPLACE FUNCTION hcbi_ras.try_boolean_smallint(p_value text) RETURNS smallint
LANGUAGE sql IMMUTABLE PARALLEL SAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog
AS $function$ SELECT CASE lower(btrim(p_value)) WHEN 'true' THEN 1::smallint WHEN 't' THEN 1::smallint WHEN '1' THEN 1::smallint WHEN 'yes' THEN 1::smallint WHEN 'y' THEN 1::smallint WHEN 'false' THEN 0::smallint WHEN 'f' THEN 0::smallint WHEN '0' THEN 0::smallint WHEN 'no' THEN 0::smallint WHEN 'n' THEN 0::smallint ELSE NULL::smallint END; $function$;
ALTER FUNCTION hcbi_ras.try_boolean_smallint(text) OWNER TO hcbi_ras;

/* =====================================================================
   PROCEDURA STG INITIALIZE
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_initialize(IN p_id_chain_log bigint,IN p_id_chain bigint,IN p_id_step bigint,IN p_ds_step_name character varying,OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,hcbi_ras,hcbi_utility AS $BODY$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0; v_updated bigint:=0; v_deleted bigint:=0; v_rec_errors bigint:=0;     v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN p_result:=-1; SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 TRUNCATE hcbi_ras.stg_anag_versione,hcbi_ras.stg_anag_versione_rej; SELECT count(*) INTO v_selected FROM hcbi_ras.v_src_tmp_anag_versione;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name); p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_stg_anag_versione_prc_initialize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_initialize(bigint,bigint,bigint,character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_initialize(bigint,bigint,bigint,character varying) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_initialize(bigint,bigint,bigint,character varying) IS 'Inizializza STG e REJ del flusso ANAG_VERSIONE e conta i record sorgente.';

/* =====================================================================
   PROCEDURA STG MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_main(IN p_id_chain_log bigint,IN p_id_chain bigint,IN p_id_step bigint,IN p_ds_step_name character varying,OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,hcbi_ras,hcbi_utility AS $BODY$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0; v_updated bigint:=0; v_deleted bigint:=0; v_rec_errors bigint:=0;     v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN p_result:=-1; SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_anag_versione_classificata;
 CREATE TABLE hcbi_ras.tmp_anag_versione_classificata AS WITH src AS MATERIALIZED(SELECT
            f.ds_anno_pubblicazione AS ds_anno_pubblicazione_raw,
            f.cd_versione AS cd_versione_raw,
            f.ds_versione AS ds_versione_raw,
            f.fl_scostamento_1_visibile AS fl_scostamento_1_visibile_raw,
            f.fl_scostamento_2_visibile AS fl_scostamento_2_visibile_raw,
            f.fl_scostamento_3_visibile AS fl_scostamento_3_visibile_raw,
            f.fl_scostamento_4_visibile AS fl_scostamento_4_visibile_raw,
            f.fl_scostamento_5_visibile AS fl_scostamento_5_visibile_raw,
            f.nr_spese_generali AS nr_spese_generali_raw,
            f.nr_utile_impresa AS nr_utile_impresa_raw,
            f.nr_di_cui_analisi AS nr_di_cui_analisi_raw,
            f.ds_llpp_homepage_title AS ds_llpp_homepage_title_raw,
            f.ds_llpp_homepage_description AS ds_llpp_homepage_description_raw,
            f.fl_pubblicazione_regionale AS fl_pubblicazione_regionale_raw,
            f.id_sorgente_versione AS id_sorgente_versione_raw,
            f.fl_mostra_annotazioni AS fl_mostra_annotazioni_raw,
            f.fl_mostra_struttura_analisi AS fl_mostra_struttura_analisi_raw,
            f.fl_is_errata_corrige AS fl_is_errata_corrige_raw,
            f.fl_mostra_cam AS fl_mostra_cam_raw,
            f.id_sorgente_provincia AS id_sorgente_provincia_raw,
            nullif(btrim(f.ds_anno_pubblicazione::text), '') AS ds_anno_pubblicazione_txt,
            nullif(btrim(f.cd_versione::text), '') AS cd_versione_txt,
            nullif(btrim(f.ds_versione::text), '') AS ds_versione_txt,
            nullif(btrim(f.fl_scostamento_1_visibile::text), '') AS fl_scostamento_1_visibile_txt,
            nullif(btrim(f.fl_scostamento_2_visibile::text), '') AS fl_scostamento_2_visibile_txt,
            nullif(btrim(f.fl_scostamento_3_visibile::text), '') AS fl_scostamento_3_visibile_txt,
            nullif(btrim(f.fl_scostamento_4_visibile::text), '') AS fl_scostamento_4_visibile_txt,
            nullif(btrim(f.fl_scostamento_5_visibile::text), '') AS fl_scostamento_5_visibile_txt,
            nullif(btrim(f.nr_spese_generali::text), '') AS nr_spese_generali_txt,
            nullif(btrim(f.nr_utile_impresa::text), '') AS nr_utile_impresa_txt,
            nullif(btrim(f.nr_di_cui_analisi::text), '') AS nr_di_cui_analisi_txt,
            nullif(btrim(f.ds_llpp_homepage_title::text), '') AS ds_llpp_homepage_title_txt,
            nullif(btrim(f.ds_llpp_homepage_description::text), '') AS ds_llpp_homepage_description_txt,
            nullif(btrim(f.fl_pubblicazione_regionale::text), '') AS fl_pubblicazione_regionale_txt,
            nullif(btrim(f.id_sorgente_versione::text), '') AS id_sorgente_versione_txt,
            nullif(btrim(f.fl_mostra_annotazioni::text), '') AS fl_mostra_annotazioni_txt,
            nullif(btrim(f.fl_mostra_struttura_analisi::text), '') AS fl_mostra_struttura_analisi_txt,
            nullif(btrim(f.fl_is_errata_corrige::text), '') AS fl_is_errata_corrige_txt,
            nullif(btrim(f.fl_mostra_cam::text), '') AS fl_mostra_cam_txt,
            nullif(btrim(f.id_sorgente_provincia::text), '') AS id_sorgente_provincia_txt,
            count(*) OVER(PARTITION BY nullif(btrim(f.ds_anno_pubblicazione),''),nullif(btrim(f.cd_versione),''),nullif(btrim(f.id_sorgente_provincia),'')) duplicate_count
 FROM hcbi_ras.v_src_tmp_anag_versione f), converted AS MATERIALIZED(SELECT s.*,
            hcbi_ras.try_integer(s.ds_anno_pubblicazione_txt) AS ds_anno_pubblicazione_cv,
            hcbi_ras.try_smallint(s.cd_versione_txt) AS cd_versione_cv,
            hcbi_ras.try_boolean_smallint(s.fl_scostamento_1_visibile_txt) AS fl_scostamento_1_visibile_cv,
            hcbi_ras.try_boolean_smallint(s.fl_scostamento_2_visibile_txt) AS fl_scostamento_2_visibile_cv,
            hcbi_ras.try_boolean_smallint(s.fl_scostamento_3_visibile_txt) AS fl_scostamento_3_visibile_cv,
            hcbi_ras.try_boolean_smallint(s.fl_scostamento_4_visibile_txt) AS fl_scostamento_4_visibile_cv,
            hcbi_ras.try_boolean_smallint(s.fl_scostamento_5_visibile_txt) AS fl_scostamento_5_visibile_cv,
            hcbi_ras.try_numeric_10_5(s.nr_spese_generali_txt) AS nr_spese_generali_cv,
            hcbi_ras.try_numeric_10_5(s.nr_utile_impresa_txt) AS nr_utile_impresa_cv,
            hcbi_ras.try_numeric_10_5(s.nr_di_cui_analisi_txt) AS nr_di_cui_analisi_cv,
            hcbi_ras.try_boolean_smallint(s.fl_pubblicazione_regionale_txt) AS fl_pubblicazione_regionale_cv,
            hcbi_ras.try_bigint(s.id_sorgente_versione_txt) AS id_sorgente_versione_cv,
            hcbi_ras.try_boolean_smallint(s.fl_mostra_annotazioni_txt) AS fl_mostra_annotazioni_cv,
            hcbi_ras.try_boolean_smallint(s.fl_mostra_struttura_analisi_txt) AS fl_mostra_struttura_analisi_cv,
            hcbi_ras.try_boolean_smallint(s.fl_is_errata_corrige_txt) AS fl_is_errata_corrige_cv,
            hcbi_ras.try_boolean_smallint(s.fl_mostra_cam_txt) AS fl_mostra_cam_cv,
            hcbi_ras.try_numeric_10_0(s.id_sorgente_provincia_txt) AS id_sorgente_provincia_cv
 FROM src s) SELECT c.*,CASE
            WHEN c.duplicate_count > 1 THEN 'Chiave duplicata: (ds_anno_pubblicazione, cd_versione, id_sorgente_provincia)'
            WHEN c.ds_anno_pubblicazione_txt IS NULL THEN 'ds_anno_pubblicazione obbligatorio'
            WHEN c.ds_anno_pubblicazione_txt IS NOT NULL AND c.ds_anno_pubblicazione_cv IS NULL THEN 'ds_anno_pubblicazione non convertibile o fuori dominio'
            WHEN c.cd_versione_txt IS NULL THEN 'cd_versione obbligatorio'
            WHEN c.cd_versione_txt IS NOT NULL AND c.cd_versione_cv IS NULL THEN 'cd_versione non convertibile o fuori dominio'
            WHEN c.fl_scostamento_1_visibile_txt IS NULL THEN 'fl_scostamento_1_visibile obbligatorio'
            WHEN c.fl_scostamento_1_visibile_txt IS NOT NULL AND c.fl_scostamento_1_visibile_cv IS NULL THEN 'fl_scostamento_1_visibile non convertibile o fuori dominio'
            WHEN c.fl_scostamento_2_visibile_txt IS NULL THEN 'fl_scostamento_2_visibile obbligatorio'
            WHEN c.fl_scostamento_2_visibile_txt IS NOT NULL AND c.fl_scostamento_2_visibile_cv IS NULL THEN 'fl_scostamento_2_visibile non convertibile o fuori dominio'
            WHEN c.fl_scostamento_3_visibile_txt IS NULL THEN 'fl_scostamento_3_visibile obbligatorio'
            WHEN c.fl_scostamento_3_visibile_txt IS NOT NULL AND c.fl_scostamento_3_visibile_cv IS NULL THEN 'fl_scostamento_3_visibile non convertibile o fuori dominio'
            WHEN c.fl_scostamento_4_visibile_txt IS NULL THEN 'fl_scostamento_4_visibile obbligatorio'
            WHEN c.fl_scostamento_4_visibile_txt IS NOT NULL AND c.fl_scostamento_4_visibile_cv IS NULL THEN 'fl_scostamento_4_visibile non convertibile o fuori dominio'
            WHEN c.fl_scostamento_5_visibile_txt IS NULL THEN 'fl_scostamento_5_visibile obbligatorio'
            WHEN c.fl_scostamento_5_visibile_txt IS NOT NULL AND c.fl_scostamento_5_visibile_cv IS NULL THEN 'fl_scostamento_5_visibile non convertibile o fuori dominio'
            WHEN c.nr_spese_generali_txt IS NULL THEN 'nr_spese_generali obbligatorio'
            WHEN c.nr_spese_generali_txt IS NOT NULL AND c.nr_spese_generali_cv IS NULL THEN 'nr_spese_generali non convertibile o fuori dominio'
            WHEN c.nr_utile_impresa_txt IS NULL THEN 'nr_utile_impresa obbligatorio'
            WHEN c.nr_utile_impresa_txt IS NOT NULL AND c.nr_utile_impresa_cv IS NULL THEN 'nr_utile_impresa non convertibile o fuori dominio'
            WHEN c.nr_di_cui_analisi_txt IS NULL THEN 'nr_di_cui_analisi obbligatorio'
            WHEN c.nr_di_cui_analisi_txt IS NOT NULL AND c.nr_di_cui_analisi_cv IS NULL THEN 'nr_di_cui_analisi non convertibile o fuori dominio'
            WHEN c.fl_pubblicazione_regionale_txt IS NULL THEN 'fl_pubblicazione_regionale obbligatorio'
            WHEN c.fl_pubblicazione_regionale_txt IS NOT NULL AND c.fl_pubblicazione_regionale_cv IS NULL THEN 'fl_pubblicazione_regionale non convertibile o fuori dominio'
            WHEN c.id_sorgente_versione_txt IS NULL THEN 'id_sorgente_versione obbligatorio'
            WHEN c.id_sorgente_versione_txt IS NOT NULL AND c.id_sorgente_versione_cv IS NULL THEN 'id_sorgente_versione non convertibile o fuori dominio'
            WHEN c.fl_mostra_annotazioni_txt IS NULL THEN 'fl_mostra_annotazioni obbligatorio'
            WHEN c.fl_mostra_annotazioni_txt IS NOT NULL AND c.fl_mostra_annotazioni_cv IS NULL THEN 'fl_mostra_annotazioni non convertibile o fuori dominio'
            WHEN c.fl_mostra_struttura_analisi_txt IS NULL THEN 'fl_mostra_struttura_analisi obbligatorio'
            WHEN c.fl_mostra_struttura_analisi_txt IS NOT NULL AND c.fl_mostra_struttura_analisi_cv IS NULL THEN 'fl_mostra_struttura_analisi non convertibile o fuori dominio'
            WHEN c.fl_is_errata_corrige_txt IS NULL THEN 'fl_is_errata_corrige obbligatorio'
            WHEN c.fl_is_errata_corrige_txt IS NOT NULL AND c.fl_is_errata_corrige_cv IS NULL THEN 'fl_is_errata_corrige non convertibile o fuori dominio'
            WHEN c.fl_mostra_cam_txt IS NULL THEN 'fl_mostra_cam obbligatorio'
            WHEN c.fl_mostra_cam_txt IS NOT NULL AND c.fl_mostra_cam_cv IS NULL THEN 'fl_mostra_cam non convertibile o fuori dominio'
            WHEN c.id_sorgente_provincia_txt IS NULL THEN 'id_sorgente_provincia obbligatorio'
            WHEN c.id_sorgente_provincia_txt IS NOT NULL AND c.id_sorgente_provincia_cv IS NULL THEN 'id_sorgente_provincia non convertibile o fuori dominio'
            ELSE NULL END::text tx_motivo_scarto FROM converted c;
 SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_anag_versione_classificata;
 INSERT INTO hcbi_ras.stg_anag_versione(ds_anno_pubblicazione,cd_versione,ds_versione,fl_scostamento_1_visibile,fl_scostamento_2_visibile,fl_scostamento_3_visibile,fl_scostamento_4_visibile,fl_scostamento_5_visibile,nr_spese_generali,nr_utile_impresa,nr_di_cui_analisi,ds_llpp_homepage_title,ds_llpp_homepage_description,fl_pubblicazione_regionale,id_sorgente_versione,fl_mostra_annotazioni,fl_mostra_struttura_analisi,fl_is_errata_corrige,fl_mostra_cam,id_sorgente_provincia) SELECT
        c.ds_anno_pubblicazione_cv,
        c.cd_versione_cv,
        c.ds_versione_txt,
        c.fl_scostamento_1_visibile_cv,
        c.fl_scostamento_2_visibile_cv,
        c.fl_scostamento_3_visibile_cv,
        c.fl_scostamento_4_visibile_cv,
        c.fl_scostamento_5_visibile_cv,
        c.nr_spese_generali_cv,
        c.nr_utile_impresa_cv,
        c.nr_di_cui_analisi_cv,
        c.ds_llpp_homepage_title_txt,
        c.ds_llpp_homepage_description_txt,
        c.fl_pubblicazione_regionale_cv,
        c.id_sorgente_versione_cv,
        c.fl_mostra_annotazioni_cv,
        c.fl_mostra_struttura_analisi_cv,
        c.fl_is_errata_corrige_cv,
        c.fl_mostra_cam_cv,
        c.id_sorgente_provincia_cv
 FROM hcbi_ras.tmp_anag_versione_classificata c WHERE tx_motivo_scarto IS NULL; GET DIAGNOSTICS v_inserted=ROW_COUNT;
 INSERT INTO hcbi_ras.stg_anag_versione_rej(ds_anno_pubblicazione,cd_versione,ds_versione,fl_scostamento_1_visibile,fl_scostamento_2_visibile,fl_scostamento_3_visibile,fl_scostamento_4_visibile,fl_scostamento_5_visibile,nr_spese_generali,nr_utile_impresa,nr_di_cui_analisi,ds_llpp_homepage_title,ds_llpp_homepage_description,fl_pubblicazione_regionale,id_sorgente_versione,fl_mostra_annotazioni,fl_mostra_struttura_analisi,fl_is_errata_corrige,fl_mostra_cam,id_sorgente_provincia,tx_motivo_scarto) SELECT
        c.ds_anno_pubblicazione_raw,
        c.cd_versione_raw,
        c.ds_versione_raw,
        c.fl_scostamento_1_visibile_raw,
        c.fl_scostamento_2_visibile_raw,
        c.fl_scostamento_3_visibile_raw,
        c.fl_scostamento_4_visibile_raw,
        c.fl_scostamento_5_visibile_raw,
        c.nr_spese_generali_raw,
        c.nr_utile_impresa_raw,
        c.nr_di_cui_analisi_raw,
        c.ds_llpp_homepage_title_raw,
        c.ds_llpp_homepage_description_raw,
        c.fl_pubblicazione_regionale_raw,
        c.id_sorgente_versione_raw,
        c.fl_mostra_annotazioni_raw,
        c.fl_mostra_struttura_analisi_raw,
        c.fl_is_errata_corrige_raw,
        c.fl_mostra_cam_raw,
        c.id_sorgente_provincia_raw,
        c.tx_motivo_scarto FROM hcbi_ras.tmp_anag_versione_classificata c WHERE tx_motivo_scarto IS NOT NULL; GET DIAGNOSTICS v_rec_errors=ROW_COUNT;
 IF v_selected<>v_inserted+v_rec_errors THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE=format('Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',v_selected,v_inserted,v_rec_errors); END IF;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name); DROP TABLE hcbi_ras.tmp_anag_versione_classificata; p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1; BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_anag_versione_classificata; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_stg_anag_versione_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_main(bigint,bigint,bigint,character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_main(bigint,bigint,bigint,character varying) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_main(bigint,bigint,bigint,character varying) IS 'Carica STG ANAG_VERSIONE in modalita set-based includendo la provincia nella business key, gestisce conversioni, scarti e riconciliazione.';

/* =====================================================================
   PROCEDURA STG FINALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_finalize(
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
        'Finalizzazione PKG_STG_ANAG_VERSIONE per lo step %',
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

    ANALYZE hcbi_ras.stg_anag_versione;
    ANALYZE hcbi_ras.stg_anag_versione_rej;

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
 RAISE WARNING 'Errore in pkg_stg_anag_versione_prc_finalize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA DWH INITIALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_initialize(
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
        'Inizializzazione PKG_DWH_ANAG_VERSIONE per lo step %',
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
 RAISE WARNING 'Errore in pkg_dwh_anag_versione_prc_initialize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA DWH MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_main(IN p_id_chain_log bigint,IN p_id_chain bigint,IN p_id_step bigint,IN p_ds_step_name character varying,OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,hcbi_ras,hcbi_utility AS $BODY$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0; v_updated bigint:=0; v_deleted bigint:=0; v_rec_errors bigint:=0;     v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN p_result:=-1; SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_versione; CREATE TABLE hcbi_ras.tmp_dwh_anag_versione AS SELECT ds_anno_pubblicazione,cd_versione,ds_versione,fl_scostamento_1_visibile,fl_scostamento_2_visibile,fl_scostamento_3_visibile,fl_scostamento_4_visibile,fl_scostamento_5_visibile,nr_spese_generali,nr_utile_impresa,nr_di_cui_analisi,ds_llpp_homepage_title,ds_llpp_homepage_description,fl_pubblicazione_regionale,id_sorgente_versione,fl_mostra_annotazioni,fl_mostra_struttura_analisi,fl_is_errata_corrige,fl_mostra_cam,id_sorgente_provincia FROM hcbi_ras.v_dwh_anag_versione;
 CREATE UNIQUE INDEX tmp_dwh_anag_versione_uq ON hcbi_ras.tmp_dwh_anag_versione(ds_anno_pubblicazione,cd_versione,id_sorgente_provincia) NULLS NOT DISTINCT; ANALYZE hcbi_ras.tmp_dwh_anag_versione; SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_dwh_anag_versione;
 UPDATE hcbi_ras.dwh_anag_versione d SET ds_versione=src.ds_versione,
       fl_scostamento_1_visibile=src.fl_scostamento_1_visibile,
       fl_scostamento_2_visibile=src.fl_scostamento_2_visibile,
       fl_scostamento_3_visibile=src.fl_scostamento_3_visibile,
       fl_scostamento_4_visibile=src.fl_scostamento_4_visibile,
       fl_scostamento_5_visibile=src.fl_scostamento_5_visibile,
       nr_spese_generali=src.nr_spese_generali,
       nr_utile_impresa=src.nr_utile_impresa,
       nr_di_cui_analisi=src.nr_di_cui_analisi,
       ds_llpp_homepage_title=src.ds_llpp_homepage_title,
       ds_llpp_homepage_description=src.ds_llpp_homepage_description,
       fl_pubblicazione_regionale=src.fl_pubblicazione_regionale,
       id_sorgente_versione=src.id_sorgente_versione,
       fl_mostra_annotazioni=src.fl_mostra_annotazioni,
       fl_mostra_struttura_analisi=src.fl_mostra_struttura_analisi,
       fl_is_errata_corrige=src.fl_is_errata_corrige,
       fl_mostra_cam=src.fl_mostra_cam,dt_update=clock_timestamp(),tx_update_by=p_ds_step_name FROM hcbi_ras.tmp_dwh_anag_versione src WHERE d.ds_anno_pubblicazione=src.ds_anno_pubblicazione AND d.cd_versione=src.cd_versione AND d.id_sorgente_provincia=src.id_sorgente_provincia AND (d.ds_versione IS DISTINCT FROM src.ds_versione
       OR d.fl_scostamento_1_visibile IS DISTINCT FROM src.fl_scostamento_1_visibile
       OR d.fl_scostamento_2_visibile IS DISTINCT FROM src.fl_scostamento_2_visibile
       OR d.fl_scostamento_3_visibile IS DISTINCT FROM src.fl_scostamento_3_visibile
       OR d.fl_scostamento_4_visibile IS DISTINCT FROM src.fl_scostamento_4_visibile
       OR d.fl_scostamento_5_visibile IS DISTINCT FROM src.fl_scostamento_5_visibile
       OR d.nr_spese_generali IS DISTINCT FROM src.nr_spese_generali
       OR d.nr_utile_impresa IS DISTINCT FROM src.nr_utile_impresa
       OR d.nr_di_cui_analisi IS DISTINCT FROM src.nr_di_cui_analisi
       OR d.ds_llpp_homepage_title IS DISTINCT FROM src.ds_llpp_homepage_title
       OR d.ds_llpp_homepage_description IS DISTINCT FROM src.ds_llpp_homepage_description
       OR d.fl_pubblicazione_regionale IS DISTINCT FROM src.fl_pubblicazione_regionale
       OR d.id_sorgente_versione IS DISTINCT FROM src.id_sorgente_versione
       OR d.fl_mostra_annotazioni IS DISTINCT FROM src.fl_mostra_annotazioni
       OR d.fl_mostra_struttura_analisi IS DISTINCT FROM src.fl_mostra_struttura_analisi
       OR d.fl_is_errata_corrige IS DISTINCT FROM src.fl_is_errata_corrige
       OR d.fl_mostra_cam IS DISTINCT FROM src.fl_mostra_cam); GET DIAGNOSTICS v_updated=ROW_COUNT;
 INSERT INTO hcbi_ras.dwh_anag_versione(ds_anno_pubblicazione,cd_versione,ds_versione,fl_scostamento_1_visibile,fl_scostamento_2_visibile,fl_scostamento_3_visibile,fl_scostamento_4_visibile,fl_scostamento_5_visibile,nr_spese_generali,nr_utile_impresa,nr_di_cui_analisi,ds_llpp_homepage_title,ds_llpp_homepage_description,fl_pubblicazione_regionale,id_sorgente_versione,fl_mostra_annotazioni,fl_mostra_struttura_analisi,fl_is_errata_corrige,fl_mostra_cam,id_sorgente_provincia,dt_creation,tx_creation_by,dt_update,tx_update_by) SELECT src.ds_anno_pubblicazione,src.cd_versione,src.ds_versione,src.fl_scostamento_1_visibile,src.fl_scostamento_2_visibile,src.fl_scostamento_3_visibile,src.fl_scostamento_4_visibile,src.fl_scostamento_5_visibile,src.nr_spese_generali,src.nr_utile_impresa,src.nr_di_cui_analisi,src.ds_llpp_homepage_title,src.ds_llpp_homepage_description,src.fl_pubblicazione_regionale,src.id_sorgente_versione,src.fl_mostra_annotazioni,src.fl_mostra_struttura_analisi,src.fl_is_errata_corrige,src.fl_mostra_cam,src.id_sorgente_provincia,clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name FROM hcbi_ras.tmp_dwh_anag_versione src ON CONFLICT ON CONSTRAINT uq_dwh_anag_versione DO NOTHING; GET DIAGNOSTICS v_inserted=ROW_COUNT;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name); DROP TABLE hcbi_ras.tmp_dwh_anag_versione; p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1; BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_versione; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_dwh_anag_versione_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_main(bigint,bigint,bigint,character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_main(bigint,bigint,bigint,character varying) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_main(bigint,bigint,bigint,character varying) IS 'Materializza la sorgente DWH, usa anno-versione-provincia come business key, aggiorna i record variati e inserisce i nuovi.';

/* =====================================================================
   PROCEDURA DWH FINALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_finalize(
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
        'Finalizzazione PKG_DWH_ANAG_VERSIONE per lo step %',
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

    ANALYZE hcbi_ras.dwh_anag_versione;

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
 RAISE WARNING 'Errore in pkg_dwh_anag_versione_prc_finalize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   COMMENTI
   ===================================================================== */

COMMENT ON TABLE hcbi_ras.frontiera_anni
IS 'Frontiera del flusso ANAG_VERSIONE';

COMMENT ON TABLE hcbi_ras.src_tmp_anag_versione
IS 'Tabella temporanea sorgente del flusso ANAG_VERSIONE';

COMMENT ON TABLE hcbi_ras.stg_anag_versione
IS 'Staging del flusso ANAG_VERSIONE';

COMMENT ON TABLE hcbi_ras.stg_anag_versione_rej
IS 'Record scartati del flusso ANAG_VERSIONE';

COMMENT ON TABLE hcbi_ras.dwh_anag_versione
IS 'DWH del flusso ANAG_VERSIONE';

COMMENT ON VIEW hcbi_ras.v_src_tmp_anag_versione
IS 'Vista di conversione della sorgente temporanea ANAG_VERSIONE';

COMMENT ON VIEW hcbi_ras.v_dwh_anag_versione
IS 'Vista di raccordo tra STG_ANAG_VERSIONE e DWH_ANAG_VERSIONE';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.ds_anno_pubblicazione
IS 'Anno della versione';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.cd_versione
IS 'Addendum/versione';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.id_sorgente_versione
IS 'Identificativo della versione nella sorgente operazionale';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.ds_versione
IS 'Descrizione della versione';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_scostamento_1_visibile
IS 'Indicatore scostamento 1: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_scostamento_2_visibile
IS 'Indicatore scostamento 2: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_scostamento_3_visibile
IS 'Indicatore scostamento 3: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_scostamento_4_visibile
IS 'Indicatore scostamento 4: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_scostamento_5_visibile
IS 'Indicatore scostamento 5: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_pubblicazione_regionale
IS 'Indicatore pubblicazione regionale: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_versione.fl_is_errata_corrige
IS 'Indicatore errata corrige: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_1_visibile
IS 'Indicatore scostamento 1: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_2_visibile
IS 'Indicatore scostamento 2: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_3_visibile
IS 'Indicatore scostamento 3: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_4_visibile
IS 'Indicatore scostamento 4: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_scostamento_5_visibile
IS 'Indicatore scostamento 5: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_pubblicazione_regionale
IS 'Indicatore pubblicazione regionale: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.fl_is_errata_corrige
IS 'Indicatore errata corrige: 0 falso, 1 vero';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Inizializza le tabelle STG_ANAG_VERSIONE e STG_ANAG_VERSIONE_REJ, gestisce i duplicati e registra l''esecuzione nel log.';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_main(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Converte e carica i dati nella tabella STG_ANAG_VERSIONE, convertendo i booleani in 0/1 e registrando gli scarti nella tabella REJ.';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Finalizza il caricamento STG_ANAG_VERSIONE e aggiorna le statistiche.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Inizializza il flusso DWH_ANAG_VERSIONE e registra l''esecuzione nel log.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_main(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Carica DWH_ANAG_VERSIONE dalla tabella STG aggiornando i record esistenti e inserendo i nuovi.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_versione_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Finalizza il flusso DWH_ANAG_VERSIONE e aggiorna le statistiche.';
COMMENT ON COLUMN hcbi_ras.stg_anag_versione.id_sorgente_provincia IS 'Identificativo sorgente della provincia e componente della business key.';
COMMENT ON COLUMN hcbi_ras.dwh_anag_versione.id_sorgente_provincia IS 'Identificativo sorgente della provincia e componente della business key.';
COMMENT ON CONSTRAINT uq_dwh_anag_versione ON hcbi_ras.dwh_anag_versione IS 'Business key: ds_anno_pubblicazione, cd_versione, id_sorgente_provincia.';
