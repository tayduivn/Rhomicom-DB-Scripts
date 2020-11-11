/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=SEC.SEC_EMAIL_SERVERS --data-only --column-inserts psdc_live > SEC.SEC_EMAIL_SERVERS.sql
*/
set define off;
TRUNCATE TABLE SEC.SEC_EMAIL_SERVERS CASCADE;


INSERT INTO sec.sec_email_servers (server_id, smtp_client, mail_user_name, mail_password, smtp_port, is_default, actv_drctry_domain_name, created_by, creation_date, last_update_by, last_update_date, ftp_server_url, ftp_user_name, ftp_user_pswd, ftp_port, ftp_app_sub_directory, enforce_ftp, pg_dump_dir, backup_dir, com_port, baud_rate, timeout, sms_param1, sms_param2, sms_param3, sms_param4, sms_param5, sms_param6, sms_param7, sms_param8, sms_param9, sms_param10, ftp_user_start_directory) VALUES (9, 'smtp.gmail.com', 'rhomicomgh@gmail.com', 'EECmyLCmTELItT77tT7', 587, '0', 'rhomicom.com', 116, '2018-01-05 13:44:35', 116, '2018-01-05 13:44:35', 'ftp://127.0.0.1', 'ftpuser', 'EECmyLCmTELItT77tT7', 21, '/test_database', '0', 'C:\PSDC\REMS_Data\Images\Logs', 'C:\PSDC\REMS_Data\Images\psdc_live_db\DB_Backups', '1', '9600', '1200', 'url|http://txtconnect.co/api/send/', 'token|123456789', 'msg|{:msg}', 'from|Rhomicom', 'to|{:to}', 'Extra Param1|', 'Extra Param2|', 'Extra Param3|', 'Extra Param4|', 'success txt|"error":0', '');
INSERT INTO sec.sec_email_servers (server_id, smtp_client, mail_user_name, mail_password, smtp_port, is_default, actv_drctry_domain_name, created_by, creation_date, last_update_by, last_update_date, ftp_server_url, ftp_user_name, ftp_user_pswd, ftp_port, ftp_app_sub_directory, enforce_ftp, pg_dump_dir, backup_dir, com_port, baud_rate, timeout, sms_param1, sms_param2, sms_param3, sms_param4, sms_param5, sms_param6, sms_param7, sms_param8, sms_param9, sms_param10, ftp_user_start_directory) VALUES (8, '172.25.60.237', 'richard.adjei-mensah@bog.gov.gh', 'EmzmLIzmZLCmLCEUcGityEzzmEz', 25, '1', 'bog.gov.gh', 116, '2016-07-12 10:27:39', 116, '2018-01-05 13:49:06', 'ftp://127.0.0.1', 'root', 'CyzmLIzmcEHIcEc66HczE6zzEHk7CTzzmEz', 21, '/test_database', '0', 'C:\PSDC\REMS_Data\Images\Logs', 'C:\PSDC\REMS_Data\Images\psdc_live_db\DB_Backups', '1', '9600', '1200', 'url|http://bog.gov.gh', 'token|12345678923456787uhyg', 'msg|{:msg}', 'from|BOG', 'to|{:to}', 'Extra Param1|', 'Extra Param2|', 'Extra Param3|', 'Extra Param4|', 'success txt|"error":0', '');



COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'SEC', 'SEC_EMAIL_SERVERS_SEQ', 12 );
COMMIT;
