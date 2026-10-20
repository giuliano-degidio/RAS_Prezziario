/* ============================================================
   FLUSSO PUBBLICAZIONE_ARTICOLI - VERSIONE 03
   Target: PostgreSQL 15.9 / 17 | Schema: hcbi_ras
   Grain: provincia, anno, codice completo, versione.
   CD_ARTICOLO resta sorgente; il punto finale si rimuove in DIM_ARTICOLO.
   ============================================================ */
/* DROP idempotenti: lo script ricrea integralmente il flusso. */
DROP PROCEDURE IF EXISTS hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_finalize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING);
DROP PROCEDURE IF EXISTS hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_main(BIGINT,BIGINT,BIGINT,CHARACTER VARYING);
DROP PROCEDURE IF EXISTS hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_initialize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING);
DROP PROCEDURE IF EXISTS hcbi_ras.pkg_stg_pubblicazione_articoli_prc_finalize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING);
DROP PROCEDURE IF EXISTS hcbi_ras.pkg_stg_pubblicazione_articoli_prc_main(BIGINT,BIGINT,BIGINT,CHARACTER VARYING);
DROP PROCEDURE IF EXISTS hcbi_ras.pkg_stg_pubblicazione_articoli_prc_initialize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING);
DROP VIEW IF EXISTS hcbi_ras.v_dwh_pubblicazione_articoli CASCADE;
DROP VIEW IF EXISTS hcbi_ras.v_src_tmp_pubblicazione_articoli CASCADE;
DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_articoli_classificata;
DROP TABLE IF EXISTS hcbi_ras.dwh_pubblicazione_articoli CASCADE;
DROP TABLE IF EXISTS hcbi_ras.stg_pubblicazione_articoli_rej CASCADE;
DROP TABLE IF EXISTS hcbi_ras.stg_pubblicazione_articoli CASCADE;
DROP TABLE IF EXISTS hcbi_ras.src_tmp_pubblicazione_articoli CASCADE;
DROP TABLE IF EXISTS hcbi_ras.frontiera_pubblicazione_articoli CASCADE;
DROP SEQUENCE IF EXISTS hcbi_ras.seq_dwh_pubblicazione_articoli CASCADE;

/* ============================================================
   SEQUENCE
   ============================================================ */

CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_pubblicazione_articoli
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_pubblicazione_articoli
    OWNER TO hcbi_ras;

GRANT ALL ON SEQUENCE hcbi_ras.seq_dwh_pubblicazione_articoli
TO hcbi_ras;

GRANT USAGE, SELECT ON SEQUENCE hcbi_ras.seq_dwh_pubblicazione_articoli
TO hcbi_utility;


/* ============================================================
   TABELLA FRONTIERA
   ============================================================ */

CREATE TABLE hcbi_ras.frontiera_pubblicazione_articoli (
	provincia varchar(100) NULL,
	anno varchar(100) NULL,
	codice_completo varchar(70) NULL,
	um varchar(20) NULL,
	prezzo varchar(100) NULL,
	prezan varchar(100) NULL,
	percsp varchar(100) NULL,
	percutil varchar(100) NULL,
	sicur varchar(100) NULL,
	percman varchar(100) NULL,
	perconeri varchar(100) NULL,
	isanalisi varchar(20) NULL,
	prezman varchar(100) NULL,
	addendum varchar(20) NULL,
	codice varchar(60) NULL,
	codice_1 varchar(10) NULL,
	codice_2 varchar(10) NULL,
	codice_3 varchar(10) NULL,
	codice_4 varchar(10) NULL,
	codice_5 varchar(10) NULL,
	um_de varchar(20) NULL,
	id_categoria varchar(20) NULL,
	is_minuteria varchar(20) NULL,
	id varchar(100) NULL,
	percman_diretta varchar(100) NULL,
	prezman_diretta varchar(100) NULL,
	ifc_scaricabile varchar(20) NULL,
	macro_gruppo varchar(20) NULL,
	spese varchar(100) NULL,
	utili varchar(100) NULL
);

ALTER TABLE hcbi_ras.frontiera_pubblicazione_articoli
    OWNER TO hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.frontiera_pubblicazione_articoli
FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.frontiera_pubblicazione_articoli
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.frontiera_pubblicazione_articoli
TO hcbi_utility;


/* ============================================================
   TABELLA SRC_TMP
   ============================================================ */

CREATE TABLE hcbi_ras.src_tmp_pubblicazione_articoli (
	provincia varchar(100) NULL,
	anno varchar(100) NULL,
	codice_completo varchar(70) NULL,
	um varchar(20) NULL,
	prezzo varchar(100) NULL,
	prezan varchar(100) NULL,
	percsp varchar(100) NULL,
	percutil varchar(100) NULL,
	sicur varchar(100) NULL,
	percman varchar(100) NULL,
	perconeri varchar(100) NULL,
	isanalisi varchar(20) NULL,
	prezman varchar(100) NULL,
	addendum varchar(20) NULL,
	codice varchar(60) NULL,
	codice_1 varchar(10) NULL,
	codice_2 varchar(10) NULL,
	codice_3 varchar(10) NULL,
	codice_4 varchar(10) NULL,
	codice_5 varchar(10) NULL,
	um_de varchar(20) NULL,
	id_categoria varchar(20) NULL,
	is_minuteria varchar(20) NULL,
	id varchar(100) NULL,
	percman_diretta varchar(100) NULL,
	prezman_diretta varchar(100) NULL,
	ifc_scaricabile varchar(20) NULL,
	macro_gruppo varchar(20) NULL,
	spese varchar(100) NULL,
	utili varchar(100) NULL
);

ALTER TABLE hcbi_ras.src_tmp_pubblicazione_articoli
    OWNER TO hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.src_tmp_pubblicazione_articoli
FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.src_tmp_pubblicazione_articoli
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.src_tmp_pubblicazione_articoli
TO hcbi_utility;


/* ============================================================
   VISTA SRC_TMP
   ============================================================ */

CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_pubblicazione_articoli
AS SELECT TRIM(BOTH FROM s.provincia::text) AS id_sorgente_provincia,
    TRIM(BOTH FROM s.anno::text) AS ds_anno_pubblicazione,
    TRIM(BOTH FROM s.codice_completo::text) AS cd_codice_completo,
    TRIM(BOTH FROM s.um::text) AS cd_unita_misura,
    TRIM(BOTH FROM s.prezzo::text) AS nr_prezzo,
    TRIM(BOTH FROM s.prezan::text) AS nr_prezzo_annuo,
    TRIM(BOTH FROM s.percsp::text) AS nr_perc_spese,
    TRIM(BOTH FROM s.percutil::text) AS nr_perc_utile,
    TRIM(BOTH FROM s.sicur::text) AS nr_sicur,
    TRIM(BOTH FROM s.percman::text) AS nr_perc_manodopera,
    TRIM(BOTH FROM s.perconeri::text) AS nr_perc_oneri,
    TRIM(BOTH FROM s.isanalisi::text) AS fl_isanalisi,
    TRIM(BOTH FROM s.prezman::text) AS nr_prezzo_manodopera,
    TRIM(BOTH FROM s.addendum::text) AS cd_versione,
    TRIM(BOTH FROM s.codice::text) AS cd_articolo,
    TRIM(BOTH FROM s.codice_1::text) AS cd_titolo,
    TRIM(BOTH FROM s.codice_2::text) AS cd_capitolo,
    TRIM(BOTH FROM s.codice_3::text) AS cd_sottocapitolo,
    TRIM(BOTH FROM s.codice_4::text) AS cd_categoria_articolo,
    TRIM(BOTH FROM s.codice_5::text) AS cd_subarticolo,
    TRIM(BOTH FROM s.um_de::text) AS ds_unita_misura_de,
    TRIM(BOTH FROM s.id_categoria::text) AS id_sorgente_categoria,
    TRIM(BOTH FROM s.is_minuteria::text) AS fl_is_minuteria,
    TRIM(BOTH FROM s.id::text) AS id_sorgente_pubblicazione_articoli,
    TRIM(BOTH FROM s.percman_diretta::text) AS nr_perc_manodopera_dir,
    TRIM(BOTH FROM s.prezman_diretta::text) AS nr_prezzo_manodopera_dir,
    TRIM(BOTH FROM s.ifc_scaricabile::text) AS fl_ifc_scaricabile,
    TRIM(BOTH FROM s.macro_gruppo::text) AS nr_macro_gruppo,
    TRIM(BOTH FROM s.spese::text) AS nr_spese,
    TRIM(BOTH FROM s.utili::text) AS nr_utili
   FROM hcbi_ras.src_tmp_pubblicazione_articoli s;

ALTER VIEW hcbi_ras.v_src_tmp_pubblicazione_articoli
    OWNER TO hcbi_ras;

GRANT ALL ON hcbi_ras.v_src_tmp_pubblicazione_articoli
TO hcbi_ras;

GRANT SELECT ON hcbi_ras.v_src_tmp_pubblicazione_articoli
TO hcbi_utility;


/* ============================================================
   TABELLA STAGING
   ============================================================ */
CREATE TABLE hcbi_ras.stg_pubblicazione_articoli (
	id_sorgente_provincia numeric(10) NOT NULL,
	ds_anno_pubblicazione numeric(10) NOT NULL,
	cd_codice_completo varchar(70) NOT NULL,
	cd_unita_misura varchar(20) NULL, -- Unita di misura dell'articolo
	nr_prezzo numeric(24, 5) NULL,
	nr_prezzo_annuo numeric(24, 5) NULL, -- Prezzo annuo
	nr_perc_spese numeric(24, 5) NULL, -- Percentuale spese
	nr_perc_utile numeric(10, 5) NULL, -- Percentuale utile
	nr_sicur numeric(24, 5) NULL,
	nr_perc_manodopera numeric(10, 5) NULL, -- Percentuale manodopera
	nr_perc_oneri numeric(10, 5) NULL, -- Percentuale oneri
	fl_isanalisi int2 NULL,
	nr_prezzo_manodopera numeric(24, 5) NULL, -- Prezzo manodopera
	cd_versione int2 NOT NULL,
	cd_articolo varchar(60) NOT NULL,
	cd_titolo varchar(10) NULL, -- Titolo
	cd_capitolo varchar(10) NULL, -- Capitolo
	cd_sottocapitolo varchar(10) NULL, -- Sottocapitolo
	cd_categoria_articolo varchar(10) NULL, -- Categoria articolo
	cd_subarticolo varchar(10) NULL, -- Subarticolo
	ds_unita_misura_de varchar(20) NULL, -- Descrizione unita di misura DE
	id_sorgente_categoria int8 NULL,
	fl_is_minuteria int2 NULL,
	id_sorgente_pubblicazione_articoli int8 NULL,
	nr_perc_manodopera_dir numeric(10, 5) NULL, -- Percentuale manodopera diretta
	nr_prezzo_manodopera_dir numeric(24, 5) NULL, -- Prezzo manodopera diretta
	fl_ifc_scaricabile int2 NULL,
	nr_macro_gruppo int4 NULL,
	nr_spese numeric(24, 5) NULL,
	nr_utili numeric(24, 5) NULL
);

ALTER TABLE hcbi_ras.stg_pubblicazione_articoli
    OWNER TO hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.stg_pubblicazione_articoli
FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.stg_pubblicazione_articoli
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_pubblicazione_articoli
TO hcbi_utility;


/* ============================================================
   TABELLA REJECT
   ============================================================ */

CREATE TABLE hcbi_ras.stg_pubblicazione_articoli_rej (
	id_sorgente_provincia varchar(100) NULL,
	ds_anno_pubblicazione varchar(100) NULL,
	cd_codice_completo varchar(70) NULL,
	cd_unita_misura varchar(20) NULL,
	nr_prezzo varchar(100) NULL,
	nr_prezzo_annuo varchar(100) NULL,
	nr_perc_spese varchar(100) NULL,
	nr_perc_utile varchar(100) NULL,
	nr_sicur varchar(100) NULL,
	nr_perc_manodopera varchar(100) NULL,
	nr_perc_oneri varchar(100) NULL,
	fl_isanalisi varchar(20) NULL,
	nr_prezzo_manodopera varchar(100) NULL,
	cd_versione varchar(20) NULL,
	cd_articolo varchar(60) NULL,
	cd_titolo varchar(10) NULL,
	cd_capitolo varchar(10) NULL,
	cd_sottocapitolo varchar(10) NULL,
	cd_categoria_articolo varchar(10) NULL,
	cd_subarticolo varchar(10) NULL,
	ds_unita_misura_de varchar(20) NULL,
	id_sorgente_categoria varchar(20) NULL,
	fl_is_minuteria varchar(20) NULL,
	id_sorgente_pubblicazione_articoli varchar(100) NULL,
	nr_perc_manodopera_dir varchar(100) NULL,
	nr_prezzo_manodopera_dir varchar(100) NULL,
	fl_ifc_scaricabile varchar(20) NULL,
	nr_macro_gruppo varchar(20) NULL,
	nr_spese varchar(100) NULL,
	nr_utili varchar(100) NULL,
	tx_motivo_scarto varchar(4000) NULL
);

ALTER TABLE hcbi_ras.stg_pubblicazione_articoli_rej
    OWNER TO hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.stg_pubblicazione_articoli_rej
FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.stg_pubblicazione_articoli_rej
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_pubblicazione_articoli_rej
TO hcbi_utility;


/* ============================================================
   TABELLA DWH
   ============================================================ */

