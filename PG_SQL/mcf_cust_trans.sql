
CREATE OR REPLACE FUNCTION mcf.get_ttl_wdwl_amount(
	v_dte_year integer,
	v_dte_mnth character varying,
	v_mnth_last_day integer,
	v_account_id bigint)
    RETURNS numeric
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
<< outerblock >>
  DECLARE
  v_count      NUMERIC := 0;
  v_rslt CHARACTER VARYING := '';
  v_sql      TEXT := '';
BEGIN

v_sql := 'SELECT sum(amount)
      FROM mcf.mcf_cust_account_transactions a
      WHERE 1 = 1 AND a.account_id = '||v_account_id||'
            AND a.trns_type = ''WITHDRAWAL'' AND a.status IN (''Paid'',''Void'') AND a.amount > 0
            AND doc_no NOT LIKE ''COT%''
            AND substr(trns_date,1,10) >= '''||v_dte_year || '-' || v_dte_mnth || 
            '-01'' AND substr(trns_date,1,10) <= ''' ||v_dte_year || '-' || v_dte_mnth || '-' || v_mnth_last_day||'''';

    EXECUTE v_sql
    INTO v_rslt;

  RETURN v_rslt::NUMERIC;
  EXCEPTION
  WHEN OTHERS THEN
  RETURN '';
END;
$BODY$;


CREATE OR REPLACE FUNCTION mcf.get_ttl_depst_amount(
	v_dte_year integer,
	v_dte_mnth character varying,
	v_mnth_last_day integer,
	v_account_id bigint)
    RETURNS numeric
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
<< outerblock >>
  DECLARE
  v_count      NUMERIC := 0;
  v_rslt CHARACTER VARYING := '';
  v_sql      TEXT := '';
BEGIN

v_sql := 'SELECT sum(amount)
      FROM mcf.mcf_cust_account_transactions a
      WHERE 1 = 1 AND a.account_id = '||v_account_id||'
            AND a.trns_type IN (''DEPOSIT'',''LOAN_REPAY'') AND a.status IN (''Received'',''Void'') AND a.amount > 0
            AND doc_no NOT LIKE ''COT%''
            AND substr(trns_date,1,10) >= '''||v_dte_year || '-' || v_dte_mnth || 
            '-01'' AND substr(trns_date,1,10) <= ''' ||v_dte_year || '-' || v_dte_mnth || '-' || v_mnth_last_day||'''';

    EXECUTE v_sql
    INTO v_rslt;

  RETURN v_rslt::NUMERIC;
  EXCEPTION
  WHEN OTHERS THEN
  RETURN '';
END;
$BODY$;

CREATE OR REPLACE FUNCTION mcf.populate_monthly_trns_sums(
	p_rpt_run_id bigint,
	p_year integer,
	p_branch_id integer,
	p_who_rn bigint,
	p_run_date character varying,
	p_orgidno integer,
	p_msgid bigint)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
<< outerblock >>
    DECLARE
    v_msgs      TEXT;
    v_UpdtMsgs  TEXT;
    vRD         RECORD;
    vRecsDate   CHARACTER VARYING(21);
    v_amnt1     NUMERIC := 0;
    v_amnt2     NUMERIC := 0;
    v_amnt3     NUMERIC := 0;
    v_amnt4     NUMERIC := 0;
    v_amnt5     NUMERIC := 0;
    v_amnt6     NUMERIC := 0;
    v_amnt7     NUMERIC := 0;
    v_amnt8     NUMERIC := 0;
    v_amnt9     NUMERIC := 0;
    v_amnt10     NUMERIC := 0;
    v_amnt11     NUMERIC := 0;
    v_amnt12     NUMERIC := 0;
    
    v_amnt1w     NUMERIC := 0;
    v_amnt2w     NUMERIC := 0;
    v_amnt3w     NUMERIC := 0;
    v_amnt4w     NUMERIC := 0;
    v_amnt5w    NUMERIC := 0;
    v_amnt6w     NUMERIC := 0;
    v_amnt7w     NUMERIC := 0;
    v_amnt8w     NUMERIC := 0;
    v_amnt9w     NUMERIC := 0;
    v_amnt10w     NUMERIC := 0;
    v_amnt11w     NUMERIC := 0;
    v_amnt12w     NUMERIC := 0;
    vCntr       INTEGER := 0;
BEGIN
    SELECT to_char(now(), 'YYYY-MM-DD HH24:MI:SS') INTO vRecsDate;
    DELETE
    FROM rpt.rpt_gnrl_data_storage
    WHERE age(now(), to_timestamp(rpt_run_date, 'YYYY-MM-DD HH24:MI:SS')) > INTERVAL '1 days';
    v_msgs := 'Before Query vRecsDate:' || vRecsDate;
	
    FOR vRD IN
        select tbl1.* FROM (SELECT distinct account_number, 
					account_title ||' ('||mcf.get_cust_local_idno(a.cust_id)||')' accnt_name, 
					account_type, mcf.get_customer_data(
    cust_type,
    cust_id,
    'cntct_no_mobl') tel_number, 
					CASE WHEN p_branch_id = -1 THEN 'All Branches' ELSE org.get_site_code_desc(p_branch_id) END branch,
          a.account_id,a.account_status, a.account_status_reason, a.is_dormant 
FROM mcf.mcf_accounts a 
WHERE 1 = 1
AND a.is_dormant !='Yes'
AND a.account_status = 'Active'
AND a.account_type in ('Savings','Susu','Current','Investment')
AND a.account_number NOT LIKE '777%'
AND a.branch_id = COALESCE(NULLIF(p_branch_id,-1),a.branch_id)) tbl1
        LOOP
				 v_amnt1 :=	coalesce(mcf.get_ttl_depst_amount(p_year,'01','31',
	vRD.account_id),0);
				 v_amnt1w :=	coalesce(mcf.get_ttl_wdwl_amount(p_year,'01','31',
	vRD.account_id),0);
				 v_amnt2 :=	coalesce(mcf.get_ttl_depst_amount(p_year,'02','31',
	vRD.account_id),0);
				 v_amnt2w :=	coalesce(mcf.get_ttl_wdwl_amount(p_year,'02','31',
	vRD.account_id),0);
				 v_amnt3 :=	coalesce(mcf.get_ttl_depst_amount(p_year,'03','31',
	vRD.account_id),0);
				 v_amnt3w :=	coalesce(mcf.get_ttl_wdwl_amount(p_year,'03','31',
	vRD.account_id),0);
				 v_amnt4 :=	coalesce(mcf.get_ttl_depst_amount(p_year,'04','31',
	vRD.account_id),0);
				 v_amnt4w :=	coalesce(mcf.get_ttl_wdwl_amount(p_year,'04','31',
	vRD.account_id),0);
				 v_amnt5 :=	coalesce(mcf.get_ttl_depst_amount(p_year,'05','31',
	vRD.account_id),0);
				 v_amnt5w :=	coalesce(mcf.get_ttl_wdwl_amount(p_year,'05','31',
	vRD.account_id),0);
				 v_amnt6 :=	coalesce(mcf.get_ttl_depst_amount(p_year,'06','31',
	vRD.account_id),0);
				 v_amnt6w :=	coalesce(mcf.get_ttl_wdwl_amount(p_year,'06','31',
	vRD.account_id),0);
				 v_amnt7 :=	coalesce(mcf.get_ttl_depst_amount(p_year,'07','31',
	vRD.account_id),0);
				 v_amnt7w :=	coalesce(mcf.get_ttl_wdwl_amount(p_year,'07','31',
	vRD.account_id),0);
				 v_amnt8 :=	coalesce(mcf.get_ttl_depst_amount(p_year,'08','31',
	vRD.account_id),0);
				 v_amnt8w :=	coalesce(mcf.get_ttl_wdwl_amount(p_year,'08','31',
	vRD.account_id),0);
				 v_amnt9 :=	coalesce(mcf.get_ttl_depst_amount(p_year,'09','31',
	vRD.account_id),0);
				 v_amnt9w :=	coalesce(mcf.get_ttl_wdwl_amount(p_year,'09','31',
	vRD.account_id),0);
				 v_amnt10 :=	coalesce(mcf.get_ttl_depst_amount(p_year,'10','31',
	vRD.account_id),0);
				 v_amnt10w :=	coalesce(mcf.get_ttl_wdwl_amount(p_year,'10','31',
	vRD.account_id),0);
				 v_amnt11 :=	coalesce(mcf.get_ttl_depst_amount(p_year,'11','31',
	vRD.account_id),0);
				 v_amnt11w :=	coalesce(mcf.get_ttl_wdwl_amount(p_year,'11','31',
	vRD.account_id),0);
				 v_amnt12 :=	coalesce(mcf.get_ttl_depst_amount(p_year,'12','31',
	vRD.account_id),0);
				 v_amnt12w :=	coalesce(mcf.get_ttl_wdwl_amount(p_year,'12','31',
	vRD.account_id),0);
                vCntr := vCntr + 1;
                INSERT INTO rpt.rpt_gnrl_data_storage(rpt_run_id,
                                                      rpt_run_date,
                                                      gnrl_data1,
                                                      gnrl_data2,
                                                      gnrl_data3,
                                                      gnrl_data4,
                                                      gnrl_data5,
                                                      gnrl_data6,
                                                      gnrl_data7,
                                                      gnrl_data8,
                                                      gnrl_data9,
                                                      gnrl_data10,
                                                      gnrl_data11,
                                                      gnrl_data12,
                                                      gnrl_data13,
                                                      gnrl_data14,
                                                      gnrl_data15,
                                                      gnrl_data16,
                                                      gnrl_data17,
                                                      gnrl_data18,
                                                      gnrl_data19,
                                                      gnrl_data20,
                                                      gnrl_data21,
                                                      gnrl_data22,
                                                      gnrl_data23,
                                                      gnrl_data24,
                                                      gnrl_data25,
                                                      gnrl_data26,
                                                      gnrl_data27,
                                                      gnrl_data28,
                                                      gnrl_data29,
                                                      gnrl_data30)
                VALUES (p_rpt_run_id,
                        vRecsDate,
                        '' || vCntr,
                        coalesce(vRD.account_number,''),
                        coalesce(vRD.accnt_name,''),
                        coalesce(vRD.account_type,''),
                        coalesce(vRD.tel_number,''),
                        coalesce(vRD.branch,''),
                        '' || v_amnt1,
                        '' || v_amnt1w,
                        '' || v_amnt2,
                        '' || v_amnt2w,
                        '' || v_amnt3,
                        '' || v_amnt3w,
                        '' || v_amnt4,
                        '' || v_amnt4w,
                        '' || v_amnt5,
                        '' || v_amnt5w,
                        '' || v_amnt6,
                        '' || v_amnt6w,
                        '' || v_amnt7,
                        '' || v_amnt7w,
                        '' || v_amnt8,
                        '' || v_amnt8w,
                        '' || v_amnt9,
                        '' || v_amnt9w,
                        '' || v_amnt10,
                        '' || v_amnt10w,
                        '' || v_amnt11,
                        '' || v_amnt11w,
                        '' || v_amnt12,
                        '' || v_amnt12w);
            
            END LOOP;
    v_msgs := v_msgs || chr(10) || 'Successfully Populated Account Transaction Sum into General Data Table!';
    v_UpdtMsgs := rpt.updaterptlogmsg(p_msgid, v_msgs, p_run_date, p_who_rn);
    RETURN v_msgs;
EXCEPTION
    WHEN OTHERS
        THEN
            v_msgs := v_msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
            v_UpdtMsgs := rpt.updaterptlogmsg(p_msgid, v_msgs, p_run_date, p_who_rn);
            RAISE NOTICE 'ERRORS:%', v_msgs;
            RAISE EXCEPTION 'ERRORS:%', v_msgs
                USING HINT = 'Please check your System Setup or Contact Vendor' || v_msgs;
            RETURN v_msgs;
END;
$BODY$;

ALTER TABLE alrt.bulk_msgs_sent
    ALTER COLUMN err_msg TYPE text COLLATE pg_catalog."default";
ALTER TABLE alrt.alrt_msgs_sent
    ALTER COLUMN err_msg TYPE text COLLATE pg_catalog."default";