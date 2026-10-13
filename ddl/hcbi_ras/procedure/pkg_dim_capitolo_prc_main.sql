CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_capitolo_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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
    v_lookup_provincia_ko BIGINT := 0;
    v_lookup_periodo_ko BIGINT := 0;
    v_lookup_versione_ko BIGINT := 0;
    v_codice_capitolo_assente BIGINT := 0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,
        p_ds_step_name)
    INTO v_id_log;

    /* Prerequisiti tecnici 0 e -1. */
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia=0)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
            MESSAGE='Record tecnici 0 e/o -1 non presenti in DIM_PROVINCIA';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo=0)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
            MESSAGE='Record tecnici 0 e/o -1 non presenti in DIM_PERIODO';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione=0)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
            MESSAGE='Record tecnici 0 e/o -1 non presenti in DIM_VERSIONE';
    END IF;

    /* Determinismo delle lookup. */
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_provincia
        WHERE id_sorgente_provincia IS NOT NULL
        GROUP BY id_sorgente_provincia HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DWH_ANAG_PROVINCIA non deterministica';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_provincia
        WHERE cd_provincia IS NOT NULL
        GROUP BY cd_provincia HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_PROVINCIA non deterministica';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_periodo
        WHERE ds_anno IS NOT NULL
        GROUP BY ds_anno HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_PERIODO non deterministica';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_versione
        GROUP BY id_periodo_pubblicazione,cd_versione,id_anag_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_VERSIONE non deterministica';
    END IF;

    SELECT COUNT(*)
    INTO v_codice_capitolo_assente
    FROM hcbi_ras.dwh_anag_capitolo AS src
    WHERE NULLIF(
              BTRIM(REGEXP_REPLACE(src.cd_capitolo::TEXT, '\.$', '')),
              ''
          ) IS NULL;

    IF v_codice_capitolo_assente > 0 THEN
        RAISE WARNING
            'DIM_CAPITOLO: % record con cd_capitolo NULL o vuoto ricondotti al tappo id_anag_capitolo=0.',
            v_codice_capitolo_assente;
    END IF;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_capitolo;

    CREATE TABLE hcbi_ras.tmp_dim_capitolo AS
    WITH lookup_base AS MATERIALIZED
    (
        SELECT
            src.id_anag_capitolo,
            src.ds_anno,
            src.cd_versione,
            REGEXP_REPLACE(src.cd_capitolo::TEXT, '\.$', '')::VARCHAR(60)
                AS cd_capitolo,
            src.ds_capitolo,
            src.id_sorgente_provincia,
            dp.id_anag_provincia AS id_anag_provincia_lookup,
            dper.id_periodo AS id_periodo_lookup
        FROM hcbi_ras.dwh_anag_capitolo AS src
        LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwh_pr
            ON dwh_pr.id_sorgente_provincia=src.id_sorgente_provincia
        LEFT JOIN hcbi_ras.dim_provincia AS dp
            ON dp.cd_provincia=dwh_pr.cd_provincia
        LEFT JOIN hcbi_ras.dim_periodo AS dper
            ON dper.ds_anno=src.ds_anno
        WHERE NULLIF(
                  BTRIM(REGEXP_REPLACE(src.cd_capitolo::TEXT, '\.$', '')),
                  ''
              ) IS NOT NULL
    )
    SELECT
        lb.id_anag_capitolo,
        lb.cd_capitolo,
        lb.ds_capitolo,
        COALESCE(lb.id_anag_provincia_lookup,(-1)::BIGINT) AS id_anag_provincia,
        COALESCE(lb.id_periodo_lookup,(-1)::INTEGER) AS id_periodo_pubblicazione,
        COALESCE(dv.id_anag_versione,(-1)::BIGINT) AS id_anag_versione,
        (lb.id_anag_provincia_lookup IS NULL) AS fl_lookup_provincia_ko,
        (lb.id_periodo_lookup IS NULL) AS fl_lookup_periodo_ko,
        (dv.id_anag_versione IS NULL) AS fl_lookup_versione_ko
    FROM lookup_base AS lb
    LEFT JOIN hcbi_ras.dim_versione AS dv
        ON dv.id_periodo_pubblicazione=COALESCE(lb.id_periodo_lookup,(-1)::INTEGER)
       AND dv.cd_versione=lb.cd_versione
       AND dv.id_anag_provincia=COALESCE(lb.id_anag_provincia_lookup,(-1)::BIGINT);

    CREATE UNIQUE INDEX tmp_dim_capitolo_pk
        ON hcbi_ras.tmp_dim_capitolo(id_anag_capitolo)
        NULLS NOT DISTINCT;
    CREATE UNIQUE INDEX tmp_dim_capitolo_bk
        ON hcbi_ras.tmp_dim_capitolo
        (cd_capitolo,id_periodo_pubblicazione,id_anag_versione,id_anag_provincia)
        NULLS NOT DISTINCT;
    ANALYZE hcbi_ras.tmp_dim_capitolo;

    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE fl_lookup_provincia_ko),
        COUNT(*) FILTER (WHERE fl_lookup_periodo_ko),
        COUNT(*) FILTER (WHERE fl_lookup_versione_ko)
    INTO
        v_selected,v_lookup_provincia_ko,
        v_lookup_periodo_ko,v_lookup_versione_ko
    FROM hcbi_ras.tmp_dim_capitolo;

    v_rec_errors := v_codice_capitolo_assente
                  + v_lookup_provincia_ko
                  + v_lookup_periodo_ko
                  + v_lookup_versione_ko;

    IF v_lookup_provincia_ko > 0 THEN
        RAISE WARNING 'DIM_CAPITOLO: % lookup provincia non risolte; applicato -1.',
            v_lookup_provincia_ko;
    END IF;
    IF v_lookup_periodo_ko > 0 THEN
        RAISE WARNING 'DIM_CAPITOLO: % lookup periodo non risolte; applicato -1.',
            v_lookup_periodo_ko;
    END IF;
    IF v_lookup_versione_ko > 0 THEN
        RAISE WARNING 'DIM_CAPITOLO: % lookup versione non risolte; applicato -1.',
            v_lookup_versione_ko;
    END IF;

    UPDATE hcbi_ras.dim_capitolo AS d
       SET cd_capitolo=src.cd_capitolo,
           ds_capitolo=src.ds_capitolo,
           id_anag_provincia=src.id_anag_provincia,
           id_periodo_pubblicazione=src.id_periodo_pubblicazione,
           id_anag_versione=src.id_anag_versione,
           dt_update=clock_timestamp(),
           tx_update_by=p_ds_step_name
      FROM hcbi_ras.tmp_dim_capitolo AS src
     WHERE d.id_anag_capitolo=src.id_anag_capitolo
       AND ROW(d.cd_capitolo,d.ds_capitolo,d.id_anag_provincia,
               d.id_periodo_pubblicazione,d.id_anag_versione)
           IS DISTINCT FROM
           ROW(src.cd_capitolo,src.ds_capitolo,src.id_anag_provincia,
               src.id_periodo_pubblicazione,src.id_anag_versione);
    GET DIAGNOSTICS v_updated=ROW_COUNT;

    INSERT INTO hcbi_ras.dim_capitolo
    (
        id_anag_capitolo,cd_capitolo,ds_capitolo,
        id_anag_provincia,id_periodo_pubblicazione,id_anag_versione,
        dt_creation,tx_creation_by,dt_update,tx_update_by
    )
    SELECT
        src.id_anag_capitolo,src.cd_capitolo,src.ds_capitolo,
        src.id_anag_provincia,src.id_periodo_pubblicazione,src.id_anag_versione,
        clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name
    FROM hcbi_ras.tmp_dim_capitolo AS src
    ON CONFLICT ON CONSTRAINT pk_dim_capitolo DO NOTHING;
    GET DIAGNOSTICS v_inserted=ROW_COUNT;

    SELECT COUNT(*) INTO v_matched
    FROM hcbi_ras.dim_capitolo AS d
    INNER JOIN hcbi_ras.tmp_dim_capitolo AS src
        ON src.id_anag_capitolo=d.id_anag_capitolo;

    IF v_selected <> v_matched THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE=FORMAT(
                'Riconciliazione DIM_CAPITOLO non valida: applicative=%s, matched=%s',
                v_selected,v_matched);
    END IF;

    IF (v_selected + v_codice_capitolo_assente) <>
       (SELECT COUNT(*) FROM hcbi_ras.dwh_anag_capitolo) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Riconciliazione sorgente DIM_CAPITOLO non valida';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,(v_selected+v_codice_capitolo_assente),
        v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_capitolo;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    BEGIN
        DROP TABLE IF EXISTS hcbi_ras.tmp_dim_capitolo;
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
    RAISE WARNING 'Errore in pkg_dim_capitolo_prc_main. SQLSTATE=%, errore=%',
        v_sqlstate,v_sqlerrm;
END;
$procedure$
