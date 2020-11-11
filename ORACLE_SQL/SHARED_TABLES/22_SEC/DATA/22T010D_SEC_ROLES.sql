/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=SEC.SEC_ROLES --data-only --column-inserts psdc_live > SEC.SEC_ROLES.sql
*/
set define off;
TRUNCATE TABLE SEC.SEC_ROLES CASCADE;


INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (72, 'System Administrator', '2016-07-12 10:18:30', '4000-12-31 00:00:00', 116, '2016-07-12 10:18:30', 116, '2016-07-12 10:18:30', '0');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (73, 'General Setup Administrator', '2016-07-12 10:18:39', '4000-12-31 00:00:00', 116, '2016-07-12 10:18:39', 116, '2016-07-12 10:18:39', '0');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (74, 'Organisation Setup Administrator', '2016-07-12 10:18:44', '4000-12-31 00:00:00', 116, '2016-07-12 10:18:44', 116, '2016-07-12 10:18:44', '0');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (75, 'Basic Person Data Administrator', '2016-07-12 10:18:56', '4000-12-31 00:00:00', 116, '2016-07-12 10:18:56', 116, '2016-07-12 10:18:56', '0');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (76, 'Reports And Processes Administrator', '2016-07-12 10:19:05', '4000-12-31 00:00:00', 116, '2016-07-12 10:19:05', 116, '2016-07-12 10:19:05', '0');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (77, 'Workflow Manager Administrator', '2016-07-12 10:19:13', '4000-12-31 00:00:00', 116, '2016-07-12 10:19:13', 116, '2016-07-12 10:19:13', '0');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (78, 'Alerts Manager Administrator', '2016-07-12 10:19:16', '4000-12-31 00:00:00', 116, '2016-07-12 10:19:16', 116, '2016-07-12 10:19:16', '0');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (79, 'Inventory Administrator', '2016-07-12 10:19:17', '4000-12-31 00:00:00', 116, '2016-07-12 10:19:17', 116, '2016-07-12 10:19:17', '0');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (80, 'Self-Service Administrator', '2016-07-12 10:19:36', '4000-12-31 00:00:00', 116, '2016-07-12 10:19:36', 116, '2016-07-12 10:19:36', '0');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (81, 'Self-Service (Standard)', '2016-07-12 10:19:44', '4000-12-31 00:00:00', 116, '2016-07-12 10:19:44', 116, '2016-07-12 10:19:44', '0');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (82, 'PSB Administrator', '2016-07-12 10:19:48', '4000-12-31 00:00:00', 116, '2016-07-12 10:19:48', 116, '2016-07-12 10:19:48', '0');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (83, 'USD Converter Administrator', '2016-07-12 10:24:04', '4000-12-31 00:00:00', 116, '2016-07-12 10:24:04', 116, '2016-07-12 10:24:04', '0');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (84, 'PSB Data Capturer (Bank)', '2016-07-12 11:13:45', '4000-12-31 23:59:59', 116, '2016-07-12 11:13:45', 116, '2016-07-12 11:13:45', '1');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (86, 'Administer My Institution''s Users', '2016-07-01 00:00:00', '4000-12-31 23:59:59', 116, '2016-07-14 12:50:13', 116, '2016-07-14 14:49:16', '1');
INSERT INTO sec.sec_roles (role_id, role_name, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date, can_mini_admins_assign) VALUES (85, 'PSB Data Capturer (Telco)', '2016-07-12 11:13:57', '4000-12-31 23:59:59', 116, '2016-07-12 11:13:57', 116, '2016-07-18 08:15:06', '1');



COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'SEC', 'SEC_ROLES_SEQ', 90 );
COMMIT;
