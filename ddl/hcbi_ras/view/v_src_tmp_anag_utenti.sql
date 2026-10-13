CREATE OR REPLACE VIEW "hcbi_ras"."v_src_tmp_anag_utenti" AS
 SELECT TRIM(BOTH FROM user_id::text) AS id_sorgente_utente,
    TRIM(BOTH FROM username::text) AS cd_username,
    TRIM(BOTH FROM email::text) AS ds_email,
    TRIM(BOTH FROM display_name::text) AS ds_nome_visualizzato,
    TRIM(BOTH FROM state::text) AS cd_stato,
    TRIM(BOTH FROM usertype::text) AS cd_tipo_utente
   FROM hcbi_ras.src_tmp_anag_utenti s;;