CREATE TABLE hcbi_ras.dwh_pubblicazione_articoli (
	id_pubblicazione_articoli int8 NOT NULL DEFAULT nextval('hcbi_ras.seq_dwh_pubblicazione_articoli'::regclass),
	id_sorgente_provincia numeric(10) NOT NULL,
	ds_anno_pubblicazione numeric(10) NOT NULL,
	cd_codice_completo varchar(70) NOT NULL,
	cd_unita_misura varchar(20) NULL,
	nr_prezzo numeric(24, 5) NULL,
	nr_prezzo_annuo numeric(24, 5) NULL,
	nr_perc_spese numeric(24, 5) NULL,
	nr_perc_utile numeric(10, 5) NULL,
	nr_sicur numeric(24, 5) NULL,
	nr_perc_manodopera numeric(10, 5) NULL,
	nr_perc_oneri numeric(10, 5) NULL,
	fl_isanalisi int2 NULL,
	nr_prezzo_manodopera numeric(24, 5) NULL,
	cd_versione int2 NOT NULL,
	cd_articolo varchar(60) NOT NULL,
	cd_titolo varchar(10) NULL,
	cd_capitolo varchar(10) NULL,
	cd_sottocapitolo varchar(10) NULL,
	cd_categoria_articolo varchar(10) NULL,
	cd_subarticolo varchar(10) NULL,
	ds_unita_misura_de varchar(20) NULL,
	id_sorgente_categoria int8 NULL,
	fl_is_minuteria int2 NULL,
	id_sorgente_pubblicazione_articoli int8 NULL,
	nr_perc_manodopera_dir numeric(10, 5) NULL,
	nr_prezzo_manodopera_dir numeric(24, 5) NULL,
	fl_ifc_scaricabile int2 NULL,
	nr_macro_gruppo int4 NULL,
	nr_spese numeric(24, 5) NULL,
	nr_utili numeric(24, 5) NULL,
	dt_creation timestamp NOT NULL DEFAULT clock_timestamp(),
	tx_creation_by varchar(4000) NOT NULL DEFAULT CURRENT_USER,
	dt_update timestamp NOT NULL DEFAULT clock_timestamp(),
	tx_update_by varchar(4000) NOT NULL DEFAULT CURRENT_USER,
	dt_reciclo timestamp NULL,
	CONSTRAINT pk_dwh_pubblicazione_articoli PRIMARY KEY (id_pubblicazione_articoli),
	CONSTRAINT uk_dwh_pubblicazione_articoli UNIQUE (id_sorgente_provincia, ds_anno_pubblicazione, cd_codice_completo, cd_versione)
);

ALTER TABLE hcbi_ras.dwh_pubblicazione_articoli
    OWNER TO hcbi_ras;

GRANT ALL ON TABLE hcbi_ras.dwh_pubblicazione_articoli
TO hcbi_ras;

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE hcbi_ras.dwh_pubblicazione_articoli
TO hcbi_utility;


/* ============================================================
   VISTA DI RACCORDO DWH
   ============================================================ */
CREATE OR REPLACE VIEW hcbi_ras.v_dwh_pubblicazione_articoli
AS SELECT s.id_sorgente_provincia,
    s.ds_anno_pubblicazione,
    s.cd_codice_completo,
    s.cd_unita_misura,
    s.nr_prezzo,
    s.nr_prezzo_annuo,
    s.nr_perc_spese,
    s.nr_perc_utile,
    s.nr_sicur,
    s.nr_perc_manodopera,
    s.nr_perc_oneri,
    s.fl_isanalisi,
    s.nr_prezzo_manodopera,
    s.cd_versione,
    s.cd_articolo,
    s.cd_titolo,
    s.cd_capitolo,
    s.cd_sottocapitolo,
    s.cd_categoria_articolo,
    s.cd_subarticolo,
    s.ds_unita_misura_de,
    s.id_sorgente_categoria,
    s.fl_is_minuteria,
    s.id_sorgente_pubblicazione_articoli,
    s.nr_perc_manodopera_dir,
    s.nr_prezzo_manodopera_dir,
    s.fl_ifc_scaricabile,
    s.nr_macro_gruppo,
    s.nr_spese,
    s.nr_utili
   FROM hcbi_ras.stg_pubblicazione_articoli s;

ALTER VIEW hcbi_ras.v_dwh_pubblicazione_articoli
    OWNER TO hcbi_ras;

GRANT ALL ON hcbi_ras.v_dwh_pubblicazione_articoli
TO hcbi_ras;

GRANT SELECT ON hcbi_ras.v_dwh_pubblicazione_articoli
TO hcbi_utility;



/* FUNZIONI DI CONVERSIONE SICURA CONDIVISE */
/* Il parametro resta p_value per compatibilita con le funzioni gia distribuite. */
CREATE OR REPLACE FUNCTION hcbi_ras.try_bigint(p_value TEXT) RETURNS BIGINT LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT AS $f$ BEGIN RETURN p_value::BIGINT; EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END;$f$;
CREATE OR REPLACE FUNCTION hcbi_ras.try_integer(p_value TEXT) RETURNS INTEGER LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT AS $f$ BEGIN RETURN p_value::INTEGER; EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END;$f$;
CREATE OR REPLACE FUNCTION hcbi_ras.try_smallint(p_value TEXT) RETURNS SMALLINT LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT AS $f$ BEGIN RETURN p_value::SMALLINT; EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END;$f$;
CREATE OR REPLACE FUNCTION hcbi_ras.try_numeric_10_0(p_value TEXT) RETURNS NUMERIC(10,0) LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT AS $f$ BEGIN RETURN p_value::NUMERIC(10,0); EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END;$f$;
CREATE OR REPLACE FUNCTION hcbi_ras.try_numeric_10_5(p_value TEXT) RETURNS NUMERIC(10,5) LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT AS $f$ BEGIN RETURN p_value::NUMERIC(10,5); EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END;$f$;
CREATE OR REPLACE FUNCTION hcbi_ras.try_numeric_24_5(p_value TEXT) RETURNS NUMERIC(24,5) LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT AS $f$ BEGIN RETURN p_value::NUMERIC(24,5); EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END;$f$;

/* ============================================================
   PROCEDURA STG INITIALIZE
   ============================================================ */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_initialize(
	IN p_id_chain_log bigint,
	IN p_id_chain bigint,
	IN p_id_step bigint,
	IN p_ds_step_name character varying,
	OUT p_result integer)
LANGUAGE 'plpgsql'
    SECURITY DEFINER 
    SET search_path=pg_catalog, hcbi_ras, hcbi_utility
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
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name
    ) INTO v_id_log;
    TRUNCATE TABLE hcbi_ras.stg_pubblicazione_articoli;
    TRUNCATE TABLE hcbi_ras.stg_pubblicazione_articoli_rej;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name
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

        RAISE WARNING 'Errore in pkg_stg_pubblicazione_articoli_prc_initialize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_initialize(bigint, bigint, bigint, character varying)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_initialize(bigint, bigint, bigint, character varying) TO PUBLIC;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_initialize(bigint, bigint, bigint, character varying) TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_initialize(bigint, bigint, bigint, character varying) TO hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_initialize(bigint, bigint, bigint, character varying)
    IS 'Svuota STG_PUBBLICAZIONE_ARTICOLI e STG_PUBBLICAZIONE_ARTICOLI_REJ; classificazione e scarti sono gestiti dalla procedura main.';


