/* =====================================================================
   FLUSSO ANAG_INFORMATORI - VERSIONE UNIFORMATA CON PROVINCIA

   Target tecnico: PostgreSQL 15.9 / 17
   Pattern tecnico: PUBBLICAZIONE_ANALISI definitivo
   Sorgente:
       public.informatori

   Schema target:
       hcbi_ras

   Chiave logica:
       ds_ragione_sociale,
       ds_anno_pubblicazione,
       cd_versione,
       id_sorgente_provincia
   ===================================================================== */


/* =====================================================================
   SEQUENCE DWH
   ===================================================================== */

CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_anag_informatori
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_anag_informatori
    OWNER TO hcbi_ras;

GRANT ALL
ON SEQUENCE hcbi_ras.seq_dwh_anag_informatori
TO hcbi_ras;

GRANT USAGE, SELECT
ON SEQUENCE hcbi_ras.seq_dwh_anag_informatori
TO hcbi_utility;


/* =====================================================================
   TABELLA FRONTIERA
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_anag_informatori
(
    id                                      VARCHAR(100),
    ragione_sociale                         VARCHAR(100),
    p_iva                                   VARCHAR(100),
    codice_ateco_2002                       VARCHAR(100),
    indirizzo_sede_legale                   VARCHAR(100),
    cap_sede_legale                         VARCHAR(10),
    citta_sede_legale                       VARCHAR(100),
    provincia_sede_legale                   VARCHAR(100),
    indirizzo_sede_operativa                VARCHAR(100),
    cap_sede_operativa                      VARCHAR(10),
    citta_sede_operativa                    VARCHAR(100),
    provincia_sede_operativa                VARCHAR(100),
    contatti                                TEXT,
    stato                                   VARCHAR(20),
    note                                    TEXT,
    stato_attivita                          VARCHAR(100),
    codice_fiscale                          VARCHAR(100),
    anno                                    VARCHAR(100),
    last_update                             VARCHAR(100),
    nazione                                 VARCHAR(40),
    addendum                                VARCHAR(20),
    provincia                               VARCHAR(100) DEFAULT '0',
    escludi_invio_mail_assoc_listino_completa VARCHAR(20)
);

ALTER TABLE hcbi_ras.frontiera_anag_informatori
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.frontiera_anag_informatori
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.frontiera_anag_informatori
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.frontiera_anag_informatori
TO hcbi_utility;


/* =====================================================================
   TABELLA SRC_TMP
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_anag_informatori
(
    id                                      VARCHAR(100),
    ragione_sociale                         VARCHAR(100),
    p_iva                                   VARCHAR(100),
    codice_ateco_2002                       VARCHAR(100),
    indirizzo_sede_legale                   VARCHAR(100),
    cap_sede_legale                         VARCHAR(10),
    citta_sede_legale                       VARCHAR(100),
    provincia_sede_legale                   VARCHAR(100),
    indirizzo_sede_operativa                VARCHAR(100),
    cap_sede_operativa                      VARCHAR(10),
    citta_sede_operativa                    VARCHAR(100),
    provincia_sede_operativa                VARCHAR(100),
    contatti                                TEXT,
    stato                                   VARCHAR(20),
    note                                    TEXT,
    stato_attivita                          VARCHAR(100),
    codice_fiscale                          VARCHAR(100),
    anno                                    VARCHAR(100),
    last_update                             VARCHAR(100),
    nazione                                 VARCHAR(40),
    addendum                                VARCHAR(20),
    provincia                               VARCHAR(100),
    escludi_invio_mail_assoc_listino_completa VARCHAR(20)
);

ALTER TABLE hcbi_ras.src_tmp_anag_informatori
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.src_tmp_anag_informatori
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.src_tmp_anag_informatori
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.src_tmp_anag_informatori
TO hcbi_utility;


/* =====================================================================
   VISTA SRC_TMP
   ===================================================================== */

CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_anag_informatori
AS
SELECT
    TRIM(s.id::TEXT)
        AS id_sorgente_informatore,

    TRIM(s.ragione_sociale::TEXT)
        AS ds_ragione_sociale,

    TRIM(s.p_iva::TEXT)
        AS cd_p_iva,

    TRIM(s.codice_ateco_2002::TEXT)
        AS cd_codice_ateco_2002,

    TRIM(s.indirizzo_sede_legale::TEXT)
        AS ds_indirizzo_sede_legale,

    TRIM(s.cap_sede_legale::TEXT)
        AS cd_cap_sede_legale,

    TRIM(s.citta_sede_legale::TEXT)
        AS ds_citta_sede_legale,

    TRIM(s.provincia_sede_legale::TEXT)
        AS cd_provincia_sede_legale,

    TRIM(s.indirizzo_sede_operativa::TEXT)
        AS ds_indirizzo_sede_operativa,

    TRIM(s.cap_sede_operativa::TEXT)
        AS cd_cap_sede_operativa,

    TRIM(s.citta_sede_operativa::TEXT)
        AS ds_citta_sede_operativa,

    TRIM(s.provincia_sede_operativa::TEXT)
        AS cd_provincia_sede_operativa,

    TRIM(s.contatti::TEXT)
        AS ds_contatti,

    TRIM(s.stato::TEXT)
        AS cd_stato,

    TRIM(s.note::TEXT)
        AS ds_note,

    TRIM(s.stato_attivita::TEXT)
        AS ds_stato_attivita,

    TRIM(s.codice_fiscale::TEXT)
        AS cd_codice_fiscale,

    TRIM(s.anno::TEXT)
        AS ds_anno_pubblicazione,

    TRIM(s.last_update::TEXT)
        AS dt_last_update,

    TRIM(s.nazione::TEXT)
        AS ds_nazione,

    TRIM(s.addendum::TEXT)
        AS cd_versione,

    TRIM(s.provincia::TEXT)
        AS id_sorgente_provincia,

    TRIM(s.escludi_invio_mail_assoc_listino_completa::TEXT)
        AS fl_escludi_invio_mail_assoc_listino_completa

