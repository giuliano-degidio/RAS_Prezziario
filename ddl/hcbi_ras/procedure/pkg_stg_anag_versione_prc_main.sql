CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_versione_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0; v_updated bigint:=0; v_deleted bigint:=0; v_rec_errors bigint:=0;     v_sqlstate text; v_sqlerrm text; v_sql_detail text; v_sql_hint text; v_sql_context text; v_log_error text;
BEGIN p_result:=-1; SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_anag_versione_classificata;
 CREATE TABLE hcbi_ras.tmp_anag_versione_classificata AS WITH src AS MATERIALIZED(SELECT
            f.ds_anno_pubblicazione AS ds_anno_pubblicazione_raw,
            f.cd_versione AS cd_versione_raw,
            f.ds_versione AS ds_versione_raw,
            f.fl_scostamento_1_visibile AS fl_scostamento_1_visibile_raw,
            f.fl_scostamento_2_visibile AS fl_scostamento_2_visibile_raw,
            f.fl_scostamento_3_visibile AS fl_scostamento_3_visibile_raw,
            f.fl_scostamento_4_visibile AS fl_scostamento_4_visibile_raw,
            f.fl_scostamento_5_visibile AS fl_scostamento_5_visibile_raw,
            f.nr_spese_generali AS nr_spese_generali_raw,
            f.nr_utile_impresa AS nr_utile_impresa_raw,
            f.nr_di_cui_analisi AS nr_di_cui_analisi_raw,
            f.ds_llpp_homepage_title AS ds_llpp_homepage_title_raw,
            f.ds_llpp_homepage_description AS ds_llpp_homepage_description_raw,
            f.fl_pubblicazione_regionale AS fl_pubblicazione_regionale_raw,
            f.id_sorgente_versione AS id_sorgente_versione_raw,
            f.fl_mostra_annotazioni AS fl_mostra_annotazioni_raw,
            f.fl_mostra_struttura_analisi AS fl_mostra_struttura_analisi_raw,
            f.fl_is_errata_corrige AS fl_is_errata_corrige_raw,
            f.fl_mostra_cam AS fl_mostra_cam_raw,
            f.id_sorgente_provincia AS id_sorgente_provincia_raw,
            nullif(btrim(f.ds_anno_pubblicazione::text), '') AS ds_anno_pubblicazione_txt,
            nullif(btrim(f.cd_versione::text), '') AS cd_versione_txt,
            nullif(btrim(f.ds_versione::text), '') AS ds_versione_txt,
            nullif(btrim(f.fl_scostamento_1_visibile::text), '') AS fl_scostamento_1_visibile_txt,
            nullif(btrim(f.fl_scostamento_2_visibile::text), '') AS fl_scostamento_2_visibile_txt,
            nullif(btrim(f.fl_scostamento_3_visibile::text), '') AS fl_scostamento_3_visibile_txt,
            nullif(btrim(f.fl_scostamento_4_visibile::text), '') AS fl_scostamento_4_visibile_txt,
            nullif(btrim(f.fl_scostamento_5_visibile::text), '') AS fl_scostamento_5_visibile_txt,
            nullif(btrim(f.nr_spese_generali::text), '') AS nr_spese_generali_txt,
            nullif(btrim(f.nr_utile_impresa::text), '') AS nr_utile_impresa_txt,
            nullif(btrim(f.nr_di_cui_analisi::text), '') AS nr_di_cui_analisi_txt,
            nullif(btrim(f.ds_llpp_homepage_title::text), '') AS ds_llpp_homepage_title_txt,
            nullif(btrim(f.ds_llpp_homepage_description::text), '') AS ds_llpp_homepage_description_txt,
            nullif(btrim(f.fl_pubblicazione_regionale::text), '') AS fl_pubblicazione_regionale_txt,
            nullif(btrim(f.id_sorgente_versione::text), '') AS id_sorgente_versione_txt,
            nullif(btrim(f.fl_mostra_annotazioni::text), '') AS fl_mostra_annotazioni_txt,
            nullif(btrim(f.fl_mostra_struttura_analisi::text), '') AS fl_mostra_struttura_analisi_txt,
            nullif(btrim(f.fl_is_errata_corrige::text), '') AS fl_is_errata_corrige_txt,
            nullif(btrim(f.fl_mostra_cam::text), '') AS fl_mostra_cam_txt,
            nullif(btrim(f.id_sorgente_provincia::text), '') AS id_sorgente_provincia_txt,
            count(*) OVER(PARTITION BY nullif(btrim(f.ds_anno_pubblicazione),''),nullif(btrim(f.cd_versione),''),nullif(btrim(f.id_sorgente_provincia),'')) duplicate_count
 FROM hcbi_ras.v_src_tmp_anag_versione f), converted AS MATERIALIZED(SELECT s.*,
            hcbi_ras.try_integer(s.ds_anno_pubblicazione_txt) AS ds_anno_pubblicazione_cv,
            hcbi_ras.try_smallint(s.cd_versione_txt) AS cd_versione_cv,
            hcbi_ras.try_boolean_smallint(s.fl_scostamento_1_visibile_txt) AS fl_scostamento_1_visibile_cv,
            hcbi_ras.try_boolean_smallint(s.fl_scostamento_2_visibile_txt) AS fl_scostamento_2_visibile_cv,
            hcbi_ras.try_boolean_smallint(s.fl_scostamento_3_visibile_txt) AS fl_scostamento_3_visibile_cv,
            hcbi_ras.try_boolean_smallint(s.fl_scostamento_4_visibile_txt) AS fl_scostamento_4_visibile_cv,
            hcbi_ras.try_boolean_smallint(s.fl_scostamento_5_visibile_txt) AS fl_scostamento_5_visibile_cv,
            hcbi_ras.try_numeric_10_5(s.nr_spese_generali_txt) AS nr_spese_generali_cv,
            hcbi_ras.try_numeric_10_5(s.nr_utile_impresa_txt) AS nr_utile_impresa_cv,
            hcbi_ras.try_numeric_10_5(s.nr_di_cui_analisi_txt) AS nr_di_cui_analisi_cv,
            hcbi_ras.try_boolean_smallint(s.fl_pubblicazione_regionale_txt) AS fl_pubblicazione_regionale_cv,
            hcbi_ras.try_bigint(s.id_sorgente_versione_txt) AS id_sorgente_versione_cv,
            hcbi_ras.try_boolean_smallint(s.fl_mostra_annotazioni_txt) AS fl_mostra_annotazioni_cv,
            hcbi_ras.try_boolean_smallint(s.fl_mostra_struttura_analisi_txt) AS fl_mostra_struttura_analisi_cv,
            hcbi_ras.try_boolean_smallint(s.fl_is_errata_corrige_txt) AS fl_is_errata_corrige_cv,
            hcbi_ras.try_boolean_smallint(s.fl_mostra_cam_txt) AS fl_mostra_cam_cv,
            hcbi_ras.try_numeric_10_0(s.id_sorgente_provincia_txt) AS id_sorgente_provincia_cv
 FROM src s) SELECT c.*,CASE
            WHEN c.duplicate_count > 1 THEN 'Chiave duplicata: (ds_anno_pubblicazione, cd_versione, id_sorgente_provincia)'
            WHEN c.ds_anno_pubblicazione_txt IS NULL THEN 'ds_anno_pubblicazione obbligatorio'
            WHEN c.ds_anno_pubblicazione_txt IS NOT NULL AND c.ds_anno_pubblicazione_cv IS NULL THEN 'ds_anno_pubblicazione non convertibile o fuori dominio'
            WHEN c.cd_versione_txt IS NULL THEN 'cd_versione obbligatorio'
            WHEN c.cd_versione_txt IS NOT NULL AND c.cd_versione_cv IS NULL THEN 'cd_versione non convertibile o fuori dominio'
            WHEN c.fl_scostamento_1_visibile_txt IS NULL THEN 'fl_scostamento_1_visibile obbligatorio'
            WHEN c.fl_scostamento_1_visibile_txt IS NOT NULL AND c.fl_scostamento_1_visibile_cv IS NULL THEN 'fl_scostamento_1_visibile non convertibile o fuori dominio'
            WHEN c.fl_scostamento_2_visibile_txt IS NULL THEN 'fl_scostamento_2_visibile obbligatorio'
            WHEN c.fl_scostamento_2_visibile_txt IS NOT NULL AND c.fl_scostamento_2_visibile_cv IS NULL THEN 'fl_scostamento_2_visibile non convertibile o fuori dominio'
            WHEN c.fl_scostamento_3_visibile_txt IS NULL THEN 'fl_scostamento_3_visibile obbligatorio'
            WHEN c.fl_scostamento_3_visibile_txt IS NOT NULL AND c.fl_scostamento_3_visibile_cv IS NULL THEN 'fl_scostamento_3_visibile non convertibile o fuori dominio'
            WHEN c.fl_scostamento_4_visibile_txt IS NULL THEN 'fl_scostamento_4_visibile obbligatorio'
            WHEN c.fl_scostamento_4_visibile_txt IS NOT NULL AND c.fl_scostamento_4_visibile_cv IS NULL THEN 'fl_scostamento_4_visibile non convertibile o fuori dominio'
            WHEN c.fl_scostamento_5_visibile_txt IS NULL THEN 'fl_scostamento_5_visibile obbligatorio'
            WHEN c.fl_scostamento_5_visibile_txt IS NOT NULL AND c.fl_scostamento_5_visibile_cv IS NULL THEN 'fl_scostamento_5_visibile non convertibile o fuori dominio'
            WHEN c.nr_spese_generali_txt IS NULL THEN 'nr_spese_generali obbligatorio'
            WHEN c.nr_spese_generali_txt IS NOT NULL AND c.nr_spese_generali_cv IS NULL THEN 'nr_spese_generali non convertibile o fuori dominio'
            WHEN c.nr_utile_impresa_txt IS NULL THEN 'nr_utile_impresa obbligatorio'
            WHEN c.nr_utile_impresa_txt IS NOT NULL AND c.nr_utile_impresa_cv IS NULL THEN 'nr_utile_impresa non convertibile o fuori dominio'
            WHEN c.nr_di_cui_analisi_txt IS NULL THEN 'nr_di_cui_analisi obbligatorio'
            WHEN c.nr_di_cui_analisi_txt IS NOT NULL AND c.nr_di_cui_analisi_cv IS NULL THEN 'nr_di_cui_analisi non convertibile o fuori dominio'
            WHEN c.fl_pubblicazione_regionale_txt IS NULL THEN 'fl_pubblicazione_regionale obbligatorio'
            WHEN c.fl_pubblicazione_regionale_txt IS NOT NULL AND c.fl_pubblicazione_regionale_cv IS NULL THEN 'fl_pubblicazione_regionale non convertibile o fuori dominio'
            WHEN c.id_sorgente_versione_txt IS NULL THEN 'id_sorgente_versione obbligatorio'
            WHEN c.id_sorgente_versione_txt IS NOT NULL AND c.id_sorgente_versione_cv IS NULL THEN 'id_sorgente_versione non convertibile o fuori dominio'
            WHEN c.fl_mostra_annotazioni_txt IS NULL THEN 'fl_mostra_annotazioni obbligatorio'
            WHEN c.fl_mostra_annotazioni_txt IS NOT NULL AND c.fl_mostra_annotazioni_cv IS NULL THEN 'fl_mostra_annotazioni non convertibile o fuori dominio'
            WHEN c.fl_mostra_struttura_analisi_txt IS NULL THEN 'fl_mostra_struttura_analisi obbligatorio'
            WHEN c.fl_mostra_struttura_analisi_txt IS NOT NULL AND c.fl_mostra_struttura_analisi_cv IS NULL THEN 'fl_mostra_struttura_analisi non convertibile o fuori dominio'
            WHEN c.fl_is_errata_corrige_txt IS NULL THEN 'fl_is_errata_corrige obbligatorio'
            WHEN c.fl_is_errata_corrige_txt IS NOT NULL AND c.fl_is_errata_corrige_cv IS NULL THEN 'fl_is_errata_corrige non convertibile o fuori dominio'
            WHEN c.fl_mostra_cam_txt IS NULL THEN 'fl_mostra_cam obbligatorio'
            WHEN c.fl_mostra_cam_txt IS NOT NULL AND c.fl_mostra_cam_cv IS NULL THEN 'fl_mostra_cam non convertibile o fuori dominio'
            WHEN c.id_sorgente_provincia_txt IS NULL THEN 'id_sorgente_provincia obbligatorio'
            WHEN c.id_sorgente_provincia_txt IS NOT NULL AND c.id_sorgente_provincia_cv IS NULL THEN 'id_sorgente_provincia non convertibile o fuori dominio'
            ELSE NULL END::text tx_motivo_scarto FROM converted c;
 SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_anag_versione_classificata;
 INSERT INTO hcbi_ras.stg_anag_versione(ds_anno_pubblicazione,cd_versione,ds_versione,fl_scostamento_1_visibile,fl_scostamento_2_visibile,fl_scostamento_3_visibile,fl_scostamento_4_visibile,fl_scostamento_5_visibile,nr_spese_generali,nr_utile_impresa,nr_di_cui_analisi,ds_llpp_homepage_title,ds_llpp_homepage_description,fl_pubblicazione_regionale,id_sorgente_versione,fl_mostra_annotazioni,fl_mostra_struttura_analisi,fl_is_errata_corrige,fl_mostra_cam,id_sorgente_provincia) SELECT
        c.ds_anno_pubblicazione_cv,
        c.cd_versione_cv,
        c.ds_versione_txt,
        c.fl_scostamento_1_visibile_cv,
        c.fl_scostamento_2_visibile_cv,
        c.fl_scostamento_3_visibile_cv,
        c.fl_scostamento_4_visibile_cv,
        c.fl_scostamento_5_visibile_cv,
        c.nr_spese_generali_cv,
        c.nr_utile_impresa_cv,
        c.nr_di_cui_analisi_cv,
        c.ds_llpp_homepage_title_txt,
        c.ds_llpp_homepage_description_txt,
        c.fl_pubblicazione_regionale_cv,
        c.id_sorgente_versione_cv,
        c.fl_mostra_annotazioni_cv,
        c.fl_mostra_struttura_analisi_cv,
        c.fl_is_errata_corrige_cv,
        c.fl_mostra_cam_cv,
        c.id_sorgente_provincia_cv
 FROM hcbi_ras.tmp_anag_versione_classificata c WHERE tx_motivo_scarto IS NULL; GET DIAGNOSTICS v_inserted=ROW_COUNT;
 INSERT INTO hcbi_ras.stg_anag_versione_rej(ds_anno_pubblicazione,cd_versione,ds_versione,fl_scostamento_1_visibile,fl_scostamento_2_visibile,fl_scostamento_3_visibile,fl_scostamento_4_visibile,fl_scostamento_5_visibile,nr_spese_generali,nr_utile_impresa,nr_di_cui_analisi,ds_llpp_homepage_title,ds_llpp_homepage_description,fl_pubblicazione_regionale,id_sorgente_versione,fl_mostra_annotazioni,fl_mostra_struttura_analisi,fl_is_errata_corrige,fl_mostra_cam,id_sorgente_provincia,tx_motivo_scarto) SELECT
        c.ds_anno_pubblicazione_raw,
        c.cd_versione_raw,
        c.ds_versione_raw,
        c.fl_scostamento_1_visibile_raw,
        c.fl_scostamento_2_visibile_raw,
        c.fl_scostamento_3_visibile_raw,
        c.fl_scostamento_4_visibile_raw,
        c.fl_scostamento_5_visibile_raw,
        c.nr_spese_generali_raw,
        c.nr_utile_impresa_raw,
        c.nr_di_cui_analisi_raw,
        c.ds_llpp_homepage_title_raw,
        c.ds_llpp_homepage_description_raw,
        c.fl_pubblicazione_regionale_raw,
        c.id_sorgente_versione_raw,
        c.fl_mostra_annotazioni_raw,
        c.fl_mostra_struttura_analisi_raw,
        c.fl_is_errata_corrige_raw,
        c.fl_mostra_cam_raw,
        c.id_sorgente_provincia_raw,
        c.tx_motivo_scarto FROM hcbi_ras.tmp_anag_versione_classificata c WHERE tx_motivo_scarto IS NOT NULL; GET DIAGNOSTICS v_rec_errors=ROW_COUNT;
 IF v_selected<>v_inserted+v_rec_errors THEN RAISE EXCEPTION USING ERRCODE='P0001',MESSAGE=format('Riconciliazione non valida: selected=%s, inserted=%s, rejected=%s',v_selected,v_inserted,v_rec_errors); END IF;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name); DROP TABLE hcbi_ras.tmp_anag_versione_classificata; p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1; BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_anag_versione_classificata; EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name); EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM; END; END IF;
 RAISE WARNING 'Errore in pkg_stg_anag_versione_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$procedure$
