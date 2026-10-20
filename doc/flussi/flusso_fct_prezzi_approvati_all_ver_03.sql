rollback;
/* =====================================================================
   FLUSSO FCT_PREZZI_APPROVATI
   Target: PostgreSQL 15.9 / 17
   Sorgente: hcbi_ras.dwh_prezzi_approvati

   Grain:
     una riga per hcbi_ras.dwh_prezzi_approvati.id_prezzi_approvati.

   Dimensioni:
     - hcbi_ras.dim_periodo
     - hcbi_ras.dim_provincia
     - hcbi_ras.dim_versione
     - hcbi_ras.dim_articolo

   Misure e attributi del fatto:
     - nr_prezzo
     - dt_approvazione

   Regole:
     - le lookup dimensionali non risolte assumono il membro tecnico -1;
     - initialize valorizza dt_reciclo nel DWH per le righe della fact con
       almeno una FK dimensionale non risolta (-1);
     - main verifica cardinalita e univocita delle lookup prima dell'upsert;
     - la Provincia e risolta nel contesto anno/addendum;
     - il caricamento e idempotente rispetto alla PK id_prezzi_approvati;
     - MAIN usa una TEMP TABLE di sessione; i contatori sono calcolati prima
       dell'upsert e richiedono assenza di esecuzioni concorrenti sullo stesso grain;
     - il codice articolo e normalizzato eliminando spazi e punti finali,
       in coerenza con il pattern FCT_PREZZI_RILEVATI fornito.

   Prerequisiti:
     - esistenza dei membri tecnici -1 nelle quattro dimensioni;
     - unicita delle business key dichiarate sulle dimensioni;
     - disponibilita delle routine di logging in hcbi_utility.
   ===================================================================== */

BEGIN;

/* ================================ FACT ================================= */
CREATE TABLE IF NOT EXISTS hcbi_ras.fct_prezzi_approvati
(
    id_prezzi_approvati bigint NOT NULL,
    id_periodo_pubblicazione integer NOT NULL,
    id_anag_provincia bigint NOT NULL,
    id_anag_versione bigint NOT NULL,
    id_anag_articolo bigint NOT NULL,
    nr_prezzo numeric(24,5) NOT NULL,
    dt_approvazione timestamp without time zone NOT NULL,
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by varchar(4000) NOT NULL DEFAULT current_user,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by varchar(4000) NOT NULL DEFAULT current_user,

    CONSTRAINT pk_fct_prezzi_approvati
        PRIMARY KEY (id_prezzi_approvati),

    CONSTRAINT fk_fct_prezzi_approvati_periodo
        FOREIGN KEY (id_periodo_pubblicazione)
        REFERENCES hcbi_ras.dim_periodo(id_periodo),

    CONSTRAINT fk_fct_prezzi_approvati_provincia
        FOREIGN KEY (id_anag_provincia)
        REFERENCES hcbi_ras.dim_provincia(id_anag_provincia),

    CONSTRAINT fk_fct_prezzi_approvati_versione
        FOREIGN KEY (id_anag_versione)
        REFERENCES hcbi_ras.dim_versione(id_anag_versione),

    CONSTRAINT fk_fct_prezzi_approvati_articolo
        FOREIGN KEY (id_anag_articolo)
        REFERENCES hcbi_ras.dim_articolo(id_anag_articolo)
);

ALTER TABLE hcbi_ras.fct_prezzi_approvati OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.fct_prezzi_approvati FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.fct_prezzi_approvati TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE
    ON TABLE hcbi_ras.fct_prezzi_approvati TO hcbi_utility;

CREATE INDEX IF NOT EXISTS ix_fct_prezzi_approvati_periodo
    ON hcbi_ras.fct_prezzi_approvati (id_periodo_pubblicazione);

CREATE INDEX IF NOT EXISTS ix_fct_prezzi_approvati_provincia
    ON hcbi_ras.fct_prezzi_approvati (id_anag_provincia);

CREATE INDEX IF NOT EXISTS ix_fct_prezzi_approvati_versione
    ON hcbi_ras.fct_prezzi_approvati (id_anag_versione);

CREATE INDEX IF NOT EXISTS ix_fct_prezzi_approvati_articolo
    ON hcbi_ras.fct_prezzi_approvati (id_anag_articolo);

COMMENT ON TABLE hcbi_ras.fct_prezzi_approvati IS
    'Fact atomica dei prezzi approvati; grain ID_PREZZI_APPROVATI.';
