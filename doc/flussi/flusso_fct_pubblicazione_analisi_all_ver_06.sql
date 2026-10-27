/* =====================================================================
   DATAMART - FCT_PUBBLICAZIONE_ANALISI - VERSIONE 06
   Target: PostgreSQL 15.9 / 17
   Schema: hcbi_ras
   Pattern: FCT_PUBBLICAZIONE_ALBERO

   Grain:
     una riga per record di HCBI_RAS.DWH_PUBBLICAZIONE_ANALISI,
     identificato da ID_PUBBLICAZIONE_ANALISI.

   Chiave primaria:
     ID_PUBBLICAZIONE_ANALISI, mantenuta dalla DWH sorgente.
     La fact non usa sequence e non introduce una nuova chiave.

   Sorgente:
     HCBI_RAS.DWH_PUBBLICAZIONE_ANALISI.
     Non sono previste FRONTIERA, SRC_TMP o STG dedicate alla fact.

   Foreign key:
     DIM_PERIODO, DIM_ARTICOLO, DIM_VERSIONE.
     Non esiste una FK verso DWH_PUBBLICAZIONE_ANALISI.
     Non esiste una FK verso DIM_ANALISI.

   Attributi mantenuti:
     CD_CODICE_ANALISI, NR_QUANTITA,
     ID_SORGENTE_PUBBLICAZIONE_ANALISI, ID_SORGENTE_CATEGORIA, NR_RIGA.

   Lookup provincia/versione/articolo:
     la provincia viene derivata raccordando
     DWH_PUBBLICAZIONE_ANALISI.CD_CODICE_ANALISI con
     DWH_PUBBLICAZIONE_ARTICOLI.CD_CODICE_COMPLETO su anno e versione.
     Il codice elemento DWH_PUBBLICAZIONE_ANALISI.CD_ARTICOLO viene
     normalizzato con BTRIM, rimozione del prefisso SARxx_ e dell'eventuale
     punto finale. La risoluzione usa quindi:
       anno + codice analisi completo + versione -> provincia;
       periodo + provincia + versione -> DIM_VERSIONE;
       periodo + codice elemento normalizzato + provincia + versione
         -> DIM_ARTICOLO.

   Il contesto della Provincia e' CD_VERSIONE. Il flusso non utilizza il
   precedente attributo di contesto. La lookup su DWH_ANAG_PROVINCIA usa
   ANNO + CD_VERSIONE + ID_SORGENTE_PROVINCIA; DIM_PROVINCIA viene risolta
   tramite ID_ANAG_PROVINCIA, verificando anche ANNO e CD_VERSIONE.
   DIM_AREA_VASTA resta una dipendenza di DIM_PROVINCIA e non viene
   referenziata direttamente dalla fact.
   Regole late-arriving:
     le FK non risolte usano temporaneamente il membro -1 delle dimensioni.
     La fact non contiene righe tappo proprie.

   Strategia:
     caricamento diretto, SCD Type 1, update dei soli record variati,
     insert dei nuovi, nessuna cancellazione.
     PRC_MAIN non eseguibile in parallelo: usa una tabella di lavoro a nome fisso.
   ===================================================================== */

/* =====================================================================
   DROP PRELIMINARI - FACT GIA ESISTENTE
   IF EXISTS evita errori quando un oggetto non e presente.
   ===================================================================== */
DROP PROCEDURE IF EXISTS hcbi_ras.pkg_fct_pubblicazione_analisi_prc_finalize(BIGINT,BIGINT,BIGINT,VARCHAR);
DROP PROCEDURE IF EXISTS hcbi_ras.pkg_fct_pubblicazione_analisi_prc_main(BIGINT,BIGINT,BIGINT,VARCHAR);
DROP PROCEDURE IF EXISTS hcbi_ras.pkg_fct_pubblicazione_analisi_prc_initialize(BIGINT,BIGINT,BIGINT,VARCHAR);
DROP VIEW IF EXISTS hcbi_ras.v_fct_pubblicazione_analisi_src CASCADE;
DROP TABLE IF EXISTS hcbi_ras.tmp_fct_pubblicazione_analisi_src;
DROP TABLE IF EXISTS hcbi_ras.fct_pubblicazione_analisi CASCADE;

