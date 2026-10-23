CREATE OR REPLACE PROCEDURE hcbi_utility.prc_execute_chain(IN p_id_chain bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_utility'
AS $procedure$

DECLARE
    r_step                       record;
    r_stale_log                  record;

    v_id_log                     bigint;
    v_step_log_id                bigint;
    v_ds_step_name               text;
    v_ds_dependency_status       text;
    v_result                     integer;

    v_schema_name                text;
    v_package_name               text;
    v_procedure_name             text;
    v_procedure_phase            text;

    v_sql                        text;
    v_error_message              text;
    v_chain_error_message        text;
    v_error_detail               text;
    v_error_hint                 text;
    v_error_context              text;
    v_sqlstate                   text;

    v_chain_exists               boolean;
    v_non_blocking_error         boolean := false;
    v_blocking_error             boolean := false;

    v_procedure_phases           text[] := ARRAY[
        'prc_initialize',
        'prc_main',
        'prc_finalize'
    ];
BEGIN
    ----------------------------------------------------------------------
    -- Validazione del parametro
    ----------------------------------------------------------------------
    IF p_id_chain IS NULL THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '22004',
                MESSAGE = 'Il parametro p_id_chain non può essere NULL';
    END IF;

    ----------------------------------------------------------------------
    -- Verifica dell'esistenza e dell'attivazione della catena
    ----------------------------------------------------------------------
    SELECT EXISTS
           (
               SELECT 1
               FROM hcbi_utility.srv_config_chain c
               WHERE c.id_chain = p_id_chain
                 AND c.fl_active = 'Y'
           )
      INTO v_chain_exists;

    IF NOT v_chain_exists THEN
        RAISE EXCEPTION
            USING
                ERRCODE = 'P0001',
                MESSAGE = format(
                    'La catena %s non esiste oppure non è attiva',
                    p_id_chain
                );
    END IF;

    ----------------------------------------------------------------------
    -- Lock applicativo sulla catena
    --
    -- Impedisce che due sessioni eseguano contemporaneamente
    -- la stessa catena.
    ----------------------------------------------------------------------
    IF NOT pg_try_advisory_xact_lock(
        hashtext('hcbi_utility.prc_execute_chain')::integer,
        p_id_chain::integer
    ) THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '55006',
                MESSAGE = format(
                    'La catena %s risulta già in esecuzione',
                    p_id_chain
                );
    END IF;

    ----------------------------------------------------------------------
    -- Riconciliazione di log IN_PROGRESS rimasti da esecuzioni interrotte
    ----------------------------------------------------------------------
    -- A questo punto il lock advisory transazionale e' gia' stato acquisito.
    -- Un'altra esecuzione conforme di questa procedura non puo' essere attiva
    -- per la stessa catena; pertanto le righe IN_PROGRESS precedenti sono
    -- residui di sessioni terminate prima della chiusura del log.
    --
    -- La lettura e la chiusura avvengono via LOG_DBLINK: oltre a sopravvivere
    -- al rollback principale, la riconciliazione evita che un vecchio log
    -- blocchi per sempre le esecuzioni successive.
    ----------------------------------------------------------------------
    PERFORM hcbi_utility.ensure_dblink_logging();

    v_sql := format(
        $sql$
        SELECT id_log
          FROM hcbi_utility.log_chain
         WHERE id_chain = %L::bigint
           AND ds_status = 'IN_PROGRESS'
         ORDER BY id_log
        $sql$,
        p_id_chain
    );

    FOR r_stale_log IN
        SELECT stale.id_log
          FROM hcbi_utility.dblink('LOG_DBLINK', v_sql)
               AS stale(id_log bigint)
    LOOP
        CALL hcbi_utility.prc_end_chain(
            r_stale_log.id_log,
            'FAILED',
            'Esecuzione precedente interrotta prima della chiusura del log; '
            'nessun lock advisory attivo al momento della riconciliazione.'
        );

        RAISE WARNING
            'Riga log IN_PROGRESS obsoleta riconciliata: catena %, id_log=%',
            p_id_chain,
            r_stale_log.id_log;
    END LOOP;

    --ATTENZIONE MODIFICARE LE SEGUENTI RIGHE DI TUNING IN BASE ALLE RISORSE DEL SERVER POSTGRES
SET LOCAL work_mem = '64MB';
SET LOCAL maintenance_work_mem ='4GB';-- '256MB';
--FINE ATTENZIONE MODIFICARE LE SEGUENTI RIGHE DI TUNING IN BASE ALLE RISORSE DEL SERVER POSTGRES

    ----------------------------------------------------------------------
    -- Apertura del log della catena nella sessione indipendente di loopback
    ----------------------------------------------------------------------
    -- prc_start_chain crea la riga attraverso LOG_DBLINK e restituisce
    -- l'identificativo generato. L'UUID viene calcolato nella sessione
    -- chiamante e passato al comando remoto; non dipende quindi dallo stato
    -- di sessione del collegamento dblink.
    ----------------------------------------------------------------------
    CALL hcbi_utility.prc_start_chain(p_id_chain, v_id_log);

    ----------------------------------------------------------------------
    -- Elaborazione degli step attivi
    ----------------------------------------------------------------------
    FOR r_step IN
        SELECT
            s.id_step,
            s.id_chain,
            s.ds_step_name,
            s.ds_package_name,
            s.nr_step_order,
            s.id_dependency_step,
            s.nr_retry_count,
            s.fl_blocking
        FROM hcbi_utility.srv_config_step s
        WHERE s.id_chain = p_id_chain
          AND s.fl_active = 'Y'
        ORDER BY
            s.nr_step_order,
            s.id_step
    LOOP
        ------------------------------------------------------------------
        -- Reset delle variabili relative allo step
        ------------------------------------------------------------------
        v_result                 := NULL;
        v_ds_dependency_status   := NULL;
        v_ds_step_name           := r_step.ds_step_name;

        ------------------------------------------------------------------
        -- Validazione della configurazione dello step
        ------------------------------------------------------------------
        IF NULLIF(btrim(r_step.ds_package_name), '') IS NULL THEN
            v_error_message := format(
                'DS_PACKAGE_NAME non valorizzato per lo step %s',
                r_step.id_step
            );

            /*
             * Registra il log dello step con la routine comune su LOG_DBLINK, quindi
             * aggiorna esito e messaggio dallo stesso canale indipendente. Anche gli
             * esiti FAILED e SKIPPED restano cosi disponibili dopo un rollback.
             */
            v_chain_error_message := v_error_message;
            v_step_log_id := hcbi_utility.pkg_log_fnc_insert_log(
                v_id_log,
                p_id_chain,
                r_step.id_step,
                COALESCE(r_step.ds_step_name, 'STEP_' || r_step.id_step),
                clock_timestamp()::timestamp,
                clock_timestamp()::timestamp,
                session_user
            );

            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_step_log_id,
                'FAILED',
                left(v_error_message, 4000),
                clock_timestamp()::timestamp,
                session_user
            );

            IF COALESCE(r_step.fl_blocking, 'Y') = 'Y' THEN
                v_blocking_error := true;
                EXIT;
            ELSE
                v_non_blocking_error := true;
                CONTINUE;
            END IF;
        END IF;

        ------------------------------------------------------------------
        -- Controllo dello stato dell'eventuale step dipendente
        ------------------------------------------------------------------
        IF r_step.id_dependency_step IS NOT NULL THEN
            SELECT ls.ds_status
              INTO v_ds_dependency_status
              FROM hcbi_utility.log_step ls
             WHERE ls.id_chain_log = v_id_log
               AND ls.id_chain = p_id_chain
               AND ls.id_step = r_step.id_dependency_step
             ORDER BY
                 ls.dt_start DESC NULLS LAST,
                 ls.dt_creation DESC NULLS LAST
             LIMIT 1;

            IF v_ds_dependency_status IS DISTINCT FROM 'SUCCESS' THEN
                v_error_message := format(
                    'Step non eseguito: dipendenza %s non completata con successo. Stato rilevato: %s',
                    r_step.id_dependency_step,
                    COALESCE(v_ds_dependency_status, 'NON TROVATO')
                );

                /*
                 * Registra il log dello step con la routine comune su LOG_DBLINK, quindi
                 * aggiorna esito e messaggio dallo stesso canale indipendente. Anche gli
                 * esiti FAILED e SKIPPED restano cosi disponibili dopo un rollback.
                 */
                v_chain_error_message := v_error_message;
                v_step_log_id := hcbi_utility.pkg_log_fnc_insert_log(
                    v_id_log,
                    p_id_chain,
                    r_step.id_step,
                    COALESCE(r_step.ds_step_name, 'STEP_' || r_step.id_step),
                    clock_timestamp()::timestamp,
                    clock_timestamp()::timestamp,
                    session_user
                );

                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_step_log_id,
                    'SKIPPED',
                    left(v_error_message, 4000),
                    clock_timestamp()::timestamp,
                    session_user
                );

                RAISE NOTICE
                    'Step % saltato: %',
                    r_step.id_step,
                    v_error_message;

                IF COALESCE(r_step.fl_blocking, 'Y') = 'Y' THEN
                    v_blocking_error := true;
                    EXIT;
                ELSE
                    v_non_blocking_error := true;
                    CONTINUE;
                END IF;
            END IF;
        END IF;

        ------------------------------------------------------------------
        -- Individuazione dello schema e del package
        --
        -- Formati ammessi per DS_PACKAGE_NAME:
        --
        --   hcbi_ras.pkg_nome
        --   pkg_nome
        --
        -- Se lo schema non è specificato, si assume hcbi_ras.
        ------------------------------------------------------------------
        IF strpos(r_step.ds_package_name, '.') > 0 THEN
            v_schema_name :=
                lower(
                    btrim(
                        split_part(r_step.ds_package_name, '.', 1)
                    )
                );

            v_package_name :=
                lower(
                    btrim(
                        split_part(r_step.ds_package_name, '.', 2)
                    )
                );
        ELSE
            v_schema_name  := 'hcbi_ras';
            v_package_name := lower(btrim(r_step.ds_package_name));
        END IF;

        ------------------------------------------------------------------
        -- Validazione dei nomi usati per l'esecuzione dinamica
        ------------------------------------------------------------------
        IF v_schema_name !~ '^[a-z_][a-z0-9_]*$' THEN
            v_error_message := format(
                'Nome schema non valido per lo step %s: %s',
                r_step.id_step,
                v_schema_name
            );

            /*
             * Registra il log dello step con la routine comune su LOG_DBLINK, quindi
             * aggiorna esito e messaggio dallo stesso canale indipendente. Anche gli
             * esiti FAILED e SKIPPED restano cosi disponibili dopo un rollback.
             */
            v_chain_error_message := v_error_message;
            v_step_log_id := hcbi_utility.pkg_log_fnc_insert_log(
                v_id_log,
                p_id_chain,
                r_step.id_step,
                COALESCE(r_step.ds_step_name, 'STEP_' || r_step.id_step),
                clock_timestamp()::timestamp,
                clock_timestamp()::timestamp,
                session_user
            );

            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_step_log_id,
                'FAILED',
                left(v_error_message, 4000),
                clock_timestamp()::timestamp,
                session_user
            );

            IF COALESCE(r_step.fl_blocking, 'Y') = 'Y' THEN
                v_blocking_error := true;
                EXIT;
            ELSE
                v_non_blocking_error := true;
                CONTINUE;
            END IF;
        END IF;

        IF v_package_name !~ '^[a-z_][a-z0-9_]*$' THEN
            v_error_message := format(
                'Nome package non valido per lo step %s: %s',
                r_step.id_step,
                v_package_name
            );

            /*
             * Registra il log dello step con la routine comune su LOG_DBLINK, quindi
             * aggiorna esito e messaggio dallo stesso canale indipendente. Anche gli
             * esiti FAILED e SKIPPED restano cosi disponibili dopo un rollback.
             */
            v_chain_error_message := v_error_message;
            v_step_log_id := hcbi_utility.pkg_log_fnc_insert_log(
                v_id_log,
                p_id_chain,
                r_step.id_step,
                COALESCE(r_step.ds_step_name, 'STEP_' || r_step.id_step),
                clock_timestamp()::timestamp,
                clock_timestamp()::timestamp,
                session_user
            );

            CALL hcbi_utility.pkg_log_prc_error_update_log(
                v_step_log_id,
                'FAILED',
                left(v_error_message, 4000),
                clock_timestamp()::timestamp,
                session_user
            );

            IF COALESCE(r_step.fl_blocking, 'Y') = 'Y' THEN
                v_blocking_error := true;
                EXIT;
            ELSE
                v_non_blocking_error := true;
                CONTINUE;
            END IF;
        END IF;

        ------------------------------------------------------------------
        -- Esecuzione delle tre fasi:
        --
        --   package_prc_initialize
        --   package_prc_main
        --   package_prc_finalize
        ------------------------------------------------------------------
        FOREACH v_procedure_phase
        IN ARRAY v_procedure_phases
        LOOP
            v_result         := NULL;
            v_error_message  := NULL;
            v_error_detail   := NULL;
            v_error_hint     := NULL;
            v_error_context  := NULL;
            v_sqlstate       := NULL;

            v_procedure_name :=
                v_package_name || '_' || v_procedure_phase;

            v_ds_step_name :=
                COALESCE(
                    NULLIF(btrim(r_step.ds_step_name), ''),
                    v_package_name
                )
                || '.'
                || v_procedure_phase;

            ----------------------------------------------------------------
            -- Verifica dell'esistenza della procedura con la firma prevista
            ----------------------------------------------------------------
			----------------------------------------------------------------
			-- ATTENZIONE
			--
			-- La verifica viene effettuata utilizzando solo i parametri IN.
			--
			-- Le procedure richiamate dalla catena sono attualmente
			-- definite con la seguente firma:
			--
			--   IN  p_id_chain_log bigint
			--   IN  p_id_chain     bigint
			--   IN  p_id_step      bigint
			--   IN  p_ds_step_name varchar
			--   OUT p_result       integer
			--
			-- PostgreSQL identifica correttamente la procedura tramite i
			-- soli parametri IN.
			--
			-- In caso di future modifiche della firma (ad esempio rimozione
			-- o variazione del parametro OUT p_result) questa verifica
			-- continuerebbe comunque a trovare la procedura.
			--
			-- Qualsiasi modifica della firma dovrà essere verificata anche
			-- nella EXECUTE dinamica e nella gestione di v_result.
			----------------------------------------------------------------

            IF to_regprocedure(
                format(
                    '%I.%I(bigint,bigint,bigint,character varying)',
                    v_schema_name,
                    v_procedure_name
                )
            ) IS NULL THEN
                v_error_message := format(
					'Procedura %I.%I(bigint,bigint,bigint,character varying,bigint) non trovata' ,--aggiunto bigint che è il parametro in output omesso nella to_regprocedure
                    v_schema_name,
                    v_procedure_name
                );

                /*
                 * Registra il log dello step con la routine comune su LOG_DBLINK, quindi
                 * aggiorna esito e messaggio dallo stesso canale indipendente. Anche gli
                 * esiti FAILED e SKIPPED restano cosi disponibili dopo un rollback.
                 */
                v_chain_error_message := v_error_message;
                v_step_log_id := hcbi_utility.pkg_log_fnc_insert_log(
                    v_id_log,
                    p_id_chain,
                    r_step.id_step,
                    v_ds_step_name,
                    clock_timestamp()::timestamp,
                    clock_timestamp()::timestamp,
                    session_user
                );

                CALL hcbi_utility.pkg_log_prc_error_update_log(
                    v_step_log_id,
                    'FAILED',
                    left(v_error_message, 4000),
                    clock_timestamp()::timestamp,
                    session_user
                );

                RAISE WARNING '%', v_error_message;

                IF COALESCE(r_step.fl_blocking, 'Y') = 'Y' THEN
                    v_blocking_error := true;
                    EXIT;
                ELSE
                    v_non_blocking_error := true;
                    EXIT;
                END IF;
            END IF;

            ----------------------------------------------------------------
            -- Costruzione e chiamata dinamica della procedura
            --
            -- L'ultimo parametro corrisponde a OUT p_result.
            -- CALL restituisce il parametro OUT come singola riga.
            ----------------------------------------------------------------
			----------------------------------------------------------------
			-- Esecuzione dinamica della procedura.
			--
			-- Le procedure di chain espongono:
			--
			--   IN  p_id_chain_log bigint
			--   IN  p_id_chain     bigint
			--   IN  p_id_step      bigint
			--   IN  p_ds_step_name varchar
			--   OUT p_result       integer
			--
			-- PostgreSQL non aggiorna automaticamente una variabile locale
			-- passata come parametro INOUT tramite EXECUTE dinamica.
			--
			-- Per acquisire correttamente il valore restituito da p_result
			-- viene utilizzata una CALL con quinto parametro NULL:
			--
			--   CALL proc($1,$2,$3,$4,NULL)
			--
			-- Il valore del parametro OUT viene quindi restituito come
			-- record e acquisito mediante:
			--
			--   EXECUTE ... INTO v_result
			--
			-- Questa soluzione è stata validata durante il porting Oracle →
			-- PostgreSQL della PRC_EXECUTE_CHAIN.
			----------------------------------------------------------------
			v_sql := format(
				'CALL %I.%I(
					$1,
					$2,
					$3,
					$4,
					NULL -- Necessario per la risoluzione della firma contenente il parametro OUT p_result.
				)',
				v_schema_name,
				v_procedure_name
			);

            RAISE NOTICE
                'Esecuzione %, chain_log=%, chain=%, step=%, step_name=%',
                format('%I.%I', v_schema_name, v_procedure_name),
                v_id_log,
                p_id_chain,
                r_step.id_step,
                v_ds_step_name;

            BEGIN
                EXECUTE v_sql
                   INTO v_result
                  USING
                      v_id_log,
                      p_id_chain,
                      r_step.id_step,
                      v_ds_step_name;