COMMENT ON COLUMN hcbi_ras.fct_prezzi_approvati.id_prezzi_approvati IS
    'PK mantenuta da DWH_PREZZI_APPROVATI.';
COMMENT ON COLUMN hcbi_ras.fct_prezzi_approvati.id_periodo_pubblicazione IS
    'FK verso DIM_PERIODO; -1 se la lookup non e risolta.';
COMMENT ON COLUMN hcbi_ras.fct_prezzi_approvati.id_anag_provincia IS
    'FK verso DIM_PROVINCIA; -1 se la lookup non e risolta.';
COMMENT ON COLUMN hcbi_ras.fct_prezzi_approvati.id_anag_versione IS
    'FK verso DIM_VERSIONE; -1 se la lookup non e risolta.';
COMMENT ON COLUMN hcbi_ras.fct_prezzi_approvati.id_anag_articolo IS
    'FK verso DIM_ARTICOLO; -1 se la lookup non e risolta.';
COMMENT ON COLUMN hcbi_ras.fct_prezzi_approvati.nr_prezzo IS
    'Prezzo approvato proveniente dal DWH.';
COMMENT ON COLUMN hcbi_ras.fct_prezzi_approvati.dt_approvazione IS
    'Data e ora di approvazione del prezzo.';

/* ============================= SOURCE VIEW ============================= */
CREATE OR REPLACE VIEW hcbi_ras.v_fct_prezzi_approvati_src AS
WITH base AS MATERIALIZED
(
    SELECT
        p.id_prezzi_approvati,
        p.cd_articolo,
        trim(trailing '.' FROM btrim(p.cd_articolo::text))::varchar(60)
            AS cd_articolo_normalizzato,
        p.ds_anno,
        p.id_sorgente_provincia,
        p.cd_versione,
        p.nr_prezzo,
        p.dt_approvazione,
        per.id_periodo,
        dpr.id_anag_provincia AS dwh_id_anag_provincia,
        prv.id_anag_provincia
    FROM hcbi_ras.dwh_prezzi_approvati p
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
        b.id_prezzi_approvati,
        b.cd_articolo,
        b.cd_articolo_normalizzato,
        b.ds_anno,
        b.id_sorgente_provincia,
        b.cd_versione,
        b.nr_prezzo,
        b.dt_approvazione,
        b.id_periodo,
        b.dwh_id_anag_provincia,
        b.id_anag_provincia,
        ver.id_anag_versione,
        art.id_anag_articolo
    FROM base b
    LEFT JOIN hcbi_ras.dim_versione ver
      ON ver.id_periodo_pubblicazione = b.id_periodo
     AND ver.cd_versione = b.cd_versione
     AND ver.id_anag_provincia = b.id_anag_provincia
    LEFT JOIN hcbi_ras.dim_articolo art
      ON art.id_periodo_pubblicazione = b.id_periodo
     AND btrim(art.cd_articolo) = btrim(b.cd_articolo_normalizzato)
     AND art.id_anag_versione = ver.id_anag_versione
     AND art.id_anag_provincia = b.id_anag_provincia
)
SELECT
    r.id_prezzi_approvati,
    CASE
        WHEN r.id_periodo IS NULL THEN -1
        ELSE r.id_periodo
    END AS id_periodo_pubblicazione,
    CASE
        WHEN r.id_anag_provincia IS NULL THEN -1::bigint
        ELSE r.id_anag_provincia
    END AS id_anag_provincia,
    CASE
        WHEN r.id_anag_versione IS NULL THEN -1::bigint
        ELSE r.id_anag_versione
    END AS id_anag_versione,
    CASE
        WHEN r.id_anag_articolo IS NULL THEN -1::bigint
        ELSE r.id_anag_articolo
    END AS id_anag_articolo,
    r.nr_prezzo,
    r.dt_approvazione,

    /* Colonne diagnostiche, non persistite nella fact. */
    r.cd_articolo,
    r.cd_articolo_normalizzato,
    r.ds_anno,
    r.cd_versione,
    r.id_sorgente_provincia,
    NULLIF(
        concat_ws(
            '; ',
            CASE
                WHEN r.id_periodo IS NULL
                    THEN 'DIM_PERIODO non risolta'
            END,
            CASE
                WHEN r.dwh_id_anag_provincia IS NULL
                    THEN 'DWH_ANAG_PROVINCIA non risolta'
            END,
            CASE
                WHEN r.dwh_id_anag_provincia IS NOT NULL
                 AND r.id_anag_provincia IS NULL
                    THEN 'Lookup DIM_PROVINCIA non risolta su anno+addendum+cd_provincia'
            END,
            CASE
                WHEN r.id_anag_versione IS NULL
                    THEN 'DIM_VERSIONE non risolta su periodo+versione+provincia'
            END,
            CASE
                WHEN r.id_anag_articolo IS NULL
                    THEN 'DIM_ARTICOLO non risolta su periodo+articolo+versione+provincia'
            END
        ),
        ''
    )::varchar(4000) AS tx_motivo_lookup
