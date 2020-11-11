/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=SEC.SEC_TRACK_USER_LOGINS --data-only --column-inserts psdc_live > SEC.SEC_TRACK_USER_LOGINS.sql
*/
set define off;
TRUNCATE TABLE SEC.SEC_TRACK_USER_LOGINS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'SEC', 'SEC_TRACK_USER_LOGINS_SEQ', 2 );
COMMIT;
