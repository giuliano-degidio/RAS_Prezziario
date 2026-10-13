CREATE OR REPLACE FUNCTION hcbi_utility.dblink(text, text)
 RETURNS SETOF record
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_record$function$
