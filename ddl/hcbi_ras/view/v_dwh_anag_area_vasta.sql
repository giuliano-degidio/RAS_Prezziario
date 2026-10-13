CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_anag_area_vasta" AS
 SELECT id_sorgente_area_vasta,
    ds_nome
   FROM hcbi_ras.stg_anag_area_vasta s;;
