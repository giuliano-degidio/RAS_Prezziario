/* =====================================================================
   DIM_TIPOLOGIA - DDL E PROCEDURE DI CARICAMENTO - VERSIONE 09
   Target: PostgreSQL 15.9 / 17
   Schema: hcbi_ras

   Sorgente:
       hcbi_ras.dwh_anag_tipologia

   Lookup dimensionali:
       1. Provincia
          Il contesto versione della Provincia e' CD_VERSIONE:
          dwh_anag_tipologia.ds_anno, cd_versione,
          id_sorgente_provincia
              = dwh_anag_provincia.anno, cd_versione,
                id_sorgente_provincia
          La DIM_PROVINCIA viene quindi risolta tramite la chiave DWH
          mantenuta nella dimensione:
          dwh_anag_provincia.id_anag_provincia
              = dim_provincia.id_anag_provincia
          con verifica ulteriore del medesimo contesto anno/cd_versione.

       2. Periodo
          dwh_anag_tipologia.ds_anno
              = dim_periodo.ds_anno

       3. Versione
          dim_periodo.id_periodo
              = dim_versione.id_periodo_pubblicazione
          dwh_anag_tipologia.cd_versione
              = dim_versione.cd_versione
          dim_provincia.id_anag_provincia
              = dim_versione.id_anag_provincia

   Destinazione:
       hcbi_ras.dim_tipologia

   Grain:
       una riga per ID_ANAG_TIPOLOGIA.

   Chiave primaria:
       id_anag_tipologia

   Business key dimensionale:
       cd_tipologia, id_periodo_pubblicazione,
       id_anag_versione, id_anag_provincia

   Regola FK:
       - lookup risolta: chiave della dimensione referenziata;
       - lookup non risolta: -1.

   Poiche' i tre riferimenti della DWH sorgente sono NOT NULL, non viene
   applicato il tappo 0. Devono esistere i record tecnici -1 in:
       dim_provincia.id_anag_provincia
       dim_periodo.id_periodo
       dim_versione.id_anag_versione

   ASSUNZIONI DA VALIDARE:
       - dwh_anag_tipologia espone cd_versione, convertibile in SMALLINT
         e utilizzato direttamente come contesto della Provincia;
       - dwh_anag_provincia e' univoca su
         (anno, cd_versione, id_sorgente_provincia);
       - dim_provincia mantiene id_anag_provincia della DWH sorgente ed e'
         univoca su (anno, cd_versione, cd_provincia);
       - DIM_AREA_VASTA e' una dipendenza di DIM_PROVINCIA e non viene
         referenziata direttamente da DIM_TIPOLOGIA;
       - dim_periodo.ds_anno e' univoco;
       - dim_versione espone i nomi fisici definitivi:
         id_anag_versione, id_periodo_pubblicazione,
         cd_versione, id_anag_provincia;
       - dim_versione e' gia' popolata prima di DIM_TIPOLOGIA;
       - caricamento SCD Type 1, nessun delete;
       - PRC_MAIN non viene eseguita in concorrenza.
   ===================================================================== */

