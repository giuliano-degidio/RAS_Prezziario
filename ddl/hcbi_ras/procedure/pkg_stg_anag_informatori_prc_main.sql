CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_anag_informatori_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log     bigint;
    v_selected   bigint := 0;
    v_inserted   bigint := 0;
    v_updated    bigint := 0;
    v_deleted    bigint := 0;
    v_rec_errors bigint := 0;

    v_sqlstate   text;
    v_sqlerrm    text;
    v_sql_detail text;
    v_sql_hint   text;
    v_sql_context text;
    v_log_error  text;
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_anag_informatori_classificata;

    CREATE TABLE hcbi_ras.tmp_anag_informatori_classificata AS
    WITH src AS MATERIALIZED (
        SELECT
            f.id_sorgente_informatore
                AS id_sorgente_informatore_raw,
            f.ds_ragione_sociale
                AS ds_ragione_sociale_raw,
            f.cd_p_iva
                AS cd_p_iva_raw,
            f.cd_codice_ateco_2002
                AS cd_codice_ateco_2002_raw,
            f.ds_indirizzo_sede_legale
                AS ds_indirizzo_sede_legale_raw,
            f.cd_cap_sede_legale
                AS cd_cap_sede_legale_raw,
            f.ds_citta_sede_legale
                AS ds_citta_sede_legale_raw,
            f.cd_provincia_sede_legale
                AS cd_provincia_sede_legale_raw,
            f.ds_indirizzo_sede_operativa
                AS ds_indirizzo_sede_operativa_raw,
            f.cd_cap_sede_operativa
                AS cd_cap_sede_operativa_raw,
            f.ds_citta_sede_operativa
                AS ds_citta_sede_operativa_raw,
            f.cd_provincia_sede_operativa
                AS cd_provincia_sede_operativa_raw,
            f.ds_contatti
                AS ds_contatti_raw,
            f.cd_stato
                AS cd_stato_raw,
            f.ds_note
                AS ds_note_raw,
            f.ds_stato_attivita
                AS ds_stato_attivita_raw,
            f.cd_codice_fiscale
                AS cd_codice_fiscale_raw,
            f.ds_anno_pubblicazione
                AS ds_anno_pubblicazione_raw,
            f.dt_last_update
                AS dt_last_update_raw,
            f.ds_nazione
                AS ds_nazione_raw,
            f.cd_versione
                AS cd_versione_raw,
            f.id_sorgente_provincia
                AS id_sorgente_provincia_raw,
            f.fl_escludi_invio_mail_assoc_listino_completa
                AS fl_escludi_invio_mail_assoc_listino_completa_raw,

            NULLIF(BTRIM(f.id_sorgente_informatore::text), '')
                AS id_sorgente_informatore_txt,
            NULLIF(BTRIM(f.ds_ragione_sociale::text), '')
                AS ds_ragione_sociale_txt,
            NULLIF(BTRIM(f.cd_p_iva::text), '')
                AS cd_p_iva_txt,
            NULLIF(BTRIM(f.cd_codice_ateco_2002::text), '')
                AS cd_codice_ateco_2002_txt,
            NULLIF(BTRIM(f.ds_indirizzo_sede_legale::text), '')
                AS ds_indirizzo_sede_legale_txt,
            NULLIF(BTRIM(f.cd_cap_sede_legale::text), '')
                AS cd_cap_sede_legale_txt,
            NULLIF(BTRIM(f.ds_citta_sede_legale::text), '')
                AS ds_citta_sede_legale_txt,
            NULLIF(BTRIM(f.cd_provincia_sede_legale::text), '')
                AS cd_provincia_sede_legale_txt,
            NULLIF(BTRIM(f.ds_indirizzo_sede_operativa::text), '')
                AS ds_indirizzo_sede_operativa_txt,
            NULLIF(BTRIM(f.cd_cap_sede_operativa::text), '')
                AS cd_cap_sede_operativa_txt,
            NULLIF(BTRIM(f.ds_citta_sede_operativa::text), '')
                AS ds_citta_sede_operativa_txt,
            NULLIF(BTRIM(f.cd_provincia_sede_operativa::text), '')
                AS cd_provincia_sede_operativa_txt,
            NULLIF(BTRIM(f.ds_contatti::text), '')
                AS ds_contatti_txt,
            NULLIF(BTRIM(f.cd_stato::text), '')
                AS cd_stato_txt,
            NULLIF(BTRIM(f.ds_note::text), '')
                AS ds_note_txt,
            NULLIF(BTRIM(f.ds_stato_attivita::text), '')
                AS ds_stato_attivita_txt,
            NULLIF(BTRIM(f.cd_codice_fiscale::text), '')
                AS cd_codice_fiscale_txt,
            NULLIF(BTRIM(f.ds_anno_pubblicazione::text), '')
                AS ds_anno_pubblicazione_txt,
            NULLIF(BTRIM(f.dt_last_update::text), '')
                AS dt_last_update_txt,
            NULLIF(BTRIM(f.ds_nazione::text), '')
                AS ds_nazione_txt,
            NULLIF(BTRIM(f.cd_versione::text), '')
                AS cd_versione_txt,
            NULLIF(BTRIM(f.id_sorgente_provincia::text), '')
                AS id_sorgente_provincia_txt,
            NULLIF(
                BTRIM(f.fl_escludi_invio_mail_assoc_listino_completa::text),
                ''
            )
                AS fl_escludi_invio_mail_assoc_listino_completa_txt,

            COUNT(*) OVER (
                PARTITION BY
                    NULLIF(BTRIM(f.ds_ragione_sociale), ''),
                    NULLIF(BTRIM(f.ds_anno_pubblicazione), ''),
                    NULLIF(BTRIM(f.cd_versione), ''),
                    NULLIF(BTRIM(f.id_sorgente_provincia), '')
            ) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_anag_informatori AS f
    ),
    cv AS MATERIALIZED (
        SELECT
            s.*,
            hcbi_ras.try_integer(
                id_sorgente_informatore_txt
            ) AS id_sorgente_informatore_cv,
            hcbi_ras.try_integer(
                cd_stato_txt
            ) AS cd_stato_cv,
            hcbi_ras.try_integer(
                ds_anno_pubblicazione_txt
            ) AS ds_anno_pubblicazione_cv,
            hcbi_ras.try_timestamp(
                dt_last_update_txt
            ) AS dt_last_update_cv,
            hcbi_ras.try_smallint(
                cd_versione_txt
            ) AS cd_versione_cv,
            hcbi_ras.try_bigint(
                id_sorgente_provincia_txt
            ) AS id_sorgente_provincia_cv,
            hcbi_ras.try_boolean_integer(
                fl_escludi_invio_mail_assoc_listino_completa_txt
            ) AS fl_escludi_invio_mail_assoc_listino_completa_cv
        FROM src AS s
    )
    SELECT
        c.*,
        CASE
            WHEN duplicate_count > 1
                THEN 'Chiave duplicata'

            WHEN ds_ragione_sociale_txt IS NULL
                THEN 'ds_ragione_sociale obbligatorio'

            WHEN ds_anno_pubblicazione_txt IS NULL
                THEN 'ds_anno_pubblicazione obbligatorio'

            WHEN cd_versione_txt IS NULL
                THEN 'cd_versione obbligatorio'

            WHEN id_sorgente_provincia_txt IS NULL
                THEN 'id_sorgente_provincia obbligatorio'

            WHEN id_sorgente_informatore_txt IS NOT NULL
                 AND id_sorgente_informatore_cv IS NULL
                THEN 'id_sorgente_informatore non convertibile o fuori dominio'

            WHEN cd_stato_txt IS NOT NULL
                 AND cd_stato_cv IS NULL
                THEN 'cd_stato non convertibile o fuori dominio'

            WHEN ds_anno_pubblicazione_txt IS NOT NULL
                 AND ds_anno_pubblicazione_cv IS NULL
                THEN 'ds_anno_pubblicazione non convertibile o fuori dominio'

            WHEN dt_last_update_txt IS NOT NULL
                 AND dt_last_update_cv IS NULL
                THEN 'dt_last_update non convertibile o fuori dominio'

            WHEN cd_versione_txt IS NOT NULL
                 AND cd_versione_cv IS NULL
                THEN 'cd_versione non convertibile o fuori dominio'

            WHEN id_sorgente_provincia_txt IS NOT NULL
                 AND id_sorgente_provincia_cv IS NULL
                THEN 'id_sorgente_provincia non convertibile o fuori dominio'

            WHEN fl_escludi_invio_mail_assoc_listino_completa_txt IS NOT NULL
                 AND fl_escludi_invio_mail_assoc_listino_completa_cv IS NULL
                THEN 'fl_escludi_invio_mail_assoc_listino_completa non convertibile o fuori dominio'

            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM cv AS c;

    SELECT COUNT(*)
    INTO v_selected
    FROM hcbi_ras.tmp_anag_informatori_classificata;

    INSERT INTO hcbi_ras.stg_anag_informatori (
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
    )
    SELECT
        id_sorgente_informatore_cv,
        ds_ragione_sociale_txt,
        cd_p_iva_txt,
        cd_codice_ateco_2002_txt,
        ds_indirizzo_sede_legale_txt,
        cd_cap_sede_legale_txt,
        ds_citta_sede_legale_txt,
        cd_provincia_sede_legale_txt,
        ds_indirizzo_sede_operativa_txt,
        cd_cap_sede_operativa_txt,
        ds_citta_sede_operativa_txt,
        cd_provincia_sede_operativa_txt,
        ds_contatti_txt,
        cd_stato_cv,
        ds_note_txt,
        ds_stato_attivita_txt,
        cd_codice_fiscale_txt,
        ds_anno_pubblicazione_cv,
        dt_last_update_cv,
        ds_nazione_txt,
        cd_versione_cv,
        id_sorgente_provincia_cv,
        fl_escludi_invio_mail_assoc_listino_completa_cv
    FROM hcbi_ras.tmp_anag_informatori_classificata
    WHERE tx_motivo_scarto IS NULL;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_anag_informatori_rej (
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
        tx_motivo_scarto
    )
    SELECT
        id_sorgente_informatore_raw,
        ds_ragione_sociale_raw,
        cd_p_iva_raw,
        cd_codice_ateco_2002_raw,
        ds_indirizzo_sede_legale_raw,
        cd_cap_sede_legale_raw,
        ds_citta_sede_legale_raw,
        cd_provincia_sede_legale_raw,
        ds_indirizzo_sede_operativa_raw,
        cd_cap_sede_operativa_raw,
        ds_citta_sede_operativa_raw,
        cd_provincia_sede_operativa_raw,
        ds_contatti_raw,
        cd_stato_raw,
        ds_note_raw,
        ds_stato_attivita_raw,
        cd_codice_fiscale_raw,
        ds_anno_pubblicazione_raw,
        dt_last_update_raw,
        ds_nazione_raw,
        cd_versione_raw,
        id_sorgente_provincia_raw,
        fl_escludi_invio_mail_assoc_listino_completa_raw,
        tx_motivo_scarto
    FROM hcbi_ras.tmp_anag_informatori_classificata
    WHERE tx_motivo_scarto IS NOT NULL;

    GET DIAGNOSTICS v_rec_errors = ROW_COUNT;

    IF v_selected <> v_inserted + v_rec_errors THEN
        RAISE EXCEPTION 'Riconciliazione non valida';
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        0,
        0,
        v_rec_errors,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name
    );

    DROP TABLE hcbi_ras.tmp_anag_informatori_classificata;

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
            DROP TABLE IF EXISTS hcbi_ras.tmp_anag_informatori_classificata;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Errore cleanup: %', SQLERRM;
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
                    RAISE WARNING 'Errore logging: %', SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore in pkg_stg_anag_informatori_prc_main: %',
            v_sqlerrm;
END;
$procedure$
