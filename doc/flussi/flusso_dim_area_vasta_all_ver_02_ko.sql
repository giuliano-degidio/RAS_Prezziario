/* =====================================================================
   DIM_AREA_VASTA - DDL E PROCEDURE DI CARICAMENTO
   Target: PostgreSQL 15.9 / 17

   Sorgente:
       hcbi_ras.dwh_anag_area_vasta

   Destinazione:
       hcbi_ras.dim_area_vasta

   Grain:
       una riga per ANNO, ADDENDUM e ID_ANAG_AREA_VASTA.

   Chiave primaria:
       anno, addendum, id_anag_area_vasta

   Business key ereditata dalla sorgente:
       anno, addendum, ds_nome

   Strategia di caricamento:
       - materializzazione della sorgente;
       - verifica preventiva dell'unicita di ANNO, ADDENDUM e ID_ANAG_AREA_VASTA;
       - UPDATE dei soli record variati;
       - INSERT dei nuovi record con ON CONFLICT;
       - conteggi separati selected/inserted/updated;
       - diagnostica completa e logging protetto;
       - ANALYZE nella FINALIZE.

   Assunzioni da validare:
       1. ID_ANAG_AREA_VASTA viene mantenuto uguale all'identificativo
          della sorgente DWH e non viene rigenerato con una sequence.
       2. DS_NOME e' candidate key nel contesto ANNO/ADDENDUM.
       2. Non e' richiesta storicizzazione SCD di tipo 2.
       2. Non sono richiesti delete fisici o logici dei record non piu'
          presenti nella sorgente.
       2. Le firme delle routine HCBI_UTILITY sono compatibili con le
          chiamate presenti nello script.
       2. Le tabelle di lavoro hanno nome fisso; non e' ammessa
          l'esecuzione concorrente della PRC_MAIN.
   ===================================================================== */

/* =====================================================================
   TABELLA DIMENSIONALE
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dim_area_vasta
(
    anno integer NOT NULL,
    addendum integer NOT NULL,
    id_anag_area_vasta bigint NOT NULL,
    id_sorgente_area_vasta bigint,
    ds_nome character varying(100)
        COLLATE pg_catalog."default" NOT NULL,
    dt_creation timestamp without time zone
        NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by character varying(4000)
        COLLATE pg_catalog."default"
        NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone
        NOT NULL DEFAULT clock_timestamp(),
    tx_update_by character varying(4000)
        COLLATE pg_catalog."default"
        NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT pk_dim_area_vasta
        PRIMARY KEY (anno, addendum, id_anag_area_vasta),
    CONSTRAINT uq_dim_area_vasta
        UNIQUE NULLS NOT DISTINCT (anno, addendum, ds_nome),
    CONSTRAINT uq_dim_area_vasta_sorgente
        UNIQUE NULLS NOT DISTINCT (anno, addendum, id_sorgente_area_vasta)
)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dim_area_vasta
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.dim_area_vasta
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.dim_area_vasta
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.dim_area_vasta
TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dim_area_vasta
IS 'Dimensione delle aree vaste alimentata da HCBI_RAS.DWH_ANAG_AREA_VASTA.';

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.anno
IS 'Anno di riferimento del record.';

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.addendum
IS 'Addendum di riferimento del record.';

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.id_anag_area_vasta
IS 'Identificativo dell''area vasta nel contesto ANNO/ADDENDUM.';

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.id_sorgente_area_vasta
IS 'Identificativo dell''area vasta nel sistema sorgente.';

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.ds_nome
IS 'Nome dell''area vasta e business key della dimensione.';

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.dt_creation
IS 'Timestamp di creazione del record nella dimensione.';

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.tx_creation_by
IS 'Processo che ha creato il record nella dimensione.';

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.dt_update
IS 'Timestamp dell''ultimo aggiornamento del record.';

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.tx_update_by
IS 'Processo che ha eseguito l''ultimo aggiornamento.';

COMMENT ON CONSTRAINT pk_dim_area_vasta
ON hcbi_ras.dim_area_vasta
IS 'Chiave primaria della dimensione: anno, addendum, id_anag_area_vasta.';

COMMENT ON CONSTRAINT uq_dim_area_vasta
ON hcbi_ras.dim_area_vasta
IS 'Business key della dimensione: anno, addendum, ds_nome.';

COMMENT ON CONSTRAINT uq_dim_area_vasta_sorgente
ON hcbi_ras.dim_area_vasta
IS 'Unicita della chiave sorgente nel contesto anno/addendum.';

/* =====================================================================
   RECORD TECNICI DIM_AREA_VASTA PER CONTESTO ANNO/ADDENDUM
   ===================================================================== */
