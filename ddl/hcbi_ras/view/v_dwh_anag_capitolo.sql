CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_anag_capitolo" AS
 SELECT ds_anno,
    cd_versione,
    cd_capitolo,
    ds_capitolo,
    id_sorgente_provincia
   FROM hcbi_ras.stg_anag_capitolo s;;
