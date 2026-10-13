CREATE OR REPLACE VIEW "hcbi_ras"."v_src_tmp_prezzi_rilevati" AS
 SELECT btrim(codice::text) AS cd_articolo,
    btrim(anno::text) AS ds_anno,
    btrim(provincia::text) AS id_sorgente_provincia,
    btrim(informatore::text) AS id_sorgente_informatore,
    btrim(rilevatore::text) AS id_sorgente_rilevatore,
    btrim(prezzo::text) AS nr_prezzo,
    data_inserimento AS dt_inserimento,
    btrim(nascosto::text) AS fl_nascosto,
    btrim(ribaltato_da_anno::text) AS ds_anno_ribaltamento,
    btrim(addendum::text) AS cd_versione,
    btrim(ribaltato_da_addendum::text) AS cd_versione_ribaltamento,
    last_update AS dt_last_update
   FROM hcbi_ras.src_tmp_prezzi_rilevati s;;
