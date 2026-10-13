CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_anag_tipologia" AS
 SELECT ds_anno,
    cd_versione,
    cd_tipologia,
    ds_tipologia,
    id_sorgente_provincia
   FROM hcbi_ras.stg_anag_tipologia s;;
