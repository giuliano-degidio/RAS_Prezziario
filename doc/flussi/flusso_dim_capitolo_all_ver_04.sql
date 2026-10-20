/* =====================================================================
   DIM_CAPITOLO - DDL E PROCEDURE DI CARICAMENTO
   Target: PostgreSQL 15.9 / 17
   Schema: hcbi_ras

   Sorgente:
       hcbi_ras.dwh_anag_capitolo

   Lookup dimensionali:
       1. Provincia
          dwh_anag_capitolo.ds_anno, addendum,
          id_sorgente_provincia
              = dwh_anag_provincia.anno, addendum,
                id_sorgente_provincia
          dwh_anag_provincia.anno, addendum, cd_provincia
              = dim_provincia.anno, addendum, cd_provincia

       2. Periodo
          dwh_anag_capitolo.ds_anno
              = dim_periodo.ds_anno

       3. Versione
          dim_periodo.id_periodo
              = dim_versione.id_periodo_pubblicazione
          dwh_anag_capitolo.cd_versione
              = dim_versione.cd_versione
          dim_provincia.id_anag_provincia
              = dim_versione.id_anag_provincia

   Destinazione:
       hcbi_ras.dim_capitolo

   Grain:
       una riga per ID_ANAG_CAPITOLO.

   Chiave primaria:
       id_anag_capitolo

   Business key dimensionale:
       cd_capitolo, id_periodo_pubblicazione,
       id_anag_versione, id_anag_provincia

   Normalizzazione CD_CAPITOLO:
       se il codice termina con il carattere '.', viene eliminato
       esclusivamente il punto finale. I punti in altre posizioni restano
       invariati. La normalizzazione avviene prima dei controlli di
       assenza e unicita della business key.

   Record tecnici:
       0  = codice capitolo assente dopo la normalizzazione: ND / NON DISPONIBILE
       -1 = codice valorizzato ma anagrafica assente: AA / ANAGRAFICA ASSENTE

   Strategia:
       SCD Type 1; update dei record variati; insert dei nuovi;
       nessuna cancellazione.

   Dipendenze:
       dim_provincia, dim_periodo e dim_versione devono essere caricate
       prima di dim_capitolo e devono contenere le righe 0 e -1.
       dwh_anag_capitolo deve esporre addendum.
       dwh_anag_provincia deve essere univoca su
       (anno, addendum, id_sorgente_provincia).
       dim_provincia deve essere univoca su
       (anno, addendum, cd_provincia).
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.dim_capitolo
(
    id_anag_capitolo          BIGINT NOT NULL,
    cd_capitolo               VARCHAR(60) NOT NULL,
    ds_capitolo               TEXT NOT NULL,
    id_anag_provincia         BIGINT NOT NULL,
    id_periodo_pubblicazione  INTEGER NOT NULL,
    id_anag_versione          BIGINT NOT NULL,
    dt_creation               TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by            VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update                 TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_update_by              VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,

    CONSTRAINT pk_dim_capitolo
        PRIMARY KEY (id_anag_capitolo),

    CONSTRAINT uq_dim_capitolo
        UNIQUE NULLS NOT DISTINCT
        (cd_capitolo, id_periodo_pubblicazione,
         id_anag_versione, id_anag_provincia),

    CONSTRAINT fk_dim_capitolo_provincia
        FOREIGN KEY (id_anag_provincia)
        REFERENCES hcbi_ras.dim_provincia (id_anag_provincia)
        ON UPDATE RESTRICT ON DELETE RESTRICT,

    CONSTRAINT fk_dim_capitolo_periodo
        FOREIGN KEY (id_periodo_pubblicazione)
        REFERENCES hcbi_ras.dim_periodo (id_periodo)
        ON UPDATE RESTRICT ON DELETE RESTRICT,

    CONSTRAINT fk_dim_capitolo_versione
        FOREIGN KEY (id_anag_versione)
        REFERENCES hcbi_ras.dim_versione (id_anag_versione)
        ON UPDATE RESTRICT ON DELETE RESTRICT
)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dim_capitolo OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.dim_capitolo FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.dim_capitolo TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.dim_capitolo TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dim_capitolo IS
    'Dimensione dei sottocapitoli alimentata da HCBI_RAS.DWH_ANAG_CAPITOLO.';
COMMENT ON COLUMN hcbi_ras.dim_capitolo.id_anag_capitolo IS
    'Chiave primaria mantenuta dalla chiave DWH sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_capitolo.cd_capitolo IS
    'Codice del capitolo normalizzato eliminando esclusivamente un eventuale punto finale.';
COMMENT ON COLUMN hcbi_ras.dim_capitolo.ds_capitolo IS
    'Descrizione del capitolo.';
COMMENT ON COLUMN hcbi_ras.dim_capitolo.id_anag_provincia IS
    'FK verso DIM_PROVINCIA risolta tramite anno, addendum e id_sorgente_provincia in DWH_ANAG_PROVINCIA, quindi tramite anno, addendum e cd_provincia.';
COMMENT ON COLUMN hcbi_ras.dim_capitolo.id_periodo_pubblicazione IS
    'FK verso DIM_PERIODO risolta tramite DS_ANNO.';
COMMENT ON COLUMN hcbi_ras.dim_capitolo.id_anag_versione IS
    'FK verso DIM_VERSIONE risolta per periodo, versione e provincia.';
COMMENT ON CONSTRAINT uq_dim_capitolo ON hcbi_ras.dim_capitolo IS
    'Business key: cd_capitolo, id_periodo_pubblicazione, id_anag_versione, id_anag_provincia.';

/* Record tecnici. Richiede 0 e -1 nelle dimensioni referenziate. */
INSERT INTO hcbi_ras.dim_capitolo
(
    id_anag_capitolo, cd_capitolo, ds_capitolo,
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
ON CONFLICT ON CONSTRAINT pk_dim_capitolo DO NOTHING;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_capitolo_prc_initialize(
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
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,
        p_ds_step_name)
    INTO v_id_log;

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
    RAISE WARNING 'Errore in pkg_dim_capitolo_prc_initialize. SQLSTATE=%, errore=%',
        v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_capitolo_prc_initialize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_capitolo_prc_initialize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_capitolo_prc_main(
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
    v_codice_capitolo_assente BIGINT := 0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT;
    v_sql_hint TEXT; v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,
        p_ds_step_name)
    INTO v_id_log;

    /* Prerequisiti tecnici 0 e -1. */
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia=0)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
            MESSAGE='Record tecnici 0 e/o -1 non presenti in DIM_PROVINCIA';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo=0)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
            MESSAGE='Record tecnici 0 e/o -1 non presenti in DIM_PERIODO';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione=0)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione=-1) THEN
        RAISE EXCEPTION USING ERRCODE='23503',
            MESSAGE='Record tecnici 0 e/o -1 non presenti in DIM_VERSIONE';
    END IF;

    /* Determinismo delle lookup. */
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_provincia
        WHERE id_sorgente_provincia IS NOT NULL
        GROUP BY anno, addendum, id_sorgente_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DWH_ANAG_PROVINCIA non deterministica',
            DETAIL='Esistono piu record con gli stessi anno, addendum e id_sorgente_provincia.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_provincia
        WHERE cd_provincia IS NOT NULL
        GROUP BY anno, addendum, cd_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_PROVINCIA non deterministica',
            DETAIL='Esistono piu record con gli stessi anno, addendum e cd_provincia.';
    END IF;

    /* Il riferimento e il contesto Provincia sono obbligatori nella sorgente. */
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_capitolo
        WHERE id_sorgente_provincia IS NULL
    ) THEN
        RAISE EXCEPTION USING ERRCODE='23502',
            MESSAGE='ID_SORGENTE_PROVINCIA nullo in DWH_ANAG_CAPITOLO',
            DETAIL='La Provincia e obbligatoria nel flusso DIM_CAPITOLO.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_capitolo
        WHERE id_sorgente_provincia IS NOT NULL
          AND ds_anno IS NULL
    ) THEN
        RAISE EXCEPTION USING ERRCODE='23502',
            MESSAGE='DS_ANNO nullo in DWH_ANAG_CAPITOLO',
            DETAIL='DS_ANNO e necessario per contestualizzare la lookup Provincia.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_capitolo
        WHERE id_sorgente_provincia IS NOT NULL
          AND addendum IS NULL
    ) THEN
        RAISE EXCEPTION USING ERRCODE='23502',
            MESSAGE='ADDENDUM nullo in DWH_ANAG_CAPITOLO',
            DETAIL='ADDENDUM e necessario per contestualizzare la lookup Provincia.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_periodo
        WHERE ds_anno IS NOT NULL
        GROUP BY ds_anno HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_PERIODO non deterministica';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_versione
        GROUP BY id_periodo_pubblicazione,cd_versione,id_anag_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_VERSIONE non deterministica';
    END IF;

    SELECT COUNT(*)
    INTO v_codice_capitolo_assente
    FROM hcbi_ras.dwh_anag_capitolo AS src
    WHERE NULLIF(
              BTRIM(REGEXP_REPLACE(src.cd_capitolo::TEXT, '\.$', '')),
              ''
          ) IS NULL;

    IF v_codice_capitolo_assente > 0 THEN
        RAISE WARNING
            'DIM_CAPITOLO: % record con cd_capitolo NULL, vuoto o solo punto esclusi dal caricamento; il tappo tecnico id_anag_capitolo=0 resta disponibile per i flussi dipendenti.',
            v_codice_capitolo_assente;
    END IF;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_capitolo;

    CREATE TABLE hcbi_ras.tmp_dim_capitolo AS
    WITH lookup_base AS MATERIALIZED
    (
        SELECT
            src.id_anag_capitolo,
            src.ds_anno,
            src.addendum,
            src.cd_versione,
            REGEXP_REPLACE(src.cd_capitolo::TEXT, '\.$', '')::VARCHAR(60)
                AS cd_capitolo,
            src.ds_capitolo,
            src.id_sorgente_provincia,
            dp.id_anag_provincia AS id_anag_provincia_lookup,
            dper.id_periodo AS id_periodo_lookup
        FROM hcbi_ras.dwh_anag_capitolo AS src
        LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwh_pr
            ON dwh_pr.anno=src.ds_anno::INTEGER
           AND dwh_pr.addendum=src.addendum::INTEGER
           AND dwh_pr.id_sorgente_provincia=src.id_sorgente_provincia
        LEFT JOIN hcbi_ras.dim_provincia AS dp
      ON dp.anno = dwh_pr.anno
     AND dp.addendum = dwh_pr.addendum
     AND dp.cd_provincia = dwh_pr.cd_provincia
        LEFT JOIN hcbi_ras.dim_periodo AS dper
            ON dper.ds_anno=src.ds_anno
        WHERE NULLIF(
                  BTRIM(REGEXP_REPLACE(src.cd_capitolo::TEXT, '\.$', '')),
                  ''
              ) IS NOT NULL
    )
    SELECT
        lb.id_anag_capitolo,
        lb.cd_capitolo,
        lb.ds_capitolo,
        COALESCE(lb.id_anag_provincia_lookup,(-1)::BIGINT) AS id_anag_provincia,
        COALESCE(lb.id_periodo_lookup,(-1)::INTEGER) AS id_periodo_pubblicazione,
        COALESCE(dv.id_anag_versione,(-1)::BIGINT) AS id_anag_versione,
        (lb.id_anag_provincia_lookup IS NULL) AS fl_lookup_provincia_ko,
        (lb.id_periodo_lookup IS NULL) AS fl_lookup_periodo_ko,
        (dv.id_anag_versione IS NULL) AS fl_lookup_versione_ko
    FROM lookup_base AS lb
    LEFT JOIN hcbi_ras.dim_versione AS dv
        ON dv.id_periodo_pubblicazione=COALESCE(lb.id_periodo_lookup,(-1)::INTEGER)
       AND dv.cd_versione=lb.cd_versione
       AND dv.id_anag_provincia=COALESCE(lb.id_anag_provincia_lookup,(-1)::BIGINT);

    CREATE UNIQUE INDEX tmp_dim_capitolo_pk
        ON hcbi_ras.tmp_dim_capitolo(id_anag_capitolo)
        NULLS NOT DISTINCT;
    CREATE UNIQUE INDEX tmp_dim_capitolo_bk
        ON hcbi_ras.tmp_dim_capitolo
        (cd_capitolo,id_periodo_pubblicazione,id_anag_versione,id_anag_provincia)
        NULLS NOT DISTINCT;
    ANALYZE hcbi_ras.tmp_dim_capitolo;

    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE fl_lookup_provincia_ko),
        COUNT(*) FILTER (WHERE fl_lookup_periodo_ko),
        COUNT(*) FILTER (WHERE fl_lookup_versione_ko)
    INTO
        v_selected,v_lookup_provincia_ko,
        v_lookup_periodo_ko,v_lookup_versione_ko
    FROM hcbi_ras.tmp_dim_capitolo;

    v_rec_errors := v_codice_capitolo_assente
                  + v_lookup_provincia_ko
                  + v_lookup_periodo_ko
                  + v_lookup_versione_ko;

    IF v_lookup_provincia_ko > 0 THEN
        RAISE WARNING 'DIM_CAPITOLO: % lookup provincia non risolte; applicato -1.',
            v_lookup_provincia_ko;
    END IF;
    IF v_lookup_periodo_ko > 0 THEN
        RAISE WARNING 'DIM_CAPITOLO: % lookup periodo non risolte; applicato -1.',
            v_lookup_periodo_ko;
    END IF;
    IF v_lookup_versione_ko > 0 THEN
        RAISE WARNING 'DIM_CAPITOLO: % lookup versione non risolte; applicato -1.',
            v_lookup_versione_ko;
    END IF;

    UPDATE hcbi_ras.dim_capitolo AS d
       SET cd_capitolo=src.cd_capitolo,
           ds_capitolo=src.ds_capitolo,
           id_anag_provincia=src.id_anag_provincia,
           id_periodo_pubblicazione=src.id_periodo_pubblicazione,
           id_anag_versione=src.id_anag_versione,
           dt_update=clock_timestamp(),
           tx_update_by=p_ds_step_name
      FROM hcbi_ras.tmp_dim_capitolo AS src
     WHERE d.id_anag_capitolo=src.id_anag_capitolo
       AND ROW(d.cd_capitolo,d.ds_capitolo,d.id_anag_provincia,
               d.id_periodo_pubblicazione,d.id_anag_versione)
           IS DISTINCT FROM
           ROW(src.cd_capitolo,src.ds_capitolo,src.id_anag_provincia,
               src.id_periodo_pubblicazione,src.id_anag_versione);
    GET DIAGNOSTICS v_updated=ROW_COUNT;

    INSERT INTO hcbi_ras.dim_capitolo
    (
        id_anag_capitolo,cd_capitolo,ds_capitolo,
        id_anag_provincia,id_periodo_pubblicazione,id_anag_versione,
        dt_creation,tx_creation_by,dt_update,tx_update_by
    )
    SELECT
        src.id_anag_capitolo,src.cd_capitolo,src.ds_capitolo,
        src.id_anag_provincia,src.id_periodo_pubblicazione,src.id_anag_versione,
        clock_timestamp(),p_ds_step_name,clock_timestamp(),p_ds_step_name
    FROM hcbi_ras.tmp_dim_capitolo AS src
    ON CONFLICT ON CONSTRAINT pk_dim_capitolo DO NOTHING;
    GET DIAGNOSTICS v_inserted=ROW_COUNT;

    SELECT COUNT(*) INTO v_matched
    FROM hcbi_ras.dim_capitolo AS d
    INNER JOIN hcbi_ras.tmp_dim_capitolo AS src
        ON src.id_anag_capitolo=d.id_anag_capitolo;

    IF v_selected <> v_matched THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE=FORMAT(
                'Riconciliazione DIM_CAPITOLO non valida: applicative=%s, matched=%s',
                v_selected,v_matched);
    END IF;

    IF (v_selected + v_codice_capitolo_assente) <>
       (SELECT COUNT(*) FROM hcbi_ras.dwh_anag_capitolo) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Riconciliazione sorgente DIM_CAPITOLO non valida';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,(v_selected+v_codice_capitolo_assente),
        v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_capitolo;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
        v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    BEGIN
        DROP TABLE IF EXISTS hcbi_ras.tmp_dim_capitolo;
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
    RAISE WARNING 'Errore in pkg_dim_capitolo_prc_main. SQLSTATE=%, errore=%',
        v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_capitolo_prc_main(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_capitolo_prc_main(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_dim_capitolo_prc_main(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING)
IS 'Carica DIM_CAPITOLO: esclude le righe con codice NULL, vuoto o solo punto; risolve la Provincia nel contesto anno/addendum; FK valorizzate ma non risolte poste a -1.';

CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_capitolo_prc_finalize(
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
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,
        p_ds_step_name)
    INTO v_id_log;
    ANALYZE hcbi_ras.dim_capitolo;
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
    RAISE WARNING 'Errore in pkg_dim_capitolo_prc_finalize. SQLSTATE=%, errore=%',
        v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_capitolo_prc_finalize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_capitolo_prc_finalize(
    BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;

/* =====================================================================
   TEST POST-DEPLOYMENT
   ===================================================================== */

/* 1. Record tecnici. Atteso: due righe per ogni dimensione. */
-- SELECT id_anag_provincia FROM hcbi_ras.dim_provincia WHERE id_anag_provincia IN (0,-1);
-- SELECT id_periodo FROM hcbi_ras.dim_periodo WHERE id_periodo IN (0,-1);
-- SELECT id_anag_versione FROM hcbi_ras.dim_versione WHERE id_anag_versione IN (0,-1);
-- SELECT id_anag_capitolo,cd_capitolo,ds_capitolo
-- FROM hcbi_ras.dim_capitolo WHERE id_anag_capitolo IN (0,-1);

/* 2. Codici capitolo assenti esclusi dal caricamento. Atteso: normalmente zero. */
-- SELECT COUNT(*) AS record_esclusi_dal_caricamento
-- FROM hcbi_ras.dwh_anag_capitolo
-- WHERE NULLIF(
--           BTRIM(REGEXP_REPLACE(cd_capitolo::TEXT, '\.$', '')),
--           ''
--       ) IS NULL;

/* 2B. Verifica normalizzazione del punto finale.
   Atteso: cd_capitolo_atteso non termina con '.'; eventuali punti interni
   sono conservati. */
-- SELECT
--     src.id_anag_capitolo,
--     src.cd_capitolo AS cd_capitolo_sorgente,
--     REGEXP_REPLACE(src.cd_capitolo::TEXT, '\.$', '')
--         AS cd_capitolo_atteso,
--     d.cd_capitolo AS cd_capitolo_dimensione
-- FROM hcbi_ras.dwh_anag_capitolo AS src
-- LEFT JOIN hcbi_ras.dim_capitolo AS d
--   ON d.id_anag_capitolo=src.id_anag_capitolo
-- WHERE RIGHT(src.cd_capitolo::TEXT,1)='.';

/* 3. Lookup provincia non risolte. Atteso: zero righe. */
-- SELECT src.id_anag_capitolo,src.ds_anno,src.addendum,
--        src.id_sorgente_provincia,dwh_pr.cd_provincia
-- FROM hcbi_ras.dwh_anag_capitolo src
-- LEFT JOIN hcbi_ras.dwh_anag_provincia dwh_pr
--   ON dwh_pr.anno=src.ds_anno::INTEGER
--  AND dwh_pr.addendum=src.addendum::INTEGER
--  AND dwh_pr.id_sorgente_provincia=src.id_sorgente_provincia
-- LEFT JOIN hcbi_ras.dim_provincia dp
--       ON dp.anno = dwh_pr.anno
--      AND dp.addendum = dwh_pr.addendum
--      AND dp.cd_provincia = dwh_pr.cd_provincia
-- WHERE dp.id_anag_provincia IS NULL;

/* 4. Lookup periodo non risolte. Atteso: zero righe. */
-- SELECT src.id_anag_capitolo,src.ds_anno
-- FROM hcbi_ras.dwh_anag_capitolo src
-- LEFT JOIN hcbi_ras.dim_periodo p ON p.ds_anno=src.ds_anno
-- WHERE p.id_periodo IS NULL;

/* 5. Lookup versione non risolte. Atteso: zero righe. */
-- SELECT src.id_anag_capitolo,src.ds_anno,src.addendum,
--        src.cd_versione,src.id_sorgente_provincia
-- FROM hcbi_ras.dwh_anag_capitolo src
-- LEFT JOIN hcbi_ras.dwh_anag_provincia dwh_pr
--   ON dwh_pr.anno=src.ds_anno::INTEGER
--  AND dwh_pr.addendum=src.addendum::INTEGER
--  AND dwh_pr.id_sorgente_provincia=src.id_sorgente_provincia
-- LEFT JOIN hcbi_ras.dim_provincia dp
--   ON dp.anno = dwh_pr.anno
--  AND dp.addendum = dwh_pr.addendum
--  AND dp.cd_provincia = dwh_pr.cd_provincia
-- LEFT JOIN hcbi_ras.dim_periodo pe ON pe.ds_anno=src.ds_anno
-- LEFT JOIN hcbi_ras.dim_versione dv
--   ON dv.id_periodo_pubblicazione=COALESCE(pe.id_periodo,-1::INTEGER)
--  AND dv.cd_versione=src.cd_versione
--  AND dv.id_anag_provincia=COALESCE(dp.id_anag_provincia,-1::BIGINT)
-- WHERE dv.id_anag_versione IS NULL;

/* 5B. Determinismo della chiave operazionale di DWH_ANAG_PROVINCIA. */
-- SELECT anno,addendum,id_sorgente_provincia,COUNT(*)
-- FROM hcbi_ras.dwh_anag_provincia
-- WHERE id_sorgente_provincia IS NOT NULL
-- GROUP BY anno,addendum,id_sorgente_provincia
-- HAVING COUNT(*) > 1;

/* 5C. Determinismo della business key contestualizzata di DIM_PROVINCIA. */
-- SELECT anno,addendum,cd_provincia,COUNT(*)
-- FROM hcbi_ras.dim_provincia
-- WHERE cd_provincia IS NOT NULL
-- GROUP BY anno,addendum,cd_provincia
-- HAVING COUNT(*) > 1;

/* 6. Orfani. Atteso: zero righe. */
-- SELECT d.* FROM hcbi_ras.dim_capitolo d
-- LEFT JOIN hcbi_ras.dim_provincia p ON p.id_anag_provincia=d.id_anag_provincia
-- LEFT JOIN hcbi_ras.dim_periodo pe ON pe.id_periodo=d.id_periodo_pubblicazione
-- LEFT JOIN hcbi_ras.dim_versione v ON v.id_anag_versione=d.id_anag_versione
-- WHERE p.id_anag_provincia IS NULL OR pe.id_periodo IS NULL OR v.id_anag_versione IS NULL;

/* 7. Riconciliazione applicativa. Atteso: zero. */
-- SELECT COUNT(*) AS chiavi_non_caricate
-- FROM hcbi_ras.dwh_anag_capitolo src
-- LEFT JOIN hcbi_ras.dim_capitolo d ON d.id_anag_capitolo=src.id_anag_capitolo
-- WHERE NULLIF(
--           BTRIM(REGEXP_REPLACE(src.cd_capitolo::TEXT, '\.$', '')),
--           ''
--       ) IS NOT NULL
--   AND d.id_anag_capitolo IS NULL;
