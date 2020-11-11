/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=ORG.ORG_ACCOUNT_CLSFCTNS --data-only --column-inserts psdc_live > ORG.ORG_ACCOUNT_CLSFCTNS.sql
*/
set define off;
TRUNCATE TABLE ORG.ORG_ACCOUNT_CLSFCTNS CASCADE;


COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'ORG_ACCOUNT_CLSFCTNS_SEQ', 300 );
COMMIT;
