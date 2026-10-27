/* =====================================================================
   DATAMART - FCT_PUBBLICAZIONE_ALBERO - VERSIONE 06
   Target verificato dai flussi allegati: PostgreSQL 15.9 / 17

   Modalita di caricamento:
     flusso Data Mart diretto, analogo ai flussi DIMENSIONALI.
     Non sono previste FRONTIERA, SRC_TMP o STG dedicate alla fact.
     La sorgente diretta e' HCBI_RAS.DWH_PUBBLICAZIONE_ALBERO.
   Concorrenza:
     la PRC_MAIN non deve essere eseguita in parallelo, poiche utilizza una
     tabella di lavoro con nome fisso e calcola i contatori prima dell'upsert.

   Grain:
     una riga per record di DWH_PUBBLICAZIONE_ALBERO, identificato da
     ID_PUBBLICAZIONE_ALBERO.

   Chiave primaria:
     ID_PUBBLICAZIONE_ALBERO, mantenuta dalla DWH sorgente.
     La fact non utilizza una sequence e non introduce una nuova chiave.

   Record tecnici:
     la fact non contiene righe tappo proprie. Le FK non risolte utilizzano
     il membro -1 delle dimensioni referenziate e vengono riallineate nei
     cicli successivi.

   Foreign key:
     DIM_PERIODO, DIM_PROVINCIA, DIM_ARTICOLO, DIM_VERSIONE,
     DIM_MACRO_GRUPPO.

   Regola speciale DIM_ARTICOLO:
     la query della V_SRV_MAPPA_PUBBLICAZIONE_ARTICOLO e' incorporata in una
     CTE della vista sorgente della fact. PUBBLICAZIONE_ARTICOLI viene
     raccordata a DWH_ANAG_ARTICOLO su anno + codice articolo + versione;
     PUBBLICAZIONE_ALBERO viene collegata alla mappa su anno + provincia +
     codice completo + versione. Il codice completo e' letto da
     DWH_PUBBLICAZIONE_ARTICOLI.CD_CODICE_COMPLETO. I nodi padre, riconosciuti
     per l'esistenza di articoli figli con lo stesso prefisso nella medesima
     pubblicazione, ricevono il membro tecnico 0 di DIM_ARTICOLO.

   Lookup dimensionali:
     - periodo: DIM_PERIODO.DS_ANNO;
     - provincia: DWH_ANAG_PROVINCIA su anno + cd_versione +
       id_sorgente_provincia, poi DIM_PROVINCIA tramite id_anag_provincia
       con verifica di anno + cd_versione;
     - articolo: DWH_ANAG_ARTICOLO su anno + provincia + codice + versione,
       poi
       DIM_ARTICOLO.ID_ANAG_ARTICOLO;
     - versione: DIM_VERSIONE su periodo + codice versione + provincia.
   Il contesto della Provincia e' CD_VERSIONE. Il flusso non utilizza il
   precedente attributo di contesto.
   DIM_AREA_VASTA resta una dipendenza di DIM_PROVINCIA e non viene
   referenziata direttamente dalla fact.
   ===================================================================== */

/* La query di mappatura pubblicazione-articolo e' incorporata nella
   vista sorgente della fact, evitando una dipendenza esterna dalla vista
   V_SRV_MAPPA_PUBBLICAZIONE_ARTICOLO. */

