/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=SEC.SEC_ALLWD_OTHER_INFOS --data-only --column-inserts psdc_live > SEC.SEC_ALLWD_OTHER_INFOS.sql
*/
set define off;
TRUNCATE TABLE SEC.SEC_ALLWD_OTHER_INFOS CASCADE;


INSERT INTO sec.sec_allwd_other_infos (comb_info_id, table_id, other_info_id, is_enabled, created_by, creation_date, last_update_by, last_update_date) VALUES (86, -1, 101, '1', 111, '2016-07-12 08:24:30', 111, '2016-07-12 08:24:30');
INSERT INTO sec.sec_allwd_other_infos (comb_info_id, table_id, other_info_id, is_enabled, created_by, creation_date, last_update_by, last_update_date) VALUES (87, -1, 103, '1', 111, '2016-07-12 08:24:30', 111, '2016-07-12 08:24:30');
INSERT INTO sec.sec_allwd_other_infos (comb_info_id, table_id, other_info_id, is_enabled, created_by, creation_date, last_update_by, last_update_date) VALUES (88, -1, 102, '1', 111, '2016-07-12 08:24:30', 111, '2016-07-12 08:24:30');




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'SEC', 'SEC_ALLWD_OTHER_INFOS_SEQ', 90 );
COMMIT;
