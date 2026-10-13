CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_delete_data_fct_dynamic_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    rec record;

    v_id_log bigint;

    v_sql_original text;
    v_sql          text;

    v_selected    bigint := 0;
    v_inserted    bigint := 0;
    v_updated     bigint := 0;
    v_deleted     bigint := 0;
    v_rec_errors  bigint := 0;

    v_total_deleted bigint := 0;
    v_total_errors  bigint := 0;

    v_error_message text;
BEGIN
    /*
     * La procedura parte con esito positivo.
     * Se almeno uno statement fallisce, il risultato finale diventa -1.
     */
    p_result := 1;

    RAISE NOTICE
        'Avvio svecchiamento dinamico per la chain %',
        p_id_chain;

    /*
     * Lettura delle istruzioni SQL nell'ordine configurato.
     */
    FOR rec IN
        SELECT
            s.id_config,
            s.ds_table_name,
            s.ds_stm_svecchiamento,
            s.nr_ordine
        FROM hcbi_utility.srv_svecchiamento_fct s
        WHERE s.fl_active = 'Y'
          AND s.id_chain = p_id_chain
        ORDER BY s.nr_ordine, s.id_config
    LOOP
        v_id_log := NULL;

        v_selected   := 0;
        v_inserted   := 0;
        v_updated    := 0;
        v_deleted    := 0;
        v_rec_errors := 0;

        BEGIN
            /*
             * Validazione della configurazione.
             */
            IF rec.ds_stm_svecchiamento IS NULL
               OR btrim(rec.ds_stm_svecchiamento) = '' THEN
                RAISE EXCEPTION
                    'Statement di svecchiamento non valorizzato per ID_CONFIG %, tabella %',
                    rec.id_config,
                    rec.ds_table_name;
            END IF;

            v_sql_original := btrim(rec.ds_stm_svecchiamento);

            /*
             * Conversione del riferimento allo schema Oracle.
             *
             * La sostituzione viene eseguita senza distinzione
             * tra maiuscole e minuscole.
             */
            v_sql :=
                regexp_replace
                (
                    v_sql_original,
                    'HCBI_PS\.',
                    'hcbi_ras.',
                    'gi'
                );

            /*
             * Rimozione dell'eventuale punto e virgola finale.
             * PL/pgSQL EXECUTE deve ricevere una singola istruzione SQL.
             */
            v_sql :=
                regexp_replace
                (
                    btrim(v_sql),
                    ';[[:space:]]*$',
                    ''
                );

            /*
             * Per sicurezza questa routine deve eseguire esclusivamente
             * istruzioni DELETE.
             */
            IF v_sql !~* '^[[:space:]]*DELETE[[:space:]]+FROM[[:space:]]+' THEN
                RAISE EXCEPTION
                    'Statement non consentito per ID_CONFIG %: è prevista esclusivamente una DELETE',
                    rec.id_config;
            END IF;

            /*
             * Apertura del log per la singola tabella sottoposta
             * a svecchiamento.
             */
            SELECT hcbi_utility.pkg_log_fnc_insert_log
            (
                p_id_chain_log,
                p_id_chain,
                p_id_step,
                p_ds_step_name,
                clock_timestamp()::timestamp,
                clock_timestamp()::timestamp,
                p_ds_step_name
            )
            INTO v_id_log;

            RAISE NOTICE
                'Esecuzione svecchiamento tabella %, ordine %',
                rec.ds_table_name,
                rec.nr_ordine;

            RAISE NOTICE
                'SQL: %',
                v_sql;

            /*
             * Esecuzione della DELETE configurata.
             */
            EXECUTE v_sql;

            /*
             * Recupero del numero di righe eliminate.
             */
            GET DIAGNOSTICS v_deleted = ROW_COUNT;

            v_total_deleted :=
                v_total_deleted + coalesce(v_deleted, 0);

            RAISE NOTICE
                'Tabella % svecchiata: eliminate % righe',
                rec.ds_table_name,
                v_deleted;

            /*
             * Chiusura positiva del log.
             */
            CALL hcbi_utility.pkg_log_prc_update_log
            (
                v_id_log,
                v_selected,
                v_inserted,
                v_updated,
                v_deleted,
                v_rec_errors,
                'SUCCESS',
                clock_timestamp()::timestamp,
                p_ds_step_name
            );

        EXCEPTION
            WHEN OTHERS THEN
                /*
                 * L'errore della singola DELETE viene registrato,
                 * ma il ciclo prosegue con le configurazioni successive,
                 * come nel package Oracle.
                 */
                p_result := -1;

                v_rec_errors  := 1;
                v_total_errors := v_total_errors + 1;

                v_error_message :=
                    coalesce(rec.ds_table_name, '<tabella non indicata>')
                    || ': '
                    || SQLSTATE
                    || ': '
                    || SQLERRM;

                RAISE WARNING
                    'Errore nello svecchiamento della tabella %. SQLSTATE=%, errore=%',
                    coalesce(rec.ds_table_name, '<tabella non indicata>'),
                    SQLSTATE,
                    SQLERRM;

                IF v_id_log IS NOT NULL THEN
                    BEGIN
                        CALL hcbi_utility.pkg_log_prc_error_update_log
                        (
                            v_id_log,
                            'FAILED',
                            left(v_error_message, 4000),
                            clock_timestamp()::timestamp,
                            p_ds_step_name
                        );

                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE WARNING
                                'Errore nella registrazione del log per la tabella %: %',
                                coalesce(
                                    rec.ds_table_name,
                                    '<tabella non indicata>'
                                ),
                                SQLERRM;
                    END;
                END IF;
        END;
    END LOOP;

    /*
     * Esito finale.
     */
    IF v_total_errors = 0 THEN
        p_result := 1;

        RAISE NOTICE
            'Svecchiamento completato per la chain %. Totale righe eliminate: %',
            p_id_chain,
            v_total_deleted;
    ELSE
        p_result := -1;

        RAISE WARNING
            'Svecchiamento completato con errori per la chain %. Errori: %, righe eliminate: %',
            p_id_chain,
            v_total_errors,
            v_total_deleted;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        /*
         * Gestione di eventuali errori esterni al ciclo.
         */
        p_result := -1;

        RAISE WARNING
            'Errore generale in pkg_delete_data_fct_dynamic_prc_main. SQLSTATE=%, errore=%',
            SQLSTATE,
            SQLERRM;
END;
$procedure$
