/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=SELF.SELF_PRSN_EXTRA_DATA --data-only --column-inserts psdc_live > SELF.SELF_PRSN_EXTRA_DATA.sql
*/
set define off;
TRUNCATE TABLE SELF.SELF_PRSN_EXTRA_DATA CASCADE;





COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'SELF', 'SELF_PRSN_EXTRA_DATA_SEQ', 2 );
COMMIT;