FROM hcbi_ras.src_tmp_anag_informatori AS s;

ALTER VIEW hcbi_ras.v_src_tmp_anag_informatori
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_src_tmp_anag_informatori
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_src_tmp_anag_informatori
TO hcbi_utility;


/* =====================================================================
   TABELLA STG
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_informatori
(
    id_sorgente_informatore
        INTEGER,

    ds_ragione_sociale
        VARCHAR(100) NOT NULL,

    cd_p_iva
        VARCHAR(100),

    cd_codice_ateco_2002
        VARCHAR(100),

    ds_indirizzo_sede_legale
        VARCHAR(100),

    cd_cap_sede_legale
        VARCHAR(10),

    ds_citta_sede_legale
        VARCHAR(100),

    cd_provincia_sede_legale
        VARCHAR(100),

    ds_indirizzo_sede_operativa
        VARCHAR(100),

    cd_cap_sede_operativa
        VARCHAR(10),

    ds_citta_sede_operativa
        VARCHAR(100),

    cd_provincia_sede_operativa
        VARCHAR(100),

    ds_contatti
        TEXT,

    cd_stato
        INTEGER,

    ds_note
        TEXT,

    ds_stato_attivita
        VARCHAR(100),

    cd_codice_fiscale
        VARCHAR(100),

    ds_anno_pubblicazione
        INTEGER NOT NULL,

    dt_last_update
        TIMESTAMP WITHOUT TIME ZONE,

    ds_nazione
        VARCHAR(40),

    cd_versione
        SMALLINT NOT NULL,

    id_sorgente_provincia
        BIGINT NOT NULL,

    fl_escludi_invio_mail_assoc_listino_completa
        INTEGER
);

ALTER TABLE hcbi_ras.stg_anag_informatori
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.stg_anag_informatori
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.stg_anag_informatori
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_informatori
TO hcbi_utility;


/* =====================================================================
   TABELLA STG REJECT
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_informatori_rej
(
    id_sorgente_informatore
        VARCHAR(100),

    ds_ragione_sociale
        VARCHAR(100),

    cd_p_iva
        VARCHAR(100),

    cd_codice_ateco_2002
        VARCHAR(100),

    ds_indirizzo_sede_legale
        VARCHAR(100),

    cd_cap_sede_legale
        VARCHAR(10),

    ds_citta_sede_legale
        VARCHAR(100),

    cd_provincia_sede_legale
        VARCHAR(100),

    ds_indirizzo_sede_operativa
        VARCHAR(100),

    cd_cap_sede_operativa
        VARCHAR(10),

    ds_citta_sede_operativa
        VARCHAR(100),

    cd_provincia_sede_operativa
        VARCHAR(100),

    ds_contatti
        TEXT,

    cd_stato
        VARCHAR(20),

    ds_note
        TEXT,

    ds_stato_attivita
        VARCHAR(100),

    cd_codice_fiscale
        VARCHAR(100),

    ds_anno_pubblicazione
        VARCHAR(100),

    dt_last_update
        VARCHAR(100),

    ds_nazione
        VARCHAR(40),

    cd_versione
        VARCHAR(20),

    id_sorgente_provincia
        VARCHAR(100),

    fl_escludi_invio_mail_assoc_listino_completa
        VARCHAR(20),

    tx_motivo_scarto
        VARCHAR(4000)
);

ALTER TABLE hcbi_ras.stg_anag_informatori_rej
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.stg_anag_informatori_rej
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.stg_anag_informatori_rej
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_informatori_rej
TO hcbi_utility;


/* =====================================================================
   TABELLA DWH
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_anag_informatori
(
    id_anag_informatore
        BIGINT NOT NULL DEFAULT nextval(
            'hcbi_ras.seq_dwh_anag_informatori'::REGCLASS
        ),

    id_sorgente_informatore
        INTEGER,

    ds_ragione_sociale
        VARCHAR(100) NOT NULL,

    cd_p_iva
        VARCHAR(100),

    cd_codice_ateco_2002
        VARCHAR(100),

    ds_indirizzo_sede_legale
        VARCHAR(100),

    cd_cap_sede_legale
        VARCHAR(10),

    ds_citta_sede_legale
        VARCHAR(100),

    cd_provincia_sede_legale
        VARCHAR(100),

    ds_indirizzo_sede_operativa
        VARCHAR(100),

    cd_cap_sede_operativa
        VARCHAR(10),

    ds_citta_sede_operativa
        VARCHAR(100),

    cd_provincia_sede_operativa
        VARCHAR(100),

    ds_contatti
        TEXT,

    cd_stato
        INTEGER,

    ds_note
        TEXT,

    ds_stato_attivita
        VARCHAR(100),

    cd_codice_fiscale
        VARCHAR(100),

    ds_anno_pubblicazione
        INTEGER NOT NULL,

    dt_last_update
        TIMESTAMP WITHOUT TIME ZONE,

    ds_nazione
        VARCHAR(40),

    cd_versione
        SMALLINT NOT NULL,

    id_sorgente_provincia
        BIGINT NOT NULL,

    fl_escludi_invio_mail_assoc_listino_completa
        INTEGER,

    dt_creation
        TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),

    tx_creation_by
        VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,

    dt_update
        TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),

    tx_update_by
        VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,

    dt_reciclo
        TIMESTAMP WITHOUT TIME ZONE,

    CONSTRAINT pk_dwh_anag_informatori
        PRIMARY KEY (id_anag_informatore),

    CONSTRAINT uq_dwh_anag_informatori
        UNIQUE NULLS NOT DISTINCT (
            ds_ragione_sociale, ds_anno_pubblicazione,
            cd_versione, id_sorgente_provincia
        )
);

ALTER TABLE hcbi_ras.dwh_anag_informatori
    OWNER TO hcbi_ras;

GRANT ALL
ON TABLE hcbi_ras.dwh_anag_informatori
TO hcbi_ras;

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE hcbi_ras.dwh_anag_informatori
TO hcbi_utility;


/* =====================================================================
   VISTA DWH
   ===================================================================== */

