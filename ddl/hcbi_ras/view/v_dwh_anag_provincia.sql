CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_anag_provincia" AS
 SELECT id_sorgente_provincia,
    cd_provincia,
    ds_nome,
    id_sorgente_area_vasta,
    fl_provincia_principale_regionale,
    fl_provincia_principale_area_vasta
   FROM hcbi_ras.stg_anag_provincia s;;
