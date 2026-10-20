/* =====================================================================
   FLUSSO PUBBLICAZIONE_ALBERO - VERSIONE UNIFORMATA
   ===================================================================== */
/* Target: PostgreSQL 15.9 e PostgreSQL 17.
   Pattern tecnico: flusso PUBBLICAZIONE_ANALISI definitivo.
   Business key: (ds_anno_pubblicazione, id_sorgente_provincia, cd_articolo, cd_versione).
   Nota: il nome sorgente is_uinta_misura_modificata e il corrispondente nome DWH
   fl_is_uinta_misura_modificata sono mantenuti per compatibilita' contrattuale. */

/* =====================================================================
   SEQUENCE DWH
   ===================================================================== */
CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_pubblicazione_albero
    INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;
ALTER SEQUENCE hcbi_ras.seq_dwh_pubblicazione_albero OWNER TO hcbi_ras;
GRANT ALL ON SEQUENCE hcbi_ras.seq_dwh_pubblicazione_albero TO hcbi_ras;
GRANT USAGE, SELECT ON SEQUENCE hcbi_ras.seq_dwh_pubblicazione_albero TO hcbi_utility;

/* =====================================================================
   TABELLA FRONTIERA
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_pubblicazione_albero
(
    anno character varying(100) COLLATE pg_catalog."default",
    provincia character varying(100) COLLATE pg_catalog."default",
    codice character varying(70) COLLATE pg_catalog."default",
    descrizione text COLLATE pg_catalog."default",
    prezzo character varying(100) COLLATE pg_catalog."default",
    idum character varying(100) COLLATE pg_catalog."default",
    isanalisi character varying(20) COLLATE pg_catalog."default",
    isincidenza character varying(20) COLLATE pg_catalog."default",
    addendum character varying(20) COLLATE pg_catalog."default",
    scostamento character varying(100) COLLATE pg_catalog."default",
    scostamento_con_spese character varying(100) COLLATE pg_catalog."default",
    is_nuovo_codice character varying(20) COLLATE pg_catalog."default",
    is_prezzo_modificato character varying(20) COLLATE pg_catalog."default",
    is_prezzo_con_spese_modificato character varying(20) COLLATE pg_catalog."default",
    is_analisi_modificata character varying(20) COLLATE pg_catalog."default",
    is_descrizione_modificata character varying(20) COLLATE pg_catalog."default",
    is_uinta_misura_modificata character varying(20) COLLATE pg_catalog."default",
    is_spese_generali_modificate character varying(20) COLLATE pg_catalog."default",
    is_utili_impresa_modificati character varying(20) COLLATE pg_catalog."default",
    is_oneri_sicurezza_modificati character varying(20) COLLATE pg_catalog."default",
    descrizione_de text COLLATE pg_catalog."default",
    is_ufficiale character varying(20) COLLATE pg_catalog."default",
    id_categoria character varying(20) COLLATE pg_catalog."default",
    nome text COLLATE pg_catalog."default",
    nome_de text COLLATE pg_catalog."default",
    is_nome_modificato character varying(20) COLLATE pg_catalog."default",
    link_cam character varying(60) COLLATE pg_catalog."default",
    annotazione text COLLATE pg_catalog."default",
    annotazione_de text COLLATE pg_catalog."default",
    id character varying(100) COLLATE pg_catalog."default",
    esporta_come_articolo character varying(20) COLLATE pg_catalog."default",
    escludi_manodopera character varying(20) COLLATE pg_catalog."default",
    mostra_struttura_analisi character varying(20) COLLATE pg_catalog."default",
    macro_gruppo character varying(20) COLLATE pg_catalog."default",
    is_cam character varying(20) COLLATE pg_catalog."default"
) TABLESPACE pg_default;
ALTER TABLE hcbi_ras.frontiera_pubblicazione_albero OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.frontiera_pubblicazione_albero FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.frontiera_pubblicazione_albero TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.frontiera_pubblicazione_albero TO hcbi_utility;
COMMENT ON TABLE hcbi_ras.frontiera_pubblicazione_albero IS 'Frontiera del flusso PUBBLICAZIONE_ALBERO';

/* =====================================================================
   TABELLA SRC_TMP
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_pubblicazione_albero
(
    anno character varying(100) COLLATE pg_catalog."default",
    provincia character varying(100) COLLATE pg_catalog."default",
    codice character varying(70) COLLATE pg_catalog."default",
    descrizione text COLLATE pg_catalog."default",
    prezzo character varying(100) COLLATE pg_catalog."default",
    idum character varying(100) COLLATE pg_catalog."default",
    isanalisi character varying(20) COLLATE pg_catalog."default",
    isincidenza character varying(20) COLLATE pg_catalog."default",
    addendum character varying(20) COLLATE pg_catalog."default",
    scostamento character varying(100) COLLATE pg_catalog."default",
    scostamento_con_spese character varying(100) COLLATE pg_catalog."default",
    is_nuovo_codice character varying(20) COLLATE pg_catalog."default",
    is_prezzo_modificato character varying(20) COLLATE pg_catalog."default",
    is_prezzo_con_spese_modificato character varying(20) COLLATE pg_catalog."default",
    is_analisi_modificata character varying(20) COLLATE pg_catalog."default",
    is_descrizione_modificata character varying(20) COLLATE pg_catalog."default",
    is_uinta_misura_modificata character varying(20) COLLATE pg_catalog."default",
    is_spese_generali_modificate character varying(20) COLLATE pg_catalog."default",
    is_utili_impresa_modificati character varying(20) COLLATE pg_catalog."default",
    is_oneri_sicurezza_modificati character varying(20) COLLATE pg_catalog."default",
    descrizione_de text COLLATE pg_catalog."default",
    is_ufficiale character varying(20) COLLATE pg_catalog."default",
    id_categoria character varying(20) COLLATE pg_catalog."default",
    nome text COLLATE pg_catalog."default",
    nome_de text COLLATE pg_catalog."default",
    is_nome_modificato character varying(20) COLLATE pg_catalog."default",
    link_cam character varying(60) COLLATE pg_catalog."default",
    annotazione text COLLATE pg_catalog."default",
    annotazione_de text COLLATE pg_catalog."default",
    id character varying(100) COLLATE pg_catalog."default",
    esporta_come_articolo character varying(20) COLLATE pg_catalog."default",
    escludi_manodopera character varying(20) COLLATE pg_catalog."default",
    mostra_struttura_analisi character varying(20) COLLATE pg_catalog."default",
    macro_gruppo character varying(20) COLLATE pg_catalog."default",
    is_cam character varying(20) COLLATE pg_catalog."default"
) TABLESPACE pg_default;
ALTER TABLE hcbi_ras.src_tmp_pubblicazione_albero OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.src_tmp_pubblicazione_albero FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.src_tmp_pubblicazione_albero TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.src_tmp_pubblicazione_albero TO hcbi_utility;
COMMENT ON TABLE hcbi_ras.src_tmp_pubblicazione_albero IS 'Tabella temporanea sorgente del flusso PUBBLICAZIONE_ALBERO';

/* =====================================================================
   VISTA SRC_TMP
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_pubblicazione_albero AS
SELECT
    btrim(s.anno::text) AS ds_anno_pubblicazione,
    btrim(s.provincia::text) AS id_sorgente_provincia,
    btrim(s.codice::text) AS cd_articolo,
    btrim(s.descrizione::text) AS ds_articolo,
    btrim(s.prezzo::text) AS nr_prezzo,
    btrim(s.idum::text) AS id_sorgente_um,
    btrim(s.isanalisi::text) AS fl_isanalisi,
    btrim(s.isincidenza::text) AS fl_isincidenza,
    btrim(s.addendum::text) AS cd_versione,
    btrim(s.scostamento::text) AS nr_scostamento,
    btrim(s.scostamento_con_spese::text) AS nr_scostamento_con_spese,
    btrim(s.is_nuovo_codice::text) AS fl_is_nuovo_codice,
    btrim(s.is_prezzo_modificato::text) AS fl_is_prezzo_modificato,
    btrim(s.is_prezzo_con_spese_modificato::text) AS fl_is_prezzo_con_spese_modificato,
    btrim(s.is_analisi_modificata::text) AS fl_is_analisi_modificata,
    btrim(s.is_descrizione_modificata::text) AS fl_is_descrizione_modificata,
    btrim(s.is_uinta_misura_modificata::text) AS fl_is_uinta_misura_modificata,
    btrim(s.is_spese_generali_modificate::text) AS fl_is_spese_generali_modificate,
    btrim(s.is_utili_impresa_modificati::text) AS fl_is_utili_impresa_modificati,
    btrim(s.is_oneri_sicurezza_modificati::text) AS fl_is_oneri_sicurezza_modificati,
    btrim(s.descrizione_de::text) AS ds_descrizione_de,
    btrim(s.is_ufficiale::text) AS fl_is_ufficiale,
    btrim(s.id_categoria::text) AS id_sorgente_categoria,
    btrim(s.nome::text) AS ds_nome,
    btrim(s.nome_de::text) AS ds_nome_de,
    btrim(s.is_nome_modificato::text) AS fl_is_nome_modificato,
    btrim(s.link_cam::text) AS ds_link_cam,
    btrim(s.annotazione::text) AS ds_annotazione,
    btrim(s.annotazione_de::text) AS ds_annotazione_de,
    btrim(s.id::text) AS id_sorgente_pubblicazione_albero,
    btrim(s.esporta_come_articolo::text) AS fl_esporta_come_articolo,
    btrim(s.escludi_manodopera::text) AS fl_escludi_manodopera,
    btrim(s.mostra_struttura_analisi::text) AS fl_mostra_struttura_analisi,
    btrim(s.macro_gruppo::text) AS nr_macro_gruppo,
    btrim(s.is_cam::text) AS fl_is_cam
FROM hcbi_ras.src_tmp_pubblicazione_albero AS s;
ALTER TABLE hcbi_ras.v_src_tmp_pubblicazione_albero OWNER TO hcbi_ras;
GRANT ALL ON TABLE hcbi_ras.v_src_tmp_pubblicazione_albero TO hcbi_ras;
GRANT SELECT ON TABLE hcbi_ras.v_src_tmp_pubblicazione_albero TO hcbi_utility;
COMMENT ON VIEW hcbi_ras.v_src_tmp_pubblicazione_albero IS 'Vista normalizzata della SRC_TMP del flusso PUBBLICAZIONE_ALBERO';

/* =====================================================================
   TABELLA STG
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_pubblicazione_albero
(
    ds_anno_pubblicazione numeric(10,0) NOT NULL,
    id_sorgente_provincia numeric(10,0) NOT NULL,
    cd_articolo varchar(70) COLLATE pg_catalog."default" NOT NULL,
    ds_articolo text COLLATE pg_catalog."default",
    nr_prezzo numeric(24,5),
    id_sorgente_um numeric(10,0),
    fl_isanalisi smallint,
    fl_isincidenza smallint,
    cd_versione smallint NOT NULL,
    nr_scostamento double precision,
    nr_scostamento_con_spese double precision,
    fl_is_nuovo_codice smallint,
    fl_is_prezzo_modificato smallint,
    fl_is_prezzo_con_spese_modificato smallint,
    fl_is_analisi_modificata smallint,
    fl_is_descrizione_modificata smallint,
    fl_is_uinta_misura_modificata smallint,
    fl_is_spese_generali_modificate smallint,
    fl_is_utili_impresa_modificati smallint,
    fl_is_oneri_sicurezza_modificati smallint,
    ds_descrizione_de text COLLATE pg_catalog."default",
    fl_is_ufficiale smallint,
    id_sorgente_categoria bigint,
    ds_nome text COLLATE pg_catalog."default",
    ds_nome_de text COLLATE pg_catalog."default",
    fl_is_nome_modificato smallint,
    ds_link_cam varchar(60) COLLATE pg_catalog."default",
    ds_annotazione text COLLATE pg_catalog."default",
    ds_annotazione_de text COLLATE pg_catalog."default",
    id_sorgente_pubblicazione_albero bigint,
    fl_esporta_come_articolo smallint,
    fl_escludi_manodopera smallint,
    fl_mostra_struttura_analisi smallint,
    nr_macro_gruppo integer,
    fl_is_cam smallint
) TABLESPACE pg_default;
ALTER TABLE hcbi_ras.stg_pubblicazione_albero OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.stg_pubblicazione_albero FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.stg_pubblicazione_albero TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.stg_pubblicazione_albero TO hcbi_utility;
COMMENT ON TABLE hcbi_ras.stg_pubblicazione_albero IS 'Staging tipizzato del flusso PUBBLICAZIONE_ALBERO';

/* =====================================================================
   TABELLA STG REJECT
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_pubblicazione_albero_rej
(
    ds_anno_pubblicazione character varying(100) COLLATE pg_catalog."default",
    id_sorgente_provincia character varying(100) COLLATE pg_catalog."default",
    cd_articolo character varying(70) COLLATE pg_catalog."default",
    ds_articolo text COLLATE pg_catalog."default",
    nr_prezzo character varying(100) COLLATE pg_catalog."default",
    id_sorgente_um character varying(100) COLLATE pg_catalog."default",
    fl_isanalisi character varying(100) COLLATE pg_catalog."default",
    fl_isincidenza character varying(100) COLLATE pg_catalog."default",
    cd_versione character varying(100) COLLATE pg_catalog."default",
    nr_scostamento character varying(100) COLLATE pg_catalog."default",
    nr_scostamento_con_spese character varying(100) COLLATE pg_catalog."default",
    fl_is_nuovo_codice character varying(100) COLLATE pg_catalog."default",
    fl_is_prezzo_modificato character varying(100) COLLATE pg_catalog."default",
    fl_is_prezzo_con_spese_modificato character varying(100) COLLATE pg_catalog."default",
    fl_is_analisi_modificata character varying(100) COLLATE pg_catalog."default",
    fl_is_descrizione_modificata character varying(100) COLLATE pg_catalog."default",
    fl_is_uinta_misura_modificata character varying(100) COLLATE pg_catalog."default",
    fl_is_spese_generali_modificate character varying(100) COLLATE pg_catalog."default",
    fl_is_utili_impresa_modificati character varying(100) COLLATE pg_catalog."default",
    fl_is_oneri_sicurezza_modificati character varying(100) COLLATE pg_catalog."default",
    ds_descrizione_de text COLLATE pg_catalog."default",
    fl_is_ufficiale character varying(100) COLLATE pg_catalog."default",
    id_sorgente_categoria character varying(100) COLLATE pg_catalog."default",
    ds_nome text COLLATE pg_catalog."default",
    ds_nome_de text COLLATE pg_catalog."default",
    fl_is_nome_modificato character varying(100) COLLATE pg_catalog."default",
    ds_link_cam character varying(60) COLLATE pg_catalog."default",
    ds_annotazione text COLLATE pg_catalog."default",
    ds_annotazione_de text COLLATE pg_catalog."default",
    id_sorgente_pubblicazione_albero character varying(100) COLLATE pg_catalog."default",
    fl_esporta_come_articolo character varying(100) COLLATE pg_catalog."default",
    fl_escludi_manodopera character varying(100) COLLATE pg_catalog."default",
    fl_mostra_struttura_analisi character varying(100) COLLATE pg_catalog."default",
    nr_macro_gruppo character varying(100) COLLATE pg_catalog."default",
    fl_is_cam character varying(100) COLLATE pg_catalog."default",
    tx_motivo_scarto character varying(4000) COLLATE pg_catalog."default"
) TABLESPACE pg_default;
ALTER TABLE hcbi_ras.stg_pubblicazione_albero_rej OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.stg_pubblicazione_albero_rej FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.stg_pubblicazione_albero_rej TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.stg_pubblicazione_albero_rej TO hcbi_utility;
COMMENT ON TABLE hcbi_ras.stg_pubblicazione_albero_rej IS 'Record scartati del flusso PUBBLICAZIONE_ALBERO';

/* =====================================================================
   TABELLA DWH
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_pubblicazione_albero
(
    id_pubblicazione_albero bigint NOT NULL DEFAULT nextval('hcbi_ras.seq_dwh_pubblicazione_albero'::regclass),
    ds_anno_pubblicazione numeric(10,0) NOT NULL,
    id_sorgente_provincia numeric(10,0) NOT NULL,
    cd_articolo varchar(70) COLLATE pg_catalog."default" NOT NULL,
    ds_articolo text COLLATE pg_catalog."default",
    nr_prezzo numeric(24,5),
    id_sorgente_um numeric(10,0),
    fl_isanalisi smallint,
    fl_isincidenza smallint,
    cd_versione smallint NOT NULL,
    nr_scostamento double precision,
    nr_scostamento_con_spese double precision,
    fl_is_nuovo_codice smallint,
    fl_is_prezzo_modificato smallint,
    fl_is_prezzo_con_spese_modificato smallint,
    fl_is_analisi_modificata smallint,
    fl_is_descrizione_modificata smallint,
    fl_is_uinta_misura_modificata smallint,
    fl_is_spese_generali_modificate smallint,
    fl_is_utili_impresa_modificati smallint,
    fl_is_oneri_sicurezza_modificati smallint,
    ds_descrizione_de text COLLATE pg_catalog."default",
    fl_is_ufficiale smallint,
    id_sorgente_categoria bigint,
    ds_nome text COLLATE pg_catalog."default",
    ds_nome_de text COLLATE pg_catalog."default",
    fl_is_nome_modificato smallint,
    ds_link_cam varchar(60) COLLATE pg_catalog."default",
    ds_annotazione text COLLATE pg_catalog."default",
    ds_annotazione_de text COLLATE pg_catalog."default",
    id_sorgente_pubblicazione_albero bigint,
    fl_esporta_come_articolo smallint,
    fl_escludi_manodopera smallint,
    fl_mostra_struttura_analisi smallint,
    nr_macro_gruppo integer,
    fl_is_cam smallint,
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by character varying(4000) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by character varying(4000) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
    dt_reciclo timestamp without time zone,
    CONSTRAINT pk_dwh_pubblicazione_albero PRIMARY KEY (id_pubblicazione_albero),
    CONSTRAINT uq_dwh_pubblicazione_albero UNIQUE NULLS NOT DISTINCT (ds_anno_pubblicazione, id_sorgente_provincia, cd_articolo, cd_versione)
) TABLESPACE pg_default;
ALTER TABLE hcbi_ras.dwh_pubblicazione_albero OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.dwh_pubblicazione_albero FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.dwh_pubblicazione_albero TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.dwh_pubblicazione_albero TO hcbi_utility;
COMMENT ON TABLE hcbi_ras.dwh_pubblicazione_albero IS 'DWH del flusso PUBBLICAZIONE_ALBERO';
COMMENT ON CONSTRAINT uq_dwh_pubblicazione_albero ON hcbi_ras.dwh_pubblicazione_albero IS 'Business key del flusso PUBBLICAZIONE_ALBERO';

/* =====================================================================
   VISTA DWH
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_dwh_pubblicazione_albero AS
SELECT
    s.ds_anno_pubblicazione,
    s.id_sorgente_provincia,
    s.cd_articolo,
    s.ds_articolo,
    s.nr_prezzo,
    s.id_sorgente_um,
    s.fl_isanalisi,
    s.fl_isincidenza,
    s.cd_versione,
    s.nr_scostamento,
    s.nr_scostamento_con_spese,
    s.fl_is_nuovo_codice,
    s.fl_is_prezzo_modificato,
    s.fl_is_prezzo_con_spese_modificato,
    s.fl_is_analisi_modificata,
    s.fl_is_descrizione_modificata,
    s.fl_is_uinta_misura_modificata,
    s.fl_is_spese_generali_modificate,
    s.fl_is_utili_impresa_modificati,
    s.fl_is_oneri_sicurezza_modificati,
    s.ds_descrizione_de,
    s.fl_is_ufficiale,
    s.id_sorgente_categoria,
    s.ds_nome,
    s.ds_nome_de,
    s.fl_is_nome_modificato,
    s.ds_link_cam,
    s.ds_annotazione,
    s.ds_annotazione_de,
    s.id_sorgente_pubblicazione_albero,
    s.fl_esporta_come_articolo,
    s.fl_escludi_manodopera,
    s.fl_mostra_struttura_analisi,
    s.nr_macro_gruppo,
    s.fl_is_cam
FROM hcbi_ras.stg_pubblicazione_albero AS s;
ALTER TABLE hcbi_ras.v_dwh_pubblicazione_albero OWNER TO hcbi_ras;
GRANT ALL ON TABLE hcbi_ras.v_dwh_pubblicazione_albero TO hcbi_ras;
GRANT SELECT ON TABLE hcbi_ras.v_dwh_pubblicazione_albero TO hcbi_utility;
COMMENT ON VIEW hcbi_ras.v_dwh_pubblicazione_albero IS 'Vista di raccordo tra STG e DWH del flusso PUBBLICAZIONE_ALBERO';

/* =====================================================================
   FUNZIONI DI CONVERSIONE SICURA
   ===================================================================== */
