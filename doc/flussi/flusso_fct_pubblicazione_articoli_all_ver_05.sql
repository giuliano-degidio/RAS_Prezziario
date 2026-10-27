/* =====================================================================
   DATAMART - FCT_PUBBLICAZIONE_ARTICOLI - VERSIONE 05
   Target: PostgreSQL 15.9 / 17
   Schema: hcbi_ras

   Grain:
     una riga per record di DWH_PUBBLICAZIONE_ARTICOLI, identificato da
     ID_PUBBLICAZIONE_ARTICOLI.

   Business key sorgente:
     ID_SORGENTE_PROVINCIA + DS_ANNO_PUBBLICAZIONE + CD_VERSIONE +
     CD_CODICE_COMPLETO.

   Regole FK:
     - periodo, provincia, versione e articolo sono obbligatori:
       lookup non risolto -> -1;
     - tipologia, capitolo, sottocapitolo, unita di misura e macro-gruppo
       sono condizionali:
       codice sorgente nullo -> 0;
       codice valorizzato ma non risolto -> -1;
       lookup riuscito -> ID dimensionale.

   Normalizzazione articolo e classificazione:
     BTRIM e rimozione del solo punto finale da CD_ARTICOLO.
     I codici gerarchici sono derivati dal codice articolo normalizzato:
       segmento 1 -> tipologia;
       segmenti 1-2 -> capitolo;
       segmenti 1-3 -> sottocapitolo.

   Lookup Provincia:
     DWH_PUBBLICAZIONE_ARTICOLI.DS_ANNO_PUBBLICAZIONE + CD_VERSIONE +
     ID_SORGENTE_PROVINCIA -> DWH_ANAG_PROVINCIA.ANNO + CD_VERSIONE +
     ID_SORGENTE_PROVINCIA; DIM_PROVINCIA viene poi risolta tramite
     ID_ANAG_PROVINCIA, con verifica di ANNO e CD_VERSIONE.
   Il contesto della Provincia e' CD_VERSIONE. Il flusso non utilizza il
   precedente attributo di contesto.
   DIM_AREA_VASTA resta una dipendenza di DIM_PROVINCIA e non viene
   referenziata direttamente dalla fact.
   Macro-gruppo:
     DWH_PUBBLICAZIONE_ARTICOLI.NR_MACRO_GRUPPO
       -> DWH_ANAG_MACRO_GRUPPO.ID_SORGENTE_MACRO_GRUPPO
       -> DIM_MACRO_GRUPPO.ID_ANAG_MACRO_GRUPPO.

   Modalita di caricamento:
     full set-based con UPSERT idempotente; nessuna cancellazione fisica
     automatica dei record non piu presenti nella DWH.
     PRC_MAIN non eseguibile in parallelo: usa una tabella di lavoro a nome fisso.
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.fct_pubblicazione_articoli
(
    id_pubblicazione_articoli bigint NOT NULL,
    id_periodo_pubblicazione integer NOT NULL,
    id_anag_provincia bigint NOT NULL,
    id_anag_versione bigint NOT NULL,
    id_anag_articolo bigint NOT NULL,
    id_anag_tipologia bigint NOT NULL,
    id_anag_capitolo bigint NOT NULL,
    id_anag_sottocapitolo bigint NOT NULL,
    id_anag_unita_misura bigint NOT NULL,
    id_anag_macro_gruppo bigint NOT NULL,

    cd_codice_completo varchar(70) NOT NULL,
    cd_categoria_articolo varchar(10),
    cd_subarticolo varchar(10),
    ds_unita_misura_de varchar(20),
    id_sorgente_categoria bigint,
    id_sorgente_pubblicazione_articoli bigint,

    nr_prezzo numeric(24,5),
    nr_prezzo_annuo numeric(24,5),
    nr_perc_spese numeric(24,5),
    nr_perc_utile numeric(10,5),
    nr_sicur numeric(24,5),
    nr_perc_manodopera numeric(10,5),
    nr_perc_oneri numeric(10,5),
    nr_prezzo_manodopera numeric(24,5),
    nr_perc_manodopera_dir numeric(10,5),
    nr_prezzo_manodopera_dir numeric(24,5),
    nr_spese numeric(24,5),
    nr_utili numeric(24,5),

    fl_isanalisi smallint,
    fl_is_minuteria smallint,
    fl_ifc_scaricabile smallint,

    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by varchar(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by varchar(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_reciclo timestamp without time zone,

    CONSTRAINT pk_fct_pubblicazione_articoli
        PRIMARY KEY (id_pubblicazione_articoli),

    CONSTRAINT fk_fct_pub_art_periodo
        FOREIGN KEY (id_periodo_pubblicazione)
        REFERENCES hcbi_ras.dim_periodo (id_periodo),

    CONSTRAINT fk_fct_pub_art_provincia
        FOREIGN KEY (id_anag_provincia)
        REFERENCES hcbi_ras.dim_provincia (id_anag_provincia),

    CONSTRAINT fk_fct_pub_art_versione
        FOREIGN KEY (id_anag_versione)
        REFERENCES hcbi_ras.dim_versione (id_anag_versione),

    CONSTRAINT fk_fct_pub_art_articolo
        FOREIGN KEY (id_anag_articolo)
        REFERENCES hcbi_ras.dim_articolo (id_anag_articolo),

    CONSTRAINT fk_fct_pub_art_tipologia
        FOREIGN KEY (id_anag_tipologia)
        REFERENCES hcbi_ras.dim_tipologia (id_anag_tipologia),

    CONSTRAINT fk_fct_pub_art_capitolo
        FOREIGN KEY (id_anag_capitolo)
        REFERENCES hcbi_ras.dim_capitolo (id_anag_capitolo),

    CONSTRAINT fk_fct_pub_art_sottocapitolo
        FOREIGN KEY (id_anag_sottocapitolo)
        REFERENCES hcbi_ras.dim_sottocapitolo (id_anag_sottocapitolo),

    CONSTRAINT fk_fct_pub_art_unita_misura
        FOREIGN KEY (id_anag_unita_misura)
        REFERENCES hcbi_ras.dim_unita_misura (id_anag_unita_misura),

    CONSTRAINT fk_fct_pub_art_macro_gruppo
        FOREIGN KEY (id_anag_macro_gruppo)
        REFERENCES hcbi_ras.dim_macro_gruppo (id_anag_macro_gruppo)
);

ALTER TABLE hcbi_ras.fct_pubblicazione_articoli OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.fct_pubblicazione_articoli FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.fct_pubblicazione_articoli TO hcbi_ras;
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE hcbi_ras.fct_pubblicazione_articoli TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.fct_pubblicazione_articoli IS
'Fact atomica delle pubblicazioni articolo; grain ID_PUBBLICAZIONE_ARTICOLI e FK verso periodo, provincia, versione, articolo, tipologia, capitolo, sottocapitolo, unita di misura e macro-gruppo.';

/* =====================================================================
   VISTA SORGENTE DELLA FACT
   ===================================================================== */
