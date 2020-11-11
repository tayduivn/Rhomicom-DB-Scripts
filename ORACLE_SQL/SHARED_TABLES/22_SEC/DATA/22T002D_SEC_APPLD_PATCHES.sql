/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=SEC.SEC_APPLD_PATCHES --data-only --column-inserts psdc_live > SEC.SEC_APPLD_PATCHES.sql
*/
set define off;
TRUNCATE TABLE SEC.SEC_APPLD_PATCHES CASCADE;


INSERT INTO sec.sec_appld_patches (patch_id, patch_description, patch_date, patch_version_nm) VALUES (1, '1. Create Database Comment on the Column accb.accb_running_prcses.which_process_is_rnng

2. Add a new column (last_active_time) to the table (accb.accb_running_prcses)

3. Create the Table sec.sec_appld_patches with its indices', '2014-01-08 18:35:35', 'ROMS V1.0.0 Patch 1');
INSERT INTO sec.sec_appld_patches (patch_id, patch_description, patch_date, patch_version_nm) VALUES (10, '1. Create Database Comment on the Column accb.accb_running_prcses.which_process_is_rnng

2. Add a new column (last_active_time) to the table (accb.accb_running_prcses)

3. Create the Table sec.sec_appld_patches with its indices

4. Change the DataType of Column patch_description in Table sec.sec_appld_patches from Character Varying(200) to Text

5. Period Close Process Stored Procedure Update

6. Deletion of Unposted Period Close Process Stored Procedure Update

7. Reversal of Posted Period Close Process Stored Procedure Update

8. Change index accb.idx_batch_name from UNIQUE to normal Index

9. UPDATE of accb.get_batch_id FUNCTION

10.UPDATE of accb.get_todysbatch_id FUNCTION

11.Change all double precision datatypes to numeric data type in all Money based Columns and Functions', '2014-01-23 12:51:33', 'ROMS V1.0.0 Patch 2');
INSERT INTO sec.sec_appld_patches (patch_id, patch_description, patch_date, patch_version_nm) VALUES (14, '1. Create Database Comment on the Column accb.accb_running_prcses.which_process_is_rnng

2. Add a new column (last_active_time) to the table (accb.accb_running_prcses)

3. Create the Table sec.sec_appld_patches with its indices

4. Change the DataType of Column patch_description in Table sec.sec_appld_patches from Character Varying(200) to Text

5. Period Close Process Stored Procedure Update

6. Deletion of Unposted Period Close Process Stored Procedure Update

7. Reversal of Posted Period Close Process Stored Procedure Update

8. Change index accb.idx_batch_name from UNIQUE to normal Index

9. UPDATE of accb.get_batch_id FUNCTION

10.UPDATE of accb.get_todysbatch_id FUNCTION

11.Change all double precision datatypes to numeric data type in all Money based Columns and Functions', '2014-01-31 09:56:20', 'REMS/ROMS V1.0.0 Patch 3');
INSERT INTO sec.sec_appld_patches (patch_id, patch_description, patch_date, patch_version_nm) VALUES (15, '1. No DB Patch Available. Database must be restored using this APP!', '2014-06-29 08:00:16', 'ROMS/REMS V1.0.0 Patch 6');
INSERT INTO sec.sec_appld_patches (patch_id, patch_description, patch_date, patch_version_nm) VALUES (16, '1. No DB Patch Available. Database must be restored using this APP!', '2015-03-05 08:18:09', 'ROMS/REMS V1 P8');
INSERT INTO sec.sec_appld_patches (patch_id, patch_description, patch_date, patch_version_nm) VALUES (17, '1. No DB Patch Available. Database must be restored using this APP!', '2015-03-25 14:18:42', 'ROMS/REMS V1 P9');
INSERT INTO sec.sec_appld_patches (patch_id, patch_description, patch_date, patch_version_nm) VALUES (18, '1. No DB Patch Available. Database must be restored using this APP!', '2015-04-08 20:01:55', 'ROMS/REMS V1 P10');
INSERT INTO sec.sec_appld_patches (patch_id, patch_description, patch_date, patch_version_nm) VALUES (19, '1. No DB Patch Available. Database must be restored using this APP!', '2015-05-13 12:58:05', 'ROMS/REMS V1 P11');
INSERT INTO sec.sec_appld_patches (patch_id, patch_description, patch_date, patch_version_nm) VALUES (20, '1. No DB Patch Available. Database must be restored using this APP!', '2015-08-20 22:52:54', 'ROMS/REMS V1 P21');
INSERT INTO sec.sec_appld_patches (patch_id, patch_description, patch_date, patch_version_nm) VALUES (21, '1. No DB Patch Available. Database must be restored using this APP!', '2016-11-25 11:34:44', 'ROMS/REMS V1 P25');




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'SEC', 'SEC_APPLD_PATCHES_SEQ', 25 );
COMMIT;