/* =====================================================================
   FLUSSO ANAG_AREA_VASTA - VERSIONE UNIFORMATA

   Target tecnico:
       PostgreSQL 15.9 / 17

   Pattern tecnico:
       PUBBLICAZIONE_ANALISI definitivo

   Sorgente operazionale:
       public.aree_vaste

   Mapping:
       id   -> id_sorgente_area_vasta
       nome -> ds_nome
       anno -> anno
       addendum -> addendum

   Business key:
       anno, addendum, ds_nome

   Grain:
       una riga per anno, addendum e area vasta.

   Regola di obbligatorieta:
       anno, addendum e ds_nome sono obbligatori.
       id_sorgente_area_vasta e' facoltativo; se valorizzato deve essere
       convertibile in BIGINT.

   Vincolo operativo:
       le tabelle di lavoro hanno nome fisso; non e' ammessa
       l'esecuzione concorrente dello stesso flusso.
   ===================================================================== */

/* =====================================================================
   SEQUENCE DWH
   ===================================================================== */
CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_anag_area_vasta
    INCREMENT 1
    START 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    CACHE 1;

ALTER SEQUENCE hcbi_ras.seq_dwh_anag_area_vasta
    OWNER TO hcbi_ras;

GRANT ALL
ON SEQUENCE hcbi_ras.seq_dwh_anag_area_vasta
TO hcbi_ras;

GRANT USAGE, SELECT
ON SEQUENCE hcbi_ras.seq_dwh_anag_area_vasta
TO hcbi_utility;

/* =====================================================================
   TABELLA FRONTIERA
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_anag_area_vasta
(
    id       character varying(100),
    nome     character varying(100),
    anno     character varying(20),
    addendum character varying(20)
);

ALTER TABLE hcbi_ras.frontiera_anag_area_vasta
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.frontiera_anag_area_vasta
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.frontiera_anag_area_vasta
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.frontiera_anag_area_vasta
TO hcbi_utility;

/* =====================================================================
   TABELLA SRC_TMP
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_anag_area_vasta
(
    id       character varying(100),
    nome     character varying(100),
    anno     character varying(20),
    addendum character varying(20)
);

ALTER TABLE hcbi_ras.src_tmp_anag_area_vasta
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.src_tmp_anag_area_vasta
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.src_tmp_anag_area_vasta
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.src_tmp_anag_area_vasta
TO hcbi_utility;

/* =====================================================================
   VISTA SRC_TMP
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_anag_area_vasta AS
SELECT
    btrim(s.id::text) AS id_sorgente_area_vasta,
    btrim(s.nome::text) AS ds_nome,
    btrim(s.anno::text) AS anno,
    btrim(s.addendum::text) AS addendum
FROM hcbi_ras.src_tmp_anag_area_vasta AS s;

ALTER VIEW hcbi_ras.v_src_tmp_anag_area_vasta
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_src_tmp_anag_area_vasta
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_src_tmp_anag_area_vasta
TO hcbi_utility;

/* =====================================================================
   TABELLA STG
   Solo la business key DS_NOME e' NOT NULL.
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_area_vasta
(
    anno integer NOT NULL,
    addendum integer NOT NULL,
    id_sorgente_area_vasta bigint,
    ds_nome character varying(100) NOT NULL
);

ALTER TABLE hcbi_ras.stg_anag_area_vasta
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.stg_anag_area_vasta
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.stg_anag_area_vasta
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_area_vasta
TO hcbi_utility;

/* =====================================================================
   TABELLA STG REJECT
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_anag_area_vasta_rej
(
    anno character varying(20),
    addendum character varying(20),
    id_sorgente_area_vasta character varying(100),
    ds_nome character varying(100),
    tx_motivo_scarto character varying(4000)
);

ALTER TABLE hcbi_ras.stg_anag_area_vasta_rej
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.stg_anag_area_vasta_rej
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.stg_anag_area_vasta_rej
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.stg_anag_area_vasta_rej
TO hcbi_utility;

/* =====================================================================
   TABELLA DWH
   Solo la business key DS_NOME e' NOT NULL tra gli attributi funzionali.
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_anag_area_vasta
(
    anno integer NOT NULL,
    addendum integer NOT NULL,
    id_anag_area_vasta bigint NOT NULL
        DEFAULT nextval(
            'hcbi_ras.seq_dwh_anag_area_vasta'::regclass
        ),
    id_sorgente_area_vasta bigint,
    ds_nome character varying(100) NOT NULL,
    dt_creation timestamp without time zone
        NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by character varying(4000)
        NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone
        NOT NULL DEFAULT clock_timestamp(),
    tx_update_by character varying(4000)
        NOT NULL DEFAULT CURRENT_USER,
    dt_reciclo timestamp without time zone,
    CONSTRAINT pk_dwh_anag_area_vasta
        PRIMARY KEY (anno, addendum, id_anag_area_vasta),
    CONSTRAINT uq_dwh_anag_area_vasta
        UNIQUE NULLS NOT DISTINCT (anno, addendum, ds_nome),
    CONSTRAINT uq_dwh_anag_area_vasta_sorgente
        UNIQUE NULLS NOT DISTINCT (anno, addendum, id_sorgente_area_vasta)
);

ALTER TABLE hcbi_ras.dwh_anag_area_vasta
    OWNER TO hcbi_ras;

GRANT ALL
ON TABLE hcbi_ras.dwh_anag_area_vasta
TO hcbi_ras;

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE hcbi_ras.dwh_anag_area_vasta
TO hcbi_utility;

/* =====================================================================
   VISTA DWH
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_dwh_anag_area_vasta AS
SELECT
    s.anno,
    s.addendum,
    s.id_sorgente_area_vasta,
    s.ds_nome
FROM hcbi_ras.stg_anag_area_vasta AS s;

ALTER VIEW hcbi_ras.v_dwh_anag_area_vasta
    OWNER TO hcbi_ras;

GRANT ALL
ON hcbi_ras.v_dwh_anag_area_vasta
TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_dwh_anag_area_vasta
TO hcbi_utility;

/* =====================================================================
   FUNZIONE DI CONVERSIONE SICURA
   ===================================================================== */