/* =====================================================================
   TABELLA DIMENSIONALE
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dim_tipologia
(
    id_anag_tipologia       BIGINT NOT NULL,
    cd_tipologia            VARCHAR(60) NOT NULL,
    ds_tipologia            TEXT NOT NULL,
    id_anag_provincia       BIGINT NOT NULL,
    id_periodo_pubblicazione INTEGER NOT NULL,
    id_anag_versione        BIGINT NOT NULL,
    dt_creation             TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by          VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update               TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_update_by            VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,

    CONSTRAINT pk_dim_tipologia
        PRIMARY KEY (id_anag_tipologia),

    CONSTRAINT uq_dim_tipologia
        UNIQUE NULLS NOT DISTINCT
        (cd_tipologia, id_periodo_pubblicazione,
         id_anag_versione, id_anag_provincia),

    CONSTRAINT fk_dim_tipologia_provincia
        FOREIGN KEY (id_anag_provincia)
        REFERENCES hcbi_ras.dim_provincia (id_anag_provincia)
        ON UPDATE RESTRICT ON DELETE RESTRICT,

    CONSTRAINT fk_dim_tipologia_periodo
        FOREIGN KEY (id_periodo_pubblicazione)
        REFERENCES hcbi_ras.dim_periodo (id_periodo)
        ON UPDATE RESTRICT ON DELETE RESTRICT,

    CONSTRAINT fk_dim_tipologia_versione
        FOREIGN KEY (id_anag_versione)
        REFERENCES hcbi_ras.dim_versione (id_anag_versione)
        ON UPDATE RESTRICT ON DELETE RESTRICT
)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dim_tipologia OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.dim_tipologia FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.dim_tipologia TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.dim_tipologia TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dim_tipologia IS
    'Dimensione delle tipologie alimentata da HCBI_RAS.DWH_ANAG_TIPOLOGIA.';
COMMENT ON COLUMN hcbi_ras.dim_tipologia.id_anag_tipologia IS
    'Chiave primaria mantenuta dalla chiave DWH sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_tipologia.cd_tipologia IS
    'Codice della tipologia normalizzato eliminando esclusivamente un eventuale punto finale.';
COMMENT ON COLUMN hcbi_ras.dim_tipologia.ds_tipologia IS
    'Descrizione della tipologia.';
COMMENT ON COLUMN hcbi_ras.dim_tipologia.id_anag_provincia IS
    'FK verso DIM_PROVINCIA risolta in DWH_ANAG_PROVINCIA tramite anno, cd_versione di DWH_ANAG_TIPOLOGIA e id_sorgente_provincia; la DIM e quindi raggiunta tramite id_anag_provincia nel medesimo contesto anno/cd_versione; -1 se la lookup non e risolta.';
COMMENT ON COLUMN hcbi_ras.dim_tipologia.id_periodo_pubblicazione IS
    'FK verso DIM_PERIODO; -1 se la lookup non e risolta.';
COMMENT ON COLUMN hcbi_ras.dim_tipologia.id_anag_versione IS
    'FK verso DIM_VERSIONE; -1 se la lookup composta periodo-versione-provincia non e risolta.';
COMMENT ON CONSTRAINT pk_dim_tipologia ON hcbi_ras.dim_tipologia IS
    'Chiave primaria: id_anag_tipologia.';
COMMENT ON CONSTRAINT uq_dim_tipologia ON hcbi_ras.dim_tipologia IS
    'Business key: cd_tipologia, id_periodo_pubblicazione, id_anag_versione, id_anag_provincia.';
COMMENT ON CONSTRAINT fk_dim_tipologia_provincia ON hcbi_ras.dim_tipologia IS
    'Relazione verso DIM_PROVINCIA.';
COMMENT ON CONSTRAINT fk_dim_tipologia_periodo ON hcbi_ras.dim_tipologia IS
    'Relazione verso DIM_PERIODO.';
COMMENT ON CONSTRAINT fk_dim_tipologia_versione ON hcbi_ras.dim_tipologia IS
    'Relazione verso DIM_VERSIONE.';
/* =====================================================================
   RECORD TECNICI DIM_TIPOLOGIA
   Prerequisito: righe 0 e -1 gia' presenti nelle dimensioni referenziate.
   ===================================================================== */
