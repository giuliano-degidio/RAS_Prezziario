/* =====================================================================
   DIM_VERSIONE - DDL E PROCEDURE DI CARICAMENTO
   Target: PostgreSQL 15.9 / 17
   Schema: hcbi_ras

   Sorgente:
       hcbi_ras.dwh_anag_versione

   Destinazione:
       hcbi_ras.dim_versione

   Grain:
       una riga per ID_ANAG_VERSIONE.

   Chiave primaria:
       id_anag_versione

   Business key dimensionale:
       id_periodo_pubblicazione, cd_versione, id_anag_provincia

   Lookup periodo:
       dwh_anag_versione.ds_anno_pubblicazione = dim_periodo.ds_anno
       Risultato: dim_periodo.id_periodo -> id_periodo_pubblicazione

   Lookup provincia:
       1. dwh_anag_versione.ds_anno_pubblicazione, addendum,
          id_sorgente_provincia
              = dwh_anag_provincia.anno, addendum,
                id_sorgente_provincia
       2. dwh_anag_provincia.anno, addendum, cd_provincia
              = dim_provincia.anno, addendum, cd_provincia
       Risultato: dim_provincia.id_anag_provincia

   Regole dei record tecnici:
       - cd_versione NULL: record sorgente escluso dal caricamento;
         nei flussi dipendenti il riferimento tecnico previsto e'
         id_anag_versione = 0 con descrizione 'NON DISPONIBILE';
       - FK valorizzata ma non trovata: FK = -1;
       - lookup risolta: chiave effettiva.

   Campi DWH esclusi dalla DIM:
       ds_anno_pubblicazione
       id_sorgente_provincia
       fl_scostamento_1_visibile
       fl_scostamento_2_visibile
       fl_scostamento_3_visibile
       fl_scostamento_4_visibile
       fl_scostamento_5_visibile
       ds_llpp_homepage_title
       ds_llpp_homepage_description
       id_sorgente_versione
       fl_mostra_annotazioni
       fl_mostra_struttura_analisi

   Strategia:
       SCD Type 1; UPDATE dei record variati; INSERT dei nuovi;
       nessuna cancellazione per assenza dalla sorgente.

   Prerequisiti:
       - record tecnici 0 e -1 in dim_periodo;
       - record tecnici 0 e -1 in dim_provincia;
       - dim_periodo.ds_anno univoco;
       - dwh_anag_provincia univoca su
         (anno, addendum, id_sorgente_provincia);
       - dim_provincia univoca su
         (anno, addendum, cd_provincia);
       - nessuna esecuzione concorrente della PRC_MAIN, poiche' la tabella
         di lavoro usa un nome fisso.
   ===================================================================== */

/* =====================================================================
   TABELLA DIMENSIONALE
   ===================================================================== */
   
CREATE TABLE IF NOT EXISTS hcbi_ras.dim_versione
(
    id_anag_versione          BIGINT NOT NULL,
    id_periodo_pubblicazione  INTEGER NOT NULL,
    cd_versione               SMALLINT NOT NULL,
    ds_versione               TEXT,
    id_anag_provincia         BIGINT NOT NULL,
    nr_spese_generali         NUMERIC(10,5) NOT NULL,
    nr_utile_impresa          NUMERIC(10,5) NOT NULL,
    nr_di_cui_analisi         NUMERIC(10,5) NOT NULL,
    fl_pubblicazione_regionale SMALLINT NOT NULL,
    fl_is_errata_corrige      SMALLINT NOT NULL,
    fl_mostra_cam             SMALLINT NOT NULL,
    dt_creation               TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by            VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update                 TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_update_by              VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,

    CONSTRAINT pk_dim_versione
        PRIMARY KEY (id_anag_versione),

    CONSTRAINT uq_dim_versione
        UNIQUE NULLS NOT DISTINCT
        (id_periodo_pubblicazione, cd_versione, id_anag_provincia),

    CONSTRAINT fk_dim_versione_periodo
        FOREIGN KEY (id_periodo_pubblicazione)
        REFERENCES hcbi_ras.dim_periodo (id_periodo)
        ON UPDATE RESTRICT ON DELETE RESTRICT,

    CONSTRAINT fk_dim_versione_provincia
        FOREIGN KEY (id_anag_provincia)
        REFERENCES hcbi_ras.dim_provincia (id_anag_provincia)
        ON UPDATE RESTRICT ON DELETE RESTRICT
)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dim_versione OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.dim_versione FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.dim_versione TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.dim_versione TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dim_versione IS
    'Dimensione versioni alimentata da HCBI_RAS.DWH_ANAG_VERSIONE.';