FROM resolved r;

ALTER VIEW hcbi_ras.v_fct_prezzi_approvati_src OWNER TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_fct_prezzi_approvati_src
    TO hcbi_ras, hcbi_utility;

/* ============================== INITIALIZE ============================= */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_initialize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name varchar,
    OUT p_result integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
    v_updated bigint := 0;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
               p_id_chain_log,
               p_id_chain,
               p_id_step,
               p_ds_step_name,
               clock_timestamp()::timestamp,
               clock_timestamp()::timestamp,
               p_ds_step_name)
      INTO v_id_log;

    UPDATE hcbi_ras.dwh_prezzi_approvati
       SET dt_reciclo = NULL
     WHERE dt_reciclo IS NOT NULL;

    UPDATE hcbi_ras.dwh_prezzi_approvati d
       SET dt_reciclo = clock_timestamp()
      FROM hcbi_ras.fct_prezzi_approvati f
     WHERE f.id_prezzi_approvati = d.id_prezzi_approvati
       AND (
            f.id_periodo_pubblicazione = -1
         OR f.id_anag_provincia = -1
         OR f.id_anag_versione = -1
         OR f.id_anag_articolo = -1
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_updated,
        0,
        v_updated,
        0,
        0,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name);

    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                    clock_timestamp()::timestamp,
                    p_ds_step_name);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Errore nel logging di INITIALIZE FCT_PREZZI_APPROVATI: %', SQLERRM;
            END;
        END IF;

        RAISE;
END;
$BODY$;

