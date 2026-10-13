CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_utenti_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_utenti;

    CREATE TABLE hcbi_ras.tmp_dwh_anag_utenti AS
    SELECT
        id_sorgente_utente,
        cd_username,
        ds_email,
        ds_nome_visualizzato,
        cd_stato,
        cd_tipo_utente
    FROM hcbi_ras.v_dwh_anag_utenti;

    CREATE UNIQUE INDEX tmp_dwh_anag_utenti_uq
    ON hcbi_ras.tmp_dwh_anag_utenti (cd_username)
    NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dwh_anag_utenti;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dwh_anag_utenti;

    UPDATE hcbi_ras.dwh_anag_utenti AS dwh
       SET id_sorgente_utente = src.id_sorgente_utente,
           ds_email = src.ds_email,
           ds_nome_visualizzato = src.ds_nome_visualizzato,
           cd_stato = src.cd_stato,
           cd_tipo_utente = src.cd_tipo_utente,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dwh_anag_utenti AS src
     WHERE dwh.cd_username = src.cd_username
       AND ROW(
            dwh.id_sorgente_utente,
            dwh.ds_email,
            dwh.ds_nome_visualizzato,
            dwh.cd_stato,
            dwh.cd_tipo_utente
       ) IS DISTINCT FROM ROW(
            src.id_sorgente_utente,
            src.ds_email,
            src.ds_nome_visualizzato,
            src.cd_stato,
            src.cd_tipo_utente
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_anag_utenti (
        id_sorgente_utente,
        cd_username,
        ds_email,
        ds_nome_visualizzato,
        cd_stato,
        cd_tipo_utente,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_sorgente_utente,
        src.cd_username,
        src.ds_email,
        src.ds_nome_visualizzato,
        src.cd_stato,
        src.cd_tipo_utente,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_utenti AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_anag_utenti
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, v_updated, v_deleted,
        v_rec_errors, 'SUCCESS', clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_utenti;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_utenti;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante il cleanup: SQLSTATE=%, errore=%',
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
                        'Errore durante la registrazione del log: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dwh_anag_utenti_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$procedure$
