CREATE OR REPLACE FUNCTION hcbi_utility.pkg_log_display_backtrace_fnc(p_context text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
	BEGIN
		RETURN
			  '***** Backtrace Start *****'
		   || E'\n'
		   || coalesce(p_context,'Nessun contesto disponibile')
		   || E'\n'
		   || '***** Backtrace End *****';
	END;
	$function$
