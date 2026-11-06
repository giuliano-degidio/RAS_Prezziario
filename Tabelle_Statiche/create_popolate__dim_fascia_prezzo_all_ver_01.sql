/* =====================================================================
   DIM_FASCIA_PREZZO - DDL E CONFIGURAZIONE - VERSIONE 01
   Target: PostgreSQL 15.9 / 17
   Schema: hcbi_ras

   Grain:
     una riga per fascia di prezzo logicamente distinta.

   Semantica:
     limite inferiore incluso;
     limite superiore escluso;
     limite superiore NULL = fascia aperta verso l'alto.

   Membri tecnici:
     -1 = fascia non determinata;
      0 = prezzo non disponibile.

   Assunzioni da validare:
     - NR_PREZZO e' espresso in euro;
     - un prezzo negativo e' un'anomalia;
     - le soglie sono gestite in modalita Type 1.
   ===================================================================== */

BEGIN;

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
REVOKE ALL ON TABLE hcbi_ras.dim_fascia_prezzo FROM hcbi_utility;
GRANT ALL ON TABLE hcbi_ras.dim_fascia_prezzo TO hcbi_ras;
GRANT SELECT ON TABLE hcbi_ras.dim_fascia_prezzo TO hcbi_utility;

COMMENT ON TABLE hcbi_ras.dim_fascia_prezzo IS
'Dimensione delle fasce applicate a NR_PREZZO.';
COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.id_fascia_prezzo IS
'PK. -1 fascia non determinata; 0 prezzo non disponibile.';
COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.cd_fascia_prezzo IS
'Codice funzionale stabile della fascia.';
COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.ds_fascia_prezzo IS
'Descrizione della fascia per il livello semantico.';
COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.nr_limite_inferiore IS
'Limite inferiore incluso per le fasce positive.';
COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.nr_limite_superiore IS
'Limite superiore escluso; NULL indica assenza di limite massimo.';
COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.nr_ordinamento IS
'Ordine di presentazione della fascia.';
COMMENT ON COLUMN hcbi_ras.dim_fascia_prezzo.fl_attivo IS
'1 fascia attiva; 0 fascia non utilizzabile nelle nuove classificazioni.';

INSERT INTO hcbi_ras.dim_fascia_prezzo
(
    id_fascia_prezzo,
    cd_fascia_prezzo,
    ds_fascia_prezzo,
    nr_limite_inferiore,
    nr_limite_superiore,
    nr_ordinamento,
    fl_attivo
)
VALUES
    (-1, 'ND',   'Fascia non determinata',        NULL, NULL, -1, 1),
    ( 0, 'NA',   'Prezzo non disponibile',        NULL, NULL,  0, 1),
    ( 1, 'P001', 'Meno di 100 euro',                 0,  100,  1, 1),
    ( 2, 'P002', 'Da 100 a meno di 500 euro',      100,  500,  2, 1),
    ( 3, 'P003', 'Da 500 a meno di 1.000 euro',    500, 1000,  3, 1),
    ( 4, 'P004', 'Da 1.000 a meno di 3.000 euro', 1000, 3000,  4, 1),
    ( 5, 'P005', 'Da 3.000 a meno di 5.000 euro', 3000, 5000,  5, 1),
    ( 6, 'P006', '5.000 euro e oltre',             5000, NULL,  6, 1)
ON CONFLICT (id_fascia_prezzo) DO UPDATE
SET
    cd_fascia_prezzo = EXCLUDED.cd_fascia_prezzo,
    ds_fascia_prezzo = EXCLUDED.ds_fascia_prezzo,
    nr_limite_inferiore = EXCLUDED.nr_limite_inferiore,
    nr_limite_superiore = EXCLUDED.nr_limite_superiore,
    nr_ordinamento = EXCLUDED.nr_ordinamento,
    fl_attivo = EXCLUDED.fl_attivo,
    dt_update = clock_timestamp(),
    tx_update_by = CURRENT_USER
