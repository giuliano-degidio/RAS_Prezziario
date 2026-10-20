/* =====================================================================
   DIM_PROVINCIA - DDL E PROCEDURE DI CARICAMENTO
   Target: PostgreSQL 15.9 / 17

   Schema:
       hcbi_ras

   Sorgenti:
       hcbi_ras.dwh_anag_provincia
       hcbi_ras.dim_area_vasta

   Destinazione:
       hcbi_ras.dim_provincia

   Grain:
       una riga per ID_ANAG_PROVINCIA.

   Chiave primaria:
       id_anag_provincia

   Contesto applicativo:
       anno, cd_versione

   Business key contestualizzata:
       anno, cd_versione, cd_provincia

   Relazione dimensionale:
       dim_provincia.id_area_vasta
           -> dim_area_vasta.id_anag_area_vasta

   Regola di lookup AREA VASTA:
       dwh_anag_provincia.anno
           = dim_area_vasta.anno
       dwh_anag_provincia.cd_versione
           = dim_area_vasta.cd_versione
       dwh_anag_provincia.id_sorgente_area_vasta
           = dim_area_vasta.id_sorgente_area_vasta

       Regola di valorizzazione della FK:
           - se id_sorgente_area_vasta IS NULL:
                 id_area_vasta = 0
           - se id_sorgente_area_vasta e' valorizzato e la lookup trova
             corrispondenza:
                 id_area_vasta = dim_area_vasta.id_anag_area_vasta
           - se id_sorgente_area_vasta e' valorizzato ma la lookup non
             trova corrispondenza:
                 id_area_vasta = -1

       I record tecnici con id_anag_area_vasta = 0 e -1 devono essere
       gia' presenti in hcbi_ras.dim_area_vasta.

   Regole dei record tecnici DIM_PROVINCIA:
       - cd_provincia NULL o vuoto: record ricondotto alla riga tecnica 0,
         codice 'ND' e descrizione 'NON DISPONIBILE';
       - codice valorizzato ma anagrafica non disponibile: riga tecnica -1,
         codice 'AA' e descrizione 'ANAGRAFICA ASSENTE'.
   Strategia di caricamento:
       - inserimento idempotente dei record tecnici 0 e -1;
       - verifica dei record tecnici AREA VASTA 0 e -1;
       - verifica dell'univocita della lookup AREA VASTA;
       - materializzazione della sorgente arricchita;
       - verifica preventiva di primary key e business key;
       - UPDATE dei soli record variati;
       - INSERT dei nuovi record con ON CONFLICT;
       - riconciliazione delle chiavi caricate;
       - diagnostica completa e logging protetto;
       - ANALYZE nella FINALIZE.

   Vincolo operativo:
       la tabella di lavoro ha nome fisso; non e' ammessa
       l'esecuzione concorrente della PRC_MAIN.

   Assunzioni confermate:
       - schema di destinazione: hcbi_ras;
       - id_anag_provincia viene mantenuto dalla sorgente DWH;
       - cd_provincia e' la business key;
       - il record tecnico AREA VASTA per riferimento NULL ha chiave 0;
       - il record tecnico AREA VASTA per lookup non risolta ha chiave -1;
       - non e' richiesta storicizzazione SCD di tipo 2;
       - non sono richieste cancellazioni dei record non piu' presenti;
       - le routine hcbi_utility hanno firme compatibili.
   ===================================================================== */

/* =====================================================================
   TABELLA DIMENSIONALE
   ===================================================================== */
