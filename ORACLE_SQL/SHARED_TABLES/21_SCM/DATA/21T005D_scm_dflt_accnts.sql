/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=SCM.SCM_DFLT_ACCNTS --data-only --column-inserts psdc_live > SCM.SCM_DFLT_ACCNTS.sql
*/
set define off;
TRUNCATE TABLE SCM.SCM_DFLT_ACCNTS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'SCM', 'SCM_DFLT_ACCNTS_ROW_ID_SEQ', 2 );
COMMIT;
