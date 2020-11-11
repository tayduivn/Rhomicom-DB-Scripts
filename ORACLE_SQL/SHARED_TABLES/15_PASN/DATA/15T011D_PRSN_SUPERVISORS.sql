
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=PASN.PRSN_SUPERVISORS --data-only --column-inserts psdc_live > PASN.PRSN_SUPERVISORS.sql
*/
set define off;
TRUNCATE TABLE PASN.PRSN_SUPERVISORS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'PASN', 'PRSN_SUPERVISORS_SEQ', 2 );
COMMIT;
