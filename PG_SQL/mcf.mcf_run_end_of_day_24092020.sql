-- Function: mcf.mcf_run_end_of_day(integer, character varying, integer, bigint, character varying)

-- DROP FUNCTION mcf.mcf_run_end_of_day(integer, character varying, integer, bigint, character varying);

CREATE OR REPLACE FUNCTION mcf.mcf_run_end_of_day(
    usr_id integer,
    run_type character varying,
    orgidno integer,
    msgid bigint,
    prcs_type character varying)
  RETURNS text AS
$BODY$

DECLARE
 
  cur_sod_date           CHARACTER VARYING := '';

  nxt_sod_date           CHARACTER VARYING;
  rcrd_count             INTEGER;

  rowAccts               RECORD;
  rowLoans               RECORD;
  rowOD                  RECORD;
  rowLoanSchdle          RECORD;
  rowInvstmnts           RECORD;
  rowOvdrwnAccts         RECORD;
  rowLnPymntsTday        RECORD;
  rowLnDfltTday          RECORD;
  rowActiveAccts	 RECORD;
  rowDet		 RECORD;
  rowSMSFees              RECORD;

  tday_dte               CHARACTER VARYING;
  next_sod_dte           CHARACTER VARYING;
  v_month_cur            INTEGER;
  v_month_nxt            INTEGER;

  is_hldy                BOOLEAN := FALSE;
  is_wknd                BOOLEAN := FALSE;

  cnta1                  INTEGER := 0;
  msgs                   TEXT := 'End of Day Process About to Start...';
  gl_btchID              BIGINT :=-1;

  tmp_dbt                NUMERIC :=0;
  tmp_crdt               NUMERIC :=0;
  tmp_net                NUMERIC :=0;
  tmp_dbt_crdt           CHARACTER VARYING(1);
  cur_ID                 BIGINT :=-1;

  cnta2                  INTEGER := 0;
  cnta3                  INTEGER := 0;
  cnta4                  INTEGER := 0;
  cnta5                  INTEGER := 0;
  cnta9			 INTEGER := 0;
  cnta8			 INTEGER := 0;

  lv_schedule_id         BIGINT := -1;
  lv_repay_date          CHARACTER VARYING(21);
  lv_interest_amnt       NUMERIC := 0;
  lv_principal_amnt      NUMERIC := 0;
  lv_is_paid             CHARACTER VARYING(15) :=  'NO';
  lv_interest_amnt_paid  NUMERIC := 0;
  lv_principal_amnt_paid NUMERIC := 0;

  od_avlbl_bal           NUMERIC := 0.0;
  od_apprvd_loan_amnt    NUMERIC := 0.0;
  od_ovdrwn_acct_bal     NUMERIC := 0.0;
  od_interest_tday       NUMERIC := 0.0;
  msgs1                  TEXT := '';

  avlbl_acct_bal         NUMERIC := 0;
  v_is_paid              CHARACTER VARYING(15) := 'NO';

  lp_fee_name            CHARACTER VARYING(200);
  lp_target              CHARACTER VARYING(50);
  lp_fee_flat            NUMERIC := 0;
  lp_fee_percent         NUMERIC := 0;
  lp_crdt_accnt_id       BIGINT := -1;

  lp_late_pnlty_fee      NUMERIC := 0.0;

  ai_account_id          BIGINT;
  ai_status              CHARACTER VARYING(20);
  ai_account_title       CHARACTER VARYING(300);
  ai_lien_bal            NUMERIC;
  ai_mandate             CHARACTER VARYING(50);
  ai_limit_no            INTEGER;
  ai_limit_amnt          NUMERIC;
  ai_withdrawal_limit    CHARACTER VARYING(15);
  ai_account_number      CHARACTER VARYING(300);

  optn_acct_bal          NUMERIC := 0.00;
  ovdrwn_pnlty_fee       NUMERIC := 0.00;

  updtMsg                BIGINT :=0;
  p_cob_record_id        BIGINT := -1;

  v_loan_prncpl_bal      NUMERIC := 0;
  v_loan_intrst_bal      NUMERIC := 0;
  v_loan_tenure_bal      NUMERIC := 0;

  v_proceed_wd_eod       TEXT := 'DISCONTINUE';
  v_loan_rpymnt_msg      TEXT := '';
  v_loan_dflt_msg        TEXT := '';
  v_loan_age             INTEGER := 0;

  v_loan_clsfctn_id      BIGINT := -1;
  v_provision_prcnt      NUMERIC := 0;

  v_lien_cnt             INTEGER := 0;
  v_lien_amt             NUMERIC := 0.00;

  rowAcctsIntCrdtn       RECORD;
  v_day_part             NUMERIC;
  v_mnth_part            NUMERIC;
  v_year_part            NUMERIC;
  v_int_bal_date         CHARACTER VARYING;
  v_intprcsn_status      CHARACTER VARYING;
  rowCOT                 RECORD;
  v_mnthly_wdwls         INTEGER := 0;
  v_mnth_last_day        INTEGER;
  v_dte_year             INTEGER;
  v_dte_mnth             INTEGER;
  v_dte_mnth_char	 CHARACTER VARYING(2) := NULL;
  v_fee_flat             NUMERIC := 0;
  v_fee_prcnt            NUMERIC := 0;
  v_cmsn_ttl             NUMERIC := 0;
  ft_rcrd_count 	 INTEGER := 0;
  
  v_acct_trns_cnt	 INTEGER := 0;
  v_drmcy_max_date	 CHARACTER VARYING := '';
  v_drmncy_period        NUMERIC := 0;	 
  v_acct_actvty_age      NUMERIC := 0;
  v_dormant_acct_cnt 	 INTEGER := 0;

  v_dflt_day_cna INTEGER := 0;  

  v_trns_tm 	CHARACTER VARYING := '';
  msgs_stndnordrs 	text := '';
  v_ttl_wdwl NUMERIC := 0.00;
  v_ttl_mnth_no           NUMERIC := 0;
  v_daily_intrst_val      NUMERIC := 0;
  v_dly_earned_intrst     NUMERIC := 0;
  v_tdy_svgns_interest    NUMERIC := 0;
  v_nxt_svgns_interest    NUMERIC := 0;
  v_ttl_intrst_accrued    NUMERIC := 0;
  v_ttl_loan_prncpl_msg    NUMERIC := 0;
  v_ttl_loan_intrst_msg    NUMERIC := 0;
  v_daily_bal_id BIGINT := -1;
  p_gnrtdTrnsNo CHARACTER VARYING;
  p_usrTrnsCode CHARACTER VARYING;
  p_dte CHARACTER VARYING;
  v_sms_rec_cnt			  INTEGER := 0;
  v_sms_rslt_cnt			  INTEGER := 0;  
  v_ptime CHARACTER VARYING(21) := '';
  v_intprcn_cnt INTEGER := 0;
  v_intprcn_rec INTEGER := 0;
  v_yr CHARACTER VARYING := '';
  v_fmtd_month CHARACTER VARYING := '';
  x_ctgrz_rslt CHARACTER VARYING(4000) := NULL;
  v_od_update_rslt CHARACTER VARYING(4000) := '';
  v_lqdtn_id bigint := -1;
  v_insrt_lqdtn_rslt CHARACTER VARYING(4000) := '';
  v_lqdtn_trnsctn_no CHARACTER VARYING(4000) := NULL;
  v_ttl_fees NUMERIC := 0.00;

  v_rlovr_amnt NUMERIC:= 0;
  v_rlovr_maturity_dte CHARACTER VARYING(10);
  v_rlovr_tenor_in_days NUMERIC := 0;
  v_rlovr_invstmnt_id BIGINT := -1; 
  v_usr_trns_code CHARACTER VARYING := '';
  v_rlovr_interest_rate NUMERIC := 0;
  v_rlovr_maturity_val NUMERIC := 0;
  v_rlovr_prcss_rslt CHARACTER VARYING(4000) := '';
  v_rlovr_invstmnt_acctid BIGINT := -1;

  v_qryWdwlCnt CHARACTER VARYING(4000) := '';

  rowSupLoanAccnts RECORD;
  rng_avlbl_acct_bal NUMERIC := 0.00;
  rwOtsdnShdl RECORD;
  lv_ttl_lnoutsndn_bal NUMERIC := 0.00;
  lv_bal_cnt INTEGER := 0;
  v_net_supaccnt_trnsf NUMERIC := 0.00;
  v_ttl_fnds_trnsf NUMERIC := 0.00;
  dst_loan_account_no CHARACTER VARYING(50) := '';
  ln_clsf_rc_cnt INTEGER := 0;

  v_provision_amnt      NUMERIC := 0;
  v_prev_provision_amnt NUMERIC := 0;

  tmp_dbt_acct_id BIGINT := -1;
  tmp_crdt_acct_id BIGINT := -1;
  v_rnng_provision_amnt NUMERIC := 0.00;
  v_enable_prvsn_flag        CHARACTER VARYING(30) := 'NO';
  v_ln_write_cnt INTEGER := 0;
BEGIN

  SELECT count(*) INTO ft_rcrd_count FROM mcf.mcf_cob_trns_records;	

  SELECT to_char(now(), 'yyyy-mm-dd HH24:MI:SS')
  INTO tday_dte;

  SELECT mcf.xx_get_start_of_day_date($3)
  INTO cur_sod_date;

  --DELETE THIS BLOCK
  /*INSERT INTO rpt.rpt_run_msgs (
    msg_id, log_messages, process_typ, process_id, created_by, creation_date,
    last_update_by, last_update_date)
  VALUES (msgid, '', 'Process Run', msgid, 1, tday_dte,
          1, tday_dte);*/
  --END OF DELETE THIS BLOCK
    IF ft_rcrd_count > 0
    THEN
	  SELECT mcf.xx_get_sod_pending_transactions(cur_sod_date, $3)
	  INTO v_proceed_wd_eod;

	  IF v_proceed_wd_eod != 'PROCEED'
	  THEN
	    msgs := v_proceed_wd_eod;

	    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
	    --msgs:=rpt.getLogMsg($4);
	    RETURN msgs;
	  END IF;
    END IF;  
    
  SELECT nextval('mcf.mcf_cob_trns_records_cob_record_id_seq' :: REGCLASS)
  INTO p_cob_record_id;

  SELECT mcf.xx_get_next_start_of_day_date($3, cur_sod_date)
  INTO nxt_sod_date;



    IF ft_rcrd_count <= 0
    THEN
	  --INSERT CURRENT COB DATE
	  INSERT INTO mcf.mcf_cob_trns_records (
	    cob_run_date, cob_status, created_by, creation_date,
	    last_update_by, last_update_date, start_of_day_date, remarks, org_id)
	  VALUES (cur_sod_date || ' ' || to_char(now(), 'HH24:MI:SS'), 'SUCCESS',
	  $1, tday_dte,
	  $1, tday_dte,
	  cur_sod_date, '', $3);
    
       msgs := 'Inserting COB Record, First Time....';
       updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
       --msgs:=rpt.getLogMsg($4);
       RETURN msgs;
    ELSE

	  --INSERT NEXT OF DAY DATE
	  INSERT INTO mcf.mcf_cob_trns_records (
	    cob_run_date, cob_status, created_by, creation_date,
	    last_update_by, last_update_date, start_of_day_date, remarks, org_id)
	  VALUES (cur_sod_date || ' ' || to_char(now(), 'HH24:MI:SS'), 'SUCCESS',
	  $1, tday_dte,
	  $1, tday_dte,
	  nxt_sod_date, '', $3);    
	       
    END IF;  
  
  msgs := 'Executing Standing Orders. Please wait....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  
  SELECT mcf.execute_standing_order(-1, $1, cur_sod_date, $3, $4) INTO msgs_stndnordrs;
  msgs := msgs_stndnordrs;
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  
  msgs := 'Completed Execution of Standing Orders'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

  
  msgs := 'Checking for dormant accounts. Please wait....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  --FLAG DORMANT ACCOUNTS 
  FOR rowActiveAccts IN (
	SELECT account_id, rvsn_ttl
	FROM mcf.mcf_accounts
	WHERE 1 = 1 
	/*is_dormant = 'No'*/
	AND status = 'Authorized')
  LOOP
	--get count of account transactions
	SELECT COUNT(*) INTO v_acct_trns_cnt 
	FROM mcf.mcf_cust_account_transactions
	WHERE account_id = rowActiveAccts.account_id
	and trns_type in ('DEPOSIT','WITHDRAWAL')
	AND to_timestamp(trns_date,'YYYY-MM-DD') != to_timestamp('2018-01-01','YYYY-MM-DD');

	IF v_acct_trns_cnt > 0 
	THEN
	--GET MAX DATE
		SELECT max(trns_date) INTO v_drmcy_max_date 
		FROM mcf.mcf_cust_account_transactions
		WHERE account_id = rowActiveAccts.account_id
		and trns_type in ('DEPOSIT','WITHDRAWAL')
		AND to_timestamp(trns_date,'YYYY-MM-DD') != to_timestamp('2018-01-01','YYYY-MM-DD');

		IF v_drmcy_max_date != ''
		THEN
		--GET AGE OF DATE
			--SELECT EXTRACT(DAY FROM ('2019-04-13'::timestamp - cast('2019-04-26 16:01:25' AS DATE)))::NUMERIC INTO v_acct_actvty_age;
			SELECT EXTRACT(DAY FROM (cur_sod_date::timestamp - cast(v_drmcy_max_date AS DATE)))::NUMERIC INTO v_acct_actvty_age;

			BEGIN
				--GET DORMANCY PERIOD
				SELECT var_value::NUMERIC INTO v_drmncy_period 
				FROM mcf.mcf_global_variables
				WHERE var_name = 'Dormancy Period in Days';
			EXCEPTION
			WHEN OTHERS THEN
			    msgs := SQLSTATE || chr(10) || SQLERRM;
			
			    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
			    --msgs:=rpt.getLogMsg($4);
			    RETURN msgs;
			END;


			IF v_acct_actvty_age > 0 AND v_drmncy_period > 0 AND v_acct_actvty_age >= v_drmncy_period
			THEN
				UPDATE mcf.mcf_accounts
				SET is_dormant = 'Yes'
				WHERE account_id = rowActiveAccts.account_id;

				UPDATE mcf.mcf_accounts_hstrc
				SET is_dormant = 'Yes'
				WHERE account_id = rowActiveAccts.account_id
				AND rvsn_ttl =  rowActiveAccts.rvsn_ttl
				AND status IN ('Rejected','Withdrawn','Incomplete');

				v_dormant_acct_cnt :=  v_dormant_acct_cnt + 1;	
			ELSE
				UPDATE mcf.mcf_accounts
				SET is_dormant = 'No'
				WHERE account_id = rowActiveAccts.account_id;

				UPDATE mcf.mcf_accounts_hstrc
				SET is_dormant = 'No'
				WHERE account_id = rowActiveAccts.account_id
				AND rvsn_ttl =  rowActiveAccts.rvsn_ttl
				AND status IN ('Rejected','Withdrawn','Incomplete');
			END IF;
		
		END IF;
	END IF;
	
  END LOOP;
  

  
  msgs := 'Flaged '||v_dormant_acct_cnt||' Accounts as Dormant. Process Ended'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);


