/* =====================================================================
   DIM_UNITA_MISURA - DDL E PROCEDURE DI CARICAMENTO
   Target: PostgreSQL 15.9 / 17
   Pattern: flusso_dim_area_vasta_all_ver_01.sql
   Sorgente: hcbi_ras.dwh_anag_unita_misura
   Destinazione: hcbi_ras.dim_unita_misura
   Grain: una riga per ID_ANAG_UNITA_MISURA.
   Chiave primaria: id_anag_unita_misura
   Business key ereditata: cd_unita_misura
   Strategia: SCD Type 1, nessun delete.
   Assunzioni:
     1. id_anag_unita_misura viene mantenuto uguale alla chiave DWH.
     2. cd_unita_misura resta univoco nella dimensione.
     3. Non e' richiesta storicizzazione SCD Type 2.
     4. Non sono richiesti delete fisici/logici per assenza dalla sorgente.
     5. Le tabelle di lavoro a nome fisso impediscono esecuzioni concorrenti.
   ===================================================================== */

CREATE TABLE IF NOT EXISTS hcbi_ras.dim_unita_misura
(
    id_anag_unita_misura      BIGINT NOT NULL,
    cd_unita_misura           VARCHAR(20) NOT NULL,
    ds_unita_misura           TEXT,
    nr_decimali               NUMERIC(10,0),
    id_sorgente_unita_misura  INTEGER,
    dt_last_update            TIMESTAMP WITHOUT TIME ZONE,
    dt_fine_validita          TIMESTAMP WITHOUT TIME ZONE,
    dt_creation               TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by            VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    dt_update                 TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    tx_update_by              VARCHAR(4000) NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT pk_dim_unita_misura PRIMARY KEY (id_anag_unita_misura),
    CONSTRAINT uq_dim_unita_misura UNIQUE NULLS NOT DISTINCT (cd_unita_misura)
)
TABLESPACE pg_default;
/*riga tappo
INSERT INTO hcbi_ras.dim_unita_misura (id_anag_unita_misura,cd_unita_misura,ds_unita_misura,nr_decimali,id_sorgente_unita_misura,dt_last_update,dt_fine_validita,dt_creation,tx_creation_by,dt_update,tx_update_by) VALUES
	 (-1,'AA','ANAGRAFICA ASSENTE',0,-1,NULL,NULL,'2026-09-24 11:56:24.811273','hcbi_ras','2026-09-24 11:56:24.811279','hcbi_ras');

INSERT INTO hcbi_ras.dim_unita_misura (id_anag_unita_misura,cd_unita_misura,ds_unita_misura,nr_decimali,id_sorgente_unita_misura,dt_last_update,dt_fine_validita,dt_creation,tx_creation_by,dt_update,tx_update_by) VALUES
	 (0,'ND','NON DISPONIBILE',0,0,NULL,NULL,'2026-09-24 11:56:24.811273','hcbi_ras','2026-09-24 11:56:24.811279','hcbi_ras');

fine riga tappo */

ALTER TABLE IF EXISTS hcbi_ras.dim_unita_misura OWNER TO hcbi_ras;
REVOKE ALL ON TABLE hcbi_ras.dim_unita_misura FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.dim_unita_misura TO hcbi_ras;
GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.dim_unita_misura TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dim_unita_misura IS 'Dimensione delle unita di misura alimentata da HCBI_RAS.DWH_ANAG_UNITA_MISURA.';
COMMENT ON COLUMN hcbi_ras.dim_unita_misura.id_anag_unita_misura IS 'Chiave primaria mantenuta dalla chiave DWH sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_unita_misura.cd_unita_misura IS 'Codice unita di misura e business key.';
COMMENT ON COLUMN hcbi_ras.dim_unita_misura.ds_unita_misura IS 'Descrizione dell unita di misura.';
COMMENT ON COLUMN hcbi_ras.dim_unita_misura.nr_decimali IS 'Numero di decimali associato all unita di misura.';
COMMENT ON COLUMN hcbi_ras.dim_unita_misura.id_sorgente_unita_misura IS 'Identificativo nel sistema sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_unita_misura.dt_last_update IS 'Timestamp di ultimo aggiornamento del dato sorgente.';
COMMENT ON COLUMN hcbi_ras.dim_unita_misura.dt_fine_validita IS 'Timestamp di fine validita del dato sorgente.';
COMMENT ON CONSTRAINT pk_dim_unita_misura ON hcbi_ras.dim_unita_misura IS 'Chiave primaria: id_anag_unita_misura.';
COMMENT ON CONSTRAINT uq_dim_unita_misura ON hcbi_ras.dim_unita_misura IS 'Business key: cd_unita_misura.';

