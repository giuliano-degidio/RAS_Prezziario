CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_informatori_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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
    v_lookup_ateco_ko BIGINT := 0;
    v_lookup_periodo_ko BIGINT := 0;
    v_lookup_provincia_ko BIGINT := 0;
    v_lookup_versione_ko BIGINT := 0;
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

    /* Record tecnici richiesti dalle FK. */
    IF NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_ateco_2002
        WHERE id_anag_ateco_2002 = 0
    ) OR NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_ateco_2002
        WHERE id_anag_ateco_2002 = -1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'Record tecnici 0 e/o -1 non presenti in DIM_ATECO_2002';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo = 0
    ) OR NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo = -1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'Record tecnici 0 e/o -1 non presenti in DIM_PERIODO';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_provincia
        WHERE id_anag_provincia = 0
    ) OR NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_provincia
        WHERE id_anag_provincia = -1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'Record tecnici 0 e/o -1 non presenti in DIM_PROVINCIA';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_versione
        WHERE id_anag_versione = 0
    ) OR NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_versione
        WHERE id_anag_versione = -1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'Record tecnici 0 e/o -1 non presenti in DIM_VERSIONE';
    END IF;

    /* Le lookup devono essere deterministiche. */
    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_ateco_2002
        WHERE cd_ateco_2002 IS NOT NULL
        GROUP BY cd_ateco_2002
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Lookup DIM_ATECO_2002 non deterministica',
            DETAIL = 'Esistono piu record con lo stesso cd_ateco_2002.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_periodo
        WHERE ds_anno IS NOT NULL
        GROUP BY ds_anno
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Lookup DIM_PERIODO non deterministica',
            DETAIL = 'Esistono piu record con lo stesso ds_anno.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dwh_anag_provincia
        WHERE id_sorgente_provincia IS NOT NULL
        GROUP BY id_sorgente_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Lookup DWH_ANAG_PROVINCIA non deterministica',
            DETAIL = 'Esistono piu record con lo stesso id_sorgente_provincia.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_provincia
        WHERE cd_provincia IS NOT NULL
        GROUP BY cd_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Lookup DIM_PROVINCIA non deterministica',
            DETAIL = 'Esistono piu record con lo stesso cd_provincia.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_versione
        GROUP BY id_periodo_pubblicazione, cd_versione, id_anag_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Lookup DIM_VERSIONE non deterministica',
            DETAIL = 'Esistono duplicati sulla business key della versione.';
    END IF;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_informatori;

    CREATE TABLE hcbi_ras.tmp_dim_informatori AS
    WITH lookup_base AS MATERIALIZED
    (
        SELECT
            src.id_anag_informatore,
            src.id_sorgente_informatore,
            src.ds_ragione_sociale,
            src.cd_p_iva,
            CASE
                WHEN NULLIF(BTRIM(src.cd_codice_ateco_2002), '') IS NULL
                    THEN 0::BIGINT
                WHEN dat.id_anag_ateco_2002 IS NULL
                    THEN (-1)::BIGINT
                ELSE dat.id_anag_ateco_2002
            END AS id_anag_ateco_2002,
            src.ds_indirizzo_sede_legale,
            src.cd_cap_sede_legale,
            src.ds_citta_sede_legale,
            src.cd_provincia_sede_legale,
            src.ds_indirizzo_sede_operativa,
            src.cd_cap_sede_operativa,
            src.ds_citta_sede_operativa,
            src.cd_provincia_sede_operativa,
            src.ds_contatti,
            src.cd_stato,
            src.ds_note,
            src.ds_stato_attivita,
            src.cd_codice_fiscale,
            COALESCE(dpe.id_periodo, (-1)::INTEGER)
                AS id_periodo_pubblicazione,
            src.dt_last_update,
            src.ds_nazione,
            src.cd_versione,
            COALESCE(dpr.id_anag_provincia, (-1)::BIGINT)
                AS id_anag_provincia,
            src.fl_escludi_invio_mail_assoc_listino_completa,
            (
                NULLIF(BTRIM(src.cd_codice_ateco_2002), '') IS NOT NULL
                AND dat.id_anag_ateco_2002 IS NULL
            ) AS fl_lookup_ateco_ko,
            (dpe.id_periodo IS NULL) AS fl_lookup_periodo_ko,
            (dpr.id_anag_provincia IS NULL) AS fl_lookup_provincia_ko
        FROM hcbi_ras.dwh_anag_informatori AS src
        LEFT JOIN hcbi_ras.dim_ateco_2002 AS dat
            ON dat.cd_ateco_2002 =
               NULLIF(BTRIM(src.cd_codice_ateco_2002), '')
        LEFT JOIN hcbi_ras.dim_periodo AS dpe
            ON dpe.ds_anno = src.ds_anno_pubblicazione
        LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwh_pr
            ON dwh_pr.id_sorgente_provincia =
               src.id_sorgente_provincia
        LEFT JOIN hcbi_ras.dim_provincia AS dpr
            ON dpr.cd_provincia = dwh_pr.cd_provincia
    )
    SELECT
        base.id_anag_informatore,
        base.id_sorgente_informatore,
        base.ds_ragione_sociale,
        base.cd_p_iva,
        base.id_anag_ateco_2002,
        base.ds_indirizzo_sede_legale,
        base.cd_cap_sede_legale,
        base.ds_citta_sede_legale,
        base.cd_provincia_sede_legale,
        base.ds_indirizzo_sede_operativa,
        base.cd_cap_sede_operativa,
        base.ds_citta_sede_operativa,
        base.cd_provincia_sede_operativa,
        base.ds_contatti,
        base.cd_stato,
        base.ds_note,
        base.ds_stato_attivita,
        base.cd_codice_fiscale,
        base.id_periodo_pubblicazione,
        base.dt_last_update,
        base.ds_nazione,
        CASE
            WHEN base.cd_versione IS NULL
                THEN 0::BIGINT
            WHEN dve.id_anag_versione IS NULL
                THEN (-1)::BIGINT
            ELSE dve.id_anag_versione
        END AS id_anag_versione,
        base.id_anag_provincia,
        base.fl_escludi_invio_mail_assoc_listino_completa,
        base.fl_lookup_ateco_ko,
        base.fl_lookup_periodo_ko,
        base.fl_lookup_provincia_ko,
        (
            base.cd_versione IS NOT NULL
            AND dve.id_anag_versione IS NULL
        ) AS fl_lookup_versione_ko
    FROM lookup_base AS base
    LEFT JOIN hcbi_ras.dim_versione AS dve
        ON dve.id_periodo_pubblicazione =
           base.id_periodo_pubblicazione
       AND dve.cd_versione = base.cd_versione
       AND dve.id_anag_provincia = base.id_anag_provincia;

    /* Verifiche preventive della PK e della business key trasformata. */
    CREATE UNIQUE INDEX tmp_dim_informatori_pk
        ON hcbi_ras.tmp_dim_informatori (id_anag_informatore)
        NULLS NOT DISTINCT;

    CREATE UNIQUE INDEX tmp_dim_informatori_bk
        ON hcbi_ras.tmp_dim_informatori
        (
            ds_ragione_sociale,
            id_periodo_pubblicazione,
            id_anag_versione,
            id_anag_provincia
        )
        NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_informatori;

    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE fl_lookup_ateco_ko),
        COUNT(*) FILTER (WHERE fl_lookup_periodo_ko),
        COUNT(*) FILTER (WHERE fl_lookup_provincia_ko),
        COUNT(*) FILTER (WHERE fl_lookup_versione_ko)
    INTO
        v_selected,
        v_lookup_ateco_ko,
        v_lookup_periodo_ko,
        v_lookup_provincia_ko,
        v_lookup_versione_ko
    FROM hcbi_ras.tmp_dim_informatori;

    v_rec_errors :=
        v_lookup_ateco_ko
        + v_lookup_periodo_ko
        + v_lookup_provincia_ko
        + v_lookup_versione_ko;

    IF v_lookup_ateco_ko > 0 THEN
        RAISE WARNING
            'DIM_INFORMATORI: % lookup ATECO 2002 non risolte; applicato id_anag_ateco_2002=-1.',
            v_lookup_ateco_ko;
    END IF;

    IF v_lookup_periodo_ko > 0 THEN
        RAISE WARNING
            'DIM_INFORMATORI: % lookup periodo non risolte; applicato id_periodo_pubblicazione=-1.',
            v_lookup_periodo_ko;
    END IF;

    IF v_lookup_provincia_ko > 0 THEN
        RAISE WARNING
            'DIM_INFORMATORI: % lookup provincia non risolte; applicato id_anag_provincia=-1.',
            v_lookup_provincia_ko;
    END IF;

    IF v_lookup_versione_ko > 0 THEN
        RAISE WARNING
            'DIM_INFORMATORI: % lookup versione non risolte; applicato id_anag_versione=-1.',
            v_lookup_versione_ko;
    END IF;

    UPDATE hcbi_ras.dim_informatori AS d
       SET id_sorgente_informatore = src.id_sorgente_informatore,
           ds_ragione_sociale = src.ds_ragione_sociale,
           cd_p_iva = src.cd_p_iva,
           id_anag_ateco_2002 = src.id_anag_ateco_2002,
           ds_indirizzo_sede_legale = src.ds_indirizzo_sede_legale,
           cd_cap_sede_legale = src.cd_cap_sede_legale,
           ds_citta_sede_legale = src.ds_citta_sede_legale,
           cd_provincia_sede_legale = src.cd_provincia_sede_legale,
           ds_indirizzo_sede_operativa = src.ds_indirizzo_sede_operativa,
           cd_cap_sede_operativa = src.cd_cap_sede_operativa,
           ds_citta_sede_operativa = src.ds_citta_sede_operativa,
           cd_provincia_sede_operativa = src.cd_provincia_sede_operativa,
           ds_contatti = src.ds_contatti,
           cd_stato = src.cd_stato,
           ds_note = src.ds_note,
           ds_stato_attivita = src.ds_stato_attivita,
           cd_codice_fiscale = src.cd_codice_fiscale,
           id_periodo_pubblicazione = src.id_periodo_pubblicazione,
           dt_last_update = src.dt_last_update,
           ds_nazione = src.ds_nazione,
           id_anag_versione = src.id_anag_versione,
           id_anag_provincia = src.id_anag_provincia,
           fl_escludi_invio_mail_assoc_listino_completa =
               src.fl_escludi_invio_mail_assoc_listino_completa,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_informatori AS src
     WHERE d.id_anag_informatore = src.id_anag_informatore
       AND ROW(
            d.id_sorgente_informatore,
            d.ds_ragione_sociale,
            d.cd_p_iva,
            d.id_anag_ateco_2002,
            d.ds_indirizzo_sede_legale,
            d.cd_cap_sede_legale,
            d.ds_citta_sede_legale,
            d.cd_provincia_sede_legale,
            d.ds_indirizzo_sede_operativa,
            d.cd_cap_sede_operativa,
            d.ds_citta_sede_operativa,
            d.cd_provincia_sede_operativa,
            d.ds_contatti,
            d.cd_stato,
            d.ds_note,
            d.ds_stato_attivita,
            d.cd_codice_fiscale,
            d.id_periodo_pubblicazione,
            d.dt_last_update,
            d.ds_nazione,
            d.id_anag_versione,
            d.id_anag_provincia,
            d.fl_escludi_invio_mail_assoc_listino_completa
       ) IS DISTINCT FROM ROW(
            src.id_sorgente_informatore,
            src.ds_ragione_sociale,
            src.cd_p_iva,
            src.id_anag_ateco_2002,
            src.ds_indirizzo_sede_legale,
            src.cd_cap_sede_legale,
            src.ds_citta_sede_legale,
            src.cd_provincia_sede_legale,
            src.ds_indirizzo_sede_operativa,
            src.cd_cap_sede_operativa,
            src.ds_citta_sede_operativa,
            src.cd_provincia_sede_operativa,
            src.ds_contatti,
            src.cd_stato,
            src.ds_note,
            src.ds_stato_attivita,
            src.cd_codice_fiscale,
            src.id_periodo_pubblicazione,
            src.dt_last_update,
            src.ds_nazione,
            src.id_anag_versione,
            src.id_anag_provincia,
            src.fl_escludi_invio_mail_assoc_listino_completa
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_informatori
    (
        id_anag_informatore,
        id_sorgente_informatore,
        ds_ragione_sociale,
        cd_p_iva,
        id_anag_ateco_2002,
        ds_indirizzo_sede_legale,
        cd_cap_sede_legale,
        ds_citta_sede_legale,
        cd_provincia_sede_legale,
        ds_indirizzo_sede_operativa,
        cd_cap_sede_operativa,
        ds_citta_sede_operativa,
        cd_provincia_sede_operativa,
        ds_contatti,
        cd_stato,
        ds_note,
        ds_stato_attivita,
        cd_codice_fiscale,
        id_periodo_pubblicazione,
        dt_last_update,
        ds_nazione,
        id_anag_versione,
        id_anag_provincia,
        fl_escludi_invio_mail_assoc_listino_completa,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_anag_informatore,
        src.id_sorgente_informatore,
        src.ds_ragione_sociale,
        src.cd_p_iva,
        src.id_anag_ateco_2002,
        src.ds_indirizzo_sede_legale,
        src.cd_cap_sede_legale,
        src.ds_citta_sede_legale,
        src.cd_provincia_sede_legale,
        src.ds_indirizzo_sede_operativa,
        src.cd_cap_sede_operativa,
        src.ds_citta_sede_operativa,
        src.cd_provincia_sede_operativa,
        src.ds_contatti,
        src.cd_stato,
        src.ds_note,
        src.ds_stato_attivita,
        src.cd_codice_fiscale,
        src.id_periodo_pubblicazione,
        src.dt_last_update,
        src.ds_nazione,
        src.id_anag_versione,
        src.id_anag_provincia,
        src.fl_escludi_invio_mail_assoc_listino_completa,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dim_informatori AS src
    ON CONFLICT ON CONSTRAINT pk_dim_informatori DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    SELECT COUNT(*)
    INTO v_matched
    FROM hcbi_ras.dim_informatori AS d
    INNER JOIN hcbi_ras.tmp_dim_informatori AS src
        ON src.id_anag_informatore = d.id_anag_informatore;

    IF v_selected <> v_matched THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = FORMAT(
                'Riconciliazione DIM_INFORMATORI non valida: selected=%s, matched=%s',
                v_selected,
                v_matched
            ),
            DETAIL = 'Non tutte le chiavi DWH risultano presenti nella dimensione.';
    END IF;

    IF v_selected <> (
        SELECT COUNT(*) FROM hcbi_ras.dwh_anag_informatori
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Riconciliazione sorgente DIM_INFORMATORI non valida';
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_informatori;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dim_informatori;
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
            'Errore in pkg_dim_informatori_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$procedure$
