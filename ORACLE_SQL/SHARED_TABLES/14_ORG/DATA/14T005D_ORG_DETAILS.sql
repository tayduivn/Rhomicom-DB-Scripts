
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=ORG.ORG_DETAILS --data-only --column-inserts psdc_live > ORG.ORG_DETAILS.sql
*/
set define off;
TRUNCATE TABLE ORG.ORG_DETAILS CASCADE;

INSERT INTO org.org_details (org_id, org_name, parent_org_id, res_addrs, pstl_addrs, email_addrsses, websites, cntct_nos, org_typ_id, is_enabled, created_by, creation_date, last_update_by, last_update_date, oprtnl_crncy_id, org_logo, org_desc, org_slogan) VALUES (1, 'Bank of Ghana', -1, '', '', '', '', '', 40, '1', 4, '2013-09-24 15:31:50', 4, '2014-02-22 21:54:40', 32, '6.png', '', 'Delivering Quality Healthcare');

COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'ORG', 'ORG_DETAILS_SEQ', 2 );
COMMIT;
