CREATE OR REPLACE FUNCTION hcbi_utility.dblink_disconnect(text)
 RETURNS text
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_disconnect$function$
