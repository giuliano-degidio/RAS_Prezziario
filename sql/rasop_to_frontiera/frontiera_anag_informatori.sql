INSERT INTO hcbi_ras.frontiera_anag_informatori (
    id, ragione_sociale, p_iva, codice_ateco_2002,
    indirizzo_sede_legale, cap_sede_legale, citta_sede_legale,
    provincia_sede_legale, indirizzo_sede_operativa,
    cap_sede_operativa, citta_sede_operativa, provincia_sede_operativa,
    contatti, stato, note, stato_attivita, codice_fiscale, anno,
    last_update, nazione, addendum,
    escludi_invio_mail_assoc_listino_completa
)
SELECT
    i.id::character varying(100) AS id,
    i.ragione_sociale,
    i.p_iva,
    i.codice_ateco_2002,
    i.indirizzo_sede_legale,
    i.cap_sede_legale,
    i.citta_sede_legale,
    i.provincia_sede_legale,
    i.indirizzo_sede_operativa,
    i.cap_sede_operativa,
    i.citta_sede_operativa,
    i.provincia_sede_operativa,
    i.contatti,
    i.stato::character varying(20) AS stato,
    i.note,
    i.stato_attivita,
    i.codice_fiscale,
    i.anno::character varying(100) AS anno,
    i.last_update::character varying(100) AS last_update,
    i.nazione,
    i.addendum::character varying(20) AS addendum,
    i.escludi_invio_mail_assoc_listino_completa::character varying(20) AS escludi_invio_mail_assoc_listino_completa
FROM public.informatori AS i
ORDER BY i.id;
