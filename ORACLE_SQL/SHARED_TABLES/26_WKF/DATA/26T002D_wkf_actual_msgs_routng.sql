/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=WKF.WKF_ACTUAL_MSGS_ROUTNG --data-only --column-inserts psdc_live > WKF.WKF_ACTUAL_MSGS_ROUTNG.sql
*/
set define off;
TRUNCATE TABLE WKF.WKF_ACTUAL_MSGS_ROUTNG CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'WKF', 'WKF_ACTUAL_MSGS_ROUTNG_SEQ', 2 );
COMMIT;
