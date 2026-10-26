/* =====================================================================
   V_FCT_PUBBLICAZIONE_ARTICOLI_BI - VERSIONE 01
   Target: PostgreSQL 15.9 / 17
   Schema: hcbi_ras

   Obiettivo:
     esporre a Power BI tutte le colonne della fact pubblicazione articoli
     e la chiave ID_FASCIA_PREZZO calcolata dal flusso dedicato.

   Grain:
     una riga per ID_PUBBLICAZIONE_ARTICOLI.

   Dipendenze:
     - HCBI_RAS.FCT_PUBBLICAZIONE_ARTICOLI;
     - HCBI_RAS.FCT_PUBBLICAZIONE_ARTICOLI_FASCIA_PREZZO;
     - HCBI_RAS.DIM_FASCIA_PREZZO.

   Nota:
     la LEFT JOIN preserva tutte le righe della fact anche se il flusso
     fascia prezzo non e' ancora allineato. ID_FASCIA_PREZZO NULL deve
     essere considerato un errore di orchestrazione o riconciliazione.
   ===================================================================== */

CREATE OR REPLACE VIEW hcbi_ras.v_fct_pubblicazione_articoli_bi AS
SELECT
    f.id_pubblicazione_articoli,
    f.id_periodo_pubblicazione,
    f.id_anag_provincia,
    f.id_anag_versione,
    f.id_anag_articolo,
    f.id_anag_tipologia,
    f.id_anag_capitolo,
    f.id_anag_sottocapitolo,
    f.id_anag_unita_misura,
    f.id_anag_macro_gruppo,
    fp.id_fascia_prezzo,

    f.cd_codice_completo,
    f.cd_categoria_articolo,
    f.cd_subarticolo,
    f.ds_unita_misura_de,
    f.id_sorgente_categoria,
    f.id_sorgente_pubblicazione_articoli,

    f.nr_prezzo,
    f.nr_prezzo_annuo,
    f.nr_perc_spese,
    f.nr_perc_utile,
    f.nr_sicur,
    f.nr_perc_manodopera,
    f.nr_perc_oneri,
    f.nr_prezzo_manodopera,
    f.nr_perc_manodopera_dir,
    f.nr_prezzo_manodopera_dir,
    f.nr_spese,
    f.nr_utili,

    f.fl_isanalisi,
    f.fl_is_minuteria,
    f.fl_ifc_scaricabile,

    f.dt_creation,
    f.tx_creation_by,
    f.dt_update,
    f.tx_update_by,
    f.dt_reciclo
FROM hcbi_ras.fct_pubblicazione_articoli AS f
LEFT JOIN hcbi_ras.fct_pubblicazione_articoli_fascia_prezzo AS fp
  ON fp.id_pubblicazione_articoli = f.id_pubblicazione_articoli;

ALTER VIEW hcbi_ras.v_fct_pubblicazione_articoli_bi OWNER TO hcbi_ras;

GRANT SELECT
ON hcbi_ras.v_fct_pubblicazione_articoli_bi
TO hcbi_ras, hcbi_utility;

COMMENT ON VIEW hcbi_ras.v_fct_pubblicazione_articoli_bi IS
'Vista di consumo Power BI della fact pubblicazione articoli, arricchita con ID_FASCIA_PREZZO. Grain una riga per ID_PUBBLICAZIONE_ARTICOLI.';

COMMENT ON COLUMN hcbi_ras.v_fct_pubblicazione_articoli_bi.id_fascia_prezzo IS
'FK verso DIM_FASCIA_PREZZO, derivata dalla factless fact FCT_PUBBLICAZIONE_ARTICOLI_FASCIA_PREZZO.';

/* =====================================================================
   TEST POST-DEPLOYMENT
   ===================================================================== */

/* T01 - Riconciliazione del grain. I conteggi devono coincidere. */
-- SELECT
--   (SELECT count(*)
--    FROM hcbi_ras.fct_pubblicazione_articoli) AS nr_fact,
--   (SELECT count(*)
--    FROM hcbi_ras.v_fct_pubblicazione_articoli_bi) AS nr_vista;

/* T02 - Duplicati. Atteso zero righe. */
-- SELECT id_pubblicazione_articoli, count(*)
-- FROM hcbi_ras.v_fct_pubblicazione_articoli_bi
-- GROUP BY id_pubblicazione_articoli
-- HAVING count(*) > 1;

/* T03 - Fasce mancanti. Atteso 0 dopo il completamento del flusso. */
-- SELECT count(*) AS nr_fasce_mancanti
-- FROM hcbi_ras.v_fct_pubblicazione_articoli_bi
-- WHERE id_fascia_prezzo IS NULL;

/* T04 - Orfani verso DIM_FASCIA_PREZZO. Atteso 0. */
-- SELECT count(*) AS nr_orfani
-- FROM hcbi_ras.v_fct_pubblicazione_articoli_bi AS v
-- LEFT JOIN hcbi_ras.dim_fascia_prezzo AS d
--   ON d.id_fascia_prezzo = v.id_fascia_prezzo
-- WHERE v.id_fascia_prezzo IS NOT NULL
--   AND d.id_fascia_prezzo IS NULL;
