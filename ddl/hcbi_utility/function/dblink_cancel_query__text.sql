CREATE OR REPLACE FUNCTION hcbi_utility.dblink_cancel_query(text)
 RETURNS text
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_cancel_query$function$