CREATE TABLE IF NOT EXISTS hcbi_ras.dim_provincia
(
    id_anag_provincia bigint NOT NULL,
    anno integer NOT NULL,
    cd_versione smallint NOT NULL,
    cd_provincia character varying(2)
        COLLATE pg_catalog."default" NOT NULL,
    ds_nome character varying(100)
        COLLATE pg_catalog."default" NOT NULL,
    id_area_vasta bigint NOT NULL,
    fl_provincia_principale_regionale smallint NOT NULL,
    fl_provincia_principale_area_vasta smallint NOT NULL,
    dt_creation timestamp without time zone
        NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by character varying(4000)
        COLLATE pg_catalog."default"
        NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone
        NOT NULL DEFAULT clock_timestamp(),
    tx_update_by character varying(4000)
        COLLATE pg_catalog."default"
        NOT NULL DEFAULT CURRENT_USER,

    CONSTRAINT pk_dim_provincia
        PRIMARY KEY (id_anag_provincia),

    CONSTRAINT uq_dim_provincia
        UNIQUE NULLS NOT DISTINCT (anno, cd_versione, cd_provincia),

    CONSTRAINT fk_dim_provincia_area_vasta
        FOREIGN KEY (id_area_vasta)
        REFERENCES hcbi_ras.dim_area_vasta (id_anag_area_vasta)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
)
TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dim_provincia
    OWNER TO hcbi_ras;

REVOKE ALL
ON TABLE hcbi_ras.dim_provincia
FROM hcbi_utility;

GRANT ALL
ON TABLE hcbi_ras.dim_provincia
TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE
ON TABLE hcbi_ras.dim_provincia
TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dim_provincia
IS 'Dimensione delle province alimentata da HCBI_RAS.DWH_ANAG_PROVINCIA.';

COMMENT ON COLUMN hcbi_ras.dim_provincia.id_anag_provincia
IS 'Chiave primaria globale della dimensione, mantenuta dalla chiave DWH sorgente.';

COMMENT ON COLUMN hcbi_ras.dim_provincia.anno
IS 'Anno del contesto applicativo usato per le lookup contestualizzate.';

COMMENT ON COLUMN hcbi_ras.dim_provincia.cd_versione
IS 'Cd_versione del contesto applicativo usato per le lookup contestualizzate.';

COMMENT ON COLUMN hcbi_ras.dim_provincia.cd_provincia
IS 'Codice della provincia; business key contestualizzata con anno e cd_versione.';

COMMENT ON COLUMN hcbi_ras.dim_provincia.ds_nome
IS 'Descrizione della provincia.';

COMMENT ON COLUMN hcbi_ras.dim_provincia.id_area_vasta
IS 'Chiave esterna verso DIM_AREA_VASTA: 0 con riferimento sorgente NULL; -1 con riferimento valorizzato ma non risolto; altrimenti chiave della DIM_AREA_VASTA.';

COMMENT ON COLUMN hcbi_ras.dim_provincia.fl_provincia_principale_regionale
IS 'Indicatore di provincia principale regionale.';

COMMENT ON COLUMN hcbi_ras.dim_provincia.fl_provincia_principale_area_vasta
IS 'Indicatore di provincia principale per area vasta.';

COMMENT ON COLUMN hcbi_ras.dim_provincia.dt_creation
IS 'Timestamp di creazione del record nella dimensione.';

COMMENT ON COLUMN hcbi_ras.dim_provincia.tx_creation_by
IS 'Processo che ha creato il record nella dimensione.';

COMMENT ON COLUMN hcbi_ras.dim_provincia.dt_update
IS 'Timestamp dell''ultimo aggiornamento del record.';

COMMENT ON COLUMN hcbi_ras.dim_provincia.tx_update_by
IS 'Processo che ha eseguito l''ultimo aggiornamento.';

COMMENT ON CONSTRAINT pk_dim_provincia
ON hcbi_ras.dim_provincia
IS 'Chiave primaria della dimensione: id_anag_provincia.';

COMMENT ON CONSTRAINT uq_dim_provincia
ON hcbi_ras.dim_provincia
IS 'Business key contestualizzata della dimensione: anno, cd_versione, cd_provincia.';

COMMENT ON CONSTRAINT fk_dim_provincia_area_vasta
ON hcbi_ras.dim_provincia
IS 'Relazione tra DIM_PROVINCIA e DIM_AREA_VASTA tramite id_area_vasta.';

