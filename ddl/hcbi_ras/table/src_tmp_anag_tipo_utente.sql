
CREATE TABLE hcbi_ras.src_tmp_anag_tipo_utente (
	usertype VARCHAR(25)
);

ALTER TABLE hcbi_ras.src_tmp_anag_tipo_utente OWNER TO hcbi_ras;
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.src_tmp_anag_tipo_utente TO hcbi_ras;
GRANT DELETE, INSERT, SELECT, UPDATE ON hcbi_ras.src_tmp_anag_tipo_utente TO hcbi_utility;
