INSERT INTO hcbi_ras.frontiera_prezzi_approvati (
    codice, anno, prezzo, provincia, data_approvazione, addendum
)
SELECT
    pa.codice,
    pa.anno::character varying(100) AS anno,
    pa.prezzo::character varying(100) AS prezzo,
    pa.provincia::character varying(100) AS provincia,
    pa.data_approvazione,
    pa.addendum::character varying(20) AS addendum
FROM public.prezzi_approvati AS pa
ORDER BY pa.codice, pa.anno, pa.provincia;