CREATE TABLE hcbi_ras.fct_pubblicazione_analisi
(
    id_pubblicazione_analisi          BIGINT NOT NULL,
    id_periodo_pubblicazione          INTEGER NOT NULL,
    id_anag_articolo                  BIGINT NOT NULL,
    id_anag_versione                  BIGINT NOT NULL,
    cd_codice_analisi                 VARCHAR(70) NOT NULL,
    nr_quantita                       NUMERIC(24,6),
    id_sorgente_pubblicazione_analisi BIGINT,
    id_sorgente_categoria             BIGINT,
    nr_riga                           SMALLINT,
    dt_creation                       TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by                    VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update                         TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_update_by                      VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT pk_fct_pubblicazione_analisi
        PRIMARY KEY (id_pubblicazione_analisi),
    CONSTRAINT fk_fct_pub_analisi_periodo
        FOREIGN KEY (id_periodo_pubblicazione)
        REFERENCES hcbi_ras.dim_periodo(id_periodo)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_fct_pub_analisi_articolo
        FOREIGN KEY (id_anag_articolo)
        REFERENCES hcbi_ras.dim_articolo(id_anag_articolo)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_fct_pub_analisi_versione
        FOREIGN KEY (id_anag_versione)
        REFERENCES hcbi_ras.dim_versione(id_anag_versione)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) TABLESPACE pg_default;

ALTER TABLE hcbi_ras.fct_pubblicazione_analisi OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.fct_pubblicazione_analisi FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.fct_pubblicazione_analisi TO hcbi_ras;
GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE hcbi_ras.fct_pubblicazione_analisi TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.fct_pubblicazione_analisi IS
'Fact alimentata direttamente da DWH_PUBBLICAZIONE_ANALISI; PK mantenuta dalla DWH e FK verso periodo, articolo e versione.';
COMMENT ON COLUMN hcbi_ras.fct_pubblicazione_analisi.cd_codice_analisi IS
'Codice analisi riportato dalla DWH come attributo degenerato, privato dei primi 6 caratteri del prefisso (es. SAR26_).';

