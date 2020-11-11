/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=SELF.SELF_PRSN_WORK_EXPERIENCE --data-only --column-inserts psdc_live > SELF.SELF_PRSN_WORK_EXPERIENCE.sql
*/
set define off;
TRUNCATE TABLE SELF.SELF_PRSN_WORK_EXPERIENCE CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'SELF', 'SELF_PRSN_WORK_EXPERIENCE_SEQ', 2 );
COMMIT;