CREATE OR REPLACE VIEW hcbi_ras.v_fct_pubblicazione_articoli_src AS
WITH base AS MATERIALIZED
(
    SELECT
        src.id_pubblicazione_articoli,
        src.id_sorgente_provincia,
        src.ds_anno_pubblicazione,
        src.cd_codice_completo,
        src.cd_versione,
        src.cd_articolo,
        trim(trailing '.' FROM btrim(src.cd_articolo::text))::varchar(60)
            AS cd_articolo_normalizzato,
        split_part(
            trim(trailing '.' FROM btrim(src.cd_articolo::text)), '.', 1
        )::varchar(60) AS cd_tipologia_lookup,
        concat_ws(
            '.',
            split_part(trim(trailing '.' FROM btrim(src.cd_articolo::text)), '.', 1),
            split_part(trim(trailing '.' FROM btrim(src.cd_articolo::text)), '.', 2)
        )::varchar(60) AS cd_capitolo_lookup,
        concat_ws(
            '.',
            split_part(trim(trailing '.' FROM btrim(src.cd_articolo::text)), '.', 1),
            split_part(trim(trailing '.' FROM btrim(src.cd_articolo::text)), '.', 2),
            split_part(trim(trailing '.' FROM btrim(src.cd_articolo::text)), '.', 3)
        )::varchar(60) AS cd_sottocapitolo_lookup,
        src.cd_titolo,
        src.cd_capitolo,
        src.cd_sottocapitolo,
        src.cd_categoria_articolo,
        src.cd_subarticolo,
        src.cd_unita_misura,
        src.ds_unita_misura_de,
        src.id_sorgente_categoria,
        src.id_sorgente_pubblicazione_articoli,
        src.nr_macro_gruppo,
        src.nr_prezzo,
        src.nr_prezzo_annuo,
        src.nr_perc_spese,
        src.nr_perc_utile,
        src.nr_sicur,
        src.nr_perc_manodopera,
        src.nr_perc_oneri,
        src.nr_prezzo_manodopera,
        src.nr_perc_manodopera_dir,
        src.nr_prezzo_manodopera_dir,
        src.nr_spese,
        src.nr_utili,
        src.fl_isanalisi,
        src.fl_is_minuteria,
        src.fl_ifc_scaricabile,
        per.id_periodo,
        dwh_prv.cd_provincia,
        prv.id_anag_provincia
    FROM hcbi_ras.dwh_pubblicazione_articoli AS src
    LEFT JOIN hcbi_ras.dim_periodo AS per
      ON per.ds_anno::numeric = src.ds_anno_pubblicazione::numeric
    LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwh_prv
      ON dwh_prv.anno = src.ds_anno_pubblicazione::integer
     AND dwh_prv.cd_versione = src.cd_versione::smallint
     AND dwh_prv.id_sorgente_provincia = src.id_sorgente_provincia::bigint
    LEFT JOIN hcbi_ras.dim_provincia AS prv
      ON prv.id_anag_provincia = dwh_prv.id_anag_provincia
     AND prv.anno = dwh_prv.anno
     AND prv.cd_versione = dwh_prv.cd_versione
),
resolved AS MATERIALIZED
(
    SELECT
        b.id_pubblicazione_articoli,
        b.id_sorgente_provincia,
        b.ds_anno_pubblicazione,
        b.cd_codice_completo,
        b.cd_versione,
        b.cd_articolo,
        b.cd_articolo_normalizzato,
        b.cd_tipologia_lookup,
        b.cd_capitolo_lookup,
        b.cd_sottocapitolo_lookup,
        b.cd_titolo,
        b.cd_capitolo,
        b.cd_sottocapitolo,
        b.cd_categoria_articolo,
        b.cd_subarticolo,
        b.cd_unita_misura,
        b.ds_unita_misura_de,
        b.id_sorgente_categoria,
        b.id_sorgente_pubblicazione_articoli,
        b.nr_macro_gruppo,
        b.nr_prezzo,
        b.nr_prezzo_annuo,
        b.nr_perc_spese,
        b.nr_perc_utile,
        b.nr_sicur,
        b.nr_perc_manodopera,
        b.nr_perc_oneri,
        b.nr_prezzo_manodopera,
        b.nr_perc_manodopera_dir,
        b.nr_prezzo_manodopera_dir,
        b.nr_spese,
        b.nr_utili,
        b.fl_isanalisi,
        b.fl_is_minuteria,
        b.fl_ifc_scaricabile,
        b.id_periodo,
        b.cd_provincia,
        b.id_anag_provincia,
        ver.id_anag_versione,
        art.id_anag_articolo,
        tip.id_anag_tipologia,
        cap.id_anag_capitolo,
        sot.id_anag_sottocapitolo,
        um.id_anag_unita_misura,
        dwh_mg.id_anag_macro_gruppo AS dwh_id_anag_macro_gruppo,
        mg.id_anag_macro_gruppo
    FROM base AS b
    LEFT JOIN hcbi_ras.dim_versione AS ver
      ON ver.id_periodo_pubblicazione = b.id_periodo
     AND ver.id_anag_provincia = b.id_anag_provincia
     AND btrim(ver.cd_versione::text) = btrim(b.cd_versione::text)
    LEFT JOIN hcbi_ras.dim_articolo AS art
      ON art.id_periodo_pubblicazione = b.id_periodo
     AND art.id_anag_provincia = b.id_anag_provincia
     AND art.id_anag_versione = ver.id_anag_versione
     AND trim(trailing '.' FROM btrim(art.cd_articolo::text))
         = b.cd_articolo_normalizzato
    LEFT JOIN hcbi_ras.dim_tipologia AS tip
      ON btrim(tip.cd_tipologia::text) = btrim(b.cd_tipologia_lookup::text)
     AND tip.id_periodo_pubblicazione = b.id_periodo
     AND tip.id_anag_versione = ver.id_anag_versione
     AND tip.id_anag_provincia = b.id_anag_provincia
    LEFT JOIN hcbi_ras.dim_capitolo AS cap
      ON btrim(cap.cd_capitolo::text) = btrim(b.cd_capitolo_lookup::text)
     AND cap.id_periodo_pubblicazione = b.id_periodo
     AND cap.id_anag_versione = ver.id_anag_versione
     AND cap.id_anag_provincia = b.id_anag_provincia
    LEFT JOIN hcbi_ras.dim_sottocapitolo AS sot
      ON btrim(sot.cd_sottocapitolo::text) = btrim(b.cd_sottocapitolo_lookup::text)
     AND sot.id_periodo_pubblicazione = b.id_periodo
     AND sot.id_anag_versione = ver.id_anag_versione
     AND sot.id_anag_provincia = b.id_anag_provincia
    LEFT JOIN hcbi_ras.dim_unita_misura AS um
      ON btrim(um.cd_unita_misura::text) = btrim(b.cd_unita_misura::text)
    LEFT JOIN hcbi_ras.dwh_anag_macro_gruppo AS dwh_mg
      ON dwh_mg.id_sorgente_macro_gruppo = b.nr_macro_gruppo::bigint
    LEFT JOIN hcbi_ras.dim_macro_gruppo AS mg
      ON mg.id_anag_macro_gruppo = dwh_mg.id_anag_macro_gruppo
)
SELECT
    r.id_pubblicazione_articoli,
    COALESCE(r.id_periodo, -1::integer) AS id_periodo_pubblicazione,
    COALESCE(r.id_anag_provincia, -1::bigint) AS id_anag_provincia,
    COALESCE(r.id_anag_versione, -1::bigint) AS id_anag_versione,
    COALESCE(r.id_anag_articolo, -1::bigint) AS id_anag_articolo,
    CASE
      WHEN NULLIF(btrim(r.cd_titolo::text), '') IS NULL THEN 0::bigint
      ELSE COALESCE(r.id_anag_tipologia, -1::bigint)
    END AS id_anag_tipologia,
    CASE
      WHEN NULLIF(btrim(r.cd_capitolo::text), '') IS NULL THEN 0::bigint
      ELSE COALESCE(r.id_anag_capitolo, -1::bigint)
    END AS id_anag_capitolo,
    CASE
      WHEN NULLIF(btrim(r.cd_sottocapitolo::text), '') IS NULL THEN 0::bigint
      ELSE COALESCE(r.id_anag_sottocapitolo, -1::bigint)
    END AS id_anag_sottocapitolo,
    CASE
      WHEN NULLIF(btrim(r.cd_unita_misura::text), '') IS NULL THEN 0::bigint
      ELSE COALESCE(r.id_anag_unita_misura, -1::bigint)
    END AS id_anag_unita_misura,
    CASE
      WHEN r.nr_macro_gruppo IS NULL THEN 0::bigint
      ELSE COALESCE(r.id_anag_macro_gruppo, -1::bigint)
    END AS id_anag_macro_gruppo,

    substr(btrim(r.cd_codice_completo::text), 7)::varchar(70)
        AS cd_codice_completo,
    r.cd_categoria_articolo,
    r.cd_subarticolo,
    r.ds_unita_misura_de,
    r.id_sorgente_categoria,
    r.id_sorgente_pubblicazione_articoli,

    r.nr_prezzo,
    r.nr_prezzo_annuo,
    r.nr_perc_spese,
    r.nr_perc_utile,
    r.nr_sicur,
    r.nr_perc_manodopera,
    r.nr_perc_oneri,
    r.nr_prezzo_manodopera,
    r.nr_perc_manodopera_dir,
    r.nr_prezzo_manodopera_dir,
    r.nr_spese,
    r.nr_utili,
    r.fl_isanalisi,
    r.fl_is_minuteria,
    r.fl_ifc_scaricabile,
    r.id_sorgente_provincia,
    r.ds_anno_pubblicazione,
    r.cd_versione,
    r.cd_articolo,
    r.cd_articolo_normalizzato,
    r.cd_tipologia_lookup,
    r.cd_capitolo_lookup,
    r.cd_sottocapitolo_lookup,
    r.cd_titolo,
    r.cd_capitolo,
    r.cd_sottocapitolo,
    r.cd_unita_misura,
    r.nr_macro_gruppo,

    NULLIF(concat_ws('; ',
        CASE WHEN r.id_periodo IS NULL
             THEN 'FK DIM_PERIODO non risolta: applicato -1' END,
        CASE WHEN r.cd_provincia IS NULL
             THEN 'DWH_ANAG_PROVINCIA non risolta' END,
        CASE WHEN r.id_anag_provincia IS NULL
             THEN 'FK DIM_PROVINCIA non risolta: applicato -1' END,
        CASE WHEN r.id_anag_versione IS NULL
             THEN 'FK DIM_VERSIONE non risolta: applicato -1' END,
        CASE WHEN r.id_anag_articolo IS NULL
             THEN 'FK DIM_ARTICOLO non risolta: applicato -1' END,
        CASE WHEN NULLIF(btrim(r.cd_titolo::text), '') IS NOT NULL
                   AND r.id_anag_tipologia IS NULL
             THEN 'FK DIM_TIPOLOGIA non risolta: applicato -1' END,
        CASE WHEN NULLIF(btrim(r.cd_capitolo::text), '') IS NOT NULL
                   AND r.id_anag_capitolo IS NULL
             THEN 'FK DIM_CAPITOLO non risolta: applicato -1' END,
        CASE WHEN NULLIF(btrim(r.cd_sottocapitolo::text), '') IS NOT NULL
                   AND r.id_anag_sottocapitolo IS NULL
             THEN 'FK DIM_SOTTOCAPITOLO non risolta: applicato -1' END,
        CASE WHEN NULLIF(btrim(r.cd_unita_misura::text), '') IS NOT NULL
                   AND r.id_anag_unita_misura IS NULL
             THEN 'FK DIM_UNITA_MISURA non risolta: applicato -1' END,
        CASE WHEN r.nr_macro_gruppo IS NOT NULL
                   AND r.dwh_id_anag_macro_gruppo IS NULL
             THEN 'DWH_ANAG_MACRO_GRUPPO non risolta' END,
        CASE WHEN r.nr_macro_gruppo IS NOT NULL
                   AND r.id_anag_macro_gruppo IS NULL
             THEN 'FK DIM_MACRO_GRUPPO non risolta: applicato -1' END
    ), '')::varchar(4000) AS tx_motivo_lookup
