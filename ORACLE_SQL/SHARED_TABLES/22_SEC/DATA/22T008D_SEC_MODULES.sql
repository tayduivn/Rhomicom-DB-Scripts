/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=SEC.SEC_MODULES --data-only --column-inserts psdc_live > SEC.SEC_MODULES.sql
*/
set define off;
TRUNCATE TABLE SEC.SEC_MODULES CASCADE;


INSERT INTO sec.sec_modules (module_id, module_name, module_desc, date_added, audit_trail_tbl_name) VALUES (59, 'System Administration', 'This module helps you to administer all the security features of this software!', '2016-07-12 10:18:30', 'sec.sec_audit_trail_tbl');
INSERT INTO sec.sec_modules (module_id, module_name, module_desc, date_added, audit_trail_tbl_name) VALUES (60, 'General Setup', '0', '2016-07-12 10:18:39', 'gst.gen_stp_audit_trail_tbl');
INSERT INTO sec.sec_modules (module_id, module_name, module_desc, date_added, audit_trail_tbl_name) VALUES (61, 'Organisation Setup', '0', '2016-07-12 10:18:44', 'org.org_audit_trail_tbl');
INSERT INTO sec.sec_modules (module_id, module_name, module_desc, date_added, audit_trail_tbl_name) VALUES (62, 'Basic Person Data', '0', '2016-07-12 10:18:56', 'prs.prsn_audit_trail_tbl');
INSERT INTO sec.sec_modules (module_id, module_name, module_desc, date_added, audit_trail_tbl_name) VALUES (63, 'Reports And Processes', 'This module helps you to manage all reports in the software!', '2016-07-12 10:19:05', 'rpt.rpt_audit_trail_tbl');
INSERT INTO sec.sec_modules (module_id, module_name, module_desc, date_added, audit_trail_tbl_name) VALUES (64, 'Workflow Manager', 'This module helps you to configure the application''s workflow system!', '2016-07-12 10:19:13', 'wkf.wkf_audit_trail_tbl');
INSERT INTO sec.sec_modules (module_id, module_name, module_desc, date_added, audit_trail_tbl_name) VALUES (65, 'Alerts Manager', 'This module helps you to configure the application''s Alert System!', '2016-07-12 10:19:16', 'alrt.alrt_audit_trail_tbl');
INSERT INTO sec.sec_modules (module_id, module_name, module_desc, date_added, audit_trail_tbl_name) VALUES (66, 'Pharmacy/Stores', 'This module automates the management of the Pharmacy and Clinic stores!', '2016-07-12 10:19:17', 'accb.accb_audit_trail_tbl');
INSERT INTO sec.sec_modules (module_id, module_name, module_desc, date_added, audit_trail_tbl_name) VALUES (67, 'Self Service', 'This module helps your Registered Persons to view and manage their Individual Records when approved!', '2016-07-12 10:19:36', 'self.self_prsn_audit_trail_tbl');
INSERT INTO sec.sec_modules (module_id, module_name, module_desc, date_added, audit_trail_tbl_name) VALUES (68, 'Payment Systems Banking', 'This module helps you to manage the payment systems banking returns!', '2016-07-12 10:19:48', 'sec.sec_audit_trail_tbl');
INSERT INTO sec.sec_modules (module_id, module_name, module_desc, date_added, audit_trail_tbl_name) VALUES (69, 'USD Converter', 'This module is for BOG to convert several currencies to USD in an Excel File!', '2016-07-12 10:24:04', 'bog.bog_audit_trail_tbl');




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'SEC', 'SEC_MODULES_SEQ', 72 );
COMMIT;
