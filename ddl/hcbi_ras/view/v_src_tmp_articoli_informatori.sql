CREATE OR REPLACE VIEW "hcbi_ras"."v_src_tmp_articoli_informatori" AS
 SELECT btrim(id_informatore::text) AS id_sorgente_informatore,
    btrim(codice_articolo::text) AS cd_articolo,
    btrim(anno::text) AS ds_anno,
    btrim(provincia::text) AS id_sorgente_provincia,
    btrim(escluso::text) AS fl_escluso,
    btrim(addendum::text) AS cd_versione,
    btrim(id::text) AS id_sorgente_articoli_informatori,
    btrim(user_id::text) AS id_sorgente_utente
   FROM hcbi_ras.src_tmp_articoli_informatori s;;
