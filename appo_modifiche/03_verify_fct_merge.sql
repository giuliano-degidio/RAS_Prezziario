-- Diagnostica read-only del merge delle fact prezzi.
-- Non modifica viste, procedure o tabelle.
-- Eseguire prima e dopo una chiamata alle procedure prc_main.

-- Conteggi generali e numero di righe che differiscono realmente.
SELECT
    'fct_prezzi_approvati' AS flusso,
    (SELECT count(*) FROM hcbi_ras.v_fct_prezzi_approvati_src) AS righe_sorgente,
    (SELECT count(*) FROM hcbi_ras.fct_prezzi_approvati) AS righe_fact,
    (
        SELECT count(*)
        FROM hcbi_ras.v_fct_prezzi_approvati_src s
        JOIN hcbi_ras.fct_prezzi_approvati f
          ON f.id_prezzi_approvati = s.id_prezzi_approvati
        WHERE ROW(
                  f.id_periodo_pubblicazione,
                  f.id_anag_provincia,
                  f.id_anag_versione,
                  f.id_anag_articolo,
                  f.nr_prezzo,
                  f.dt_approvazione
              ) IS DISTINCT FROM ROW(
                  s.id_periodo_pubblicazione,
                  s.id_anag_provincia,
                  s.id_anag_versione,
                  s.id_anag_articolo,
                  s.nr_prezzo,
                  s.dt_approvazione
              )
    ) AS aggiornamenti_reali,
    (
        SELECT count(*)
        FROM hcbi_ras.v_fct_prezzi_approvati_src s
        LEFT JOIN hcbi_ras.fct_prezzi_approvati f
          ON f.id_prezzi_approvati = s.id_prezzi_approvati
        WHERE f.id_prezzi_approvati IS NULL
    ) AS nuovi_record
UNION ALL
SELECT
    'fct_prezzi_rilevati',
    (SELECT count(*) FROM hcbi_ras.v_fct_prezzi_rilevati_src),
    (SELECT count(*) FROM hcbi_ras.fct_prezzi_rilevati),
    (
        SELECT count(*)
        FROM hcbi_ras.v_fct_prezzi_rilevati_src s
        JOIN hcbi_ras.fct_prezzi_rilevati f
          ON f.id_prezzi_rilevati = s.id_prezzi_rilevati
        WHERE ROW(
                  f.id_periodo_pubblicazione,
                  f.id_anag_provincia,
                  f.id_anag_versione,
                  f.id_anag_articolo,
                  f.id_anag_informatore,
                  f.id_anag_utente_rilevatore,
                  f.nr_prezzo,
                  f.dt_inserimento,
                  f.fl_nascosto,
                  f.ds_anno_ribaltamento,
                  f.cd_versione_ribaltamento,
                  f.dt_last_update
              ) IS DISTINCT FROM ROW(
                  s.id_periodo_pubblicazione,
                  s.id_anag_provincia,
                  s.id_anag_versione,
                  s.id_anag_articolo,
                  s.id_anag_informatore,
                  s.id_anag_utente_rilevatore,
                  s.nr_prezzo,
                  s.dt_inserimento,
                  s.fl_nascosto,
                  s.ds_anno_ribaltamento,
                  s.cd_versione_ribaltamento,
                  s.dt_last_update
              )
    ),
    (
        SELECT count(*)
        FROM hcbi_ras.v_fct_prezzi_rilevati_src s
        LEFT JOIN hcbi_ras.fct_prezzi_rilevati f
          ON f.id_prezzi_rilevati = s.id_prezzi_rilevati
        WHERE f.id_prezzi_rilevati IS NULL
    );

-- Verifica dei contatori registrati dagli ultimi run.
SELECT id_log,
       ds_step_name,
       ds_status,
       nr_rec_selected,
       nr_rec_inserted,
       nr_rec_updated,
       nr_rec_errors,
       dt_start,
       dt_end
FROM hcbi_utility.log_step
WHERE ds_step_name IN (
    'ras-Popolamento tabella fct_prezzi_approvati.prc_main',
    'ras-Popolamento tabella fct_prezzi_rilevati.prc_main'
)
ORDER BY id_log DESC
LIMIT 20;
