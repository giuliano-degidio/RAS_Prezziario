CREATE OR REPLACE VIEW "hcbi_utility"."v_log_chain_last_run" AS
 SELECT id_chain,
    id_log_last_run,
    ds_chain_name,
    dt_start,
    dt_end,
    EXTRACT(epoch FROM dt_end - dt_start) / 60::numeric AS elapsed_minutes,
    ds_status,
    tx_error_message
   FROM ( SELECT b.id_chain,
            b.ds_chain_name,
            a.dt_start,
            a.dt_end,
            a.ds_status,
            a.tx_error_message,
            a.id_log,
            max(a.id_log) OVER (PARTITION BY a.id_chain) AS id_log_last_run
           FROM hcbi_utility.log_chain a
             JOIN hcbi_utility.srv_config_chain b ON a.id_chain = b.id_chain) x
  WHERE id_log = id_log_last_run;;
