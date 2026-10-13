CREATE OR REPLACE PROCEDURE hcbi_utility.init_dblink_logging()
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'hcbi_utility'
AS $procedure$
		BEGIN
			PERFORM hcbi_utility.ensure_dblink_logging();
		END;
		$procedure$
