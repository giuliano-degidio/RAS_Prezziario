CREATE OR REPLACE FUNCTION hcbi_utility.dblink_current_query()
 RETURNS text
 LANGUAGE c
 PARALLEL RESTRICTED
AS '$libdir/dblink', $function$dblink_current_query$function$
