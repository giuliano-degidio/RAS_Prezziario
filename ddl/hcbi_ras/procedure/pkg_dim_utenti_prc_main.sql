CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_utenti_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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
    v_sqlstate TEXT;
    v_sqlerrm TEXT;
    v_sql_detail TEXT;
    v_sql_hint TEXT;
    v_sql_context TEXT;
    v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::TIMESTAMP,
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    )
    INTO v_id_log;

    /*
       Materializzazione della sorgente DWH. I campi tecnici della DWH
       non vengono trasferiti nella dimensione.
    */
    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_utenti;

    CREATE TABLE hcbi_ras.tmp_dim_utenti AS
    SELECT
        src.id_anag_utente,
        src.id_sorgente_utente,
        src.cd_username,
        src.ds_email,
        src.ds_nome_visualizzato,
        src.cd_stato,
        src.cd_tipo_utente
    FROM hcbi_ras.dwh_anag_utenti AS src;

    /* Verifica preventiva della primary key sorgente. */
    CREATE UNIQUE INDEX tmp_dim_utenti_pk
        ON hcbi_ras.tmp_dim_utenti (id_anag_utente)
        NULLS NOT DISTINCT;

    /* Verifica preventiva della business key sorgente. */
    CREATE UNIQUE INDEX tmp_dim_utenti_bk
        ON hcbi_ras.tmp_dim_utenti (cd_username)
        NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_utenti;

    SELECT COUNT(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dim_utenti;

    /* Aggiornamento SCD Type 1 dei soli attributi variati. */
    UPDATE hcbi_ras.dim_utenti AS d
       SET id_sorgente_utente = src.id_sorgente_utente,
           cd_username = src.cd_username,
           ds_email = src.ds_email,
           ds_nome_visualizzato = src.ds_nome_visualizzato,
           cd_stato = src.cd_stato,
           cd_tipo_utente = src.cd_tipo_utente,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_utenti AS src
     WHERE d.id_anag_utente = src.id_anag_utente
       AND ROW(
            d.id_sorgente_utente,
            d.cd_username,
            d.ds_email,
            d.ds_nome_visualizzato,
            d.cd_stato,
            d.cd_tipo_utente
       ) IS DISTINCT FROM ROW(
            src.id_sorgente_utente,
            src.cd_username,
            src.ds_email,
            src.ds_nome_visualizzato,
            src.cd_stato,
            src.cd_tipo_utente
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_utenti
    (
        id_anag_utente,
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
        src.id_anag_utente,
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
    FROM hcbi_ras.tmp_dim_utenti AS src
    ON CONFLICT ON CONSTRAINT pk_dim_utenti
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    /*
       Riconciliazione per chiave primaria: ogni riga della sorgente deve
       risultare presente nella dimensione dopo UPDATE e INSERT.
    */
    SELECT COUNT(*)
    INTO v_matched
    FROM hcbi_ras.dim_utenti AS d
    INNER JOIN hcbi_ras.tmp_dim_utenti AS src
        ON src.id_anag_utente = d.id_anag_utente;

    IF v_selected <> v_matched THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = FORMAT(
                    'Riconciliazione DIM_UTENTI non valida: selected=%s, matched=%s',
                    v_selected,
                    v_matched
                ),
                DETAIL =
                    'Non tutte le chiavi ID_ANAG_UTENTE della sorgente risultano presenti nella dimensione.';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_utenti;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dim_utenti;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante il cleanup: SQLSTATE=%, errore=%',
                    SQLSTATE, SQLERRM;
        END;

        v_log_error := LEFT(CONCAT_WS(E'\n',
            'SQLSTATE=' || COALESCE(v_sqlstate, ''),
            'MESSAGE=' || LEFT(COALESCE(v_sqlerrm, ''), 1500),
            CASE WHEN NULLIF(v_sql_detail, '') IS NOT NULL
                 THEN 'DETAIL=' || LEFT(v_sql_detail, 1000) END,
            CASE WHEN NULLIF(v_sql_hint, '') IS NOT NULL
                 THEN 'HINT=' || LEFT(v_sql_hint, 500) END,
            CASE WHEN NULLIF(v_sql_context, '') IS NOT NULL
                 THEN 'CONTEXT=' || LEFT(v_sql_context, 800) END
        ), 4000);

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::TIMESTAMP,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore durante il logging: SQLSTATE=%, errore=%',
                        SQLSTATE, SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dim_utenti_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$procedure$