SELECT mcf.xx_categorize_cust_accounts() INTO x_ctgrz_rslt;

  IF x_ctgrz_rslt != 'TRUE'
  THEN
    msgs := 'Failed to Categorize Accounts';
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
    --RETURN msgs;
  ELSE
     msgs := 'Account Categorization Successful';
     updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  END IF;
  
  UPDATE  mcf.mcf_loan_schedule
  set repay_date = '4000-12-31'
  WHERE repay_date = '';

    --FIX INVALID REPAY_END_DATE
  FOR rowDet IN (SELECT DISBMNT_DET_ID, repay_end_date, 
  substr(repay_end_date,(5+(length(repay_end_date)-8)))||'-'||to_char(to_timestamp(substr(repay_end_date,4,(length(repay_end_date)-8)),'Mon'),'MM')||'-'||substr(repay_end_date,1,2) new_red FROM MCF.MCF_LOAN_DISBURSEMENT_DET
  WHERE 1 = 1
  AND SUBSTR(repay_end_date,6,1) NOT IN ('0','1'))
  LOOP

	  UPDATE MCF.MCF_LOAN_DISBURSEMENT_DET
	  SET repay_end_date = rowDet.new_red
	  WHERE disbmnt_det_id = rowDet.disbmnt_det_id;

  END LOOP;

  UPDATE MCF.mcf_loan_schedule
  SET ACTUAL_REPAY_DATE = SUBSTR(ACTUAL_REPAY_DATE,1,10)
  WHERE LENGTH(actual_repay_date) > 10;

  -- FIX INCOMPLE LIEN REMOVALS
  UPDATE mcf.mcf_account_liens
  SET lien_status = 'Active'
  WHERE acct_lien_id in (SELECT DISTINCT acct_lien_id
  FROM mcf.mcf_account_liens
  WHERE lien_status  = 'Removed'
  AND end_date_active = '4000-12-31');

  UPDATE MCF.MCF_ACCOUNT_LIENS X
  SET RVSN_TTL = (SELECT rvsn_ttl FROM mcf.mcf_accounts where account_id = x.account_id)
  WHERE x.acct_lien_id IN
  (SELECT b.acct_lien_id
  from mcf.mcf_account_liens b, mcf.mcf_accounts a
  WHERE a.account_id = b.account_id
  AND a.status = 'Authorized'
  AND b.lien_status = 'Active'
  and a.rvsn_ttl != (select max(rvsn_ttl) FROM mcf.mcf_account_liens WHERE account_id = a.account_id AND lien_status = 'Active')
  order  by 1);

 --Delete zero accrued interest records with 
 DELETE FROM mcf.mcf_daily_acct_bals_n_interest WHERE interest_earned = 0;

  DELETE FROM mcf.mcf_daily_acct_bals_n_interest WHERE is_interest_paid = 'Yes'; 

  --Round all inteface transactions to 2 decimal places
  UPDATE mcf.mcf_gl_interface
  SET crdt_amount = round(crdt_amount,2),
  dbt_amount = round(dbt_amount,2),
  net_amount = round(net_amount,2)
  WHERE gl_batch_id = -1;

  --Fix invalid creation_data and last_update_date
  UPDATE mcf.mcf_cust_account_transactions
  SET creation_date = to_char(to_timestamp(creation_date, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS')
  where char_length(creation_date) = 20;

  UPDATE mcf.mcf_cust_account_transactions
  SET last_update_date = to_char(to_timestamp(last_update_date, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS')
  where char_length(last_update_date) = 20;
  
  msgs := 'Creating Customer Account GL Batch Header Process....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  
  SELECT to_char(now(), 'YYYYMMDDHH24MISS') INTO v_trns_tm;
  IF gl_btchID <= 0
  THEN
    INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date,
                                           org_id, batch_status, last_update_by, last_update_date, batch_source)
    VALUES
      ('End of Day Process - Account Transactions (' || cur_sod_date || ')-' || v_trns_tm,
       'End of Day Process - Account Transactions (' || cur_sod_date || ')-' || v_trns_tm,
       $1, tday_dte, $3, '0', $1, tday_dte, 'End of Day Process - Account Transactions');
    --COMMIT;
  END IF;

  SELECT COALESCE(accb.get_TodysBatch_id('End of Day Process - Account Transactions (' || cur_sod_date, $3), -1)
  INTO gl_btchID;
  msgs := 'End of Day Process GL Batch ID= ' ||
          trim(to_char(gl_btchID, '999999999999999999999999999999999999999999'));
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
            
  msgs := 'End of Day Process GL Batch Name= ''End of Day Process - Account Transactions (' || cur_sod_date || ')''';
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

  --RAISE NOTICE 'FULL Query = "%"', tday_dte;

  --ACCOUNT
  /**ACCOUNT TRANSACTIONS **/
  FOR rowAccts IN (SELECT
                     b.account_title,
                     b.account_id,
                     b.branch_id,
                     coalesce(interest_rate, 0)                             interest_rate,
                     c.interest_accrual_frequency,
                     c.interest_calc_method,
                     interest_crediting_period,
                     interest_crediting_type,
                     e.crncy_id,
                     account_number,
                     c.svngs_product_id,
                     daily_minbal_for_interest,
                     mcf.get_cstacnt_avlbl_bals(b.account_id, cur_sod_date) dly_bal,
                     sec.get_usr_prsn_id(b.created_by)                      prsn_id
                   FROM mcf.mcf_accounts b INNER JOIN mcf.mcf_prdt_savings c ON (b.product_type_id = c.svngs_product_id)
                     LEFT OUTER JOIN mcf.mcf_prdt_savings_stdevnt_accntn d ON (c.svngs_product_id = d.svngs_product_id)
                     LEFT OUTER JOIN mcf.mcf_currencies e ON (c.currency_id = e.crncy_id)
                   WHERE UPPER(c.charge_interest) = 'YES' AND UPPER(b.status) = 'AUTHORIZED' AND
                         account_type IN ('Current', 'Savings', 'Susu') AND UPPER(account_status) != 'CLOSED'
                         AND mcf.get_cstacnt_avlbl_bals(b.account_id, cur_sod_date) > 0
                         AND mcf.get_cstacnt_avlbl_bals(b.account_id, cur_sod_date) > daily_minbal_for_interest
                   ORDER BY 3, 2
                   )
  LOOP

    SELECT nextval('mcf.mcf_daily_acct_bals_n_interest_daily_bal_id_seq') INTO v_daily_bal_id;
    
    --A. CREATE ACCOUNT INTEREST RECORDS
    INSERT INTO mcf.mcf_daily_acct_bals_n_interest (daily_bal_id, 
      bal_date, account_id, created_by, creation_date,
      last_update_by, last_update_date, closing_balance, interest_earned)
    VALUES (v_daily_bal_id, cur_sod_date, rowAccts.account_id, usr_id, tday_dte,
            usr_id, tday_dte, (SELECT mcf.get_cstacnt_avlbl_bals(rowAccts.account_id, cur_sod_date)),
            (SELECT mcf.xx_calc_daily_savings_interest(mcf.get_cstacnt_avlbl_bals(rowAccts.account_id, cur_sod_date),
                                                       rowAccts.interest_rate)));

     SELECT mcf.xx_calc_daily_savings_interest(mcf.get_cstacnt_avlbl_bals(rowAccts.account_id, cur_sod_date),
                                                rowAccts.interest_rate)
     INTO v_tdy_svgns_interest;                                                                                             

    --INCREASE DATE AND CHECK FOR HOLIDAYS AND WEEKENDS
    next_sod_dte := cur_sod_date;
    SELECT mcf.get_date_part('month', next_sod_dte)
    INTO v_month_cur;
    v_month_nxt := v_month_cur;

    --EXIT WHEN counter = n 
    v_dly_earned_intrst := v_tdy_svgns_interest;

    WHILE v_month_cur = v_month_nxt
    LOOP
      SELECT mcf.get_next_date(next_sod_dte, 1)
      INTO next_sod_dte;
      SELECT mcf.get_date_part('month', next_sod_dte)
      INTO v_month_nxt;

      SELECT mcf.is_date_holiday(next_sod_dte)
      INTO is_hldy;
      SELECT mcf.is_date_weekend(next_sod_dte)
      INTO is_wknd;

      IF v_month_cur = v_month_nxt
      THEN
        IF is_hldy = TRUE
        THEN

	  SELECT mcf.xx_calc_daily_savings_interest(mcf.get_cstacnt_avlbl_bals(rowAccts.account_id, next_sod_dte),
                                                        rowAccts.interest_rate) 
	  INTO v_nxt_svgns_interest;
	  
          v_dly_earned_intrst := v_dly_earned_intrst + v_nxt_svgns_interest;
          
          INSERT INTO mcf.mcf_daily_acct_bals_n_interest (
            bal_date, account_id, created_by, creation_date,
            last_update_by, last_update_date, closing_balance, interest_earned)
          VALUES (next_sod_dte, rowAccts.account_id, usr_id, tday_dte,
                  usr_id, tday_dte, mcf.get_cstacnt_avlbl_bals(rowAccts.account_id, next_sod_dte), v_nxt_svgns_interest);
        ELSE
          IF is_wknd = TRUE
          THEN

            SELECT mcf.xx_calc_daily_savings_interest(mcf.get_cstacnt_avlbl_bals(rowAccts.account_id, next_sod_dte),
                                                        rowAccts.interest_rate) 
	    INTO v_nxt_svgns_interest;
	  
            v_dly_earned_intrst := v_dly_earned_intrst + v_nxt_svgns_interest;
          
            INSERT INTO mcf.mcf_daily_acct_bals_n_interest (
              bal_date, account_id, created_by, creation_date,
              last_update_by, last_update_date, closing_balance, interest_earned)
            VALUES (next_sod_dte, rowAccts.account_id, usr_id, tday_dte,
                    usr_id, tday_dte, mcf.get_cstacnt_avlbl_bals(rowAccts.account_id, next_sod_dte), v_nxt_svgns_interest);
          ELSE
            EXIT;
          END IF;
        END IF;

      ELSE
        EXIT;
      END IF;

    END LOOP;

    --B. CHECK ACCRUAL FREQUENCY => IF 'Daily' GET ACCOUNT AND ACCRUE
    IF UPPER(rowAccts.interest_accrual_frequency) = 'DAILY'
    THEN
      SELECT mapped_lov_crncy_id :: BIGINT
      INTO cur_ID
      FROM mcf.mcf_currencies
      WHERE crncy_id = rowAccts.crncy_id;

      --DR
      tmp_crdt := 0;
      /*SELECT mcf.xx_calc_daily_savings_interest(mcf.get_cstacnt_avlbl_bals(rowAccts.account_id, cur_sod_date),
                                                rowAccts.interest_rate)
      INTO tmp_dbt;*/
      tmp_dbt :=  v_dly_earned_intrst;
      tmp_net := tmp_dbt;
      tmp_dbt_crdt := 'D';

      IF tmp_dbt > 0
      THEN
        INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                               dbt_amount, trnsctn_date,
                                               func_cur_id, created_by, creation_date, batch_id,
                                               crdt_amount,
                                               last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                               entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                               func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                               is_reconciled)
        VALUES
          ((SELECT org.get_accnt_id_brnch_eqv(rowAccts.branch_id ,(SELECT mcf.get_svngs_prdt_acct_id(rowAccts.svngs_product_id,
                                                                                              'INTEREST ACCRUAL',
                                                                                              'DR')))),
            'Interest expense for Account no ' || rowAccts.account_number,
            tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1, tday_dte, gl_btchID,
            tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                    tmp_net,
                                    cur_ID,
                                    tmp_net,
                                    cur_ID,
                                    1,
                                    1,
                                    tmp_dbt_crdt,
           '',
           '1');

        --CR
        tmp_dbt := 0;
        /*SELECT mcf.xx_calc_daily_savings_interest(mcf.get_cstacnt_avlbl_bals(rowAccts.account_id, cur_sod_date),
                                                  rowAccts.interest_rate)
        INTO tmp_crdt;*/
        
        tmp_crdt := v_dly_earned_intrst;
        tmp_net := tmp_crdt;
        tmp_dbt_crdt := 'C';

        INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc, dbt_amount, trnsctn_date,
                                               func_cur_id, created_by, creation_date, batch_id, crdt_amount,
                                               last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                               entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                               func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                               is_reconciled)
        VALUES
          ((SELECT org.get_accnt_id_brnch_eqv(rowAccts.branch_id ,(SELECT mcf.get_svngs_prdt_acct_id(rowAccts.svngs_product_id,
                                                                                          'INTEREST ACCRUAL', 'CR')))),
            'Interest accrual for Account no ' || rowAccts.account_number,
            tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1, tday_dte, gl_btchID,
            tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                    tmp_net,
                                    cur_ID,
                                    tmp_net,
                                    cur_ID,
                                    1,
                                    1,
                                    tmp_dbt_crdt,
            '',
            '1');

         UPDATE mcf.mcf_daily_acct_bals_n_interest
         SET is_interest_accrued = 'Yes' 
         WHERE account_id = rowAccts.account_id
         AND daily_bal_id >= v_daily_bal_id;

        --msgs := msgs || chr(10) || 'Interest accrual for Account no ' || rowAccts.account_number || ' is ' || tmp_crdt;
	v_ttl_intrst_accrued := v_ttl_intrst_accrued + tmp_crdt;
        cnta1 := cnta1 + 1;
      END IF;
    END IF;

  END LOOP;

  
  IF cnta1 > 0
  THEN
    msgs := 'Successfully Created ' || trim(to_char(cnta1, '99999999999999999999999999999999999')) ||
            ' Interest Transaction(s)! Total Amount is GHS'||v_ttl_intrst_accrued||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
            updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  ELSE
    --DELETE HEADER
    DELETE FROM accb.accb_trnsctn_batches
    WHERE batch_id = gl_btchID;
    msgs := 'Deleted Account GL Batch Header Successfully'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  END IF;
  
  

  --SMS ALERT FEES
  
  msgs := 'Creating SMS Alert Fee GL Batch Header Process....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

  SELECT mcf.getdb_incrmntl_datetime_ymdhms(v_trns_tm) INTO v_trns_tm;
  gl_btchID := -1;
  IF gl_btchID <= 0
  THEN
    INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date,
                                           org_id, batch_status, last_update_by, last_update_date, batch_source)
    VALUES
      ('End of Day Process - SMS Alert Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       'End of Day Process - SMS Alert Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       $1, cur_sod_date, $3, '0', $1, cur_sod_date, 'End of Day Process - SMS Alert Accounting');
    --COMMIT;
  END IF;
  SELECT COALESCE(accb.get_TodysBatch_id('End of Day Process - SMS Alert Accounting (' || cur_sod_date, $3), -1)
  INTO gl_btchID;
  msgs := 'End of Day Process - SMS Alert Accounting GL Batch ID= ' || trim(to_char(gl_btchID, '999999999999999999999999999999999999999999'));
          updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  msgs := 'End of Day Process - SMS Alert Accounting GL Batch Name= ''End of Day Process - SMS Alert Accounting (' || cur_sod_date || ')''';
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