CREATE OR REPLACE FUNCTION hcbi_ras.try_numeric_10_0(p_value text)
RETURNS numeric(10,0)
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT
SECURITY INVOKER SET search_path TO pg_catalog
AS $function$
BEGIN
    RETURN p_value::numeric(10,0);
EXCEPTION
    WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$;
ALTER FUNCTION hcbi_ras.try_numeric_10_0(text) OWNER TO hcbi_ras;

CREATE OR REPLACE FUNCTION hcbi_ras.try_numeric_24_5(p_value text)
RETURNS numeric(24,5)
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT
SECURITY INVOKER SET search_path TO pg_catalog
AS $function$
BEGIN
    RETURN p_value::numeric(24,5);
EXCEPTION
    WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$;
ALTER FUNCTION hcbi_ras.try_numeric_24_5(text) OWNER TO hcbi_ras;

CREATE OR REPLACE FUNCTION hcbi_ras.try_smallint(p_value text)
RETURNS smallint
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT
SECURITY INVOKER SET search_path TO pg_catalog
AS $function$
BEGIN
    RETURN p_value::smallint;
EXCEPTION
    WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$;
ALTER FUNCTION hcbi_ras.try_smallint(text) OWNER TO hcbi_ras;

CREATE OR REPLACE FUNCTION hcbi_ras.try_bigint(p_value text)
RETURNS bigint
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT
SECURITY INVOKER SET search_path TO pg_catalog
AS $function$
BEGIN
    RETURN p_value::bigint;
