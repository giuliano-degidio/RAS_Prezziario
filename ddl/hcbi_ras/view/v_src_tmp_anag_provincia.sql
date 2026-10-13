CREATE OR REPLACE VIEW "hcbi_ras"."v_src_tmp_anag_provincia" AS
 SELECT TRIM(BOTH FROM id::text) AS id_sorgente_provincia,
    TRIM(BOTH FROM provincia::text) AS cd_provincia,
    TRIM(BOTH FROM nome::text) AS ds_nome,
    TRIM(BOTH FROM id_area_vasta::text) AS id_sorgente_area_vasta,
    TRIM(BOTH FROM provincia_principale_regionale::text) AS fl_provincia_principale_regionale,
    TRIM(BOTH FROM provincia_principale_area_vasta::text) AS fl_provincia_principale_area_vasta
   FROM hcbi_ras.src_tmp_anag_provincia s;;