FOR rowSMSFees IN (SELECT
   b.account_title,
   b.account_id,
   b.branch_id,
   coalesce(sms_alert_fee, 0)                             sms_alert_fee,
   e.crncy_id,
   account_number,
   c.svngs_product_id,
   mcf.get_cstacnt_avlbl_bals(b.account_id, cur_sod_date) avlbl_dly_bal,
   org.get_accnt_id_brnch_eqv(b.branch_id, c.sms_alert_revenue_id) sms_alert_revenue_id, 'C'
 FROM
   mcf.mcf_accounts b INNER JOIN mcf.mcf_prdt_savings c ON (b.product_type_id = c.svngs_product_id)
   LEFT OUTER JOIN mcf.mcf_currencies e ON (c.currency_id = e.crncy_id)
 WHERE 1 = 1
 AND   UPPER(account_status) != 'CLOSED'
	   AND sms_alert_triggers != ''
 ORDER BY 3, 2)
 LOOP
 
	BEGIN
		SELECT mcf.xx_process_sms_fee_deduction($1,cur_sod_date,$3,rowSMSFees.crncy_id, rowSMSFees.branch_id, rowSMSFees.account_id, 
		rowSMSFees.sms_alert_revenue_id, gl_btchID, rowSMSFees.sms_alert_fee) INTO v_sms_rslt_cnt;
	EXCEPTION
	WHEN OTHERS THEN
		RAISE EXCEPTION 'Error Processing SMS Fees';
	END;
	
	IF v_sms_rslt_cnt > 0 THEN
		v_sms_rec_cnt := v_sms_rec_cnt + 1;
	END IF;
 END LOOP;
 


   IF v_sms_rec_cnt > 0
  THEN
    msgs := 'Successfully Created ' || trim(to_char(v_sms_rec_cnt, '99999999999999999999999999999999999')) ||
            ' SMS Alert Fee Transaction(s)! '||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
            updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
    --RAISE NOTICE 'msgs = "%"', msgs;
  ELSE
    --DELETE HEADER
    DELETE FROM accb.accb_trnsctn_batches
    WHERE batch_id = gl_btchID;
    msgs := 'Deleted SMS Account GL Batch Header Successfully'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  END IF;


 /*FIXED DEPOSIT LIQUIDATION AND ROLLOVER*/
  cnta3 = 0;
  msgs :=  'Creating Investment Liquidations GL Batch Header Process....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

  SELECT mcf.getdb_incrmntl_datetime_ymdhms(v_trns_tm) INTO v_trns_tm;
  gl_btchID := -1;
  IF gl_btchID <= 0
  THEN
    INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date,
                                           org_id, batch_status, last_update_by, last_update_date, batch_source)
    VALUES
      ('End of Day Process - Investment Liquidation Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       'End of Day Process - Investment Liquidation Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       $1, cur_sod_date, $3, '0', $1, cur_sod_date, 'End of Day Process - Investment Liquidation Accounting');
    --COMMIT;
  END IF;
  SELECT COALESCE(accb.get_TodysBatch_id('End of Day Process - Investment Liquidation Accounting (' || cur_sod_date, $3), -1)
  INTO gl_btchID;
  msgs :=  'End of Day Process - Investment Liquidation Accounting GL Batch ID= ' ||
          trim(to_char(gl_btchID, '999999999999999999999999999999999999999999'));
          updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  msgs := 'End of Day Process - Investment Liquidation Accounting GL Batch Name= ''End of Day Process - Investment Liquidation Accounting (' ||
         cur_sod_date
         || ')''';
         updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

  /*FIXED DEPOSIT LIQUIDATION*/
  FOR rowInvstmnts IN (
		SELECT -1 lqdtn_id, a.amount, /*1*/
			mcf.invstmnt_liability_accnt_id(invstmnt_id) invstmnt_liability_accnt_id, 'D', /*3*/
			org.get_accnt_id_brnch_eqv(f.branch_id, e.interest_payment_crdt_accnt_id) customer_gl_liability_1, 'I', /*5*/
			org.get_accnt_id_brnch_eqv(f.branch_id, e.accrued_interest_dbt_accnt_id) interest_expense_account_id, 'I', /*7*/
			org.get_accnt_id_brnch_eqv(f.branch_id, e.interest_payment_crdt_accnt_id) customer_gl_liability_2, 'I', /*9*/
			coalesce(nullif(c.invstmnt_charge_fees,''),'No Fee') invstmnt_charge_fees, c.invstmnt_fees_flat, c.invstmnt_fees_percent, /*12*/
			org.get_accnt_id_brnch_eqv(f.branch_id, e.interest_payment_crdt_accnt_id) customer_gl_liability_3, 'D', /*14*/
			org.get_accnt_id_brnch_eqv(f.branch_id, e.invstmnt_fee_crdt_accnt_id) invstmnt_fee_crdt_accnt_id, 'I', /*16*/
			d.crncy_id, mcf.xx_calc_invstmnt_current_interest(invstmnt_id,orgidno) current_interest_value, /*18*/
			' for Investment No. '||a.trnsctn_no||' for Customer '||mcf.get_customer_name(a.cust_type, a.cust_id) trns_desc, /*19*/
			'Investment Liquidation', product_type, /*21*/
			f.branch_id, 
			a.trnsctn_no invstmnt_trnsctn_no,
			payback_crdt_acct_id,
			a.account_id invstmnt_account_id,
			invstmnt_id,
			mcf.get_cstacct_gl_liablty_acct_id(payback_crdt_acct_id) gl_payback_crdt_acct_id,
			shd_rollover,
			rollover_type,
			tenor, 
			tenor_type,
			a.svngs_product_id
		 FROM mcf.mcf_investments a, mcf.mcf_prdt_savings c, mcf.mcf_currencies d,
			mcf.mcf_prdt_savings_stdevnt_accntn e, mcf.mcf_accounts f 
		 WHERE 1 = 1 AND f.product_type_id = c.svngs_product_id
			AND c.currency_id = d.crncy_id AND c.svngs_product_id = e.svngs_product_id
			AND a.pymnt_dbt_acct_id = f.account_id
			AND a.status = 'Authorized' AND a.invstmnt_status = 'Running'
			AND end_date <= cur_sod_date
			AND invstmnt_id IN (115, 119)
			ORDER BY invstmnt_id)
  LOOP
	SELECT mcf.getdb_incrmntl_datetime_ymdhms(v_trns_tm) INTO v_trns_tm;
  
	SELECT nextval('mcf.mcf_investments_liquidation_lqdtn_id_seq'::regclass) INTO v_lqdtn_id;
  
    --CREATE LIQUIDATION RECORD
	SELECT mcf.create_investment_lqdtn(v_lqdtn_id, rowInvstmnts.invstmnt_id, -1, 
		cur_sod_date, 'Maturity Liquidation', rowInvstmnts.branch_id, tday_dte, $1, $3, v_trns_tm) INTO v_insrt_lqdtn_rslt;
		
	SELECT lqdtn_trnsctn_no INTO v_lqdtn_trnsctn_no FROM mcf.mcf_investments_liquidation WHERE lqdtn_id = v_lqdtn_id;

    SELECT mapped_lov_crncy_id :: BIGINT
    INTO cur_ID
    FROM mcf.mcf_currencies
    WHERE crncy_id = rowInvstmnts.crncy_id;

	
      --CREATE ACCOUNTING FOR PRINCIAL DEBIT INVESTMENT_LIABILITY AND CREDIT_CUSTOMER_LIABILITY_ACCOUNT 
	  tmp_crdt := 0;
	  tmp_dbt := rowInvstmnts.amount;
	  tmp_net := tmp_dbt;
	  tmp_dbt_crdt := 'D';

	IF tmp_dbt != 0  
	THEN
      INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                             dbt_amount, trnsctn_date,
                                             func_cur_id, created_by, creation_date, batch_id,
                                             crdt_amount,
                                             last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                             entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                             func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                             is_reconciled)
      VALUES
        (rowInvstmnts.invstmnt_liability_accnt_id, 'Investment Liquiditation ' || v_lqdtn_trnsctn_no ||rowInvstmnts.trns_desc|| ' - Investment Amount',
                                       tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
                                       tday_dte,
                                       gl_btchID,
                                       tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                               tmp_net,
                                                               cur_ID,
                                                               tmp_net,
                                                               cur_ID,
                                                               1,
                                                               1,
                                                               tmp_dbt_crdt,
         '',
         '1');


      tmp_crdt := rowInvstmnts.amount;
      tmp_dbt :=0;
      tmp_net := tmp_crdt;
      tmp_dbt_crdt := 'C';

      INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                             dbt_amount, trnsctn_date,
                                             func_cur_id, created_by, creation_date, batch_id,
                                             crdt_amount,
                                             last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                             entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                             func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                             is_reconciled)
      VALUES
        (rowInvstmnts.customer_gl_liability_1, 'Investment Liquiditation ' || v_lqdtn_trnsctn_no ||rowInvstmnts.trns_desc|| ' - Investment Amount',
                                         tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
                                         tday_dte,
                                         gl_btchID,
                                         tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                                 tmp_net,
                                                                 cur_ID,
                                                                 tmp_net,
                                                                 cur_ID,
                                                                 1,
                                                                 1,
                                                                 tmp_dbt_crdt,
         '',
         '1');
	  
    END IF;
	
	--CREATE ACCOUNTING INTEREST EXPENSE
	tmp_crdt := 0;
	tmp_dbt := rowInvstmnts.current_interest_value;
	tmp_net := tmp_dbt;
	tmp_dbt_crdt := 'D';

	IF tmp_dbt != 0  
	THEN
      INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                             dbt_amount, trnsctn_date,
                                             func_cur_id, created_by, creation_date, batch_id,
                                             crdt_amount,
                                             last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                             entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                             func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                             is_reconciled)
      VALUES
        (rowInvstmnts.interest_expense_account_id, 'Investment Liquiditation ' || v_lqdtn_trnsctn_no ||rowInvstmnts.trns_desc|| ' - Interest Earned',
                                       tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
                                       tday_dte,
                                       gl_btchID,
                                       tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                               tmp_net,
                                                               cur_ID,
                                                               tmp_net,
                                                               cur_ID,
                                                               1,
                                                               1,
                                                               tmp_dbt_crdt,
         '',
         '1');


      tmp_crdt := rowInvstmnts.current_interest_value;
      tmp_dbt :=0;
      tmp_net := tmp_crdt;
      tmp_dbt_crdt := 'C';

      INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                             dbt_amount, trnsctn_date,
                                             func_cur_id, created_by, creation_date, batch_id,
                                             crdt_amount,
                                             last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                             entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                             func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                             is_reconciled)
      VALUES
        (rowInvstmnts.customer_gl_liability_1, 'Investment Liquiditation ' || v_lqdtn_trnsctn_no ||rowInvstmnts.trns_desc|| ' - Interest Earned',
                                         tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
                                         tday_dte,
                                         gl_btchID,
                                         tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                                 tmp_net,
                                                                 cur_ID,
                                                                 tmp_net,
                                                                 cur_ID,
                                                                 1,
                                                                 1,
                                                                 tmp_dbt_crdt,
         '',
         '1');
	  
    END IF;
	
	
	
	
	
      --CREATE CUSTOMER ACCOUNT document RECORD
      SELECT
        b.account_id,
        b.status,
        b.account_title,
        mcf.get_cstacnt_lien_bals(b.account_id, cur_sod_date),
        b.mandate,
        e.withdrawal_limit_no,
        e.withdrawal_limit_amount,
        e.withdrawal_limit,
        b.account_number
      INTO ai_account_id, ai_status, ai_account_title, ai_lien_bal, ai_mandate, ai_limit_no, ai_limit_amnt, ai_withdrawal_limit,
        ai_account_number
      FROM mcf.mcf_accounts b
        LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
        LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
      WHERE ((b.account_id = rowInvstmnts.payback_crdt_acct_id));

	 --CREDIT CUSTOMER ACCOUNT => Increase
	 PERFORM mcf.createAccountTrns(rowInvstmnts.payback_crdt_acct_id, tday_dte, 'Paperless',
	      'DEP-' || v_trns_tm,
	      'Investment Liquiditation ' || v_lqdtn_trnsctn_no ||' for Investment No. '||rowInvstmnts.invstmnt_trnsctn_no, 'CR', (rowInvstmnts.amount + rowInvstmnts.current_interest_value),
	      'DEPOSIT',
	      (rowInvstmnts.amount + rowInvstmnts.current_interest_value), 'Self', '', '', '', '', '',
	      'DEP-' || v_trns_tm,
	      'Received', -1, '', '', rowInvstmnts.crncy_id, 1, ai_status, ai_account_title,
	      ai_lien_bal, ai_mandate,
	      ai_limit_no, ai_limit_amnt, ai_withdrawal_limit, '0', -1, -1, rowInvstmnts.branch_id,
	      $3, $1, cur_sod_date);
									  
	 --DEBIT INVESTMENT LIABILITY ACCOUNT -> Decrease
	 PERFORM mcf.createAccountTrns(rowInvstmnts.invstmnt_account_id, tday_dte, 'Paperless',
	      'WTH-' || v_trns_tm,
	      'Investment Liquiditation ' || v_lqdtn_trnsctn_no ||' for Investment No. '||rowInvstmnts.invstmnt_trnsctn_no, 'DR', rowInvstmnts.amount,
	      'WITHDRAWAL',
	      rowInvstmnts.amount, 'Self', '', '', '', '', '',
	      'WTH-' || v_trns_tm,
	      'Paid', -1, '', '', rowInvstmnts.crncy_id, 1, ai_status, ai_account_title,
	      ai_lien_bal, ai_mandate,
	      ai_limit_no, ai_limit_amnt, ai_withdrawal_limit, '0', -1, -1, rowInvstmnts.branch_id,
	      $3, $1, cur_sod_date);

      --CREATE DAILY BALANCE RECORD
      BEGIN
	    --update customer account balance
		PERFORM mcf.update_cstmracnt_balances_ovdrft(rowInvstmnts.payback_crdt_acct_id, (rowInvstmnts.amount + rowInvstmnts.current_interest_value),
		       0.00, 0.00, '',
		       cur_sod_date, 'I', 'DEP-', '', $1, tday_dte);
		
		--update investment account balance
		PERFORM mcf.update_cstmracnt_balances_ovdrft(rowInvstmnts.invstmnt_account_id, rowInvstmnts.amount,
		       0.00, 0.00, '',
		       cur_sod_date, 'D', 'WTH-', '', $1, tday_dte);
	  
        EXCEPTION
        WHEN OTHERS
          THEN
            RETURN 'FAILURE' || chr(10) || SQLSTATE || chr(10) || SQLERRM;
      END;
	  
	  
	  --ACCOUNT FOR FEES
	  IF rowInvstmnts.invstmnt_charge_fees = 'Liquidating'
	  THEN
			
		IF rowInvstmnts.invstmnt_fees_flat > 0 AND rowInvstmnts.invstmnt_fees_percent > 0 THEN
			v_ttl_fees := rowInvstmnts.invstmnt_fees_flat + (rowInvstmnts.invstmnt_fees_percent/100 * rowInvstmnts.current_interest_value);
		ELSIF rowInvstmnts.invstmnt_fees_flat > 0 THEN
			v_ttl_fees := rowInvstmnts.invstmnt_fees_flat;
		ELSIF rowInvstmnts.invstmnt_fees_percent > 0 THEN
			v_ttl_fees := (rowInvstmnts.invstmnt_fees_percent/100 * rowInvstmnts.current_interest_value);
		END IF;

		IF v_ttl_fees > 0
		THEN
			v_ttl_fees := round(v_ttl_fees,2);
			
			--CREATE ACCOUNTING INTEREST EXPENSE
			tmp_crdt := 0;
			tmp_dbt := v_ttl_fees;
			tmp_net := tmp_dbt;
			tmp_dbt_crdt := 'D';

			IF tmp_dbt != 0  
			THEN
			  INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
					 dbt_amount, trnsctn_date,
					 func_cur_id, created_by, creation_date, batch_id,
					 crdt_amount,
					 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
					 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
					 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
					 is_reconciled)
			  VALUES
				(rowInvstmnts.customer_gl_liability_1, 'Investment Liquiditation ' || v_lqdtn_trnsctn_no ||rowInvstmnts.trns_desc|| ' - Fee Revenue',
				   tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
				   tday_dte,
				   gl_btchID,
				   tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
										   tmp_net,
										   cur_ID,
										   tmp_net,
										   cur_ID,
										   1,
										   1,
										   tmp_dbt_crdt,
				 '',
				 '1');


			  tmp_crdt := v_ttl_fees;
			  tmp_dbt :=0;
			  tmp_net := tmp_crdt;
			  tmp_dbt_crdt := 'C';

			  INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
					 dbt_amount, trnsctn_date,
					 func_cur_id, created_by, creation_date, batch_id,
					 crdt_amount,
					 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
					 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
					 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
					 is_reconciled)
			  VALUES
				(rowInvstmnts.invstmnt_fee_crdt_accnt_id, 'Investment Liquiditation ' || v_lqdtn_trnsctn_no ||rowInvstmnts.trns_desc|| ' - Fee Revenue',
					 tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
					 tday_dte,
					 gl_btchID,
					 tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
											 tmp_net,
											 cur_ID,
											 tmp_net,
											 cur_ID,
											 1,
											 1,
											 tmp_dbt_crdt,
				 '',
				 '1');
			  
			END IF;
			
			
			PERFORM mcf.createAccountTrns(rowInvstmnts.payback_crdt_acct_id, tday_dte, 'Paperless',
			      'FT-WTH-' || v_trns_tm,
			      'Funds Tranfer - Investment Liquiditation ' || v_lqdtn_trnsctn_no ||' for Investment No. '||rowInvstmnts.invstmnt_trnsctn_no, 'DR', v_ttl_fees,
			      'WITHDRAWAL',
			      v_ttl_fees, 'Self', '', '', '', '', '',
			      'FT-WTH-' || v_trns_tm,
			      'Paid', -1, '', '', rowInvstmnts.crncy_id, 1, ai_status, ai_account_title,
			      ai_lien_bal, ai_mandate,
			      ai_limit_no, ai_limit_amnt, ai_withdrawal_limit, '0', -1, -1, rowInvstmnts.branch_id,
			      $3, $1, cur_sod_date);

			  --CREATE DAILY BALANCE RECORD
			  BEGIN
				PERFORM mcf.update_cstmracnt_balances_ovdrft(rowInvstmnts.payback_crdt_acct_id, v_ttl_fees,
					   0.00, 0.00, '', cur_sod_date, 'D', 'FT-WTH-', '', $1, tday_dte);
			  
				EXCEPTION
				WHEN OTHERS
				  THEN
					RETURN 'FAILURE' || chr(10) || SQLSTATE || chr(10) || SQLERRM;
			  END;
			
		
		END IF;

	  END IF;
	  
	  --UPDATE 
	  BEGIN
	  
		UPDATE mcf.mcf_investments_liquidation SET status = 'Authorized', lqdtn_invstmnt_status = 'Processed',
		authorized_by_person_id = -1, autorization_date = tday_dte 
		WHERE lqdtn_id = v_lqdtn_id;
		
		UPDATE mcf.mcf_investments SET status = 'Authorized', invstmnt_status = 'Matured', 
		running_interest_bal = rowInvstmnts.current_interest_value 
		WHERE invstmnt_id = rowInvstmnts.invstmnt_id;

	  EXCEPTION
	  WHEN OTHERS THEN
		msgs := SQLSTATE || chr(10) || SQLERRM;
		
		updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
		RETURN msgs;
	  END;
	  
	  
	  --ROLL OVER
	  IF rowInvstmnts.shd_rollover = 'Yes'
	  THEN
	  
		IF rowInvstmnts.rollover_type = 'Principal Only'
		THEN
			v_rlovr_amnt := rowInvstmnts.amount;
		ELSE
			v_rlovr_amnt :=  rowInvstmnts.amount + rowInvstmnts.current_interest_value;
		END IF;
		
		v_rlovr_tenor_in_days := rowInvstmnts.tenor;
		
		IF 	rowInvstmnts.tenor_type = 'Year' THEN
			v_rlovr_tenor_in_days := rowInvstmnts.tenor * 364;
		END IF;
		
	    --GET PRODUCT CURRENT INTEREST RATE
		SELECT interest_rate INTO  v_rlovr_interest_rate FROM mcf.mcf_prdt_savings a WHERE svngs_product_id = rowInvstmnts.svngs_product_id;	
		
		--GET NEW MATURITY DATE
		SELECT mcf.get_invstmnt_maturity_date_ymd(cur_sod_date, v_rlovr_tenor_in_days) INTO v_rlovr_maturity_dte;
		
		--GET MATURITY VALUE
		SELECT mcf.compute_invstmnt_maturity_amnt(v_rlovr_amnt, v_rlovr_interest_rate, v_rlovr_tenor_in_days) INTO v_rlovr_maturity_val;
		
		--GET NEW INVESTMENT ID
		SELECT nextval('mcf.mcf_investments_invstmnt_id_seq'::regclass) INTO v_rlovr_invstmnt_id;
		
		--GET TRNS CODE FOR USER
		SELECT code_for_trns_nums INTO v_usr_trns_code FROM sec.sec_users WHERE user_id =  $1;

		--GET INVESTMENT ACCOUNT ID
		SELECT account_id INTO v_rlovr_invstmnt_acctid FROM mcf.mcf_investments WHERE invstmnt_id = rowInvstmnts.invstmnt_id;

		--INSERT INVESTMENT RECORD
		BEGIN
			INSERT INTO mcf.mcf_investments(invstmnt_id,
				svngs_product_id, amount, tenor, tenor_type, shd_rollover,
				rollover_type, ifo_name, ifo_contact, interest_rate,
				discount_rate, rate_type, pay_back_method, running_interest_bal, payback_crdt_acct_id,
				status, trnsctn_no, application_date, branch_id, pymnt_method, cash_chq_pymnt_acct_trns_id, pymnt_dbt_acct_id,
				cust_type, cust_id, invstmnt_officer_id, invstmnt_type, start_date, end_date, maturity_value, payback_chq_no,
				created_by, creation_date, last_update_by, last_update_date, account_id)
			SELECT v_rlovr_invstmnt_id, svngs_product_id, v_rlovr_amnt, tenor, tenor_type, shd_rollover,
				rollover_type, ifo_name, ifo_contact, v_rlovr_interest_rate,
				discount_rate, rate_type, pay_back_method, 0.00, payback_crdt_acct_id,
				'Incomplete', 'IV-FD-'||v_usr_trns_code||'-'||v_trns_tm, tday_dte, branch_id, pymnt_method, cash_chq_pymnt_acct_trns_id, pymnt_dbt_acct_id,
				cust_type, cust_id, invstmnt_officer_id, invstmnt_type, cur_sod_date, v_rlovr_maturity_dte, v_rlovr_maturity_val, payback_chq_no,
				$1, tday_dte, $1, tday_dte, v_rlovr_invstmnt_acctid FROM mcf.mcf_investments WHERE invstmnt_id = rowInvstmnts.invstmnt_id;
				
		EXCEPTION
		WHEN OTHERS THEN
			msgs := SQLSTATE || chr(10) || SQLERRM;
		
			updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
			RETURN msgs;
		END;
		
		
		--PROCESS INVESTMENTS
		BEGIN
			SELECT mcf.xx_process_fxdeposit_invstmnt($1, cur_sod_date, $3, 0, v_rlovr_invstmnt_id) INTO v_rlovr_prcss_rslt;
		EXCEPTION
		WHEN OTHERS THEN
			msgs := SQLSTATE || chr(10) || SQLERRM;
			
			updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
			RETURN msgs;
		END;

		--UPDATE INVESTMENT RECORD
		  BEGIN
			UPDATE mcf.mcf_investments SET status = 'Authorized', invstmnt_status = 'Running'
			WHERE invstmnt_id = v_rlovr_invstmnt_id;
		  EXCEPTION
		  WHEN OTHERS THEN
			msgs := SQLSTATE || chr(10) || SQLERRM;
			
			updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
			RETURN msgs;
		  END;
	  
	  END IF;
			
	  
	  cnta3 := cnta3 + 1;
  END LOOP;

  
  IF cnta3 > 0
  THEN
    msgs :=  'Successfully Created ' || trim(to_char(cnta3, '99999999999999999999999999999999999')) ||
            ' Investment Liquidation Accounting Transaction(s)!'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
            updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  ELSE
    --DELETE HEADER
    DELETE FROM accb.accb_trnsctn_batches
    WHERE batch_id = gl_btchID;
    msgs := 'Deleted Investment Liquidation Accounting GL Batch Header Successfully'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  END IF;	
  

  --LOANS
  --2. DEBIT PRINCIPAL AND/INTEREST FOR ALL RUNNING LOANS WHERE SCHEDULE DATE IS DUE
  
  msgs :=  'Creating Loan Deductions GL Batch Header Process....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

  SELECT mcf.getdb_incrmntl_datetime_ymdhms(v_trns_tm) INTO v_trns_tm;
  gl_btchID := -1;
  IF gl_btchID <= 0
  THEN
    INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date,
                                           org_id, batch_status, last_update_by, last_update_date, batch_source)
    VALUES
      ('End of Day Process - Loan Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       'End of Day Process - Loan Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       $1, cur_sod_date, $3, '0', $1, cur_sod_date, 'End of Day Process - Loan Accounting');
    --COMMIT;
  END IF;
  SELECT COALESCE(accb.get_TodysBatch_id('End of Day Process - Loan Accounting (' || cur_sod_date, $3), -1)
  INTO gl_btchID;
  msgs :=  'End of Day Process - Loan Accounting GL Batch ID= ' ||
          trim(to_char(gl_btchID, '999999999999999999999999999999999999999999'));
          updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  msgs := 'End of Day Process - Loan Accounting GL Batch Name= ''End of Day Process - Loan Accounting (' ||
  cur_sod_date || ')''';
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);


