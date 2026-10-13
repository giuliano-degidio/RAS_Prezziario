CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_prezzi_approvati_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log bigint;
    v_selected bigint := 0;
    v_inserted bigint := 0;
    v_rejected bigint := 0;
    v_updated bigint := 0;
    v_deleted bigint := 0;
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

    DROP TABLE IF EXISTS hcbi_ras.tmp_prezzi_approvati_classificata;

    CREATE TABLE hcbi_ras.tmp_prezzi_approvati_classificata AS
    WITH src AS MATERIALIZED (
        SELECT f.cd_articolo,
               f.ds_anno,
               f.nr_prezzo,
               f.id_sorgente_provincia,
               f.dt_approvazione,
               f.cd_versione,
               NULLIF(btrim(f.cd_articolo), '') AS codice_txt,
               NULLIF(btrim(f.ds_anno), '') AS anno_txt,
               NULLIF(btrim(f.nr_prezzo), '') AS prezzo_txt,
               NULLIF(btrim(f.id_sorgente_provincia), '') AS provincia_txt,
               NULLIF(btrim(f.cd_versione), '') AS addendum_txt
        FROM hcbi_ras.v_src_tmp_prezzi_approvati f
    ),
    cv AS MATERIALIZED (
        SELECT s.*,
               s.codice_txt AS codice_cv,
               hcbi_ras.try_integer(s.anno_txt) AS anno_cv,
               hcbi_ras.try_numeric_24_5(replace(s.prezzo_txt, ',', '.')) AS prezzo_cv,
               hcbi_ras.try_integer(s.provincia_txt) AS provincia_cv,
               hcbi_ras.try_smallint(s.addendum_txt) AS addendum_cv
        FROM src s
    ),
    dup AS MATERIALIZED (
        SELECT c.*,
               count(*) OVER (
                   PARTITION BY c.codice_cv,
                                c.anno_cv,
                                c.provincia_cv,
                                c.addendum_cv
               ) AS duplicate_count
        FROM cv c
    )
    SELECT d.*,
           CASE
               WHEN d.codice_txt IS NULL
                   THEN 'codice obbligatorio'
               WHEN length(d.codice_txt) > 60
                   THEN 'codice eccede 60 caratteri'
               WHEN d.anno_txt IS NULL
                   THEN 'anno obbligatorio'
               WHEN d.anno_cv IS NULL
                   THEN 'anno non convertibile o fuori dominio integer'
               WHEN d.prezzo_txt IS NULL
                   THEN 'prezzo obbligatorio'
               WHEN d.prezzo_cv IS NULL
                   THEN 'prezzo non convertibile o fuori dominio numeric(24,5)'
               WHEN d.provincia_txt IS NULL
                   THEN 'provincia obbligatoria'
               WHEN d.provincia_cv IS NULL
                   THEN 'provincia non convertibile o fuori dominio integer'
               WHEN d.dt_approvazione IS NULL
                   THEN 'data_approvazione obbligatoria'
               WHEN d.addendum_txt IS NULL
                   THEN 'addendum obbligatorio'
               WHEN d.addendum_cv IS NULL
                   THEN 'addendum non convertibile o fuori dominio smallint'
               WHEN d.duplicate_count > 1
                   THEN 'Chiave duplicata: (codice, anno, provincia, addendum)'
               ELSE NULL
           END::text AS tx_motivo_scarto
    FROM dup d;

    SELECT count(*)
      INTO v_selected
      FROM hcbi_ras.tmp_prezzi_approvati_classificata;

    INSERT INTO hcbi_ras.stg_prezzi_approvati (
        cd_articolo,
        ds_anno,
        nr_prezzo,
        id_sorgente_provincia,
        dt_approvazione,
        cd_versione)
    SELECT codice_cv,
           anno_cv,
           prezzo_cv,
           provincia_cv,
           dt_approvazione,
           addendum_cv
      FROM hcbi_ras.tmp_prezzi_approvati_classificata
     WHERE tx_motivo_scarto IS NULL;

    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_prezzi_approvati_rej (
        cd_articolo,
        ds_anno,
        nr_prezzo,
        id_sorgente_provincia,
        dt_approvazione,
        cd_versione,
        tx_motivo_scarto)
    SELECT cd_articolo,
           ds_anno,
           nr_prezzo,
           id_sorgente_provincia,
           dt_approvazione,
           cd_versione,
           tx_motivo_scarto
      FROM hcbi_ras.tmp_prezzi_approvati_classificata
     WHERE tx_motivo_scarto IS NOT NULL;

    GET DIAGNOSTICS v_rejected = ROW_COUNT;

    IF v_selected <> v_inserted + v_rejected THEN
        RAISE EXCEPTION
            'Riconciliazione STG non valida: selected=%, inserted=%, rejected=%',
            v_selected, v_inserted, v_rejected;
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,
        v_selected,
        v_inserted,
        v_updated,
        v_deleted,
        v_rejected,
        'SUCCESS',
        clock_timestamp()::timestamp,
        p_ds_step_name);

    DROP TABLE hcbi_ras.tmp_prezzi_approvati_classificata;
    p_result := 1;
EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;
        DROP TABLE IF EXISTS hcbi_ras.tmp_prezzi_approvati_classificata;

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
                    RAISE WARNING 'Errore logging: %', SQLERRM;
            END;
        END IF;

        RAISE WARNING 'Errore main STG PREZZI_APPROVATI: %', SQLERRM;
END;
$procedure$
