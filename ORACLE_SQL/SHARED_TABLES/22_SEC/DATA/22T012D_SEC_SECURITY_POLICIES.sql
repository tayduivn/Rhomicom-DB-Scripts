/* Formatted on 12-20-2018 1:38:29 PM (QP5 v5.126.903.23003) */
/*
"C:\Program Files (x86)\pgAdmin 4\v3\runtime\pg_dump" --host localhost --port 5432 --username postgres --verbose --table=SEC.SEC_SECURITY_POLICIES --data-only --column-inserts psdc_live > SEC.SEC_SECURITY_POLICIES.sql
*/
set define off;
TRUNCATE TABLE SEC.SEC_SECURITY_POLICIES CASCADE;


INSERT INTO sec.sec_security_policies (policy_id, policy_name, max_failed_lgn_attmpts, pswd_expiry_days, auto_unlocking_time_mins, pswd_require_caps, pswd_require_small, pswd_require_dgt, pswd_require_wild, pswd_reqrmnt_combntns, is_default, created_by, creation_date, last_update_by, last_update_date, old_pswd_cnt_to_disallow, pswd_min_length, pswd_max_length, max_no_recs_to_dsply, allow_repeating_chars, allow_usrname_in_pswds, session_timeout) VALUES (9, 'Rho Standard Policy', 3, 90, 30, '1', '1', '1', '1', 'ANY 3', '0', 116, '2016-07-12 10:27:35', 116, '2016-07-12 10:27:35', 10, 7, 25, 30, '1', '0', 4500);



COMMIT;
EXEC SYS.SEQUENCE_NEWVALUE( 'SEC', 'SEC_SECURITY_POLICIES_SEQ', 10 );
COMMIT;