/* La vista conserva il grain DWH e risolve le FK in modalita set-based. */
CREATE OR REPLACE VIEW hcbi_ras.v_fct_pubblicazione_analisi_src AS
WITH mappa_analisi_provincia AS
(
    SELECT DISTINCT
        pa.ds_anno_pubblicazione,
        pa.cd_codice_completo::VARCHAR(70)
            AS cd_codice_analisi_completo,
        pa.cd_versione,
        pa.id_sorgente_provincia
    FROM hcbi_ras.dwh_pubblicazione_articoli AS pa
),
base AS
(
    SELECT
        src.*,
        per.id_periodo,
        map.id_sorgente_provincia,
        prv.id_anag_provincia,
        regexp_replace(
            substr(btrim(src.cd_articolo::TEXT), 7),
            '\.$',
            ''
        )::VARCHAR(70) AS cd_articolo_normalizzato,
        src.cd_codice_analisi::VARCHAR(70)
            AS cd_codice_analisi_completo
    FROM hcbi_ras.dwh_pubblicazione_analisi AS src
    LEFT JOIN hcbi_ras.dim_periodo AS per
      ON per.ds_anno::NUMERIC = src.ds_anno_pubblicazione
    LEFT JOIN mappa_analisi_provincia AS map
      ON map.ds_anno_pubblicazione = src.ds_anno_pubblicazione
     AND map.cd_codice_analisi_completo = src.cd_codice_analisi
     AND map.cd_versione = src.cd_versione
    LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwh_prv
      ON dwh_prv.anno = src.ds_anno_pubblicazione::INTEGER
     AND dwh_prv.cd_versione = src.cd_versione::SMALLINT
     AND dwh_prv.id_sorgente_provincia = map.id_sorgente_provincia::BIGINT
    LEFT JOIN hcbi_ras.dim_provincia AS prv
      ON prv.id_anag_provincia = dwh_prv.id_anag_provincia
     AND prv.anno = dwh_prv.anno
     AND prv.cd_versione = dwh_prv.cd_versione
),
resolved AS
(
    SELECT
        b.*,
        ver.id_anag_versione,
        art.id_anag_articolo
    FROM base AS b
    LEFT JOIN hcbi_ras.dim_versione AS ver
      ON ver.id_periodo_pubblicazione = COALESCE(b.id_periodo,-1::INTEGER)
     AND ver.cd_versione = b.cd_versione
     AND ver.id_anag_provincia = COALESCE(b.id_anag_provincia,-1::BIGINT)
    LEFT JOIN hcbi_ras.dim_articolo AS art
      ON art.id_periodo_pubblicazione = COALESCE(b.id_periodo,-1::INTEGER)
     AND art.cd_articolo = b.cd_articolo_normalizzato
     AND art.id_anag_versione = COALESCE(ver.id_anag_versione,-1::BIGINT)
     AND art.id_anag_provincia = COALESCE(b.id_anag_provincia,-1::BIGINT)
)
SELECT
    id_pubblicazione_analisi,
    COALESCE(id_periodo,-1::INTEGER) AS id_periodo_pubblicazione,
    COALESCE(id_anag_articolo,-1::BIGINT) AS id_anag_articolo,
    COALESCE(id_anag_versione,-1::BIGINT) AS id_anag_versione,
    substr(btrim(cd_codice_analisi::TEXT), 7)::VARCHAR(70) AS cd_codice_analisi,
    nr_quantita,
    id_sorgente_pubblicazione_analisi,
    id_sorgente_categoria,
    nr_riga,
    ds_anno_pubblicazione,
    cd_articolo,
    cd_articolo_normalizzato,
    cd_codice_analisi_completo,
    cd_versione,
    id_sorgente_provincia,
    id_anag_provincia,
    NULLIF(concat_ws('; ',
        CASE WHEN id_periodo IS NULL
             THEN 'FK DIM_PERIODO non risolta: applicato -1' END,
        CASE WHEN id_sorgente_provincia IS NULL
             THEN 'Provincia non derivata da DWH_PUBBLICAZIONE_ARTICOLI' END,
        CASE WHEN id_anag_provincia IS NULL
             THEN 'Lookup DIM_PROVINCIA non risolta' END,
        CASE WHEN id_anag_versione IS NULL
             THEN 'FK DIM_VERSIONE non risolta: applicato -1' END,
        CASE WHEN id_anag_articolo IS NULL
             THEN 'FK DIM_ARTICOLO non risolta: applicato -1' END
    ), '')::VARCHAR(4000) AS tx_motivo_lookup
