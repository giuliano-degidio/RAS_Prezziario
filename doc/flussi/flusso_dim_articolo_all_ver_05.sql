/* ===================================================================== 
   DIM_ARTICOLO - DDL E PROCEDURE DI CARICAMENTO - VERSIONE 05
   Target: PostgreSQL 15.9 / 17
   Schema: hcbi_ras
   Pattern: DIM_INFORMATORI

   Sorgente: hcbi_ras.dwh_anag_articolo
   Destinazione: hcbi_ras.dim_articolo
   Grain: una riga per ID_ANAG_ARTICOLO della DWH, distinta anche per
   provincia nella business key sorgente.
   PK: id_anag_articolo, mantenuta dalla DWH.
   Business key sorgente verificata:
     ds_anno, cd_articolo, cd_versione, id_sorgente_provincia.
   Business key dimensionale:
     id_periodo_pubblicazione, cd_articolo, id_anag_versione,
     id_anag_provincia.

   FK confermate:
     DIM_PERIODO, DIM_PROVINCIA, DIM_VERSIONE,
     DIM_MACRO_GRUPPO, DIM_UNITA_MISURA.
   ID_SORGENTE_CATEGORIA resta attributo e non genera una FK.

   Lookup:
     periodo: DWH_ANAG_ARTICOLO.DS_ANNO = DIM_PERIODO.DS_ANNO;
     provincia: DS_ANNO + CD_VERSIONE + ID_SORGENTE_PROVINCIA ->
       DWH_ANAG_PROVINCIA;
       DWH_ANAG_PROVINCIA.ID_ANAG_PROVINCIA -> DIM_PROVINCIA,
       con verifica del contesto ANNO/CD_VERSIONE;
     DIM_AREA_VASTA resta una dipendenza di DIM_PROVINCIA e non viene
       referenziata direttamente da DIM_ARTICOLO;
     versione: periodo + CD_VERSIONE + provincia -> DIM_VERSIONE;
     macro-gruppo: NR_MACRO_GRUPPO ->
       DWH_ANAG_MACRO_GRUPPO.ID_SORGENTE_MACRO_GRUPPO -> DIM_MACRO_GRUPPO;
     unita misura: DS_UNITA_MISURA, numerico nella DWH articolo, ->
       DIM_UNITA_MISURA.ID_SORGENTE_UNITA_MISURA.

   Contesto Provincia:
     DWH_ANAG_ARTICOLO.CD_VERSIONE e' utilizzato direttamente per la lookup
     su DWH_ANAG_PROVINCIA.CD_VERSIONE ed e' verificato nel dominio SMALLINT.
   Regole FK:
     riferimento facoltativo NULL -> 0;
     riferimento valorizzato ma non risolto -> -1;
     riferimento risolto -> chiave della dimensione.

   Strategia: SCD Type 1; update dei soli record variati; insert dei nuovi;
   nessuna cancellazione. Tabella temporanea a nome fisso: MAIN non concorrente.
   ===================================================================== */

/* =====================================================================
   DROP PRELIMINARI - DIM_ARTICOLO GIA ESISTENTE
   IF EXISTS evita errori quando un oggetto non e presente.
   CASCADE sulla tabella rimuove i vincoli e gli oggetti dipendenti, incluse
   eventuali FK delle fact. Tali fact devono essere ridistribuite dopo la DIM.
   ===================================================================== */
DROP PROCEDURE IF EXISTS hcbi_ras.pkg_dim_articolo_prc_finalize(
    BIGINT,BIGINT,BIGINT,VARCHAR
);
DROP PROCEDURE IF EXISTS hcbi_ras.pkg_dim_articolo_prc_main(
    BIGINT,BIGINT,BIGINT,VARCHAR
);
DROP PROCEDURE IF EXISTS hcbi_ras.pkg_dim_articolo_prc_initialize(
    BIGINT,BIGINT,BIGINT,VARCHAR
);
DROP TABLE IF EXISTS hcbi_ras.tmp_dim_articolo;
DROP TABLE IF EXISTS hcbi_ras.dim_articolo CASCADE;

