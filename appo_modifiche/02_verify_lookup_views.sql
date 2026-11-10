-- Verifica da eseguire dopo l'applicazione delle viste.
-- Sola lettura: non modifica il database.

SELECT 'fct_prezzi_approvati' AS flusso,
       count(*) AS righe,
       count(*) FILTER (WHERE tx_motivo_lookup IS NOT NULL) AS righe_con_lookup_error
FROM hcbi_ras.v_fct_prezzi_approvati_src
UNION ALL
SELECT 'fct_prezzi_rilevati',
       count(*),
       count(*) FILTER (WHERE tx_motivo_lookup IS NOT NULL)
FROM hcbi_ras.v_fct_prezzi_rilevati_src;

SELECT tx_motivo_lookup, count(*) AS righe
FROM hcbi_ras.v_fct_prezzi_approvati_src
WHERE tx_motivo_lookup IS NOT NULL
GROUP BY tx_motivo_lookup
ORDER BY righe DESC;

SELECT tx_motivo_lookup, count(*) AS righe
FROM hcbi_ras.v_fct_prezzi_rilevati_src
WHERE tx_motivo_lookup IS NOT NULL
GROUP BY tx_motivo_lookup
ORDER BY righe DESC;

SELECT id_prezzi_approvati, id_periodo_pubblicazione,
       id_anag_provincia, id_anag_versione, id_anag_articolo,
       tx_motivo_lookup
FROM hcbi_ras.v_fct_prezzi_approvati_src
WHERE tx_motivo_lookup IS NOT NULL
LIMIT 20;

SELECT id_prezzi_rilevati, id_periodo_pubblicazione,
       id_anag_provincia, id_anag_versione, id_anag_articolo,
       id_anag_informatore, tx_motivo_lookup
FROM hcbi_ras.v_fct_prezzi_rilevati_src
WHERE tx_motivo_lookup IS NOT NULL
LIMIT 20;
