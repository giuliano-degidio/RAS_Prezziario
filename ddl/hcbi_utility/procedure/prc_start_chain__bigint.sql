CREATE OR REPLACE PROCEDURE hcbi_utility.prc_start_chain(IN p_id_chain bigint, OUT p_id_log bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_utility'
AS $procedure$
	DECLARE
		v_sql            TEXT;
		v_running_count  BIGINT;
	BEGIN

		p_id_log := NULL;

		IF p_id_chain IS NULL THEN
			RAISE EXCEPTION
			'PRC_START_CHAIN: p_id_chain obbligatorio';
		END IF;

		PERFORM hcbi_utility.ensure_dblink_logging();

		/*
		   Verifica catena già in esecuzione
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
		   Inserimento LOG_CHAIN
		*/
		v_sql := format(
			$SQL$
			INSERT INTO hcbi_utility.log_chain
			(
				id_chain,
				dt_start,
				ds_status
			)
			VALUES
			(
				%L,
				clock_timestamp(),
				'IN_PROGRESS'
			)
			RETURNING id_log
			$SQL$,
			p_id_chain
		);

		SELECT r.id_log
		  INTO p_id_log
		  FROM hcbi_utility.dblink(
				'LOG_DBLINK',
				v_sql
		  ) AS r(id_log BIGINT);

	END;
	$procedure$
