/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=RPT.RPT_PRCSS_RNNRS --data-only --column-inserts psdc_live > RPT.RPT_PRCSS_RNNRS.sql
*/
set define off;
TRUNCATE TABLE RPT.RPT_PRCSS_RNNRS CASCADE;



INSERT INTO rpt.rpt_prcss_rnnrs (prcss_rnnr_id, rnnr_name, rnnr_desc, rnnr_lst_actv_dtetme, created_by, creation_date, last_update_by, last_update_date, rnnr_status, executbl_file_nm, crnt_rnng_priority, shld_rnnr_stop) VALUES (13, 'Standard Process Runner', 'This is a standard runner that can run almost all kinds of reports and processes in the background.', '2015-10-24 23:14:15', 4, '2013-10-24 08:43:50', -1, '2015-10-26 04:37:31', 'PID: 8456 Running on: HOITD2ZDP.bog.gov.gh / 0A0027000000 / 169.254.147.108', '\bin\REMSProcessRunner.exe', '5-Lowest', '0');
INSERT INTO rpt.rpt_prcss_rnnrs (prcss_rnnr_id, rnnr_name, rnnr_desc, rnnr_lst_actv_dtetme, created_by, creation_date, last_update_by, last_update_date, rnnr_status, executbl_file_nm, crnt_rnng_priority, shld_rnnr_stop) VALUES (12, 'REQUESTS LISTENER PROGRAM', 'This is the main Program responsible for making sure that your reports and background processes are run by their respective programs when a request is submitted for them to be run.', '2015-10-31 19:37:05', 4, '2013-10-22 07:50:07', -1, '2015-10-31 19:37:05', 'PID: 6332 Running on: HOITD2ZDP.bog.gov.gh / 0A0027000000 / 169.254.147.108', '\bin\REMSProcessRunner.exe', '5-Lowest', '0');



COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'RPT', 'RPT_PRCSS_RNNRS_PRCSS_RNNR_ID_SEQ', 15 );
COMMIT;

