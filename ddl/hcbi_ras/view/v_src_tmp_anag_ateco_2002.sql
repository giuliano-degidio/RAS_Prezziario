CREATE OR REPLACE VIEW "hcbi_ras"."v_src_tmp_anag_ateco_2002" AS
 SELECT btrim(cd_ateco_2002::text) AS cd_ateco_2002,
    btrim(ds_ateco_2002::text) AS ds_ateco_2002
   FROM hcbi_ras.src_tmp_anag_ateco_2002 s;;
