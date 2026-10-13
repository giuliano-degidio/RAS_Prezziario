CREATE OR REPLACE FUNCTION hcbi_utility.dblink_connect(text, text)
 RETURNS text
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_connect$function$