FROM resolved AS r;

ALTER VIEW hcbi_ras.v_fct_pubblicazione_articoli_src OWNER TO hcbi_ras;
GRANT SELECT ON hcbi_ras.v_fct_pubblicazione_articoli_src
TO hcbi_ras, hcbi_utility;

COMMENT ON VIEW hcbi_ras.v_fct_pubblicazione_articoli_src IS
'Vista set-based di risoluzione delle FK per FCT_PUBBLICAZIONE_ARTICOLI; usa 0 per attributi condizionali nulli e -1 per lookup valorizzati ma non risolti.';

/* =====================================================================
   PROCEDURA INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pubblicazione_articoli_prc_initialize(
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
        p_ds_step_name
    ) INTO v_id_log;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',
        clock_timestamp()::timestamp,p_ds_step_name
    );

    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,
                'FAILED',
                left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM,4000),
                clock_timestamp()::timestamp,
                p_ds_step_name
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging FCT_PUBBLICAZIONE_ARTICOLI: %', SQLERRM;
        END;
    END IF;
    RAISE WARNING
        'Errore initialize FCT_PUBBLICAZIONE_ARTICOLI: SQLSTATE=%, errore=%',
        SQLSTATE,SQLERRM;
END;
$BODY$;

/* =====================================================================
   PROCEDURA MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pubblicazione_articoli_prc_main(
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
    v_duplicate_rows bigint := 0;
BEGIN
    p_result := -1;

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    ) INTO v_id_log;

    IF NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_periodo WHERE id_periodo = -1)
       OR NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_provincia WHERE id_anag_provincia = -1)
       OR NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_versione WHERE id_anag_versione = -1)
       OR NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_articolo WHERE id_anag_articolo = -1)
       OR NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_tipologia WHERE id_anag_tipologia = -1)
       OR NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_tipologia WHERE id_anag_tipologia = 0)
       OR NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_capitolo WHERE id_anag_capitolo = -1)
       OR NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_capitolo WHERE id_anag_capitolo = 0)
       OR NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_sottocapitolo WHERE id_anag_sottocapitolo = -1)
       OR NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_sottocapitolo WHERE id_anag_sottocapitolo = 0)
       OR NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_unita_misura WHERE id_anag_unita_misura = -1)
       OR NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_unita_misura WHERE id_anag_unita_misura = 0)
       OR NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_macro_gruppo WHERE id_anag_macro_gruppo = -1)
       OR NOT EXISTS
       (SELECT 1 FROM hcbi_ras.dim_macro_gruppo WHERE id_anag_macro_gruppo = 0)
    THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'Membri tecnici richiesti mancanti nelle dimensioni referenziate',
            HINT = 'Verificare -1 nelle dimensioni obbligatorie e -1/0 nelle dimensioni condizionali.';
    END IF;

    /* Controlli di determinismo delle lookup e del contesto Provincia. */
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_anag_provincia
        WHERE id_sorgente_provincia IS NOT NULL
        GROUP BY anno,cd_versione,id_sorgente_provincia
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DWH_ANAG_PROVINCIA non deterministica',
            DETAIL='Duplicati su anno, cd_versione e id_sorgente_provincia.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_provincia
        WHERE cd_provincia IS NOT NULL
        GROUP BY anno,cd_versione,cd_provincia
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
            MESSAGE='Lookup DIM_PERIODO non deterministica';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_versione
        GROUP BY id_periodo_pubblicazione,cd_versione,id_anag_provincia
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_VERSIONE non deterministica';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dim_articolo
        GROUP BY id_periodo_pubblicazione,cd_articolo,id_anag_versione,id_anag_provincia
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Lookup DIM_ARTICOLO non deterministica';
    END IF;

    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_pubblicazione_articoli
        WHERE id_sorgente_provincia IS NULL
           OR ds_anno_pubblicazione IS NULL
           OR cd_versione IS NULL
    ) THEN
        RAISE EXCEPTION USING ERRCODE='23502',
            MESSAGE='Contesto Provincia incompleto in DWH_PUBBLICAZIONE_ARTICOLI',
            DETAIL='ID_SORGENTE_PROVINCIA, DS_ANNO_PUBBLICAZIONE e CD_VERSIONE sono obbligatori.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM hcbi_ras.dwh_pubblicazione_articoli
        WHERE cd_versione IS NOT NULL
          AND (cd_versione::numeric < -32768 OR cd_versione::numeric > 32767)
    ) THEN
        RAISE EXCEPTION USING ERRCODE='22003',
            MESSAGE='CD_VERSIONE fuori dominio SMALLINT in DWH_PUBBLICAZIONE_ARTICOLI',
            DETAIL='CD_VERSIONE deve rientrare nel dominio SMALLINT della Provincia.';
    END IF;

    DROP TABLE IF EXISTS hcbi_ras.tmp_fct_pubblicazione_articoli_src;

    CREATE TABLE hcbi_ras.tmp_fct_pubblicazione_articoli_src AS
    SELECT
        id_pubblicazione_articoli,
        id_periodo_pubblicazione,
        id_anag_provincia,
        id_anag_versione,
        id_anag_articolo,
        id_anag_tipologia,
        id_anag_capitolo,
        id_anag_sottocapitolo,
        id_anag_unita_misura,
        id_anag_macro_gruppo,
        cd_codice_completo,
        cd_categoria_articolo,
        cd_subarticolo,
        ds_unita_misura_de,
        id_sorgente_categoria,
        id_sorgente_pubblicazione_articoli,
        nr_prezzo,
        nr_prezzo_annuo,
        nr_perc_spese,
        nr_perc_utile,
        nr_sicur,
        nr_perc_manodopera,
        nr_perc_oneri,
        nr_prezzo_manodopera,
        nr_perc_manodopera_dir,
        nr_prezzo_manodopera_dir,
        nr_spese,
        nr_utili,
        fl_isanalisi,
        fl_is_minuteria,
        fl_ifc_scaricabile,
        tx_motivo_lookup
    FROM hcbi_ras.v_fct_pubblicazione_articoli_src;

    SELECT count(1)
    INTO v_selected
    FROM hcbi_ras.dwh_pubblicazione_articoli;

    SELECT count(1)
    INTO v_duplicate_rows
    FROM
    (
        SELECT id_pubblicazione_articoli
        FROM hcbi_ras.tmp_fct_pubblicazione_articoli_src
        GROUP BY id_pubblicazione_articoli
        HAVING count(1) > 1
    ) AS duplicati;

    IF v_duplicate_rows > 0 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = format(
                'Lookup non univoci per %s record PUBBLICAZIONE_ARTICOLI',
                v_duplicate_rows
            ),
            HINT = 'Verificare le UK delle dimensioni e i raccordi della vista sorgente.';
    END IF;

    IF v_selected <>
       (SELECT count(1) FROM hcbi_ras.tmp_fct_pubblicazione_articoli_src)
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'La vista di lookup ha alterato la cardinalita sorgente';
    END IF;

    SELECT count(1)
    INTO v_errors
    FROM hcbi_ras.tmp_fct_pubblicazione_articoli_src
    WHERE tx_motivo_lookup IS NOT NULL;

    SELECT count(1)
    INTO v_inserted
    FROM hcbi_ras.tmp_fct_pubblicazione_articoli_src AS src
    LEFT JOIN hcbi_ras.fct_pubblicazione_articoli AS f
      ON f.id_pubblicazione_articoli = src.id_pubblicazione_articoli
    WHERE f.id_pubblicazione_articoli IS NULL;

    SELECT count(1)
    INTO v_updated
    FROM hcbi_ras.tmp_fct_pubblicazione_articoli_src AS src
    JOIN hcbi_ras.fct_pubblicazione_articoli AS f
      ON f.id_pubblicazione_articoli = src.id_pubblicazione_articoli
    WHERE ROW(
        f.id_periodo_pubblicazione,
        f.id_anag_provincia,
        f.id_anag_versione,
        f.id_anag_articolo,
        f.id_anag_tipologia,
        f.id_anag_capitolo,
        f.id_anag_sottocapitolo,
        f.id_anag_unita_misura,
        f.id_anag_macro_gruppo,
        f.cd_codice_completo,
        f.cd_categoria_articolo,
        f.cd_subarticolo,
        f.ds_unita_misura_de,
        f.id_sorgente_categoria,
        f.id_sorgente_pubblicazione_articoli,
        f.nr_prezzo,
        f.nr_prezzo_annuo,
        f.nr_perc_spese,
        f.nr_perc_utile,
        f.nr_sicur,
        f.nr_perc_manodopera,
        f.nr_perc_oneri,
        f.nr_prezzo_manodopera,
        f.nr_perc_manodopera_dir,
        f.nr_prezzo_manodopera_dir,
        f.nr_spese,
        f.nr_utili,
        f.fl_isanalisi,
        f.fl_is_minuteria,
        f.fl_ifc_scaricabile
    ) IS DISTINCT FROM ROW(
        src.id_periodo_pubblicazione,
        src.id_anag_provincia,
        src.id_anag_versione,
        src.id_anag_articolo,
        src.id_anag_tipologia,
        src.id_anag_capitolo,
        src.id_anag_sottocapitolo,
        src.id_anag_unita_misura,
        src.id_anag_macro_gruppo,
        src.cd_codice_completo,
        src.cd_categoria_articolo,
        src.cd_subarticolo,
        src.ds_unita_misura_de,
        src.id_sorgente_categoria,
        src.id_sorgente_pubblicazione_articoli,
        src.nr_prezzo,
        src.nr_prezzo_annuo,
        src.nr_perc_spese,
        src.nr_perc_utile,
        src.nr_sicur,
        src.nr_perc_manodopera,
        src.nr_perc_oneri,
        src.nr_prezzo_manodopera,
        src.nr_perc_manodopera_dir,
        src.nr_prezzo_manodopera_dir,
        src.nr_spese,
        src.nr_utili,
        src.fl_isanalisi,
        src.fl_is_minuteria,
        src.fl_ifc_scaricabile
    );

    INSERT INTO hcbi_ras.fct_pubblicazione_articoli AS f
    (
        id_pubblicazione_articoli,
        id_periodo_pubblicazione,
        id_anag_provincia,
        id_anag_versione,
        id_anag_articolo,
        id_anag_tipologia,
        id_anag_capitolo,
        id_anag_sottocapitolo,
        id_anag_unita_misura,
        id_anag_macro_gruppo,
        cd_codice_completo,
        cd_categoria_articolo,
        cd_subarticolo,
        ds_unita_misura_de,
        id_sorgente_categoria,
        id_sorgente_pubblicazione_articoli,
        nr_prezzo,
        nr_prezzo_annuo,
        nr_perc_spese,
        nr_perc_utile,
        nr_sicur,
        nr_perc_manodopera,
        nr_perc_oneri,
        nr_prezzo_manodopera,
        nr_perc_manodopera_dir,
        nr_prezzo_manodopera_dir,
        nr_spese,
        nr_utili,
        fl_isanalisi,
        fl_is_minuteria,
        fl_ifc_scaricabile,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_pubblicazione_articoli,
        src.id_periodo_pubblicazione,
        src.id_anag_provincia,
        src.id_anag_versione,
        src.id_anag_articolo,
        src.id_anag_tipologia,
        src.id_anag_capitolo,
        src.id_anag_sottocapitolo,
        src.id_anag_unita_misura,
        src.id_anag_macro_gruppo,
        src.cd_codice_completo,
        src.cd_categoria_articolo,
        src.cd_subarticolo,
        src.ds_unita_misura_de,
        src.id_sorgente_categoria,
        src.id_sorgente_pubblicazione_articoli,
        src.nr_prezzo,
        src.nr_prezzo_annuo,
        src.nr_perc_spese,
        src.nr_perc_utile,
        src.nr_sicur,
        src.nr_perc_manodopera,
        src.nr_perc_oneri,
        src.nr_prezzo_manodopera,
        src.nr_perc_manodopera_dir,
        src.nr_prezzo_manodopera_dir,
        src.nr_spese,
        src.nr_utili,
        src.fl_isanalisi,
        src.fl_is_minuteria,
        src.fl_ifc_scaricabile,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_fct_pubblicazione_articoli_src AS src
    ON CONFLICT (id_pubblicazione_articoli) DO UPDATE SET
        id_periodo_pubblicazione = EXCLUDED.id_periodo_pubblicazione,
        id_anag_provincia = EXCLUDED.id_anag_provincia,
        id_anag_versione = EXCLUDED.id_anag_versione,
        id_anag_articolo = EXCLUDED.id_anag_articolo,
        id_anag_tipologia = EXCLUDED.id_anag_tipologia,
        id_anag_capitolo = EXCLUDED.id_anag_capitolo,
        id_anag_sottocapitolo = EXCLUDED.id_anag_sottocapitolo,
        id_anag_unita_misura = EXCLUDED.id_anag_unita_misura,
        id_anag_macro_gruppo = EXCLUDED.id_anag_macro_gruppo,
        cd_codice_completo = EXCLUDED.cd_codice_completo,
        cd_categoria_articolo = EXCLUDED.cd_categoria_articolo,
        cd_subarticolo = EXCLUDED.cd_subarticolo,
        ds_unita_misura_de = EXCLUDED.ds_unita_misura_de,
        id_sorgente_categoria = EXCLUDED.id_sorgente_categoria,
        id_sorgente_pubblicazione_articoli = EXCLUDED.id_sorgente_pubblicazione_articoli,
        nr_prezzo = EXCLUDED.nr_prezzo,
        nr_prezzo_annuo = EXCLUDED.nr_prezzo_annuo,
        nr_perc_spese = EXCLUDED.nr_perc_spese,
        nr_perc_utile = EXCLUDED.nr_perc_utile,
        nr_sicur = EXCLUDED.nr_sicur,
        nr_perc_manodopera = EXCLUDED.nr_perc_manodopera,
        nr_perc_oneri = EXCLUDED.nr_perc_oneri,
        nr_prezzo_manodopera = EXCLUDED.nr_prezzo_manodopera,
        nr_perc_manodopera_dir = EXCLUDED.nr_perc_manodopera_dir,
        nr_prezzo_manodopera_dir = EXCLUDED.nr_prezzo_manodopera_dir,
        nr_spese = EXCLUDED.nr_spese,
        nr_utili = EXCLUDED.nr_utili,
        fl_isanalisi = EXCLUDED.fl_isanalisi,
        fl_is_minuteria = EXCLUDED.fl_is_minuteria,
        fl_ifc_scaricabile = EXCLUDED.fl_ifc_scaricabile,
        dt_update = clock_timestamp(),
        tx_update_by = p_ds_step_name
    WHERE ROW(
        f.id_periodo_pubblicazione,
        f.id_anag_provincia,
        f.id_anag_versione,
        f.id_anag_articolo,
        f.id_anag_tipologia,
        f.id_anag_capitolo,
        f.id_anag_sottocapitolo,
        f.id_anag_unita_misura,
        f.id_anag_macro_gruppo,
        f.cd_codice_completo,
        f.cd_categoria_articolo,
        f.cd_subarticolo,
        f.ds_unita_misura_de,
        f.id_sorgente_categoria,
        f.id_sorgente_pubblicazione_articoli,
        f.nr_prezzo,
        f.nr_prezzo_annuo,
        f.nr_perc_spese,
        f.nr_perc_utile,
        f.nr_sicur,
        f.nr_perc_manodopera,
        f.nr_perc_oneri,
        f.nr_prezzo_manodopera,
        f.nr_perc_manodopera_dir,
        f.nr_prezzo_manodopera_dir,
        f.nr_spese,
        f.nr_utili,
        f.fl_isanalisi,
        f.fl_is_minuteria,
        f.fl_ifc_scaricabile
    ) IS DISTINCT FROM ROW(
        EXCLUDED.id_periodo_pubblicazione,
        EXCLUDED.id_anag_provincia,
        EXCLUDED.id_anag_versione,
        EXCLUDED.id_anag_articolo,
        EXCLUDED.id_anag_tipologia,
        EXCLUDED.id_anag_capitolo,
        EXCLUDED.id_anag_sottocapitolo,
        EXCLUDED.id_anag_unita_misura,
        EXCLUDED.id_anag_macro_gruppo,
        EXCLUDED.cd_codice_completo,
        EXCLUDED.cd_categoria_articolo,
        EXCLUDED.cd_subarticolo,
        EXCLUDED.ds_unita_misura_de,
        EXCLUDED.id_sorgente_categoria,
        EXCLUDED.id_sorgente_pubblicazione_articoli,
        EXCLUDED.nr_prezzo,
        EXCLUDED.nr_prezzo_annuo,
        EXCLUDED.nr_perc_spese,
        EXCLUDED.nr_perc_utile,
        EXCLUDED.nr_sicur,
        EXCLUDED.nr_perc_manodopera,
        EXCLUDED.nr_perc_oneri,
        EXCLUDED.nr_prezzo_manodopera,
        EXCLUDED.nr_perc_manodopera_dir,
        EXCLUDED.nr_prezzo_manodopera_dir,
        EXCLUDED.nr_spese,
        EXCLUDED.nr_utili,
        EXCLUDED.fl_isanalisi,
        EXCLUDED.fl_is_minuteria,
        EXCLUDED.fl_ifc_scaricabile
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
        p_ds_step_name
    );

    DROP TABLE hcbi_ras.tmp_fct_pubblicazione_articoli_src;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    BEGIN
        DROP TABLE IF EXISTS hcbi_ras.tmp_fct_pubblicazione_articoli_src;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;

    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,
                'FAILED',
                left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM,4000),
                clock_timestamp()::timestamp,
                p_ds_step_name
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging FCT_PUBBLICAZIONE_ARTICOLI: %', SQLERRM;
        END;
    END IF;

    RAISE WARNING
        'Errore main FCT_PUBBLICAZIONE_ARTICOLI: SQLSTATE=%, errore=%',
        SQLSTATE,SQLERRM;
