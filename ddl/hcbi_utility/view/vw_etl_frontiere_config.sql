CREATE OR REPLACE VIEW hcbi_utility.vw_etl_frontiere_config AS
SELECT frontiera_code,
    description,
    execution_order,
    source_service_code,
    source_query,
    target_schema,
    target_table,
    truncate_before_load
   FROM hcbi_utility.etl_frontiere_config c
  WHERE enabled = true;
