CREATE OR REPLACE VIEW hcbi_ras.v_src_tmp_anag_tipo_utente
AS SELECT TRIM(BOTH FROM usertype::text) AS ds_tipo_utente
   FROM hcbi_ras.src_tmp_anag_tipo_utente_vw s;
