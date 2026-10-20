/* =====================================================================
   FLUSSO PREZZI_RILEVATI
   Target: PostgreSQL 15.9 / 17
   Sorgente operazionale: public.prezzi_rilevati

   Grain DWH proposto:
     una riga per (codice, anno, provincia, addendum, informatore).

   Nota chiavi:
     la sorgente ha PK a 6 colonne, incluso rilevatore, ma applica anche
     una UNIQUE a 5 colonne che esclude rilevatore. Poiche' la UNIQUE e'
     piu' restrittiva, questa viene adottata come chiave naturale DWH;
     rilevatore resta un attributo aggiornabile.
   ===================================================================== */

CREATE SEQUENCE IF NOT EXISTS hcbi_ras.seq_dwh_prezzi_rilevati
    AS bigint INCREMENT 1 START 1 MINVALUE 1 CACHE 1;
ALTER SEQUENCE hcbi_ras.seq_dwh_prezzi_rilevati OWNER TO hcbi_ras;
GRANT ALL ON SEQUENCE hcbi_ras.seq_dwh_prezzi_rilevati TO hcbi_ras;
GRANT USAGE, SELECT ON SEQUENCE hcbi_ras.seq_dwh_prezzi_rilevati TO hcbi_utility;

/* ============================== FRONTIERA ============================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.frontiera_prezzi_rilevati (
    codice varchar(60),
	anno varchar(100),
	provincia varchar(100),
    informatore varchar(100),
	rilevatore varchar(100),
	prezzo varchar(100),
    data_inserimento timestamp without time zone,
	nascosto varchar(20),
    ribaltato_da_anno varchar(100), 
	addendum varchar(20),
    ribaltato_da_addendum varchar(100), 
	last_update timestamp without time zone
);
ALTER TABLE hcbi_ras.frontiera_prezzi_rilevati OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.frontiera_prezzi_rilevati FROM hcbi_utility;
GRANT ALL ON hcbi_ras.frontiera_prezzi_rilevati TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.frontiera_prezzi_rilevati TO hcbi_utility;

/* ============================== SRC_TMP ================================ */
CREATE TABLE IF NOT EXISTS hcbi_ras.src_tmp_prezzi_rilevati
(LIKE hcbi_ras.frontiera_prezzi_rilevati INCLUDING DEFAULTS);
ALTER TABLE hcbi_ras.src_tmp_prezzi_rilevati OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.src_tmp_prezzi_rilevati FROM hcbi_utility;
GRANT ALL ON hcbi_ras.src_tmp_prezzi_rilevati TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.src_tmp_prezzi_rilevati TO hcbi_utility;

CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_prezzi_rilevati AS
SELECT btrim(s.codice) AS cd_articolo,
       btrim(s.anno) AS ds_anno,
       btrim(s.provincia) AS id_sorgente_provincia,
       btrim(s.informatore) AS id_sorgente_informatore,
       btrim(s.rilevatore) AS id_sorgente_rilevatore,
       btrim(s.prezzo) AS nr_prezzo,
       s.data_inserimento AS dt_inserimento,
       btrim(s.nascosto) AS fl_nascosto,
       btrim(s.ribaltato_da_anno) AS ds_anno_ribaltamento,
       btrim(s.addendum) AS cd_versione,
       btrim(s.ribaltato_da_addendum) AS cd_versione_ribaltamento,
       s.last_update AS dt_last_update
FROM hcbi_ras.src_tmp_prezzi_rilevati s;
ALTER VIEW hcbi_ras.v_src_tmp_prezzi_rilevati OWNER TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_src_tmp_prezzi_rilevati TO hcbi_utility;

