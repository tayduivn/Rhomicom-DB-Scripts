/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=SEC.SEC_MODULE_SUB_GROUPS --data-only --column-inserts psdc_live > SEC.SEC_MODULE_SUB_GROUPS.sql
*/
set define off;
TRUNCATE TABLE SEC.SEC_MODULE_SUB_GROUPS CASCADE;


INSERT INTO sec.sec_module_sub_groups (table_id, sub_group_name, main_table_name, row_pk_col_name, module_id, date_added) VALUES (46, 'Organisation''s Details', 'org.org_details', 'org_id', 61, '2016-07-12 10:18:55');
INSERT INTO sec.sec_module_sub_groups (table_id, sub_group_name, main_table_name, row_pk_col_name, module_id, date_added) VALUES (47, 'Divisions/Groups', 'org.org_divs_groups', 'div_id', 61, '2016-07-12 10:18:55');
INSERT INTO sec.sec_module_sub_groups (table_id, sub_group_name, main_table_name, row_pk_col_name, module_id, date_added) VALUES (48, 'Sites/Locations', 'org.org_sites_locations', 'location_id', 61, '2016-07-12 10:18:56');
INSERT INTO sec.sec_module_sub_groups (table_id, sub_group_name, main_table_name, row_pk_col_name, module_id, date_added) VALUES (49, 'Jobs', 'org.org_jobs', 'job_id', 61, '2016-07-12 10:18:56');
INSERT INTO sec.sec_module_sub_groups (table_id, sub_group_name, main_table_name, row_pk_col_name, module_id, date_added) VALUES (50, 'Grades', 'org.org_grades', 'grade_id', 61, '2016-07-12 10:18:56');
INSERT INTO sec.sec_module_sub_groups (table_id, sub_group_name, main_table_name, row_pk_col_name, module_id, date_added) VALUES (51, 'Positions', 'org.org_positions', 'position_id', 61, '2016-07-12 10:18:56');
INSERT INTO sec.sec_module_sub_groups (table_id, sub_group_name, main_table_name, row_pk_col_name, module_id, date_added) VALUES (52, 'Person Data', 'prs.prsn_names_nos', 'person_id', 62, '2016-07-12 10:19:04');




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'SEC', 'SEC_MODULE_SUB_GROUPS_SEQ', 55 );
COMMIT;
