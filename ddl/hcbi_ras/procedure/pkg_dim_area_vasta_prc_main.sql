CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_area_vasta_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_ras', 'hcbi_utility'
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

    /*
       La sorgente viene materializzata una sola volta, escludendo i
       campi tecnici della DWH sorgente che non fanno parte della DIM.
    */
    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_area_vasta;

    CREATE TABLE hcbi_ras.tmp_dim_area_vasta AS
    SELECT
        src.id_anag_area_vasta,
        src.id_sorgente_area_vasta,
        src.ds_nome
    FROM hcbi_ras.dwh_anag_area_vasta AS src;

    /* Verifica preventiva della chiave primaria sorgente. */
    CREATE UNIQUE INDEX tmp_dim_area_vasta_pk
    ON hcbi_ras.tmp_dim_area_vasta (id_anag_area_vasta)
    NULLS NOT DISTINCT;

    /* Verifica preventiva della business key sorgente. */
    CREATE UNIQUE INDEX tmp_dim_area_vasta_bk
    ON hcbi_ras.tmp_dim_area_vasta (ds_nome)
    NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_area_vasta;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dim_area_vasta;

    /* Aggiorna soltanto gli attributi effettivamente variati. */
    UPDATE hcbi_ras.dim_area_vasta AS d
       SET id_sorgente_area_vasta = src.id_sorgente_area_vasta,
           ds_nome = src.ds_nome,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_area_vasta AS src
     WHERE d.id_anag_area_vasta = src.id_anag_area_vasta
       AND ROW(
            d.id_sorgente_area_vasta,
            d.ds_nome
       ) IS DISTINCT FROM ROW(
            src.id_sorgente_area_vasta,
            src.ds_nome
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_area_vasta (
        id_anag_area_vasta,
        id_sorgente_area_vasta,
        ds_nome,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_anag_area_vasta,
        src.id_sorgente_area_vasta,
        src.ds_nome,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dim_area_vasta AS src
    ON CONFLICT ON CONSTRAINT pk_dim_area_vasta
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    /*
       Riconciliazione del caricamento:
       ogni riga sorgente deve risultare gia presente oppure inserita.
       Il conteggio aggiornati e' informativo ed e' un sottoinsieme dei
       record gia presenti.
    */
    IF v_selected <> (
        SELECT count(*)
        FROM hcbi_ras.dim_area_vasta AS d
        INNER JOIN hcbi_ras.tmp_dim_area_vasta AS src
            ON src.id_anag_area_vasta = d.id_anag_area_vasta
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = format(
                    'Riconciliazione DIM_AREA_VASTA non valida: selected=%s',
                    v_selected
                ),
                DETAIL =
                    'Non tutte le chiavi ID_ANAG_AREA_VASTA della sorgente risultano presenti nella dimensione.';
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_area_vasta;

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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dim_area_vasta;
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
                        'Errore durante il logging: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dim_area_vasta_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$procedure$
