CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_anag_unita_misura" AS
 SELECT cd_unita_misura,
    ds_unita_misura,
    nr_decimali,
    id_sorgente_unita_misura,
    dt_last_update,
    dt_fine_validita
   FROM hcbi_ras.stg_anag_unita_misura s;;
