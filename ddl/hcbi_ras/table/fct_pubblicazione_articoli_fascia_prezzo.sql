CREATE TABLE IF NOT EXISTS hcbi_ras.fct_pubblicazione_articoli_fascia_prezzo
(
    id_pubblicazione_articoli bigint NOT NULL,
    id_fascia_prezzo smallint NOT NULL,

    dt_creation timestamp without time zone
        NOT NULL DEFAULT clock_timestamp(),
    tx_creation_by varchar(4000)
        NOT NULL DEFAULT CURRENT_USER,
    dt_update timestamp without time zone
        NOT NULL DEFAULT clock_timestamp(),
    tx_update_by varchar(4000)
        NOT NULL DEFAULT CURRENT_USER,

    CONSTRAINT pk_fct_pub_art_fascia_prezzo
        PRIMARY KEY (id_pubblicazione_articoli),

    CONSTRAINT fk_fct_pub_art_fp_pubblicazione
        FOREIGN KEY (id_pubblicazione_articoli)
        REFERENCES hcbi_ras.fct_pubblicazione_articoli
            (id_pubblicazione_articoli)
        ON UPDATE RESTRICT
        ON DELETE CASCADE,

    CONSTRAINT fk_fct_pub_art_fp_fascia
        FOREIGN KEY (id_fascia_prezzo)
        REFERENCES hcbi_ras.dim_fascia_prezzo
            (id_fascia_prezzo)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);
