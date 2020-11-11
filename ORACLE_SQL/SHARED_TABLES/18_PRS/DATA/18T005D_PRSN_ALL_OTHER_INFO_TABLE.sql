/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=PRS.PRSN_ALL_OTHER_INFO_TABLE --data-only --column-inserts psdc_live > PRS.PRSN_ALL_OTHER_INFO_TABLE.sql
*/
set define off;
TRUNCATE TABLE PRS.PRSN_ALL_OTHER_INFO_TABLE CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'PRS', 'PRSN_ALL_OTHER_INFO_TABLE_SEQ', 2 );
COMMIT;

