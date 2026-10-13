CREATE OR REPLACE VIEW "hcbi_ras"."v_src_tmp_pubblicazione_analisi" AS
 SELECT TRIM(BOTH FROM anno::text) AS ds_anno_pubblicazione,
    TRIM(BOTH FROM codice_analisi::text) AS cd_codice_analisi,
    TRIM(BOTH FROM quantita::text) AS nr_quantita,
    TRIM(BOTH FROM codice_elemento::text) AS cd_articolo,
    TRIM(BOTH FROM addendum::text) AS cd_versione,
    TRIM(BOTH FROM id::text) AS id_sorgente_pubblicazione_analisi,
    TRIM(BOTH FROM id_categoria::text) AS id_sorgente_categoria,
    nr_riga
   FROM hcbi_ras.src_tmp_pubblicazione_analisi s;;
