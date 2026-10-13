CREATE OR REPLACE VIEW "hcbi_ras"."v_src_tmp_anag_area_vasta" AS
 SELECT TRIM(BOTH FROM id::text) AS id_sorgente_area_vasta,
    TRIM(BOTH FROM nome::text) AS ds_nome
   FROM hcbi_ras.src_tmp_anag_area_vasta s;;
