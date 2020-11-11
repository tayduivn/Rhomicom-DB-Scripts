
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=PASN.PRSN_WORK_ID --data-only --column-inserts psdc_live > PASN.PRSN_WORK_ID.sql
*/
set define off;
TRUNCATE TABLE PASN.PRSN_WORK_ID CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'PASN', 'PRSN_WORK_ID_SEQ', 2 );
COMMIT;
