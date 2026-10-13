CREATE OR REPLACE FUNCTION hcbi_utility.dblink_error_message(text)
 RETURNS text
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_error_message$function$