WHERE ROW(
        hcbi_ras.dim_fascia_prezzo.cd_fascia_prezzo,
        hcbi_ras.dim_fascia_prezzo.ds_fascia_prezzo,
        hcbi_ras.dim_fascia_prezzo.nr_limite_inferiore,
        hcbi_ras.dim_fascia_prezzo.nr_limite_superiore,
        hcbi_ras.dim_fascia_prezzo.nr_ordinamento,
        hcbi_ras.dim_fascia_prezzo.fl_attivo
      ) IS DISTINCT FROM ROW(
        EXCLUDED.cd_fascia_prezzo,
        EXCLUDED.ds_fascia_prezzo,
        EXCLUDED.nr_limite_inferiore,
        EXCLUDED.nr_limite_superiore,
        EXCLUDED.nr_ordinamento,
        EXCLUDED.fl_attivo
      );

DO $BODY$
DECLARE
    v_open_count integer;
    v_overlap_count bigint;
    v_gap_count bigint;
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_fascia_prezzo
        WHERE id_fascia_prezzo = -1
          AND fl_attivo = 1
    ) OR NOT EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_fascia_prezzo
        WHERE id_fascia_prezzo = 0
          AND fl_attivo = 1
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = '23503',
            MESSAGE = 'Membri tecnici mancanti in DIM_FASCIA_PREZZO',
            DETAIL = 'Sono obbligatori i membri attivi -1 e 0.';
    END IF;

    SELECT count(*)
    INTO v_open_count
    FROM hcbi_ras.dim_fascia_prezzo
    WHERE id_fascia_prezzo > 0
      AND fl_attivo = 1
      AND nr_limite_superiore IS NULL;

    IF v_open_count <> 1 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Configurazione fascia aperta non valida',
            DETAIL = 'Deve esistere una sola fascia positiva attiva con limite superiore NULL.';
    END IF;

    SELECT count(*)
    INTO v_overlap_count
    FROM hcbi_ras.dim_fascia_prezzo AS a
    JOIN hcbi_ras.dim_fascia_prezzo AS b
      ON a.id_fascia_prezzo < b.id_fascia_prezzo
     AND a.id_fascia_prezzo > 0
     AND b.id_fascia_prezzo > 0
     AND a.fl_attivo = 1
     AND b.fl_attivo = 1
     AND COALESCE(a.nr_limite_superiore, 1e30::numeric)
           > b.nr_limite_inferiore
     AND COALESCE(b.nr_limite_superiore, 1e30::numeric)
           > a.nr_limite_inferiore;

    IF v_overlap_count > 0 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Sovrapposizione in DIM_FASCIA_PREZZO',
            DETAIL = 'Le fasce positive attive devono essere non sovrapposte.';
    END IF;

    WITH fasce AS
    (
        SELECT
            nr_limite_inferiore,
            nr_limite_superiore,
            lead(nr_limite_inferiore) OVER (
                ORDER BY nr_limite_inferiore
            ) AS limite_successivo
        FROM hcbi_ras.dim_fascia_prezzo
        WHERE id_fascia_prezzo > 0
          AND fl_attivo = 1
    )
    SELECT count(*)
    INTO v_gap_count
    FROM fasce
    WHERE nr_limite_superiore IS NOT NULL
      AND nr_limite_superiore IS DISTINCT FROM limite_successivo;

    IF v_gap_count > 0 OR NOT EXISTS (
        SELECT 1
        FROM hcbi_ras.dim_fascia_prezzo
        WHERE id_fascia_prezzo > 0
          AND fl_attivo = 1
          AND nr_limite_inferiore = 0
    ) THEN
        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'Copertura non continua in DIM_FASCIA_PREZZO',
            DETAIL = 'Le fasce positive attive devono coprire da zero a infinito senza buchi.';
    END IF;
END;
$BODY$;

ANALYZE hcbi_ras.dim_fascia_prezzo;

COMMIT;

/* TEST POST-DEPLOYMENT

T01 - Contenuto atteso: 8 righe.
SELECT *
FROM hcbi_ras.dim_fascia_prezzo
ORDER BY nr_ordinamento;

T02 - Fasce positive aperte: atteso 1.
SELECT count(*)
FROM hcbi_ras.dim_fascia_prezzo
WHERE id_fascia_prezzo > 0
  AND fl_attivo = 1
  AND nr_limite_superiore IS NULL;
*/
