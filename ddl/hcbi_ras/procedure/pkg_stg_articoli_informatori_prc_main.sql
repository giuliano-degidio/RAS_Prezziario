CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_stg_articoli_informatori_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
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
        p_id_chain_log,p_id_chain,p_id_step,p_ds_step_name,
        clock_timestamp()::timestamp,clock_timestamp()::timestamp,p_ds_step_name)
    INTO v_id_log;

    DROP TABLE IF EXISTS hcbi_ras.tmp_articoli_informatori_classificata;

    CREATE TABLE hcbi_ras.tmp_articoli_informatori_classificata AS
    WITH src AS MATERIALIZED (
        SELECT f.id_sorgente_informatore,
               f.cd_articolo,
               f.ds_anno,
               f.id_sorgente_provincia,
               f.fl_escluso,
               f.cd_versione,
               f.id_sorgente_articoli_informatori,
               f.id_sorgente_utente,
               NULLIF(btrim(f.id_sorgente_informatore),'') AS informatore_txt,
               NULLIF(btrim(f.cd_articolo),'') AS articolo_txt,
               NULLIF(btrim(f.ds_anno),'') AS anno_txt,
               NULLIF(btrim(f.id_sorgente_provincia),'') AS provincia_txt,
               NULLIF(lower(btrim(f.fl_escluso)),'') AS escluso_txt,
               NULLIF(btrim(f.cd_versione),'') AS addendum_txt,
               NULLIF(btrim(f.id_sorgente_articoli_informatori),'') AS id_txt,
               NULLIF(btrim(f.id_sorgente_utente),'') AS utente_txt
        FROM hcbi_ras.v_src_tmp_articoli_informatori f
    ), cv AS MATERIALIZED (
        SELECT s.*,
               hcbi_ras.try_integer(s.informatore_txt) AS informatore_cv,
               s.articolo_txt AS articolo_cv,
               hcbi_ras.try_integer(s.anno_txt) AS anno_cv,
               hcbi_ras.try_integer(s.provincia_txt) AS provincia_cv,
               CASE s.escluso_txt
                   WHEN '0' THEN 0::smallint
                   WHEN 'false' THEN 0::smallint
                   WHEN 'f' THEN 0::smallint
                   WHEN 'no' THEN 0::smallint
                   WHEN 'n' THEN 0::smallint
                   WHEN '1' THEN 1::smallint
                   WHEN 'true' THEN 1::smallint
                   WHEN 't' THEN 1::smallint
                   WHEN 'yes' THEN 1::smallint
                   WHEN 'y' THEN 1::smallint
                   ELSE NULL::smallint
               END AS escluso_cv,
               hcbi_ras.try_smallint(s.addendum_txt) AS addendum_cv,
               hcbi_ras.try_bigint(s.id_txt) AS id_cv,
               hcbi_ras.try_integer(s.utente_txt) AS utente_cv
        FROM src s
    ), dup AS MATERIALIZED (
        SELECT c.*,
               count(*) OVER (
                   PARTITION BY c.informatore_cv,c.articolo_cv,c.anno_cv,c.provincia_cv,c.addendum_cv
               ) AS duplicate_key_count,
               count(*) OVER (PARTITION BY c.id_cv) AS duplicate_id_count
        FROM cv c
    )
    SELECT d.*,
           CASE
               WHEN d.informatore_txt IS NULL THEN 'id_informatore obbligatorio'
               WHEN d.informatore_cv IS NULL THEN 'id_informatore non convertibile o fuori dominio integer'
               WHEN d.articolo_txt IS NULL THEN 'codice_articolo obbligatorio'
               WHEN length(d.articolo_txt) > 60 THEN 'codice_articolo eccede 60 caratteri'
               WHEN d.anno_txt IS NULL THEN 'anno obbligatorio'
               WHEN d.anno_cv IS NULL THEN 'anno non convertibile o fuori dominio integer'
               WHEN d.provincia_txt IS NULL THEN 'provincia obbligatoria'
               WHEN d.provincia_cv IS NULL THEN 'provincia non convertibile o fuori dominio integer'
               WHEN d.escluso_txt IS NULL THEN 'escluso obbligatorio'
               WHEN d.escluso_cv IS NULL THEN 'escluso non riconosciuto; valori ammessi: 0/1, false/true, f/t, no/yes, n/y'
               WHEN d.addendum_txt IS NULL THEN 'addendum obbligatorio'
               WHEN d.addendum_cv IS NULL THEN 'addendum non convertibile o fuori dominio smallint'
               WHEN d.id_txt IS NULL THEN 'id obbligatorio'
               WHEN d.id_cv IS NULL THEN 'id non convertibile o fuori dominio bigint'
               WHEN d.utente_txt IS NOT NULL AND d.utente_cv IS NULL THEN 'user_id non convertibile o fuori dominio integer'
               WHEN d.duplicate_key_count > 1 THEN 'Chiave duplicata: (id_informatore, codice_articolo, anno, provincia, addendum)'
               WHEN d.duplicate_id_count > 1 THEN 'id sorgente duplicato'
               ELSE NULL
           END::text AS tx_motivo_scarto
    FROM dup d;

    SELECT count(*) INTO v_selected
    FROM hcbi_ras.tmp_articoli_informatori_classificata;

    INSERT INTO hcbi_ras.stg_articoli_informatori (
        id_sorgente_informatore,cd_articolo,ds_anno,id_sorgente_provincia,fl_escluso,cd_versione,
        id_sorgente_articoli_informatori,id_sorgente_utente)
    SELECT informatore_cv,articolo_cv,anno_cv,provincia_cv,escluso_cv,addendum_cv,id_cv,utente_cv
    FROM hcbi_ras.tmp_articoli_informatori_classificata
    WHERE tx_motivo_scarto IS NULL;
    GET DIAGNOSTICS v_inserted = ROW_COUNT;

    INSERT INTO hcbi_ras.stg_articoli_informatori_rej (
        id_sorgente_informatore,cd_articolo,ds_anno,id_sorgente_provincia,fl_escluso,cd_versione,
        id_sorgente_articoli_informatori,id_sorgente_utente,tx_motivo_scarto)
    SELECT id_sorgente_informatore,cd_articolo,ds_anno,id_sorgente_provincia,fl_escluso,cd_versione,
           id_sorgente_articoli_informatori,id_sorgente_utente,tx_motivo_scarto
    FROM hcbi_ras.tmp_articoli_informatori_classificata
    WHERE tx_motivo_scarto IS NOT NULL;
    GET DIAGNOSTICS v_rejected = ROW_COUNT;

    IF v_selected <> v_inserted + v_rejected THEN
        RAISE EXCEPTION 'Riconciliazione STG non valida: selected=%, inserted=%, rejected=%',
            v_selected,v_inserted,v_rejected;
    END IF;

    CALL hcbi_utility.pkg_log_prc_update_log(
        v_id_log,v_selected,v_inserted,v_updated,v_deleted,v_rejected,
        'SUCCESS',clock_timestamp()::timestamp,p_ds_step_name);

    DROP TABLE hcbi_ras.tmp_articoli_informatori_classificata;
    p_result := 1;
EXCEPTION WHEN OTHERS THEN
    p_result := -1;
    DROP TABLE IF EXISTS hcbi_ras.tmp_articoli_informatori_classificata;
    IF v_id_log IS NOT NULL THEN
        BEGIN
            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_id_log,'FAILED',left('SQLSTATE='||SQLSTATE||E'\nMESSAGE='||SQLERRM,4000),
                clock_timestamp()::timestamp,p_ds_step_name);
        EXCEPTION WHEN OTHERS THEN RAISE WARNING 'Errore logging: %',SQLERRM; END;
    END IF;
    RAISE WARNING 'Errore main STG ARTICOLI_INFORMATORI: %',SQLERRM;
END;
$procedure$
