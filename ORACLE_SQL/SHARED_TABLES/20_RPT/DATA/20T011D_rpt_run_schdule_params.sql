/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=RPT.RPT_RUN_SCHDULE_PARAMS --data-only --column-inserts psdc_live > RPT.RPT_RUN_SCHDULE_PARAMS.sql
*/
set define off;
TRUNCATE TABLE RPT.RPT_RUN_SCHDULE_PARAMS CASCADE;



INSERT INTO rpt.rpt_run_schdule_params (schdl_param_id, schedule_id, parameter_id, parameter_value, created_by, creation_date, last_update_by, last_update_date, alert_id) VALUES (10, 7, 76, 'scm.scm_gl_interface', 8, '2015-02-14 09:06:02', 4, '2015-05-05 03:20:09', -1);
INSERT INTO rpt.rpt_run_schdule_params (schdl_param_id, schedule_id, parameter_id, parameter_value, created_by, creation_date, last_update_by, last_update_date, alert_id) VALUES (9, 7, 77, '%Inventory%', 8, '2015-02-14 09:06:02', 4, '2015-05-05 03:20:09', -1);


COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'RPT', 'RPT_RUN_SCHDULE_PARAMS_ID_SEQ', 16 );
COMMIT;
