CREATE OR REPLACE VIEW "hcbi_ras"."v_src_tmp_anag_unita_misura" AS
 SELECT TRIM(BOTH FROM codice::text) AS cd_unita_misura,
    TRIM(BOTH FROM descrizione) AS ds_unita_misura,
    TRIM(BOTH FROM decimali::text) AS nr_decimali,
    TRIM(BOTH FROM id::text) AS id_sorgente_unita_misura,
    TRIM(BOTH FROM last_update::text) AS dt_last_update,
    TRIM(BOTH FROM data_fine_validita::text) AS dt_fine_validita
   FROM hcbi_ras.src_tmp_anag_unita_misura s;;
