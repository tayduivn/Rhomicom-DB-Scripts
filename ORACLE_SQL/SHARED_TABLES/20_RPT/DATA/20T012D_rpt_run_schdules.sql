/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=RPT.RPT_RUN_SCHDULES --data-only --column-inserts psdc_live > RPT.RPT_RUN_SCHDULES.sql
*/
set define off;
TRUNCATE TABLE RPT.RPT_RUN_SCHDULES CASCADE;


INSERT INTO rpt.rpt_run_schdules (schedule_id, report_id, created_by, creation_date, last_update_by, last_update_date, start_dte_tme, repeat_uom, repeat_every, run_at_spcfd_hour) VALUES (7, 24, 8, '2015-02-14 09:06:02', 4, '2015-05-05 03:20:09', '2015-02-14 23:05:27', 'Day(s)', 5, '1');
INSERT INTO rpt.rpt_run_schdules (schedule_id, report_id, created_by, creation_date, last_update_by, last_update_date, start_dte_tme, repeat_uom, repeat_every, run_at_spcfd_hour) VALUES (8, 23, 8, '2015-02-14 09:07:32', 4, '2015-05-05 03:21:15', '2015-02-14 06:06:58', 'Day(s)', 8, '0');



COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'RPT', 'RPT_RUN_SCHDULES_ID_SEQ', 15 );
COMMIT;
