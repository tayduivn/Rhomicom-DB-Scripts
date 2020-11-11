
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=ORG.ORG_GRADES --data-only --column-inserts psdc_live > ORG.ORG_GRADES.sql
*/
set define off;
TRUNCATE TABLE ORG.ORG_GRADES CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'ORG_GRADES_SEQ', 2 );
COMMIT;