CREATE TABLE IF NOT EXISTS hcbi_ras.fct_pubblicazione_albero
(
    id_pubblicazione_albero bigint NOT NULL,
    id_periodo_pubblicazione integer NOT NULL,
    id_anag_provincia bigint NOT NULL,
    id_anag_articolo bigint NOT NULL,
    id_anag_versione bigint NOT NULL,
    nr_prezzo numeric(24,5),
    id_sorgente_um numeric(10,0),
    fl_isanalisi smallint,
    fl_isincidenza smallint,
    nr_scostamento double precision,
    nr_scostamento_con_spese double precision,
    fl_is_nuovo_codice smallint,
    fl_is_prezzo_modificato smallint,
    fl_is_prezzo_con_spese_modificato smallint,
    fl_is_analisi_modificata smallint,
    fl_is_descrizione_modificata smallint,
    fl_is_uinta_misura_modificata smallint,
    fl_is_spese_generali_modificate smallint,
    fl_is_utili_impresa_modificati smallint,
    fl_is_oneri_sicurezza_modificati smallint,
    fl_is_ufficiale smallint,
    id_sorgente_categoria bigint,
    ds_nome text,
    ds_link_cam varchar(60),
    ds_annotazione text,
    id_sorgente_pubblicazione_albero bigint,
    fl_esporta_come_articolo smallint,
    fl_escludi_manodopera smallint,
    fl_mostra_struttura_analisi smallint,
    id_anag_macro_gruppo bigint NOT NULL,
    fl_is_cam smallint,
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by varchar(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by varchar(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_reciclo timestamp without time zone,
    CONSTRAINT pk_fct_pubblicazione_albero PRIMARY KEY (id_pubblicazione_albero),
    CONSTRAINT fk_fct_pub_albero_periodo FOREIGN KEY (id_periodo_pubblicazione)
        REFERENCES hcbi_ras.dim_periodo (id_periodo),
    CONSTRAINT fk_fct_pub_albero_provincia FOREIGN KEY (id_anag_provincia)
        REFERENCES hcbi_ras.dim_provincia (id_anag_provincia),
    CONSTRAINT fk_fct_pub_albero_articolo FOREIGN KEY (id_anag_articolo)
        REFERENCES hcbi_ras.dim_articolo (id_anag_articolo),
    CONSTRAINT fk_fct_pub_albero_versione FOREIGN KEY (id_anag_versione)
        REFERENCES hcbi_ras.dim_versione (id_anag_versione),
    CONSTRAINT fk_fct_pub_albero_macro_gruppo FOREIGN KEY (id_anag_macro_gruppo)
        REFERENCES hcbi_ras.dim_macro_gruppo (id_anag_macro_gruppo)
);
ALTER TABLE hcbi_ras.fct_pubblicazione_albero OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.fct_pubblicazione_albero FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.fct_pubblicazione_albero TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE hcbi_ras.fct_pubblicazione_albero TO hcbi_utility;

/*
   La vista conserva una riga per record DWH. I join sono separati per rendere
   diagnosticabili dimensioni mancanti e cardinalita non univoche.
*/
CREATE OR REPLACE VIEW hcbi_ras.v_fct_pubblicazione_albero_src AS
WITH mappa_pubblicazione_articolo AS
(
    SELECT
        aa.id_anag_articolo,
        pa.cd_codice_completo,
        pa.ds_anno_pubblicazione,
        pa.id_sorgente_provincia,
        pa.cd_versione
    FROM hcbi_ras.dwh_pubblicazione_articoli AS pa
    JOIN hcbi_ras.dwh_anag_articolo AS aa
      ON aa.ds_anno = pa.ds_anno_pubblicazione::integer
     AND aa.cd_versione = pa.cd_versione
     AND aa.id_sorgente_provincia = pa.id_sorgente_provincia
     AND rtrim(aa.cd_articolo::text, '.') = rtrim(pa.cd_articolo::text, '.')
),
prefissi_pubblicazione_articolo AS
(
    SELECT DISTINCT
        figlio.ds_anno_pubblicazione,
        figlio.id_sorgente_provincia,
        figlio.cd_versione,
        array_to_string(parti.codice[1:livello.n], '.')::varchar(70) AS cd_articolo
    FROM hcbi_ras.dwh_pubblicazione_articoli AS figlio
    CROSS JOIN LATERAL
        (SELECT string_to_array(figlio.cd_codice_completo, '.') AS codice) AS parti
    CROSS JOIN LATERAL generate_series(1, cardinality(parti.codice) - 1) AS livello(n)
),
nodi_padre AS
(
    SELECT padre.id_pubblicazione_albero
    FROM prefissi_pubblicazione_articolo AS prefisso
    JOIN hcbi_ras.dwh_pubblicazione_albero AS padre
      ON padre.ds_anno_pubblicazione = prefisso.ds_anno_pubblicazione
     AND padre.id_sorgente_provincia = prefisso.id_sorgente_provincia
     AND padre.cd_versione = prefisso.cd_versione
     AND padre.cd_articolo = prefisso.cd_articolo
),
lookup_base AS
(
    SELECT
        src.*,
        COALESCE(per.id_periodo, -1::integer) AS id_periodo_pubblicazione_lkp,
        COALESCE(prv.id_anag_provincia, -1::bigint) AS id_anag_provincia_lkp,
        CASE
          WHEN nodo.id_pubblicazione_albero IS NOT NULL THEN 0::bigint
          ELSE COALESCE(art.id_anag_articolo, -1::bigint)
        END AS id_anag_articolo_lkp,
        CASE
          WHEN src.nr_macro_gruppo IS NULL THEN 0::bigint
          ELSE COALESCE(mg.id_anag_macro_gruppo, -1::bigint)
        END AS id_anag_macro_gruppo_lkp,
        per.id_periodo IS NULL AS fl_periodo_ko,
        prv.id_anag_provincia IS NULL AS fl_provincia_ko,
        nodo.id_pubblicazione_albero IS NULL
        AND (map.id_anag_articolo IS NULL OR art.id_anag_articolo IS NULL) AS fl_articolo_ko,
        src.nr_macro_gruppo IS NOT NULL AND mg.id_anag_macro_gruppo IS NULL AS fl_macro_gruppo_ko
    FROM hcbi_ras.dwh_pubblicazione_albero AS src
    LEFT JOIN hcbi_ras.dim_periodo AS per
      ON per.ds_anno::numeric = src.ds_anno_pubblicazione
    LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwh_prv
      ON dwh_prv.anno = src.ds_anno_pubblicazione::integer
     AND dwh_prv.cd_versione = src.cd_versione
     AND dwh_prv.id_sorgente_provincia = src.id_sorgente_provincia::bigint
    LEFT JOIN hcbi_ras.dim_provincia AS prv
      ON prv.id_anag_provincia = dwh_prv.id_anag_provincia
     AND prv.anno = dwh_prv.anno
     AND prv.cd_versione = dwh_prv.cd_versione
    LEFT JOIN nodi_padre AS nodo
      ON nodo.id_pubblicazione_albero = src.id_pubblicazione_albero
    /* Raccordo incorporato dalla V_SRV_MAPPA_PUBBLICAZIONE_ARTICOLO.
       La business key verso PUBBLICAZIONE_ARTICOLI e' composta da anno,
       provincia, codice completo e versione. CD_ARTICOLO della sorgente
       albero contiene il codice completo e viene quindi confrontato con
       DWH_PUBBLICAZIONE_ARTICOLI.CD_CODICE_COMPLETO. */
    LEFT JOIN mappa_pubblicazione_articolo AS map
      ON map.ds_anno_pubblicazione = src.ds_anno_pubblicazione
     AND map.id_sorgente_provincia = src.id_sorgente_provincia
     AND map.cd_codice_completo = src.cd_articolo
     AND map.cd_versione = src.cd_versione
    LEFT JOIN hcbi_ras.dim_articolo AS art
      ON art.id_anag_articolo = map.id_anag_articolo
    LEFT JOIN hcbi_ras.dwh_anag_macro_gruppo AS dwh_mg
      ON dwh_mg.id_sorgente_macro_gruppo = src.nr_macro_gruppo::bigint
    LEFT JOIN hcbi_ras.dim_macro_gruppo AS mg
      ON mg.id_anag_macro_gruppo = dwh_mg.id_anag_macro_gruppo
)
SELECT
    b.id_pubblicazione_albero,
    b.id_periodo_pubblicazione_lkp AS id_periodo_pubblicazione,
    b.id_anag_provincia_lkp AS id_anag_provincia,
    b.id_anag_articolo_lkp AS id_anag_articolo,
    COALESCE(ver.id_anag_versione, -1::bigint) AS id_anag_versione,
    b.nr_prezzo,
    b.id_sorgente_um,
    b.fl_isanalisi,
    b.fl_isincidenza,
    b.nr_scostamento,
    b.nr_scostamento_con_spese,
    b.fl_is_nuovo_codice,
    b.fl_is_prezzo_modificato,
    b.fl_is_prezzo_con_spese_modificato,
    b.fl_is_analisi_modificata,
    b.fl_is_descrizione_modificata,
    b.fl_is_uinta_misura_modificata,
    b.fl_is_spese_generali_modificate,
    b.fl_is_utili_impresa_modificati,
    b.fl_is_oneri_sicurezza_modificati,
    b.fl_is_ufficiale,
    b.id_sorgente_categoria,
    b.ds_nome,
    b.ds_link_cam,
    b.ds_annotazione,
    b.id_sorgente_pubblicazione_albero,
    b.fl_esporta_come_articolo,
    b.fl_escludi_manodopera,
    b.fl_mostra_struttura_analisi,
    b.id_anag_macro_gruppo_lkp AS id_anag_macro_gruppo,
    b.fl_is_cam,
    b.ds_anno_pubblicazione,
    b.id_sorgente_provincia,
    b.cd_articolo,
    b.cd_versione,
    NULLIF(concat_ws('; ',
        CASE WHEN b.fl_periodo_ko THEN 'FK DIM_PERIODO non risolta: applicato -1' END,
        CASE WHEN b.fl_provincia_ko THEN 'FK DIM_PROVINCIA non risolta: applicato -1' END,
        CASE WHEN b.fl_articolo_ko THEN 'FK DIM_ARTICOLO non risolta: applicato -1' END,
        CASE WHEN b.fl_macro_gruppo_ko THEN 'FK DIM_MACRO_GRUPPO non risolta: applicato -1' END,
        CASE WHEN ver.id_anag_versione IS NULL THEN 'FK DIM_VERSIONE non risolta: applicato -1' END
    ), '')::varchar(4000) AS tx_motivo_scarto
FROM lookup_base AS b
LEFT JOIN hcbi_ras.dim_versione AS ver
  ON ver.id_periodo_pubblicazione = b.id_periodo_pubblicazione_lkp
 AND ver.cd_versione = b.cd_versione
 AND ver.id_anag_provincia = b.id_anag_provincia_lkp;
ALTER VIEW hcbi_ras.v_fct_pubblicazione_albero_src OWNER TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_fct_pubblicazione_albero_src TO hcbi_ras, hcbi_utility;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pubblicazione_albero_prc_initialize(
    IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
    IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE v_id_log bigint;
BEGIN
  p_result := -1;
  SELECT hcbi_utility.pkg_log_fnc_insert_log(
    p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
    clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
  INTO v_id_log;
  CALL hcbi_utility.pkg_log_prc_update_log(
    v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
  p_result := 1;
EXCEPTION WHEN OTHERS THEN
  p_result := -1;
  IF v_id_log IS NOT NULL THEN
    CALL hcbi_utility.pkg_log_prc_error_update_log(
      v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),
      clock_timestamp()::timestamp,p_ds_step_name);
  END IF;
  RAISE WARNING 'Errore initialize FCT_PUBBLICAZIONE_ALBERO: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
END;
$BODY$;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pubblicazione_albero_prc_main(
    IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
    IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
  v_id_log bigint; v_selected bigint := 0; v_inserted bigint := 0;
  v_updated bigint := 0; v_deleted bigint := 0; v_errors bigint := 0;
  v_duplicate_rows bigint := 0;
BEGIN
  p_result := -1;
  SELECT hcbi_utility.pkg_log_fnc_insert_log(
    p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
    clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
  INTO v_id_log;

  IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo = -1)
     OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia = -1)
     OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_articolo WHERE id_anag_articolo = -1)
     OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_articolo WHERE id_anag_articolo = 0)
     OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione = -1)
     OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_macro_gruppo WHERE id_anag_macro_gruppo = -1)
     OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_macro_gruppo WHERE id_anag_macro_gruppo = 0)
  THEN
    RAISE EXCEPTION USING
      ERRCODE = '23503',
      MESSAGE = 'Membro tecnico richiesto mancante',
      DETAIL = 'Richiesti -1 per tutte le dimensioni; richiesto anche 0 per DIM_ARTICOLO e DIM_MACRO_GRUPPO.';
  END IF;

  /* Controlli di determinismo delle lookup contestualizzate. */
  IF EXISTS (
    SELECT 1 FROM hcbi_ras.dwh_anag_provincia
    WHERE id_sorgente_provincia IS NOT NULL
    GROUP BY anno, cd_versione, id_sorgente_provincia
    HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P0001',
      MESSAGE='Lookup DWH_ANAG_PROVINCIA non deterministica',
      DETAIL='Duplicati su anno, cd_versione e id_sorgente_provincia.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM hcbi_ras.dim_provincia
    WHERE cd_provincia IS NOT NULL
    GROUP BY anno, cd_versione, cd_provincia
    HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P0001',
      MESSAGE='Lookup DIM_PROVINCIA non deterministica',
      DETAIL='Duplicati su anno, cd_versione e cd_provincia.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM hcbi_ras.dim_periodo
    WHERE ds_anno IS NOT NULL
    GROUP BY ds_anno HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P0001',
      MESSAGE='Lookup DIM_PERIODO non deterministica',
      DETAIL='Duplicati su DIM_PERIODO.DS_ANNO.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM hcbi_ras.dim_versione
    GROUP BY id_periodo_pubblicazione, cd_versione, id_anag_provincia
    HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION USING ERRCODE='P0001',
      MESSAGE='Lookup DIM_VERSIONE non deterministica',
      DETAIL='Duplicati sulla business key di DIM_VERSIONE.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM hcbi_ras.dwh_pubblicazione_albero
    WHERE id_sorgente_provincia IS NOT NULL
      AND ds_anno_pubblicazione IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE='23502',
      MESSAGE='DS_ANNO_PUBBLICAZIONE nullo in DWH_PUBBLICAZIONE_ALBERO',
      DETAIL='L''anno e necessario per contestualizzare la Provincia.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM hcbi_ras.dwh_pubblicazione_albero
    WHERE id_sorgente_provincia IS NOT NULL
      AND cd_versione IS NOT NULL
      AND (cd_versione::numeric < -32768 OR cd_versione::numeric > 32767)
  ) THEN
    RAISE EXCEPTION USING ERRCODE='22003',
      MESSAGE='CD_VERSIONE fuori dominio SMALLINT in DWH_PUBBLICAZIONE_ALBERO',
      DETAIL='CD_VERSIONE deve rientrare nel dominio SMALLINT della Provincia.';
  END IF;
  IF EXISTS (
    SELECT 1 FROM hcbi_ras.dwh_pubblicazione_albero
    WHERE id_sorgente_provincia IS NOT NULL
      AND cd_versione IS NULL
  ) THEN
    RAISE EXCEPTION USING ERRCODE='23502',
      MESSAGE='CD_VERSIONE nullo in DWH_PUBBLICAZIONE_ALBERO',
      DETAIL='CD_VERSIONE e necessario per contestualizzare la Provincia.';
  END IF;

  DROP TABLE IF EXISTS hcbi_ras.tmp_fct_pubblicazione_albero_src;
  CREATE TABLE hcbi_ras.tmp_fct_pubblicazione_albero_src AS
  SELECT * FROM hcbi_ras.v_fct_pubblicazione_albero_src;

  SELECT count(*) INTO v_selected FROM hcbi_ras.dwh_pubblicazione_albero;
  SELECT count(*) INTO v_duplicate_rows
  FROM (SELECT id_pubblicazione_albero FROM hcbi_ras.tmp_fct_pubblicazione_albero_src
        GROUP BY id_pubblicazione_albero HAVING count(*) > 1) AS d;
  IF v_duplicate_rows > 0 THEN
    RAISE EXCEPTION USING ERRCODE='P0001',
      MESSAGE=format('Lookup non univoci per %s record PUBBLICAZIONE_ALBERO',v_duplicate_rows),
      HINT='Verificare unicita di DIM_PERIODO, DIM_PROVINCIA, DIM_VERSIONE e della mappa articolo.';
  END IF;

  SELECT count(*)
  INTO v_errors
  FROM hcbi_ras.tmp_fct_pubblicazione_albero_src
  WHERE tx_motivo_scarto IS NOT NULL;

  SELECT count(*)
  INTO v_inserted
  FROM hcbi_ras.tmp_fct_pubblicazione_albero_src AS src
  LEFT JOIN hcbi_ras.fct_pubblicazione_albero AS f
    ON f.id_pubblicazione_albero = src.id_pubblicazione_albero
  WHERE f.id_pubblicazione_albero IS NULL;

  SELECT count(*)
  INTO v_updated
  FROM hcbi_ras.tmp_fct_pubblicazione_albero_src AS src
  JOIN hcbi_ras.fct_pubblicazione_albero AS f
    ON f.id_pubblicazione_albero = src.id_pubblicazione_albero
  WHERE ROW(f.id_periodo_pubblicazione,f.id_anag_provincia,f.id_anag_articolo,
            f.id_anag_versione,f.nr_prezzo,f.id_sorgente_um,f.fl_isanalisi,
            f.fl_isincidenza,f.nr_scostamento,f.nr_scostamento_con_spese,
            f.fl_is_nuovo_codice,f.fl_is_prezzo_modificato,
            f.fl_is_prezzo_con_spese_modificato,f.fl_is_analisi_modificata,
            f.fl_is_descrizione_modificata,f.fl_is_uinta_misura_modificata,
            f.fl_is_spese_generali_modificate,f.fl_is_utili_impresa_modificati,
            f.fl_is_oneri_sicurezza_modificati,f.fl_is_ufficiale,
            f.id_sorgente_categoria,f.ds_nome,f.ds_link_cam,f.ds_annotazione,
            f.id_sorgente_pubblicazione_albero,f.fl_esporta_come_articolo,
            f.fl_escludi_manodopera,f.fl_mostra_struttura_analisi,
            f.id_anag_macro_gruppo,f.fl_is_cam)
     IS DISTINCT FROM
        ROW(src.id_periodo_pubblicazione,src.id_anag_provincia,
            src.id_anag_articolo,src.id_anag_versione,src.nr_prezzo,
            src.id_sorgente_um,src.fl_isanalisi,src.fl_isincidenza,
            src.nr_scostamento,src.nr_scostamento_con_spese,
            src.fl_is_nuovo_codice,src.fl_is_prezzo_modificato,
            src.fl_is_prezzo_con_spese_modificato,src.fl_is_analisi_modificata,
            src.fl_is_descrizione_modificata,src.fl_is_uinta_misura_modificata,
            src.fl_is_spese_generali_modificate,src.fl_is_utili_impresa_modificati,
            src.fl_is_oneri_sicurezza_modificati,src.fl_is_ufficiale,
            src.id_sorgente_categoria,src.ds_nome,src.ds_link_cam,src.ds_annotazione,
            src.id_sorgente_pubblicazione_albero,src.fl_esporta_come_articolo,
            src.fl_escludi_manodopera,src.fl_mostra_struttura_analisi,
            src.id_anag_macro_gruppo,src.fl_is_cam);

  INSERT INTO hcbi_ras.fct_pubblicazione_albero AS f
  (id_pubblicazione_albero,id_periodo_pubblicazione,id_anag_provincia,
   id_anag_articolo,id_anag_versione,nr_prezzo,id_sorgente_um,fl_isanalisi,
   fl_isincidenza,nr_scostamento,nr_scostamento_con_spese,fl_is_nuovo_codice,
   fl_is_prezzo_modificato,fl_is_prezzo_con_spese_modificato,
   fl_is_analisi_modificata,fl_is_descrizione_modificata,
   fl_is_uinta_misura_modificata,fl_is_spese_generali_modificate,
   fl_is_utili_impresa_modificati,fl_is_oneri_sicurezza_modificati,
   fl_is_ufficiale,id_sorgente_categoria,ds_nome,ds_link_cam,ds_annotazione,
   id_sorgente_pubblicazione_albero,fl_esporta_come_articolo,
   fl_escludi_manodopera,fl_mostra_struttura_analisi,id_anag_macro_gruppo,fl_is_cam,
   dt_creation,tx_creation_by,dt_update,tx_update_by)
  SELECT id_pubblicazione_albero,id_periodo_pubblicazione,id_anag_provincia,
   id_anag_articolo,id_anag_versione,nr_prezzo,id_sorgente_um,fl_isanalisi,
   fl_isincidenza,nr_scostamento,nr_scostamento_con_spese,fl_is_nuovo_codice,
   fl_is_prezzo_modificato,fl_is_prezzo_con_spese_modificato,
   fl_is_analisi_modificata,fl_is_descrizione_modificata,
   fl_is_uinta_misura_modificata,fl_is_spese_generali_modificate,
   fl_is_utili_impresa_modificati,fl_is_oneri_sicurezza_modificati,
   fl_is_ufficiale,id_sorgente_categoria,ds_nome,ds_link_cam,ds_annotazione,
   id_sorgente_pubblicazione_albero,fl_esporta_come_articolo,
   fl_escludi_manodopera,fl_mostra_struttura_analisi,id_anag_macro_gruppo,fl_is_cam,
   clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name
  FROM hcbi_ras.tmp_fct_pubblicazione_albero_src
  ON CONFLICT (id_pubblicazione_albero) DO UPDATE SET
    id_periodo_pubblicazione=EXCLUDED.id_periodo_pubblicazione,
    id_anag_provincia=EXCLUDED.id_anag_provincia,
    id_anag_articolo=EXCLUDED.id_anag_articolo,
    id_anag_versione=EXCLUDED.id_anag_versione,
    nr_prezzo=EXCLUDED.nr_prezzo,id_sorgente_um=EXCLUDED.id_sorgente_um,
    fl_isanalisi=EXCLUDED.fl_isanalisi,fl_isincidenza=EXCLUDED.fl_isincidenza,
    nr_scostamento=EXCLUDED.nr_scostamento,
    nr_scostamento_con_spese=EXCLUDED.nr_scostamento_con_spese,
    fl_is_nuovo_codice=EXCLUDED.fl_is_nuovo_codice,
    fl_is_prezzo_modificato=EXCLUDED.fl_is_prezzo_modificato,
    fl_is_prezzo_con_spese_modificato=EXCLUDED.fl_is_prezzo_con_spese_modificato,
    fl_is_analisi_modificata=EXCLUDED.fl_is_analisi_modificata,
    fl_is_descrizione_modificata=EXCLUDED.fl_is_descrizione_modificata,
    fl_is_uinta_misura_modificata=EXCLUDED.fl_is_uinta_misura_modificata,
    fl_is_spese_generali_modificate=EXCLUDED.fl_is_spese_generali_modificate,
    fl_is_utili_impresa_modificati=EXCLUDED.fl_is_utili_impresa_modificati,
    fl_is_oneri_sicurezza_modificati=EXCLUDED.fl_is_oneri_sicurezza_modificati,
    fl_is_ufficiale=EXCLUDED.fl_is_ufficiale,
    id_sorgente_categoria=EXCLUDED.id_sorgente_categoria,
    ds_nome=EXCLUDED.ds_nome,ds_link_cam=EXCLUDED.ds_link_cam,
    ds_annotazione=EXCLUDED.ds_annotazione,
    id_sorgente_pubblicazione_albero=EXCLUDED.id_sorgente_pubblicazione_albero,
    fl_esporta_come_articolo=EXCLUDED.fl_esporta_come_articolo,
    fl_escludi_manodopera=EXCLUDED.fl_escludi_manodopera,
    fl_mostra_struttura_analisi=EXCLUDED.fl_mostra_struttura_analisi,
    id_anag_macro_gruppo=EXCLUDED.id_anag_macro_gruppo,fl_is_cam=EXCLUDED.fl_is_cam,
    dt_update=clock_timestamp(),tx_update_by=p_ds_step_name
  WHERE ROW(f.id_periodo_pubblicazione,f.id_anag_provincia,f.id_anag_articolo,
            f.id_anag_versione,f.nr_prezzo,f.id_sorgente_um,f.fl_isanalisi,
            f.fl_isincidenza,f.nr_scostamento,f.nr_scostamento_con_spese,
            f.fl_is_nuovo_codice,f.fl_is_prezzo_modificato,
            f.fl_is_prezzo_con_spese_modificato,f.fl_is_analisi_modificata,
            f.fl_is_descrizione_modificata,f.fl_is_uinta_misura_modificata,
            f.fl_is_spese_generali_modificate,f.fl_is_utili_impresa_modificati,
            f.fl_is_oneri_sicurezza_modificati,f.fl_is_ufficiale,
            f.id_sorgente_categoria,f.ds_nome,f.ds_link_cam,f.ds_annotazione,
            f.id_sorgente_pubblicazione_albero,f.fl_esporta_come_articolo,
            f.fl_escludi_manodopera,f.fl_mostra_struttura_analisi,
            f.id_anag_macro_gruppo,f.fl_is_cam)
     IS DISTINCT FROM
        ROW(EXCLUDED.id_periodo_pubblicazione,EXCLUDED.id_anag_provincia,
            EXCLUDED.id_anag_articolo,EXCLUDED.id_anag_versione,
            EXCLUDED.nr_prezzo,EXCLUDED.id_sorgente_um,EXCLUDED.fl_isanalisi,
            EXCLUDED.fl_isincidenza,EXCLUDED.nr_scostamento,
            EXCLUDED.nr_scostamento_con_spese,EXCLUDED.fl_is_nuovo_codice,
            EXCLUDED.fl_is_prezzo_modificato,
            EXCLUDED.fl_is_prezzo_con_spese_modificato,
            EXCLUDED.fl_is_analisi_modificata,EXCLUDED.fl_is_descrizione_modificata,
            EXCLUDED.fl_is_uinta_misura_modificata,
            EXCLUDED.fl_is_spese_generali_modificate,
            EXCLUDED.fl_is_utili_impresa_modificati,
            EXCLUDED.fl_is_oneri_sicurezza_modificati,EXCLUDED.fl_is_ufficiale,
            EXCLUDED.id_sorgente_categoria,EXCLUDED.ds_nome,EXCLUDED.ds_link_cam,
            EXCLUDED.ds_annotazione,EXCLUDED.id_sorgente_pubblicazione_albero,
            EXCLUDED.fl_esporta_come_articolo,EXCLUDED.fl_escludi_manodopera,
            EXCLUDED.fl_mostra_struttura_analisi,EXCLUDED.id_anag_macro_gruppo,
            EXCLUDED.fl_is_cam);
  IF v_selected <> (SELECT count(*) FROM hcbi_ras.tmp_fct_pubblicazione_albero_src) THEN
    RAISE EXCEPTION 'La vista di lookup ha alterato la cardinalita sorgente';
  END IF;

  CALL hcbi_utility.pkg_log_prc_update_log(
    v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_errors,'SUCCESS',
    clock_timestamp()::timestamp,p_ds_step_name);
  DROP TABLE hcbi_ras.tmp_fct_pubblicazione_albero_src;
  p_result := 1;
