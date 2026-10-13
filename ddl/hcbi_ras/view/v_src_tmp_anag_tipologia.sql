CREATE OR REPLACE VIEW "hcbi_ras"."v_src_tmp_anag_tipologia" AS
 SELECT TRIM(BOTH FROM anno::text) AS ds_anno,
    TRIM(BOTH FROM addendum::text) AS cd_versione,
    TRIM(BOTH FROM codice::text) AS cd_tipologia,
    TRIM(BOTH FROM nome) AS ds_tipologia,
    TRIM(BOTH FROM provincia::text) AS id_sorgente_provincia
   FROM hcbi_ras.src_tmp_anag_tipologia_vw s;;
