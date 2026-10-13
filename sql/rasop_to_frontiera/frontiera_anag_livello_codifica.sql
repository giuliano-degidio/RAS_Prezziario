INSERT INTO hcbi_ras.frontiera_anag_livello_codifica (id, nome, plurale)
SELECT
    lc.id::character varying(100) AS id,
    lc.nome,
    lc.plurale
FROM public.livelli_codifica AS lc
ORDER BY lc.id;