FOR rowLoans IN (SELECT tbl1.* FROM (SELECT
                     a.loan_rqst_id,
                     disbmnt_det_id,
                     a.branch_id,
                     CASE WHEN a.cust_type = 'Group'
                       THEN mcf.get_customer_name('Individual', a.cust_id)
                     ELSE mcf.get_customer_name(a.cust_type, a.cust_id) END                 customer,
                     a.cust_type,
                     a.trnsctn_id,
                     to_char(to_timestamp(c.repay_start_date, 'YYYY-MM-DD'), 'DD-Mon-YYYY') repay_start_date,
                     to_char(to_timestamp(c.repay_end_date, 'YYYY-MM-DD'), 'DD-Mon-YYYY')   repay_end_date,
                     crdt_type,
                     org.get_accnt_id_brnch_eqv(a.branch_id, principal_rcvbl_acct_id) principal_rcvbl_acct_id,
                     org.get_accnt_id_brnch_eqv(a.branch_id, interest_rcvbl_acct_id) interest_rcvbl_acct_id,
                     org.get_accnt_id_brnch_eqv(a.branch_id, deferred_interest_acct_id) deferred_interest_acct_id,
                     org.get_accnt_id_brnch_eqv(a.branch_id, interest_revenue_acct_id) interest_revenue_acct_id,
                     currency_id,
                     repayment_type,
                     repayment_account_id,
                     b.loan_product_id,
                     account_id                                                             loan_account_id,
                     a.is_disbursed,
                     sec.get_usr_prsn_id(d.created_by)                                      prsn_id,
                     COALESCE(a.cash_collateral_id,-1) cash_collateral_id
                   FROM mcf.mcf_loan_request a, mcf.mcf_prdt_loans b, mcf.mcf_loan_disbursement_det c,
                     mcf.mcf_loan_disbursement_hdr d
                   WHERE a.loan_product_id = b.loan_product_id AND c.loan_rqst_id = a.loan_rqst_id AND
                         c.disbmnt_hdr_id = d.disbmnt_hdr_id
                         AND c.ttl_tenor_bal > 0 AND repayment_type = 'Account Deductions' AND is_disbursed = 'YES' AND
                         crdt_type = 'Loan' AND b.charge_interest = 'YES'
                         AND a.status = 'Approved' AND d.status = 'Disbursed' AND c.principal_amount > 0
                         AND upper(b.is_staff_loan_product) = 'NO' 
                   ORDER BY crdt_type, trnsctn_id, a.branch_id)tbl1 /*LIMIT 5*/)
  LOOP
    lv_interest_amnt := 0.00;
    lv_principal_amnt := 0.00;
    lv_ttl_lnoutsndn_bal := 0.00;
    lv_bal_cnt := 0;
    avlbl_acct_bal := 0.00;
  
    SELECT mcf.getdb_incrmntl_datetime_ymdhms(v_trns_tm) INTO v_trns_tm;

    SELECT account_number INTO dst_loan_account_no FROM mcf.mcf_accounts WHERE account_id = rowLoans.repayment_account_id LIMIT 1;
  
    SELECT mcf.get_cstacnt_avlbl_bals(rowLoans.repayment_account_id, cur_sod_date)
    INTO avlbl_acct_bal;

    SELECT mapped_lov_crncy_id :: BIGINT
    INTO cur_ID
    FROM mcf.mcf_currencies
    WHERE crncy_id = rowLoans.currency_id;

    --lv_interest_amnt := 0.00;
    --lv_principal_amnt := 0.00;

	--RAISE NOTICE 'lv_schedule_id = "%"', lv_schedule_id;

	--GET TOTAL LOAN OUTSTANDING BALANCE
	SELECT COUNT(*) INTO lv_bal_cnt
		 FROM mcf.mcf_loan_schedule a
		 WHERE a.disbmnt_det_id = rowLoans.disbmnt_det_id
		 AND upper(is_paid) IN ('NO', 'PARTIAL')
		 AND to_timestamp(repay_date,'YYYY-MM-DD') <= to_timestamp(cur_sod_date,'YYYY-MM-DD');

	IF lv_bal_cnt > 0 THEN
	       SELECT SUM(COALESCE(((a.interest_amnt - a.interest_amnt_paid) +  (a.principal_amnt - principal_amnt_paid)),0)) INTO lv_ttl_lnoutsndn_bal
			 FROM mcf.mcf_loan_schedule a
			 WHERE a.disbmnt_det_id = rowLoans.disbmnt_det_id
			 AND upper(is_paid) IN ('NO', 'PARTIAL')
			 AND to_timestamp(repay_date,'YYYY-MM-DD') <= to_timestamp(cur_sod_date,'YYYY-MM-DD');
	END IF;


	IF lv_ttl_lnoutsndn_bal > avlbl_acct_bal THEN
	 --MOVE FUNDS FROM CANDIDATE ACCOUNTS
	 v_net_supaccnt_trnsf = lv_ttl_lnoutsndn_bal - avlbl_acct_bal;

	 v_ttl_fnds_trnsf := 0.00;

	 FOR rowSupLoanAccnts IN (SELECT DISTINCT x.account_id, mcf.get_cstacnt_avlbl_bals(x.account_id, cur_sod_date) supacct_bal, y.account_number
				  FROM mcf.mcf_repayment_suplmntry_accounts x, mcf.mcf_accounts y WHERE x.account_id = y.account_id AND loan_rqst_id = rowLoans.loan_rqst_id
				  AND UPPER(x.is_enabled) = 'YES')
	 LOOP
		--NEW
		SELECT
		  b.account_id,
		  b.status,
		  b.account_title,
		  mcf.get_cstacnt_lien_bals(b.account_id, cur_sod_date),
		  b.mandate,
		  e.withdrawal_limit_no,
		  e.withdrawal_limit_amount,
		  e.withdrawal_limit,
		  b.account_number
		INTO ai_account_id, ai_status, ai_account_title, ai_lien_bal, ai_mandate, ai_limit_no, ai_limit_amnt, ai_withdrawal_limit,
		  ai_account_number
		FROM mcf.mcf_accounts b
		  LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
		  LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
		WHERE ((b.account_id = rowSupLoanAccnts.account_id));
						       
		IF rowSupLoanAccnts.supacct_bal > 0 THEN
			IF v_net_supaccnt_trnsf >= 0.01 THEN
				IF v_net_supaccnt_trnsf <= rowSupLoanAccnts.supacct_bal THEN
					--TRANSFER v_net_supaccnt_trnsf and exit
					PERFORM mcf.createAccountTrns(rowSupLoanAccnts.account_id, tday_dte, 'Paperless',
						      'FT-WTH-' || v_trns_tm,
						      'Funds Tranfer to Account No. '||dst_loan_account_no||' - Automatic Loan Repayment(COB) for Loan Request '||rowLoans.trnsctn_id, 'DR', round(v_net_supaccnt_trnsf,2),
						      'WITHDRAWAL',
						      round(v_net_supaccnt_trnsf,2), 'Self', '', '', '', '', '',
						      'FT-WTH-' || v_trns_tm,
						      'Paid', -1, '', '', rowLoans.currency_id, 1, ai_status, ai_account_title,
						      ai_lien_bal, ai_mandate,
						      ai_limit_no, ai_limit_amnt, ai_withdrawal_limit, '0', -1, -1, rowLoans.branch_id,
						      $3, $1, cur_sod_date);                   

					--CREATE CUSTOMER ACCOUNT BALANCE		
					PERFORM mcf.update_cstmracnt_balances_ovdrft(rowSupLoanAccnts.account_id, round(v_net_supaccnt_trnsf,2),
							0.00, 0.00, '', cur_sod_date, 'D', 'FT-WTH', '', $1, tday_dte);	

					--DEPOSIT INTO REPAYMENT ACCOUNT
					--CREDIT CUSTOMER ACCOUNT => Increase
					 PERFORM mcf.createAccountTrns(rowLoans.repayment_account_id, tday_dte, 'Paperless',
						      'DEP-' || v_trns_tm,
						      'Funds Tranfer from Account No. '||rowSupLoanAccnts.account_number||' - Automatic Loan Repayment(COB) for Loan Request '||rowLoans.trnsctn_id, 'CR', round(v_net_supaccnt_trnsf,2),
						      'DEPOSIT',
						      round(v_net_supaccnt_trnsf,2), 'Self', '', '', '', '', '',
						      'DEP-' || v_trns_tm,
						      'Received', -1, '', '', rowLoans.currency_id, 1, ai_status, ai_account_title,
						      ai_lien_bal, ai_mandate,
						      ai_limit_no, ai_limit_amnt, ai_withdrawal_limit, '0', -1, -1, rowLoans.branch_id,
						      $3, $1, cur_sod_date);

					PERFORM mcf.update_cstmracnt_balances_ovdrft(rowLoans.repayment_account_id, round(v_net_supaccnt_trnsf,2),
						       0.00, 0.00, '', cur_sod_date, 'I', 'DEP-', '', $1, tday_dte);
									

					v_ttl_fnds_trnsf  := v_ttl_fnds_trnsf + round(v_net_supaccnt_trnsf,2);			
					EXIT;
				ELSIF v_net_supaccnt_trnsf > rowSupLoanAccnts.supacct_bal  THEN
					--TRANSFER rowSupLoanAccnts.supacct_bal
					PERFORM mcf.createAccountTrns(rowSupLoanAccnts.account_id, tday_dte, 'Paperless',
						      'FT-WTH-' || v_trns_tm,
						      'Funds Tranfer to Account No. '||dst_loan_account_no||' - Automatic Loan Repayment(COB) for Loan Request '||rowLoans.trnsctn_id, 'DR', round(rowSupLoanAccnts.supacct_bal,2),
						      'WITHDRAWAL',
						      round(rowSupLoanAccnts.supacct_bal,2), 'Self', '', '', '', '', '',
						      'FT-WTH-' || v_trns_tm,
						      'Paid', -1, '', '', rowLoans.currency_id, 1, ai_status, ai_account_title,
						      ai_lien_bal, ai_mandate,
						      ai_limit_no, ai_limit_amnt, ai_withdrawal_limit, '0', -1, -1, rowLoans.branch_id,
						      $3, $1, cur_sod_date);                   

					--CREATE CUSTOMER ACCOUNT BALANCE		
					PERFORM mcf.update_cstmracnt_balances_ovdrft(rowSupLoanAccnts.account_id, round(rowSupLoanAccnts.supacct_bal,2),
							0.00, 0.00, '', cur_sod_date, 'D', 'FT-WTH', '', $1, tday_dte);


					--DEPOSIT INTO REPAYMENT ACCOUNT
					--CREDIT CUSTOMER ACCOUNT => Increase
					 PERFORM mcf.createAccountTrns(rowLoans.repayment_account_id, tday_dte, 'Paperless',
						      'DEP-' || v_trns_tm,
						      'Funds Tranfer from Account No. '||rowSupLoanAccnts.account_number||' - Automatic Loan Repayment(COB) for Loan Request '||rowLoans.trnsctn_id, 'CR', round(rowSupLoanAccnts.supacct_bal,2),
						      'DEPOSIT',
						      round(rowSupLoanAccnts.supacct_bal,2), 'Self', '', '', '', '', '',
						      'DEP-' || v_trns_tm,
						      'Received', -1, '', '', rowLoans.currency_id, 1, ai_status, ai_account_title,
						      ai_lien_bal, ai_mandate,
						      ai_limit_no, ai_limit_amnt, ai_withdrawal_limit, '0', -1, -1, rowLoans.branch_id,
						      $3, $1, cur_sod_date);

					PERFORM mcf.update_cstmracnt_balances_ovdrft(rowLoans.repayment_account_id, round(rowSupLoanAccnts.supacct_bal,2),
						       0.00, 0.00, '', cur_sod_date, 'I', 'DEP-', '', $1, tday_dte);
							
					v_net_supaccnt_trnsf := v_net_supaccnt_trnsf - rowSupLoanAccnts.supacct_bal;
					
					v_ttl_fnds_trnsf  := v_ttl_fnds_trnsf + round(rowSupLoanAccnts.supacct_bal,2);
				END IF;
			END IF;
		END IF;	

	 END LOOP;
	 
	END IF;

	
    IF (avlbl_acct_bal + v_ttl_fnds_trnsf) > 0
    THEN      

	cnta2 := cnta2 + 1;
	rng_avlbl_acct_bal := 0.00;
      
      rng_avlbl_acct_bal := (avlbl_acct_bal + v_ttl_fnds_trnsf);
      FOR rwOtsdnShdl IN (SELECT
			x.schedule_id lv_schedule_id,
			x.repay_date lv_repay_date,
			x.intamt lv_interest_amnt,
			x.pnpamt lv_principal_amnt,
			x.is_paid lv_is_paid,
			x.interest_amnt_paid lv_interest_amnt_paid,
			x.principal_amnt_paid lv_principal_amnt_paid
		      FROM
			(SELECT DISTINCT
			   a.schedule_id,
			   a.repay_date,
			   (a.interest_amnt - a.interest_amnt_paid) intamt,
			   (a.principal_amnt - principal_amnt_paid) pnpamt,
			   a.is_paid,
			   a.interest_amnt_paid,
			   a.principal_amnt_paid
			 FROM mcf.mcf_loan_schedule a
			 WHERE a.disbmnt_det_id = rowLoans.disbmnt_det_id
			       AND upper(is_paid) IN ('NO', 'PARTIAL')
			       AND to_timestamp(repay_date,'YYYY-MM-DD') <= to_timestamp(cur_sod_date,'YYYY-MM-DD')
			 ORDER BY repay_date ASC) x)
      LOOP
		IF rng_avlbl_acct_bal > 0 THEN
			IF rng_avlbl_acct_bal >= (rwOtsdnShdl.lv_interest_amnt + rwOtsdnShdl.lv_principal_amnt)
			THEN
			  v_is_paid := 'YES';

			  UPDATE mcf.mcf_loan_schedule
			  SET interest_amnt_paid = (interest_amnt_paid + rwOtsdnShdl.lv_interest_amnt),
				principal_amnt_paid  = (principal_amnt_paid + rwOtsdnShdl.lv_principal_amnt), 
				is_paid = v_is_paid, actual_repay_date = cur_sod_date,
				last_update_by       = $1,
				last_update_date     = tday_dte
			  WHERE schedule_id = rwOtsdnShdl.lv_schedule_id;

			  lv_principal_amnt := lv_principal_amnt + rwOtsdnShdl.lv_principal_amnt;
			  lv_interest_amnt := lv_interest_amnt + rwOtsdnShdl.lv_interest_amnt;

			  rng_avlbl_acct_bal := rng_avlbl_acct_bal - (rwOtsdnShdl.lv_interest_amnt + rwOtsdnShdl.lv_principal_amnt);
			ELSIF rng_avlbl_acct_bal < (rwOtsdnShdl.lv_interest_amnt + rwOtsdnShdl.lv_principal_amnt)		
			  THEN		    
				v_is_paid := 'PARTIAL';
				IF rng_avlbl_acct_bal <= rwOtsdnShdl.lv_interest_amnt
				THEN
				  lv_principal_amnt := 0;

				  UPDATE mcf.mcf_loan_schedule
				  SET interest_amnt_paid = (interest_amnt_paid + rng_avlbl_acct_bal), 
				is_paid = v_is_paid, actual_repay_date = cur_sod_date,
				last_update_by       = $1,
				last_update_date     = tday_dte
				  WHERE schedule_id = rwOtsdnShdl.lv_schedule_id;

				  lv_interest_amnt := lv_interest_amnt + rng_avlbl_acct_bal;
				  
				  rng_avlbl_acct_bal := 0;
				ELSIF rng_avlbl_acct_bal > rwOtsdnShdl.lv_interest_amnt
				  THEN
				rng_avlbl_acct_bal :=  rng_avlbl_acct_bal - rwOtsdnShdl.lv_interest_amnt;

				UPDATE mcf.mcf_loan_schedule
				SET interest_amnt_paid = (interest_amnt_paid + rwOtsdnShdl.lv_interest_amnt),
				  principal_amnt_paid  = (principal_amnt_paid + rng_avlbl_acct_bal), 
				  is_paid = v_is_paid, actual_repay_date = cur_sod_date,
				  last_update_by       = $1,
				  last_update_date     = tday_dte
				WHERE schedule_id = rwOtsdnShdl.lv_schedule_id;

				lv_principal_amnt := lv_principal_amnt + rng_avlbl_acct_bal;
					lv_interest_amnt := lv_interest_amnt + rwOtsdnShdl.lv_interest_amnt;
			  
				rng_avlbl_acct_bal := 0;
				END IF;

				
			END IF;
		END IF;
      END LOOP;

      IF 1 > 0 
      THEN
        SELECT mcf.calc_loan_ttl_bal(rowLoans.loan_rqst_id :: INTEGER, 'PRINCIPAL OUTSTANDING') :: NUMERIC
        INTO v_loan_prncpl_bal;
        SELECT mcf.calc_loan_ttl_bal(rowLoans.loan_rqst_id :: INTEGER, 'INTEREST OUTSTANDING') :: NUMERIC
        INTO v_loan_intrst_bal;
        SELECT mcf.calc_loan_ttl_bal(rowLoans.loan_rqst_id :: INTEGER, 'TENURE OUTSTANDING') :: NUMERIC
        INTO v_loan_tenure_bal;


        UPDATE mcf.mcf_loan_disbursement_det
        SET principal_amount_bal = v_loan_prncpl_bal,
          ttl_interest_bal       = v_loan_intrst_bal,
          ttl_tenor_bal          = v_loan_tenure_bal,
          last_update_by         = $1, last_update_date = tday_dte
        WHERE disbmnt_det_id = rowLoans.disbmnt_det_id;

        --msgs := msgs || chr(10) || 'STEP= '||v_loan_prncpl_bal;

        --CREATE ACCOUNTING
        SELECT mcf.xx_create_automatic_loanrepay_accntn($1, cur_sod_date, $3, $4, lv_principal_amnt, lv_interest_amnt,
                                                        rowLoans.principal_rcvbl_acct_id,
                                                        rowLoans.interest_rcvbl_acct_id,
                                                        rowLoans.deferred_interest_acct_id,
                                                        rowLoans.interest_revenue_acct_id,
                                                        gl_btchID, rowLoans.trnsctn_id, rowLoans.currency_id,
                                                        rowLoans.repayment_account_id, tday_dte)
        INTO msgs1;

        --NEW
        SELECT
          b.account_id,
          b.status,
          b.account_title,
          mcf.get_cstacnt_lien_bals(b.account_id, cur_sod_date),
          b.mandate,
          e.withdrawal_limit_no,
          e.withdrawal_limit_amount,
          e.withdrawal_limit,
          b.account_number
        INTO ai_account_id, ai_status, ai_account_title, ai_lien_bal, ai_mandate, ai_limit_no, ai_limit_amnt, ai_withdrawal_limit,
          ai_account_number
        FROM mcf.mcf_accounts b
          LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
          LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
        WHERE ((b.account_id = rowLoans.repayment_account_id));

        PERFORM mcf.createAccountTrns(rowLoans.repayment_account_id, tday_dte, 'Paperless',
                                      'RPMT-' || v_trns_tm,
                                      'Automatic Loan Repayment(COB) for Loan Request '||rowLoans.trnsctn_id, 'DR', (lv_principal_amnt + lv_interest_amnt),
                                      'REPAYMENT',
                                      (lv_principal_amnt + lv_interest_amnt), 'Self', '', '', '', '', '',
                                      'RPMT-' || v_trns_tm,
                                      'Paid', -1, '', '', rowLoans.currency_id, 1, ai_status, ai_account_title,
                                      ai_lien_bal, ai_mandate,
                                      ai_limit_no, ai_limit_amnt, ai_withdrawal_limit, '0', -1, -1, rowLoans.branch_id,
                                      $3, $1, cur_sod_date);
                     

        --CREATE CUSTOMER ACCOUNT BALANCE
        
          PERFORM mcf.update_cstmracnt_balances_ovdrft(rowLoans.repayment_account_id, (lv_principal_amnt + lv_interest_amnt),
                                               0.00, 0.00, '', cur_sod_date, 'D', 'RPMT', '', $1, tday_dte);

        IF msgs1 != '' THEN
           msgs :=   msgs1;
           updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
        END IF;
        v_ttl_loan_prncpl_msg := v_ttl_loan_prncpl_msg + lv_principal_amnt;
        v_ttl_loan_intrst_msg := v_ttl_loan_intrst_msg + lv_interest_amnt;
       

        IF round((v_loan_prncpl_bal + v_loan_intrst_bal)) = 0.00
        THEN
          SELECT count(*)
          INTO v_lien_cnt
          FROM mcf.mcf_account_liens
          WHERE loan_rqst_id = rowLoans.loan_rqst_id AND lien_status = 'Active';
          IF v_lien_cnt > 0
          THEN
            IF v_lien_cnt > 1
            THEN
              msgs := 'Loan Request ' || rowLoans.trnsctn_id || ' has v_lien_cnt ' ||
                     ' Active Liens ';
                     updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
            ELSE
              UPDATE mcf.mcf_account_liens
              SET lien_status = 'Removed', end_date_active = cur_sod_date
              WHERE loan_rqst_id = rowLoans.loan_rqst_id AND
                    account_id = rowLoans.cash_collateral_id;

              UPDATE mcf.mcf_account_liens
              SET lien_status = 'Removed', end_date_active = cur_sod_date
              WHERE loan_rqst_id = rowLoans.loan_rqst_id AND
                    account_id = rowLoans.cash_collateral_id;

              -- REVERSE LIEN
              SELECT coalesce(amount, 0.00)
              INTO v_lien_amt
              FROM mcf.mcf_account_liens
              WHERE loan_rqst_id = rowLoans.loan_rqst_id AND
                    account_id = rowLoans.cash_collateral_id;

              select to_char(now(),'YYMMDDHH24MISS') INTO p_dte;
	      SELECT code_for_trns_nums INTO p_usrTrnsCode FROM sec.sec_users WHERE user_id = $1;
	    
	      p_gnrtdTrnsNo := 'LIEN-'||p_usrTrnsCode||'-'||p_dte;

              PERFORM mcf.createAccountTrns(rowLoans.cash_collateral_id, tday_dte, 'Paperless',
			p_gnrtdTrnsNo,
			'LIEN Reversal - for Loan Request '||rowLoans.trnsctn_id, 'CR', v_lien_amt,
			'LIEN_TRNS',
			0, 'Self', '', '', '', '', '',
			p_gnrtdTrnsNo,
			'Received', -1, '', '', rowLoans.currency_id, 1, ai_status, ai_account_title, ai_lien_bal, ai_mandate,
                        ai_limit_no, ai_limit_amnt, ai_withdrawal_limit, '0', -1, -1, rowLoans.branch_id, 
                        $3, $1, cur_sod_date); 	

              UPDATE mcf.mcf_account_liens
              SET lien_status = 'Removed', end_date_active = cur_sod_date
              WHERE loan_rqst_id = rowLoans.loan_rqst_id AND
                    account_id = rowLoans.cash_collateral_id;	

              PERFORM mcf.update_cstmracnt_balances_ovdrft(rowLoans.cash_collateral_id, (-1 * v_lien_amt),
                                                    0.00, v_lien_amt, '',
                                                    cur_sod_date, 'D', 'LIEN', '', $1, tday_dte);

            END IF;

          END IF;

        END IF;

      END IF;

      --RAISE NOTICE 'lv_schedule_id2 = "%"', lv_schedule_id;
    END IF;


    --CHECK FOR LATE PAYMENTS AND APPLY APPLICABLE PENALTY
    v_is_paid := 'NO';

    SELECT DISTINCT a.is_paid
    INTO v_is_paid
    FROM mcf.mcf_loan_schedule a
    WHERE a.disbmnt_det_id = rowLoans.disbmnt_det_id
          AND to_char(to_timestamp(a.repay_date, 'YYYY-MM-DD'), 'YYYY-MM-DD') = cur_sod_date;

    --CHARGE PENALTY
    IF v_is_paid = 'NO' OR v_is_paid = 'PARTIAL'
    THEN
      SELECT
        fee_name,
        target,
        fee_flat,
        fee_percent,
        frequency,
        frequency_no,
        remarks,
        org.get_accnt_id_brnch_eqv(rowLoans.branch_id, crdt_accnt_id) crdt_accnt_id
      INTO lp_fee_name, lp_target, lp_fee_flat, lp_fee_percent, lp_crdt_accnt_id
      FROM mcf.mcf_loanprdt_latefees_n_accts
      WHERE loan_product_id > rowLoans.loan_product_id;
      IF lp_fee_flat > 0 OR lp_fee_percent > 0
      THEN
        IF lp_target = 'Total Loan Amount' OR lp_target = 'Principal and Interest Balance'
        THEN
          IF lp_fee_flat > 0
          THEN
            lp_late_pnlty_fee := lp_fee_flat;
          END IF;
          IF lp_fee_percent > 0
          THEN
            lp_late_pnlty_fee := lp_late_pnlty_fee + lp_fee_percent * (lv_principal_amnt + lv_interest_amnt);
          END IF;
        ELSIF lp_target = 'Overdue Principal' OR lp_target = 'Principal Balance'
          THEN
            IF lp_fee_flat > 0
            THEN
              lp_late_pnlty_fee := lp_fee_flat;
            END IF;
            IF lp_fee_percent > 0
            THEN
              lp_late_pnlty_fee := lp_late_pnlty_fee + lp_fee_percent * (lv_principal_amnt);
            END IF;
        ELSIF lp_target = 'Overdue Interest' OR lp_target = 'Interest Balance'
          THEN
            IF lp_fee_flat > 0
            THEN
              lp_late_pnlty_fee := lp_fee_flat;
            END IF;
            IF lp_fee_percent > 0
            THEN
              lp_late_pnlty_fee := lp_late_pnlty_fee + lp_fee_percent * (lv_interest_amnt);
            END IF;
        END IF;

        IF lp_late_pnlty_fee > 0
        THEN
          --CREATE ACCOUNTING
          tmp_crdt := 0;
          tmp_dbt := lp_late_pnlty_fee;
          tmp_net := tmp_dbt;
          tmp_dbt_crdt := 'D';

          INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                                 dbt_amount, trnsctn_date,
                                                 func_cur_id, created_by, creation_date, batch_id,
                                                 crdt_amount,
                                                 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                                 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                                 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                                 is_reconciled)
          VALUES
            ((SELECT mcf.get_cstacct_gl_liablty_acct_id(rowLoans.repayment_account_id)),
              lp_fee_name || ' on ' || lp_target || ' - ' || rowLoans.trnsctn_id,
              tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1, tday_dte, gl_btchID,
              tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                      tmp_net,
                                      cur_ID,
                                      tmp_net,
                                      cur_ID,
                                      1,
                                      1,
                                      tmp_dbt_crdt,
             '',
             '1');


          tmp_crdt := lp_late_pnlty_fee;
          tmp_dbt :=0;
          tmp_net := tmp_crdt;
          tmp_dbt_crdt := 'C';

          INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                                 dbt_amount, trnsctn_date,
                                                 func_cur_id, created_by, creation_date, batch_id,
                                                 crdt_amount,
                                                 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                                 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                                 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                                 is_reconciled)
          VALUES
            (lp_crdt_accnt_id, lp_fee_name || ' on ' || lp_target || ' - ' || rowLoans.trnsctn_id,
                               tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1, tday_dte,
                               gl_btchID,
                               tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                       tmp_net,
                                                       cur_ID,
                                                       tmp_net,
                                                       cur_ID,
                                                       1,
                                                       1,
                                                       tmp_dbt_crdt,
             '',
             '1');

          cnta2 := cnta2 + 1;

          --CREATE CUSTOMER ACCOUNT TRANSACTION RECORD
          SELECT
            b.account_id,
            b.status,
            b.account_title,
            mcf.get_cstacnt_lien_bals(b.account_id, to_char(now(), 'YYYY-MM-DD')),
            b.mandate,
            e.withdrawal_limit_no,
            e.withdrawal_limit_amount,
            e.withdrawal_limit,
            b.account_number
          INTO ai_account_id, ai_status, ai_account_title, ai_lien_bal, ai_mandate, ai_limit_no, ai_limit_amnt, ai_withdrawal_limit,
            ai_account_number
          FROM mcf.mcf_accounts b
            LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
            LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
          WHERE ((b.account_id = rowLoans.repayment_account_id));

          PERFORM mcf.createAccountTrns(rowLoans.repayment_account_id, tday_dte, 'Paperless',
                                        'PNLTY-' || v_trns_tm,
                                        'Loan Repayment Default Penalty', 'DR', lp_late_pnlty_fee,
                                        'LOAN REPAYMENT PENALTY',
                                        lp_late_pnlty_fee, 'Self', '', '', '', '', '',
                                        'PNLTY-' || v_trns_tm,
                                        'Paid', -1, '', '', rowLoans.currency_id, 1, ai_status, ai_account_title,
                                        ai_lien_bal, ai_mandate,
                                        ai_limit_no, ai_limit_amnt, ai_withdrawal_limit, '0', -1, -1,
                                        rowLoans.branch_id, $3, $1, cur_sod_date);

          --CREATE DAILY BALANCE RECORD
          PERFORM mcf.update_cstmracnt_balances_ovdrft(rowLoans.repayment_account_id, lp_late_pnlty_fee, 0.00, 0.00, '',
                                                       cur_sod_date, 'D', 'PNLTY', '', $1,
                                                       cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()));

        END IF;
      END IF;
    END IF;
  END LOOP;

  IF cnta2 > 0
  THEN
    msgs :=  'Successfully Created ' || trim(to_char(cnta2, '99999999999999999999999999999999999')) ||
            ' Loan Repayment Transaction(s)! Total Principal: GHS'||v_ttl_loan_prncpl_msg||' Total Interest: GHS'||v_ttl_loan_intrst_msg||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
            updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
    --RAISE NOTICE 'msgs = "%"', msgs;
  ELSE
    --DELETE HEADER
    DELETE FROM accb.accb_trnsctn_batches
    WHERE batch_id = gl_btchID;
    msgs :=  'Deleted Account GL Batch Header Successfully'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  END IF;

  /*3. DEBIT INTEREST FOR OVERDRAFT FACILITY*/
  msgs :=  'Creating Overdraft Deductions GL Batch Header Process....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

  SELECT mcf.getdb_incrmntl_datetime_ymdhms(v_trns_tm) INTO v_trns_tm;
  gl_btchID := -1;
  IF gl_btchID <= 0
  THEN
    INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date,
                                           org_id, batch_status, last_update_by, last_update_date, batch_source)
    VALUES
      ('End of Day Process - Overdraft Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       'End of Day Process - Overdraft Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       $1, cur_sod_date, $3, '0', $1, cur_sod_date, 'End of Day Process - Overdraft Accounting');
    --COMMIT;
  END IF;
  SELECT COALESCE(accb.get_TodysBatch_id('End of Day Process - Overdraft Accounting (' || cur_sod_date, $3), -1)
  INTO gl_btchID;
  msgs :=  'End of Day Process - Overdraft Accounting GL Batch ID= ' ||
          trim(to_char(gl_btchID, '999999999999999999999999999999999999999999'));
          updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  msgs := 'End of Day Process - Overdraft Accounting GL Batch Name= ''End of Day Process - Overdraft Accounting (' ||
         cur_sod_date
         || ')''';
         updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  --OVERDRAFT
  /*2. ACCRUE PRINCIPAL AND/INTEREST FOR ALL RUNNING ODS WHERE SCHEDULE DATE IS DUE*/
  FOR rowOD IN (SELECT
                  a.loan_rqst_id,
                  disbmnt_det_id,
                  a.branch_id,
                  CASE WHEN a.cust_type = 'Group'
                    THEN mcf.get_customer_name('Individual', a.cust_id)
                  ELSE mcf.get_customer_name(a.cust_type, a.cust_id) END                 customer,
                  a.cust_type,
                  a.trnsctn_id,
                  a.approved_amount,
                  a.apprvd_interest_rate,
                  to_char(to_timestamp(c.repay_start_date, 'YYYY-MM-DD'), 'DD-Mon-YYYY') repay_start_date,
                  to_char(to_timestamp(c.repay_end_date, 'YYYY-MM-DD'), 'DD-Mon-YYYY')   repay_end_date,
                  crdt_type,
                  org.get_accnt_id_brnch_eqv(a.branch_id, principal_rcvbl_acct_id) principal_rcvbl_acct_id,
				  org.get_accnt_id_brnch_eqv(a.branch_id, interest_rcvbl_acct_id) interest_rcvbl_acct_id,
                  org.get_accnt_id_brnch_eqv(a.branch_id, interest_revenue_acct_id) deferred_interest_acct_id,
                  currency_id,
                  repayment_type,
                  repayment_account_id,
                  b.loan_product_id,
                  account_id                                                             loan_account_id,
                  a.is_disbursed,
                  sec.get_usr_prsn_id(d.created_by)                                      prsn_id
                FROM mcf.mcf_loan_request a, mcf.mcf_prdt_loans b, mcf.mcf_loan_disbursement_det c,
                  mcf.mcf_loan_disbursement_hdr d
                WHERE a.loan_product_id = b.loan_product_id AND c.loan_rqst_id = a.loan_rqst_id AND
                      c.disbmnt_hdr_id = d.disbmnt_hdr_id
                      AND to_char(now(), 'YYYY-MM-DD') BETWEEN c.repay_start_date AND c.repay_end_date
                      --AND c.ttl_tenor_bal > 0 
                      AND repayment_type = 'Account Deductions' AND is_disbursed = 'YES' AND
                      crdt_type = 'Overdraft' AND b.charge_interest = 'YES'
                      AND a.status = 'Approved' AND d.status = 'Disbursed' AND c.principal_amount > 0
                ORDER BY crdt_type, trnsctn_id, a.branch_id)
  LOOP
 
    SELECT mcf.get_cstacnt_avlbl_bals(rowOD.repayment_account_id, cur_sod_date)
    INTO od_avlbl_bal;
    od_apprvd_loan_amnt := rowOD.approved_amount;
    od_ovdrwn_acct_bal := od_apprvd_loan_amnt - od_avlbl_bal;

    SELECT mapped_lov_crncy_id :: BIGINT
    INTO cur_ID
    FROM mcf.mcf_currencies
    WHERE crncy_id = rowOD.currency_id;

    IF od_avlbl_bal > 0 AND  od_ovdrwn_acct_bal > 0
    THEN
      SELECT mcf.xx_calc_daily_interest(od_ovdrwn_acct_bal, rowOD.apprvd_interest_rate)
      INTO od_interest_tday;

      -- ACCRUE
      INSERT INTO mcf.mcf_daily_overdraft_interest (
        bal_date, repayment_account_id, disbmnt_det_id,
        created_by, creation_date, last_update_by, last_update_date,
        closing_balance, interest_earned, is_interest_paid, payment_date)
      VALUES (cur_sod_date, rowOD.repayment_account_id, rowOD.disbmnt_det_id,
                            usr_id, tday_dte, usr_id, tday_dte,
                            od_avlbl_bal, od_interest_tday, 'No', '');

      --RAISE NOTICE 'lv_schedule_id2 = "%"', lv_schedule_id;

      --CREATE ACCOUNTING
      tmp_crdt := 0;
      tmp_dbt :=od_interest_tday;
      tmp_net := tmp_dbt;
      tmp_dbt_crdt := 'D';

      INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                             dbt_amount, trnsctn_date,
                                             func_cur_id, created_by, creation_date, batch_id,
                                             crdt_amount,
                                             last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                             entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                             func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                             is_reconciled)
      VALUES
        (rowOD.interest_rcvbl_acct_id, 'Interest Accrual for Overdraft Request no ' || rowOD.trnsctn_id,
                                       tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
                                       tday_dte,
                                       gl_btchID,
                                       tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                               tmp_net,
                                                               cur_ID,
                                                               tmp_net,
                                                               cur_ID,
                                                               1,
                                                               1,
                                                               tmp_dbt_crdt,
         '',
         '1');


      tmp_crdt := od_interest_tday;
      tmp_dbt :=0;
      tmp_net := tmp_crdt;
      tmp_dbt_crdt := 'C';

      INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                             dbt_amount, trnsctn_date,
                                             func_cur_id, created_by, creation_date, batch_id,
                                             crdt_amount,
                                             last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                             entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                             func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                             is_reconciled)
      VALUES
        (rowOD.deferred_interest_acct_id, 'Interest Accrual for Overdraft Request no ' || rowOD.trnsctn_id,
                                         tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
                                         tday_dte,
                                         gl_btchID,
                                         tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                                 tmp_net,
                                                                 cur_ID,
                                                                 tmp_net,
                                                                 cur_ID,
                                                                 1,
                                                                 1,
                                                                 tmp_dbt_crdt,
         '',
         '1');

      --INCREASE DATE AND CHECK FOR HOLIDAYS AND WEEKENDS
      next_sod_dte := cur_sod_date;
      SELECT mcf.get_date_part('month', next_sod_dte)
      INTO v_month_cur;
      v_month_nxt := v_month_cur;

      --EXIT WHEN counter = n

      WHILE v_month_cur = v_month_nxt
      LOOP
        SELECT mcf.get_next_date(next_sod_dte, 1)
        INTO next_sod_dte;
        SELECT mcf.get_date_part('month', next_sod_dte)
        INTO v_month_nxt;

        SELECT mcf.is_date_holiday(next_sod_dte)
        INTO is_hldy;
        SELECT mcf.is_date_weekend(next_sod_dte)
        INTO is_wknd;

        IF v_month_cur = v_month_nxt
        THEN
          IF is_hldy = TRUE
          THEN
            INSERT INTO mcf.mcf_daily_overdraft_interest (
              bal_date, repayment_account_id, disbmnt_det_id,
              created_by, creation_date, last_update_by, last_update_date,
              closing_balance, interest_earned, is_interest_paid, payment_date)
            VALUES (next_sod_dte, rowOD.repayment_account_id, rowOD.disbmnt_det_id,
                                  usr_id, tday_dte, usr_id, tday_dte,
                                  od_avlbl_bal, od_interest_tday, 'No', '');
          ELSE
            IF is_wknd = TRUE
            THEN
              INSERT INTO mcf.mcf_daily_overdraft_interest (
                bal_date, repayment_account_id, disbmnt_det_id,
                created_by, creation_date, last_update_by, last_update_date,
                closing_balance, interest_earned, is_interest_paid, payment_date)
              VALUES (next_sod_dte, rowOD.repayment_account_id, rowOD.disbmnt_det_id,
                                    usr_id, tday_dte, usr_id, tday_dte,
                                    od_avlbl_bal, od_interest_tday, 'No', '');

            ELSE
              EXIT;
            END IF;
          END IF;

          tmp_crdt := 0;
          tmp_dbt :=od_interest_tday;
          tmp_net := tmp_dbt;
          tmp_dbt_crdt := 'D';

          INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                                 dbt_amount, trnsctn_date,
                                                 func_cur_id, created_by, creation_date, batch_id,
                                                 crdt_amount,
                                                 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                                 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                                 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                                 is_reconciled)
          VALUES
            (rowOD.interest_rcvbl_acct_id, 'Interest Accrual for Overdraft Request no ' || rowOD.trnsctn_id,
                                           tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
                                           tday_dte, gl_btchID,
                                           tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                                   tmp_net,
                                                                   cur_ID,
                                                                   tmp_net,
                                                                   cur_ID,
                                                                   1,
                                                                   1,
                                                                   tmp_dbt_crdt,
             '',
             '1');


          tmp_crdt := od_interest_tday;
          tmp_dbt :=0;
          tmp_net := tmp_crdt;
          tmp_dbt_crdt := 'C';


          INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                                 dbt_amount, trnsctn_date,
                                                 func_cur_id, created_by, creation_date, batch_id,
                                                 crdt_amount,
                                                 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                                 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                                 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                                 is_reconciled)
          VALUES
            (rowOD.deferred_interest_acct_id, 'Interest Accrual for Overdraft Request no ' || rowOD.trnsctn_id,
                                             tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
                                             tday_dte, gl_btchID,
                                             tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                                     tmp_net,
                                                                     cur_ID,
                                                                     tmp_net,
                                                                     cur_ID,
                                                                     1,
                                                                     1,
                                                                     tmp_dbt_crdt,
             '',
             '1');

        ELSE
          EXIT;
        END IF;
      END LOOP;

      --DEBIT CUSTOMER LIABILITY ACCOUNT WITH INTEREST (and Update Customer Balance) and CREDIT INTEREST RECEIVABLE and CREATE ACCOUNTING =>


      --msgs :=   'Overdraft Interest Accrual for Loan Request ' || rowOD.trnsctn_id || ' Interest ' ||
      --        od_interest_tday;
      --        updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
      cnta3 := cnta3 + 1;
    END IF;
  END LOOP;

  
  IF cnta3 > 0
  THEN
    msgs :=  'Successfully Created ' || trim(to_char(cnta3, '99999999999999999999999999999999999')) ||
            ' Overdraft Interest Accrual Transaction(s)!'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
            updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  ELSE
    --DELETE HEADER
    DELETE FROM accb.accb_trnsctn_batches
    WHERE batch_id = gl_btchID;
    msgs := 'Deleted OD Account GL Batch Header Successfully'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  END IF;

  

  --CHARGE PENALTY FOR OVERDRAWN ACCOUNTS WITHOUT ODS
   
  msgs :=  'START: Charging Penalties for Overdrawn Accounts without Overdrafts Facilities.....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  
  SELECT mcf.getdb_incrmntl_datetime_ymdhms(v_trns_tm) INTO v_trns_tm;
  gl_btchID := -1;
  IF gl_btchID <= 0
  THEN
    INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date,
                                           org_id, batch_status, last_update_by, last_update_date, batch_source)
    VALUES
      ('End of Day Process - Overdrawn Accounts Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       'End of Day Process - Overdrawn Accounts Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       $1, cur_sod_date, $3, '0', $1, cur_sod_date, 'End of Day Process - Overdrawn Accounts Accounting');
    --COMMIT;
  END IF;
  SELECT COALESCE(accb.get_TodysBatch_id('End of Day Process - Overdrawn Accounts Accounting (' || cur_sod_date, $3), -1)
  INTO gl_btchID;
  msgs :=  'End of Day Process - Overdrawn Accounts Accounting GL Batch ID= ' ||
          trim(to_char(gl_btchID, '999999999999999999999999999999999999999999'));
          updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  msgs := 'End of Day Process - Overdrawn Accounts Accounting GL Batch Name= ''End of Day Process - Overdrawn Accounts Accounting (' ||
         cur_sod_date
         || ')''';
         updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  
  FOR rowOvdrwnAccts IN (SELECT
                           b.account_title,
                           b.account_id,
                           b.branch_id,
                           e.crncy_id,
                           account_number,
                           c.svngs_product_id,
                           c.overdraft_penalty_flat,
                           c.overdraft_penalty_percent,
                           org.get_accnt_id_brnch_eqv(b.branch_id, d.overdraft_pnlty_crdt_accnt_id) overdraft_pnlty_crdt_accnt_id
                         FROM mcf.mcf_accounts b INNER JOIN mcf.mcf_prdt_savings c
                             ON (b.product_type_id = c.svngs_product_id)
                           LEFT OUTER JOIN mcf.mcf_prdt_savings_stdevnt_accntn d
                             ON (c.svngs_product_id = d.svngs_product_id)
                           LEFT OUTER JOIN mcf.mcf_currencies e ON (c.currency_id = e.crncy_id)
                         WHERE
                           1 = 1 AND UPPER(b.status) = 'AUTHORIZED' AND account_type IN ('Current', 'Savings', 'Susu')
                           AND UPPER(account_status) != 'CLOSED'
                           AND b.account_id NOT IN (SELECT DISTINCT repayment_account_id
                                                    FROM mcf.mcf_loan_request a, mcf.mcf_prdt_loans b,
                                                      mcf.mcf_loan_disbursement_det c, mcf.mcf_loan_disbursement_hdr d
                                                    WHERE a.loan_product_id = b.loan_product_id AND
                                                          c.loan_rqst_id = a.loan_rqst_id AND
                                                          c.disbmnt_hdr_id = d.disbmnt_hdr_id
                                                          AND to_char(now(),
                                                                      'YYYY-MM-DD') BETWEEN c.repay_start_date AND c.repay_end_date
                                                          AND c.ttl_tenor_bal > 0 AND
                                                          repayment_type = 'Account Deductions' AND is_disbursed = 'YES'
                                                          AND crdt_type = 'Overdraft' AND b.charge_interest = 'YES'
                                                          AND a.status = 'Approved')
                         ORDER BY 3, 2)
  LOOP
  
    SELECT mcf.getdb_incrmntl_datetime_ymdhms(v_trns_tm) INTO v_trns_tm;
  
    SELECT mapped_lov_crncy_id :: BIGINT
    INTO cur_ID
    FROM mcf.mcf_currencies
    WHERE crncy_id = rowOvdrwnAccts.crncy_id;

    SELECT mcf.get_cstacnt_avlbl_bals(rowOvdrwnAccts.account_id, cur_sod_date)
    INTO optn_acct_bal;
    IF optn_acct_bal < 0
    THEN
      --GET PENALTIES
      IF rowOvdrwnAccts.overdraft_penalty_flat > 0 OR rowOvdrwnAccts.overdraft_penalty_percent > 0
      THEN
        IF rowOvdrwnAccts.overdraft_penalty_flat > 0
        THEN
          ovdrwn_pnlty_fee := rowOvdrwnAccts.overdraft_penalty_flat;
        END IF;
        IF rowOvdrwnAccts.overdraft_penalty_percent > 0
        THEN
          ovdrwn_pnlty_fee := ovdrwn_pnlty_fee + rowOvdrwnAccts.overdraft_penalty_percent * (optn_acct_bal);
        END IF;

        IF ovdrwn_pnlty_fee > 0
        THEN
          --CREATE ACCOUNTING
          tmp_crdt := 0;
          tmp_dbt := ovdrwn_pnlty_fee;
          tmp_net := tmp_dbt;
          tmp_dbt_crdt := 'D';

          INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                                 dbt_amount, trnsctn_date,
                                                 func_cur_id, created_by, creation_date, batch_id,
                                                 crdt_amount,
                                                 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                                 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                                 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                                 is_reconciled)
          VALUES
            ((SELECT mcf.get_cstacct_gl_liablty_acct_id(rowOvdrwnAccts.account_id)),
              'Penalty for Overdrawing Account - ' || rowOvdrwnAccts.account_number,
              tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1, tday_dte, gl_btchID,
              tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                      tmp_net,
                                      cur_ID,
                                      tmp_net,
                                      cur_ID,
                                      1,
                                      1,
                                      tmp_dbt_crdt,
             '',
             '1');


          tmp_crdt := ovdrwn_pnlty_fee;
          tmp_dbt :=0;
          tmp_net := tmp_crdt;
          tmp_dbt_crdt := 'C';

          INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                                 dbt_amount, trnsctn_date,
                                                 func_cur_id, created_by, creation_date, batch_id,
                                                 crdt_amount,
                                                 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                                 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                                 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                                 is_reconciled)
          VALUES
            (rowOvdrwnAccts.overdraft_pnlty_crdt_accnt_id,
              'Penalty for Overdrawing Account - ' || rowOvdrwnAccts.account_number,
              tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1, tday_dte, gl_btchID,
              tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                      tmp_net,
                                      cur_ID,
                                      tmp_net,
                                      cur_ID,
                                      1,
                                      1,
                                      tmp_dbt_crdt,
             '',
             '1');

          cnta5 := cnta5 + 1;

          --CREATE CUSTOMER ACCOUNT TRANSACTION RECORD
          SELECT
            b.account_id,
            b.status,
            b.account_title,
            mcf.get_cstacnt_lien_bals(b.account_id, cur_sod_date),
            b.mandate,
            e.withdrawal_limit_no,
            e.withdrawal_limit_amount,
            e.withdrawal_limit,
            b.account_number
          INTO ai_account_id, ai_status, ai_account_title, ai_lien_bal, ai_mandate, ai_limit_no, ai_limit_amnt, ai_withdrawal_limit,
            ai_account_number
          FROM mcf.mcf_accounts b
            LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
            LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
          WHERE ((b.account_id = rowOvdrwnAccts.account_id));

          --msgs := msgs || chr(10) || 'ai_account_id='||ai_account_id|| ' ai_account_id='||ai_account_id

          PERFORM mcf.createAccountTrns(rowOvdrwnAccts.account_id, tday_dte, 'Paperless',
                                        'PNLTY-' || v_trns_tm,
                                        'Overdrawn Account Default Penalty', 'DR', ovdrwn_pnlty_fee,
                                        'OVERDRAWN ACCOUNT PENALTY',
                                        ovdrwn_pnlty_fee, 'Self', '', '', '', '', '',
                                        'PNLTY-' || v_trns_tm,
                                        'Paid', -1, '', '', rowOvdrwnAccts.crncy_id, 1, ai_status, ai_account_title,
                                        ai_lien_bal, ai_mandate,
                                        ai_limit_no, ai_limit_amnt, ai_withdrawal_limit, '0', -1, -1,
                                        rowOvdrwnAccts.branch_id, $3, $1, cur_sod_date);

          --CREATE DAILY BALANCE RECORD
          PERFORM mcf.update_cstmracnt_balances_ovdrft(rowOvdrwnAccts.account_id, ovdrwn_pnlty_fee, 0.00, 0.00, '',
                                                       cur_sod_date, 'D', 'PNLTY', '', $1,
                                                       cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()));

        END IF;
      END IF;
    END IF;
  END LOOP;

  
  msgs := 'END: Charging Penalties for Overdrawn Accounts without Overdrafts Facilities.....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

  IF cnta5 > 0
  THEN
    msgs :=  'Successfully Created ' || trim(to_char(cnta5, '99999999999999999999999999999999999')) ||
            ' Penalty Transaction(s)!';
            updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  ELSE
    --DELETE HEADER
    DELETE FROM accb.accb_trnsctn_batches
    WHERE batch_id = gl_btchID;
    msgs :=  'Deleted Account GL Batch Header Successfully';
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  END IF;


  /*6. SMS ALERTS -> PAYMENTS, DETAULTS*/
  --LOAD PAYMENTS
  msgs :=  'Start Loading Loan Payments for today'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  FOR rowLnPymntsTday IN (
    SELECT DISTINCT
      mcf.get_customer_account_name(a.cust_type, a.cust_id)                                    customer,
      COALESCE(mcf.get_customer_data(a.cust_type, a.cust_id, 'cntct_no_mobl'), 'NO DATA')      tel_no,
      COALESCE(mcf.get_customer_data(a.cust_type, a.cust_id, 'email'), 'NO DATA')              email,
      --to_char(to_timestamp(c.actual_repay_date, 'YYYY-MM-DD'), 'DD-Mon-YYYY')             repayment_date,
      CASE WHEN sum(c.interest_amnt_paid + c.principal_amnt_paid) = 0
        THEN '0.00'
      ELSE
        to_char(sum(c.interest_amnt_paid + c.principal_amnt_paid), 'FM999,999,999,990D00') END ttl_payment,
      a.loan_rqst_id,
      a.trnsctn_id,
      e.iso_code,
      CASE WHEN b.principal_amount_bal = 0
        THEN '0.00'
      ELSE
        to_char(b.principal_amount_bal, 'FM999,999,999,990D00') END                            principal_amount_bal,
      CASE WHEN b.ttl_interest_bal = 0
        THEN '0.00'
      ELSE to_char(b.ttl_interest_bal, 'FM999,999,999,990D00') END                             ttl_interest_bal
    FROM mcf.mcf_loan_request a, mcf.mcf_loan_disbursement_det b, mcf.mcf_loan_schedule c,
      mcf.mcf_prdt_loans d, mcf.mcf_currencies e
    WHERE a.loan_rqst_id = b.loan_rqst_id
          AND b.disbmnt_det_id = c.disbmnt_det_id
          AND a.loan_product_id = d.loan_product_id
          AND e.crncy_id = d.currency_id
          AND trim(actual_repay_date) = cur_sod_date
    GROUP BY a.cust_type, a.cust_id, a.loan_rqst_id, a.trnsctn_id, e.iso_code, b.principal_amount_bal,
      b.ttl_interest_bal)
  LOOP
    v_loan_rpymnt_msg :=
    'Dear ' || rowLnPymntsTday.customer || ',' || chr(10) || 'An amount of ' || rowLnPymntsTday.iso_code
    || rowLnPymntsTday.ttl_payment || ' was received today ' || to_char(now(), 'DD-Mon-YYYY') ||
    ' as repayment of LOAN REQUEST ' || rowLnPymntsTday.trnsctn_id
    || chr(10) || 'Principal Bal: ' || rowLnPymntsTday.iso_code || rowLnPymntsTday.principal_amount_bal ||
    ', Interest Bal: ' || rowLnPymntsTday.iso_code || rowLnPymntsTday.ttl_interest_bal
    || chr(10) || 'Thank you!' || chr(10) || 'From: Yilo Star Management';

    INSERT INTO mcf.mcf_cob_sms_loans (
      cob_date, loan_rqst_id, phone_no, msg_to_send, status,
      created_by, creation_date, last_update_by, last_update_date,
      msg_type)
    VALUES
      (cur_sod_date, rowLnPymntsTday.loan_rqst_id, rowLnPymntsTday.tel_no, v_loan_rpymnt_msg, 'UNSENT', $1, tday_dte,
       $1, tday_dte, 'LOAN REPAYMENT');
    NULL;
  END LOOP;


  msgs :=  'End Loading Loan Payments for today'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  
  -- LOAD DEFAULTS
  
  msgs :=  'Start Loading Loan Defaults for today'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  FOR rowLnDfltTday IN (
    SELECT DISTINCT
      repay_date,
      mcf.get_customer_account_name(a.cust_type, a.cust_id)                               customer,
      COALESCE(mcf.get_customer_data(a.cust_type, a.cust_id, 'cntct_no_mobl'), 'NO DATA') tel_no,
      COALESCE(mcf.get_customer_data(a.cust_type, a.cust_id, 'email'), 'NO DATA')         email,
      CASE WHEN c.actual_repay_date = ''
        THEN ''
      ELSE to_char(to_timestamp(c.actual_repay_date, 'YYYY-MM-DD'), 'DD-Mon-YYYY') END    repayment_date,
      --(c.interest_amnt_paid + c.principal_amnt_paid)                                      ttl_payment,
      a.loan_rqst_id,
      a.trnsctn_id,
      e.iso_code,
      CASE WHEN b.principal_amount_bal = 0
        THEN '0.00'
      ELSE
        to_char(b.principal_amount_bal, 'FM999,999,999,990D00') END                       principal_amount_bal,
      CASE WHEN b.ttl_interest_bal = 0
        THEN '0.00'
      ELSE to_char(b.ttl_interest_bal, 'FM999,999,999,990D00') END                        ttl_interest_bal
    FROM mcf.mcf_loan_request a, mcf.mcf_loan_disbursement_det b, mcf.mcf_loan_schedule c,
      mcf.mcf_prdt_loans d, mcf.mcf_currencies e
    WHERE a.loan_rqst_id = b.loan_rqst_id
          AND b.disbmnt_det_id = c.disbmnt_det_id
          AND a.loan_product_id = d.loan_product_id
          AND e.crncy_id = d.currency_id
          AND trim(repay_date) = cur_sod_date AND actual_repay_date = '')
  LOOP
    v_loan_dflt_msg :=
    'Dear ' || rowLnDfltTday.customer || ',' || chr(10) || 'NO PAYMENT was received today ' ||
    to_char(now(), 'DD-Mon-YYYY') ||
    ' as repayment of LOAN REQUEST ' || rowLnDfltTday.trnsctn_id
    || chr(10) || 'Principal Bal: ' || rowLnDfltTday.iso_code || rowLnDfltTday.principal_amount_bal ||
    ', Interest Bal: ' || rowLnDfltTday.iso_code || rowLnDfltTday.ttl_interest_bal
    || chr(10) || 'Thank you!' || chr(10) || 'From: Yilo Star Management';

    INSERT INTO mcf.mcf_cob_sms_loans (
      cob_date, loan_rqst_id, phone_no, msg_to_send, status,
      created_by, creation_date, last_update_by, last_update_date,
      msg_type)
    VALUES
      (cur_sod_date, rowLnPymntsTday.loan_rqst_id, rowLnPymntsTday.tel_no, v_loan_rpymnt_msg, 'UNSENT', $1, tday_dte,
       $1, tday_dte, 'LOAN DEFAULT');
  END LOOP;
  
  msgs := 'End Loading Loan Defaults for today'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);