CREATE OR REPLACE VIEW hcbi_ras.v_dwh_anag_informatori
AS
SELECT
    s.id_sorgente_informatore,
    s.ds_ragione_sociale,
    s.cd_p_iva,
    s.cd_codice_ateco_2002,
    s.ds_indirizzo_sede_legale,
    s.cd_cap_sede_legale,
    s.ds_citta_sede_legale,
    s.cd_provincia_sede_legale,
    s.ds_indirizzo_sede_operativa,
    s.cd_cap_sede_operativa,
    s.ds_citta_sede_operativa,
    s.cd_provincia_sede_operativa,
    s.ds_contatti,
    s.cd_stato,
    s.ds_note,
    s.ds_stato_attivita,
    s.cd_codice_fiscale,
    s.ds_anno_pubblicazione,
    s.dt_last_update,
    s.ds_nazione,
    s.cd_versione,
    s.id_sorgente_provincia,
    s.fl_escludi_invio_mail_assoc_listino_completa
FROM hcbi_ras.stg_anag_informatori AS s;

ALTER VIEW hcbi_ras.v_dwh_anag_informatori
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_dwh_anag_informatori
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_dwh_anag_informatori
TO hcbi_utility;


/* =====================================================================
   FUNZIONI DI CONVERSIONE SICURA
   ===================================================================== */
