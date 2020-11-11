/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=SCM.SCM_ALL_OTHER_INFO_TABLE --data-only --column-inserts psdc_live > SCM.SCM_ALL_OTHER_INFO_TABLE.sql
*/
set define off;
TRUNCATE TABLE SCM.SCM_ALL_OTHER_INFO_TABLE CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'SCM', 'SCM_ALL_OTHER_INFO_ROW_ID_SEQ', 2 );
COMMIT;