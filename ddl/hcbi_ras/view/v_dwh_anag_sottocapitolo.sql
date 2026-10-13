CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_anag_sottocapitolo" AS
 SELECT ds_anno,
    cd_versione,
    cd_sottocapitolo,
    ds_sottocapitolo,
    id_sorgente_provincia
   FROM hcbi_ras.stg_anag_sottocapitolo s;;
