/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=WKF.WKF_APPS_N_HRCHIES --data-only --column-inserts psdc_live > WKF.WKF_APPS_N_HRCHIES.sql
*/
set define off;
TRUNCATE TABLE WKF.WKF_APPS_N_HRCHIES CASCADE;


INSERT INTO wkf.wkf_apps_n_hrchies (app_hrchy_id, app_id, hierarchy_id, is_enabled, created_by, creation_date, last_update_by, last_update_date) VALUES (1, 6, 1, '1', 1, '2016-01-11 10:36:57', 1, '2016-01-11 10:36:57');



COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'WKF', 'WKF_APPS_N_HRCHIES_ID_SEQ', 2 );
COMMIT;