INSERT INTO hcbi_ras.dim_tipologia
(
    id_anag_tipologia, cd_tipologia, ds_tipologia,
    id_anag_provincia, id_periodo_pubblicazione, id_anag_versione,
    dt_creation, tx_creation_by, dt_update, tx_update_by
)
VALUES
(
    0, 'ND', 'NON DISPONIBILE', 0, 0, 0,
    clock_timestamp(), CURRENT_USER, clock_timestamp(), CURRENT_USER
),
(
    -1, 'AA', 'ANAGRAFICA ASSENTE', -1, -1, -1,
    clock_timestamp(), CURRENT_USER, clock_timestamp(), CURRENT_USER
)
ON CONFLICT ON CONSTRAINT pk_dim_tipologia DO NOTHING;
/* =====================================================================
   PROCEDURA INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_tipologia_prc_initialize(
    IN p_id_chain_log BIGINT,
    IN p_id_chain BIGINT,
    IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING,
    OUT p_result INTEGER
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::TIMESTAMP,
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name)
    INTO v_id_log;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0, 'SUCCESS',
        clock_timestamp()::TIMESTAMP, p_ds_step_name);

    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE, v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL, v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    v_log_error := LEFT(CONCAT_WS(E'\n',
        'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500),
        CASE WHEN NULLIF(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||LEFT(v_sql_detail,1000) END,
        CASE WHEN NULLIF(v_sql_hint,'') IS NOT NULL THEN 'HINT='||LEFT(v_sql_hint,500) END,
        CASE WHEN NULLIF(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||LEFT(v_sql_context,800) END),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',v_log_error,
                clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
        END;
    END IF;
    RAISE WARNING
        'Errore in pkg_dim_tipologia_prc_initialize. SQLSTATE=%, errore=%',
        v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_tipologia_prc_initialize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_tipologia_prc_initialize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_dim_tipologia_prc_initialize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING)
IS 'Inizializza il caricamento DIM_TIPOLOGIA e registra l esecuzione nel log.';

/* =====================================================================
   PROCEDURA MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_tipologia_prc_main(
    IN p_id_chain_log BIGINT,
    IN p_id_chain BIGINT,
    IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING,
    OUT p_result INTEGER
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT;
    v_selected BIGINT := 0;
    v_inserted BIGINT := 0;
    v_updated BIGINT := 0;
    v_deleted BIGINT := 0;
    v_rec_errors BIGINT := 0;
    v_matched BIGINT := 0;
    v_lookup_provincia_ko BIGINT := 0;
    v_lookup_periodo_ko BIGINT := 0;
    v_lookup_versione_ko BIGINT := 0;
    v_codice_tipologia_assente BIGINT := 0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::TIMESTAMP,
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name)
    INTO v_id_log;

    /* Verifica dei record tecnici 0 e -1 richiesti dalle FK. */
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia = 0)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia = -1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
            MESSAGE='Record tecnici 0 e/o -1 non presenti in DIM_PROVINCIA';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo = 0)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo = -1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
            MESSAGE='Record tecnici 0 e/o -1 non presenti in DIM_PERIODO';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione = 0)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione = -1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
            MESSAGE='Record tecnici 0 e/o -1 non presenti in DIM_VERSIONE';
    END IF;

    /* Controlli di determinismo delle lookup. */
    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dwh_anag_provincia
        WHERE id_sorgente_provincia IS NOT NULL
        GROUP BY anno, cd_versione, id_sorgente_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DWH_ANAG_PROVINCIA non deterministica',
            DETAIL='Esistono piu record con gli stessi anno, cd_versione e id_sorgente_provincia.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_provincia
        WHERE cd_provincia IS NOT NULL
        GROUP BY anno, cd_versione, cd_provincia HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_PROVINCIA non deterministica',
            DETAIL='Esistono piu record con gli stessi anno, cd_versione e cd_provincia.';
    END IF;

    /* Il riferimento e il contesto Provincia sono obbligatori nella sorgente. */
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_tipologia
        WHERE id_sorgente_provincia IS NULL
    ) THEN
        RAISE EXCEPTION USING ERRCODE='23502',
            MESSAGE='ID_SORGENTE_PROVINCIA nullo in DWH_ANAG_TIPOLOGIA',
            DETAIL='La Provincia e obbligatoria nel flusso DIM_TIPOLOGIA.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_tipologia
        WHERE id_sorgente_provincia IS NOT NULL
          AND ds_anno IS NULL
    ) THEN
        RAISE EXCEPTION USING ERRCODE='23502',
            MESSAGE='DS_ANNO nullo in DWH_ANAG_TIPOLOGIA',
            DETAIL='DS_ANNO e necessario per contestualizzare la lookup Provincia.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_tipologia
        WHERE id_sorgente_provincia IS NOT NULL
          AND cd_versione IS NOT NULL
          AND (cd_versione::NUMERIC < -32768 OR cd_versione::NUMERIC > 32767)
    ) THEN
        RAISE EXCEPTION USING ERRCODE='22003',
            MESSAGE='CD_VERSIONE fuori dominio SMALLINT in DWH_ANAG_TIPOLOGIA',
            DETAIL='CD_VERSIONE deve rientrare nel dominio SMALLINT della Provincia.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_tipologia
        WHERE id_sorgente_provincia IS NOT NULL
          AND cd_versione IS NULL
    ) THEN
        RAISE EXCEPTION USING ERRCODE='23502',
            MESSAGE='CD_VERSIONE nullo in DWH_ANAG_TIPOLOGIA',
            DETAIL='CD_VERSIONE e necessario per contestualizzare la lookup Provincia.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_periodo
        WHERE ds_anno IS NOT NULL
        GROUP BY ds_anno HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_PERIODO non deterministica',
            DETAIL='Esistono piu record con lo stesso ds_anno.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_versione
        GROUP BY id_periodo_pubblicazione, cd_versione, id_anag_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_VERSIONE non deterministica',
            DETAIL='Esistono duplicati su periodo, versione e provincia.';
    END IF;

    SELECT COUNT(*) INTO v_codice_tipologia_assente
    FROM hcbi_ras.dwh_anag_tipologia AS src
    WHERE NULLIF(BTRIM(REGEXP_REPLACE(src.cd_tipologia::TEXT, '\.$', '')), '') IS NULL;
    IF v_codice_tipologia_assente > 0 THEN
        RAISE WARNING
            'DIM_TIPOLOGIA: % record con cd_tipologia NULL, vuoto o solo punto esclusi dal caricamento; il tappo tecnico id_anag_tipologia=0 resta disponibile per i flussi dipendenti.',
            v_codice_tipologia_assente;
    END IF;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_tipologia;
    CREATE TABLE hcbi_ras.tmp_dim_tipologia AS
    WITH lookup_base AS MATERIALIZED
    (
        SELECT
            src.id_anag_tipologia,
            src.ds_anno,
            src.cd_versione,
            REGEXP_REPLACE(src.cd_tipologia::TEXT, '\.$', '')::VARCHAR(60)
                AS cd_tipologia,
            src.ds_tipologia,
            src.id_sorgente_provincia,
            dp.id_anag_provincia AS id_anag_provincia_lookup,
            dper.id_periodo AS id_periodo_lookup
        FROM hcbi_ras.dwh_anag_tipologia AS src
        LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwh_pr
            ON dwh_pr.anno = src.ds_anno::INTEGER
           AND dwh_pr.cd_versione = src.cd_versione::SMALLINT
           AND dwh_pr.id_sorgente_provincia =
               src.id_sorgente_provincia
        LEFT JOIN hcbi_ras.dim_provincia AS dp
            ON dp.id_anag_provincia = dwh_pr.id_anag_provincia
           AND dp.anno = dwh_pr.anno
           AND dp.cd_versione = dwh_pr.cd_versione
        LEFT JOIN hcbi_ras.dim_periodo AS dper
            ON dper.ds_anno = src.ds_anno
        WHERE NULLIF(BTRIM(REGEXP_REPLACE(src.cd_tipologia::TEXT, '\.$', '')), '') IS NOT NULL
    )
    SELECT
        lb.id_anag_tipologia,
        lb.cd_tipologia,
        lb.ds_tipologia,
        COALESCE(lb.id_anag_provincia_lookup,(-1)::BIGINT)
            AS id_anag_provincia,
        COALESCE(lb.id_periodo_lookup,(-1)::INTEGER)
            AS id_periodo_pubblicazione,
        COALESCE(dv.id_anag_versione,(-1)::BIGINT)
            AS id_anag_versione,
        (lb.id_anag_provincia_lookup IS NULL)
            AS fl_lookup_provincia_ko,
        (lb.id_periodo_lookup IS NULL)
            AS fl_lookup_periodo_ko,
        (dv.id_anag_versione IS NULL)
            AS fl_lookup_versione_ko
    FROM lookup_base AS lb
    LEFT JOIN hcbi_ras.dim_versione AS dv
        ON dv.id_periodo_pubblicazione =
           COALESCE(lb.id_periodo_lookup,(-1)::INTEGER)
       AND dv.cd_versione = lb.cd_versione
       AND dv.id_anag_provincia =
           COALESCE(lb.id_anag_provincia_lookup,(-1)::BIGINT);

    CREATE UNIQUE INDEX tmp_dim_tipologia_pk
        ON hcbi_ras.tmp_dim_tipologia(id_anag_tipologia)
        NULLS NOT DISTINCT;

    CREATE UNIQUE INDEX tmp_dim_tipologia_bk
        ON hcbi_ras.tmp_dim_tipologia
        (cd_tipologia,id_periodo_pubblicazione,
         id_anag_versione,id_anag_provincia)
        NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_tipologia;

    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE fl_lookup_provincia_ko),
        COUNT(*) FILTER (WHERE fl_lookup_periodo_ko),
        COUNT(*) FILTER (WHERE fl_lookup_versione_ko)
    INTO
        v_selected,
        v_lookup_provincia_ko,
        v_lookup_periodo_ko,
        v_lookup_versione_ko
    FROM hcbi_ras.tmp_dim_tipologia;

    /* Le lookup mancate vengono valorizzate a -1 e rese visibili nel log. */
    v_rec_errors :=
        v_codice_tipologia_assente +
        v_lookup_provincia_ko +
        v_lookup_periodo_ko +
        v_lookup_versione_ko;

    IF v_lookup_provincia_ko > 0 THEN
        RAISE WARNING 'DIM_TIPOLOGIA: % lookup provincia non risolte; applicato id_anag_provincia=-1.',
            v_lookup_provincia_ko;
    END IF;
    IF v_lookup_periodo_ko > 0 THEN
        RAISE WARNING 'DIM_TIPOLOGIA: % lookup periodo non risolte; applicato id_periodo_pubblicazione=-1.',
            v_lookup_periodo_ko;
    END IF;
    IF v_lookup_versione_ko > 0 THEN
        RAISE WARNING 'DIM_TIPOLOGIA: % lookup versione non risolte; applicato id_anag_versione=-1.',
            v_lookup_versione_ko;
    END IF;

    UPDATE hcbi_ras.dim_tipologia AS d
       SET cd_tipologia = src.cd_tipologia,
           ds_tipologia = src.ds_tipologia,
           id_anag_provincia = src.id_anag_provincia,
           id_periodo_pubblicazione = src.id_periodo_pubblicazione,
           id_anag_versione = src.id_anag_versione,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_tipologia AS src
     WHERE d.id_anag_tipologia = src.id_anag_tipologia
       AND ROW(
            d.cd_tipologia,
            d.ds_tipologia,
            d.id_anag_provincia,
            d.id_periodo_pubblicazione,
            d.id_anag_versione
       ) IS DISTINCT FROM ROW(
            src.cd_tipologia,
            src.ds_tipologia,
            src.id_anag_provincia,
            src.id_periodo_pubblicazione,
            src.id_anag_versione
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_tipologia
    (
        id_anag_tipologia,
        cd_tipologia,
        ds_tipologia,
        id_anag_provincia,
        id_periodo_pubblicazione,
        id_anag_versione,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_anag_tipologia,
        src.cd_tipologia,
        src.ds_tipologia,
        src.id_anag_provincia,
        src.id_periodo_pubblicazione,
        src.id_anag_versione,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dim_tipologia AS src
    ON CONFLICT ON CONSTRAINT pk_dim_tipologia DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    SELECT COUNT(*)
    INTO v_matched
    FROM hcbi_ras.dim_tipologia AS d
    INNER JOIN hcbi_ras.tmp_dim_tipologia AS src
        ON src.id_anag_tipologia = d.id_anag_tipologia;

    IF v_selected <> v_matched THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE=FORMAT(
                'Riconciliazione DIM_TIPOLOGIA non valida: applicative=%s, matched=%s',
                v_selected,v_matched),
            DETAIL='Non tutte le chiavi applicative risultano presenti nella dimensione.';
    END IF;

    IF (v_selected + v_codice_tipologia_assente) <>
       (SELECT COUNT(*) FROM hcbi_ras.dwh_anag_tipologia) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Riconciliazione sorgente DIM_TIPOLOGIA non valida';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,(v_selected + v_codice_tipologia_assente),v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_tipologia;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;

    BEGIN
        DROP TABLE IF EXISTS hcbi_ras.tmp_dim_tipologia;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Errore cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
    END;

    v_log_error := LEFT(CONCAT_WS(E'\n',
        'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500),
        CASE WHEN NULLIF(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||LEFT(v_sql_detail,1000) END,
        CASE WHEN NULLIF(v_sql_hint,'') IS NOT NULL THEN 'HINT='||LEFT(v_sql_hint,500) END,
        CASE WHEN NULLIF(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||LEFT(v_sql_context,800) END),4000);

    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',v_log_error,
                clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
        END;
    END IF;

    RAISE WARNING
        'Errore in pkg_dim_tipologia_prc_main. SQLSTATE=%, errore=%',
        v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_tipologia_prc_main(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_tipologia_prc_main(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_dim_tipologia_prc_main(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING)
IS 'Carica DIM_TIPOLOGIA: esclude le righe con codice NULL, vuoto o solo punto; risolve la Provincia nel contesto anno/cd_versione usando DWH_ANAG_TIPOLOGIA.cd_versione; FK valorizzate ma non risolte poste a -1.';

/* =====================================================================
   PROCEDURA FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_tipologia_prc_finalize(
    IN p_id_chain_log BIGINT,
    IN p_id_chain BIGINT,
    IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING,
    OUT p_result INTEGER
)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name)
    INTO v_id_log;

    ANALYZE hcbi_ras.dim_tipologia;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',
        clock_timestamp()::TIMESTAMP,p_ds_step_name);

    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    v_log_error := LEFT(CONCAT_WS(E'\n',
        'SQLSTATE='||COALESCE(v_sqlstate,''),
        'MESSAGE='||LEFT(COALESCE(v_sqlerrm,''),1500),
        CASE WHEN NULLIF(v_sql_detail,'') IS NOT NULL THEN 'DETAIL='||LEFT(v_sql_detail,1000) END,
        CASE WHEN NULLIF(v_sql_hint,'') IS NOT NULL THEN 'HINT='||LEFT(v_sql_hint,500) END,
        CASE WHEN NULLIF(v_sql_context,'') IS NOT NULL THEN 'CONTEXT='||LEFT(v_sql_context,800) END),4000);
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',v_log_error,
                clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
        END;
    END IF;
    RAISE WARNING
        'Errore in pkg_dim_tipologia_prc_finalize. SQLSTATE=%, errore=%',
        v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_tipologia_prc_finalize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_tipologia_prc_finalize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_dim_tipologia_prc_finalize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING)
IS 'Finalizza DIM_TIPOLOGIA e aggiorna le statistiche.';

/* =====================================================================
   TEST POST-DEPLOYMENT
   ===================================================================== */

/* 1. Record tecnici obbligatori. */
-- SELECT id_anag_provincia FROM hcbi_ras.dim_provincia WHERE id_anag_provincia IN (0,-1);
-- SELECT id_periodo FROM hcbi_ras.dim_periodo WHERE id_periodo IN (0,-1);
-- SELECT id_anag_versione FROM hcbi_ras.dim_versione WHERE id_anag_versione IN (0,-1);
-- SELECT id_anag_tipologia,cd_tipologia,ds_tipologia
-- FROM hcbi_ras.dim_tipologia WHERE id_anag_tipologia IN (0,-1);

/* 1B. Codici NULL, vuoti o solo punto esclusi dal caricamento; tappo 0 disponibile per i flussi dipendenti. */
-- SELECT COUNT(*) AS record_esclusi_dal_caricamento
-- FROM hcbi_ras.dwh_anag_tipologia
-- WHERE NULLIF(BTRIM(REGEXP_REPLACE(cd_tipologia::TEXT, '\.$', '')), '') IS NULL;

/* 1C. Verifica normalizzazione punto finale. */
-- SELECT src.id_anag_tipologia,
--        src.cd_tipologia AS cd_tipologia_sorgente,
--        REGEXP_REPLACE(src.cd_tipologia::TEXT, '\.$', '') AS cd_tipologia_attesa,
--        d.cd_tipologia AS cd_tipologia_dimensione
-- FROM hcbi_ras.dwh_anag_tipologia src
-- LEFT JOIN hcbi_ras.dim_tipologia d
--   ON d.id_anag_tipologia=src.id_anag_tipologia
-- WHERE RIGHT(src.cd_tipologia::TEXT,1)='.';

/* 2. Lookup provincia non risolte. */
-- SELECT
--     src.id_anag_tipologia,
--     src.ds_anno,
--     src.cd_versione AS cd_versione_provincia,
--     src.id_sorgente_provincia,
--     dwh_pr.id_anag_provincia AS id_anag_provincia_dwh,
--     dwh_pr.cd_provincia,
--     CASE
--         WHEN dwh_pr.id_sorgente_provincia IS NULL
--             THEN 'ID_SORGENTE_PROVINCIA non trovato in DWH_ANAG_PROVINCIA nel contesto anno/cd_versione'
--         WHEN dp.id_anag_provincia IS NULL
--             THEN 'ID_ANAG_PROVINCIA DWH non trovato in DIM_PROVINCIA nel medesimo contesto anno/cd_versione'
--     END AS motivo_lookup_ko
-- FROM hcbi_ras.dwh_anag_tipologia src
-- LEFT JOIN hcbi_ras.dwh_anag_provincia dwh_pr
--   ON dwh_pr.anno=src.ds_anno::INTEGER
--  AND dwh_pr.cd_versione=src.cd_versione::SMALLINT
--  AND dwh_pr.id_sorgente_provincia=src.id_sorgente_provincia
-- LEFT JOIN hcbi_ras.dim_provincia dp
--   ON dp.id_anag_provincia=dwh_pr.id_anag_provincia
--  AND dp.anno=dwh_pr.anno
--  AND dp.cd_versione=dwh_pr.cd_versione
-- WHERE dp.id_anag_provincia IS NULL;

/* 3. Lookup periodo non risolte. */
-- SELECT src.id_anag_tipologia,src.ds_anno
-- FROM hcbi_ras.dwh_anag_tipologia src
-- LEFT JOIN hcbi_ras.dim_periodo p ON p.ds_anno=src.ds_anno
-- WHERE p.id_periodo IS NULL;

/* 4. Lookup versione non risolte. */
-- SELECT src.id_anag_tipologia,src.ds_anno,src.cd_versione,
--        src.id_sorgente_provincia
-- FROM hcbi_ras.dwh_anag_tipologia src
-- LEFT JOIN hcbi_ras.dwh_anag_provincia dwh_pr
--   ON dwh_pr.anno=src.ds_anno::INTEGER
--  AND dwh_pr.cd_versione=src.cd_versione::SMALLINT
--  AND dwh_pr.id_sorgente_provincia=src.id_sorgente_provincia
-- LEFT JOIN hcbi_ras.dim_provincia dp
--   ON dp.id_anag_provincia=dwh_pr.id_anag_provincia
--  AND dp.anno=dwh_pr.anno
--  AND dp.cd_versione=dwh_pr.cd_versione
-- LEFT JOIN hcbi_ras.dim_periodo pe
--   ON pe.ds_anno=src.ds_anno
-- LEFT JOIN hcbi_ras.dim_versione dv
--   ON dv.id_periodo_pubblicazione=COALESCE(pe.id_periodo,-1::integer)
--  AND dv.cd_versione=src.cd_versione
--  AND dv.id_anag_provincia=COALESCE(dp.id_anag_provincia,-1::bigint)
-- WHERE dv.id_anag_versione IS NULL;

/* 4B. Determinismo della chiave operazionale di DWH_ANAG_PROVINCIA. */
-- SELECT anno,cd_versione,id_sorgente_provincia,COUNT(*)
-- FROM hcbi_ras.dwh_anag_provincia
-- WHERE id_sorgente_provincia IS NOT NULL
-- GROUP BY anno,cd_versione,id_sorgente_provincia
-- HAVING COUNT(*) > 1;

/* 4C. Determinismo della business key contestualizzata di DIM_PROVINCIA. */
-- SELECT anno,cd_versione,cd_provincia,COUNT(*)
-- FROM hcbi_ras.dim_provincia
-- WHERE cd_provincia IS NOT NULL
-- GROUP BY anno,cd_versione,cd_provincia
-- HAVING COUNT(*) > 1;

/* 5. Orfani nella DIM. */
-- SELECT d.* FROM hcbi_ras.dim_tipologia d
-- LEFT JOIN hcbi_ras.dim_provincia p ON p.id_anag_provincia=d.id_anag_provincia
-- LEFT JOIN hcbi_ras.dim_periodo pe ON pe.id_periodo=d.id_periodo_pubblicazione
-- LEFT JOIN hcbi_ras.dim_versione v ON v.id_anag_versione=d.id_anag_versione
-- WHERE p.id_anag_provincia IS NULL
--    OR pe.id_periodo IS NULL
--    OR v.id_anag_versione IS NULL;

/* 6. Riconciliazione DWH-DIM. */
-- SELECT COUNT(*) AS chiavi_non_caricate
-- FROM hcbi_ras.dwh_anag_tipologia src
-- LEFT JOIN hcbi_ras.dim_tipologia d
--   ON d.id_anag_tipologia=src.id_anag_tipologia
-- WHERE d.id_anag_tipologia IS NULL;
