CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_area_vasta_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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
    v_rec_errors bigint := 0;
    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_area_vasta_classificata;

    CREATE TABLE hcbi_ras.tmp_anag_area_vasta_classificata AS
    WITH src AS MATERIALIZED (
        SELECT
            f.id_sorgente_area_vasta AS id_sorgente_area_vasta_raw,
            f.ds_nome AS ds_nome_raw,
            nullif(btrim(f.id_sorgente_area_vasta), '')
                AS id_sorgente_area_vasta_txt,
            nullif(btrim(f.ds_nome), '') AS ds_nome_txt,
            count(*) OVER (
                PARTITION BY nullif(btrim(f.ds_nome), '')
            ) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_anag_area_vasta AS f
    ), converted AS MATERIALIZED (
        SELECT
            s.*,
            hcbi_ras.try_bigint(s.id_sorgente_area_vasta_txt)
                AS id_sorgente_area_vasta_cv
        FROM src AS s
    )
    SELECT
        c.*,
        CASE
            WHEN c.ds_nome_txt IS NULL THEN
                'ds_nome obbligatorio'
            WHEN c.duplicate_count > 1 THEN
                'Chiave duplicata nella sorgente: (ds_nome)'
            WHEN length(c.ds_nome_txt) > 100 THEN
                'ds_nome eccede 100 caratteri'
            WHEN c.id_sorgente_area_vasta_txt IS NOT NULL
             AND c.id_sorgente_area_vasta_cv IS NULL THEN
                'id_sorgente_area_vasta non convertibile in bigint o fuori dominio'
            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM converted AS c;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_anag_area_vasta_classificata;

    INSERT INTO hcbi_ras.stg_anag_area_vasta (
        id_sorgente_area_vasta,
        ds_nome
    )
    SELECT
        c.id_sorgente_area_vasta_cv,
        c.ds_nome_txt
    FROM hcbi_ras.tmp_anag_area_vasta_classificata AS c
    WHERE c.tx_motivo_scarto IS NULL;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_anag_area_vasta_rej (
        id_sorgente_area_vasta,
        ds_nome,
        tx_motivo_scarto
    )
    SELECT
        c.id_sorgente_area_vasta_raw,
        c.ds_nome_raw,
        c.tx_motivo_scarto
    FROM hcbi_ras.tmp_anag_area_vasta_classificata AS c
    WHERE c.tx_motivo_scarto IS NOT NULL;

    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = format(
                    'Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',
                    v_selected,
                    v_inserted,
                    v_rec_errors
                );
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_area_vasta_classificata;
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_sqlstate = RETURNED_SQLSTATE,
            v_sqlerrm = MESSAGE_TEXT,
            v_sql_detail = PG_EXCEPTION_DETAIL,
            v_sql_hint = PG_EXCEPTION_HINT,
            v_sql_context = PG_EXCEPTION_CONTEXT;

        p_result := -1;

        BEGIN
            DROP TABLE IF EXISTS hcbi_ras.tmp_anag_area_vasta_classificata;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore nel cleanup: SQLSTATE=%, errore=%',
                    SQLSTATE,
                    SQLERRM;
        END;

        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
                CASE WHEN nullif(v_sql_detail, '') IS NOT NULL
                    THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
                CASE WHEN nullif(v_sql_hint, '') IS NOT NULL
                    THEN 'HINT=' || left(v_sql_hint, 500) END,
                CASE WHEN nullif(v_sql_context, '') IS NOT NULL
                    THEN 'CONTEXT=' || left(v_sql_context, 800) END
            ),
            4000
        );

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::timestamp,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore nel logging: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_stg_anag_area_vasta_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$procedure$