END;
$BODY$;

/* =====================================================================
   PROCEDURA FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pubblicazione_articoli_prc_finalize(
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
        p_ds_step_name
    ) INTO v_id_log;

    ANALYZE hcbi_ras.fct_pubblicazione_articoli;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,0,0,0,0,0,'SUCCESS',
        clock_timestamp()::timestamp,p_ds_step_name
    );

    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,
                'FAILED',
                left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM,4000),
                clock_timestamp()::timestamp,
                p_ds_step_name
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore logging FCT_PUBBLICAZIONE_ARTICOLI: %', SQLERRM;
        END;
    END IF;
    RAISE WARNING
        'Errore finalize FCT_PUBBLICAZIONE_ARTICOLI: SQLSTATE=%, errore=%',
        SQLSTATE,SQLERRM;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_fct_pubblicazione_articoli_prc_initialize(
    bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_fct_pubblicazione_articoli_prc_main(
    bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;
ALTER PROCEDURE hcbi_ras.pkg_fct_pubblicazione_articoli_prc_finalize(
    bigint,bigint,bigint,varchar) OWNER TO hcbi_ras;

GRANT EXECUTE ON PROCEDURE
hcbi_ras.pkg_fct_pubblicazione_articoli_prc_initialize(
    bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE
hcbi_ras.pkg_fct_pubblicazione_articoli_prc_main(
    bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;
GRANT EXECUTE ON PROCEDURE
hcbi_ras.pkg_fct_pubblicazione_articoli_prc_finalize(
    bigint,bigint,bigint,varchar) TO hcbi_ras,hcbi_utility;

/* =====================================================================
   TEST POST-DEPLOYMENT
   ===================================================================== */

