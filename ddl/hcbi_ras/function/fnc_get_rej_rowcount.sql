CREATE OR REPLACE FUNCTION hcbi_ras.fnc_get_rej_rowcount(p_table_name character varying)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_sql   text;
    v_count bigint;
BEGIN

    v_sql :=
           'SELECT COUNT(*) ' ||
           'FROM ' || p_table_name || ' r ' ||
           'INNER JOIN hcbi_utility.log_chain lc ' ||
           'ON (r.dt_scarto BETWEEN lc.dt_start AND lc.dt_end) ' ||
           'WHERE lc.id_log = (' ||
           '   SELECT MAX(ls.id_chain_log) ' ||
           '   FROM hcbi_utility.log_step ls ' ||
           '   WHERE ls.id_chain = (' ||
           '      SELECT sc.id_chain ' ||
           '      FROM hcbi_utility.srv_config_chain sc ' ||
           '      WHERE sc.ds_chain_name ILIKE ''%hcbi_ras%'' ' ||
           '   )' ||
           ')';

    EXECUTE v_sql INTO v_count;

    RETURN coalesce(v_count,0);

END;
$function$
