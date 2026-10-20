/* =====================================================================
   FLUSSO ANAG_ARTICOLO

   Sorgente:
       public.articoli

   Chiave logica per la gestione dei duplicati:
       anno,
       codice,
       addendum

   Mapping chiave:
       anno     -> ds_anno
       codice   -> cd_articolo
       addendum -> cd_versione

   Note:
       - last_update è di tipo TIMESTAMP anche in FRONTIERA e SRC_TMP;
       - i campi incidenza e link_cam sono esclusi;
       - i campi booleani esporta_come_articolo ed
         escludi_manodopera sono rappresentati come SMALLINT nei livelli
         STG e DWH:
             0 = FALSE
             1 = TRUE
   ===================================================================== */


/* =====================================================================
   SEQUENCE DWH
   ===================================================================== */

CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_anag_articolo
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_anag_articolo
    OWNER TO hcbi_ras;

GRANT ALL
ON SEQUENCE hcbi_ras.seq_dwh_anag_articolo
TO hcbi_ras;

GRANT USAGE, SELECT
ON SEQUENCE hcbi_ras.seq_dwh_anag_articolo
TO hcbi_utility;


/* =====================================================================
   TABELLA FRONTIERA
   ===================================================================== */

-- Table: hcbi_ras.frontiera_anag_articolo

-- DROP TABLE IF EXISTS hcbi_ras.frontiera_anag_articolo;

CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_anag_articolo
(
    id character varying(100) COLLATE pg_catalog."default",
    anno character varying(100) COLLATE pg_catalog."default",
    codice character varying(60) COLLATE pg_catalog."default",
    livello character varying(20) COLLATE pg_catalog."default",
    nome text COLLATE pg_catalog."default",
    descrizione text COLLATE pg_catalog."default",
    eliminato character varying(20) COLLATE pg_catalog."default",
    prezzo_regionale character varying(20) COLLATE pg_catalog."default",
    unita_misura character varying(100) COLLATE pg_catalog."default",
    macro_gruppo character varying(20) COLLATE pg_catalog."default",
    spese_generali character varying(100) COLLATE pg_catalog."default",
    di_cui_analisi character varying(100) COLLATE pg_catalog."default",
    utile_impresa character varying(100) COLLATE pg_catalog."default",
    last_update timestamp without time zone,
    analisi_approvata character varying(20) COLLATE pg_catalog."default",
    has_utile_impresa character varying(20) COLLATE pg_catalog."default",
    analisi_pubblicata character varying(20) COLLATE pg_catalog."default",
    addendum character varying(20) COLLATE pg_catalog."default",
    is_analisi character varying(20) COLLATE pg_catalog."default",
    is_cam character varying(20) COLLATE pg_catalog."default",
    is_ufficiale character varying(20) COLLATE pg_catalog."default",
    id_categoria character varying(100) COLLATE pg_catalog."default",
    is_manodopera character varying(20) COLLATE pg_catalog."default",
    codice_lev1 character varying(60) COLLATE pg_catalog."default",
    codice_lev2 character varying(60) COLLATE pg_catalog."default",
    codice_lev3 character varying(60) COLLATE pg_catalog."default",
    codice_lev4 character varying(60) COLLATE pg_catalog."default",
    codice_lev5 character varying(60) COLLATE pg_catalog."default",
    is_minuteria character varying(20) COLLATE pg_catalog."default",
    percentuale_aumento character varying(100) COLLATE pg_catalog."default",
    annotazione text COLLATE pg_catalog."default",
    esporta_come_articolo character varying(20) COLLATE pg_catalog."default",
    escludi_manodopera character varying(20) COLLATE pg_catalog."default",
    provincia character varying(20) COLLATE pg_catalog."default" DEFAULT '0'::character varying
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.frontiera_anag_articolo
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.frontiera_anag_articolo FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.frontiera_anag_articolo TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.frontiera_anag_articolo TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.frontiera_anag_articolo
    IS 'Frontiera del flusso ANAG_ARTICOLO';

COMMENT ON COLUMN hcbi_ras.frontiera_anag_articolo.provincia
    IS 'Colonna aggiunta manualmente dallo sviluppo ETL, in attesa che venga implementata nel DB operazionale.';


/* =====================================================================
   TABELLA SRC_TMP
   ===================================================================== */

-- Table: hcbi_ras.src_tmp_anag_articolo

-- DROP TABLE IF EXISTS hcbi_ras.src_tmp_anag_articolo;

CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_anag_articolo
(
    id character varying(100) COLLATE pg_catalog."default",
    anno character varying(100) COLLATE pg_catalog."default",
    codice character varying(60) COLLATE pg_catalog."default",
    livello character varying(20) COLLATE pg_catalog."default",
    nome text COLLATE pg_catalog."default",
    descrizione text COLLATE pg_catalog."default",
    eliminato character varying(20) COLLATE pg_catalog."default",
    prezzo_regionale character varying(20) COLLATE pg_catalog."default",
    unita_misura character varying(100) COLLATE pg_catalog."default",
    macro_gruppo character varying(20) COLLATE pg_catalog."default",
    spese_generali character varying(100) COLLATE pg_catalog."default",
    di_cui_analisi character varying(100) COLLATE pg_catalog."default",
    utile_impresa character varying(100) COLLATE pg_catalog."default",
    last_update timestamp without time zone,
    analisi_approvata character varying(20) COLLATE pg_catalog."default",
    has_utile_impresa character varying(20) COLLATE pg_catalog."default",
    analisi_pubblicata character varying(20) COLLATE pg_catalog."default",
    addendum character varying(20) COLLATE pg_catalog."default",
    is_analisi character varying(20) COLLATE pg_catalog."default",
    is_cam character varying(20) COLLATE pg_catalog."default",
    is_ufficiale character varying(20) COLLATE pg_catalog."default",
    id_categoria character varying(100) COLLATE pg_catalog."default",
    is_manodopera character varying(20) COLLATE pg_catalog."default",
    codice_lev1 character varying(60) COLLATE pg_catalog."default",
    codice_lev2 character varying(60) COLLATE pg_catalog."default",
    codice_lev3 character varying(60) COLLATE pg_catalog."default",
    codice_lev4 character varying(60) COLLATE pg_catalog."default",
    codice_lev5 character varying(60) COLLATE pg_catalog."default",
    is_minuteria character varying(20) COLLATE pg_catalog."default",
    percentuale_aumento character varying(100) COLLATE pg_catalog."default",
    annotazione text COLLATE pg_catalog."default",
    esporta_come_articolo character varying(20) COLLATE pg_catalog."default",
    escludi_manodopera character varying(20) COLLATE pg_catalog."default",
    provincia character varying(20) COLLATE pg_catalog."default" DEFAULT '0'::character varying
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.src_tmp_anag_articolo
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.src_tmp_anag_articolo FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.src_tmp_anag_articolo TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.src_tmp_anag_articolo TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.src_tmp_anag_articolo
    IS 'Tabella temporanea sorgente del flusso ANAG_ARTICOLO';

COMMENT ON COLUMN hcbi_ras.src_tmp_anag_articolo.provincia
    IS 'Colonna aggiunta manualmente dallo sviluppo ETL, in attesa che venga implementata nel DB operazionale.';

/* =====================================================================
   VISTA SRC_TMP
   ===================================================================== */
-- View: hcbi_ras.v_src_tmp_anag_articolo

-- DROP VIEW hcbi_ras.v_src_tmp_anag_articolo;

CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_anag_articolo
 AS
 SELECT TRIM(BOTH FROM s.id::text) AS id_sorgente_articolo,
    TRIM(BOTH FROM s.anno::text) AS ds_anno,
    TRIM(BOTH FROM s.codice::text) AS cd_articolo,
    TRIM(BOTH FROM s.livello::text) AS nr_livello,
    TRIM(BOTH FROM s.nome) AS ds_nome,
    TRIM(BOTH FROM s.descrizione) AS ds_descrizione,
    TRIM(BOTH FROM s.eliminato::text) AS fl_eliminato,
    TRIM(BOTH FROM s.prezzo_regionale::text) AS fl_prezzo_regionale,
    TRIM(BOTH FROM s.unita_misura::text) AS ds_unita_misura,
    TRIM(BOTH FROM s.macro_gruppo::text) AS nr_macro_gruppo,
    TRIM(BOTH FROM s.spese_generali::text) AS nr_spese_generali,
    TRIM(BOTH FROM s.di_cui_analisi::text) AS nr_di_cui_analisi,
    TRIM(BOTH FROM s.utile_impresa::text) AS nr_utile_impresa,
    s.last_update AS dt_last_update,
    TRIM(BOTH FROM s.analisi_approvata::text) AS fl_analisi_approvata,
    TRIM(BOTH FROM s.has_utile_impresa::text) AS fl_has_utile_impresa,
    TRIM(BOTH FROM s.analisi_pubblicata::text) AS fl_analisi_pubblicata,
    TRIM(BOTH FROM s.addendum::text) AS cd_versione,
    TRIM(BOTH FROM s.is_analisi::text) AS fl_is_analisi,
    TRIM(BOTH FROM s.is_cam::text) AS fl_is_cam,
    TRIM(BOTH FROM s.is_ufficiale::text) AS fl_is_ufficiale,
    TRIM(BOTH FROM s.id_categoria::text) AS id_sorgente_categoria,
    TRIM(BOTH FROM s.is_manodopera::text) AS fl_is_manodopera,
    TRIM(BOTH FROM s.codice_lev1::text) AS cd_codice_lev1,
    TRIM(BOTH FROM s.codice_lev2::text) AS cd_codice_lev2,
    TRIM(BOTH FROM s.codice_lev3::text) AS cd_codice_lev3,
    TRIM(BOTH FROM s.codice_lev4::text) AS cd_codice_lev4,
    TRIM(BOTH FROM s.codice_lev5::text) AS cd_codice_lev5,
    TRIM(BOTH FROM s.is_minuteria::text) AS fl_is_minuteria,
    TRIM(BOTH FROM s.percentuale_aumento::text) AS nr_percentuale_aumento,
    TRIM(BOTH FROM s.annotazione) AS ds_annotazione,
    TRIM(BOTH FROM s.esporta_come_articolo::text) AS fl_esporta_come_articolo,
    TRIM(BOTH FROM s.escludi_manodopera::text) AS fl_escludi_manodopera,
    TRIM(BOTH FROM s.provincia::text) AS id_sorgente_provincia
   FROM hcbi_ras.src_tmp_anag_articolo s;

ALTER TABLE hcbi_ras.v_src_tmp_anag_articolo
    OWNER TO hcbi_ras;
COMMENT ON VIEW hcbi_ras.v_src_tmp_anag_articolo
    IS 'Vista di conversione della sorgente temporanea ANAG_ARTICOLO';

GRANT ALL ON TABLE hcbi_ras.v_src_tmp_anag_articolo TO hcbi_ras;
GRANT SELECT ON TABLE hcbi_ras.v_src_tmp_anag_articolo TO hcbi_utility;

/* =====================================================================
   TABELLA STG
   ===================================================================== */
-- Table: hcbi_ras.stg_anag_articolo

-- DROP TABLE IF EXISTS hcbi_ras.stg_anag_articolo;

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_articolo
(
    id_sorgente_articolo bigint NOT NULL,
    ds_anno integer NOT NULL,
    cd_articolo character varying(60) COLLATE pg_catalog."default" NOT NULL,
    nr_livello integer NOT NULL,
    ds_nome text COLLATE pg_catalog."default" NOT NULL,
    ds_descrizione text COLLATE pg_catalog."default" NOT NULL,
    fl_eliminato smallint NOT NULL,
    fl_prezzo_regionale smallint NOT NULL,
    ds_unita_misura integer,
    nr_macro_gruppo integer,
    nr_spese_generali numeric(24,5),
    nr_di_cui_analisi numeric(24,5),
    nr_utile_impresa numeric(24,5),
    dt_last_update timestamp without time zone NOT NULL,
    fl_analisi_approvata smallint NOT NULL,
    fl_has_utile_impresa smallint NOT NULL,
    fl_analisi_pubblicata smallint NOT NULL,
    cd_versione smallint NOT NULL,
    fl_is_analisi smallint NOT NULL,
    fl_is_cam smallint NOT NULL,
    fl_is_ufficiale smallint NOT NULL,
    id_sorgente_categoria bigint,
    fl_is_manodopera smallint NOT NULL,
    cd_codice_lev1 character varying(60) COLLATE pg_catalog."default",
    cd_codice_lev2 character varying(60) COLLATE pg_catalog."default",
    cd_codice_lev3 character varying(60) COLLATE pg_catalog."default",
    cd_codice_lev4 character varying(60) COLLATE pg_catalog."default",
    cd_codice_lev5 character varying(60) COLLATE pg_catalog."default",
    fl_is_minuteria smallint NOT NULL,
    nr_percentuale_aumento numeric(24,5),
    ds_annotazione text COLLATE pg_catalog."default",
    fl_esporta_come_articolo smallint NOT NULL,
    fl_escludi_manodopera smallint NOT NULL,
    id_sorgente_provincia numeric(10,0) NOT NULL DEFAULT 0
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.stg_anag_articolo
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.stg_anag_articolo FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.stg_anag_articolo TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.stg_anag_articolo TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.stg_anag_articolo
    IS 'Staging del flusso ANAG_ARTICOLO';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo.id_sorgente_articolo
    IS 'Identificativo dell''articolo nella sorgente operazionale';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo.ds_anno
    IS 'Anno dell''articolo';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo.cd_articolo
    IS 'Codice dell''articolo';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo.cd_versione
    IS 'Versione/addendum dell''articolo';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo.fl_esporta_come_articolo
    IS 'Indicatore esportazione come articolo: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo.fl_escludi_manodopera
    IS 'Indicatore esclusione manodopera: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo.id_sorgente_provincia
    IS 'Colonna aggiunta manualmente dallo sviluppo ETL, in attesa che venga implementata nel DB operazionale.';
	
/* =====================================================================
   TABELLA STG REJECT
   ===================================================================== */
-- Table: hcbi_ras.stg_anag_articolo_rej

-- DROP TABLE IF EXISTS hcbi_ras.stg_anag_articolo_rej;

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_articolo_rej
(
    id_sorgente_articolo character varying(100) COLLATE pg_catalog."default",
    ds_anno character varying(100) COLLATE pg_catalog."default",
    cd_articolo character varying(60) COLLATE pg_catalog."default",
    nr_livello character varying(20) COLLATE pg_catalog."default",
    ds_nome text COLLATE pg_catalog."default",
    ds_descrizione text COLLATE pg_catalog."default",
    fl_eliminato character varying(20) COLLATE pg_catalog."default",
    fl_prezzo_regionale character varying(20) COLLATE pg_catalog."default",
    ds_unita_misura character varying(100) COLLATE pg_catalog."default",
    nr_macro_gruppo character varying(20) COLLATE pg_catalog."default",
    nr_spese_generali character varying(100) COLLATE pg_catalog."default",
    nr_di_cui_analisi character varying(100) COLLATE pg_catalog."default",
    nr_utile_impresa character varying(100) COLLATE pg_catalog."default",
    dt_last_update timestamp without time zone,
    fl_analisi_approvata character varying(20) COLLATE pg_catalog."default",
    fl_has_utile_impresa character varying(20) COLLATE pg_catalog."default",
    fl_analisi_pubblicata character varying(20) COLLATE pg_catalog."default",
    cd_versione character varying(20) COLLATE pg_catalog."default",
    fl_is_analisi character varying(20) COLLATE pg_catalog."default",
    fl_is_cam character varying(20) COLLATE pg_catalog."default",
    fl_is_ufficiale character varying(20) COLLATE pg_catalog."default",
    id_sorgente_categoria character varying(100) COLLATE pg_catalog."default",
    fl_is_manodopera character varying(20) COLLATE pg_catalog."default",
    cd_codice_lev1 character varying(60) COLLATE pg_catalog."default",
    cd_codice_lev2 character varying(60) COLLATE pg_catalog."default",
    cd_codice_lev3 character varying(60) COLLATE pg_catalog."default",
    cd_codice_lev4 character varying(60) COLLATE pg_catalog."default",
    cd_codice_lev5 character varying(60) COLLATE pg_catalog."default",
    fl_is_minuteria character varying(20) COLLATE pg_catalog."default",
    nr_percentuale_aumento character varying(100) COLLATE pg_catalog."default",
    ds_annotazione text COLLATE pg_catalog."default",
    fl_esporta_come_articolo character varying(20) COLLATE pg_catalog."default",
    fl_escludi_manodopera character varying(20) COLLATE pg_catalog."default",
    tx_motivo_scarto character varying(4000) COLLATE pg_catalog."default",
    id_sorgente_provincia character varying(20) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.stg_anag_articolo_rej
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.stg_anag_articolo_rej FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.stg_anag_articolo_rej TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.stg_anag_articolo_rej TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.stg_anag_articolo_rej
    IS 'Record scartati del flusso ANAG_ARTICOLO';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo_rej.id_sorgente_provincia
    IS 'Colonna aggiunta manualmente dallo sviluppo ETL, in attesa che venga implementata nel DB operazionale.';
/* =====================================================================
   TABELLA DWH
   ===================================================================== */
-- Table: hcbi_ras.dwh_anag_articolo

-- DROP TABLE IF EXISTS hcbi_ras.dwh_anag_articolo;

CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_anag_articolo
(
    id_anag_articolo bigint NOT NULL DEFAULT nextval('hcbi_ras.seq_dwh_anag_articolo'::regclass),
    id_sorgente_articolo bigint NOT NULL,
    ds_anno integer NOT NULL,
    cd_articolo character varying(60) COLLATE pg_catalog."default" NOT NULL,
    nr_livello integer NOT NULL,
    ds_nome text COLLATE pg_catalog."default" NOT NULL,
    ds_descrizione text COLLATE pg_catalog."default" NOT NULL,
    fl_eliminato smallint NOT NULL,
    fl_prezzo_regionale smallint NOT NULL,
    ds_unita_misura integer,
    nr_macro_gruppo integer,
    nr_spese_generali numeric(24,5),
    nr_di_cui_analisi numeric(24,5),
    nr_utile_impresa numeric(24,5),
    dt_last_update timestamp without time zone NOT NULL,
    fl_analisi_approvata smallint NOT NULL,
    fl_has_utile_impresa smallint NOT NULL,
    fl_analisi_pubblicata smallint NOT NULL,
    cd_versione smallint NOT NULL,
    fl_is_analisi smallint NOT NULL,
    fl_is_cam smallint NOT NULL,
    fl_is_ufficiale smallint NOT NULL,
    id_sorgente_categoria bigint,
    fl_is_manodopera smallint NOT NULL,
    cd_codice_lev1 character varying(60) COLLATE pg_catalog."default",
    cd_codice_lev2 character varying(60) COLLATE pg_catalog."default",
    cd_codice_lev3 character varying(60) COLLATE pg_catalog."default",
    cd_codice_lev4 character varying(60) COLLATE pg_catalog."default",
    cd_codice_lev5 character varying(60) COLLATE pg_catalog."default",
    fl_is_minuteria smallint NOT NULL,
    nr_percentuale_aumento numeric(24,5),
    ds_annotazione text COLLATE pg_catalog."default",
    fl_esporta_come_articolo smallint NOT NULL,
    fl_escludi_manodopera smallint NOT NULL,
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by character varying(4000) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by character varying(4000) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
    dt_reciclo timestamp without time zone,
    id_sorgente_provincia numeric(10,0) NOT NULL DEFAULT 0,
    CONSTRAINT pk_dwh_anag_articolo PRIMARY KEY (id_anag_articolo),
    CONSTRAINT uk_dwh_anag_articolo UNIQUE (ds_anno, cd_articolo, cd_versione)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dwh_anag_articolo
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.dwh_anag_articolo FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.dwh_anag_articolo TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.dwh_anag_articolo TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dwh_anag_articolo
    IS 'DWH del flusso ANAG_ARTICOLO';

COMMENT ON COLUMN hcbi_ras.dwh_anag_articolo.fl_esporta_come_articolo
    IS 'Indicatore esportazione come articolo: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_articolo.fl_escludi_manodopera
    IS 'Indicatore esclusione manodopera: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_articolo.id_sorgente_provincia
    IS 'Colonna aggiunta manualmente dallo sviluppo ETL, in attesa che venga implementata nel DB operazionale.';

/* =====================================================================
   VISTA DWH
   ===================================================================== */
-- View: hcbi_ras.v_dwh_anag_articolo

-- DROP VIEW hcbi_ras.v_dwh_anag_articolo;

CREATE OR REPLACE VIEW hcbi_ras.v_dwh_anag_articolo
 AS
 SELECT s.id_sorgente_articolo,
    s.ds_anno,
    s.cd_articolo,
    s.nr_livello,
    s.ds_nome,
    s.ds_descrizione,
    s.fl_eliminato,
    s.fl_prezzo_regionale,
    s.ds_unita_misura,
    s.nr_macro_gruppo,
    s.nr_spese_generali,
    s.nr_di_cui_analisi,
    s.nr_utile_impresa,
    s.dt_last_update,
    s.fl_analisi_approvata,
    s.fl_has_utile_impresa,
    s.fl_analisi_pubblicata,
    s.cd_versione,
    s.fl_is_analisi,
    s.fl_is_cam,
    s.fl_is_ufficiale,
    s.id_sorgente_categoria,
    s.fl_is_manodopera,
    s.cd_codice_lev1,
    s.cd_codice_lev2,
    s.cd_codice_lev3,
    s.cd_codice_lev4,
    s.cd_codice_lev5,
    s.fl_is_minuteria,
    s.nr_percentuale_aumento,
    s.ds_annotazione,
    s.fl_esporta_come_articolo,
    s.fl_escludi_manodopera,
    s.id_sorgente_provincia
   FROM hcbi_ras.stg_anag_articolo s;

ALTER TABLE hcbi_ras.v_dwh_anag_articolo
    OWNER TO hcbi_ras;
COMMENT ON VIEW hcbi_ras.v_dwh_anag_articolo
    IS 'Vista di raccordo tra STG_ANAG_ARTICOLO e DWH_ANAG_ARTICOLO';

GRANT ALL ON TABLE hcbi_ras.v_dwh_anag_articolo TO hcbi_ras;
GRANT SELECT ON TABLE hcbi_ras.v_dwh_anag_articolo TO hcbi_utility;


/* =====================================================================
   FUNZIONI DI CONVERSIONE SICURA
   PostgreSQL 15.9 / 17
   ===================================================================== */
CREATE OR REPLACE FUNCTION hcbi_ras.try_bigint(p_value text)
RETURNS bigint
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT
SECURITY INVOKER SET search_path TO pg_catalog
AS $function$
BEGIN RETURN p_value::bigint;
EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION hcbi_ras.try_integer(p_value text)
RETURNS integer
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT
SECURITY INVOKER SET search_path TO pg_catalog
AS $function$
BEGIN RETURN p_value::integer;
EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION hcbi_ras.try_smallint(p_value text)
RETURNS smallint
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT
SECURITY INVOKER SET search_path TO pg_catalog
AS $function$
BEGIN RETURN p_value::smallint;
EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION hcbi_ras.try_numeric_24_5(p_value text)
RETURNS numeric(24,5)
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT
SECURITY INVOKER SET search_path TO pg_catalog
AS $function$
BEGIN RETURN p_value::numeric(24,5);
EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION hcbi_ras.try_numeric_10_0(p_value text)
RETURNS numeric(10,0)
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT
SECURITY INVOKER SET search_path TO pg_catalog
AS $function$
BEGIN RETURN p_value::numeric(10,0);
EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION hcbi_ras.try_boolean_smallint(p_value text)
RETURNS smallint
LANGUAGE sql IMMUTABLE PARALLEL SAFE RETURNS NULL ON NULL INPUT
SECURITY INVOKER SET search_path TO pg_catalog
AS $function$
SELECT CASE
    WHEN lower(btrim(p_value)) IN ('true','t','1','yes','y') THEN 1::smallint
    WHEN lower(btrim(p_value)) IN ('false','f','0','no','n') THEN 0::smallint
    ELSE NULL::smallint
END;
$function$;

/* =====================================================================
   PROCEDURA STG INITIALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_articolo_prc_initialize(
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
    v_id_log bigint;
    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
BEGIN
    p_result := -1;
    RAISE NOTICE 'Inizializzazione PKG_STG_ANAG_ARTICOLO: pulizia delle tabelle STG e REJ per lo step %', p_ds_step_name;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp, clock_timestamp()::timestamp, p_ds_step_name
    ) INTO v_id_log;
    TRUNCATE TABLE hcbi_ras.stg_anag_articolo;
    TRUNCATE TABLE hcbi_ras.stg_anag_articolo_rej;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name
    );
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
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
                RAISE WARNING 'Errore durante la registrazione del log di errore: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_stg_anag_articolo_prc_initialize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_articolo_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_articolo_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA STG MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_articolo_prc_main(
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
    v_ts_start timestamp;
BEGIN
    p_result := -1;
    v_ts_start := clock_timestamp()::timestamp;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        v_ts_start, v_ts_start, p_ds_step_name
    ) INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_articolo_classificata;
    CREATE TABLE hcbi_ras.tmp_anag_articolo_classificata AS
    WITH src AS MATERIALIZED (
        SELECT
            f.id_sorgente_articolo AS id_sorgente_articolo_raw,
            f.ds_anno AS ds_anno_raw,
            f.cd_articolo AS cd_articolo_raw,
            f.nr_livello AS nr_livello_raw,
            f.ds_nome AS ds_nome_raw,
            f.ds_descrizione AS ds_descrizione_raw,
            f.fl_eliminato AS fl_eliminato_raw,
            f.fl_prezzo_regionale AS fl_prezzo_regionale_raw,
            f.ds_unita_misura AS ds_unita_misura_raw,
            f.nr_macro_gruppo AS nr_macro_gruppo_raw,
            f.nr_spese_generali AS nr_spese_generali_raw,
            f.nr_di_cui_analisi AS nr_di_cui_analisi_raw,
            f.nr_utile_impresa AS nr_utile_impresa_raw,
            f.dt_last_update AS dt_last_update_raw,
            f.fl_analisi_approvata AS fl_analisi_approvata_raw,
            f.fl_has_utile_impresa AS fl_has_utile_impresa_raw,
            f.fl_analisi_pubblicata AS fl_analisi_pubblicata_raw,
            f.cd_versione AS cd_versione_raw,
            f.fl_is_analisi AS fl_is_analisi_raw,
            f.fl_is_cam AS fl_is_cam_raw,
            f.fl_is_ufficiale AS fl_is_ufficiale_raw,
            f.id_sorgente_categoria AS id_sorgente_categoria_raw,
            f.fl_is_manodopera AS fl_is_manodopera_raw,
            f.cd_codice_lev1 AS cd_codice_lev1_raw,
            f.cd_codice_lev2 AS cd_codice_lev2_raw,
            f.cd_codice_lev3 AS cd_codice_lev3_raw,
            f.cd_codice_lev4 AS cd_codice_lev4_raw,
            f.cd_codice_lev5 AS cd_codice_lev5_raw,
            f.fl_is_minuteria AS fl_is_minuteria_raw,
            f.nr_percentuale_aumento AS nr_percentuale_aumento_raw,
            f.ds_annotazione AS ds_annotazione_raw,
            f.fl_esporta_come_articolo AS fl_esporta_come_articolo_raw,
            f.fl_escludi_manodopera AS fl_escludi_manodopera_raw,
            f.id_sorgente_provincia AS id_sorgente_provincia_raw,
            NULLIF(btrim(f.id_sorgente_articolo), '') AS id_sorgente_articolo_txt,
            NULLIF(btrim(f.ds_anno), '') AS ds_anno_txt,
            NULLIF(btrim(f.cd_articolo), '') AS cd_articolo_txt,
            NULLIF(btrim(f.nr_livello), '') AS nr_livello_txt,
            NULLIF(btrim(f.ds_nome), '') AS ds_nome_txt,
            NULLIF(btrim(f.ds_descrizione), '') AS ds_descrizione_txt,
            NULLIF(btrim(f.fl_eliminato), '') AS fl_eliminato_txt,
            NULLIF(btrim(f.fl_prezzo_regionale), '') AS fl_prezzo_regionale_txt,
            NULLIF(btrim(f.ds_unita_misura), '') AS ds_unita_misura_txt,
            NULLIF(btrim(f.nr_macro_gruppo), '') AS nr_macro_gruppo_txt,
            NULLIF(btrim(f.nr_spese_generali), '') AS nr_spese_generali_txt,
            NULLIF(btrim(f.nr_di_cui_analisi), '') AS nr_di_cui_analisi_txt,
            NULLIF(btrim(f.nr_utile_impresa), '') AS nr_utile_impresa_txt,
            NULLIF(btrim(f.fl_analisi_approvata), '') AS fl_analisi_approvata_txt,
            NULLIF(btrim(f.fl_has_utile_impresa), '') AS fl_has_utile_impresa_txt,
            NULLIF(btrim(f.fl_analisi_pubblicata), '') AS fl_analisi_pubblicata_txt,
            NULLIF(btrim(f.cd_versione), '') AS cd_versione_txt,
            NULLIF(btrim(f.fl_is_analisi), '') AS fl_is_analisi_txt,
            NULLIF(btrim(f.fl_is_cam), '') AS fl_is_cam_txt,
            NULLIF(btrim(f.fl_is_ufficiale), '') AS fl_is_ufficiale_txt,
            NULLIF(btrim(f.id_sorgente_categoria), '') AS id_sorgente_categoria_txt,
            NULLIF(btrim(f.fl_is_manodopera), '') AS fl_is_manodopera_txt,
            NULLIF(btrim(f.cd_codice_lev1), '') AS cd_codice_lev1_txt,
            NULLIF(btrim(f.cd_codice_lev2), '') AS cd_codice_lev2_txt,
            NULLIF(btrim(f.cd_codice_lev3), '') AS cd_codice_lev3_txt,
            NULLIF(btrim(f.cd_codice_lev4), '') AS cd_codice_lev4_txt,
            NULLIF(btrim(f.cd_codice_lev5), '') AS cd_codice_lev5_txt,
            NULLIF(btrim(f.fl_is_minuteria), '') AS fl_is_minuteria_txt,
            NULLIF(btrim(f.nr_percentuale_aumento), '') AS nr_percentuale_aumento_txt,
            NULLIF(btrim(f.ds_annotazione), '') AS ds_annotazione_txt,
            NULLIF(btrim(f.fl_esporta_come_articolo), '') AS fl_esporta_come_articolo_txt,
            NULLIF(btrim(f.fl_escludi_manodopera), '') AS fl_escludi_manodopera_txt,
            NULLIF(btrim(f.id_sorgente_provincia), '') AS id_sorgente_provincia_txt,
            count(*) OVER (
                PARTITION BY f.ds_anno, f.cd_articolo, f.cd_versione
            ) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_anag_articolo AS f
    ),
    converted AS MATERIALIZED (
        SELECT
            s.*,
            hcbi_ras.try_bigint(s.id_sorgente_articolo_txt) AS id_sorgente_articolo_cv,
            hcbi_ras.try_integer(s.ds_anno_txt) AS ds_anno_cv,
            s.cd_articolo_txt AS cd_articolo_cv,
            hcbi_ras.try_integer(s.nr_livello_txt) AS nr_livello_cv,
            s.ds_nome_txt AS ds_nome_cv,
            s.ds_descrizione_txt AS ds_descrizione_cv,
            hcbi_ras.try_smallint(s.fl_eliminato_txt) AS fl_eliminato_cv,
            hcbi_ras.try_smallint(s.fl_prezzo_regionale_txt) AS fl_prezzo_regionale_cv,
            hcbi_ras.try_integer(s.ds_unita_misura_txt) AS ds_unita_misura_cv,
            hcbi_ras.try_integer(s.nr_macro_gruppo_txt) AS nr_macro_gruppo_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_spese_generali_txt, ',', '.')) AS nr_spese_generali_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_di_cui_analisi_txt, ',', '.')) AS nr_di_cui_analisi_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_utile_impresa_txt, ',', '.')) AS nr_utile_impresa_cv,
            s.dt_last_update_raw AS dt_last_update_cv,
            hcbi_ras.try_smallint(s.fl_analisi_approvata_txt) AS fl_analisi_approvata_cv,
            hcbi_ras.try_smallint(s.fl_has_utile_impresa_txt) AS fl_has_utile_impresa_cv,
            hcbi_ras.try_smallint(s.fl_analisi_pubblicata_txt) AS fl_analisi_pubblicata_cv,
            hcbi_ras.try_smallint(s.cd_versione_txt) AS cd_versione_cv,
            hcbi_ras.try_smallint(s.fl_is_analisi_txt) AS fl_is_analisi_cv,
            hcbi_ras.try_smallint(s.fl_is_cam_txt) AS fl_is_cam_cv,
            hcbi_ras.try_smallint(s.fl_is_ufficiale_txt) AS fl_is_ufficiale_cv,
            hcbi_ras.try_bigint(s.id_sorgente_categoria_txt) AS id_sorgente_categoria_cv,
            hcbi_ras.try_smallint(s.fl_is_manodopera_txt) AS fl_is_manodopera_cv,
            s.cd_codice_lev1_txt AS cd_codice_lev1_cv,
            s.cd_codice_lev2_txt AS cd_codice_lev2_cv,
            s.cd_codice_lev3_txt AS cd_codice_lev3_cv,
            s.cd_codice_lev4_txt AS cd_codice_lev4_cv,
            s.cd_codice_lev5_txt AS cd_codice_lev5_cv,
            hcbi_ras.try_smallint(s.fl_is_minuteria_txt) AS fl_is_minuteria_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_percentuale_aumento_txt, ',', '.')) AS nr_percentuale_aumento_cv,
            s.ds_annotazione_txt AS ds_annotazione_cv,
            hcbi_ras.try_boolean_smallint(s.fl_esporta_come_articolo_txt) AS fl_esporta_come_articolo_cv,
            hcbi_ras.try_boolean_smallint(s.fl_escludi_manodopera_txt) AS fl_escludi_manodopera_cv,
            coalesce(hcbi_ras.try_numeric_10_0(s.id_sorgente_provincia_txt), 0::numeric(10,0)) AS id_sorgente_provincia_cv
        FROM src AS s
    )
    SELECT
        c.*,
        CASE
            WHEN c.duplicate_count > 1 THEN 'Chiave duplicata nella sorgente: (ds_anno, cd_articolo, cd_versione)'
            WHEN c.id_sorgente_articolo_txt IS NULL THEN 'id_sorgente_articolo obbligatorio'
            WHEN c.id_sorgente_articolo_cv IS NULL THEN 'id_sorgente_articolo non convertibile o fuori dominio'
            WHEN c.ds_anno_txt IS NULL THEN 'ds_anno obbligatorio'
            WHEN c.ds_anno_cv IS NULL THEN 'ds_anno non convertibile o fuori dominio'
            WHEN c.cd_articolo_txt IS NULL THEN 'cd_articolo obbligatorio'
            WHEN c.nr_livello_txt IS NULL THEN 'nr_livello obbligatorio'
            WHEN c.nr_livello_cv IS NULL THEN 'nr_livello non convertibile o fuori dominio'
            WHEN c.ds_nome_txt IS NULL THEN 'ds_nome obbligatorio'
            WHEN c.ds_descrizione_txt IS NULL THEN 'ds_descrizione obbligatorio'
            WHEN c.fl_eliminato_txt IS NULL THEN 'fl_eliminato obbligatorio'
            WHEN c.fl_eliminato_cv IS NULL THEN 'fl_eliminato non convertibile o fuori dominio'
            WHEN c.fl_prezzo_regionale_txt IS NULL THEN 'fl_prezzo_regionale obbligatorio'
            WHEN c.fl_prezzo_regionale_cv IS NULL THEN 'fl_prezzo_regionale non convertibile o fuori dominio'
            WHEN c.dt_last_update_raw IS NULL THEN 'dt_last_update obbligatorio'
            WHEN c.fl_analisi_approvata_txt IS NULL THEN 'fl_analisi_approvata obbligatorio'
            WHEN c.fl_analisi_approvata_cv IS NULL THEN 'fl_analisi_approvata non convertibile o fuori dominio'
            WHEN c.fl_has_utile_impresa_txt IS NULL THEN 'fl_has_utile_impresa obbligatorio'
            WHEN c.fl_has_utile_impresa_cv IS NULL THEN 'fl_has_utile_impresa non convertibile o fuori dominio'
            WHEN c.fl_analisi_pubblicata_txt IS NULL THEN 'fl_analisi_pubblicata obbligatorio'
            WHEN c.fl_analisi_pubblicata_cv IS NULL THEN 'fl_analisi_pubblicata non convertibile o fuori dominio'
            WHEN c.cd_versione_txt IS NULL THEN 'cd_versione obbligatorio'
            WHEN c.cd_versione_cv IS NULL THEN 'cd_versione non convertibile o fuori dominio'
            WHEN c.fl_is_analisi_txt IS NULL THEN 'fl_is_analisi obbligatorio'
            WHEN c.fl_is_analisi_cv IS NULL THEN 'fl_is_analisi non convertibile o fuori dominio'
            WHEN c.fl_is_cam_txt IS NULL THEN 'fl_is_cam obbligatorio'
            WHEN c.fl_is_cam_cv IS NULL THEN 'fl_is_cam non convertibile o fuori dominio'
            WHEN c.fl_is_ufficiale_txt IS NULL THEN 'fl_is_ufficiale obbligatorio'
            WHEN c.fl_is_ufficiale_cv IS NULL THEN 'fl_is_ufficiale non convertibile o fuori dominio'
            WHEN c.fl_is_manodopera_txt IS NULL THEN 'fl_is_manodopera obbligatorio'
            WHEN c.fl_is_manodopera_cv IS NULL THEN 'fl_is_manodopera non convertibile o fuori dominio'
            WHEN c.fl_is_minuteria_txt IS NULL THEN 'fl_is_minuteria obbligatorio'
            WHEN c.fl_is_minuteria_cv IS NULL THEN 'fl_is_minuteria non convertibile o fuori dominio'
            WHEN c.fl_esporta_come_articolo_txt IS NULL THEN 'fl_esporta_come_articolo obbligatorio'
            WHEN c.fl_esporta_come_articolo_cv IS NULL THEN 'fl_esporta_come_articolo non convertibile o fuori dominio'
            WHEN c.fl_escludi_manodopera_txt IS NULL THEN 'fl_escludi_manodopera obbligatorio'
            WHEN c.fl_escludi_manodopera_cv IS NULL THEN 'fl_escludi_manodopera non convertibile o fuori dominio'
            WHEN c.ds_unita_misura_txt IS NOT NULL AND c.ds_unita_misura_cv IS NULL THEN 'ds_unita_misura non convertibile'
            WHEN c.nr_macro_gruppo_txt IS NOT NULL AND c.nr_macro_gruppo_cv IS NULL THEN 'nr_macro_gruppo non convertibile'
            WHEN c.nr_spese_generali_txt IS NOT NULL AND c.nr_spese_generali_cv IS NULL THEN 'nr_spese_generali non convertibile'
            WHEN c.nr_di_cui_analisi_txt IS NOT NULL AND c.nr_di_cui_analisi_cv IS NULL THEN 'nr_di_cui_analisi non convertibile'
            WHEN c.nr_utile_impresa_txt IS NOT NULL AND c.nr_utile_impresa_cv IS NULL THEN 'nr_utile_impresa non convertibile'
            WHEN c.id_sorgente_categoria_txt IS NOT NULL AND c.id_sorgente_categoria_cv IS NULL THEN 'id_sorgente_categoria non convertibile'
            WHEN c.nr_percentuale_aumento_txt IS NOT NULL AND c.nr_percentuale_aumento_cv IS NULL THEN 'nr_percentuale_aumento non convertibile'
            WHEN c.id_sorgente_provincia_txt IS NOT NULL AND hcbi_ras.try_numeric_10_0(c.id_sorgente_provincia_txt) IS NULL THEN 'id_sorgente_provincia non convertibile in numeric(10,0)'
            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM converted AS c;

    SELECT count(*) INTO v_selected
    FROM hcbi_ras.tmp_anag_articolo_classificata;

    INSERT INTO hcbi_ras.stg_anag_articolo (
        id_sorgente_articolo,
        ds_anno,
        cd_articolo,
        nr_livello,
        ds_nome,
        ds_descrizione,
        fl_eliminato,
        fl_prezzo_regionale,
        ds_unita_misura,
        nr_macro_gruppo,
        nr_spese_generali,
        nr_di_cui_analisi,
        nr_utile_impresa,
        dt_last_update,
        fl_analisi_approvata,
        fl_has_utile_impresa,
        fl_analisi_pubblicata,
        cd_versione,
        fl_is_analisi,
        fl_is_cam,
        fl_is_ufficiale,
        id_sorgente_categoria,
        fl_is_manodopera,
        cd_codice_lev1,
        cd_codice_lev2,
        cd_codice_lev3,
        cd_codice_lev4,
        cd_codice_lev5,
        fl_is_minuteria,
        nr_percentuale_aumento,
        ds_annotazione,
        fl_esporta_come_articolo,
        fl_escludi_manodopera,
        id_sorgente_provincia
    )
    SELECT
        t.id_sorgente_articolo_cv,
        t.ds_anno_cv,
        t.cd_articolo_cv,
        t.nr_livello_cv,
        t.ds_nome_cv,
        t.ds_descrizione_cv,
        t.fl_eliminato_cv,
        t.fl_prezzo_regionale_cv,
        t.ds_unita_misura_cv,
        t.nr_macro_gruppo_cv,
        t.nr_spese_generali_cv,
        t.nr_di_cui_analisi_cv,
        t.nr_utile_impresa_cv,
        t.dt_last_update_cv,
        t.fl_analisi_approvata_cv,
        t.fl_has_utile_impresa_cv,
        t.fl_analisi_pubblicata_cv,
        t.cd_versione_cv,
        t.fl_is_analisi_cv,
        t.fl_is_cam_cv,
        t.fl_is_ufficiale_cv,
        t.id_sorgente_categoria_cv,
        t.fl_is_manodopera_cv,
        t.cd_codice_lev1_cv,
        t.cd_codice_lev2_cv,
        t.cd_codice_lev3_cv,
        t.cd_codice_lev4_cv,
        t.cd_codice_lev5_cv,
        t.fl_is_minuteria_cv,
        t.nr_percentuale_aumento_cv,
        t.ds_annotazione_cv,
        t.fl_esporta_come_articolo_cv,
        t.fl_escludi_manodopera_cv,
        t.id_sorgente_provincia_cv
    FROM hcbi_ras.tmp_anag_articolo_classificata AS t
    WHERE t.tx_motivo_scarto IS NULL;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_anag_articolo_rej (
        id_sorgente_articolo,
        ds_anno,
        cd_articolo,
        nr_livello,
        ds_nome,
        ds_descrizione,
        fl_eliminato,
        fl_prezzo_regionale,
        ds_unita_misura,
        nr_macro_gruppo,
        nr_spese_generali,
        nr_di_cui_analisi,
        nr_utile_impresa,
        dt_last_update,
        fl_analisi_approvata,
        fl_has_utile_impresa,
        fl_analisi_pubblicata,
        cd_versione,
        fl_is_analisi,
        fl_is_cam,
        fl_is_ufficiale,
        id_sorgente_categoria,
        fl_is_manodopera,
        cd_codice_lev1,
        cd_codice_lev2,
        cd_codice_lev3,
        cd_codice_lev4,
        cd_codice_lev5,
        fl_is_minuteria,
        nr_percentuale_aumento,
        ds_annotazione,
        fl_esporta_come_articolo,
        fl_escludi_manodopera,
        id_sorgente_provincia,
        tx_motivo_scarto
    )
    SELECT
        t.id_sorgente_articolo_raw,
        t.ds_anno_raw,
        t.cd_articolo_raw,
        t.nr_livello_raw,
        t.ds_nome_raw,
        t.ds_descrizione_raw,
        t.fl_eliminato_raw,
        t.fl_prezzo_regionale_raw,
        t.ds_unita_misura_raw,
        t.nr_macro_gruppo_raw,
        t.nr_spese_generali_raw,
        t.nr_di_cui_analisi_raw,
        t.nr_utile_impresa_raw,
        t.dt_last_update_raw,
        t.fl_analisi_approvata_raw,
        t.fl_has_utile_impresa_raw,
        t.fl_analisi_pubblicata_raw,
        t.cd_versione_raw,
        t.fl_is_analisi_raw,
        t.fl_is_cam_raw,
        t.fl_is_ufficiale_raw,
        t.id_sorgente_categoria_raw,
        t.fl_is_manodopera_raw,
        t.cd_codice_lev1_raw,
        t.cd_codice_lev2_raw,
        t.cd_codice_lev3_raw,
        t.cd_codice_lev4_raw,
        t.cd_codice_lev5_raw,
        t.fl_is_minuteria_raw,
        t.nr_percentuale_aumento_raw,
        t.ds_annotazione_raw,
        t.fl_esporta_come_articolo_raw,
        t.fl_escludi_manodopera_raw,
        t.id_sorgente_provincia_raw,
        t.tx_motivo_scarto
    FROM hcbi_ras.tmp_anag_articolo_classificata AS t
    WHERE t.tx_motivo_scarto IS NOT NULL;
    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = format('Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s', v_selected, v_inserted, v_rec_errors),
            DETAIL = 'Il numero di record letti non coincide con caricati e scartati.',
            HINT = 'Verificare classificazione e INSERT verso STG e REJ.';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, v_updated, v_deleted,
        v_rec_errors, 'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_articolo_classificata;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_anag_articolo_classificata;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore durante la pulizia della tabella di lavoro: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
        END;

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
                RAISE WARNING 'Errore durante la registrazione del log di errore: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;

        RAISE WARNING 'Errore in pkg_stg_anag_articolo_prc_main. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_articolo_prc_main(bigint, bigint, bigint, character varying)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_articolo_prc_main(bigint, bigint, bigint, character varying)
TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   PROCEDURA STG FINALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_articolo_prc_finalize(
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
    v_id_log bigint;
    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
BEGIN
    p_result := -1;
    RAISE NOTICE 'Finalizzazione PKG_STG_ANAG_ARTICOLO per lo step %', p_ds_step_name;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp, clock_timestamp()::timestamp, p_ds_step_name
    ) INTO v_id_log;
    ANALYZE hcbi_ras.stg_anag_articolo;
    ANALYZE hcbi_ras.stg_anag_articolo_rej;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name
    );
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
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
                RAISE WARNING 'Errore durante la registrazione del log di errore: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_stg_anag_articolo_prc_finalize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_articolo_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_articolo_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA DWH INITIALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_articolo_prc_initialize(
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
    v_id_log bigint;
    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
BEGIN
    p_result := -1;
    RAISE NOTICE 'Inizializzazione PKG_DWH_ANAG_ARTICOLO per lo step %', p_ds_step_name;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp, clock_timestamp()::timestamp, p_ds_step_name
    ) INTO v_id_log;
    -- Nessuna inizializzazione dati richiesta.
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name
    );
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
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
                RAISE WARNING 'Errore durante la registrazione del log di errore: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_dwh_anag_articolo_prc_initialize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_articolo_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_articolo_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA DWH MAIN
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_articolo_prc_main(
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
    v_id_log bigint;
    v_selected bigint := 0;
    v_inserted bigint := 0;
    v_updated bigint := 0;
    v_deleted bigint := 0;
    v_rec_errors bigint := 0;
    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp, clock_timestamp()::timestamp, p_ds_step_name
    ) INTO v_id_log;
    SELECT count(*) INTO v_selected FROM hcbi_ras.v_dwh_anag_articolo;

    UPDATE hcbi_ras.dwh_anag_articolo AS dwh
       SET id_sorgente_articolo = src.id_sorgente_articolo,
           nr_livello = src.nr_livello,
           ds_nome = src.ds_nome,
           ds_descrizione = src.ds_descrizione,
           fl_eliminato = src.fl_eliminato,
           fl_prezzo_regionale = src.fl_prezzo_regionale,
           ds_unita_misura = src.ds_unita_misura,
           nr_macro_gruppo = src.nr_macro_gruppo,
           nr_spese_generali = src.nr_spese_generali,
           nr_di_cui_analisi = src.nr_di_cui_analisi,
           nr_utile_impresa = src.nr_utile_impresa,
           dt_last_update = src.dt_last_update,
           fl_analisi_approvata = src.fl_analisi_approvata,
           fl_has_utile_impresa = src.fl_has_utile_impresa,
           fl_analisi_pubblicata = src.fl_analisi_pubblicata,
           fl_is_analisi = src.fl_is_analisi,
           fl_is_cam = src.fl_is_cam,
           fl_is_ufficiale = src.fl_is_ufficiale,
           id_sorgente_categoria = src.id_sorgente_categoria,
           fl_is_manodopera = src.fl_is_manodopera,
           cd_codice_lev1 = src.cd_codice_lev1,
           cd_codice_lev2 = src.cd_codice_lev2,
           cd_codice_lev3 = src.cd_codice_lev3,
           cd_codice_lev4 = src.cd_codice_lev4,
           cd_codice_lev5 = src.cd_codice_lev5,
           fl_is_minuteria = src.fl_is_minuteria,
           nr_percentuale_aumento = src.nr_percentuale_aumento,
           ds_annotazione = src.ds_annotazione,
           fl_esporta_come_articolo = src.fl_esporta_come_articolo,
           fl_escludi_manodopera = src.fl_escludi_manodopera,
           id_sorgente_provincia = src.id_sorgente_provincia,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.v_dwh_anag_articolo AS src
     WHERE dwh.ds_anno = src.ds_anno
       AND dwh.cd_articolo = src.cd_articolo
       AND dwh.cd_versione = src.cd_versione
       AND ROW(dwh.id_sorgente_articolo, dwh.nr_livello, dwh.ds_nome, dwh.ds_descrizione, dwh.fl_eliminato, dwh.fl_prezzo_regionale, dwh.ds_unita_misura, dwh.nr_macro_gruppo, dwh.nr_spese_generali, dwh.nr_di_cui_analisi, dwh.nr_utile_impresa, dwh.dt_last_update, dwh.fl_analisi_approvata, dwh.fl_has_utile_impresa, dwh.fl_analisi_pubblicata, dwh.fl_is_analisi, dwh.fl_is_cam, dwh.fl_is_ufficiale, dwh.id_sorgente_categoria, dwh.fl_is_manodopera, dwh.cd_codice_lev1, dwh.cd_codice_lev2, dwh.cd_codice_lev3, dwh.cd_codice_lev4, dwh.cd_codice_lev5, dwh.fl_is_minuteria, dwh.nr_percentuale_aumento, dwh.ds_annotazione, dwh.fl_esporta_come_articolo, dwh.fl_escludi_manodopera, dwh.id_sorgente_provincia) IS DISTINCT FROM ROW(src.id_sorgente_articolo, src.nr_livello, src.ds_nome, src.ds_descrizione, src.fl_eliminato, src.fl_prezzo_regionale, src.ds_unita_misura, src.nr_macro_gruppo, src.nr_spese_generali, src.nr_di_cui_analisi, src.nr_utile_impresa, src.dt_last_update, src.fl_analisi_approvata, src.fl_has_utile_impresa, src.fl_analisi_pubblicata, src.fl_is_analisi, src.fl_is_cam, src.fl_is_ufficiale, src.id_sorgente_categoria, src.fl_is_manodopera, src.cd_codice_lev1, src.cd_codice_lev2, src.cd_codice_lev3, src.cd_codice_lev4, src.cd_codice_lev5, src.fl_is_minuteria, src.nr_percentuale_aumento, src.ds_annotazione, src.fl_esporta_come_articolo, src.fl_escludi_manodopera, src.id_sorgente_provincia);
    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_anag_articolo (
        id_sorgente_articolo,
        ds_anno,
        cd_articolo,
        nr_livello,
        ds_nome,
        ds_descrizione,
        fl_eliminato,
        fl_prezzo_regionale,
        ds_unita_misura,
        nr_macro_gruppo,
        nr_spese_generali,
        nr_di_cui_analisi,
        nr_utile_impresa,
        dt_last_update,
        fl_analisi_approvata,
        fl_has_utile_impresa,
        fl_analisi_pubblicata,
        cd_versione,
        fl_is_analisi,
        fl_is_cam,
        fl_is_ufficiale,
        id_sorgente_categoria,
        fl_is_manodopera,
        cd_codice_lev1,
        cd_codice_lev2,
        cd_codice_lev3,
        cd_codice_lev4,
        cd_codice_lev5,
        fl_is_minuteria,
        nr_percentuale_aumento,
        ds_annotazione,
        fl_esporta_come_articolo,
        fl_escludi_manodopera,
        id_sorgente_provincia,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_sorgente_articolo,
        src.ds_anno,
        src.cd_articolo,
        src.nr_livello,
        src.ds_nome,
        src.ds_descrizione,
        src.fl_eliminato,
        src.fl_prezzo_regionale,
        src.ds_unita_misura,
        src.nr_macro_gruppo,
        src.nr_spese_generali,
        src.nr_di_cui_analisi,
        src.nr_utile_impresa,
        src.dt_last_update,
        src.fl_analisi_approvata,
        src.fl_has_utile_impresa,
        src.fl_analisi_pubblicata,
        src.cd_versione,
        src.fl_is_analisi,
        src.fl_is_cam,
        src.fl_is_ufficiale,
        src.id_sorgente_categoria,
        src.fl_is_manodopera,
        src.cd_codice_lev1,
        src.cd_codice_lev2,
        src.cd_codice_lev3,
        src.cd_codice_lev4,
        src.cd_codice_lev5,
        src.fl_is_minuteria,
        src.nr_percentuale_aumento,
        src.ds_annotazione,
        src.fl_esporta_come_articolo,
        src.fl_escludi_manodopera,
        src.id_sorgente_provincia,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.v_dwh_anag_articolo AS src
    ON CONFLICT (ds_anno, cd_articolo, cd_versione) DO NOTHING;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, v_updated, v_deleted, v_rec_errors,
        'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name
    );
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
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
                RAISE WARNING 'Errore durante la registrazione del log di errore: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_dwh_anag_articolo_prc_main. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_articolo_prc_main(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_articolo_prc_main(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA DWH FINALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_articolo_prc_finalize(
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
    v_id_log bigint;
    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
BEGIN
    p_result := -1;
    RAISE NOTICE 'Finalizzazione PKG_DWH_ANAG_ARTICOLO per lo step %', p_ds_step_name;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp, clock_timestamp()::timestamp, p_ds_step_name
    ) INTO v_id_log;
    ANALYZE hcbi_ras.dwh_anag_articolo;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name
    );
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
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
                RAISE WARNING 'Errore durante la registrazione del log di errore: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_dwh_anag_articolo_prc_finalize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_articolo_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_articolo_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   COMMENTI
   ===================================================================== */

COMMENT ON TABLE hcbi_ras.frontiera_anag_articolo
IS 'Frontiera del flusso ANAG_ARTICOLO';

COMMENT ON TABLE hcbi_ras.src_tmp_anag_articolo
IS 'Tabella temporanea sorgente del flusso ANAG_ARTICOLO';

COMMENT ON TABLE hcbi_ras.stg_anag_articolo
IS 'Staging del flusso ANAG_ARTICOLO';

COMMENT ON TABLE hcbi_ras.stg_anag_articolo_rej
IS 'Record scartati del flusso ANAG_ARTICOLO';

COMMENT ON TABLE hcbi_ras.dwh_anag_articolo
IS 'DWH del flusso ANAG_ARTICOLO';

COMMENT ON VIEW hcbi_ras.v_src_tmp_anag_articolo
IS 'Vista di conversione della sorgente temporanea ANAG_ARTICOLO';

COMMENT ON VIEW hcbi_ras.v_dwh_anag_articolo
IS 'Vista di raccordo tra STG_ANAG_ARTICOLO e DWH_ANAG_ARTICOLO';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo.id_sorgente_articolo
IS 'Identificativo dell''articolo nella sorgente operazionale';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo.ds_anno
IS 'Anno dell''articolo';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo.cd_articolo
IS 'Codice dell''articolo';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo.cd_versione
IS 'Versione/addendum dell''articolo';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo.fl_esporta_come_articolo
IS 'Indicatore esportazione come articolo: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.stg_anag_articolo.fl_escludi_manodopera
IS 'Indicatore esclusione manodopera: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_articolo.fl_esporta_come_articolo
IS 'Indicatore esportazione come articolo: 0 falso, 1 vero';

COMMENT ON COLUMN hcbi_ras.dwh_anag_articolo.fl_escludi_manodopera
IS 'Indicatore esclusione manodopera: 0 falso, 1 vero';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_articolo_prc_initialize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
)
IS 'Svuota STG_ANAG_ARTICOLO e STG_ANAG_ARTICOLO_REJ; classificazione e scarti sono gestiti dalla procedura main.';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_articolo_prc_main(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
)
IS 'Classifica e converte in modalita set-based i dati ANAG_ARTICOLO, identifica duplicati e scarti, carica STG e riconcilia i conteggi.';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_articolo_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Finalizza il caricamento STG_ANAG_ARTICOLO e aggiorna le statistiche.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_articolo_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Inizializza il flusso DWH_ANAG_ARTICOLO e registra l''esecuzione nel log.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_articolo_prc_main(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Carica DWH_ANAG_ARTICOLO dalla tabella STG aggiornando i record esistenti e inserendo i nuovi.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_articolo_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Finalizza il flusso DWH_ANAG_ARTICOLO e aggiorna le statistiche.';