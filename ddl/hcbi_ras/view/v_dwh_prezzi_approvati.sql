CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_prezzi_approvati" AS
 SELECT cd_articolo,
    ds_anno,
    nr_prezzo,
    id_sorgente_provincia,
    dt_approvazione,
    cd_versione
   FROM hcbi_ras.stg_prezzi_approvati s;;
