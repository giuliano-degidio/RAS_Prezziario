INSERT INTO hcbi_ras.frontiera_anag_macro_gruppo (id, nome, plurale)
SELECT
    mg.id::character varying(100) AS id,
    mg.nome,
    mg.plurale
FROM public.macro_gruppi AS mg
ORDER BY mg.id;
