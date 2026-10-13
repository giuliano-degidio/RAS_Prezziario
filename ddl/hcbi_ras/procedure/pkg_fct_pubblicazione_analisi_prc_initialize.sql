CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pubblicazione_analisi_prc_initialize(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log BIGINT;
    v_sqlstate TEXT;
    v_sqlerrm TEXT;
    v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,
        v_sqlerrm=MESSAGE_TEXT;
    p_result := -1;
    v_log_error := left('SQLSTATE='||coalesce(v_sqlstate,'')||E'\nMESSAGE='||coalesce(v_sqlerrm,''),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging INITIALIZE FCT_PUBBLICAZIONE_ANALISI: %',SQLERRM;
        END;
    END IF;
    RAISE WARNING 'Errore INITIALIZE FCT_PUBBLICAZIONE_ANALISI: SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$procedure$
