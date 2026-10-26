/* =====================================================================
   DIM_INFORMATORI - DDL E PROCEDURE DI CARICAMENTO - VERSIONE 05
   Target: PostgreSQL 15.9 / 17
   Schema: hcbi_ras

   Sorgente:
       hcbi_ras.dwh_anag_informatori

   Destinazione:
       hcbi_ras.dim_informatori

   Grain:
       una riga per ID_ANAG_INFORMATORE.

   Chiave primaria:
       id_anag_informatore

   Business key dimensionale:
       ds_ragione_sociale,
       id_periodo_pubblicazione,
       id_anag_versione,
       id_anag_provincia

   Lookup ATECO 2002:
       dwh_anag_informatori.cd_codice_ateco_2002
           = dim_ateco_2002.cd_ateco_2002
       Risultato: dim_ateco_2002.id_anag_ateco_2002.

   Lookup periodo:
       dwh_anag_informatori.ds_anno_pubblicazione
           = dim_periodo.ds_anno
       Risultato: dim_periodo.id_periodo
           -> id_periodo_pubblicazione.

   Lookup provincia:
       1. Il contesto versione della Provincia e' CD_VERSIONE:
          dwh_anag_informatori.ds_anno_pubblicazione, cd_versione,
          id_sorgente_provincia
              = dwh_anag_provincia.anno, cd_versione,
                id_sorgente_provincia
       2. La DIM_PROVINCIA viene risolta tramite la chiave DWH mantenuta
          nella dimensione:
          dwh_anag_provincia.id_anag_provincia
              = dim_provincia.id_anag_provincia
          con verifica ulteriore del medesimo contesto anno/cd_versione.
       Risultato: dim_provincia.id_anag_provincia.
       DIM_AREA_VASTA resta una dipendenza di DIM_PROVINCIA e non viene
       referenziata direttamente da DIM_INFORMATORI.

   Lookup versione:
       dim_versione.id_periodo_pubblicazione
           = periodo risolto per l'informatore
       dim_versione.cd_versione
           = dwh_anag_informatori.cd_versione
       dim_versione.id_anag_provincia
           = provincia risolta per l'informatore
       Risultato: dim_versione.id_anag_versione.

   Regole FK:
       - riferimento sorgente NULL/vuoto: chiave tecnica 0;
       - riferimento valorizzato ma lookup non risolta: chiave tecnica -1;
       - lookup risolta: chiave effettiva della dimensione.

   Strategia:
       SCD Type 1; UPDATE dei soli record variati; INSERT dei nuovi;
       nessuna cancellazione per assenza dalla sorgente.

   Prerequisiti:
       - record tecnici 0 e -1 in DIM_ATECO_2002, DIM_PERIODO,
         DIM_PROVINCIA e DIM_VERSIONE;
       - DIM_PERIODO.DS_ANNO univoco;
       - DWH_ANAG_INFORMATORI espone CD_VERSIONE, convertibile in SMALLINT
         quando ID_SORGENTE_PROVINCIA e' valorizzato e utilizzato direttamente
         come contesto della Provincia;
       - DWH_ANAG_PROVINCIA univoca su
         (ANNO, CD_VERSIONE, ID_SORGENTE_PROVINCIA);
       - DIM_PROVINCIA mantiene ID_ANAG_PROVINCIA della DWH sorgente ed e'
         univoca su (ANNO, CD_VERSIONE, CD_PROVINCIA);
       - DIM_ATECO_2002.CD_ATECO_2002 univoco;
       - business key di DIM_VERSIONE univoca;
       - nessuna esecuzione concorrente della PRC_MAIN, poiche' la tabella
         di lavoro usa un nome fisso.
   ===================================================================== */