/* ================================= MAIN ================================ */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_main(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name varchar,
    OUT p_result integer)
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
    v_errors bigint := 0;
    v_dwh_count bigint := 0;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
               p_id_chain_log,
               p_id_chain,
               p_id_step,
               p_ds_step_name,
               clock_timestamp()::timestamp,
               clock_timestamp()::timestamp,
               p_ds_step_name)
      INTO v_id_log;

    /* I membri -1 sono obbligatori per rispettare le FK della fact. */
    IF NOT EXISTS (
           SELECT 1
             FROM hcbi_ras.dim_periodo
            WHERE id_periodo = -1
       )
       OR NOT EXISTS (
           SELECT 1
             FROM hcbi_ras.dim_provincia
            WHERE id_anag_provincia = -1
       )
       OR NOT EXISTS (
           SELECT 1
             FROM hcbi_ras.dim_versione
            WHERE id_anag_versione = -1
       )
       OR NOT EXISTS (
           SELECT 1
             FROM hcbi_ras.dim_articolo
            WHERE id_anag_articolo = -1
       ) THEN
        RAISE EXCEPTION
            'Membri tecnici -1 mancanti nelle dimensioni della FCT_PREZZI_APPROVATI';
    END IF;

    /* Controlli preventivi sulle chiavi di lookup contestualizzate. */
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_provincia
        WHERE id_sorgente_provincia IS NOT NULL
        GROUP BY anno, addendum, id_sorgente_provincia
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DWH_ANAG_PROVINCIA non deterministica',
            DETAIL='Duplicati su anno, addendum e id_sorgente_provincia.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_provincia
        WHERE cd_provincia IS NOT NULL
        GROUP BY anno, addendum, cd_provincia
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_PROVINCIA non deterministica',
            DETAIL='Duplicati su anno, addendum e cd_provincia.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_periodo
        WHERE ds_anno IS NOT NULL
        GROUP BY ds_anno HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_PERIODO non deterministica';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_versione
        GROUP BY id_periodo_pubblicazione, cd_versione, id_anag_provincia
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_VERSIONE non deterministica';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_articolo
        GROUP BY id_periodo_pubblicazione, cd_articolo,
                 id_anag_versione, id_anag_provincia
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_ARTICOLO non deterministica';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_prezzi_approvati
        WHERE id_sorgente_provincia IS NULL
           OR ds_anno IS NULL
           OR addendum IS NULL
    ) THEN
        RAISE EXCEPTION USING ERRCODE='23502',
            MESSAGE='Contesto Provincia incompleto in DWH_PREZZI_APPROVATI',
            DETAIL='ID_SORGENTE_PROVINCIA, DS_ANNO e ADDENDUM sono obbligatori.';
    END IF;

    DROP TABLE IF EXISTS tmp_fct_prezzi_approvati_src;

    CREATE TEMP TABLE tmp_fct_prezzi_approvati_src
    ON COMMIT DROP
    AS
    SELECT
        id_prezzi_approvati,
        id_periodo_pubblicazione,
        id_anag_provincia,
        id_anag_versione,
        id_anag_articolo,
        nr_prezzo,
        dt_approvazione,
        cd_articolo,
        cd_articolo_normalizzato,
        ds_anno,
        addendum,
        cd_versione,
        id_sorgente_provincia,
        tx_motivo_lookup
    FROM hcbi_ras.v_fct_prezzi_approvati_src;

    SELECT count(*)
      INTO v_selected
      FROM tmp_fct_prezzi_approvati_src;

    SELECT count(*)
      INTO v_dwh_count
      FROM hcbi_ras.dwh_prezzi_approvati;

    IF v_selected <> v_dwh_count THEN
        RAISE EXCEPTION
            'Cardinalita vista FCT_PREZZI_APPROVATI (%) diversa dal DWH (%)',
            v_selected,
            v_dwh_count;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM tmp_fct_prezzi_approvati_src
         GROUP BY id_prezzi_approvati
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION
            'Lookup non univoche nella vista FCT_PREZZI_APPROVATI';
    END IF;

    SELECT count(*)
      INTO v_errors
      FROM tmp_fct_prezzi_approvati_src
     WHERE tx_motivo_lookup IS NOT NULL;

    SELECT count(*)
      INTO v_inserted
      FROM tmp_fct_prezzi_approvati_src s
      LEFT JOIN hcbi_ras.fct_prezzi_approvati f
        ON f.id_prezzi_approvati = s.id_prezzi_approvati
     WHERE f.id_prezzi_approvati IS NULL;

    SELECT count(*)
      INTO v_updated
      FROM tmp_fct_prezzi_approvati_src s
      JOIN hcbi_ras.fct_prezzi_approvati f
        ON f.id_prezzi_approvati = s.id_prezzi_approvati
     WHERE ROW(
               f.id_periodo_pubblicazione,
               f.id_anag_provincia,
               f.id_anag_versione,
               f.id_anag_articolo,
               f.nr_prezzo,
               f.dt_approvazione
           ) IS DISTINCT FROM ROW(
               s.id_periodo_pubblicazione,
               s.id_anag_provincia,
               s.id_anag_versione,
               s.id_anag_articolo,
               s.nr_prezzo,
               s.dt_approvazione
           );

    INSERT INTO hcbi_ras.fct_prezzi_approvati AS f
    (
        id_prezzi_approvati,
        id_periodo_pubblicazione,
        id_anag_provincia,
        id_anag_versione,
        id_anag_articolo,
        nr_prezzo,
        dt_approvazione,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        s.id_prezzi_approvati,
        s.id_periodo_pubblicazione,
        s.id_anag_provincia,
        s.id_anag_versione,
        s.id_anag_articolo,
        s.nr_prezzo,
        s.dt_approvazione,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM tmp_fct_prezzi_approvati_src s
    ON CONFLICT (id_prezzi_approvati)
    DO UPDATE SET
        id_periodo_pubblicazione = EXCLUDED.id_periodo_pubblicazione,
        id_anag_provincia = EXCLUDED.id_anag_provincia,
        id_anag_versione = EXCLUDED.id_anag_versione,
        id_anag_articolo = EXCLUDED.id_anag_articolo,
        nr_prezzo = EXCLUDED.nr_prezzo,
        dt_approvazione = EXCLUDED.dt_approvazione,
        dt_update = clock_timestamp(),
        tx_update_by = p_ds_step_name
    WHERE ROW(
              f.id_periodo_pubblicazione,
              f.id_anag_provincia,
              f.id_anag_versione,
              f.id_anag_articolo,
              f.nr_prezzo,
              f.dt_approvazione
          ) IS DISTINCT FROM ROW(
              EXCLUDED.id_periodo_pubblicazione,
              EXCLUDED.id_anag_provincia,
              EXCLUDED.id_anag_versione,
              EXCLUDED.id_anag_articolo,
              EXCLUDED.nr_prezzo,
              EXCLUDED.dt_approvazione
          );

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name);

    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                    clock_timestamp()::timestamp,
                    p_ds_step_name);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Errore nel logging di MAIN FCT_PREZZI_APPROVATI: %', SQLERRM;
            END;
        END IF;

        RAISE;
