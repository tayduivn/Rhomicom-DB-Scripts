/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=SELF.SELF_PERSON_QUESTION_ANSWERS --data-only --column-inserts psdc_live > SELF.SELF_PERSON_QUESTION_ANSWERS.sql
*/
set define off;
TRUNCATE TABLE SELF.SELF_PERSON_QUESTION_ANSWERS CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'SELF', 'SELF_PERSON_QUESTION_ANSWERS_SEQ', 2 );
COMMIT;