CREATE TABLE IF NOT EXISTS hcbi_ras.dim_articolo
(
    id_anag_articolo BIGINT NOT NULL,
    id_sorgente_articolo BIGINT NOT NULL,
    id_periodo_pubblicazione INTEGER NOT NULL,
    cd_articolo VARCHAR(60) NOT NULL,
    nr_livello INTEGER NOT NULL,
    ds_nome TEXT NOT NULL,
    ds_descrizione TEXT NOT NULL,
    fl_eliminato SMALLINT NOT NULL,
    fl_prezzo_regionale SMALLINT NOT NULL,
    id_anag_unita_misura BIGINT NOT NULL,
    id_anag_macro_gruppo BIGINT NOT NULL,
    nr_spese_generali NUMERIC(24,5),
    nr_di_cui_analisi NUMERIC(24,5),
    nr_utile_impresa NUMERIC(24,5),
    dt_last_update TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    fl_analisi_approvata SMALLINT NOT NULL,
    fl_has_utile_impresa SMALLINT NOT NULL,
    fl_analisi_pubblicata SMALLINT NOT NULL,
    id_anag_versione BIGINT NOT NULL,
    fl_is_analisi SMALLINT NOT NULL,
    fl_is_cam SMALLINT NOT NULL,
    fl_is_ufficiale SMALLINT NOT NULL,
    id_sorgente_categoria BIGINT,
    fl_is_manodopera SMALLINT NOT NULL,
    cd_codice_lev1 VARCHAR(60),
    cd_codice_lev2 VARCHAR(60),
    cd_codice_lev3 VARCHAR(60),
    cd_codice_lev4 VARCHAR(60),
    cd_codice_lev5 VARCHAR(60),
    fl_is_minuteria SMALLINT NOT NULL,
    nr_percentuale_aumento NUMERIC(24,5),
    ds_annotazione TEXT,
    fl_esporta_come_articolo SMALLINT NOT NULL,
    fl_escludi_manodopera SMALLINT NOT NULL,
    id_anag_provincia BIGINT NOT NULL,
    dt_creation TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_update_by VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT pk_dim_articolo PRIMARY KEY (id_anag_articolo),
    CONSTRAINT uq_dim_articolo UNIQUE NULLS NOT DISTINCT
      (id_periodo_pubblicazione,cd_articolo,id_anag_versione,id_anag_provincia),
    CONSTRAINT fk_dim_articolo_periodo FOREIGN KEY (id_periodo_pubblicazione)
      REFERENCES hcbi_ras.dim_periodo(id_periodo) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_dim_articolo_provincia FOREIGN KEY (id_anag_provincia)
      REFERENCES hcbi_ras.dim_provincia(id_anag_provincia) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_dim_articolo_versione FOREIGN KEY (id_anag_versione)
      REFERENCES hcbi_ras.dim_versione(id_anag_versione) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_dim_articolo_macro_gruppo FOREIGN KEY (id_anag_macro_gruppo)
      REFERENCES hcbi_ras.dim_macro_gruppo(id_anag_macro_gruppo) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_dim_articolo_unita_misura FOREIGN KEY (id_anag_unita_misura)
      REFERENCES hcbi_ras.dim_unita_misura(id_anag_unita_misura) ON UPDATE RESTRICT ON DELETE RESTRICT
) TABLESPACE pg_default;
ALTER TABLE hcbi_ras.dim_articolo OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.dim_articolo FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.dim_articolo TO hcbi_ras;
GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE hcbi_ras.dim_articolo TO hcbi_utility;
COMMENT ON TABLE hcbi_ras.dim_articolo IS 'Dimensione articoli alimentata da HCBI_RAS.DWH_ANAG_ARTICOLO.';
COMMENT ON CONSTRAINT uq_dim_articolo ON hcbi_ras.dim_articolo IS
'Business key trasformata: periodo, codice articolo, versione e provincia.';

/* Record tecnici della dimensione. */
INSERT INTO hcbi_ras.dim_articolo
(
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
)
VALUES
    (
        0,
        0,
        0,
        'ND',
        0,
        'NON DISPONIBILE',
        'NON DISPONIBILE',
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        TIMESTAMP '1900-01-01 00:00:00',
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        NULL,
        0,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        0,
        0,
        'NON DISPONIBILE',
        0,
        0,
        0,
        clock_timestamp(),
        CURRENT_USER,
        clock_timestamp(),
        CURRENT_USER
    ),
    (
        -1,
        -1,
        -1,
        'AA',
        0,
        'ANAGRAFICA ASSENTE',
        'ANAGRAFICA ASSENTE',
        0,
        0,
        -1,
        -1,
        0,
        0,
        0,
        TIMESTAMP '1900-01-01 00:00:00',
        0,
        0,
        0,
        -1,
        0,
        0,
        0,
        NULL,
        0,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        0,
        0,
        'ANAGRAFICA ASSENTE',
        0,
        0,
        -1,
        clock_timestamp(),
        CURRENT_USER,
        clock_timestamp(),
        CURRENT_USER
    )
ON CONFLICT ON CONSTRAINT pk_dim_articolo DO NOTHING;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_articolo_prc_initialize(
 IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
 IN p_ds_step_name VARCHAR, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE v_id_log BIGINT; v_sqlstate TEXT; v_sqlerrm TEXT; v_log_error TEXT;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,
   p_ds_step_name,clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
 INTO v_id_log;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT;
 p_result:=-1; v_log_error:=left('SQLSTATE='||coalesce(v_sqlstate,'')||E'\nMESSAGE='||coalesce(v_sqlerrm,''),4000);
 IF v_id_log IS NOT NULL THEN
  BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name);
  EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
 END IF;
 RAISE WARNING 'Errore initialize DIM_ARTICOLO: SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;$BODY$;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_articolo_prc_main
