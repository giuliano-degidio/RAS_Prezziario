CREATE OR REPLACE FUNCTION hcbi_utility.dblink_exec(text)
 RETURNS text
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_exec$function$
