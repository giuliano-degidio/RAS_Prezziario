CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_anag_ateco_2002" AS
 SELECT cd_ateco_2002,
    ds_ateco_2002
   FROM hcbi_ras.stg_anag_ateco_2002 s;;
