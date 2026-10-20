/* =====================================================================
   DIM_AREA_VASTA - DDL E PROCEDURE DI CARICAMENTO
   Target: PostgreSQL 15.9 / 17

   Sorgente:
       hcbi_ras.dwh_anag_area_vasta

   Destinazione:
       hcbi_ras.dim_area_vasta

   Grain:
       una riga per ID_ANAG_AREA_VASTA.

   Chiave primaria:
       id_anag_area_vasta

   Contesto applicativo:
       anno, cd_versione

   Business key contestualizzata:
       anno, cd_versione, ds_nome

   Chiave di lookup da DIM_PROVINCIA:
       anno, cd_versione, id_sorgente_area_vasta

   Strategia di caricamento:
       - materializzazione della sorgente;
       - verifica preventiva dell'unicita di ID_ANAG_AREA_VASTA;
       - UPDATE dei soli record variati;
       - INSERT dei nuovi record con ON CONFLICT;
       - conteggi separati selected/inserted/updated;
       - diagnostica completa e logging protetto;
       - ANALYZE nella FINALIZE.

   Assunzioni da validare:
       1. ID_ANAG_AREA_VASTA viene mantenuto uguale all'identificativo
          della sorgente DWH e non viene rigenerato con una sequence.
       2. ANNO, CD_VERSIONE e DS_NOME costituiscono la candidate key funzionale.
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
    id_anag_area_vasta bigint NOT NULL,
    anno integer NOT NULL,
    cd_versione smallint NOT NULL,
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
        PRIMARY KEY (id_anag_area_vasta),
    CONSTRAINT uq_dim_area_vasta
        UNIQUE NULLS NOT DISTINCT (anno, cd_versione, ds_nome),

    CONSTRAINT uq_dim_area_vasta_sorgente
        UNIQUE NULLS NOT DISTINCT
        (anno, cd_versione, id_sorgente_area_vasta)
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

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.id_anag_area_vasta
IS 'Chiave primaria globale della dimensione, mantenuta dalla chiave DWH sorgente.';

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.anno
IS 'Anno del contesto applicativo usato nelle lookup contestualizzate.';

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.cd_versione
IS 'Cd_versione del contesto applicativo usato nelle lookup contestualizzate.';

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.id_sorgente_area_vasta
IS 'Identificativo dell''area vasta nel sistema sorgente, univoco nel contesto anno/cd_versione.';

COMMENT ON COLUMN hcbi_ras.dim_area_vasta.ds_nome
IS 'Nome dell''area vasta; business key contestualizzata con anno e cd_versione.';

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
IS 'Chiave primaria tecnica della dimensione: id_anag_area_vasta.';

COMMENT ON CONSTRAINT uq_dim_area_vasta
ON hcbi_ras.dim_area_vasta
IS 'Business key contestualizzata della dimensione: anno, cd_versione, ds_nome.';

COMMENT ON CONSTRAINT uq_dim_area_vasta_sorgente
ON hcbi_ras.dim_area_vasta
IS 'Chiave di lookup contestualizzata: anno, cd_versione, id_sorgente_area_vasta.';

/* =====================================================================
   RECORD TECNICI DIM_AREA_VASTA
   ===================================================================== */
INSERT INTO hcbi_ras.dim_area_vasta
(id_anag_area_vasta, anno, cd_versione, id_sorgente_area_vasta, ds_nome,
 dt_creation, tx_creation_by, dt_update, tx_update_by)
VALUES
(0, 0, 0, 0, 'NON DISPONIBILE',
 clock_timestamp(), CURRENT_USER, clock_timestamp(), CURRENT_USER),
