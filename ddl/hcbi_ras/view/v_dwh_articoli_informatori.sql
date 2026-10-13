CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_articoli_informatori" AS
 SELECT id_sorgente_articoli_informatori,
    id_sorgente_informatore,
    cd_articolo,
    ds_anno,
    id_sorgente_provincia,
    fl_escluso,
    cd_versione,
    id_sorgente_utente
   FROM hcbi_ras.stg_articoli_informatori s;;
