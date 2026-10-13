CREATE OR REPLACE FUNCTION hcbi_utility.dblink_is_busy(text)
 RETURNS integer
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_is_busy$function$
