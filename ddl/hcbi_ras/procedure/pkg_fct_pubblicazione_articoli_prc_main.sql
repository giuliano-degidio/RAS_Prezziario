CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_fct_pubblicazione_articoli_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
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
        CALL hcbi_utility.pkg_log_prc_error_update_log(
            v_id_log,
            'FAILED',
            left('SQLSTATE=' || SQLSTATE || E'\nMESSAGE=' || SQLERRM,4000),
            clock_timestamp()::timestamp,
            p_ds_step_name
        );
    END IF;

    RAISE WARNING
        'Errore main FCT_PUBBLICAZIONE_ARTICOLI: SQLSTATE=%, errore=%',
        SQLSTATE,SQLERRM;
END;
$procedure$