(
    IN  p_id_chain_log bigint,
    IN  p_id_chain bigint,
    IN  p_id_step bigint,
    IN  p_ds_step_name character varying,
    OUT p_result integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;

    v_selected bigint := 0;
    v_inserted bigint := 0;
    v_updated bigint := 0;
    v_deleted bigint := 0;
    v_rec_errors bigint := 0;
    v_matched bigint := 0;

    v_lookup_periodo_ko bigint := 0;
    v_lookup_provincia_ko bigint := 0;
    v_lookup_versione_ko bigint := 0;
    v_lookup_macro_gruppo_ko bigint := 0;
    v_lookup_unita_misura_ko bigint := 0;

    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log
    (
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    )
    INTO v_id_log;

    /*
     * Verifica dei record tecnici.
     * Le dimensioni referenziate devono contenere i tappi 0 e -1
     * utilizzati dal processo.
     */

    IF NOT EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_periodo
        WHERE id_periodo = 0
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico 0 mancante in HCBI_RAS.DIM_PERIODO',
                DETAIL =
                    'DIM_ARTICOLO richiede DIM_PERIODO.ID_PERIODO = 0.',
                HINT =
                    'Inserire il tappo 0 in DIM_PERIODO e rilanciare la procedura.';
    END IF;

    IF NOT EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_periodo
        WHERE id_periodo = -1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico -1 mancante in HCBI_RAS.DIM_PERIODO',
                DETAIL =
                    'DIM_ARTICOLO usa -1 quando la lookup del periodo non viene risolta.',
                HINT =
                    'Inserire il tappo -1 in DIM_PERIODO e rilanciare la procedura.';
    END IF;

    IF NOT EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_provincia
        WHERE id_anag_provincia = 0
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico 0 mancante in HCBI_RAS.DIM_PROVINCIA',
                DETAIL =
                    'DIM_ARTICOLO richiede DIM_PROVINCIA.ID_ANAG_PROVINCIA = 0.',
                HINT =
                    'Inserire il tappo 0 in DIM_PROVINCIA e rilanciare la procedura.';
    END IF;

    IF NOT EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_provincia
        WHERE id_anag_provincia = -1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico -1 mancante in HCBI_RAS.DIM_PROVINCIA',
                DETAIL =
                    'DIM_ARTICOLO usa -1 quando la lookup della provincia non viene risolta.',
                HINT =
                    'Inserire il tappo -1 in DIM_PROVINCIA e rilanciare la procedura.';
    END IF;

    IF NOT EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_versione
        WHERE id_anag_versione = 0
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico 0 mancante in HCBI_RAS.DIM_VERSIONE',
                DETAIL =
                    'DIM_ARTICOLO richiede DIM_VERSIONE.ID_ANAG_VERSIONE = 0.',
                HINT =
                    'Inserire il tappo 0 in DIM_VERSIONE e rilanciare la procedura.';
    END IF;

    IF NOT EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_versione
        WHERE id_anag_versione = -1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico -1 mancante in HCBI_RAS.DIM_VERSIONE',
                DETAIL =
                    'DIM_ARTICOLO usa -1 quando la lookup della versione non viene risolta.',
                HINT =
                    'Inserire il tappo -1 in DIM_VERSIONE e rilanciare la procedura.';
    END IF;

    IF NOT EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_macro_gruppo
        WHERE id_anag_macro_gruppo = 0
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico 0 mancante in HCBI_RAS.DIM_MACRO_GRUPPO',
                DETAIL =
                    'DIM_ARTICOLO usa 0 quando NR_MACRO_GRUPPO non è valorizzato.',
                HINT =
                    'Inserire il tappo 0 in DIM_MACRO_GRUPPO e rilanciare la procedura.';
    END IF;

    IF NOT EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_macro_gruppo
        WHERE id_anag_macro_gruppo = -1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico -1 mancante in HCBI_RAS.DIM_MACRO_GRUPPO',
                DETAIL =
                    'DIM_ARTICOLO usa -1 quando la lookup del macro-gruppo non viene risolta.',
                HINT =
                    'Inserire il tappo -1 in DIM_MACRO_GRUPPO e rilanciare la procedura.';
    END IF;

    IF NOT EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_unita_misura
        WHERE id_anag_unita_misura = 0
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico 0 mancante in HCBI_RAS.DIM_UNITA_MISURA',
                DETAIL =
                    'DIM_ARTICOLO usa 0 quando DS_UNITA_MISURA non è valorizzato.',
                HINT =
                    'Inserire il tappo 0 in DIM_UNITA_MISURA e rilanciare la procedura.';
    END IF;

    IF NOT EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_unita_misura
        WHERE id_anag_unita_misura = -1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico -1 mancante in HCBI_RAS.DIM_UNITA_MISURA',
                DETAIL =
                    'DIM_ARTICOLO usa -1 quando la lookup dell''unità di misura non viene risolta.',
                HINT =
                    'Inserire il tappo -1 in DIM_UNITA_MISURA e rilanciare la procedura.';
    END IF;

    /*
     * Obbligatorietà del riferimento alla Provincia.
     */

    IF EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dwh_anag_articolo
        WHERE id_sorgente_provincia IS NULL
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23502',
                MESSAGE =
                    'ID_SORGENTE_PROVINCIA nullo in HCBI_RAS.DWH_ANAG_ARTICOLO',
                DETAIL =
                    'La provincia è obbligatoria nel flusso ANAG_ARTICOLO aggiornato.';
    END IF;

    IF EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dwh_anag_articolo
        WHERE ds_anno IS NULL
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23502',
                MESSAGE =
                    'DS_ANNO nullo in HCBI_RAS.DWH_ANAG_ARTICOLO',
                DETAIL =
                    'DS_ANNO è necessario per contestualizzare la lookup della provincia.';
    END IF;

    IF EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dwh_anag_articolo
        WHERE cd_versione IS NOT NULL
          AND (cd_versione::numeric < -32768 OR cd_versione::numeric > 32767)
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '22003',
                MESSAGE =
                    'CD_VERSIONE fuori dominio SMALLINT in HCBI_RAS.DWH_ANAG_ARTICOLO',
                DETAIL =
                    'CD_VERSIONE deve rientrare nel dominio SMALLINT della Provincia.';
    END IF;

    IF EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dwh_anag_articolo
        WHERE cd_versione IS NULL
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23502',
                MESSAGE =
                    'CD_VERSIONE nullo in HCBI_RAS.DWH_ANAG_ARTICOLO',
                DETAIL =
                    'CD_VERSIONE è necessario per contestualizzare la lookup della provincia.';
    END IF;

    /*
     * Controlli di determinismo.
     */

    IF EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dwh_anag_articolo
        GROUP BY
            ds_anno,
            cd_articolo,
            cd_versione,
            id_sorgente_provincia
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE =
                    'Business key non deterministica: HCBI_RAS.DWH_ANAG_ARTICOLO',
                DETAIL =
                    'Duplicati su DS_ANNO, CD_ARTICOLO, CD_VERSIONE e ID_SORGENTE_PROVINCIA.',
                HINT =
                    'Rieseguire il flusso ANAG_ARTICOLO aggiornato e verificare la UK DWH.';
    END IF;

    IF EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_periodo
        WHERE ds_anno IS NOT NULL
        GROUP BY ds_anno
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE =
                    'Lookup non deterministica: HCBI_RAS.DIM_PERIODO.DS_ANNO',
                DETAIL =
                    'Esistono più righe in DIM_PERIODO con lo stesso DS_ANNO.',
                HINT =
                    'Eseguire il test duplicati su DIM_PERIODO e correggere la business key.';
    END IF;

    IF EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dwh_anag_provincia
        WHERE id_sorgente_provincia IS NOT NULL
        GROUP BY
            anno,
            cd_versione,
            id_sorgente_provincia
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE =
                    'Lookup non deterministica: HCBI_RAS.DWH_ANAG_PROVINCIA',
                DETAIL =
                    'Esistono più righe con gli stessi ANNO, CD_VERSIONE e ID_SORGENTE_PROVINCIA.',
                HINT =
                    'Verificare la candidate key contestualizzata di DWH_ANAG_PROVINCIA.';
    END IF;

    IF EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_provincia
        WHERE cd_provincia IS NOT NULL
        GROUP BY
            anno,
            cd_versione,
            cd_provincia
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE =
                    'Lookup non deterministica: HCBI_RAS.DIM_PROVINCIA',
                DETAIL =
                    'Esistono più righe con gli stessi ANNO, CD_VERSIONE e CD_PROVINCIA.',
                HINT =
                    'Verificare il vincolo univoco su ANNO, CD_VERSIONE e CD_PROVINCIA.';
    END IF;

    IF EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_versione
        GROUP BY
            id_periodo_pubblicazione,
            cd_versione,
            id_anag_provincia
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE =
                    'Lookup non deterministica: HCBI_RAS.DIM_VERSIONE',
                DETAIL =
                    'Duplicati sulla chiave ID_PERIODO_PUBBLICAZIONE, CD_VERSIONE e ID_ANAG_PROVINCIA.',
                HINT =
                    'Eseguire il test duplicati sulla business key di DIM_VERSIONE.';
    END IF;

    IF EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dwh_anag_macro_gruppo
        WHERE id_sorgente_macro_gruppo IS NOT NULL
        GROUP BY id_sorgente_macro_gruppo
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE =
                    'Lookup non deterministica: HCBI_RAS.DWH_ANAG_MACRO_GRUPPO',
                DETAIL =
                    'Esistono più righe con lo stesso ID_SORGENTE_MACRO_GRUPPO.',
                HINT =
                    'Verificare la candidate key di DWH_ANAG_MACRO_GRUPPO.';
    END IF;

    IF EXISTS
    (
        SELECT 1
        FROM hcbi_ras.dim_unita_misura
        WHERE id_sorgente_unita_misura IS NOT NULL
        GROUP BY id_sorgente_unita_misura
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE =
                    'Lookup non deterministica: HCBI_RAS.DIM_UNITA_MISURA',
                DETAIL =
                    'Esistono più righe con lo stesso ID_SORGENTE_UNITA_MISURA.',
                HINT =
                    'Verificare la candidate key di DIM_UNITA_MISURA.';
    END IF;

    /*
     * Materializzazione della sorgente arricchita.
     */

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_articolo;

    CREATE TABLE hcbi_ras.tmp_dim_articolo AS
    WITH base AS MATERIALIZED
    (
        SELECT
            src.*,
            COALESCE(
                dp.id_periodo,
                (-1)::integer
            ) AS periodo_lkp,
            COALESCE(
                dpr.id_anag_provincia,
                (-1)::bigint
            ) AS provincia_lkp,
            dp.id_periodo IS NULL AS periodo_ko,
            dpr.id_anag_provincia IS NULL AS provincia_ko
        FROM hcbi_ras.dwh_anag_articolo AS src

        LEFT JOIN hcbi_ras.dim_periodo AS dp
            ON dp.ds_anno = src.ds_anno

        LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwp
            ON dwp.anno = src.ds_anno::integer
           AND dwp.cd_versione = src.cd_versione::smallint
           AND dwp.id_sorgente_provincia =
               src.id_sorgente_provincia

        LEFT JOIN hcbi_ras.dim_provincia AS dpr
            ON dpr.id_anag_provincia = dwp.id_anag_provincia
           AND dpr.anno = dwp.anno
           AND dpr.cd_versione = dwp.cd_versione
    )
    SELECT
        b.id_anag_articolo,
        b.id_sorgente_articolo,
        b.periodo_lkp AS id_periodo_pubblicazione,

        regexp_replace(
            btrim(b.cd_articolo),
            '\.$',
            ''
        )::character varying(60) AS cd_articolo,

        b.nr_livello,
        b.ds_nome,
        b.ds_descrizione,
        b.fl_eliminato,
        b.fl_prezzo_regionale,

        CASE
            WHEN b.ds_unita_misura IS NULL
                THEN 0::bigint
            ELSE COALESCE(
                dum.id_anag_unita_misura,
                (-1)::bigint
            )
        END AS id_anag_unita_misura,

        CASE
            WHEN b.nr_macro_gruppo IS NULL
                THEN 0::bigint
            ELSE COALESCE(
                dmg.id_anag_macro_gruppo,
                (-1)::bigint
            )
        END AS id_anag_macro_gruppo,

        b.nr_spese_generali,
        b.nr_di_cui_analisi,
        b.nr_utile_impresa,
        b.dt_last_update,
        b.fl_analisi_approvata,
        b.fl_has_utile_impresa,
        b.fl_analisi_pubblicata,

        COALESCE(
            dv.id_anag_versione,
            (-1)::bigint
        ) AS id_anag_versione,

        b.fl_is_analisi,
        b.fl_is_cam,
        b.fl_is_ufficiale,
        b.id_sorgente_categoria,
        b.fl_is_manodopera,
        b.cd_codice_lev1,
        b.cd_codice_lev2,
        b.cd_codice_lev3,
        b.cd_codice_lev4,
        b.cd_codice_lev5,
        b.fl_is_minuteria,
        b.nr_percentuale_aumento,
        b.ds_annotazione,
        b.fl_esporta_come_articolo,
        b.fl_escludi_manodopera,
        b.provincia_lkp AS id_anag_provincia,

        b.periodo_ko,
        b.provincia_ko,
        dv.id_anag_versione IS NULL AS versione_ko,

        (
            b.nr_macro_gruppo IS NOT NULL
            AND dmg.id_anag_macro_gruppo IS NULL
        ) AS macro_gruppo_ko,

        (
            b.ds_unita_misura IS NOT NULL
            AND dum.id_anag_unita_misura IS NULL
        ) AS unita_misura_ko

    FROM base AS b

    LEFT JOIN hcbi_ras.dim_versione AS dv
        ON dv.id_periodo_pubblicazione =
           b.periodo_lkp
       AND dv.cd_versione =
           b.cd_versione
       AND dv.id_anag_provincia =
           b.provincia_lkp

    LEFT JOIN hcbi_ras.dwh_anag_macro_gruppo AS dwmg
        ON dwmg.id_sorgente_macro_gruppo =
           b.nr_macro_gruppo::bigint

    LEFT JOIN hcbi_ras.dim_macro_gruppo AS dmg
        ON dmg.id_anag_macro_gruppo =
           dwmg.id_anag_macro_gruppo

    LEFT JOIN hcbi_ras.dim_unita_misura AS dum
        ON dum.id_sorgente_unita_misura =
           b.ds_unita_misura;

    /*
     * Controlli preventivi sulla tabella di lavoro.
     */

    CREATE UNIQUE INDEX tmp_dim_articolo_pk
        ON hcbi_ras.tmp_dim_articolo
        (id_anag_articolo)
        NULLS NOT DISTINCT;

    CREATE UNIQUE INDEX tmp_dim_articolo_bk
        ON hcbi_ras.tmp_dim_articolo
        (
            id_periodo_pubblicazione,
            cd_articolo,
            id_anag_versione,
            id_anag_provincia
        )
        NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_articolo;

    /*
     * Conteggi delle lookup non risolte.
     */

    SELECT
        count(*),
        count(*) FILTER (WHERE periodo_ko),
        count(*) FILTER (WHERE provincia_ko),
        count(*) FILTER (WHERE versione_ko),
        count(*) FILTER (WHERE macro_gruppo_ko),
        count(*) FILTER (WHERE unita_misura_ko)
    INTO
        v_selected,
        v_lookup_periodo_ko,
        v_lookup_provincia_ko,
        v_lookup_versione_ko,
        v_lookup_macro_gruppo_ko,
        v_lookup_unita_misura_ko
    FROM hcbi_ras.tmp_dim_articolo;

    v_rec_errors :=
          v_lookup_periodo_ko
        + v_lookup_provincia_ko
        + v_lookup_versione_ko
        + v_lookup_macro_gruppo_ko
        + v_lookup_unita_misura_ko;

    IF v_lookup_periodo_ko > 0 THEN
        RAISE WARNING
            'DIM_ARTICOLO: % lookup DIM_PERIODO non risolte.',
            v_lookup_periodo_ko;
    END IF;

    IF v_lookup_provincia_ko > 0 THEN
        RAISE WARNING
            'DIM_ARTICOLO: % lookup DIM_PROVINCIA non risolte.',
            v_lookup_provincia_ko;
    END IF;

    IF v_lookup_versione_ko > 0 THEN
        RAISE WARNING
            'DIM_ARTICOLO: % lookup DIM_VERSIONE non risolte.',
            v_lookup_versione_ko;
    END IF;

    IF v_lookup_macro_gruppo_ko > 0 THEN
        RAISE WARNING
            'DIM_ARTICOLO: % lookup DIM_MACRO_GRUPPO non risolte.',
            v_lookup_macro_gruppo_ko;
    END IF;

    IF v_lookup_unita_misura_ko > 0 THEN
        RAISE WARNING
            'DIM_ARTICOLO: % lookup DIM_UNITA_MISURA non risolte.',
            v_lookup_unita_misura_ko;
    END IF;

    /*
     * Aggiornamento dei soli record variati.
     */

    UPDATE hcbi_ras.dim_articolo AS d
       SET id_sorgente_articolo =
               src.id_sorgente_articolo,
           id_periodo_pubblicazione =
               src.id_periodo_pubblicazione,
           cd_articolo =
               src.cd_articolo,
           nr_livello =
               src.nr_livello,
           ds_nome =
               src.ds_nome,
           ds_descrizione =
               src.ds_descrizione,
           fl_eliminato =
               src.fl_eliminato,
           fl_prezzo_regionale =
               src.fl_prezzo_regionale,
           id_anag_unita_misura =
               src.id_anag_unita_misura,
           id_anag_macro_gruppo =
               src.id_anag_macro_gruppo,
           nr_spese_generali =
               src.nr_spese_generali,
           nr_di_cui_analisi =
               src.nr_di_cui_analisi,
           nr_utile_impresa =
               src.nr_utile_impresa,
           dt_last_update =
               src.dt_last_update,
           fl_analisi_approvata =
               src.fl_analisi_approvata,
           fl_has_utile_impresa =
               src.fl_has_utile_impresa,
           fl_analisi_pubblicata =
               src.fl_analisi_pubblicata,
           id_anag_versione =
               src.id_anag_versione,
           fl_is_analisi =
               src.fl_is_analisi,
           fl_is_cam =
               src.fl_is_cam,
           fl_is_ufficiale =
               src.fl_is_ufficiale,
           id_sorgente_categoria =
               src.id_sorgente_categoria,
           fl_is_manodopera =
               src.fl_is_manodopera,
           cd_codice_lev1 =
               src.cd_codice_lev1,
           cd_codice_lev2 =
               src.cd_codice_lev2,
           cd_codice_lev3 =
               src.cd_codice_lev3,
           cd_codice_lev4 =
               src.cd_codice_lev4,
           cd_codice_lev5 =
               src.cd_codice_lev5,
           fl_is_minuteria =
               src.fl_is_minuteria,
           nr_percentuale_aumento =
               src.nr_percentuale_aumento,
           ds_annotazione =
               src.ds_annotazione,
           fl_esporta_come_articolo =
               src.fl_esporta_come_articolo,
           fl_escludi_manodopera =
               src.fl_escludi_manodopera,
           id_anag_provincia =
               src.id_anag_provincia,
           dt_update =
               clock_timestamp(),
           tx_update_by =
               p_ds_step_name
      FROM hcbi_ras.tmp_dim_articolo AS src
     WHERE d.id_anag_articolo =
           src.id_anag_articolo
       AND ROW
       (
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
       )
       IS DISTINCT FROM ROW
       (
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

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    /*
     * Inserimento dei nuovi record.
     */

    INSERT INTO hcbi_ras.dim_articolo
    (
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
    )
    SELECT
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
    FROM hcbi_ras.tmp_dim_articolo AS src
    ON CONFLICT ON CONSTRAINT pk_dim_articolo
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    /*
     * Riconciliazione per chiave primaria.
     */

    SELECT count(*)
    INTO v_matched
    FROM hcbi_ras.dim_articolo AS d
    INNER JOIN hcbi_ras.tmp_dim_articolo AS src
        ON src.id_anag_articolo =
           d.id_anag_articolo;

    IF v_selected <> v_matched THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = format(
                    'Riconciliazione DIM_ARTICOLO non valida: selected=%s, matched=%s',
                    v_selected,
                    v_matched
                ),
                DETAIL =
                    'Non tutte le chiavi ID_ANAG_ARTICOLO della sorgente risultano presenti nella dimensione.';
    END IF;

    IF v_selected <>
       (
           SELECT count(*)
           FROM hcbi_ras.dwh_anag_articolo
       )
    THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE =
                    'Riconciliazione sorgente DIM_ARTICOLO non valida',
                DETAIL = format(
                    'Righe DWH=%s, righe temporanee=%s.',
                    (
                        SELECT count(*)
                        FROM hcbi_ras.dwh_anag_articolo
                    ),
                    v_selected
                );
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log
    (
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_articolo;

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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dim_articolo;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante il cleanup di TMP_DIM_ARTICOLO: SQLSTATE=%, errore=%',
                    SQLSTATE,
                    SQLERRM;
        END;

        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' ||
                    coalesce(v_sqlstate, ''),
                'MESSAGE=' ||
                    left(coalesce(v_sqlerrm, ''), 1500),
                CASE
                    WHEN nullif(v_sql_detail, '') IS NOT NULL
                        THEN 'DETAIL=' ||
                             left(v_sql_detail, 1000)
                END,
                CASE
                    WHEN nullif(v_sql_hint, '') IS NOT NULL
                        THEN 'HINT=' ||
                             left(v_sql_hint, 500)
                END,
                CASE
                    WHEN nullif(v_sql_context, '') IS NOT NULL
                        THEN 'CONTEXT=' ||
                             left(v_sql_context, 1000)
                END
            ),
            4000
        );

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log
                (
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::timestamp,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore durante il logging: SQLSTATE=%, errore=%',
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in PKG_DIM_ARTICOLO_PRC_MAIN: SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_articolo_prc_finalize(
 IN p_id_chain_log BIGINT, IN p_id_chain BIGINT, IN p_id_step BIGINT,
 IN p_ds_step_name VARCHAR, OUT p_result INTEGER)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path=pg_catalog,hcbi_ras,hcbi_utility
AS $BODY$
DECLARE v_id_log BIGINT; v_sqlstate TEXT; v_sqlerrm TEXT; v_log_error TEXT;
BEGIN
 p_result:=-1;
 SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
  clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;
 ANALYZE hcbi_ras.dim_articolo;
 CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,0,0,0,0,0,'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
 p_result:=1;
EXCEPTION WHEN OTHERS THEN
 GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT;
 p_result:=-1; v_log_error:=left('SQLSTATE='||coalesce(v_sqlstate,'')||E'\nMESSAGE='||coalesce(v_sqlerrm,''),4000);
 IF v_id_log IS NOT NULL THEN BEGIN CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',v_log_error,clock_timestamp()::timestamp,p_ds_step_name);
 EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END; END IF;
 RAISE WARNING 'Errore FINALIZE DIM_ARTICOLO: SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_articolo_prc_initialize(BIGINT,BIGINT,BIGINT,VARCHAR) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dim_articolo_prc_main(BIGINT,BIGINT,BIGINT,VARCHAR) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_dim_articolo_prc_finalize(BIGINT,BIGINT,BIGINT,VARCHAR) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_articolo_prc_initialize(BIGINT,BIGINT,BIGINT,VARCHAR) TO PUBLIC,hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_articolo_prc_main(BIGINT,BIGINT,BIGINT,VARCHAR) TO PUBLIC,hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_articolo_prc_finalize(BIGINT,BIGINT,BIGINT,VARCHAR) TO PUBLIC,hcbi_ras,hcbi_utility;

/* TEST POST-DEPLOYMENT */
-- T01: SELECT id_anag_articolo,cd_articolo FROM hcbi_ras.dim_articolo WHERE id_anag_articolo IN(0,-1);
-- T02: SELECT id_anag_articolo,count(*) FROM hcbi_ras.dim_articolo GROUP BY 1 HAVING count(*)>1;
-- T03: SELECT id_periodo_pubblicazione,cd_articolo,id_anag_versione,id_anag_provincia,count(*) FROM hcbi_ras.dim_articolo GROUP BY 1,2,3,4 HAVING count(*)>1;
-- T04: SELECT count(*) FROM hcbi_ras.dwh_anag_articolo s LEFT JOIN hcbi_ras.dim_articolo d USING(id_anag_articolo) WHERE d.id_anag_articolo IS NULL;
-- T05: SELECT count(*) FROM hcbi_ras.dim_articolo d LEFT JOIN hcbi_ras.dim_periodo p ON p.id_periodo=d.id_periodo_pubblicazione LEFT JOIN hcbi_ras.dim_provincia pr ON pr.id_anag_provincia=d.id_anag_provincia LEFT JOIN hcbi_ras.dim_versione v ON v.id_anag_versione=d.id_anag_versione LEFT JOIN hcbi_ras.dim_macro_gruppo mg ON mg.id_anag_macro_gruppo=d.id_anag_macro_gruppo LEFT JOIN hcbi_ras.dim_unita_misura um ON um.id_anag_unita_misura=d.id_anag_unita_misura WHERE p.id_periodo IS NULL OR pr.id_anag_provincia IS NULL OR v.id_anag_versione IS NULL OR mg.id_anag_macro_gruppo IS NULL OR um.id_anag_unita_misura IS NULL;
-- T06: SELECT count(*) FILTER(WHERE id_periodo_pubblicazione=-1),count(*) FILTER(WHERE id_anag_provincia=-1),count(*) FILTER(WHERE id_anag_versione=-1),count(*) FILTER(WHERE id_anag_macro_gruppo=-1),count(*) FILTER(WHERE id_anag_unita_misura=-1) FROM hcbi_ras.dim_articolo;
-- T07: rilanciare le procedure senza modificare la DWH; atteso inserted=0, updated=0.
-- T08: diagnostica completa dei tappi mancanti. Atteso: zero righe.
-- SELECT * FROM (
--   SELECT 'DIM_PERIODO' AS tabella, v.id AS tappo
--   FROM (VALUES (0),(-1)) v(id)
--   WHERE NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo d WHERE d.id_periodo=v.id)
--   UNION ALL
--   SELECT 'DIM_PROVINCIA', v.id FROM (VALUES (0),(-1)) v(id)
--   WHERE NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia d WHERE d.id_anag_provincia=v.id)
--   UNION ALL
--   SELECT 'DIM_VERSIONE', v.id FROM (VALUES (0),(-1)) v(id)
--   WHERE NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione d WHERE d.id_anag_versione=v.id)
--   UNION ALL
--   SELECT 'DIM_MACRO_GRUPPO', v.id FROM (VALUES (0),(-1)) v(id)
--   WHERE NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_macro_gruppo d WHERE d.id_anag_macro_gruppo=v.id)
--   UNION ALL
--   SELECT 'DIM_UNITA_MISURA', v.id FROM (VALUES (0),(-1)) v(id)
--   WHERE NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_unita_misura d WHERE d.id_anag_unita_misura=v.id)
-- ) x ORDER BY tabella,tappo;