--RAISE NOTICE 'DEBUG -> procedura=%, result=%',format('%I.%I', v_schema_name, v_procedure_name), coalesce(v_result::text,'NULL');
                ----------------------------------------------------------------
                -- Un valore NULL non è considerato un esito valido
                ----------------------------------------------------------------
                IF v_result IS NULL THEN
                    v_result := -1;

                    v_error_message := format(
                        'La procedura %I.%I non ha restituito p_result',
                        v_schema_name,
                        v_procedure_name
                    );
                ELSIF v_result < 0 THEN
                    v_error_message := format(
                        'La procedura %I.%I ha restituito p_result=%s',
                        v_schema_name,
                        v_procedure_name,
                        v_result
                    );
                ELSE
                    RAISE NOTICE
                        'Procedura % completata con p_result=%',
                        format('%I.%I', v_schema_name, v_procedure_name),
                        v_result;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    GET STACKED DIAGNOSTICS
                        v_error_message = MESSAGE_TEXT,
                        v_error_detail  = PG_EXCEPTION_DETAIL,
                        v_error_hint    = PG_EXCEPTION_HINT,
                        v_error_context = PG_EXCEPTION_CONTEXT,
                        v_sqlstate      = RETURNED_SQLSTATE;

                    v_error_message := concat_ws(
                        ' | ',
                        format(
                            'Errore nella procedura %I.%I',
                            v_schema_name,
                            v_procedure_name
                        ),
                        'SQLSTATE=' || COALESCE(v_sqlstate, SQLSTATE),
                        'SQLERRM=' || COALESCE(v_error_message, SQLERRM),
                        CASE
                            WHEN NULLIF(v_error_detail, '') IS NOT NULL
                            THEN 'DETAIL=' || v_error_detail
                        END,
                        CASE
                            WHEN NULLIF(v_error_hint, '') IS NOT NULL
                            THEN 'HINT=' || v_error_hint
                        END,
                        CASE
                            WHEN NULLIF(v_error_context, '') IS NOT NULL
                            THEN 'CONTEXT=' || v_error_context
                        END
                    );

                    v_result := -1;
            END;

            ----------------------------------------------------------------
            -- Gestione dell'esito negativo della fase
            ----------------------------------------------------------------
            IF COALESCE(v_result, -1) < 0 THEN
                v_chain_error_message := v_error_message;
                CALL hcbi_utility.prc_mark_chain_failed(
                    v_id_log,
                    left(
                        COALESCE(
                            v_error_message,
                            format(
                                'Errore nella procedura %I.%I',
                                v_schema_name,
                                v_procedure_name
                            )
                        ),
                        4000
                    )
                );

                IF COALESCE(r_step.fl_blocking, 'Y') = 'Y' THEN
                    v_blocking_error := true;

                    RAISE WARNING
                        'Interruzione della catena %: errore bloccante nello step %, procedura %',
                        p_id_chain,
                        r_step.id_step,
                        format('%I.%I', v_schema_name, v_procedure_name);

                    EXIT;
                ELSE
                    v_non_blocking_error := true;

                    RAISE WARNING
                        'Errore non bloccante nella catena %, step %, procedura %. L''elaborazione prosegue con lo step successivo',
                        p_id_chain,
                        r_step.id_step,
                        format('%I.%I', v_schema_name, v_procedure_name);

                    EXIT;
                END IF;
            END IF;
        END LOOP;

        ------------------------------------------------------------------
        -- Uscita dal ciclo degli step in caso di errore bloccante
        ------------------------------------------------------------------
        IF v_blocking_error THEN
            EXIT;
        END IF;
    END LOOP;

    ----------------------------------------------------------------------
    -- Chiusura della catena
    ----------------------------------------------------------------------
    IF v_blocking_error THEN
        CALL hcbi_utility.prc_end_chain(
            v_id_log,
            'FAILED',
            left(
                COALESCE(
                    v_chain_error_message,
                    'Catena interrotta a causa di un errore bloccante'
                ),
                4000
            )
        );

        RAISE WARNING
            'Catena % terminata con stato FAILED, id_log=%',
            p_id_chain,
            v_id_log;

    ELSIF v_non_blocking_error THEN
        ------------------------------------------------------------------
        -- La catena ha completato tutti gli step eseguibili, ma almeno
        -- uno step non bloccante è terminato in errore.
        ------------------------------------------------------------------
        CALL hcbi_utility.prc_end_chain(
            v_id_log,
            'FAILED',
            left(
                COALESCE(
                    v_chain_error_message,
                    'Catena completata con piu errori non bloccanti'
                ),
                4000
            )
        );

        RAISE WARNING
            'Catena % completata con errori non bloccanti, id_log=%',
            p_id_chain,
            v_id_log;

    ELSE
        CALL hcbi_utility.prc_end_chain(
            v_id_log,
            'COMPLETED',
            NULL
        );

        RAISE NOTICE
            'Catena % completata correttamente, id_log=%',
            p_id_chain,
            v_id_log;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_error_message = MESSAGE_TEXT,
            v_error_detail  = PG_EXCEPTION_DETAIL,
            v_error_hint    = PG_EXCEPTION_HINT,
            v_error_context = PG_EXCEPTION_CONTEXT,
            v_sqlstate      = RETURNED_SQLSTATE;

        v_error_message := concat_ws(
            ' | ',
            'Errore durante l''esecuzione della catena ' || p_id_chain,
            'SQLSTATE=' || COALESCE(v_sqlstate, SQLSTATE),
            'SQLERRM=' || COALESCE(v_error_message, SQLERRM),
            CASE
                WHEN NULLIF(v_error_detail, '') IS NOT NULL
                THEN 'DETAIL=' || v_error_detail
            END,
            CASE
                WHEN NULLIF(v_error_hint, '') IS NOT NULL
                THEN 'HINT=' || v_error_hint
            END,
            CASE
                WHEN NULLIF(v_error_context, '') IS NOT NULL
                THEN 'CONTEXT=' || v_error_context
            END
        );

        ------------------------------------------------------------------
        -- Registra l'errore finale tramite la sessione indipendente.
        -- Un eventuale guasto del canale di logging viene segnalato senza
        -- sostituire il messaggio dell'errore originale.
        ------------------------------------------------------------------
        IF v_id_log IS NOT NULL THEN
            BEGIN
                CALL hcbi_utility.prc_end_chain(
                    v_id_log,
                    'FAILED',
                    left(v_error_message, 4000)
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING
                        'Impossibile aggiornare il log della catena % (id_log=%). '
                        'Errore logging SQLSTATE=%, messaggio=%',
                        p_id_chain,
                        v_id_log,
                        SQLSTATE,
                        SQLERRM;
            END;
        END IF;

        RAISE WARNING '%', v_error_message;

        ------------------------------------------------------------------
        -- Non viene eseguito RAISE senza argomenti: si conserva il
        -- comportamento corrente della procedura, che segnala l'esito
        -- negativo tramite log e WARNING senza rilanciare l'eccezione.
        -- Il log, essendo scritto via LOG_DBLINK, resta indipendente
        -- dall'esito della transazione principale.
        ------------------------------------------------------------------
        RETURN;
END;
$procedure$
