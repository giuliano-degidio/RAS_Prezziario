CREATE OR REPLACE VIEW "hcbi_ras"."v_src_tmp_anag_macro_gruppo" AS
 SELECT btrim(id::text) AS id_sorgente_macro_gruppo,
    btrim(nome::text) AS ds_nome,
    btrim(plurale::text) AS ds_plurale
   FROM hcbi_ras.src_tmp_anag_macro_gruppo s;;