/* ============================================================
   PROCEDURA STG MAIN
   ============================================================ */
-- DROP PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_main(in int8, in int8, in int8, in varchar, out int4);
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_main(
	IN p_id_chain_log bigint,
	IN p_id_chain bigint,
	IN p_id_step bigint,
	IN p_ds_step_name character varying,
	OUT p_result integer)
LANGUAGE 'plpgsql'
    SECURITY DEFINER 
    SET search_path=pg_catalog, hcbi_ras, hcbi_utility
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
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name
    ) INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_articoli_classificata;
    CREATE TABLE hcbi_ras.tmp_pubblicazione_articoli_classificata AS
    WITH src AS MATERIALIZED (
        SELECT
            f.id_sorgente_provincia AS id_sorgente_provincia_raw,
            f.ds_anno_pubblicazione AS ds_anno_pubblicazione_raw,
            f.cd_codice_completo AS cd_codice_completo_raw,
            f.cd_unita_misura AS cd_unita_misura_raw,
            f.nr_prezzo AS nr_prezzo_raw,
            f.nr_prezzo_annuo AS nr_prezzo_annuo_raw,
            f.nr_perc_spese AS nr_perc_spese_raw,
            f.nr_perc_utile AS nr_perc_utile_raw,
            f.nr_sicur AS nr_sicur_raw,
            f.nr_perc_manodopera AS nr_perc_manodopera_raw,
            f.nr_perc_oneri AS nr_perc_oneri_raw,
            f.fl_isanalisi AS fl_isanalisi_raw,
            f.nr_prezzo_manodopera AS nr_prezzo_manodopera_raw,
            f.cd_versione AS cd_versione_raw,
            f.cd_articolo AS cd_articolo_raw,
            f.cd_titolo AS cd_titolo_raw,
            f.cd_capitolo AS cd_capitolo_raw,
            f.cd_sottocapitolo AS cd_sottocapitolo_raw,
            f.cd_categoria_articolo AS cd_categoria_articolo_raw,
            f.cd_subarticolo AS cd_subarticolo_raw,
            f.ds_unita_misura_de AS ds_unita_misura_de_raw,
            f.id_sorgente_categoria AS id_sorgente_categoria_raw,
            f.fl_is_minuteria AS fl_is_minuteria_raw,
            f.id_sorgente_pubblicazione_articoli AS id_sorgente_pubblicazione_articoli_raw,
            f.nr_perc_manodopera_dir AS nr_perc_manodopera_dir_raw,
            f.nr_prezzo_manodopera_dir AS nr_prezzo_manodopera_dir_raw,
            f.fl_ifc_scaricabile AS fl_ifc_scaricabile_raw,
            f.nr_macro_gruppo AS nr_macro_gruppo_raw,
            f.nr_spese AS nr_spese_raw,
            f.nr_utili AS nr_utili_raw,
            NULLIF(btrim(f.id_sorgente_provincia), '') AS id_sorgente_provincia_txt,
            NULLIF(btrim(f.ds_anno_pubblicazione), '') AS ds_anno_pubblicazione_txt,
            NULLIF(btrim(f.cd_codice_completo), '') AS cd_codice_completo_txt,
            NULLIF(btrim(f.cd_unita_misura), '') AS cd_unita_misura_txt,
            NULLIF(btrim(f.nr_prezzo), '') AS nr_prezzo_txt,
            NULLIF(btrim(f.nr_prezzo_annuo), '') AS nr_prezzo_annuo_txt,
            NULLIF(btrim(f.nr_perc_spese), '') AS nr_perc_spese_txt,
            NULLIF(btrim(f.nr_perc_utile), '') AS nr_perc_utile_txt,
            NULLIF(btrim(f.nr_sicur), '') AS nr_sicur_txt,
            NULLIF(btrim(f.nr_perc_manodopera), '') AS nr_perc_manodopera_txt,
            NULLIF(btrim(f.nr_perc_oneri), '') AS nr_perc_oneri_txt,
            NULLIF(btrim(f.fl_isanalisi), '') AS fl_isanalisi_txt,
            NULLIF(btrim(f.nr_prezzo_manodopera), '') AS nr_prezzo_manodopera_txt,
            NULLIF(btrim(f.cd_versione), '') AS cd_versione_txt,
            NULLIF(btrim(f.cd_articolo), '') AS cd_articolo_txt,
            NULLIF(btrim(f.cd_titolo), '') AS cd_titolo_txt,
            NULLIF(btrim(f.cd_capitolo), '') AS cd_capitolo_txt,
            NULLIF(btrim(f.cd_sottocapitolo), '') AS cd_sottocapitolo_txt,
            NULLIF(btrim(f.cd_categoria_articolo), '') AS cd_categoria_articolo_txt,
            NULLIF(btrim(f.cd_subarticolo), '') AS cd_subarticolo_txt,
            NULLIF(btrim(f.ds_unita_misura_de), '') AS ds_unita_misura_de_txt,
            NULLIF(btrim(f.id_sorgente_categoria), '') AS id_sorgente_categoria_txt,
            NULLIF(btrim(f.fl_is_minuteria), '') AS fl_is_minuteria_txt,
            NULLIF(btrim(f.id_sorgente_pubblicazione_articoli), '') AS id_sorgente_pubblicazione_articoli_txt,
            NULLIF(btrim(f.nr_perc_manodopera_dir), '') AS nr_perc_manodopera_dir_txt,
            NULLIF(btrim(f.nr_prezzo_manodopera_dir), '') AS nr_prezzo_manodopera_dir_txt,
            NULLIF(btrim(f.fl_ifc_scaricabile), '') AS fl_ifc_scaricabile_txt,
            NULLIF(btrim(f.nr_macro_gruppo), '') AS nr_macro_gruppo_txt,
            NULLIF(btrim(f.nr_spese), '') AS nr_spese_txt,
            NULLIF(btrim(f.nr_utili), '') AS nr_utili_txt
        FROM hcbi_ras.v_src_tmp_pubblicazione_articoli AS f

    ), converted AS MATERIALIZED (
        SELECT s.*,
            hcbi_ras.try_numeric_10_0(s.id_sorgente_provincia_txt) AS id_sorgente_provincia_cv,
            hcbi_ras.try_numeric_10_0(s.ds_anno_pubblicazione_txt) AS ds_anno_pubblicazione_cv,
            s.cd_codice_completo_txt AS cd_codice_completo_cv,
            s.cd_unita_misura_txt AS cd_unita_misura_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_prezzo_txt, ',', '.')) AS nr_prezzo_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_prezzo_annuo_txt, ',', '.')) AS nr_prezzo_annuo_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_perc_spese_txt, ',', '.')) AS nr_perc_spese_cv,
            hcbi_ras.try_numeric_10_5(replace(s.nr_perc_utile_txt, ',', '.')) AS nr_perc_utile_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_sicur_txt, ',', '.')) AS nr_sicur_cv,
            hcbi_ras.try_numeric_10_5(replace(s.nr_perc_manodopera_txt, ',', '.')) AS nr_perc_manodopera_cv,
            hcbi_ras.try_numeric_10_5(replace(s.nr_perc_oneri_txt, ',', '.')) AS nr_perc_oneri_cv,
            hcbi_ras.try_smallint(s.fl_isanalisi_txt) AS fl_isanalisi_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_prezzo_manodopera_txt, ',', '.')) AS nr_prezzo_manodopera_cv,
            hcbi_ras.try_smallint(s.cd_versione_txt) AS cd_versione_cv,
            s.cd_articolo_txt AS cd_articolo_cv,
            s.cd_titolo_txt AS cd_titolo_cv,
            s.cd_capitolo_txt AS cd_capitolo_cv,
            s.cd_sottocapitolo_txt AS cd_sottocapitolo_cv,
            s.cd_categoria_articolo_txt AS cd_categoria_articolo_cv,
            s.cd_subarticolo_txt AS cd_subarticolo_cv,
            s.ds_unita_misura_de_txt AS ds_unita_misura_de_cv,
            hcbi_ras.try_bigint(s.id_sorgente_categoria_txt) AS id_sorgente_categoria_cv,
            hcbi_ras.try_smallint(s.fl_is_minuteria_txt) AS fl_is_minuteria_cv,
            hcbi_ras.try_bigint(s.id_sorgente_pubblicazione_articoli_txt) AS id_sorgente_pubblicazione_articoli_cv,
            hcbi_ras.try_numeric_10_5(replace(s.nr_perc_manodopera_dir_txt, ',', '.')) AS nr_perc_manodopera_dir_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_prezzo_manodopera_dir_txt, ',', '.')) AS nr_prezzo_manodopera_dir_cv,
            hcbi_ras.try_smallint(s.fl_ifc_scaricabile_txt) AS fl_ifc_scaricabile_cv,
            hcbi_ras.try_integer(s.nr_macro_gruppo_txt) AS nr_macro_gruppo_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_spese_txt, ',', '.')) AS nr_spese_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_utili_txt, ',', '.')) AS nr_utili_cv
        FROM src AS s
    ), classified AS MATERIALIZED (
        SELECT c.*,
            count(*) OVER (
                PARTITION BY c.id_sorgente_provincia_cv,
                             c.ds_anno_pubblicazione_cv,
                             c.cd_codice_completo_cv,
                             c.cd_versione_cv
            ) AS duplicate_count
        FROM converted AS c
    )
    SELECT c.*,
        CASE
            WHEN c.duplicate_count > 1 THEN 'Chiave duplicata dopo trim/conversione: (id_sorgente_provincia, ds_anno_pubblicazione, cd_codice_completo, cd_versione)'
            WHEN c.id_sorgente_provincia_txt IS NULL THEN 'id_sorgente_provincia obbligatorio'
            WHEN c.id_sorgente_provincia_cv IS NULL THEN 'id_sorgente_provincia non convertibile in numeric(10,0)'
            WHEN c.ds_anno_pubblicazione_txt IS NULL THEN 'ds_anno_pubblicazione obbligatorio'
            WHEN c.ds_anno_pubblicazione_cv IS NULL THEN 'ds_anno_pubblicazione non convertibile in numeric(10,0)'
            WHEN c.cd_codice_completo_txt IS NULL THEN 'cd_codice_completo obbligatorio'
            WHEN c.cd_versione_txt IS NULL THEN 'cd_versione obbligatorio'
            WHEN c.cd_versione_cv IS NULL THEN 'cd_versione non convertibile in smallint'
            WHEN c.cd_articolo_txt IS NULL THEN 'cd_articolo obbligatorio'
            WHEN c.nr_prezzo_txt IS NOT NULL AND c.nr_prezzo_cv IS NULL THEN 'nr_prezzo non convertibile' 
            WHEN c.nr_prezzo_annuo_txt IS NOT NULL AND c.nr_prezzo_annuo_cv IS NULL THEN 'nr_prezzo_annuo non convertibile' 
            WHEN c.nr_perc_spese_txt IS NOT NULL AND c.nr_perc_spese_cv IS NULL THEN 'nr_perc_spese non convertibile' 
            WHEN c.nr_perc_utile_txt IS NOT NULL AND c.nr_perc_utile_cv IS NULL THEN 'nr_perc_utile non convertibile' 
            WHEN c.nr_sicur_txt IS NOT NULL AND c.nr_sicur_cv IS NULL THEN 'nr_sicur non convertibile' 
            WHEN c.nr_perc_manodopera_txt IS NOT NULL AND c.nr_perc_manodopera_cv IS NULL THEN 'nr_perc_manodopera non convertibile' 
            WHEN c.nr_perc_oneri_txt IS NOT NULL AND c.nr_perc_oneri_cv IS NULL THEN 'nr_perc_oneri non convertibile' 
            WHEN c.fl_isanalisi_txt IS NOT NULL AND c.fl_isanalisi_cv IS NULL THEN 'fl_isanalisi non convertibile' 
            WHEN c.nr_prezzo_manodopera_txt IS NOT NULL AND c.nr_prezzo_manodopera_cv IS NULL THEN 'nr_prezzo_manodopera non convertibile' 
            WHEN c.id_sorgente_categoria_txt IS NOT NULL AND c.id_sorgente_categoria_cv IS NULL THEN 'id_sorgente_categoria non convertibile' 
            WHEN c.fl_is_minuteria_txt IS NOT NULL AND c.fl_is_minuteria_cv IS NULL THEN 'fl_is_minuteria non convertibile' 
            WHEN c.id_sorgente_pubblicazione_articoli_txt IS NOT NULL AND c.id_sorgente_pubblicazione_articoli_cv IS NULL THEN 'id_sorgente_pubblicazione_articoli non convertibile' 
            WHEN c.nr_perc_manodopera_dir_txt IS NOT NULL AND c.nr_perc_manodopera_dir_cv IS NULL THEN 'nr_perc_manodopera_dir non convertibile' 
            WHEN c.nr_prezzo_manodopera_dir_txt IS NOT NULL AND c.nr_prezzo_manodopera_dir_cv IS NULL THEN 'nr_prezzo_manodopera_dir non convertibile' 
            WHEN c.fl_ifc_scaricabile_txt IS NOT NULL AND c.fl_ifc_scaricabile_cv IS NULL THEN 'fl_ifc_scaricabile non convertibile' 
            WHEN c.nr_macro_gruppo_txt IS NOT NULL AND c.nr_macro_gruppo_cv IS NULL THEN 'nr_macro_gruppo non convertibile' 
            WHEN c.nr_spese_txt IS NOT NULL AND c.nr_spese_cv IS NULL THEN 'nr_spese non convertibile' 
            WHEN c.nr_utili_txt IS NOT NULL AND c.nr_utili_cv IS NULL THEN 'nr_utili non convertibile' 
            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM classified AS c;

    SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_pubblicazione_articoli_classificata;

    INSERT INTO hcbi_ras.stg_pubblicazione_articoli (
        id_sorgente_provincia,
        ds_anno_pubblicazione,
        cd_codice_completo,
        cd_unita_misura,
        nr_prezzo,
        nr_prezzo_annuo,
        nr_perc_spese,
        nr_perc_utile,
        nr_sicur,
        nr_perc_manodopera,
        nr_perc_oneri,
        fl_isanalisi,
        nr_prezzo_manodopera,
        cd_versione,
        cd_articolo,
        cd_titolo,
        cd_capitolo,
        cd_sottocapitolo,
        cd_categoria_articolo,
        cd_subarticolo,
        ds_unita_misura_de,
        id_sorgente_categoria,
        fl_is_minuteria,
        id_sorgente_pubblicazione_articoli,
        nr_perc_manodopera_dir,
        nr_prezzo_manodopera_dir,
        fl_ifc_scaricabile,
        nr_macro_gruppo,
        nr_spese,
        nr_utili
    )
    SELECT
        t.id_sorgente_provincia_cv,
        t.ds_anno_pubblicazione_cv,
        t.cd_codice_completo_cv,
        t.cd_unita_misura_cv,
        t.nr_prezzo_cv,
        t.nr_prezzo_annuo_cv,
        t.nr_perc_spese_cv,
        t.nr_perc_utile_cv,
        t.nr_sicur_cv,
        t.nr_perc_manodopera_cv,
        t.nr_perc_oneri_cv,
        t.fl_isanalisi_cv,
        t.nr_prezzo_manodopera_cv,
        t.cd_versione_cv,
        t.cd_articolo_cv,
        t.cd_titolo_cv,
        t.cd_capitolo_cv,
        t.cd_sottocapitolo_cv,
        t.cd_categoria_articolo_cv,
        t.cd_subarticolo_cv,
        t.ds_unita_misura_de_cv,
        t.id_sorgente_categoria_cv,
        t.fl_is_minuteria_cv,
        t.id_sorgente_pubblicazione_articoli_cv,
        t.nr_perc_manodopera_dir_cv,
        t.nr_prezzo_manodopera_dir_cv,
        t.fl_ifc_scaricabile_cv,
        t.nr_macro_gruppo_cv,
        t.nr_spese_cv,
        t.nr_utili_cv
    FROM hcbi_ras.tmp_pubblicazione_articoli_classificata AS t
    WHERE t.tx_motivo_scarto IS NULL;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_pubblicazione_articoli_rej (
        id_sorgente_provincia,
        ds_anno_pubblicazione,
        cd_codice_completo,
        cd_unita_misura,
        nr_prezzo,
        nr_prezzo_annuo,
        nr_perc_spese,
        nr_perc_utile,
        nr_sicur,
        nr_perc_manodopera,
        nr_perc_oneri,
        fl_isanalisi,
        nr_prezzo_manodopera,
        cd_versione,
        cd_articolo,
        cd_titolo,
        cd_capitolo,
        cd_sottocapitolo,
        cd_categoria_articolo,
        cd_subarticolo,
        ds_unita_misura_de,
        id_sorgente_categoria,
        fl_is_minuteria,
        id_sorgente_pubblicazione_articoli,
        nr_perc_manodopera_dir,
        nr_prezzo_manodopera_dir,
        fl_ifc_scaricabile,
        nr_macro_gruppo,
        nr_spese,
        nr_utili,
        tx_motivo_scarto
    )
    SELECT
        t.id_sorgente_provincia_raw,
        t.ds_anno_pubblicazione_raw,
        t.cd_codice_completo_raw,
        t.cd_unita_misura_raw,
        t.nr_prezzo_raw,
        t.nr_prezzo_annuo_raw,
        t.nr_perc_spese_raw,
        t.nr_perc_utile_raw,
        t.nr_sicur_raw,
        t.nr_perc_manodopera_raw,
        t.nr_perc_oneri_raw,
        t.fl_isanalisi_raw,
        t.nr_prezzo_manodopera_raw,
        t.cd_versione_raw,
        t.cd_articolo_raw,
        t.cd_titolo_raw,
        t.cd_capitolo_raw,
        t.cd_sottocapitolo_raw,
        t.cd_categoria_articolo_raw,
        t.cd_subarticolo_raw,
        t.ds_unita_misura_de_raw,
        t.id_sorgente_categoria_raw,
        t.fl_is_minuteria_raw,
        t.id_sorgente_pubblicazione_articoli_raw,
        t.nr_perc_manodopera_dir_raw,
        t.nr_prezzo_manodopera_dir_raw,
        t.fl_ifc_scaricabile_raw,
        t.nr_macro_gruppo_raw,
        t.nr_spese_raw,
        t.nr_utili_raw,
        t.tx_motivo_scarto
    FROM hcbi_ras.tmp_pubblicazione_articoli_classificata AS t
    WHERE t.tx_motivo_scarto IS NOT NULL;
    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE=format('Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',v_selected,v_inserted,v_rec_errors),
            DETAIL='Il numero di record letti non coincide con caricati e scartati.',
            HINT='Verificare classificazione e INSERT verso STG e REJ.';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_articoli_classificata;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_articoli_classificata;
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

        RAISE WARNING 'Errore in pkg_stg_pubblicazione_articoli_prc_main. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;