--LOANS DEFAULT PROVISIONING
  --2. DEBIT PROVISION EXPENSE and CREDIT RESERVE FOR PROVISIONS FOR ALL AGED LOANS
  msgs :=  'Creating Loan Provisions GL Batch Header Process....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

  SELECT mcf.getdb_incrmntl_datetime_ymdhms(v_trns_tm) INTO v_trns_tm;
  
  gl_btchID := -1;
  IF gl_btchID <= 0
  THEN
    INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date,
                                           org_id, batch_status, last_update_by, last_update_date, batch_source)
    VALUES
      ('End of Day Process - Loan Provision Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       'End of Day Process - Loan Provision Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       $1, cur_sod_date, $3, '0', $1, cur_sod_date, 'End of Day Process - Loan Provision Accounting');
    --COMMIT;
  END IF;
    
  SELECT COALESCE(accb.get_TodysBatch_id('End of Day Process - Loan Provision Accounting (' || cur_sod_date, $3), -1)
  INTO gl_btchID;
  msgs :=  'End of Day Process - Loan Provision Accounting GL Batch ID= ' ||
          trim(to_char(gl_btchID, '999999999999999999999999999999999999999999'));
          updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  msgs := 'End of Day Process - Loan Provision Accounting GL Batch Name= ''End of Day Process - Loan Accounting (' ||
  cur_sod_date || ')''';

  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  cnta2 := 0;
  v_loan_prncpl_bal := 0;

  BEGIN
	--GET PROVISION FLAG
	SELECT UPPER(var_value) INTO v_enable_prvsn_flag
	FROM mcf.mcf_global_variables
	WHERE var_name = 'Enable Loan Loss Provisioning Accounting';
  EXCEPTION
  WHEN OTHERS THEN
        msgs := SQLSTATE || chr(10) || SQLERRM;
        updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
        --msgs:=rpt.getLogMsg($4);
        RETURN msgs;
  END;

