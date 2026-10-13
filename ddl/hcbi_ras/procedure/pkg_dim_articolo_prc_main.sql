CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_articolo_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
 v_id_log BIGINT; v_selected BIGINT:=0; v_inserted BIGINT:=0; v_updated BIGINT:=0;
 v_deleted BIGINT:=0; v_rec_errors BIGINT:=0; v_matched BIGINT:=0;
 v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,
   p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
 INTO v_id_log;

 /* Tutte le dimensioni referenziate devono possedere entrambi i tappi 0 e -1.
    I controlli sono separati per produrre una diagnostica puntuale. */
 IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo = 0) THEN
  RAISE EXCEPTION USING ERRCODE='23503',
   MESSAGE='Record tecnico 0 mancante in HCBI_RAS.DIM_PERIODO',
   DETAIL='DIM_ARTICOLO richiede DIM_PERIODO.ID_PERIODO = 0.',
   HINT='Inserire il tappo 0 in DIM_PERIODO e rilanciare la procedura.';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo = -1) THEN
  RAISE EXCEPTION USING ERRCODE='23503',
   MESSAGE='Record tecnico -1 mancante in HCBI_RAS.DIM_PERIODO',
   DETAIL='DIM_ARTICOLO usa -1 quando la lookup del periodo non viene risolta.',
   HINT='Inserire il tappo -1 in DIM_PERIODO e rilanciare la procedura.';
 END IF;

 IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia = 0) THEN
  RAISE EXCEPTION USING ERRCODE='23503',
   MESSAGE='Record tecnico 0 mancante in HCBI_RAS.DIM_PROVINCIA',
   DETAIL='DIM_ARTICOLO richiede DIM_PROVINCIA.ID_ANAG_PROVINCIA = 0.',
   HINT='Inserire il tappo 0 in DIM_PROVINCIA e rilanciare la procedura.';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia = -1) THEN
  RAISE EXCEPTION USING ERRCODE='23503',
   MESSAGE='Record tecnico -1 mancante in HCBI_RAS.DIM_PROVINCIA',
   DETAIL='DIM_ARTICOLO usa -1 quando la lookup della provincia non viene risolta.',
   HINT='Inserire il tappo -1 in DIM_PROVINCIA e rilanciare la procedura.';
 END IF;

 IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione = 0) THEN
  RAISE EXCEPTION USING ERRCODE='23503',
   MESSAGE='Record tecnico 0 mancante in HCBI_RAS.DIM_VERSIONE',
   DETAIL='DIM_ARTICOLO richiede DIM_VERSIONE.ID_ANAG_VERSIONE = 0.',
   HINT='Inserire il tappo 0 in DIM_VERSIONE e rilanciare la procedura.';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione = -1) THEN
  RAISE EXCEPTION USING ERRCODE='23503',
   MESSAGE='Record tecnico -1 mancante in HCBI_RAS.DIM_VERSIONE',
   DETAIL='DIM_ARTICOLO usa -1 quando la lookup della versione non viene risolta.',
   HINT='Inserire il tappo -1 in DIM_VERSIONE e rilanciare la procedura.';
 END IF;

 IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_macro_gruppo WHERE id_anag_macro_gruppo = 0) THEN
  RAISE EXCEPTION USING ERRCODE='23503',
   MESSAGE='Record tecnico 0 mancante in HCBI_RAS.DIM_MACRO_GRUPPO',
   DETAIL='DIM_ARTICOLO usa 0 quando NR_MACRO_GRUPPO non e valorizzato.',
   HINT='Inserire il tappo 0 in DIM_MACRO_GRUPPO e rilanciare la procedura.';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_macro_gruppo WHERE id_anag_macro_gruppo = -1) THEN
  RAISE EXCEPTION USING ERRCODE='23503',
   MESSAGE='Record tecnico -1 mancante in HCBI_RAS.DIM_MACRO_GRUPPO',
   DETAIL='DIM_ARTICOLO usa -1 quando la lookup del macro-gruppo non viene risolta.',
   HINT='Inserire il tappo -1 in DIM_MACRO_GRUPPO e rilanciare la procedura.';
 END IF;

 IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_unita_misura WHERE id_anag_unita_misura = 0) THEN
  RAISE EXCEPTION USING ERRCODE='23503',
   MESSAGE='Record tecnico 0 mancante in HCBI_RAS.DIM_UNITA_MISURA',
   DETAIL='DIM_ARTICOLO usa 0 quando DS_UNITA_MISURA non e valorizzato.',
   HINT='Inserire il tappo 0 in DIM_UNITA_MISURA e rilanciare la procedura.';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_unita_misura WHERE id_anag_unita_misura = -1) THEN
  RAISE EXCEPTION USING ERRCODE='23503',
   MESSAGE='Record tecnico -1 mancante in HCBI_RAS.DIM_UNITA_MISURA',
   DETAIL='DIM_ARTICOLO usa -1 quando la lookup dell unita di misura non viene risolta.',
   HINT='Inserire il tappo -1 in DIM_UNITA_MISURA e rilanciare la procedura.';
 END IF;

 /* La DWH aggiornata deve essere univoca sulla business key con provincia. */
 IF EXISTS (
  SELECT 1
  FROM hcbi_ras.dwh_anag_articolo
  GROUP BY ds_anno,cd_articolo,cd_versione,id_sorgente_provincia
  HAVING count(*) > 1
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',
   MESSAGE='Business key non deterministica: HCBI_RAS.DWH_ANAG_ARTICOLO',
   DETAIL='Duplicati su DS_ANNO, CD_ARTICOLO, CD_VERSIONE, ID_SORGENTE_PROVINCIA.',
   HINT='Rieseguire il flusso ANAG_ARTICOLO aggiornato e verificare la UK DWH.';
 END IF;

 /* Controlli di determinismo separati per una diagnostica puntuale. */
 IF EXISTS (
  SELECT 1 FROM hcbi_ras.dim_periodo
  WHERE ds_anno IS NOT NULL
  GROUP BY ds_anno HAVING count(*) > 1
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',
   MESSAGE='Lookup non deterministica: HCBI_RAS.DIM_PERIODO.DS_ANNO',
   DETAIL='Esistono piu righe in DIM_PERIODO con lo stesso DS_ANNO.',
   HINT='Eseguire il test duplicati su DIM_PERIODO e correggere la business key.';
 END IF;

 IF EXISTS (
  SELECT 1 FROM hcbi_ras.dwh_anag_provincia
  WHERE id_sorgente_provincia IS NOT NULL
  GROUP BY id_sorgente_provincia HAVING count(*) > 1
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',
   MESSAGE='Lookup non deterministica: HCBI_RAS.DWH_ANAG_PROVINCIA.ID_SORGENTE_PROVINCIA',
   DETAIL='Esistono piu righe in DWH_ANAG_PROVINCIA con lo stesso ID_SORGENTE_PROVINCIA.',
   HINT='Eseguire il test duplicati su DWH_ANAG_PROVINCIA e correggere la candidate key.';
 END IF;

 IF EXISTS (
  SELECT 1 FROM hcbi_ras.dim_provincia
  WHERE cd_provincia IS NOT NULL
  GROUP BY cd_provincia HAVING count(*) > 1
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',
   MESSAGE='Lookup non deterministica: HCBI_RAS.DIM_PROVINCIA.CD_PROVINCIA',
   DETAIL='Esistono piu righe in DIM_PROVINCIA con lo stesso CD_PROVINCIA.',
   HINT='Eseguire il test duplicati su DIM_PROVINCIA e correggere la business key.';
 END IF;

 IF EXISTS (
  SELECT 1 FROM hcbi_ras.dim_versione
  GROUP BY id_periodo_pubblicazione,cd_versione,id_anag_provincia
  HAVING count(*) > 1
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',
   MESSAGE='Lookup non deterministica: HCBI_RAS.DIM_VERSIONE',
   DETAIL='Duplicati sulla chiave ID_PERIODO_PUBBLICAZIONE, CD_VERSIONE, ID_ANAG_PROVINCIA.',
   HINT='Eseguire il test duplicati sulla business key di DIM_VERSIONE.';
 END IF;

 IF EXISTS (
  SELECT 1 FROM hcbi_ras.dwh_anag_macro_gruppo
  WHERE id_sorgente_macro_gruppo IS NOT NULL
  GROUP BY id_sorgente_macro_gruppo HAVING count(*) > 1
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',
   MESSAGE='Lookup non deterministica: HCBI_RAS.DWH_ANAG_MACRO_GRUPPO.ID_SORGENTE_MACRO_GRUPPO',
   DETAIL='Esistono piu righe con lo stesso ID_SORGENTE_MACRO_GRUPPO.',
   HINT='Eseguire il test duplicati su DWH_ANAG_MACRO_GRUPPO e correggere la candidate key.';
 END IF;

 IF EXISTS (
  SELECT 1 FROM hcbi_ras.dim_unita_misura
  WHERE id_sorgente_unita_misura IS NOT NULL
  GROUP BY id_sorgente_unita_misura HAVING count(*) > 1
 ) THEN
  RAISE EXCEPTION USING ERRCODE='P0001',
   MESSAGE='Lookup non deterministica: HCBI_RAS.DIM_UNITA_MISURA.ID_SORGENTE_UNITA_MISURA',
   DETAIL='Esistono piu righe con lo stesso ID_SORGENTE_UNITA_MISURA.',
   HINT='Eseguire il test duplicati su DIM_UNITA_MISURA e correggere la candidate key.';
 END IF;

 IF EXISTS (
  SELECT 1 FROM hcbi_ras.dwh_anag_articolo
  WHERE id_sorgente_provincia IS NULL
 ) THEN
  RAISE EXCEPTION USING ERRCODE='23502',
   MESSAGE='ID_SORGENTE_PROVINCIA nullo in HCBI_RAS.DWH_ANAG_ARTICOLO',
   DETAIL='La provincia e obbligatoria nel flusso ANAG_ARTICOLO aggiornato.';
 END IF;

 DROP TABLE IF EXISTS hcbi_ras.tmp_dim_articolo;
 CREATE TABLE hcbi_ras.tmp_dim_articolo AS
 WITH base AS MATERIALIZED
 (
  SELECT src.*, COALESCE(dp.id_periodo,-1::INTEGER) AS periodo_lkp,
         COALESCE(dpr.id_anag_provincia,-1::BIGINT) AS provincia_lkp,
         dp.id_periodo IS NULL AS periodo_ko,
         dpr.id_anag_provincia IS NULL AS provincia_ko
  FROM hcbi_ras.dwh_anag_articolo src
  LEFT JOIN hcbi_ras.dim_periodo dp ON dp.ds_anno=src.ds_anno
  LEFT JOIN hcbi_ras.dwh_anag_provincia dwp ON dwp.id_sorgente_provincia=src.id_sorgente_provincia
  LEFT JOIN hcbi_ras.dim_provincia dpr ON dpr.cd_provincia=dwp.cd_provincia
 )
 SELECT
        b.id_anag_articolo,
        b.id_sorgente_articolo AS id_sorgente_articolo,
        b.periodo_lkp AS id_periodo_pubblicazione,
        regexp_replace(btrim(b.cd_articolo), '\.$', '')::VARCHAR(60) AS cd_articolo,
        b.nr_livello AS nr_livello,
        b.ds_nome AS ds_nome,
        b.ds_descrizione AS ds_descrizione,
        b.fl_eliminato AS fl_eliminato,
        b.fl_prezzo_regionale AS fl_prezzo_regionale,
        CASE WHEN b.ds_unita_misura IS NULL THEN 0::BIGINT ELSE COALESCE(dum.id_anag_unita_misura,-1::BIGINT) END AS id_anag_unita_misura,
        CASE WHEN b.nr_macro_gruppo IS NULL THEN 0::BIGINT ELSE COALESCE(dmg.id_anag_macro_gruppo,-1::BIGINT) END AS id_anag_macro_gruppo,
        b.nr_spese_generali AS nr_spese_generali,
        b.nr_di_cui_analisi AS nr_di_cui_analisi,
        b.nr_utile_impresa AS nr_utile_impresa,
        b.dt_last_update AS dt_last_update,
        b.fl_analisi_approvata AS fl_analisi_approvata,
        b.fl_has_utile_impresa AS fl_has_utile_impresa,
        b.fl_analisi_pubblicata AS fl_analisi_pubblicata,
        COALESCE(dv.id_anag_versione,-1::BIGINT) AS id_anag_versione,
        b.fl_is_analisi AS fl_is_analisi,
        b.fl_is_cam AS fl_is_cam,
        b.fl_is_ufficiale AS fl_is_ufficiale,
        b.id_sorgente_categoria AS id_sorgente_categoria,
        b.fl_is_manodopera AS fl_is_manodopera,
        b.cd_codice_lev1 AS cd_codice_lev1,
        b.cd_codice_lev2 AS cd_codice_lev2,
        b.cd_codice_lev3 AS cd_codice_lev3,
        b.cd_codice_lev4 AS cd_codice_lev4,
        b.cd_codice_lev5 AS cd_codice_lev5,
        b.fl_is_minuteria AS fl_is_minuteria,
        b.nr_percentuale_aumento AS nr_percentuale_aumento,
        b.ds_annotazione AS ds_annotazione,
        b.fl_esporta_come_articolo AS fl_esporta_come_articolo,
        b.fl_escludi_manodopera AS fl_escludi_manodopera,
        b.provincia_lkp AS id_anag_provincia,
        b.periodo_ko,
        b.provincia_ko,
        (dv.id_anag_versione IS NULL) AS versione_ko,
        (b.nr_macro_gruppo IS NOT NULL AND dmg.id_anag_macro_gruppo IS NULL) AS macro_gruppo_ko,
        (b.ds_unita_misura IS NOT NULL AND dum.id_anag_unita_misura IS NULL) AS unita_misura_ko
 FROM base b
 LEFT JOIN hcbi_ras.dim_versione dv
   ON dv.id_periodo_pubblicazione=b.periodo_lkp AND dv.cd_versione=b.cd_versione
  AND dv.id_anag_provincia=b.provincia_lkp
 LEFT JOIN hcbi_ras.dwh_anag_macro_gruppo dwmg
   ON dwmg.id_sorgente_macro_gruppo=b.nr_macro_gruppo::BIGINT
 LEFT JOIN hcbi_ras.dim_macro_gruppo dmg
   ON dmg.id_anag_macro_gruppo=dwmg.id_anag_macro_gruppo
 LEFT JOIN hcbi_ras.dim_unita_misura dum
   ON dum.id_sorgente_unita_misura=b.ds_unita_misura;

 CREATE UNIQUE INDEX tmp_dim_articolo_pk ON hcbi_ras.tmp_dim_articolo(id_anag_articolo) NULLS NOT DISTINCT;
 CREATE UNIQUE INDEX tmp_dim_articolo_bk ON hcbi_ras.tmp_dim_articolo
   (id_periodo_pubblicazione,cd_articolo,id_anag_versione,id_anag_provincia) NULLS NOT DISTINCT;
 ANALYZE hcbi_ras.tmp_dim_articolo;
 SELECT count(*),count(*) FILTER(WHERE periodo_ko),count(*) FILTER(WHERE provincia_ko),
        count(*) FILTER(WHERE versione_ko),count(*) FILTER(WHERE macro_gruppo_ko),
        count(*) FILTER(WHERE unita_misura_ko)
 INTO v_selected,v_rec_errors,v_matched,v_inserted,v_updated,v_deleted
 FROM hcbi_ras.tmp_dim_articolo;
 v_rec_errors:=v_rec_errors+v_matched+v_inserted+v_updated+v_deleted;
 v_inserted:=0; v_updated:=0; v_deleted:=0; v_matched:=0;

 UPDATE hcbi_ras.dim_articolo d SET
           id_sorgente_articolo = src.id_sorgente_articolo,
           id_periodo_pubblicazione = src.id_periodo_pubblicazione,
           cd_articolo = src.cd_articolo,
           nr_livello = src.nr_livello,
           ds_nome = src.ds_nome,
           ds_descrizione = src.ds_descrizione,
           fl_eliminato = src.fl_eliminato,
           fl_prezzo_regionale = src.fl_prezzo_regionale,
           id_anag_unita_misura = src.id_anag_unita_misura,
           id_anag_macro_gruppo = src.id_anag_macro_gruppo,
           nr_spese_generali = src.nr_spese_generali,
           nr_di_cui_analisi = src.nr_di_cui_analisi,
           nr_utile_impresa = src.nr_utile_impresa,
           dt_last_update = src.dt_last_update,
           fl_analisi_approvata = src.fl_analisi_approvata,
           fl_has_utile_impresa = src.fl_has_utile_impresa,
           fl_analisi_pubblicata = src.fl_analisi_pubblicata,
           id_anag_versione = src.id_anag_versione,
           fl_is_analisi = src.fl_is_analisi,
           fl_is_cam = src.fl_is_cam,
           fl_is_ufficiale = src.fl_is_ufficiale,
           id_sorgente_categoria = src.id_sorgente_categoria,
           fl_is_manodopera = src.fl_is_manodopera,
           cd_codice_lev1 = src.cd_codice_lev1,
           cd_codice_lev2 = src.cd_codice_lev2,
           cd_codice_lev3 = src.cd_codice_lev3,
           cd_codice_lev4 = src.cd_codice_lev4,
           cd_codice_lev5 = src.cd_codice_lev5,
           fl_is_minuteria = src.fl_is_minuteria,
           nr_percentuale_aumento = src.nr_percentuale_aumento,
           ds_annotazione = src.ds_annotazione,
           fl_esporta_come_articolo = src.fl_esporta_come_articolo,
           fl_escludi_manodopera = src.fl_escludi_manodopera,
           id_anag_provincia = src.id_anag_provincia,
           dt_update=clock_timestamp(),tx_update_by=p_ds_step_name
 FROM hcbi_ras.tmp_dim_articolo src
 WHERE d.id_anag_articolo=src.id_anag_articolo
 AND ROW(
            d.id_sorgente_articolo,
            d.id_periodo_pubblicazione,
            d.cd_articolo,
            d.nr_livello,
            d.ds_nome,
            d.ds_descrizione,
            d.fl_eliminato,
            d.fl_prezzo_regionale,
            d.id_anag_unita_misura,
            d.id_anag_macro_gruppo,
            d.nr_spese_generali,
            d.nr_di_cui_analisi,
            d.nr_utile_impresa,
            d.dt_last_update,
            d.fl_analisi_approvata,
            d.fl_has_utile_impresa,
            d.fl_analisi_pubblicata,
            d.id_anag_versione,
            d.fl_is_analisi,
            d.fl_is_cam,
            d.fl_is_ufficiale,
            d.id_sorgente_categoria,
            d.fl_is_manodopera,
            d.cd_codice_lev1,
            d.cd_codice_lev2,
            d.cd_codice_lev3,
            d.cd_codice_lev4,
            d.cd_codice_lev5,
            d.fl_is_minuteria,
            d.nr_percentuale_aumento,
            d.ds_annotazione,
            d.fl_esporta_come_articolo,
            d.fl_escludi_manodopera,
            d.id_anag_provincia
 ) IS DISTINCT FROM ROW(
            src.id_sorgente_articolo,
            src.id_periodo_pubblicazione,
            src.cd_articolo,
            src.nr_livello,
            src.ds_nome,
            src.ds_descrizione,
            src.fl_eliminato,
            src.fl_prezzo_regionale,
            src.id_anag_unita_misura,
            src.id_anag_macro_gruppo,
            src.nr_spese_generali,
            src.nr_di_cui_analisi,
            src.nr_utile_impresa,
            src.dt_last_update,
            src.fl_analisi_approvata,
            src.fl_has_utile_impresa,
            src.fl_analisi_pubblicata,
            src.id_anag_versione,
            src.fl_is_analisi,
            src.fl_is_cam,
            src.fl_is_ufficiale,
            src.id_sorgente_categoria,
            src.fl_is_manodopera,
            src.cd_codice_lev1,
            src.cd_codice_lev2,
            src.cd_codice_lev3,
            src.cd_codice_lev4,
            src.cd_codice_lev5,
            src.fl_is_minuteria,
            src.nr_percentuale_aumento,
            src.ds_annotazione,
            src.fl_esporta_come_articolo,
            src.fl_escludi_manodopera,
            src.id_anag_provincia
 );
 GET DIAGNOSTICS v_updated=ROW_COUNT;

 INSERT INTO hcbi_ras.dim_articolo(
        id_anag_articolo,
        id_sorgente_articolo,
        id_periodo_pubblicazione,
        cd_articolo,
        nr_livello,
        ds_nome,
        ds_descrizione,
        fl_eliminato,
        fl_prezzo_regionale,
        id_anag_unita_misura,
        id_anag_macro_gruppo,
        nr_spese_generali,
        nr_di_cui_analisi,
        nr_utile_impresa,
        dt_last_update,
        fl_analisi_approvata,
        fl_has_utile_impresa,
        fl_analisi_pubblicata,
        id_anag_versione,
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
        id_anag_provincia,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
 ) SELECT
        src.id_anag_articolo,
        src.id_sorgente_articolo,
        src.id_periodo_pubblicazione,
        src.cd_articolo,
        src.nr_livello,
        src.ds_nome,
        src.ds_descrizione,
        src.fl_eliminato,
        src.fl_prezzo_regionale,
        src.id_anag_unita_misura,
        src.id_anag_macro_gruppo,
        src.nr_spese_generali,
        src.nr_di_cui_analisi,
        src.nr_utile_impresa,
        src.dt_last_update,
        src.fl_analisi_approvata,
        src.fl_has_utile_impresa,
        src.fl_analisi_pubblicata,
        src.id_anag_versione,
        src.fl_is_analisi,
        src.fl_is_cam,
        src.fl_is_ufficiale,
        src.id_sorgente_categoria,
        src.fl_is_manodopera,
        src.cd_codice_lev1,
        src.cd_codice_lev2,
        src.cd_codice_lev3,
        src.cd_codice_lev4,
        src.cd_codice_lev5,
        src.fl_is_minuteria,
        src.nr_percentuale_aumento,
        src.ds_annotazione,
        src.fl_esporta_come_articolo,
        src.fl_escludi_manodopera,
        src.id_anag_provincia,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
 FROM hcbi_ras.tmp_dim_articolo src
 ON CONFLICT ON CONSTRAINT pk_dim_articolo DO NOTHING;
 GET DIAGNOSTICS v_inserted=ROW_COUNT;

 SELECT count(*) INTO v_matched FROM hcbi_ras.dim_articolo d
 JOIN hcbi_ras.tmp_dim_articolo src ON src.id_anag_articolo=d.id_anag_articolo;
 IF v_selected<>v_matched THEN RAISE EXCEPTION 'Riconciliazione DIM_ARTICOLO non valida: selected=%, matched=%',v_selected,v_matched; END IF;
 IF v_selected<>(SELECT count(*) FROM hcbi_ras.dwh_anag_articolo) THEN RAISE EXCEPTION 'Riconciliazione sorgente DIM_ARTICOLO non valida'; END IF;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 DROP TABLE hcbi_ras.tmp_dim_articolo; p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_context=PG_EXCEPTION_CONTEXT;
 p_result:=-1; BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dim_articolo; EXCEPTION WHEN OTHERS THEN NULL; END;
 v_log_error:=left(concat_ws(E'\n','SQLSTATE='||coalesce(v_sqlstate,''),'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),
  CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,
  CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,1000) END),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name);
 EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END; END IF;
 RAISE WARNING 'Errore MAIN DIM_ARTICOLO: SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;$procedure$