FROM resolved;
ALTER VIEW hcbi_ras.v_fct_pubblicazione_analisi_src OWNER TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_fct_pubblicazione_analisi_src TO hcbi_ras,hcbi_utility;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pubblicazione_analisi_prc_initialize(
    IN p_id_chain_log BIGINT,
    IN p_id_chain BIGINT,
    IN p_id_step BIGINT,
    IN p_ds_step_name VARCHAR,
    OUT p_result INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT;
    v_sqlstate TEXT;
    v_sqlerrm TEXT;
    v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,
        v_sqlerrm=MESSAGE_TEXT;
    p_result := -1;
    v_log_error := left('SQLSTATE='||coalesce(v_sqlstate,'')||E'\nMESSAGE='||coalesce(v_sqlerrm,''),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging INITIALIZE FCT_PUBBLICAZIONE_ANALISI: %',SQLERRM;
        END;
    END IF;
    RAISE WARNING 'Errore INITIALIZE FCT_PUBBLICAZIONE_ANALISI: SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pubblicazione_analisi_prc_main(
    IN p_id_chain_log BIGINT,
    IN p_id_chain BIGINT,
    IN p_id_step BIGINT,
    IN p_ds_step_name VARCHAR,
    OUT p_result INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT;
    v_selected BIGINT := 0;
    v_inserted BIGINT := 0;
    v_updated BIGINT := 0;
    v_deleted BIGINT := 0;
    v_errors BIGINT := 0;
    v_duplicate_rows BIGINT := 0;
    v_sqlstate TEXT;
    v_sqlerrm TEXT;
    v_sql_detail TEXT;
    v_sql_hint TEXT;
    v_sql_context TEXT;
    v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;

    /* Diagnostica puntuale dei membri tecnici necessari. */
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
          MESSAGE='Record tecnico -1 mancante in HCBI_RAS.DIM_PERIODO';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_articolo WHERE id_anag_articolo=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
          MESSAGE='Record tecnico -1 mancante in HCBI_RAS.DIM_ARTICOLO';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
          MESSAGE='Record tecnico -1 mancante in HCBI_RAS.DIM_VERSIONE';
    END IF;

    /* Determinismo periodo. */
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_periodo
        WHERE ds_anno IS NOT NULL
        GROUP BY ds_anno HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Lookup non deterministica: HCBI_RAS.DIM_PERIODO.DS_ANNO';
    END IF;

    /* La provincia dell'analisi deve essere derivabile in modo univoco
       dalla pubblicazione dell'articolo analizzato. */
    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dwh_pubblicazione_articoli
        GROUP BY ds_anno_pubblicazione,
                 btrim(cd_codice_completo::TEXT),
                 btrim(cd_versione::TEXT)
        HAVING count(DISTINCT id_sorgente_provincia)>1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Lookup provincia non deterministica da DWH_PUBBLICAZIONE_ARTICOLI',
          DETAIL='La stessa combinazione anno, codice analisi completo e versione appartiene a piu province.',
          HINT='Eseguire il test T04 e verificare la business key anno, codice completo e versione.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_provincia
        WHERE id_sorgente_provincia IS NOT NULL
        GROUP BY anno,cd_versione,id_sorgente_provincia
        HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Lookup DWH_ANAG_PROVINCIA non deterministica',
          DETAIL='Duplicati su anno, cd_versione e id_sorgente_provincia.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_provincia
        WHERE cd_provincia IS NOT NULL
        GROUP BY anno,cd_versione,cd_provincia
        HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Lookup DIM_PROVINCIA non deterministica',
          DETAIL='Duplicati su anno, cd_versione e cd_provincia.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_pubblicazione_analisi
        WHERE ds_anno_pubblicazione IS NULL OR cd_versione IS NULL
    ) THEN
        RAISE EXCEPTION USING ERRCODE='23502',
          MESSAGE='Contesto anno/cd_versione incompleto in DWH_PUBBLICAZIONE_ANALISI',
          DETAIL='DS_ANNO_PUBBLICAZIONE e CD_VERSIONE sono necessari per derivare la Provincia.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_pubblicazione_analisi
        WHERE cd_versione IS NOT NULL
          AND (cd_versione::NUMERIC < -32768 OR cd_versione::NUMERIC > 32767)
    ) THEN
        RAISE EXCEPTION USING ERRCODE='22003',
          MESSAGE='CD_VERSIONE fuori dominio SMALLINT in DWH_PUBBLICAZIONE_ANALISI',
          DETAIL='CD_VERSIONE deve rientrare nel dominio SMALLINT della Provincia.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_versione
        GROUP BY id_periodo_pubblicazione,cd_versione,id_anag_provincia
        HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Lookup non deterministica: HCBI_RAS.DIM_VERSIONE business key';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_articolo
        GROUP BY id_periodo_pubblicazione,cd_articolo,
                 id_anag_versione,id_anag_provincia
        HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Lookup non deterministica: HCBI_RAS.DIM_ARTICOLO business key';
    END IF;

    DROP TABLE IF EXISTS hcbi_ras.tmp_fct_pubblicazione_analisi_src;
    CREATE TABLE hcbi_ras.tmp_fct_pubblicazione_analisi_src AS
    SELECT
        id_pubblicazione_analisi,
        id_periodo_pubblicazione,
        id_anag_articolo,
        id_anag_versione,
        cd_codice_analisi,
        nr_quantita,
        id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria,
        nr_riga,
        tx_motivo_lookup
    FROM hcbi_ras.v_fct_pubblicazione_analisi_src;

    CREATE UNIQUE INDEX tmp_fct_pubblicazione_analisi_pk
      ON hcbi_ras.tmp_fct_pubblicazione_analisi_src(id_pubblicazione_analisi);
    ANALYZE hcbi_ras.tmp_fct_pubblicazione_analisi_src;

    SELECT count(*) INTO v_selected
    FROM hcbi_ras.dwh_pubblicazione_analisi;

    SELECT count(*) INTO v_duplicate_rows
    FROM (
        SELECT id_pubblicazione_analisi
        FROM hcbi_ras.tmp_fct_pubblicazione_analisi_src
        GROUP BY id_pubblicazione_analisi
        HAVING count(*)>1
    ) AS d;
    IF v_duplicate_rows>0 THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE=format('Lookup non univoche per %s record PUBBLICAZIONE_ANALISI',v_duplicate_rows);
    END IF;

    IF v_selected<>(SELECT count(*) FROM hcbi_ras.tmp_fct_pubblicazione_analisi_src) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='La vista di lookup ha alterato la cardinalita di DWH_PUBBLICAZIONE_ANALISI';
    END IF;

    SELECT count(*) INTO v_errors
    FROM hcbi_ras.tmp_fct_pubblicazione_analisi_src
    WHERE tx_motivo_lookup IS NOT NULL;

    SELECT count(*) INTO v_inserted
    FROM hcbi_ras.tmp_fct_pubblicazione_analisi_src AS src
    LEFT JOIN hcbi_ras.fct_pubblicazione_analisi AS f
      ON f.id_pubblicazione_analisi=src.id_pubblicazione_analisi
    WHERE f.id_pubblicazione_analisi IS NULL;

    SELECT count(*) INTO v_updated
    FROM hcbi_ras.tmp_fct_pubblicazione_analisi_src AS src
    JOIN hcbi_ras.fct_pubblicazione_analisi AS f
      ON f.id_pubblicazione_analisi=src.id_pubblicazione_analisi
    WHERE ROW(
        f.id_periodo_pubblicazione,
        f.id_anag_articolo,
        f.id_anag_versione,
        f.cd_codice_analisi,
        f.nr_quantita,
        f.id_sorgente_pubblicazione_analisi,
        f.id_sorgente_categoria,
        f.nr_riga
    ) IS DISTINCT FROM ROW(
        src.id_periodo_pubblicazione,
        src.id_anag_articolo,
        src.id_anag_versione,
        src.cd_codice_analisi,
        src.nr_quantita,
        src.id_sorgente_pubblicazione_analisi,
        src.id_sorgente_categoria,
        src.nr_riga
    );

    INSERT INTO hcbi_ras.fct_pubblicazione_analisi AS f
    (
        id_pubblicazione_analisi,
        id_periodo_pubblicazione,
        id_anag_articolo,
        id_anag_versione,
        cd_codice_analisi,
        nr_quantita,
        id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria,
        nr_riga,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_pubblicazione_analisi,
        src.id_periodo_pubblicazione,
        src.id_anag_articolo,
        src.id_anag_versione,
        src.cd_codice_analisi,
        src.nr_quantita,
        src.id_sorgente_pubblicazione_analisi,
        src.id_sorgente_categoria,
        src.nr_riga,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_fct_pubblicazione_analisi_src AS src
    ON CONFLICT ON CONSTRAINT pk_fct_pubblicazione_analisi
    DO UPDATE SET
        id_periodo_pubblicazione=EXCLUDED.id_periodo_pubblicazione,
        id_anag_articolo=EXCLUDED.id_anag_articolo,
        id_anag_versione=EXCLUDED.id_anag_versione,
        cd_codice_analisi=EXCLUDED.cd_codice_analisi,
        nr_quantita=EXCLUDED.nr_quantita,
        id_sorgente_pubblicazione_analisi=EXCLUDED.id_sorgente_pubblicazione_analisi,
        id_sorgente_categoria=EXCLUDED.id_sorgente_categoria,
        nr_riga=EXCLUDED.nr_riga,
        dt_update=clock_timestamp(),
        tx_update_by=p_ds_step_name
    WHERE ROW(
        f.id_periodo_pubblicazione,
        f.id_anag_articolo,
        f.id_anag_versione,
        f.cd_codice_analisi,
        f.nr_quantita,
        f.id_sorgente_pubblicazione_analisi,
        f.id_sorgente_categoria,
        f.nr_riga
    ) IS DISTINCT FROM ROW(
        EXCLUDED.id_periodo_pubblicazione,
        EXCLUDED.id_anag_articolo,
        EXCLUDED.id_anag_versione,
        EXCLUDED.cd_codice_analisi,
        EXCLUDED.nr_quantita,
        EXCLUDED.id_sorgente_pubblicazione_analisi,
        EXCLUDED.id_sorgente_categoria,
        EXCLUDED.nr_riga
    );

    IF v_selected<>(
        SELECT count(*)
        FROM hcbi_ras.fct_pubblicazione_analisi AS f
        JOIN hcbi_ras.tmp_fct_pubblicazione_analisi_src AS src
          ON src.id_pubblicazione_analisi=f.id_pubblicazione_analisi
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
          MESSAGE='Riconciliazione FCT_PUBBLICAZIONE_ANALISI non valida';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);

    DROP TABLE hcbi_ras.tmp_fct_pubblicazione_analisi_src;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,
        v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,
        v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    BEGIN
        DROP TABLE IF EXISTS hcbi_ras.tmp_fct_pubblicazione_analisi_src;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Errore cleanup FCT_PUBBLICAZIONE_ANALISI: %',SQLERRM;
    END;
    v_log_error := left(concat_ws(E'\n',
        'SQLSTATE='||coalesce(v_sqlstate,''),
        'MESSAGE='||left(coalesce(v_sqlerrm,''),1500),
        CASE WHEN nullif(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||left(v_sql_detail,1000) END,
        CASE WHEN nullif(v_sql_hint,'') IS NOT NULL THEN 'HINT='||left(v_sql_hint,500) END,
        CASE WHEN nullif(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||left(v_sql_context,800) END
    ),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging MAIN FCT_PUBBLICAZIONE_ANALISI: %',SQLERRM;
        END;
    END IF;
    RAISE WARNING 'Errore MAIN FCT_PUBBLICAZIONE_ANALISI: SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pubblicazione_analisi_prc_finalize(
    IN p_id_chain_log BIGINT,
    IN p_id_chain BIGINT,
    IN p_id_step BIGINT,
    IN p_ds_step_name VARCHAR,
    OUT p_result INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT;
    v_sqlstate TEXT;
    v_sqlerrm TEXT;
    v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;

    ANALYZE hcbi_ras.fct_pubblicazione_analisi;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,
        v_sqlerrm=MESSAGE_TEXT;
    p_result := -1;
    v_log_error := left('SQLSTATE='||coalesce(v_sqlstate,'')||E'\nMESSAGE='||coalesce(v_sqlerrm,''),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging FINALIZE FCT_PUBBLICAZIONE_ANALISI: %',SQLERRM;
        END;
    END IF;
    RAISE WARNING 'Errore FINALIZE FCT_PUBBLICAZIONE_ANALISI: SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_fct_pubblicazione_analisi_prc_initialize(BIGINT,BIGINT,BIGINT,VARCHAR) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_fct_pubblicazione_analisi_prc_main(BIGINT,BIGINT,BIGINT,VARCHAR) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_fct_pubblicazione_analisi_prc_finalize(BIGINT,BIGINT,BIGINT,VARCHAR) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_pubblicazione_analisi_prc_initialize(BIGINT,BIGINT,BIGINT,VARCHAR) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_pubblicazione_analisi_prc_main(BIGINT,BIGINT,BIGINT,VARCHAR) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_pubblicazione_analisi_prc_finalize(BIGINT,BIGINT,BIGINT,VARCHAR) TO hcbi_ras,hcbi_utility;

/* =====================================================================
   TEST POST-DEPLOYMENT
   ===================================================================== */

/* T01 - PK sorgente duplicata. Atteso: zero righe. */
-- SELECT id_pubblicazione_analisi,count(*)
-- FROM hcbi_ras.dwh_pubblicazione_analisi
-- GROUP BY id_pubblicazione_analisi HAVING count(*)>1;

/* T02 - Tappi dimensionali. Atteso: tre righe. */
-- SELECT 'DIM_PERIODO' oggetto,count(*) FROM hcbi_ras.dim_periodo WHERE id_periodo=-1
-- UNION ALL SELECT 'DIM_ARTICOLO',count(*) FROM hcbi_ras.dim_articolo WHERE id_anag_articolo=-1
-- UNION ALL SELECT 'DIM_VERSIONE',count(*) FROM hcbi_ras.dim_versione WHERE id_anag_versione=-1;

/* T03 - Periodi duplicati. Atteso: zero righe. */
-- SELECT ds_anno,count(*) FROM hcbi_ras.dim_periodo
-- WHERE ds_anno IS NOT NULL GROUP BY ds_anno HAVING count(*)>1;

/* T04 - Ambiguita della provincia derivata. Atteso: zero righe. */
-- SELECT ds_anno_pubblicazione,
--        btrim(cd_codice_completo::TEXT) AS codice_analisi_completo,
--        btrim(cd_versione::TEXT) AS cd_versione,
--        count(DISTINCT id_sorgente_provincia) AS province
-- FROM hcbi_ras.dwh_pubblicazione_articoli
-- GROUP BY ds_anno_pubblicazione,
--          btrim(cd_codice_completo::TEXT),btrim(cd_versione::TEXT)
-- HAVING count(DISTINCT id_sorgente_provincia)>1;

/* T05 - Analisi senza provincia derivata. Atteso: zero righe. */
-- SELECT id_pubblicazione_analisi,cd_codice_analisi,
--        ds_anno_pubblicazione,cd_versione
-- FROM hcbi_ras.v_fct_pubblicazione_analisi_src
-- WHERE id_sorgente_provincia IS NULL;

/* T06 - Duplicati business key DIM_VERSIONE. Atteso: zero righe. */
-- SELECT id_periodo_pubblicazione,cd_versione,id_anag_provincia,count(*)
-- FROM hcbi_ras.dim_versione GROUP BY 1,2,3 HAVING count(*)>1;

/* T07 - Duplicati business key DIM_ARTICOLO. Atteso: zero righe. */
-- SELECT id_periodo_pubblicazione,cd_articolo,
--        id_anag_versione,id_anag_provincia,count(*)
-- FROM hcbi_ras.dim_articolo GROUP BY 1,2,3,4 HAVING count(*)>1;

/* T08 - Cardinalita vista e sorgente. Atteso: conteggi uguali. */
-- SELECT
--  (SELECT count(*) FROM hcbi_ras.dwh_pubblicazione_analisi) sorgente,
--  (SELECT count(*) FROM hcbi_ras.v_fct_pubblicazione_analisi_src) vista;

/* T09 - Chiavi non caricate. Atteso: zero. */
-- SELECT count(*)
-- FROM hcbi_ras.dwh_pubblicazione_analisi s
-- LEFT JOIN hcbi_ras.fct_pubblicazione_analisi f USING(id_pubblicazione_analisi)
-- WHERE f.id_pubblicazione_analisi IS NULL;

/* T10 - Orfani FK. Atteso: zero. */
-- SELECT count(*)
-- FROM hcbi_ras.fct_pubblicazione_analisi f
-- LEFT JOIN hcbi_ras.dim_periodo p ON p.id_periodo=f.id_periodo_pubblicazione
-- LEFT JOIN hcbi_ras.dim_articolo a ON a.id_anag_articolo=f.id_anag_articolo
-- LEFT JOIN hcbi_ras.dim_versione v ON v.id_anag_versione=f.id_anag_versione
-- WHERE p.id_periodo IS NULL OR a.id_anag_articolo IS NULL OR v.id_anag_versione IS NULL;

/* T11 - Lookup non risolte. Informativo. */
-- SELECT count(*) FILTER(WHERE id_periodo_pubblicazione=-1) periodo_nd,
--        count(*) FILTER(WHERE id_anag_articolo=-1) articolo_nd,
--        count(*) FILTER(WHERE id_anag_versione=-1) versione_nd
-- FROM hcbi_ras.fct_pubblicazione_analisi;

/* T12 - Idempotenza: rilanciare senza variazioni. Atteso inserted=0, updated=0. */

/* T13 - Regressione lookup sui record verificati.
   Atteso:
     ID 1 -> provincia 0, versione 1, articolo 1435;
     ID 2 -> provincia 0, versione 1, articolo 1456;
     ID 3 -> provincia 0, versione 1, articolo 1481;
     TX_MOTIVO_LOOKUP NULL per tutte le righe. */
-- SELECT
--     id_pubblicazione_analisi,
--     id_periodo_pubblicazione,
--     id_sorgente_provincia,
--     id_anag_provincia,
--     id_anag_versione,
--     id_anag_articolo,
--     cd_codice_analisi,
--     cd_articolo,
--     cd_articolo_normalizzato,
--     tx_motivo_lookup
-- FROM hcbi_ras.v_fct_pubblicazione_analisi_src
-- WHERE id_pubblicazione_analisi IN (1,2,3)
-- ORDER BY id_pubblicazione_analisi;

/* T14 - Riconciliazione globale dei lookup articolo/versione non risolti.
   Informativo: analizzare le righe residue dopo T04-T08. */
-- SELECT
--     count(*) FILTER (WHERE id_anag_versione=-1) AS versione_nd,
--     count(*) FILTER (WHERE id_anag_articolo=-1) AS articolo_nd
-- FROM hcbi_ras.v_fct_pubblicazione_analisi_src;

/* T15 - Determinismo chiave operazionale DWH_ANAG_PROVINCIA. Atteso: zero righe. */
-- SELECT anno,cd_versione,id_sorgente_provincia,count(*)
-- FROM hcbi_ras.dwh_anag_provincia
-- WHERE id_sorgente_provincia IS NOT NULL
-- GROUP BY anno,cd_versione,id_sorgente_provincia
-- HAVING count(*)>1;

/* T16 - Determinismo business key contestualizzata DIM_PROVINCIA. Atteso: zero righe. */
-- SELECT anno,cd_versione,cd_provincia,count(*)
-- FROM hcbi_ras.dim_provincia
-- WHERE cd_provincia IS NOT NULL
-- GROUP BY anno,cd_versione,cd_provincia
-- HAVING count(*)>1;

/* =====================================================================
   ORDINE DI DEPLOYMENT
   1. DIM_PERIODO
   2. DIM_PROVINCIA, DIM_UNITA_MISURA, DIM_MACRO_GRUPPO
   3. DIM_VERSIONE
   4. DWH_PUBBLICAZIONE_ARTICOLI
   5. DIM_ARTICOLO
   6. DWH_PUBBLICAZIONE_ANALISI
   7. FCT_PUBBLICAZIONE_ANALISI

   ROLLBACK STRUTTURALE, previa autorizzazione:
   DROP PROCEDURE delle tre procedure della fact;
   DROP VIEW HCBI_RAS.V_FCT_PUBBLICAZIONE_ANALISI_SRC;
   DROP TABLE HCBI_RAS.FCT_PUBBLICAZIONE_ANALISI;
   ===================================================================== */