/* =====================================================================
   TABELLA DIMENSIONALE
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dim_informatori
(
    id_anag_informatore BIGINT NOT NULL,
    id_sorgente_informatore INTEGER,
    ds_ragione_sociale VARCHAR(100) NOT NULL,
    cd_p_iva VARCHAR(100),
    id_anag_ateco_2002 BIGINT NOT NULL,
    ds_indirizzo_sede_legale VARCHAR(100),
    cd_cap_sede_legale VARCHAR(10),
    ds_citta_sede_legale VARCHAR(100),
    cd_provincia_sede_legale VARCHAR(100),
    ds_indirizzo_sede_operativa VARCHAR(100),
    cd_cap_sede_operativa VARCHAR(10),
    ds_citta_sede_operativa VARCHAR(100),
    cd_provincia_sede_operativa VARCHAR(100),
    ds_contatti TEXT,
    cd_stato INTEGER,
    ds_note TEXT,
    ds_stato_attivita VARCHAR(100),
    cd_codice_fiscale VARCHAR(100),
    id_periodo_pubblicazione INTEGER NOT NULL,
    dt_last_update TIMESTAMP WITHOUT TIME ZONE,
    ds_nazione VARCHAR(40),
    id_anag_versione BIGINT NOT NULL,
    id_anag_provincia BIGINT NOT NULL,
    fl_escludi_invio_mail_assoc_listino_completa INTEGER,
    dt_creation TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_update_by VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT pk_dim_informatori
        PRIMARY KEY (id_anag_informatore),
    CONSTRAINT uq_dim_informatori
        UNIQUE NULLS NOT DISTINCT
        (ds_ragione_sociale, id_periodo_pubblicazione,
         id_anag_versione, id_anag_provincia),
    CONSTRAINT fk_dim_informatori_ateco_2002
        FOREIGN KEY (id_anag_ateco_2002)
        REFERENCES hcbi_ras.dim_ateco_2002 (id_anag_ateco_2002)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_dim_informatori_periodo
        FOREIGN KEY (id_periodo_pubblicazione)
        REFERENCES hcbi_ras.dim_periodo (id_periodo)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_dim_informatori_versione
        FOREIGN KEY (id_anag_versione)
        REFERENCES hcbi_ras.dim_versione (id_anag_versione)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_dim_informatori_provincia
        FOREIGN KEY (id_anag_provincia)
        REFERENCES hcbi_ras.dim_provincia (id_anag_provincia)
        ON UPDATE RESTRICT ON DELETE RESTRICT
)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dim_informatori OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.dim_informatori FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.dim_informatori TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.dim_informatori TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dim_informatori IS
    'Dimensione degli informatori alimentata da HCBI_RAS.DWH_ANAG_INFORMATORI.';
COMMENT ON COLUMN hcbi_ras.dim_informatori.id_anag_informatore IS
    'Chiave primaria mantenuta dalla chiave DWH sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_informatori.id_anag_ateco_2002 IS
    'FK verso DIM_ATECO_2002: 0 se codice non valorizzato; -1 se valorizzato ma non risolto.';
COMMENT ON COLUMN hcbi_ras.dim_informatori.id_periodo_pubblicazione IS
    'FK verso DIM_PERIODO ottenuta da DS_ANNO_PUBBLICAZIONE.';
COMMENT ON COLUMN hcbi_ras.dim_informatori.id_anag_versione IS
    'FK verso DIM_VERSIONE risolta con periodo, codice versione e provincia.';
COMMENT ON COLUMN hcbi_ras.dim_informatori.id_anag_provincia IS
    'FK verso DIM_PROVINCIA: 0 se il riferimento sorgente non e valorizzato; altrimenti lookup in DWH_ANAG_PROVINCIA tramite anno, cd_versione di DWH_ANAG_INFORMATORI e id_sorgente_provincia; la DIM e raggiunta tramite id_anag_provincia nel medesimo contesto anno/cd_versione; -1 se non risolta.';
COMMENT ON CONSTRAINT uq_dim_informatori ON hcbi_ras.dim_informatori IS
    'Business key: ragione sociale, periodo, versione e provincia.';

/* =====================================================================
   RECORD TECNICI DIM_INFORMATORI
   ===================================================================== */
INSERT INTO hcbi_ras.dim_informatori
(
    id_anag_informatore,
    ds_ragione_sociale,
    id_anag_ateco_2002,
    id_periodo_pubblicazione,
    id_anag_versione,
    id_anag_provincia,
    dt_creation,
    tx_creation_by,
    dt_update,
    tx_update_by
)
VALUES
(
    0,
    'NON DISPONIBILE',
    0,
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
    'ANAGRAFICA ASSENTE',
    -1,
    -1,
    -1,
    -1,
    clock_timestamp(),
    CURRENT_USER,
    clock_timestamp(),
    CURRENT_USER
)
ON CONFLICT ON CONSTRAINT pk_dim_informatori DO NOTHING;

