/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=PRS.LEAVE_DOC_ATTCHMNTS --data-only --column-inserts psdc_live > PRS.LEAVE_DOC_ATTCHMNTS.sql
*/
set define off;
TRUNCATE TABLE PRS.LEAVE_DOC_ATTCHMNTS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'PRS', 'LEAVE_DOC_ATTCHMNTS_SEQ', 2 );
COMMIT;

