/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=RPT.RPT_REPORT_RUNS --data-only --column-inserts psdc_live > RPT.RPT_REPORT_RUNS.sql
*/
set define off;
TRUNCATE TABLE RPT.RPT_REPORT_RUNS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'RPT', 'RPT_REPORT_RUNS_RPT_RUN_ID_SEQ', 2 );
COMMIT;

