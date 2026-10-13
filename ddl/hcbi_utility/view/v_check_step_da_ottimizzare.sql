CREATE OR REPLACE VIEW "hcbi_utility"."v_check_step_da_ottimizzare" AS
 SELECT id_chain,
    ds_chain_name,
    ds_step_name,
    dt_start,
    dt_end,
    elapsed_minutes
   FROM ( SELECT a.id_log,
            a.id_chain_log,
            a.id_chain,
            a.id_step,
            a.ds_step_name,
            a.dt_start,
            a.dt_end,
            EXTRACT(epoch FROM a.dt_end - a.dt_start) / 60::numeric AS elapsed_minutes,
            a.ds_status,
            a.tx_error_message,
            a.nr_rec_selected,
            a.nr_rec_inserted,
            a.nr_rec_updated,
            a.nr_rec_deleted,
            a.nr_rec_errors,
            max(a.id_chain_log) OVER (PARTITION BY a.id_chain) AS last_run,
            b.ds_chain_name
           FROM hcbi_utility.log_step a
             JOIN hcbi_utility.srv_config_chain b ON a.id_chain = b.id_chain) x
  WHERE id_chain_log = last_run AND elapsed_minutes > 1::numeric;;
