CREATE OR REPLACE PROCEDURE hcbi_utility.prc_start_chain(IN p_id_chain bigint, OUT p_id_log bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_utility'
AS $procedure$
	DECLARE
		v_sql            TEXT;
		v_running_count  BIGINT;
		v_execution_uuid UUID;
	BEGIN

		p_id_log := NULL;

		IF p_id_chain IS NULL THEN
			RAISE EXCEPTION
			'PRC_START_CHAIN: p_id_chain obbligatorio';
		END IF;

		PERFORM hcbi_utility.ensure_dblink_logging();

		/*
		 * Legge l'UUID nella sessione chiamante prima dell'INSERT remoto.
		 * Il valore non dipende da eventuali variabili di sessione del
		 * collegamento LOG_DBLINK, che e' una sessione PostgreSQL distinta.
		 */
		v_execution_uuid := hcbi_utility.get_current_etl_execution_uuid();

		/*
		 * Difesa aggiuntiva contro chiamate dirette o versioni concorrenti.
		 * prc_execute_chain acquisisce prima il lock advisory e riconcilia
		 * i vecchi log IN_PROGRESS; qui si verifica comunque sul database
		 * remoto che non sia rimasta un'esecuzione registrata come attiva.
		 */
		v_sql := format(
			$SQL$
			SELECT count(*)
			FROM hcbi_utility.log_chain
			WHERE id_chain = %L
			  AND ds_status = 'IN_PROGRESS'
			$SQL$,
			p_id_chain
		);

		SELECT r.running_count
		  INTO v_running_count
		  FROM hcbi_utility.dblink(
				  'LOG_DBLINK',
				  v_sql
			   ) AS r(running_count BIGINT);

		IF COALESCE(v_running_count,0) > 0 THEN

			RAISE EXCEPTION
			'Catena % già in esecuzione',
			p_id_chain;

		END IF;

		/*
		 * Apertura durevole del log della catena.
		 * L'INSERT e' eseguito tramite LOG_DBLINK, in una sessione separata:
		 * un rollback della transazione principale non annulla questa riga.
		 * I valori sono formattati con %L per gestire UUID, identificativi
		 * e testi in modo sicuro, inclusi NULL e caratteri speciali.
		 */
		v_sql := format(
			$SQL$
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
				%L::bigint,
				%L::uuid,
				clock_timestamp(),
				NULL,
				'IN_PROGRESS',
				NULL,
				clock_timestamp(),
				%L::text
			)
			RETURNING id_log
			$SQL$,
			p_id_chain,
			v_execution_uuid,
			session_user
		);

		SELECT r.id_log
		  INTO p_id_log
		  FROM hcbi_utility.dblink(
				'LOG_DBLINK',
				v_sql
		  ) AS r(id_log BIGINT);

	END;
	$procedure$