EXCEPTION
    WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$;
ALTER FUNCTION hcbi_ras.try_bigint(text) OWNER TO hcbi_ras;

CREATE OR REPLACE FUNCTION hcbi_ras.try_integer(p_value text)
RETURNS integer
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT
SECURITY INVOKER SET search_path TO pg_catalog
AS $function$
BEGIN
    RETURN p_value::integer;
EXCEPTION
    WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$;
ALTER FUNCTION hcbi_ras.try_integer(text) OWNER TO hcbi_ras;

CREATE OR REPLACE FUNCTION hcbi_ras.try_double_precision(p_value text)
RETURNS double precision
LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT
SECURITY INVOKER SET search_path TO pg_catalog
AS $function$
BEGIN
    RETURN p_value::double precision;
EXCEPTION
    WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL;
END;
$function$;
ALTER FUNCTION hcbi_ras.try_double_precision(text) OWNER TO hcbi_ras;

CREATE OR REPLACE FUNCTION hcbi_ras.try_flag_smallint(p_value text)
RETURNS smallint
LANGUAGE sql IMMUTABLE PARALLEL SAFE RETURNS NULL ON NULL INPUT
SECURITY INVOKER SET search_path TO pg_catalog
AS $function$
    SELECT CASE lower(btrim(p_value))
        WHEN 'true' THEN 1::smallint WHEN 'false' THEN 0::smallint
        WHEN '1' THEN 1::smallint WHEN '0' THEN 0::smallint
        ELSE NULL::smallint END;
