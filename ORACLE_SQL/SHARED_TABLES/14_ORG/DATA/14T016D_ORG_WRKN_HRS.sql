
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=ORG.ORG_WRKN_HRS --data-only --column-inserts psdc_live > ORG.ORG_WRKN_HRS.sql
*/
set define off;
TRUNCATE TABLE ORG.ORG_WRKN_HRS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'ORG_WRKN_HRS_SEQ', 2 );
COMMIT;
