CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pubblicazione_analisi_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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
    v_errors BIGINT := 0;
    v_duplicate_rows BIGINT := 0;
    v_sqlstate TEXT;
    v_sqlerrm TEXT;
    v_sql_detail TEXT;
    v_sql_hint TEXT;
    v_sql_context TEXT;
    v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;

    /* Diagnostica puntuale dei membri tecnici necessari. */
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
          MESSAGE='Record tecnico -1 mancante in HCBI_RAS.DIM_PERIODO';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_articolo WHERE id_anag_articolo=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
          MESSAGE='Record tecnico -1 mancante in HCBI_RAS.DIM_ARTICOLO';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
          MESSAGE='Record tecnico -1 mancante in HCBI_RAS.DIM_VERSIONE';
    END IF;

    /* Determinismo periodo. */
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_periodo
        WHERE ds_anno IS NOT NULL
        GROUP BY ds_anno HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Lookup non deterministica: HCBI_RAS.DIM_PERIODO.DS_ANNO';
    END IF;

    /* La provincia dell'analisi deve essere derivabile in modo univoco
       dalla pubblicazione dell'articolo analizzato. */
    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dwh_pubblicazione_articoli
        GROUP BY ds_anno_pubblicazione,
                 btrim(cd_codice_completo::TEXT),
                 btrim(cd_versione::TEXT)
        HAVING count(DISTINCT id_sorgente_provincia)>1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Lookup provincia non deterministica da DWH_PUBBLICAZIONE_ARTICOLI',
          DETAIL='La stessa combinazione anno, codice analisi completo e versione appartiene a piu province.',
          HINT='Eseguire il test T04 e verificare la business key anno, codice completo e versione.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_versione
        GROUP BY id_periodo_pubblicazione,cd_versione,id_anag_provincia
        HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Lookup non deterministica: HCBI_RAS.DIM_VERSIONE business key';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_articolo
        GROUP BY id_periodo_pubblicazione,cd_articolo,
                 id_anag_versione,id_anag_provincia
        HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Lookup non deterministica: HCBI_RAS.DIM_ARTICOLO business key';
    END IF;

    DROP TABLE IF EXISTS hcbi_ras.tmp_fct_pubblicazione_analisi_src;
    CREATE TABLE hcbi_ras.tmp_fct_pubblicazione_analisi_src AS
    SELECT
        id_pubblicazione_analisi,
        id_periodo_pubblicazione,
        id_anag_articolo,
        id_anag_versione,
        cd_codice_analisi,
        nr_quantita,
        id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria,
        nr_riga,
        tx_motivo_lookup
    FROM hcbi_ras.v_fct_pubblicazione_analisi_src;

    CREATE UNIQUE INDEX tmp_fct_pubblicazione_analisi_pk
      ON hcbi_ras.tmp_fct_pubblicazione_analisi_src(id_pubblicazione_analisi);
    ANALYZE hcbi_ras.tmp_fct_pubblicazione_analisi_src;

    SELECT count(*) INTO v_selected
    FROM hcbi_ras.dwh_pubblicazione_analisi;

    SELECT count(*) INTO v_duplicate_rows
    FROM (
        SELECT id_pubblicazione_analisi
        FROM hcbi_ras.tmp_fct_pubblicazione_analisi_src
        GROUP BY id_pubblicazione_analisi
        HAVING count(*)>1
    ) AS d;
    IF v_duplicate_rows>0 THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE=format('Lookup non univoche per %s record PUBBLICAZIONE_ANALISI',v_duplicate_rows);
    END IF;

    IF v_selected<>(SELECT count(*) FROM hcbi_ras.tmp_fct_pubblicazione_analisi_src) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='La vista di lookup ha alterato la cardinalita di DWH_PUBBLICAZIONE_ANALISI';
    END IF;

    SELECT count(*) INTO v_errors
    FROM hcbi_ras.tmp_fct_pubblicazione_analisi_src
    WHERE tx_motivo_lookup IS NOT NULL;

    SELECT count(*) INTO v_inserted
    FROM hcbi_ras.tmp_fct_pubblicazione_analisi_src AS src
    LEFT JOIN hcbi_ras.fct_pubblicazione_analisi AS f
      ON f.id_pubblicazione_analisi=src.id_pubblicazione_analisi
    WHERE f.id_pubblicazione_analisi IS NULL;

    SELECT count(*) INTO v_updated
    FROM hcbi_ras.tmp_fct_pubblicazione_analisi_src AS src
    JOIN hcbi_ras.fct_pubblicazione_analisi AS f
      ON f.id_pubblicazione_analisi=src.id_pubblicazione_analisi
    WHERE ROW(
        f.id_periodo_pubblicazione,
        f.id_anag_articolo,
        f.id_anag_versione,
        f.cd_codice_analisi,
        f.nr_quantita,
        f.id_sorgente_pubblicazione_analisi,
        f.id_sorgente_categoria,
        f.nr_riga
    ) IS DISTINCT FROM ROW(
        src.id_periodo_pubblicazione,
        src.id_anag_articolo,
        src.id_anag_versione,
        src.cd_codice_analisi,
        src.nr_quantita,
        src.id_sorgente_pubblicazione_analisi,
        src.id_sorgente_categoria,
        src.nr_riga
    );

    INSERT INTO hcbi_ras.fct_pubblicazione_analisi AS f
    (
        id_pubblicazione_analisi,
        id_periodo_pubblicazione,
        id_anag_articolo,
        id_anag_versione,
        cd_codice_analisi,
        nr_quantita,
        id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria,
        nr_riga,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_pubblicazione_analisi,
        src.id_periodo_pubblicazione,
        src.id_anag_articolo,
        src.id_anag_versione,
        src.cd_codice_analisi,
        src.nr_quantita,
        src.id_sorgente_pubblicazione_analisi,
        src.id_sorgente_categoria,
        src.nr_riga,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_fct_pubblicazione_analisi_src AS src
    ON CONFLICT ON CONSTRAINT pk_fct_pubblicazione_analisi
    DO UPDATE SET
        id_periodo_pubblicazione=EXCLUDED.id_periodo_pubblicazione,
        id_anag_articolo=EXCLUDED.id_anag_articolo,
        id_anag_versione=EXCLUDED.id_anag_versione,
        cd_codice_analisi=EXCLUDED.cd_codice_analisi,
        nr_quantita=EXCLUDED.nr_quantita,
        id_sorgente_pubblicazione_analisi=EXCLUDED.id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria=EXCLUDED.id_sorgente_categoria,
        nr_riga=EXCLUDED.nr_riga,
        dt_update=clock_timestamp(),
        tx_update_by=p_ds_step_name
    WHERE ROW(
        f.id_periodo_pubblicazione,
        f.id_anag_articolo,
        f.id_anag_versione,
        f.cd_codice_analisi,
        f.nr_quantita,
        f.id_sorgente_pubblicazione_analisi,
        f.id_sorgente_categoria,
        f.nr_riga
    ) IS DISTINCT FROM ROW(
        EXCLUDED.id_periodo_pubblicazione,
        EXCLUDED.id_anag_articolo,
        EXCLUDED.id_anag_versione,
        EXCLUDED.cd_codice_analisi,
        EXCLUDED.nr_quantita,
        EXCLUDED.id_sorgente_pubblicazione_analisi,
        EXCLUDED.id_sorgente_categoria,
        EXCLUDED.nr_riga
    );

    IF v_selected<>(
        SELECT count(*)
        FROM hcbi_ras.fct_pubblicazione_analisi AS f
        JOIN hcbi_ras.tmp_fct_pubblicazione_analisi_src AS src
          ON src.id_pubblicazione_analisi=f.id_pubblicazione_analisi
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Riconciliazione FCT_PUBBLICAZIONE_ANALISI non valida';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);

    DROP TABLE hcbi_ras.tmp_fct_pubblicazione_analisi_src;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,
        v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,
        v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    BEGIN
        DROP TABLE IF EXISTS hcbi_ras.tmp_fct_pubblicazione_analisi_src;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Errore cleanup FCT_PUBBLICAZIONE_ANALISI: %',SQLERRM;
    END;
    v_log_error := left(concat_ws(E'\n',
        'SQLSTATE='||coalesce(v_sqlstate,''),
        'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),
        CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,
        CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,
        CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END
    ),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging MAIN FCT_PUBBLICAZIONE_ANALISI: %',SQLERRM;
        END;
    END IF;
    RAISE WARNING 'Errore MAIN FCT_PUBBLICAZIONE_ANALISI: SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$procedure$