/* =====================================================================
   RECORD TECNICI DIM_PROVINCIA
   ===================================================================== */
INSERT INTO hcbi_ras.dim_provincia
(id_anag_provincia,anno,cd_versione,cd_provincia,ds_nome,id_area_vasta,
 fl_provincia_principale_regionale,fl_provincia_principale_area_vasta,
 dt_creation,tx_creation_by,dt_update,tx_update_by)
VALUES
(0,0,0,'ND','NON DISPONIBILE',0,0::smallint,0::smallint,
 clock_timestamp(),CURRENT_USER,clock_timestamp(),CURRENT_USER),
(-1,0,0,'AA','ANAGRAFICA ASSENTE',-1,0::smallint,0::smallint,
 clock_timestamp(),CURRENT_USER,clock_timestamp(),CURRENT_USER)
ON CONFLICT ON CONSTRAINT pk_dim_provincia DO NOTHING;

/* =====================================================================
   PROCEDURA INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_provincia_prc_initialize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name character varying,
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

    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
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
    )
    INTO v_id_log;

    /* Nessuna inizializzazione applicativa richiesta. */

    CALL hcbi_utility.pkg_log_prc_update_log(
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

        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
                CASE WHEN nullif(v_sql_detail, '') IS NOT NULL
                    THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
                CASE WHEN nullif(v_sql_hint, '') IS NOT NULL
                    THEN 'HINT=' || left(v_sql_hint, 500) END,
                CASE WHEN nullif(v_sql_context, '') IS NOT NULL
                    THEN 'CONTEXT=' || left(v_sql_context, 800) END
            ),
            4000
        );

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
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
            'Errore in pkg_dim_provincia_prc_initialize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_provincia_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_provincia_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_provincia_prc_initialize(
    bigint,
    bigint,
    bigint,
    character varying
)
IS 'Inizializza il caricamento DIM_PROVINCIA e registra l''esecuzione nel log.';