END;
$BODY$;

/* =============================== FINALIZE ============================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_finalize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name varchar,
    OUT p_result integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, hcbi_ras, hcbi_utility
AS $BODY$
DECLARE
    v_id_log bigint;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
               p_id_chain_log,
               p_id_chain,
               p_id_step,
               p_ds_step_name,
               clock_timestamp()::timestamp,
               clock_timestamp()::timestamp,
               p_ds_step_name)
      INTO v_id_log;

    ANALYZE hcbi_ras.fct_prezzi_approvati;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        0,
        0,
        0,
        0,
        0,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name);

    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_id_log,
                    'FAILED',
                    left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                    clock_timestamp()::timestamp,
                    p_ds_step_name);
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING 'Errore nel logging di FINALIZE FCT_PREZZI_APPROVATI: %', SQLERRM;
            END;
        END IF;

        RAISE;
END;
$BODY$;

/* ========================= OWNER / EXECUTE ============================= */
ALTER PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_initialize(
    bigint, bigint, bigint, varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_main(
    bigint, bigint, bigint, varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_finalize(
    bigint, bigint, bigint, varchar) OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_initialize(
    bigint, bigint, bigint, varchar) TO hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_main(
    bigint, bigint, bigint, varchar) TO hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_finalize(
    bigint, bigint, bigint, varchar) TO hcbi_ras, hcbi_utility;

COMMENT ON VIEW hcbi_ras.v_fct_prezzi_approvati_src IS
    'Vista di alimentazione e diagnostica della FCT_PREZZI_APPROVATI.';
COMMENT ON PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_initialize(
    bigint, bigint, bigint, varchar) IS
    'Inizializza il riciclo delle lookup dimensionali non risolte.';
COMMENT ON PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_main(
    bigint, bigint, bigint, varchar) IS
    'Controlla le lookup e riallinea FCT_PREZZI_APPROVATI tramite upsert.';
COMMENT ON PROCEDURE hcbi_ras.pkg_fct_prezzi_approvati_prc_finalize(
    bigint, bigint, bigint, varchar) IS
    'Aggiorna le statistiche della FCT_PREZZI_APPROVATI.';

COMMIT;

/* ================================ TEST =================================
   Eseguire i test nella sequenza indicata.
   ===================================================================== */

/* T01 - Prerequisiti strutturali.
   Atteso: tutti gli oggetti valorizzati. */
-- SELECT
--     to_regclass('hcbi_ras.dwh_prezzi_approvati') AS dwh,
--     to_regclass('hcbi_ras.fct_prezzi_approvati') AS fact,
--     to_regclass('hcbi_ras.dim_periodo') AS dim_periodo,
--     to_regclass('hcbi_ras.dim_provincia') AS dim_provincia,
--     to_regclass('hcbi_ras.dim_versione') AS dim_versione,
--     to_regclass('hcbi_ras.dim_articolo') AS dim_articolo,
--     to_regclass('hcbi_ras.dwh_anag_provincia') AS dwh_anag_provincia;

/* T02 - Membri tecnici -1.
   Atteso: tutte TRUE. */
-- SELECT
--     EXISTS (
--         SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo = -1
--     ) AS periodo,
--     EXISTS (
--         SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia = -1
--     ) AS provincia,
--     EXISTS (
--         SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione = -1
--     ) AS versione,
--     EXISTS (
--         SELECT 1 FROM hcbi_ras.dim_articolo WHERE id_anag_articolo = -1
--     ) AS articolo;

/* T03 - Univocita chiave operazionale DWH_ANAG_PROVINCIA.
   Atteso: zero righe. */
-- SELECT
--     anno,
--     addendum,
--     id_sorgente_provincia,
--     count(*) AS occorrenze
-- FROM hcbi_ras.dwh_anag_provincia
-- WHERE id_sorgente_provincia IS NOT NULL
-- GROUP BY anno, addendum, id_sorgente_provincia
-- HAVING count(*) > 1;

/* T03B - Univocita business key contestualizzata DIM_PROVINCIA.
   Atteso: zero righe. */
-- SELECT anno, addendum, cd_provincia, count(*) AS occorrenze
-- FROM hcbi_ras.dim_provincia
-- WHERE cd_provincia IS NOT NULL
-- GROUP BY anno, addendum, cd_provincia
-- HAVING count(*) > 1;

/* T04 - Univocita business key DIM_VERSIONE.
   Atteso: zero righe. */
-- SELECT
--     id_periodo_pubblicazione,
--     cd_versione,
--     id_anag_provincia,
--     count(*) AS occorrenze
-- FROM hcbi_ras.dim_versione
-- GROUP BY id_periodo_pubblicazione, cd_versione, id_anag_provincia
-- HAVING count(*) > 1;

/* T05 - Univocita business key DIM_ARTICOLO normalizzata.
   Atteso: zero righe. La normalizzazione replica quella della vista. */
-- SELECT
--     id_periodo_pubblicazione,
--     trim(trailing '.' FROM btrim(cd_articolo::text)) AS cd_articolo_normalizzato,
--     id_anag_versione,
--     id_anag_provincia,
--     count(*) AS occorrenze
-- FROM hcbi_ras.dim_articolo
-- GROUP BY
--     id_periodo_pubblicazione,
--     trim(trailing '.' FROM btrim(cd_articolo::text)),
--     id_anag_versione,
--     id_anag_provincia
-- HAVING count(*) > 1;

/* T06 - Cardinalita DWH/vista.
   Atteso: conteggi uguali. */
-- SELECT
--     (SELECT count(*) FROM hcbi_ras.dwh_prezzi_approvati) AS righe_dwh,
--     (SELECT count(*) FROM hcbi_ras.v_fct_prezzi_approvati_src) AS righe_vista;

/* T07 - Duplicati per grain nella vista.
   Atteso: zero righe. */
-- SELECT
--     id_prezzi_approvati,
--     count(*) AS occorrenze
-- FROM hcbi_ras.v_fct_prezzi_approvati_src
-- GROUP BY id_prezzi_approvati
-- HAVING count(*) > 1;

/* T08 - Dettaglio lookup non risolte.
   Atteso a regime: zero righe. */
-- SELECT
--     id_prezzi_approvati,
--     ds_anno,
--     addendum,
--     cd_versione,
--     id_sorgente_provincia,
--     cd_articolo,
--     cd_articolo_normalizzato,
--     tx_motivo_lookup
-- FROM hcbi_ras.v_fct_prezzi_approvati_src
-- WHERE tx_motivo_lookup IS NOT NULL
-- ORDER BY id_prezzi_approvati;

/* T08B - Lookup Provincia non risolte. Atteso: zero righe a regime. */
-- SELECT p.id_prezzi_approvati, p.ds_anno, p.addendum,
--        p.id_sorgente_provincia, dpr.cd_provincia
-- FROM hcbi_ras.dwh_prezzi_approvati AS p
-- LEFT JOIN hcbi_ras.dwh_anag_provincia AS dpr
--   ON dpr.anno=p.ds_anno::integer
--  AND dpr.addendum=p.addendum::integer
--  AND dpr.id_sorgente_provincia=p.id_sorgente_provincia::bigint
-- LEFT JOIN hcbi_ras.dim_provincia AS prv
--   ON prv.anno=dpr.anno
--  AND prv.addendum=dpr.addendum
--  AND prv.cd_provincia=dpr.cd_provincia
-- WHERE prv.id_anag_provincia IS NULL;

/* T09 - Distribuzione membri tecnici nella fact. */
-- SELECT
--     count(*) AS totale,
--     count(*) FILTER (WHERE id_periodo_pubblicazione = -1) AS periodo_nd,
--     count(*) FILTER (WHERE id_anag_provincia = -1) AS provincia_nd,
--     count(*) FILTER (WHERE id_anag_versione = -1) AS versione_nd,
--     count(*) FILTER (WHERE id_anag_articolo = -1) AS articolo_nd
-- FROM hcbi_ras.fct_prezzi_approvati;

/* T10 - Integrita referenziale logica.
   Atteso: zero. */
-- SELECT count(*) AS orfani
-- FROM hcbi_ras.fct_prezzi_approvati f
-- LEFT JOIN hcbi_ras.dim_periodo p
--   ON p.id_periodo = f.id_periodo_pubblicazione
-- LEFT JOIN hcbi_ras.dim_provincia pr
--   ON pr.id_anag_provincia = f.id_anag_provincia
-- LEFT JOIN hcbi_ras.dim_versione v
--   ON v.id_anag_versione = f.id_anag_versione
-- LEFT JOIN hcbi_ras.dim_articolo a
--   ON a.id_anag_articolo = f.id_anag_articolo
-- WHERE p.id_periodo IS NULL
--    OR pr.id_anag_provincia IS NULL
--    OR v.id_anag_versione IS NULL
--    OR a.id_anag_articolo IS NULL;

/* T11 - Riconciliazione di conteggi e prezzo.
   Atteso dopo MAIN: conteggi e somme uguali. */
-- SELECT
--     (SELECT count(*) FROM hcbi_ras.dwh_prezzi_approvati) AS righe_dwh,
--     (SELECT count(*) FROM hcbi_ras.fct_prezzi_approvati) AS righe_fact,
--     (SELECT sum(nr_prezzo) FROM hcbi_ras.dwh_prezzi_approvati) AS prezzo_dwh,
--     (SELECT sum(nr_prezzo) FROM hcbi_ras.fct_prezzi_approvati) AS prezzo_fact;

/* T12 - Confronto puntuale DWH/fact.
   Atteso dopo MAIN: zero righe. */
-- SELECT
--     s.id_prezzi_approvati,
--     s.tx_motivo_lookup
-- FROM hcbi_ras.v_fct_prezzi_approvati_src s
-- LEFT JOIN hcbi_ras.fct_prezzi_approvati f
--   ON f.id_prezzi_approvati = s.id_prezzi_approvati
-- WHERE f.id_prezzi_approvati IS NULL
--    OR ROW(
--           f.id_periodo_pubblicazione,
--           f.id_anag_provincia,
--           f.id_anag_versione,
--           f.id_anag_articolo,
--           f.nr_prezzo,
--           f.dt_approvazione
--       ) IS DISTINCT FROM ROW(
--           s.id_periodo_pubblicazione,
--           s.id_anag_provincia,
--           s.id_anag_versione,
--           s.id_anag_articolo,
--           s.nr_prezzo,
--           s.dt_approvazione
--       );

/* T13 - Riciclo.
   Passi:
   1. eseguire INITIALIZE;
   2. verificare che le sole righe della fact con almeno una FK = -1 abbiano
      la corrispondente DWH con dt_reciclo non NULL.
   Atteso: anomalie = 0. */
-- SELECT count(*) AS anomalie
-- FROM hcbi_ras.dwh_prezzi_approvati d
-- JOIN hcbi_ras.fct_prezzi_approvati f
--   ON f.id_prezzi_approvati = d.id_prezzi_approvati
-- WHERE (f.id_periodo_pubblicazione = -1
--     OR f.id_anag_provincia = -1
--     OR f.id_anag_versione = -1
--     OR f.id_anag_articolo = -1)
--   AND d.dt_reciclo IS NULL;

/* T14 - Idempotenza.
   Rilanciare MAIN senza modificare DWH o dimensioni.
   Atteso nel log: inserted = 0, updated = 0. */

/* ========================= DEPLOYMENT / ROLLBACK ========================
Prerequisiti:
1. Verificare T01-T05.
2. Acquisire un restore point o backup secondo la procedura autorizzata.
3. Verificare i privilegi di hcbi_ras e hcbi_utility.

Ordine operativo:
1. Eseguire questo script.
2. Eseguire INITIALIZE, MAIN e FINALIZE tramite l'orchestratore.
3. Eseguire T06-T14 e conservare le evidenze.

Rollback applicativo:
1. Ripristinare le precedenti definizioni di vista e procedure, se esistenti.
2. Il DROP di FCT_PREZZI_APPROVATI e consentito solo previa autorizzazione e
   dopo backup dei dati.
3. In caso di errore prima del COMMIT, PostgreSQL annulla l'intero blocco DDL.

Nota delete:
Il flusso, coerentemente con il pattern fornito, non elimina dalla fact le
chiavi non piu presenti nel DWH. Un'eventuale propagazione delle cancellazioni
richiede una regola funzionale esplicita e non e inclusa in questo script.
======================================================================== */