$function$;
ALTER FUNCTION hcbi_ras.try_flag_smallint(text) OWNER TO hcbi_ras;
COMMENT ON FUNCTION hcbi_ras.try_flag_smallint(text) IS 'Converte true/false/1/0 in smallint; restituisce NULL per valori non riconosciuti.';

/* =====================================================================
   PROCEDURA STG INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_initialize(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog, hcbi_ras, hcbi_utility
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
    SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
    TRUNCATE TABLE hcbi_ras.stg_pubblicazione_albero;
    TRUNCATE TABLE hcbi_ras.stg_pubblicazione_albero_rej;
    CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT,
            v_sql_detail = PG_EXCEPTION_DETAIL, v_sql_hint = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;
        p_result := -1;
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
            CASE WHEN nullif(v_sql_detail, '') IS NOT NULL THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
            CASE WHEN nullif(v_sql_hint, '') IS NOT NULL THEN 'HINT=' || left(v_sql_hint, 500) END,
            CASE WHEN nullif(v_sql_context, '') IS NOT NULL THEN 'CONTEXT=' || left(v_sql_context, 800) END), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log, 'FAILED', v_log_error, clock_timestamp()::timestamp, p_ds_step_name);
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore durante la registrazione del log: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_stg_pubblicazione_albero_prc_initialize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_initialize(bigint, bigint, bigint, character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_initialize(bigint, bigint, bigint, character varying) TO PUBLIC;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_initialize(bigint, bigint, bigint, character varying) TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_initialize(bigint, bigint, bigint, character varying) TO hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_initialize(bigint, bigint, bigint, character varying) IS 'Inizializza il caricamento STG PUBBLICAZIONE_ALBERO, svuota STG e REJ e registra il log.';

/* =====================================================================
   PROCEDURA STG MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
    v_selected bigint := 0; v_inserted bigint := 0; v_updated bigint := 0; v_deleted bigint := 0; v_rec_errors bigint := 0;
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
    DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_albero_classificata;
    CREATE TABLE hcbi_ras.tmp_pubblicazione_albero_classificata AS
    WITH src AS MATERIALIZED (
        SELECT f.*,
            NULLIF(btrim(f.ds_anno_pubblicazione::text), '') AS anno_txt,
            NULLIF(btrim(f.id_sorgente_provincia::text), '') AS provincia_txt,
            NULLIF(btrim(f.cd_articolo::text), '') AS articolo_txt,
            NULLIF(btrim(f.ds_articolo::text), '') AS descrizione_txt,
            NULLIF(replace(btrim(f.nr_prezzo::text), ',', '.'), '') AS prezzo_txt,
            NULLIF(btrim(f.id_sorgente_um::text), '') AS um_txt,
            NULLIF(btrim(f.fl_isanalisi::text), '') AS isanalisi_txt,
            NULLIF(btrim(f.fl_isincidenza::text), '') AS isincidenza_txt,
            NULLIF(btrim(f.cd_versione::text), '') AS versione_txt,
            NULLIF(replace(btrim(f.nr_scostamento::text), ',', '.'), '') AS scostamento_txt,
            NULLIF(replace(btrim(f.nr_scostamento_con_spese::text), ',', '.'), '') AS scostamento_spese_txt,
            NULLIF(btrim(f.fl_is_nuovo_codice::text), '') AS is_nuovo_codice_txt,
            NULLIF(btrim(f.fl_is_prezzo_modificato::text), '') AS is_prezzo_modificato_txt,
            NULLIF(btrim(f.fl_is_prezzo_con_spese_modificato::text), '') AS is_prezzo_spese_modificato_txt,
            NULLIF(btrim(f.fl_is_analisi_modificata::text), '') AS is_analisi_modificata_txt,
            NULLIF(btrim(f.fl_is_descrizione_modificata::text), '') AS is_descrizione_modificata_txt,
            NULLIF(btrim(f.fl_is_uinta_misura_modificata::text), '') AS is_unita_misura_modificata_txt,
            NULLIF(btrim(f.fl_is_spese_generali_modificate::text), '') AS is_spese_generali_modificate_txt,
            NULLIF(btrim(f.fl_is_utili_impresa_modificati::text), '') AS is_utili_impresa_modificati_txt,
            NULLIF(btrim(f.fl_is_oneri_sicurezza_modificati::text), '') AS is_oneri_sicurezza_modificati_txt,
            NULLIF(btrim(f.ds_descrizione_de::text), '') AS descrizione_de_txt,
            NULLIF(btrim(f.fl_is_ufficiale::text), '') AS is_ufficiale_txt,
            NULLIF(btrim(f.id_sorgente_categoria::text), '') AS categoria_txt,
            NULLIF(btrim(f.ds_nome::text), '') AS nome_txt,
            NULLIF(btrim(f.ds_nome_de::text), '') AS nome_de_txt,
            NULLIF(btrim(f.fl_is_nome_modificato::text), '') AS is_nome_modificato_txt,
            NULLIF(btrim(f.ds_link_cam::text), '') AS link_cam_txt,
            NULLIF(btrim(f.ds_annotazione::text), '') AS annotazione_txt,
            NULLIF(btrim(f.ds_annotazione_de::text), '') AS annotazione_de_txt,
            NULLIF(btrim(f.id_sorgente_pubblicazione_albero::text), '') AS id_pubblicazione_txt,
            NULLIF(btrim(f.fl_esporta_come_articolo::text), '') AS esporta_articolo_txt,
            NULLIF(btrim(f.fl_escludi_manodopera::text), '') AS escludi_manodopera_txt,
            NULLIF(btrim(f.fl_mostra_struttura_analisi::text), '') AS mostra_struttura_txt,
            NULLIF(btrim(f.nr_macro_gruppo::text), '') AS macro_gruppo_txt,
            NULLIF(btrim(f.fl_is_cam::text), '') AS is_cam_txt,
            count(*) OVER (PARTITION BY f.ds_anno_pubblicazione,f.id_sorgente_provincia,f.cd_articolo,f.cd_versione) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_pubblicazione_albero AS f
    ), converted AS MATERIALIZED (
        SELECT s.*,
            hcbi_ras.try_numeric_10_0(s.anno_txt) AS ds_anno_pubblicazione_convertito,
            hcbi_ras.try_numeric_10_0(s.provincia_txt) AS id_sorgente_provincia_convertito,
            hcbi_ras.try_numeric_24_5(s.prezzo_txt) AS nr_prezzo_convertito,
            hcbi_ras.try_numeric_10_0(s.um_txt) AS id_sorgente_um_convertito,
            hcbi_ras.try_flag_smallint(s.isanalisi_txt) AS fl_isanalisi_convertito,
            hcbi_ras.try_flag_smallint(s.isincidenza_txt) AS fl_isincidenza_convertito,
            hcbi_ras.try_smallint(s.versione_txt) AS cd_versione_convertito,
            hcbi_ras.try_double_precision(s.scostamento_txt) AS nr_scostamento_convertito,
            hcbi_ras.try_double_precision(s.scostamento_spese_txt) AS nr_scostamento_con_spese_convertito,
            hcbi_ras.try_flag_smallint(s.is_nuovo_codice_txt) AS fl_is_nuovo_codice_convertito,
            hcbi_ras.try_flag_smallint(s.is_prezzo_modificato_txt) AS fl_is_prezzo_modificato_convertito,
            hcbi_ras.try_flag_smallint(s.is_prezzo_spese_modificato_txt) AS fl_is_prezzo_con_spese_modificato_convertito,
            hcbi_ras.try_flag_smallint(s.is_analisi_modificata_txt) AS fl_is_analisi_modificata_convertito,
            hcbi_ras.try_flag_smallint(s.is_descrizione_modificata_txt) AS fl_is_descrizione_modificata_convertito,
            hcbi_ras.try_flag_smallint(s.is_unita_misura_modificata_txt) AS fl_is_uinta_misura_modificata_convertito,
            hcbi_ras.try_flag_smallint(s.is_spese_generali_modificate_txt) AS fl_is_spese_generali_modificate_convertito,
            hcbi_ras.try_flag_smallint(s.is_utili_impresa_modificati_txt) AS fl_is_utili_impresa_modificati_convertito,
            hcbi_ras.try_flag_smallint(s.is_oneri_sicurezza_modificati_txt) AS fl_is_oneri_sicurezza_modificati_convertito,
            hcbi_ras.try_flag_smallint(s.is_ufficiale_txt) AS fl_is_ufficiale_convertito,
            hcbi_ras.try_bigint(s.categoria_txt) AS id_sorgente_categoria_convertito,
            hcbi_ras.try_flag_smallint(s.is_nome_modificato_txt) AS fl_is_nome_modificato_convertito,
            hcbi_ras.try_bigint(s.id_pubblicazione_txt) AS id_sorgente_pubblicazione_albero_convertito,
            hcbi_ras.try_flag_smallint(s.esporta_articolo_txt) AS fl_esporta_come_articolo_convertito,
            hcbi_ras.try_flag_smallint(s.escludi_manodopera_txt) AS fl_escludi_manodopera_convertito,
            hcbi_ras.try_flag_smallint(s.mostra_struttura_txt) AS fl_mostra_struttura_analisi_convertito,
            hcbi_ras.try_integer(s.macro_gruppo_txt) AS nr_macro_gruppo_convertito,
            hcbi_ras.try_flag_smallint(s.is_cam_txt) AS fl_is_cam_convertito
        FROM src AS s
    )
    SELECT c.*,
        CASE
            WHEN c.duplicate_count > 1 THEN 'Chiave duplicata nella sorgente: (ds_anno_pubblicazione, id_sorgente_provincia, cd_articolo, cd_versione)'
            WHEN c.anno_txt IS NULL THEN 'ds_anno_pubblicazione obbligatorio'
            WHEN c.ds_anno_pubblicazione_convertito IS NULL THEN 'ds_anno_pubblicazione non convertibile in numeric(10,0)'
            WHEN c.provincia_txt IS NULL THEN 'id_sorgente_provincia obbligatorio'
            WHEN c.id_sorgente_provincia_convertito IS NULL THEN 'id_sorgente_provincia non convertibile in numeric(10,0)'
            WHEN c.articolo_txt IS NULL THEN 'cd_articolo obbligatorio'
            WHEN c.versione_txt IS NULL THEN 'cd_versione obbligatorio'
            WHEN c.cd_versione_convertito IS NULL THEN 'cd_versione non convertibile in smallint'
            WHEN c.prezzo_txt IS NOT NULL AND c.nr_prezzo_convertito IS NULL THEN 'nr_prezzo non convertibile in numeric(24,5)'
            WHEN c.um_txt IS NOT NULL AND c.id_sorgente_um_convertito IS NULL THEN 'id_sorgente_um non convertibile in numeric(10,0)'
            WHEN c.isanalisi_txt IS NOT NULL AND c.fl_isanalisi_convertito IS NULL THEN 'fl_isanalisi non convertibile in smallint'
            WHEN c.isincidenza_txt IS NOT NULL AND c.fl_isincidenza_convertito IS NULL THEN 'fl_isincidenza non convertibile in smallint'
            WHEN c.scostamento_txt IS NOT NULL AND c.nr_scostamento_convertito IS NULL THEN 'nr_scostamento non convertibile in double precision'
            WHEN c.scostamento_spese_txt IS NOT NULL AND c.nr_scostamento_con_spese_convertito IS NULL THEN 'nr_scostamento_con_spese non convertibile in double precision'
            WHEN c.is_nuovo_codice_txt IS NOT NULL AND c.fl_is_nuovo_codice_convertito IS NULL THEN 'fl_is_nuovo_codice non convertibile in smallint'
            WHEN c.is_prezzo_modificato_txt IS NOT NULL AND c.fl_is_prezzo_modificato_convertito IS NULL THEN 'fl_is_prezzo_modificato non convertibile in smallint'
            WHEN c.is_prezzo_spese_modificato_txt IS NOT NULL AND c.fl_is_prezzo_con_spese_modificato_convertito IS NULL THEN 'fl_is_prezzo_con_spese_modificato non convertibile in smallint'
            WHEN c.is_analisi_modificata_txt IS NOT NULL AND c.fl_is_analisi_modificata_convertito IS NULL THEN 'fl_is_analisi_modificata non convertibile in smallint'
            WHEN c.is_descrizione_modificata_txt IS NOT NULL AND c.fl_is_descrizione_modificata_convertito IS NULL THEN 'fl_is_descrizione_modificata non convertibile in smallint'
            WHEN c.is_unita_misura_modificata_txt IS NOT NULL AND c.fl_is_uinta_misura_modificata_convertito IS NULL THEN 'fl_is_uinta_misura_modificata non convertibile in smallint'
            WHEN c.is_spese_generali_modificate_txt IS NOT NULL AND c.fl_is_spese_generali_modificate_convertito IS NULL THEN 'fl_is_spese_generali_modificate non convertibile in smallint'
            WHEN c.is_utili_impresa_modificati_txt IS NOT NULL AND c.fl_is_utili_impresa_modificati_convertito IS NULL THEN 'fl_is_utili_impresa_modificati non convertibile in smallint'
            WHEN c.is_oneri_sicurezza_modificati_txt IS NOT NULL AND c.fl_is_oneri_sicurezza_modificati_convertito IS NULL THEN 'fl_is_oneri_sicurezza_modificati non convertibile in smallint'
            WHEN c.is_ufficiale_txt IS NOT NULL AND c.fl_is_ufficiale_convertito IS NULL THEN 'fl_is_ufficiale non convertibile in smallint'
            WHEN c.categoria_txt IS NOT NULL AND c.id_sorgente_categoria_convertito IS NULL THEN 'id_sorgente_categoria non convertibile in bigint'
            WHEN c.is_nome_modificato_txt IS NOT NULL AND c.fl_is_nome_modificato_convertito IS NULL THEN 'fl_is_nome_modificato non convertibile in smallint'
            WHEN c.id_pubblicazione_txt IS NOT NULL AND c.id_sorgente_pubblicazione_albero_convertito IS NULL THEN 'id_sorgente_pubblicazione_albero non convertibile in bigint'
            WHEN c.esporta_articolo_txt IS NOT NULL AND c.fl_esporta_come_articolo_convertito IS NULL THEN 'fl_esporta_come_articolo non convertibile in smallint'
            WHEN c.escludi_manodopera_txt IS NOT NULL AND c.fl_escludi_manodopera_convertito IS NULL THEN 'fl_escludi_manodopera non convertibile in smallint'
            WHEN c.mostra_struttura_txt IS NOT NULL AND c.fl_mostra_struttura_analisi_convertito IS NULL THEN 'fl_mostra_struttura_analisi non convertibile in smallint'
            WHEN c.macro_gruppo_txt IS NOT NULL AND c.nr_macro_gruppo_convertito IS NULL THEN 'nr_macro_gruppo non convertibile in integer'
            WHEN c.is_cam_txt IS NOT NULL AND c.fl_is_cam_convertito IS NULL THEN 'fl_is_cam non convertibile in smallint'
            ELSE NULL END::text AS tx_motivo_scarto
    FROM converted AS c;
    SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_pubblicazione_albero_classificata;
    INSERT INTO hcbi_ras.stg_pubblicazione_albero (
        ds_anno_pubblicazione,
        id_sorgente_provincia,
        cd_articolo,
        ds_articolo,
        nr_prezzo,
        id_sorgente_um,
        fl_isanalisi,
        fl_isincidenza,
        cd_versione,
        nr_scostamento,
        nr_scostamento_con_spese,
        fl_is_nuovo_codice,
        fl_is_prezzo_modificato,
        fl_is_prezzo_con_spese_modificato,
        fl_is_analisi_modificata,
        fl_is_descrizione_modificata,
        fl_is_uinta_misura_modificata,
        fl_is_spese_generali_modificate,
        fl_is_utili_impresa_modificati,
        fl_is_oneri_sicurezza_modificati,
        ds_descrizione_de,
        fl_is_ufficiale,
        id_sorgente_categoria,
        ds_nome,
        ds_nome_de,
        fl_is_nome_modificato,
        ds_link_cam,
        ds_annotazione,
        ds_annotazione_de,
        id_sorgente_pubblicazione_albero,
        fl_esporta_come_articolo,
        fl_escludi_manodopera,
        fl_mostra_struttura_analisi,
        nr_macro_gruppo,
        fl_is_cam
    )
    SELECT
        c.ds_anno_pubblicazione_convertito,
        c.id_sorgente_provincia_convertito,
        c.articolo_txt,
        c.descrizione_txt,
        c.nr_prezzo_convertito,
        c.id_sorgente_um_convertito,
        c.fl_isanalisi_convertito,
        c.fl_isincidenza_convertito,
        c.cd_versione_convertito,
        c.nr_scostamento_convertito,
        c.nr_scostamento_con_spese_convertito,
        c.fl_is_nuovo_codice_convertito,
        c.fl_is_prezzo_modificato_convertito,
        c.fl_is_prezzo_con_spese_modificato_convertito,
        c.fl_is_analisi_modificata_convertito,
        c.fl_is_descrizione_modificata_convertito,
        c.fl_is_uinta_misura_modificata_convertito,
        c.fl_is_spese_generali_modificate_convertito,
        c.fl_is_utili_impresa_modificati_convertito,
        c.fl_is_oneri_sicurezza_modificati_convertito,
        c.descrizione_de_txt,
        c.fl_is_ufficiale_convertito,
        c.id_sorgente_categoria_convertito,
        c.nome_txt,
        c.nome_de_txt,
        c.fl_is_nome_modificato_convertito,
        c.link_cam_txt,
        c.annotazione_txt,
        c.annotazione_de_txt,
        c.id_sorgente_pubblicazione_albero_convertito,
        c.fl_esporta_come_articolo_convertito,
        c.fl_escludi_manodopera_convertito,
        c.fl_mostra_struttura_analisi_convertito,
        c.nr_macro_gruppo_convertito,
        c.fl_is_cam_convertito
    FROM hcbi_ras.tmp_pubblicazione_albero_classificata AS c
    WHERE c.tx_motivo_scarto IS NULL;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;
    INSERT INTO hcbi_ras.stg_pubblicazione_albero_rej (
        ds_anno_pubblicazione,
        id_sorgente_provincia,
        cd_articolo,
        ds_articolo,
        nr_prezzo,
        id_sorgente_um,
        fl_isanalisi,
        fl_isincidenza,
        cd_versione,
        nr_scostamento,
        nr_scostamento_con_spese,
        fl_is_nuovo_codice,
        fl_is_prezzo_modificato,
        fl_is_prezzo_con_spese_modificato,
        fl_is_analisi_modificata,
        fl_is_descrizione_modificata,
        fl_is_uinta_misura_modificata,
        fl_is_spese_generali_modificate,
        fl_is_utili_impresa_modificati,
        fl_is_oneri_sicurezza_modificati,
        ds_descrizione_de,
        fl_is_ufficiale,
        id_sorgente_categoria,
        ds_nome,
        ds_nome_de,
        fl_is_nome_modificato,
        ds_link_cam,
        ds_annotazione,
        ds_annotazione_de,
        id_sorgente_pubblicazione_albero,
        fl_esporta_come_articolo,
        fl_escludi_manodopera,
        fl_mostra_struttura_analisi,
        nr_macro_gruppo,
        fl_is_cam,
        tx_motivo_scarto
    )
    SELECT
        c.ds_anno_pubblicazione,
        c.id_sorgente_provincia,
        c.cd_articolo,
        c.ds_articolo,
        c.nr_prezzo,
        c.id_sorgente_um,
        c.fl_isanalisi,
        c.fl_isincidenza,
        c.cd_versione,
        c.nr_scostamento,
        c.nr_scostamento_con_spese,
        c.fl_is_nuovo_codice,
        c.fl_is_prezzo_modificato,
        c.fl_is_prezzo_con_spese_modificato,
        c.fl_is_analisi_modificata,
        c.fl_is_descrizione_modificata,
        c.fl_is_uinta_misura_modificata,
        c.fl_is_spese_generali_modificate,
        c.fl_is_utili_impresa_modificati,
        c.fl_is_oneri_sicurezza_modificati,
        c.ds_descrizione_de,
        c.fl_is_ufficiale,
        c.id_sorgente_categoria,
        c.ds_nome,
        c.ds_nome_de,
        c.fl_is_nome_modificato,
        c.ds_link_cam,
        c.ds_annotazione,
        c.ds_annotazione_de,
        c.id_sorgente_pubblicazione_albero,
        c.fl_esporta_come_articolo,
        c.fl_escludi_manodopera,
        c.fl_mostra_struttura_analisi,
        c.nr_macro_gruppo,
        c.fl_is_cam,
        c.tx_motivo_scarto
    FROM hcbi_ras.tmp_pubblicazione_albero_classificata AS c
    WHERE c.tx_motivo_scarto IS NOT NULL;
    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;
    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE=format('Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',v_selected,v_inserted,v_rec_errors);
    END IF;
    CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_albero_classificata;
    p_result := 1;
    RAISE NOTICE 'Fine STG PUBBLICAZIONE_ALBERO: selected=%, inserted=%, rejected=%',v_selected,v_inserted,v_rec_errors;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT,
            v_sql_detail = PG_EXCEPTION_DETAIL, v_sql_hint = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;
        p_result := -1;
        BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_albero_classificata; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM; END;
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
            CASE WHEN nullif(v_sql_detail, '') IS NOT NULL THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
            CASE WHEN nullif(v_sql_hint, '') IS NOT NULL THEN 'HINT=' || left(v_sql_hint, 500) END,
            CASE WHEN nullif(v_sql_context, '') IS NOT NULL THEN 'CONTEXT=' || left(v_sql_context, 800) END), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log, 'FAILED', v_log_error, clock_timestamp()::timestamp, p_ds_step_name);
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore durante la registrazione del log: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_stg_pubblicazione_albero_prc_main. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_main(bigint, bigint, bigint, character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_main(bigint, bigint, bigint, character varying) TO PUBLIC;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_main(bigint, bigint, bigint, character varying) TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_main(bigint, bigint, bigint, character varying) TO hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_main(bigint, bigint, bigint, character varying) IS 'Classifica e carica in modalita set-based la STG PUBBLICAZIONE_ALBERO, valida le conversioni, gestisce duplicati e scarti e riconcilia i conteggi.';

/* =====================================================================
   PROCEDURA STG FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_finalize(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog, hcbi_ras, hcbi_utility
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
    SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
    ANALYZE hcbi_ras.stg_pubblicazione_albero;
    ANALYZE hcbi_ras.stg_pubblicazione_albero_rej;
    CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT,
            v_sql_detail = PG_EXCEPTION_DETAIL, v_sql_hint = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;
        p_result := -1;
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
            CASE WHEN nullif(v_sql_detail, '') IS NOT NULL THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
            CASE WHEN nullif(v_sql_hint, '') IS NOT NULL THEN 'HINT=' || left(v_sql_hint, 500) END,
            CASE WHEN nullif(v_sql_context, '') IS NOT NULL THEN 'CONTEXT=' || left(v_sql_context, 800) END), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log, 'FAILED', v_log_error, clock_timestamp()::timestamp, p_ds_step_name);
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore durante la registrazione del log: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_stg_pubblicazione_albero_prc_finalize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_finalize(bigint, bigint, bigint, character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_finalize(bigint, bigint, bigint, character varying) TO PUBLIC;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_finalize(bigint, bigint, bigint, character varying) TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_finalize(bigint, bigint, bigint, character varying) TO hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_albero_prc_finalize(bigint, bigint, bigint, character varying) IS 'Finalize del flusso STG PUBBLICAZIONE_ALBERO con logging e diagnostica completa.';

/* =====================================================================
   PROCEDURA DWH INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_initialize(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog, hcbi_ras, hcbi_utility
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
    SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
    CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT,
            v_sql_detail = PG_EXCEPTION_DETAIL, v_sql_hint = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;
        p_result := -1;
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
            CASE WHEN nullif(v_sql_detail, '') IS NOT NULL THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
            CASE WHEN nullif(v_sql_hint, '') IS NOT NULL THEN 'HINT=' || left(v_sql_hint, 500) END,
            CASE WHEN nullif(v_sql_context, '') IS NOT NULL THEN 'CONTEXT=' || left(v_sql_context, 800) END), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log, 'FAILED', v_log_error, clock_timestamp()::timestamp, p_ds_step_name);
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore durante la registrazione del log: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_dwh_pubblicazione_albero_prc_initialize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_initialize(bigint, bigint, bigint, character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_initialize(bigint, bigint, bigint, character varying) TO PUBLIC;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_initialize(bigint, bigint, bigint, character varying) TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_initialize(bigint, bigint, bigint, character varying) TO hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_initialize(bigint, bigint, bigint, character varying) IS 'Initialize del flusso DWH PUBBLICAZIONE_ALBERO con logging e diagnostica completa.';

/* =====================================================================
   PROCEDURA DWH FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_finalize(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog, hcbi_ras, hcbi_utility
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
    SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
    ANALYZE hcbi_ras.dwh_pubblicazione_albero;
    CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT,
            v_sql_detail = PG_EXCEPTION_DETAIL, v_sql_hint = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;
        p_result := -1;
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
            CASE WHEN nullif(v_sql_detail, '') IS NOT NULL THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
            CASE WHEN nullif(v_sql_hint, '') IS NOT NULL THEN 'HINT=' || left(v_sql_hint, 500) END,
            CASE WHEN nullif(v_sql_context, '') IS NOT NULL THEN 'CONTEXT=' || left(v_sql_context, 800) END), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log, 'FAILED', v_log_error, clock_timestamp()::timestamp, p_ds_step_name);
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore durante la registrazione del log: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_dwh_pubblicazione_albero_prc_finalize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_finalize(bigint, bigint, bigint, character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_finalize(bigint, bigint, bigint, character varying) TO PUBLIC;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_finalize(bigint, bigint, bigint, character varying) TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_finalize(bigint, bigint, bigint, character varying) TO hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_finalize(bigint, bigint, bigint, character varying) IS 'Finalize del flusso DWH PUBBLICAZIONE_ALBERO con logging e diagnostica completa.';

/* =====================================================================
   PROCEDURA DWH MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
    v_selected bigint := 0; v_inserted bigint := 0; v_updated bigint := 0; v_deleted bigint := 0; v_rec_errors bigint := 0;
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_pubblicazione_albero;
    CREATE TABLE hcbi_ras.tmp_dwh_pubblicazione_albero AS SELECT
        ds_anno_pubblicazione,
        id_sorgente_provincia,
        cd_articolo,
        ds_articolo,
        nr_prezzo,
        id_sorgente_um,
        fl_isanalisi,
        fl_isincidenza,
        cd_versione,
        nr_scostamento,
        nr_scostamento_con_spese,
        fl_is_nuovo_codice,
        fl_is_prezzo_modificato,
        fl_is_prezzo_con_spese_modificato,
        fl_is_analisi_modificata,
        fl_is_descrizione_modificata,
        fl_is_uinta_misura_modificata,
        fl_is_spese_generali_modificate,
        fl_is_utili_impresa_modificati,
        fl_is_oneri_sicurezza_modificati,
        ds_descrizione_de,
        fl_is_ufficiale,
        id_sorgente_categoria,
        ds_nome,
        ds_nome_de,
        fl_is_nome_modificato,
        ds_link_cam,
        ds_annotazione,
        ds_annotazione_de,
        id_sorgente_pubblicazione_albero,
        fl_esporta_come_articolo,
        fl_escludi_manodopera,
        fl_mostra_struttura_analisi,
        nr_macro_gruppo,
        fl_is_cam
    FROM hcbi_ras.v_dwh_pubblicazione_albero;
    CREATE UNIQUE INDEX tmp_dwh_pubblicazione_albero_uq ON hcbi_ras.tmp_dwh_pubblicazione_albero (ds_anno_pubblicazione,id_sorgente_provincia,cd_articolo,cd_versione) NULLS NOT DISTINCT;
    ANALYZE hcbi_ras.tmp_dwh_pubblicazione_albero;
    SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_dwh_pubblicazione_albero;
    UPDATE hcbi_ras.dwh_pubblicazione_albero AS dwh SET
        ds_articolo = src.ds_articolo,
        nr_prezzo = src.nr_prezzo,
        id_sorgente_um = src.id_sorgente_um,
        fl_isanalisi = src.fl_isanalisi,
        fl_isincidenza = src.fl_isincidenza,
        nr_scostamento = src.nr_scostamento,
        nr_scostamento_con_spese = src.nr_scostamento_con_spese,
        fl_is_nuovo_codice = src.fl_is_nuovo_codice,
        fl_is_prezzo_modificato = src.fl_is_prezzo_modificato,
        fl_is_prezzo_con_spese_modificato = src.fl_is_prezzo_con_spese_modificato,
        fl_is_analisi_modificata = src.fl_is_analisi_modificata,
        fl_is_descrizione_modificata = src.fl_is_descrizione_modificata,
        fl_is_uinta_misura_modificata = src.fl_is_uinta_misura_modificata,
        fl_is_spese_generali_modificate = src.fl_is_spese_generali_modificate,
        fl_is_utili_impresa_modificati = src.fl_is_utili_impresa_modificati,
        fl_is_oneri_sicurezza_modificati = src.fl_is_oneri_sicurezza_modificati,
        ds_descrizione_de = src.ds_descrizione_de,
        fl_is_ufficiale = src.fl_is_ufficiale,
        id_sorgente_categoria = src.id_sorgente_categoria,
        ds_nome = src.ds_nome,
        ds_nome_de = src.ds_nome_de,
        fl_is_nome_modificato = src.fl_is_nome_modificato,
        ds_link_cam = src.ds_link_cam,
        ds_annotazione = src.ds_annotazione,
        ds_annotazione_de = src.ds_annotazione_de,
        id_sorgente_pubblicazione_albero = src.id_sorgente_pubblicazione_albero,
        fl_esporta_come_articolo = src.fl_esporta_come_articolo,
        fl_escludi_manodopera = src.fl_escludi_manodopera,
        fl_mostra_struttura_analisi = src.fl_mostra_struttura_analisi,
        nr_macro_gruppo = src.nr_macro_gruppo,
        fl_is_cam = src.fl_is_cam,
        dt_update = clock_timestamp(),
        tx_update_by = p_ds_step_name
    FROM hcbi_ras.tmp_dwh_pubblicazione_albero AS src
    WHERE dwh.ds_anno_pubblicazione=src.ds_anno_pubblicazione
      AND dwh.id_sorgente_provincia=src.id_sorgente_provincia
      AND dwh.cd_articolo=src.cd_articolo
      AND dwh.cd_versione=src.cd_versione
      AND (
dwh.ds_articolo IS DISTINCT FROM src.ds_articolo
        OR dwh.nr_prezzo IS DISTINCT FROM src.nr_prezzo
        OR dwh.id_sorgente_um IS DISTINCT FROM src.id_sorgente_um
        OR dwh.fl_isanalisi IS DISTINCT FROM src.fl_isanalisi
        OR dwh.fl_isincidenza IS DISTINCT FROM src.fl_isincidenza
        OR dwh.nr_scostamento IS DISTINCT FROM src.nr_scostamento
        OR dwh.nr_scostamento_con_spese IS DISTINCT FROM src.nr_scostamento_con_spese
        OR dwh.fl_is_nuovo_codice IS DISTINCT FROM src.fl_is_nuovo_codice
        OR dwh.fl_is_prezzo_modificato IS DISTINCT FROM src.fl_is_prezzo_modificato
        OR dwh.fl_is_prezzo_con_spese_modificato IS DISTINCT FROM src.fl_is_prezzo_con_spese_modificato
        OR dwh.fl_is_analisi_modificata IS DISTINCT FROM src.fl_is_analisi_modificata
        OR dwh.fl_is_descrizione_modificata IS DISTINCT FROM src.fl_is_descrizione_modificata
        OR dwh.fl_is_uinta_misura_modificata IS DISTINCT FROM src.fl_is_uinta_misura_modificata
        OR dwh.fl_is_spese_generali_modificate IS DISTINCT FROM src.fl_is_spese_generali_modificate
        OR dwh.fl_is_utili_impresa_modificati IS DISTINCT FROM src.fl_is_utili_impresa_modificati
        OR dwh.fl_is_oneri_sicurezza_modificati IS DISTINCT FROM src.fl_is_oneri_sicurezza_modificati
        OR dwh.ds_descrizione_de IS DISTINCT FROM src.ds_descrizione_de
        OR dwh.fl_is_ufficiale IS DISTINCT FROM src.fl_is_ufficiale
        OR dwh.id_sorgente_categoria IS DISTINCT FROM src.id_sorgente_categoria
        OR dwh.ds_nome IS DISTINCT FROM src.ds_nome
        OR dwh.ds_nome_de IS DISTINCT FROM src.ds_nome_de
        OR dwh.fl_is_nome_modificato IS DISTINCT FROM src.fl_is_nome_modificato
        OR dwh.ds_link_cam IS DISTINCT FROM src.ds_link_cam
        OR dwh.ds_annotazione IS DISTINCT FROM src.ds_annotazione
        OR dwh.ds_annotazione_de IS DISTINCT FROM src.ds_annotazione_de
        OR dwh.id_sorgente_pubblicazione_albero IS DISTINCT FROM src.id_sorgente_pubblicazione_albero
        OR dwh.fl_esporta_come_articolo IS DISTINCT FROM src.fl_esporta_come_articolo
        OR dwh.fl_escludi_manodopera IS DISTINCT FROM src.fl_escludi_manodopera
        OR dwh.fl_mostra_struttura_analisi IS DISTINCT FROM src.fl_mostra_struttura_analisi
        OR dwh.nr_macro_gruppo IS DISTINCT FROM src.nr_macro_gruppo
        OR dwh.fl_is_cam IS DISTINCT FROM src.fl_is_cam
      );
    GET DIAGNOSTICS v_updated = ROW_COUNT;
    INSERT INTO hcbi_ras.dwh_pubblicazione_albero (
        ds_anno_pubblicazione,
        id_sorgente_provincia,
        cd_articolo,
        ds_articolo,
        nr_prezzo,
        id_sorgente_um,
        fl_isanalisi,
        fl_isincidenza,
        cd_versione,
        nr_scostamento,
        nr_scostamento_con_spese,
        fl_is_nuovo_codice,
        fl_is_prezzo_modificato,
        fl_is_prezzo_con_spese_modificato,
        fl_is_analisi_modificata,
        fl_is_descrizione_modificata,
        fl_is_uinta_misura_modificata,
        fl_is_spese_generali_modificate,
        fl_is_utili_impresa_modificati,
        fl_is_oneri_sicurezza_modificati,
        ds_descrizione_de,
        fl_is_ufficiale,
        id_sorgente_categoria,
        ds_nome,
        ds_nome_de,
        fl_is_nome_modificato,
        ds_link_cam,
        ds_annotazione,
        ds_annotazione_de,
        id_sorgente_pubblicazione_albero,
        fl_esporta_come_articolo,
        fl_escludi_manodopera,
        fl_mostra_struttura_analisi,
        nr_macro_gruppo,
        fl_is_cam,
        dt_creation,tx_creation_by,dt_update,tx_update_by
    )
    SELECT
        src.ds_anno_pubblicazione,
        src.id_sorgente_provincia,
        src.cd_articolo,
        src.ds_articolo,
        src.nr_prezzo,
        src.id_sorgente_um,
        src.fl_isanalisi,
        src.fl_isincidenza,
        src.cd_versione,
        src.nr_scostamento,
        src.nr_scostamento_con_spese,
        src.fl_is_nuovo_codice,
        src.fl_is_prezzo_modificato,
        src.fl_is_prezzo_con_spese_modificato,
        src.fl_is_analisi_modificata,
        src.fl_is_descrizione_modificata,
        src.fl_is_uinta_misura_modificata,
        src.fl_is_spese_generali_modificate,
        src.fl_is_utili_impresa_modificati,
        src.fl_is_oneri_sicurezza_modificati,
        src.ds_descrizione_de,
        src.fl_is_ufficiale,
        src.id_sorgente_categoria,
        src.ds_nome,
        src.ds_nome_de,
        src.fl_is_nome_modificato,
        src.ds_link_cam,
        src.ds_annotazione,
        src.ds_annotazione_de,
        src.id_sorgente_pubblicazione_albero,
        src.fl_esporta_come_articolo,
        src.fl_escludi_manodopera,
        src.fl_mostra_struttura_analisi,
        src.nr_macro_gruppo,
        src.fl_is_cam,
        clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name
    FROM hcbi_ras.tmp_dwh_pubblicazione_albero AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_pubblicazione_albero DO NOTHING;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;
    CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_pubblicazione_albero;
    p_result := 1;
    RAISE NOTICE 'Fine DWH PUBBLICAZIONE_ALBERO: selected=%, inserted=%, updated=%',v_selected,v_inserted,v_updated;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE, v_sqlerrm = MESSAGE_TEXT,
            v_sql_detail = PG_EXCEPTION_DETAIL, v_sql_hint = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;
        p_result := -1;
        BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_pubblicazione_albero; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM; END;
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
            CASE WHEN nullif(v_sql_detail, '') IS NOT NULL THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
            CASE WHEN nullif(v_sql_hint, '') IS NOT NULL THEN 'HINT=' || left(v_sql_hint, 500) END,
            CASE WHEN nullif(v_sql_context, '') IS NOT NULL THEN 'CONTEXT=' || left(v_sql_context, 800) END), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log, 'FAILED', v_log_error, clock_timestamp()::timestamp, p_ds_step_name);
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore durante la registrazione del log: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
            END;
        END IF;
        RAISE WARNING 'Errore in pkg_dwh_pubblicazione_albero_prc_main. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_main(bigint, bigint, bigint, character varying) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_main(bigint, bigint, bigint, character varying) TO PUBLIC;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_main(bigint, bigint, bigint, character varying) TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_main(bigint, bigint, bigint, character varying) TO hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_albero_prc_main(bigint, bigint, bigint, character varying) IS 'Materializza la sorgente DWH, verifica la business key, aggiorna i record variati, inserisce i nuovi e pulisce la tabella di lavoro.';

