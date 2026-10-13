CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_provincia_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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
    v_matched bigint := 0;
    v_codice_provincia_assente bigint := 0;

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
       Il valore 0 identifica il riferimento AREA VASTA non valorizzato
       nella sorgente. Il valore -1 identifica un riferimento valorizzato
       nella sorgente ma non risolto dalla lookup.
       La FK richiede che entrambi i record tecnici esistano realmente.
    */
    IF NOT EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_area_vasta AS dav
        WHERE dav.id_anag_area_vasta = 0
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico DIM_AREA_VASTA con id_anag_area_vasta = 0 non presente',
                DETAIL =
                    'DIM_PROVINCIA usa id_area_vasta = 0 quando id_sorgente_area_vasta e'' NULL.',
                HINT =
                    'Creare il record tecnico 0 nella DIM_AREA_VASTA prima del caricamento.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_area_vasta AS dav
        WHERE dav.id_anag_area_vasta = -1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico DIM_AREA_VASTA con id_anag_area_vasta = -1 non presente',
                DETAIL =
                    'DIM_PROVINCIA usa id_area_vasta = -1 quando id_sorgente_area_vasta e'' valorizzato ma la lookup non trova corrispondenza.',
                HINT =
                    'Creare il record tecnico -1 nella DIM_AREA_VASTA prima del caricamento.';
    END IF;

    /*
       La lookup deve essere deterministica. Piu' record DIM_AREA_VASTA
       con lo stesso ID_SORGENTE_AREA_VASTA produrrebbero una duplicazione
       delle righe della provincia.
    */
    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_area_vasta AS dav
        WHERE dav.id_sorgente_area_vasta IS NOT NULL
        GROUP BY dav.id_sorgente_area_vasta
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE =
                    'Lookup DIM_AREA_VASTA non deterministica',
                DETAIL =
                    'Esistono piu record con lo stesso id_sorgente_area_vasta.',
                HINT =
                    'Rimuovere i duplicati o introdurre un vincolo univoco sulla chiave di lookup.';
    END IF;

    SELECT count(*) INTO v_codice_provincia_assente
    FROM hcbi_ras.dwh_anag_provincia AS src
    WHERE nullif(btrim(src.cd_provincia::text),'') IS NULL;
    IF v_codice_provincia_assente > 0 THEN
        RAISE WARNING
            'DIM_PROVINCIA: % record con cd_provincia NULL o vuoto ricondotti al tappo id_anag_provincia=0.',
            v_codice_provincia_assente;
    END IF;
    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_provincia;
    CREATE TABLE hcbi_ras.tmp_dim_provincia AS
    SELECT
        src.id_anag_provincia,
        src.cd_provincia,
        src.ds_nome,
        CASE
            WHEN src.id_sorgente_area_vasta IS NULL
                THEN 0::bigint
            WHEN dav.id_anag_area_vasta IS NULL
                THEN (-1)::bigint
            ELSE dav.id_anag_area_vasta
        END AS id_area_vasta,
        src.fl_provincia_principale_regionale,
        src.fl_provincia_principale_area_vasta
    FROM hcbi_ras.dwh_anag_provincia AS src
    LEFT JOIN hcbi_ras.dim_area_vasta AS dav
        ON dav.id_sorgente_area_vasta = src.id_sorgente_area_vasta
    WHERE nullif(btrim(src.cd_provincia::text),'') IS NOT NULL;

    /* Verifica preventiva della primary key sorgente. */
    CREATE UNIQUE INDEX tmp_dim_provincia_pk
    ON hcbi_ras.tmp_dim_provincia (id_anag_provincia)
    NULLS NOT DISTINCT;

    /* Verifica preventiva della business key sorgente. */
    CREATE UNIQUE INDEX tmp_dim_provincia_bk
    ON hcbi_ras.tmp_dim_provincia (cd_provincia)
    NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_provincia;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dim_provincia;
    v_rec_errors := v_codice_provincia_assente;

    UPDATE hcbi_ras.dim_provincia AS d
       SET cd_provincia = src.cd_provincia,
           ds_nome = src.ds_nome,
           id_area_vasta = src.id_area_vasta,
           fl_provincia_principale_regionale =
               src.fl_provincia_principale_regionale,
           fl_provincia_principale_area_vasta =
               src.fl_provincia_principale_area_vasta,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_provincia AS src
     WHERE d.id_anag_provincia = src.id_anag_provincia
       AND ROW(
            d.cd_provincia,
            d.ds_nome,
            d.id_area_vasta,
            d.fl_provincia_principale_regionale,
            d.fl_provincia_principale_area_vasta
       ) IS DISTINCT FROM ROW(
            src.cd_provincia,
            src.ds_nome,
            src.id_area_vasta,
            src.fl_provincia_principale_regionale,
            src.fl_provincia_principale_area_vasta
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_provincia (
        id_anag_provincia,
        cd_provincia,
        ds_nome,
        id_area_vasta,
        fl_provincia_principale_regionale,
        fl_provincia_principale_area_vasta,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_anag_provincia,
        src.cd_provincia,
        src.ds_nome,
        src.id_area_vasta,
        src.fl_provincia_principale_regionale,
        src.fl_provincia_principale_area_vasta,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dim_provincia AS src
    ON CONFLICT ON CONSTRAINT pk_dim_provincia
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    /*
       Riconciliazione per chiave primaria: tutte le righe sorgente devono
       risultare presenti nella dimensione dopo UPDATE e INSERT.
    */
    SELECT count(*)
    INTO v_matched
    FROM hcbi_ras.dim_provincia AS d
    INNER JOIN hcbi_ras.tmp_dim_provincia AS src
        ON src.id_anag_provincia = d.id_anag_provincia;

    IF v_selected <> v_matched THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = format(
                    'Riconciliazione DIM_PROVINCIA non valida: applicative=%s, matched=%s',
                    v_selected,
                    v_matched
                ),
                DETAIL =
                    'Non tutte le chiavi applicative ID_ANAG_PROVINCIA risultano presenti nella dimensione.';
    END IF;
    IF (v_selected + v_codice_provincia_assente) <>
       (SELECT count(*) FROM hcbi_ras.dwh_anag_provincia) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Riconciliazione sorgente DIM_PROVINCIA non valida';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        (v_selected + v_codice_provincia_assente),
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_provincia;

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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dim_provincia;
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
            'Errore in pkg_dim_provincia_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$procedure$