-- T09: diagnostica delle lookup non deterministiche. Atteso: zero righe.
-- SELECT * FROM (
--   SELECT 'DIM_PERIODO.DS_ANNO' AS lookup,
--          ds_anno::text AS valore, count(*) AS occorrenze
--   FROM hcbi_ras.dim_periodo
--   WHERE ds_anno IS NOT NULL GROUP BY ds_anno HAVING count(*) > 1
--   UNION ALL
--   SELECT 'DWH_ANAG_PROVINCIA.CHIAVE_CONTESTUALIZZATA',
--          concat_ws('|',anno::text,cd_versione::text,
--                    id_sorgente_provincia::text), count(*)
--   FROM hcbi_ras.dwh_anag_provincia
--   WHERE id_sorgente_provincia IS NOT NULL
--   GROUP BY anno,cd_versione,id_sorgente_provincia HAVING count(*) > 1
--   UNION ALL
--   SELECT 'DIM_PROVINCIA.BUSINESS_KEY', concat_ws('|',anno::text,cd_versione::text,cd_provincia::text), count(*)
--   FROM hcbi_ras.dim_provincia
--   WHERE cd_provincia IS NOT NULL GROUP BY anno,cd_versione,cd_provincia HAVING count(*) > 1
--   UNION ALL
--   SELECT 'DIM_VERSIONE.BUSINESS_KEY',
--          concat_ws('|',id_periodo_pubblicazione::text,cd_versione::text,
--                    id_anag_provincia::text), count(*)
--   FROM hcbi_ras.dim_versione
--   GROUP BY id_periodo_pubblicazione,cd_versione,id_anag_provincia
--   HAVING count(*) > 1
--   UNION ALL
--   SELECT 'DWH_ANAG_MACRO_GRUPPO.ID_SORGENTE_MACRO_GRUPPO',
--          id_sorgente_macro_gruppo::text, count(*)
--   FROM hcbi_ras.dwh_anag_macro_gruppo
--   WHERE id_sorgente_macro_gruppo IS NOT NULL
--   GROUP BY id_sorgente_macro_gruppo HAVING count(*) > 1
--   UNION ALL
--   SELECT 'DIM_UNITA_MISURA.ID_SORGENTE_UNITA_MISURA',
--          id_sorgente_unita_misura::text, count(*)
--   FROM hcbi_ras.dim_unita_misura
--   WHERE id_sorgente_unita_misura IS NOT NULL
--   GROUP BY id_sorgente_unita_misura HAVING count(*) > 1
-- ) q ORDER BY lookup,valore;

