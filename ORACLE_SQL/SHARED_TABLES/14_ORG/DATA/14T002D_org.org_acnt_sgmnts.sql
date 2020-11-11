/* Formatted on 12-15-2018 7:43:43 AM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=ORG.ORG_ACNT_SGMNTS --data-only --column-inserts psdc_live > ORG.ORG_ACNT_SGMNTS.sql
*/
set define off;
TRUNCATE TABLE ORG.ORG_ACNT_SGMNTS CASCADE;


COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'ORG_ACNT_SGMNTS_SEQ', 300 );
COMMIT;
