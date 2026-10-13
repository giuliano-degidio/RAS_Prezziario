CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_macro_gruppo_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log BIGINT; v_selected BIGINT:=0; v_inserted BIGINT:=0;
    v_updated BIGINT:=0; v_deleted BIGINT:=0; v_rec_errors BIGINT:=0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result:=-1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_macro_gruppo_classificata;
    CREATE TABLE hcbi_ras.tmp_anag_macro_gruppo_classificata AS
    WITH src AS MATERIALIZED
    (
        SELECT
            f.id_sorgente_macro_gruppo AS id_raw,
            f.ds_nome AS nome_raw,
            f.ds_plurale AS plurale_raw,
            NULLIF(BTRIM(f.id_sorgente_macro_gruppo),'') AS id_txt,
            NULLIF(BTRIM(f.ds_nome),'') AS nome_txt,
            NULLIF(BTRIM(f.ds_plurale),'') AS plurale_txt,
            COUNT(*) OVER (PARTITION BY NULLIF(BTRIM(f.ds_nome),'')) AS nome_duplicate_count,
            COUNT(*) OVER (PARTITION BY NULLIF(BTRIM(f.id_sorgente_macro_gruppo),'')) AS id_duplicate_count
        FROM hcbi_ras.v_src_tmp_anag_macro_gruppo AS f
    ), converted AS MATERIALIZED
    (
        SELECT s.*,hcbi_ras.try_bigint(s.id_txt) AS id_cv
        FROM src AS s
    )
    SELECT
        c.*,
        CASE
            WHEN c.id_txt IS NULL THEN 'id_sorgente_macro_gruppo obbligatorio'
            WHEN c.id_cv IS NULL THEN 'id_sorgente_macro_gruppo non convertibile in bigint o fuori dominio'
            WHEN c.nome_txt IS NULL THEN 'ds_nome obbligatorio'
            WHEN LENGTH(c.nome_txt)>50 THEN 'ds_nome eccede 50 caratteri'
            WHEN LENGTH(c.plurale_txt)>50 THEN 'ds_plurale eccede 50 caratteri'
            WHEN c.nome_duplicate_count>1 THEN 'Chiave duplicata nella sorgente: (ds_nome)'
            WHEN c.id_duplicate_count>1 THEN 'Identificativo sorgente duplicato: (id_sorgente_macro_gruppo)'
            ELSE NULL
        END::TEXT AS tx_motivo_scarto
    FROM converted AS c;

    SELECT COUNT(*) INTO v_selected
    FROM hcbi_ras.tmp_anag_macro_gruppo_classificata;

    INSERT INTO hcbi_ras.stg_anag_macro_gruppo
        (id_sorgente_macro_gruppo,ds_nome,ds_plurale)
    SELECT c.id_cv,c.nome_txt,c.plurale_txt
    FROM hcbi_ras.tmp_anag_macro_gruppo_classificata AS c
    WHERE c.tx_motivo_scarto IS NULL;
    GET DIAGNOSTICS v_inserted=ROW_COUNT;

    INSERT INTO hcbi_ras.stg_anag_macro_gruppo_rej
        (id_sorgente_macro_gruppo,ds_nome,ds_plurale,tx_motivo_scarto)
    SELECT c.id_raw,c.nome_raw,c.plurale_raw,c.tx_motivo_scarto
    FROM hcbi_ras.tmp_anag_macro_gruppo_classificata AS c
    WHERE c.tx_motivo_scarto IS NOT NULL;
    GET DIAGNOSTICS v_rec_errors=ROW_COUNT;

    IF v_selected<>v_inserted+v_rec_errors THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE=FORMAT('Riconciliazione STG non valida: selected=%s, inserted=%s, rejected=%s',
                v_selected,v_inserted,v_rec_errors);
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_macro_gruppo_classificata;
    p_result:=1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result:=-1;
    BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_anag_macro_gruppo_classificata;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
    END;
    v_log_error:=LEFT(CONCAT_WS(E'\n',
        'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500),
        CASE WHEN NULLIF(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||LEFT(v_sql_detail,1000) END,
        CASE WHEN NULLIF(v_sql_hint,'') IS NOT NULL THEN 'HINT='||LEFT(v_sql_hint,500) END,
        CASE WHEN NULLIF(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||LEFT(v_sql_context,800) END),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
        END;
    END IF;
    RAISE WARNING 'Errore in pkg_stg_anag_macro_gruppo_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$procedure$