/* T01 - PK della fact. Atteso: ID_PUBBLICAZIONE_ARTICOLI. */
-- SELECT
--     att.attname AS pk_column
-- FROM pg_catalog.pg_constraint AS con
-- JOIN pg_catalog.pg_class AS rel
--   ON rel.oid = con.conrelid
-- JOIN pg_catalog.pg_namespace AS ns
--   ON ns.oid = rel.relnamespace
-- CROSS JOIN LATERAL unnest(con.conkey)
--     WITH ORDINALITY AS key_col(attnum, ordinality)
-- JOIN pg_catalog.pg_attribute AS att
--   ON att.attrelid = rel.oid
--  AND att.attnum = key_col.attnum
-- WHERE ns.nspname = 'hcbi_ras'
--   AND rel.relname = 'fct_pubblicazione_articoli'
--   AND con.contype = 'p'
-- ORDER BY key_col.ordinality;

/* T02 - Duplicati nella sorgente sulla PK. Atteso: zero righe. */
-- SELECT
--     id_pubblicazione_articoli,
--     count(1) AS nr_righe
-- FROM hcbi_ras.dwh_pubblicazione_articoli
-- GROUP BY id_pubblicazione_articoli
-- HAVING count(1) > 1;

/* T03 - Cardinalita vista sorgente. Atteso: conteggi uguali. */
-- SELECT
--     (SELECT count(1)
--      FROM hcbi_ras.dwh_pubblicazione_articoli) AS nr_dwh,
--     (SELECT count(1)
--      FROM hcbi_ras.v_fct_pubblicazione_articoli_src) AS nr_vista;