/* =====================================================================
   PROCEDURA MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_provincia_prc_main(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name character varying,
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
    v_codice_provincia_assente bigint := 0;

    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
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
    )
    INTO v_id_log;

    /*
       Il valore 0 identifica il riferimento AREA VASTA non valorizzato
       nella sorgente. Il valore -1 identifica un riferimento valorizzato
       nella sorgente ma non risolto dalla lookup.
       La FK richiede che entrambi i record tecnici esistano realmente.
    */
    IF NOT EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_area_vasta AS dav
        WHERE dav.id_anag_area_vasta = 0
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico DIM_AREA_VASTA con id_anag_area_vasta = 0 non presente',
                DETAIL =
                    'DIM_PROVINCIA usa id_area_vasta = 0 quando id_sorgente_area_vasta e'' NULL.',
                HINT =
                    'Creare il record tecnico 0 nella DIM_AREA_VASTA prima del caricamento.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_area_vasta AS dav
        WHERE dav.id_anag_area_vasta = -1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '23503',
                MESSAGE =
                    'Record tecnico DIM_AREA_VASTA con id_anag_area_vasta = -1 non presente',
                DETAIL =
                    'DIM_PROVINCIA usa id_area_vasta = -1 quando id_sorgente_area_vasta e'' valorizzato ma la lookup non trova corrispondenza.',
                HINT =
                    'Creare il record tecnico -1 nella DIM_AREA_VASTA prima del caricamento.';
    END IF;

    /*
       La lookup deve essere deterministica. Piu' record DIM_AREA_VASTA
       con lo stesso ID_SORGENTE_AREA_VASTA produrrebbero una duplicazione
       delle righe della provincia.
    */
    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_area_vasta AS dav
        WHERE dav.id_sorgente_area_vasta IS NOT NULL
        GROUP BY dav.anno, dav.cd_versione, dav.id_sorgente_area_vasta
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE =
                    'Lookup DIM_AREA_VASTA non deterministica',
                DETAIL =
                    'Esistono piu record con lo stesso anno, cd_versione e id_sorgente_area_vasta.',
                HINT =
                    'Rimuovere i duplicati o introdurre un vincolo univoco sulla chiave di lookup.';
    END IF;

    SELECT count(*) INTO v_codice_provincia_assente
    FROM hcbi_ras.dwh_anag_provincia AS src
    WHERE nullif(btrim(src.cd_provincia::text),'') IS NULL;
    IF v_codice_provincia_assente > 0 THEN
        RAISE WARNING
            'DIM_PROVINCIA: % record con cd_provincia NULL o vuoto ricondotti al tappo id_anag_provincia=0.',
            v_codice_provincia_assente;
    END IF;
    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_provincia;
    CREATE TABLE hcbi_ras.tmp_dim_provincia AS
    SELECT
        src.id_anag_provincia,
        src.anno,
        src.cd_versione,
        src.cd_provincia,
        src.ds_nome,
        CASE
            WHEN src.id_sorgente_area_vasta IS NULL
                THEN 0::bigint
            WHEN dav.id_anag_area_vasta IS NULL
                THEN (-1)::bigint
            ELSE dav.id_anag_area_vasta
        END AS id_area_vasta,
        src.fl_provincia_principale_regionale,
        src.fl_provincia_principale_area_vasta
    FROM hcbi_ras.dwh_anag_provincia AS src
    LEFT JOIN hcbi_ras.dim_area_vasta AS dav
        ON dav.anno = src.anno
       AND dav.cd_versione = src.cd_versione
       AND dav.id_sorgente_area_vasta = src.id_sorgente_area_vasta
    WHERE nullif(btrim(src.cd_provincia::text),'') IS NOT NULL;

    /* Verifica preventiva della primary key sorgente. */
    CREATE UNIQUE INDEX tmp_dim_provincia_pk
    ON hcbi_ras.tmp_dim_provincia (id_anag_provincia)
    NULLS NOT DISTINCT;

    /* Verifica preventiva della business key sorgente. */
    CREATE UNIQUE INDEX tmp_dim_provincia_bk
    ON hcbi_ras.tmp_dim_provincia (anno, cd_versione, cd_provincia)
    NULLS NOT DISTINCT;

    ANALYZE hcbi_ras.tmp_dim_provincia;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dim_provincia;
    v_rec_errors := v_codice_provincia_assente;

    UPDATE hcbi_ras.dim_provincia AS d
       SET anno = src.anno,
           cd_versione = src.cd_versione,
           cd_provincia = src.cd_provincia,
           ds_nome = src.ds_nome,
           id_area_vasta = src.id_area_vasta,
           fl_provincia_principale_regionale =
               src.fl_provincia_principale_regionale,
           fl_provincia_principale_area_vasta =
               src.fl_provincia_principale_area_vasta,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_provincia AS src
     WHERE d.id_anag_provincia = src.id_anag_provincia
       AND ROW(
            d.anno,
            d.cd_versione,
            d.cd_provincia,
            d.ds_nome,
            d.id_area_vasta,
            d.fl_provincia_principale_regionale,
            d.fl_provincia_principale_area_vasta
       ) IS DISTINCT FROM ROW(
            src.anno,
            src.cd_versione,
            src.cd_provincia,
            src.ds_nome,
            src.id_area_vasta,
            src.fl_provincia_principale_regionale,
            src.fl_provincia_principale_area_vasta
       );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_provincia (
        id_anag_provincia,
        anno,
        cd_versione,
        cd_provincia,
        ds_nome,
        id_area_vasta,
        fl_provincia_principale_regionale,
        fl_provincia_principale_area_vasta,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_anag_provincia,
        src.anno,
        src.cd_versione,
        src.cd_provincia,
        src.ds_nome,
        src.id_area_vasta,
        src.fl_provincia_principale_regionale,
        src.fl_provincia_principale_area_vasta,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dim_provincia AS src
    ON CONFLICT ON CONSTRAINT pk_dim_provincia
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    /*
       Riconciliazione per chiave primaria: tutte le righe sorgente devono
       risultare presenti nella dimensione dopo UPDATE e INSERT.
    */
    SELECT count(*)
    INTO v_matched
    FROM hcbi_ras.dim_provincia AS d
    INNER JOIN hcbi_ras.tmp_dim_provincia AS src
        ON src.id_anag_provincia = d.id_anag_provincia;

    IF v_selected <> v_matched THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = format(
                    'Riconciliazione DIM_PROVINCIA non valida: applicative=%s, matched=%s',
                    v_selected,
                    v_matched
                ),
                DETAIL =
                    'Non tutte le chiavi applicative ID_ANAG_PROVINCIA risultano presenti nella dimensione.';
    END IF;
    IF (v_selected + v_codice_provincia_assente) <>
       (SELECT count(*) FROM hcbi_ras.dwh_anag_provincia) THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE='Riconciliazione sorgente DIM_PROVINCIA non valida';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        (v_selected + v_codice_provincia_assente),
        v_inserted,
        v_updated,
        v_deleted,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_provincia;

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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dim_provincia;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore durante il cleanup: SQLSTATE=%, errore=%',
                    SQLSTATE,
                    SQLERRM;
        END;

        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
                CASE WHEN nullif(v_sql_detail, '') IS NOT NULL
                    THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
                CASE WHEN nullif(v_sql_hint, '') IS NOT NULL
                    THEN 'HINT=' || left(v_sql_hint, 500) END,
                CASE WHEN nullif(v_sql_context, '') IS NOT NULL
                    THEN 'CONTEXT=' || left(v_sql_context, 800) END
            ),
            4000
        );

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
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
            'Errore in pkg_dim_provincia_prc_main. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_provincia_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_provincia_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_provincia_prc_main(
    bigint,
    bigint,
    bigint,
    character varying
)
IS 'Carica DIM_PROVINCIA: cd_provincia NULL o vuoto ricondotto al tappo 0; AREA VASTA NULL posta a 0 e non risolta posta a -1.';

