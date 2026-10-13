CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_anag_livello_codifica" AS
 SELECT id_sorgente_livello_codifica,
    ds_nome,
    ds_plurale
   FROM hcbi_ras.stg_anag_livello_codifica s;;
