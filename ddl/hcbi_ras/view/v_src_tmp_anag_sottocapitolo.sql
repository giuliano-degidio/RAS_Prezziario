CREATE OR REPLACE VIEW "hcbi_ras"."v_src_tmp_anag_sottocapitolo" AS
 SELECT TRIM(BOTH FROM anno::text) AS ds_anno,
    TRIM(BOTH FROM addendum::text) AS cd_versione,
    TRIM(BOTH FROM codice::text) AS cd_sottocapitolo,
    TRIM(BOTH FROM nome) AS ds_sottocapitolo,
    TRIM(BOTH FROM provincia::text) AS id_sorgente_provincia
   FROM hcbi_ras.src_tmp_anag_sottocapitolo_vw s;;
