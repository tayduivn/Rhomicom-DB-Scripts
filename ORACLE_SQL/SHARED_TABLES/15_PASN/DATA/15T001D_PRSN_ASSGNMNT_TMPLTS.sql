
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=PASN.PRSN_ASSGNMNT_TMPLTS --data-only --column-inserts psdc_live > PASN.PRSN_ASSGNMNT_TMPLTS.sql
*/
set define off;
TRUNCATE TABLE PASN.PRSN_ASSGNMNT_TMPLTS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'PRSN_ASSGNMNT_TMPLTS_SEQ', 2 );
COMMIT;