INSERT INTO hcbi_ras.dim_area_vasta
(anno, addendum, id_anag_area_vasta, id_sorgente_area_vasta, ds_nome,
 dt_creation, tx_creation_by, dt_update, tx_update_by)
SELECT
    ctx.anno,
    ctx.addendum,
    tech.id_anag_area_vasta,
    tech.id_sorgente_area_vasta,
    tech.ds_nome,
    clock_timestamp(),
    CURRENT_USER,
    clock_timestamp(),
    CURRENT_USER
FROM (
    SELECT DISTINCT src.anno, src.addendum
    FROM hcbi_ras.dwh_anag_area_vasta AS src
) AS ctx
CROSS JOIN (
    VALUES
        (0::bigint, 0::bigint, 'NON DISPONIBILE'::character varying(100)),
        ((-1)::bigint, (-1)::bigint, 'ANAGRAFICA ASSENTE'::character varying(100))
) AS tech(id_anag_area_vasta, id_sorgente_area_vasta, ds_nome)
ON CONFLICT ON CONSTRAINT pk_dim_area_vasta DO NOTHING;

/* =====================================================================
   PROCEDURA INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_area_vasta_prc_initialize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name character varying,
    OUT p_result integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_ras, hcbi_utility
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

    /* Nessuna inizializzazione applicativa richiesta. */

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
                        'Errore durante il logging: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dim_area_vasta_prc_initialize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_area_vasta_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_area_vasta_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_area_vasta_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
)
IS 'Inizializza il caricamento DIM_AREA_VASTA e registra l''esecuzione nel log.';

