-- Diagnostica read-only del rapporto tra prc_initialize e prc_main.
-- Non modifica il database.

-- Le righe con almeno una chiave tecnica -1 sono quelle che prc_initialize
-- marca nel DWH con dt_reciclo e contabilizza come nr_rec_updated.
SELECT
    'fct_prezzi_approvati' AS flusso,
    count(*) AS righe_fact,
    count(*) FILTER (
        WHERE id_periodo_pubblicazione = -1
           OR id_anag_provincia = -1
           OR id_anag_versione = -1
           OR id_anag_articolo = -1
    ) AS righe_con_chiave_tecnica,
    count(*) FILTER (WHERE dt_reciclo IS NOT NULL) AS righe_dwh_in_riciclo
FROM hcbi_ras.fct_prezzi_approvati f
JOIN hcbi_ras.dwh_prezzi_approvati d USING (id_prezzi_approvati)
UNION ALL
SELECT
    'fct_prezzi_rilevati',
    count(*),
    count(*) FILTER (
        WHERE id_periodo_pubblicazione = -1
           OR id_anag_provincia = -1
           OR id_anag_versione = -1
           OR id_anag_articolo = -1
           OR id_anag_informatore = -1
           OR id_anag_utente_rilevatore = -1
    ),
    count(*) FILTER (WHERE dt_reciclo IS NOT NULL)
FROM hcbi_ras.fct_prezzi_rilevati f
JOIN hcbi_ras.dwh_prezzi_rilevati d USING (id_prezzi_rilevati);

-- Stato dei run indicati nell'analisi.
SELECT id_log,
       ds_step_name,
       nr_rec_selected,
       nr_rec_inserted,
       nr_rec_updated,
       nr_rec_errors,
       dt_start,
       dt_end
FROM hcbi_utility.log_step
WHERE id_log IN (874, 875, 877, 878)
ORDER BY id_log;

-- Dopo il riallineamento, il numero di differenze residue deve essere zero.
SELECT 'approvati' AS flusso, count(*) AS differenze_residue
FROM hcbi_ras.v_fct_prezzi_approvati_src s
JOIN hcbi_ras.fct_prezzi_approvati f USING (id_prezzi_approvati)
WHERE ROW(f.id_periodo_pubblicazione,f.id_anag_provincia,
          f.id_anag_versione,f.id_anag_articolo,f.nr_prezzo,
          f.dt_approvazione)
   IS DISTINCT FROM
      ROW(s.id_periodo_pubblicazione,s.id_anag_provincia,
          s.id_anag_versione,s.id_anag_articolo,s.nr_prezzo,
          s.dt_approvazione)
UNION ALL
SELECT 'rilevati', count(*)
FROM hcbi_ras.v_fct_prezzi_rilevati_src s
JOIN hcbi_ras.fct_prezzi_rilevati f USING (id_prezzi_rilevati)
WHERE ROW(f.id_periodo_pubblicazione,f.id_anag_provincia,
          f.id_anag_versione,f.id_anag_articolo,f.id_anag_informatore,
          f.id_anag_utente_rilevatore,f.nr_prezzo,f.dt_inserimento,
          f.fl_nascosto,f.ds_anno_ribaltamento,
          f.cd_versione_ribaltamento,f.dt_last_update)
   IS DISTINCT FROM
      ROW(s.id_periodo_pubblicazione,s.id_anag_provincia,
          s.id_anag_versione,s.id_anag_articolo,s.id_anag_informatore,
          s.id_anag_utente_rilevatore,s.nr_prezzo,s.dt_inserimento,
          s.fl_nascosto,s.ds_anno_ribaltamento,
          s.cd_versione_ribaltamento,s.dt_last_update);
