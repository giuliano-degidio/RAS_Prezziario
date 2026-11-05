
CREATE TABLE hcbi_ras.src_tmp_anag_tipo_utente_vw (
	usertype VARCHAR(100)
);

ALTER TABLE hcbi_ras.src_tmp_anag_tipo_utente_vw OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.src_tmp_anag_tipo_utente_vw IS 'Tabella temporanea del flusso ANAG_TIPO_UTENTE alimentata dalla vista di frontiera.';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.src_tmp_anag_tipo_utente_vw TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.src_tmp_anag_tipo_utente_vw TO hcbi_utility;
