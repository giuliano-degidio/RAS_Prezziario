CREATE OR REPLACE FUNCTION hcbi_utility.dblink_send_query(text, text)
 RETURNS integer
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_send_query$function$