(-1, 0, 0, -1, 'ANAGRAFICA ASSENTE',
 clock_timestamp(), CURRENT_USER, clock_timestamp(), CURRENT_USER)
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

    /*
       La sorgente viene materializzata una sola volta, escludendo i
       campi tecnici della DWH sorgente che non fanno parte della DIM.
    */
    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_area_vasta;

    CREATE TABLE hcbi_ras.tmp_dim_area_vasta AS
    SELECT
        src.id_anag_area_vasta,
        src.anno,
        src.cd_versione,
        src.id_sorgente_area_vasta,
        src.ds_nome
    FROM hcbi_ras.dwh_anag_area_vasta AS src;

    /* Verifica preventiva della chiave primaria sorgente. */
    CREATE UNIQUE INDEX tmp_dim_area_vasta_pk
    ON hcbi_ras.tmp_dim_area_vasta (id_anag_area_vasta)
    NULLS NOT DISTINCT;

    /* Verifica preventiva della business key sorgente. */
    CREATE UNIQUE INDEX tmp_dim_area_vasta_bk
    ON hcbi_ras.tmp_dim_area_vasta (anno, cd_versione, ds_nome)
    NULLS NOT DISTINCT;

    /* Verifica preventiva della chiave usata dalla lookup DIM_PROVINCIA. */
    CREATE UNIQUE INDEX tmp_dim_area_vasta_sorgente_uq
    ON hcbi_ras.tmp_dim_area_vasta
        (anno, cd_versione, id_sorgente_area_vasta)
    NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_area_vasta;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dim_area_vasta;

    /* Aggiorna soltanto gli attributi effettivamente variati. */
    UPDATE hcbi_ras.dim_area_vasta AS d
       SET anno = src.anno,
           cd_versione = src.cd_versione,
           id_sorgente_area_vasta = src.id_sorgente_area_vasta,
           ds_nome = src.ds_nome,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_area_vasta AS src
     WHERE d.id_anag_area_vasta = src.id_anag_area_vasta
       AND ROW(
            d.anno,
            d.cd_versione,
            d.id_sorgente_area_vasta,
            d.ds_nome
       ) IS DISTINCT FROM ROW(
            src.anno,
            src.cd_versione,
            src.id_sorgente_area_vasta,
            src.ds_nome
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_area_vasta (
        id_anag_area_vasta,
        anno,
        cd_versione,
        id_sorgente_area_vasta,
        ds_nome,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_anag_area_vasta,
        src.anno,
        src.cd_versione,
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
            ON src.id_anag_area_vasta = d.id_anag_area_vasta
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = format(
                    'Riconciliazione DIM_AREA_VASTA non valida: selected=%s',
                    v_selected
                ),
                DETAIL =
                    'Non tutte le chiavi ID_ANAG_AREA_VASTA della sorgente risultano presenti nella dimensione.';
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
IS 'Materializza DWH_ANAG_AREA_VASTA, verifica PK globale, business key e chiave sorgente contestualizzate, aggiorna i record variati e inserisce i nuovi record.';

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
/* 1. Univocita della PK globale. Atteso: zero righe. */
-- SELECT id_anag_area_vasta, count(*)
-- FROM hcbi_ras.dim_area_vasta
-- GROUP BY id_anag_area_vasta
-- HAVING count(*) > 1;

/* 2. Univocita della business key contestualizzata. Atteso: zero righe. */
-- SELECT anno, cd_versione, ds_nome, count(*)
-- FROM hcbi_ras.dim_area_vasta
-- GROUP BY anno, cd_versione, ds_nome
-- HAVING count(*) > 1;

/* 3. Univocita della chiave usata da DIM_PROVINCIA. Atteso: zero righe. */
-- SELECT anno, cd_versione, id_sorgente_area_vasta, count(*)
-- FROM hcbi_ras.dim_area_vasta
-- WHERE id_sorgente_area_vasta IS NOT NULL
-- GROUP BY anno, cd_versione, id_sorgente_area_vasta
-- HAVING count(*) > 1;

/* 4. Presenza dei record tecnici globali. Atteso: due righe. */
-- SELECT id_anag_area_vasta, anno, cd_versione, id_sorgente_area_vasta, ds_nome
-- FROM hcbi_ras.dim_area_vasta
-- WHERE id_anag_area_vasta IN (0, -1)
-- ORDER BY id_anag_area_vasta;