/* =====================================================================
   PROCEDURA INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_informatori_prc_initialize(
    IN p_id_chain_log BIGINT,
    IN p_id_chain BIGINT,
    IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING,
    OUT p_result INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT;
    v_selected BIGINT := 0;
    v_inserted BIGINT := 0;
    v_updated BIGINT := 0;
    v_deleted BIGINT := 0;
    v_rec_errors BIGINT := 0;
    v_sqlstate TEXT;
    v_sqlerrm TEXT;
    v_sql_detail TEXT;
    v_sql_hint TEXT;
    v_sql_context TEXT;
    v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::TIMESTAMP,
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    )
    INTO v_id_log;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    );

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
        v_log_error := LEFT(CONCAT_WS(E'\n',
            'SQLSTATE=' || COALESCE(v_sqlstate, ''),
            'MESSAGE=' || LEFT(COALESCE(v_sqlerrm, ''), 1500),
            CASE WHEN NULLIF(v_sql_detail, '') IS NOT NULL
                THEN 'DETAIL=' || LEFT(v_sql_detail, 1000) END,
            CASE WHEN NULLIF(v_sql_hint, '') IS NOT NULL
                THEN 'HINT=' || LEFT(v_sql_hint, 500) END,
            CASE WHEN NULLIF(v_sql_context, '') IS NOT NULL
                THEN 'CONTEXT=' || LEFT(v_sql_context, 800) END
        ), 4000);

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::TIMESTAMP,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore durante il logging: SQLSTATE=%, errore=%',
                        SQLSTATE, SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dim_informatori_prc_initialize. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_informatori_prc_initialize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_informatori_prc_initialize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_informatori_prc_initialize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) IS 'Inizializza il caricamento DIM_INFORMATORI e registra l esecuzione nel log.';

/* =====================================================================
   PROCEDURA MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_informatori_prc_main(
    IN p_id_chain_log BIGINT,
    IN p_id_chain BIGINT,
    IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING,
    OUT p_result INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
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
    v_lookup_ateco_ko BIGINT := 0;
    v_lookup_periodo_ko BIGINT := 0;
    v_lookup_provincia_ko BIGINT := 0;
    v_lookup_versione_ko BIGINT := 0;
    v_sqlstate TEXT;
    v_sqlerrm TEXT;
    v_sql_detail TEXT;
    v_sql_hint TEXT;
    v_sql_context TEXT;
    v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::TIMESTAMP,
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    )
    INTO v_id_log;

    /* Record tecnici richiesti dalle FK. */
    IF NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_ateco_2002
        WHERE id_anag_ateco_2002 = 0
    ) OR NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_ateco_2002
        WHERE id_anag_ateco_2002 = -1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'Record tecnici 0 e/o -1 non presenti in DIM_ATECO_2002';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo = 0
    ) OR NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo = -1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'Record tecnici 0 e/o -1 non presenti in DIM_PERIODO';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_provincia
        WHERE id_anag_provincia = 0
    ) OR NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_provincia
        WHERE id_anag_provincia = -1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'Record tecnici 0 e/o -1 non presenti in DIM_PROVINCIA';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_versione
        WHERE id_anag_versione = 0
    ) OR NOT EXISTS (
        SELECT 1 FROM hcbi_ras.dim_versione
        WHERE id_anag_versione = -1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'Record tecnici 0 e/o -1 non presenti in DIM_VERSIONE';
    END IF;

    /* Le lookup devono essere deterministiche. */
    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_ateco_2002
        WHERE cd_ateco_2002 IS NOT NULL
        GROUP BY cd_ateco_2002
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Lookup DIM_ATECO_2002 non deterministica',
            DETAIL = 'Esistono piu record con lo stesso cd_ateco_2002.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_periodo
        WHERE ds_anno IS NOT NULL
        GROUP BY ds_anno
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Lookup DIM_PERIODO non deterministica',
            DETAIL = 'Esistono piu record con lo stesso ds_anno.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dwh_anag_provincia
        WHERE id_sorgente_provincia IS NOT NULL
        GROUP BY anno, cd_versione, id_sorgente_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Lookup DWH_ANAG_PROVINCIA non deterministica',
            DETAIL = 'Esistono piu record con gli stessi anno, cd_versione e id_sorgente_provincia.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_provincia
        WHERE cd_provincia IS NOT NULL
        GROUP BY anno, cd_versione, cd_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Lookup DIM_PROVINCIA non deterministica',
            DETAIL = 'Esistono piu record con gli stessi anno, cd_versione e cd_provincia.';
    END IF;

    /* Il contesto e obbligatorio solo quando il riferimento Provincia e valorizzato. */
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_informatori
        WHERE id_sorgente_provincia IS NOT NULL
          AND ds_anno_pubblicazione IS NULL
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE='23502',
            MESSAGE='DS_ANNO_PUBBLICAZIONE nullo in DWH_ANAG_INFORMATORI',
            DETAIL='DS_ANNO_PUBBLICAZIONE e necessario per contestualizzare la lookup Provincia.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_informatori
        WHERE id_sorgente_provincia IS NOT NULL
          AND cd_versione IS NOT NULL
          AND (cd_versione::NUMERIC < -32768 OR cd_versione::NUMERIC > 32767)
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE='22003',
            MESSAGE='CD_VERSIONE fuori dominio SMALLINT in DWH_ANAG_INFORMATORI',
            DETAIL='CD_VERSIONE deve rientrare nel dominio SMALLINT della Provincia.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_informatori
        WHERE id_sorgente_provincia IS NOT NULL
          AND cd_versione IS NULL
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE='23502',
            MESSAGE='CD_VERSIONE nullo in DWH_ANAG_INFORMATORI',
            DETAIL='CD_VERSIONE e necessario per contestualizzare la lookup Provincia.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_versione
        GROUP BY id_periodo_pubblicazione, cd_versione, id_anag_provincia
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Lookup DIM_VERSIONE non deterministica',
            DETAIL = 'Esistono duplicati sulla business key della versione.';
    END IF;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_informatori;

    CREATE TABLE hcbi_ras.tmp_dim_informatori AS
    WITH lookup_base AS MATERIALIZED
    (
        SELECT
            src.id_anag_informatore,
            src.id_sorgente_informatore,
            src.ds_ragione_sociale,
            src.cd_p_iva,
            CASE
                WHEN NULLIF(BTRIM(src.cd_codice_ateco_2002::TEXT), '') IS NULL
                    THEN 0::BIGINT
                WHEN dat.id_anag_ateco_2002 IS NULL
                    THEN (-1)::BIGINT
                ELSE dat.id_anag_ateco_2002
            END AS id_anag_ateco_2002,
            src.ds_indirizzo_sede_legale,
            src.cd_cap_sede_legale,
            src.ds_citta_sede_legale,
            src.cd_provincia_sede_legale,
            src.ds_indirizzo_sede_operativa,
            src.cd_cap_sede_operativa,
            src.ds_citta_sede_operativa,
            src.cd_provincia_sede_operativa,
            src.ds_contatti,
            src.cd_stato,
            src.ds_note,
            src.ds_stato_attivita,
            src.cd_codice_fiscale,
            CASE
                WHEN NULLIF(BTRIM(src.ds_anno_pubblicazione::TEXT), '') IS NULL
                    THEN 0::INTEGER
                WHEN dpe.id_periodo IS NULL
                    THEN (-1)::INTEGER
                ELSE dpe.id_periodo
            END AS id_periodo_pubblicazione,
            src.dt_last_update,
            src.ds_nazione,
            src.cd_versione,
            CASE
                WHEN src.id_sorgente_provincia IS NULL
                    THEN 0::BIGINT
                WHEN dpr.id_anag_provincia IS NULL
                    THEN (-1)::BIGINT
                ELSE dpr.id_anag_provincia
            END AS id_anag_provincia,
            src.fl_escludi_invio_mail_assoc_listino_completa,
            (
                NULLIF(BTRIM(src.cd_codice_ateco_2002::TEXT), '') IS NOT NULL
                AND dat.id_anag_ateco_2002 IS NULL
            ) AS fl_lookup_ateco_ko,
            (
                NULLIF(BTRIM(src.ds_anno_pubblicazione::TEXT), '') IS NOT NULL
                AND dpe.id_periodo IS NULL
            ) AS fl_lookup_periodo_ko,
            (
                src.id_sorgente_provincia IS NOT NULL
                AND dpr.id_anag_provincia IS NULL
            ) AS fl_lookup_provincia_ko
        FROM hcbi_ras.dwh_anag_informatori AS src
        LEFT JOIN hcbi_ras.dim_ateco_2002 AS dat
            ON dat.cd_ateco_2002 =
               NULLIF(BTRIM(src.cd_codice_ateco_2002::TEXT), '')
        LEFT JOIN hcbi_ras.dim_periodo AS dpe
            ON dpe.ds_anno = src.ds_anno_pubblicazione
        LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwh_pr
            ON dwh_pr.anno = src.ds_anno_pubblicazione::INTEGER
           AND dwh_pr.cd_versione = src.cd_versione::SMALLINT
           AND dwh_pr.id_sorgente_provincia =
               src.id_sorgente_provincia
        LEFT JOIN hcbi_ras.dim_provincia AS dpr
            ON dpr.id_anag_provincia = dwh_pr.id_anag_provincia
           AND dpr.anno = dwh_pr.anno
           AND dpr.cd_versione = dwh_pr.cd_versione
    )
    SELECT
        base.id_anag_informatore,
        base.id_sorgente_informatore,
        base.ds_ragione_sociale,
        base.cd_p_iva,
        base.id_anag_ateco_2002,
        base.ds_indirizzo_sede_legale,
        base.cd_cap_sede_legale,
        base.ds_citta_sede_legale,
        base.cd_provincia_sede_legale,
        base.ds_indirizzo_sede_operativa,
        base.cd_cap_sede_operativa,
        base.ds_citta_sede_operativa,
        base.cd_provincia_sede_operativa,
        base.ds_contatti,
        base.cd_stato,
        base.ds_note,
        base.ds_stato_attivita,
        base.cd_codice_fiscale,
        base.id_periodo_pubblicazione,
        base.dt_last_update,
        base.ds_nazione,
        CASE
            WHEN base.cd_versione IS NULL
                THEN 0::BIGINT
            WHEN dve.id_anag_versione IS NULL
                THEN (-1)::BIGINT
            ELSE dve.id_anag_versione
        END AS id_anag_versione,
        base.id_anag_provincia,
        base.fl_escludi_invio_mail_assoc_listino_completa,
        base.fl_lookup_ateco_ko,
        base.fl_lookup_periodo_ko,
        base.fl_lookup_provincia_ko,
        (
            base.cd_versione IS NOT NULL
            AND dve.id_anag_versione IS NULL
        ) AS fl_lookup_versione_ko
    FROM lookup_base AS base
    LEFT JOIN hcbi_ras.dim_versione AS dve
        ON dve.id_periodo_pubblicazione =
           base.id_periodo_pubblicazione
       AND dve.cd_versione = base.cd_versione
       AND dve.id_anag_provincia = base.id_anag_provincia;

    /* Verifiche preventive della PK e della business key trasformata. */
    CREATE UNIQUE INDEX tmp_dim_informatori_pk
        ON hcbi_ras.tmp_dim_informatori (id_anag_informatore)
        NULLS NOT DISTINCT;

    CREATE UNIQUE INDEX tmp_dim_informatori_bk
        ON hcbi_ras.tmp_dim_informatori
        (
            ds_ragione_sociale,
            id_periodo_pubblicazione,
            id_anag_versione,
            id_anag_provincia
        )
        NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_informatori;

    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE fl_lookup_ateco_ko),
        COUNT(*) FILTER (WHERE fl_lookup_periodo_ko),
        COUNT(*) FILTER (WHERE fl_lookup_provincia_ko),
        COUNT(*) FILTER (WHERE fl_lookup_versione_ko)
    INTO
        v_selected,
        v_lookup_ateco_ko,
        v_lookup_periodo_ko,
        v_lookup_provincia_ko,
        v_lookup_versione_ko
    FROM hcbi_ras.tmp_dim_informatori;

    v_rec_errors :=
        v_lookup_ateco_ko
        + v_lookup_periodo_ko
        + v_lookup_provincia_ko
        + v_lookup_versione_ko;

    IF v_lookup_ateco_ko > 0 THEN
        RAISE WARNING
            'DIM_INFORMATORI: % lookup ATECO 2002 non risolte; applicato id_anag_ateco_2002=-1.',
            v_lookup_ateco_ko;
    END IF;

    IF v_lookup_periodo_ko > 0 THEN
        RAISE WARNING
            'DIM_INFORMATORI: % lookup periodo non risolte; applicato id_periodo_pubblicazione=-1.',
            v_lookup_periodo_ko;
    END IF;

    IF v_lookup_provincia_ko > 0 THEN
        RAISE WARNING
            'DIM_INFORMATORI: % lookup provincia non risolte; applicato id_anag_provincia=-1.',
            v_lookup_provincia_ko;
    END IF;

    IF v_lookup_versione_ko > 0 THEN
        RAISE WARNING
            'DIM_INFORMATORI: % lookup versione non risolte; applicato id_anag_versione=-1.',
            v_lookup_versione_ko;
    END IF;

    UPDATE hcbi_ras.dim_informatori AS d
       SET id_sorgente_informatore = src.id_sorgente_informatore,
           ds_ragione_sociale = src.ds_ragione_sociale,
           cd_p_iva = src.cd_p_iva,
           id_anag_ateco_2002 = src.id_anag_ateco_2002,
           ds_indirizzo_sede_legale = src.ds_indirizzo_sede_legale,
           cd_cap_sede_legale = src.cd_cap_sede_legale,
           ds_citta_sede_legale = src.ds_citta_sede_legale,
           cd_provincia_sede_legale = src.cd_provincia_sede_legale,
           ds_indirizzo_sede_operativa = src.ds_indirizzo_sede_operativa,
           cd_cap_sede_operativa = src.cd_cap_sede_operativa,
           ds_citta_sede_operativa = src.ds_citta_sede_operativa,
           cd_provincia_sede_operativa = src.cd_provincia_sede_operativa,
           ds_contatti = src.ds_contatti,
           cd_stato = src.cd_stato,
           ds_note = src.ds_note,
           ds_stato_attivita = src.ds_stato_attivita,
           cd_codice_fiscale = src.cd_codice_fiscale,
           id_periodo_pubblicazione = src.id_periodo_pubblicazione,
           dt_last_update = src.dt_last_update,
           ds_nazione = src.ds_nazione,
           id_anag_versione = src.id_anag_versione,
           id_anag_provincia = src.id_anag_provincia,
           fl_escludi_invio_mail_assoc_listino_completa =
               src.fl_escludi_invio_mail_assoc_listino_completa,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_informatori AS src
     WHERE d.id_anag_informatore = src.id_anag_informatore
       AND ROW(
            d.id_sorgente_informatore,
            d.ds_ragione_sociale,
            d.cd_p_iva,
            d.id_anag_ateco_2002,
            d.ds_indirizzo_sede_legale,
            d.cd_cap_sede_legale,
            d.ds_citta_sede_legale,
            d.cd_provincia_sede_legale,
            d.ds_indirizzo_sede_operativa,
            d.cd_cap_sede_operativa,
            d.ds_citta_sede_operativa,
            d.cd_provincia_sede_operativa,
            d.ds_contatti,
            d.cd_stato,
            d.ds_note,
            d.ds_stato_attivita,
            d.cd_codice_fiscale,
            d.id_periodo_pubblicazione,
            d.dt_last_update,
            d.ds_nazione,
            d.id_anag_versione,
            d.id_anag_provincia,
            d.fl_escludi_invio_mail_assoc_listino_completa
       ) IS DISTINCT FROM ROW(
            src.id_sorgente_informatore,
            src.ds_ragione_sociale,
            src.cd_p_iva,
            src.id_anag_ateco_2002,
            src.ds_indirizzo_sede_legale,
            src.cd_cap_sede_legale,
            src.ds_citta_sede_legale,
            src.cd_provincia_sede_legale,
            src.ds_indirizzo_sede_operativa,
            src.cd_cap_sede_operativa,
            src.ds_citta_sede_operativa,
            src.cd_provincia_sede_operativa,
            src.ds_contatti,
            src.cd_stato,
            src.ds_note,
            src.ds_stato_attivita,
            src.cd_codice_fiscale,
            src.id_periodo_pubblicazione,
            src.dt_last_update,
            src.ds_nazione,
            src.id_anag_versione,
            src.id_anag_provincia,
            src.fl_escludi_invio_mail_assoc_listino_completa
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_informatori
    (
        id_anag_informatore,
        id_sorgente_informatore,
        ds_ragione_sociale,
        cd_p_iva,
        id_anag_ateco_2002,
        ds_indirizzo_sede_legale,
        cd_cap_sede_legale,
        ds_citta_sede_legale,
        cd_provincia_sede_legale,
        ds_indirizzo_sede_operativa,
        cd_cap_sede_operativa,
        ds_citta_sede_operativa,
        cd_provincia_sede_operativa,
        ds_contatti,
        cd_stato,
        ds_note,
        ds_stato_attivita,
        cd_codice_fiscale,
        id_periodo_pubblicazione,
        dt_last_update,
        ds_nazione,
        id_anag_versione,
        id_anag_provincia,
        fl_escludi_invio_mail_assoc_listino_completa,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_anag_informatore,
        src.id_sorgente_informatore,
        src.ds_ragione_sociale,
        src.cd_p_iva,
        src.id_anag_ateco_2002,
        src.ds_indirizzo_sede_legale,
        src.cd_cap_sede_legale,
        src.ds_citta_sede_legale,
        src.cd_provincia_sede_legale,
        src.ds_indirizzo_sede_operativa,
        src.cd_cap_sede_operativa,
        src.ds_citta_sede_operativa,
        src.cd_provincia_sede_operativa,
        src.ds_contatti,
        src.cd_stato,
        src.ds_note,
        src.ds_stato_attivita,
        src.cd_codice_fiscale,
        src.id_periodo_pubblicazione,
        src.dt_last_update,
        src.ds_nazione,
        src.id_anag_versione,
        src.id_anag_provincia,
        src.fl_escludi_invio_mail_assoc_listino_completa,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dim_informatori AS src
    ON CONFLICT ON CONSTRAINT pk_dim_informatori DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    SELECT COUNT(*)
    INTO v_matched
    FROM hcbi_ras.dim_informatori AS d
    INNER JOIN hcbi_ras.tmp_dim_informatori AS src
        ON src.id_anag_informatore = d.id_anag_informatore;

    IF v_selected <> v_matched THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = FORMAT(
                'Riconciliazione DIM_INFORMATORI non valida: selected=%s, matched=%s',
                v_selected,
                v_matched
            ),
            DETAIL = 'Non tutte le chiavi DWH risultano presenti nella dimensione.';
    END IF;

    IF v_selected <> (
        SELECT COUNT(*) FROM hcbi_ras.dwh_anag_informatori
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Riconciliazione sorgente DIM_INFORMATORI non valida';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_informatori;
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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dim_informatori;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante il cleanup: SQLSTATE=%, errore=%',
                    SQLSTATE, SQLERRM;
        END;

        v_log_error := LEFT(CONCAT_WS(E'\n',
            'SQLSTATE=' || COALESCE(v_sqlstate, ''),
            'MESSAGE=' || LEFT(COALESCE(v_sqlerrm, ''), 1500),
            CASE WHEN NULLIF(v_sql_detail, '') IS NOT NULL
                THEN 'DETAIL=' || LEFT(v_sql_detail, 1000) END,
            CASE WHEN NULLIF(v_sql_hint, '') IS NOT NULL
                THEN 'HINT=' || LEFT(v_sql_hint, 500) END,
            CASE WHEN NULLIF(v_sql_context, '') IS NOT NULL
                THEN 'CONTEXT=' || LEFT(v_sql_context, 800) END
        ), 4000);

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::TIMESTAMP,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore durante il logging: SQLSTATE=%, errore=%',
                        SQLSTATE, SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dim_informatori_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_informatori_prc_main(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_informatori_prc_main(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_informatori_prc_main(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) IS 'Carica DIM_INFORMATORI con lookup ATECO, periodo, Provincia nel contesto anno/cd_versione di DWH_ANAG_INFORMATORI e versione; raggiunge DIM_PROVINCIA tramite id_anag_provincia, applica tappi 0/-1 e SCD Type 1 senza delete.';

/* =====================================================================
   PROCEDURA FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_informatori_prc_finalize(
    IN p_id_chain_log BIGINT,
    IN p_id_chain BIGINT,
    IN p_id_step BIGINT,
    IN p_ds_step_name CHARACTER VARYING,
    OUT p_result INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log BIGINT;
    v_selected BIGINT := 0;
    v_inserted BIGINT := 0;
    v_updated BIGINT := 0;
    v_deleted BIGINT := 0;
    v_rec_errors BIGINT := 0;
    v_sqlstate TEXT;
    v_sqlerrm TEXT;
    v_sql_detail TEXT;
    v_sql_hint TEXT;
    v_sql_context TEXT;
    v_log_error TEXT;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::TIMESTAMP,
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    )
    INTO v_id_log;

    ANALYZE hcbi_ras.dim_informatori;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::TIMESTAMP,
        p_ds_step_name
    );

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
        v_log_error := LEFT(CONCAT_WS(E'\n',
            'SQLSTATE=' || COALESCE(v_sqlstate, ''),
            'MESSAGE=' || LEFT(COALESCE(v_sqlerrm, ''), 1500),
            CASE WHEN NULLIF(v_sql_detail, '') IS NOT NULL
                THEN 'DETAIL=' || LEFT(v_sql_detail, 1000) END,
            CASE WHEN NULLIF(v_sql_hint, '') IS NOT NULL
                THEN 'HINT=' || LEFT(v_sql_hint, 500) END,
            CASE WHEN NULLIF(v_sql_context, '') IS NOT NULL
                THEN 'CONTEXT=' || LEFT(v_sql_context, 800) END
        ), 4000);

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    v_log_error,
                    clock_timestamp()::TIMESTAMP,
                    p_ds_step_name
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Errore durante il logging: SQLSTATE=%, errore=%',
                        SQLSTATE, SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dim_informatori_prc_finalize. SQLSTATE=%, errore=%',
            v_sqlstate, v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_informatori_prc_finalize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_informatori_prc_finalize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_informatori_prc_finalize(
    BIGINT, BIGINT, BIGINT, CHARACTER VARYING
) IS 'Finalizza il caricamento DIM_INFORMATORI e aggiorna le statistiche.';

/* =====================================================================
   TEST POST-DEPLOYMENT
   ===================================================================== */

/* T01 - Struttura della dimensione. */
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_schema = 'hcbi_ras'
--   AND table_name = 'dim_informatori'
-- ORDER BY ordinal_position;

/* T02 - Record tecnici DIM_INFORMATORI. Atteso: due righe. */
-- SELECT id_anag_informatore, ds_ragione_sociale,
--        id_anag_ateco_2002, id_periodo_pubblicazione,
--        id_anag_versione, id_anag_provincia
-- FROM hcbi_ras.dim_informatori
-- WHERE id_anag_informatore IN (0, -1)
-- ORDER BY id_anag_informatore;

/* T03 - Record tecnici delle dimensioni referenziate. */
-- SELECT id_anag_ateco_2002 FROM hcbi_ras.dim_ateco_2002
-- WHERE id_anag_ateco_2002 IN (0, -1);
-- SELECT id_periodo FROM hcbi_ras.dim_periodo
-- WHERE id_periodo IN (0, -1);
-- SELECT id_anag_versione FROM hcbi_ras.dim_versione
-- WHERE id_anag_versione IN (0, -1);
-- SELECT id_anag_provincia FROM hcbi_ras.dim_provincia
-- WHERE id_anag_provincia IN (0, -1);

/* T04 - Duplicati PK. Atteso: zero righe. */
-- SELECT id_anag_informatore, COUNT(*)
-- FROM hcbi_ras.dim_informatori
-- GROUP BY id_anag_informatore
-- HAVING COUNT(*) > 1;

/* T05 - Duplicati business key. Atteso: zero righe. */
-- SELECT ds_ragione_sociale, id_periodo_pubblicazione,
--        id_anag_versione, id_anag_provincia, COUNT(*)
-- FROM hcbi_ras.dim_informatori
-- GROUP BY ds_ragione_sociale, id_periodo_pubblicazione,
--          id_anag_versione, id_anag_provincia
-- HAVING COUNT(*) > 1;

/* T06 - Orfani rispetto alle dimensioni referenziate. Atteso: zero. */
-- SELECT COUNT(*) AS record_orfani
-- FROM hcbi_ras.dim_informatori AS d
-- LEFT JOIN hcbi_ras.dim_ateco_2002 AS a
--   ON a.id_anag_ateco_2002 = d.id_anag_ateco_2002
-- LEFT JOIN hcbi_ras.dim_periodo AS p
--   ON p.id_periodo = d.id_periodo_pubblicazione
-- LEFT JOIN hcbi_ras.dim_versione AS v
--   ON v.id_anag_versione = d.id_anag_versione
-- LEFT JOIN hcbi_ras.dim_provincia AS pr
--   ON pr.id_anag_provincia = d.id_anag_provincia
-- WHERE a.id_anag_ateco_2002 IS NULL
--    OR p.id_periodo IS NULL
--    OR v.id_anag_versione IS NULL
--    OR pr.id_anag_provincia IS NULL;

/* T07 - Chiavi DWH non caricate. Atteso: zero. */
-- SELECT COUNT(*) AS chiavi_non_caricate
-- FROM hcbi_ras.dwh_anag_informatori AS src
-- LEFT JOIN hcbi_ras.dim_informatori AS d
--   ON d.id_anag_informatore = src.id_anag_informatore
-- WHERE d.id_anag_informatore IS NULL;

/* T08 - Lookup ATECO non risolte. */
-- SELECT src.id_anag_informatore, src.cd_codice_ateco_2002
-- FROM hcbi_ras.dwh_anag_informatori AS src
-- LEFT JOIN hcbi_ras.dim_ateco_2002 AS a
--   ON a.cd_ateco_2002 = NULLIF(BTRIM(src.cd_codice_ateco_2002::TEXT), '')
-- WHERE NULLIF(BTRIM(src.cd_codice_ateco_2002::TEXT), '') IS NOT NULL
--   AND a.id_anag_ateco_2002 IS NULL;

/* T09 - Lookup periodo non risolte. */
-- SELECT src.id_anag_informatore, src.ds_anno_pubblicazione
-- FROM hcbi_ras.dwh_anag_informatori AS src
-- LEFT JOIN hcbi_ras.dim_periodo AS p
--   ON p.ds_anno = src.ds_anno_pubblicazione
-- WHERE p.id_periodo IS NULL;

/* T10 - Lookup provincia non risolte. */
-- SELECT src.id_anag_informatore, src.ds_anno_pubblicazione,
--        src.cd_versione AS cd_versione_provincia,
--        src.id_sorgente_provincia,
--        dwh_pr.id_anag_provincia AS id_anag_provincia_dwh,
--        dwh_pr.cd_provincia
-- FROM hcbi_ras.dwh_anag_informatori AS src
-- LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwh_pr
--   ON dwh_pr.anno = src.ds_anno_pubblicazione::INTEGER
--  AND dwh_pr.cd_versione = src.cd_versione::SMALLINT
--  AND dwh_pr.id_sorgente_provincia = src.id_sorgente_provincia
-- LEFT JOIN hcbi_ras.dim_provincia AS pr
--   ON pr.id_anag_provincia = dwh_pr.id_anag_provincia
--  AND pr.anno = dwh_pr.anno
--  AND pr.cd_versione = dwh_pr.cd_versione
-- WHERE src.id_sorgente_provincia IS NOT NULL
--   AND pr.id_anag_provincia IS NULL;

/* T11 - Lookup versione non risolte. */
-- WITH base AS (
--   SELECT src.id_anag_informatore, src.cd_versione,
--          COALESCE(p.id_periodo, -1) AS id_periodo_pubblicazione,
--          COALESCE(pr.id_anag_provincia, -1) AS id_anag_provincia
--   FROM hcbi_ras.dwh_anag_informatori AS src
--   LEFT JOIN hcbi_ras.dim_periodo AS p
--     ON p.ds_anno = src.ds_anno_pubblicazione
--   LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwh_pr
--     ON dwh_pr.anno = src.ds_anno_pubblicazione::INTEGER
--    AND dwh_pr.cd_versione = src.cd_versione::SMALLINT
--    AND dwh_pr.id_sorgente_provincia = src.id_sorgente_provincia
--   LEFT JOIN hcbi_ras.dim_provincia AS pr
--     ON pr.id_anag_provincia = dwh_pr.id_anag_provincia
--    AND pr.anno = dwh_pr.anno
--    AND pr.cd_versione = dwh_pr.cd_versione
-- )
-- SELECT base.*
-- FROM base
-- LEFT JOIN hcbi_ras.dim_versione AS v
--   ON v.id_periodo_pubblicazione = base.id_periodo_pubblicazione
--  AND v.cd_versione = base.cd_versione
--  AND v.id_anag_provincia = base.id_anag_provincia
-- WHERE base.cd_versione IS NOT NULL
--   AND v.id_anag_versione IS NULL;

/* T11B - Determinismo chiave operazionale DWH_ANAG_PROVINCIA. Atteso: zero righe. */
-- SELECT anno, cd_versione, id_sorgente_provincia, COUNT(*)
-- FROM hcbi_ras.dwh_anag_provincia
-- WHERE id_sorgente_provincia IS NOT NULL
-- GROUP BY anno, cd_versione, id_sorgente_provincia
-- HAVING COUNT(*) > 1;

/* T11C - Determinismo business key contestualizzata DIM_PROVINCIA. Atteso: zero righe. */
-- SELECT anno, cd_versione, cd_provincia, COUNT(*)
-- FROM hcbi_ras.dim_provincia
-- WHERE cd_provincia IS NOT NULL
-- GROUP BY anno, cd_versione, cd_provincia
-- HAVING COUNT(*) > 1;

/* T12 - Idempotenza.
   Rilanciare INITIALIZE, MAIN e FINALIZE senza modificare le sorgenti.
   Atteso nel log MAIN: inserted=0 e updated=0. */
-- SELECT COUNT(*) AS numero_record,
--        MAX(dt_update) AS ultimo_aggiornamento
-- FROM hcbi_ras.dim_informatori;
