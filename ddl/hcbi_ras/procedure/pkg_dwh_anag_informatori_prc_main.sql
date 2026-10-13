CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_dwh_anag_informatori_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log      bigint;
    v_selected    bigint := 0;
    v_inserted    bigint := 0;
    v_updated     bigint := 0;
    v_deleted     bigint := 0;
    v_rec_errors  bigint := 0;

    v_sqlstate    text;
    v_sqlerrm     text;
    v_sql_detail  text;
    v_sql_hint    text;
    v_sql_context text;
    v_log_error   text;
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_informatori;

    CREATE TABLE hcbi_ras.tmp_dwh_anag_informatori AS
    SELECT
        id_sorgente_informatore,
        ds_ragione_sociale,
        cd_p_iva,
        cd_codice_ateco_2002,
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
        ds_anno_pubblicazione,
        dt_last_update,
        ds_nazione,
        cd_versione,
        id_sorgente_provincia,
        fl_escludi_invio_mail_assoc_listino_completa
    FROM hcbi_ras.v_dwh_anag_informatori;

    CREATE UNIQUE INDEX tmp_dwh_anag_informatori_uq
    ON hcbi_ras.tmp_dwh_anag_informatori (
        ds_ragione_sociale,
        ds_anno_pubblicazione,
        cd_versione,
        id_sorgente_provincia
    )
    NULLS NOT DISTINCT;

    SELECT COUNT(*)
    INTO v_selected
    FROM hcbi_ras.tmp_dwh_anag_informatori;

    UPDATE hcbi_ras.dwh_anag_informatori AS d
    SET
        id_sorgente_informatore =
            src.id_sorgente_informatore,
        cd_p_iva =
            src.cd_p_iva,
        cd_codice_ateco_2002 =
            src.cd_codice_ateco_2002,
        ds_indirizzo_sede_legale =
            src.ds_indirizzo_sede_legale,
        cd_cap_sede_legale =
            src.cd_cap_sede_legale,
        ds_citta_sede_legale =
            src.ds_citta_sede_legale,
        cd_provincia_sede_legale =
            src.cd_provincia_sede_legale,
        ds_indirizzo_sede_operativa =
            src.ds_indirizzo_sede_operativa,
        cd_cap_sede_operativa =
            src.cd_cap_sede_operativa,
        ds_citta_sede_operativa =
            src.ds_citta_sede_operativa,
        cd_provincia_sede_operativa =
            src.cd_provincia_sede_operativa,
        ds_contatti =
            src.ds_contatti,
        cd_stato =
            src.cd_stato,
        ds_note =
            src.ds_note,
        ds_stato_attivita =
            src.ds_stato_attivita,
        cd_codice_fiscale =
            src.cd_codice_fiscale,
        dt_last_update =
            src.dt_last_update,
        ds_nazione =
            src.ds_nazione,
        fl_escludi_invio_mail_assoc_listino_completa =
            src.fl_escludi_invio_mail_assoc_listino_completa,
        dt_update =
            clock_timestamp(),
        tx_update_by =
            p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_informatori AS src
    WHERE d.ds_ragione_sociale = src.ds_ragione_sociale
      AND d.ds_anno_pubblicazione = src.ds_anno_pubblicazione
      AND d.cd_versione = src.cd_versione
      AND d.id_sorgente_provincia = src.id_sorgente_provincia
      AND (
             d.id_sorgente_informatore IS DISTINCT FROM
                 src.id_sorgente_informatore
          OR d.cd_p_iva IS DISTINCT FROM
                 src.cd_p_iva
          OR d.cd_codice_ateco_2002 IS DISTINCT FROM
                 src.cd_codice_ateco_2002
          OR d.ds_indirizzo_sede_legale IS DISTINCT FROM
                 src.ds_indirizzo_sede_legale
          OR d.cd_cap_sede_legale IS DISTINCT FROM
                 src.cd_cap_sede_legale
          OR d.ds_citta_sede_legale IS DISTINCT FROM
                 src.ds_citta_sede_legale
          OR d.cd_provincia_sede_legale IS DISTINCT FROM
                 src.cd_provincia_sede_legale
          OR d.ds_indirizzo_sede_operativa IS DISTINCT FROM
                 src.ds_indirizzo_sede_operativa
          OR d.cd_cap_sede_operativa IS DISTINCT FROM
                 src.cd_cap_sede_operativa
          OR d.ds_citta_sede_operativa IS DISTINCT FROM
                 src.ds_citta_sede_operativa
          OR d.cd_provincia_sede_operativa IS DISTINCT FROM
                 src.cd_provincia_sede_operativa
          OR d.ds_contatti IS DISTINCT FROM
                 src.ds_contatti
          OR d.cd_stato IS DISTINCT FROM
                 src.cd_stato
          OR d.ds_note IS DISTINCT FROM
                 src.ds_note
          OR d.ds_stato_attivita IS DISTINCT FROM
                 src.ds_stato_attivita
          OR d.cd_codice_fiscale IS DISTINCT FROM
                 src.cd_codice_fiscale
          OR d.dt_last_update IS DISTINCT FROM
                 src.dt_last_update
          OR d.ds_nazione IS DISTINCT FROM
                 src.ds_nazione
          OR d.fl_escludi_invio_mail_assoc_listino_completa
                 IS DISTINCT FROM
                 src.fl_escludi_invio_mail_assoc_listino_completa
      );

    GET DIAGNOSTICS v_updated = ROW_COUNT;

    INSERT INTO hcbi_ras.dwh_anag_informatori (
        id_sorgente_informatore,
        ds_ragione_sociale,
        cd_p_iva,
        cd_codice_ateco_2002,
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
        ds_anno_pubblicazione,
        dt_last_update,
        ds_nazione,
        cd_versione,
        id_sorgente_provincia,
        fl_escludi_invio_mail_assoc_listino_completa,
        dt_creation,
        tx_creation_by,
        dt_update,
        tx_update_by
    )
    SELECT
        src.id_sorgente_informatore,
        src.ds_ragione_sociale,
        src.cd_p_iva,
        src.cd_codice_ateco_2002,
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
        src.ds_anno_pubblicazione,
        src.dt_last_update,
        src.ds_nazione,
        src.cd_versione,
        src.id_sorgente_provincia,
        src.fl_escludi_invio_mail_assoc_listino_completa,
        clock_timestamp(),
        p_ds_step_name,
        clock_timestamp(),
        p_ds_step_name
    FROM hcbi_ras.tmp_dwh_anag_informatori AS src
    ON CONFLICT ON CONSTRAINT uq_dwh_anag_informatori
    DO NOTHING;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        0,
        0,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE hcbi_ras.tmp_dwh_anag_informatori;

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
            DROP TABLE IF EXISTS hcbi_ras.tmp_dwh_anag_informatori;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING
                    'Errore cleanup: %',
                    SQLERRM;
        END;

        v_log_error := LEFT(
            CONCAT_WS(
                E'\n',
                'SQLSTATE=' || COALESCE(v_sqlstate, ''),
                'MESSAGE=' || COALESCE(v_sqlerrm, ''),
                'DETAIL=' || COALESCE(v_sql_detail, ''),
                'HINT=' || COALESCE(v_sql_hint, ''),
                'CONTEXT=' || COALESCE(v_sql_context, '')
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
                        'Errore logging: %',
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_dwh_anag_informatori_prc_main: %',
            v_sqlerrm;
END;
$procedure$
