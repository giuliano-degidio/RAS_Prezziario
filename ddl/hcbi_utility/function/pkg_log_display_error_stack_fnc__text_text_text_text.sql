CREATE OR REPLACE FUNCTION hcbi_utility.pkg_log_display_error_stack_fnc(p_sqlstate text DEFAULT NULL::text, p_message text DEFAULT NULL::text, p_detail text DEFAULT NULL::text, p_hint text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
	DECLARE
		v_result text;
	BEGIN
		v_result :=
			  '***** Error Stack Start *****' || E'\n'
		   || 'SQLSTATE : ' || coalesce(p_sqlstate,'') || E'\n'
		   || 'MESSAGE  : ' || coalesce(p_message,'') || E'\n';

		IF p_detail IS NOT NULL THEN
			v_result :=
				v_result ||
				'DETAIL   : ' || p_detail || E'\n';
		END IF;

		IF p_hint IS NOT NULL THEN
			v_result :=
				v_result ||
				'HINT     : ' || p_hint || E'\n';
		END IF;

		v_result :=
			v_result ||
			'***** Error Stack End *****';

		RETURN v_result;
	END;
	$function$