/* T04 - Chiavi DWH non caricate nella fact. Atteso: zero. */
-- SELECT count(1) AS chiavi_non_caricate
-- FROM hcbi_ras.dwh_pubblicazione_articoli AS src
-- LEFT JOIN hcbi_ras.fct_pubblicazione_articoli AS f
--   ON f.id_pubblicazione_articoli = src.id_pubblicazione_articoli
-- WHERE f.id_pubblicazione_articoli IS NULL;

/* T05 - Orfani FK. Atteso: zero. */
-- SELECT count(1) AS record_orfani
-- FROM hcbi_ras.fct_pubblicazione_articoli AS f
-- LEFT JOIN hcbi_ras.dim_periodo AS per
--   ON per.id_periodo = f.id_periodo_pubblicazione
-- LEFT JOIN hcbi_ras.dim_provincia AS prv
--   ON prv.id_anag_provincia = f.id_anag_provincia
-- LEFT JOIN hcbi_ras.dim_versione AS ver
--   ON ver.id_anag_versione = f.id_anag_versione
-- LEFT JOIN hcbi_ras.dim_articolo AS art
--   ON art.id_anag_articolo = f.id_anag_articolo
-- LEFT JOIN hcbi_ras.dim_tipologia AS tip
--   ON tip.id_anag_tipologia = f.id_anag_tipologia
-- LEFT JOIN hcbi_ras.dim_capitolo AS cap
--   ON cap.id_anag_capitolo = f.id_anag_capitolo
-- LEFT JOIN hcbi_ras.dim_sottocapitolo AS sot
--   ON sot.id_anag_sottocapitolo = f.id_anag_sottocapitolo
-- LEFT JOIN hcbi_ras.dim_unita_misura AS um
--   ON um.id_anag_unita_misura = f.id_anag_unita_misura
-- LEFT JOIN hcbi_ras.dim_macro_gruppo AS mg
--   ON mg.id_anag_macro_gruppo = f.id_anag_macro_gruppo
-- WHERE per.id_periodo IS NULL
--    OR prv.id_anag_provincia IS NULL
--    OR ver.id_anag_versione IS NULL
--    OR art.id_anag_articolo IS NULL
--    OR tip.id_anag_tipologia IS NULL
--    OR cap.id_anag_capitolo IS NULL
--    OR sot.id_anag_sottocapitolo IS NULL
--    OR um.id_anag_unita_misura IS NULL
--    OR mg.id_anag_macro_gruppo IS NULL;