CREATE OR REPLACE FUNCTION hcbi_ras.try_integer(p_value text) RETURNS integer LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog AS $function$ BEGIN RETURN p_value::integer; EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END; $function$;
CREATE OR REPLACE FUNCTION hcbi_ras.try_smallint(p_value text) RETURNS smallint LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog AS $function$ BEGIN RETURN p_value::smallint; EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END; $function$;
CREATE OR REPLACE FUNCTION hcbi_ras.try_bigint(p_value text) RETURNS bigint LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog AS $function$ BEGIN RETURN p_value::bigint; EXCEPTION WHEN invalid_text_representation OR numeric_value_out_of_range THEN RETURN NULL; END; $function$;
CREATE OR REPLACE FUNCTION hcbi_ras.try_timestamp(p_value text) RETURNS timestamp without time zone LANGUAGE plpgsql IMMUTABLE PARALLEL UNSAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog AS $function$ BEGIN RETURN p_value::timestamp without time zone; EXCEPTION WHEN invalid_datetime_format OR datetime_field_overflow THEN RETURN NULL; END; $function$;
CREATE OR REPLACE FUNCTION hcbi_ras.try_boolean_integer(p_value text) RETURNS integer LANGUAGE sql IMMUTABLE PARALLEL SAFE RETURNS NULL ON NULL INPUT SECURITY INVOKER SET search_path TO pg_catalog AS $function$ SELECT CASE lower(btrim(p_value)) WHEN 'true' THEN 1 WHEN 't' THEN 1 WHEN '1' THEN 1 WHEN 'yes' THEN 1 WHEN 'y' THEN 1 WHEN 'false' THEN 0 WHEN 'f' THEN 0 WHEN '0' THEN 0 WHEN 'no' THEN 0 WHEN 'n' THEN 0 ELSE NULL::integer END; $function$;
/* =====================================================================
   PROCEDURA STG INITIALIZE
   */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_initialize(
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
    v_id_log      bigint;
    v_selected    bigint := 0;
    v_inserted    bigint := 0;
    v_updated     bigint := 0;
    v_deleted     bigint := 0;
    v_rec_errors  bigint := 0;

    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
BEGIN
    p_result := -1;

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

    TRUNCATE
        hcbi_ras.stg_anag_informatori,
        hcbi_ras.stg_anag_informatori_rej;

    SELECT COUNT(*)
    INTO v_selected
    FROM hcbi_ras.v_src_tmp_anag_informatori;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        0,
        0,
        0,
        0,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
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

        v_log_error := LEFT(
            CONCAT_WS(
                E'\n',
                'SQLSTATE=' || COALESCE(v_sqlstate, ''),
                'MESSAGE=' || COALESCE(v_sqlerrm, ''),
                'DETAIL=' || COALESCE(v_sql_detail, ''),
                'HINT=' || COALESCE(v_sql_hint, ''),
                'CONTEXT=' || COALESCE(v_sql_context, '')
            ),
            4000
        );

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::timestamp,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore logging: %',
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_stg_anag_informatori_prc_initialize: %',
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
)
IS 'Inizializza il flusso STG ANAG_INFORMATORI.';
/* =====================================================================
   PROCEDURA STG MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_main(
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
    v_id_log     bigint;
    v_selected   bigint := 0;
    v_inserted   bigint := 0;
    v_updated    bigint := 0;
    v_deleted    bigint := 0;
    v_rec_errors bigint := 0;

    v_sqlstate   text;
    v_sqlerrm    text;
    v_sql_detail text;
    v_sql_hint   text;
    v_sql_context text;
    v_log_error  text;
BEGIN
    p_result := -1;

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

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_informatori_classificata;

    CREATE TABLE hcbi_ras.tmp_anag_informatori_classificata AS
    WITH src AS MATERIALIZED (
        SELECT
            f.id_sorgente_informatore
                AS id_sorgente_informatore_raw,
            f.ds_ragione_sociale
                AS ds_ragione_sociale_raw,
            f.cd_p_iva
                AS cd_p_iva_raw,
            f.cd_codice_ateco_2002
                AS cd_codice_ateco_2002_raw,
            f.ds_indirizzo_sede_legale
                AS ds_indirizzo_sede_legale_raw,
            f.cd_cap_sede_legale
                AS cd_cap_sede_legale_raw,
            f.ds_citta_sede_legale
                AS ds_citta_sede_legale_raw,
            f.cd_provincia_sede_legale
                AS cd_provincia_sede_legale_raw,
            f.ds_indirizzo_sede_operativa
                AS ds_indirizzo_sede_operativa_raw,
            f.cd_cap_sede_operativa
                AS cd_cap_sede_operativa_raw,
            f.ds_citta_sede_operativa
                AS ds_citta_sede_operativa_raw,
            f.cd_provincia_sede_operativa
                AS cd_provincia_sede_operativa_raw,
            f.ds_contatti
                AS ds_contatti_raw,
            f.cd_stato
                AS cd_stato_raw,
            f.ds_note
                AS ds_note_raw,
            f.ds_stato_attivita
                AS ds_stato_attivita_raw,
            f.cd_codice_fiscale
                AS cd_codice_fiscale_raw,
            f.ds_anno_pubblicazione
                AS ds_anno_pubblicazione_raw,
            f.dt_last_update
                AS dt_last_update_raw,
            f.ds_nazione
                AS ds_nazione_raw,
            f.cd_versione
                AS cd_versione_raw,
            f.id_sorgente_provincia
                AS id_sorgente_provincia_raw,
            f.fl_escludi_invio_mail_assoc_listino_completa
                AS fl_escludi_invio_mail_assoc_listino_completa_raw,

            NULLIF(BTRIM(f.id_sorgente_informatore::text), '')
                AS id_sorgente_informatore_txt,
            NULLIF(BTRIM(f.ds_ragione_sociale::text), '')
                AS ds_ragione_sociale_txt,
            NULLIF(BTRIM(f.cd_p_iva::text), '')
                AS cd_p_iva_txt,
            NULLIF(BTRIM(f.cd_codice_ateco_2002::text), '')
                AS cd_codice_ateco_2002_txt,
            NULLIF(BTRIM(f.ds_indirizzo_sede_legale::text), '')
                AS ds_indirizzo_sede_legale_txt,
            NULLIF(BTRIM(f.cd_cap_sede_legale::text), '')
                AS cd_cap_sede_legale_txt,
            NULLIF(BTRIM(f.ds_citta_sede_legale::text), '')
                AS ds_citta_sede_legale_txt,
            NULLIF(BTRIM(f.cd_provincia_sede_legale::text), '')
                AS cd_provincia_sede_legale_txt,
            NULLIF(BTRIM(f.ds_indirizzo_sede_operativa::text), '')
                AS ds_indirizzo_sede_operativa_txt,
            NULLIF(BTRIM(f.cd_cap_sede_operativa::text), '')
                AS cd_cap_sede_operativa_txt,
            NULLIF(BTRIM(f.ds_citta_sede_operativa::text), '')
                AS ds_citta_sede_operativa_txt,
            NULLIF(BTRIM(f.cd_provincia_sede_operativa::text), '')
                AS cd_provincia_sede_operativa_txt,
            NULLIF(BTRIM(f.ds_contatti::text), '')
                AS ds_contatti_txt,
            NULLIF(BTRIM(f.cd_stato::text), '')
                AS cd_stato_txt,
            NULLIF(BTRIM(f.ds_note::text), '')
                AS ds_note_txt,
            NULLIF(BTRIM(f.ds_stato_attivita::text), '')
                AS ds_stato_attivita_txt,
            NULLIF(BTRIM(f.cd_codice_fiscale::text), '')
                AS cd_codice_fiscale_txt,
            NULLIF(BTRIM(f.ds_anno_pubblicazione::text), '')
                AS ds_anno_pubblicazione_txt,
            NULLIF(BTRIM(f.dt_last_update::text), '')
                AS dt_last_update_txt,
            NULLIF(BTRIM(f.ds_nazione::text), '')
                AS ds_nazione_txt,
            NULLIF(BTRIM(f.cd_versione::text), '')
                AS cd_versione_txt,
            NULLIF(BTRIM(f.id_sorgente_provincia::text), '')
                AS id_sorgente_provincia_txt,
            NULLIF(
                BTRIM(f.fl_escludi_invio_mail_assoc_listino_completa::text),
                ''
            )
                AS fl_escludi_invio_mail_assoc_listino_completa_txt,

            COUNT(*) OVER (
                PARTITION BY
                    NULLIF(BTRIM(f.ds_ragione_sociale), ''),
                    NULLIF(BTRIM(f.ds_anno_pubblicazione), ''),
                    NULLIF(BTRIM(f.cd_versione), ''),
                    NULLIF(BTRIM(f.id_sorgente_provincia), '')
            ) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_anag_informatori AS f
    ),
    cv AS MATERIALIZED (
        SELECT
            s.*,
            hcbi_ras.try_integer(
                id_sorgente_informatore_txt
            ) AS id_sorgente_informatore_cv,
            hcbi_ras.try_integer(
                cd_stato_txt
            ) AS cd_stato_cv,
            hcbi_ras.try_integer(
                ds_anno_pubblicazione_txt
            ) AS ds_anno_pubblicazione_cv,
            hcbi_ras.try_timestamp(
                dt_last_update_txt
            ) AS dt_last_update_cv,
            hcbi_ras.try_smallint(
                cd_versione_txt
            ) AS cd_versione_cv,
            hcbi_ras.try_bigint(
                id_sorgente_provincia_txt
            ) AS id_sorgente_provincia_cv,
            hcbi_ras.try_boolean_integer(
                fl_escludi_invio_mail_assoc_listino_completa_txt
            ) AS fl_escludi_invio_mail_assoc_listino_completa_cv
        FROM src AS s
    )
    SELECT
        c.*,
        CASE
            WHEN duplicate_count > 1
                THEN 'Chiave duplicata'

            WHEN ds_ragione_sociale_txt IS NULL
                THEN 'ds_ragione_sociale obbligatorio'

            WHEN ds_anno_pubblicazione_txt IS NULL
                THEN 'ds_anno_pubblicazione obbligatorio'

            WHEN cd_versione_txt IS NULL
                THEN 'cd_versione obbligatorio'

            WHEN id_sorgente_provincia_txt IS NULL
                THEN 'id_sorgente_provincia obbligatorio'

            WHEN id_sorgente_informatore_txt IS NOT NULL
                 AND id_sorgente_informatore_cv IS NULL
                THEN 'id_sorgente_informatore non convertibile o fuori dominio'

            WHEN cd_stato_txt IS NOT NULL
                 AND cd_stato_cv IS NULL
                THEN 'cd_stato non convertibile o fuori dominio'

            WHEN ds_anno_pubblicazione_txt IS NOT NULL
                 AND ds_anno_pubblicazione_cv IS NULL
                THEN 'ds_anno_pubblicazione non convertibile o fuori dominio'

            WHEN dt_last_update_txt IS NOT NULL
                 AND dt_last_update_cv IS NULL
                THEN 'dt_last_update non convertibile o fuori dominio'

            WHEN cd_versione_txt IS NOT NULL
                 AND cd_versione_cv IS NULL
                THEN 'cd_versione non convertibile o fuori dominio'

            WHEN id_sorgente_provincia_txt IS NOT NULL
                 AND id_sorgente_provincia_cv IS NULL
                THEN 'id_sorgente_provincia non convertibile o fuori dominio'

            WHEN fl_escludi_invio_mail_assoc_listino_completa_txt IS NOT NULL
                 AND fl_escludi_invio_mail_assoc_listino_completa_cv IS NULL
                THEN 'fl_escludi_invio_mail_assoc_listino_completa non convertibile o fuori dominio'

            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM cv AS c;

    SELECT COUNT(*)
    INTO v_selected
    FROM hcbi_ras.tmp_anag_informatori_classificata;

    INSERT INTO hcbi_ras.stg_anag_informatori (
        id_sorgente_informatore,
        ds_ragione_sociale,
        cd_p_iva,
        cd_codice_ateco_2002,
        ds_indirizzo_sede_legale,
        cd_cap_sede_legale,
        ds_citta_sede_legale,
        cd_provincia_sede_legale,
        ds_indirizzo_sede_operativa,
        cd_cap_sede_operativa,
        ds_citta_sede_operativa,
        cd_provincia_sede_operativa,
        ds_contatti,
        cd_stato,
        ds_note,
        ds_stato_attivita,
        cd_codice_fiscale,
        ds_anno_pubblicazione,
        dt_last_update,
        ds_nazione,
        cd_versione,
        id_sorgente_provincia,
        fl_escludi_invio_mail_assoc_listino_completa
    )
    SELECT
        id_sorgente_informatore_cv,
        ds_ragione_sociale_txt,
        cd_p_iva_txt,
        cd_codice_ateco_2002_txt,
        ds_indirizzo_sede_legale_txt,
        cd_cap_sede_legale_txt,
        ds_citta_sede_legale_txt,
        cd_provincia_sede_legale_txt,
        ds_indirizzo_sede_operativa_txt,
        cd_cap_sede_operativa_txt,
        ds_citta_sede_operativa_txt,
        cd_provincia_sede_operativa_txt,
        ds_contatti_txt,
        cd_stato_cv,
        ds_note_txt,
        ds_stato_attivita_txt,
        cd_codice_fiscale_txt,
        ds_anno_pubblicazione_cv,
        dt_last_update_cv,
        ds_nazione_txt,
        cd_versione_cv,
        id_sorgente_provincia_cv,
        fl_escludi_invio_mail_assoc_listino_completa_cv
    FROM hcbi_ras.tmp_anag_informatori_classificata
    WHERE tx_motivo_scarto IS NULL;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_anag_informatori_rej (
        id_sorgente_informatore,
        ds_ragione_sociale,
        cd_p_iva,
        cd_codice_ateco_2002,
        ds_indirizzo_sede_legale,
        cd_cap_sede_legale,
        ds_citta_sede_legale,
        cd_provincia_sede_legale,
        ds_indirizzo_sede_operativa,
        cd_cap_sede_operativa,
        ds_citta_sede_operativa,
        cd_provincia_sede_operativa,
        ds_contatti,
        cd_stato,
        ds_note,
        ds_stato_attivita,
        cd_codice_fiscale,
        ds_anno_pubblicazione,
        dt_last_update,
        ds_nazione,
        cd_versione,
        id_sorgente_provincia,
        fl_escludi_invio_mail_assoc_listino_completa,
        tx_motivo_scarto
    )
    SELECT
        id_sorgente_informatore_raw,
        ds_ragione_sociale_raw,
        cd_p_iva_raw,
        cd_codice_ateco_2002_raw,
        ds_indirizzo_sede_legale_raw,
        cd_cap_sede_legale_raw,
        ds_citta_sede_legale_raw,
        cd_provincia_sede_legale_raw,
        ds_indirizzo_sede_operativa_raw,
        cd_cap_sede_operativa_raw,
        ds_citta_sede_operativa_raw,
        cd_provincia_sede_operativa_raw,
        ds_contatti_raw,
        cd_stato_raw,
        ds_note_raw,
        ds_stato_attivita_raw,
        cd_codice_fiscale_raw,
        ds_anno_pubblicazione_raw,
        dt_last_update_raw,
        ds_nazione_raw,
        cd_versione_raw,
        id_sorgente_provincia_raw,
        fl_escludi_invio_mail_assoc_listino_completa_raw,
        tx_motivo_scarto
    FROM hcbi_ras.tmp_anag_informatori_classificata
    WHERE tx_motivo_scarto IS NOT NULL;

    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION 'Riconciliazione non valida';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        0,
        0,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE hcbi_ras.tmp_anag_informatori_classificata;

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
            DROP TABLE IF EXISTS hcbi_ras.tmp_anag_informatori_classificata;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Errore cleanup: %', SQLERRM;
        END;

        v_log_error := LEFT(
            CONCAT_WS(
                E'\n',
                'SQLSTATE=' || COALESCE(v_sqlstate, ''),
                'MESSAGE=' || COALESCE(v_sqlerrm, ''),
                'DETAIL=' || COALESCE(v_sql_detail, ''),
                'HINT=' || COALESCE(v_sql_hint, ''),
                'CONTEXT=' || COALESCE(v_sql_context, '')
            ),
            4000
        );

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::timestamp,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Errore logging: %', SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_stg_anag_informatori_prc_main: %',
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
IS 'Carica STG: obbligatori soltanto i quattro campi della business key.';
/* =====================================================================
   PROCEDURA STG FINALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_finalize(
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
    v_id_log BIGINT;v_sqlstate text;v_sqlerrm text;v_sql_detail text;v_sql_hint text;v_sql_context text;v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Finalizzazione PKG_STG_ANAG_INFORMATORI per lo step %',
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

    ANALYZE hcbi_ras.stg_anag_informatori;
    ANALYZE hcbi_ras.stg_anag_informatori_rej;

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

EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;p_result:=-1;v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||coalesce(v_sqlerrm,''),'DETAIL='||coalesce(v_sql_detail,''),'HINT='||coalesce(v_sql_hint,''),'CONTEXT='||coalesce(v_sql_context,'')),4000);IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name);EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM;END;END IF;RAISE WARNING 'Errore in pkg_stg_anag_informatori_prc_finalize: %',v_sqlerrm;END;$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA DWH INITIALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_initialize(
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
    v_id_log BIGINT;v_sqlstate text;v_sqlerrm text;v_sql_detail text;v_sql_hint text;v_sql_context text;v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Inizializzazione PKG_DWH_ANAG_INFORMATORI per lo step %',
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

EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;p_result:=-1;v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||coalesce(v_sqlerrm,''),'DETAIL='||coalesce(v_sql_detail,''),'HINT='||coalesce(v_sql_hint,''),'CONTEXT='||coalesce(v_sql_context,'')),4000);IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name);EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM;END;END IF;RAISE WARNING 'Errore in pkg_dwh_anag_informatori_prc_initialize: %',v_sqlerrm;END;$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   PROCEDURA DWH MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_main(
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
    v_id_log      bigint;
    v_selected    bigint := 0;
    v_inserted    bigint := 0;
    v_updated     bigint := 0;
    v_deleted     bigint := 0;
    v_rec_errors  bigint := 0;

    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
BEGIN
    p_result := -1;

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

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_informatori;

    CREATE TABLE hcbi_ras.tmp_dwh_anag_informatori AS
    SELECT
        id_sorgente_informatore,
        ds_ragione_sociale,
        cd_p_iva,
        cd_codice_ateco_2002,
        ds_indirizzo_sede_legale,
        cd_cap_sede_legale,
        ds_citta_sede_legale,
        cd_provincia_sede_legale,
        ds_indirizzo_sede_operativa,
        cd_cap_sede_operativa,
        ds_citta_sede_operativa,
        cd_provincia_sede_operativa,
        ds_contatti,
        cd_stato,
        ds_note,
        ds_stato_attivita,
        cd_codice_fiscale,
        ds_anno_pubblicazione,
        dt_last_update,
        ds_nazione,
        cd_versione,
        id_sorgente_provincia,
        fl_escludi_invio_mail_assoc_listino_completa
    FROM hcbi_ras.v_dwh_anag_informatori;

    CREATE UNIQUE INDEX tmp_dwh_anag_informatori_uq
    ON hcbi_ras.tmp_dwh_anag_informatori (
        ds_ragione_sociale,
        ds_anno_pubblicazione,
        cd_versione,
        id_sorgente_provincia
    )
    NULLS NOT DISTINCT;

    SELECT COUNT(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dwh_anag_informatori;

    UPDATE hcbi_ras.dwh_anag_informatori AS d
    SET
        id_sorgente_informatore =
            src.id_sorgente_informatore,
        cd_p_iva =
            src.cd_p_iva,
        cd_codice_ateco_2002 =
            src.cd_codice_ateco_2002,
        ds_indirizzo_sede_legale =
            src.ds_indirizzo_sede_legale,
        cd_cap_sede_legale =
            src.cd_cap_sede_legale,
        ds_citta_sede_legale =
            src.ds_citta_sede_legale,
        cd_provincia_sede_legale =
            src.cd_provincia_sede_legale,
        ds_indirizzo_sede_operativa =
            src.ds_indirizzo_sede_operativa,
        cd_cap_sede_operativa =
            src.cd_cap_sede_operativa,
        ds_citta_sede_operativa =
            src.ds_citta_sede_operativa,
        cd_provincia_sede_operativa =
            src.cd_provincia_sede_operativa,
        ds_contatti =
            src.ds_contatti,
        cd_stato =
            src.cd_stato,
        ds_note =
            src.ds_note,
        ds_stato_attivita =
            src.ds_stato_attivita,
        cd_codice_fiscale =
            src.cd_codice_fiscale,
        dt_last_update =
            src.dt_last_update,
        ds_nazione =
            src.ds_nazione,
        fl_escludi_invio_mail_assoc_listino_completa =
            src.fl_escludi_invio_mail_assoc_listino_completa,
        dt_update =
            clock_timestamp(),
        tx_update_by =
            p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_informatori AS src
    WHERE d.ds_ragione_sociale = src.ds_ragione_sociale
      AND d.ds_anno_pubblicazione = src.ds_anno_pubblicazione
      AND d.cd_versione = src.cd_versione
      AND d.id_sorgente_provincia = src.id_sorgente_provincia
      AND (
             d.id_sorgente_informatore IS DISTINCT FROM
                 src.id_sorgente_informatore
          OR d.cd_p_iva IS DISTINCT FROM
                 src.cd_p_iva
          OR d.cd_codice_ateco_2002 IS DISTINCT FROM
                 src.cd_codice_ateco_2002
          OR d.ds_indirizzo_sede_legale IS DISTINCT FROM
                 src.ds_indirizzo_sede_legale
          OR d.cd_cap_sede_legale IS DISTINCT FROM
                 src.cd_cap_sede_legale
          OR d.ds_citta_sede_legale IS DISTINCT FROM
                 src.ds_citta_sede_legale
          OR d.cd_provincia_sede_legale IS DISTINCT FROM
                 src.cd_provincia_sede_legale
          OR d.ds_indirizzo_sede_operativa IS DISTINCT FROM
                 src.ds_indirizzo_sede_operativa
          OR d.cd_cap_sede_operativa IS DISTINCT FROM
                 src.cd_cap_sede_operativa
          OR d.ds_citta_sede_operativa IS DISTINCT FROM
                 src.ds_citta_sede_operativa
          OR d.cd_provincia_sede_operativa IS DISTINCT FROM
                 src.cd_provincia_sede_operativa
          OR d.ds_contatti IS DISTINCT FROM
                 src.ds_contatti
          OR d.cd_stato IS DISTINCT FROM
                 src.cd_stato
          OR d.ds_note IS DISTINCT FROM
                 src.ds_note
          OR d.ds_stato_attivita IS DISTINCT FROM
                 src.ds_stato_attivita
          OR d.cd_codice_fiscale IS DISTINCT FROM
                 src.cd_codice_fiscale
          OR d.dt_last_update IS DISTINCT FROM
                 src.dt_last_update
          OR d.ds_nazione IS DISTINCT FROM
                 src.ds_nazione
          OR d.fl_escludi_invio_mail_assoc_listino_completa
                 IS DISTINCT FROM
                 src.fl_escludi_invio_mail_assoc_listino_completa
      );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_anag_informatori (
        id_sorgente_informatore,
        ds_ragione_sociale,
        cd_p_iva,
        cd_codice_ateco_2002,
        ds_indirizzo_sede_legale,
        cd_cap_sede_legale,
        ds_citta_sede_legale,
        cd_provincia_sede_legale,
        ds_indirizzo_sede_operativa,
        cd_cap_sede_operativa,
        ds_citta_sede_operativa,
        cd_provincia_sede_operativa,
        ds_contatti,
        cd_stato,
        ds_note,
        ds_stato_attivita,
        cd_codice_fiscale,
        ds_anno_pubblicazione,
        dt_last_update,
        ds_nazione,
        cd_versione,
        id_sorgente_provincia,
        fl_escludi_invio_mail_assoc_listino_completa,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_sorgente_informatore,
        src.ds_ragione_sociale,
        src.cd_p_iva,
        src.cd_codice_ateco_2002,
        src.ds_indirizzo_sede_legale,
        src.cd_cap_sede_legale,
        src.ds_citta_sede_legale,
        src.cd_provincia_sede_legale,
        src.ds_indirizzo_sede_operativa,
        src.cd_cap_sede_operativa,
        src.ds_citta_sede_operativa,
        src.cd_provincia_sede_operativa,
        src.ds_contatti,
        src.cd_stato,
        src.ds_note,
        src.ds_stato_attivita,
        src.cd_codice_fiscale,
        src.ds_anno_pubblicazione,
        src.dt_last_update,
        src.ds_nazione,
        src.cd_versione,
        src.id_sorgente_provincia,
        src.fl_escludi_invio_mail_assoc_listino_completa,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_informatori AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_anag_informatori
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        0,
        0,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE hcbi_ras.tmp_dwh_anag_informatori;

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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_informatori;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore cleanup: %',
                    SQLERRM;
        END;

        v_log_error := LEFT(
            CONCAT_WS(
                E'\n',
                'SQLSTATE=' || COALESCE(v_sqlstate, ''),
                'MESSAGE=' || COALESCE(v_sqlerrm, ''),
                'DETAIL=' || COALESCE(v_sql_detail, ''),
                'HINT=' || COALESCE(v_sql_hint, ''),
                'CONTEXT=' || COALESCE(v_sql_context, '')
            ),
            4000
        );

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::timestamp,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore logging: %',
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dwh_anag_informatori_prc_main: %',
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
IS 'Carica DWH usando la nuova business key.';
/* =====================================================================
   PROCEDURA DWH FINALIZE
   ===================================================================== */

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_finalize(
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
    v_id_log BIGINT;v_sqlstate text;v_sqlerrm text;v_sql_detail text;v_sql_hint text;v_sql_context text;v_log_error text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Finalizzazione PKG_DWH_ANAG_INFORMATORI per lo step %',
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

    ANALYZE hcbi_ras.dwh_anag_informatori;

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

EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;p_result:=-1;v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||coalesce(v_sqlerrm,''),'DETAIL='||coalesce(v_sql_detail,''),'HINT='||coalesce(v_sql_hint,''),'CONTEXT='||coalesce(v_sql_context,'')),4000);IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name);EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM;END;END IF;RAISE WARNING 'Errore in pkg_dwh_anag_informatori_prc_finalize: %',v_sqlerrm;END;$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
TO PUBLIC, hcbi_ras, hcbi_utility;


