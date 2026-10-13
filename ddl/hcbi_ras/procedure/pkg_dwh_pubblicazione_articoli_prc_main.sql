CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_pubblicazione_articoli_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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

        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name

    ) INTO v_id_log;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.v_dwh_pubblicazione_articoli
        GROUP BY id_sorgente_provincia,ds_anno_pubblicazione,cd_codice_completo,cd_versione
        HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='Business key duplicata in HCBI_RAS.V_DWH_PUBBLICAZIONE_ARTICOLI';
    END IF;
    SELECT count(*) INTO v_selected FROM hcbi_ras.v_dwh_pubblicazione_articoli;

    UPDATE hcbi_ras.dwh_pubblicazione_articoli AS dwh
       SET cd_unita_misura=src.cd_unita_misura,
           nr_prezzo=src.nr_prezzo,
           nr_prezzo_annuo=src.nr_prezzo_annuo,
           nr_perc_spese=src.nr_perc_spese,
           nr_perc_utile=src.nr_perc_utile,
           nr_sicur=src.nr_sicur,
           nr_perc_manodopera=src.nr_perc_manodopera,
           nr_perc_oneri=src.nr_perc_oneri,
           fl_isanalisi=src.fl_isanalisi,
           nr_prezzo_manodopera=src.nr_prezzo_manodopera,
           cd_articolo=src.cd_articolo,
           cd_titolo=src.cd_titolo,
           cd_capitolo=src.cd_capitolo,
           cd_sottocapitolo=src.cd_sottocapitolo,
           cd_categoria_articolo=src.cd_categoria_articolo,
           cd_subarticolo=src.cd_subarticolo,
           ds_unita_misura_de=src.ds_unita_misura_de,
           id_sorgente_categoria=src.id_sorgente_categoria,
           fl_is_minuteria=src.fl_is_minuteria,
           id_sorgente_pubblicazione_articoli=src.id_sorgente_pubblicazione_articoli,
           nr_perc_manodopera_dir=src.nr_perc_manodopera_dir,
           nr_prezzo_manodopera_dir=src.nr_prezzo_manodopera_dir,
           fl_ifc_scaricabile=src.fl_ifc_scaricabile,
           nr_macro_gruppo=src.nr_macro_gruppo,
           nr_spese=src.nr_spese,
           nr_utili=src.nr_utili,
           dt_update=clock_timestamp(),
           tx_update_by=p_ds_step_name
      FROM hcbi_ras.v_dwh_pubblicazione_articoli AS src
     WHERE dwh.id_sorgente_provincia = src.id_sorgente_provincia
       AND dwh.ds_anno_pubblicazione = src.ds_anno_pubblicazione
       AND dwh.cd_codice_completo= src.cd_codice_completo
       AND dwh.cd_versione = src.cd_versione
       AND ROW(dwh.cd_unita_misura, dwh.nr_prezzo, dwh.nr_prezzo_annuo, dwh.nr_perc_spese, dwh.nr_perc_utile, dwh.nr_sicur, dwh.nr_perc_manodopera, dwh.nr_perc_oneri, dwh.fl_isanalisi, dwh.nr_prezzo_manodopera, dwh.cd_articolo, dwh.cd_titolo, dwh.cd_capitolo, dwh.cd_sottocapitolo, dwh.cd_categoria_articolo, dwh.cd_subarticolo, dwh.ds_unita_misura_de, dwh.id_sorgente_categoria, dwh.fl_is_minuteria, dwh.id_sorgente_pubblicazione_articoli, dwh.nr_perc_manodopera_dir, dwh.nr_prezzo_manodopera_dir, dwh.fl_ifc_scaricabile, dwh.nr_macro_gruppo, dwh.nr_spese, dwh.nr_utili) IS DISTINCT FROM ROW(src.cd_unita_misura, src.nr_prezzo, src.nr_prezzo_annuo, src.nr_perc_spese, src.nr_perc_utile, src.nr_sicur, src.nr_perc_manodopera, src.nr_perc_oneri, src.fl_isanalisi, src.nr_prezzo_manodopera, src.cd_articolo, src.cd_titolo, src.cd_capitolo, src.cd_sottocapitolo, src.cd_categoria_articolo, src.cd_subarticolo, src.ds_unita_misura_de, src.id_sorgente_categoria, src.fl_is_minuteria, src.id_sorgente_pubblicazione_articoli, src.nr_perc_manodopera_dir, src.nr_prezzo_manodopera_dir, src.fl_ifc_scaricabile, src.nr_macro_gruppo, src.nr_spese, src.nr_utili);

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_pubblicazione_articoli (
        id_sorgente_provincia,
        ds_anno_pubblicazione,
        cd_codice_completo,
        cd_unita_misura,
        nr_prezzo,
        nr_prezzo_annuo,
        nr_perc_spese,
        nr_perc_utile,
        nr_sicur,
        nr_perc_manodopera,
        nr_perc_oneri,
        fl_isanalisi,
        nr_prezzo_manodopera,
        cd_versione,
        cd_articolo,
        cd_titolo,
        cd_capitolo,
        cd_sottocapitolo,
        cd_categoria_articolo,
        cd_subarticolo,
        ds_unita_misura_de,
        id_sorgente_categoria,
        fl_is_minuteria,
        id_sorgente_pubblicazione_articoli,
        nr_perc_manodopera_dir,
        nr_prezzo_manodopera_dir,
        fl_ifc_scaricabile,
        nr_macro_gruppo,
        nr_spese,
        nr_utili,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_sorgente_provincia,
        src.ds_anno_pubblicazione,
        src.cd_codice_completo,
        src.cd_unita_misura,
        src.nr_prezzo,
        src.nr_prezzo_annuo,
        src.nr_perc_spese,
        src.nr_perc_utile,
        src.nr_sicur,
        src.nr_perc_manodopera,
        src.nr_perc_oneri,
        src.fl_isanalisi,
        src.nr_prezzo_manodopera,
        src.cd_versione,
        src.cd_articolo,
        src.cd_titolo,
        src.cd_capitolo,
        src.cd_sottocapitolo,
        src.cd_categoria_articolo,
        src.cd_subarticolo,
        src.ds_unita_misura_de,
        src.id_sorgente_categoria,
        src.fl_is_minuteria,
        src.id_sorgente_pubblicazione_articoli,
        src.nr_perc_manodopera_dir,
        src.nr_prezzo_manodopera_dir,
        src.fl_ifc_scaricabile,
        src.nr_macro_gruppo,
        src.nr_spese,
        src.nr_utili,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.v_dwh_pubblicazione_articoli AS src
    ON CONFLICT (id_sorgente_provincia,ds_anno_pubblicazione,cd_codice_completo,cd_versione) DO NOTHING;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;
    IF v_selected <> (
        SELECT count(*)
        FROM hcbi_ras.v_dwh_pubblicazione_articoli src
        JOIN hcbi_ras.dwh_pubblicazione_articoli dwh
          ON dwh.id_sorgente_provincia=src.id_sorgente_provincia
         AND dwh.ds_anno_pubblicazione=src.ds_anno_pubblicazione
         AND dwh.cd_codice_completo=src.cd_codice_completo
         AND dwh.cd_versione=src.cd_versione
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='Riconciliazione DWH_PUBBLICAZIONE_ARTICOLI non valida';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name
    );

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

        v_log_error := left(concat_ws(E'\n',
            'SQLSTATE=' || coalesce(v_sqlstate, ''),
            'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
            CASE WHEN nullif(v_sql_detail, '') IS NOT NULL THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
            CASE WHEN nullif(v_sql_hint, '') IS NOT NULL THEN 'HINT=' || left(v_sql_hint, 500) END,
            CASE WHEN nullif(v_sql_context, '') IS NOT NULL THEN 'CONTEXT=' || left(v_sql_context, 800) END
        ), 4000);
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(

                    v_id_log, 'FAILED', v_log_error,
                    clock_timestamp()::timestamp, p_ds_step_name

                );
            EXCEPTION WHEN OTHERS THEN

                RAISE WARNING 'Errore durante la registrazione del log di errore: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;

            END;
        END IF;

        RAISE WARNING 'Errore in pkg_dwh_pubblicazione_articoli_prc_main. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;

END;
$procedure$
