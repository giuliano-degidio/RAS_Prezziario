CREATE OR REPLACE VIEW "hcbi_ras"."v_src_tmp_prezzi_approvati" AS
 SELECT btrim(codice::text) AS cd_articolo,
    btrim(anno::text) AS ds_anno,
    btrim(prezzo::text) AS nr_prezzo,
    btrim(provincia::text) AS id_sorgente_provincia,
    data_approvazione AS dt_approvazione,
    btrim(addendum::text) AS cd_versione
   FROM hcbi_ras.src_tmp_prezzi_approvati s;;
