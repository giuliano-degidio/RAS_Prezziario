CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_pubblicazione_articoli_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_articoli_classificata;
    CREATE TABLE hcbi_ras.tmp_pubblicazione_articoli_classificata AS
    WITH src AS MATERIALIZED (
        SELECT
            f.id_sorgente_provincia AS id_sorgente_provincia_raw,
            f.ds_anno_pubblicazione AS ds_anno_pubblicazione_raw,
            f.cd_codice_completo AS cd_codice_completo_raw,
            f.cd_unita_misura AS cd_unita_misura_raw,
            f.nr_prezzo AS nr_prezzo_raw,
            f.nr_prezzo_annuo AS nr_prezzo_annuo_raw,
            f.nr_perc_spese AS nr_perc_spese_raw,
            f.nr_perc_utile AS nr_perc_utile_raw,
            f.nr_sicur AS nr_sicur_raw,
            f.nr_perc_manodopera AS nr_perc_manodopera_raw,
            f.nr_perc_oneri AS nr_perc_oneri_raw,
            f.fl_isanalisi AS fl_isanalisi_raw,
            f.nr_prezzo_manodopera AS nr_prezzo_manodopera_raw,
            f.cd_versione AS cd_versione_raw,
            f.cd_articolo AS cd_articolo_raw,
            f.cd_titolo AS cd_titolo_raw,
            f.cd_capitolo AS cd_capitolo_raw,
            f.cd_sottocapitolo AS cd_sottocapitolo_raw,
            f.cd_categoria_articolo AS cd_categoria_articolo_raw,
            f.cd_subarticolo AS cd_subarticolo_raw,
            f.ds_unita_misura_de AS ds_unita_misura_de_raw,
            f.id_sorgente_categoria AS id_sorgente_categoria_raw,
            f.fl_is_minuteria AS fl_is_minuteria_raw,
            f.id_sorgente_pubblicazione_articoli AS id_sorgente_pubblicazione_articoli_raw,
            f.nr_perc_manodopera_dir AS nr_perc_manodopera_dir_raw,
            f.nr_prezzo_manodopera_dir AS nr_prezzo_manodopera_dir_raw,
            f.fl_ifc_scaricabile AS fl_ifc_scaricabile_raw,
            f.nr_macro_gruppo AS nr_macro_gruppo_raw,
            f.nr_spese AS nr_spese_raw,
            f.nr_utili AS nr_utili_raw,
            NULLIF(btrim(f.id_sorgente_provincia), '') AS id_sorgente_provincia_txt,
            NULLIF(btrim(f.ds_anno_pubblicazione), '') AS ds_anno_pubblicazione_txt,
            NULLIF(btrim(f.cd_codice_completo), '') AS cd_codice_completo_txt,
            NULLIF(btrim(f.cd_unita_misura), '') AS cd_unita_misura_txt,
            NULLIF(btrim(f.nr_prezzo), '') AS nr_prezzo_txt,
            NULLIF(btrim(f.nr_prezzo_annuo), '') AS nr_prezzo_annuo_txt,
            NULLIF(btrim(f.nr_perc_spese), '') AS nr_perc_spese_txt,
            NULLIF(btrim(f.nr_perc_utile), '') AS nr_perc_utile_txt,
            NULLIF(btrim(f.nr_sicur), '') AS nr_sicur_txt,
            NULLIF(btrim(f.nr_perc_manodopera), '') AS nr_perc_manodopera_txt,
            NULLIF(btrim(f.nr_perc_oneri), '') AS nr_perc_oneri_txt,
            NULLIF(btrim(f.fl_isanalisi), '') AS fl_isanalisi_txt,
            NULLIF(btrim(f.nr_prezzo_manodopera), '') AS nr_prezzo_manodopera_txt,
            NULLIF(btrim(f.cd_versione), '') AS cd_versione_txt,
            NULLIF(btrim(f.cd_articolo), '') AS cd_articolo_txt,
            NULLIF(btrim(f.cd_titolo), '') AS cd_titolo_txt,
            NULLIF(btrim(f.cd_capitolo), '') AS cd_capitolo_txt,
            NULLIF(btrim(f.cd_sottocapitolo), '') AS cd_sottocapitolo_txt,
            NULLIF(btrim(f.cd_categoria_articolo), '') AS cd_categoria_articolo_txt,
            NULLIF(btrim(f.cd_subarticolo), '') AS cd_subarticolo_txt,
            NULLIF(btrim(f.ds_unita_misura_de), '') AS ds_unita_misura_de_txt,
            NULLIF(btrim(f.id_sorgente_categoria), '') AS id_sorgente_categoria_txt,
            NULLIF(btrim(f.fl_is_minuteria), '') AS fl_is_minuteria_txt,
            NULLIF(btrim(f.id_sorgente_pubblicazione_articoli), '') AS id_sorgente_pubblicazione_articoli_txt,
            NULLIF(btrim(f.nr_perc_manodopera_dir), '') AS nr_perc_manodopera_dir_txt,
            NULLIF(btrim(f.nr_prezzo_manodopera_dir), '') AS nr_prezzo_manodopera_dir_txt,
            NULLIF(btrim(f.fl_ifc_scaricabile), '') AS fl_ifc_scaricabile_txt,
            NULLIF(btrim(f.nr_macro_gruppo), '') AS nr_macro_gruppo_txt,
            NULLIF(btrim(f.nr_spese), '') AS nr_spese_txt,
            NULLIF(btrim(f.nr_utili), '') AS nr_utili_txt
        FROM hcbi_ras.v_src_tmp_pubblicazione_articoli AS f

    ), converted AS MATERIALIZED (
        SELECT s.*,
            hcbi_ras.try_numeric_10_0(s.id_sorgente_provincia_txt) AS id_sorgente_provincia_cv,
            hcbi_ras.try_numeric_10_0(s.ds_anno_pubblicazione_txt) AS ds_anno_pubblicazione_cv,
            s.cd_codice_completo_txt AS cd_codice_completo_cv,
            s.cd_unita_misura_txt AS cd_unita_misura_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_prezzo_txt, ',', '.')) AS nr_prezzo_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_prezzo_annuo_txt, ',', '.')) AS nr_prezzo_annuo_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_perc_spese_txt, ',', '.')) AS nr_perc_spese_cv,
            hcbi_ras.try_numeric_10_5(replace(s.nr_perc_utile_txt, ',', '.')) AS nr_perc_utile_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_sicur_txt, ',', '.')) AS nr_sicur_cv,
            hcbi_ras.try_numeric_10_5(replace(s.nr_perc_manodopera_txt, ',', '.')) AS nr_perc_manodopera_cv,
            hcbi_ras.try_numeric_10_5(replace(s.nr_perc_oneri_txt, ',', '.')) AS nr_perc_oneri_cv,
            hcbi_ras.try_smallint(s.fl_isanalisi_txt) AS fl_isanalisi_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_prezzo_manodopera_txt, ',', '.')) AS nr_prezzo_manodopera_cv,
            hcbi_ras.try_smallint(s.cd_versione_txt) AS cd_versione_cv,
            s.cd_articolo_txt AS cd_articolo_cv,
            s.cd_titolo_txt AS cd_titolo_cv,
            s.cd_capitolo_txt AS cd_capitolo_cv,
            s.cd_sottocapitolo_txt AS cd_sottocapitolo_cv,
            s.cd_categoria_articolo_txt AS cd_categoria_articolo_cv,
            s.cd_subarticolo_txt AS cd_subarticolo_cv,
            s.ds_unita_misura_de_txt AS ds_unita_misura_de_cv,
            hcbi_ras.try_bigint(s.id_sorgente_categoria_txt) AS id_sorgente_categoria_cv,
            hcbi_ras.try_smallint(s.fl_is_minuteria_txt) AS fl_is_minuteria_cv,
            hcbi_ras.try_bigint(s.id_sorgente_pubblicazione_articoli_txt) AS id_sorgente_pubblicazione_articoli_cv,
            hcbi_ras.try_numeric_10_5(replace(s.nr_perc_manodopera_dir_txt, ',', '.')) AS nr_perc_manodopera_dir_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_prezzo_manodopera_dir_txt, ',', '.')) AS nr_prezzo_manodopera_dir_cv,
            hcbi_ras.try_smallint(s.fl_ifc_scaricabile_txt) AS fl_ifc_scaricabile_cv,
            hcbi_ras.try_integer(s.nr_macro_gruppo_txt) AS nr_macro_gruppo_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_spese_txt, ',', '.')) AS nr_spese_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_utili_txt, ',', '.')) AS nr_utili_cv
        FROM src AS s
    ), classified AS MATERIALIZED (
        SELECT c.*,
            count(*) OVER (
                PARTITION BY c.id_sorgente_provincia_cv,
                             c.ds_anno_pubblicazione_cv,
                             c.cd_codice_completo_cv,
                             c.cd_versione_cv
            ) AS duplicate_count
        FROM converted AS c
    )
    SELECT c.*,
        CASE
            WHEN c.duplicate_count > 1 THEN 'Chiave duplicata dopo trim/conversione: (id_sorgente_provincia, ds_anno_pubblicazione, cd_codice_completo, cd_versione)'
            WHEN c.id_sorgente_provincia_txt IS NULL THEN 'id_sorgente_provincia obbligatorio'
            WHEN c.id_sorgente_provincia_cv IS NULL THEN 'id_sorgente_provincia non convertibile in numeric(10,0)'
            WHEN c.ds_anno_pubblicazione_txt IS NULL THEN 'ds_anno_pubblicazione obbligatorio'
            WHEN c.ds_anno_pubblicazione_cv IS NULL THEN 'ds_anno_pubblicazione non convertibile in numeric(10,0)'
            WHEN c.cd_codice_completo_txt IS NULL THEN 'cd_codice_completo obbligatorio'
            WHEN c.cd_versione_txt IS NULL THEN 'cd_versione obbligatorio'
            WHEN c.cd_versione_cv IS NULL THEN 'cd_versione non convertibile in smallint'
            WHEN c.cd_articolo_txt IS NULL THEN 'cd_articolo obbligatorio'
            WHEN c.nr_prezzo_txt IS NOT NULL AND c.nr_prezzo_cv IS NULL THEN 'nr_prezzo non convertibile' 
            WHEN c.nr_prezzo_annuo_txt IS NOT NULL AND c.nr_prezzo_annuo_cv IS NULL THEN 'nr_prezzo_annuo non convertibile' 
            WHEN c.nr_perc_spese_txt IS NOT NULL AND c.nr_perc_spese_cv IS NULL THEN 'nr_perc_spese non convertibile' 
            WHEN c.nr_perc_utile_txt IS NOT NULL AND c.nr_perc_utile_cv IS NULL THEN 'nr_perc_utile non convertibile' 
            WHEN c.nr_sicur_txt IS NOT NULL AND c.nr_sicur_cv IS NULL THEN 'nr_sicur non convertibile' 
            WHEN c.nr_perc_manodopera_txt IS NOT NULL AND c.nr_perc_manodopera_cv IS NULL THEN 'nr_perc_manodopera non convertibile' 
            WHEN c.nr_perc_oneri_txt IS NOT NULL AND c.nr_perc_oneri_cv IS NULL THEN 'nr_perc_oneri non convertibile' 
            WHEN c.fl_isanalisi_txt IS NOT NULL AND c.fl_isanalisi_cv IS NULL THEN 'fl_isanalisi non convertibile' 
            WHEN c.nr_prezzo_manodopera_txt IS NOT NULL AND c.nr_prezzo_manodopera_cv IS NULL THEN 'nr_prezzo_manodopera non convertibile' 
            WHEN c.id_sorgente_categoria_txt IS NOT NULL AND c.id_sorgente_categoria_cv IS NULL THEN 'id_sorgente_categoria non convertibile' 
            WHEN c.fl_is_minuteria_txt IS NOT NULL AND c.fl_is_minuteria_cv IS NULL THEN 'fl_is_minuteria non convertibile' 
            WHEN c.id_sorgente_pubblicazione_articoli_txt IS NOT NULL AND c.id_sorgente_pubblicazione_articoli_cv IS NULL THEN 'id_sorgente_pubblicazione_articoli non convertibile' 
            WHEN c.nr_perc_manodopera_dir_txt IS NOT NULL AND c.nr_perc_manodopera_dir_cv IS NULL THEN 'nr_perc_manodopera_dir non convertibile' 
            WHEN c.nr_prezzo_manodopera_dir_txt IS NOT NULL AND c.nr_prezzo_manodopera_dir_cv IS NULL THEN 'nr_prezzo_manodopera_dir non convertibile' 
            WHEN c.fl_ifc_scaricabile_txt IS NOT NULL AND c.fl_ifc_scaricabile_cv IS NULL THEN 'fl_ifc_scaricabile non convertibile' 
            WHEN c.nr_macro_gruppo_txt IS NOT NULL AND c.nr_macro_gruppo_cv IS NULL THEN 'nr_macro_gruppo non convertibile' 
            WHEN c.nr_spese_txt IS NOT NULL AND c.nr_spese_cv IS NULL THEN 'nr_spese non convertibile' 
            WHEN c.nr_utili_txt IS NOT NULL AND c.nr_utili_cv IS NULL THEN 'nr_utili non convertibile' 
            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM classified AS c;

    SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_pubblicazione_articoli_classificata;

    INSERT INTO hcbi_ras.stg_pubblicazione_articoli (
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
        nr_utili
    )
    SELECT
        t.id_sorgente_provincia_cv,
        t.ds_anno_pubblicazione_cv,
        t.cd_codice_completo_cv,
        t.cd_unita_misura_cv,
        t.nr_prezzo_cv,
        t.nr_prezzo_annuo_cv,
        t.nr_perc_spese_cv,
        t.nr_perc_utile_cv,
        t.nr_sicur_cv,
        t.nr_perc_manodopera_cv,
        t.nr_perc_oneri_cv,
        t.fl_isanalisi_cv,
        t.nr_prezzo_manodopera_cv,
        t.cd_versione_cv,
        t.cd_articolo_cv,
        t.cd_titolo_cv,
        t.cd_capitolo_cv,
        t.cd_sottocapitolo_cv,
        t.cd_categoria_articolo_cv,
        t.cd_subarticolo_cv,
        t.ds_unita_misura_de_cv,
        t.id_sorgente_categoria_cv,
        t.fl_is_minuteria_cv,
        t.id_sorgente_pubblicazione_articoli_cv,
        t.nr_perc_manodopera_dir_cv,
        t.nr_prezzo_manodopera_dir_cv,
        t.fl_ifc_scaricabile_cv,
        t.nr_macro_gruppo_cv,
        t.nr_spese_cv,
        t.nr_utili_cv
    FROM hcbi_ras.tmp_pubblicazione_articoli_classificata AS t
    WHERE t.tx_motivo_scarto IS NULL;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_pubblicazione_articoli_rej (
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
        tx_motivo_scarto
    )
    SELECT
        t.id_sorgente_provincia_raw,
        t.ds_anno_pubblicazione_raw,
        t.cd_codice_completo_raw,
        t.cd_unita_misura_raw,
        t.nr_prezzo_raw,
        t.nr_prezzo_annuo_raw,
        t.nr_perc_spese_raw,
        t.nr_perc_utile_raw,
        t.nr_sicur_raw,
        t.nr_perc_manodopera_raw,
        t.nr_perc_oneri_raw,
        t.fl_isanalisi_raw,
        t.nr_prezzo_manodopera_raw,
        t.cd_versione_raw,
        t.cd_articolo_raw,
        t.cd_titolo_raw,
        t.cd_capitolo_raw,
        t.cd_sottocapitolo_raw,
        t.cd_categoria_articolo_raw,
        t.cd_subarticolo_raw,
        t.ds_unita_misura_de_raw,
        t.id_sorgente_categoria_raw,
        t.fl_is_minuteria_raw,
        t.id_sorgente_pubblicazione_articoli_raw,
        t.nr_perc_manodopera_dir_raw,
        t.nr_prezzo_manodopera_dir_raw,
        t.fl_ifc_scaricabile_raw,
        t.nr_macro_gruppo_raw,
        t.nr_spese_raw,
        t.nr_utili_raw,
        t.tx_motivo_scarto
    FROM hcbi_ras.tmp_pubblicazione_articoli_classificata AS t
    WHERE t.tx_motivo_scarto IS NOT NULL;
    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE=format('Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',v_selected,v_inserted,v_rec_errors),
            DETAIL='Il numero di record letti non coincide con caricati e scartati.',
            HINT='Verificare classificazione e INSERT verso STG e REJ.';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_articoli_classificata;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_pubblicazione_articoli_classificata;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore durante la pulizia della tabella di lavoro: SQLSTATE=%, errore=%', SQLSTATE, SQLERRM;
        END;
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

        RAISE WARNING 'Errore in pkg_stg_pubblicazione_articoli_prc_main. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;


END;
$procedure$