COMMENT ON COLUMN hcbi_ras.dim_versione.id_anag_versione IS
    'Chiave primaria mantenuta dalla chiave DWH sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_versione.id_periodo_pubblicazione IS
    'FK verso DIM_PERIODO ottenuta tramite anno di pubblicazione; -1 se non risolta.';
COMMENT ON COLUMN hcbi_ras.dim_versione.cd_versione IS
    'Codice della versione.';
COMMENT ON COLUMN hcbi_ras.dim_versione.ds_versione IS
    'Descrizione della versione.';
COMMENT ON COLUMN hcbi_ras.dim_versione.id_anag_provincia IS
    'FK verso DIM_PROVINCIA ottenuta tramite DWH_ANAG_PROVINCIA: anno, addendum e id_sorgente_provincia, con successivo match su anno, addendum e cd_provincia; -1 se non risolta.';
COMMENT ON CONSTRAINT pk_dim_versione ON hcbi_ras.dim_versione IS
    'Chiave primaria: id_anag_versione.';
COMMENT ON CONSTRAINT uq_dim_versione ON hcbi_ras.dim_versione IS
    'Business key: id_periodo_pubblicazione, cd_versione, id_anag_provincia.';

/* =====================================================================
   RECORD TECNICI DIM_VERSIONE
   ===================================================================== */
INSERT INTO hcbi_ras.dim_versione
(
    id_anag_versione, id_periodo_pubblicazione, cd_versione,
    ds_versione, id_anag_provincia,
    nr_spese_generali, nr_utile_impresa, nr_di_cui_analisi,
    fl_pubblicazione_regionale, fl_is_errata_corrige, fl_mostra_cam,
    dt_creation, tx_creation_by, dt_update, tx_update_by
)
VALUES
(
    0, 0, 0, 'NON DISPONIBILE', 0,
    0::NUMERIC(10,5), 0::NUMERIC(10,5), 0::NUMERIC(10,5),
    0::SMALLINT, 0::SMALLINT, 0::SMALLINT,
    clock_timestamp(), CURRENT_USER, clock_timestamp(), CURRENT_USER
),
(
    -1, -1, -1, 'ANAGRAFICA ASSENTE', -1,
    0::NUMERIC(10,5), 0::NUMERIC(10,5), 0::NUMERIC(10,5),
    0::SMALLINT, 0::SMALLINT, 0::SMALLINT,
    clock_timestamp(), CURRENT_USER, clock_timestamp(), CURRENT_USER
)
ON CONFLICT ON CONSTRAINT pk_dim_versione DO NOTHING;

