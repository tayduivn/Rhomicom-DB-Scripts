/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=PRS.HR_PERSON_ABSENCES --data-only --column-inserts psdc_live > PRS.HR_PERSON_ABSENCES.sql
*/
set define off;
TRUNCATE TABLE PRS.HR_PERSON_ABSENCES CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'PRS', 'HR_PERSON_ABSENCES_SEQ', 2 );
COMMIT;