/* =====================================================================
   PROCEDURA MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_area_vasta_prc_main(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name character varying,
    OUT p_result integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_ras, hcbi_utility
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

    /* Garantisce i record tecnici per ogni contesto presente a ogni esecuzione. */
    INSERT INTO hcbi_ras.dim_area_vasta
    (anno, addendum, id_anag_area_vasta, id_sorgente_area_vasta, ds_nome,
     dt_creation, tx_creation_by, dt_update, tx_update_by)
    SELECT
        ctx.anno,
        ctx.addendum,
        tech.id_anag_area_vasta,
        tech.id_sorgente_area_vasta,
        tech.ds_nome,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM (
        SELECT DISTINCT src.anno, src.addendum
        FROM hcbi_ras.dwh_anag_area_vasta AS src
    ) AS ctx
    CROSS JOIN (
        VALUES
            (0::bigint, 0::bigint, 'NON DISPONIBILE'::character varying(100)),
            ((-1)::bigint, (-1)::bigint, 'ANAGRAFICA ASSENTE'::character varying(100))
    ) AS tech(id_anag_area_vasta, id_sorgente_area_vasta, ds_nome)
    ON CONFLICT ON CONSTRAINT pk_dim_area_vasta DO NOTHING;

    /*
       La sorgente viene materializzata una sola volta, escludendo i
       campi tecnici della DWH sorgente che non fanno parte della DIM.
    */
    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_area_vasta;

    CREATE TABLE hcbi_ras.tmp_dim_area_vasta AS
    SELECT
        src.anno,
        src.addendum,
        src.id_anag_area_vasta,
        src.id_sorgente_area_vasta,
        src.ds_nome
    FROM hcbi_ras.dwh_anag_area_vasta AS src
    WHERE src.id_anag_area_vasta NOT IN (0, -1);

    /* Verifica preventiva della chiave primaria sorgente. */
    CREATE UNIQUE INDEX tmp_dim_area_vasta_pk
    ON hcbi_ras.tmp_dim_area_vasta (anno, addendum, id_anag_area_vasta)
    NULLS NOT DISTINCT;

    /* Verifica preventiva della business key sorgente. */
    CREATE UNIQUE INDEX tmp_dim_area_vasta_bk
    ON hcbi_ras.tmp_dim_area_vasta (anno, addendum, ds_nome)
    NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_area_vasta;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dim_area_vasta;

    /* Aggiorna soltanto gli attributi effettivamente variati. */
    UPDATE hcbi_ras.dim_area_vasta AS d
       SET id_sorgente_area_vasta = src.id_sorgente_area_vasta,
           ds_nome = src.ds_nome,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_area_vasta AS src
     WHERE d.anno = src.anno
       AND d.addendum = src.addendum
       AND d.id_anag_area_vasta = src.id_anag_area_vasta
       AND ROW(
            d.id_sorgente_area_vasta,
            d.ds_nome
       ) IS DISTINCT FROM ROW(
            src.id_sorgente_area_vasta,
            src.ds_nome
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_area_vasta (
        anno,
        addendum,
        id_anag_area_vasta,
        id_sorgente_area_vasta,
        ds_nome,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.anno,
        src.addendum,
        src.id_anag_area_vasta,
        src.id_sorgente_area_vasta,
        src.ds_nome,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dim_area_vasta AS src
    ON CONFLICT ON CONSTRAINT pk_dim_area_vasta
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    /*
       Riconciliazione del caricamento:
       ogni riga sorgente deve risultare gia presente oppure inserita.
       Il conteggio aggiornati e' informativo ed e' un sottoinsieme dei
       record gia presenti.
    */
    IF v_selected <> (
        SELECT count(*)
        FROM hcbi_ras.dim_area_vasta AS d
        INNER JOIN hcbi_ras.tmp_dim_area_vasta AS src
            ON src.anno = d.anno
           AND src.addendum = d.addendum
           AND src.id_anag_area_vasta = d.id_anag_area_vasta
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = format(
                    'Riconciliazione DIM_AREA_VASTA non valida: selected=%s',
                    v_selected
                ),
                DETAIL =
                    'Non tutte le chiavi (ANNO, ADDENDUM, ID_ANAG_AREA_VASTA) della sorgente risultano presenti nella dimensione.';
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_area_vasta;

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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dim_area_vasta;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante il cleanup: SQLSTATE=%, errore=%',
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
                        'Errore durante il logging: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dim_area_vasta_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_area_vasta_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_area_vasta_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_area_vasta_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
IS 'Materializza DWH_ANAG_AREA_VASTA al grain anno/addendum/area vasta, verifica PK e business key, aggiorna i record variati e inserisce i nuovi record.';

/* =====================================================================
   PROCEDURA FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_area_vasta_prc_finalize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name character varying,
    OUT p_result integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_ras, hcbi_utility
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

    ANALYZE hcbi_ras.dim_area_vasta;

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
                        'Errore durante il logging: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dim_area_vasta_prc_finalize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_area_vasta_prc_finalize(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_area_vasta_prc_finalize(
    bigint,
    bigint,
    bigint,
    character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_area_vasta_prc_finalize(
    bigint,
    bigint,
    bigint,
    character varying
)
IS 'Finalizza il caricamento DIM_AREA_VASTA e aggiorna le statistiche della tabella.';


/* =====================================================================
   TEST DI VERIFICA POST-DEPLOYMENT
   ===================================================================== */
-- 1. Duplicati sulla PK logica.
-- SELECT anno, addendum, id_anag_area_vasta, count(*)
-- FROM hcbi_ras.dim_area_vasta
-- GROUP BY anno, addendum, id_anag_area_vasta HAVING count(*) > 1;

-- 2. Duplicati sulla business key contestualizzata.
-- SELECT anno, addendum, ds_nome, count(*)
-- FROM hcbi_ras.dim_area_vasta
-- GROUP BY anno, addendum, ds_nome HAVING count(*) > 1;

-- 3. Presenza record tecnici per ogni contesto sorgente.
-- SELECT ctx.anno, ctx.addendum
-- FROM (SELECT DISTINCT anno, addendum FROM hcbi_ras.dwh_anag_area_vasta) AS ctx
-- LEFT JOIN hcbi_ras.dim_area_vasta AS d0
--   ON d0.anno=ctx.anno AND d0.addendum=ctx.addendum AND d0.id_anag_area_vasta=0
-- LEFT JOIN hcbi_ras.dim_area_vasta AS dm1
--   ON dm1.anno=ctx.anno AND dm1.addendum=ctx.addendum AND dm1.id_anag_area_vasta=-1
-- WHERE d0.id_anag_area_vasta IS NULL OR dm1.id_anag_area_vasta IS NULL;
