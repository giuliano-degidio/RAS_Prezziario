-- Table: hcbi_ras.dim_utenti

-- DROP TABLE IF EXISTS hcbi_ras.dim_utenti;

CREATE TABLE IF NOT EXISTS hcbi_ras.dim_utenti
(
    id_anag_utente bigint NOT NULL,
    id_sorgente_utente bigint,
    cd_username character varying(255) COLLATE pg_catalog."default" NOT NULL,
    ds_email character varying(255) COLLATE pg_catalog."default",
    ds_nome_visualizzato character varying(50) COLLATE pg_catalog."default",
    cd_stato smallint,
    cd_tipo_utente character varying(25) COLLATE pg_catalog."default",
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by character varying(4000) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by character varying(4000) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT pk_dim_utenti PRIMARY KEY (id_anag_utente),
    CONSTRAINT uq_dim_utenti UNIQUE NULLS NOT DISTINCT (cd_username)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dim_utenti
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.dim_utenti FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.dim_utenti TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.dim_utenti TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dim_utenti
    IS 'Dimensione utenti alimentata da HCBI_RAS.DWH_ANAG_UTENTI.';

COMMENT ON COLUMN hcbi_ras.dim_utenti.id_anag_utente
    IS 'Chiave primaria mantenuta dalla chiave DWH sorgente.';

COMMENT ON COLUMN hcbi_ras.dim_utenti.id_sorgente_utente
    IS 'Identificativo dell utente nel sistema sorgente.';

COMMENT ON COLUMN hcbi_ras.dim_utenti.cd_username
    IS 'Username e business key della dimensione.';

COMMENT ON COLUMN hcbi_ras.dim_utenti.ds_email
    IS 'Indirizzo email dell utente.';

COMMENT ON COLUMN hcbi_ras.dim_utenti.ds_nome_visualizzato
    IS 'Nome visualizzato dell utente.';

COMMENT ON COLUMN hcbi_ras.dim_utenti.cd_stato
    IS 'Stato dell utente.';

COMMENT ON COLUMN hcbi_ras.dim_utenti.cd_tipo_utente
    IS 'Tipologia dell utente.';

COMMENT ON COLUMN hcbi_ras.dim_utenti.dt_creation
    IS 'Timestamp di creazione del record nella dimensione.';

COMMENT ON COLUMN hcbi_ras.dim_utenti.tx_creation_by
    IS 'Processo che ha creato il record nella dimensione.';

COMMENT ON COLUMN hcbi_ras.dim_utenti.dt_update
    IS 'Timestamp dell ultimo aggiornamento del record nella dimensione.';

COMMENT ON COLUMN hcbi_ras.dim_utenti.tx_update_by
    IS 'Processo che ha eseguito l ultimo aggiornamento.';
COMMENT ON CONSTRAINT pk_dim_utenti ON hcbi_ras.dim_utenti
    IS 'Chiave primaria: id_anag_utente.';

COMMENT ON CONSTRAINT uq_dim_utenti ON hcbi_ras.dim_utenti
    IS 'Business key: cd_username.';
