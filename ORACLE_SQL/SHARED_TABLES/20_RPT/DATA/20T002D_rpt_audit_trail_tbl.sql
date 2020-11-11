/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=RPT.RPT_AUDIT_TRAIL_TBL --data-only --column-inserts psdc_live > RPT.RPT_AUDIT_TRAIL_TBL.sql
*/
set define off;
TRUNCATE TABLE RPT.RPT_AUDIT_TRAIL_TBL CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'RPT', 'RPT_AUDIT_TRAIL_DFT_ROW_ID_SEQ', 2 );
COMMIT;
