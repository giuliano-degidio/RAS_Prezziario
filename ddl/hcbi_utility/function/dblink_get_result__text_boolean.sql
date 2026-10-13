CREATE OR REPLACE FUNCTION hcbi_utility.dblink_get_result(text, boolean)
 RETURNS SETOF record
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_get_result$function$