END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_main(bigint, bigint, bigint, character varying)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_main(bigint, bigint, bigint, character varying) TO PUBLIC;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_main(bigint, bigint, bigint, character varying) TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_main(bigint, bigint, bigint, character varying) TO hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_main(bigint, bigint, bigint, character varying)
    IS 'Classifica e converte in modalita set-based PUBBLICAZIONE_ARTICOLI, identifica duplicati e scarti, carica STG e riconcilia i conteggi.';


/* ============================================================
   PROCEDURA STG FINALIZE
   ============================================================ */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_finalize(
	IN p_id_chain_log bigint,
	IN p_id_chain bigint,
	IN p_id_step bigint,
	IN p_ds_step_name character varying,
	OUT p_result integer)
LANGUAGE 'plpgsql'
    SECURITY DEFINER 
    SET search_path=pg_catalog, hcbi_ras, hcbi_utility
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
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name
    ) INTO v_id_log;

    ANALYZE hcbi_ras.stg_pubblicazione_articoli;
    ANALYZE hcbi_ras.stg_pubblicazione_articoli_rej;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name
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

        RAISE WARNING 'Errore in pkg_stg_pubblicazione_articoli_prc_finalize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;


END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_finalize(bigint, bigint, bigint, character varying)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_finalize(bigint, bigint, bigint, character varying) TO PUBLIC;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_finalize(bigint, bigint, bigint, character varying) TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_finalize(bigint, bigint, bigint, character varying) TO hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_finalize(bigint, bigint, bigint, character varying)
    IS 'Finalizza il caricamento STG_PUBBLICAZIONE_ARTICOLI e aggiorna le statistiche.';



