CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_macro_gruppo_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log BIGINT; v_selected BIGINT:=0; v_inserted BIGINT:=0;
    v_updated BIGINT:=0; v_deleted BIGINT:=0; v_rec_errors BIGINT:=0;
    v_matched BIGINT:=0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result:=-1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_macro_gruppo;
    CREATE TABLE hcbi_ras.tmp_dwh_anag_macro_gruppo AS
    SELECT s.id_sorgente_macro_gruppo,s.ds_nome,s.ds_plurale
    FROM hcbi_ras.v_dwh_anag_macro_gruppo AS s;

    CREATE UNIQUE INDEX tmp_dwh_anag_macro_gruppo_uq
        ON hcbi_ras.tmp_dwh_anag_macro_gruppo(ds_nome) NULLS NOT DISTINCT;
    CREATE UNIQUE INDEX tmp_dwh_anag_macro_gruppo_src_uq
        ON hcbi_ras.tmp_dwh_anag_macro_gruppo(id_sorgente_macro_gruppo)
        NULLS NOT DISTINCT;
    ANALYZE hcbi_ras.tmp_dwh_anag_macro_gruppo;

    SELECT COUNT(*) INTO v_selected
    FROM hcbi_ras.tmp_dwh_anag_macro_gruppo;

    UPDATE hcbi_ras.dwh_anag_macro_gruppo AS d
       SET id_sorgente_macro_gruppo=src.id_sorgente_macro_gruppo,
           ds_plurale=src.ds_plurale,
           dt_update=clock_timestamp(),
           tx_update_by=p_ds_step_name
      FROM hcbi_ras.tmp_dwh_anag_macro_gruppo AS src
     WHERE d.ds_nome=src.ds_nome
       AND ROW(d.id_sorgente_macro_gruppo,d.ds_plurale)
           IS DISTINCT FROM ROW(src.id_sorgente_macro_gruppo,src.ds_plurale);
    GET DIAGNOSTICS v_updated=ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_anag_macro_gruppo
    (id_sorgente_macro_gruppo,ds_nome,ds_plurale,
     dt_creation,tx_creation_by,dt_update,tx_update_by)
    SELECT src.id_sorgente_macro_gruppo,src.ds_nome,src.ds_plurale,
           clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_macro_gruppo AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_anag_macro_gruppo DO NOTHING;
    GET DIAGNOSTICS v_inserted=ROW_COUNT;

    SELECT COUNT(*) INTO v_matched
    FROM hcbi_ras.dwh_anag_macro_gruppo AS d
    INNER JOIN hcbi_ras.tmp_dwh_anag_macro_gruppo AS src
        ON src.ds_nome=d.ds_nome;

    IF v_selected<>v_matched THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE=FORMAT('Riconciliazione DWH non valida: selected=%s, matched=%s',
                v_selected,v_matched);
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_macro_gruppo;
    p_result:=1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result:=-1;
    BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_macro_gruppo;
    EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: %',SQLERRM; END;
    v_log_error:=LEFT(CONCAT_WS(E'\n','SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500)),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore in pkg_dwh_anag_macro_gruppo_prc_main: %',v_sqlerrm;
END;
$procedure$
