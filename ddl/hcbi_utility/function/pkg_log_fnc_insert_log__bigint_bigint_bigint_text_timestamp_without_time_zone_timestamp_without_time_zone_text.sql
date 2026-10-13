CREATE OR REPLACE FUNCTION hcbi_utility.pkg_log_fnc_insert_log(p_id_chain_log bigint, p_id_chain bigint, p_id_step bigint, p_ds_step_name text, p_dt_start timestamp without time zone DEFAULT clock_timestamp(), p_dt_creation timestamp without time zone DEFAULT clock_timestamp(), p_ds_transaction text DEFAULT CURRENT_USER)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_utility'
AS $function$
	DECLARE
		v_sql     text;
		v_id_log  bigint;
	BEGIN
		IF p_id_chain_log IS NULL THEN
			RAISE EXCEPTION
				'PKG_LOG_FNC_INSERT_LOG: p_id_chain_log obbligatorio';
		END IF;

		IF p_id_chain IS NULL THEN
			RAISE EXCEPTION
				'PKG_LOG_FNC_INSERT_LOG: p_id_chain obbligatorio';
		END IF;

		IF p_id_step IS NULL THEN
			RAISE EXCEPTION
				'PKG_LOG_FNC_INSERT_LOG: p_id_step obbligatorio';
		END IF;

		PERFORM hcbi_utility.ensure_dblink_logging();

		/*
		 * format() con %L gestisce:
		 *
		 * - apici nei testi;
		 * - valori NULL;
		 * - conversione sicura in letterali SQL.
		 */
		v_sql := format(
			$sql$
			INSERT INTO hcbi_utility.log_step
			(
				id_chain_log,
				id_chain,
				id_step,
				ds_step_name,
				dt_start,
				dt_creation,
				tx_creation_by
			)
			VALUES
			(
				%L::bigint,
				%L::bigint,
				%L::bigint,
				%L::text,
				%L::timestamp,
				%L::timestamp,
				%L::text
			)
			RETURNING id_log
			$sql$,
			p_id_chain_log,
			p_id_chain,
			p_id_step,
			p_ds_step_name,
			p_dt_start,
			p_dt_creation,
			p_ds_transaction
		);
--RAISE NOTICE 'SQL=%', v_sql;
		/*
		 * Si usa dblink() anziché dblink_exec() perché è
		 * necessario recuperare ID_LOG dalla clausola RETURNING.
		 */	 
		SELECT risultato.id_log
		  INTO STRICT v_id_log
		  FROM hcbi_utility.dblink(
				   'LOG_DBLINK',
				   v_sql
			   ) AS risultato(id_log bigint);

		RETURN v_id_log;
	EXCEPTION
		WHEN OTHERS THEN
			RAISE EXCEPTION
				'PKG_LOG_FNC_INSERT_LOG: errore inserimento LOG_STEP. '
				'SQLSTATE: %, errore: %',
				SQLSTATE,
				SQLERRM;
	END;
	
$function$
