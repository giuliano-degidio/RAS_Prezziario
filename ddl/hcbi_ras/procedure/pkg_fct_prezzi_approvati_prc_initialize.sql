CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_initialize(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log bigint;
    v_updated bigint := 0;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
               p_id_chain_log,
               p_id_chain,
               p_id_step,
               p_ds_step_name,
               clock_timestamp()::timestamp,
               clock_timestamp()::timestamp,
               p_ds_step_name)
      INTO v_id_log;

    UPDATE hcbi_ras.dwh_prezzi_approvati
       SET dt_reciclo = NULL
     WHERE dt_reciclo IS NOT NULL;

    UPDATE hcbi_ras.dwh_prezzi_approvati d
       SET dt_reciclo = clock_timestamp()
      FROM hcbi_ras.fct_prezzi_approvati f
     WHERE f.id_prezzi_approvati = d.id_prezzi_approvati
       AND (
            f.id_periodo_pubblicazione = -1
         OR f.id_anag_provincia = -1
         OR f.id_anag_versione = -1
         OR f.id_anag_articolo = -1
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_updated,
        0,
        v_updated,
        0,
        0,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name);

    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                    clock_timestamp()::timestamp,
                    p_ds_step_name);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Errore nel logging di INITIALIZE FCT_PREZZI_APPROVATI: %', SQLERRM;
            END;
        END IF;

        RAISE;
END;
$procedure$