EXCEPTION WHEN OTHERS THEN
  p_result := -1;
  BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_fct_pubblicazione_albero_src; EXCEPTION WHEN OTHERS THEN NULL; END;
  IF v_id_log IS NOT NULL THEN
    CALL hcbi_utility.pkg_log_prc_error_update_log(
      v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),
      clock_timestamp()::timestamp,p_ds_step_name);
  END IF;
  RAISE WARNING 'Errore main FCT_PUBBLICAZIONE_ALBERO: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
END;
$BODY$;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pubblicazione_albero_prc_finalize(
    IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
    IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE v_id_log bigint;
BEGIN
  p_result := -1;
  SELECT hcbi_utility.pkg_log_fnc_insert_log(
    p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
    clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
  INTO v_id_log;
  ANALYZE hcbi_ras.fct_pubblicazione_albero;
  CALL hcbi_utility.pkg_log_prc_update_log(
    v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
  p_result := 1;
EXCEPTION WHEN OTHERS THEN
  p_result := -1;
  IF v_id_log IS NOT NULL THEN
    CALL hcbi_utility.pkg_log_prc_error_update_log(
      v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),
      clock_timestamp()::timestamp,p_ds_step_name);
  END IF;
  RAISE WARNING 'Errore finalize FCT_PUBBLICAZIONE_ALBERO: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_fct_pubblicazione_albero_prc_initialize(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_fct_pubblicazione_albero_prc_main(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_fct_pubblicazione_albero_prc_finalize(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_pubblicazione_albero_prc_initialize(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_pubblicazione_albero_prc_main(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_pubblicazione_albero_prc_finalize(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;

COMMENT ON TABLE hcbi_ras.fct_pubblicazione_albero IS
'Fact Pubblicazione Albero alimentata direttamente da DWH_PUBBLICAZIONE_ALBERO; PK mantenuta dalla DWH e FK verso periodo, provincia, articolo, versione e macro-gruppo.';
COMMENT ON VIEW hcbi_ras.v_fct_pubblicazione_albero_src IS
'Risoluzione set-based delle FK dalla DWH_PUBBLICAZIONE_ALBERO; risolve la Provincia mediante anno, cd_versione e id_sorgente_provincia, incorpora la query di V_SRV_MAPPA_PUBBLICAZIONE_ARTICOLO e usa 0 per i nodi padre e -1 per i lookup articolo realmente mancanti.';


/* =====================================================================
   TEST POST-DEPLOYMENT
   ===================================================================== */

/* T01 - Verifica assenza di sequence dedicata.
   Atteso: zero righe. */
-- SELECT 1
-- FROM pg_catalog.pg_class AS c
-- JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
-- WHERE n.nspname = 'hcbi_ras'
--   AND c.relkind = 'S'
--   AND c.relname = 'seq_fct_pubblicazione_albero';

/* T02 - Verifica PK mantenuta dalla DWH.
   Atteso: id_pubblicazione_albero come unica colonna della PK. */
-- SELECT a.attname
-- FROM pg_catalog.pg_constraint AS con
-- JOIN pg_catalog.pg_class AS rel ON rel.oid = con.conrelid
-- JOIN pg_catalog.pg_namespace AS n ON n.oid = rel.relnamespace
-- CROSS JOIN LATERAL unnest(con.conkey) AS k(attnum)
-- JOIN pg_catalog.pg_attribute AS a
--   ON a.attrelid = rel.oid AND a.attnum = k.attnum
-- WHERE n.nspname = 'hcbi_ras'
--   AND rel.relname = 'fct_pubblicazione_albero'
--   AND con.contype = 'p';

/* T03 - Duplicati nella sorgente sulla PK. Atteso: zero righe. */
-- SELECT id_pubblicazione_albero, count(*)
-- FROM hcbi_ras.dwh_pubblicazione_albero
-- GROUP BY id_pubblicazione_albero
-- HAVING count(*) > 1;

/* T04 - Chiavi DWH non caricate nella fact. Atteso: zero. */
-- SELECT count(*) AS chiavi_non_caricate
-- FROM hcbi_ras.dwh_pubblicazione_albero AS src
-- LEFT JOIN hcbi_ras.fct_pubblicazione_albero AS f
--   ON f.id_pubblicazione_albero = src.id_pubblicazione_albero
-- WHERE f.id_pubblicazione_albero IS NULL;

/* T05 - Orfani FK. Atteso: zero. */
-- SELECT count(*) AS record_orfani
-- FROM hcbi_ras.fct_pubblicazione_albero AS f
-- LEFT JOIN hcbi_ras.dim_periodo AS p
--   ON p.id_periodo = f.id_periodo_pubblicazione
-- LEFT JOIN hcbi_ras.dim_provincia AS pr
--   ON pr.id_anag_provincia = f.id_anag_provincia
-- LEFT JOIN hcbi_ras.dim_articolo AS a
--   ON a.id_anag_articolo = f.id_anag_articolo
-- LEFT JOIN hcbi_ras.dim_versione AS v
--   ON v.id_anag_versione = f.id_anag_versione
-- LEFT JOIN hcbi_ras.dim_macro_gruppo AS mg
--   ON mg.id_anag_macro_gruppo = f.id_anag_macro_gruppo
-- WHERE p.id_periodo IS NULL
--    OR pr.id_anag_provincia IS NULL
--    OR a.id_anag_articolo IS NULL
--    OR v.id_anag_versione IS NULL
--    OR mg.id_anag_macro_gruppo IS NULL;

/* T06 - Lookup temporaneamente a -1, da monitorare e riciclare. */
-- SELECT
--   count(*) FILTER (WHERE id_periodo_pubblicazione = -1) AS periodo_nd,
--   count(*) FILTER (WHERE id_anag_provincia = -1) AS provincia_nd,
--   count(*) FILTER (WHERE id_anag_articolo = -1) AS articolo_nd,
--   count(*) FILTER (WHERE id_anag_versione = -1) AS versione_nd,
--   count(*) FILTER (WHERE id_anag_macro_gruppo = -1) AS macro_gruppo_nd
-- FROM hcbi_ras.fct_pubblicazione_albero;

/* T07 - Idempotenza.
   Rilanciare INITIALIZE, MAIN e FINALIZE senza modificare la DWH.
   Atteso nel log MAIN: inserted=0 e updated=0. */

/* T08 - Cardinalita della mappa incorporata.
   Atteso: zero righe. Eventuali risultati rendono non deterministica la
   lookup ID_ANAG_ARTICOLO per la fact. */
-- SELECT
--   pa.id_sorgente_provincia,
--   pa.ds_anno_pubblicazione,
--   pa.cd_codice_completo,
--   pa.cd_versione,
--   count(*)
-- FROM hcbi_ras.dwh_pubblicazione_articoli AS pa
-- JOIN hcbi_ras.dwh_anag_articolo AS aa
--   ON aa.ds_anno::numeric = pa.ds_anno_pubblicazione::numeric
--  AND aa.id_sorgente_provincia::bigint = pa.id_sorgente_provincia::bigint
--  AND trim(trailing '.' FROM btrim(aa.cd_articolo::text)) =
--      trim(trailing '.' FROM btrim(pa.cd_articolo::text))
--  AND btrim(aa.cd_versione::text) = btrim(pa.cd_versione::text)
-- GROUP BY pa.id_sorgente_provincia, pa.ds_anno_pubblicazione,
--          pa.cd_codice_completo, pa.cd_versione
-- HAVING count(*) > 1;

/* T09 - Regressione lookup articolo sui record verificati.
   Atteso: tre righe, ID_PUBBLICAZIONE_ARTICOLI e ID_ANAG_ARTICOLO valorizzati. */
-- SELECT
--   src.id_pubblicazione_albero,
--   pa.id_pubblicazione_articoli,
--   aa.id_anag_articolo
-- FROM hcbi_ras.dwh_pubblicazione_albero AS src
-- LEFT JOIN hcbi_ras.dwh_pubblicazione_articoli AS pa
--   ON pa.ds_anno_pubblicazione::numeric = src.ds_anno_pubblicazione::numeric
--  AND pa.id_sorgente_provincia::bigint = src.id_sorgente_provincia::bigint
--  AND btrim(pa.cd_codice_completo::text) = btrim(src.cd_articolo::text)
--  AND btrim(pa.cd_versione::text) = btrim(src.cd_versione::text)
-- LEFT JOIN hcbi_ras.dwh_anag_articolo AS aa
--   ON aa.ds_anno::numeric = pa.ds_anno_pubblicazione::numeric
--  AND aa.id_sorgente_provincia::bigint = pa.id_sorgente_provincia::bigint
--  AND trim(trailing '.' FROM btrim(aa.cd_articolo::text)) =
--      trim(trailing '.' FROM btrim(pa.cd_articolo::text))
--  AND btrim(aa.cd_versione::text) = btrim(pa.cd_versione::text)
-- WHERE src.id_pubblicazione_albero IN (27293, 9591, 5644)
--   AND pa.id_pubblicazione_articoli IS NOT NULL
--   AND aa.id_anag_articolo IS NOT NULL;

/* T10 - Nodi padre valorizzati con membro tecnico 0.
   Atteso: tre righe e ID_ANAG_ARTICOLO = 0. */
-- SELECT id_pubblicazione_albero, id_anag_articolo, tx_motivo_scarto
-- FROM hcbi_ras.v_fct_pubblicazione_albero_src
-- WHERE id_pubblicazione_albero IN (100, 199, 350)
-- ORDER BY id_pubblicazione_albero;

/* T11 - Nessun nodo padre classificato come articolo non risolto.
   Atteso: zero righe. */
-- SELECT src.id_pubblicazione_albero, src.cd_articolo
-- FROM hcbi_ras.dwh_pubblicazione_albero AS src
-- JOIN hcbi_ras.v_fct_pubblicazione_albero_src AS v
--   ON v.id_pubblicazione_albero = src.id_pubblicazione_albero
-- WHERE EXISTS
-- (
--     SELECT 1
--     FROM hcbi_ras.dwh_pubblicazione_articoli AS figlio
--     WHERE figlio.ds_anno_pubblicazione::numeric = src.ds_anno_pubblicazione::numeric
--       AND figlio.id_sorgente_provincia::bigint = src.id_sorgente_provincia::bigint
--       AND btrim(figlio.cd_versione::text) = btrim(src.cd_versione::text)
--       AND btrim(figlio.cd_codice_completo::text)
--           LIKE btrim(src.cd_articolo::text) || '.%'
-- )
-- AND v.id_anag_articolo <> 0;

/* T12 - Determinismo chiave operazionale DWH_ANAG_PROVINCIA. Atteso: zero righe. */
-- SELECT anno, cd_versione, id_sorgente_provincia, count(*)
-- FROM hcbi_ras.dwh_anag_provincia
-- WHERE id_sorgente_provincia IS NOT NULL
-- GROUP BY anno, cd_versione, id_sorgente_provincia
-- HAVING count(*) > 1;

/* T13 - Determinismo business key contestualizzata DIM_PROVINCIA. Atteso: zero righe. */
-- SELECT anno, cd_versione, cd_provincia, count(*)
-- FROM hcbi_ras.dim_provincia
-- WHERE cd_provincia IS NOT NULL
-- GROUP BY anno, cd_versione, cd_provincia
-- HAVING count(*) > 1;

/* =====================================================================
   ORDINE DI DEPLOYMENT
   1. DIM_PERIODO
   2. DIM_PROVINCIA
   3. DIM_ARTICOLO
   4. DIM_VERSIONE
   5. DIM_MACRO_GRUPPO
   6. FCT_PUBBLICAZIONE_ALBERO

   ROLLBACK STRUTTURALE PROPOSTO, da eseguire solo previa autorizzazione:
   DROP PROCEDURE delle tre procedure della fact;
   DROP VIEW V_FCT_PUBBLICAZIONE_ALBERO_SRC;
   DROP TABLE FCT_PUBBLICAZIONE_ALBERO;
   ===================================================================== */