/* ============================================================
   PROCEDURA DWH INITIALIZE
   ============================================================ */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_initialize(
	IN p_id_chain_log bigint,
	IN p_id_chain bigint,
	IN p_id_step bigint,
	IN p_ds_step_name character varying,
	OUT p_result integer)
LANGUAGE 'plpgsql'
    SECURITY DEFINER 
    SET search_path=pg_catalog, hcbi_ras, hcbi_utility
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
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name
    ) INTO v_id_log;

    -- Nessuna inizializzazione dati richiesta.
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name
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

        RAISE WARNING 'Errore in pkg_dwh_pubblicazione_articoli_prc_initialize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;


END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_initialize(bigint, bigint, bigint, character varying)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_initialize(bigint, bigint, bigint, character varying) TO PUBLIC;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_initialize(bigint, bigint, bigint, character varying) TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_initialize(bigint, bigint, bigint, character varying) TO hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_initialize(bigint, bigint, bigint, character varying)
    IS 'Inizializza il flusso DWH_PUBBLICAZIONE_ARTICOLI e registra l''esecuzione nel log.';



/* ============================================================
   PROCEDURA DWH MAIN
   ============================================================ */

-- DROP PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_main(in int8, in int8, in int8, in varchar, out int4);

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_main(
	IN p_id_chain_log bigint,
	IN p_id_chain bigint,
	IN p_id_step bigint,
	IN p_ds_step_name character varying,
	OUT p_result integer)