/* ============================== STAGING ================================ */
CREATE TABLE IF NOT EXISTS hcbi_ras.stg_prezzi_rilevati (
    cd_articolo varchar(60) NOT NULL,
    ds_anno integer NOT NULL,
    id_sorgente_provincia integer NOT NULL,
    id_sorgente_informatore integer NOT NULL,
    id_sorgente_rilevatore integer NOT NULL,
    nr_prezzo numeric(24,5) NOT NULL,
    dt_inserimento timestamp without time zone NOT NULL,
    fl_nascosto smallint NOT NULL,
    ds_anno_ribaltamento integer,
    cd_versione smallint NOT NULL,
    cd_versione_ribaltamento integer,
    dt_last_update timestamp without time zone NOT NULL,
    CONSTRAINT ck_stg_prezzi_rilevati_nascosto CHECK (fl_nascosto IN (0,1))
);
ALTER TABLE hcbi_ras.stg_prezzi_rilevati OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.stg_prezzi_rilevati FROM hcbi_utility;
GRANT ALL ON hcbi_ras.stg_prezzi_rilevati TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.stg_prezzi_rilevati TO hcbi_utility;

CREATE TABLE IF NOT EXISTS hcbi_ras.stg_prezzi_rilevati_rej (
    cd_articolo varchar(60), ds_anno varchar(100),
    id_sorgente_provincia varchar(100), id_sorgente_informatore varchar(100),
    id_sorgente_rilevatore varchar(100), nr_prezzo varchar(100),
    dt_inserimento timestamp without time zone, fl_nascosto varchar(20),
    ds_anno_ribaltamento varchar(100), cd_versione varchar(20),
    cd_versione_ribaltamento varchar(100), dt_last_update timestamp without time zone,
    tx_motivo_scarto varchar(4000), dt_scarto timestamp without time zone NOT NULL DEFAULT clock_timestamp()
);
ALTER TABLE hcbi_ras.stg_prezzi_rilevati_rej OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.stg_prezzi_rilevati_rej FROM hcbi_utility;
GRANT ALL ON hcbi_ras.stg_prezzi_rilevati_rej TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.stg_prezzi_rilevati_rej TO hcbi_utility;

/* ================================ DWH ================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dwh_prezzi_rilevati (
    id_prezzi_rilevati bigint NOT NULL DEFAULT nextval('hcbi_ras.seq_dwh_prezzi_rilevati'::regclass),
    cd_articolo varchar(60) NOT NULL,
    ds_anno integer NOT NULL,
    id_sorgente_provincia integer NOT NULL,
    id_sorgente_informatore integer NOT NULL,
    id_sorgente_rilevatore integer NOT NULL,
    nr_prezzo numeric(24,5) NOT NULL,
    dt_inserimento timestamp without time zone NOT NULL,
    fl_nascosto smallint NOT NULL,
    ds_anno_ribaltamento integer,
    cd_versione smallint NOT NULL,
    cd_versione_ribaltamento integer,
    dt_last_update timestamp without time zone NOT NULL,
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by varchar(4000) NOT NULL DEFAULT current_user,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by varchar(4000) NOT NULL DEFAULT current_user,
    dt_reciclo timestamp without time zone,
    CONSTRAINT pk_dwh_prezzi_rilevati PRIMARY KEY (id_prezzi_rilevati),
    CONSTRAINT uk_dwh_prezzi_rilevati UNIQUE
      (cd_articolo, ds_anno, id_sorgente_provincia, cd_versione, id_sorgente_informatore),
    CONSTRAINT ck_dwh_prezzi_rilevati_nascosto CHECK (fl_nascosto IN (0,1))
);
CREATE INDEX IF NOT EXISTS ix_dwh_prezzi_rilevati_articolo
ON hcbi_ras.dwh_prezzi_rilevati (cd_articolo, ds_anno, cd_versione);
ALTER TABLE hcbi_ras.dwh_prezzi_rilevati OWNER TO hcbi_ras;
REVOKE ALL ON hcbi_ras.dwh_prezzi_rilevati FROM hcbi_utility;
GRANT ALL ON hcbi_ras.dwh_prezzi_rilevati TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE ON hcbi_ras.dwh_prezzi_rilevati TO hcbi_utility;

CREATE OR REPLACE VIEW hcbi_ras.v_dwh_prezzi_rilevati AS
SELECT cd_articolo, ds_anno, id_sorgente_provincia, id_sorgente_informatore,
       id_sorgente_rilevatore, nr_prezzo, dt_inserimento, fl_nascosto,
       ds_anno_ribaltamento, cd_versione, cd_versione_ribaltamento, dt_last_update
FROM hcbi_ras.stg_prezzi_rilevati;
ALTER VIEW hcbi_ras.v_dwh_prezzi_rilevati OWNER TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_dwh_prezzi_rilevati TO hcbi_utility;

/* Funzioni try_* attese dal pattern ANAG_ARTICOLO:
   hcbi_ras.try_integer(text), try_smallint(text), try_numeric_24_5(text).
*/