/*7. RECLASSIFY LOANS AND OVERDRAFT DEFAULTS*/  
  msgs :=  'Start Loan and Overdraft default Classifications'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  FOR rowLoans IN (SELECT DISTINCT
                     b.disbmnt_det_id,
                     org.get_accnt_id_brnch_eqv(a.branch_id, d.loan_provision_dbt_acct_id) loan_provision_dbt_acct_id,
		     org.get_accnt_id_brnch_eqv(a.branch_id, d.loan_provision_crdt_acct_id) loan_provision_crdt_acct_id,
                     a.loan_rqst_id,
                     currency_id,
                     a.trnsctn_id
                   FROM mcf.mcf_loan_request a, mcf.mcf_loan_disbursement_det b,/* mcf.mcf_loan_schedule c,*/
                     mcf.mcf_prdt_loans d, mcf.mcf_loan_disbursement_hdr e
                   WHERE a.loan_rqst_id = b.loan_rqst_id
                         /*AND b.disbmnt_det_id = c.disbmnt_det_id*/
                         AND a.loan_product_id = d.loan_product_id
                         AND b.disbmnt_hdr_id = e.disbmnt_hdr_id
                         AND a.status = 'Approved' AND e.status = 'Disbursed' AND b.principal_amount > 0
						 ORDER BY 4 DESC
                         /*AND a.loan_rqst_id NOT IN (SELECT DISTINCT loan_rqst_id
                                                    FROM mcf.mcf_loan_writeoffs x
                                                    WHERE x.status = 'Authorized' AND x.writeoff_status = 'Processed')
                         AND a.loan_rqst_id IN (13944, 13962, 17226, 17227, 17229)*/
                         )
  LOOP
  
	v_loan_clsfctn_id := -1;
	v_loan_age := 0;
	ln_clsf_rc_cnt := 0;
	v_provision_prcnt := 0;
	v_ln_write_cnt := 0;
	v_loan_prncpl_bal := 0;
	v_provision_amnt := 0;	
	v_prev_provision_amnt := 0;

	SELECT mcf.get_loan_dflt_age(rowLoans.loan_rqst_id, cur_sod_date) INTO v_loan_age;
	
	IF v_loan_age = 0 THEN
		v_loan_clsfctn_id := -1;
	ELSE
		SELECT COUNT(*) INTO ln_clsf_rc_cnt
		FROM mcf.mcf_loan_classifications_setup a
		WHERE v_loan_age BETWEEN range_low AND range_high;

	      IF ln_clsf_rc_cnt > 0  THEN
			SELECT loan_clsfctn_id,	provision_prcnt
		        INTO v_loan_clsfctn_id, v_provision_prcnt
		        FROM mcf.mcf_loan_classifications_setup a
		        WHERE v_loan_age BETWEEN range_low AND range_high;
	      ELSE
			v_loan_clsfctn_id := -1;
			v_provision_prcnt := 0;
	      END IF;	
	END IF;

	UPDATE mcf.mcf_loan_request
        SET loan_clsfctn_id = v_loan_clsfctn_id, dflt_age_in_days = v_loan_age
        WHERE loan_rqst_id = rowLoans.loan_rqst_id;

        --8. PROVISION FOR LOANS DEFAULTS--
        --CHECK FOR WRITE-OFFS
	SELECT COUNT(*) INTO v_ln_write_cnt  FROM mcf.mcf_loan_writeoffs x
        WHERE x.status = 'Authorized' AND x.writeoff_status = 'Processed'
        AND loan_rqst_id = rowLoans.loan_rqst_id;

        IF v_ln_write_cnt > 0 THEN
		v_loan_prncpl_bal := 0;
		v_provision_amnt := 0;		
        ELSE
		SELECT mcf.get_loan_ttl_principal_bal_as_at(rowLoans.loan_rqst_id, cur_sod_date) INTO v_loan_prncpl_bal;            
		v_provision_amnt := round(((v_provision_prcnt * v_loan_prncpl_bal)/100),2);
        END IF;
        
	SELECT mcf.get_lastloan_prvsn_amnt(rowLoans.loan_rqst_id, cur_sod_date) INTO v_prev_provision_amnt;
	
	IF v_enable_prvsn_flag = 'YES' THEN
		INSERT INTO mcf.mcf_loan_provisions(
			loan_rqst_id, outstanding_bal, prvsn_amnt, created_by, 
			creation_date, last_update_by, last_update_date, bal_date, default_age)
		VALUES (rowLoans.loan_rqst_id, round(v_loan_prncpl_bal,2), v_provision_amnt, $1, tday_dte, $1, tday_dte, cur_sod_date, v_loan_age);

		IF (v_provision_amnt - v_prev_provision_amnt) > 0 THEN
			--DEBIT EXPENSE AND CREDIT ASSET
			tmp_dbt_acct_id := rowLoans.loan_provision_dbt_acct_id;
			tmp_crdt_acct_id := rowLoans.loan_provision_crdt_acct_id;
		ELSIF (v_provision_amnt - v_prev_provision_amnt) < 0 THEN
			--CREDIT EXPENSE AND DEBIT ASSET
			tmp_dbt_acct_id := rowLoans.loan_provision_crdt_acct_id;
			tmp_crdt_acct_id := rowLoans.loan_provision_dbt_acct_id;
		END IF;

	
	
		SELECT mapped_lov_crncy_id :: BIGINT
		INTO cur_ID
		FROM mcf.mcf_currencies
		WHERE crncy_id = rowLoans.currency_id;

		--DR
		tmp_crdt := 0;
		tmp_dbt := (v_provision_amnt - v_prev_provision_amnt);
		IF tmp_dbt < 0 THEN
			tmp_dbt := -1 * tmp_dbt;
		END IF;
		tmp_net := tmp_dbt;
		tmp_dbt_crdt := 'D';
		
		IF tmp_dbt > 0
		THEN
		  INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
							 dbt_amount, trnsctn_date,
							 func_cur_id, created_by, creation_date, batch_id,
							 crdt_amount,
							 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
							 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
							 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
							 is_reconciled)
		  VALUES
		    (tmp_dbt_acct_id,
		      'Provision for Loan Request ' || rowLoans.trnsctn_id||' at default age of '||v_loan_age||' day(s)',
		      tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1, tday_dte, gl_btchID,
		      tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
					      tmp_net,
					      cur_ID,
					      tmp_net,
					      cur_ID,
					      1,
					      1,
					      tmp_dbt_crdt,
					     '',
					     '1');

		  --CR
		  tmp_dbt := 0;
		  tmp_crdt := (v_provision_amnt - v_prev_provision_amnt);      
		  IF tmp_crdt < 0 THEN
			tmp_crdt := -1 * tmp_crdt;
		  END IF;
		  tmp_net := tmp_crdt;
		  tmp_dbt_crdt := 'C';

		  INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc, dbt_amount, trnsctn_date,
							 func_cur_id, created_by, creation_date, batch_id, crdt_amount,
							 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
							 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
							 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
							 is_reconciled)
		  VALUES
		    (tmp_crdt_acct_id,
		      'Provision for Loan Request ' || rowLoans.trnsctn_id||' at default age of '||v_loan_age||' day(s)',
		      tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1, tday_dte, gl_btchID,
		      tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
					      tmp_net,
					      cur_ID,
					      tmp_net,
					      cur_ID,
					      1,
					      1,
					      tmp_dbt_crdt,
		      '',
		      '1');
		      v_rnng_provision_amnt := v_rnng_provision_amnt + tmp_crdt;
		      cnta2 := cnta2 + 1;
		END IF;
	END IF;
  END LOOP;
  
  msgs :=  'End Loan and Overdraft default Classifications'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1); 

  IF cnta2 > 0
  THEN
    msgs :=  'Successfully Created ' || trim(to_char(cnta2, '99999999999999999999999999999999999')) ||
            ' Loan Provision Transaction(s)! Total Amount: GHS'||v_rnng_provision_amnt||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
            updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
    --RAISE NOTICE 'msgs = "%"', msgs;
  ELSE
    --DELETE HEADER
    DELETE FROM accb.accb_trnsctn_batches
    WHERE batch_id = gl_btchID;
    msgs :=  'Deleted Provision GL Batch Header Successfully'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  END IF;
 
  /*11. END-DATED LIEN ACCOUNTING*/

  --INVESTMENTS
  --COMPLETE LATER
  /*10. ON MATURITY FLAG INVESTMENT AS MATURED/FULL TERM*/
  -- GET LIST OF RUNNING INVESEMENT
  -- GET VALUE FOR VARIABLE Fixed Deposit Maturity Crediting from TABLE mcf.mcf_global_variables(
  -- IF Automatic THEN CREDIT INTEREST


  /*UPDATE COB TABLE*/
  UPDATE mcf.mcf_cob_trns_records
  SET cob_status     = 'SUCCESS', last_update_by = $1,
    last_update_date = tday_dte
  WHERE cob_record_id = p_cob_record_id;

  /*updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  msgs:=rpt.getLogMsg($4);*/


IF prcs_type = 'End of Day PLUS End of Month'
  THEN
   
    msgs :=  'Starting End of Month Processes....COB DATE'||cur_sod_date||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);


    /*8. DEBIT CUSTOMER ACCOUNTS WITH ACCRUED INTEREST FOR OVERDRAFT FACILITY*/
  cnta3 = 0;
  msgs :=  'Creating Overdraft Accrued Interest Deductions GL Batch Header Process....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

  SELECT mcf.getdb_incrmntl_datetime_ymdhms(v_trns_tm) INTO v_trns_tm;
  gl_btchID := -1;
  IF gl_btchID <= 0
  THEN
    INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date,
                                           org_id, batch_status, last_update_by, last_update_date, batch_source)
    VALUES
      ('End of Day Process - Overdraft Accrued Interest Deduction Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       'End of Day Process - Overdraft Accrued Interest Deduction Accounting (' || cur_sod_date || ')-' || v_trns_tm,
       $1, cur_sod_date, $3, '0', $1, cur_sod_date, 'End of Day Process - Overdraft Accrued Interest Deduction Accounting');
    --COMMIT;
  END IF;
  SELECT COALESCE(accb.get_TodysBatch_id('End of Day Process - Overdraft Accrued Interest Deduction Accounting (' || cur_sod_date, $3), -1)
  INTO gl_btchID;
  msgs :=  'End of Day Process - Overdraft Accrued Interest Deduction Accounting GL Batch ID= ' ||
          trim(to_char(gl_btchID, '999999999999999999999999999999999999999999'));
          updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  msgs := 'End of Day Process - Overdraft Accrued Interest Deduction Accounting GL Batch Name= ''End of Day Process - Overdraft Accrued Interest Deduction Accounting (' ||
         cur_sod_date
         || ')''';
         updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

  --OVERDRAFT
  /*8. ACCRUE PRINCIPAL AND/INTEREST FOR ALL RUNNING ODS WHERE SCHEDULE DATE IS DUE*/
  FOR rowOD IN (
		SELECT distinct -1 mnlpymnt_ovdrft_hdr_id, 
			mcf.get_ovdrft_accrd_bal(b.loan_rqst_id) ttl_amount_paid,
			mcf.get_cstacct_gl_liablty_acct_id(repayment_account_id) gl_repayment_account_id, 'D',
			org.get_accnt_id_brnch_eqv(b.branch_id, c.interest_revenue_acct_id) interest_revenue_acct_id, 'I',
			d.crncy_id, 
			-1 mnlpymnt_ovdrft_hdr_id,
			'Overdraft Interest transaction for Overdraft Request No. '||b.trnsctn_id||' for Customer '||mcf.get_customer_name(b.cust_type, b.cust_id) trns_desc, 'AUTOMATIC OVERDRAFT INTEREST PAYMENT',
			mcf.get_ovdrft_accrd_bal(b.loan_rqst_id) int_accrued, 
			repayment_account_id, 
			y.disbmnt_det_id,
			org.get_accnt_id_brnch_eqv(b.branch_id, c.deferred_interest_acct_id) gl_deferred_interest_acct_id, 'D',
			org.get_accnt_id_brnch_eqv(b.branch_id, c.interest_rcvbl_acct_id) gl_interest_rcvbl_acct_id, 'D',
			b.loan_rqst_id, 
			b.branch_id, 
			b.trnsctn_id
		FROM mcf.mcf_loan_request b, mcf.mcf_prdt_loans c,
			mcf.mcf_currencies d, mcf.mcf_loan_disbursement_hdr x, mcf.mcf_loan_disbursement_det y
		WHERE b.loan_product_id = c.loan_product_id
			AND c.currency_id = d.crncy_id AND x.disbmnt_hdr_id = y.disbmnt_hdr_id
			AND y.loan_rqst_id = b.loan_rqst_id and x.status != 'Void' AND y.principal_amount > 0
			AND mcf.get_ovdrft_accrd_bal(b.loan_rqst_id) > 0
			ORDER BY b.loan_rqst_id)
  LOOP

    SELECT mapped_lov_crncy_id :: BIGINT
    INTO cur_ID
    FROM mcf.mcf_currencies
    WHERE crncy_id = rowOD.crncy_id;

	
      --CREATE ACCOUNTING FOR INTEREST REVENUE
	  tmp_crdt := 0;
	  tmp_dbt := rowOD.int_accrued;
	  tmp_net := tmp_dbt;
	  tmp_dbt_crdt := 'D';

	IF tmp_dbt != 0  
	THEN
      INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                             dbt_amount, trnsctn_date,
                                             func_cur_id, created_by, creation_date, batch_id,
                                             crdt_amount,
                                             last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                             entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                             func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                             is_reconciled)
      VALUES
        (rowOD.gl_repayment_account_id, rowOD.trns_desc|| ' - Interest Revenue',
                                       tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
                                       tday_dte,
                                       gl_btchID,
                                       tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                               tmp_net,
                                                               cur_ID,
                                                               tmp_net,
                                                               cur_ID,
                                                               1,
                                                               1,
                                                               tmp_dbt_crdt,
         '',
         '1');


      tmp_crdt := rowOD.int_accrued;
      tmp_dbt :=0;
      tmp_net := tmp_crdt;
      tmp_dbt_crdt := 'C';

      INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                             dbt_amount, trnsctn_date,
                                             func_cur_id, created_by, creation_date, batch_id,
                                             crdt_amount,
                                             last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                             entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                             func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                             is_reconciled)
      VALUES
        (rowOD.interest_revenue_acct_id, rowOD.trns_desc|| ' - Interest Revenue',
                                         tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
                                         tday_dte,
                                         gl_btchID,
                                         tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                                 tmp_net,
                                                                 cur_ID,
                                                                 tmp_net,
                                                                 cur_ID,
                                                                 1,
                                                                 1,
                                                                 tmp_dbt_crdt,
         '',
         '1');
	  
    END IF;
	
	--CREATE ACCOUNTING FOR DEFERRED INTEREST
	tmp_crdt := 0;
	tmp_dbt := rowOD.int_accrued;
	tmp_net := tmp_dbt;
	tmp_dbt_crdt := 'D';

	IF tmp_dbt != 0  
	THEN
      INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                             dbt_amount, trnsctn_date,
                                             func_cur_id, created_by, creation_date, batch_id,
                                             crdt_amount,
                                             last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                             entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                             func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                             is_reconciled)
      VALUES
        (rowOD.gl_deferred_interest_acct_id, rowOD.trns_desc|| ' - Deferred Interest Balance',
                                       tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
                                       tday_dte,
                                       gl_btchID,
                                       tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                               tmp_net,
                                                               cur_ID,
                                                               tmp_net,
                                                               cur_ID,
                                                               1,
                                                               1,
                                                               tmp_dbt_crdt,
         '',
         '1');


      tmp_crdt := rowOD.int_accrued;
      tmp_dbt :=0;
      tmp_net := tmp_crdt;
      tmp_dbt_crdt := 'C';

      INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                             dbt_amount, trnsctn_date,
                                             func_cur_id, created_by, creation_date, batch_id,
                                             crdt_amount,
                                             last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                             entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                             func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                             is_reconciled)
      VALUES
        (rowOD.gl_interest_rcvbl_acct_id, rowOD.trns_desc|| ' - Deferred Interest Balance',
                                         tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1,
                                         tday_dte,
                                         gl_btchID,
                                         tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                                 tmp_net,
                                                                 cur_ID,
                                                                 tmp_net,
                                                                 cur_ID,
                                                                 1,
                                                                 1,
                                                                 tmp_dbt_crdt,
         '',
         '1');
	  
    END IF;
	
	
      --CREATE CUSTOMER ACCOUNT document RECORD
      SELECT
        b.account_id,
        b.status,
        b.account_title,
        mcf.get_cstacnt_lien_bals(b.account_id, cur_sod_date),
        b.mandate,
        e.withdrawal_limit_no,
        e.withdrawal_limit_amount,
        e.withdrawal_limit,
        b.account_number
      INTO ai_account_id, ai_status, ai_account_title, ai_lien_bal, ai_mandate, ai_limit_no, ai_limit_amnt, ai_withdrawal_limit,
        ai_account_number
      FROM mcf.mcf_accounts b
        LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
        LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
      WHERE ((b.account_id = rowOD.repayment_account_id));

	 
	 PERFORM mcf.createAccountTrns(rowOD.repayment_account_id, tday_dte, 'Paperless',
                                      'FT-WTH-' || v_trns_tm,
                                      'OVERDRAFT ACCRUED INTEREST PAYMENT for OD Request '||rowOD.trnsctn_id, 'DR', rowOD.int_accrued,
                                      'WITHDRAWAL',
                                      rowOD.int_accrued, 'Self', '', '', '', '', '',
                                      'FT-WTH-' || v_trns_tm,
                                      'Paid', -1, '', '', rowOD.crncy_id, 1, ai_status, ai_account_title,
                                      ai_lien_bal, ai_mandate,
                                      ai_limit_no, ai_limit_amnt, ai_withdrawal_limit, '0', -1, -1, rowOD.branch_id,
                                      $3, $1, cur_sod_date);

      --CREATE DAILY BALANCE RECORD
      BEGIN
		PERFORM mcf.update_cstmracnt_balances_ovdrft(rowOD.repayment_account_id, rowOD.int_accrued,
                                               0.00, 0.00, '',
                                               cur_sod_date, 'D', 'FT-WTH-', '', $1, tday_dte);
	  
        EXCEPTION
        WHEN OTHERS
          THEN
            RETURN 'FAILURE' || chr(10) || SQLSTATE || chr(10) || SQLERRM;
      END;
	  
	  
	  --UPDATE ACCRUED INTEREST TABLE 
	  SELECT mcf.update_od_acrued_interest_table(rowOD.disbmnt_det_id, rowOD.int_accrued, $1, tday_dte) INTO v_od_update_rslt;
	  
	  
	  cnta3 := cnta3 + 1;
  END LOOP;

  
  IF cnta3 > 0
  THEN
    msgs :=  'Successfully Created ' || trim(to_char(cnta3, '99999999999999999999999999999999999')) ||
            ' Overdraft Interest Accrual Transaction(s)!'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
            updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  ELSE
    --DELETE HEADER
    DELETE FROM accb.accb_trnsctn_batches
    WHERE batch_id = gl_btchID;
    msgs := 'Deleted OD Interest Accrual GL Batch Header Successfully'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  END IF;

    
    
    msgs :=  'Starting Interest and Accrual Processes....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
    
    SELECT to_char(now(), 'YYYYMMDDHH24MISS') INTO v_trns_tm;

    SELECT mcf.getdb_incrmntl_datetime_ymdhms(v_trns_tm) INTO v_trns_tm;
    
    gl_btchID = -1;
    IF gl_btchID <= 0
    THEN
      INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date,
                                             org_id, batch_status, last_update_by, last_update_date, batch_source)
      VALUES
        ('Interest accrual Process (' || cur_sod_date || ')-' || v_trns_tm,
         'Interest accrual Process (' || cur_sod_date || ')-' || v_trns_tm,
         $1, tday_dte, $3, '0', $1, tday_dte, 'Interest accrual Process');
      --COMMIT;
    END IF;

    SELECT COALESCE(accb.get_TodysBatch_id('Interest accrual Process (' || cur_sod_date, $3), -1)
    INTO gl_btchID;
    msgs :=  'Interest accrual Process GL Batch ID= ' ||
            trim(to_char(gl_btchID, '999999999999999999999999999999999999999999'));
            updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
    msgs := 'Interest accrual Process GL Batch Name= ''Interest accrual Process (' || cur_sod_date
    || ')''';
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

    v_ttl_intrst_accrued := 0;

    --ACCOUNT
    /**ACCOUNT TRANSACTIONS **/
    FOR rowAccts IN (SELECT
                       b.account_title,
                       b.account_id,
                       b.branch_id,
                       coalesce(interest_rate, 0)                             interest_rate,
                       c.interest_accrual_frequency,
                       c.interest_calc_method,
                       interest_crediting_period,
                       interest_crediting_type,
                       e.crncy_id,
                       account_number,
                       c.svngs_product_id,
                       daily_minbal_for_interest,
                       mcf.get_cstacnt_avlbl_bals(b.account_id, cur_sod_date) dly_bal,
                       sec.get_usr_prsn_id(b.created_by)                      prsn_id
                     FROM
                       mcf.mcf_accounts b INNER JOIN mcf.mcf_prdt_savings c ON (b.product_type_id = c.svngs_product_id)
                       LEFT OUTER JOIN mcf.mcf_prdt_savings_stdevnt_accntn d
                         ON (c.svngs_product_id = d.svngs_product_id)
                       LEFT OUTER JOIN mcf.mcf_currencies e ON (c.currency_id = e.crncy_id)
                     WHERE UPPER(c.charge_interest) = 'YES' AND UPPER(b.status) = 'AUTHORIZED' AND
                           account_type IN ('Current', 'Savings', 'Susu') AND UPPER(account_status) != 'CLOSED'
                           AND mcf.get_cstacnt_avlbl_bals(b.account_id, cur_sod_date) > 0
                           AND mcf.get_cstacnt_avlbl_bals(b.account_id, cur_sod_date) > daily_minbal_for_interest
                     ORDER BY 3, 2)
    LOOP

       --RAISE NOTICE 'Query = "%" ',1;
      --B. CHECK ACCRUAL FREQUENCY => IF 'Monthly' GET ACCOUNT AND ACCRUE
      IF UPPER(rowAccts.interest_accrual_frequency) = 'MONTHLY'
      THEN
        SELECT mapped_lov_crncy_id :: BIGINT
        INTO cur_ID
        FROM mcf.mcf_currencies
        WHERE crncy_id = rowAccts.crncy_id;

        SELECT to_char((select (to_date((SELECT SUBSTR(mcf.xx_get_start_of_day_date($3),1,7))||'-01','YYYY-MM-DD') + interval '1 month' - interval '1 day')),'DD')::NUMERIC INTO v_ttl_mnth_no;

        --DR
        tmp_crdt := 0;
        /*SELECT mcf.xx_calc_daily_savings_interest(mcf.get_cstacnt_avlbl_bals(rowAccts.account_id, cur_sod_date),
                                                  rowAccts.interest_rate)
        INTO v_daily_intrst_val;*/

        SELECT SUM(COALESCE(interest_earned,0)) INTO v_daily_intrst_val
        FROM mcf.mcf_daily_acct_bals_n_interest
	WHERE account_id = rowAccts.account_id
	AND UPPER(is_interest_paid) = 'NO'
	AND UPPER(COALESCE(is_interest_accrued,'')) != 'YES';

        tmp_dbt := round(v_daily_intrst_val,2); --(v_daily_intrst_val * v_ttl_mnth_no);
        tmp_net := tmp_dbt;
        tmp_dbt_crdt := 'D';

        IF tmp_dbt > 0
        THEN
          INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                                 dbt_amount, trnsctn_date,
                                                 func_cur_id, created_by, creation_date, batch_id,
                                                 crdt_amount,
                                                 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                                 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                                 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                                 is_reconciled)
          VALUES
            ((SELECT org.get_accnt_id_brnch_eqv(rowAccts.branch_id, (SELECT mcf.get_svngs_prdt_acct_id(rowAccts.svngs_product_id,
                                                                                           'INTEREST ACCRUAL',
                                                                                           'DR')))),
              'Interest expense for Account no ' || rowAccts.account_number,
              tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1, tday_dte, gl_btchID,
              tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                      tmp_net,
                                      cur_ID,
                                      tmp_net,
                                      cur_ID,
                                      1,
                                      1,
                                      tmp_dbt_crdt,
             '',
             '1');

          --CR
          tmp_dbt := 0;
          /*SELECT mcf.xx_calc_daily_savings_interest(mcf.get_cstacnt_avlbl_bals(rowAccts.account_id, cur_sod_date),
                                                    rowAccts.interest_rate)
          INTO v_daily_intrst_val;*/

          tmp_crdt := round(v_daily_intrst_val,2);--(v_daily_intrst_val * v_ttl_mnth_no);
          
          tmp_net := tmp_crdt;
          tmp_dbt_crdt := 'C';

          INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc, dbt_amount, trnsctn_date,
                                                 func_cur_id, created_by, creation_date, batch_id, crdt_amount,
                                                 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                                 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                                 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                                 is_reconciled)
          VALUES
            ((SELECT org.get_accnt_id_brnch_eqv(rowAccts.branch_id, (SELECT mcf.get_svngs_prdt_acct_id(rowAccts.svngs_product_id,
                                                                                            'INTEREST ACCRUAL',
                                                                                            'CR')))),
              'Interest accrual for Account no ' || rowAccts.account_number,
              tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1, tday_dte, gl_btchID,
              tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                      tmp_net,
                                      cur_ID,
                                      tmp_net,
                                      cur_ID,
                                      1,
                                      1,
                                      tmp_dbt_crdt,
              '',
              '1');

          --msgs := msgs || chr(10) || 'Interest accrual for Account no ' || rowAccts.account_number || ' is ' || tmp_crdt;
	  v_ttl_intrst_accrued := v_ttl_intrst_accrued + tmp_crdt;
	  
          cnta1 := cnta1 + 1;
        END IF;
      END IF;

    END LOOP;

    
    IF cnta1 > 0
    THEN
      msgs :=  'Successfully Created ' || trim(to_char(cnta1, '99999999999999999999999999999999999'))
              ||
              ' Interest Transaction(s)! Total Amount is GHS'||v_ttl_intrst_accrued||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
              updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
    ELSE
      --DELETE HEADER
      DELETE FROM accb.accb_trnsctn_batches
      WHERE batch_id = gl_btchID;
      msgs :=  'Deleted Account GL Batch Header Successfully'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
      updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
    END IF;


    
    msgs :=  'Starting Interest Expense Payment Processes....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
    
    cnta1 := 0;
    gl_btchID = -1;
    IF gl_btchID <= 0
    THEN
      INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date,
                                             org_id, batch_status, last_update_by, last_update_date, batch_source)
      VALUES
        ('Interest Payment Processing (' || cur_sod_date || ')-' || v_trns_tm,
         'Interest Payment Processing (' || cur_sod_date || ')-' || v_trns_tm,
         $1, tday_dte, $3, '0', $1, tday_dte, 'Interest Payment Processing');
      --COMMIT;
    END IF;

    SELECT COALESCE(accb.get_TodysBatch_id('Interest Payment Processing (' || cur_sod_date, $3), -1)
    INTO gl_btchID;
    msgs :=  'Interest Payment Processing GL Batch ID= ' ||
            trim(to_char(gl_btchID, '999999999999999999999999999999999999999999'));
            updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
    msgs := 'Interest Payment Processing GL Batch Name= ''Interest Payment Processing (' || cur_sod_date
    || ')''';
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);


    --LOOP THROUGH INTEREST CREDITING DATES TABLE AND COMPARE LAST CREDITING DATE WITH TODAY
    --SELECT EXTRACT(year FROM age(now(),cast('2017-11-19' AS DATE)))*12 + EXTRACT(month FROM age(now(),cast('2017-11-19' AS DATE)))::INTEGER
    SELECT count(*) INTO v_intprcn_cnt
                             FROM mcf.mcf_accounts a, mcf.mcf_prdt_savings b
                             WHERE a.product_type_id = b.svngs_product_id
                                   AND UPPER(a.status) = 'AUTHORIZED' AND
                                   account_type IN ('Current', 'Savings', 'Susu') AND UPPER(account_status) != 'CLOSED'
                                   AND b.charge_interest = 'YES' /*AND b.interest_crediting_type = 'Automatic'*/
                                   AND EXISTS (SELECT 1 FROM mcf.mcf_daily_acct_bals_n_interest WHERE account_id = a.account_id AND upper(is_interest_paid) = 'NO');

     msgs :=  'Starting to process Interest Expense Payment for '||v_intprcn_cnt||' Customer Accounts @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
     updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);     
    
    FOR rowAcctsIntCrdtn IN (SELECT
                               a.account_id,
                                COALESCE(NULLIF(a.last_interest_crdtn_date,''),'2000-01-01') last_interest_crdtn_date,
                               b.interest_crediting_type,
                               b.interest_crediting_period,
                               b.charge_interest,
                               b.currency_id,
                               a.branch_id,
                               a.account_number
                             FROM mcf.mcf_accounts a, mcf.mcf_prdt_savings b
                             WHERE a.product_type_id = b.svngs_product_id
                                   AND UPPER(a.status) = 'AUTHORIZED' AND
                                   account_type IN ('Current', 'Savings', 'Susu') AND UPPER(account_status) != 'CLOSED'
                                   AND b.charge_interest = 'YES' /*AND b.interest_crediting_type = 'Automatic'*/
                                   AND EXISTS (SELECT 1 FROM mcf.mcf_daily_acct_bals_n_interest WHERE account_id = a.account_id AND upper(is_interest_paid) = 'NO')
                             ORDER BY 1)
    LOOP

      --cnta8 := 0;
      SELECT mcf.get_age_part(substr(rowAcctsIntCrdtn.last_interest_crdtn_date, 1, 10), 'year')
      INTO v_year_part;
      SELECT mcf.get_age_part(substr(rowAcctsIntCrdtn.last_interest_crdtn_date, 1, 10), 'month')
      INTO v_mnth_part;
      SELECT mcf.get_age_part(substr(rowAcctsIntCrdtn.last_interest_crdtn_date, 1, 10), 'day')
      INTO v_day_part;

      IF rowAcctsIntCrdtn.interest_crediting_period = 'monthly'
      THEN
        --RAISE NOTICE 'Monthly = "%"', 'Monthly';
        IF rowAcctsIntCrdtn.last_interest_crdtn_date = '2000-01-01' OR v_year_part > 0 OR v_mnth_part >= 1 OR
           (v_mnth_part = 0 AND v_day_part >= 21)
        THEN
        
	  v_intprcn_rec := v_intprcn_rec + 1;
	  msgs :=  'RECORD '||v_intprcn_rec||', Account Number '||rowAcctsIntCrdtn.account_number||'. RECORDS REMAINING: '||(v_intprcn_cnt-v_intprcn_rec)||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
	  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
		
          SELECT
            mcf.xx_process_interest_pymnt_svngs_automatic($1, cur_sod_date, $3, rowAcctsIntCrdtn.currency_id, rowAcctsIntCrdtn.branch_id, 'AUTOMATIC', -1, rowAcctsIntCrdtn.account_id, gl_btchID)
          INTO v_intprcsn_status;

          --RAISE NOTICE 'Monthly = "%"', 'Success';

          IF v_intprcsn_status != 'SUCCESS'
          THEN
            msgs := v_intprcsn_status;
            updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
            --msgs:=rpt.getLogMsg($4);
            

            RETURN msgs;
          ELSE
		cnta1 :=  cnta1 + 1;
          END IF;

        END IF;
      ELSIF rowAcctsIntCrdtn.interest_crediting_period = 'every2months'
        THEN
        --RAISE NOTICE 'every2months = "%"', 'every2months';
          IF rowAcctsIntCrdtn.last_interest_crdtn_date = '2000-01-01'
          THEN
            --GET DATE OF FIRST INTEREST
            SELECT count(*)
            INTO cnta5
            FROM mcf.mcf_daily_acct_bals_n_interest
            WHERE account_id = rowAcctsIntCrdtn.account_id
                  AND upper(is_interest_paid) = 'NO';

            IF cnta5 > 0
            THEN
              SELECT MIN(bal_date)
              INTO v_int_bal_date
              FROM mcf.mcf_daily_acct_bals_n_interest
              WHERE account_id = rowAcctsIntCrdtn.account_id
                    AND upper(is_interest_paid) = 'NO';
            END IF;

            IF v_int_bal_date != ''
            THEN
              SELECT mcf.get_age_part(substr(v_int_bal_date, 1, 10), 'year')
              INTO v_year_part;
              SELECT mcf.get_age_part(substr(v_int_bal_date, 1, 10), 'month')
              INTO v_mnth_part;
              SELECT mcf.get_age_part(substr(v_int_bal_date, 1, 10), 'day')
              INTO v_day_part;
            END IF;
          END IF;

          IF v_year_part > 0 OR v_mnth_part >= 2 OR (v_mnth_part = 1 AND v_day_part >= 28)
          THEN
            SELECT
              mcf.xx_process_interest_pymnt_svngs_automatic($1, cur_sod_date, $3, rowAcctsIntCrdtn.currency_id, rowAcctsIntCrdtn.branch_id, 'AUTOMATIC', -1, rowAcctsIntCrdtn.account_id, gl_btchID)
            INTO v_intprcsn_status;

	--RAISE NOTICE 'every2months = "%"', v_intprcsn_status;

            IF v_intprcsn_status != 'SUCCESS'
            THEN
              msgs :=  v_intprcsn_status;
              updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
              --msgs:=rpt.getLogMsg($4);

              RETURN msgs;
            ELSE
		cnta1 :=  cnta1 + 1;
            END IF;
          END IF;
      ELSIF rowAcctsIntCrdtn.interest_crediting_period = 'quarterly'
        THEN
          IF rowAcctsIntCrdtn.last_interest_crdtn_date = '2000-01-01'
          THEN
             --RAISE NOTICE 'quarterly = "%"', 'quarterly1';
            --GET DATE OF FIRST INTEREST
            SELECT count(*)
            INTO cnta5
            FROM mcf.mcf_daily_acct_bals_n_interest
            WHERE account_id = rowAcctsIntCrdtn.account_id
                  AND upper(is_interest_paid) = 'NO';

                  --RAISE NOTICE 'quarterly count = "%"', cnta5;

            IF cnta5 > 0
            THEN
              SELECT MIN(bal_date)
              INTO v_int_bal_date
              FROM mcf.mcf_daily_acct_bals_n_interest
              WHERE account_id = rowAcctsIntCrdtn.account_id
                    AND upper(is_interest_paid) = 'NO';
            END IF;

            --RAISE NOTICE 'v_int_bal_date  = "%"', v_int_bal_date;

            IF v_int_bal_date != ''
            THEN
              SELECT mcf.get_age_part(substr(v_int_bal_date, 1, 10), 'year')
              INTO v_year_part;
              SELECT mcf.get_age_part(substr(v_int_bal_date, 1, 10), 'month')
              INTO v_mnth_part;
              SELECT mcf.get_age_part(substr(v_int_bal_date, 1, 10), 'day')
              INTO v_day_part;
            END IF;
          END IF;

          --RAISE NOTICE 'v_year_DATE  = "%"', v_year_part||'-'||v_mnth_part||'-'||v_day_part;

          IF v_year_part > 0 OR v_mnth_part >= 2 OR (v_mnth_part = 2 AND v_day_part >= 28) -- CHANGE v_mnth_part >= 2 TO >= 3
          THEN
          --RAISE NOTICE 'process account_id = "%"', rowAcctsIntCrdtn.account_id||'-'||cur_sod_date||'-'||gl_btchID;
            SELECT
              mcf.xx_process_interest_pymnt_svngs_automatic($1, cur_sod_date, $3, rowAcctsIntCrdtn.currency_id, rowAcctsIntCrdtn.branch_id, 'AUTOMATIC', -1, rowAcctsIntCrdtn.account_id, gl_btchID)
            INTO v_intprcsn_status;

	--RAISE NOTICE 'quarterly = "%"', v_intprcsn_status;

            IF v_intprcsn_status != 'SUCCESS'
            THEN
              msgs :=  v_intprcsn_status;
              updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
              --msgs:=rpt.getLogMsg($4);

              RETURN msgs;
            ELSE
		cnta1 :=  cnta1 + 1;
            END IF;
          END IF;
      ELSIF rowAcctsIntCrdtn.interest_crediting_period = 'semi-anually'
        THEN
          IF rowAcctsIntCrdtn.last_interest_crdtn_date = '2000-01-01'
          THEN
            --GET DATE OF FIRST INTEREST
            SELECT count(*)
            INTO cnta5
            FROM mcf.mcf_daily_acct_bals_n_interest
            WHERE account_id = rowAcctsIntCrdtn.account_id
                  AND upper(is_interest_paid) = 'NO';

            IF cnta5 > 0
            THEN
              SELECT MIN(bal_date)
              INTO v_int_bal_date
              FROM mcf.mcf_daily_acct_bals_n_interest
              WHERE account_id = rowAcctsIntCrdtn.account_id
                    AND upper(is_interest_paid) = 'NO';
            END IF;

            IF v_int_bal_date != ''
            THEN
              SELECT mcf.get_age_part(substr(v_int_bal_date, 1, 10), 'year')
              INTO v_year_part;
              SELECT mcf.get_age_part(substr(v_int_bal_date, 1, 10), 'month')
              INTO v_mnth_part;
              SELECT mcf.get_age_part(substr(v_int_bal_date, 1, 10), 'day')
              INTO v_day_part;
            END IF;
          END IF;

          IF v_year_part > 0 OR v_mnth_part >= 6 OR (v_mnth_part = 5 AND v_day_part >= 28)
          THEN
            SELECT
              mcf.xx_process_interest_pymnt_svngs_automatic($1, cur_sod_date, $3, rowAcctsIntCrdtn.currency_id, rowAcctsIntCrdtn.branch_id, 'AUTOMATIC', -1, rowAcctsIntCrdtn.account_id, gl_btchID)
            INTO v_intprcsn_status;

            IF v_intprcsn_status != 'SUCCESS'
            THEN
              msgs :=  v_intprcsn_status;
              updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
              --msgs:=rpt.getLogMsg($4);

              RETURN msgs;
            ELSE
		cnta1 :=  cnta1 + 1;
            END IF;
          END IF;

      ELSIF rowAcctsIntCrdtn.interest_crediting_period = 'annually'
        THEN
          IF rowAcctsIntCrdtn.last_interest_crdtn_date = '2000-01-01'
          THEN
            --GET DATE OF FIRST INTEREST
            SELECT count(*)
            INTO cnta5
            FROM mcf.mcf_daily_acct_bals_n_interest
            WHERE account_id = rowAcctsIntCrdtn.account_id
                  AND upper(is_interest_paid) = 'NO';

            IF cnta5 > 0
            THEN
              SELECT MIN(bal_date)
              INTO v_int_bal_date
              FROM mcf.mcf_daily_acct_bals_n_interest
              WHERE account_id = rowAcctsIntCrdtn.account_id
                    AND upper(is_interest_paid) = 'NO';
            END IF;

            IF v_int_bal_date != ''
            THEN
              SELECT mcf.get_age_part(substr(v_int_bal_date, 1, 10), 'year')
              INTO v_year_part;
              SELECT mcf.get_age_part(substr(v_int_bal_date, 1, 10), 'month')
              INTO v_mnth_part;
              SELECT mcf.get_age_part(substr(v_int_bal_date, 1, 10), 'day')
              INTO v_day_part;
            END IF;
          END IF;

          IF v_year_part > 0 OR v_mnth_part >= 12 OR (v_mnth_part = 11 AND v_day_part >= 28)
          THEN
            SELECT
              mcf.xx_process_interest_pymnt_svngs_automatic($1, cur_sod_date, $3, rowAcctsIntCrdtn.currency_id, rowAcctsIntCrdtn.branch_id, 'AUTOMATIC', -1, rowAcctsIntCrdtn.account_id, gl_btchID)
            INTO v_intprcsn_status;

            IF v_intprcsn_status != 'SUCCESS'
            THEN
              msgs := v_intprcsn_status;
              updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
              --msgs:=rpt.getLogMsg($4);

              RETURN msgs;
            ELSE
		cnta1 :=  cnta1 + 1;
            END IF;
          END IF;
      END IF;
    END LOOP;

        
    msgs :=  'Ending Interest Expense Payment Processes....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

    	  IF cnta1 > 0
	  THEN
	    msgs :=  'Successfully Created ' || trim(to_char(cnta1, '99999999999999999999999999999999999')) ||
		    ' Interest Expense Payment Transaction(s)!'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
		    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
	  ELSE
	    --DELETE HEADER
	    DELETE FROM accb.accb_trnsctn_batches
	    WHERE batch_id = gl_btchID;
	    msgs := 'Deleted Interest Expense Payment GL Batch Header Successfully'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
	    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
	  END IF;

    

    --COMMISSION ON TURNOVER
    --SELECT mcf.get_cstacnt_avlbl_bals(b.account_id, cur_sod_date);
    SELECT mcf.getdb_incrmntl_datetime_ymdhms(v_trns_tm) INTO v_trns_tm;
    gl_btchID := -1;
    cnta9  := 0;
    
    msgs :=  'Processing Commission on Turnover....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

    IF gl_btchID <= 0
    THEN
      INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date,
                                             org_id, batch_status, last_update_by, last_update_date, batch_source)
      VALUES
        ('Commission on Turnover Process (' || cur_sod_date || ')-' || v_trns_tm,
         'Commission on Turnover Process (' || cur_sod_date || ')-' || v_trns_tm,
         $1, tday_dte, $3, '0', $1, tday_dte, 'BANKING');
      --COMMIT;
      msgs :=  'Inserting into accb.accb_trnsctn_batches table....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
      updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
    END IF;

    SELECT COALESCE(accb.get_TodysBatch_id('Commission on Turnover Process (' || cur_sod_date, $3), -1)
    INTO gl_btchID;
    msgs := 'Commission on Turnover Process GL Batch ID= ' ||
            trim(to_char(gl_btchID, '999999999999999999999999999999999999999999'));
            updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
    msgs := 'Commission on Turnover Process GL Batch Name= ''Commission on Turnover Process (' ||
    cur_sod_date
    || ')''';
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

    --GET ALL ACCOUNTS WITH PRODUCTS THAT HAS CHARGE_COT SET TO YES
    FOR rowCOT IN (SELECT
                     b.account_title,
                     b.account_id,
                     b.branch_id,
                     e.crncy_id,
                     account_number,
                     cot_free_withdrawals_max,
                     c.svngs_product_id,
                     org.get_accnt_id_brnch_eqv(b.branch_id, d.cot_amnt_flat_crdt_accnt_id) cot_amnt_flat_crdt_accnt_id,
                     mcf.get_cstacnt_avlbl_bals(b.account_id, cur_sod_date) dly_bal,
                     sec.get_usr_prsn_id(b.created_by)                      prsn_id
                   FROM mcf.mcf_accounts b INNER JOIN mcf.mcf_prdt_savings c ON (b.product_type_id = c.svngs_product_id)
                     LEFT OUTER JOIN mcf.mcf_prdt_savings_stdevnt_accntn d ON (c.svngs_product_id = d.svngs_product_id)
                     LEFT OUTER JOIN mcf.mcf_currencies e ON (c.currency_id = e.crncy_id)
                   WHERE 1 = 1 AND UPPER(c.charge_cot) = 'YES'
                         AND UPPER(b.status) = 'AUTHORIZED' AND
                         account_type IN ('Current','Savings','Susu') AND UPPER(account_status) != 'CLOSED'
                         --AND mcf.get_cstacnt_avlbl_bals(b.account_id, cur_sod_date) > 0
                   ORDER BY 3, 2)
    LOOP
      SELECT mcf.getdb_incrmntl_datetime_ymdhms(v_trns_tm) INTO v_trns_tm;
    
      SELECT mcf.get_date_part('day', to_char((date_trunc('MONTH', to_timestamp(cur_sod_date,'YYYY-MM-DD')) + INTERVAL '1 MONTH - 1 day'),
                                              'YYYY-MM-DD')) :: INTEGER
      INTO v_mnth_last_day;
      SELECT SUBSTR(cur_sod_date,6,2) dte /*mcf.get_date_part('month', cur_sod_date)*/
      INTO v_dte_mnth_char;
      SELECT mcf.get_date_part('year', cur_sod_date)
      INTO v_dte_year;

      SELECT TO_CHAR(to_date(substr(cur_sod_date,6,2),'MM'),'MONTH') INTO v_fmtd_month;

      /*SELECT count(*)
      INTO v_mnthly_wdwls
      FROM mcf.mcf_cust_account_transactions a
      WHERE 1 = 1 AND a.account_id = rowCOT.account_id
            AND a.trns_type = 'WITHDRAWAL' AND a.status = 'Paid' AND a.amount > 0
            AND doc_no NOT LIKE 'COT%'
            AND substr(trns_date,1,10) between v_dte_year || '-' || v_dte_mnth || '-' || '01' AND v_dte_year || '-' || v_dte_mnth || '-' || v_mnth_last_day; */

      select mcf.get_ttl_wdwl_count(v_dte_year,v_dte_mnth_char,v_mnth_last_day,rowCOT.account_id)::INTEGER INTO v_mnthly_wdwls;

      msgs :=  ' Withdrawal count for '||rowCOT.account_number||'  is '|| v_mnthly_wdwls ||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
      updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
            

     --RAISE NOTICE 'v_mnthly_wdwls count = "%"',v_mnthly_wdwls;
     --RAISE NOTICE 'rowCOT.cot_free_withdrawals_max count = "%"',rowCOT.cot_free_withdrawals_max;


      --CONDITION TO CHARGE COT
      IF v_mnthly_wdwls > rowCOT.cot_free_withdrawals_max
      THEN
	--GET TOTAL WITHDRAWAL FOR PERIOD
	/*SELECT sum(amount) INTO v_ttl_wdwl FROM mcf.mcf_cust_account_transactions a
	WHERE 1 = 1 AND a.account_id = rowCOT.account_id
            AND a.trns_type = 'WITHDRAWAL' AND a.status = 'Paid' AND a.amount > 0
            AND doc_no NOT LIKE 'COT%'
            AND substr(trns_date,1,10) between v_dte_year || '-' || v_dte_mnth || '-' || '01' AND v_dte_year || '-' || v_dte_mnth || '-' || v_mnth_last_day; */
            --AND substr(trns_date,1,10) between '2018-02-05' AND cur_sod_date; 

        select mcf.get_ttl_wdwl_amount(v_dte_year,v_dte_mnth_char,v_mnth_last_day,rowCOT.account_id) INTO v_ttl_wdwl;

            --RAISE NOTICE 'v_ttl_wdwl = "%"',v_ttl_wdwl;
      
        --CHECK EXISTENCE OF RANGE FOR
        SELECT count(*)
        INTO cnta2
        FROM mcf.mcf_svngs_wthdrwl_comm x
        WHERE x.product_id = rowCOT.svngs_product_id
              AND v_ttl_wdwl BETWEEN x.range_low AND x.range_high;

        IF cnta2 > 0
        THEN
          SELECT
            coalesce(comm_flat, 0),
            coalesce(comm_percent, 0)
          INTO v_fee_flat, v_fee_prcnt
          FROM mcf.mcf_svngs_wthdrwl_comm y
          WHERE y.product_id = rowCOT.svngs_product_id AND v_ttl_wdwl BETWEEN y.range_low AND y.range_high
          ORDER BY y.range_low ASC
          LIMIT 1;

          IF v_fee_flat > 0 OR v_fee_prcnt > 0
          THEN
            v_cmsn_ttl := (v_ttl_wdwl * v_fee_prcnt / 100) + v_fee_flat;
          END IF;

          --DEBIT CUSTOMER ACCOUNT WITH COT CHARGE & CREDIT REVENUE ACCOUNT
          tmp_crdt := 0;
          tmp_dbt := round(v_cmsn_ttl,2);
          tmp_net := tmp_dbt;
          tmp_dbt_crdt := 'D';

          IF tmp_dbt > 0 THEN

          --RAISE NOTICE 'Accounting 1 = "%"',tmp_dbt;

          INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                                 dbt_amount, trnsctn_date,
                                                 func_cur_id, created_by, creation_date, batch_id,
                                                 crdt_amount,
                                                 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                                 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                                 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                                 is_reconciled)
          VALUES
            ((SELECT mcf.get_cstacct_gl_liablty_acct_id(rowCOT.account_id)),
              'Commission on Turnover ' || rowCOT.account_number||' for '||v_fmtd_month||'-'||v_dte_year,
              tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID, $1, tday_dte, gl_btchID,
              tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                      tmp_net,
                                      cur_ID,
                                      tmp_net,
                                      cur_ID,
                                      1,
                                      1,
                                      tmp_dbt_crdt,
             '',
             '1');


          tmp_crdt := round(v_cmsn_ttl,2);
          tmp_dbt :=0;
          tmp_net := tmp_crdt;
          tmp_dbt_crdt := 'C';

          INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc,
                                                 dbt_amount, trnsctn_date,
                                                 func_cur_id, created_by, creation_date, batch_id,
                                                 crdt_amount,
                                                 last_update_by, last_update_date, net_amount, trns_status, source_trns_ids,
                                                 entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id,
                                                 func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number,
                                                 is_reconciled)
          VALUES
            (rowCOT.cot_amnt_flat_crdt_accnt_id, 'Commission on Turnover ' || rowCOT.account_number||' for '||v_fmtd_month||'-'||v_dte_year,
                                                 tmp_dbt, cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()), cur_ID,
                                                 $1,
                                                 tday_dte,
                                                 gl_btchID,
                                                 tmp_crdt, $1, tday_dte, tmp_net, '0', ',',
                                                                         tmp_net,
                                                                         cur_ID,
                                                                         tmp_net,
                                                                         cur_ID,
                                                                         1,
                                                                         1,
                                                                         tmp_dbt_crdt,
             '',
             '1');

             

          --CREATE WITHDRAWAL ACCOUNT TRANSACTION
          SELECT
            b.account_id,
            b.status,
            b.account_title,
            mcf.get_cstacnt_lien_bals(b.account_id, cur_sod_date),
            b.mandate,
            e.withdrawal_limit_no,
            e.withdrawal_limit_amount,
            e.withdrawal_limit,
            b.account_number
          INTO ai_account_id, ai_status, ai_account_title, ai_lien_bal, ai_mandate, ai_limit_no, ai_limit_amnt, ai_withdrawal_limit,
            ai_account_number
          FROM mcf.mcf_accounts b
            LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
            LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
          WHERE ((b.account_id = rowCOT.account_id));

          PERFORM mcf.createAccountTrns(rowCOT.account_id, tday_dte, 'Paperless',
                                        'COT-' || v_trns_tm,
                                        'COT Charge'||' for '||v_fmtd_month||'-'||v_dte_year, 'DR', round(v_cmsn_ttl,2),
                                        'WITHDRAWAL',
                                        round(v_cmsn_ttl,2), 'Self', '', '', '', '', '',
                                        'COT-' || v_trns_tm,
                                        'Paid', -1, '', '', rowCOT.crncy_id, 1, ai_status, ai_account_title,
                                        ai_lien_bal, ai_mandate,
                                        ai_limit_no, ai_limit_amnt, ai_withdrawal_limit, '0', -1, -1,
                                        rowCOT.branch_id, $3, $1, cur_sod_date);

          --CREATE DAILY BALANCE => DECREASE ACCOUNT BALANCE
          PERFORM mcf.update_cstmracnt_balances_ovdrft(rowCOT.account_id, round(v_cmsn_ttl,2), 0.00, 0.00, '',
                                                       cur_sod_date, 'D', 'COT', '', $1,
                                                       cur_sod_date || ' ' || (SELECT mcf.get_crnt_time()));

          cnta9 := cnta9 + 1;

          msgs :=  'Commission for '||rowCOT.account_number||'  is '|| v_cmsn_ttl ||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
          updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

          END IF;


        END IF;

      END IF;
    END LOOP;

    
    msgs :=  'Ending Commission on Turnover Process....'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);

  IF cnta9 > 0
  THEN
    msgs :=  'Successfully Created ' || trim(to_char(cnta9, '99999999999999999999999999999999999')) ||
            ' Commission on Turnover Transaction(s)!'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
            updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  ELSE
    --DELETE HEADER
    DELETE FROM accb.accb_trnsctn_batches
    WHERE batch_id = gl_btchID;
    msgs := 'Deleted Commission on Turnover GL Batch Header Successfully'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  END IF;

    IF prcs_type = 'End of Day + End of Month + End of Year'
    THEN
      NULL;
    END IF;
  END IF;  
  
    updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  --msgs:=rpt.getLogMsg($4);

    
    IF run_type = 'Draft'
    THEN
      msgs :=  'Draft Mode Run Completed Successfully.'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
      --RAISE NOTICE 'FULL Query = "%"','Draft Mode Run Completed Successfully.';
      updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
      --msgs:=rpt.getLogMsg($4);
      
      RETURN 1 / 0;
    ELSE
      msgs :=  'COB Final Mode Run Completed Successfully.'||' @'||to_char(timeofday()::timestamp, 'DD-Mon-YYYY HH24:MI:SS');
      --RAISE NOTICE 'FULL Query = "%"','Draft Mode Run Completed Successfully.';
      updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
    END IF;


  --RAISE NOTICE 'FULL Query = "%" ',msgs;
  updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
  RETURN msgs;

  EXCEPTION
  WHEN OTHERS
    THEN
      msgs :=  SQLSTATE || chr(10) || SQLERRM;
      --RAISE NOTICE 'FULL Query = "%" ','ERROR 1 - '||SQLSTATE || chr(10) || SQLERRM;
      updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
      --msgs:=rpt.getLogMsg($4);
      BEGIN
        UPDATE mcf.mcf_cob_trns_records
        SET cob_status     = 'FAILED', last_update_by = $1,
          last_update_date = tday_dte
        WHERE cob_record_id = p_cob_record_id;
      END;

      RETURN msgs;
      RAISE NOTICE 'FULL Query = "%" ',msgs;
  WHEN NO_DATA_FOUND
    THEN
      msgs := SQLSTATE || chr(10) || SQLERRM;
      --RAISE NOTICE 'FULL Query = "%"','ERROR 2'||SQLSTATE || chr(10) || SQLERRM;
      updtMsg := rpt.updateRptLogMsg(msgid, msgs, cur_sod_date, $1);
      --msgs:=rpt.getLogMsg($4);
      BEGIN
        UPDATE mcf.mcf_cob_trns_records
        SET cob_status     = 'FAILED', last_update_by = $1,
          last_update_date = tday_dte
        WHERE cob_record_id = p_cob_record_id;
      END;
      RAISE NOTICE 'FULL Query = "%" ',msgs;
      RETURN msgs;
	
END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION mcf.mcf_run_end_of_day(integer, character varying, integer, bigint, character varying)
  OWNER TO postgres;
