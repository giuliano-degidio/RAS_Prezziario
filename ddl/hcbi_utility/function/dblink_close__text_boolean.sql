CREATE OR REPLACE FUNCTION hcbi_utility.dblink_close(text, boolean)
 RETURNS text
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_close$function$
