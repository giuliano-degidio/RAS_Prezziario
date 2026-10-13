CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_anag_macro_gruppo" AS
 SELECT id_sorgente_macro_gruppo,
    ds_nome,
    ds_plurale
   FROM hcbi_ras.stg_anag_macro_gruppo s;;
