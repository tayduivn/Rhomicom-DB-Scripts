
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=ORG.ORG_POSITIONS --data-only --column-inserts psdc_live > ORG.ORG_POSITIONS.sql
*/
set define off;
TRUNCATE TABLE ORG.ORG_POSITIONS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'ORG_POSITIONS_SEQ', 2 );
COMMIT;
