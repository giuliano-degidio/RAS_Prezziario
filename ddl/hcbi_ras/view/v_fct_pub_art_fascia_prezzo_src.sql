CREATE OR REPLACE VIEW hcbi_ras.v_fct_pub_art_fascia_prezzo_src AS
SELECT
    f.id_pubblicazione_articoli,
    CASE
        WHEN f.nr_prezzo IS NULL THEN 0::smallint
        WHEN f.nr_prezzo < 0 THEN -1::smallint
        ELSE COALESCE(fp.id_fascia_prezzo, -1::smallint)
    END AS id_fascia_prezzo,
    f.nr_prezzo,
    NULLIF(concat_ws('; ',
        CASE
            WHEN f.nr_prezzo < 0
            THEN 'NR_PREZZO negativo: applicato ID_FASCIA_PREZZO = -1'
        END,
        CASE
            WHEN f.nr_prezzo IS NOT NULL
             AND f.nr_prezzo >= 0
             AND fp.id_fascia_prezzo IS NULL
            THEN 'DIM_FASCIA_PREZZO non risolta: applicato -1'
        END
    ), '')::varchar(4000) AS tx_motivo_lookup
FROM hcbi_ras.fct_pubblicazione_articoli AS f
LEFT JOIN hcbi_ras.dim_fascia_prezzo AS fp
  ON fp.fl_attivo = 1
 AND fp.id_fascia_prezzo > 0
 AND f.nr_prezzo >= fp.nr_limite_inferiore
 AND (
        fp.nr_limite_superiore IS NULL
        OR f.nr_prezzo < fp.nr_limite_superiore
     );
