INSERT INTO hcbi_ras.frontiera_prezzi_rilevati (
    codice, anno, provincia, informatore, rilevatore, prezzo,
    data_inserimento, nascosto, ribaltato_da_anno,
    addendum, ribaltato_da_addendum, last_update
)
SELECT
    pr.codice,
    pr.anno::character varying(100) AS anno,
    pr.provincia::character varying(100) AS provincia,
    pr.informatore::character varying(100) AS informatore,
    pr.rilevatore::character varying(100) AS rilevatore,
    pr.prezzo::character varying(100) AS prezzo,
    pr.data_inserimento,
    pr.nascosto::character varying(20) AS nascosto,
    pr.ribaltato_da_anno::character varying(100) AS ribaltato_da_anno,
    pr.addendum::character varying(20) AS addendum,
    pr.ribaltato_da_addendum::character varying(100) AS ribaltato_da_addendum,
    pr.last_update
FROM public.prezzi_rilevati AS pr
ORDER BY pr.codice, pr.anno, pr.provincia;
