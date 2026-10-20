/* =====================================================================
   FLUSSO PUBBLICAZIONE_ANALISI
   ===================================================================== */


/* =====================================================================
   SEQUENCE DWH
   ===================================================================== */

CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_pubblicazione_analisi
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_pubblicazione_analisi
    OWNER TO hcbi_ras;

GRANT ALL ON SEQUENCE hcbi_ras.seq_dwh_pubblicazione_analisi
TO hcbi_ras;

GRANT USAGE, SELECT
ON SEQUENCE hcbi_ras.seq_dwh_pubblicazione_analisi
TO hcbi_utility;


/* =====================================================================
   TABELLA FRONTIERA
   ===================================================================== */

-- DROP TABLE IF EXISTS hcbi_ras.frontiera_pubblicazione_analisi;
CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_pubblicazione_analisi
(
    anno character varying(100) COLLATE pg_catalog."default",
    codice_analisi character varying(70) COLLATE pg_catalog."default",
    quantita character varying(100) COLLATE pg_catalog."default",
    codice_elemento character varying(70) COLLATE pg_catalog."default",
    addendum character varying(20) COLLATE pg_catalog."default",
    id character varying(100) COLLATE pg_catalog."default",
    id_categoria character varying(20) COLLATE pg_catalog."default",
    nr_riga smallint
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.frontiera_pubblicazione_analisi
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.frontiera_pubblicazione_analisi FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.frontiera_pubblicazione_analisi TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.frontiera_pubblicazione_analisi TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.frontiera_pubblicazione_analisi
    IS 'Frontiera del flusso PUBBLICAZIONE_ANALISI';

/* =====================================================================
   TABELLA SRC_TMP
   ===================================================================== */
-- Table: hcbi_ras.src_tmp_pubblicazione_analisi

-- DROP TABLE IF EXISTS hcbi_ras.src_tmp_pubblicazione_analisi;

CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_pubblicazione_analisi
(
    anno character varying(100) COLLATE pg_catalog."default",
    codice_analisi character varying(70) COLLATE pg_catalog."default",
    quantita character varying(100) COLLATE pg_catalog."default",
    codice_elemento character varying(70) COLLATE pg_catalog."default",
    addendum character varying(20) COLLATE pg_catalog."default",
    id character varying(100) COLLATE pg_catalog."default",
    id_categoria character varying(20) COLLATE pg_catalog."default",
    nr_riga smallint
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.src_tmp_pubblicazione_analisi
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.src_tmp_pubblicazione_analisi FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.src_tmp_pubblicazione_analisi TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.src_tmp_pubblicazione_analisi TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.src_tmp_pubblicazione_analisi
    IS 'Tabella temporanea sorgente del flusso PUBBLICAZIONE_ANALISI';

/* =====================================================================
   VISTA SRC_TMP
   ===================================================================== */
-- View: hcbi_ras.v_src_tmp_pubblicazione_analisi

-- DROP VIEW hcbi_ras.v_src_tmp_pubblicazione_analisi;

CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_pubblicazione_analisi
 AS
 SELECT TRIM(BOTH FROM s.anno::text) AS ds_anno_pubblicazione,
    TRIM(BOTH FROM s.codice_analisi::text) AS cd_codice_analisi,
    TRIM(BOTH FROM s.quantita::text) AS nr_quantita,
    TRIM(BOTH FROM s.codice_elemento::text) AS cd_articolo,
    TRIM(BOTH FROM s.addendum::text) AS cd_versione,
    TRIM(BOTH FROM s.id::text) AS id_sorgente_pubblicazione_analisi,
    TRIM(BOTH FROM s.id_categoria::text) AS id_sorgente_categoria,
    s.nr_riga
   FROM hcbi_ras.src_tmp_pubblicazione_analisi s;

ALTER TABLE hcbi_ras.v_src_tmp_pubblicazione_analisi
    OWNER TO hcbi_ras;

GRANT ALL ON TABLE hcbi_ras.v_src_tmp_pubblicazione_analisi TO hcbi_ras;
GRANT SELECT ON TABLE hcbi_ras.v_src_tmp_pubblicazione_analisi TO hcbi_utility;

/* =====================================================================
   TABELLA STG
   ===================================================================== */

-- DROP TABLE IF EXISTS hcbi_ras.stg_pubblicazione_analisi;

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_pubblicazione_analisi
(
    ds_anno_pubblicazione numeric(10,0) NOT NULL,
    cd_codice_analisi character varying(70) COLLATE pg_catalog."default" NOT NULL,
    nr_quantita numeric(24,6),
    cd_articolo character varying(70) COLLATE pg_catalog."default" NOT NULL,
    cd_versione smallint NOT NULL,
    id_sorgente_pubblicazione_analisi bigint,
    id_sorgente_categoria bigint,
    nr_riga smallint NOT NULL
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.stg_pubblicazione_analisi
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.stg_pubblicazione_analisi FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.stg_pubblicazione_analisi TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.stg_pubblicazione_analisi TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.stg_pubblicazione_analisi
    IS 'Staging del flusso PUBBLICAZIONE_ANALISI';

COMMENT ON COLUMN hcbi_ras.stg_pubblicazione_analisi.cd_articolo
    IS 'Codice articolo associato all''analisi';


/* =====================================================================
   TABELLA STG REJECT
   ===================================================================== */

-- DROP TABLE IF EXISTS hcbi_ras.stg_pubblicazione_analisi_rej;

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_pubblicazione_analisi_rej
(
    ds_anno_pubblicazione character varying(100) COLLATE pg_catalog."default",
    cd_codice_analisi character varying(70) COLLATE pg_catalog."default",
    nr_quantita character varying(100) COLLATE pg_catalog."default",
    cd_articolo character varying(70) COLLATE pg_catalog."default",
    cd_versione character varying(20) COLLATE pg_catalog."default",
    id_sorgente_pubblicazione_analisi character varying(100) COLLATE pg_catalog."default",
    id_sorgente_categoria character varying(20) COLLATE pg_catalog."default",
    tx_motivo_scarto character varying(4000) COLLATE pg_catalog."default",
    nr_riga smallint
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.stg_pubblicazione_analisi_rej
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.stg_pubblicazione_analisi_rej FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.stg_pubblicazione_analisi_rej TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.stg_pubblicazione_analisi_rej TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.stg_pubblicazione_analisi_rej
    IS 'Record scartati del flusso PUBBLICAZIONE_ANALISI';

COMMENT ON COLUMN hcbi_ras.stg_pubblicazione_analisi_rej.cd_articolo
    IS 'Codice articolo associato all''analisi';


/* =====================================================================
   TABELLA DWH
   ===================================================================== */
-- DROP TABLE IF EXISTS hcbi_ras.dwh_pubblicazione_analisi;

CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_pubblicazione_analisi
(
    id_pubblicazione_analisi bigint NOT NULL DEFAULT nextval('hcbi_ras.seq_dwh_pubblicazione_analisi'::regclass),
    ds_anno_pubblicazione numeric(10,0) NOT NULL,
    cd_codice_analisi character varying(70) COLLATE pg_catalog."default" NOT NULL,
    nr_quantita numeric(24,6),
    cd_articolo character varying(70) COLLATE pg_catalog."default" NOT NULL,
    cd_versione smallint NOT NULL,
    id_sorgente_pubblicazione_analisi bigint,
    id_sorgente_categoria bigint,
    nr_riga smallint,
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by character varying(4000) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by character varying(4000) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
    dt_reciclo timestamp without time zone,
    CONSTRAINT pk_dwh_pubblicazione_analisi PRIMARY KEY (id_pubblicazione_analisi),
    CONSTRAINT uq_dwh_pubblicazione_analisi UNIQUE NULLS NOT DISTINCT (ds_anno_pubblicazione, cd_codice_analisi, cd_articolo, cd_versione, nr_riga)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dwh_pubblicazione_analisi
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.dwh_pubblicazione_analisi FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.dwh_pubblicazione_analisi TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.dwh_pubblicazione_analisi TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dwh_pubblicazione_analisi
    IS 'DWH del flusso PUBBLICAZIONE_ANALISI';

COMMENT ON COLUMN hcbi_ras.dwh_pubblicazione_analisi.cd_articolo
    IS 'Codice articolo associato all''analisi';

/* =====================================================================
   VISTA DWH
   ===================================================================== */

-- DROP VIEW hcbi_ras.v_dwh_pubblicazione_analisi;

CREATE OR REPLACE VIEW hcbi_ras.v_dwh_pubblicazione_analisi
 AS
 SELECT s.ds_anno_pubblicazione,
    s.cd_codice_analisi,
    s.nr_quantita,
    s.cd_articolo,
    s.cd_versione,
    s.id_sorgente_pubblicazione_analisi,
    s.id_sorgente_categoria,
    s.nr_riga
   FROM hcbi_ras.stg_pubblicazione_analisi s;

ALTER TABLE hcbi_ras.v_dwh_pubblicazione_analisi
    OWNER TO hcbi_ras;

GRANT ALL ON TABLE hcbi_ras.v_dwh_pubblicazione_analisi TO hcbi_ras;
GRANT SELECT ON TABLE hcbi_ras.v_dwh_pubblicazione_analisi TO hcbi_utility;

-- ----------------------------------------------------------------------------
-- 1. Funzioni di conversione sicura
--    Compatibili con PostgreSQL 15.9 e PostgreSQL 17.
--    Restituiscono NULL quando il valore non e' convertibile o e' fuori range.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION hcbi_ras.try_numeric_10_0(
    p_value text
)
RETURNS numeric(10,0)
LANGUAGE plpgsql
IMMUTABLE
PARALLEL UNSAFE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
SET search_path TO pg_catalog
AS $function$
BEGIN
    RETURN p_value::numeric(10,0);

EXCEPTION
    WHEN invalid_text_representation
       OR numeric_value_out_of_range
    THEN
        RETURN NULL;
END;
$function$;

ALTER FUNCTION hcbi_ras.try_numeric_10_0(text)
    OWNER TO hcbi_ras;

COMMENT ON FUNCTION hcbi_ras.try_numeric_10_0(text)
IS 'Converte text in numeric(10,0); restituisce NULL per input non valido o fuori range.';


CREATE OR REPLACE FUNCTION hcbi_ras.try_numeric_24_6(
    p_value text
)
RETURNS numeric(24,6)
LANGUAGE plpgsql
IMMUTABLE
PARALLEL UNSAFE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
SET search_path TO pg_catalog
AS $function$
BEGIN
    RETURN p_value::numeric(24,6);

EXCEPTION
    WHEN invalid_text_representation
       OR numeric_value_out_of_range
    THEN
        RETURN NULL;
END;
$function$;

ALTER FUNCTION hcbi_ras.try_numeric_24_6(text)
    OWNER TO hcbi_ras;

COMMENT ON FUNCTION hcbi_ras.try_numeric_24_6(text)
IS 'Converte text in numeric(24,6); restituisce NULL per input non valido o fuori range.';


CREATE OR REPLACE FUNCTION hcbi_ras.try_smallint(
    p_value text
)
RETURNS smallint
LANGUAGE plpgsql
IMMUTABLE
PARALLEL UNSAFE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
SET search_path TO pg_catalog
AS $function$
BEGIN
    RETURN p_value::smallint;

EXCEPTION
    WHEN invalid_text_representation
       OR numeric_value_out_of_range
    THEN
        RETURN NULL;
END;
$function$;

ALTER FUNCTION hcbi_ras.try_smallint(text)
    OWNER TO hcbi_ras;

COMMENT ON FUNCTION hcbi_ras.try_smallint(text)
IS 'Converte text in smallint; restituisce NULL per input non valido o fuori range.';


CREATE OR REPLACE FUNCTION hcbi_ras.try_bigint(
    p_value text
)
RETURNS bigint
LANGUAGE plpgsql
IMMUTABLE
PARALLEL UNSAFE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
SET search_path TO pg_catalog
AS $function$
BEGIN
    RETURN p_value::bigint;

EXCEPTION
    WHEN invalid_text_representation
       OR numeric_value_out_of_range
    THEN
        RETURN NULL;
END;
$function$;

ALTER FUNCTION hcbi_ras.try_bigint(text)
    OWNER TO hcbi_ras;

COMMENT ON FUNCTION hcbi_ras.try_bigint(text)
IS 'Converte text in bigint; restituisce NULL per input non valido o fuori range.';


/* =====================================================================
   PROCEDURA STG INITIALIZE
   ===================================================================== */

-- DROP PROCEDURE IF EXISTS hcbi_ras.pkg_stg_pubblicazione_analisi_prc_initialize(bigint, bigint, bigint, character varying);

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_initialize(
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
    v_id_log     bigint;
    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Inizializzazione PKG_STG_PUBBLICAZIONE_ANALISI: '
        'pulizia delle tabelle STG e REJ per lo step %',
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

    TRUNCATE TABLE hcbi_ras.stg_pubblicazione_analisi;
    TRUNCATE TABLE hcbi_ras.stg_pubblicazione_analisi_rej;


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

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;
        p_result := -1;
        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE='  || left(coalesce(v_sqlerrm, ''), 1500),
                CASE WHEN nullif(v_sql_detail, '') IS NOT NULL
                    THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
                CASE WHEN nullif(v_sql_hint, '') IS NOT NULL
                    THEN 'HINT=' || left(v_sql_hint, 500) END,
                CASE WHEN nullif(v_sql_context, '') IS NOT NULL
                    THEN 'CONTEXT=' || left(v_sql_context, 800) END
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
                        'Errore durante la registrazione del log di errore: '
                        'SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;
        -- Compatibilita' con il contratto corrente:
        -- l'errore non viene rilanciato; il chiamante deve verificare p_result.
        RAISE WARNING
            'Errore in pkg_stg_pubblicazione_analisi_prc_initialize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_initialize(bigint, bigint, bigint, character varying)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_initialize(bigint, bigint, bigint, character varying) TO PUBLIC;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_initialize(bigint, bigint, bigint, character varying) TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_initialize(bigint, bigint, bigint, character varying) TO hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_initialize(bigint, bigint, bigint, character varying)
    IS 'Inizializza il caricamento STG PUBBLICAZIONE_ANALISI, svuota le tabelle STG e REJ e registra l''esecuzione nel log. La classificazione dei record e la gestione degli scarti sono eseguite dalla procedura main.';


/* =====================================================================
   PROCEDURA STG MAIN
   ===================================================================== */


-- DROP PROCEDURE IF EXISTS hcbi_ras.pkg_stg_pubblicazione_analisi_prc_main(bigint, bigint, bigint, character varying);

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_main(
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
    v_id_log        bigint;
    v_selected      bigint := 0;
    v_inserted      bigint := 0;
    v_updated       bigint := 0;
    v_deleted       bigint := 0;
    v_rec_errors    bigint := 0;

    v_sqlstate      text;
    v_sqlerrm       text;
    v_sql_detail    text;
    v_sql_hint      text;
    v_sql_context   text;
    v_log_error     text;
    v_ts_start      timestamp;
BEGIN
    p_result  := -1;
    v_ts_start := clock_timestamp()::timestamp;

    RAISE NOTICE
        'Avvio PKG_STG_PUBBLICAZIONE_ANALISI per lo step %',
        p_ds_step_name;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        v_ts_start,
        v_ts_start,
        p_ds_step_name
    )
    INTO v_id_log;

    -- Tabella di lavoro persistente. Nessuna concorrenza ammessa.
    DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_analisi_classificata;

    CREATE TABLE hcbi_ras.tmp_pubblicazione_analisi_classificata
    AS
    WITH src AS MATERIALIZED (
        SELECT
            f.ds_anno_pubblicazione,
            f.cd_codice_analisi,
            f.nr_quantita,
            f.cd_articolo,
            f.cd_versione,
            f.id_sorgente_pubblicazione_analisi,
            f.id_sorgente_categoria,
            f.nr_riga,

            NULLIF(btrim(f.ds_anno_pubblicazione), '')
                AS anno_txt,

            NULLIF(btrim(f.cd_codice_analisi), '')
                AS codice_analisi_txt,

            NULLIF(
                replace(btrim(f.nr_quantita), ',', '.'),
                ''
            ) AS quantita_txt,

            NULLIF(btrim(f.cd_articolo), '')
                AS articolo_txt,

            NULLIF(btrim(f.cd_versione), '')
                AS versione_txt,

            NULLIF(
                btrim(f.id_sorgente_pubblicazione_analisi),
                ''
            ) AS id_pubblicazione_txt,

            NULLIF(
                btrim(f.id_sorgente_categoria),
                ''
            ) AS id_categoria_txt,

            count(*) OVER (
                PARTITION BY
                    f.ds_anno_pubblicazione,
                    f.cd_codice_analisi,
                    f.cd_articolo,
                    f.cd_versione,
                    f.nr_riga
            ) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_pubblicazione_analisi AS f
    ),
    converted AS MATERIALIZED (
        SELECT
            s.ds_anno_pubblicazione,
            s.cd_codice_analisi,
            s.nr_quantita,
            s.cd_articolo,
            s.cd_versione,
            s.id_sorgente_pubblicazione_analisi,
            s.id_sorgente_categoria,
            s.nr_riga,
            s.anno_txt,
            s.codice_analisi_txt,
            s.quantita_txt,
            s.articolo_txt,
            s.versione_txt,
            s.id_pubblicazione_txt,
            s.id_categoria_txt,
            s.duplicate_count,

            hcbi_ras.try_numeric_10_0(s.anno_txt)
                AS anno_convertito,

            hcbi_ras.try_numeric_24_6(s.quantita_txt)
                AS quantita_convertita,

            hcbi_ras.try_smallint(s.versione_txt)
                AS versione_convertita,

            hcbi_ras.try_bigint(s.id_pubblicazione_txt)
                AS id_pubblicazione_convertito,

            hcbi_ras.try_bigint(s.id_categoria_txt)
                AS id_categoria_convertito
        FROM src AS s
    )
    SELECT
        c.ds_anno_pubblicazione,
        c.cd_codice_analisi,
        c.nr_quantita,
        c.cd_articolo,
        c.cd_versione,
        c.id_sorgente_pubblicazione_analisi,
        c.id_sorgente_categoria,
        c.nr_riga,
        c.anno_txt,
        c.codice_analisi_txt,
        c.quantita_txt,
        c.articolo_txt,
        c.versione_txt,
        c.id_pubblicazione_txt,
        c.id_categoria_txt,
        c.anno_convertito,
        c.quantita_convertita,
        c.versione_convertita,
        c.id_pubblicazione_convertito,
        c.id_categoria_convertito,
        c.duplicate_count,
        CASE
            WHEN c.duplicate_count > 1 THEN
                'Chiave duplicata nella sorgente: '
                || '(ds_anno_pubblicazione, cd_codice_analisi, '
                || 'cd_articolo, cd_versione, nr_riga)'

            WHEN c.anno_txt IS NOT NULL
             AND c.anno_convertito IS NULL THEN
                'ds_anno_pubblicazione non convertibile in numeric(10,0)'

            WHEN c.quantita_txt IS NOT NULL
             AND c.quantita_convertita IS NULL THEN
                'nr_quantita non convertibile in numeric(24,6)'

            WHEN c.versione_txt IS NOT NULL
             AND c.versione_convertita IS NULL THEN
                'cd_versione non convertibile in smallint'

            WHEN c.id_pubblicazione_txt IS NOT NULL
             AND c.id_pubblicazione_convertito IS NULL THEN
                'id_sorgente_pubblicazione_analisi non convertibile in bigint'

            WHEN c.id_categoria_txt IS NOT NULL
             AND c.id_categoria_convertito IS NULL THEN
                'id_sorgente_categoria non convertibile in bigint'

            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM converted AS c;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_pubblicazione_analisi_classificata;

    INSERT INTO hcbi_ras.stg_pubblicazione_analisi (
        ds_anno_pubblicazione,
        cd_codice_analisi,
        nr_quantita,
        cd_articolo,
        cd_versione,
        id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria,
        nr_riga
    )
    SELECT
        c.anno_convertito,
        c.codice_analisi_txt,
        c.quantita_convertita,
        c.articolo_txt,
        c.versione_convertita,
        c.id_pubblicazione_convertito,
        c.id_categoria_convertito,
        c.nr_riga
    FROM hcbi_ras.tmp_pubblicazione_analisi_classificata AS c
    WHERE c.tx_motivo_scarto IS NULL;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_pubblicazione_analisi_rej (
        ds_anno_pubblicazione,
        cd_codice_analisi,
        nr_quantita,
        cd_articolo,
        cd_versione,
        id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria,
        nr_riga,
        tx_motivo_scarto
    )
    SELECT
        c.ds_anno_pubblicazione,
        c.cd_codice_analisi,
        c.nr_quantita,
        c.cd_articolo,
        c.cd_versione,
        c.id_sorgente_pubblicazione_analisi,
        c.id_sorgente_categoria,
        c.nr_riga,
        c.tx_motivo_scarto
    FROM hcbi_ras.tmp_pubblicazione_analisi_classificata AS c
    WHERE c.tx_motivo_scarto IS NOT NULL;

    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    v_updated := 0;
    v_deleted := 0;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = format(
                    'Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',
                    v_selected,
                    v_inserted,
                    v_rec_errors
                ),
                DETAIL =
                    'Il numero di record letti non coincide con la somma '
                    || 'dei record caricati e scartati.',
                HINT =
                    'Verificare la classificazione e gli INSERT verso STG e REJ.';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    -- Pulizia della tabella di lavoro dopo l'uso.
    DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_analisi_classificata;

    p_result := 1;

    RAISE NOTICE
        'Fine PKG_STG_PUBBLICAZIONE_ANALISI: selected=%, inserted=%, rejected=%',
        v_selected,
        v_inserted,
        v_rec_errors;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;

        p_result := -1;

        -- Pulizia best effort: non deve sostituire l'errore originario.
        BEGIN
            DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_analisi_classificata;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante la pulizia della tabella di lavoro: '
                    'SQLSTATE=%, errore=%',
                    SQLSTATE,
                    SQLERRM;
        END;

v_log_error := left(
    concat_ws(
        E'\n',
        'SQLSTATE=' || coalesce(v_sqlstate, ''),
        'MESSAGE='  || left(coalesce(v_sqlerrm, ''), 1500),
        CASE
            WHEN nullif(v_sql_detail, '') IS NOT NULL
                THEN 'DETAIL=' || left(v_sql_detail, 1000)
        END,
        CASE
            WHEN nullif(v_sql_hint, '') IS NOT NULL
                THEN 'HINT=' || left(v_sql_hint, 500)
        END,
        CASE
            WHEN nullif(v_sql_context, '') IS NOT NULL
                THEN 'CONTEXT=' || left(v_sql_context, 800)
        END
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
                        'Errore durante la registrazione del log di errore: '
                        'SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        -- Compatibilita' con la procedura originaria:
        -- l'errore non viene rilanciato; il chiamante deve verificare p_result.
        RAISE WARNING
            'Errore in pkg_stg_pubblicazione_analisi_prc_main. '
            'SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_main(bigint, bigint, bigint, character varying)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_main(bigint, bigint, bigint, character varying) TO PUBLIC;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_main(bigint, bigint, bigint, character varying) TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_main(bigint, bigint, bigint, character varying) TO hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_main(bigint, bigint, bigint, character varying)
    IS 'Converte e carica in modalita set-based i dati nella tabella STG_PUBBLICAZIONE_ANALISI; valida le conversioni, identifica i duplicati e registra gli scarti nella tabella REJ. Compatibile con PostgreSQL 15.9 e 17.';


/* =====================================================================
   PROCEDURA STG FINALIZE
   ===================================================================== */

-- DROP PROCEDURE IF EXISTS hcbi_ras.pkg_stg_pubblicazione_analisi_prc_finalize(bigint, bigint, bigint, character varying);

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_finalize(
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
    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Finalizzazione PKG_STG_PUBBLICAZIONE_ANALISI per lo step %',
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

    ANALYZE hcbi_ras.stg_pubblicazione_analisi;
    ANALYZE hcbi_ras.stg_pubblicazione_analisi_rej;

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

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;
        p_result := -1;
        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE='  || left(coalesce(v_sqlerrm, ''), 1500),
                CASE WHEN nullif(v_sql_detail, '') IS NOT NULL
                    THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
                CASE WHEN nullif(v_sql_hint, '') IS NOT NULL
                    THEN 'HINT=' || left(v_sql_hint, 500) END,
                CASE WHEN nullif(v_sql_context, '') IS NOT NULL
                    THEN 'CONTEXT=' || left(v_sql_context, 800) END
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
                        'Errore durante la registrazione del log di errore: '
                        'SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;
        -- Compatibilita' con il contratto corrente:
        -- l'errore non viene rilanciato; il chiamante deve verificare p_result.
        RAISE WARNING
            'Errore in pkg_stg_pubblicazione_analisi_prc_finalize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_finalize(bigint, bigint, bigint, character varying)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_finalize(bigint, bigint, bigint, character varying) TO PUBLIC;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_finalize(bigint, bigint, bigint, character varying) TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_finalize(bigint, bigint, bigint, character varying) TO hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_stg_pubblicazione_analisi_prc_finalize(bigint, bigint, bigint, character varying)
    IS 'Finalizza il caricamento STG_PUBBLICAZIONE_ANALISI e aggiorna le statistiche.';


/* =====================================================================
   PROCEDURA DWH INITIALIZE
   ===================================================================== */
-- DROP PROCEDURE IF EXISTS hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_initialize(bigint, bigint, bigint, character varying);

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_initialize(
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
    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Inizializzazione PKG_DWH_PUBBLICAZIONE_ANALISI per lo step %',
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

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;
        p_result := -1;
        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE='  || left(coalesce(v_sqlerrm, ''), 1500),
                CASE WHEN nullif(v_sql_detail, '') IS NOT NULL
                    THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
                CASE WHEN nullif(v_sql_hint, '') IS NOT NULL
                    THEN 'HINT=' || left(v_sql_hint, 500) END,
                CASE WHEN nullif(v_sql_context, '') IS NOT NULL
                    THEN 'CONTEXT=' || left(v_sql_context, 800) END
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
                        'Errore durante la registrazione del log di errore: '
                        'SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;
        -- Compatibilita' con il contratto corrente:
        -- l'errore non viene rilanciato; il chiamante deve verificare p_result.
        RAISE WARNING
            'Errore in pkg_dwh_pubblicazione_analisi_prc_initialize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_initialize(bigint, bigint, bigint, character varying)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_initialize(bigint, bigint, bigint, character varying) TO PUBLIC;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_initialize(bigint, bigint, bigint, character varying) TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_initialize(bigint, bigint, bigint, character varying) TO hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_initialize(bigint, bigint, bigint, character varying)
    IS 'Inizializza il flusso DWH_PUBBLICAZIONE_ANALISI e registra l''esecuzione nel log.';


/* =====================================================================
   PROCEDURA DWH MAIN
   ===================================================================== */
-- DROP PROCEDURE IF EXISTS hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_main(bigint, bigint, bigint, character varying);

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_main(
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

    RAISE NOTICE
        'Avvio PKG_DWH_PUBBLICAZIONE_ANALISI per lo step %',
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

    /*
     * Tabella di lavoro persistente nello schema hcbi_ras.
     * Non e' ammessa l'esecuzione concorrente della procedura
     * per lo stesso flusso.
     */
    DROP TABLE IF EXISTS
        hcbi_ras.tmp_dwh_pubblicazione_analisi;

    CREATE TABLE
        hcbi_ras.tmp_dwh_pubblicazione_analisi
    AS
    SELECT
        ds_anno_pubblicazione,
        cd_codice_analisi,
        nr_quantita,
        cd_articolo,
        cd_versione,
        id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria,
        nr_riga
    FROM hcbi_ras.v_dwh_pubblicazione_analisi;

    /*
     * L'indice replica la semantica della business key DWH
     * e segnala eventuali duplicati nella sorgente materializzata.
     */
    CREATE UNIQUE INDEX
        tmp_dwh_pubblicazione_analisi_uq
    ON hcbi_ras.tmp_dwh_pubblicazione_analisi (
        ds_anno_pubblicazione,
        cd_codice_analisi,
        cd_articolo,
        cd_versione,
        nr_riga
    ) NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dwh_pubblicazione_analisi;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dwh_pubblicazione_analisi;

    UPDATE hcbi_ras.dwh_pubblicazione_analisi AS dwh
       SET nr_quantita = src.nr_quantita,
           id_sorgente_pubblicazione_analisi =
               src.id_sorgente_pubblicazione_analisi,
           id_sorgente_categoria = src.id_sorgente_categoria,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dwh_pubblicazione_analisi AS src
     WHERE
		   dwh.ds_anno_pubblicazione = src.ds_anno_pubblicazione
	   AND dwh.cd_codice_analisi = src.cd_codice_analisi
	   AND dwh.cd_articolo = src.cd_articolo
	   AND dwh.cd_versione = src.cd_versione
	   AND dwh.nr_riga = src.nr_riga
       AND (
              dwh.nr_quantita IS DISTINCT FROM src.nr_quantita
           OR dwh.id_sorgente_pubblicazione_analisi IS DISTINCT FROM
                  src.id_sorgente_pubblicazione_analisi
           OR dwh.id_sorgente_categoria IS DISTINCT FROM
                  src.id_sorgente_categoria
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_pubblicazione_analisi (
        ds_anno_pubblicazione,
        cd_codice_analisi,
        nr_quantita,
        cd_articolo,
        cd_versione,
        id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria,
        nr_riga,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.ds_anno_pubblicazione,
        src.cd_codice_analisi,
        src.nr_quantita,
        src.cd_articolo,
        src.cd_versione,
        src.id_sorgente_pubblicazione_analisi,
        src.id_sorgente_categoria,
        src.nr_riga,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dwh_pubblicazione_analisi AS src
    ON CONFLICT (
        ds_anno_pubblicazione,
        cd_codice_analisi,
        cd_articolo,
        cd_versione,
        nr_riga
    )
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS
        hcbi_ras.tmp_dwh_pubblicazione_analisi;

    p_result := 1;

    RAISE NOTICE
        'Fine PKG_DWH_PUBBLICAZIONE_ANALISI: selected=%, inserted=%, updated=%',
        v_selected,
        v_inserted,
        v_updated;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;

        p_result := -1;

        /* Cleanup best effort: non deve sostituire l'errore originario. */
        BEGIN
            DROP TABLE IF EXISTS
                hcbi_ras.tmp_dwh_pubblicazione_analisi;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante la pulizia della tabella di lavoro: '
                    'SQLSTATE=%, errore=%',
                    SQLSTATE,
                    SQLERRM;
        END;

        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
                CASE
                    WHEN nullif(v_sql_detail, '') IS NOT NULL
                        THEN 'DETAIL=' || left(v_sql_detail, 1000)
                END,
                CASE
                    WHEN nullif(v_sql_hint, '') IS NOT NULL
                        THEN 'HINT=' || left(v_sql_hint, 500)
                END,
                CASE
                    WHEN nullif(v_sql_context, '') IS NOT NULL
                        THEN 'CONTEXT=' || left(v_sql_context, 800)
                END
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
                        'Errore durante la registrazione del log di errore: '
                        'SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dwh_pubblicazione_analisi_prc_main. '
            'SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_main(bigint, bigint, bigint, character varying)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_main(bigint, bigint, bigint, character varying) TO PUBLIC;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_main(bigint, bigint, bigint, character varying) TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_main(bigint, bigint, bigint, character varying) TO hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_main(bigint, bigint, bigint, character varying)
    IS 'Materializza la sorgente in una tabella di lavoro persistente nello schema hcbi_ras, valida l''unicita della business key, aggiorna i record DWH esistenti, inserisce i nuovi e rimuove la tabella di lavoro anche in caso di errore.';


/* =====================================================================
   PROCEDURA DWH FINALIZE
   ===================================================================== */

-- PROCEDURE: hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_finalize(bigint, bigint, bigint, character varying)

-- DROP PROCEDURE IF EXISTS hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_finalize(bigint, bigint, bigint, character varying);

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_finalize(
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
    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
BEGIN
    p_result := -1;

    RAISE NOTICE
        'Finalizzazione PKG_DWH_PUBBLICAZIONE_ANALISI per lo step %',
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

    ANALYZE hcbi_ras.dwh_pubblicazione_analisi;

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

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate    = RETURNED_SQLSTATE,
            v_sqlerrm     = MESSAGE_TEXT,
            v_sql_detail  = PG_EXCEPTION_DETAIL,
            v_sql_hint    = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;
        p_result := -1;
        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE='  || left(coalesce(v_sqlerrm, ''), 1500),
                CASE WHEN nullif(v_sql_detail, '') IS NOT NULL
                    THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
                CASE WHEN nullif(v_sql_hint, '') IS NOT NULL
                    THEN 'HINT=' || left(v_sql_hint, 500) END,
                CASE WHEN nullif(v_sql_context, '') IS NOT NULL
                    THEN 'CONTEXT=' || left(v_sql_context, 800) END
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
                        'Errore durante la registrazione del log di errore: '
                        'SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;
        -- Compatibilita' con il contratto corrente:
        -- l'errore non viene rilanciato; il chiamante deve verificare p_result.
        RAISE WARNING
            'Errore in pkg_dwh_pubblicazione_analisi_prc_finalize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;
ALTER PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_finalize(bigint, bigint, bigint, character varying)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_finalize(bigint, bigint, bigint, character varying) TO PUBLIC;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_finalize(bigint, bigint, bigint, character varying) TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_finalize(bigint, bigint, bigint, character varying) TO hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_analisi_prc_finalize(bigint, bigint, bigint, character varying)
    IS 'Finalizza il flusso DWH_PUBBLICAZIONE_ANALISI e aggiorna le statistiche.';


