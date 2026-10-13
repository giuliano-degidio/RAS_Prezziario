CREATE OR REPLACE FUNCTION hcbi_utility.disconnect_dblink_logging()
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_utility'
AS $function$
		DECLARE
			v_connections text[];
		BEGIN
			v_connections :=
				hcbi_utility.dblink_get_connections();

			IF v_connections IS NOT NULL
			   AND 'LOG_DBLINK' = ANY(v_connections)
			THEN
				PERFORM hcbi_utility.dblink_disconnect('LOG_DBLINK');
				RETURN true;
			END IF;

			RETURN false;
		END;
		$function$