-- T10: codici sorgente con punto finale. Informativo.
-- SELECT id_anag_articolo,cd_articolo,
--        regexp_replace(btrim(cd_articolo), '\.$', '') AS cd_articolo_normalizzato
-- FROM hcbi_ras.dwh_anag_articolo
-- WHERE btrim(cd_articolo) LIKE '%.';

-- T11: collisioni introdotte dalla normalizzazione nel nuovo grain. Atteso: zero righe.
-- SELECT ds_anno,
--        regexp_replace(btrim(cd_articolo), '\.$', '') AS cd_articolo_normalizzato,
--        cd_versione,id_sorgente_provincia,count(*) AS occorrenze
-- FROM hcbi_ras.dwh_anag_articolo
-- GROUP BY ds_anno,regexp_replace(btrim(cd_articolo), '\.$', ''),
--          cd_versione,id_sorgente_provincia
-- HAVING count(*) > 1;

-- T12: business key DWH aggiornata. Atteso: zero righe.
-- SELECT ds_anno,cd_articolo,cd_versione,id_sorgente_provincia,count(*)
-- FROM hcbi_ras.dwh_anag_articolo
-- GROUP BY ds_anno,cd_articolo,cd_versione,id_sorgente_provincia
-- HAVING count(*) > 1;

-- T13: province DWH non risolte nella DIM. Informativo, atteso: zero.
-- SELECT count(*) AS province_non_risolte
-- FROM hcbi_ras.dwh_anag_articolo a
-- LEFT JOIN hcbi_ras.dwh_anag_provincia p
--   ON p.anno=a.ds_anno::integer
--  AND p.cd_versione=a.cd_versione::smallint
--  AND p.id_sorgente_provincia=a.id_sorgente_provincia
-- LEFT JOIN hcbi_ras.dim_provincia d
--   ON d.id_anag_provincia=p.id_anag_provincia
--  AND d.anno=p.anno
--  AND d.cd_versione=p.cd_versione
-- WHERE d.id_anag_provincia IS NULL;

