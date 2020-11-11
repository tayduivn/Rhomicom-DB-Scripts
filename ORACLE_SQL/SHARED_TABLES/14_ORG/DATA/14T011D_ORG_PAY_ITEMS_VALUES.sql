
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=ORG.ORG_PAY_ITEMS_VALUES --data-only --column-inserts psdc_live > ORG.ORG_PAY_ITEMS_VALUES.sql
*/
set define off;
TRUNCATE TABLE ORG.ORG_PAY_ITEMS_VALUES CASCADE;




COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'ORG_PAY_ITEMS_VALUES_SEQ', 2 );
COMMIT;
