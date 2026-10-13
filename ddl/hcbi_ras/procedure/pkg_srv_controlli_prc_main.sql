CREATE OR REPLACE PROCEDURE hcbi_ras.pkg_srv_controlli_prc_main(IN p_id_chain_log bigint, IN p_id_chain bigint, IN p_id_step bigint, IN p_ds_step_name character varying, OUT p_result integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_ras', 'hcbi_utility'
AS $procedure$
DECLARE
    rec record;

    v_id_log bigint;

    v_sql text;

    v_selected   bigint := 0;
    v_inserted   bigint := 0;
    v_updated    bigint := 0;
    v_deleted    bigint := 0;
    v_rec_errors bigint := 0;

    v_inserted_view  bigint := 0;
    v_total_inserted bigint := 0;
    v_total_views    bigint := 0;
    v_total_errors   bigint := 0;

    v_error_message text;
BEGIN
    /*
     * La procedura parte con esito positivo.
     * Diventa -1 se almeno una vista genera un errore.
     */
    p_result := 1;

    RAISE NOTICE
        'Avvio PKG_SRV_CONTROLLI per la chain %, step %',
        p_id_chain,
        p_ds_step_name;

    /*
     * Apertura del log generale dello step.
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

    /*
     * Ricerca dinamica di tutte le viste di controllo presenti
     * nello schema hcbi_ras.
     *
     * La vista placeholder:
     *
     *   hcbi_ras.v_srv_controlli_ras_anag_ripetute
     *
     * è già compatibile e, finché non sarà implementata la logica
     * definitiva, restituirà zero righe.
     */
    FOR rec IN
        SELECT
            v.schemaname AS view_schema,
            v.viewname   AS view_name
        FROM pg_catalog.pg_views v
        WHERE v.schemaname = 'hcbi_ras'
          AND v.viewname LIKE 'v\_srv\_controlli\_%' ESCAPE '\'
        ORDER BY v.viewname
    LOOP
        v_total_views := v_total_views + 1;
        v_inserted_view := 0;

        BEGIN
            /*
             * Ogni vista di controllo deve esporre almeno la colonna:
             *
             *   ds_tipo_controllo
             *
             * La logica Oracle raggruppa le righe per tale colonna
             * e inserisce nella tabella SRV_CONTROLLI:
             *
             *   - nome qualificato della vista;
             *   - tipo di controllo;
             *   - conteggio delle occorrenze.
             */
            IF NOT EXISTS
            (
                SELECT 1
                FROM information_schema.columns c
                WHERE c.table_schema = rec.view_schema
                  AND c.table_name = rec.view_name
                  AND c.column_name = 'ds_tipo_controllo'
            ) THEN
                RAISE EXCEPTION
                    'La vista %.% non espone la colonna obbligatoria ds_tipo_controllo',
                    rec.view_schema,
                    rec.view_name;
            END IF;

            v_sql :=
                format
                (
                    $dynamic_sql$
                    INSERT INTO hcbi_ras.srv_controlli
                    (
                        dt_data_check,
                        id_chain_log,
                        id_chain,
                        ds_tipo_controllo,
                        ds_oggetto_controllo,
                        ds_risultato_controllo
                    )
                    SELECT
                        clock_timestamp()::timestamp,
                        $1,
                        $2,
                        src.ds_tipo_controllo::varchar(4000),
                        $3,
                        (
                            'Occorrenze da verificare : '
                            || count(*)::text
                        )::varchar(4000)
                    FROM %I.%I src
                    GROUP BY src.ds_tipo_controllo
                    $dynamic_sql$,
                    rec.view_schema,
                    rec.view_name
                );

            RAISE NOTICE
                'Esecuzione vista di controllo %.%',
                rec.view_schema,
                rec.view_name;

            EXECUTE v_sql
            USING
                p_id_chain_log,
                p_id_chain,
                rec.view_schema || '.' || rec.view_name;

            GET DIAGNOSTICS v_inserted_view = ROW_COUNT;

            v_total_inserted :=
                v_total_inserted + coalesce(v_inserted_view, 0);

            RAISE NOTICE
                'Vista %.% elaborata: inserite % righe in hcbi_ras.srv_controlli',
                rec.view_schema,
                rec.view_name,
                v_inserted_view;

        EXCEPTION
            WHEN OTHERS THEN
                /*
                 * L'errore sulla singola vista viene registrato,
                 * ma l'elaborazione continua con le viste successive.
                 */
                v_total_errors := v_total_errors + 1;

                v_error_message :=
                    rec.view_schema
                    || '.'
                    || rec.view_name
                    || ': '
                    || SQLSTATE
                    || ': '
                    || SQLERRM;

                RAISE WARNING
                    'Errore durante l''esecuzione della vista %.%. SQLSTATE=%, errore=%',
                    rec.view_schema,
                    rec.view_name,
                    SQLSTATE,
                    SQLERRM;

                /*
                 * Inserimento diretto dell'anomalia nella tabella
                 * dei controlli. In questo modo l'errore della vista
                 * resta visibile anche nel risultato applicativo.
                 */
                BEGIN
                    INSERT INTO hcbi_ras.srv_controlli
                    (
                        dt_data_check,
                        id_chain_log,
                        id_chain,
                        ds_tipo_controllo,
                        ds_oggetto_controllo,
                        ds_risultato_controllo
                    )
                    VALUES
                    (
                        clock_timestamp()::timestamp,
                        p_id_chain_log,
                        p_id_chain,
                        'ERRORE_ESECUZIONE_CONTROLLO',
                        rec.view_schema || '.' || rec.view_name,
                        left(v_error_message, 4000)
                    );

                    v_total_inserted := v_total_inserted + 1;

                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE WARNING
                            'Impossibile registrare in srv_controlli l''errore della vista %.%: %',
                            rec.view_schema,
                            rec.view_name,
                            SQLERRM;
                END;
        END;
    END LOOP;

    v_selected   := v_total_views;
    v_inserted   := v_total_inserted;
    v_rec_errors := v_total_errors;

    /*
     * Chiusura del log generale.
     */
    IF v_total_errors = 0 THEN
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

        p_result := 1;

        RAISE NOTICE
            'PKG_SRV_CONTROLLI completato. Viste esaminate: %, righe inserite: %',
            v_total_views,
            v_total_inserted;

    ELSE
        v_error_message :=
            'PKG_SRV_CONTROLLI completato con errori. '
            || 'Viste esaminate: '
            || v_total_views
            || '; errori: '
            || v_total_errors
            || '; righe inserite: '
            || v_total_inserted;

        CALL hcbi_utility.pkg_log_prc_error_update_log
        (
            v_id_log,
            'FAILED',
            left(v_error_message, 4000),
            clock_timestamp()::timestamp,
            p_ds_step_name
        );

        p_result := -1;

        RAISE WARNING '%', v_error_message;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        p_result := -1;

        v_error_message :=
            'PKG_SRV_CONTROLLI.PRC_MAIN: '
            || SQLSTATE
            || ': '
            || SQLERRM;

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
                        'Errore durante la registrazione del log generale: %',
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING
            'Errore generale in pkg_srv_controlli_prc_main. SQLSTATE=%, errore=%',
            SQLSTATE,
            SQLERRM;
END;
$procedure$