LANGUAGE 'plpgsql'
    SECURITY DEFINER 
    SET search_path=pg_catalog, hcbi_ras, hcbi_utility
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

        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name

    ) INTO v_id_log;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.v_dwh_pubblicazione_articoli
        GROUP BY id_sorgente_provincia,ds_anno_pubblicazione,cd_codice_completo,cd_versione
        HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='Business key duplicata in HCBI_RAS.V_DWH_PUBBLICAZIONE_ARTICOLI';
    END IF;
    SELECT count(*) INTO v_selected FROM hcbi_ras.v_dwh_pubblicazione_articoli;

    UPDATE hcbi_ras.dwh_pubblicazione_articoli AS dwh
       SET cd_unita_misura=src.cd_unita_misura,
           nr_prezzo=src.nr_prezzo,
           nr_prezzo_annuo=src.nr_prezzo_annuo,
           nr_perc_spese=src.nr_perc_spese,
           nr_perc_utile=src.nr_perc_utile,
           nr_sicur=src.nr_sicur,
           nr_perc_manodopera=src.nr_perc_manodopera,
           nr_perc_oneri=src.nr_perc_oneri,
           fl_isanalisi=src.fl_isanalisi,
           nr_prezzo_manodopera=src.nr_prezzo_manodopera,
           cd_articolo=src.cd_articolo,
           cd_titolo=src.cd_titolo,
           cd_capitolo=src.cd_capitolo,
           cd_sottocapitolo=src.cd_sottocapitolo,
           cd_categoria_articolo=src.cd_categoria_articolo,
           cd_subarticolo=src.cd_subarticolo,
           ds_unita_misura_de=src.ds_unita_misura_de,
           id_sorgente_categoria=src.id_sorgente_categoria,
           fl_is_minuteria=src.fl_is_minuteria,
           id_sorgente_pubblicazione_articoli=src.id_sorgente_pubblicazione_articoli,
           nr_perc_manodopera_dir=src.nr_perc_manodopera_dir,
           nr_prezzo_manodopera_dir=src.nr_prezzo_manodopera_dir,
           fl_ifc_scaricabile=src.fl_ifc_scaricabile,
           nr_macro_gruppo=src.nr_macro_gruppo,
           nr_spese=src.nr_spese,
           nr_utili=src.nr_utili,
           dt_update=clock_timestamp(),
           tx_update_by=p_ds_step_name
      FROM hcbi_ras.v_dwh_pubblicazione_articoli AS src
     WHERE dwh.id_sorgente_provincia = src.id_sorgente_provincia
       AND dwh.ds_anno_pubblicazione = src.ds_anno_pubblicazione
       AND dwh.cd_codice_completo= src.cd_codice_completo
       AND dwh.cd_versione = src.cd_versione
       AND ROW(dwh.cd_unita_misura, dwh.nr_prezzo, dwh.nr_prezzo_annuo, dwh.nr_perc_spese, dwh.nr_perc_utile, dwh.nr_sicur, dwh.nr_perc_manodopera, dwh.nr_perc_oneri, dwh.fl_isanalisi, dwh.nr_prezzo_manodopera, dwh.cd_articolo, dwh.cd_titolo, dwh.cd_capitolo, dwh.cd_sottocapitolo, dwh.cd_categoria_articolo, dwh.cd_subarticolo, dwh.ds_unita_misura_de, dwh.id_sorgente_categoria, dwh.fl_is_minuteria, dwh.id_sorgente_pubblicazione_articoli, dwh.nr_perc_manodopera_dir, dwh.nr_prezzo_manodopera_dir, dwh.fl_ifc_scaricabile, dwh.nr_macro_gruppo, dwh.nr_spese, dwh.nr_utili) IS DISTINCT FROM ROW(src.cd_unita_misura, src.nr_prezzo, src.nr_prezzo_annuo, src.nr_perc_spese, src.nr_perc_utile, src.nr_sicur, src.nr_perc_manodopera, src.nr_perc_oneri, src.fl_isanalisi, src.nr_prezzo_manodopera, src.cd_articolo, src.cd_titolo, src.cd_capitolo, src.cd_sottocapitolo, src.cd_categoria_articolo, src.cd_subarticolo, src.ds_unita_misura_de, src.id_sorgente_categoria, src.fl_is_minuteria, src.id_sorgente_pubblicazione_articoli, src.nr_perc_manodopera_dir, src.nr_prezzo_manodopera_dir, src.fl_ifc_scaricabile, src.nr_macro_gruppo, src.nr_spese, src.nr_utili);

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_pubblicazione_articoli (
        id_sorgente_provincia,
        ds_anno_pubblicazione,
        cd_codice_completo,
        cd_unita_misura,
        nr_prezzo,
        nr_prezzo_annuo,
        nr_perc_spese,
        nr_perc_utile,
        nr_sicur,
        nr_perc_manodopera,
        nr_perc_oneri,
        fl_isanalisi,
        nr_prezzo_manodopera,
        cd_versione,
        cd_articolo,
        cd_titolo,
        cd_capitolo,
        cd_sottocapitolo,
        cd_categoria_articolo,
        cd_subarticolo,
        ds_unita_misura_de,
        id_sorgente_categoria,
        fl_is_minuteria,
        id_sorgente_pubblicazione_articoli,
        nr_perc_manodopera_dir,
        nr_prezzo_manodopera_dir,
        fl_ifc_scaricabile,
        nr_macro_gruppo,
        nr_spese,
        nr_utili,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_sorgente_provincia,
        src.ds_anno_pubblicazione,
        src.cd_codice_completo,
        src.cd_unita_misura,
        src.nr_prezzo,
        src.nr_prezzo_annuo,
        src.nr_perc_spese,
        src.nr_perc_utile,
        src.nr_sicur,
        src.nr_perc_manodopera,
        src.nr_perc_oneri,
        src.fl_isanalisi,
        src.nr_prezzo_manodopera,
        src.cd_versione,
        src.cd_articolo,
        src.cd_titolo,
        src.cd_capitolo,
        src.cd_sottocapitolo,
        src.cd_categoria_articolo,
        src.cd_subarticolo,
        src.ds_unita_misura_de,
        src.id_sorgente_categoria,
        src.fl_is_minuteria,
        src.id_sorgente_pubblicazione_articoli,
        src.nr_perc_manodopera_dir,
        src.nr_prezzo_manodopera_dir,
        src.fl_ifc_scaricabile,
        src.nr_macro_gruppo,
        src.nr_spese,
        src.nr_utili,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.v_dwh_pubblicazione_articoli AS src
    ON CONFLICT (id_sorgente_provincia,ds_anno_pubblicazione,cd_codice_completo,cd_versione) DO NOTHING;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;
    IF v_selected <> (
        SELECT count(*)
        FROM hcbi_ras.v_dwh_pubblicazione_articoli src
        JOIN hcbi_ras.dwh_pubblicazione_articoli dwh
          ON dwh.id_sorgente_provincia=src.id_sorgente_provincia
         AND dwh.ds_anno_pubblicazione=src.ds_anno_pubblicazione
         AND dwh.cd_codice_completo=src.cd_codice_completo
         AND dwh.cd_versione=src.cd_versione
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='Riconciliazione DWH_PUBBLICAZIONE_ARTICOLI non valida';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name
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

        RAISE WARNING 'Errore in pkg_dwh_pubblicazione_articoli_prc_main. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;

END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_main(bigint, bigint, bigint, character varying)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_main(bigint, bigint, bigint, character varying) TO PUBLIC;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_main(bigint, bigint, bigint, character varying) TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_main(bigint, bigint, bigint, character varying) TO hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_main(bigint, bigint, bigint, character varying)
    IS 'Carica DWH_PUBBLICAZIONE_ARTICOLI dalla tabella STG aggiornando i record esistenti e inserendo i nuovi.';

/* ============================================================
   PROCEDURA DWH FINALIZE
   ============================================================ */

-- DROP PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_finalize(in int8, in int8, in int8, in varchar, out int4);

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_finalize(
	IN p_id_chain_log bigint,
	IN p_id_chain bigint,
	IN p_id_step bigint,
	IN p_ds_step_name character varying,
	OUT p_result integer)
LANGUAGE 'plpgsql'
    SECURITY DEFINER 
    SET search_path=pg_catalog, hcbi_ras, hcbi_utility
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
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name
    ) INTO v_id_log;

    ANALYZE hcbi_ras.dwh_pubblicazione_articoli;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name
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

        RAISE WARNING 'Errore in pkg_dwh_pubblicazione_articoli_prc_finalize. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;


END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_finalize(bigint, bigint, bigint, character varying)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_finalize(bigint, bigint, bigint, character varying) TO PUBLIC;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_finalize(bigint, bigint, bigint, character varying) TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_finalize(bigint, bigint, bigint, character varying) TO hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_finalize(bigint, bigint, bigint, character varying)
    IS 'Finalizza il flusso DWH_PUBBLICAZIONE_ARTICOLI e aggiorna le statistiche.';

/* ============================================================
   COMMENTI
   ============================================================ */

COMMENT ON TABLE hcbi_ras.frontiera_pubblicazione_articoli
IS 'Frontiera del flusso PUBBLICAZIONE_ARTICOLI';

COMMENT ON TABLE hcbi_ras.src_tmp_pubblicazione_articoli
IS 'Tabella temporanea sorgente del flusso PUBBLICAZIONE_ARTICOLI';

COMMENT ON TABLE hcbi_ras.stg_pubblicazione_articoli
IS 'Staging del flusso PUBBLICAZIONE_ARTICOLI';

COMMENT ON TABLE hcbi_ras.stg_pubblicazione_articoli_rej
IS 'Record scartati del flusso PUBBLICAZIONE_ARTICOLI';

COMMENT ON TABLE hcbi_ras.dwh_pubblicazione_articoli
IS 'DWH del flusso PUBBLICAZIONE_ARTICOLI';

COMMENT ON VIEW hcbi_ras.v_src_tmp_pubblicazione_articoli
IS 'Vista di conversione della sorgente temporanea PUBBLICAZIONE_ARTICOLI';

COMMENT ON VIEW hcbi_ras.v_dwh_pubblicazione_articoli
IS 'Vista di raccordo tra STG_PUBBLICAZIONE_ARTICOLI e DWH_PUBBLICAZIONE_ARTICOLI';

/* TEST POST-DEPLOYMENT */
-- T01 provincia obbligatoria, atteso zero:
-- SELECT * FROM hcbi_ras.frontiera_pubblicazione_articoli WHERE NULLIF(btrim(provincia),'') IS NULL;
-- T02 duplicati STG, atteso zero:
-- SELECT id_sorgente_provincia,ds_anno_pubblicazione,cd_codice_completo,cd_versione,count(*) FROM hcbi_ras.stg_pubblicazione_articoli GROUP BY 1,2,3,4 HAVING count(*)>1;
-- T03 duplicati DWH, atteso zero:
-- SELECT id_sorgente_provincia,ds_anno_pubblicazione,cd_codice_completo,cd_versione,count(*) FROM hcbi_ras.dwh_pubblicazione_articoli GROUP BY 1,2,3,4 HAVING count(*)>1;
-- T04 chiavi STG non caricate, atteso zero:
-- SELECT count(*) FROM hcbi_ras.stg_pubblicazione_articoli s LEFT JOIN hcbi_ras.dwh_pubblicazione_articoli d ON d.id_sorgente_provincia=s.id_sorgente_provincia AND d.ds_anno_pubblicazione=s.ds_anno_pubblicazione AND d.cd_codice_completo=s.cd_codice_completo AND d.cd_versione=s.cd_versione WHERE d.id_pubblicazione_articoli IS NULL;
-- T05 codici con punto finale, informativo:
-- SELECT id_pubblicazione_articoli,cd_articolo FROM hcbi_ras.dwh_pubblicazione_articoli WHERE btrim(cd_articolo) LIKE '%.';
-- T06 province non raccordabili, atteso zero:
-- SELECT DISTINCT a.id_sorgente_provincia FROM hcbi_ras.dwh_pubblicazione_articoli a LEFT JOIN hcbi_ras.dwh_anag_provincia p ON p.id_sorgente_provincia=a.id_sorgente_provincia WHERE p.id_sorgente_provincia IS NULL;
-- T07 idempotenza: rilanciare senza variazioni; atteso inserted=0, updated=0.
/* DEPLOYMENT DISTRUTTIVO: backup/restore point e caricamento full obbligatori. */
