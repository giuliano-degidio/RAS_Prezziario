CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pub_art_fascia_prezzo_prc_main(
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
    v_expected bigint := 0;
    v_actual bigint := 0;
    v_open_count integer := 0;
    v_overlap_count bigint := 0;
    v_gap_count bigint := 0;
BEGIN
    p_result := -1;

    PERFORM pg_advisory_xact_lock(
        hashtext('hcbi_ras.fct_pubblicazione_articoli_fascia_prezzo')
    );

    SELECT hcbi_utility.pkg_log_fnc_insert_log(
        p_id_chain_log,
        p_id_chain,
        p_id_step,
        p_ds_step_name,
        clock_timestamp()::timestamp,
        clock_timestamp()::timestamp,
        p_ds_step_name
    ) INTO v_id_log;

    IF NOT EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_fascia_prezzo
        WHERE id_fascia_prezzo = -1
          AND fl_attivo = 1
    ) OR NOT EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_fascia_prezzo
        WHERE id_fascia_prezzo = 0
          AND fl_attivo = 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'Membri tecnici mancanti in DIM_FASCIA_PREZZO';
    END IF;

    SELECT count(*)
    INTO v_open_count
    FROM hcbi_ras.dim_fascia_prezzo
    WHERE id_fascia_prezzo > 0
      AND fl_attivo = 1
      AND nr_limite_superiore IS NULL;

    IF v_open_count <> 1 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Configurazione fascia aperta non valida';
    END IF;

    SELECT count(*)
    INTO v_overlap_count
    FROM hcbi_ras.dim_fascia_prezzo AS a
    JOIN hcbi_ras.dim_fascia_prezzo AS b
      ON a.id_fascia_prezzo < b.id_fascia_prezzo
     AND a.id_fascia_prezzo > 0
     AND b.id_fascia_prezzo > 0
     AND a.fl_attivo = 1
     AND b.fl_attivo = 1
     AND COALESCE(a.nr_limite_superiore,1e30::numeric)
           > b.nr_limite_inferiore
     AND COALESCE(b.nr_limite_superiore,1e30::numeric)
           > a.nr_limite_inferiore;

    IF v_overlap_count > 0 THEN
        RAISE EXCEPTION USING
            ERRCODE = '21000',
            MESSAGE = 'DIM_FASCIA_PREZZO non deterministica',
            DETAIL = 'Sono presenti fasce positive attive sovrapposte.';
    END IF;

    WITH fasce AS
    (
        SELECT
            nr_limite_inferiore,
            nr_limite_superiore,
            lead(nr_limite_inferiore) OVER (
                ORDER BY nr_limite_inferiore
            ) AS limite_successivo
        FROM hcbi_ras.dim_fascia_prezzo
        WHERE id_fascia_prezzo > 0
          AND fl_attivo = 1
    )
    SELECT count(*)
    INTO v_gap_count
    FROM fasce
    WHERE nr_limite_superiore IS NOT NULL
      AND nr_limite_superiore IS DISTINCT FROM limite_successivo;

    IF v_gap_count > 0 OR NOT EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_fascia_prezzo
        WHERE id_fascia_prezzo > 0
          AND fl_attivo = 1
          AND nr_limite_inferiore = 0
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Copertura non continua in DIM_FASCIA_PREZZO';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM hcbi_ras.v_fct_pub_art_fascia_prezzo_src
        GROUP BY id_pubblicazione_articoli
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '21000',
            MESSAGE = 'Vista sorgente non deterministica',
            DETAIL = 'Piu righe per lo stesso ID_PUBBLICAZIONE_ARTICOLI.';
    END IF;

    DROP TABLE IF EXISTS hcbi_ras.tmp_fct_pub_art_fascia_prezzo_src;

    CREATE TABLE hcbi_ras.tmp_fct_pub_art_fascia_prezzo_src AS
    SELECT
        id_pubblicazione_articoli,
        id_fascia_prezzo,
        nr_prezzo,
        tx_motivo_lookup
    FROM hcbi_ras.v_fct_pub_art_fascia_prezzo_src;

    ANALYZE hcbi_ras.tmp_fct_pub_art_fascia_prezzo_src;

    SELECT count(*)
    INTO v_selected
    FROM hcbi_ras.tmp_fct_pub_art_fascia_prezzo_src;

    SELECT count(*)
    INTO v_inserted
    FROM hcbi_ras.tmp_fct_pub_art_fascia_prezzo_src AS src
    LEFT JOIN hcbi_ras.fct_pubblicazione_articoli_fascia_prezzo AS tgt
      ON tgt.id_pubblicazione_articoli = src.id_pubblicazione_articoli
    WHERE tgt.id_pubblicazione_articoli IS NULL;

    SELECT count(*)
    INTO v_updated
    FROM hcbi_ras.tmp_fct_pub_art_fascia_prezzo_src AS src
    JOIN hcbi_ras.fct_pubblicazione_articoli_fascia_prezzo AS tgt
      ON tgt.id_pubblicazione_articoli = src.id_pubblicazione_articoli
    WHERE tgt.id_fascia_prezzo IS DISTINCT FROM src.id_fascia_prezzo;

    SELECT count(*)
    INTO v_errors
    FROM hcbi_ras.tmp_fct_pub_art_fascia_prezzo_src
    WHERE tx_motivo_lookup IS NOT NULL;

    INSERT INTO hcbi_ras.fct_pubblicazione_articoli_fascia_prezzo
    (
        id_pubblicazione_articoli,
        id_fascia_prezzo,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_pubblicazione_articoli,
        src.id_fascia_prezzo,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_fct_pub_art_fascia_prezzo_src AS src
    ON CONFLICT (id_pubblicazione_articoli) DO UPDATE
    SET
        id_fascia_prezzo = EXCLUDED.id_fascia_prezzo,
        dt_update = clock_timestamp(),
        tx_update_by = EXCLUDED.tx_update_by
    WHERE hcbi_ras.fct_pubblicazione_articoli_fascia_prezzo.id_fascia_prezzo
          IS DISTINCT FROM EXCLUDED.id_fascia_prezzo;

    SELECT count(*)
    INTO v_expected
    FROM hcbi_ras.fct_pubblicazione_articoli;

    SELECT count(*)
    INTO v_actual
    FROM hcbi_ras.fct_pubblicazione_articoli_fascia_prezzo;

    IF v_actual <> v_expected THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Riconciliazione non superata',
            DETAIL = format(
                'FCT_PUBBLICAZIONE_ARTICOLI=%s; associazioni=%s.',
                v_expected,
                v_actual
            );
    END IF;

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

    DROP TABLE hcbi_ras.tmp_fct_pub_art_fascia_prezzo_src;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;

    BEGIN
        DROP TABLE IF EXISTS hcbi_ras.tmp_fct_pub_art_fascia_prezzo_src;
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
            RAISE WARNING
                'Errore logging FCT_PUBBLICAZIONE_ARTICOLI_FASCIA_PREZZO: %',
                SQLERRM;
        END;
    END IF;

    RAISE WARNING
        'Errore main FCT_PUBBLICAZIONE_ARTICOLI_FASCIA_PREZZO: SQLSTATE=%, errore=%',
        SQLSTATE,SQLERRM;
END;
$BODY$;