/* T06 - Lookup non risolti. Informativo. */
-- SELECT
--     count(1) FILTER (WHERE id_periodo_pubblicazione = -1) AS periodo_nd,
--     count(1) FILTER (WHERE id_anag_provincia = -1) AS provincia_nd,
--     count(1) FILTER (WHERE id_anag_versione = -1) AS versione_nd,
--     count(1) FILTER (WHERE id_anag_articolo = -1) AS articolo_nd,
--     count(1) FILTER (WHERE id_anag_tipologia = -1) AS tipologia_nd,
--     count(1) FILTER (WHERE id_anag_capitolo = -1) AS capitolo_nd,
--     count(1) FILTER (WHERE id_anag_sottocapitolo = -1) AS sottocapitolo_nd,
--     count(1) FILTER (WHERE id_anag_unita_misura = -1) AS unita_misura_nd,
--     count(1) FILTER (WHERE id_anag_macro_gruppo = -1) AS macro_gruppo_nd
-- FROM hcbi_ras.fct_pubblicazione_articoli;

/* T07 - Regressione specifica del dataset di collaudo sui record verificati.
   Atteso: TX_MOTIVO_LOOKUP NULL per tutte le righe. */
-- SELECT
--     id_pubblicazione_articoli,
--     id_periodo_pubblicazione,
--     id_anag_provincia,
--     id_anag_versione,
--     id_anag_articolo,
--     id_anag_tipologia,
--     id_anag_capitolo,
--     id_anag_sottocapitolo,
--     id_anag_unita_misura,
--     id_anag_macro_gruppo,
--     tx_motivo_lookup
-- FROM hcbi_ras.v_fct_pubblicazione_articoli_src
-- WHERE id_pubblicazione_articoli IN
--       (1,2,71,5609,10588,10597,24718,30449,30501)
-- ORDER BY id_pubblicazione_articoli;

/* T08 - Test specifico del dataset di collaudo: valori attesi per le quattro FK principali. */
-- SELECT
--     id_pubblicazione_articoli,
--     id_periodo_pubblicazione,
--     id_anag_provincia,
--     id_anag_versione,
--     id_anag_articolo
-- FROM hcbi_ras.v_fct_pubblicazione_articoli_src
-- WHERE (id_pubblicazione_articoli = 1
--        AND ROW(id_periodo_pubblicazione,id_anag_provincia,
--                id_anag_versione,id_anag_articolo)
--            IS DISTINCT FROM ROW(8,0::bigint,1::bigint,4::bigint))
--    OR (id_pubblicazione_articoli = 2
--        AND ROW(id_periodo_pubblicazione,id_anag_provincia,
--                id_anag_versione,id_anag_articolo)
--            IS DISTINCT FROM ROW(8,0::bigint,1::bigint,5::bigint))
--    OR (id_pubblicazione_articoli = 71
--        AND ROW(id_periodo_pubblicazione,id_anag_provincia,
--                id_anag_versione,id_anag_articolo)
--            IS DISTINCT FROM ROW(8,0::bigint,1::bigint,107::bigint))
--    OR (id_pubblicazione_articoli = 24718
--        AND ROW(id_periodo_pubblicazione,id_anag_provincia,
--                id_anag_versione,id_anag_articolo)
--            IS DISTINCT FROM ROW(9,0::bigint,3::bigint,27872::bigint));

/* T09 - Test specifico del dataset di collaudo: macro-gruppo verificato. */
-- SELECT
--     id_pubblicazione_articoli,
--     id_anag_macro_gruppo
-- FROM hcbi_ras.v_fct_pubblicazione_articoli_src
-- WHERE id_pubblicazione_articoli IN
--       (1,2,71,5609,10588,10597,24718,30449,30501)
--   AND id_anag_macro_gruppo <> 1;

/* T10 - Test specifico del dataset di collaudo: unita di misura verificata.
   Atteso: 24718->39, 30449->24, 30501->6. */
-- SELECT
--     id_pubblicazione_articoli,
--     id_anag_unita_misura
-- FROM hcbi_ras.v_fct_pubblicazione_articoli_src
-- WHERE (id_pubblicazione_articoli = 24718
--        AND id_anag_unita_misura <> 39)
--    OR (id_pubblicazione_articoli = 30449
--        AND id_anag_unita_misura <> 24)
--    OR (id_pubblicazione_articoli = 30501
--        AND id_anag_unita_misura <> 6);

