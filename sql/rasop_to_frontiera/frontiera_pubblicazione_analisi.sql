INSERT INTO hcbi_ras.frontiera_pubblicazione_analisi (
    anno, codice_analisi, quantita, codice_elemento, addendum, id,
    id_categoria, nr_riga
)
SELECT
    pa.anno::character varying(100) AS anno,
    pa.codice_analisi,
    pa.quantita::character varying(100) AS quantita,
    pa.codice_elemento,
    pa.addendum::character varying(20) AS addendum,
    pa.id::character varying(100) AS id,
    pa.id_categoria::character varying(20) AS id_categoria,
    row_number() OVER (ORDER BY pa.id)::smallint AS nr_riga
FROM public.pubblicazione_analisi AS pa
ORDER BY pa.id;
