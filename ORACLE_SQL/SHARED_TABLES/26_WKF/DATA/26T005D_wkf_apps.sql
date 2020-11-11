/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=WKF.WKF_APPS --data-only --column-inserts psdc_live > WKF.WKF_APPS.sql
*/
set define off;
TRUNCATE TABLE WKF.WKF_APPS CASCADE;


INSERT INTO wkf.wkf_apps (app_id, app_name, source_module, app_desc, created_by, creation_date) VALUES (1, 'Login', 'System Administration', 'Login Welcome Messages', 1, '2013-11-25 07:55:01');
INSERT INTO wkf.wkf_apps (app_id, app_name, source_module, app_desc, created_by, creation_date) VALUES (5, 'Clinical Appointments', 'Clinic/Hospital', 'Messages related to Clinic/Hospital Appointments', 1, '2016-01-08 15:39:43');
INSERT INTO wkf.wkf_apps (app_id, app_name, source_module, app_desc, created_by, creation_date) VALUES (6, 'Personal Records Change', 'Basic Person Data', 'Messages related to Basic Person Data Change Requests', 1, '2016-01-08 15:39:44');
INSERT INTO wkf.wkf_apps (app_id, app_name, source_module, app_desc, created_by, creation_date) VALUES (7, 'PSB Forms Submission', 'Payment Systems Banking', 'Messages related to PSB Forms Submitted', 1, '2016-01-22 09:05:21');




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'WKF', 'WKF_WORKFLOW_APPS_APP_ID_SEQ', 10 );
COMMIT;