/* =====================================================================
   PROCEDURA INITIALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_unita_misura_prc_initialize(
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
    v_selected BIGINT := 0; v_inserted BIGINT := 0; v_updated BIGINT := 0;
    v_deleted BIGINT := 0; v_rec_errors BIGINT := 0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT; v_sql_hint TEXT;
    v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log, p_id_chain, p_id_step, p_ds_step_name,
        clock_timestamp()::TIMESTAMP, clock_timestamp()::TIMESTAMP, p_ds_step_name)
    INTO v_id_log;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log, v_selected, v_inserted, v_updated, v_deleted, v_rec_errors,
        'SUCCESS', clock_timestamp()::TIMESTAMP, p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE, v_sqlerrm=MESSAGE_TEXT,
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
                v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore durante il logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
        END;
    END IF;
    RAISE WARNING 'Errore in pkg_dim_unita_misura_prc_initialize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_unita_misura_prc_initialize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_unita_misura_prc_initialize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_dim_unita_misura_prc_initialize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) IS 'Inizializza il caricamento DIM_UNITA_MISURA e registra l esecuzione nel log.';

/* =====================================================================
   PROCEDURA MAIN
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_unita_misura_prc_main(
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
    v_selected BIGINT := 0; v_inserted BIGINT := 0; v_updated BIGINT := 0;
    v_deleted BIGINT := 0; v_rec_errors BIGINT := 0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT; v_sql_hint TEXT;
    v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_unita_misura;
    CREATE TABLE hcbi_ras.tmp_dim_unita_misura AS
    SELECT
        src.id_anag_unita_misura,
        src.cd_unita_misura,
        src.ds_unita_misura,
        src.nr_decimali,
        src.id_sorgente_unita_misura,
        src.dt_last_update,
        src.dt_fine_validita
    FROM hcbi_ras.dwh_anag_unita_misura AS src;

    CREATE UNIQUE INDEX tmp_dim_unita_misura_pk
        ON hcbi_ras.tmp_dim_unita_misura(id_anag_unita_misura) NULLS NOT DISTINCT;
    CREATE UNIQUE INDEX tmp_dim_unita_misura_bk
        ON hcbi_ras.tmp_dim_unita_misura(cd_unita_misura) NULLS NOT DISTINCT;
    ANALYZE hcbi_ras.tmp_dim_unita_misura;

    SELECT COUNT(*) INTO v_selected FROM hcbi_ras.tmp_dim_unita_misura;

    UPDATE hcbi_ras.dim_unita_misura AS d
       SET cd_unita_misura = src.cd_unita_misura,
           ds_unita_misura = src.ds_unita_misura,
           nr_decimali = src.nr_decimali,
           id_sorgente_unita_misura = src.id_sorgente_unita_misura,
           dt_last_update = src.dt_last_update,
           dt_fine_validita = src.dt_fine_validita,
           dt_update = clock_timestamp(),
           tx_update_by = p_ds_step_name
      FROM hcbi_ras.tmp_dim_unita_misura AS src
     WHERE d.id_anag_unita_misura = src.id_anag_unita_misura
       AND ROW(d.cd_unita_misura,d.ds_unita_misura,d.nr_decimali,
               d.id_sorgente_unita_misura,d.dt_last_update,d.dt_fine_validita)
           IS DISTINCT FROM
           ROW(src.cd_unita_misura,src.ds_unita_misura,src.nr_decimali,
               src.id_sorgente_unita_misura,src.dt_last_update,src.dt_fine_validita);
    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dim_unita_misura(
        id_anag_unita_misura,cd_unita_misura,ds_unita_misura,nr_decimali,
        id_sorgente_unita_misura,dt_last_update,dt_fine_validita,
        dt_creation,tx_creation_by,dt_update,tx_update_by)
    SELECT
        src.id_anag_unita_misura,src.cd_unita_misura,src.ds_unita_misura,
        src.nr_decimali,src.id_sorgente_unita_misura,src.dt_last_update,
        src.dt_fine_validita,clock_timestamp(),p_ds_step_name,
        clock_timestamp(),p_ds_step_name
    FROM hcbi_ras.tmp_dim_unita_misura AS src
    ON CONFLICT ON CONSTRAINT pk_dim_unita_misura DO NOTHING;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    IF v_selected <> (
        SELECT COUNT(*)
        FROM hcbi_ras.dim_unita_misura AS d
        INNER JOIN hcbi_ras.tmp_dim_unita_misura AS src
            ON src.id_anag_unita_misura = d.id_anag_unita_misura)
    THEN
        RAISE EXCEPTION USING ERRCODE='P0001',
            MESSAGE=FORMAT('Riconciliazione DIM_UNITA_MISURA non valida: selected=%s',v_selected),
            DETAIL='Non tutte le chiavi ID_ANAG_UNITA_MISURA della sorgente risultano presenti nella dimensione.';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    DROP TABLE IF EXISTS hcbi_ras.tmp_dim_unita_misura;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
        v_sql_detail=PG_EXCEPTION_DETAIL,v_sql_hint=PG_EXCEPTION_HINT,
        v_sql_context=PG_EXCEPTION_CONTEXT;
    p_result := -1;
    BEGIN DROP TABLE IF EXISTS hcbi_ras.tmp_dim_unita_misura;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Errore durante il cleanup: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
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
                v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore durante il logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
        END;
    END IF;
    RAISE WARNING 'Errore in pkg_dim_unita_misura_prc_main. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_unita_misura_prc_main(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_unita_misura_prc_main(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_dim_unita_misura_prc_main(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) IS 'Materializza DWH_ANAG_UNITA_MISURA, verifica PK e business key, aggiorna i record variati e inserisce i nuovi record in DIM_UNITA_MISURA.';

/* =====================================================================
   PROCEDURA FINALIZE
   ===================================================================== */
CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dim_unita_misura_prc_finalize(
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
    v_selected BIGINT := 0; v_inserted BIGINT := 0; v_updated BIGINT := 0;
    v_deleted BIGINT := 0; v_rec_errors BIGINT := 0;
    v_sqlstate TEXT; v_sqlerrm TEXT; v_sql_detail TEXT; v_sql_hint TEXT;
    v_sql_context TEXT; v_log_error TEXT;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::TIMESTAMP,clock_timestamp()::TIMESTAMP,p_ds_step_name)
    INTO v_id_log;

    ANALYZE hcbi_ras.dim_unita_misura;
    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rec_errors,
        'SUCCESS',clock_timestamp()::TIMESTAMP,p_ds_step_name);
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_sqlstate=RETURNED_SQLSTATE,v_sqlerrm=MESSAGE_TEXT,
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
                v_id_log,'FAILED',v_log_error,clock_timestamp()::TIMESTAMP,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Errore durante il logging: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
        END;
    END IF;
    RAISE WARNING 'Errore in pkg_dim_unita_misura_prc_finalize. SQLSTATE=%, errore=%',v_sqlstate,v_sqlerrm;
END;
$BODY$;

ALTER PROCEDURE hcbi_ras.pkg_dim_unita_misura_prc_finalize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) OWNER TO hcbi_ras;
GRANT EXECUTE ON PROCEDURE hcbi_ras.pkg_dim_unita_misura_prc_finalize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) TO PUBLIC,hcbi_ras,hcbi_utility;
COMMENT ON PROCEDURE hcbi_ras.pkg_dim_unita_misura_prc_finalize(BIGINT,BIGINT,BIGINT,CHARACTER VARYING) IS 'Finalizza il caricamento DIM_UNITA_MISURA e aggiorna le statistiche.';
