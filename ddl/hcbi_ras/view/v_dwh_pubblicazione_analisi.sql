CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_pubblicazione_analisi" AS
 SELECT ds_anno_pubblicazione,
    cd_codice_analisi,
    nr_quantita,
    cd_articolo,
    cd_versione,
    id_sorgente_pubblicazione_analisi,
    id_sorgente_categoria,
    nr_riga
   FROM hcbi_ras.stg_pubblicazione_analisi s;;
