CREATE OR REPLACE VIEW "hcbi_ras"."v_dwh_anag_utenti" AS
 SELECT id_sorgente_utente,
    cd_username,
    ds_email,
    ds_nome_visualizzato,
    cd_stato,
    cd_tipo_utente
   FROM hcbi_ras.stg_anag_utenti s;;