CREATE OR REPLACE FUNCTION hcbi_ras.try_bigint(p_value text)
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
      OR numeric_value_out_of_range THEN
        RETURN NULL;
END;
$function$;

ALTER FUNCTION hcbi_ras.try_bigint(text)
    OWNER TO hcbi_ras;

CREATE OR REPLACE FUNCTION hcbi_ras.try_integer(p_value text)
RETURNS integer
LANGUAGE plpgsql
IMMUTABLE
PARALLEL UNSAFE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
SET search_path TO pg_catalog
AS $function$
BEGIN
    RETURN p_value::integer;
EXCEPTION
    WHEN invalid_text_representation
      OR numeric_value_out_of_range THEN
        RETURN NULL;
END;
$function$;
ALTER FUNCTION hcbi_ras.try_integer(text) OWNER TO hcbi_ras;

/* =====================================================================
   PROCEDURA STG INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_area_vasta_prc_initialize(
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

    TRUNCATE TABLE hcbi_ras.stg_anag_area_vasta;
    TRUNCATE TABLE hcbi_ras.stg_anag_area_vasta_rej;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.v_src_tmp_anag_area_vasta;

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
        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
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
                        'Errore nel logging: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_stg_anag_area_vasta_prc_initialize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_area_vasta_prc_initialize(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_area_vasta_prc_initialize(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   PROCEDURA STG MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_area_vasta_prc_main(
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_area_vasta_classificata;

    CREATE TABLE hcbi_ras.tmp_anag_area_vasta_classificata AS
    WITH src AS MATERIALIZED (
        SELECT
            f.anno AS anno_raw,
            f.addendum AS addendum_raw,
            f.id_sorgente_area_vasta AS id_sorgente_area_vasta_raw,
            f.ds_nome AS ds_nome_raw,
            nullif(btrim(f.anno), '') AS anno_txt,
            nullif(btrim(f.addendum), '') AS addendum_txt,
            nullif(btrim(f.id_sorgente_area_vasta), '')
                AS id_sorgente_area_vasta_txt,
            nullif(btrim(f.ds_nome), '') AS ds_nome_txt,
            count(*) OVER (
                PARTITION BY nullif(btrim(f.anno), ''), nullif(btrim(f.addendum), ''), nullif(btrim(f.ds_nome), '')
            ) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_anag_area_vasta AS f
    ), converted AS MATERIALIZED (
        SELECT
            s.*,
            hcbi_ras.try_integer(s.anno_txt) AS anno_cv,
            hcbi_ras.try_integer(s.addendum_txt) AS addendum_cv,
            hcbi_ras.try_bigint(s.id_sorgente_area_vasta_txt)
                AS id_sorgente_area_vasta_cv
        FROM src AS s
    )
    SELECT
        c.*,
        CASE
            WHEN c.anno_txt IS NULL THEN 'anno obbligatorio'
            WHEN c.anno_cv IS NULL THEN 'anno non convertibile in integer o fuori dominio'
            WHEN c.addendum_txt IS NULL THEN 'addendum obbligatorio'
            WHEN c.addendum_cv IS NULL THEN 'addendum non convertibile in integer o fuori dominio'
            WHEN c.ds_nome_txt IS NULL THEN
                'ds_nome obbligatorio'
            WHEN c.duplicate_count > 1 THEN
                'Chiave duplicata nella sorgente: (anno, addendum, ds_nome)'
            WHEN length(c.ds_nome_txt) > 100 THEN
                'ds_nome eccede 100 caratteri'
            WHEN c.id_sorgente_area_vasta_txt IS NOT NULL
             AND c.id_sorgente_area_vasta_cv IS NULL THEN
                'id_sorgente_area_vasta non convertibile in bigint o fuori dominio'
            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM converted AS c;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_anag_area_vasta_classificata;

    INSERT INTO hcbi_ras.stg_anag_area_vasta (
        anno, addendum, id_sorgente_area_vasta, ds_nome
    )
    SELECT
        c.anno_cv, c.addendum_cv, c.id_sorgente_area_vasta_cv, c.ds_nome_txt
    FROM hcbi_ras.tmp_anag_area_vasta_classificata AS c
    WHERE c.tx_motivo_scarto IS NULL;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_anag_area_vasta_rej (
        anno, addendum, id_sorgente_area_vasta, ds_nome,
        tx_motivo_scarto
    )
    SELECT
        c.anno_raw, c.addendum_raw, c.id_sorgente_area_vasta_raw,
        c.ds_nome_raw, c.tx_motivo_scarto
    FROM hcbi_ras.tmp_anag_area_vasta_classificata AS c
    WHERE c.tx_motivo_scarto IS NOT NULL;

    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = format(
                    'Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',
                    v_selected,
                    v_inserted,
                    v_rec_errors
                );
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_area_vasta_classificata;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_anag_area_vasta_classificata;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore nel cleanup: SQLSTATE=%, errore=%',
                    SQLSTATE,
                    SQLERRM;
        END;

        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
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
                        'Errore nel logging: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_stg_anag_area_vasta_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_area_vasta_prc_main(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_area_vasta_prc_main(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   PROCEDURA STG FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_area_vasta_prc_finalize(
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
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
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

    ANALYZE hcbi_ras.stg_anag_area_vasta;
    ANALYZE hcbi_ras.stg_anag_area_vasta_rej;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS',
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
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || coalesce(v_sqlerrm, ''),
            'DETAIL=' || coalesce(v_sql_detail, ''),
            'HINT=' || coalesce(v_sql_hint, ''),
            'CONTEXT=' || coalesce(v_sql_context, '')
        ), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore nel logging: %', SQLERRM;
            END;
        END IF;
        RAISE WARNING
            'Errore in pkg_stg_anag_area_vasta_prc_finalize: %',
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_stg_anag_area_vasta_prc_finalize(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_stg_anag_area_vasta_prc_finalize(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   PROCEDURA DWH INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_area_vasta_prc_initialize(
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
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
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

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS',
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
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || coalesce(v_sqlerrm, ''),
            'DETAIL=' || coalesce(v_sql_detail, ''),
            'HINT=' || coalesce(v_sql_hint, ''),
            'CONTEXT=' || coalesce(v_sql_context, '')
        ), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore nel logging: %', SQLERRM;
            END;
        END IF;
        RAISE WARNING
            'Errore in pkg_dwh_anag_area_vasta_prc_initialize: %',
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_area_vasta_prc_initialize(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_area_vasta_prc_initialize(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   PROCEDURA DWH MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_area_vasta_prc_main(
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_area_vasta;

    CREATE TABLE hcbi_ras.tmp_dwh_anag_area_vasta AS
    SELECT
        s.anno, s.addendum, s.id_sorgente_area_vasta, s.ds_nome
    FROM hcbi_ras.v_dwh_anag_area_vasta AS s;

    CREATE UNIQUE INDEX tmp_dwh_anag_area_vasta_uq
    ON hcbi_ras.tmp_dwh_anag_area_vasta (anno, addendum, ds_nome)
    NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dwh_anag_area_vasta;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dwh_anag_area_vasta;

    UPDATE hcbi_ras.dwh_anag_area_vasta AS dwh
       SET id_sorgente_area_vasta = src.id_sorgente_area_vasta,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dwh_anag_area_vasta AS src
     WHERE dwh.anno = src.anno
       AND dwh.addendum = src.addendum
       AND dwh.ds_nome = src.ds_nome
       AND dwh.id_sorgente_area_vasta
           IS DISTINCT FROM src.id_sorgente_area_vasta;

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_anag_area_vasta (
        anno, addendum, id_sorgente_area_vasta, ds_nome,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.anno, src.addendum, src.id_sorgente_area_vasta, src.ds_nome,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_area_vasta AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_anag_area_vasta
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_area_vasta;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_area_vasta;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore nel cleanup: SQLSTATE=%, errore=%',
                    SQLSTATE,
                    SQLERRM;
        END;

        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || coalesce(v_sqlerrm, ''),
            'DETAIL=' || coalesce(v_sql_detail, ''),
            'HINT=' || coalesce(v_sql_hint, ''),
            'CONTEXT=' || coalesce(v_sql_context, '')
        ), 4000);

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore nel logging: %', SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dwh_anag_area_vasta_prc_main: %',
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_area_vasta_prc_main(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_area_vasta_prc_main(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   PROCEDURA DWH FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_area_vasta_prc_finalize(
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
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
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

    ANALYZE hcbi_ras.dwh_anag_area_vasta;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS',
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
        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || coalesce(v_sqlerrm, ''),
            'DETAIL=' || coalesce(v_sql_detail, ''),
            'HINT=' || coalesce(v_sql_hint, ''),
            'CONTEXT=' || coalesce(v_sql_context, '')
        ), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name
                );
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Errore nel logging: %', SQLERRM;
            END;
        END IF;
        RAISE WARNING
            'Errore in pkg_dwh_anag_area_vasta_prc_finalize: %',
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dwh_anag_area_vasta_prc_finalize(
    bigint, bigint, bigint, character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dwh_anag_area_vasta_prc_finalize(
    bigint, bigint, bigint, character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

/* =====================================================================
   COMMENTI
   ===================================================================== */
