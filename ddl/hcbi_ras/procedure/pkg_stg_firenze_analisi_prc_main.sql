CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_firenze_analisi_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    v_id_log bigint;
    v_selected bigint := 0;
    v_inserted bigint := 0;
    v_rejected bigint := 0;
BEGIN
    p_result := -1;
    SELECT hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name) INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_firenze_analisi_stg_classificata;
    CREATE TABLE hcbi_ras.tmp_firenze_analisi_stg_classificata AS
    WITH src AS MATERIALIZED
    (
        SELECT
            f.*,
            hcbi_ras.try_integer(nullif(btrim(f.nr_anno),'')) AS nr_anno_c,
            hcbi_ras.try_bigint(nullif(btrim(f.nr_riga_file),'')) AS nr_riga_file_c,
            hcbi_ras.try_timestamp(nullif(btrim(f.dt_caricamento),'')) AS dt_caricamento_c,
            count(*) OVER (PARTITION BY f.nr_anno, f.nr_riga_file) AS duplicate_count
        FROM hcbi_ras.v_src_tmp_firenze_analisi f
    )
    SELECT
        s.*,
        CASE
            WHEN s.duplicate_count > 1 THEN 'Chiave sorgente duplicata: (nr_anno, nr_riga_file)'
            WHEN s.nr_anno_c IS NULL THEN 'nr_anno obbligatorio o non convertibile in integer'
            WHEN s.nr_riga_file_c IS NULL THEN 'nr_riga_file obbligatorio o non convertibile in bigint'
            WHEN nullif(btrim(s.ds_regione),'') IS NULL THEN 'ds_regione obbligatoria'
            WHEN nullif(btrim(s.ds_provincia),'') IS NULL THEN 'ds_provincia obbligatoria'
            WHEN nullif(btrim(s.tx_nome_file),'') IS NULL THEN 'tx_nome_file obbligatorio'
            ELSE NULL
        END::text AS tx_motivo_scarto
    FROM src s;

    SELECT count(*) INTO v_selected FROM hcbi_ras.tmp_firenze_analisi_stg_classificata;

    INSERT INTO hcbi_ras.stg_firenze_analisi
    (nr_anno,ds_regione,ds_provincia,nr_riga_file,analisi,descrizione,cam,
     codice_dettaglio,cam_codice_dettaglio,voce_articolo,codice_collegato,
     unita_misura,quantita,prezzo_unitario,importo,tx_nome_file,
     dt_caricamento,tx_caricamento_by)
    SELECT
        nr_anno_c,btrim(ds_regione),btrim(ds_provincia),nr_riga_file_c,
        analisi,descrizione,cam,codice_dettaglio,cam_codice_dettaglio,
        voce_articolo,codice_collegato,unita_misura,quantita,prezzo_unitario,
        importo,btrim(tx_nome_file),dt_caricamento_c,
        nullif(btrim(tx_caricamento_by),'')
    FROM hcbi_ras.tmp_firenze_analisi_stg_classificata
    WHERE tx_motivo_scarto IS NULL;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_firenze_analisi_rej
    (nr_anno,ds_regione,ds_provincia,nr_riga_file,analisi,descrizione,cam,
     codice_dettaglio,cam_codice_dettaglio,voce_articolo,codice_collegato,
     unita_misura,quantita,prezzo_unitario,importo,tx_nome_file,
     dt_caricamento,tx_caricamento_by,tx_motivo_scarto,dt_scarto)
    SELECT
        nr_anno,ds_regione,ds_provincia,nr_riga_file,analisi,descrizione,cam,
        codice_dettaglio,cam_codice_dettaglio,voce_articolo,codice_collegato,
        unita_misura,quantita,prezzo_unitario,importo,tx_nome_file,
        dt_caricamento,tx_caricamento_by,tx_motivo_scarto,clock_timestamp()
    FROM hcbi_ras.tmp_firenze_analisi_stg_classificata
    WHERE tx_motivo_scarto IS NOT NULL;
    GET DIAGNOSTICS v_rejected = ROW_COUNT;

    IF v_selected <> v_inserted + v_rejected THEN
        RAISE EXCEPTION 'Riconciliazione STG non valida selected=%, inserted=%, rejected=%',
            v_selected,v_inserted,v_rejected;
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(v_id_log,v_selected,v_inserted,0,0,v_rejected,
        'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);
    DROP TABLE hcbi_ras.tmp_firenze_analisi_stg_classificata;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    DROP TABLE IF EXISTS hcbi_ras.tmp_firenze_analisi_stg_classificata;
    IF v_id_log IS NOT NULL THEN
        CALL hcbi_utility.pkg_log_prc_error_update_log(v_id_log,'FAILED',
            left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),clock_timestamp()::timestamp,p_ds_step_name);
    END IF;
    RAISE WARNING 'Errore STG main: SQLSTATE=%, errore=%',SQLSTATE,SQLERRM;
END;
$procedure$
