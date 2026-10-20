
/* FCT_PREZZI_RILEVATI - PostgreSQL 15.9/17
   Versione 02 aggiornata
   Grain: una riga per DWH_PREZZI_RILEVATI.ID_PREZZI_RILEVATI.

   Correzioni principali:
   1) lookup informatore su DWH_ANAG_INFORMATORI con:
      ID_SORGENTE_INFORMATORE + ID_SORGENTE_PROVINCIA +
      DS_ANNO_PUBBLICAZIONE + ADDENDUM + CD_VERSIONE;
   2) passaggio DWH_ANAG_INFORMATORI -> DIM_INFORMATORI sulla PK comune;
   3) lookup versione sulla business key dichiarata dalla DDL:
      periodo + codice versione + provincia;
   4) lookup articolo indipendente dalla lookup informatore;
   5) controlli bloccanti di cardinalita e lookup non univoci.

   Assunzione da validare:
   DIM_VERSIONE e DIM_ARTICOLO contengono gia le righe coerenti con
   periodo, versione e provincia dei prezzi. Lo script include test diagnostici.
*/

BEGIN;

CREATE TABLE IF NOT EXISTS hcbi_ras.fct_prezzi_rilevati
(
    id_prezzi_rilevati bigint NOT NULL,
    id_periodo_pubblicazione integer NOT NULL,
    id_anag_provincia bigint NOT NULL,
    id_anag_versione bigint NOT NULL,
    id_anag_articolo bigint NOT NULL,
    id_anag_informatore bigint NOT NULL,
    id_anag_utente_rilevatore bigint NOT NULL,
    nr_prezzo numeric(24,5) NOT NULL,
    dt_inserimento timestamp without time zone NOT NULL,
    fl_nascosto smallint NOT NULL,
    ds_anno_ribaltamento integer,
    cd_versione_ribaltamento integer,
    dt_last_update timestamp without time zone NOT NULL,
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by varchar(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by varchar(4000) NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT pk_fct_prezzi_rilevati PRIMARY KEY (id_prezzi_rilevati),
    CONSTRAINT ck_fct_prezzi_rilevati_nascosto CHECK (fl_nascosto IN (0,1)),
    CONSTRAINT fk_fct_prezzi_rilevati_periodo FOREIGN KEY (id_periodo_pubblicazione)
        REFERENCES hcbi_ras.dim_periodo(id_periodo),
    CONSTRAINT fk_fct_prezzi_rilevati_provincia FOREIGN KEY (id_anag_provincia)
        REFERENCES hcbi_ras.dim_provincia(id_anag_provincia),
    CONSTRAINT fk_fct_prezzi_rilevati_versione FOREIGN KEY (id_anag_versione)
        REFERENCES hcbi_ras.dim_versione(id_anag_versione),
    CONSTRAINT fk_fct_prezzi_rilevati_articolo FOREIGN KEY (id_anag_articolo)
        REFERENCES hcbi_ras.dim_articolo(id_anag_articolo),
    CONSTRAINT fk_fct_prezzi_rilevati_informatore FOREIGN KEY (id_anag_informatore)
        REFERENCES hcbi_ras.dim_informatori(id_anag_informatore),
    CONSTRAINT fk_fct_prezzi_rilevati_rilevatore FOREIGN KEY (id_anag_utente_rilevatore)
        REFERENCES hcbi_ras.dim_utenti(id_anag_utente)
);

ALTER TABLE hcbi_ras.fct_prezzi_rilevati OWNER TO hcbi_ras;
GRANT ALL ON TABLE hcbi_ras.fct_prezzi_rilevati TO hcbi_ras;
GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE hcbi_ras.fct_prezzi_rilevati TO hcbi_utility;

CREATE INDEX IF NOT EXISTS ix_fct_prezzi_rilevati_periodo ON hcbi_ras.fct_prezzi_rilevati(id_periodo_pubblicazione);
CREATE INDEX IF NOT EXISTS ix_fct_prezzi_rilevati_provincia ON hcbi_ras.fct_prezzi_rilevati(id_anag_provincia);
CREATE INDEX IF NOT EXISTS ix_fct_prezzi_rilevati_versione ON hcbi_ras.fct_prezzi_rilevati(id_anag_versione);
CREATE INDEX IF NOT EXISTS ix_fct_prezzi_rilevati_articolo ON hcbi_ras.fct_prezzi_rilevati(id_anag_articolo);
CREATE INDEX IF NOT EXISTS ix_fct_prezzi_rilevati_informatore ON hcbi_ras.fct_prezzi_rilevati(id_anag_informatore);
CREATE INDEX IF NOT EXISTS ix_fct_prezzi_rilevati_rilevatore ON hcbi_ras.fct_prezzi_rilevati(id_anag_utente_rilevatore);

COMMENT ON TABLE hcbi_ras.fct_prezzi_rilevati IS
'Fact atomica dei prezzi rilevati; grain ID_PREZZI_RILEVATI.';

/* Vista completa di lookup. Le colonne diagnostiche restano esposte ma non
   vengono persistite nella fact. */
CREATE OR REPLACE VIEW hcbi_ras.v_fct_prezzi_rilevati_src AS
WITH base AS MATERIALIZED
(
    SELECT
        p.id_prezzi_rilevati,
        p.cd_articolo,
        trim(trailing '.' FROM btrim(p.cd_articolo::text))::varchar(60) AS cd_articolo_normalizzato,		
        p.ds_anno,
        p.id_sorgente_provincia,
        p.id_sorgente_informatore,
        p.id_sorgente_rilevatore,
        p.nr_prezzo,
        p.dt_inserimento,
        p.fl_nascosto,
        p.ds_anno_ribaltamento,
        p.cd_versione,
        p.cd_versione_ribaltamento,
        p.dt_last_update,
        per.id_periodo,
        dpr.id_anag_provincia AS dwh_id_anag_provincia,
        prv.id_anag_provincia
    FROM hcbi_ras.dwh_prezzi_rilevati p
    LEFT JOIN hcbi_ras.dim_periodo per
      ON per.ds_anno = p.ds_anno
    LEFT JOIN hcbi_ras.dwh_anag_provincia dpr
      ON dpr.anno = p.ds_anno::integer
     AND dpr.addendum::text = p.cd_versione::text
     AND dpr.id_sorgente_provincia = p.id_sorgente_provincia::bigint
    LEFT JOIN hcbi_ras.dim_provincia prv
      ON prv.anno = dpr.anno
     AND prv.addendum = dpr.addendum
     AND prv.cd_provincia = dpr.cd_provincia
),
resolved AS MATERIALIZED
(
    SELECT
        b.*,
        ver.id_anag_versione,
        art.id_anag_articolo,
        dinf.id_anag_informatore AS dwh_id_anag_informatore,
        inf.id_anag_informatore,
        dusr.id_anag_utente AS dwh_id_anag_utente,
        usr.id_anag_utente AS id_anag_utente_rilevatore
    FROM base b
    /* Business key DIM_VERSIONE verificata nella DDL allegata. */
    LEFT JOIN hcbi_ras.dim_versione ver
      ON ver.id_periodo_pubblicazione = b.id_periodo
     AND ver.cd_versione = b.cd_versione
     AND ver.id_anag_provincia = b.id_anag_provincia
    /* Business key DIM_ARTICOLO verificata nella DDL allegata. */
    LEFT JOIN hcbi_ras.dim_articolo art
      ON art.id_periodo_pubblicazione = b.id_periodo
     AND btrim(art.cd_articolo) = btrim(b.cd_articolo_normalizzato)
     AND art.id_anag_versione = ver.id_anag_versione
     AND art.id_anag_provincia = b.id_anag_provincia
    /* Lookup informatore corretta: usa anche ID_SORGENTE_PROVINCIA. */
    LEFT JOIN hcbi_ras.dwh_anag_informatori dinf
      ON dinf.id_sorgente_informatore = b.id_sorgente_informatore
     AND dinf.id_sorgente_provincia = b.id_sorgente_provincia::bigint
     AND dinf.ds_anno_pubblicazione = b.ds_anno
     AND dinf.cd_versione::text = b.cd_versione::text
     AND dinf.cd_versione = b.cd_versione
    /* PK DWH mantenuta nella DIM: nessuna seconda ricostruzione della BK. */
    LEFT JOIN hcbi_ras.dim_informatori inf
      ON inf.id_anag_informatore = dinf.id_anag_informatore
    LEFT JOIN hcbi_ras.dwh_anag_utenti dusr
      ON dusr.id_sorgente_utente = b.id_sorgente_rilevatore::bigint
    LEFT JOIN hcbi_ras.dim_utenti usr
      ON usr.id_anag_utente = dusr.id_anag_utente
)
SELECT
    r.id_prezzi_rilevati,
    CASE WHEN r.id_periodo IS NULL THEN -1 ELSE r.id_periodo END AS id_periodo_pubblicazione,
    CASE WHEN r.id_anag_provincia IS NULL THEN -1 ELSE r.id_anag_provincia END AS id_anag_provincia,
    CASE WHEN r.id_anag_versione IS NULL THEN -1 ELSE r.id_anag_versione END AS id_anag_versione,
    CASE WHEN r.id_anag_articolo IS NULL THEN -1 ELSE r.id_anag_articolo END AS id_anag_articolo,
    CASE WHEN r.id_anag_informatore IS NULL THEN -1 ELSE r.id_anag_informatore END AS id_anag_informatore,
    CASE WHEN r.id_anag_utente_rilevatore IS NULL THEN -1 ELSE r.id_anag_utente_rilevatore END AS id_anag_utente_rilevatore,
    r.nr_prezzo, r.dt_inserimento, r.fl_nascosto,
    r.ds_anno_ribaltamento, r.cd_versione_ribaltamento, r.dt_last_update,
    r.cd_articolo, r.ds_anno, r.cd_versione,
    r.id_sorgente_provincia, r.id_sorgente_informatore, r.id_sorgente_rilevatore,
    NULLIF(concat_ws('; ',
      CASE WHEN r.id_periodo IS NULL THEN 'DIM_PERIODO non risolta' END,
      CASE WHEN r.dwh_id_anag_provincia IS NULL THEN 'DWH_ANAG_PROVINCIA non risolta' END,
      CASE WHEN r.id_anag_provincia IS NULL THEN 'DIM_PROVINCIA non risolta' END,
      CASE WHEN r.id_anag_versione IS NULL THEN 'DIM_VERSIONE non risolta su periodo+versione+provincia' END,
      CASE WHEN r.id_anag_articolo IS NULL THEN 'DIM_ARTICOLO non risolta su periodo+articolo+versione+provincia' END,
      CASE WHEN r.dwh_id_anag_informatore IS NULL THEN 'DWH_ANAG_INFORMATORI non risolta su informatore+provincia+anno+addendum+versione' END,
      CASE WHEN r.dwh_id_anag_informatore IS NOT NULL AND r.id_anag_informatore IS NULL THEN 'DIM_INFORMATORI non contiene la PK DWH' END,
      CASE WHEN r.dwh_id_anag_utente IS NULL THEN 'DWH_ANAG_UTENTI non risolta' END,
      CASE WHEN r.dwh_id_anag_utente IS NOT NULL AND r.id_anag_utente_rilevatore IS NULL THEN 'DIM_UTENTI non contiene la PK DWH' END
    ),'')::varchar(4000) AS tx_motivo_lookup
FROM resolved r;

ALTER VIEW hcbi_ras.v_fct_prezzi_rilevati_src OWNER TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_fct_prezzi_rilevati_src TO hcbi_ras,hcbi_utility;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_prezzi_rilevati_prc_initialize(
 p_id_chain_log bigint,p_id_chain bigint,p_id_step bigint,p_ds_step_name varchar,
 OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE v_id_log bigint; v_upd bigint:=0;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,
   p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
 INTO v_id_log;
 UPDATE hcbi_ras.dwh_prezzi_rilevati SET dt_reciclo=NULL WHERE dt_reciclo IS NOT NULL;
 UPDATE hcbi_ras.dwh_prezzi_rilevati d SET dt_reciclo=clock_timestamp()
 FROM hcbi_ras.fct_prezzi_rilevati f
 WHERE f.id_prezzi_rilevati=d.id_prezzi_rilevati
 AND (f.id_periodo_pubblicazione=-1 OR f.id_anag_provincia=-1
   OR f.id_anag_versione=-1 OR f.id_anag_articolo=-1
   OR f.id_anag_informatore=-1 OR f.id_anag_utente_rilevatore=-1);
 GET DIAGNOSTICS v_upd=ROW_COUNT;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_upd,0,v_upd,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 p_result:=1;
EXCEPTION WHEN OTHERS THEN
 p_result:=-1;
 IF v_id_log IS NOT NULL THEN
  BEGIN
   CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);
  EXCEPTION WHEN OTHERS THEN
   RAISE WARNING 'Errore logging FCT_PREZZI_RILEVATI: %',SQLERRM;
  END;
 END IF;
 RAISE;
END;$BODY$;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_prezzi_rilevati_prc_main(
 p_id_chain_log bigint,p_id_chain bigint,p_id_step bigint,p_ds_step_name varchar,
 OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE v_id_log bigint; v_sel bigint:=0; v_ins bigint:=0; v_upd bigint:=0; v_err bigint:=0;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,
   p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
 INTO v_id_log;

 IF NOT EXISTS(SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo=-1)
 OR NOT EXISTS(SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia=-1)
 OR NOT EXISTS(SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione=-1)
 OR NOT EXISTS(SELECT 1 FROM hcbi_ras.dim_articolo WHERE id_anag_articolo=-1)
 OR NOT EXISTS(SELECT 1 FROM hcbi_ras.dim_informatori WHERE id_anag_informatore=-1)
 OR NOT EXISTS(SELECT 1 FROM hcbi_ras.dim_utenti WHERE id_anag_utente=-1) THEN
  RAISE EXCEPTION 'Membri tecnici -1 mancanti nelle dimensioni della fact';
 END IF;

 /* Controlli preventivi sulle chiavi di lookup contestualizzate. */
 IF EXISTS(
   SELECT 1 FROM hcbi_ras.dwh_anag_provincia
   WHERE id_sorgente_provincia IS NOT NULL
   GROUP BY anno,addendum,id_sorgente_provincia
   HAVING count(*)>1
 ) THEN
  RAISE EXCEPTION 'Lookup DWH_ANAG_PROVINCIA non deterministica su anno, addendum, id_sorgente_provincia';
 END IF;
 IF EXISTS(
   SELECT 1 FROM hcbi_ras.dim_provincia
   WHERE cd_provincia IS NOT NULL
   GROUP BY anno,addendum,cd_provincia
   HAVING count(*)>1
 ) THEN
  RAISE EXCEPTION 'Lookup DIM_PROVINCIA non deterministica su anno, addendum, cd_provincia';
 END IF;
 IF EXISTS(
   SELECT 1 FROM hcbi_ras.dwh_anag_informatori
   WHERE id_sorgente_informatore IS NOT NULL
   GROUP BY id_sorgente_informatore,id_sorgente_provincia,
            ds_anno_pubblicazione,addendum,cd_versione
   HAVING count(*)>1
 ) THEN
  RAISE EXCEPTION 'Lookup DWH_ANAG_INFORMATORI non deterministica sulla business key contestualizzata';
 END IF;
 IF EXISTS(
   SELECT 1 FROM hcbi_ras.dim_periodo
   WHERE ds_anno IS NOT NULL GROUP BY ds_anno HAVING count(*)>1
 ) THEN
  RAISE EXCEPTION 'Lookup DIM_PERIODO non deterministica';
 END IF;
 IF EXISTS(
   SELECT 1 FROM hcbi_ras.dim_versione
   GROUP BY id_periodo_pubblicazione,cd_versione,id_anag_provincia
   HAVING count(*)>1
 ) THEN
  RAISE EXCEPTION 'Lookup DIM_VERSIONE non deterministica';
 END IF;
 IF EXISTS(
   SELECT 1 FROM hcbi_ras.dim_articolo
   GROUP BY id_periodo_pubblicazione,cd_articolo,id_anag_versione,id_anag_provincia
   HAVING count(*)>1
 ) THEN
  RAISE EXCEPTION 'Lookup DIM_ARTICOLO non deterministica';
 END IF;
 IF EXISTS(
   SELECT 1 FROM hcbi_ras.dwh_prezzi_rilevati
   WHERE id_sorgente_provincia IS NULL OR ds_anno IS NULL OR addendum IS NULL
 ) THEN
  RAISE EXCEPTION 'Contesto Provincia incompleto: ID_SORGENTE_PROVINCIA, DS_ANNO e ADDENDUM sono obbligatori';
 END IF;
 DROP TABLE IF EXISTS tmp_fct_prezzi_rilevati_src;
 CREATE TEMP TABLE tmp_fct_prezzi_rilevati_src ON COMMIT DROP AS
 SELECT * FROM hcbi_ras.v_fct_prezzi_rilevati_src;

 SELECT count(*) INTO v_sel FROM tmp_fct_prezzi_rilevati_src;
 IF v_sel<>(SELECT count(*) FROM hcbi_ras.dwh_prezzi_rilevati) THEN
  RAISE EXCEPTION 'Cardinalita vista (%) diversa dal DWH (%)',v_sel,(SELECT count(*) FROM hcbi_ras.dwh_prezzi_rilevati);
 END IF;
 IF EXISTS(SELECT 1 FROM tmp_fct_prezzi_rilevati_src GROUP BY id_prezzi_rilevati HAVING count(*)>1) THEN
  RAISE EXCEPTION 'Lookup non univoci nella vista FCT_PREZZI_RILEVATI';
 END IF;
 SELECT count(*) INTO v_err FROM tmp_fct_prezzi_rilevati_src WHERE tx_motivo_lookup IS NOT NULL;
 SELECT count(*) INTO v_ins FROM tmp_fct_prezzi_rilevati_src s LEFT JOIN hcbi_ras.fct_prezzi_rilevati f USING(id_prezzi_rilevati) WHERE f.id_prezzi_rilevati IS NULL;
 SELECT count(*) INTO v_upd FROM tmp_fct_prezzi_rilevati_src s JOIN hcbi_ras.fct_prezzi_rilevati f USING(id_prezzi_rilevati)
 WHERE ROW(f.id_periodo_pubblicazione,f.id_anag_provincia,f.id_anag_versione,f.id_anag_articolo,f.id_anag_informatore,f.id_anag_utente_rilevatore,f.nr_prezzo,f.dt_inserimento,f.fl_nascosto,f.ds_anno_ribaltamento,f.cd_versione_ribaltamento,f.dt_last_update)
 IS DISTINCT FROM ROW(s.id_periodo_pubblicazione,s.id_anag_provincia,s.id_anag_versione,s.id_anag_articolo,s.id_anag_informatore,s.id_anag_utente_rilevatore,s.nr_prezzo,s.dt_inserimento,s.fl_nascosto,s.ds_anno_ribaltamento,s.cd_versione_ribaltamento,s.dt_last_update);

 INSERT INTO hcbi_ras.fct_prezzi_rilevati AS f
 (id_prezzi_rilevati,id_periodo_pubblicazione,id_anag_provincia,id_anag_versione,
  id_anag_articolo,id_anag_informatore,id_anag_utente_rilevatore,nr_prezzo,
  dt_inserimento,fl_nascosto,ds_anno_ribaltamento,cd_versione_ribaltamento,
  dt_last_update,dt_creation,tx_creation_by,dt_update,tx_update_by)
 SELECT id_prezzi_rilevati,id_periodo_pubblicazione,id_anag_provincia,id_anag_versione,
  id_anag_articolo,id_anag_informatore,id_anag_utente_rilevatore,nr_prezzo,
  dt_inserimento,fl_nascosto,ds_anno_ribaltamento,cd_versione_ribaltamento,
  dt_last_update,clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name
 FROM tmp_fct_prezzi_rilevati_src
 ON CONFLICT(id_prezzi_rilevati) DO UPDATE SET
  id_periodo_pubblicazione=EXCLUDED.id_periodo_pubblicazione,
  id_anag_provincia=EXCLUDED.id_anag_provincia,
  id_anag_versione=EXCLUDED.id_anag_versione,
  id_anag_articolo=EXCLUDED.id_anag_articolo,
  id_anag_informatore=EXCLUDED.id_anag_informatore,
  id_anag_utente_rilevatore=EXCLUDED.id_anag_utente_rilevatore,
  nr_prezzo=EXCLUDED.nr_prezzo,dt_inserimento=EXCLUDED.dt_inserimento,
  fl_nascosto=EXCLUDED.fl_nascosto,ds_anno_ribaltamento=EXCLUDED.ds_anno_ribaltamento,
  cd_versione_ribaltamento=EXCLUDED.cd_versione_ribaltamento,
  dt_last_update=EXCLUDED.dt_last_update,dt_update=clock_timestamp(),tx_update_by=p_ds_step_name
 WHERE ROW(f.id_periodo_pubblicazione,f.id_anag_provincia,f.id_anag_versione,f.id_anag_articolo,f.id_anag_informatore,f.id_anag_utente_rilevatore,f.nr_prezzo,f.dt_inserimento,f.fl_nascosto,f.ds_anno_ribaltamento,f.cd_versione_ribaltamento,f.dt_last_update)
 IS DISTINCT FROM ROW(EXCLUDED.id_periodo_pubblicazione,EXCLUDED.id_anag_provincia,EXCLUDED.id_anag_versione,EXCLUDED.id_anag_articolo,EXCLUDED.id_anag_informatore,EXCLUDED.id_anag_utente_rilevatore,EXCLUDED.nr_prezzo,EXCLUDED.dt_inserimento,EXCLUDED.fl_nascosto,EXCLUDED.ds_anno_ribaltamento,EXCLUDED.cd_versione_ribaltamento,EXCLUDED.dt_last_update);

 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_sel,v_ins,v_upd,0,v_err,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 p_result:=1;
EXCEPTION WHEN OTHERS THEN
 p_result:=-1;
 IF v_id_log IS NOT NULL THEN
  BEGIN
   CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);
  EXCEPTION WHEN OTHERS THEN
   RAISE WARNING 'Errore logging FCT_PREZZI_RILEVATI: %',SQLERRM;
  END;
 END IF;
 RAISE;
END;$BODY$;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_prezzi_rilevati_prc_finalize(
 p_id_chain_log bigint,p_id_chain bigint,p_id_step bigint,p_ds_step_name varchar,
 OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE v_id_log bigint;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,
 p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 ANALYZE hcbi_ras.fct_prezzi_rilevati;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 p_result:=1;
EXCEPTION WHEN OTHERS THEN
 p_result:=-1;
 IF v_id_log IS NOT NULL THEN
  BEGIN
   CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);
  EXCEPTION WHEN OTHERS THEN
   RAISE WARNING 'Errore logging FCT_PREZZI_RILEVATI: %',SQLERRM;
  END;
 END IF;
 RAISE;
END;$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_fct_prezzi_rilevati_prc_initialize(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_fct_prezzi_rilevati_prc_main(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_fct_prezzi_rilevati_prc_finalize(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_prezzi_rilevati_prc_initialize(bigint,bigint,bigint,varchar) TO hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_prezzi_rilevati_prc_main(bigint,bigint,bigint,varchar) TO hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_prezzi_rilevati_prc_finalize(bigint,bigint,bigint,varchar) TO hcbi_utility;

--COMMIT;

/* =========================== TEST ================================
T01 - I membri tecnici devono esistere. Atteso: tutte TRUE. */
-- SELECT
-- EXISTS(SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo=-1) periodo,
-- EXISTS(SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia=-1) provincia,
-- EXISTS(SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione=-1) versione,
-- EXISTS(SELECT 1 FROM hcbi_ras.dim_articolo WHERE id_anag_articolo=-1) articolo,
-- EXISTS(SELECT 1 FROM hcbi_ras.dim_informatori WHERE id_anag_informatore=-1) informatore,
-- EXISTS(SELECT 1 FROM hcbi_ras.dim_utenti WHERE id_anag_utente=-1) utente;

/* T02 - Unicita business key DWH informatori. Atteso: zero righe. */
-- SELECT id_sorgente_informatore,id_sorgente_provincia,
--        ds_anno_pubblicazione,addendum,cd_versione,count(*)
-- FROM hcbi_ras.dwh_anag_informatori
-- GROUP BY 1,2,3,4,5 HAVING count(*)>1;

/* T03 - Copertura lookup informatore usando la provincia. */
-- SELECT count(*) totale,
-- count(i.id_anag_informatore) risolti,
-- count(*) FILTER(WHERE i.id_anag_informatore IS NULL) non_risolti
-- FROM hcbi_ras.dwh_prezzi_rilevati p
-- LEFT JOIN hcbi_ras.dwh_anag_informatori i
-- ON i.id_sorgente_informatore=p.id_sorgente_informatore
-- AND i.id_sorgente_provincia=p.id_sorgente_provincia::bigint
-- AND i.ds_anno_pubblicazione=p.ds_anno
-- AND i.addendum=p.addendum
-- AND i.cd_versione=p.cd_versione;

/* T04 - Copertura versione per componente della BK. */
-- SELECT p.ds_anno,p.addendum,p.cd_versione,p.id_sorgente_provincia,
-- per.id_periodo,prv.id_anag_provincia,count(*) nr_prezzi,
-- count(ver.id_anag_versione) nr_versioni_risolte
-- FROM hcbi_ras.dwh_prezzi_rilevati p
-- LEFT JOIN hcbi_ras.dim_periodo per ON per.ds_anno=p.ds_anno
-- LEFT JOIN hcbi_ras.dwh_anag_provincia dp
--   ON dp.anno=p.ds_anno::integer
--  AND dp.addendum=p.addendum::integer
--  AND dp.id_sorgente_provincia=p.id_sorgente_provincia::bigint
-- LEFT JOIN hcbi_ras.dim_provincia prv
--   ON prv.anno=dp.anno
--  AND prv.addendum=dp.addendum
--  AND prv.cd_provincia=dp.cd_provincia
-- LEFT JOIN hcbi_ras.dim_versione ver ON ver.id_periodo_pubblicazione=per.id_periodo
-- AND ver.cd_versione=p.cd_versione AND ver.id_anag_provincia=prv.id_anag_provincia
-- GROUP BY 1,2,3,4,5,6 ORDER BY 1,2,3,4;

/* T05 - Cardinalita. Atteso: conteggi uguali. */
-- SELECT (SELECT count(*) FROM hcbi_ras.dwh_prezzi_rilevati) dwh,
-- (SELECT count(*) FROM hcbi_ras.v_fct_prezzi_rilevati_src) vista;

/* T06 - Dettaglio anomalie. Atteso a regime: zero righe. */
-- SELECT id_prezzi_rilevati,ds_anno,cd_versione,id_sorgente_provincia,
-- cd_articolo,id_sorgente_informatore,tx_motivo_lookup
-- FROM hcbi_ras.v_fct_prezzi_rilevati_src
-- WHERE tx_motivo_lookup IS NOT NULL ORDER BY id_prezzi_rilevati;

/* T07 - Distribuzione tappi dopo il carico. */
-- SELECT count(*) totale,
-- count(*) FILTER(WHERE id_anag_versione=-1) versione_nd,
-- count(*) FILTER(WHERE id_anag_articolo=-1) articolo_nd,
-- count(*) FILTER(WHERE id_anag_informatore=-1) informatore_nd
-- FROM hcbi_ras.fct_prezzi_rilevati;

/* T08 - Integrita referenziale logica. Atteso: zero. */
-- SELECT count(*) orfani FROM hcbi_ras.fct_prezzi_rilevati f
-- LEFT JOIN hcbi_ras.dim_versione v ON v.id_anag_versione=f.id_anag_versione
-- LEFT JOIN hcbi_ras.dim_articolo a ON a.id_anag_articolo=f.id_anag_articolo
-- LEFT JOIN hcbi_ras.dim_informatori i ON i.id_anag_informatore=f.id_anag_informatore
-- WHERE v.id_anag_versione IS NULL OR a.id_anag_articolo IS NULL OR i.id_anag_informatore IS NULL;

/* T09 - Riconciliazione conteggi e prezzo. */
-- SELECT
-- (SELECT count(*) FROM hcbi_ras.dwh_prezzi_rilevati) righe_dwh,
-- (SELECT count(*) FROM hcbi_ras.fct_prezzi_rilevati) righe_fact,
-- (SELECT sum(nr_prezzo) FROM hcbi_ras.dwh_prezzi_rilevati) prezzo_dwh,
-- (SELECT sum(nr_prezzo) FROM hcbi_ras.fct_prezzi_rilevati) prezzo_fact;

/* T10 - Idempotenza: rilanciare MAIN senza modifiche DWH.
   Atteso nel log: inseriti=0, aggiornati=0. */

/* T11 - Determinismo chiave operazionale DWH_ANAG_PROVINCIA. Atteso: zero righe. */
-- SELECT anno,addendum,id_sorgente_provincia,count(*)
-- FROM hcbi_ras.dwh_anag_provincia
-- WHERE id_sorgente_provincia IS NOT NULL
-- GROUP BY anno,addendum,id_sorgente_provincia HAVING count(*)>1;
/* T12 - Determinismo business key DIM_PROVINCIA. Atteso: zero righe. */
-- SELECT anno,addendum,cd_provincia,count(*)
-- FROM hcbi_ras.dim_provincia
-- WHERE cd_provincia IS NOT NULL
-- GROUP BY anno,addendum,cd_provincia HAVING count(*)>1;
/* DEPLOYMENT
   1. Eseguire T01-T04 prima del deploy.
   2. Acquisire restore point secondo la procedura autorizzata.
   3. Eseguire lo script in transazione.
   4. Eseguire INITIALIZE, MAIN, FINALIZE.
   5. Eseguire T05-T10.
   Rollback applicativo: ripristinare la precedente definizione della vista e
   delle procedure. DROP TABLE solo se autorizzato e previo backup della fact.
*/