/* T11 - Test specifico del dataset di collaudo: unita di misura nulla/non valorizzata.
   Atteso per i casi indicati: ID_ANAG_UNITA_MISURA = 0. */
-- SELECT
--     id_pubblicazione_articoli,
--     id_anag_unita_misura
-- FROM hcbi_ras.v_fct_pubblicazione_articoli_src
-- WHERE id_pubblicazione_articoli IN (1,2,71,5609,10588,10597)
--   AND id_anag_unita_misura <> 0;

/* T12 - Idempotenza.
   Rilanciare INITIALIZE, MAIN e FINALIZE senza modifiche DWH.
   Atteso nel log MAIN: inserted=0 e updated=0. */

/* T13 - Test specifico del dataset di collaudo: gerarchia di classificazione. */
-- SELECT id_pubblicazione_articoli,
--        id_anag_tipologia,
--        id_anag_capitolo,
--        id_anag_sottocapitolo
-- FROM hcbi_ras.v_fct_pubblicazione_articoli_src
-- WHERE (id_pubblicazione_articoli = 1
--        AND ROW(id_anag_tipologia,id_anag_capitolo,id_anag_sottocapitolo)
--            IS DISTINCT FROM ROW(1::bigint,1::bigint,1::bigint))
--    OR (id_pubblicazione_articoli = 2
--        AND ROW(id_anag_tipologia,id_anag_capitolo,id_anag_sottocapitolo)
--            IS DISTINCT FROM ROW(1::bigint,1::bigint,1::bigint))
--    OR (id_pubblicazione_articoli = 71
--        AND ROW(id_anag_tipologia,id_anag_capitolo,id_anag_sottocapitolo)
--            IS DISTINCT FROM ROW(2::bigint,4::bigint,26::bigint))
--    OR (id_pubblicazione_articoli = 5609
--        AND ROW(id_anag_tipologia,id_anag_capitolo,id_anag_sottocapitolo)
--            IS DISTINCT FROM ROW(3::bigint,19::bigint,182::bigint))
--    OR (id_pubblicazione_articoli = 10588
--        AND ROW(id_anag_tipologia,id_anag_capitolo,id_anag_sottocapitolo)
--            IS DISTINCT FROM ROW(4::bigint,99::bigint,567::bigint))
--    OR (id_pubblicazione_articoli = 10597
--        AND ROW(id_anag_tipologia,id_anag_capitolo,id_anag_sottocapitolo)
--            IS DISTINCT FROM ROW(5::bigint,101::bigint,570::bigint))
--    OR (id_pubblicazione_articoli = 24718
--        AND ROW(id_anag_tipologia,id_anag_capitolo,id_anag_sottocapitolo)
--            IS DISTINCT FROM ROW(11::bigint,327::bigint,1635::bigint))
--    OR (id_pubblicazione_articoli = 30449
--        AND ROW(id_anag_tipologia,id_anag_capitolo,id_anag_sottocapitolo)
--            IS DISTINCT FROM ROW(12::bigint,342::bigint,1793::bigint))
--    OR (id_pubblicazione_articoli = 30501
--        AND ROW(id_anag_tipologia,id_anag_capitolo,id_anag_sottocapitolo)
--            IS DISTINCT FROM ROW(12::bigint,342::bigint,1794::bigint));

/* T14 - Business key sorgente contestualizzata. Atteso: zero righe. */
-- SELECT id_sorgente_provincia,ds_anno_pubblicazione,cd_versione,
--        cd_codice_completo,count(*)
-- FROM hcbi_ras.dwh_pubblicazione_articoli
-- GROUP BY id_sorgente_provincia,ds_anno_pubblicazione,cd_versione,
--          cd_codice_completo
-- HAVING count(*) > 1;

/* T15 - Determinismo chiave operazionale DWH_ANAG_PROVINCIA. Atteso: zero righe. */
-- SELECT anno,cd_versione,id_sorgente_provincia,count(*)
-- FROM hcbi_ras.dwh_anag_provincia
-- WHERE id_sorgente_provincia IS NOT NULL
-- GROUP BY anno,cd_versione,id_sorgente_provincia
-- HAVING count(*) > 1;

/* T16 - Determinismo business key contestualizzata DIM_PROVINCIA. Atteso: zero righe. */
-- SELECT anno,cd_versione,cd_provincia,count(*)
-- FROM hcbi_ras.dim_provincia
-- WHERE cd_provincia IS NOT NULL
-- GROUP BY anno,cd_versione,cd_provincia
-- HAVING count(*) > 1;

/* T17 - Lookup Provincia non risolte. Atteso: zero righe. */
-- SELECT src.id_pubblicazione_articoli,src.ds_anno_pubblicazione,
--        src.cd_versione,src.id_sorgente_provincia,
--        dwh_prv.id_anag_provincia AS id_anag_provincia_dwh,
--        dwh_prv.cd_provincia
-- FROM hcbi_ras.dwh_pubblicazione_articoli AS src
-- LEFT JOIN hcbi_ras.dwh_anag_provincia AS dwh_prv
--   ON dwh_prv.anno=src.ds_anno_pubblicazione::integer
--  AND dwh_prv.cd_versione=src.cd_versione::smallint
--  AND dwh_prv.id_sorgente_provincia=src.id_sorgente_provincia::bigint
-- LEFT JOIN hcbi_ras.dim_provincia AS prv
--   ON prv.id_anag_provincia=dwh_prv.id_anag_provincia
--  AND prv.anno=dwh_prv.anno
--  AND prv.cd_versione=dwh_prv.cd_versione
-- WHERE prv.id_anag_provincia IS NULL;

/* =====================================================================
   DEPLOYMENT
   Prerequisiti:
     1. DIM_PERIODO
     2. DIM_PROVINCIA
     3. DIM_VERSIONE
     4. DIM_ARTICOLO
     5. DIM_TIPOLOGIA
     6. DIM_CAPITOLO
     7. DIM_SOTTOCAPITOLO
     8. DIM_UNITA_MISURA
     9. DIM_MACRO_GRUPPO
    10. DWH_ANAG_PROVINCIA
    11. DWH_ANAG_MACRO_GRUPPO
    12. DWH_PUBBLICAZIONE_ARTICOLI

   Verifiche pre-deploy:
     - backup/restore point secondo procedure operative autorizzate;
     - presenza membri tecnici richiesti;
     - esecuzione test di unicita sulle dimensioni;
     - verifica firme routine di logging HCBI_UTILITY.

   Rollback strutturale, solo previa autorizzazione:
     DROP PROCEDURE delle tre procedure della fact;
     DROP VIEW HCBI_RAS.V_FCT_PUBBLICAZIONE_ARTICOLI_SRC;
     DROP TABLE HCBI_RAS.FCT_PUBBLICAZIONE_ARTICOLI.
   ===================================================================== */
