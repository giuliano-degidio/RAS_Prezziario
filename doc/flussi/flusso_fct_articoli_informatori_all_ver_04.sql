/* =====================================================================
   FCT_ARTICOLI_INFORMATORI - VERSIONE 04 - PostgreSQL 15.9 / 17

   Sorgente: hcbi_ras.dwh_articoli_informatori
   Destinazione: hcbi_ras.fct_articoli_informatori
   Grain: una riga per DWH_ARTICOLI_INFORMATORI.ID_ARTICOLI_INFORMATORI.

   Regole applicate:
   - lookup periodo tramite DS_ANNO;
   - lookup provincia tramite DWH_ANAG_PROVINCIA e DIM_PROVINCIA;
   - lookup versione tramite periodo + codice versione + provincia;
   - lookup articolo tramite periodo + codice articolo + versione + provincia;
   - lookup informatore tramite identificativo sorgente + provincia + anno +
     versione, quindi passaggio alla DIM_INFORMATORI tramite PK comune;
   - lookup utente tramite ID_SORGENTE_UTENTE, quindi passaggio alla DIM_UTENTI
     tramite PK comune;
   - membro tecnico -1 per lookup non risolte e per utente sorgente NULL;
   - controlli bloccanti di cardinalita e lookup non univoche;
   - caricamento idempotente tramite UPSERT;
   - nessuna cancellazione fisica dalla fact.

   Assunzioni dichiarate:
   - esistono i membri tecnici -1 nelle dimensioni referenziate;
   - DIM_VERSIONE, DIM_ARTICOLO e DIM_INFORMATORI sono gia alimentate;
   - DWH_ARTICOLI_INFORMATORI contiene ID_SORGENTE_PROVINCIA e CD_VERSIONE;
   - DWH_ANAG_INFORMATORI espone CD_VERSIONE;
   - la Provincia e risolta nel contesto ANNO/CD_VERSIONE;
   - DWH_ANAG_PROVINCIA viene risolta tramite ANNO + CD_VERSIONE +
     ID_SORGENTE_PROVINCIA; DIM_PROVINCIA viene raggiunta tramite
     ID_ANAG_PROVINCIA, con verifica di ANNO e CD_VERSIONE;
   - DIM_AREA_VASTA resta una dipendenza di DIM_PROVINCIA e non viene
     referenziata direttamente dalla fact;
   - MAIN usa una TEMP TABLE di sessione; evitare esecuzioni concorrenti sullo stesso grain.
   ===================================================================== */



