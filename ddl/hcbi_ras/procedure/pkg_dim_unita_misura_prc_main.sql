CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_unita_misura_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log BIGINT;
    v_selected BIGINT := 0; v_inserted BIGINT := 0; v_updated BIGINT := 0;
    v_deleted BIGINT := 0; v_rec_errors BIGINT := 0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT; v_sql_hint TEXT;
    v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_unita_misura;
    CREATE TABLE hcbi_ras.tmp_dim_unita_misura AS
    SELECT
        src.id_anag_unita_misura,
        src.cd_unita_misura,
        src.ds_unita_misura,
        src.nr_decimali,
        src.id_sorgente_unita_misura,
        src.dt_last_update,
        src.dt_fine_validita
    FROM hcbi_ras.dwh_anag_unita_misura AS src;

    CREATE UNIQUE INDEX tmp_dim_unita_misura_pk
        ON hcbi_ras.tmp_dim_unita_misura(id_anag_unita_misura) NULLS NOT DISTINCT;
    CREATE UNIQUE INDEX tmp_dim_unita_misura_bk
        ON hcbi_ras.tmp_dim_unita_misura(cd_unita_misura) NULLS NOT DISTINCT;
    ANALYZE hcbi_ras.tmp_dim_unita_misura;

    SELECT COUNT(*) INTO v_selected FROM hcbi_ras.tmp_dim_unita_misura;

    UPDATE hcbi_ras.dim_unita_misura AS d
       SET cd_unita_misura = src.cd_unita_misura,
           ds_unita_misura = src.ds_unita_misura,
           nr_decimali = src.nr_decimali,
           id_sorgente_unita_misura = src.id_sorgente_unita_misura,
           dt_last_update = src.dt_last_update,
           dt_fine_validita = src.dt_fine_validita,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_unita_misura AS src
     WHERE d.id_anag_unita_misura = src.id_anag_unita_misura
       AND ROW(d.cd_unita_misura,d.ds_unita_misura,d.nr_decimali,
               d.id_sorgente_unita_misura,d.dt_last_update,d.dt_fine_validita)
           IS DISTINCT FROM
           ROW(src.cd_unita_misura,src.ds_unita_misura,src.nr_decimali,
               src.id_sorgente_unita_misura,src.dt_last_update,src.dt_fine_validita);
    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_unita_misura(
        id_anag_unita_misura,cd_unita_misura,ds_unita_misura,nr_decimali,
        id_sorgente_unita_misura,dt_last_update,dt_fine_validita,
        dt_creation,tx_creation_by,dt_update,tx_update_by)
    SELECT
        src.id_anag_unita_misura,src.cd_unita_misura,src.ds_unita_misura,
        src.nr_decimali,src.id_sorgente_unita_misura,src.dt_last_update,
        src.dt_fine_validita,clock_timestamp(),p_ds_step_name,
        clock_timestamp(),p_ds_step_name
    FROM hcbi_ras.tmp_dim_unita_misura AS src
    ON CONFLICT ON CONSTRAINT pk_dim_unita_misura DO NOTHING;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    IF v_selected <> (
        SELECT COUNT(*)
        FROM hcbi_ras.dim_unita_misura AS d
        INNER JOIN hcbi_ras.tmp_dim_unita_misura AS src
            ON src.id_anag_unita_misura = d.id_anag_unita_misura)
    THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE=FORMAT('Riconciliazione DIM_UNITA_MISURA non valida: selected=%s',v_selected),
            DETAIL='Non tutte le chiavi ID_ANAG_UNITA_MISURA della sorgente risultano presenti nella dimensione.';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_unita_misura;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dim_unita_misura;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Errore durante il cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
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
                v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore durante il logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
        END;
    END IF;
    RAISE WARNING 'Errore in pkg_dim_unita_misura_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$procedure$
