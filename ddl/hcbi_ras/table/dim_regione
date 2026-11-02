CREATE TABLE IF NOT EXISTS hcbi_ras.dim_regione
(
    id_anag_regione bigint NOT NULL,
    cd_regione character varying(50) COLLATE pg_catalog."default",
    ds_regione character varying(100) COLLATE pg_catalog."default",
    cd_anno integer NOT NULL,
    dt_creation timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by character varying(4000) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
    tx_update_by character varying(4000) COLLATE pg_catalog."default" NOT NULL DEFAULT CURRENT_USER,
	CONSTRAINT pk_dim_regione PRIMARY KEY (id_anag_regione),
    CONSTRAINT uq_dim_regione UNIQUE NULLS NOT DISTINCT (cd_anno,cd_regione)
	
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS hcbi_ras.dim_regione
    OWNER to hcbi_ras;

REVOKE ALL ON TABLE hcbi_ras.dim_regione FROM hcbi_utility;

GRANT ALL ON TABLE hcbi_ras.dim_regione TO hcbi_ras;

GRANT INSERT, DELETE, SELECT, UPDATE ON TABLE hcbi_ras.dim_regione TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dim_regione
    IS 'Dimensione delle regioni tabella statica.';

COMMENT ON COLUMN hcbi_ras.dim_regione.id_anag_regione
    IS 'Chiave primaria globale della dimensione.';

COMMENT ON COLUMN hcbi_ras.dim_regione.cd_anno
    IS 'Anno del contesto applicativo usato per le lookup contestualizzate.';

COMMENT ON COLUMN hcbi_ras.dim_regione.cd_regione
    IS 'Codice della regione; business key contestualizzata con anno.';

COMMENT ON COLUMN hcbi_ras.dim_regione.ds_regione
    IS 'Descrizione della regione.';

COMMENT ON COLUMN hcbi_ras.dim_regione.dt_creation
    IS 'Timestamp di creazione del record nella dimensione.';

COMMENT ON COLUMN hcbi_ras.dim_regione.tx_creation_by
    IS 'Processo che ha creato il record nella dimensione.';

COMMENT ON COLUMN hcbi_ras.dim_regione.dt_update
    IS 'Timestamp dell''ultimo aggiornamento del record.';

COMMENT ON COLUMN hcbi_ras.dim_regione.tx_update_by
    IS 'Processo che ha eseguito l''ultimo aggiornamento.';
	
COMMENT ON CONSTRAINT pk_dim_regione ON hcbi_ras.dim_regione
    IS 'Chiave primaria della dimensione: id_anag_provincia.';

COMMENT ON CONSTRAINT uq_dim_regione ON hcbi_ras.dim_regione
    IS 'Business key contestualizzata della dimensione: cd_anno, cd_regione.';