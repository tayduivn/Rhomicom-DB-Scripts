
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=ORG.ORG_JOBS --data-only --column-inserts psdc_live > ORG.ORG_JOBS.sql
*/
set define off;
TRUNCATE TABLE ORG.ORG_JOBS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'ORG_JOBS_SEQ', 2 );
COMMIT;