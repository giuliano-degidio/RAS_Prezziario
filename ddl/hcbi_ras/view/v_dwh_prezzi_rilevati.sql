CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_prezzi_rilevati" AS
 SELECT cd_articolo,
    ds_anno,
    id_sorgente_provincia,
    id_sorgente_informatore,
    id_sorgente_rilevatore,
    nr_prezzo,
    dt_inserimento,
    fl_nascosto,
    ds_anno_ribaltamento,
    cd_versione,
    cd_versione_ribaltamento,
    dt_last_update
   FROM hcbi_ras.stg_prezzi_rilevati;;
