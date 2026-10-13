
CREATE TABLE hcbi_ras.stg_anag_utenti_rej (
	id_sorgente_utente VARCHAR(100), 
	cd_username VARCHAR(255), 
	ds_email VARCHAR(255), 
	ds_nome_visualizzato VARCHAR(50), 
	cd_stato VARCHAR(20), 
	cd_tipo_utente VARCHAR(25), 
	tx_motivo_scarto VARCHAR(4000)
);