/* =====================================================================
   PROCEDURA INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_versione_prc_initialize(
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
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::TIMESTAMP,
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name)
    INTO v_id_log;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS',
        clock_timestamp()::TIMESTAMP, p_ds_step_name);

    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE, v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL, v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    v_log_error := LEFT(CONCAT_WS(E'\n',
        'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500),
        CASE WHEN NULLIF(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||LEFT(v_sql_detail,1000) END,
        CASE WHEN NULLIF(v_sql_hint,'') IS NOT NULL THEN 'HINT='||LEFT(v_sql_hint,500) END,
        CASE WHEN NULLIF(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||LEFT(v_sql_context,800) END),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',v_log_error,
                clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
        END;
    END IF;
    RAISE WARNING
        'Errore in pkg_dim_versione_prc_initialize. SQLSTATE=%, errore=%',
        v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_versione_prc_initialize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_versione_prc_initialize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;

/* =====================================================================
   PROCEDURA MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_versione_prc_main(
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
    v_selected BIGINT := 0;
    v_inserted BIGINT := 0;
    v_updated BIGINT := 0;
    v_deleted BIGINT := 0;
    v_rec_errors BIGINT := 0;
    v_matched BIGINT := 0;
    v_lookup_periodo_ko BIGINT := 0;
    v_lookup_provincia_ko BIGINT := 0;
    v_codice_versione_assente BIGINT := 0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::TIMESTAMP,
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name)
    INTO v_id_log;

    /* Record tecnici 0 e -1 richiesti dalle FK. */
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo=0)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
            MESSAGE='Record tecnici 0 e/o -1 non presenti in DIM_PERIODO';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia=0)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
            MESSAGE='Record tecnici 0 e/o -1 non presenti in DIM_PROVINCIA';
    END IF;
    /* Le lookup devono essere deterministiche. */
    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_periodo
        WHERE ds_anno IS NOT NULL
        GROUP BY ds_anno
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_PERIODO non deterministica',
            DETAIL='Esistono piu record con lo stesso ds_anno.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dwh_anag_provincia
        WHERE id_sorgente_provincia IS NOT NULL
        GROUP BY anno, addendum, id_sorgente_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DWH_ANAG_PROVINCIA non deterministica',
            DETAIL='Esistono piu record con gli stessi anno, addendum e id_sorgente_provincia.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_provincia
        WHERE cd_provincia IS NOT NULL
        GROUP BY anno, addendum, cd_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_PROVINCIA non deterministica',
            DETAIL='Esistono piu record con gli stessi anno, addendum e cd_provincia.';
    END IF;

    /* Il contesto della Provincia e' obbligatorio quando la FK sorgente e' valorizzata. */
    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dwh_anag_versione
        WHERE id_sorgente_provincia IS NOT NULL
          AND ds_anno_pubblicazione IS NULL
    ) THEN
        RAISE EXCEPTION USING ERRCODE='23502',
            MESSAGE='DS_ANNO_PUBBLICAZIONE nullo in DWH_ANAG_VERSIONE',
            DETAIL='DS_ANNO_PUBBLICAZIONE e necessario per contestualizzare la lookup Provincia.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dwh_anag_versione
        WHERE id_sorgente_provincia IS NOT NULL
          AND addendum IS NULL
    ) THEN
        RAISE EXCEPTION USING ERRCODE='23502',
            MESSAGE='ADDENDUM nullo in DWH_ANAG_VERSIONE',
            DETAIL='ADDENDUM e necessario per contestualizzare la lookup Provincia.';
    END IF;

    SELECT COUNT(*)
    INTO v_codice_versione_assente
    FROM hcbi_ras.dwh_anag_versione AS src
    WHERE src.cd_versione IS NULL;
    IF v_codice_versione_assente > 0 THEN
        RAISE WARNING
            'DIM_VERSIONE: % record con cd_versione NULL esclusi dal caricamento; il tappo tecnico id_anag_versione=0 resta disponibile per i flussi dipendenti.',
            v_codice_versione_assente;
    END IF;
    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_versione;
    CREATE TABLE hcbi_ras.tmp_dim_versione AS
    SELECT
        src.id_anag_versione,
        COALESCE(dp.id_periodo,(-1)::INTEGER)
            AS id_periodo_pubblicazione,
        src.cd_versione,
        src.ds_versione,
        COALESCE(dpr.id_anag_provincia,(-1)::BIGINT)
            AS id_anag_provincia,
        src.nr_spese_generali,
        src.nr_utile_impresa,
        src.nr_di_cui_analisi,
        src.fl_pubblicazione_regionale,
        src.fl_is_errata_corrige,
        src.fl_mostra_cam,
        (dp.id_periodo IS NULL) AS fl_lookup_periodo_ko,
        (dpr.id_anag_provincia IS NULL) AS fl_lookup_provincia_ko
    FROM hcbi_ras.dwh_anag_versione AS src
    LEFT JOIN hcbi_ras.dim_periodo AS dp
        ON dp.ds_anno = src.ds_anno_pubblicazione
    LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwh_pr
        ON dwh_pr.anno = src.ds_anno_pubblicazione::INTEGER
       AND dwh_pr.addendum = src.addendum::INTEGER
       AND dwh_pr.id_sorgente_provincia = src.id_sorgente_provincia
    LEFT JOIN hcbi_ras.dim_provincia AS dpr
      ON dpr.anno = dwh_pr.anno
     AND dpr.addendum = dwh_pr.addendum
     AND dpr.cd_provincia = dwh_pr.cd_provincia
    WHERE src.cd_versione IS NOT NULL;

    /* Controlli preventivi sulla PK e sulla business key trasformata. */
    CREATE UNIQUE INDEX tmp_dim_versione_pk
        ON hcbi_ras.tmp_dim_versione(id_anag_versione)
        NULLS NOT DISTINCT;

    CREATE UNIQUE INDEX tmp_dim_versione_bk
        ON hcbi_ras.tmp_dim_versione
        (id_periodo_pubblicazione,cd_versione,id_anag_provincia)
        NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_versione;

    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE fl_lookup_periodo_ko),
        COUNT(*) FILTER (WHERE fl_lookup_provincia_ko)
    INTO
        v_selected,
        v_lookup_periodo_ko,
        v_lookup_provincia_ko
    FROM hcbi_ras.tmp_dim_versione;

    /* Ogni mancata decodifica viene conteggiata separatamente. */
    v_rec_errors := v_codice_versione_assente + v_lookup_periodo_ko + v_lookup_provincia_ko;

    IF v_lookup_periodo_ko > 0 THEN
        RAISE WARNING
            'DIM_VERSIONE: % lookup periodo non risolte; applicato id_periodo_pubblicazione=-1.',
            v_lookup_periodo_ko;
    END IF;

    IF v_lookup_provincia_ko > 0 THEN
        RAISE WARNING
            'DIM_VERSIONE: % lookup provincia non risolte; applicato id_anag_provincia=-1.',
            v_lookup_provincia_ko;
    END IF;

    UPDATE hcbi_ras.dim_versione AS d
       SET id_periodo_pubblicazione = src.id_periodo_pubblicazione,
           cd_versione = src.cd_versione,
           ds_versione = src.ds_versione,
           id_anag_provincia = src.id_anag_provincia,
           nr_spese_generali = src.nr_spese_generali,
           nr_utile_impresa = src.nr_utile_impresa,
           nr_di_cui_analisi = src.nr_di_cui_analisi,
           fl_pubblicazione_regionale = src.fl_pubblicazione_regionale,
           fl_is_errata_corrige = src.fl_is_errata_corrige,
           fl_mostra_cam = src.fl_mostra_cam,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_versione AS src
     WHERE d.id_anag_versione = src.id_anag_versione
       AND ROW(
            d.id_periodo_pubblicazione,
            d.cd_versione,
            d.ds_versione,
            d.id_anag_provincia,
            d.nr_spese_generali,
            d.nr_utile_impresa,
            d.nr_di_cui_analisi,
            d.fl_pubblicazione_regionale,
            d.fl_is_errata_corrige,
            d.fl_mostra_cam
       ) IS DISTINCT FROM ROW(
            src.id_periodo_pubblicazione,
            src.cd_versione,
            src.ds_versione,
            src.id_anag_provincia,
            src.nr_spese_generali,
            src.nr_utile_impresa,
            src.nr_di_cui_analisi,
            src.fl_pubblicazione_regionale,
            src.fl_is_errata_corrige,
            src.fl_mostra_cam
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_versione
    (
        id_anag_versione,
        id_periodo_pubblicazione,
        cd_versione,
        ds_versione,
        id_anag_provincia,
        nr_spese_generali,
        nr_utile_impresa,
        nr_di_cui_analisi,
        fl_pubblicazione_regionale,
        fl_is_errata_corrige,
        fl_mostra_cam,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_anag_versione,
        src.id_periodo_pubblicazione,
        src.cd_versione,
        src.ds_versione,
        src.id_anag_provincia,
        src.nr_spese_generali,
        src.nr_utile_impresa,
        src.nr_di_cui_analisi,
        src.fl_pubblicazione_regionale,
        src.fl_is_errata_corrige,
        src.fl_mostra_cam,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dim_versione AS src
    ON CONFLICT ON CONSTRAINT pk_dim_versione DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    SELECT COUNT(*)
    INTO v_matched
    FROM hcbi_ras.dim_versione AS d
    INNER JOIN hcbi_ras.tmp_dim_versione AS src
        ON src.id_anag_versione = d.id_anag_versione;

    IF v_selected <> v_matched THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE=FORMAT(
                'Riconciliazione DIM_VERSIONE non valida: applicative=%s, matched=%s',
                v_selected,v_matched),
            DETAIL='Non tutte le chiavi applicative risultano presenti nella dimensione.';
    END IF;
    IF (v_selected + v_codice_versione_assente) <>
       (SELECT COUNT(*) FROM hcbi_ras.dwh_anag_versione) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Riconciliazione sorgente DIM_VERSIONE non valida';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,(v_selected + v_codice_versione_assente),v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_versione;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;

    BEGIN
        DROP TABLE IF EXISTS hcbi_ras.tmp_dim_versione;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
    END;

    v_log_error := LEFT(CONCAT_WS(E'\n',
        'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500),
        CASE WHEN NULLIF(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||LEFT(v_sql_detail,1000) END,
        CASE WHEN NULLIF(v_sql_hint,'') IS NOT NULL THEN 'HINT='||LEFT(v_sql_hint,500) END,
        CASE WHEN NULLIF(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||LEFT(v_sql_context,800) END),4000);

    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',v_log_error,
                clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
        END;
    END IF;

    RAISE WARNING
        'Errore in pkg_dim_versione_prc_main. SQLSTATE=%, errore=%',
        v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_versione_prc_main(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_versione_prc_main(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;

/* =====================================================================
   PROCEDURA FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_versione_prc_finalize(
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
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name)
    INTO v_id_log;

    ANALYZE hcbi_ras.dim_versione;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',
        clock_timestamp()::TIMESTAMP,p_ds_step_name);

    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    v_log_error := LEFT(CONCAT_WS(E'\n',
        'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500),
        CASE WHEN NULLIF(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||LEFT(v_sql_detail,1000) END,
        CASE WHEN NULLIF(v_sql_hint,'') IS NOT NULL THEN 'HINT='||LEFT(v_sql_hint,500) END,
        CASE WHEN NULLIF(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||LEFT(v_sql_context,800) END),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',v_log_error,
                clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
        END;
    END IF;
    RAISE WARNING
        'Errore in pkg_dim_versione_prc_finalize. SQLSTATE=%, errore=%',
        v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_versione_prc_finalize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_versione_prc_finalize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_versione_prc_main(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING)
IS 'Carica DIM_VERSIONE: esclude le righe con cd_versione NULL; risolve la Provincia tramite anno, addendum e id_sorgente_provincia, quindi tramite anno, addendum e cd_provincia; FK valorizzate ma non risolte poste a -1.';
COMMENT ON PROCEDURE hcbi_ras.pkg_dim_versione_prc_finalize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING)
IS 'Finalizza DIM_VERSIONE e aggiorna le statistiche.';

/* =====================================================================
   TEST POST-DEPLOYMENT
   ===================================================================== */

/* 1. Verifica record tecnici richiesti. */
-- SELECT id_periodo FROM hcbi_ras.dim_periodo WHERE id_periodo IN (0,-1);
-- SELECT id_anag_provincia FROM hcbi_ras.dim_provincia WHERE id_anag_provincia IN (0,-1);
-- SELECT id_anag_versione,cd_versione,ds_versione
-- FROM hcbi_ras.dim_versione WHERE id_anag_versione IN (0,-1);
/* 1B. Codici versione NULL esclusi dal caricamento; tappo tecnico 0 disponibile per i flussi dipendenti. */
-- SELECT COUNT(*) FROM hcbi_ras.dwh_anag_versione WHERE cd_versione IS NULL;

/* 2. Lookup periodo non risolte. */
-- SELECT src.id_anag_versione,src.ds_anno_pubblicazione
-- FROM hcbi_ras.dwh_anag_versione src
-- LEFT JOIN hcbi_ras.dim_periodo p
--   ON p.ds_anno=src.ds_anno_pubblicazione
-- WHERE p.id_periodo IS NULL;

/* 3. Lookup provincia non risolte. */
-- SELECT
--     src.id_anag_versione,
--     src.ds_anno_pubblicazione,
--     src.addendum,
--     src.id_sorgente_provincia,
--     dwh_pr.cd_provincia,
--     CASE
--         WHEN dwh_pr.id_sorgente_provincia IS NULL
--             THEN 'Provincia non trovata nel contesto DWH_ANAG_PROVINCIA'
--         WHEN p.id_anag_provincia IS NULL
--             THEN 'Provincia non trovata nel contesto DIM_PROVINCIA'
--     END AS motivo_lookup_ko
-- FROM hcbi_ras.dwh_anag_versione AS src
-- LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwh_pr
--     ON dwh_pr.anno = src.ds_anno_pubblicazione::INTEGER
--    AND dwh_pr.addendum = src.addendum::INTEGER
--    AND dwh_pr.id_sorgente_provincia = src.id_sorgente_provincia
-- LEFT JOIN hcbi_ras.dim_provincia AS p
--     ON p.anno = dwh_pr.anno
--    AND p.addendum = dwh_pr.addendum
--    AND p.cd_provincia = dwh_pr.cd_provincia
-- WHERE src.cd_versione IS NOT NULL
--   AND p.id_anag_provincia IS NULL;

/* 3B. Determinismo della chiave operazionale di DWH_ANAG_PROVINCIA. */
-- SELECT anno, addendum, id_sorgente_provincia, COUNT(*)
-- FROM hcbi_ras.dwh_anag_provincia
-- WHERE id_sorgente_provincia IS NOT NULL
-- GROUP BY anno, addendum, id_sorgente_provincia
-- HAVING COUNT(*) > 1;

/* 3C. Determinismo della business key contestualizzata di DIM_PROVINCIA. */
-- SELECT anno, addendum, cd_provincia, COUNT(*)
-- FROM hcbi_ras.dim_provincia
-- WHERE cd_provincia IS NOT NULL
-- GROUP BY anno, addendum, cd_provincia
-- HAVING COUNT(*) > 1;

/* 4. Riconciliazione DWH-DIM. */
-- SELECT COUNT(*) AS chiavi_non_caricate
-- FROM hcbi_ras.dwh_anag_versione src
-- LEFT JOIN hcbi_ras.dim_versione d
--   ON d.id_anag_versione=src.id_anag_versione
-- WHERE d.id_anag_versione IS NULL;

/* 5. Verifica degli orfani. */
-- SELECT d.*
-- FROM hcbi_ras.dim_versione d
-- LEFT JOIN hcbi_ras.dim_periodo pe
--   ON pe.id_periodo=d.id_periodo_pubblicazione
-- LEFT JOIN hcbi_ras.dim_provincia pr
--   ON pr.id_anag_provincia=d.id_anag_provincia
-- WHERE pe.id_periodo IS NULL OR pr.id_anag_provincia IS NULL;
