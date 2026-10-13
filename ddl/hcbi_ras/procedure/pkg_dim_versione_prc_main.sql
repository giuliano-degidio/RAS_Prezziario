CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_versione_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
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
        GROUP BY id_sorgente_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DWH_ANAG_PROVINCIA non deterministica',
            DETAIL='Esistono piu record con lo stesso id_sorgente_provincia.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_provincia
        WHERE cd_provincia IS NOT NULL
        GROUP BY cd_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_PROVINCIA non deterministica',
            DETAIL='Esistono piu record con lo stesso cd_provincia.';
    END IF;

    SELECT COUNT(*)
    INTO v_codice_versione_assente
    FROM hcbi_ras.dwh_anag_versione AS src
    WHERE src.cd_versione IS NULL;
    IF v_codice_versione_assente > 0 THEN
        RAISE WARNING
            'DIM_VERSIONE: % record con cd_versione NULL ricondotti al tappo id_anag_versione=0.',
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
        ON dwh_pr.id_sorgente_provincia = src.id_sorgente_provincia
    LEFT JOIN hcbi_ras.dim_provincia AS dpr
        ON dpr.cd_provincia = dwh_pr.cd_provincia
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
$procedure$
