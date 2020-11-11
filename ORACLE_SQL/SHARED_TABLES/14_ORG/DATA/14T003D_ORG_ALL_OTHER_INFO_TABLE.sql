
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=ORG.ORG_ALL_OTHER_INFO_TABLE --data-only --column-inserts psdc_live > ORG.ORG_ALL_OTHER_INFO_TABLE.sql
*/
set define off;
TRUNCATE TABLE ORG.ORG_ALL_OTHER_INFO_TABLE CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'ORG_ALL_OTHER_INFO_TABLE_SEQ', 2 );
COMMIT;
