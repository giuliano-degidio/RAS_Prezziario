CREATE OR REPLACE FUNCTION hcbi_utility.dblink_get_connections()
 RETURNS text[]
 LANGUAGE c
 PARALLEL RESTRICTED
AS '$libdir/dblink', $function$dblink_get_connections$function$