-- T14: coerenza provincia DIM rispetto alla sorgente. Atteso: zero.
-- SELECT count(*) AS disallineamenti
-- FROM hcbi_ras.dwh_anag_articolo a
-- JOIN hcbi_ras.dim_articolo d ON d.id_anag_articolo=a.id_anag_articolo
-- JOIN hcbi_ras.dwh_anag_provincia p
--   ON p.anno=a.ds_anno::integer
--  AND p.cd_versione=a.cd_versione::smallint
--  AND p.id_sorgente_provincia=a.id_sorgente_provincia
-- JOIN hcbi_ras.dim_provincia pr
--   ON pr.id_anag_provincia=p.id_anag_provincia
--  AND pr.anno=p.anno
--  AND pr.cd_versione=p.cd_versione
-- WHERE d.id_anag_provincia IS DISTINCT FROM pr.id_anag_provincia;

/* Ordine: DIM_PERIODO, DIM_PROVINCIA, DIM_VERSIONE, DIM_MACRO_GRUPPO,
   DIM_UNITA_MISURA, DIM_ARTICOLO, quindi le fact dipendenti. */

/* DEPLOYMENT: eseguire dopo il ricaricamento completo di DWH_ANAG_ARTICOLO.
   Il DROP CASCADE della DIM rimuove le FK dipendenti; ridistribuire poi le
   fact e rieseguire i relativi controlli di orfani e riconciliazione. */
