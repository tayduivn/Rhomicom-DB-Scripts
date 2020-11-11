
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=ORG.ORG_DIVS_GROUPS --data-only --column-inserts psdc_live > ORG.ORG_DIVS_GROUPS.sql
*/
set define off;
TRUNCATE TABLE ORG.ORG_DIVS_GROUPS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'ORG_DIVS_GROUPS_SEQ', 2 );
COMMIT;
