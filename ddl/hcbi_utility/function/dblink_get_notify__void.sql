CREATE OR REPLACE FUNCTION hcbi_utility.dblink_get_notify(OUT notify_name text, OUT be_pid integer, OUT extra text)
 RETURNS SETOF record
 LANGUAGE c
 PARALLEL RESTRICTED STRICT
AS '$libdir/dblink', $function$dblink_get_notify$function$