/* =============================== FACT ================================= */
CREATE TABLE IF NOT EXISTS hcbi_ras.fct_articoli_informatori
(
    id_articoli_informatori bigint NOT NULL,
    id_periodo_pubblicazione integer NOT NULL,
    id_anag_provincia bigint NOT NULL,
    id_anag_versione bigint NOT NULL,
    id_anag_articolo bigint NOT NULL,
    id_anag_informatore bigint NOT NULL,
    id_anag_utente bigint NOT NULL,
    fl_escluso smallint NOT NULL,
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by varchar(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by varchar(4000) NOT NULL DEFAULT CURRENT_USER,

    CONSTRAINT pk_fct_articoli_informatori
        PRIMARY KEY (id_articoli_informatori),
    CONSTRAINT ck_fct_articoli_informatori_escluso
        CHECK (fl_escluso IN (0,1)),
    CONSTRAINT fk_fct_articoli_informatori_periodo
        FOREIGN KEY (id_periodo_pubblicazione)
        REFERENCES hcbi_ras.dim_periodo(id_periodo),
    CONSTRAINT fk_fct_articoli_informatori_provincia
        FOREIGN KEY (id_anag_provincia)
        REFERENCES hcbi_ras.dim_provincia(id_anag_provincia),
    CONSTRAINT fk_fct_articoli_informatori_versione
        FOREIGN KEY (id_anag_versione)
        REFERENCES hcbi_ras.dim_versione(id_anag_versione),
    CONSTRAINT fk_fct_articoli_informatori_articolo
        FOREIGN KEY (id_anag_articolo)
        REFERENCES hcbi_ras.dim_articolo(id_anag_articolo),
    CONSTRAINT fk_fct_articoli_informatori_informatore
        FOREIGN KEY (id_anag_informatore)
        REFERENCES hcbi_ras.dim_informatori(id_anag_informatore),
    CONSTRAINT fk_fct_articoli_informatori_utente
        FOREIGN KEY (id_anag_utente)
        REFERENCES hcbi_ras.dim_utenti(id_anag_utente)
);

ALTER TABLE hcbi_ras.fct_articoli_informatori OWNER TO hcbi_ras;
GRANT ALL ON TABLE hcbi_ras.fct_articoli_informatori TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE
    ON TABLE hcbi_ras.fct_articoli_informatori TO hcbi_utility;

CREATE INDEX IF NOT EXISTS ix_fct_articoli_informatori_periodo
    ON hcbi_ras.fct_articoli_informatori(id_periodo_pubblicazione);
CREATE INDEX IF NOT EXISTS ix_fct_articoli_informatori_provincia
    ON hcbi_ras.fct_articoli_informatori(id_anag_provincia);
CREATE INDEX IF NOT EXISTS ix_fct_articoli_informatori_versione
    ON hcbi_ras.fct_articoli_informatori(id_anag_versione);
CREATE INDEX IF NOT EXISTS ix_fct_articoli_informatori_articolo
    ON hcbi_ras.fct_articoli_informatori(id_anag_articolo);
CREATE INDEX IF NOT EXISTS ix_fct_articoli_informatori_informatore
    ON hcbi_ras.fct_articoli_informatori(id_anag_informatore);
CREATE INDEX IF NOT EXISTS ix_fct_articoli_informatori_utente
    ON hcbi_ras.fct_articoli_informatori(id_anag_utente);

COMMENT ON TABLE hcbi_ras.fct_articoli_informatori IS
'Fact atomica delle associazioni articoli-informatori; grain ID_ARTICOLI_INFORMATORI.';
COMMENT ON COLUMN hcbi_ras.fct_articoli_informatori.id_articoli_informatori IS
'PK mantenuta dalla riga sorgente DWH_ARTICOLI_INFORMATORI.';
COMMENT ON COLUMN hcbi_ras.fct_articoli_informatori.id_anag_utente IS
'Utente risolto dalla sorgente; -1 se ID_SORGENTE_UTENTE e NULL o non risolto.';

/* ========================== VISTA DI LOOKUP ============================ */
CREATE OR REPLACE VIEW hcbi_ras.v_fct_articoli_informatori_src AS
WITH base AS MATERIALIZED
(
    SELECT
        ai.id_articoli_informatori,
        ai.id_sorgente_articoli_informatori,
        ai.id_sorgente_informatore,
        ai.cd_articolo,
        trim(trailing '.' FROM btrim(ai.cd_articolo::text))::varchar(60)
            AS cd_articolo_normalizzato,
        ai.ds_anno,
        ai.id_sorgente_provincia,
        ai.cd_versione,
        ai.id_sorgente_utente,
        ai.fl_escluso,
        per.id_periodo,
        dpr.id_anag_provincia AS dwh_id_anag_provincia,
        prv.id_anag_provincia
    FROM hcbi_ras.dwh_articoli_informatori ai
    LEFT JOIN hcbi_ras.dim_periodo per
      ON per.ds_anno = ai.ds_anno
    LEFT JOIN hcbi_ras.dwh_anag_provincia dpr
      ON dpr.anno = ai.ds_anno::integer
     AND dpr.cd_versione = ai.cd_versione::smallint
     AND dpr.id_sorgente_provincia = ai.id_sorgente_provincia::bigint
    LEFT JOIN hcbi_ras.dim_provincia prv
      ON prv.id_anag_provincia = dpr.id_anag_provincia
     AND prv.anno = dpr.anno
     AND prv.cd_versione = dpr.cd_versione
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
        usr.id_anag_utente
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
    LEFT JOIN hcbi_ras.dwh_anag_informatori dinf
      ON dinf.id_sorgente_informatore = b.id_sorgente_informatore
     AND dinf.id_sorgente_provincia = b.id_sorgente_provincia::bigint
     AND dinf.ds_anno_pubblicazione = b.ds_anno
     AND dinf.cd_versione::text = b.cd_versione::text
     AND dinf.cd_versione = b.cd_versione
    LEFT JOIN hcbi_ras.dim_informatori inf
      ON inf.id_anag_informatore = dinf.id_anag_informatore
    LEFT JOIN hcbi_ras.dwh_anag_utenti dusr
      ON dusr.id_sorgente_utente = b.id_sorgente_utente::bigint
    LEFT JOIN hcbi_ras.dim_utenti usr
      ON usr.id_anag_utente = dusr.id_anag_utente
)
SELECT
    r.id_articoli_informatori,
    COALESCE(r.id_periodo, -1) AS id_periodo_pubblicazione,
    COALESCE(r.id_anag_provincia, -1::bigint) AS id_anag_provincia,
    COALESCE(r.id_anag_versione, -1::bigint) AS id_anag_versione,
    COALESCE(r.id_anag_articolo, -1::bigint) AS id_anag_articolo,
    COALESCE(r.id_anag_informatore, -1::bigint) AS id_anag_informatore,
    COALESCE(r.id_anag_utente, -1::bigint) AS id_anag_utente,
    r.fl_escluso,

    /* Colonne diagnostiche, non persistite nella fact. */
    r.id_sorgente_articoli_informatori,
    r.id_sorgente_informatore,
    r.cd_articolo,
    r.cd_articolo_normalizzato,
    r.ds_anno,
    r.id_sorgente_provincia,
    r.cd_versione,
    r.id_sorgente_utente,
    NULLIF(concat_ws('; ',
        CASE WHEN r.id_periodo IS NULL
             THEN 'DIM_PERIODO non risolta' END,
        CASE WHEN r.dwh_id_anag_provincia IS NULL
             THEN 'DWH_ANAG_PROVINCIA non risolta' END,
        CASE WHEN r.id_anag_provincia IS NULL
             THEN 'Lookup DIM_PROVINCIA non risolta tramite id_anag_provincia nel contesto anno+cd_versione' END,
        CASE WHEN r.id_anag_versione IS NULL
             THEN 'DIM_VERSIONE non risolta su periodo+versione+provincia' END,
        CASE WHEN r.id_anag_articolo IS NULL
             THEN 'DIM_ARTICOLO non risolta su periodo+articolo+versione+provincia' END,
        CASE WHEN r.dwh_id_anag_informatore IS NULL
             THEN 'DWH_ANAG_INFORMATORI non risolta su informatore+provincia+anno+versione' END,
        CASE WHEN r.dwh_id_anag_informatore IS NOT NULL
                   AND r.id_anag_informatore IS NULL
             THEN 'DIM_INFORMATORI non contiene la PK DWH' END,
        CASE WHEN r.id_sorgente_utente IS NOT NULL
                   AND r.dwh_id_anag_utente IS NULL
             THEN 'DWH_ANAG_UTENTI non risolta' END,
        CASE WHEN r.dwh_id_anag_utente IS NOT NULL
                   AND r.id_anag_utente IS NULL
             THEN 'DIM_UTENTI non contiene la PK DWH' END
    ), '')::varchar(4000) AS tx_motivo_lookup
FROM resolved r;

ALTER VIEW hcbi_ras.v_fct_articoli_informatori_src OWNER TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_fct_articoli_informatori_src
    TO hcbi_ras, hcbi_utility;

/* ============================= INITIALIZE ============================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_articoli_informatori_prc_initialize(
    p_id_chain_log bigint,
    p_id_chain bigint,
    p_id_step bigint,
    p_ds_step_name varchar,
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
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp, clock_timestamp()::timestamp,
        p_ds_step_name)
    INTO v_id_log;

    UPDATE hcbi_ras.dwh_articoli_informatori
       SET dt_reciclo = NULL
     WHERE dt_reciclo IS NOT NULL;

    UPDATE hcbi_ras.dwh_articoli_informatori d
       SET dt_reciclo = clock_timestamp()
      FROM hcbi_ras.fct_articoli_informatori f
     WHERE f.id_articoli_informatori = d.id_articoli_informatori
       AND (f.id_periodo_pubblicazione = -1
         OR f.id_anag_provincia = -1
         OR f.id_anag_versione = -1
         OR f.id_anag_articolo = -1
         OR f.id_anag_informatore = -1
         OR f.id_anag_utente = -1);

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_updated, 0, v_updated, 0, 0,
        'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name);

    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log, 'FAILED',
                left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                clock_timestamp()::timestamp, p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging INITIALIZE FCT_ARTICOLI_INFORMATORI: %', SQLERRM;
        END;
    END IF;
    RAISE;
END;
$BODY$;

/* ================================ MAIN ================================ */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_articoli_informatori_prc_main(
    p_id_chain_log bigint,
    p_id_chain bigint,
    p_id_step bigint,
    p_ds_step_name varchar,
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
    v_errors bigint := 0;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp, clock_timestamp()::timestamp,
        p_ds_step_name)
    INTO v_id_log;

    IF NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo = -1)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia = -1)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione = -1)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_articolo WHERE id_anag_articolo = -1)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_informatori WHERE id_anag_informatore = -1)
       OR NOT EXISTS (SELECT 1 FROM hcbi_ras.dim_utenti WHERE id_anag_utente = -1) THEN
        RAISE EXCEPTION 'Membri tecnici -1 mancanti nelle dimensioni della fact';
    END IF;

    /* Controlli preventivi sulle chiavi di lookup contestualizzate. */
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_provincia
        WHERE id_sorgente_provincia IS NOT NULL
        GROUP BY anno,cd_versione,id_sorgente_provincia
        HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION 'Lookup DWH_ANAG_PROVINCIA non deterministica su anno, cd_versione, id_sorgente_provincia';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_provincia
        WHERE cd_provincia IS NOT NULL
        GROUP BY anno,cd_versione,cd_provincia
        HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION 'Lookup DIM_PROVINCIA non deterministica su anno, cd_versione, cd_provincia';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_informatori
        WHERE id_sorgente_informatore IS NOT NULL
        GROUP BY id_sorgente_informatore,id_sorgente_provincia,
                 ds_anno_pubblicazione,cd_versione
        HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION 'Lookup DWH_ANAG_INFORMATORI non deterministica sulla business key contestualizzata';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_periodo
        WHERE ds_anno IS NOT NULL GROUP BY ds_anno HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION 'Lookup DIM_PERIODO non deterministica';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_versione
        GROUP BY id_periodo_pubblicazione,cd_versione,id_anag_provincia
        HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION 'Lookup DIM_VERSIONE non deterministica';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_articolo
        GROUP BY id_periodo_pubblicazione,cd_articolo,id_anag_versione,id_anag_provincia
        HAVING count(*)>1
    ) THEN
        RAISE EXCEPTION 'Lookup DIM_ARTICOLO non deterministica';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_articoli_informatori
        WHERE id_sorgente_provincia IS NULL OR ds_anno IS NULL OR cd_versione IS NULL
    ) THEN
        RAISE EXCEPTION 'Contesto Provincia incompleto: ID_SORGENTE_PROVINCIA, DS_ANNO e CD_VERSIONE sono obbligatori';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_articoli_informatori
        WHERE cd_versione IS NOT NULL
          AND (cd_versione::numeric < -32768 OR cd_versione::numeric > 32767)
    ) THEN
        RAISE EXCEPTION 'CD_VERSIONE fuori dominio SMALLINT in DWH_ARTICOLI_INFORMATORI';
    END IF;

    DROP TABLE IF EXISTS tmp_fct_articoli_informatori_src;
    CREATE TEMP TABLE tmp_fct_articoli_informatori_src
    ON COMMIT DROP AS
    SELECT
        id_articoli_informatori,
        id_periodo_pubblicazione,
        id_anag_provincia,
        id_anag_versione,
        id_anag_articolo,
        id_anag_informatore,
        id_anag_utente,
        fl_escluso,
        tx_motivo_lookup
    FROM hcbi_ras.v_fct_articoli_informatori_src;

    SELECT count(*) INTO v_selected
    FROM tmp_fct_articoli_informatori_src;

    IF v_selected <> (SELECT count(*) FROM hcbi_ras.dwh_articoli_informatori) THEN
        RAISE EXCEPTION 'Cardinalita vista (%) diversa dal DWH (%)',
            v_selected,
            (SELECT count(*) FROM hcbi_ras.dwh_articoli_informatori);
    END IF;

    IF EXISTS (
        SELECT 1
        FROM tmp_fct_articoli_informatori_src
        GROUP BY id_articoli_informatori
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION 'Lookup non univoci nella vista FCT_ARTICOLI_INFORMATORI';
    END IF;

    SELECT count(*) INTO v_errors
    FROM tmp_fct_articoli_informatori_src
    WHERE tx_motivo_lookup IS NOT NULL;

    SELECT count(*) INTO v_inserted
    FROM tmp_fct_articoli_informatori_src s
    LEFT JOIN hcbi_ras.fct_articoli_informatori f
      USING (id_articoli_informatori)
    WHERE f.id_articoli_informatori IS NULL;

    SELECT count(*) INTO v_updated
    FROM tmp_fct_articoli_informatori_src s
    JOIN hcbi_ras.fct_articoli_informatori f
      USING (id_articoli_informatori)
    WHERE ROW(
        f.id_periodo_pubblicazione,
        f.id_anag_provincia,
        f.id_anag_versione,
        f.id_anag_articolo,
        f.id_anag_informatore,
        f.id_anag_utente,
        f.fl_escluso
    ) IS DISTINCT FROM ROW(
        s.id_periodo_pubblicazione,
        s.id_anag_provincia,
        s.id_anag_versione,
        s.id_anag_articolo,
        s.id_anag_informatore,
        s.id_anag_utente,
        s.fl_escluso
    );

    INSERT INTO hcbi_ras.fct_articoli_informatori AS f
    (
        id_articoli_informatori,
        id_periodo_pubblicazione,
        id_anag_provincia,
        id_anag_versione,
        id_anag_articolo,
        id_anag_informatore,
        id_anag_utente,
        fl_escluso,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        s.id_articoli_informatori,
        s.id_periodo_pubblicazione,
        s.id_anag_provincia,
        s.id_anag_versione,
        s.id_anag_articolo,
        s.id_anag_informatore,
        s.id_anag_utente,
        s.fl_escluso,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM tmp_fct_articoli_informatori_src s
    ON CONFLICT (id_articoli_informatori) DO UPDATE SET
        id_periodo_pubblicazione = EXCLUDED.id_periodo_pubblicazione,
        id_anag_provincia = EXCLUDED.id_anag_provincia,
        id_anag_versione = EXCLUDED.id_anag_versione,
        id_anag_articolo = EXCLUDED.id_anag_articolo,
        id_anag_informatore = EXCLUDED.id_anag_informatore,
        id_anag_utente = EXCLUDED.id_anag_utente,
        fl_escluso = EXCLUDED.fl_escluso,
        dt_update = clock_timestamp(),
        tx_update_by = p_ds_step_name
    WHERE ROW(
        f.id_periodo_pubblicazione,
        f.id_anag_provincia,
        f.id_anag_versione,
        f.id_anag_articolo,
        f.id_anag_informatore,
        f.id_anag_utente,
        f.fl_escluso
    ) IS DISTINCT FROM ROW(
        EXCLUDED.id_periodo_pubblicazione,
        EXCLUDED.id_anag_provincia,
        EXCLUDED.id_anag_versione,
        EXCLUDED.id_anag_articolo,
        EXCLUDED.id_anag_informatore,
        EXCLUDED.id_anag_utente,
        EXCLUDED.fl_escluso
    );

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, v_updated, 0, v_errors,
        'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name);

    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log, 'FAILED',
                left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                clock_timestamp()::timestamp, p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging MAIN FCT_ARTICOLI_INFORMATORI: %', SQLERRM;
        END;
    END IF;
    RAISE;
END;
$BODY$;

/* ============================== FINALIZE =============================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_articoli_informatori_prc_finalize(
    p_id_chain_log bigint,
    p_id_chain bigint,
    p_id_step bigint,
    p_ds_step_name varchar,
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
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::timestamp, clock_timestamp()::timestamp,
        p_ds_step_name)
    INTO v_id_log;

    ANALYZE hcbi_ras.fct_articoli_informatori;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, 0, 0, 0, 0, 0,
        'SUCCESS', clock_timestamp()::timestamp, p_ds_step_name);

    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log, 'FAILED',
                left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM, 4000),
                clock_timestamp()::timestamp, p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging FINALIZE FCT_ARTICOLI_INFORMATORI: %', SQLERRM;
        END;
    END IF;
    RAISE;
END;
$BODY$;

/* ========================= OWNER / EXECUTE ============================= */
ALTER PROCEDURE hcbi_ras.pkg_fct_articoli_informatori_prc_initialize(bigint,bigint,bigint,varchar)
    OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_fct_articoli_informatori_prc_main(bigint,bigint,bigint,varchar)
    OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_fct_articoli_informatori_prc_finalize(bigint,bigint,bigint,varchar)
    OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_articoli_informatori_prc_initialize(bigint,bigint,bigint,varchar)
    TO hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_articoli_informatori_prc_main(bigint,bigint,bigint,varchar)
    TO hcbi_ras, hcbi_utility;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_fct_articoli_informatori_prc_finalize(bigint,bigint,bigint,varchar)
    TO hcbi_ras, hcbi_utility;

-- COMMIT;  -- Abilitare solo dopo i test pre-deployment e il restore point.

/* ================================ TEST =================================
T01 - Membri tecnici. Atteso: tutte TRUE.
SELECT
 EXISTS(SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo=-1) AS periodo,
 EXISTS(SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia=-1) AS provincia,
 EXISTS(SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione=-1) AS versione,
 EXISTS(SELECT 1 FROM hcbi_ras.dim_articolo WHERE id_anag_articolo=-1) AS articolo,
 EXISTS(SELECT 1 FROM hcbi_ras.dim_informatori WHERE id_anag_informatore=-1) AS informatore,
 EXISTS(SELECT 1 FROM hcbi_ras.dim_utenti WHERE id_anag_utente=-1) AS utente;

T02 - Business key DWH informatori. Atteso: zero righe.
SELECT id_sorgente_informatore,id_sorgente_provincia,
       ds_anno_pubblicazione,cd_versione,count(*)
FROM hcbi_ras.dwh_anag_informatori
GROUP BY 1,2,3,4 HAVING count(*)>1;

T02B - Chiave operazionale DWH_ANAG_PROVINCIA. Atteso: zero righe.
SELECT anno,cd_versione,id_sorgente_provincia,count(*)
FROM hcbi_ras.dwh_anag_provincia
WHERE id_sorgente_provincia IS NOT NULL
GROUP BY anno,cd_versione,id_sorgente_provincia HAVING count(*)>1;
T02C - Business key contestualizzata DIM_PROVINCIA. Atteso: zero righe.
SELECT anno,cd_versione,cd_provincia,count(*)
FROM hcbi_ras.dim_provincia
WHERE cd_provincia IS NOT NULL
GROUP BY anno,cd_versione,cd_provincia HAVING count(*)>1;
T02D - Province non risolte. Atteso: zero righe.
SELECT ai.id_articoli_informatori,ai.ds_anno,ai.cd_versione,
       ai.id_sorgente_provincia,
       dpr.id_anag_provincia AS id_anag_provincia_dwh,
       dpr.cd_provincia
FROM hcbi_ras.dwh_articoli_informatori ai
LEFT JOIN hcbi_ras.dwh_anag_provincia dpr
  ON dpr.anno=ai.ds_anno::integer
 AND dpr.cd_versione=ai.cd_versione::smallint
 AND dpr.id_sorgente_provincia=ai.id_sorgente_provincia::bigint
LEFT JOIN hcbi_ras.dim_provincia prv
  ON prv.id_anag_provincia=dpr.id_anag_provincia
 AND prv.anno=dpr.anno
 AND prv.cd_versione=dpr.cd_versione
WHERE prv.id_anag_provincia IS NULL;
T03 - Cardinalita DWH/vista. Atteso: conteggi uguali.
SELECT
 (SELECT count(*) FROM hcbi_ras.dwh_articoli_informatori) AS dwh,
 (SELECT count(*) FROM hcbi_ras.v_fct_articoli_informatori_src) AS vista;

T04 - Lookup non univoche. Atteso: zero righe.
SELECT id_articoli_informatori,count(*)
FROM hcbi_ras.v_fct_articoli_informatori_src
GROUP BY id_articoli_informatori HAVING count(*)>1;

T05 - Dettaglio lookup non risolte. Atteso a regime: zero righe,
      esclusi i casi ammessi dall'uso del membro tecnico -1.
SELECT id_articoli_informatori,ds_anno,cd_versione,
       id_sorgente_provincia,cd_articolo,id_sorgente_informatore,
       id_sorgente_utente,tx_motivo_lookup
FROM hcbi_ras.v_fct_articoli_informatori_src
WHERE tx_motivo_lookup IS NOT NULL
ORDER BY id_articoli_informatori;

T06 - Distribuzione membri tecnici dopo il carico.
SELECT count(*) AS totale,
 count(*) FILTER(WHERE id_periodo_pubblicazione=-1) AS periodo_nd,
 count(*) FILTER(WHERE id_anag_provincia=-1) AS provincia_nd,
 count(*) FILTER(WHERE id_anag_versione=-1) AS versione_nd,
 count(*) FILTER(WHERE id_anag_articolo=-1) AS articolo_nd,
 count(*) FILTER(WHERE id_anag_informatore=-1) AS informatore_nd,
 count(*) FILTER(WHERE id_anag_utente=-1) AS utente_nd
FROM hcbi_ras.fct_articoli_informatori;

T07 - Integrita referenziale logica. Atteso: zero.
SELECT count(*) AS orfani
FROM hcbi_ras.fct_articoli_informatori f
LEFT JOIN hcbi_ras.dim_periodo p
  ON p.id_periodo=f.id_periodo_pubblicazione
LEFT JOIN hcbi_ras.dim_provincia pr
  ON pr.id_anag_provincia=f.id_anag_provincia
LEFT JOIN hcbi_ras.dim_versione v
  ON v.id_anag_versione=f.id_anag_versione
LEFT JOIN hcbi_ras.dim_articolo a
  ON a.id_anag_articolo=f.id_anag_articolo
LEFT JOIN hcbi_ras.dim_informatori i
  ON i.id_anag_informatore=f.id_anag_informatore
LEFT JOIN hcbi_ras.dim_utenti u
  ON u.id_anag_utente=f.id_anag_utente
WHERE p.id_periodo IS NULL
   OR pr.id_anag_provincia IS NULL
   OR v.id_anag_versione IS NULL
   OR a.id_anag_articolo IS NULL
   OR i.id_anag_informatore IS NULL
   OR u.id_anag_utente IS NULL;

T08 - Riconciliazione DWH/fact. Atteso: conteggi e somma flag uguali.
SELECT
 (SELECT count(*) FROM hcbi_ras.dwh_articoli_informatori) AS righe_dwh,
 (SELECT count(*) FROM hcbi_ras.fct_articoli_informatori) AS righe_fact,
 (SELECT sum(fl_escluso) FROM hcbi_ras.dwh_articoli_informatori) AS esclusi_dwh,
 (SELECT sum(fl_escluso) FROM hcbi_ras.fct_articoli_informatori) AS esclusi_fact;

T09 - Coerenza attributi DWH/fact. Atteso: zero righe.
SELECT d.id_articoli_informatori
FROM hcbi_ras.dwh_articoli_informatori d
JOIN hcbi_ras.fct_articoli_informatori f
  USING(id_articoli_informatori)
WHERE d.fl_escluso IS DISTINCT FROM f.fl_escluso;

T10 - Idempotenza.
Rieseguire MAIN senza modifiche al DWH.
Atteso nel log: inseriti=0, aggiornati=0.

DEPLOYMENT
1. Verificare T01 e T02.
2. Acquisire un restore point secondo la procedura autorizzata.
3. Eseguire lo script in transazione lasciando COMMIT commentato.
4. Eseguire T03 e T04, quindi COMMIT se gli esiti sono conformi.
5. Eseguire INITIALIZE, MAIN e FINALIZE.
6. Eseguire T05-T10.

ROLLBACK
- Prima del COMMIT: ROLLBACK.
- Dopo il COMMIT: ripristinare vista e procedure dalla versione precedente.
- DROP TABLE della fact solo se autorizzato e dopo backup dei dati.
======================================================================== */