/* =====================================================================
   PROCEDURA FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_provincia_prc_finalize(
    IN p_id_chain_log bigint,
    IN p_id_chain bigint,
    IN p_id_step bigint,
    IN p_ds_step_name character varying,
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

    v_sqlstate text;
    v_sqlerrm text;
    v_sql_detail text;
    v_sql_hint text;
    v_sql_context text;
    v_log_error text;
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
    )
    INTO v_id_log;

    ANALYZE hcbi_ras.dim_provincia;

    CALL hcbi_utility.pkg_log_prc_update_log(
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

        v_log_error := left(
            concat_ws(
                E'\n',
                'SQLSTATE=' || coalesce(v_sqlstate, ''),
                'MESSAGE=' || left(coalesce(v_sqlerrm, ''), 1500),
                CASE WHEN nullif(v_sql_detail, '') IS NOT NULL
                    THEN 'DETAIL=' || left(v_sql_detail, 1000) END,
                CASE WHEN nullif(v_sql_hint, '') IS NOT NULL
                    THEN 'HINT=' || left(v_sql_hint, 500) END,
                CASE WHEN nullif(v_sql_context, '') IS NOT NULL
                    THEN 'CONTEXT=' || left(v_sql_context, 800) END
            ),
            4000
        );

        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.pkg_log_prc_error_update_log(
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
            'Errore in pkg_dim_provincia_prc_finalize. SQLSTATE=%, errore=%',
            v_sqlstate,
            v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_provincia_prc_finalize(
    bigint,
    bigint,
    bigint,
    character varying
)
OWNER TO hcbi_ras;

GRANT EXECUTE
ON PROCEDURE hcbi_ras.pkg_dim_provincia_prc_finalize(
    bigint,
    bigint,
    bigint,
    character varying
)
TO PUBLIC, hcbi_ras, hcbi_utility;

COMMENT ON PROCEDURE hcbi_ras.pkg_dim_provincia_prc_finalize(
    bigint,
    bigint,
    bigint,
    character varying
)
IS 'Finalizza il caricamento DIM_PROVINCIA e aggiorna le statistiche della tabella.';

/* =====================================================================
   TEST DI VERIFICA POST-DEPLOYMENT
   Eseguire in ambiente controllato dopo il deployment.
   ===================================================================== */