/* ============================ STG INITIALIZE =========================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_prezzi_rilevati_prc_initialize(
 IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
 IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility AS $BODY$
DECLARE v_id_log bigint;
BEGIN
 p_result := -1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
   clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 TRUNCATE hcbi_ras.stg_prezzi_rilevati, hcbi_ras.stg_prezzi_rilevati_rej;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 p_result := 1;
EXCEPTION WHEN OTHERS THEN
 p_result := -1;
 IF v_id_log IS NOT NULL THEN
  BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',
    left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);
  EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
 END IF;
 RAISE WARNING 'Errore initialize STG PREZZI_RILEVATI: %',SQLERRM;
END;$BODY$;

/* ============================== STG MAIN =============================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_prezzi_rilevati_prc_main(
 IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
 IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility AS $BODY$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0;
 v_rejected bigint:=0; v_updated bigint:=0; v_deleted bigint:=0;
BEGIN
 p_result := -1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
  clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 DROP TABLE IF EXISTS hcbi_ras.tmp_prezzi_rilevati_classificata;
 CREATE TABLE hcbi_ras.tmp_prezzi_rilevati_classificata AS
 WITH src AS MATERIALIZED (
  SELECT f.*,
   NULLIF(btrim(f.cd_articolo),'') codice_txt,
   NULLIF(btrim(f.ds_anno),'') anno_txt,
   NULLIF(btrim(f.id_sorgente_provincia),'') provincia_txt,
   NULLIF(btrim(f.id_sorgente_informatore),'') informatore_txt,
   NULLIF(btrim(f.id_sorgente_rilevatore),'') rilevatore_txt,
   NULLIF(btrim(f.nr_prezzo),'') prezzo_txt,
   NULLIF(btrim(f.fl_nascosto),'') nascosto_txt,
   NULLIF(btrim(f.ds_anno_ribaltamento),'') rib_anno_txt,
   NULLIF(btrim(f.cd_versione),'') addendum_txt,
   NULLIF(btrim(f.cd_versione_ribaltamento),'') rib_addendum_txt,
   count(*) OVER(PARTITION BY f.cd_articolo,f.ds_anno,f.id_sorgente_provincia,
                              f.cd_versione,f.id_sorgente_informatore) duplicate_count
  FROM hcbi_ras.v_src_tmp_prezzi_rilevati f
 ), cv AS MATERIALIZED (
  SELECT s.*,
   s.codice_txt codice_cv, hcbi_ras.try_integer(s.anno_txt) anno_cv,
   hcbi_ras.try_integer(s.provincia_txt) provincia_cv,
   hcbi_ras.try_integer(s.informatore_txt) informatore_cv,
   hcbi_ras.try_integer(s.rilevatore_txt) rilevatore_cv,
   hcbi_ras.try_numeric_24_5(replace(s.prezzo_txt,',','.')) prezzo_cv,
   hcbi_ras.try_smallint(s.nascosto_txt) nascosto_cv,
   hcbi_ras.try_integer(s.rib_anno_txt) rib_anno_cv,
   hcbi_ras.try_smallint(s.addendum_txt) addendum_cv,
   hcbi_ras.try_integer(s.rib_addendum_txt) rib_addendum_cv
  FROM src s
 )
 SELECT cv.*,
  CASE
   WHEN duplicate_count>1 THEN 'Chiave duplicata: (codice, anno, provincia, addendum, informatore)'
   WHEN codice_txt IS NULL THEN 'codice obbligatorio'
   WHEN length(codice_txt)>60 THEN 'codice eccede 60 caratteri'
   WHEN anno_txt IS NULL THEN 'anno obbligatorio'
   WHEN anno_cv IS NULL THEN 'anno non convertibile o fuori dominio integer'
   WHEN provincia_txt IS NULL THEN 'provincia obbligatoria'
   WHEN provincia_cv IS NULL THEN 'provincia non convertibile o fuori dominio integer'
   WHEN informatore_txt IS NULL THEN 'informatore obbligatorio'
   WHEN informatore_cv IS NULL THEN 'informatore non convertibile o fuori dominio integer'
   WHEN rilevatore_txt IS NULL THEN 'rilevatore obbligatorio'
   WHEN rilevatore_cv IS NULL THEN 'rilevatore non convertibile o fuori dominio integer'
   WHEN prezzo_txt IS NULL THEN 'prezzo obbligatorio'
   WHEN prezzo_cv IS NULL THEN 'prezzo non convertibile o fuori dominio numeric(24,5)'
   WHEN dt_inserimento IS NULL THEN 'data_inserimento obbligatoria'
   WHEN nascosto_txt IS NULL THEN 'nascosto obbligatorio'
   WHEN nascosto_cv IS NULL OR nascosto_cv NOT IN (0,1) THEN 'nascosto deve valere 0 o 1'
   WHEN addendum_txt IS NULL THEN 'addendum obbligatorio'
   WHEN addendum_cv IS NULL THEN 'addendum non convertibile o fuori dominio smallint'
   WHEN dt_last_update IS NULL THEN 'last_update obbligatorio'
   WHEN rib_anno_txt IS NOT NULL AND rib_anno_cv IS NULL THEN 'ribaltato_da_anno non convertibile'
   WHEN rib_addendum_txt IS NOT NULL AND rib_addendum_cv IS NULL THEN 'ribaltato_da_addendum non convertibile'
   ELSE NULL END::text tx_motivo_scarto
 FROM cv;
 SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_prezzi_rilevati_classificata;
 INSERT INTO hcbi_ras.stg_prezzi_rilevati
 SELECT codice_cv,anno_cv,provincia_cv,informatore_cv,rilevatore_cv,prezzo_cv,
        dt_inserimento,nascosto_cv,rib_anno_cv,addendum_cv,rib_addendum_cv,dt_last_update
 FROM hcbi_ras.tmp_prezzi_rilevati_classificata WHERE tx_motivo_scarto IS NULL;
 GET DIAGNOSTICS v_inserted=ROW_COUNT;
 INSERT INTO hcbi_ras.stg_prezzi_rilevati_rej
 (cd_articolo,ds_anno,id_sorgente_provincia,id_sorgente_informatore,id_sorgente_rilevatore,
  nr_prezzo,dt_inserimento,fl_nascosto,ds_anno_ribaltamento,cd_versione,
  cd_versione_ribaltamento,dt_last_update,tx_motivo_scarto)
 SELECT cd_articolo,ds_anno,id_sorgente_provincia,id_sorgente_informatore,id_sorgente_rilevatore,
        nr_prezzo,dt_inserimento,fl_nascosto,ds_anno_ribaltamento,cd_versione,
        cd_versione_ribaltamento,dt_last_update,tx_motivo_scarto
 FROM hcbi_ras.tmp_prezzi_rilevati_classificata WHERE tx_motivo_scarto IS NOT NULL;
 GET DIAGNOSTICS v_rejected=ROW_COUNT;
 IF v_selected<>v_inserted+v_rejected THEN
  RAISE EXCEPTION 'Riconciliazione STG non valida: selected=%, inserted=%, rejected=%',v_selected,v_inserted,v_rejected;
 END IF;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,
   v_rejected,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 DROP TABLE hcbi_ras.tmp_prezzi_rilevati_classificata;
 p_result:=1;
EXCEPTION WHEN OTHERS THEN
 p_result:=-1; DROP TABLE IF EXISTS hcbi_ras.tmp_prezzi_rilevati_classificata;
 IF v_id_log IS NOT NULL THEN
  BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',
   left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);
  EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
 END IF;
 RAISE WARNING 'Errore main STG PREZZI_RILEVATI: %',SQLERRM;
END;$BODY$;

/* ============================ STG FINALIZE ============================= */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_prezzi_rilevati_prc_finalize(
 IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
 IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility AS $BODY$
DECLARE v_id_log bigint;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
  clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 ANALYZE hcbi_ras.stg_prezzi_rilevati;
 ANALYZE hcbi_ras.stg_prezzi_rilevati_rej;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 p_result:=1;
EXCEPTION WHEN OTHERS THEN p_result:=-1; RAISE WARNING 'Errore finalize STG: %',SQLERRM;
END;$BODY$;

/* ============================= DWH INIT ================================ */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_prezzi_rilevati_prc_initialize(
 IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
 IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility AS $BODY$
DECLARE v_id_log bigint;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
  clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 p_result:=1;
EXCEPTION WHEN OTHERS THEN p_result:=-1; RAISE WARNING 'Errore initialize DWH: %',SQLERRM;
END;$BODY$;

/* ============================== DWH MAIN =============================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_prezzi_rilevati_prc_main(
 IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
 IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility AS $BODY$
DECLARE v_id_log bigint; v_selected bigint:=0; v_inserted bigint:=0;
 v_updated bigint:=0; v_deleted bigint:=0; v_errors bigint:=0;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
  clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 SELECT count(*) INTO v_selected FROM hcbi_ras.v_dwh_prezzi_rilevati;
 UPDATE hcbi_ras.dwh_prezzi_rilevati d
 SET id_sorgente_rilevatore=s.id_sorgente_rilevatore, nr_prezzo=s.nr_prezzo,
     dt_inserimento=s.dt_inserimento, fl_nascosto=s.fl_nascosto,
     ds_anno_ribaltamento=s.ds_anno_ribaltamento,
     cd_versione_ribaltamento=s.cd_versione_ribaltamento,
     dt_last_update=s.dt_last_update, dt_update=clock_timestamp(), tx_update_by=p_ds_step_name
 FROM hcbi_ras.v_dwh_prezzi_rilevati s
 WHERE d.cd_articolo=s.cd_articolo AND d.ds_anno=s.ds_anno
   AND d.id_sorgente_provincia=s.id_sorgente_provincia
   AND d.cd_versione=s.cd_versione
   AND d.id_sorgente_informatore=s.id_sorgente_informatore
   AND ROW(d.id_sorgente_rilevatore,d.nr_prezzo,d.dt_inserimento,d.fl_nascosto,
           d.ds_anno_ribaltamento,d.cd_versione_ribaltamento,d.dt_last_update)
       IS DISTINCT FROM
       ROW(s.id_sorgente_rilevatore,s.nr_prezzo,s.dt_inserimento,s.fl_nascosto,
           s.ds_anno_ribaltamento,s.cd_versione_ribaltamento,s.dt_last_update);
 GET DIAGNOSTICS v_updated=ROW_COUNT;
 INSERT INTO hcbi_ras.dwh_prezzi_rilevati
 (cd_articolo,ds_anno,id_sorgente_provincia,id_sorgente_informatore,id_sorgente_rilevatore,
  nr_prezzo,dt_inserimento,fl_nascosto,ds_anno_ribaltamento,cd_versione,
  cd_versione_ribaltamento,dt_last_update,tx_creation_by,tx_update_by)
 SELECT s.cd_articolo,s.ds_anno,s.id_sorgente_provincia,s.id_sorgente_informatore,
  s.id_sorgente_rilevatore,s.nr_prezzo,s.dt_inserimento,s.fl_nascosto,
  s.ds_anno_ribaltamento,s.cd_versione,s.cd_versione_ribaltamento,s.dt_last_update,
  p_ds_step_name,p_ds_step_name
 FROM hcbi_ras.v_dwh_prezzi_rilevati s
 ON CONFLICT (cd_articolo,ds_anno,id_sorgente_provincia,cd_versione,id_sorgente_informatore)
 DO NOTHING;
 GET DIAGNOSTICS v_inserted=ROW_COUNT;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,v_updated,v_deleted,
  v_errors,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 p_result:=1;
EXCEPTION WHEN OTHERS THEN
 p_result:=-1;
 IF v_id_log IS NOT NULL THEN
  BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',
   left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);
  EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
 END IF;
 RAISE WARNING 'Errore main DWH PREZZI_RILEVATI: %',SQLERRM;
END;$BODY$;

/* ============================ DWH FINALIZE ============================= */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_prezzi_rilevati_prc_finalize(
 IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint,
 IN p_ds_step_name varchar, OUT p_result integer)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility AS $BODY$
DECLARE v_id_log bigint;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
  clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 ANALYZE hcbi_ras.dwh_prezzi_rilevati;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 p_result:=1;
EXCEPTION WHEN OTHERS THEN p_result:=-1; RAISE WARNING 'Errore finalize DWH: %',SQLERRM;
END;$BODY$;

/* ========================= OWNER / EXECUTE / COMMENT =================== */
ALTER PROCEDURE hcbi_ras.pkg_stg_prezzi_rilevati_prc_initialize(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_stg_prezzi_rilevati_prc_main(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_stg_prezzi_rilevati_prc_finalize(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dwh_prezzi_rilevati_prc_initialize(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dwh_prezzi_rilevati_prc_main(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dwh_prezzi_rilevati_prc_finalize(bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_prezzi_rilevati_prc_initialize(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_prezzi_rilevati_prc_main(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_stg_prezzi_rilevati_prc_finalize(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_prezzi_rilevati_prc_initialize(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_prezzi_rilevati_prc_main(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dwh_prezzi_rilevati_prc_finalize(bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;

COMMENT ON TABLE hcbi_ras.frontiera_prezzi_rilevati IS 'Frontiera del flusso PREZZI_RILEVATI';
COMMENT ON TABLE hcbi_ras.src_tmp_prezzi_rilevati IS 'Sorgente temporanea del flusso PREZZI_RILEVATI';
COMMENT ON TABLE hcbi_ras.stg_prezzi_rilevati IS 'Staging valida del flusso PREZZI_RILEVATI';
COMMENT ON TABLE hcbi_ras.stg_prezzi_rilevati_rej IS 'Record scartati del flusso PREZZI_RILEVATI';
COMMENT ON TABLE hcbi_ras.dwh_prezzi_rilevati IS 'DWH non storicizzato del flusso PREZZI_RILEVATI';

/* ================================ TEST =================================
-- Pre-check dipendenze:
SELECT to_regprocedure('hcbi_ras.try_integer(text)'),
       to_regprocedure('hcbi_ras.try_smallint(text)'),
       to_regprocedure('hcbi_ras.try_numeric_24_5(text)');

-- Riconciliazione STG:
SELECT (SELECT count(*) FROM hcbi_ras.v_src_tmp_prezzi_rilevati) input,
       (SELECT count(*) FROM hcbi_ras.stg_prezzi_rilevati) validi,
       (SELECT count(*) FROM hcbi_ras.stg_prezzi_rilevati_rej) scarti;

-- Duplicati DWH, atteso zero righe:
SELECT cd_articolo,ds_anno,id_sorgente_provincia,cd_versione,id_sorgente_informatore,count(*)
FROM hcbi_ras.dwh_prezzi_rilevati
GROUP BY 1,2,3,4,5 HAVING count(*)>1;

-- Idempotenza: rieseguire il main DWH senza cambiare STG; attesi inserted=0, updated=0.
======================================================================== */