/* =====================================================================
   COMMENTI
   ===================================================================== */

COMMENT ON TABLE hcbi_ras.frontiera_anag_informatori
IS 'Frontiera del flusso ANAG_INFORMATORI';

COMMENT ON TABLE hcbi_ras.src_tmp_anag_informatori
IS 'Tabella temporanea sorgente del flusso ANAG_INFORMATORI';

COMMENT ON TABLE hcbi_ras.stg_anag_informatori
IS 'Staging del flusso ANAG_INFORMATORI';

COMMENT ON TABLE hcbi_ras.stg_anag_informatori_rej
IS 'Record scartati del flusso ANAG_INFORMATORI';

COMMENT ON TABLE hcbi_ras.dwh_anag_informatori
IS 'DWH del flusso ANAG_INFORMATORI';

COMMENT ON VIEW hcbi_ras.v_src_tmp_anag_informatori
IS 'Vista di conversione della sorgente temporanea ANAG_INFORMATORI';

COMMENT ON VIEW hcbi_ras.v_dwh_anag_informatori
IS 'Vista di raccordo tra STG_ANAG_INFORMATORI e DWH_ANAG_INFORMATORI';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Inizializza le tabelle STG_ANAG_INFORMATORI e STG_ANAG_INFORMATORI_REJ, gestisce i duplicati e registra l''esecuzione nel log.';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_main(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Converte e carica i dati nella tabella STG_ANAG_INFORMATORI registrando gli scarti nella tabella REJ.';

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Finalizza il caricamento STG_ANAG_INFORMATORI e aggiorna le statistiche.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_initialize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Inizializza il flusso DWH_ANAG_INFORMATORI e registra l''esecuzione nel log.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_main(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Carica DWH_ANAG_INFORMATORI dalla tabella STG aggiornando i record esistenti e inserendo i nuovi.';

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_finalize(
    BIGINT,
    BIGINT,
    BIGINT,
    CHARACTER VARYING
)
IS 'Finalizza il flusso DWH_ANAG_INFORMATORI e aggiorna le statistiche.';
COMMENT ON CONSTRAINT uq_dwh_anag_informatori ON hcbi_ras.dwh_anag_informatori IS 'Business key: ds_ragione_sociale, ds_anno_pubblicazione, cd_versione, id_sorgente_provincia.';
