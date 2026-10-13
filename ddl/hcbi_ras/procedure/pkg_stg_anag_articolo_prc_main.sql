CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_articolo_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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
    v_ts_start timestamp;
BEGIN
    p_result := -1;
    v_ts_start := clock_timestamp()::timestamp;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        v_ts_start, v_ts_start, p_ds_step_name
    ) INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_articolo_classificata;
    CREATE TABLE hcbi_ras.tmp_anag_articolo_classificata AS
    WITH src AS MATERIALIZED (
        SELECT
            f.id_sorgente_articolo AS id_sorgente_articolo_raw,
            f.ds_anno AS ds_anno_raw,
            f.cd_articolo AS cd_articolo_raw,
            f.nr_livello AS nr_livello_raw,
            f.ds_nome AS ds_nome_raw,
            f.ds_descrizione AS ds_descrizione_raw,
            f.fl_eliminato AS fl_eliminato_raw,
            f.fl_prezzo_regionale AS fl_prezzo_regionale_raw,
            f.ds_unita_misura AS ds_unita_misura_raw,
            f.nr_macro_gruppo AS nr_macro_gruppo_raw,
            f.nr_spese_generali AS nr_spese_generali_raw,
            f.nr_di_cui_analisi AS nr_di_cui_analisi_raw,
            f.nr_utile_impresa AS nr_utile_impresa_raw,
            f.dt_last_update AS dt_last_update_raw,
            f.fl_analisi_approvata AS fl_analisi_approvata_raw,
            f.fl_has_utile_impresa AS fl_has_utile_impresa_raw,
            f.fl_analisi_pubblicata AS fl_analisi_pubblicata_raw,
            f.cd_versione AS cd_versione_raw,
            f.fl_is_analisi AS fl_is_analisi_raw,
            f.fl_is_cam AS fl_is_cam_raw,
            f.fl_is_ufficiale AS fl_is_ufficiale_raw,
            f.id_sorgente_categoria AS id_sorgente_categoria_raw,
            f.fl_is_manodopera AS fl_is_manodopera_raw,
            f.cd_codice_lev1 AS cd_codice_lev1_raw,
            f.cd_codice_lev2 AS cd_codice_lev2_raw,
            f.cd_codice_lev3 AS cd_codice_lev3_raw,
            f.cd_codice_lev4 AS cd_codice_lev4_raw,
            f.cd_codice_lev5 AS cd_codice_lev5_raw,
            f.fl_is_minuteria AS fl_is_minuteria_raw,
            f.nr_percentuale_aumento AS nr_percentuale_aumento_raw,
            f.ds_annotazione AS ds_annotazione_raw,
            f.fl_esporta_come_articolo AS fl_esporta_come_articolo_raw,
            f.fl_escludi_manodopera AS fl_escludi_manodopera_raw,
            f.id_sorgente_provincia AS id_sorgente_provincia_raw,
            NULLIF(btrim(f.id_sorgente_articolo), '') AS id_sorgente_articolo_txt,
            NULLIF(btrim(f.ds_anno), '') AS ds_anno_txt,
            NULLIF(btrim(f.cd_articolo), '') AS cd_articolo_txt,
            NULLIF(btrim(f.nr_livello), '') AS nr_livello_txt,
            NULLIF(btrim(f.ds_nome), '') AS ds_nome_txt,
            NULLIF(btrim(f.ds_descrizione), '') AS ds_descrizione_txt,
            NULLIF(btrim(f.fl_eliminato), '') AS fl_eliminato_txt,
            NULLIF(btrim(f.fl_prezzo_regionale), '') AS fl_prezzo_regionale_txt,
            NULLIF(btrim(f.ds_unita_misura), '') AS ds_unita_misura_txt,
            NULLIF(btrim(f.nr_macro_gruppo), '') AS nr_macro_gruppo_txt,
            NULLIF(btrim(f.nr_spese_generali), '') AS nr_spese_generali_txt,
            NULLIF(btrim(f.nr_di_cui_analisi), '') AS nr_di_cui_analisi_txt,
            NULLIF(btrim(f.nr_utile_impresa), '') AS nr_utile_impresa_txt,
            NULLIF(btrim(f.fl_analisi_approvata), '') AS fl_analisi_approvata_txt,
            NULLIF(btrim(f.fl_has_utile_impresa), '') AS fl_has_utile_impresa_txt,
            NULLIF(btrim(f.fl_analisi_pubblicata), '') AS fl_analisi_pubblicata_txt,
            NULLIF(btrim(f.cd_versione), '') AS cd_versione_txt,
            NULLIF(btrim(f.fl_is_analisi), '') AS fl_is_analisi_txt,
            NULLIF(btrim(f.fl_is_cam), '') AS fl_is_cam_txt,
            NULLIF(btrim(f.fl_is_ufficiale), '') AS fl_is_ufficiale_txt,
            NULLIF(btrim(f.id_sorgente_categoria), '') AS id_sorgente_categoria_txt,
            NULLIF(btrim(f.fl_is_manodopera), '') AS fl_is_manodopera_txt,
            NULLIF(btrim(f.cd_codice_lev1), '') AS cd_codice_lev1_txt,
            NULLIF(btrim(f.cd_codice_lev2), '') AS cd_codice_lev2_txt,
            NULLIF(btrim(f.cd_codice_lev3), '') AS cd_codice_lev3_txt,
            NULLIF(btrim(f.cd_codice_lev4), '') AS cd_codice_lev4_txt,
            NULLIF(btrim(f.cd_codice_lev5), '') AS cd_codice_lev5_txt,
            NULLIF(btrim(f.fl_is_minuteria), '') AS fl_is_minuteria_txt,
            NULLIF(btrim(f.nr_percentuale_aumento), '') AS nr_percentuale_aumento_txt,
            NULLIF(btrim(f.ds_annotazione), '') AS ds_annotazione_txt,
            NULLIF(btrim(f.fl_esporta_come_articolo), '') AS fl_esporta_come_articolo_txt,
            NULLIF(btrim(f.fl_escludi_manodopera), '') AS fl_escludi_manodopera_txt,
            NULLIF(btrim(f.id_sorgente_provincia), '') AS id_sorgente_provincia_txt,
            count(*) OVER (
                PARTITION BY f.ds_anno, f.cd_articolo, f.cd_versione
            ) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_anag_articolo AS f
    ),
    converted AS MATERIALIZED (
        SELECT
            s.*,
            hcbi_ras.try_bigint(s.id_sorgente_articolo_txt) AS id_sorgente_articolo_cv,
            hcbi_ras.try_integer(s.ds_anno_txt) AS ds_anno_cv,
            s.cd_articolo_txt AS cd_articolo_cv,
            hcbi_ras.try_integer(s.nr_livello_txt) AS nr_livello_cv,
            s.ds_nome_txt AS ds_nome_cv,
            s.ds_descrizione_txt AS ds_descrizione_cv,
            hcbi_ras.try_smallint(s.fl_eliminato_txt) AS fl_eliminato_cv,
            hcbi_ras.try_smallint(s.fl_prezzo_regionale_txt) AS fl_prezzo_regionale_cv,
            hcbi_ras.try_integer(s.ds_unita_misura_txt) AS ds_unita_misura_cv,
            hcbi_ras.try_integer(s.nr_macro_gruppo_txt) AS nr_macro_gruppo_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_spese_generali_txt, ',', '.')) AS nr_spese_generali_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_di_cui_analisi_txt, ',', '.')) AS nr_di_cui_analisi_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_utile_impresa_txt, ',', '.')) AS nr_utile_impresa_cv,
            s.dt_last_update_raw AS dt_last_update_cv,
            hcbi_ras.try_smallint(s.fl_analisi_approvata_txt) AS fl_analisi_approvata_cv,
            hcbi_ras.try_smallint(s.fl_has_utile_impresa_txt) AS fl_has_utile_impresa_cv,
            hcbi_ras.try_smallint(s.fl_analisi_pubblicata_txt) AS fl_analisi_pubblicata_cv,
            hcbi_ras.try_smallint(s.cd_versione_txt) AS cd_versione_cv,
            hcbi_ras.try_smallint(s.fl_is_analisi_txt) AS fl_is_analisi_cv,
            hcbi_ras.try_smallint(s.fl_is_cam_txt) AS fl_is_cam_cv,
            hcbi_ras.try_smallint(s.fl_is_ufficiale_txt) AS fl_is_ufficiale_cv,
            hcbi_ras.try_bigint(s.id_sorgente_categoria_txt) AS id_sorgente_categoria_cv,
            hcbi_ras.try_smallint(s.fl_is_manodopera_txt) AS fl_is_manodopera_cv,
            s.cd_codice_lev1_txt AS cd_codice_lev1_cv,
            s.cd_codice_lev2_txt AS cd_codice_lev2_cv,
            s.cd_codice_lev3_txt AS cd_codice_lev3_cv,
            s.cd_codice_lev4_txt AS cd_codice_lev4_cv,
            s.cd_codice_lev5_txt AS cd_codice_lev5_cv,
            hcbi_ras.try_smallint(s.fl_is_minuteria_txt) AS fl_is_minuteria_cv,
            hcbi_ras.try_numeric_24_5(replace(s.nr_percentuale_aumento_txt, ',', '.')) AS nr_percentuale_aumento_cv,
            s.ds_annotazione_txt AS ds_annotazione_cv,
            hcbi_ras.try_boolean_smallint(s.fl_esporta_come_articolo_txt) AS fl_esporta_come_articolo_cv,
            hcbi_ras.try_boolean_smallint(s.fl_escludi_manodopera_txt) AS fl_escludi_manodopera_cv,
            coalesce(hcbi_ras.try_numeric_10_0(s.id_sorgente_provincia_txt), 0::numeric(10,0)) AS id_sorgente_provincia_cv
        FROM src AS s
    )
    SELECT
        c.*,
        CASE
            WHEN c.duplicate_count > 1 THEN 'Chiave duplicata nella sorgente: (ds_anno, cd_articolo, cd_versione)'
            WHEN c.id_sorgente_articolo_txt IS NULL THEN 'id_sorgente_articolo obbligatorio'
            WHEN c.id_sorgente_articolo_cv IS NULL THEN 'id_sorgente_articolo non convertibile o fuori dominio'
            WHEN c.ds_anno_txt IS NULL THEN 'ds_anno obbligatorio'
            WHEN c.ds_anno_cv IS NULL THEN 'ds_anno non convertibile o fuori dominio'
            WHEN c.cd_articolo_txt IS NULL THEN 'cd_articolo obbligatorio'
            WHEN c.nr_livello_txt IS NULL THEN 'nr_livello obbligatorio'
            WHEN c.nr_livello_cv IS NULL THEN 'nr_livello non convertibile o fuori dominio'
            WHEN c.ds_nome_txt IS NULL THEN 'ds_nome obbligatorio'
            WHEN c.ds_descrizione_txt IS NULL THEN 'ds_descrizione obbligatorio'
            WHEN c.fl_eliminato_txt IS NULL THEN 'fl_eliminato obbligatorio'
            WHEN c.fl_eliminato_cv IS NULL THEN 'fl_eliminato non convertibile o fuori dominio'
            WHEN c.fl_prezzo_regionale_txt IS NULL THEN 'fl_prezzo_regionale obbligatorio'
            WHEN c.fl_prezzo_regionale_cv IS NULL THEN 'fl_prezzo_regionale non convertibile o fuori dominio'
            WHEN c.dt_last_update_raw IS NULL THEN 'dt_last_update obbligatorio'
            WHEN c.fl_analisi_approvata_txt IS NULL THEN 'fl_analisi_approvata obbligatorio'
            WHEN c.fl_analisi_approvata_cv IS NULL THEN 'fl_analisi_approvata non convertibile o fuori dominio'
            WHEN c.fl_has_utile_impresa_txt IS NULL THEN 'fl_has_utile_impresa obbligatorio'
            WHEN c.fl_has_utile_impresa_cv IS NULL THEN 'fl_has_utile_impresa non convertibile o fuori dominio'
            WHEN c.fl_analisi_pubblicata_txt IS NULL THEN 'fl_analisi_pubblicata obbligatorio'
            WHEN c.fl_analisi_pubblicata_cv IS NULL THEN 'fl_analisi_pubblicata non convertibile o fuori dominio'
            WHEN c.cd_versione_txt IS NULL THEN 'cd_versione obbligatorio'
            WHEN c.cd_versione_cv IS NULL THEN 'cd_versione non convertibile o fuori dominio'
            WHEN c.fl_is_analisi_txt IS NULL THEN 'fl_is_analisi obbligatorio'
            WHEN c.fl_is_analisi_cv IS NULL THEN 'fl_is_analisi non convertibile o fuori dominio'
            WHEN c.fl_is_cam_txt IS NULL THEN 'fl_is_cam obbligatorio'
            WHEN c.fl_is_cam_cv IS NULL THEN 'fl_is_cam non convertibile o fuori dominio'
            WHEN c.fl_is_ufficiale_txt IS NULL THEN 'fl_is_ufficiale obbligatorio'
            WHEN c.fl_is_ufficiale_cv IS NULL THEN 'fl_is_ufficiale non convertibile o fuori dominio'
            WHEN c.fl_is_manodopera_txt IS NULL THEN 'fl_is_manodopera obbligatorio'
            WHEN c.fl_is_manodopera_cv IS NULL THEN 'fl_is_manodopera non convertibile o fuori dominio'
            WHEN c.fl_is_minuteria_txt IS NULL THEN 'fl_is_minuteria obbligatorio'
            WHEN c.fl_is_minuteria_cv IS NULL THEN 'fl_is_minuteria non convertibile o fuori dominio'
            WHEN c.fl_esporta_come_articolo_txt IS NULL THEN 'fl_esporta_come_articolo obbligatorio'
            WHEN c.fl_esporta_come_articolo_cv IS NULL THEN 'fl_esporta_come_articolo non convertibile o fuori dominio'
            WHEN c.fl_escludi_manodopera_txt IS NULL THEN 'fl_escludi_manodopera obbligatorio'
            WHEN c.fl_escludi_manodopera_cv IS NULL THEN 'fl_escludi_manodopera non convertibile o fuori dominio'
            WHEN c.ds_unita_misura_txt IS NOT NULL AND c.ds_unita_misura_cv IS NULL THEN 'ds_unita_misura non convertibile'
            WHEN c.nr_macro_gruppo_txt IS NOT NULL AND c.nr_macro_gruppo_cv IS NULL THEN 'nr_macro_gruppo non convertibile'
            WHEN c.nr_spese_generali_txt IS NOT NULL AND c.nr_spese_generali_cv IS NULL THEN 'nr_spese_generali non convertibile'
            WHEN c.nr_di_cui_analisi_txt IS NOT NULL AND c.nr_di_cui_analisi_cv IS NULL THEN 'nr_di_cui_analisi non convertibile'
            WHEN c.nr_utile_impresa_txt IS NOT NULL AND c.nr_utile_impresa_cv IS NULL THEN 'nr_utile_impresa non convertibile'
            WHEN c.id_sorgente_categoria_txt IS NOT NULL AND c.id_sorgente_categoria_cv IS NULL THEN 'id_sorgente_categoria non convertibile'
            WHEN c.nr_percentuale_aumento_txt IS NOT NULL AND c.nr_percentuale_aumento_cv IS NULL THEN 'nr_percentuale_aumento non convertibile'
            WHEN c.id_sorgente_provincia_txt IS NOT NULL AND hcbi_ras.try_numeric_10_0(c.id_sorgente_provincia_txt) IS NULL THEN 'id_sorgente_provincia non convertibile in numeric(10,0)'
            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM converted AS c;

    SELECT count(*) INTO v_selected
    FROM hcbi_ras.tmp_anag_articolo_classificata;

    INSERT INTO hcbi_ras.stg_anag_articolo (
        id_sorgente_articolo,
        ds_anno,
        cd_articolo,
        nr_livello,
        ds_nome,
        ds_descrizione,
        fl_eliminato,
        fl_prezzo_regionale,
        ds_unita_misura,
        nr_macro_gruppo,
        nr_spese_generali,
        nr_di_cui_analisi,
        nr_utile_impresa,
        dt_last_update,
        fl_analisi_approvata,
        fl_has_utile_impresa,
        fl_analisi_pubblicata,
        cd_versione,
        fl_is_analisi,
        fl_is_cam,
        fl_is_ufficiale,
        id_sorgente_categoria,
        fl_is_manodopera,
        cd_codice_lev1,
        cd_codice_lev2,
        cd_codice_lev3,
        cd_codice_lev4,
        cd_codice_lev5,
        fl_is_minuteria,
        nr_percentuale_aumento,
        ds_annotazione,
        fl_esporta_come_articolo,
        fl_escludi_manodopera,
        id_sorgente_provincia
    )
    SELECT
        t.id_sorgente_articolo_cv,
        t.ds_anno_cv,
        t.cd_articolo_cv,
        t.nr_livello_cv,
        t.ds_nome_cv,
        t.ds_descrizione_cv,
        t.fl_eliminato_cv,
        t.fl_prezzo_regionale_cv,
        t.ds_unita_misura_cv,
        t.nr_macro_gruppo_cv,
        t.nr_spese_generali_cv,
        t.nr_di_cui_analisi_cv,
        t.nr_utile_impresa_cv,
        t.dt_last_update_cv,
        t.fl_analisi_approvata_cv,
        t.fl_has_utile_impresa_cv,
        t.fl_analisi_pubblicata_cv,
        t.cd_versione_cv,
        t.fl_is_analisi_cv,
        t.fl_is_cam_cv,
        t.fl_is_ufficiale_cv,
        t.id_sorgente_categoria_cv,
        t.fl_is_manodopera_cv,
        t.cd_codice_lev1_cv,
        t.cd_codice_lev2_cv,
        t.cd_codice_lev3_cv,
        t.cd_codice_lev4_cv,
        t.cd_codice_lev5_cv,
        t.fl_is_minuteria_cv,
        t.nr_percentuale_aumento_cv,
        t.ds_annotazione_cv,
        t.fl_esporta_come_articolo_cv,
        t.fl_escludi_manodopera_cv,
        t.id_sorgente_provincia_cv
    FROM hcbi_ras.tmp_anag_articolo_classificata AS t
    WHERE t.tx_motivo_scarto IS NULL;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_anag_articolo_rej (
        id_sorgente_articolo,
        ds_anno,
        cd_articolo,
        nr_livello,
        ds_nome,
        ds_descrizione,
        fl_eliminato,
        fl_prezzo_regionale,
        ds_unita_misura,
        nr_macro_gruppo,
        nr_spese_generali,
        nr_di_cui_analisi,
        nr_utile_impresa,
        dt_last_update,
        fl_analisi_approvata,
        fl_has_utile_impresa,
        fl_analisi_pubblicata,
        cd_versione,
        fl_is_analisi,
        fl_is_cam,
        fl_is_ufficiale,
        id_sorgente_categoria,
        fl_is_manodopera,
        cd_codice_lev1,
        cd_codice_lev2,
        cd_codice_lev3,
        cd_codice_lev4,
        cd_codice_lev5,
        fl_is_minuteria,
        nr_percentuale_aumento,
        ds_annotazione,
        fl_esporta_come_articolo,
        fl_escludi_manodopera,
        id_sorgente_provincia,
        tx_motivo_scarto
    )
    SELECT
        t.id_sorgente_articolo_raw,
        t.ds_anno_raw,
        t.cd_articolo_raw,
        t.nr_livello_raw,
        t.ds_nome_raw,
        t.ds_descrizione_raw,
        t.fl_eliminato_raw,
        t.fl_prezzo_regionale_raw,
        t.ds_unita_misura_raw,
        t.nr_macro_gruppo_raw,
        t.nr_spese_generali_raw,
        t.nr_di_cui_analisi_raw,
        t.nr_utile_impresa_raw,
        t.dt_last_update_raw,
        t.fl_analisi_approvata_raw,
        t.fl_has_utile_impresa_raw,
        t.fl_analisi_pubblicata_raw,
        t.cd_versione_raw,
        t.fl_is_analisi_raw,
        t.fl_is_cam_raw,
        t.fl_is_ufficiale_raw,
        t.id_sorgente_categoria_raw,
        t.fl_is_manodopera_raw,
        t.cd_codice_lev1_raw,
        t.cd_codice_lev2_raw,
        t.cd_codice_lev3_raw,
        t.cd_codice_lev4_raw,
        t.cd_codice_lev5_raw,
        t.fl_is_minuteria_raw,
        t.nr_percentuale_aumento_raw,
        t.ds_annotazione_raw,
        t.fl_esporta_come_articolo_raw,
        t.fl_escludi_manodopera_raw,
        t.id_sorgente_provincia_raw,
        t.tx_motivo_scarto
    FROM hcbi_ras.tmp_anag_articolo_classificata AS t
    WHERE t.tx_motivo_scarto IS NOT NULL;
    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = format('Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s', v_selected, v_inserted, v_rec_errors),
            DETAIL = 'Il numero di record letti non coincide con caricati e scartati.',
            HINT = 'Verificare classificazione e INSERT verso STG e REJ.';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, v_updated, v_deleted,
        v_rec_errors, 'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_articolo_classificata;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_anag_articolo_classificata;
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

        RAISE WARNING 'Errore in pkg_stg_anag_articolo_prc_main. SQLSTATE=%, errore=%', v_sqlstate, v_sqlerrm;
END;
$procedure$
