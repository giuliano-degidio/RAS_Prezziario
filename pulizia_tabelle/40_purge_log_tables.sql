BEGIN;

TRUNCATE TABLE hcbi_utility.etl_frontiere_execution_lock,
               hcbi_utility.etl_frontiere_run,
               hcbi_utility.etl_dwh_refresh_run,
               hcbi_utility.log_chain,
               hcbi_utility.log_step;

COMMIT;
