-- Tabella importata da foglio Excel.
-- Non esiste una query deterministicamente derivabile da rasop per tutti i campi.
-- Template best-effort basato su public.analisi.
INSERT INTO hcbi_ras.frontiera_firenze_analisi (
    nr_anno, ds_regione, ds_provincia, nr_riga_file, analisi,
    descrizione, cam, codice_dettaglio, cam_codice_dettaglio,
    voce_articolo, codice_collegato, unita_misura, quantita,
    prezzo_unitario, importo, tx_nome_file, dt_caricamento,
    tx_caricamento_by
)
SELECT
    a.anno::integer AS nr_anno,
    NULL::varchar(50) AS ds_regione,
    NULL::varchar(50) AS ds_provincia,
    row_number() OVER (ORDER BY a.id)::bigint AS nr_riga_file,
    a.codice_analisi,
    a.codice_elemento::text AS descrizione,
    NULL::text AS cam,
    a.codice_elemento::text AS codice_dettaglio,
    NULL::text AS cam_codice_dettaglio,
    NULL::text AS voce_articolo,
    a.id_codice_collegato::text AS codice_collegato,
    NULL::text AS unita_misura,
    a.quantita::text AS quantita,
    NULL::text AS prezzo_unitario,
    NULL::text AS importo,
    NULL::varchar(255) AS tx_nome_file,
    clock_timestamp()::timestamp AS dt_caricamento,
    current_user::varchar(100) AS tx_caricamento_by
FROM public.analisi AS a;
