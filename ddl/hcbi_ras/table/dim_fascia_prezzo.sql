CREATE TABLE IF NOT EXISTS hcbi_ras.dim_fascia_prezzo
(
    id_fascia_prezzo smallint NOT NULL,
    cd_fascia_prezzo varchar(20) NOT NULL,
    ds_fascia_prezzo varchar(100) NOT NULL,
    nr_limite_inferiore numeric(24,5),
    nr_limite_superiore numeric(24,5),
    nr_ordinamento smallint NOT NULL,
    fl_attivo smallint NOT NULL DEFAULT 1,

    dt_creation timestamp without time zone
        NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by varchar(4000)
        NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone
        NOT NULL DEFAULT clock_timestamp(),
    tx_update_by varchar(4000)
        NOT NULL DEFAULT CURRENT_USER,

    CONSTRAINT pk_dim_fascia_prezzo
        PRIMARY KEY (id_fascia_prezzo),

    CONSTRAINT uk_dim_fascia_prezzo_codice
        UNIQUE (cd_fascia_prezzo),

    CONSTRAINT uk_dim_fascia_prezzo_ordinamento
        UNIQUE (nr_ordinamento),

    CONSTRAINT ck_dim_fascia_prezzo_attivo
        CHECK (fl_attivo IN (0,1)),

    CONSTRAINT ck_dim_fascia_prezzo_limiti
        CHECK (
            (
                id_fascia_prezzo IN (-1,0)
                AND nr_limite_inferiore IS NULL
                AND nr_limite_superiore IS NULL
            )
            OR
            (
                id_fascia_prezzo > 0
                AND nr_limite_inferiore IS NOT NULL
                AND (
                    nr_limite_superiore IS NULL
                    OR nr_limite_inferiore < nr_limite_superiore
                )
            )
        )
);

ALTER TABLE hcbi_ras.dim_fascia_prezzo OWNER TO hcbi_ras;
COMMENT ON TABLE hcbi_ras.dim_fascia_prezzo IS 'Dimensione delle fasce applicate a NR_PREZZO.Tabella statica';
GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON hcbi_ras.dim_fascia_prezzo TO hcbi_ras;
GRANT SELECT ON hcbi_ras.dim_fascia_prezzo TO hcbi_utility;

COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.id_fascia_prezzo IS 'PK. -1 fascia non determinata; 0 prezzo non disponibile.';
COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.cd_fascia_prezzo IS 'Codice funzionale stabile della fascia.';
COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.ds_fascia_prezzo IS 'Descrizione della fascia per il livello semantico.';
COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.nr_limite_inferiore IS 'Limite inferiore incluso per le fasce positive.';
COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.nr_limite_superiore IS 'Limite superiore escluso; NULL indica assenza di limite massimo.';
COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.nr_ordinamento IS 'Ordine di presentazione della fascia.';
COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.fl_attivo IS '1 fascia attiva; 0 fascia non utilizzabile nelle nuove classificazioni.';