/* 0. Verifica record tecnici DIM_PROVINCIA. */
-- SELECT id_anag_provincia,anno,cd_versione,cd_provincia,ds_nome,id_area_vasta
-- FROM hcbi_ras.dim_provincia WHERE id_anag_provincia IN (0,-1);
/* 0B. Codici provincia NULL o vuoti ricondotti al tappo 0. */
-- SELECT count(*) FROM hcbi_ras.dwh_anag_provincia
-- WHERE nullif(btrim(cd_provincia::text),'') IS NULL;
/* 1. Verifica dei record tecnici AREA VASTA. */
-- SELECT *
-- FROM hcbi_ras.dim_area_vasta
-- WHERE id_anag_area_vasta IN (0, -1);

/* 2. Verifica di eventuali chiavi lookup duplicate. */
-- SELECT
--     anno, cd_versione, id_sorgente_area_vasta,
--     count(*) AS numero_record
-- FROM hcbi_ras.dim_area_vasta
-- WHERE id_sorgente_area_vasta IS NOT NULL
-- GROUP BY anno, cd_versione, id_sorgente_area_vasta
-- HAVING count(*) > 1;

/* 3. Verifica dei duplicati sulla business key della dimensione. */
-- SELECT
--     anno, cd_versione, cd_provincia,
--     count(*) AS numero_record
-- FROM hcbi_ras.dim_provincia
-- GROUP BY anno, cd_versione, cd_provincia
-- HAVING count(*) > 1;

/* 4. Verifica degli orfani rispetto a DIM_AREA_VASTA. */
-- SELECT p.*
-- FROM hcbi_ras.dim_provincia AS p
-- LEFT JOIN hcbi_ras.dim_area_vasta AS av
--     ON av.id_anag_area_vasta = p.id_area_vasta
-- WHERE av.id_anag_area_vasta IS NULL;

/* 5. Province con riferimento AREA VASTA non valorizzato. */
-- SELECT count(*) AS province_area_vasta_non_valorizzata
-- FROM hcbi_ras.dim_provincia
-- WHERE id_area_vasta = 0;

/* 6. Province con riferimento AREA VASTA valorizzato ma non risolto. */
-- SELECT count(*) AS province_area_vasta_non_trovata
-- FROM hcbi_ras.dim_provincia
-- WHERE id_area_vasta = -1;

/* 7. Dettaglio delle lookup AREA VASTA non risolte. */
-- SELECT
--     src.id_anag_provincia,
--     src.anno,
--     src.cd_versione,
--     src.cd_provincia,
--     src.id_sorgente_area_vasta
-- FROM hcbi_ras.dwh_anag_provincia AS src
-- LEFT JOIN hcbi_ras.dim_area_vasta AS dav
--     ON dav.anno = src.anno
--    AND dav.cd_versione = src.cd_versione
--    AND dav.id_sorgente_area_vasta = src.id_sorgente_area_vasta
-- WHERE src.id_sorgente_area_vasta IS NOT NULL
--   AND dav.id_anag_area_vasta IS NULL;


/* 8. Verifica univocita della PK globale. */
-- SELECT id_anag_provincia, count(*)
-- FROM hcbi_ras.dim_provincia
-- GROUP BY id_anag_provincia
-- HAVING count(*) > 1;

/* 9. Verifica business key contestualizzata. */
-- SELECT anno, cd_versione, cd_provincia, count(*)
-- FROM hcbi_ras.dim_provincia
-- GROUP BY anno, cd_versione, cd_provincia
-- HAVING count(*) > 1;