COMMENT ON TABLE hcbi_ras.frontiera_anag_area_vasta
IS 'Frontiera del flusso ANAG_AREA_VASTA.';

COMMENT ON TABLE hcbi_ras.src_tmp_anag_area_vasta
IS 'Tabella temporanea sorgente del flusso ANAG_AREA_VASTA.';

COMMENT ON TABLE hcbi_ras.stg_anag_area_vasta
IS 'Staging del flusso ANAG_AREA_VASTA.';

COMMENT ON TABLE hcbi_ras.stg_anag_area_vasta_rej
IS 'Record scartati del flusso ANAG_AREA_VASTA.';

COMMENT ON TABLE hcbi_ras.dwh_anag_area_vasta
IS 'DWH del flusso ANAG_AREA_VASTA.';

COMMENT ON COLUMN hcbi_ras.stg_anag_area_vasta.id_sorgente_area_vasta
IS 'Identificativo sorgente facoltativo; se valorizzato deve essere convertibile in BIGINT.';

COMMENT ON COLUMN hcbi_ras.stg_anag_area_vasta.ds_nome
IS 'Nome dell''area vasta e business key del flusso.';

COMMENT ON CONSTRAINT uq_dwh_anag_area_vasta
ON hcbi_ras.dwh_anag_area_vasta
IS 'Business key del flusso ANAG_AREA_VASTA: anno, addendum, ds_nome.';


/* =====================================================================
   QUERY DI ESTRAZIONE OPERAZIONALE
   ===================================================================== */
-- SELECT
--     av.id::character varying(100) AS id,
--     av.nome::character varying(100) AS nome,
--     av.anno::character varying(20) AS anno,
--     av.addendum::character varying(20) AS addendum
-- FROM public.aree_vaste AS av;
