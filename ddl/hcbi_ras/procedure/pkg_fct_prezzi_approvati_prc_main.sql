CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log bigint;
    v_selected bigint := 0;
    v_inserted bigint := 0;
    v_updated bigint := 0;
    v_deleted bigint := 0;
    v_errors bigint := 0;
    v_dwh_count bigint := 0;
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

    /* I membri -1 sono obbligatori per rispettare le FK della fact. */
    IF NOT EXISTS (
           SELECT 1
             FROM hcbi_ras.dim_periodo
            WHERE id_periodo = -1
       )
       OR NOT EXISTS (
           SELECT 1
             FROM hcbi_ras.dim_provincia
            WHERE id_anag_provincia = -1
       )
       OR NOT EXISTS (
           SELECT 1
             FROM hcbi_ras.dim_versione
            WHERE id_anag_versione = -1
       )
       OR NOT EXISTS (
           SELECT 1
             FROM hcbi_ras.dim_articolo
            WHERE id_anag_articolo = -1
       ) THEN
        RAISE EXCEPTION
            'Membri tecnici -1 mancanti nelle dimensioni della FCT_PREZZI_APPROVATI';
    END IF;

    DROP TABLE IF EXISTS tmp_fct_prezzi_approvati_src;

    CREATE TEMP TABLE tmp_fct_prezzi_approvati_src
    ON COMMIT DROP
    AS
    SELECT
        id_prezzi_approvati,
        id_periodo_pubblicazione,
        id_anag_provincia,
        id_anag_versione,
        id_anag_articolo,
        nr_prezzo,
        dt_approvazione,
        cd_articolo,
        cd_articolo_normalizzato,
        ds_anno,
        cd_versione,
        id_sorgente_provincia,
        tx_motivo_lookup
    FROM hcbi_ras.v_fct_prezzi_approvati_src;

    SELECT count(*)
      INTO v_selected
      FROM tmp_fct_prezzi_approvati_src;

    SELECT count(*)
      INTO v_dwh_count
      FROM hcbi_ras.dwh_prezzi_approvati;

    IF v_selected <> v_dwh_count THEN
        RAISE EXCEPTION
            'Cardinalita vista FCT_PREZZI_APPROVATI (%) diversa dal DWH (%)',
            v_selected,
            v_dwh_count;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM tmp_fct_prezzi_approvati_src
         GROUP BY id_prezzi_approvati
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION
            'Lookup non univoche nella vista FCT_PREZZI_APPROVATI';
    END IF;

    SELECT count(*)
      INTO v_errors
      FROM tmp_fct_prezzi_approvati_src
     WHERE tx_motivo_lookup IS NOT NULL;

    SELECT count(*)
      INTO v_inserted
      FROM tmp_fct_prezzi_approvati_src s
      LEFT JOIN hcbi_ras.fct_prezzi_approvati f
        ON f.id_prezzi_approvati = s.id_prezzi_approvati
     WHERE f.id_prezzi_approvati IS NULL;

    SELECT count(*)
      INTO v_updated
      FROM tmp_fct_prezzi_approvati_src s
      JOIN hcbi_ras.fct_prezzi_approvati f
        ON f.id_prezzi_approvati = s.id_prezzi_approvati
     WHERE ROW(
               f.id_periodo_pubblicazione,
               f.id_anag_provincia,
               f.id_anag_versione,
               f.id_anag_articolo,
               f.nr_prezzo,
               f.dt_approvazione
           ) IS DISTINCT FROM ROW(
               s.id_periodo_pubblicazione,
               s.id_anag_provincia,
               s.id_anag_versione,
               s.id_anag_articolo,
               s.nr_prezzo,
               s.dt_approvazione
           );

    INSERT INTO hcbi_ras.fct_prezzi_approvati AS f
    (
        id_prezzi_approvati,
        id_periodo_pubblicazione,
        id_anag_provincia,
        id_anag_versione,
        id_anag_articolo,
        nr_prezzo,
        dt_approvazione,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        s.id_prezzi_approvati,
        s.id_periodo_pubblicazione,
        s.id_anag_provincia,
        s.id_anag_versione,
        s.id_anag_articolo,
        s.nr_prezzo,
        s.dt_approvazione,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM tmp_fct_prezzi_approvati_src s
    ON CONFLICT (id_prezzi_approvati)
    DO UPDATE SET
        id_periodo_pubblicazione = EXCLUDED.id_periodo_pubblicazione,
        id_anag_provincia = EXCLUDED.id_anag_provincia,
        id_anag_versione = EXCLUDED.id_anag_versione,
        id_anag_articolo = EXCLUDED.id_anag_articolo,
        nr_prezzo = EXCLUDED.nr_prezzo,
        dt_approvazione = EXCLUDED.dt_approvazione,
        dt_update = clock_timestamp(),
        tx_update_by = p_ds_step_name
    WHERE ROW(
              f.id_periodo_pubblicazione,
              f.id_anag_provincia,
              f.id_anag_versione,
              f.id_anag_articolo,
              f.nr_prezzo,
              f.dt_approvazione
          ) IS DISTINCT FROM ROW(
              EXCLUDED.id_periodo_pubblicazione,
              EXCLUDED.id_anag_provincia,
              EXCLUDED.id_anag_versione,
              EXCLUDED.id_anag_articolo,
              EXCLUDED.nr_prezzo,
              EXCLUDED.dt_approvazione
          );

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_errors,
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
                    RAISE WARNING 'Errore nel logging di MAIN FCT_PREZZI_APPROVATI: %', SQLERRM;
            END;
        END IF;

        RAISE;
END;
$procedure$
