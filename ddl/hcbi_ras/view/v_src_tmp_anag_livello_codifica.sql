CREATE OR REPLACE VIEW "hcbi_ras"."v_src_tmp_anag_livello_codifica" AS
 SELECT btrim(id::text) AS id_sorgente_livello_codifica,
    btrim(nome::text) AS ds_nome,
    btrim(plurale::text) AS ds_plurale
   FROM hcbi_ras.src_tmp_anag_livello_codifica s;;
