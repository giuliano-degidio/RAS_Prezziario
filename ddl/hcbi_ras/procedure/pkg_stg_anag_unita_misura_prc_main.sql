CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_unita_misura_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log BIGINT; v_selected BIGINT := 0; v_inserted BIGINT := 0;
    v_rec_errors BIGINT := 0; v_sqlstate TEXT; v_sqlerrm TEXT;
    v_sql_detail TEXT; v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::TIMESTAMP, clock_timestamp()::TIMESTAMP, p_ds_step_name)
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_unita_misura_classificata;
    CREATE TABLE hcbi_ras.tmp_anag_unita_misura_classificata AS
    WITH src AS MATERIALIZED (
        SELECT
            f.cd_unita_misura AS cd_unita_misura_raw,
            f.ds_unita_misura AS ds_unita_misura_raw,
            f.nr_decimali AS nr_decimali_raw,
            f.id_sorgente_unita_misura AS id_sorgente_unita_misura_raw,
            f.dt_last_update AS dt_last_update_raw,
            f.dt_fine_validita AS dt_fine_validita_raw,
            NULLIF(BTRIM(f.cd_unita_misura::TEXT), '') AS cd_unita_misura_txt,
            NULLIF(BTRIM(f.ds_unita_misura::TEXT), '') AS ds_unita_misura_txt,
            NULLIF(BTRIM(f.nr_decimali::TEXT), '') AS nr_decimali_txt,
            NULLIF(BTRIM(f.id_sorgente_unita_misura::TEXT), '') AS id_sorgente_unita_misura_txt,
            NULLIF(BTRIM(f.dt_last_update::TEXT), '') AS dt_last_update_txt,
            NULLIF(BTRIM(f.dt_fine_validita::TEXT), '') AS dt_fine_validita_txt,
            COUNT(*) OVER (PARTITION BY NULLIF(BTRIM(f.cd_unita_misura::TEXT), '')) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_anag_unita_misura AS f
    ), cv AS MATERIALIZED (
        SELECT s.*,
            hcbi_ras.try_anag_um_numeric_10_0(nr_decimali_txt) AS nr_decimali_cv,
            hcbi_ras.try_anag_um_integer(id_sorgente_unita_misura_txt) AS id_sorgente_unita_misura_cv,
            hcbi_ras.try_anag_um_timestamp(dt_last_update_txt) AS dt_last_update_cv,
            hcbi_ras.try_anag_um_timestamp(dt_fine_validita_txt) AS dt_fine_validita_cv
        FROM src AS s
    )
    SELECT c.*,
        CASE
            WHEN cd_unita_misura_txt IS NULL THEN 'cd_unita_misura obbligatorio'
            WHEN LENGTH(cd_unita_misura_txt) > 20 THEN 'cd_unita_misura supera 20 caratteri'
            WHEN duplicate_count > 1 THEN 'Chiave duplicata: cd_unita_misura'
            WHEN nr_decimali_txt IS NOT NULL AND nr_decimali_cv IS NULL
                THEN 'nr_decimali non convertibile o fuori dominio NUMERIC(10,0)'
            WHEN id_sorgente_unita_misura_txt IS NOT NULL AND id_sorgente_unita_misura_cv IS NULL
                THEN 'id_sorgente_unita_misura non convertibile o fuori dominio INTEGER'
            WHEN dt_last_update_txt IS NOT NULL AND dt_last_update_cv IS NULL
                THEN 'dt_last_update non convertibile'
            WHEN dt_fine_validita_txt IS NOT NULL AND dt_fine_validita_cv IS NULL
                THEN 'dt_fine_validita non convertibile'
            ELSE NULL
        END::TEXT AS tx_motivo_scarto
    FROM cv AS c;

    SELECT COUNT(*) INTO v_selected FROM hcbi_ras.tmp_anag_unita_misura_classificata;

    INSERT INTO hcbi_ras.stg_anag_unita_misura (
        cd_unita_misura, ds_unita_misura, nr_decimali,
        id_sorgente_unita_misura, dt_last_update, dt_fine_validita)
    SELECT cd_unita_misura_txt, ds_unita_misura_txt, nr_decimali_cv,
        id_sorgente_unita_misura_cv, dt_last_update_cv, dt_fine_validita_cv
    FROM hcbi_ras.tmp_anag_unita_misura_classificata
    WHERE tx_motivo_scarto IS NULL;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

INSERT INTO hcbi_ras.stg_anag_unita_misura_rej (
    cd_unita_misura,
    ds_unita_misura,
    nr_decimali,
    id_sorgente_unita_misura,
    dt_last_update,
    dt_fine_validita,
    tx_motivo_scarto
)
SELECT
    cd_unita_misura_raw,
    ds_unita_misura_raw,
    nr_decimali_raw,
    id_sorgente_unita_misura_raw,
    dt_last_update_cv,
    dt_fine_validita_cv,
    tx_motivo_scarto
FROM hcbi_ras.tmp_anag_unita_misura_classificata
WHERE tx_motivo_scarto IS NOT NULL;

GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION 'Riconciliazione non valida: selected=%, inserted=%, rejected=%',
            v_selected, v_inserted, v_rec_errors;
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, 0, 0, v_rec_errors, 'SUCCESS',
        clock_timestamp()::TIMESTAMP, p_ds_step_name);
    DROP TABLE hcbi_ras.tmp_anag_unita_misura_classificata;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE, v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL, v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_anag_unita_misura_classificata;
    EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: %', SQLERRM; END;
    v_log_error := LEFT(CONCAT_WS(E'\n', 'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||COALESCE(v_sqlerrm,''), 'DETAIL='||COALESCE(v_sql_detail,''),
        'HINT='||COALESCE(v_sql_hint,''), 'CONTEXT='||COALESCE(v_sql_context,'')), 4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log, 'FAILED', v_log_error, clock_timestamp()::TIMESTAMP, p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %', SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore in pkg_stg_anag_unita_misura_prc_main: %', v_sqlerrm;
END;
$procedure$
