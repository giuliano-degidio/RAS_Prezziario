CREATE OR REPLACE PROCEDURE hcbi_utility.prc_execute_chain(IN p_id_chain bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_utility'
AS $procedure$

DECLARE
    r_step                       record;

    v_id_log                     bigint;
    v_ds_step_name               text;
    v_ds_dependency_status       text;
    v_result                     integer;

    v_schema_name                text;
    v_package_name               text;
    v_procedure_name             text;
    v_procedure_phase            text;

    v_sql                        text;
    v_error_message              text;
    v_error_detail               text;
    v_error_hint                 text;
    v_error_context              text;
    v_sqlstate                   text;

    v_chain_exists               boolean;
    v_running_count              bigint;
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
    -- Controllo aggiuntivo sulle eventuali esecuzioni IN_PROGRESS
    ----------------------------------------------------------------------
    SELECT count(*)
      INTO v_running_count
      FROM hcbi_utility.log_chain lc
     WHERE lc.id_chain = p_id_chain
       AND lc.ds_status = 'IN_PROGRESS';

    IF v_running_count > 0 THEN
        RAISE EXCEPTION
            USING
                ERRCODE = '55006',
                MESSAGE = format(
                    'La catena %s presenta già %s esecuzione/i con stato IN_PROGRESS',
                    p_id_chain,
                    v_running_count
                );
    END IF;
--ATTENZIONE MODIFICARE LE SEGUENTI RIGHE DI TUNING IN BASE ALLE RISORSE DEL SERVER POSTGRES
SET LOCAL work_mem = '64MB';
SET LOCAL maintenance_work_mem ='4GB';-- '256MB';
--FINE ATTENZIONE MODIFICARE LE SEGUENTI RIGHE DI TUNING IN BASE ALLE RISORSE DEL SERVER POSTGRES

    ----------------------------------------------------------------------
    -- Apertura del log della catena
    -- Associa, se disponibile, l'UUID (etl_execution_uuid) dell'esecuzione orchestratore ETL corrente.
    -- id_log deve essere una colonna identity oppure avere un DEFAULT
    -- associato alla relativa sequence.
    ----------------------------------------------------------------------
	INSERT INTO hcbi_utility.log_chain
    (
        id_chain,
        etl_execution_uuid,
        dt_start,
        dt_end,
        ds_status,
        tx_error_message,
        dt_creation,
        tx_creation_by
    )
    VALUES
    (
        p_id_chain,
        hcbi_utility.get_current_etl_execution_uuid(),
        clock_timestamp(),
        NULL,
        'IN_PROGRESS',
        NULL,
        clock_timestamp(),
        session_user
    )
    RETURNING id_log
         INTO v_id_log;

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

            INSERT INTO hcbi_utility.log_step
            (
                id_chain_log,
                id_chain,
                id_step,
                ds_step_name,
                dt_start,
                dt_end,
                ds_status,
                tx_error_message,
                dt_creation,
                tx_creation_by
            )
            VALUES
            (
                v_id_log,
                p_id_chain,
                r_step.id_step,
                COALESCE(r_step.ds_step_name, 'STEP_' || r_step.id_step),
                clock_timestamp(),
                clock_timestamp(),
                'FAILED',
                left(v_error_message, 4000),
                clock_timestamp(),
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

                INSERT INTO hcbi_utility.log_step
                (
                    id_chain_log,
                    id_chain,
                    id_step,
                    ds_step_name,
                    dt_start,
                    dt_end,
                    ds_status,
                    tx_error_message,
                    dt_creation,
                    tx_creation_by
                )
                VALUES
                (
                    v_id_log,
                    p_id_chain,
                    r_step.id_step,
                    COALESCE(r_step.ds_step_name, 'STEP_' || r_step.id_step),
                    clock_timestamp(),
                    clock_timestamp(),
                    'SKIPPED',
                    left(v_error_message, 4000),
                    clock_timestamp(),
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

            INSERT INTO hcbi_utility.log_step
            (
                id_chain_log,
                id_chain,
                id_step,
                ds_step_name,
                dt_start,
                dt_end,
                ds_status,
                tx_error_message,
                dt_creation,
                tx_creation_by
            )
            VALUES
            (
                v_id_log,
                p_id_chain,
                r_step.id_step,
                COALESCE(r_step.ds_step_name, 'STEP_' || r_step.id_step),
                clock_timestamp(),
                clock_timestamp(),
                'FAILED',
                left(v_error_message, 4000),
                clock_timestamp(),
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

            INSERT INTO hcbi_utility.log_step
            (
                id_chain_log,
                id_chain,
                id_step,
                ds_step_name,
                dt_start,
                dt_end,
                ds_status,
                tx_error_message,
                dt_creation,
                tx_creation_by
            )
            VALUES
            (
                v_id_log,
                p_id_chain,
                r_step.id_step,
                COALESCE(r_step.ds_step_name, 'STEP_' || r_step.id_step),
                clock_timestamp(),
                clock_timestamp(),
                'FAILED',
                left(v_error_message, 4000),
                clock_timestamp(),
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

                INSERT INTO hcbi_utility.log_step
                (
                    id_chain_log,
                    id_chain,
                    id_step,
                    ds_step_name,
                    dt_start,
                    dt_end,
                    ds_status,
                    tx_error_message,
                    dt_creation,
                    tx_creation_by
                )
                VALUES
                (
                    v_id_log,
                    p_id_chain,
                    r_step.id_step,
                    v_ds_step_name,
                    clock_timestamp(),
                    clock_timestamp(),
                    'FAILED',
                    left(v_error_message, 4000),
                    clock_timestamp(),
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
                UPDATE hcbi_utility.log_chain
                   SET ds_status = 'FAILED',
                       tx_error_message = left(
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
                 WHERE id_log = v_id_log;

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
        UPDATE hcbi_utility.log_chain
           SET dt_end = clock_timestamp(),
               ds_status = 'FAILED',
               tx_error_message = left(
                   COALESCE(
                       tx_error_message,
                       'Catena interrotta a causa di un errore bloccante'
                   ),
                   4000
               )
         WHERE id_log = v_id_log;

        RAISE WARNING
            'Catena % terminata con stato FAILED, id_log=%',
            p_id_chain,
            v_id_log;

    ELSIF v_non_blocking_error THEN
        ------------------------------------------------------------------
        -- La catena ha completato tutti gli step eseguibili, ma almeno
        -- uno step non bloccante è terminato in errore.
        ------------------------------------------------------------------
        UPDATE hcbi_utility.log_chain
           SET dt_end = clock_timestamp(),
               ds_status = 'FAILED',
               tx_error_message = left(
                   COALESCE(
                       tx_error_message,
                       'Catena completata con uno o più errori non bloccanti'
                   ),
                   4000
               )
         WHERE id_log = v_id_log;

        RAISE WARNING
            'Catena % completata con errori non bloccanti, id_log=%',
            p_id_chain,
            v_id_log;

    ELSE
        UPDATE hcbi_utility.log_chain
           SET dt_end = clock_timestamp(),
               ds_status = 'COMPLETED',
               tx_error_message = NULL
         WHERE id_log = v_id_log;

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
        -- Aggiornamento del log solo se il record di catena è già stato
        -- creato.
        ------------------------------------------------------------------
        IF v_id_log IS NOT NULL THEN
            UPDATE hcbi_utility.log_chain
               SET dt_end = clock_timestamp(),
                   ds_status = 'FAILED',
                   tx_error_message = left(v_error_message, 4000)
             WHERE id_log = v_id_log;
        END IF;

        RAISE WARNING '%', v_error_message;

        ------------------------------------------------------------------
        -- Non viene eseguito RAISE senza argomenti.
        --
        -- In questo modo il log FAILED aggiornato sopra può essere
        -- conservato dal chiamante quando la transazione viene confermata.
        ------------------------------------------------------------------
        RETURN;
END;
$procedure$

