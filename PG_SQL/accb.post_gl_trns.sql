CREATE OR REPLACE FUNCTION accb.istransprmttd(
	p_org_id integer,
	p_accntid integer,
	p_trnsdate character varying,
	p_amnt numeric)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
<< outerblock >>
DECLARE
	v_res character varying(1) := '0';
	v_cnt bigint :=0;
	trnsDte timestamp;
	dte1 timestamp;
	dte1Or timestamp;
	dte2 timestamp;
	prdHdrID bigint := - 1;
	noTrnsDatesLov character varying(200) := '';
	noTrnsDayLov character varying(200) := '';
	actvBdgtID bigint := - 1;
	amntLmt numeric := 0;
	bdte1 timestamp;
	bdte2 timestamp;
	crntBals numeric := 0;
	actn character varying(200) := '';
BEGIN
	IF coalesce(p_accntID, - 1) <= 0 THEN
		RETURN 'ERROR:Account Number cannot be empty!';
	END IF;
	IF p_trnsdate = '' THEN
		RETURN 'ERROR:Transaction Date cannot be empty!';
	END IF;

	SELECT COUNT(accnt_id) 
		INTO v_cnt
	FROM accb.accb_chart_of_accnts
	WHERE accnt_id= p_accntID AND org_id=p_org_id;

	IF coalesce(v_cnt, - 1) <= 0 THEN
		RETURN 'ERROR:Account Number must exist in the Current Organization!';
	END IF;
	trnsDte := to_timestamp(p_trnsdate, 'DD-Mon-YYYY HH24:MI:SS');
	dte1 := to_timestamp(accb.getLtstPrdStrtDate (), 'DD-Mon-YYYY HH24:MI:SS');
	dte1Or := to_timestamp(accb.getLastPrdClseDate (p_org_id), 'DD-Mon-YYYY HH24:MI:SS');
	dte2 := to_timestamp(accb.getLtstPrdEndDate (), 'DD-Mon-YYYY HH24:MI:SS');

	/*IF (trnsDte <= dte1Or)
	 THEN
	 RETURN 'ERROR:Transaction Date cannot be On or Before ' || to_char(dte1Or, 'DD-Mon-YYYY HH24:MI:SS');
	 END IF;
	 IF (trnsDte < dte1)
	 THEN
	 RETURN 'ERROR:Transaction Date cannot be before ' || to_char(dte1, 'DD-Mon-YYYY HH24:MI:SS');
	 END IF;
	 IF (trnsDte > dte2)
	 THEN
	 RETURN 'ERROR:Transaction Date cannot be after ' || to_char(dte2, 'DD-Mon-YYYY HH24:MI:SS');
	 END IF;*/
	--Check if trnsDate exists in an Open Period
	prdHdrID := accb.getPrdHdrID (p_org_id);
	IF (prdHdrID > 0) THEN
		IF (accb.getTrnsDteOpenPrdLnID (prdHdrID, to_char(trnsDte, 'YYYY-MM-DD HH24:MI:SS')) < 0) THEN
			RETURN 'ERROR:Cannot use a Transaction Date (' || to_char(trnsDte, 'DD-Mon-YYYY HH24:MI:SS') || ') which does not exist in any OPEN period!';
		END IF;
		--Check if Date is not in Disallowed Dates
		noTrnsDatesLov := gst.getGnrlRecNm ('accb.accb_periods_hdr', 'periods_hdr_id', 'no_trns_dates_lov_nm', prdHdrID);
		noTrnsDayLov := gst.getGnrlRecNm ('accb.accb_periods_hdr', 'periods_hdr_id', 'no_trns_wk_days_lov_nm', prdHdrID);
		IF (noTrnsDatesLov != '') THEN
			IF (gst.getEnbldPssblValID (UPPER(to_char(trnsDte, 'DD-Mon-YYYY')), gst.getEnbldLovID (noTrnsDatesLov)) > 0) THEN
				RETURN 'ERROR:Transactions on this Date (' || to_char(trnsDte, 'DD-Mon-YYYY HH24:MI:SS') || ') have been banned on this system!';
			END IF;
		END IF;
		--Check if Day of Week is not in Disaalowed days
		IF (noTrnsDatesLov != '') THEN
			IF (gst.getEnbldPssblValID (upper(to_char(trnsDte, 'DAY')), gst.getEnbldLovID (noTrnsDayLov)) > 0) THEN
				RETURN 'ERROR:Transactions on this Day of Week (' || to_char(trnsDte, 'DAY') || ') have been banned on this system!';
			END IF;
		END IF;
	END IF;
	--//Amount must not disobey budget settings on that account
	actvBdgtID := accb.getActiveBdgtID (p_org_id);
	amntLmt := accb.getAcntsBdgtdAmnt1 (actvBdgtID, p_accntID, to_char(trnsDte, 'DD-Mon-YYYY HH24:MI:SS'));
	bdte1 := to_timestamp(accb.getAcntsBdgtStrtDte (actvBdgtID, p_accntID, to_char(trnsDte, 'DD-Mon-YYYY HH24:MI:SS')), 'DD-Mon-YYYY HH24:MI:SS');
	bdte2 := to_timestamp(accb.getAcntsBdgtEndDte (actvBdgtID, p_accntID, to_char(trnsDte, 'DD-Mon-YYYY HH24:MI:SS')), 'DD-Mon-YYYY HH24:MI:SS');
	crntBals := accb.getTrnsSum (p_accntID, to_char(bdte1, 'DD-Mon-YYYY HH24:MI:SS'), to_char(bdte2, 'DD-Mon-YYYY HH24:MI:SS'), '1');
	actn := accb.getAcntsBdgtLmtActn (actvBdgtID, p_accntID, to_char(trnsDte, 'DD-Mon-YYYY HH24:MI:SS'));
	IF ((p_amnt + crntBals) > amntLmt) THEN
		IF (actn = 'Disallow') THEN
			RETURN 'ERROR:This transaction will cause budget on \r\nthe chosen account to be exceeded! ';
		ELSIF (actn = 'Warn') THEN
			RETURN 'SUCCESS:This is just to WARN you that the budget on \r\nthe chosen account will be exceeded!';
		ELSIF (actn = 'Congratulate') THEN
			RETURN 'SUCCESS:This is just to CONGRATULATE you for exceeding the targetted Amount!';
		ELSE
			RETURN 'SUCCESS:';
		END IF;
	END IF;
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'ERROR:' || SQLERRM;
END;
$BODY$;

CREATE OR REPLACE FUNCTION public.rho_reset_sequence (p_seq_name TEXT, p_key_column TEXT, p_table_name TEXT)
	RETURNS TEXT
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_max_id bigint := - 1;
	v_SQL TEXT:= ''; 
BEGIN	
--v_SQL :='SELECT MAX('||p_key_column||') FROM '||p_table_name;
--EXECUTE v_SQL INTO v_max_id;
--v_SQL :='SELECT nextval('''||p_seq_name||''')';
v_SQL :='SELECT setval('''||p_seq_name||''', COALESCE((SELECT MAX('||p_key_column||')+1 FROM '||p_table_name||'), 1), false)';
EXECUTE v_SQL;
RETURN 'SUCCESS:';
END;
$BODY$;

CREATE OR REPLACE FUNCTION org.get_accnt_id_brnch_eqv (p_brnch_id bigint, dfltacntid bigint)
	RETURNS integer
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res integer := - 1;
	v_orgid integer := - 1;
	p_main_brnch_id bigint := - 1;
	p_sub_brnch_id bigint := - 1;
	orgTtlSgmnts integer := 0;
	costCntrSgmntNum integer := 0;
	subCostCntrSgmntNum integer := 0;
	costCntrSgmntID integer := - 1;
	subCostCntrSgmntID integer := - 1;
	v_div_grp_id3 integer := - 1;
	v_cost_cntr_sgvalid integer := - 1;
	old_cost_cntr_sgvalid integer := - 1;
	v_sub_cntr_sgvalid integer := - 1;
	seg_val_ids1 integer := - 1;
	seg_val_ids2 integer := - 1;
	seg_val_ids3 integer := - 1;
	seg_val_ids4 integer := - 1;
	seg_val_ids5 integer := - 1;
	seg_val_ids6 integer := - 1;
	seg_val_ids7 integer := - 1;
	seg_val_ids8 integer := - 1;
	seg_val_ids9 integer := - 1;
	seg_val_ids10 integer := - 1;
	v_is_contra character varying(1) := '0';
	v_prnt_accnt_id integer := - 1;
	v_accnt_type character varying(50) := '';
	v_is_prnt_accnt character varying(1) := '0';
	v_is_enabled character varying(1) := '0';
	v_is_retained_earnings character varying(1) := '0';
	v_is_net_income character varying(1) := '0';
	v_accnt_typ_id integer := - 1;
	v_report_line_no integer := - 1;
	v_has_sub_ledgers character varying(1) := '0';
	v_control_account_id integer := - 1;
	v_crncy_id integer := - 1;
	v_is_suspens_accnt character varying(1) := '0';
	v_account_clsfctn character varying(200) := '';
	v_mapped_grp_accnt_id integer := - 1;
	v_AccNum character varying(200) := '';
	v_AccDesc character varying(500) := '';
	v_UsrID bigint := - 1;
BEGIN
	/*
	 1. Get all segment types {BusinessGroup|CostCenter|Location|NaturalAccount|Currency|Other}
	 */
	SELECT
		COALESCE(x.accnt_seg1_val_id, - 1),
		COALESCE(x.accnt_seg2_val_id, - 1),
		COALESCE(x.accnt_seg3_val_id, - 1),
		COALESCE(x.accnt_seg4_val_id, - 1),
		COALESCE(x.accnt_seg5_val_id, - 1),
		COALESCE(x.accnt_seg6_val_id, - 1),
		COALESCE(x.accnt_seg7_val_id, - 1),
		COALESCE(x.accnt_seg8_val_id, - 1),
		COALESCE(x.accnt_seg9_val_id, - 1),
		COALESCE(x.accnt_seg10_val_id, - 1),
		is_contra,
		prnt_accnt_id,
		org_id,
		accnt_type,
		is_prnt_accnt,
		is_enabled,
		is_retained_earnings,
		is_net_income,
		accnt_typ_id,
		report_line_no,
		has_sub_ledgers,
		control_account_id,
		crncy_id,
		is_suspens_accnt,
		account_clsfctn,
		mapped_grp_accnt_id INTO seg_val_ids1,
		seg_val_ids2,
		seg_val_ids3,
		seg_val_ids4,
		seg_val_ids5,
		seg_val_ids6,
		seg_val_ids7,
		seg_val_ids8,
		seg_val_ids9,
		seg_val_ids10,
		v_is_contra,
		v_prnt_accnt_id,
		v_orgid,
		v_accnt_type,
		v_is_prnt_accnt,
		v_is_enabled,
		v_is_retained_earnings,
		v_is_net_income,
		v_accnt_typ_id,
		v_report_line_no,
		v_has_sub_ledgers,
		v_control_account_id,
		v_crncy_id,
		v_is_suspens_accnt,
		v_account_clsfctn,
		v_mapped_grp_accnt_id
	FROM
		accb.accb_chart_of_accnts x
	WHERE
		x.accnt_id = dfltacntid;
	IF coalesce(v_orgid, - 1) <= 0 AND coalesce(dfltacntid, - 1) > 0 THEN
		RAISE EXCEPTION 'GL ACCOUNT DOES NOT EXIST:%', dfltacntid
			USING HINT = 'GL ACCOUNT DOES NOT EXIST:' || dfltacntid;
	END IF;
	SELECT
		COALESCE(org_id, - 1),
		prnt_location_id INTO v_orgid,
		v_div_grp_id3
	FROM
		org.org_sites_locations a
	WHERE (a.location_id = p_brnch_id
		AND p_brnch_id > 0);
	IF COALESCE(v_div_grp_id3, - 1) > 0 THEN
		p_main_brnch_id := v_div_grp_id3;
		p_sub_brnch_id := p_brnch_id;
	ELSE
		p_main_brnch_id := p_brnch_id;
		p_sub_brnch_id := p_brnch_id;
	END IF;
	SELECT
		no_of_accnt_sgmnts,
		loc_sgmnt_number,
		sub_loc_sgmnt_number INTO orgTtlSgmnts,
		costCntrSgmntNum,
		subCostCntrSgmntNum
	FROM
		org.org_details
	WHERE
		org_id = v_orgid;
	BEGIN
		SELECT
			segment_id INTO costCntrSgmntID
		FROM
			org.org_acnt_sgmnts
		WHERE
			segment_number = costCntrSgmntNum;
		EXCEPTION
		WHEN OTHERS THEN
			costCntrSgmntNum := 0;
		END;
	BEGIN
		SELECT
			segment_id INTO subCostCntrSgmntID
		FROM
			org.org_acnt_sgmnts
		WHERE
			segment_number = subCostCntrSgmntNum;
		EXCEPTION
		WHEN OTHERS THEN
			subCostCntrSgmntID := - 1;
		END;
	BEGIN
		SELECT
			segment_value_id INTO v_cost_cntr_sgvalid
		FROM
			org.org_segment_values
		WHERE
			segment_id = costCntrSgmntID
			AND lnkd_site_loc_id = p_main_brnch_id;
		EXCEPTION
		WHEN OTHERS THEN
			v_cost_cntr_sgvalid := - 1;
		END;
	BEGIN
		SELECT
			segment_value_id INTO v_sub_cntr_sgvalid
		FROM
			org.org_segment_values
		WHERE
			segment_id = subCostCntrSgmntID
			AND lnkd_site_loc_id = p_sub_brnch_id;
		EXCEPTION
		WHEN OTHERS THEN
			v_sub_cntr_sgvalid := - 1;
		END;
	IF (costCntrSgmntNum = 1) THEN
		old_cost_cntr_sgvalid := seg_val_ids1;
		seg_val_ids1 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 2) THEN
		old_cost_cntr_sgvalid := seg_val_ids2;
		seg_val_ids2 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 3) THEN
		old_cost_cntr_sgvalid := seg_val_ids3;
		seg_val_ids3 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 4) THEN
		old_cost_cntr_sgvalid := seg_val_ids4;
		seg_val_ids4 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 5) THEN
		old_cost_cntr_sgvalid := seg_val_ids5;
		seg_val_ids5 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 6) THEN
		old_cost_cntr_sgvalid := seg_val_ids6;
		seg_val_ids6 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 7) THEN
		old_cost_cntr_sgvalid := seg_val_ids7;
		seg_val_ids7 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 8) THEN
		old_cost_cntr_sgvalid := seg_val_ids8;
		seg_val_ids8 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 9) THEN
		old_cost_cntr_sgvalid := seg_val_ids9;
		seg_val_ids9 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 10) THEN
		old_cost_cntr_sgvalid := seg_val_ids10;
		seg_val_ids10 := v_cost_cntr_sgvalid;
	END IF;
	IF (subCostCntrSgmntNum = 1) THEN
		seg_val_ids1 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 2) THEN
		seg_val_ids2 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 3) THEN
		seg_val_ids3 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 4) THEN
		seg_val_ids4 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 5) THEN
		seg_val_ids5 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 6) THEN
		seg_val_ids6 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 7) THEN
		seg_val_ids7 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 8) THEN
		seg_val_ids8 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 9) THEN
		seg_val_ids9 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 10) THEN
		seg_val_ids10 := v_sub_cntr_sgvalid;
	END IF;
	SELECT
		COALESCE(x.accnt_id, - 1) INTO v_res
	FROM
		accb.accb_chart_of_accnts x
	WHERE
		x.accnt_seg1_val_id = COALESCE(seg_val_ids1, - 1)
		AND x.accnt_seg2_val_id = COALESCE(seg_val_ids2, - 1)
		AND x.accnt_seg3_val_id = COALESCE(seg_val_ids3, - 1)
		AND x.accnt_seg4_val_id = COALESCE(seg_val_ids4, - 1)
		AND x.accnt_seg5_val_id = COALESCE(seg_val_ids5, - 1)
		AND x.accnt_seg6_val_id = COALESCE(seg_val_ids6, - 1)
		AND x.accnt_seg7_val_id = COALESCE(seg_val_ids7, - 1)
		AND x.accnt_seg8_val_id = COALESCE(seg_val_ids8, - 1)
		AND x.accnt_seg9_val_id = COALESCE(seg_val_ids9, - 1)
		AND x.accnt_seg10_val_id = COALESCE(seg_val_ids10, - 1)
		AND x.org_id = v_orgid
		AND ('' || x.accnt_seg1_val_id || x.accnt_seg2_val_id || x.accnt_seg3_val_id || x.accnt_seg4_val_id || x.accnt_seg5_val_id || x.accnt_seg6_val_id || x.accnt_seg7_val_id || x.accnt_seg8_val_id || x.accnt_seg9_val_id || x.accnt_seg10_val_id) != '-1-1-1-1-1-1-1-1-1-1';

	/*RAISE NOTICE 'FULL Query = "%"', (v_res);*/
	IF COALESCE(v_res, - 1) <= 0 AND orgTtlSgmnts >= 2 AND seg_val_ids1 > 0 AND seg_val_ids2 > 0 AND v_cost_cntr_sgvalid > 0 AND old_cost_cntr_sgvalid > 0 AND v_is_net_income != '1' AND v_is_prnt_accnt != '1' AND v_is_enabled = '1' AND v_has_sub_ledgers != '1' THEN
		/*Create COmbination*/
		v_UsrID := sec.get_usr_id ('admin');
		v_AccNum := BTRIM(COALESCE(org.get_sgmnt_val (seg_val_ids1), '') || COALESCE(org.get_sgmnt_val (seg_val_ids2), '') || COALESCE(org.get_sgmnt_val (seg_val_ids3), '') || COALESCE(org.get_sgmnt_val (seg_val_ids4), '') || COALESCE(org.get_sgmnt_val (seg_val_ids5), '') || COALESCE(org.get_sgmnt_val (seg_val_ids6), '') || COALESCE(org.get_sgmnt_val (seg_val_ids7), '') || COALESCE(org.get_sgmnt_val (seg_val_ids8), '') || COALESCE(org.get_sgmnt_val (seg_val_ids9), '') || COALESCE(org.get_sgmnt_val (seg_val_ids10), ''), ' ');
		v_AccDesc := BTRIM(COALESCE(org.get_sgmnt_val_desc (seg_val_ids1), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids2), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids3), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids4), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids5), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids6), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids7), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids8), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids9), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids10), ''), ' ');
		INSERT INTO accb.accb_chart_of_accnts (accnt_num, accnt_name, accnt_desc, is_contra, prnt_accnt_id, balance_date, created_by, creation_date, last_update_by, last_update_date, org_id, accnt_type, is_prnt_accnt, debit_balance, credit_balance, is_enabled, net_balance, is_retained_earnings, is_net_income, accnt_typ_id, report_line_no, has_sub_ledgers, control_account_id, crncy_id, is_suspens_accnt, account_clsfctn, accnt_seg1_val_id, accnt_seg2_val_id, accnt_seg3_val_id, accnt_seg4_val_id, accnt_seg5_val_id, accnt_seg6_val_id, accnt_seg7_val_id, accnt_seg8_val_id, accnt_seg9_val_id, accnt_seg10_val_id, mapped_grp_accnt_id)
			VALUES (v_AccNum, v_AccDesc, v_AccDesc, v_is_contra, v_prnt_accnt_id, to_char(now(), 'YYYY-MM-DD'), v_UsrID, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), v_UsrID, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), v_orgid, v_accnt_type, v_is_prnt_accnt, 0, 0, v_is_enabled, 0, v_is_retained_earnings, v_is_net_income, v_accnt_typ_id, v_report_line_no, v_has_sub_ledgers, v_control_account_id, v_crncy_id, v_is_suspens_accnt, v_account_clsfctn, COALESCE(seg_val_ids1, - 1), COALESCE(seg_val_ids2, - 1), COALESCE(seg_val_ids3, - 1), COALESCE(seg_val_ids4, - 1), COALESCE(seg_val_ids5, - 1), COALESCE(seg_val_ids6, - 1), COALESCE(seg_val_ids7, - 1), COALESCE(seg_val_ids8, - 1), COALESCE(seg_val_ids9, - 1), COALESCE(seg_val_ids10, - 1), v_mapped_grp_accnt_id);
		SELECT
			COALESCE(x.accnt_id, - 1) INTO v_res
		FROM
			accb.accb_chart_of_accnts x
		WHERE
			x.accnt_seg1_val_id = COALESCE(seg_val_ids1, - 1)
			AND x.accnt_seg2_val_id = COALESCE(seg_val_ids2, - 1)
			AND x.accnt_seg3_val_id = COALESCE(seg_val_ids3, - 1)
			AND x.accnt_seg4_val_id = COALESCE(seg_val_ids4, - 1)
			AND x.accnt_seg5_val_id = COALESCE(seg_val_ids5, - 1)
			AND x.accnt_seg6_val_id = COALESCE(seg_val_ids6, - 1)
			AND x.accnt_seg7_val_id = COALESCE(seg_val_ids7, - 1)
			AND x.accnt_seg8_val_id = COALESCE(seg_val_ids8, - 1)
			AND x.accnt_seg9_val_id = COALESCE(seg_val_ids9, - 1)
			AND x.accnt_seg10_val_id = COALESCE(seg_val_ids10, - 1)
			AND x.org_id = v_orgid
			AND ('' || x.accnt_seg1_val_id || x.accnt_seg2_val_id || x.accnt_seg3_val_id || x.accnt_seg4_val_id || x.accnt_seg5_val_id || x.accnt_seg6_val_id || x.accnt_seg7_val_id || x.accnt_seg8_val_id || x.accnt_seg9_val_id || x.accnt_seg10_val_id) != '-1-1-1-1-1-1-1-1-1-1';
	END IF;
	IF COALESCE(v_res, - 1) <= 0 THEN
		v_res := dfltacntid;
	END IF;
	IF accb.is_accnt_prnt (v_res) = '1' OR accb.is_accnt_hvng_sbldgrs (v_res) = '1' THEN
		v_AccDesc := accb.get_accnt_num (v_res) || '.' || accb.get_accnt_name (v_res);
		RAISE EXCEPTION 'WRONG ACCOUNT SELECTED:Parent or Control Account!%', v_AccDesc || ' ID: ' || dfltacntid || ' BRNCHID:' || p_brnch_id || ' NEW ACC ID:' || v_res
			USING HINT = 'Cannot directly impact a Parent or Control Account!';
	END IF;
	RETURN COALESCE(v_res, dfltacntid);

	/*EXCEPTION
	 WHEN OTHERS
	 THEN
	 RETURN dfltacntid;*/
END;

$BODY$;

CREATE OR REPLACE FUNCTION org.get_accnt_id_eqv (p_brnch_id bigint, p_sub_brnch_id bigint, dfltacntid bigint)
	RETURNS integer
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_msgs text := '';
	v_res integer := - 1;
	orgid integer := - 1;
	v_orgid integer := - 1;
	orgTtlSgmnts integer := 0;
	costCntrSgmntNum integer := 0;
	subCostCntrSgmntNum integer := 0;
	costCntrSgmntID integer := - 1;
	subCostCntrSgmntID integer := - 1;
	v_div_grp_id1 integer := - 1;
	v_div_grp_id2 integer := - 1;
	v_cost_cntr_sgvalid integer := - 1;
	v_sub_cntr_sgvalid integer := - 1;
	i RECORD;
	seg_val_ids1 integer := - 1;
	seg_val_ids2 integer := - 1;
	seg_val_ids3 integer := - 1;
	seg_val_ids4 integer := - 1;
	seg_val_ids5 integer := - 1;
	seg_val_ids6 integer := - 1;
	seg_val_ids7 integer := - 1;
	seg_val_ids8 integer := - 1;
	seg_val_ids9 integer := - 1;
	seg_val_ids10 integer := - 1;
	v_AccDesc character varying(300) := '';
BEGIN
	/*
	 1. Get all segment types {BusinessGroup|CostCenter|Location|NaturalAccount|Currency|Other}
	 */
	SELECT
		COALESCE(x.accnt_seg1_val_id, - 1),
		COALESCE(x.accnt_seg2_val_id, - 1),
		COALESCE(x.accnt_seg3_val_id, - 1),
		COALESCE(x.accnt_seg4_val_id, - 1),
		COALESCE(x.accnt_seg5_val_id, - 1),
		COALESCE(x.accnt_seg6_val_id, - 1),
		COALESCE(x.accnt_seg7_val_id, - 1),
		COALESCE(x.accnt_seg8_val_id, - 1),
		COALESCE(x.accnt_seg9_val_id, - 1),
		COALESCE(x.accnt_seg10_val_id, - 1),
		org_id INTO seg_val_ids1,
		seg_val_ids2,
		seg_val_ids3,
		seg_val_ids4,
		seg_val_ids5,
		seg_val_ids6,
		seg_val_ids7,
		seg_val_ids8,
		seg_val_ids9,
		seg_val_ids10,
		v_orgid
	FROM
		accb.accb_chart_of_accnts x
	WHERE
		x.accnt_id = dfltacntid;
	IF coalesce(v_orgid, - 1) <= 0 AND coalesce(dfltacntid, - 1) > 0 THEN
		RAISE EXCEPTION 'GL ACCOUNT DOES NOT EXIST:%', dfltacntid
			USING HINT = 'GL ACCOUNT DOES NOT EXIST:' || dfltacntid;
	END IF;
	IF p_brnch_id > 0 THEN
		SELECT
			COALESCE(org_id, - 1) INTO orgid
		FROM
			org.org_sites_locations
		WHERE (location_id = p_brnch_id);
	END IF;
	IF p_sub_brnch_id > 0 AND orgid <= 0 THEN
		SELECT
			COALESCE(org_id, - 1) INTO orgid
		FROM
			org.org_sites_locations
		WHERE (location_id = p_sub_brnch_id);
	END IF;
	SELECT
		no_of_accnt_sgmnts,
		loc_sgmnt_number,
		sub_loc_sgmnt_number INTO orgTtlSgmnts,
		costCntrSgmntNum,
		subCostCntrSgmntNum
	FROM
		org.org_details
	WHERE
		org_id = orgid;
	BEGIN
		SELECT
			segment_id INTO costCntrSgmntID
		FROM
			org.org_acnt_sgmnts
		WHERE
			segment_number = costCntrSgmntNum;
		EXCEPTION
		WHEN OTHERS THEN
			costCntrSgmntID := - 1;
		END;
	BEGIN
		SELECT
			segment_id INTO subCostCntrSgmntID
		FROM
			org.org_acnt_sgmnts
		WHERE
			segment_number = subCostCntrSgmntNum;
		EXCEPTION
		WHEN OTHERS THEN
			subCostCntrSgmntID := - 1;
		END;
	BEGIN
		SELECT
			segment_value_id INTO v_cost_cntr_sgvalid
		FROM
			org.org_segment_values
		WHERE
			segment_id = costCntrSgmntID
			AND lnkd_site_loc_id = p_brnch_id;
		EXCEPTION
		WHEN OTHERS THEN
			v_cost_cntr_sgvalid := - 1;
		END;
	BEGIN
		SELECT
			segment_value_id INTO v_sub_cntr_sgvalid
		FROM
			org.org_segment_values
		WHERE
			segment_id = subCostCntrSgmntID
			AND lnkd_site_loc_id = p_sub_brnch_id;
		EXCEPTION
		WHEN OTHERS THEN
			v_sub_cntr_sgvalid := - 1;
		END;
	IF v_cost_cntr_sgvalid > 0 THEN
		IF (costCntrSgmntNum = 1) THEN
			seg_val_ids1 := v_cost_cntr_sgvalid;
		ELSIF (costCntrSgmntNum = 2) THEN
			seg_val_ids2 := v_cost_cntr_sgvalid;
		ELSIF (costCntrSgmntNum = 3) THEN
			seg_val_ids3 := v_cost_cntr_sgvalid;
		ELSIF (costCntrSgmntNum = 4) THEN
			seg_val_ids4 := v_cost_cntr_sgvalid;
		ELSIF (costCntrSgmntNum = 5) THEN
			seg_val_ids5 := v_cost_cntr_sgvalid;
		ELSIF (costCntrSgmntNum = 6) THEN
			seg_val_ids6 := v_cost_cntr_sgvalid;
		ELSIF (costCntrSgmntNum = 7) THEN
			seg_val_ids7 := v_cost_cntr_sgvalid;
		ELSIF (costCntrSgmntNum = 8) THEN
			seg_val_ids8 := v_cost_cntr_sgvalid;
		ELSIF (costCntrSgmntNum = 9) THEN
			seg_val_ids9 := v_cost_cntr_sgvalid;
		ELSIF (costCntrSgmntNum = 10) THEN
			seg_val_ids10 := v_cost_cntr_sgvalid;
		END IF;
	END IF;
	IF v_sub_cntr_sgvalid > 0 THEN
		IF (subCostCntrSgmntNum = 1) THEN
			seg_val_ids1 := v_sub_cntr_sgvalid;
		ELSIF (subCostCntrSgmntNum = 2) THEN
			seg_val_ids2 := v_sub_cntr_sgvalid;
		ELSIF (subCostCntrSgmntNum = 3) THEN
			seg_val_ids3 := v_sub_cntr_sgvalid;
		ELSIF (subCostCntrSgmntNum = 4) THEN
			seg_val_ids4 := v_sub_cntr_sgvalid;
		ELSIF (subCostCntrSgmntNum = 5) THEN
			seg_val_ids5 := v_sub_cntr_sgvalid;
		ELSIF (subCostCntrSgmntNum = 6) THEN
			seg_val_ids6 := v_sub_cntr_sgvalid;
		ELSIF (subCostCntrSgmntNum = 7) THEN
			seg_val_ids7 := v_sub_cntr_sgvalid;
		ELSIF (subCostCntrSgmntNum = 8) THEN
			seg_val_ids8 := v_sub_cntr_sgvalid;
		ELSIF (subCostCntrSgmntNum = 9) THEN
			seg_val_ids9 := v_sub_cntr_sgvalid;
		ELSIF (subCostCntrSgmntNum = 10) THEN
			seg_val_ids10 := v_sub_cntr_sgvalid;
		END IF;
	END IF;
	SELECT
		COALESCE(x.accnt_id, - 1) INTO v_res
	FROM
		accb.accb_chart_of_accnts x
	WHERE
		x.accnt_seg1_val_id = COALESCE(seg_val_ids1, - 1)
		AND x.accnt_seg2_val_id = COALESCE(seg_val_ids2, - 1)
		AND x.accnt_seg3_val_id = COALESCE(seg_val_ids3, - 1)
		AND x.accnt_seg4_val_id = COALESCE(seg_val_ids4, - 1)
		AND x.accnt_seg5_val_id = COALESCE(seg_val_ids5, - 1)
		AND x.accnt_seg6_val_id = COALESCE(seg_val_ids6, - 1)
		AND x.accnt_seg7_val_id = COALESCE(seg_val_ids7, - 1)
		AND x.accnt_seg8_val_id = COALESCE(seg_val_ids8, - 1)
		AND x.accnt_seg9_val_id = COALESCE(seg_val_ids9, - 1)
		AND x.accnt_seg10_val_id = COALESCE(seg_val_ids10, - 1)
		AND x.org_id = orgid
		AND ('' || x.accnt_seg1_val_id || x.accnt_seg2_val_id || x.accnt_seg3_val_id || x.accnt_seg4_val_id || x.accnt_seg5_val_id || x.accnt_seg6_val_id || x.accnt_seg7_val_id || x.accnt_seg8_val_id || x.accnt_seg9_val_id || x.accnt_seg10_val_id) != '-1-1-1-1-1-1-1-1-1-1';
	IF COALESCE(v_res, - 1) <= 0 THEN
		v_res := dfltacntid;
	END IF;
	IF accb.is_accnt_prnt (v_res) = '1' OR accb.is_accnt_hvng_sbldgrs (v_res) = '1' THEN
		v_AccDesc := accb.get_accnt_num (v_res) || '.' || accb.get_accnt_name (v_res);
		RAISE EXCEPTION 'WRONG ACCOUNT SELECTED:%', v_AccDesc
			USING HINT = 'Cannot directly impact a Parent or Control Account!';
	END IF;
	RETURN COALESCE(v_res, - 1);

	/*EXCEPTION
	 WHEN OTHERS
	 THEN
	 v_msgs := v_msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
	 RAISE NOTICE 'ERRORS T5T5:%', v_msgs;
	 RETURN dfltacntid;*/
END;

$BODY$;

CREATE OR REPLACE FUNCTION org.get_accnt_id_frmaccnt (p_one_brnch_acntid bigint, dfltacntid bigint)
	RETURNS integer
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res integer := - 1;
	v_orgid integer := - 1;
	p_main_brnch_id bigint := - 1;
	p_sub_brnch_id bigint := - 1;
	orgTtlSgmnts integer := 0;
	costCntrSgmntNum integer := 0;
	subCostCntrSgmntNum integer := 0;
	costCntrSgmntID integer := - 1;
	subCostCntrSgmntID integer := - 1;
	--v_div_grp_id3          INTEGER                := -1;
	v_cost_cntr_sgvalid integer := - 1;
	v_sub_cntr_sgvalid integer := - 1;
	seg_val_ids1 integer := - 1;
	seg_val_ids2 integer := - 1;
	seg_val_ids3 integer := - 1;
	seg_val_ids4 integer := - 1;
	seg_val_ids5 integer := - 1;
	seg_val_ids6 integer := - 1;
	seg_val_ids7 integer := - 1;
	seg_val_ids8 integer := - 1;
	seg_val_ids9 integer := - 1;
	seg_val_ids10 integer := - 1;
	v_is_contra character varying(1) := '0';
	v_prnt_accnt_id integer := - 1;
	v_accnt_type character varying(50) := '';
	v_is_prnt_accnt character varying(1) := '0';
	v_is_enabled character varying(1) := '0';
	v_is_retained_earnings character varying(1) := '0';
	v_is_net_income character varying(1) := '0';
	v_accnt_typ_id integer := - 1;
	v_report_line_no integer := - 1;
	v_has_sub_ledgers character varying(1) := '0';
	v_control_account_id integer := - 1;
	v_crncy_id integer := - 1;
	v_is_suspens_accnt character varying(1) := '0';
	v_account_clsfctn character varying(200) := '';
	v_mapped_grp_accnt_id integer := - 1;
	v_AccNum character varying(200) := '';
	v_AccDesc character varying(500) := '';
	v_UsrID bigint := - 1;
BEGIN
	/*
	 1. Get all segment types {BusinessGroup|CostCenter|Location|NaturalAccount|Currency|Other}
	 */
	SELECT
		COALESCE(x.accnt_seg1_val_id, - 1),
		COALESCE(x.accnt_seg2_val_id, - 1),
		COALESCE(x.accnt_seg3_val_id, - 1),
		COALESCE(x.accnt_seg4_val_id, - 1),
		COALESCE(x.accnt_seg5_val_id, - 1),
		COALESCE(x.accnt_seg6_val_id, - 1),
		COALESCE(x.accnt_seg7_val_id, - 1),
		COALESCE(x.accnt_seg8_val_id, - 1),
		COALESCE(x.accnt_seg9_val_id, - 1),
		COALESCE(x.accnt_seg10_val_id, - 1),
		org_id INTO seg_val_ids1,
		seg_val_ids2,
		seg_val_ids3,
		seg_val_ids4,
		seg_val_ids5,
		seg_val_ids6,
		seg_val_ids7,
		seg_val_ids8,
		seg_val_ids9,
		seg_val_ids10,
		v_orgid
	FROM
		accb.accb_chart_of_accnts x
	WHERE
		x.accnt_id = p_one_brnch_acntid;
	IF coalesce(v_orgid, - 1) <= 0 AND coalesce(p_one_brnch_acntid, - 1) > 0 THEN
		RAISE EXCEPTION 'GL ACCOUNT DOES NOT EXIST:%', p_one_brnch_acntid
			USING HINT = 'GL ACCOUNT DOES NOT EXIST:' || p_one_brnch_acntid;
	END IF;
	SELECT
		no_of_accnt_sgmnts,
		loc_sgmnt_number,
		sub_loc_sgmnt_number INTO orgTtlSgmnts,
		costCntrSgmntNum,
		subCostCntrSgmntNum
	FROM
		org.org_details
	WHERE
		org_id = v_orgid;
	BEGIN
		SELECT
			segment_id INTO costCntrSgmntID
		FROM
			org.org_acnt_sgmnts
		WHERE
			segment_number = costCntrSgmntNum;
		EXCEPTION
		WHEN OTHERS THEN
			costCntrSgmntNum := 0;
		END;
	BEGIN
		SELECT
			segment_id INTO subCostCntrSgmntID
		FROM
			org.org_acnt_sgmnts
		WHERE
			segment_number = subCostCntrSgmntNum;
		EXCEPTION
		WHEN OTHERS THEN
			subCostCntrSgmntID := - 1;
		END;
	IF (costCntrSgmntNum = 1) THEN
		v_cost_cntr_sgvalid := seg_val_ids1;
	ELSIF (costCntrSgmntNum = 2) THEN
		v_cost_cntr_sgvalid := seg_val_ids2;
	ELSIF (costCntrSgmntNum = 3) THEN
		v_cost_cntr_sgvalid := seg_val_ids3;
	ELSIF (costCntrSgmntNum = 4) THEN
		v_cost_cntr_sgvalid := seg_val_ids4;
	ELSIF (costCntrSgmntNum = 5) THEN
		v_cost_cntr_sgvalid := seg_val_ids5;
	ELSIF (costCntrSgmntNum = 6) THEN
		v_cost_cntr_sgvalid := seg_val_ids6;
	ELSIF (costCntrSgmntNum = 7) THEN
		v_cost_cntr_sgvalid := seg_val_ids7;
	ELSIF (costCntrSgmntNum = 8) THEN
		v_cost_cntr_sgvalid := seg_val_ids8;
	ELSIF (costCntrSgmntNum = 9) THEN
		v_cost_cntr_sgvalid := seg_val_ids9;
	ELSIF (costCntrSgmntNum = 10) THEN
		v_cost_cntr_sgvalid := seg_val_ids10;
	END IF;
	IF (subCostCntrSgmntNum = 1) THEN
		v_sub_cntr_sgvalid := seg_val_ids1;
	ELSIF (subCostCntrSgmntNum = 2) THEN
		v_sub_cntr_sgvalid := seg_val_ids2;
	ELSIF (subCostCntrSgmntNum = 3) THEN
		v_sub_cntr_sgvalid := seg_val_ids3;
	ELSIF (subCostCntrSgmntNum = 4) THEN
		v_sub_cntr_sgvalid := seg_val_ids4;
	ELSIF (subCostCntrSgmntNum = 5) THEN
		v_sub_cntr_sgvalid := seg_val_ids5;
	ELSIF (subCostCntrSgmntNum = 6) THEN
		v_sub_cntr_sgvalid := seg_val_ids6;
	ELSIF (subCostCntrSgmntNum = 7) THEN
		v_sub_cntr_sgvalid := seg_val_ids7;
	ELSIF (subCostCntrSgmntNum = 8) THEN
		v_sub_cntr_sgvalid := seg_val_ids8;
	ELSIF (subCostCntrSgmntNum = 9) THEN
		v_sub_cntr_sgvalid := seg_val_ids9;
	ELSIF (subCostCntrSgmntNum = 10) THEN
		v_sub_cntr_sgvalid := seg_val_ids10;
	END IF;
	BEGIN
		SELECT
			lnkd_site_loc_id INTO p_main_brnch_id
		FROM
			org.org_segment_values
		WHERE
			segment_id = costCntrSgmntID
			AND segment_value_id = v_cost_cntr_sgvalid;
		EXCEPTION
		WHEN OTHERS THEN
			p_main_brnch_id := - 1;
		END;
	BEGIN
		SELECT
			lnkd_site_loc_id INTO p_sub_brnch_id
		FROM
			org.org_segment_values
		WHERE
			segment_id = subCostCntrSgmntID
			AND segment_value_id = v_sub_cntr_sgvalid;
		EXCEPTION
		WHEN OTHERS THEN
			p_sub_brnch_id := - 1;
		END;
	SELECT
		COALESCE(x.accnt_seg1_val_id, - 1),
		COALESCE(x.accnt_seg2_val_id, - 1),
		COALESCE(x.accnt_seg3_val_id, - 1),
		COALESCE(x.accnt_seg4_val_id, - 1),
		COALESCE(x.accnt_seg5_val_id, - 1),
		COALESCE(x.accnt_seg6_val_id, - 1),
		COALESCE(x.accnt_seg7_val_id, - 1),
		COALESCE(x.accnt_seg8_val_id, - 1),
		COALESCE(x.accnt_seg9_val_id, - 1),
		COALESCE(x.accnt_seg10_val_id, - 1),
		is_contra,
		prnt_accnt_id,
		org_id,
		accnt_type,
		is_prnt_accnt,
		is_enabled,
		is_retained_earnings,
		is_net_income,
		accnt_typ_id,
		report_line_no,
		has_sub_ledgers,
		control_account_id,
		crncy_id,
		is_suspens_accnt,
		account_clsfctn,
		mapped_grp_accnt_id INTO seg_val_ids1,
		seg_val_ids2,
		seg_val_ids3,
		seg_val_ids4,
		seg_val_ids5,
		seg_val_ids6,
		seg_val_ids7,
		seg_val_ids8,
		seg_val_ids9,
		seg_val_ids10,
		v_is_contra,
		v_prnt_accnt_id,
		v_orgid,
		v_accnt_type,
		v_is_prnt_accnt,
		v_is_enabled,
		v_is_retained_earnings,
		v_is_net_income,
		v_accnt_typ_id,
		v_report_line_no,
		v_has_sub_ledgers,
		v_control_account_id,
		v_crncy_id,
		v_is_suspens_accnt,
		v_account_clsfctn,
		v_mapped_grp_accnt_id
	FROM
		accb.accb_chart_of_accnts x
	WHERE
		x.accnt_id = dfltacntid;
	IF (costCntrSgmntNum = 1) THEN
		seg_val_ids1 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 2) THEN
		seg_val_ids2 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 3) THEN
		seg_val_ids3 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 4) THEN
		seg_val_ids4 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 5) THEN
		seg_val_ids5 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 6) THEN
		seg_val_ids6 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 7) THEN
		seg_val_ids7 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 8) THEN
		seg_val_ids8 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 9) THEN
		seg_val_ids9 := v_cost_cntr_sgvalid;
	ELSIF (costCntrSgmntNum = 10) THEN
		seg_val_ids10 := v_cost_cntr_sgvalid;
	END IF;
	IF (subCostCntrSgmntNum = 1) THEN
		seg_val_ids1 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 2) THEN
		seg_val_ids2 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 3) THEN
		seg_val_ids3 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 4) THEN
		seg_val_ids4 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 5) THEN
		seg_val_ids5 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 6) THEN
		seg_val_ids6 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 7) THEN
		seg_val_ids7 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 8) THEN
		seg_val_ids8 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 9) THEN
		seg_val_ids9 := v_sub_cntr_sgvalid;
	ELSIF (subCostCntrSgmntNum = 10) THEN
		seg_val_ids10 := v_sub_cntr_sgvalid;
	END IF;
	SELECT
		COALESCE(x.accnt_id, - 1) INTO v_res
	FROM
		accb.accb_chart_of_accnts x
	WHERE
		x.accnt_seg1_val_id = COALESCE(seg_val_ids1, - 1)
		AND x.accnt_seg2_val_id = COALESCE(seg_val_ids2, - 1)
		AND x.accnt_seg3_val_id = COALESCE(seg_val_ids3, - 1)
		AND x.accnt_seg4_val_id = COALESCE(seg_val_ids4, - 1)
		AND x.accnt_seg5_val_id = COALESCE(seg_val_ids5, - 1)
		AND x.accnt_seg6_val_id = COALESCE(seg_val_ids6, - 1)
		AND x.accnt_seg7_val_id = COALESCE(seg_val_ids7, - 1)
		AND x.accnt_seg8_val_id = COALESCE(seg_val_ids8, - 1)
		AND x.accnt_seg9_val_id = COALESCE(seg_val_ids9, - 1)
		AND x.accnt_seg10_val_id = COALESCE(seg_val_ids10, - 1)
		AND x.org_id = v_orgid
		AND ('' || x.accnt_seg1_val_id || x.accnt_seg2_val_id || x.accnt_seg3_val_id || x.accnt_seg4_val_id || x.accnt_seg5_val_id || x.accnt_seg6_val_id || x.accnt_seg7_val_id || x.accnt_seg8_val_id || x.accnt_seg9_val_id || x.accnt_seg10_val_id) != '-1-1-1-1-1-1-1-1-1-1';

	/*RAISE NOTICE 'FULL Query = "%"', (v_res);*/
	IF COALESCE(v_res, - 1) <= 0 AND orgTtlSgmnts >= 2 AND seg_val_ids1 > 0 AND seg_val_ids2 > 0 AND v_cost_cntr_sgvalid > 0 AND v_is_net_income != '1' AND v_is_prnt_accnt != '1' AND v_is_enabled = '1' AND v_has_sub_ledgers != '1' THEN
		/*Create COmbination*/
		v_UsrID := sec.get_usr_id ('admin');
		v_AccNum := BTRIM(COALESCE(org.get_sgmnt_val (seg_val_ids1), '') || COALESCE(org.get_sgmnt_val (seg_val_ids2), '') || COALESCE(org.get_sgmnt_val (seg_val_ids3), '') || COALESCE(org.get_sgmnt_val (seg_val_ids4), '') || COALESCE(org.get_sgmnt_val (seg_val_ids5), '') || COALESCE(org.get_sgmnt_val (seg_val_ids6), '') || COALESCE(org.get_sgmnt_val (seg_val_ids7), '') || COALESCE(org.get_sgmnt_val (seg_val_ids8), '') || COALESCE(org.get_sgmnt_val (seg_val_ids9), '') || COALESCE(org.get_sgmnt_val (seg_val_ids10), ''), ' ');
		v_AccDesc := BTRIM(COALESCE(org.get_sgmnt_val_desc (seg_val_ids1), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids2), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids3), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids4), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids5), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids6), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids7), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids8), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids9), '') || ' ' || COALESCE(org.get_sgmnt_val_desc (seg_val_ids10), ''), ' ');
		INSERT INTO accb.accb_chart_of_accnts (accnt_num, accnt_name, accnt_desc, is_contra, prnt_accnt_id, balance_date, created_by, creation_date, last_update_by, last_update_date, org_id, accnt_type, is_prnt_accnt, debit_balance, credit_balance, is_enabled, net_balance, is_retained_earnings, is_net_income, accnt_typ_id, report_line_no, has_sub_ledgers, control_account_id, crncy_id, is_suspens_accnt, account_clsfctn, accnt_seg1_val_id, accnt_seg2_val_id, accnt_seg3_val_id, accnt_seg4_val_id, accnt_seg5_val_id, accnt_seg6_val_id, accnt_seg7_val_id, accnt_seg8_val_id, accnt_seg9_val_id, accnt_seg10_val_id, mapped_grp_accnt_id)
			VALUES (v_AccNum, v_AccDesc, v_AccDesc, v_is_contra, v_prnt_accnt_id, to_char(now(), 'YYYY-MM-DD'), v_UsrID, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), v_UsrID, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), v_orgid, v_accnt_type, v_is_prnt_accnt, 0, 0, v_is_enabled, 0, v_is_retained_earnings, v_is_net_income, v_accnt_typ_id, v_report_line_no, v_has_sub_ledgers, v_control_account_id, v_crncy_id, v_is_suspens_accnt, v_account_clsfctn, COALESCE(seg_val_ids1, - 1), COALESCE(seg_val_ids2, - 1), COALESCE(seg_val_ids3, - 1), COALESCE(seg_val_ids4, - 1), COALESCE(seg_val_ids5, - 1), COALESCE(seg_val_ids6, - 1), COALESCE(seg_val_ids7, - 1), COALESCE(seg_val_ids8, - 1), COALESCE(seg_val_ids9, - 1), COALESCE(seg_val_ids10, - 1), v_mapped_grp_accnt_id);
		SELECT
			COALESCE(x.accnt_id, - 1) INTO v_res
		FROM
			accb.accb_chart_of_accnts x
		WHERE
			x.accnt_seg1_val_id = COALESCE(seg_val_ids1, - 1)
			AND x.accnt_seg2_val_id = COALESCE(seg_val_ids2, - 1)
			AND x.accnt_seg3_val_id = COALESCE(seg_val_ids3, - 1)
			AND x.accnt_seg4_val_id = COALESCE(seg_val_ids4, - 1)
			AND x.accnt_seg5_val_id = COALESCE(seg_val_ids5, - 1)
			AND x.accnt_seg6_val_id = COALESCE(seg_val_ids6, - 1)
			AND x.accnt_seg7_val_id = COALESCE(seg_val_ids7, - 1)
			AND x.accnt_seg8_val_id = COALESCE(seg_val_ids8, - 1)
			AND x.accnt_seg9_val_id = COALESCE(seg_val_ids9, - 1)
			AND x.accnt_seg10_val_id = COALESCE(seg_val_ids10, - 1)
			AND x.org_id = v_orgid
			AND ('' || x.accnt_seg1_val_id || x.accnt_seg2_val_id || x.accnt_seg3_val_id || x.accnt_seg4_val_id || x.accnt_seg5_val_id || x.accnt_seg6_val_id || x.accnt_seg7_val_id || x.accnt_seg8_val_id || x.accnt_seg9_val_id || x.accnt_seg10_val_id) != '-1-1-1-1-1-1-1-1-1-1';
	END IF;
	IF COALESCE(v_res, - 1) <= 0 THEN
		v_res := dfltacntid;
	END IF;
	IF accb.is_accnt_prnt (v_res) = '1' OR accb.is_accnt_hvng_sbldgrs (v_res) = '1' THEN
		v_AccDesc := accb.get_accnt_num (v_res) || '.' || accb.get_accnt_name (v_res);
		RAISE EXCEPTION 'WRONG ACCOUNT SELECTED:%', v_AccDesc
			USING HINT = 'Cannot directly impact a Parent or Control Account!';
	END IF;
	RETURN COALESCE(v_res, dfltacntid);

	/*EXCEPTION
	 WHEN OTHERS
	 THEN
	 RETURN dfltacntid;*/
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.is_accnt_hvng_sbldgrs (accntid integer)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid character varying(1) := '0';
BEGIN
	SELECT
		has_sub_ledgers INTO bid
	FROM
		accb.accb_chart_of_accnts
	WHERE
		accnt_id = accntid;
	RETURN COALESCE(bid, '0');
EXCEPTION
	WHEN OTHERS THEN
		RETURN '0';
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.post_gl_trns (gl_btchid bigint, who_rn bigint, run_date character varying, orgidno integer, p_msgid bigint, p_is_bulk_run character varying)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	msgid bigint := - 1;
	rd_gl_btchID bigint := - 1;
	btchSrc character varying(200);
	rd2 RECORD;
	rd1 RECORD;
	rd0 RECORD;
	msgs text := chr(10) || '';
	orgNetIcmAccntID integer := - 1;
	orgRetErnAccntID integer := - 1;
	cur_ID bigint := - 1;
	cntr integer := 0;
	errCntr integer := 0;
	batchCntr integer := 0;
	updtMsg bigint := 0;
	v_reslt_1 character varying(200) := '';
	dateStr character varying(21) := '';
	asAtDate character varying(21) := '';
	accntCurrID integer := - 1;
	funCurID integer := - 1;
	accntCurrAmnt numeric := 0;
	acctyp character varying(200) := '';
	hsBnUpdt boolean := FALSE;
	dbt1 numeric := 0;
	crdt1 numeric := 0;
	net1 numeric := 0;
	cntrlAcntID integer := - 1;
	cntrlAcntCurrID integer := - 1;
	aesum numeric := 0;
	crlsum numeric := 0;
BEGIN
	errCntr := 0;
	batchCntr := 0;
	dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	cur_ID := COALESCE(org.get_Orgfunc_Crncy_id (orgidno), - 1);
	orgRetErnAccntID := accb.get_OrgRetErnAccntID (orgidno);
	orgNetIcmAccntID := accb.get_orgnetincmaccntid (orgidno);
	btchSrc := accb.get_batch_source (gl_btchID);
	msgid := p_msgid;
	IF msgid <= 0 THEN
		msgid := rpt.getRptLogMsgID (gl_btchID, 'Posting Batch of Transactions');
		IF msgid <= 0 THEN
			v_reslt_1 := rpt.createRptLogMsg (dateStr || ' .... Posting Batch of Transactions is about to Start...', 'Posting Batch of Transactions', gl_btchID, dateStr, who_rn);
			msgid := rpt.getRptLogMsgID (gl_btchID, 'Posting Batch of Transactions');
		END IF;
	END IF;
	IF (accb.isThereANActvPrcss ('5') = '1') THEN
		msgs := msgs || chr(10) || 'Sorry an Account Posting Process is already on-going!\r\nKindly Wait for that Process to Finish and try again!';
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, $3, $2);
			--msgs := rpt.getLogMsg(msgid);
		ELSE
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		RAISE EXCEPTION 'ERROR:%', msgs
			USING HINT = 'ERROR:' || msgs;
	ELSE
		v_reslt_1 := accb.updateANActvPrcss ('5', '1');
	END IF;
	IF coalesce(orgNetIcmAccntID, - 1) <= 0 OR coalesce(orgRetErnAccntID, - 1) <= 0 THEN
		msgs := msgs || chr(10) || 'Net Income and Retained Earnings Accounts Must be Created First!';
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, $3, $2);
			--msgs := rpt.getLogMsg(msgid);
		ELSE
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		v_reslt_1 := accb.updateANActvPrcss ('5', '0');
		RAISE EXCEPTION 'ERROR:%', msgs
			USING HINT = 'ERROR:' || msgs;
	END IF;
	IF gl_btchID <= 0 AND p_is_bulk_run != '1' THEN
		msgs := msgs || chr(10) || 'Please select a saved Batch First!';
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, $3, $2);
			--msgs := rpt.getLogMsg(msgid);
		ELSE
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		v_reslt_1 := accb.updateANActvPrcss ('5', '0');
		RAISE EXCEPTION 'ERROR:%', msgs
			USING HINT = 'ERROR:' || msgs;
	ELSE
		FOR rd0 IN
		SELECT
			batch_id,
			batch_name,
			batch_source,
			batch_status,
			CASE WHEN batch_status = '1' THEN
				'POSTED'
			ELSE
				'NOT POSTED'
			END pstng_status,
			batch_description,
			org_id,
			avlbl_for_postng,
			(
				SELECT
					count(1)
				FROM
					accb.accb_trnsctn_details y
				WHERE
					y.batch_id = a.batch_id) no_of_trns,
			(
				SELECT
					max(y.trnsctn_date)
				FROM
					accb.accb_trnsctn_details y
				WHERE
					y.batch_id = a.batch_id) lastBatchTrnsDate
		FROM
			accb.accb_trnsctn_batches a
		WHERE
			org_id = orgidno
			AND batch_status = '0'
			AND (avlbl_for_postng = '1'
				OR batch_id = gl_btchID)
			AND ((
					SELECT
						count(1)
					FROM
						accb.accb_trnsctn_details y
					WHERE
						y.batch_id = a.batch_id) > 0
					OR batch_source = 'Period Close Process')
			AND ((age(now(), to_timestamp(last_update_date, 'YYYY-MM-DD HH24:MI:SS')) >= interval '5 second'
					AND gl_btchID <= 0)
				OR (batch_id = gl_btchID))
		ORDER BY
			1 ASC
		LIMIT 500 OFFSET 0 LOOP
			btchSrc := rd0.batch_source;
			rd_gl_btchID := rd0.batch_id;
			v_reslt_1 := accb.updateANActvPrcss ('5', '1');
			UPDATE
				accb.accb_trnsctn_details
			SET
				dbt_amount = round(dbt_amount, 2),
				crdt_amount = round(crdt_amount, 2),
				net_amount = round((
					CASE WHEN accb.get_accnt_type (accnt_id) IN ('A', 'EX') THEN
					(dbt_amount - crdt_amount)
				ELSE
					(crdt_amount - dbt_amount)
					END), 2)
			WHERE
				batch_id = rd_gl_btchID;
			IF accb.gl_batch_trns_sum (rd_gl_btchID, 'Debit') != accb.gl_batch_trns_sum (rd_gl_btchID, 'Credit') THEN
				msgs := msgs || chr(10) || 'Cannot Post an Unbalanced Batch of Transactions!';
				IF msgid > 0 THEN
					updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, $3, $2);
					--msgs := rpt.getLogMsg(msgid);
				END IF;
				IF msgid <= 0 THEN
					msgs := REPLACE(msgs, chr(10), '<br/>');
				END IF;
				v_reslt_1 := accb.updateANActvPrcss ('5', '0');
				RAISE EXCEPTION 'ERROR:%', msgs
					USING HINT = 'ERROR:' || msgs;
			END IF;
			cntr := 0;
			FOR rd1 IN
			SELECT
				substring(a.trnsctn_date FROM 1 FOR 10) trnsctndate,
				round(SUM(a.dbt_amount), 4) dbtamount,
				round(SUM(a.crdt_amount), 4) crdtamount
			FROM
				accb.accb_trnsctn_details a
			WHERE (a.batch_id = rd_gl_btchID)
		GROUP BY
			substring(a.trnsctn_date FROM 1 FOR 10)
		HAVING
			round(SUM(a.dbt_amount), 2) != round(SUM(a.crdt_amount), 2)
		ORDER BY
			1 LOOP
				IF cntr = 0 THEN
					msgs := msgs || chr(10) || 'Your transactions will cause your Balance Sheet to become Unbalanced on some Days!
                                                            Please make sure each day has equal debits and credits.
                                                            Check the ff Days:';
				END IF;
				msgs := msgs || chr(10) || rd1.trnsctndate || '     DR=' || rd1.dbtamount || '     CR=' || rd1.crdt_amount;
				cntr := cntr + 1;
			END LOOP;
			IF cntr > 0 THEN
				IF msgid > 0 THEN
					updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, $3, $2);
					--msgs := rpt.getLogMsg(msgid);
				ELSE
					msgs := REPLACE(msgs, chr(10), '<br/>');
				END IF;
				v_reslt_1 := accb.updateANActvPrcss ('5', '0');
				RAISE EXCEPTION 'ERROR:%', msgs
					USING HINT = 'ERROR:' || msgs;
			END IF;
			cntr := 0;
			FOR rd2 IN
			SELECT
				a.transctn_id,
				b.accnt_num,
				b.accnt_name,
				a.transaction_desc,
				a.dbt_amount,
				a.crdt_amount,
				to_char(to_timestamp(a.trnsctn_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') lnDte,
				a.func_cur_id,
				a.batch_id,
				a.accnt_id,
				a.net_amount,
				a.trns_status,
				a.entered_amnt,
				gst.get_pssbl_val (a.entered_amt_crncy_id),
				a.entered_amt_crncy_id,
				a.accnt_crncy_amnt,
				gst.get_pssbl_val (a.accnt_crncy_id),
				a.accnt_crncy_id,
				a.func_cur_exchng_rate,
				a.accnt_cur_exchng_rate,
				a.src_trns_id_reconciled,
				b.is_prnt_accnt,
				b.has_sub_ledgers
			FROM
				accb.accb_trnsctn_details a
			LEFT OUTER JOIN accb.accb_chart_of_accnts b ON a.accnt_id = b.accnt_id
	WHERE (a.batch_id = rd_gl_btchID
		AND a.trns_status = '0')
ORDER BY
	a.transctn_id LOOP
		IF rd2.is_prnt_accnt = '1' OR rd2.has_sub_ledgers = '1' THEN
			msgs := msgs || chr(10) || 'Operation Cancelled because one cannot post directly into a parent or control account as present in the FF lines!' || chr(10) || 'ACCOUNT: ' || rd2.accnt_num || '.' || rd2.accnt_name || chr(10) || 'AMOUNT: ' || rd2.net_amount || chr(10) || 'DATE: ' || rd2.lnDte;
			IF msgid > 0 THEN
				updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, $3, $2);
				--msgs := rpt.getLogMsg(msgid);
			ELSE
				msgs := REPLACE(msgs, chr(10), '<br/>');
			END IF;
			v_reslt_1 := accb.updateANActvPrcss ('5', '0');
			RAISE EXCEPTION 'ERROR:%', msgs
				USING HINT = 'ERROR:' || msgs;
		END IF;
		IF rd2.accnt_num IS NULL OR rd2.accnt_name IS NULL THEN
			msgs := msgs || chr(10) || 'Operation Cancelled because selected Account does not exist in this Organisation as present in the FF lines!' || chr(10) || 'ACCOUNT: ID-' || rd2.accnt_id || '-' || COALESCE(rd2.accnt_num, 'UNKNOWN') || '.' || COALESCE(rd2.accnt_name, 'UNKNOWN') || chr(10) || 'AMOUNT: ' || rd2.net_amount || chr(10) || 'DATE: ' || rd2.lnDte;
			IF msgid > 0 THEN
				updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, $3, $2);
				--msgs := rpt.getLogMsg(msgid);
			ELSE
				msgs := REPLACE(msgs, chr(10), '<br/>');
			END IF;
			v_reslt_1 := accb.updateANActvPrcss ('5', '0');
			RAISE EXCEPTION 'ERROR:%', msgs
				USING HINT = 'ERROR:' || msgs;
		END IF;
		IF btchSrc != 'Period Close Process' THEN
			--Check if Transaction is permitted per Period Date and Budgetary Controls
			v_reslt_1 := accb.isTransPrmttd (orgidno, rd2.accnt_id, rd2.lnDte, rd2.net_amount);
			IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
				msgs := msgs || chr(10) || 'Operation Cancelled because the line with the ff details was detected as an INVALID Transaction!' || chr(10) || 'ACCOUNT: ' || rd2.accnt_num || '.' || rd2.accnt_name || chr(10) || 'AMOUNT: ' || rd2.net_amount || chr(10) || 'DATE: ' || rd2.lnDte || chr(10) || v_reslt_1;
				IF msgid > 0 THEN
					updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, $3, $2);
					--msgs := rpt.getLogMsg(msgid);
				ELSE
					msgs := REPLACE(msgs, chr(10), '<br/>');
				END IF;
				v_reslt_1 := accb.updateANActvPrcss ('5', '0');
				RAISE EXCEPTION 'ERROR:%', msgs
					USING HINT = 'ERROR:' || msgs;
			END IF;
		END IF;
		accntCurrID := rd2.accnt_crncy_id;
		funCurID := rd2.func_cur_id;
		accntCurrAmnt := rd2.accnt_crncy_amnt;
		acctyp := accb.get_accnt_type (rd2.accnt_id);
		hsBnUpdt := accb.hsTrnsUptdAcntBls (rd2.transctn_id, rd2.lnDte, rd2.accnt_id);
		IF hsBnUpdt = FALSE THEN
			dbt1 := rd2.dbt_amount;
			crdt1 := rd2.crdt_amount;
			net1 := rd2.net_amount;
			IF (funCurID != accntCurrID) THEN
				v_reslt_1 := accb.postAccntCurrTransaction (rd2.accnt_id, public.getSign (dbt1) * accntCurrAmnt, public.getSign (crdt1) * accntCurrAmnt, public.getSign (net1) * accntCurrAmnt, rd2.lnDte, rd2.transctn_id, accntCurrID, who_rn);
				IF v_reslt_1 LIKE 'ERROR:%' THEN
					errCntr := errCntr + 1;
					msgs := msgs || chr(10) || v_reslt_1;
				END IF;
			END IF;
			v_reslt_1 := accb.postTransaction (rd2.accnt_id, dbt1, crdt1, net1, rd2.lnDte, rd2.transctn_id, who_rn);
			IF v_reslt_1 LIKE 'ERROR:%' THEN
				errCntr := errCntr + 1;
				msgs := msgs || chr(10) || v_reslt_1;
			END IF;
		END IF;
		hsBnUpdt := accb.hsTrnsUptdAcntBls (rd2.transctn_id, rd2.lnDte, orgNetIcmAccntID);
		IF (hsBnUpdt = FALSE) THEN
			IF (acctyp = 'R') THEN
				v_reslt_1 := accb.postTransaction (orgNetIcmAccntID, rd2.dbt_amount, rd2.crdt_amount, rd2.net_amount, rd2.lnDte, rd2.transctn_id, who_rn);
				IF v_reslt_1 LIKE 'ERROR:%' THEN
					errCntr := errCntr + 1;
					msgs := msgs || chr(10) || v_reslt_1;
				END IF;
			ELSIF (acctyp = 'EX') THEN
				v_reslt_1 := accb.postTransaction (orgNetIcmAccntID, rd2.dbt_amount, rd2.crdt_amount, (- 1) * rd2.net_amount, rd2.lnDte, rd2.transctn_id, who_rn);
				IF v_reslt_1 LIKE 'ERROR:%' THEN
					errCntr := errCntr + 1;
					msgs := msgs || chr(10) || v_reslt_1;
				END IF;
			END IF;
		END IF;
		cntrlAcntID := gst.getGnrlRecNm ('accb.accb_chart_of_accnts', 'accnt_id', 'control_account_id', rd2.accnt_id)::integer;
		IF (cntrlAcntID > 0) THEN
			hsBnUpdt := accb.hsTrnsUptdAcntBls (rd2.transctn_id, rd2.lnDte, cntrlAcntID);
			IF (hsBnUpdt = FALSE) THEN
				cntrlAcntCurrID := gst.getGnrlRecNm ('accb.accb_chart_of_accnts', 'accnt_id', 'crncy_id', cntrlAcntID)::integer;
				dbt1 := rd2.dbt_amount;
				crdt1 := rd2.crdt_amount;
				net1 := rd2.net_amount;
				IF (funCurID != cntrlAcntCurrID AND cntrlAcntCurrID = accntCurrID) THEN
					v_reslt_1 := accb.postAccntCurrTransaction (cntrlAcntID, public.getSign (dbt1) * accntCurrAmnt, public.getSign (crdt1) * accntCurrAmnt, public.getSign (net1) * accntCurrAmnt, rd2.lnDte, rd2.transctn_id, accntCurrID, who_rn);
					IF v_reslt_1 LIKE 'ERROR:%' THEN
						errCntr := errCntr + 1;
						msgs := msgs || chr(10) || v_reslt_1;
					END IF;
				END IF;
				v_reslt_1 := accb.postTransaction (cntrlAcntID, rd2.dbt_amount, rd2.crdt_amount, rd2.net_amount, rd2.lnDte, rd2.transctn_id, who_rn);
				IF v_reslt_1 LIKE 'ERROR:%' THEN
					errCntr := errCntr + 1;
					msgs := msgs || chr(10) || v_reslt_1;
				END IF;
			END IF;
		END IF;
		v_reslt_1 := accb.chngeTrnsStatus (rd2.transctn_id, '1', who_rn);
		v_reslt_1 := accb.changeReconciledStatus (rd2.src_trns_id_reconciled, '1');
		IF msgid > 0 THEN
			msgs := msgs || chr(10) || 'Successfully posted transaction ID= ' || rd2.transctn_id;
			updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, $3, $2);
			--msgs := rpt.getLogMsg(msgid);
		END IF;
		cntr := cntr + 1;
	END LOOP;
			v_reslt_1 := accb.updateBatchStatus (rd_gl_btchID, '1', '0', who_rn);
			batchCntr := batchCntr + 1;
			msgs := msgs || chr(10) || 'Successfully Posted a Total of ' || cntr || ' Transaction(s) In the Journal Batch (' || rd0.batch_name || ')!';
		END LOOP;
	END IF;
	IF gl_btchID > 0 THEN
		v_reslt_1 := accb.reloadAcntChrtBals (gl_btchID, orgNetIcmAccntID, who_rn);
		IF v_reslt_1 LIKE 'ERROR:%' THEN
			errCntr := errCntr + 1;
			msgs := msgs || chr(10) || v_reslt_1;
		END IF;
	ELSE
		v_reslt_1 := accb.reloadAcntChrtBals1 (orgNetIcmAccntID, orgidno, who_rn);
		IF v_reslt_1 LIKE 'ERROR:%' THEN
			errCntr := errCntr + 1;
			msgs := msgs || chr(10) || v_reslt_1;
		END IF;
	END IF;
	msgs := msgs || chr(10) || v_reslt_1 || 'Reloading Chart of Account Balances!';
	IF msgid > 0 THEN
		updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, $3, $2);
		--msgs := rpt.getLogMsg(msgid);
	END IF;
	aesum := accb.get_COA_AESum (orgidno);
	crlsum := accb.get_COA_CRLSum (orgidno);
	IF (aesum != crlsum) THEN
		msgs := msgs || chr(10) || 'Batch of Transactions caused an IMBALANCE in the Accounting! A+E=' || aesum || chr(10) || ' C+R+L=' || crlsum || chr(10) || 'Diff=' || (aesum - crlsum);
		asAtDate := accb.getMinUnpstdTrnsDte (orgidno);
		IF (asAtDate != '') THEN
			v_reslt_1 := accb.correctImblnsProcess (asAtDate, orgidno, who_rn);
			IF v_reslt_1 LIKE 'ERROR:%' THEN
				errCntr := errCntr + 1;
				msgs := msgs || chr(10) || v_reslt_1;
			END IF;
		END IF;
	ELSE
		msgs := msgs || chr(10) || 'Batch of Transactions POSTED SUCCESSFULLY!=' || (aesum - crlsum);
	END IF;
	IF msgid > 0 THEN
		updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, $3, $2);
		--msgs := rpt.getLogMsg(msgid);
	ELSE
		msgs := REPLACE(msgs, chr(10), '<br/>');
	END IF;
	IF errCntr <= 0 AND batchCntr > 0 THEN
		msgs := 'Posting Completed Successfully!' || chr(10) || 'You can Review Logs for any details there may be. Thanks!';
	ELSIF errCntr <= 0 THEN
		msgs := msgs || chr(10) || 'TOTAL ERRORS:' || errCntr || ' in TOTAL BATCHES PROCESSED:' || batchCntr;
	ELSE
		msgs := msgs || chr(10) || 'TOTAL ERRORS:' || errCntr || ' in TOTAL BATCHES PROCESSED:' || batchCntr;
		RAISE EXCEPTION 'ERROR:%', msgs
			USING HINT = 'ERROR:' || msgs;
	END IF;
	--dbt1 := 1 / 0;
	RETURN REPLACE(msgs, chr(10), '<br/>');
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		msgs := msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
	IF msgid > 0 THEN
		updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, $3, $2);
		--msgs := rpt.getLogMsg(msgid);
	ELSE
		msgs := REPLACE(msgs, chr(10), '<br/>');
	END IF;
	RETURN msgs;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.post_gl_trns_inc_mnl (gl_btchid bigint, p_include_mnl character varying, who_rn bigint, run_date character varying, orgidno integer, p_msgid bigint, p_is_bulk_run character varying)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	msgid bigint := - 1;
	rd_gl_btchID bigint := - 1;
	btchSrc character varying(200);
	rd2 RECORD;
	rd1 RECORD;
	rd0 RECORD;
	msgs text := chr(10) || '';
	orgNetIcmAccntID integer := - 1;
	orgRetErnAccntID integer := - 1;
	cur_ID bigint := - 1;
	cntr integer := 0;
	errCntr integer := 0;
	batchCntr integer := 0;
	updtMsg bigint := 0;
	v_reslt_1 character varying(200) := '';
	dateStr character varying(21) := '';
	asAtDate character varying(21) := '';
	accntCurrID integer := - 1;
	funCurID integer := - 1;
	accntCurrAmnt numeric := 0;
	acctyp character varying(200) := '';
	hsBnUpdt boolean := FALSE;
	dbt1 numeric := 0;
	crdt1 numeric := 0;
	net1 numeric := 0;
	cntrlAcntID integer := - 1;
	cntrlAcntCurrID integer := - 1;
	aesum numeric := 0;
	crlsum numeric := 0;
BEGIN
	errCntr := 0;
	batchCntr := 0;
	dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	cur_ID := COALESCE(org.get_Orgfunc_Crncy_id (orgidno), - 1);
	orgRetErnAccntID := accb.get_OrgRetErnAccntID (orgidno);
	orgNetIcmAccntID := accb.get_orgnetincmaccntid (orgidno);
	btchSrc := accb.get_batch_source (gl_btchID);
	msgid := p_msgid;
	IF msgid <= 0 THEN
		msgid := rpt.getRptLogMsgID (gl_btchID, 'Posting Batch of Transactions');
		IF msgid <= 0 THEN
			v_reslt_1 := rpt.createRptLogMsg (dateStr || ' .... Posting Batch of Transactions is about to Start...', 'Posting Batch of Transactions', gl_btchID, dateStr, who_rn);
			msgid := rpt.getRptLogMsgID (gl_btchID, 'Posting Batch of Transactions');
		END IF;
	END IF;
	IF (accb.isThereANActvPrcss ('5') = '1') THEN
		msgs := msgs || chr(10) || 'Sorry an Account Posting Process is already on-going!\r\nKindly Wait for that Process to Finish and try again!';
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, run_date, who_rn);
			--msgs := rpt.getLogMsg(msgid);
		ELSE
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		RAISE EXCEPTION 'ERROR:%', msgs
			USING HINT = 'ERROR:' || msgs;
	ELSE
		v_reslt_1 := accb.updateANActvPrcss ('5', '1');
	END IF;
	IF coalesce(orgNetIcmAccntID, - 1) <= 0 OR coalesce(orgRetErnAccntID, - 1) <= 0 THEN
		msgs := msgs || chr(10) || 'Net Income and Retained Earnings Accounts Must be Created First!';
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, run_date, who_rn);
			--msgs := rpt.getLogMsg(msgid);
		ELSE
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		v_reslt_1 := accb.updateANActvPrcss ('5', '0');
		RAISE EXCEPTION 'ERROR:%', msgs
			USING HINT = 'ERROR:' || msgs;
	END IF;
	IF gl_btchID <= 0 AND p_is_bulk_run != '1' THEN
		msgs := msgs || chr(10) || 'Please select a saved Batch First!';
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, run_date, who_rn);
			--msgs := rpt.getLogMsg(msgid);
		ELSE
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		v_reslt_1 := accb.updateANActvPrcss ('5', '0');
		RAISE EXCEPTION 'ERROR:%', msgs
			USING HINT = 'ERROR:' || msgs;
	ELSE
		FOR rd0 IN
		SELECT
			batch_id,
			batch_name,
			batch_source,
			batch_status,
			CASE WHEN batch_status = '1' THEN
				'POSTED'
			ELSE
				'NOT POSTED'
			END pstng_status,
			batch_description,
			org_id,
			avlbl_for_postng,
			(
				SELECT
					count(1)
				FROM
					accb.accb_trnsctn_details y
				WHERE
					y.batch_id = a.batch_id) no_of_trns,
			(
				SELECT
					max(y.trnsctn_date)
				FROM
					accb.accb_trnsctn_details y
				WHERE
					y.batch_id = a.batch_id) lastBatchTrnsDate
		FROM
			accb.accb_trnsctn_batches a
		WHERE
			org_id = orgidno
			AND batch_status = '0'
			AND (avlbl_for_postng = '1'
				OR batch_id = gl_btchID
				OR UPPER(p_include_mnl) = 'YES')
			AND ((
					SELECT
						count(1)
					FROM
						accb.accb_trnsctn_details y
					WHERE
						y.batch_id = a.batch_id) > 0
					OR batch_source = 'Period Close Process')
			AND ((age(now(), to_timestamp(last_update_date, 'YYYY-MM-DD HH24:MI:SS')) >= interval '0 second'
					AND gl_btchID <= 0)
				OR (batch_id = gl_btchID))
		ORDER BY
			1 ASC
		LIMIT 500 OFFSET 0 LOOP
			btchSrc := rd0.batch_source;
			rd_gl_btchID := rd0.batch_id;
			v_reslt_1 := accb.updateANActvPrcss ('5', '1');
			UPDATE
				accb.accb_trnsctn_details
			SET
				dbt_amount = round(dbt_amount, 2),
				crdt_amount = round(crdt_amount, 2),
				net_amount = round((
					CASE WHEN accb.get_accnt_type (accnt_id) IN ('A', 'EX') THEN
					(dbt_amount - crdt_amount)
				ELSE
					(crdt_amount - dbt_amount)
					END), 2)
			WHERE
				batch_id = rd_gl_btchID;
			IF accb.gl_batch_trns_sum (rd_gl_btchID, 'Debit') != accb.gl_batch_trns_sum (rd_gl_btchID, 'Credit') THEN
				msgs := msgs || chr(10) || 'Cannot Post an Unbalanced Batch of Transactions!';
				IF msgid > 0 THEN
					updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, run_date, who_rn);
					--msgs := rpt.getLogMsg(msgid);
				END IF;
				IF msgid <= 0 THEN
					msgs := REPLACE(msgs, chr(10), '<br/>');
				END IF;
				v_reslt_1 := accb.updateANActvPrcss ('5', '0');
				RAISE EXCEPTION 'ERROR:%', msgs
					USING HINT = 'ERROR:' || msgs;
			END IF;
			cntr := 0;
			FOR rd1 IN
			SELECT
				substring(a.trnsctn_date FROM 1 FOR 10) trnsctndate,
				round(SUM(a.dbt_amount), 4) dbtamount,
				round(SUM(a.crdt_amount), 4) crdtamount
			FROM
				accb.accb_trnsctn_details a
			WHERE (a.batch_id = rd_gl_btchID)
		GROUP BY
			substring(a.trnsctn_date FROM 1 FOR 10)
		HAVING
			round(SUM(a.dbt_amount), 2) != round(SUM(a.crdt_amount), 2)
		ORDER BY
			1 LOOP
				IF cntr = 0 THEN
					msgs := msgs || chr(10) || 'Your transactions will cause your Balance Sheet to become Unbalanced on some Days!
                                                            Please make sure each day has equal debits and credits.
                                                            Check the ff Days:';
				END IF;
				msgs := msgs || chr(10) || rd1.trnsctndate || '     DR=' || rd1.dbtamount || '     CR=' || rd1.crdt_amount;
				cntr := cntr + 1;
			END LOOP;
			IF cntr > 0 THEN
				IF msgid > 0 THEN
					updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, run_date, who_rn);
					--msgs := rpt.getLogMsg(msgid);
				ELSE
					msgs := REPLACE(msgs, chr(10), '<br/>');
				END IF;
				v_reslt_1 := accb.updateANActvPrcss ('5', '0');
				RAISE EXCEPTION 'ERROR:%', msgs
					USING HINT = 'ERROR:' || msgs;
			END IF;
			cntr := 0;
			FOR rd2 IN
			SELECT
				a.transctn_id,
				b.accnt_num,
				b.accnt_name,
				a.transaction_desc,
				a.dbt_amount,
				a.crdt_amount,
				to_char(to_timestamp(a.trnsctn_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') lnDte,
				a.func_cur_id,
				a.batch_id,
				a.accnt_id,
				a.net_amount,
				a.trns_status,
				a.entered_amnt,
				gst.get_pssbl_val (a.entered_amt_crncy_id),
				a.entered_amt_crncy_id,
				a.accnt_crncy_amnt,
				gst.get_pssbl_val (a.accnt_crncy_id),
				a.accnt_crncy_id,
				a.func_cur_exchng_rate,
				a.accnt_cur_exchng_rate,
				a.src_trns_id_reconciled,
				b.is_prnt_accnt,
				b.has_sub_ledgers
			FROM
				accb.accb_trnsctn_details a
			LEFT OUTER JOIN accb.accb_chart_of_accnts b ON a.accnt_id = b.accnt_id
	WHERE (a.batch_id = rd_gl_btchID
		AND a.trns_status = '0')
ORDER BY
	a.transctn_id LOOP
		IF rd2.is_prnt_accnt = '1' OR rd2.has_sub_ledgers = '1' THEN
			msgs := msgs || chr(10) || 'Operation Cancelled because one cannot post directly into a parent or control account as present in the FF lines!' || chr(10) || 'ACCOUNT: ' || rd2.accnt_num || '.' || rd2.accnt_name || chr(10) || 'AMOUNT: ' || rd2.net_amount || chr(10) || 'DATE: ' || rd2.lnDte;
			IF msgid > 0 THEN
				updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, run_date, who_rn);
				--msgs := rpt.getLogMsg(msgid);
			ELSE
				msgs := REPLACE(msgs, chr(10), '<br/>');
			END IF;
			v_reslt_1 := accb.updateANActvPrcss ('5', '0');
			RAISE EXCEPTION 'ERROR:%', msgs
				USING HINT = 'ERROR:' || msgs;
		END IF;
		IF rd2.accnt_num IS NULL OR rd2.accnt_name IS NULL THEN
			msgs := msgs || chr(10) || 'Operation Cancelled because selected Account does not exist in this Organisation as present in the FF lines!' || chr(10) || 'ACCOUNT: ID-' || rd2.accnt_id || '-' || COALESCE(rd2.accnt_num, 'UNKNOWN') || '.' || COALESCE(rd2.accnt_name, 'UNKNOWN') || chr(10) || 'AMOUNT: ' || rd2.net_amount || chr(10) || 'DATE: ' || rd2.lnDte;
			IF msgid > 0 THEN
				updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, run_date, who_rn);
				--msgs := rpt.getLogMsg(msgid);
			ELSE
				msgs := REPLACE(msgs, chr(10), '<br/>');
			END IF;
			v_reslt_1 := accb.updateANActvPrcss ('5', '0');
			RAISE EXCEPTION 'ERROR:%', msgs
				USING HINT = 'ERROR:' || msgs;
		END IF;
		IF btchSrc != 'Period Close Process' THEN
			--Check if Transaction is permitted per Period Date and Budgetary Controls
			v_reslt_1 := accb.isTransPrmttd (orgidno, rd2.accnt_id, rd2.lnDte, rd2.net_amount);
			IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
				msgs := msgs || chr(10) || 'Operation Cancelled because the line with the ff details was detected as an INVALID Transaction!' || chr(10) || 'ACCOUNT: ' || rd2.accnt_num || '.' || rd2.accnt_name || chr(10) || 'AMOUNT: ' || rd2.net_amount || chr(10) || 'DATE: ' || rd2.lnDte || chr(10) || v_reslt_1;
				IF msgid > 0 THEN
					updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, run_date, who_rn);
					--msgs := rpt.getLogMsg(msgid);
				ELSE
					msgs := REPLACE(msgs, chr(10), '<br/>');
				END IF;
				v_reslt_1 := accb.updateANActvPrcss ('5', '0');
				RAISE EXCEPTION 'ERROR:%', msgs
					USING HINT = 'ERROR:' || msgs;
			END IF;
		END IF;
		accntCurrID := rd2.accnt_crncy_id;
		funCurID := rd2.func_cur_id;
		accntCurrAmnt := rd2.accnt_crncy_amnt;
		acctyp := accb.get_accnt_type (rd2.accnt_id);
		hsBnUpdt := accb.hsTrnsUptdAcntBls (rd2.transctn_id, rd2.lnDte, rd2.accnt_id);
		IF hsBnUpdt = FALSE THEN
			dbt1 := rd2.dbt_amount;
			crdt1 := rd2.crdt_amount;
			net1 := rd2.net_amount;
			IF (funCurID != accntCurrID) THEN
				v_reslt_1 := accb.postAccntCurrTransaction (rd2.accnt_id, public.getSign (dbt1) * accntCurrAmnt, public.getSign (crdt1) * accntCurrAmnt, public.getSign (net1) * accntCurrAmnt, rd2.lnDte, rd2.transctn_id, accntCurrID, who_rn);
				IF v_reslt_1 LIKE 'ERROR:%' THEN
					errCntr := errCntr + 1;
					msgs := msgs || chr(10) || v_reslt_1;
				END IF;
			END IF;
			v_reslt_1 := accb.postTransaction (rd2.accnt_id, dbt1, crdt1, net1, rd2.lnDte, rd2.transctn_id, who_rn);
			IF v_reslt_1 LIKE 'ERROR:%' THEN
				errCntr := errCntr + 1;
				msgs := msgs || chr(10) || v_reslt_1;
			END IF;
		END IF;
		hsBnUpdt := accb.hsTrnsUptdAcntBls (rd2.transctn_id, rd2.lnDte, orgNetIcmAccntID);
		IF (hsBnUpdt = FALSE) THEN
			IF (acctyp = 'R') THEN
				v_reslt_1 := accb.postTransaction (orgNetIcmAccntID, rd2.dbt_amount, rd2.crdt_amount, rd2.net_amount, rd2.lnDte, rd2.transctn_id, who_rn);
				IF v_reslt_1 LIKE 'ERROR:%' THEN
					errCntr := errCntr + 1;
					msgs := msgs || chr(10) || v_reslt_1;
				END IF;
			ELSIF (acctyp = 'EX') THEN
				v_reslt_1 := accb.postTransaction (orgNetIcmAccntID, rd2.dbt_amount, rd2.crdt_amount, (- 1) * rd2.net_amount, rd2.lnDte, rd2.transctn_id, who_rn);
				IF v_reslt_1 LIKE 'ERROR:%' THEN
					errCntr := errCntr + 1;
					msgs := msgs || chr(10) || v_reslt_1;
				END IF;
			END IF;
		END IF;
		cntrlAcntID := gst.getGnrlRecNm ('accb.accb_chart_of_accnts', 'accnt_id', 'control_account_id', rd2.accnt_id)::integer;
		IF (cntrlAcntID > 0) THEN
			hsBnUpdt := accb.hsTrnsUptdAcntBls (rd2.transctn_id, rd2.lnDte, cntrlAcntID);
			IF (hsBnUpdt = FALSE) THEN
				cntrlAcntCurrID := gst.getGnrlRecNm ('accb.accb_chart_of_accnts', 'accnt_id', 'crncy_id', cntrlAcntID)::integer;
				dbt1 := rd2.dbt_amount;
				crdt1 := rd2.crdt_amount;
				net1 := rd2.net_amount;
				IF (funCurID != cntrlAcntCurrID AND cntrlAcntCurrID = accntCurrID) THEN
					v_reslt_1 := accb.postAccntCurrTransaction (cntrlAcntID, public.getSign (dbt1) * accntCurrAmnt, public.getSign (crdt1) * accntCurrAmnt, public.getSign (net1) * accntCurrAmnt, rd2.lnDte, rd2.transctn_id, accntCurrID, who_rn);
					IF v_reslt_1 LIKE 'ERROR:%' THEN
						errCntr := errCntr + 1;
						msgs := msgs || chr(10) || v_reslt_1;
					END IF;
				END IF;
				v_reslt_1 := accb.postTransaction (cntrlAcntID, rd2.dbt_amount, rd2.crdt_amount, rd2.net_amount, rd2.lnDte, rd2.transctn_id, who_rn);
				IF v_reslt_1 LIKE 'ERROR:%' THEN
					errCntr := errCntr + 1;
					msgs := msgs || chr(10) || v_reslt_1;
				END IF;
			END IF;
		END IF;
		v_reslt_1 := accb.chngeTrnsStatus (rd2.transctn_id, '1', who_rn);
		v_reslt_1 := accb.changeReconciledStatus (rd2.src_trns_id_reconciled, '1');
		IF msgid > 0 THEN
			msgs := msgs || chr(10) || 'Successfully posted transaction ID= ' || rd2.transctn_id;
			updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, run_date, who_rn);
			--msgs := rpt.getLogMsg(msgid);
		END IF;
		cntr := cntr + 1;
	END LOOP;
			v_reslt_1 := accb.updateBatchStatus (rd_gl_btchID, '1', '0', who_rn);
			batchCntr := batchCntr + 1;
			msgs := msgs || chr(10) || 'Successfully Posted a Total of ' || cntr || ' Transaction(s) In the Journal Batch (' || rd0.batch_name || ')!';
		END LOOP;
	END IF;
	IF gl_btchID > 0 THEN
		v_reslt_1 := accb.reloadAcntChrtBals (gl_btchID, orgNetIcmAccntID, who_rn);
		IF v_reslt_1 LIKE 'ERROR:%' THEN
			errCntr := errCntr + 1;
			msgs := msgs || chr(10) || v_reslt_1;
		END IF;
	ELSE
		v_reslt_1 := accb.reloadAcntChrtBals1 (orgNetIcmAccntID, orgidno, who_rn);
		IF v_reslt_1 LIKE 'ERROR:%' THEN
			errCntr := errCntr + 1;
			msgs := msgs || chr(10) || v_reslt_1;
		END IF;
	END IF;
	msgs := msgs || chr(10) || v_reslt_1 || 'Reloading Chart of Account Balances!';
	IF msgid > 0 THEN
		updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, run_date, who_rn);
		--msgs := rpt.getLogMsg(msgid);
	END IF;
	aesum := accb.get_COA_AESum (orgidno);
	crlsum := accb.get_COA_CRLSum (orgidno);
	IF (aesum != crlsum) THEN
		msgs := msgs || chr(10) || 'Batch of Transactions caused an IMBALANCE in the Accounting! A+E=' || aesum || chr(10) || ' C+R+L=' || crlsum || chr(10) || 'Diff=' || (aesum - crlsum);
		asAtDate := accb.getMinUnpstdTrnsDte (orgidno);
		IF (asAtDate != '') THEN
			v_reslt_1 := accb.correctImblnsProcess (asAtDate, orgidno, who_rn);
			IF v_reslt_1 LIKE 'ERROR:%' THEN
				errCntr := errCntr + 1;
				msgs := msgs || chr(10) || v_reslt_1;
			END IF;
		END IF;
	ELSE
		msgs := msgs || chr(10) || 'Batch of Transactions POSTED SUCCESSFULLY!=' || (aesum - crlsum);
	END IF;
	IF msgid > 0 THEN
		updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, run_date, who_rn);
		--msgs := rpt.getLogMsg(msgid);
	ELSE
		msgs := REPLACE(msgs, chr(10), '<br/>');
	END IF;
	IF errCntr <= 0 AND batchCntr > 0 THEN
		msgs := 'Posting Completed Successfully!' || chr(10) || 'You can Review Logs for any details there may be. Thanks!';
	ELSIF errCntr <= 0 THEN
		msgs := msgs || chr(10) || 'TOTAL ERRORS:' || errCntr || ' in TOTAL BATCHES PROCESSED:' || batchCntr;
	ELSE
		msgs := msgs || chr(10) || 'TOTAL ERRORS:' || errCntr || ' in TOTAL BATCHES PROCESSED:' || batchCntr;
		RAISE EXCEPTION 'ERROR:%', msgs
			USING HINT = 'ERROR:' || msgs;
	END IF;
	--dbt1 := 1 / 0;
	RETURN REPLACE(msgs, chr(10), '<br/>');
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		msgs := msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
	IF msgid > 0 THEN
		updtMsg := rpt.updateRptLogMsg1 (msgid, msgs, run_date, who_rn);
		--msgs := rpt.getLogMsg(msgid);
	ELSE
		msgs := REPLACE(msgs, chr(10), '<br/>');
	END IF;
	RETURN msgs;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.reloadAcntChrtBals1 (netaccntid integer, p_OrgID integer, p_usrID bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	rd2 RECORD;
	rd1 RECORD;
	msgs text := chr(10) || '';
	v_reslt_1 character varying(200) := '';
	dateStr character varying(21) := '';
	dateStr1 character varying(21) := '';
	lstNetBals numeric := 0;
	lstDbtBals numeric := 0;
	lstCrdtBals numeric := 0;
	cntrlAcntID integer := - 1;
	v_cntr integer := 0;
BEGIN
	dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
	dateStr1 := to_char(now(), 'YYYY-MM-DD');
	lstNetBals := 0;
	lstDbtBals := 0;
	lstCrdtBals := 0;
	FOR rd1 IN
	SELECT
		a.accnt_id,
		a.debit_balance,
		a.credit_balance,
		a.net_balance,
		to_char(to_timestamp(a.balance_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') bsldte
	FROM
		accb.accb_chart_of_accnts a
	WHERE
		a.org_id = p_OrgID
	ORDER BY
		a.accnt_typ_id,
		a.report_line_no,
		a.accnt_num LOOP
			v_cntr := 0;
			FOR rd2 IN
			SELECT
				a.dbt_bal,
				a.crdt_bal,
				a.net_balance,
				to_char(to_timestamp(a.as_at_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') as_at_date
			FROM
				accb.accb_accnt_daily_bals a
			WHERE (a.accnt_id = rd1.accnt_id)
		ORDER BY
			a.as_at_date DESC,
			a.daily_bals_id DESC
		LIMIT 1 OFFSET 0 LOOP
			lstNetBals := rd2.net_balance;
			lstDbtBals := rd2.dbt_bal;
			lstCrdtBals := rd2.crdt_bal;
			v_reslt_1 := accb.updtAcntChrtBals (rd1.accnt_id, lstDbtBals, lstCrdtBals, lstNetBals, rd2.as_at_date, p_usrID);
			v_cntr := v_cntr + 1;
			--msgs := msgs || chr(10) || v_reslt_1;
		END LOOP;
			IF v_cntr <= 0 THEN
				v_reslt_1 := accb.updtAcntChrtBals (rd1.accnt_id, 0, 0, 0, to_char(now(), 'DD-Mon-YYYY HH24:MI:SS'), p_usrID);
			END IF;
			--//get control accnt id
			cntrlAcntID := gst.getGnrlRecNm ('accb.accb_chart_of_accnts', 'accnt_id', 'control_account_id', rd1.accnt_id)::integer;
			IF (cntrlAcntID > 0) THEN
				v_cntr := 0;
				FOR rd2 IN
				SELECT
					a.dbt_bal,
					a.crdt_bal,
					a.net_balance,
					to_char(to_timestamp(a.as_at_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') as_at_date
				FROM
					accb.accb_accnt_daily_bals a
				WHERE (a.accnt_id = cntrlAcntID)
			ORDER BY
				a.as_at_date DESC,
				a.daily_bals_id DESC
			LIMIT 1 OFFSET 0 LOOP
				lstNetBals := rd2.net_balance;
				lstDbtBals := rd2.dbt_bal;
				lstCrdtBals := rd2.crdt_bal;
				v_reslt_1 := accb.updtAcntChrtBals (cntrlAcntID, lstDbtBals, lstCrdtBals, lstNetBals, rd2.as_at_date, p_usrID);
				v_cntr := v_cntr + 1;
				-- msgs := msgs || chr(10) || v_reslt_1;
			END LOOP;
				IF v_cntr <= 0 THEN
					v_reslt_1 := accb.updtAcntChrtBals (cntrlAcntID, 0, 0, 0, to_char(now(), 'DD-Mon-YYYY HH24:MI:SS'), p_usrID);
				END IF;
			END IF;
		END LOOP;
	IF (netaccntid > 0) THEN
		v_cntr := 0;
		FOR rd2 IN
		SELECT
			a.dbt_bal,
			a.crdt_bal,
			a.net_balance,
			to_char(to_timestamp(a.as_at_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') as_at_date
		FROM
			accb.accb_accnt_daily_bals a
		WHERE (a.accnt_id = netaccntid)
	ORDER BY
		a.as_at_date DESC,
		a.daily_bals_id DESC
	LIMIT 1 OFFSET 0 LOOP
		lstNetBals := rd2.net_balance;
		lstDbtBals := rd2.dbt_bal;
		lstCrdtBals := rd2.crdt_bal;
		v_reslt_1 := accb.updtAcntChrtBals (netaccntid, lstDbtBals, lstCrdtBals, lstNetBals, rd2.as_at_date, p_usrID);
		v_cntr := v_cntr + 1;
		--msgs := msgs || chr(10) || v_reslt_1;
	END LOOP;
		IF v_cntr <= 0 THEN
			v_reslt_1 := accb.updtAcntChrtBals (netaccntid, 0, 0, 0, to_char(now(), 'DD-Mon-YYYY HH24:MI:SS'), p_usrID);
		END IF;
	END IF;
	msgs := msgs || chr(10) || 'SUCCESS:';
	RETURN msgs;
EXCEPTION
	WHEN OTHERS THEN
		msgs := msgs || chr(10) || 'ERROR:';
	msgs := msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
	RETURN msgs;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.reloadOneAcntChrtBals (accntID integer, netaccntid integer, p_usrID bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	rd2 RECORD;
	msgs text := chr(10) || '';
	v_reslt_1 character varying(200) := '';
	dateStr character varying(21) := '';
	dateStr1 character varying(21) := '';
	lstNetBals numeric := 0;
	lstDbtBals numeric := 0;
	lstCrdtBals numeric := 0;
	cntrlAcntID integer := - 1;
BEGIN
	dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
	dateStr1 := to_char(now(), 'YYYY-MM-DD');
	lstNetBals := 0;
	lstDbtBals := 0;
	lstCrdtBals := 0;
	FOR rd2 IN
	SELECT
		a.dbt_bal,
		a.crdt_bal,
		a.net_balance,
		to_char(to_timestamp(a.as_at_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') as_at_date
	FROM
		accb.accb_accnt_daily_bals a
	WHERE (to_timestamp(a.as_at_date, 'YYYY-MM-DD') <= to_timestamp(dateStr1, 'YYYY-MM-DD')
		AND a.accnt_id = accntID)
ORDER BY
	to_timestamp(a.as_at_date, 'YYYY-MM-DD') DESC
LIMIT 1 OFFSET 0 LOOP
	lstNetBals := rd2.net_balance;
	lstDbtBals := rd2.dbt_bal;
	lstCrdtBals := rd2.crdt_bal;
	v_reslt_1 := accb.updtAcntChrtBals (accntID, lstDbtBals, lstCrdtBals, lstNetBals, rd2.as_at_date, p_usrID);
	--msgs := msgs || chr(10) || v_reslt_1;
END LOOP;
	cntrlAcntID := gst.getGnrlRecNm ('accb.accb_chart_of_accnts', 'accnt_id', 'control_account_id', accntID)::integer;
	IF (cntrlAcntID > 0) THEN
		FOR rd2 IN
		SELECT
			a.dbt_bal,
			a.crdt_bal,
			a.net_balance,
			to_char(to_timestamp(a.as_at_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') as_at_date
		FROM
			accb.accb_accnt_daily_bals a
		WHERE (to_timestamp(a.as_at_date, 'YYYY-MM-DD') <= to_timestamp(dateStr1, 'YYYY-MM-DD')
			AND a.accnt_id = cntrlAcntID)
	ORDER BY
		to_timestamp(a.as_at_date, 'YYYY-MM-DD') DESC
	LIMIT 1 OFFSET 0 LOOP
		lstNetBals := rd2.net_balance;
		lstDbtBals := rd2.dbt_bal;
		lstCrdtBals := rd2.crdt_bal;
		v_reslt_1 := accb.updtAcntChrtBals (cntrlAcntID, lstDbtBals, lstCrdtBals, lstNetBals, rd2.as_at_date, p_usrID);
		--msgs := msgs || chr(10) || v_reslt_1;
	END LOOP;
	END IF;
	IF (netaccntid > 0) THEN
		FOR rd2 IN
		SELECT
			a.dbt_bal,
			a.crdt_bal,
			a.net_balance,
			to_char(to_timestamp(a.as_at_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') as_at_date
		FROM
			accb.accb_accnt_daily_bals a
		WHERE (to_timestamp(a.as_at_date, 'YYYY-MM-DD') <= to_timestamp(dateStr1, 'YYYY-MM-DD')
			AND a.accnt_id = netaccntid)
	ORDER BY
		to_timestamp(a.as_at_date, 'YYYY-MM-DD') DESC
	LIMIT 1 OFFSET 0 LOOP
		lstNetBals := rd2.net_balance;
		lstDbtBals := rd2.dbt_bal;
		lstCrdtBals := rd2.crdt_bal;
		v_reslt_1 := accb.updtAcntChrtBals (netaccntid, lstDbtBals, lstCrdtBals, lstNetBals, rd2.as_at_date, p_usrID);
		--msgs := msgs || chr(10) || v_reslt_1;
	END LOOP;
	END IF;
	msgs := msgs || chr(10) || 'SUCCESS:';
	RETURN msgs;
EXCEPTION
	WHEN OTHERS THEN
		msgs := msgs || chr(10) || 'ERROR:';
	msgs := msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
	RETURN msgs;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.reloadAcntChrtBals (btchid bigint, netaccntid integer, p_usrID bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	rd2 RECORD;
	rd1 RECORD;
	msgs text := chr(10) || '';
	v_reslt_1 character varying(200) := '';
	dateStr character varying(21) := '';
	dateStr1 character varying(21) := '';
	lstNetBals numeric := 0;
	lstDbtBals numeric := 0;
	lstCrdtBals numeric := 0;
	cntrlAcntID integer := - 1;
BEGIN
	dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
	dateStr1 := to_char(now(), 'YYYY-MM-DD');
	lstNetBals := 0;
	lstDbtBals := 0;
	lstCrdtBals := 0;
	FOR rd1 IN SELECT DISTINCT
		a.accnt_id
	FROM
		accb.accb_trnsctn_details a
	LEFT OUTER JOIN accb.accb_chart_of_accnts b ON a.accnt_id = b.accnt_id
WHERE (a.batch_id = btchid)
ORDER BY
	a.accnt_id LOOP
		FOR rd2 IN
		SELECT
			a.dbt_bal,
			a.crdt_bal,
			a.net_balance,
			to_char(to_timestamp(a.as_at_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') as_at_date
		FROM
			accb.accb_accnt_daily_bals a
		WHERE (to_timestamp(a.as_at_date, 'YYYY-MM-DD') <= to_timestamp(dateStr1, 'YYYY-MM-DD')
			AND a.accnt_id = rd1.accnt_id)
	ORDER BY
		to_timestamp(a.as_at_date, 'YYYY-MM-DD') DESC
	LIMIT 1 OFFSET 0 LOOP
		lstNetBals := rd2.net_balance;
		lstDbtBals := rd2.dbt_bal;
		lstCrdtBals := rd2.crdt_bal;
		v_reslt_1 := accb.updtAcntChrtBals (rd1.accnt_id, lstDbtBals, lstCrdtBals, lstNetBals, rd2.as_at_date, p_usrID);
		--msgs := msgs || chr(10) || v_reslt_1;
	END LOOP;
		--//get control accnt id
		cntrlAcntID := gst.getGnrlRecNm ('accb.accb_chart_of_accnts', 'accnt_id', 'control_account_id', rd1.accnt_id)::integer;
		IF (cntrlAcntID > 0) THEN
			FOR rd2 IN
			SELECT
				a.dbt_bal,
				a.crdt_bal,
				a.net_balance,
				to_char(to_timestamp(a.as_at_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') as_at_date
			FROM
				accb.accb_accnt_daily_bals a
			WHERE (to_timestamp(a.as_at_date, 'YYYY-MM-DD') <= to_timestamp(dateStr1, 'YYYY-MM-DD')
				AND a.accnt_id = cntrlAcntID)
		ORDER BY
			to_timestamp(a.as_at_date, 'YYYY-MM-DD') DESC
		LIMIT 1 OFFSET 0 LOOP
			lstNetBals := rd2.net_balance;
			lstDbtBals := rd2.dbt_bal;
			lstCrdtBals := rd2.crdt_bal;
			v_reslt_1 := accb.updtAcntChrtBals (cntrlAcntID, lstDbtBals, lstCrdtBals, lstNetBals, rd2.as_at_date, p_usrID);
			--msgs := msgs || chr(10) || v_reslt_1;
		END LOOP;
		END IF;
	END LOOP;
	IF (netaccntid > 0) THEN
		FOR rd2 IN
		SELECT
			a.dbt_bal,
			a.crdt_bal,
			a.net_balance,
			to_char(to_timestamp(a.as_at_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') as_at_date
		FROM
			accb.accb_accnt_daily_bals a
		WHERE (to_timestamp(a.as_at_date, 'YYYY-MM-DD') <= to_timestamp(dateStr1, 'YYYY-MM-DD')
			AND a.accnt_id = netaccntid)
	ORDER BY
		to_timestamp(a.as_at_date, 'YYYY-MM-DD') DESC
	LIMIT 1 OFFSET 0 LOOP
		lstNetBals := rd2.net_balance;
		lstDbtBals := rd2.dbt_bal;
		lstCrdtBals := rd2.crdt_bal;
		v_reslt_1 := accb.updtAcntChrtBals (netaccntid, lstDbtBals, lstCrdtBals, lstNetBals, rd2.as_at_date, p_usrID);
		--msgs := msgs || chr(10) || v_reslt_1;
	END LOOP;
	END IF;
	msgs := msgs || chr(10) || 'SUCCESS:';
	RETURN msgs;
EXCEPTION
	WHEN OTHERS THEN
		msgs := msgs || chr(10) || 'ERROR:';
	msgs := msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
	RETURN msgs;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.correctImblnsProcess (asAtDate character varying, p_OrgID integer, p_usrID bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	rd1 RECORD;
	msgs text := chr(10) || '';
	v_reslt_1 character varying(200) := '';
	trnsAftaDate character varying(21) := '';
	acctyp character varying(21) := '';
	dbt1 numeric := 0;
	crdt1 numeric := 0;
	net1 numeric := 0;
	suspns_accnt integer := - 1;
	ret_accnt integer := - 1;
	net_accnt integer := - 1;
	StartDate timestamp;
	EndDate timestamp;
	rDate timestamp;
BEGIN
	suspns_accnt := accb.get_OrgSuspns_Accnt (p_OrgID);
	ret_accnt := accb.get_OrgRetErnAccntID (p_OrgID);
	net_accnt := accb.get_orgnetincmaccntid (p_OrgID);
	trnsAftaDate := to_char(to_timestamp(asAtDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD');
	DELETE FROM accb.accb_trnsctn_batches
	WHERE batch_source = 'Banking'
		AND batch_id NOT IN (
			SELECT
				gl_batch_id
			FROM
				mcf.mcf_gl_interface);
	DELETE FROM accb.accb_trnsctn_details
	WHERE batch_id NOT IN (
			SELECT
				batch_id
			FROM
				accb.accb_trnsctn_batches);
	DELETE FROM accb.accb_trnsctn_smmrys
	WHERE batch_id NOT IN (
			SELECT
				batch_id
			FROM
				accb.accb_trnsctn_batches);
	DELETE FROM accb.accb_trnsctn_amnt_breakdown
	WHERE transaction_id > 0
		AND transaction_id NOT IN (
			SELECT
				transctn_id
			FROM
				accb.accb_trnsctn_details);
	DELETE FROM accb.accb_trnsctn_amnt_breakdown
	WHERE trnsctn_smmry_id > 0
		AND trnsctn_smmry_id NOT IN (
			SELECT
				trnsctn_smmry_id
			FROM
				accb.accb_trnsctn_smmrys);
	UPDATE
		mcf.mcf_gl_interface
	SET
		gl_batch_id = - 1
	WHERE
		gl_batch_id > 0
		AND gl_batch_id NOT IN (
			SELECT
				batch_id
			FROM
				accb.accb_trnsctn_batches);
	DELETE FROM accb.accb_accnt_daily_bals
	WHERE daily_bals_id IN (
			SELECT
				tbl1.db1
			FROM (
				SELECT
					count(daily_bals_id),
					accnt_id,
					as_at_date,
					MAX(daily_bals_id) db1
				FROM
					accb.accb_accnt_daily_bals
				GROUP BY
					accnt_id,
					as_at_date
				HAVING
					count(daily_bals_id) > 1) tbl1);
	UPDATE
		accb.accb_accnt_daily_bals a
	SET
		dbt_bal = 0,
		crdt_bal = 0,
		net_balance = 0
	WHERE
		as_at_date >= trnsAftaDate;
	UPDATE
		accb.accb_trnsctn_details
	SET
		dbt_amount = round(dbt_amount, 2),
		crdt_amount = round(crdt_amount, 2),
		net_amount = round((
			CASE WHEN accb.get_accnt_type (accnt_id) IN ('A', 'EX') THEN
			(dbt_amount - crdt_amount)
		ELSE
			(crdt_amount - dbt_amount)
			END), 2)
	WHERE
		dbt_amount != round(dbt_amount, 2)
		OR crdt_amount != round(crdt_amount, 2)
		OR net_amount != round((
			CASE WHEN accb.get_accnt_type (accnt_id) IN ('A', 'EX') THEN
			(dbt_amount - crdt_amount)
		ELSE
			(crdt_amount - dbt_amount)
			END), 2);
	StartDate := to_timestamp(trnsAftaDate || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
	EndDate := to_timestamp('01' || substr(to_char(now(), 'DD-Mon-YYYY HH24:MI:SS'), 3, 9) || ' 23:59:59', 'DD-Mon-YYYY HH24:MI:SS') + interval '1 month' - interval '1 day';
	rDate := StartDate;
	WHILE (rDate <= EndDate)
	LOOP
		trnsAftaDate := to_char(rDate, 'YYYY-MM-DD');
		FOR rd1 IN
		SELECT
			*
		FROM (
			SELECT
				a.daily_bals_id,
				a.accnt_id,
				b.accnt_name,
				b.accnt_type,
				round(accb.get_accnt_trnsSum (a.accnt_id, 'dbt_amount', as_at_date || ' 23:59:59'), 2) - a.dbt_bal nw_dbbt_diff,
				round(accb.get_accnt_trnsSum (a.accnt_id, 'crdt_amount', as_at_date || ' 23:59:59'), 2) - a.crdt_bal nw_crdt_diff,
				round(accb.get_accnt_trnsSum (a.accnt_id, 'net_amount', as_at_date || ' 23:59:59'), 2) - a.net_balance nw_net_diff,
				to_char(to_timestamp(a.as_at_date || ' 23:59:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') trns_date
			FROM
				accb.accb_accnt_daily_bals a,
				accb.accb_chart_of_accnts b
			WHERE
				a.accnt_id = b.accnt_id
				AND b.org_id = p_OrgID
				AND b.is_net_income != '1'
				AND b.has_sub_ledgers != '1'
				AND a.as_at_date = trnsAftaDate
			ORDER BY
				a.as_at_date ASC) tbl1
	WHERE
		tbl1.nw_dbbt_diff != 0
			OR tbl1.nw_crdt_diff != 0
			OR tbl1.nw_net_diff != 0 LOOP
				acctyp := accb.get_accnt_type (rd1.accnt_id);
				dbt1 := rd1.nw_dbbt_diff;
				crdt1 := rd1.nw_crdt_diff;
				net1 := rd1.nw_net_diff;
				v_reslt_1 := accb.postTransaction (rd1.accnt_id, dbt1, crdt1, net1, rd1.trns_date, - 993, p_usrID);
				--msgs := msgs || chr(10) || v_reslt_1;
			END LOOP;
		FOR rd1 IN
		SELECT
			*
		FROM (
			SELECT
				a.daily_bals_id,
				a.accnt_id,
				b.accnt_name,
				b.accnt_type,
				round(accb.get_accnt_trnsSum (a.accnt_id, 'dbt_amount', as_at_date || ' 23:59:59'), 2) - a.dbt_bal nw_dbbt_diff,
				round(accb.get_accnt_trnsSum (a.accnt_id, 'crdt_amount', as_at_date || ' 23:59:59'), 2) - a.crdt_bal nw_crdt_diff,
				round(accb.get_accnt_trnsSum (a.accnt_id, 'net_amount', as_at_date || ' 23:59:59'), 2) - a.net_balance nw_net_diff,
				to_char(to_timestamp(a.as_at_date || ' 23:59:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') trns_date
			FROM
				accb.accb_accnt_daily_bals a,
				accb.accb_chart_of_accnts b
			WHERE
				a.accnt_id = b.accnt_id
				AND b.org_id = p_OrgID
				AND b.is_net_income != '1'
				AND b.has_sub_ledgers = '1'
				AND a.as_at_date = trnsAftaDate
			ORDER BY
				a.as_at_date ASC) tbl1
	WHERE
		tbl1.nw_dbbt_diff != 0
			OR tbl1.nw_crdt_diff != 0
			OR tbl1.nw_net_diff != 0 LOOP
				acctyp := accb.get_accnt_type (rd1.accnt_id);
				dbt1 := rd1.nw_dbbt_diff;
				crdt1 := rd1.nw_crdt_diff;
				net1 := rd1.nw_net_diff;
				v_reslt_1 := accb.postTransaction (rd1.accnt_id, dbt1, crdt1, net1, rd1.trns_date, - 993, p_usrID);
				--msgs := msgs || chr(10) || v_reslt_1;
			END LOOP;
		FOR rd1 IN
		SELECT
			a.daily_bals_id,
			a.accnt_id,
			b.accnt_name,
			b.accnt_type,
			round(accb.get_accnttype_trnsSum (p_OrgID, 'R', 'dbt_amount', as_at_date || ' 23:59:59'), 2) + round(accb.get_accnttype_trnsSum (p_OrgID, 'EX', 'dbt_amount', as_at_date || ' 23:59:59'), 2) - a.dbt_bal nw_dbbt_diff,
			round(accb.get_accnttype_trnsSum (p_OrgID, 'R', 'crdt_amount', as_at_date || ' 23:59:59'), 2) + round(accb.get_accnttype_trnsSum (p_OrgID, 'EX', 'crdt_amount', as_at_date || ' 23:59:59'), 2) - a.crdt_bal nw_crdt_diff,
			round(accb.get_accnttype_trnsSum (p_OrgID, 'R', 'net_amount', as_at_date || ' 23:59:59'), 2) - round(accb.get_accnttype_trnsSum (p_OrgID, 'EX', 'net_amount', as_at_date || ' 23:59:59'), 2) - a.net_balance nw_net_diff,
			to_char(to_timestamp(a.as_at_date || ' 23:59:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') trns_date
		FROM
			accb.accb_accnt_daily_bals a,
			accb.accb_chart_of_accnts b
		WHERE
			a.accnt_id = b.accnt_id
			AND b.org_id = p_OrgID
			AND b.is_net_income = '1'
			AND b.has_sub_ledgers != '1'
			AND a.as_at_date = trnsAftaDate
		ORDER BY
			a.as_at_date ASC LOOP
				acctyp := accb.get_accnt_type (rd1.accnt_id);
				dbt1 := rd1.nw_dbbt_diff;
				crdt1 := rd1.nw_crdt_diff;
				net1 := rd1.nw_net_diff;
				v_reslt_1 := accb.postTransaction (rd1.accnt_id, dbt1, crdt1, net1, rd1.trns_date, - 993, p_usrID);
				--msgs := msgs || chr(10) || v_reslt_1;
			END LOOP;
		rDate := rDate + interval '1 day';
	END LOOP;
	v_reslt_1 := accb.reloadAcntChrtBals1 (net_accnt, p_OrgID, p_usrID);
	--msgs := msgs || chr(10) || v_reslt_1;
	msgs := msgs || chr(10) || 'SUCCESS:';
	RETURN msgs;
EXCEPTION
	WHEN OTHERS THEN
		msgs := msgs || chr(10) || 'ERROR:';
	msgs := msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
	RETURN msgs;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.sendJournalsToGL (p_intrfcTblNme character varying, p_interval character varying, p_prcID integer, p_msgid bigint, p_orgID integer, p_who_rn bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res numeric := 0;
	v_reslt_1 text := '';
	v_errmsg text := '';
	v_SQL text := '';
	rd1 RECORD;
	rd2 RECORD;
	v_allwPyActng character varying(200) := '';
	v_allwPyActngID integer := - 1;
	v_dbtsum numeric := 0;
	v_crdtsum numeric := 0;
	v_cntr integer := - 1;
	v_dateStr character varying(21) := '';
	v_btchPrfx character varying(20) := '';
	v_todaysGlBatch character varying(200) := '';
	v_todbatchid bigint := - 1;
	v_accntCurrID integer := - 1;
	v_src_ids text := '';
	v_entrdAmnt numeric := 0;
	v_dbtCrdt character varying(21) := '';
	v_accntCurrRate numeric := 0;
	v_actlAmnts1 numeric := 0;
	v_actlAmnts2 numeric := 0;
	updtMsg bigint := 0;
BEGIN
	UPDATE
		accb.accb_trnsctn_batches
	SET
		avlbl_for_postng = '1'
	WHERE
		avlbl_for_postng = '0'
		AND batch_source != 'Manual';
	IF (gst.getEnbldPssblValID ('NO', gst.getenbldlovid ('Allow Inventory to be Costed')) > 0) THEN
		v_reslt_1 := accb.zeroInterfaceValues (p_orgID, 'scm.scm_gl_interface', p_who_rn);
		IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
		END IF;
	END IF;
	v_allwPyActngID := gst.getEnbldPssblValID ('Allow Payroll to be Auto-Accounted', gst.getenbldlovid ('All Other General Setups'));
	v_allwPyActng := gst.get_pssbl_val_desc (v_allwPyActngID);
	IF (upper(v_allwPyActng) = 'NO') THEN
		v_reslt_1 := accb.zeroInterfaceValues (p_orgID, 'pay.pay_gl_interface', p_who_rn);
	END IF;
	v_dbtsum := 0;
	v_crdtsum := 0;
	v_cntr := 0;
	v_SQL := 'DELETE FROM ' || p_intrfcTblNme || ' WHERE gl_batch_id<=0 and accnt_id IN (select b.accnt_id from ' || 'accb.accb_chart_of_accnts b where b.org_id=' || p_orgID || ') and dbt_amount=0 and crdt_amount=0 and net_amount=0';
	EXECUTE v_SQL;
	FOR rd1 IN
	SELECT
		accnt_id,
		trnsdte,
		dbt_sum,
		crdt_sum,
		net_sum,
		func_cur_id
	FROM
		accb.get_gl_intrfc_recs (p_intrfcTblNme, p_orgID, p_interval)
		LOOP
			v_dbtsum := v_dbtsum + rd1.dbt_sum;
			v_crdtsum := v_crdtsum + rd1.crdt_sum;
			v_cntr := v_cntr + 1;
		END LOOP;
	v_dbtsum := round(v_dbtsum, 2);
	v_crdtsum := round(v_crdtsum, 2);
	IF (v_cntr = 0) THEN
		v_errmsg := chr(10) || 'Cannot Transfer Transactions to GL because NO Interface Transactions were found!';
		updtMsg := rpt.updateRptLogMsg1 (p_msgid, v_errmsg, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);
		RETURN 'SUCCESS:';

		/*RAISE EXCEPTION USING
		 ERRCODE = 'RHERR',
		 MESSAGE = v_errmsg,
		 HINT = v_errmsg;*/
	END IF;
	IF (v_dbtsum != v_crdtsum) THEN
		v_errmsg := chr(10) || 'Cannot Transfer Transactions to GL because' || ' Transactions in the GL Interface are not Balanced! Difference=' || abs(v_dbtsum - v_crdtsum);
		updtMsg := rpt.updateRptLogMsg1 (p_msgid, v_errmsg, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = v_errmsg, HINT = v_errmsg;
	END IF;
	v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
	v_btchPrfx := 'Internal Payments';
	IF (p_intrfcTblNme = 'scm.scm_gl_interface') THEN
		v_btchPrfx := 'Inventory';
	ELSIF (p_intrfcTblNme = 'mcf.mcf_gl_interface') THEN
		v_btchPrfx := 'Banking';
	ELSIF (p_intrfcTblNme = 'vms.vms_gl_interface') THEN
		v_btchPrfx := 'Vault Management';
	END IF;
	v_todaysGlBatch := v_btchPrfx || ' (' || v_dateStr || ')';
	v_todbatchid := accb.get_todysbatch_id (v_todaysGlBatch, p_orgID);
	IF (v_todbatchid <= 0) THEN
		v_reslt_1 := accb.createBatch (p_orgID, v_todaysGlBatch, 'Journal Importation from ' || v_btchPrfx || ' Module @' || to_char(now(), 'DD-Mon-YYYY HH24:MI:SS') || ')', v_btchPrfx, 'VALID', - 1, '0', p_who_rn);
		updtMsg := rpt.updateRptLogMsg1 (p_msgid, v_reslt_1, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);
		IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
		END IF;
		v_todbatchid := accb.get_todysbatch_id (v_todaysGlBatch, p_orgID);
	END IF;
	IF (v_todbatchid > 0) THEN
		v_todaysGlBatch := accb.get_gl_batch_name (v_todbatchid);
	END IF;
	updtMsg := rpt.updateRptLogMsg1 (p_msgid, 'GL Batch Nm:' || v_todaysGlBatch, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);

	/*
	 * 1. Get list of all accounts to transfer from the
	 * interface table and their total amounts.
	 * 2. Loop through each and transfer
	 */
	FOR rd2 IN
	SELECT
		accnt_id,
		trnsdte,
		dbt_sum,
		crdt_sum,
		net_sum,
		func_cur_id
	FROM
		accb.get_gl_intrfc_recs (p_intrfcTblNme, p_orgID, p_interval)
		LOOP
			v_src_ids := ',' || BTRIM(accb.getGLIntrfcIDs (rd2.accnt_id, rd2.trnsdte, rd2.func_cur_id, p_intrfcTblNme), ',') || ',';
			v_entrdAmnt := (
				CASE WHEN rd2.dbt_sum = 0 THEN
					rd2.crdt_sum
				ELSE
					rd2.dbt_sum
				END);
			v_dbtCrdt := (
				CASE WHEN rd2.crdt_sum = 0 THEN
					'D'
				ELSE
					'C'
				END);
			v_accntCurrID := gst.getGnrlRecNm ('accb.accb_chart_of_accnts', 'accnt_id', 'crncy_id', rd2.accnt_id)::integer;
			v_accntCurrRate := round(accb.get_ltst_exchrate (rd2.func_cur_id, v_accntCurrID, rd2.trnsdte, p_orgid), 15);
			-- CHECK IF dbtsum IN intrfcids matchs the dbt amount been sent TO gl
			v_actlAmnts1 := 0;
			v_actlAmnts2 := 0;
			SELECT
				*
			FROM
				accb.getGLIntrfcIDAmntSum (v_src_ids, p_intrfcTblNme, rd2.accnt_id) INTO v_actlAmnts1,
	v_actlAmnts2;
			IF (v_actlAmnts1 = rd2.dbt_sum AND v_actlAmnts2 = rd2.crdt_sum) THEN
				v_reslt_1 := accb.createTransaction (rd2.accnt_id, 'Lumped sum of all transactions (from the ' || v_btchPrfx || ' module) to this account', rd2.dbt_sum, rd2.trnsdte, rd2.func_cur_id, v_todbatchid, rd2.crdt_sum, rd2.net_sum, v_src_ids, v_entrdAmnt, rd2.func_cur_id, v_entrdAmnt * v_accntCurrRate, v_accntCurrID, 1, v_accntCurrRate, 'D', '', '', - 1, p_who_rn);
				updtMsg := rpt.updateRptLogMsg1 (p_msgid, v_reslt_1, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);
				IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
				END IF;
			ELSE
				v_errmsg := chr(10) || 'Interface Transaction Amounts DR:' || v_actlAmnts1 || ' CR:' || v_actlAmnts2 || ' \r\ndo not match Amount being sent to GL DR:' || rd2.dbt_sum || ' CR:' || rd2.crdt_sum || '!\r\n Interface Line IDs:' || v_src_ids;
				updtMsg := rpt.updateRptLogMsg1 (p_msgid, v_errmsg, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_errmsg, HINT = v_errmsg;
				RETURN v_errmsg;
			END IF;
		END LOOP;
	IF (accb.get_Batch_CrdtSum (v_todbatchid) = accb.get_Batch_DbtSum (v_todbatchid)) THEN
		v_reslt_1 := accb.updtPymntAllGLIntrfcLnOrg (v_todbatchid, p_orgID, p_intrfcTblNme, p_who_rn);
		IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
		END IF;
		v_reslt_1 := accb.updtGLIntrfcLnSpclOrg (p_orgID, p_intrfcTblNme, v_btchPrfx, p_who_rn);
		IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
		END IF;
		UPDATE
			accb.accb_trnsctn_batches
		SET
			avlbl_for_postng = '1'
		WHERE
			avlbl_for_postng = '0'
			AND batch_source != 'Manual';
		RETURN 'SUCCESS:';
	ELSE
		DELETE FROM accb.accb_trnsctn_details
		WHERE (batch_id = v_todbatchid);
		DELETE FROM accb.accb_trnsctn_batches
		WHERE (batch_id = v_todbatchid);
		v_errmsg := v_errmsg || chr(10) || 'The GL Batch created is not Balanced!\r\nTransactions created will be reversed and deleted!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = v_errmsg, HINT = v_errmsg;
	END IF;
	RETURN 'SUCCESS:' || v_errmsg;
EXCEPTION
	WHEN OTHERS THEN
		v_errmsg := v_errmsg || chr(10) || 'Error Sending Transaction to GL!\r\n:' || SQLERRM || '::' || v_reslt_1;
	updtMsg := rpt.updateRptLogMsg1 (p_msgid, v_errmsg, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);
	RAISE EXCEPTION
	USING ERRCODE = 'RHERR', MESSAGE = v_errmsg, HINT = v_errmsg;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.close_period (date_to_close character varying, who_rn bigint, run_date character varying, orgidno integer, msgid bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	crnt_close_date character varying(21);
	last_close_date character varying(21);
	last_open_date character varying(21);
	isDateAllwd boolean;
	v_isAdjstmntPrd boolean;
	row_data RECORD;
	rd1 RECORD;
	msgs text := '';
	gl_btchID bigint := - 1;
	retErnAccntID integer := - 1;
	orgRetErnAccntID integer := - 1;
	ttl_dbt numeric := 0;
	ttl_crdt numeric := 0;
	ttl_net numeric := 0;
	tmp_dbt numeric := 0;
	tmp_crdt numeric := 0;
	tmp_net numeric := 0;
	tmp_dbt_crdt character varying(1);
	cur_ID bigint := - 1;
	cntr integer := 0;
	cntr1 integer := 0;
	ttl_cntr integer := 0;
	unpstdTrnsCnt bigint := 0;
	prdClseTrnsCnt bigint := 0;
	updtMsg bigint := 0;
	p_brnch_id bigint := - 1;
	p_sub_brnch_id bigint := - 1;
	orgid integer := - 1;
	orgTtlSgmnts integer := 0;
	costCntrSgmntNum integer := 0;
	subCostCntrSgmntNum integer := 0;
	costCntrSgmntID integer := - 1;
	subCostCntrSgmntID integer := - 1;
	v_div_grp_id1 integer := - 1;
	v_div_grp_id2 integer := - 1;
	v_cost_cntr_sgvalid integer := - 1;
	v_sub_cntr_sgvalid integer := - 1;
	seg_val_ids1 numeric := - 1;
	seg_val_ids2 numeric := - 1;
	seg_val_ids3 numeric := - 1;
	seg_val_ids4 numeric := - 1;
	seg_val_ids5 numeric := - 1;
	seg_val_ids6 numeric := - 1;
	seg_val_ids7 numeric := - 1;
	seg_val_ids8 numeric := - 1;
	seg_val_ids9 numeric := - 1;
	seg_val_ids10 numeric := - 1;
	v_prd_strt_date character varying(21);
	v_prd_end_date character varying(21);
	v_prd_det_id bigint := - 1;
BEGIN
	UPDATE
		accb.accb_running_prcses
	SET
		last_active_time = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
	WHERE
		which_process_is_rnng = 6;
	crnt_close_date := $1;
	msgs := msgs || chr(10) || 'Date to Close = ' || crnt_close_date;
	SELECT
		(COALESCE(a.period_start_date, '0001-01-01 00:00:00')),
		(COALESCE(a.period_end_date, '0001-01-01 00:00:00')),
		a.period_det_id INTO v_prd_strt_date,
		v_prd_end_date,
		v_prd_det_id
	FROM
		accb.accb_periods_det a,
		accb.accb_periods_hdr b
	WHERE
		a.period_hdr_id = b.periods_hdr_id
		AND b.org_id = $4
		AND a.period_end_date = date_to_close
		AND (a.period_status = 'Open')
	ORDER BY
		a.period_end_date ASC
	LIMIT 1 OFFSET 0;
	IF COALESCE(v_prd_strt_date, '0001-01-01 00:00:00') = '0001-01-01 00:00:00' THEN
		msgs := msgs || chr(10) || 'Invalid Period Selected for Closure!' || date_to_close;
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
		ELSE
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		RAISE EXCEPTION 'ERROR:%', msgs
			USING HINT = 'ERROR:' || msgs;
	END IF;
	SELECT
		age(to_timestamp(v_prd_end_date, 'YYYY-MM-DD HH24:MI:SS') + interval '10 second', to_timestamp(v_prd_strt_date, 'YYYY-MM-DD HH24:MI:SS')) <= interval '18 second' INTO v_isAdjstmntPrd;
	SELECT
		COALESCE(accb.get_TodysBatch_id ('Period Close Process (' || $1, $4), - 1) INTO gl_btchID;
	unpstdTrnsCnt := 0;
	prdClseTrnsCnt := 0;
	SELECT
		COALESCE(accb.getPrdClseUnpstdTrnsCnt ($4, crnt_close_date, gl_btchID), 0) INTO prdClseTrnsCnt;
	IF prdClseTrnsCnt > 0 THEN
		msgs := msgs || chr(10) || 'There are ' || trim(to_char(prdClseTrnsCnt, '99999999999999999999999999999999')) || ' Unposted Period Close Transactions on or Before the Date to be Closed' || chr(10) || ' Please post or reverse all such transactions!';
		msgs := msgs || chr(10) || 'Period Close Process will now exit....';
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
			msgs := rpt.getLogMsg ($5);
		END IF;
		IF msgid <= 0 THEN
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		RETURN msgs;
	END IF;
	SELECT
		COALESCE(accb.getUnpstdTrnsCnt ($4, crnt_close_date), 0) INTO unpstdTrnsCnt;
	IF unpstdTrnsCnt > 0 THEN
		msgs := msgs || chr(10) || 'There are ' || trim(to_char(unpstdTrnsCnt, '99999999999999999999999999999999')) || ' Unposted Transactions on or Before the Date to be Closed' || chr(10) || ' Please post or delete all such transactions before closing the period ending on this date';
		msgs := msgs || chr(10) || 'Period Close Process will now exit....';
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
			msgs := rpt.getLogMsg ($5);
		END IF;
		IF msgid <= 0 THEN
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		RETURN msgs;
	END IF;
	SELECT
		COALESCE(period_close_date, '0001-01-01 00:00:00') INTO last_close_date
	FROM
		accb.accb_period_close_dates
	WHERE
		org_id = $4
	ORDER BY
		period_close_id DESC
	LIMIT 1 OFFSET 0;
	IF last_close_date IS NULL THEN
		last_close_date := '0001-01-01 00:00:00';
	END IF;
	SELECT
		(COALESCE(a.period_end_date, '0001-01-01 00:00:00')) INTO last_open_date
	FROM
		accb.accb_periods_det a,
		accb.accb_periods_hdr b
	WHERE
		a.period_hdr_id = b.periods_hdr_id
		AND b.org_id = $4
		AND (a.period_status = 'Open')
	ORDER BY
		a.period_end_date ASC
	LIMIT 1 OFFSET 0;
	IF last_open_date IS NULL THEN
		last_open_date := '0001-01-01 00:00:00';
	END IF;
	SELECT
		to_timestamp(crnt_close_date, 'YYYY-MM-DD HH24:MI:SS') > to_timestamp(last_close_date, 'YYYY-MM-DD HH24:MI:SS')
		AND to_timestamp(crnt_close_date, 'YYYY-MM-DD HH24:MI:SS') = to_timestamp(last_open_date, 'YYYY-MM-DD HH24:MI:SS') INTO isDateAllwd;
	msgs := msgs || chr(10) || 'Last Period Close Date = ' || last_close_date;
	SELECT
		COALESCE(accb.get_TodysBatch_id ('Period Close Process (' || $1, $4), - 1) INTO gl_btchID;
	IF gl_btchID <= 0 THEN
		INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date, org_id, batch_status, last_update_by, last_update_date, batch_source)
			VALUES ('Period Close Process (' || $1 || ')-' || to_char(now(), 'YYYYMMDDHH24MISS'), 'Period Close Process (' || $1 || ')-' || to_char(now(), 'YYYYMMDDHH24MISS'), $2, $3, $4, '0', $2, $3, 'Period Close Process');
	END IF;
	SELECT
		COALESCE(accb.get_TodysBatch_id ('Period Close Process (' || $1, $4), - 1) INTO gl_btchID;
	msgs := msgs || chr(10) || 'Period Close Process GL Batch ID= ' || trim(to_char(gl_btchID, '999999999999999999999999999999999999999999'));
	msgs := msgs || chr(10) || 'Period Close Process GL Batch Name= ''Period Close Process (' || $1 || ')''';
	IF isDateAllwd OR v_isAdjstmntPrd THEN
		INSERT INTO accb.accb_period_close_dates (period_close_date, run_by, run_date, period_close_description, org_id, is_posted, gl_batch_id)
			VALUES (crnt_close_date, $2, $3, 'Running Period Close Process for the Period that Ended on ' || crnt_close_date, $4, '0', gl_btchID);
		msgs := msgs || chr(10) || 'Created Period Close Process line in Database....';
	ELSE
		msgs := msgs || chr(10) || 'Cannot close a date that comes before or is equal to the LAST CLOSED PERIOD!';
		msgs := msgs || chr(10) || 'Neither can you close a date that is not the FIRST AVAILABLE OPEN PERIOD!';
		msgs := msgs || chr(10) || 'Period Close Process will now exit....';
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
			msgs := rpt.getLogMsg ($5);
		END IF;
		IF msgid <= 0 THEN
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		RETURN msgs;
	END IF;
	SELECT
		COALESCE(org.get_Orgfunc_Crncy_id ($4), - 1) INTO cur_ID;
	orgRetErnAccntID := accb.get_OrgRetErnAccntID ($4);
	IF coalesce(orgRetErnAccntID, - 1) <= 0 THEN
		msgs := msgs || chr(10) || 'Retained Earnings Accounts Must be Created First!';
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
		ELSE
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		RAISE EXCEPTION 'ERROR:%', msgs
			USING HINT = 'ERROR:' || msgs;
	END IF;

	/*
	 1. Get all Branches and Sub-Branch segment Values
	 2. Get the retained earnings account segment val id and natural account segment id
	 3. For each Branch and Sub-Branch get all Revenue/Expense Account Combinations that use them
	 3. Also get the corresponding retained earnings account for that branch and sub-branch
	 */
	orgid := $4;
	SELECT
		no_of_accnt_sgmnts,
		loc_sgmnt_number,
		sub_loc_sgmnt_number INTO orgTtlSgmnts,
		costCntrSgmntNum,
		subCostCntrSgmntNum
	FROM
		org.org_details
	WHERE
		org_id = orgid;
	BEGIN
		SELECT
			segment_id INTO costCntrSgmntID
		FROM
			org.org_acnt_sgmnts
		WHERE
			segment_number = costCntrSgmntNum;
		EXCEPTION
		WHEN OTHERS THEN
			costCntrSgmntID := - 1;
		END;
	BEGIN
		SELECT
			segment_id INTO subCostCntrSgmntID
		FROM
			org.org_acnt_sgmnts
		WHERE
			segment_number = subCostCntrSgmntNum;
		EXCEPTION
		WHEN OTHERS THEN
			subCostCntrSgmntID := - 1;
		END;
	cntr := 0;
	ttl_cntr := 0;
	FOR rd1 IN (
		SELECT
			location_id,
			prnt_location_id
		FROM
			org.org_sites_locations
		WHERE
			org_id = orgid)
		LOOP
			IF rd1.prnt_location_id <= 0 THEN
				p_brnch_id := rd1.location_id;
				p_sub_brnch_id := rd1.location_id;
			ELSE
				p_brnch_id := rd1.prnt_location_id;
				p_sub_brnch_id := rd1.location_id;
			END IF;
			BEGIN
				SELECT
					segment_value_id INTO v_cost_cntr_sgvalid
				FROM
					org.org_segment_values
				WHERE
					segment_id = costCntrSgmntID
					AND lnkd_site_loc_id = p_brnch_id;
				EXCEPTION
				WHEN OTHERS THEN
					v_cost_cntr_sgvalid := - 1;
				END;
			BEGIN
				SELECT
					segment_value_id INTO v_sub_cntr_sgvalid
				FROM
					org.org_segment_values
				WHERE
					segment_id = subCostCntrSgmntID
					AND lnkd_site_loc_id = p_sub_brnch_id;
				EXCEPTION
				WHEN OTHERS THEN
					v_sub_cntr_sgvalid := - 1;
				END;
			seg_val_ids1 := - 1;
			seg_val_ids2 := - 1;
			seg_val_ids3 := - 1;
			seg_val_ids4 := - 1;
			seg_val_ids5 := - 1;
			seg_val_ids6 := - 1;
			seg_val_ids7 := - 1;
			seg_val_ids8 := - 1;
			seg_val_ids9 := - 1;
			seg_val_ids10 := - 1;
			IF v_cost_cntr_sgvalid > 0 THEN
				IF (costCntrSgmntNum = 1) THEN
					seg_val_ids1 := v_cost_cntr_sgvalid;
				ELSIF (costCntrSgmntNum = 2) THEN
					seg_val_ids2 := v_cost_cntr_sgvalid;
				ELSIF (costCntrSgmntNum = 3) THEN
					seg_val_ids3 := v_cost_cntr_sgvalid;
				ELSIF (costCntrSgmntNum = 4) THEN
					seg_val_ids4 := v_cost_cntr_sgvalid;
				ELSIF (costCntrSgmntNum = 5) THEN
					seg_val_ids5 := v_cost_cntr_sgvalid;
				ELSIF (costCntrSgmntNum = 6) THEN
					seg_val_ids6 := v_cost_cntr_sgvalid;
				ELSIF (costCntrSgmntNum = 7) THEN
					seg_val_ids7 := v_cost_cntr_sgvalid;
				ELSIF (costCntrSgmntNum = 8) THEN
					seg_val_ids8 := v_cost_cntr_sgvalid;
				ELSIF (costCntrSgmntNum = 9) THEN
					seg_val_ids9 := v_cost_cntr_sgvalid;
				ELSIF (costCntrSgmntNum = 10) THEN
					seg_val_ids10 := v_cost_cntr_sgvalid;
				END IF;
			END IF;
			IF v_sub_cntr_sgvalid > 0 THEN
				IF (subCostCntrSgmntNum = 1) THEN
					seg_val_ids1 := v_sub_cntr_sgvalid;
				ELSIF (subCostCntrSgmntNum = 2) THEN
					seg_val_ids2 := v_sub_cntr_sgvalid;
				ELSIF (subCostCntrSgmntNum = 3) THEN
					seg_val_ids3 := v_sub_cntr_sgvalid;
				ELSIF (subCostCntrSgmntNum = 4) THEN
					seg_val_ids4 := v_sub_cntr_sgvalid;
				ELSIF (subCostCntrSgmntNum = 5) THEN
					seg_val_ids5 := v_sub_cntr_sgvalid;
				ELSIF (subCostCntrSgmntNum = 6) THEN
					seg_val_ids6 := v_sub_cntr_sgvalid;
				ELSIF (subCostCntrSgmntNum = 7) THEN
					seg_val_ids7 := v_sub_cntr_sgvalid;
				ELSIF (subCostCntrSgmntNum = 8) THEN
					seg_val_ids8 := v_sub_cntr_sgvalid;
				ELSIF (subCostCntrSgmntNum = 9) THEN
					seg_val_ids9 := v_sub_cntr_sgvalid;
				ELSIF (subCostCntrSgmntNum = 10) THEN
					seg_val_ids10 := v_sub_cntr_sgvalid;
				END IF;
			END IF;
			--get_accnt_id_brnch_eqv, p_sub_brnch_id
			BEGIN
				retErnAccntID := org.get_accnt_id_brnch_eqv (rd1.location_id, orgRetErnAccntID);
				EXCEPTION
				WHEN OTHERS THEN
					retErnAccntID := - 1;
				END;
			ttl_dbt := 0;
			ttl_crdt := 0;
			ttl_net := 0;
			tmp_dbt := 0;
			tmp_crdt := 0;
			tmp_net := 0;
			tmp_dbt_crdt := NULL;
			IF seg_val_ids1 = - 1 AND seg_val_ids2 = - 1 AND seg_val_ids3 = - 1 AND seg_val_ids4 = - 1 AND seg_val_ids5 = - 1 AND seg_val_ids6 = - 1 AND seg_val_ids7 = - 1 AND seg_val_ids8 = - 1 AND seg_val_ids9 = - 1 AND seg_val_ids10 = - 1 THEN
				CONTINUE;
			ELSE
				IF coalesce(retErnAccntID, - 1) <= 0 THEN
					msgs := msgs || chr(10) || 'Retained Earnings Accounts for Branch Must be Created First!';
					IF msgid > 0 THEN
						updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
					ELSE
						msgs := REPLACE(msgs, chr(10), '<br/>');
					END IF;
					RAISE EXCEPTION 'ERROR:%', msgs
						USING HINT = 'ERROR:' || msgs;
				END IF;
				--START OF REPEATING CODE FOR BRANCH/SUBRANCH
				cntr := 0;
				--msgs := msgs || chr(10) || 'SEGMENT IDs = ID1:' || seg_val_ids1 || ':ID2:' || seg_val_ids2 || ':ID3:' || seg_val_ids3;
				FOR row_data IN
				SELECT
					SUM(a.dbt_amount) dbts,
					SUM(a.crdt_amount) crdts,
					b.accnt_id acntID,
					b.accnt_type acntTyp,
					b.accnt_typ_id
				FROM
					accb.accb_trnsctn_details a,
					accb.accb_chart_of_accnts b,
					accb.accb_trnsctn_batches c
				WHERE ((b.org_id = $4)
					AND (a.batch_id = c.batch_id
						AND a.accnt_id = b.accnt_id)
					AND (a.trns_status = '1')
					AND (to_timestamp(a.trnsctn_date, 'YYYY-MM-DD HH24:MI:SS') >= to_timestamp(v_prd_strt_date, 'YYYY-MM-DD HH24:MI:SS')
						AND to_timestamp(a.trnsctn_date, 'YYYY-MM-DD HH24:MI:SS') <= to_timestamp(v_prd_end_date, 'YYYY-MM-DD HH24:MI:SS'))
					AND (b.accnt_type = 'R'
						OR b.accnt_type = 'EX')
					AND (b.has_sub_ledgers = '0')
					AND (c.batch_source != 'Period Close Process')
					AND (
						CASE WHEN costCntrSgmntNum = 1
							OR subCostCntrSgmntNum = 1 THEN
							COALESCE(b.accnt_seg1_val_id, - 1)
						ELSE
							- 1
						END) = seg_val_ids1
					AND (
						CASE WHEN costCntrSgmntNum = 2
							OR subCostCntrSgmntNum = 2 THEN
							COALESCE(b.accnt_seg2_val_id, - 1)
						ELSE
							- 1
						END) = seg_val_ids2
					AND (
						CASE WHEN costCntrSgmntNum = 3
							OR subCostCntrSgmntNum = 3 THEN
							COALESCE(b.accnt_seg3_val_id, - 1)
						ELSE
							- 1
						END) = seg_val_ids3
					AND (
						CASE WHEN costCntrSgmntNum = 4
							OR subCostCntrSgmntNum = 4 THEN
							COALESCE(b.accnt_seg4_val_id, - 1)
						ELSE
							- 1
						END) = seg_val_ids4
					AND (
						CASE WHEN costCntrSgmntNum = 5
							OR subCostCntrSgmntNum = 5 THEN
							COALESCE(b.accnt_seg5_val_id, - 1)
						ELSE
							- 1
						END) = seg_val_ids5
					AND (
						CASE WHEN costCntrSgmntNum = 6
							OR subCostCntrSgmntNum = 6 THEN
							COALESCE(b.accnt_seg6_val_id, - 1)
						ELSE
							- 1
						END) = seg_val_ids6
					AND (
						CASE WHEN costCntrSgmntNum = 7
							OR subCostCntrSgmntNum = 7 THEN
							COALESCE(b.accnt_seg7_val_id, - 1)
						ELSE
							- 1
						END) = seg_val_ids7
					AND (
						CASE WHEN costCntrSgmntNum = 8
							OR subCostCntrSgmntNum = 8 THEN
							COALESCE(b.accnt_seg8_val_id, - 1)
						ELSE
							- 1
						END) = seg_val_ids8
					AND (
						CASE WHEN costCntrSgmntNum = 9
							OR subCostCntrSgmntNum = 9 THEN
							COALESCE(b.accnt_seg9_val_id, - 1)
						ELSE
							- 1
						END) = seg_val_ids9
					AND (
						CASE WHEN costCntrSgmntNum = 10
							OR subCostCntrSgmntNum = 10 THEN
							COALESCE(b.accnt_seg10_val_id, - 1)
						ELSE
							- 1
						END) = seg_val_ids10
					/*AND COALESCE(NULLIF(seg_val_ids1, -1), b.accnt_seg1_val_id) = b.accnt_seg1_val_id
					 AND COALESCE(NULLIF(seg_val_ids2, -1), b.accnt_seg2_val_id) = b.accnt_seg2_val_id
					 AND COALESCE(NULLIF(seg_val_ids3, -1), b.accnt_seg3_val_id) = b.accnt_seg3_val_id
					 AND COALESCE(NULLIF(seg_val_ids4, -1), b.accnt_seg4_val_id) = b.accnt_seg4_val_id
					 AND COALESCE(NULLIF(seg_val_ids5, -1), b.accnt_seg5_val_id) = b.accnt_seg5_val_id
					 AND COALESCE(NULLIF(seg_val_ids6, -1), b.accnt_seg6_val_id) = b.accnt_seg6_val_id
					 AND COALESCE(NULLIF(seg_val_ids7, -1), b.accnt_seg7_val_id) = b.accnt_seg7_val_id
					 AND COALESCE(NULLIF(seg_val_ids8, -1), b.accnt_seg8_val_id) = b.accnt_seg8_val_id
					 AND COALESCE(NULLIF(seg_val_ids9, -1), b.accnt_seg9_val_id) = b.accnt_seg9_val_id
					 AND COALESCE(NULLIF(seg_val_ids10, -1), b.accnt_seg10_val_id) = b.accnt_seg10_val_id*/)
			GROUP BY
				b.accnt_typ_id,
				b.accnt_type,
				b.accnt_id
			ORDER BY
				b.accnt_typ_id,
				b.accnt_type,
				b.accnt_id LOOP
					IF coalesce(row_data.acntID, - 1) <= 0 OR accb.get_accnt_num (coalesce(row_data.acntID, - 1)) IS NULL THEN
						msgs := msgs || chr(10) || ' Account does not exist! ID:' || coalesce(row_data.acntID, - 1);
						IF msgid > 0 THEN
							updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
						ELSE
							msgs := REPLACE(msgs, chr(10), '<br/>');
						END IF;
						RAISE EXCEPTION 'ERROR:%', msgs
							USING HINT = 'ERROR:' || msgs;
					END IF;
					UPDATE
						accb.accb_running_prcses
					SET
						last_active_time = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
					WHERE
						which_process_is_rnng = 6;
					tmp_dbt := row_data.dbts;
					tmp_crdt := row_data.crdts;

					/*msgs := msgs || chr(10) || 'Transaction Details: ' || trim(to_char(row_data.dbts,
					 '99999999999999999999999999999999999990.00'))
					 ||
					 '|' || trim(to_char(row_data.crdts,
					 '99999999999999999999999999999999999990.00')) || '|' || row_data.acntTyp || '|' ||
					 trim(to_char(row_data.acntID, '9999999999999999999999999999999999999')) || '';*/
					tmp_dbt_crdt := 'D';
					IF row_data.acntTyp = 'R' THEN
						tmp_net := row_data.dbts - row_data.crdts;
						IF tmp_net > 0 THEN
							tmp_dbt_crdt := 'C';
						END IF;
					ELSE
						tmp_net := row_data.crdts - row_data.dbts;
						IF tmp_net < 0 THEN
							tmp_dbt_crdt := 'C';
						END IF;
					END IF;
					ttl_dbt := ttl_dbt + tmp_dbt;
					ttl_crdt := ttl_crdt + tmp_crdt;
					INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc, dbt_amount, trnsctn_date, func_cur_id, created_by, creation_date, batch_id, crdt_amount, last_update_by, last_update_date, net_amount, trns_status, source_trns_ids, entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id, func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number, is_reconciled)
						VALUES (row_data.acntID, 'Period Close Process for the Period that Ended on ' || crnt_close_date, tmp_crdt, crnt_close_date, cur_ID, $2, $3, gl_btchID, tmp_dbt, $2, $3, tmp_net, '0', ',', tmp_net, cur_ID, tmp_net, cur_ID, 1, 1, tmp_dbt_crdt, '', '1');
					cntr := cntr + 1;
					ttl_cntr := ttl_cntr + 1;
					--COMMIT;
				END LOOP;
				IF cntr > 0 THEN
					ttl_net := abs(ttl_dbt - ttl_crdt);
					UPDATE
						accb.accb_running_prcses
					SET
						last_active_time = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
					WHERE
						which_process_is_rnng = 6;
					IF ttl_dbt > ttl_crdt THEN
						INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc, dbt_amount, trnsctn_date, func_cur_id, created_by, creation_date, batch_id, crdt_amount, last_update_by, last_update_date, net_amount, trns_status, source_trns_ids, entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id, func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number, is_reconciled)
							VALUES (retErnAccntID, 'Period Close Process for the Period that Ended on ' || crnt_close_date, ttl_net, crnt_close_date, cur_ID, $2, $3, gl_btchID, 0, $2, $3, - 1 * ttl_net, '0', ',', ttl_net, cur_ID, ttl_net, cur_ID, 1, 1, 'D', '', '0');
						cntr := cntr + 1;
						ttl_cntr := ttl_cntr + 1;
					ELSIF ttl_dbt <= ttl_crdt THEN
						INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc, dbt_amount, trnsctn_date, func_cur_id, created_by, creation_date, batch_id, crdt_amount, last_update_by, last_update_date, net_amount, trns_status, source_trns_ids, entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id, func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number, is_reconciled)
							VALUES (retErnAccntID, 'Period Close Process for the Period that Ended on ' || crnt_close_date, 0, crnt_close_date, cur_ID, $2, $3, gl_btchID, ttl_net, $2, $3, ttl_net, '0', ',', ttl_net, cur_ID, ttl_net, cur_ID, 1, 1, 'C', '', '0');
						cntr := cntr + 1;
						ttl_cntr := ttl_cntr + 1;
					END IF;
				END IF;
				--END OF REPEATING CODE FOR BRANCH/SUBRANCH
			END IF;
		END LOOP;
	msgs := msgs || chr(10) || 'Successfully Created ' || ttl_cntr || ' Segment Based Transaction(s)!';
	--FOR THOSE CUSTOMERS NOT USING SEQMENTS
	retErnAccntID := orgRetErnAccntID;
	ttl_dbt := 0;
	ttl_crdt := 0;
	ttl_net := 0;
	tmp_dbt := 0;
	tmp_crdt := 0;
	tmp_net := 0;
	tmp_dbt_crdt := NULL;
	cntr1 := 0;
	--START OF REPEATING CODE FOR BRANCH/SUBRANCH
	FOR row_data IN
	SELECT
		SUM(a.dbt_amount) dbts,
		SUM(a.crdt_amount) crdts,
		b.accnt_id acntID,
		b.accnt_type acntTyp,
		b.accnt_typ_id
	FROM
		accb.accb_trnsctn_details a,
		accb.accb_chart_of_accnts b,
		accb.accb_trnsctn_batches c
	WHERE ((b.org_id = $4)
		AND (a.batch_id = c.batch_id
			AND a.accnt_id = b.accnt_id)
		AND (a.trns_status = '1')
		AND (to_timestamp(a.trnsctn_date, 'YYYY-MM-DD HH24:MI:SS') >= to_timestamp(v_prd_strt_date, 'YYYY-MM-DD HH24:MI:SS')
			AND to_timestamp(a.trnsctn_date, 'YYYY-MM-DD HH24:MI:SS') <= to_timestamp(v_prd_end_date, 'YYYY-MM-DD HH24:MI:SS'))
		AND (b.accnt_type = 'R'
			OR b.accnt_type = 'EX')
		AND (b.has_sub_ledgers = '0')
		AND (c.batch_source != 'Period Close Process')
		AND (
			CASE WHEN costCntrSgmntNum = 1
				OR subCostCntrSgmntNum = 1 THEN
				COALESCE(b.accnt_seg1_val_id, - 1)
			ELSE
				- 1
			END) = - 1
		AND (
			CASE WHEN costCntrSgmntNum = 2
				OR subCostCntrSgmntNum = 2 THEN
				COALESCE(b.accnt_seg2_val_id, - 1)
			ELSE
				- 1
			END) = - 1
		AND (
			CASE WHEN costCntrSgmntNum = 3
				OR subCostCntrSgmntNum = 3 THEN
				COALESCE(b.accnt_seg3_val_id, - 1)
			ELSE
				- 1
			END) = - 1
		AND (
			CASE WHEN costCntrSgmntNum = 4
				OR subCostCntrSgmntNum = 4 THEN
				COALESCE(b.accnt_seg4_val_id, - 1)
			ELSE
				- 1
			END) = - 1
		AND (
			CASE WHEN costCntrSgmntNum = 5
				OR subCostCntrSgmntNum = 5 THEN
				COALESCE(b.accnt_seg5_val_id, - 1)
			ELSE
				- 1
			END) = - 1
		AND (
			CASE WHEN costCntrSgmntNum = 6
				OR subCostCntrSgmntNum = 6 THEN
				COALESCE(b.accnt_seg6_val_id, - 1)
			ELSE
				- 1
			END) = - 1
		AND (
			CASE WHEN costCntrSgmntNum = 7
				OR subCostCntrSgmntNum = 7 THEN
				COALESCE(b.accnt_seg7_val_id, - 1)
			ELSE
				- 1
			END) = - 1
		AND (
			CASE WHEN costCntrSgmntNum = 8
				OR subCostCntrSgmntNum = 8 THEN
				COALESCE(b.accnt_seg8_val_id, - 1)
			ELSE
				- 1
			END) = - 1
		AND (
			CASE WHEN costCntrSgmntNum = 9
				OR subCostCntrSgmntNum = 9 THEN
				COALESCE(b.accnt_seg9_val_id, - 1)
			ELSE
				- 1
			END) = - 1
		AND (
			CASE WHEN costCntrSgmntNum = 10
				OR subCostCntrSgmntNum = 10 THEN
				COALESCE(b.accnt_seg10_val_id, - 1)
			ELSE
				- 1
			END) = - 1)
GROUP BY
	b.accnt_typ_id,
	b.accnt_type,
	b.accnt_id
ORDER BY
	b.accnt_typ_id,
	b.accnt_type,
	b.accnt_id LOOP
		IF coalesce(row_data.acntID, - 1) <= 0 OR accb.get_accnt_num (coalesce(row_data.acntID, - 1)) IS NULL THEN
			msgs := msgs || chr(10) || ' Account does not exist! ID:' || coalesce(row_data.acntID, - 1);
			IF msgid > 0 THEN
				updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
			ELSE
				msgs := REPLACE(msgs, chr(10), '<br/>');
			END IF;
			RAISE EXCEPTION 'ERROR:%', msgs
				USING HINT = 'ERROR:' || msgs;
		END IF;
		UPDATE
			accb.accb_running_prcses
		SET
			last_active_time = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
		WHERE
			which_process_is_rnng = 6;
		tmp_dbt := row_data.dbts;
		tmp_crdt := row_data.crdts;

		/*msgs := msgs || chr(10) || 'Transaction Details: ' || trim(to_char(row_data.dbts,
		 '99999999999999999999999999999999999990.00'))
		 ||
		 '|' || trim(to_char(row_data.crdts,
		 '99999999999999999999999999999999999990.00')) || '|' || row_data.acntTyp || '|' ||
		 trim(to_char(row_data.acntID, '9999999999999999999999999999999999999')) || '';*/
		tmp_dbt_crdt := 'D';
		IF row_data.acntTyp = 'R' THEN
			tmp_net := row_data.dbts - row_data.crdts;
			IF tmp_net > 0 THEN
				tmp_dbt_crdt := 'C';
			END IF;
		ELSE
			tmp_net := row_data.crdts - row_data.dbts;
			IF tmp_net < 0 THEN
				tmp_dbt_crdt := 'C';
			END IF;
		END IF;
		ttl_dbt := ttl_dbt + tmp_dbt;
		ttl_crdt := ttl_crdt + tmp_crdt;
		INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc, dbt_amount, trnsctn_date, func_cur_id, created_by, creation_date, batch_id, crdt_amount, last_update_by, last_update_date, net_amount, trns_status, source_trns_ids, entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id, func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number, is_reconciled)
			VALUES (row_data.acntID, 'Period Close Process for the Period that Ended on ' || crnt_close_date, tmp_crdt, crnt_close_date, cur_ID, $2, $3, gl_btchID, tmp_dbt, $2, $3, tmp_net, '0', ',', tmp_net, cur_ID, tmp_net, cur_ID, 1, 1, tmp_dbt_crdt, '', '1');
		cntr1 := cntr1 + 1;
		ttl_cntr := ttl_cntr + 1;
	END LOOP;
	IF cntr1 > 0 THEN
		ttl_net := abs(ttl_dbt - ttl_crdt);
		UPDATE
			accb.accb_running_prcses
		SET
			last_active_time = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
		WHERE
			which_process_is_rnng = 6;
		IF ttl_dbt > ttl_crdt THEN
			INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc, dbt_amount, trnsctn_date, func_cur_id, created_by, creation_date, batch_id, crdt_amount, last_update_by, last_update_date, net_amount, trns_status, source_trns_ids, entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id, func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number, is_reconciled)
				VALUES (retErnAccntID, 'Period Close Process for the Period that Ended on ' || crnt_close_date, ttl_net, crnt_close_date, cur_ID, $2, $3, gl_btchID, 0, $2, $3, - 1 * ttl_net, '0', ',', ttl_net, cur_ID, ttl_net, cur_ID, 1, 1, 'D', '', '0');
			cntr1 := cntr1 + 1;
			ttl_cntr := ttl_cntr + 1;
		ELSIF ttl_dbt <= ttl_crdt THEN
			INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc, dbt_amount, trnsctn_date, func_cur_id, created_by, creation_date, batch_id, crdt_amount, last_update_by, last_update_date, net_amount, trns_status, source_trns_ids, entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id, func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number, is_reconciled)
				VALUES (retErnAccntID, 'Period Close Process for the Period that Ended on ' || crnt_close_date, 0, crnt_close_date, cur_ID, $2, $3, gl_btchID, ttl_net, $2, $3, ttl_net, '0', ',', ttl_net, cur_ID, ttl_net, cur_ID, 1, 1, 'C', '', '0');
			cntr1 := cntr1 + 1;
			ttl_cntr := ttl_cntr + 1;
		END IF;
		--END OF REPEATING CODE FOR BRANCH/SUBRANCH
		msgs := msgs || chr(10) || 'Successfully Created ' || cntr1 || ' Non-Segment Based Transaction(s)!';
	END IF;
	UPDATE
		accb.accb_running_prcses
	SET
		last_active_time = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
	WHERE
		which_process_is_rnng = 6;
	UPDATE
		accb.accb_periods_det
	SET
		last_update_by = $2,
		last_update_date = $3,
		period_status = 'Closed'
	WHERE
		period_end_date = crnt_close_date;
	msgs := msgs || chr(10) || 'Successfully Created a Total of ' || (ttl_cntr) || ' Transaction(s) In the Period Close Transactions Batch waiting to be Posted!';
	-- COMMIT;
	IF msgid > 0 THEN
		updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
		msgs := rpt.getLogMsg ($5);
	END IF;
	IF msgid <= 0 THEN
		msgs := REPLACE(msgs, chr(10), '<br/>');
	END IF;
	RETURN msgs;
EXCEPTION
	WHEN OTHERS THEN
		msgs := msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
	IF msgid > 0 THEN
		updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
		msgs := rpt.getLogMsg ($5);
	END IF;
	IF msgid <= 0 THEN
		msgs := REPLACE(msgs, chr(10), '<br/>');
	END IF;
	RETURN msgs;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.rvrs_period_close (date_to_close character varying, who_rn bigint, run_date character varying, orgidno integer, msgid bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	last_close_date character varying(21);
	isDateAllwd boolean;
	row_data RECORD;
	msgs text := chr(10) || 'Reversal of Unposted Period Close Process About to Start...';
	gl_btchID bigint := - 1;
	old_gl_btchID bigint := - 1;
	retErnAccntID integer := - 1;
	ttl_dbt numeric := 0;
	ttl_crdt numeric := 0;
	ttl_net numeric := 0;
	tmp_dbt numeric := 0;
	tmp_crdt numeric := 0;
	tmp_net numeric := 0;
	cur_ID bigint := - 1;
	cntr integer := 0;
	trnsCnt bigint := 0;
	batchCnt bigint := 0;
	pcloseCnt bigint := 0;
	updtMsg bigint := 0;
	v_isAdjstmntPrd boolean;
	v_prd_strt_date character varying(21);
	v_prd_end_date character varying(21);
	v_prd_det_id bigint := - 1;
BEGIN
	/*UPDATE accb . accb_running_prcses
	 SET last_active_time = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
	 WHERE which_process_is_rnng = 6;*/
	SELECT
		trim(period_close_date) INTO last_close_date
	FROM
		accb.accb_period_close_dates
	WHERE
		org_id = $4
	ORDER BY
		period_close_id DESC
	LIMIT 1 OFFSET 0;
	msgs := msgs || chr(10) || 'Date to Reverse = ' || last_close_date;
	SELECT
		(COALESCE(a.period_start_date, '0001-01-01 00:00:00')),
		(COALESCE(a.period_end_date, '0001-01-01 00:00:00')),
		a.period_det_id INTO v_prd_strt_date,
		v_prd_end_date,
		v_prd_det_id
	FROM
		accb.accb_periods_det a,
		accb.accb_periods_hdr b
	WHERE
		a.period_hdr_id = b.periods_hdr_id
		AND b.org_id = $4
		AND a.period_end_date = date_to_close
		AND (a.period_status = 'Closed')
	ORDER BY
		a.period_end_date ASC
	LIMIT 1 OFFSET 0;
	SELECT
		age(to_timestamp(v_prd_end_date, 'YYYY-MM-DD HH24:MI:SS') + interval '10 second', to_timestamp(v_prd_strt_date, 'YYYY-MM-DD HH24:MI:SS')) <= interval '18 second' INTO v_isAdjstmntPrd;
	IF last_close_date IS NULL THEN
		msgs := msgs || chr(10) || 'There is no Unposted Period Close Run Process to Reverse';
		msgs := msgs || chr(10) || 'Reversal of Unposted Period Close Process will now exit....';
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
			msgs := rpt.getLogMsg ($5);
		END IF;
		IF msgid <= 0 THEN
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		RETURN msgs;
	END IF;
	SELECT
		COALESCE(accb.get_batch_id ('Period Close Process (' || v_prd_end_date || ')', $4), - 1) INTO old_gl_btchID;

	/*Select COALESCE(accb.get_TodysBatch_id('Reversal of Unposted Period Close Process (' || $1,$4),-1) INTO gl_btchID;
	 unpstdTrnsCnt:=0;
	 prdClseTrnsCnt:=0;*/
	SELECT
		COUNT(1) INTO trnsCnt
	FROM
		accb.accb_trnsctn_details a
	WHERE
		a.trns_status = '0'
		AND a.batch_id = old_gl_btchID;
	SELECT
		COUNT(1) INTO batchCnt
	FROM
		accb.accb_trnsctn_batches b
	WHERE
		b.batch_id = old_gl_btchID
		AND b.batch_status = '0';
	SELECT
		COUNT(1) INTO pcloseCnt
	FROM
		accb.accb_period_close_dates b
	WHERE
		b.period_close_date ILIKE '%' || v_prd_end_date || '%'
		AND b.is_posted = '0'
		AND org_id = $4;
	UPDATE
		accb.accb_running_prcses
	SET
		last_active_time = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
	WHERE
		which_process_is_rnng = 6;
	DELETE FROM accb.accb_trnsctn_details a
	WHERE a.trns_status = '0'
		AND a.batch_id = old_gl_btchID;
	DELETE FROM accb.accb_trnsctn_batches b
	WHERE b.batch_id = old_gl_btchID
		AND b.batch_status = '0';
	DELETE FROM accb.accb_period_close_dates b
	WHERE b.period_close_date ILIKE '%' || v_prd_end_date || '%'
		AND COALESCE(accb.is_gl_batch_pstd (b.gl_batch_id), '0') = '0'
		AND org_id = $4;
	UPDATE
		accb.accb_periods_det
	SET
		last_update_by = $2,
		last_update_date = $3,
		period_status = 'Open'
	WHERE
		period_end_date = v_prd_end_date;
	UPDATE
		accb.accb_running_prcses
	SET
		last_active_time = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
	WHERE
		which_process_is_rnng = 6;
	msgs := msgs || chr(10) || 'Successfully Deleted ' || trim(to_char(trnsCnt, '999999999999999')) || ' Transactions, ' || trim(to_char(batchCnt, '999999999999999')) || ' Period Close Batch, ' || trim(to_char(pcloseCnt, '999999999999999')) || ' Period Close Date!';
	-- COMMIT;
	IF msgid > 0 THEN
		updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
		msgs := rpt.getLogMsg ($5);
	END IF;
	IF msgid <= 0 THEN
		msgs := REPLACE(msgs, chr(10), '<br/>');
	END IF;
	RETURN msgs;
EXCEPTION
	WHEN OTHERS THEN
		msgs := msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
	IF msgid > 0 THEN
		updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
		msgs := rpt.getLogMsg ($5);
	END IF;
	IF msgid <= 0 THEN
		msgs := REPLACE(msgs, chr(10), '<br/>');
	END IF;
	RETURN msgs;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.rvrs_pstd_period_close (date_to_close character varying, who_rn bigint, run_date character varying, orgidno integer, msgid bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	last_close_date character varying(21);
	last_close_date1 character varying(21);
	crnt_close_date character varying(21);
	isDateAllwd boolean;
	row_data RECORD;
	msgs text := chr(10) || 'Reversal of Posted Period Close Process About to Start...';
	gl_btchID bigint := - 1;
	old_gl_btchID bigint := - 1;
	retErnAccntID integer := - 1;
	ttl_dbt numeric := 0;
	ttl_crdt numeric := 0;
	ttl_net numeric := 0;
	tmp_dbt numeric := 0;
	tmp_crdt numeric := 0;
	tmp_net numeric := 0;
	cur_ID bigint := - 1;
	cntr integer := 0;
	trnsCnt bigint := 0;
	batchCnt bigint := 0;
	pcloseCnt bigint := 0;
	updtMsg bigint := 0;
	v_isAdjstmntPrd boolean;
	v_prd_strt_date character varying(21);
	v_prd_end_date character varying(21);
	v_prd_det_id bigint := - 1;
BEGIN
	/*UPDATE accb . accb_running_prcses
	 SET last_active_time = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
	 WHERE which_process_is_rnng = 6;*/
	crnt_close_date := $1;
	SELECT
		trim(SUBSTR(period_close_date, 0, 12)),
		period_close_date INTO last_close_date,
		last_close_date1
	FROM
		accb.accb_period_close_dates
	WHERE
		org_id = $4
	ORDER BY
		period_close_id DESC
	LIMIT 1 OFFSET 0;
	SELECT
		(COALESCE(a.period_start_date, '0001-01-01 00:00:00')),
		(COALESCE(a.period_end_date, '0001-01-01 00:00:00')),
		a.period_det_id INTO v_prd_strt_date,
		v_prd_end_date,
		v_prd_det_id
	FROM
		accb.accb_periods_det a,
		accb.accb_periods_hdr b
	WHERE
		a.period_hdr_id = b.periods_hdr_id
		AND b.org_id = $4
		AND a.period_end_date = date_to_close
		AND (a.period_status = 'Closed')
	ORDER BY
		a.period_end_date ASC
	LIMIT 1 OFFSET 0;
	SELECT
		age(to_timestamp(v_prd_end_date, 'YYYY-MM-DD HH24:MI:SS') + interval '10 second', to_timestamp(v_prd_strt_date, 'YYYY-MM-DD HH24:MI:SS')) <= interval '18 second' INTO v_isAdjstmntPrd;
	msgs := msgs || chr(10) || 'Date to Reverse = ' || crnt_close_date;
	IF last_close_date IS NULL THEN
		msgs := msgs || chr(10) || 'There is no Posted Period Close Run Process to Reverse';
		msgs := msgs || chr(10) || 'Reversal of Posted Period Close Process will now exit....';
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
			msgs := rpt.getLogMsg ($5);
		END IF;
		IF msgid <= 0 THEN
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		RETURN msgs;
	END IF;
	--last_close_date := trim(SUBSTR(v_prd_end_date, 0, 12));
	--last_close_date1 := v_prd_end_date;
	SELECT
		COALESCE(accb.get_batch_id ('Period Close Process (' || v_prd_end_date || ')', $4), - 1) INTO old_gl_btchID;
	SELECT
		to_timestamp(crnt_close_date, 'YYYY-MM-DD HH24:MI:SS') = to_timestamp(last_close_date1, 'YYYY-MM-DD HH24:MI:SS') INTO isDateAllwd;
	msgs := msgs || chr(10) || 'Last Period Close Date = ' || last_close_date1;
	IF isDateAllwd OR v_isAdjstmntPrd THEN
	ELSE
		msgs := msgs || chr(10) || 'Cannot delete a date that is not equal to the last period close date';
		msgs := msgs || chr(10) || 'Reversal of Posted Period Close Process will now exit....';
		IF msgid > 0 THEN
			updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
			msgs := rpt.getLogMsg ($5);
		END IF;
		IF msgid <= 0 THEN
			msgs := REPLACE(msgs, chr(10), '<br/>');
		END IF;
		RETURN msgs;
	END IF;
	--New GL Batch ID
	SELECT
		COALESCE(accb.get_TodysBatch_id ('Reversal of Posted Period Close Process (' || $1, $4), - 1) INTO gl_btchID;
	IF gl_btchID <= 0 THEN
		INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date, org_id, batch_status, last_update_by, last_update_date, batch_source, batch_vldty_status, src_batch_id)
			VALUES ('Reversal of Posted Period Close Process (' || $1 || ')-' || to_char(now(), 'YYYYMMDDHH24MISS'), 'Reversal of Posted Period Close Process (' || $1 || ')-' || to_char(now(), 'YYYYMMDDHH24MISS'), $2, $3, $4, '0', $2, $3, 'Period Close Process', 'VALID', old_gl_btchID);
		--COMMIT;
	END IF;
	SELECT
		COALESCE(accb.get_TodysBatch_id ('Reversal of Posted Period Close Process (' || $1, $4), - 1) INTO gl_btchID;
	msgs := msgs || chr(10) || 'Reversal of Posted Period Close Process GL Batch ID= ' || trim(to_char(gl_btchID, '999999999999999999999999999999999999999999'));
	msgs := msgs || chr(10) || 'Reversal of Posted Period Close Process GL Batch Name= ''Reversal of Posted Period Close Process (' || $1 || ')''';
	SELECT
		COUNT(1) INTO pcloseCnt
	FROM
		accb.accb_period_close_dates b
	WHERE
		b.period_close_date ILIKE '%' || v_prd_end_date || '%'
		AND accb.is_gl_batch_pstd (b.gl_batch_id) = '1'
		AND org_id = $4;
	SELECT
		COALESCE(org.get_Orgfunc_Crncy_id ($4), - 1) INTO cur_ID;
	msgs := msgs || chr(10) || 'About to create Transactions...';
	FOR row_data IN
	SELECT
		- 1 * a.dbt_amount dbts,
		- 1 * a.crdt_amount crdts,
		b.accnt_id acntID,
		b.accnt_type acntTyp,
		b.accnt_typ_id,
		- 1 * a.net_amount ntmt,
		a.entered_amnt,
		a.entered_amt_crncy_id,
		a.accnt_crncy_amnt,
		a.accnt_crncy_id,
		a.func_cur_exchng_rate,
		a.accnt_cur_exchng_rate,
		a.dbt_or_crdt,
		a.ref_doc_number,
		a.is_reconciled
	FROM
		accb.accb_trnsctn_details a,
		accb.accb_chart_of_accnts b
	WHERE ((b.org_id = $4)
		AND (a.accnt_id = b.accnt_id)
		AND (a.batch_id = old_gl_btchID))
ORDER BY
	b.accnt_typ_id,
	b.accnt_type,
	b.accnt_id LOOP
		UPDATE
			accb.accb_running_prcses
		SET
			last_active_time = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
		WHERE
			which_process_is_rnng = 6;
		tmp_dbt := row_data.dbts;
		tmp_crdt := row_data.crdts;
		tmp_net := row_data.ntmt;
		ttl_dbt := ttl_dbt + tmp_dbt;
		ttl_crdt := ttl_crdt + tmp_crdt;
		INSERT INTO accb.accb_trnsctn_details (accnt_id, transaction_desc, dbt_amount, trnsctn_date, func_cur_id, created_by, creation_date, batch_id, crdt_amount, last_update_by, last_update_date, net_amount, trns_status, source_trns_ids, entered_amnt, entered_amt_crncy_id, accnt_crncy_amnt, accnt_crncy_id, func_cur_exchng_rate, accnt_cur_exchng_rate, dbt_or_crdt, ref_doc_number, is_reconciled)
			VALUES (row_data.acntID, 'Reversal of Posted Period Close Process for the Period that Ended on ' || crnt_close_date, tmp_dbt, crnt_close_date, cur_ID, $2, $3, gl_btchID, tmp_crdt, $2, $3, tmp_net, '0', ',', - 1 * row_data.entered_amnt, row_data.entered_amt_crncy_id, - 1 * row_data.accnt_crncy_amnt, row_data.accnt_crncy_id, row_data.func_cur_exchng_rate, row_data.accnt_cur_exchng_rate, row_data.dbt_or_crdt, row_data.ref_doc_number, row_data.is_reconciled);
		cntr := cntr + 1;
		--COMMIT;
		/*msgs := msgs || chr(10) || 'Successfully Created ' || trim(to_char(cntr, '99999999999999999999999999999999999')) ||
		 ' Transaction(s)!';*/
	END LOOP;
	msgs := msgs || chr(10) || 'Successfully Created ' || trim(to_char(cntr, '99999999999999999999999999999999999')) || ' Transaction(s)!';
	cntr := cntr + 1;
	IF cntr > 0 THEN
		UPDATE
			accb.accb_trnsctn_batches
		SET
			batch_vldty_status = 'VOID',
			batch_name = '(VOIDED) ' || batch_name,
			batch_description = '(VOIDED) ' || batch_description
		WHERE
			batch_id = old_gl_btchID;
		DELETE FROM accb.accb_period_close_dates b
		WHERE b.period_close_date ILIKE '%' || v_prd_end_date || '%'
			AND COALESCE(accb.is_gl_batch_pstd (b.gl_batch_id), '1') = '1'
			AND org_id = $4;
		UPDATE
			accb.accb_periods_det
		SET
			last_update_by = $2,
			last_update_date = $3,
			period_status = 'Open'
		WHERE
			period_end_date = v_prd_end_date;
		msgs := msgs || chr(10) || 'Successfully Deleted ' || trim(to_char(pcloseCnt, '999999999999999')) || ' Period Close Date!';
		-- COMMIT;
	END IF;
	IF msgid > 0 THEN
		updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
		msgs := rpt.getLogMsg ($5);
	END IF;
	IF msgid <= 0 THEN
		msgs := REPLACE(msgs, chr(10), '<br/>');
	END IF;
	RETURN msgs;
EXCEPTION
	WHEN OTHERS THEN
		msgs := msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
	IF msgid > 0 THEN
		updtMsg := rpt.updateRptLogMsg (msgid, msgs, $3, $2);
		msgs := rpt.getLogMsg ($5);
	END IF;
	IF msgid <= 0 THEN
		msgs := REPLACE(msgs, chr(10), '<br/>');
	END IF;
	RETURN msgs;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.gettrnsdteopenprdlnid (prdhdrid bigint, trnsdte character varying)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		a.period_det_id INTO v_res
	FROM
		accb.accb_periods_det a
	WHERE ((a.period_hdr_id = prdHdrID)
		AND (a.period_status = 'Open')
		AND (trnsdte >= a.period_start_date
			AND trnsdte <= a.period_end_date));
	RETURN COALESCE(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN COALESCE(v_res, - 1);
END;

$BODY$;

CREATE OR REPLACE FUNCTION mcf.execute_standing_order (p_stnd_ordr_id bigint, p_who_rn bigint, p_run_date character varying, p_orgidno integer, p_msgid bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_srcAcntID integer;
	v_destAcntID integer;
	v_StndOrdrID bigint;
	v_IsTimeOK boolean;
	v_isSrcAcntBalsOK boolean;
	v_isDstAcntBalsOK boolean;
	v_clearedQty numeric;
	v_unClearedQty numeric;
	v_lienQty numeric;
	v_trnsDate character varying(21);
	v_trnsDateOnly character varying(21);
	tday_dte character varying(21);
	v_RecsDte character varying(21);
	v_TrnsNoDte character varying(21);
	v_TrnsfrOrdrNum character varying(50);
	v_UsrTrnsCode character varying(5);
	v_Remarks character varying(500);
	v_FeeRemarks character varying(500);
	v_TrnsType character varying(200);
	v_GnrtdTrnsNo character varying(50);
	v_AcntTrnsID bigint;
	v_AcntTrnsID1 bigint;
	v_AcntTrnsChqID bigint;
	v_OrdrExctnID bigint;
	v_AthrzrID bigint;
	v_AprvlLmtID bigint;
	v_BrnchID integer;
	v_PrsnID bigint;
	v_CrtdBy bigint;
	v_cur_ID bigint := - 1;
	v_TrnsAmnt numeric;
	v_TrnsRate numeric;
	v_row_data RECORD;
	v_row_data1 RECORD;
	v_row_data2 RECORD;
	v_rd3 RECORD;
	v_rd4 RECORD;
	v_rd5 RECORD;
	v_msgs text := chr(10) || 'Order/Transfer Execution About to Start...';
	v_cntr integer := 0;
	v_updtMsg bigint := 0;
	v_AcntNum character varying(50);
	v_acctstatus character varying(20) := '';
	v_acctcustomer character varying(200) := '';
	v_acctlien numeric := 0;
	v_mandate character varying(200) := '';
	v_wtdrwllimitno integer := - 1;
	v_wtdrwllimitamt numeric := 0;
	v_wtdrwllimittype character varying(15) := '';
	v_ChequeTypID integer;
	v_ChequeBnkID integer;
	v_ChequeBrnchID integer;
	v_SubTrnsType character varying(200);
	v_GlAcntID integer;
	v_IncrDcrs character varying(1) := '';
	v_TrnsTypePrfx character varying(3);
	isFunctnDone boolean := FALSE;
BEGIN
	/*
	 STEPS
	 1. GET SOURCE AND DEST ACCOUNTS IN THE STANDING ORDER
	 2. IF DESTINATION IS IN-HOUSE AND SOURCE IS IN-HOUSE THEN CREDIT DESTINATION ACCOUNT (DEPOSIT TRNS), AUTHORIZE
	 THEN DEBIT THE SOURCE ACCOUNT BY CREATING A WITHDRAWAL TRNS IN mcf.mcf_cust_account_transactions, AUTHORIZE THIS TRANSACTION AND UPDATE SOURCE AND DEST CUSTOMER ACCOUNT BALANCE
	 3. IF DESTINATION IS EXTERNAL, THEN CREATE AN UNCLEARED TRNS FROM SRC TO DEST. PENDING CLEARING
	 .i.e Create a Withdrawal Trns for SOurce Account and Create a Cheque Trns for Destination and Update Uncleared bals till it is cleared
	 */
	IF p_stnd_ordr_id > 0 THEN
		v_StndOrdrID := p_stnd_ordr_id;
	ELSE
		v_StndOrdrID := NULL;
	END IF;
	SELECT
		to_char(now(), 'YYYY-MM-DD HH24:MI:SS') INTO v_RecsDte;
	SELECT
		to_char(now(), 'DD-Mon-YYYY HH24:MI:SS') INTO tday_dte;
	v_trnsDateOnly := mcf.xx_get_start_of_day_date (p_orgidno);
	v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
	--v_BrnchID := pasn.get_prsn_siteid(v_PrsnID);
	FOR v_row_data IN
	SELECT
		a.stndn_order_id,
		a.src_account_id,
		mcf.get_cust_accnt_num (a.src_account_id) account_number,
		a.dest_type,
		a.dest_acct_or_wallet_no,
		transfer_type,
		amount,
		frqncy_no,
		frqncy_type,
		start_date,
		end_date,
		extnl_bank_id,
		extnl_branch_id,
		extnl_bnfcry_name,
		extnl_bnfcry_pstl_addrs,
		created_by,
		creation_date,
		last_update_by,
		last_update_date,
		branch_id,
		currency_id,
		negotiated_exch_rate,
		rmrk_narration,
		status,
		authorized_by_person_id,
		autorization_date,
		approval_limit_id,
		cheque_slip_no
	FROM
		mcf.mcf_standing_orders a
	WHERE
		stndn_order_id = COALESCE(v_StndOrdrID, stndn_order_id)
		AND status IN ('Authorized')
		AND (
			CASE WHEN COALESCE(v_StndOrdrID, - 1) <= 0 THEN
				processing_ongoing
			ELSE
				'0'
			END) = '0' LOOP
			v_StndOrdrID := v_row_data.stndn_order_id;
			v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
			v_IsTimeOK := mcf.is_trsfr_ordr_time_ok (v_StndOrdrID, v_trnsDate);
			IF v_IsTimeOK = FALSE THEN
				v_msgs := 'Cannot Process this Transfer/Order Execution!' || chr(10) || 'Time is not yet Up!';
				-- COMMIT;
				v_updtMsg := rpt.updaterptlogmsg ($5, v_msgs, $3, $2);
				RETURN v_msgs;
			END IF;
			v_CrtdBy := v_row_data.created_by;
			v_PrsnID := sec.get_usr_prsn_id (v_CrtdBy);
			v_UsrTrnsCode = sec.get_user_trns_code (p_who_rn);
			v_TrnsAmnt := v_row_data.amount;
			v_TrnsRate := v_row_data.negotiated_exch_rate;
			v_srcAcntID := v_row_data.src_account_id;
			v_TrnsfrOrdrNum := v_row_data.cheque_slip_no;
			v_AthrzrID := v_row_data.authorized_by_person_id;
			v_AprvlLmtID := v_row_data.approval_limit_id;
			v_BrnchID := v_row_data.branch_id;
			v_cur_ID := v_row_data.currency_id;
			v_Remarks := v_row_data.rmrk_narration;
			v_Remarks := v_Remarks || ' - Execution of Transfer/Order No.:' || v_TrnsfrOrdrNum || ' on ' || tday_dte;
			v_TrnsType := 'WITHDRAWAL';
			v_ChequeBnkID := v_row_data.extnl_bank_id;
			v_ChequeBrnchID := v_row_data.extnl_branch_id;
			IF v_row_data.dest_type = 'Bank Account' AND v_row_data.transfer_type = 'In-House' AND v_row_data.status = 'Authorized' THEN
				--DIRECT DEBIT SOURCE|CREDIT DEST
				v_clearedQty := v_row_data.amount;
				v_unClearedQty := 0;
				v_lienQty := 0;
				v_destAcntID := mcf.get_cust_accnt_id (v_row_data.dest_acct_or_wallet_no);
				v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
				v_isSrcAcntBalsOK := mcf.is_acnt_amt_avlbl (v_srcAcntID, v_clearedQty, v_unClearedQty, v_lienQty, v_trnsDate, 'D');
				v_isDstAcntBalsOK := mcf.is_acnt_amt_avlbl (v_destAcntID, v_clearedQty, v_unClearedQty, v_lienQty, v_trnsDate, 'I');
				v_AcntNum := COALESCE(v_row_data.account_number, '');
				RAISE NOTICE 'v_srcAcntID:%', v_srcAcntID || ':v_clearedQty:' || v_clearedQty || ':v_unClearedQty:' || v_unClearedQty || ':v_lienQty:' || v_lienQty || ':v_trnsDate:' || v_trnsDate;
				IF v_isSrcAcntBalsOK = TRUE AND v_isDstAcntBalsOK = TRUE THEN
					v_OrdrExctnID := nextval('mcf.mcf_standing_order_executions_stndn_order_exec_id_seq'::REGCLASS);
					v_AcntTrnsID := nextval('mcf.mcf_cust_account_transactions_acct_trns_id_seq'::REGCLASS);
					--SOURCE ACCOUNT TRANSACTION
					RAISE NOTICE 'Inside Source Trns v_AcntTrnsID:%', v_AcntTrnsID;
					RAISE NOTICE 'Inside Source Trns v_OrdrExctnID:%', v_OrdrExctnID;
					v_TrnsType := 'WITHDRAWAL';
					v_TrnsNoDte = to_char(now(), 'YYYYMMDD') || '-' || to_char(now(), 'HH24MISS');
					v_GnrtdTrnsNo = 'WTH' || '-' || v_UsrTrnsCode || '-' || v_TrnsNoDte || '-' || floor(random() * (999 - 100)) + 100;
					FOR v_row_data1 IN
					SELECT
						b.account_id,
						b.account_number,
						b.account_title,
						b.currency_id,
						c.mapped_lov_crncy_id,
						gst.get_pssbl_val (c.mapped_lov_crncy_id) crncy_nm,
						b.branch_id,
						mcf.get_cstacnt_unclrd_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
						mcf.get_cstacnt_avlbl_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
						b.account_type,
						b.status,
						mcf.get_customer_name (b.cust_type, b.cust_id) cstmrnm,
						b.prsn_type_or_entity,
						mcf.get_cstacnt_lien_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')) acntlien,
						b.mandate,
						e.withdrawal_limit_no,
						e.withdrawal_limit_amount,
						e.withdrawal_limit,
						mcf.get_cstacnt_unclrd_funds (b.account_id, to_char(now(), 'YYYY-MM-DD')),
						b.cust_type,
						b.cust_id
					FROM
						mcf.mcf_accounts b
					LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
				LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
			WHERE (b.account_id = v_srcAcntID)
				LOOP
					v_AcntNum := COALESCE(v_row_data1.account_number, '');
					v_acctstatus := COALESCE(v_row_data1.status, '');
					v_acctcustomer := COALESCE(v_row_data1.cstmrnm, '');
					v_acctlien := COALESCE(v_row_data1.acntlien, 0);
					v_mandate := COALESCE(v_row_data1.mandate, '');
					v_wtdrwllimitno := COALESCE(v_row_data1.withdrawal_limit_no, 0);
					v_wtdrwllimitamt := COALESCE(v_row_data1.withdrawal_limit_amount, 0);
					v_wtdrwllimittype := COALESCE(v_row_data1.withdrawal_limit, '');
				END LOOP;
					RAISE NOTICE 'BE4 INSERT TRNS acctcustomer:%', char_length(v_acctcustomer);
					v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
					INSERT INTO mcf.mcf_cust_account_transactions (acct_trns_id, trns_date, account_id, trns_type, description, amount, value_date, branch_id, doc_no, trns_person_name, trns_person_tel_no, trns_person_address, trns_person_id_type, trns_person_id_number, trns_person_type, created_by, creation_date, last_update_by, last_update_date, org_id, status, doc_type, debit_or_credit, authorized_by_person_id, autorization_date, trns_no, amount_cash, voided_acct_trns_id, voided_trns_type, reversal_reason, approval_limit_id, unclrdbal, clrdbal, acctstatus, acctcustomer, acctlien, mandate, wtdrwllimitno, wtdrwllimitamt, wtdrwllimittype, entered_crncy_id, accnt_crncy_rate, trns_has_other_lines, disbmnt_hdr_id, disbmnt_det_id, sub_trns_type, lnkd_chq_trns_id, lnkd_ordr_exctn_id, lnkd_mscl_trns_id, loan_rpmnt_type)
						VALUES (v_AcntTrnsID, v_trnsDate, v_srcAcntID, v_trnsType, v_Remarks, v_TrnsAmnt, v_trnsDateOnly, v_BrnchID, v_GnrtdTrnsNo, '', '', '', '', '', 'Self', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, p_orgidno, 'Paid', 'Paperless', 'DR', v_AthrzrID, v_RecsDte, v_GnrtdTrnsNo, v_TrnsAmnt, - 1, '', '', v_AprvlLmtID, mcf.get_cstacnt_unclrd_bals (v_srcAcntID, v_trnsDateOnly), mcf.get_cstacnt_avlbl_bals (v_srcAcntID, v_trnsDateOnly), v_acctstatus, v_acctcustomer, v_acctlien, v_mandate, v_wtdrwllimitno, v_wtdrwllimitamt, v_wtdrwllimittype, v_cur_ID, v_TrnsRate, '0', - 1, - 1, 'TRNSFR_ORDER', - 1, v_OrdrExctnID, - 1, '');
					PERFORM
						mcf.update_cstmracnt_balances (v_srcAcntID::bigint, v_clearedQty, v_unClearedQty, v_lienQty, '', v_trnsDateOnly, 'D', 'WTH', '' || v_AcntTrnsID, p_who_rn, v_RecsDte);
					RAISE NOTICE 'BE4 create_mcf_accntng v_Remarks:%', char_length(v_Remarks);
					isFunctnDone := mcf.create_mcf_accntng (v_AcntTrnsID, v_PrsnID, p_orgidno, p_who_rn, p_msgid);
					IF isFunctnDone = FALSE THEN
						RAISE EXCEPTION
							USING ERRCODE = 'RHERR', MESSAGE = 'ACCOUNTING FAILED:' || 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!', HINT = 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!';
						RETURN v_msgs;
					END IF;
					--DESTINATION ACCOUNT TRANSACTION
					v_AcntTrnsID1 := nextval('mcf.mcf_cust_account_transactions_acct_trns_id_seq'::REGCLASS);
					v_TrnsType := 'DEPOSIT';
					v_TrnsNoDte = to_char(now(), 'YYYYMMDD') || '-' || to_char(now(), 'HH24MISS');
					v_GnrtdTrnsNo = 'DEP' || '-' || v_UsrTrnsCode || '-' || v_TrnsNoDte || '-' || floor(random() * (999 - 100)) + 100;
					FOR v_row_data1 IN
					SELECT
						b.account_id,
						b.account_number,
						b.account_title,
						b.currency_id,
						c.mapped_lov_crncy_id,
						gst.get_pssbl_val (c.mapped_lov_crncy_id) crncy_nm,
						b.branch_id,
						mcf.get_cstacnt_unclrd_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
						mcf.get_cstacnt_avlbl_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
						b.account_type,
						b.status,
						mcf.get_customer_name (b.cust_type, b.cust_id) cstmrnm,
						b.prsn_type_or_entity,
						mcf.get_cstacnt_lien_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')) acntlien,
						b.mandate,
						e.withdrawal_limit_no,
						e.withdrawal_limit_amount,
						e.withdrawal_limit,
						mcf.get_cstacnt_unclrd_funds (b.account_id, to_char(now(), 'YYYY-MM-DD')),
						b.cust_type,
						b.cust_id
					FROM
						mcf.mcf_accounts b
					LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
				LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
			WHERE (b.account_id = v_destAcntID)
				LOOP
					v_AcntNum := COALESCE(v_row_data1.account_number, '');
					v_acctstatus := COALESCE(v_row_data1.status, '');
					v_acctcustomer := COALESCE(v_row_data1.cstmrnm, '');
					v_acctlien := COALESCE(v_row_data1.acntlien, 0);
					v_mandate := COALESCE(v_row_data1.mandate, '');
					v_wtdrwllimitno := COALESCE(v_row_data1.withdrawal_limit_no, 0);
					v_wtdrwllimitamt := COALESCE(v_row_data1.withdrawal_limit_amount, 0);
					v_wtdrwllimittype := COALESCE(v_row_data1.withdrawal_limit, '');
				END LOOP;
					v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
					INSERT INTO mcf.mcf_cust_account_transactions (acct_trns_id, trns_date, account_id, trns_type, description, amount, value_date, branch_id, doc_no, trns_person_name, trns_person_tel_no, trns_person_address, trns_person_id_type, trns_person_id_number, trns_person_type, created_by, creation_date, last_update_by, last_update_date, org_id, status, doc_type, debit_or_credit, authorized_by_person_id, autorization_date, trns_no, amount_cash, voided_acct_trns_id, voided_trns_type, reversal_reason, approval_limit_id, unclrdbal, clrdbal, acctstatus, acctcustomer, acctlien, mandate, wtdrwllimitno, wtdrwllimitamt, wtdrwllimittype, entered_crncy_id, accnt_crncy_rate, trns_has_other_lines, disbmnt_hdr_id, disbmnt_det_id, sub_trns_type, lnkd_chq_trns_id, lnkd_ordr_exctn_id, lnkd_mscl_trns_id, loan_rpmnt_type)
						VALUES (v_AcntTrnsID1, v_trnsDate, v_destAcntID, v_trnsType, v_Remarks, v_TrnsAmnt, v_trnsDateOnly, v_BrnchID, v_GnrtdTrnsNo, '', '', '', '', '', 'Self', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, p_orgidno, 'Received', 'Paperless', 'CR', v_AthrzrID, v_RecsDte, v_GnrtdTrnsNo, v_TrnsAmnt, - 1, '', '', v_AprvlLmtID, mcf.get_cstacnt_unclrd_bals (v_destAcntID, v_trnsDateOnly), mcf.get_cstacnt_avlbl_bals (v_destAcntID, v_trnsDateOnly), v_acctstatus, v_acctcustomer, v_acctlien, v_mandate, v_wtdrwllimitno, v_wtdrwllimitamt, v_wtdrwllimittype, v_cur_ID, v_TrnsRate, '0', - 1, - 1, 'TRNSFR_ORDER', - 1, v_OrdrExctnID, - 1, '');
					PERFORM
						mcf.update_cstmracnt_balances (v_destAcntID::bigint, v_clearedQty, v_unClearedQty, v_lienQty, '', v_trnsDateOnly, 'I', 'DEP', '' || v_AcntTrnsID1, p_who_rn, v_RecsDte);
					isFunctnDone := mcf.create_mcf_accntng (v_AcntTrnsID1, v_PrsnID, p_orgidno, p_who_rn, p_msgid);
					IF isFunctnDone = FALSE THEN
						RAISE EXCEPTION
							USING ERRCODE = 'RHERR', MESSAGE = 'ACCOUNTING FAILED:' || 'Transaction ID: ' || v_AcntTrnsID1 || ' Accounting for Transaction could not be created!', HINT = 'Transaction ID: ' || v_AcntTrnsID1 || ' Accounting for Transaction could not be created!';
						RETURN v_msgs;
					END IF;
					INSERT INTO mcf.mcf_standing_order_executions (stndn_order_exec_id, stndn_order_id, src_acnt_trns_id, ach_acnt_trns_id, was_trnsfr_sccfl, failure_reason, created_by, creation_date, last_update_by, last_update_date, stndn_order_dst_id)
						VALUES (v_OrdrExctnID, v_StndOrdrID, v_AcntTrnsID, v_AcntTrnsID1, '1', '', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, - 1);
					v_cntr := v_cntr + 1;
					RAISE NOTICE 'Final Destination Account Trns DONE:%', isFunctnDone;
				ELSE
					RAISE NOTICE 'Either Source or Destination Account Balances NOT OK:%', v_AcntNum;
					v_msgs := 'Acc/No: ' || v_AcntNum || ' cannot be overdrawn!';
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR', MESSAGE = 'TRANSFER FAILED:' || 'Acc/No: ' || v_AcntNum || ' Either Source or Destination Account Balances NOT OK!', HINT = 'Acc/No: ' || v_AcntNum || ' Either Source or Destination Account Balances NOT OK!';
					RETURN v_msgs;
				END IF;
			ELSIF v_row_data.transfer_type != 'In-House'
					AND v_row_data.status = 'Authorized' THEN
					--UNCLEARED DEBIT SOURCE|CHEQUE FOR DESTINATION
					v_clearedQty := - 1 * v_row_data.amount;
				v_unClearedQty := v_row_data.amount;
				v_lienQty := 0;
				v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
				v_isSrcAcntBalsOK := mcf.is_acnt_amt_avlbl (v_srcAcntID, v_clearedQty, v_unClearedQty, v_lienQty, v_trnsDate, 'D');
				IF v_isSrcAcntBalsOK = TRUE THEN
					v_OrdrExctnID := nextval('mcf_standing_order_executions_stndn_order_exec_id_seq'::REGCLASS);
					v_AcntTrnsID := nextval('mcf.mcf_cust_account_transactions_acct_trns_id_seq'::REGCLASS);
					v_AcntTrnsChqID := nextval('mcf.mcf_cust_account_trns_cheques_trns_cheque_id_seq'::REGCLASS);
					--SOURCE ACCOUNT TRANSACTION
					v_TrnsType := 'WITHDRAWAL';
					v_TrnsNoDte = to_char(now(), 'YYYYMMDD') || '-' || to_char(now(), 'HH24MISS');
					v_GnrtdTrnsNo = 'WTH' || '-' || v_UsrTrnsCode || '-' || v_TrnsNoDte || '-' || floor(random() * (999 - 100)) + 100;
					v_ChequeTypID := gst.get_pssbl_val_id ('External', gst.get_lov_id ("MCF Deposit Cheque Types"));
					FOR v_row_data1 IN
					SELECT
						b.account_id,
						b.account_number,
						b.account_title,
						b.currency_id,
						c.mapped_lov_crncy_id,
						gst.get_pssbl_val (c.mapped_lov_crncy_id) crncy_nm,
						b.branch_id,
						mcf.get_cstacnt_unclrd_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
						mcf.get_cstacnt_avlbl_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
						b.account_type,
						b.status,
						mcf.get_customer_name (b.cust_type, b.cust_id) cstmrnm,
						b.prsn_type_or_entity,
						mcf.get_cstacnt_lien_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')) acntlien,
						b.mandate,
						e.withdrawal_limit_no,
						e.withdrawal_limit_amount,
						e.withdrawal_limit,
						mcf.get_cstacnt_unclrd_funds (b.account_id, to_char(now(), 'YYYY-MM-DD')),
						b.cust_type,
						b.cust_id
					FROM
						mcf.mcf_accounts b
					LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
				LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
			WHERE (b.account_id = v_srcAcntID)
				LOOP
					v_AcntNum := COALESCE(v_row_data1.account_number, '');
					v_acctstatus := COALESCE(v_row_data1.status, '');
					v_acctcustomer := COALESCE(v_row_data1.cstmrnm, '');
					v_acctlien := COALESCE(v_row_data1.acntlien, 0);
					v_mandate := COALESCE(v_row_data1.mandate, '');
					v_wtdrwllimitno := COALESCE(v_row_data1.withdrawal_limit_no, 0);
					v_wtdrwllimitamt := COALESCE(v_row_data1.withdrawal_limit_amount, 0);
					v_wtdrwllimittype := COALESCE(v_row_data1.withdrawal_limit, '');
				END LOOP;
					v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
					INSERT INTO mcf.mcf_cust_account_transactions (acct_trns_id, trns_date, account_id, trns_type, description, amount, value_date, branch_id, doc_no, trns_person_name, trns_person_tel_no, trns_person_address, trns_person_id_type, trns_person_id_number, trns_person_type, created_by, creation_date, last_update_by, last_update_date, org_id, status, doc_type, debit_or_credit, authorized_by_person_id, autorization_date, trns_no, amount_cash, voided_acct_trns_id, voided_trns_type, reversal_reason, approval_limit_id, unclrdbal, clrdbal, acctstatus, acctcustomer, acctlien, mandate, wtdrwllimitno, wtdrwllimitamt, wtdrwllimittype, entered_crncy_id, accnt_crncy_rate, trns_has_other_lines, disbmnt_hdr_id, disbmnt_det_id, sub_trns_type, lnkd_chq_trns_id, lnkd_ordr_exctn_id, lnkd_mscl_trns_id, loan_rpmnt_type)
						VALUES (v_AcntTrnsID, v_trnsDate, v_srcAcntID, v_trnsType, v_Remarks, v_TrnsAmnt, v_trnsDate, v_BrnchID, v_GnrtdTrnsNo, '', '', '', '', '', 'Self', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, p_orgidno, 'Paid', 'Paperless', 'DR', v_AthrzrID, v_RecsDte, v_GnrtdTrnsNo, v_TrnsAmnt, - 1, '', '', v_AprvlLmtID, mcf.get_cstacnt_unclrd_bals (v_srcAcntID, v_trnsDateOnly), mcf.get_cstacnt_avlbl_bals (v_srcAcntID, v_trnsDateOnly), v_acctstatus, v_acctcustomer, v_acctlien, v_mandate, v_wtdrwllimitno, v_wtdrwllimitamt, v_wtdrwllimittype, v_cur_ID, v_TrnsRate, '1', - 1, - 1, 'TRNSFR_ORDER', - 1, v_OrdrExctnID, - 1, '');
					INSERT INTO mcf.mcf_cust_account_trns_cheques (trns_cheque_id, acct_trns_id, cheque_bank_id, cheque_branch_id, cheque_no, amount, created_by, creation_date, last_update_by, last_update_date, value_date, cheque_type, cheque_date, cheque_type_id, cheque_crncy_id, accnt_crncy_rate, house_chq_src_accnt_id, is_cleared, date_cleared, src_accnt_trns_id, cheque_mandate)
						VALUES (v_AcntTrnsChqID, v_AcntTrnsID, v_ChequeBnkID, v_ChequeBrnchID, v_TrnsfrOrdrNum, v_TrnsAmnt, p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, v_trnsDateOnly, 'External', v_trnsDateOnly, v_ChequeTypID, v_cur_ID, v_TrnsRate, v_srcAcntID, '0', '', - 1, v_mandate);
					PERFORM
						mcf.update_cstmracnt_balances (v_srcAcntID, v_clearedQty, v_unClearedQty, v_lienQty, '', v_trnsDateOnly, 'D', 'WTH', v_AcntTrnsID, p_who_rn, v_RecsDte);
					isFunctnDone := mcf.create_mcf_accntng (v_AcntTrnsID, v_PrsnID, p_orgidno, p_who_rn, p_msgid);
					IF isFunctnDone = FALSE THEN
						RAISE EXCEPTION
							USING ERRCODE = 'RHERR', MESSAGE = 'ACCOUNTING FAILED:' || 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!', HINT = 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!';
						RETURN v_msgs;
					END IF;
					INSERT INTO mcf.mcf_standing_order_executions (stndn_order_exec_id, stndn_order_id, src_acnt_trns_id, ach_acnt_trns_id, was_trnsfr_sccfl, failure_reason, created_by, creation_date, last_update_by, last_update_date, stndn_order_dst_id)
						VALUES (v_OrdrExctnID, v_StndOrdrID, v_AcntTrnsID, - 1, '1', '', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, - 1);
					v_cntr := v_cntr + 1;
				END IF;
			END IF;
			FOR v_rd3 IN
			SELECT
				stndn_order_dst_id,
				stndn_order_id,
				dest_type,
				transfer_type,
				dest_acct_or_wallet_no,
				amount,
				extnl_bank_id,
				extnl_branch_id,
				extnl_bnfcry_name,
				extnl_bnfcry_pstl_addrs,
				created_by,
				creation_date,
				last_update_by,
				last_update_date
			FROM
				mcf.mcf_stnd_ordr_dstntns
			WHERE
				stndn_order_id = v_StndOrdrID LOOP
					v_AcntNum := COALESCE(v_row_data.account_number, '');
					v_TrnsAmnt := v_rd3.amount;
					v_TrnsType := 'WITHDRAWAL';
					v_ChequeBnkID := v_rd3.extnl_bank_id;
					v_ChequeBrnchID := v_rd3.extnl_branch_id;
					IF v_rd3.dest_type = 'Bank Account' AND v_rd3.transfer_type = 'In-House' AND v_row_data.status = 'Authorized' THEN
						--DIRECT DEBIT SOURCE|CREDIT DEST
						RAISE NOTICE 'Inside Authorized Trns Amnt:%', v_TrnsAmnt;
						v_clearedQty := v_TrnsAmnt;
						v_unClearedQty := 0;
						v_lienQty := 0;
						v_destAcntID := mcf.get_cust_accnt_id (v_rd3.dest_acct_or_wallet_no);
						v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
						RAISE NOTICE 'Inside Authorized Trns v_destAcntID:%', v_destAcntID;
						v_isSrcAcntBalsOK := mcf.is_acnt_amt_avlbl (v_srcAcntID, v_clearedQty, v_unClearedQty, v_lienQty, v_trnsDate, 'D');
						v_isDstAcntBalsOK := mcf.is_acnt_amt_avlbl (v_destAcntID, v_clearedQty, v_unClearedQty, v_lienQty, v_trnsDate, 'I');
						RAISE NOTICE 'Inside Source Trns v_isSrcAcntBalsOK:%', v_isSrcAcntBalsOK;
						RAISE NOTICE 'Inside Source Trns v_isDstAcntBalsOK:%', v_isDstAcntBalsOK;
						IF v_isSrcAcntBalsOK = TRUE AND v_isDstAcntBalsOK = TRUE THEN
							v_OrdrExctnID := nextval('mcf.mcf_standing_order_executions_stndn_order_exec_id_seq'::REGCLASS);
							v_AcntTrnsID := nextval('mcf.mcf_cust_account_transactions_acct_trns_id_seq'::REGCLASS);
							--SOURCE ACCOUNT TRANSACTION
							RAISE NOTICE 'Inside Source Trns v_AcntTrnsID:%', v_AcntTrnsID;
							RAISE NOTICE 'Inside Source Trns v_OrdrExctnID:%', v_OrdrExctnID;
							v_TrnsType := 'WITHDRAWAL';
							v_TrnsNoDte = to_char(now(), 'YYYYMMDD') || '-' || to_char(now(), 'HH24MISS');
							v_GnrtdTrnsNo = 'WTH' || '-' || v_UsrTrnsCode || '-' || v_TrnsNoDte || '-' || floor(random() * (999 - 100)) + 100;
							FOR v_row_data1 IN
							SELECT
								b.account_id,
								b.account_number,
								b.account_title,
								b.currency_id,
								c.mapped_lov_crncy_id,
								gst.get_pssbl_val (c.mapped_lov_crncy_id) crncy_nm,
								b.branch_id,
								mcf.get_cstacnt_unclrd_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								mcf.get_cstacnt_avlbl_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								b.account_type,
								b.status,
								mcf.get_customer_name (b.cust_type, b.cust_id) cstmrnm,
								b.prsn_type_or_entity,
								mcf.get_cstacnt_lien_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')) acntlien,
								b.mandate,
								e.withdrawal_limit_no,
								e.withdrawal_limit_amount,
								e.withdrawal_limit,
								mcf.get_cstacnt_unclrd_funds (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								b.cust_type,
								b.cust_id
							FROM
								mcf.mcf_accounts b
							LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
						LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
					WHERE (b.account_id = v_srcAcntID)
						LOOP
							v_AcntNum := COALESCE(v_row_data1.account_number, '');
							v_acctstatus := COALESCE(v_row_data1.status, '');
							v_acctcustomer := COALESCE(v_row_data1.cstmrnm, '');
							v_acctlien := COALESCE(v_row_data1.acntlien, 0);
							v_mandate := COALESCE(v_row_data1.mandate, '');
							v_wtdrwllimitno := COALESCE(v_row_data1.withdrawal_limit_no, 0);
							v_wtdrwllimitamt := COALESCE(v_row_data1.withdrawal_limit_amount, 0);
							v_wtdrwllimittype := COALESCE(v_row_data1.withdrawal_limit, '');
						END LOOP;
							RAISE NOTICE 'BE4 INSERT TRNS v_acctcustomer:%', v_acctcustomer;
							v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
							INSERT INTO mcf.mcf_cust_account_transactions (acct_trns_id, trns_date, account_id, trns_type, description, amount, value_date, branch_id, doc_no, trns_person_name, trns_person_tel_no, trns_person_address, trns_person_id_type, trns_person_id_number, trns_person_type, created_by, creation_date, last_update_by, last_update_date, org_id, status, doc_type, debit_or_credit, authorized_by_person_id, autorization_date, trns_no, amount_cash, voided_acct_trns_id, voided_trns_type, reversal_reason, approval_limit_id, unclrdbal, clrdbal, acctstatus, acctcustomer, acctlien, mandate, wtdrwllimitno, wtdrwllimitamt, wtdrwllimittype, entered_crncy_id, accnt_crncy_rate, trns_has_other_lines, disbmnt_hdr_id, disbmnt_det_id, sub_trns_type, lnkd_chq_trns_id, lnkd_ordr_exctn_id, lnkd_mscl_trns_id, loan_rpmnt_type)
								VALUES (v_AcntTrnsID, v_trnsDate, v_srcAcntID, v_trnsType, v_Remarks, v_TrnsAmnt, v_trnsDateOnly, v_BrnchID, v_GnrtdTrnsNo, '', '', '', '', '', 'Self', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, p_orgidno, 'Paid', 'Paperless', 'DR', v_AthrzrID, v_RecsDte, v_GnrtdTrnsNo, v_TrnsAmnt, - 1, '', '', v_AprvlLmtID, mcf.get_cstacnt_unclrd_bals (v_srcAcntID, v_trnsDateOnly), mcf.get_cstacnt_avlbl_bals (v_srcAcntID, v_trnsDateOnly), v_acctstatus, v_acctcustomer, v_acctlien, v_mandate, v_wtdrwllimitno, v_wtdrwllimitamt, v_wtdrwllimittype, v_cur_ID, v_TrnsRate, '0', - 1, - 1, 'TRNSFR_ORDER', - 1, v_OrdrExctnID, - 1, '');
							PERFORM
								mcf.update_cstmracnt_balances (v_srcAcntID::bigint, v_clearedQty, v_unClearedQty, v_lienQty, '', v_trnsDateOnly, 'D', 'WTH', '' || v_AcntTrnsID, p_who_rn, v_RecsDte);
							RAISE NOTICE 'BE4 CREATE ACNTNG ONE v_AcntTrnsID:%', v_AcntTrnsID;
							isFunctnDone := mcf.create_mcf_accntng (v_AcntTrnsID, v_PrsnID, p_orgidno, p_who_rn, p_msgid);
							IF isFunctnDone = FALSE THEN
								RAISE EXCEPTION
									USING ERRCODE = 'RHERR', MESSAGE = 'ACCOUNTING FAILED:' || 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!', HINT = 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!';
								RETURN v_msgs;
							END IF;
							RAISE NOTICE 'AFTER CREATE ACNTNG ONE v_PrsnID:%', v_PrsnID;
							--DESTINATION ACCOUNT TRANSACTION
							v_AcntTrnsID1 := nextval('mcf.mcf_cust_account_transactions_acct_trns_id_seq'::REGCLASS);
							v_TrnsType := 'DEPOSIT';
							v_TrnsNoDte = to_char(now(), 'YYYYMMDD') || '-' || to_char(now(), 'HH24MISS');
							v_GnrtdTrnsNo = 'DEP' || '-' || v_UsrTrnsCode || '-' || v_TrnsNoDte || '-' || floor(random() * (999 - 100)) + 100;
							RAISE NOTICE 'BE4 DESTINATION ACNT TRNS v_AcntTrnsID1:%', v_AcntTrnsID1;
							FOR v_row_data1 IN
							SELECT
								b.account_id,
								b.account_number,
								b.account_title,
								b.currency_id,
								c.mapped_lov_crncy_id,
								gst.get_pssbl_val (c.mapped_lov_crncy_id) crncy_nm,
								b.branch_id,
								mcf.get_cstacnt_unclrd_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								mcf.get_cstacnt_avlbl_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								b.account_type,
								b.status,
								mcf.get_customer_name (b.cust_type, b.cust_id) cstmrnm,
								b.prsn_type_or_entity,
								mcf.get_cstacnt_lien_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')) acntlien,
								b.mandate,
								e.withdrawal_limit_no,
								e.withdrawal_limit_amount,
								e.withdrawal_limit,
								mcf.get_cstacnt_unclrd_funds (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								b.cust_type,
								b.cust_id
							FROM
								mcf.mcf_accounts b
							LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
						LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
					WHERE (b.account_id = v_destAcntID)
						LOOP
							v_AcntNum := COALESCE(v_row_data1.account_number, '');
							v_acctstatus := COALESCE(v_row_data1.status, '');
							v_acctcustomer := COALESCE(v_row_data1.cstmrnm, '');
							v_acctlien := COALESCE(v_row_data1.acntlien, 0);
							v_mandate := COALESCE(v_row_data1.mandate, '');
							v_wtdrwllimitno := COALESCE(v_row_data1.withdrawal_limit_no, 0);
							v_wtdrwllimitamt := COALESCE(v_row_data1.withdrawal_limit_amount, 0);
							v_wtdrwllimittype := COALESCE(v_row_data1.withdrawal_limit, '');
						END LOOP;
							v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
							INSERT INTO mcf.mcf_cust_account_transactions (acct_trns_id, trns_date, account_id, trns_type, description, amount, value_date, branch_id, doc_no, trns_person_name, trns_person_tel_no, trns_person_address, trns_person_id_type, trns_person_id_number, trns_person_type, created_by, creation_date, last_update_by, last_update_date, org_id, status, doc_type, debit_or_credit, authorized_by_person_id, autorization_date, trns_no, amount_cash, voided_acct_trns_id, voided_trns_type, reversal_reason, approval_limit_id, unclrdbal, clrdbal, acctstatus, acctcustomer, acctlien, mandate, wtdrwllimitno, wtdrwllimitamt, wtdrwllimittype, entered_crncy_id, accnt_crncy_rate, trns_has_other_lines, disbmnt_hdr_id, disbmnt_det_id, sub_trns_type, lnkd_chq_trns_id, lnkd_ordr_exctn_id, lnkd_mscl_trns_id, loan_rpmnt_type)
								VALUES (v_AcntTrnsID1, v_trnsDate, v_destAcntID, v_trnsType, v_Remarks, v_TrnsAmnt, v_trnsDateOnly, v_BrnchID, v_GnrtdTrnsNo, '', '', '', '', '', 'Self', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, p_orgidno, 'Received', 'Paperless', 'CR', v_AthrzrID, v_RecsDte, v_GnrtdTrnsNo, v_TrnsAmnt, - 1, '', '', v_AprvlLmtID, mcf.get_cstacnt_unclrd_bals (v_destAcntID, v_trnsDateOnly), mcf.get_cstacnt_avlbl_bals (v_destAcntID, v_trnsDateOnly), v_acctstatus, v_acctcustomer, v_acctlien, v_mandate, v_wtdrwllimitno, v_wtdrwllimitamt, v_wtdrwllimittype, v_cur_ID, v_TrnsRate, '0', - 1, - 1, 'TRNSFR_ORDER', - 1, v_OrdrExctnID, - 1, '');
							PERFORM
								mcf.update_cstmracnt_balances (v_destAcntID::bigint, v_clearedQty, v_unClearedQty, v_lienQty, '', v_trnsDateOnly, 'I', 'DEP', '' || v_AcntTrnsID1, p_who_rn, v_RecsDte);
							isFunctnDone := mcf.create_mcf_accntng (v_AcntTrnsID1, v_PrsnID, p_orgidno, p_who_rn, p_msgid);
							IF isFunctnDone = FALSE THEN
								RAISE EXCEPTION
									USING ERRCODE = 'RHERR', MESSAGE = 'ACCOUNTING FAILED:' || 'Transaction ID: ' || v_AcntTrnsID1 || ' Accounting for Transaction could not be created!', HINT = 'Transaction ID: ' || v_AcntTrnsID1 || ' Accounting for Transaction could not be created!';
								RETURN v_msgs;
							END IF;
							INSERT INTO mcf.mcf_standing_order_executions (stndn_order_exec_id, stndn_order_id, src_acnt_trns_id, ach_acnt_trns_id, was_trnsfr_sccfl, failure_reason, created_by, creation_date, last_update_by, last_update_date, stndn_order_dst_id)
								VALUES (v_OrdrExctnID, v_StndOrdrID, v_AcntTrnsID, v_AcntTrnsID1, '1', '', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, v_rd3.stndn_order_dst_id);
							v_cntr := v_cntr + 1;
							RAISE NOTICE 'Final Destination Account Trns DONE:%', isFunctnDone;
						ELSE
							RAISE NOTICE 'Either Source or Destination Account Balances NOT OK:%', v_AcntNum;
							v_msgs := 'Acc/No: ' || v_AcntNum || ' cannot be overdrawn!';
							RAISE EXCEPTION
								USING ERRCODE = 'RHERR', MESSAGE = 'TRANSFER FAILED:' || 'Acc/No: ' || v_AcntNum || ' Either Source or Destination Account Balances NOT OK!', HINT = 'Acc/No: ' || v_AcntNum || ' Either Source or Destination Account Balances NOT OK!';
							RETURN v_msgs;
						END IF;
					ELSIF v_rd3.transfer_type != 'In-House'
							AND v_row_data.status = 'Authorized' THEN
							--UNCLEARED DEBIT SOURCE|CHEQUE FOR DESTINATION
							v_clearedQty := - 1 * v_rd3.amount;
						v_unClearedQty := v_rd3.amount;
						v_lienQty := 0;
						v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
						v_isSrcAcntBalsOK := mcf.is_acnt_amt_avlbl (v_srcAcntID, v_clearedQty, v_unClearedQty, v_lienQty, v_trnsDate, 'D');
						IF v_isSrcAcntBalsOK = TRUE THEN
							v_OrdrExctnID := nextval('mcf_standing_order_executions_stndn_order_exec_id_seq'::REGCLASS);
							v_AcntTrnsID := nextval('mcf.mcf_cust_account_transactions_acct_trns_id_seq'::REGCLASS);
							v_AcntTrnsChqID := nextval('mcf.mcf_cust_account_trns_cheques_trns_cheque_id_seq'::REGCLASS);
							--SOURCE ACCOUNT TRANSACTION
							v_TrnsType := 'WITHDRAWAL';
							v_TrnsNoDte = to_char(now(), 'YYYYMMDD') || '-' || to_char(now(), 'HH24MISS');
							v_GnrtdTrnsNo = 'WTH' || '-' || v_UsrTrnsCode || '-' || v_TrnsNoDte || '-' || floor(random() * (999 - 100)) + 100;
							v_ChequeTypID := gst.get_pssbl_val_id ('External', gst.get_lov_id ("MCF Deposit Cheque Types"));
							FOR v_row_data1 IN
							SELECT
								b.account_id,
								b.account_number,
								b.account_title,
								b.currency_id,
								c.mapped_lov_crncy_id,
								gst.get_pssbl_val (c.mapped_lov_crncy_id) crncy_nm,
								b.branch_id,
								mcf.get_cstacnt_unclrd_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								mcf.get_cstacnt_avlbl_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								b.account_type,
								b.status,
								mcf.get_customer_name (b.cust_type, b.cust_id) cstmrnm,
								b.prsn_type_or_entity,
								mcf.get_cstacnt_lien_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')) acntlien,
								b.mandate,
								e.withdrawal_limit_no,
								e.withdrawal_limit_amount,
								e.withdrawal_limit,
								mcf.get_cstacnt_unclrd_funds (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								b.cust_type,
								b.cust_id
							FROM
								mcf.mcf_accounts b
							LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
						LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
					WHERE (b.account_id = v_srcAcntID)
						LOOP
							v_AcntNum := COALESCE(v_row_data1.account_number, '');
							v_acctstatus := COALESCE(v_row_data1.status, '');
							v_acctcustomer := COALESCE(v_row_data1.cstmrnm, '');
							v_acctlien := COALESCE(v_row_data1.acntlien, 0);
							v_mandate := COALESCE(v_row_data1.mandate, '');
							v_wtdrwllimitno := COALESCE(v_row_data1.withdrawal_limit_no, 0);
							v_wtdrwllimitamt := COALESCE(v_row_data1.withdrawal_limit_amount, 0);
							v_wtdrwllimittype := COALESCE(v_row_data1.withdrawal_limit, '');
						END LOOP;
							v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
							INSERT INTO mcf.mcf_cust_account_transactions (acct_trns_id, trns_date, account_id, trns_type, description, amount, value_date, branch_id, doc_no, trns_person_name, trns_person_tel_no, trns_person_address, trns_person_id_type, trns_person_id_number, trns_person_type, created_by, creation_date, last_update_by, last_update_date, org_id, status, doc_type, debit_or_credit, authorized_by_person_id, autorization_date, trns_no, amount_cash, voided_acct_trns_id, voided_trns_type, reversal_reason, approval_limit_id, unclrdbal, clrdbal, acctstatus, acctcustomer, acctlien, mandate, wtdrwllimitno, wtdrwllimitamt, wtdrwllimittype, entered_crncy_id, accnt_crncy_rate, trns_has_other_lines, disbmnt_hdr_id, disbmnt_det_id, sub_trns_type, lnkd_chq_trns_id, lnkd_ordr_exctn_id, lnkd_mscl_trns_id, loan_rpmnt_type)
								VALUES (v_AcntTrnsID, v_trnsDate, v_srcAcntID, v_trnsType, v_Remarks, v_TrnsAmnt, v_trnsDate, v_BrnchID, v_GnrtdTrnsNo, '', '', '', '', '', 'Self', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, p_orgidno, 'Paid', 'Paperless', 'DR', v_AthrzrID, v_RecsDte, v_GnrtdTrnsNo, v_TrnsAmnt, - 1, '', '', v_AprvlLmtID, mcf.get_cstacnt_unclrd_bals (v_srcAcntID, v_trnsDateOnly), mcf.get_cstacnt_avlbl_bals (v_srcAcntID, v_trnsDateOnly), v_acctstatus, v_acctcustomer, v_acctlien, v_mandate, v_wtdrwllimitno, v_wtdrwllimitamt, v_wtdrwllimittype, v_cur_ID, v_TrnsRate, '1', - 1, - 1, 'TRNSFR_ORDER', - 1, v_OrdrExctnID, - 1, '');
							INSERT INTO mcf.mcf_cust_account_trns_cheques (trns_cheque_id, acct_trns_id, cheque_bank_id, cheque_branch_id, cheque_no, amount, created_by, creation_date, last_update_by, last_update_date, value_date, cheque_type, cheque_date, cheque_type_id, cheque_crncy_id, accnt_crncy_rate, house_chq_src_accnt_id, is_cleared, date_cleared, src_accnt_trns_id, cheque_mandate)
								VALUES (v_AcntTrnsChqID, v_AcntTrnsID, v_ChequeBnkID, v_ChequeBrnchID, v_TrnsfrOrdrNum, v_TrnsAmnt, p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, v_trnsDateOnly, 'External', v_trnsDateOnly, v_ChequeTypID, v_cur_ID, v_TrnsRate, - 1, '0', '', - 1, v_mandate);
							PERFORM
								mcf.update_cstmracnt_balances (v_srcAcntID, v_clearedQty, v_unClearedQty, v_lienQty, '', v_trnsDateOnly, 'D', 'WTH', v_AcntTrnsID, p_who_rn, v_RecsDte);
							isFunctnDone := mcf.create_mcf_accntng (v_AcntTrnsID, v_PrsnID, p_orgidno, p_who_rn, p_msgid);
							IF isFunctnDone = FALSE THEN
								RAISE EXCEPTION
									USING ERRCODE = 'RHERR', MESSAGE = 'ACCOUNTING FAILED:' || 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!', HINT = 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!';
								RETURN v_msgs;
							END IF;
							INSERT INTO mcf.mcf_standing_order_executions (stndn_order_exec_id, stndn_order_id, src_acnt_trns_id, ach_acnt_trns_id, was_trnsfr_sccfl, failure_reason, created_by, creation_date, last_update_by, last_update_date, stndn_order_dst_id)
								VALUES (v_OrdrExctnID, v_StndOrdrID, v_AcntTrnsID, - 1, '1', '', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, v_rd3.stndn_order_dst_id);
							v_cntr := v_cntr + 1;
						ELSE
							RAISE NOTICE 'Either Source or Destination Account Balances NOT OK:%', v_AcntNum;
							v_msgs := 'Acc/No: ' || v_AcntNum || ' cannot be overdrawn!';
							RAISE EXCEPTION
								USING ERRCODE = 'RHERR', MESSAGE = 'TRASNFER FAILED:' || 'Acc/No: ' || v_AcntNum || ' Either Source or Destination Account Balances NOT OK!', HINT = 'Acc/No: ' || v_AcntNum || ' Either Source or Destination Account Balances NOT OK!';
							RETURN v_msgs;
						END IF;
					END IF;
				END LOOP;
			FOR v_rd5 IN
			SELECT
				stndn_order_src_id,
				stndn_order_id,
				account_id,
				mcf.get_cust_accnt_num (account_id) accntnum,
				amount,
				description,
				entered_crncy_id,
				accnt_crncy_rate,
				created_by,
				creation_date,
				last_update_by,
				last_update_date
			FROM
				mcf.mcf_stnd_ordr_sources
			WHERE
				stndn_order_id = v_StndOrdrID LOOP
					v_AcntNum := COALESCE(v_rd5.accntnum, '');
					v_TrnsAmnt := v_rd5.amount;
					v_TrnsType := 'WITHDRAWAL';
					v_ChequeBnkID := v_row_data.extnl_bank_id;
					v_ChequeBrnchID := v_row_data.extnl_branch_id;
					IF v_row_data.dest_type = 'Bank Account' AND v_row_data.transfer_type = 'In-House' AND v_row_data.status = 'Authorized' THEN
						--DIRECT DEBIT SOURCE|CREDIT DEST
						v_clearedQty := v_TrnsAmnt;
						v_unClearedQty := 0;
						v_lienQty := 0;
						v_srcAcntID := v_rd5.account_id;
						v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
						v_destAcntID := mcf.get_cust_accnt_id (v_row_data.dest_acct_or_wallet_no);
						v_isSrcAcntBalsOK := mcf.is_acnt_amt_avlbl (v_srcAcntID, v_clearedQty, v_unClearedQty, v_lienQty, v_trnsDate, 'D');
						v_isDstAcntBalsOK := mcf.is_acnt_amt_avlbl (v_destAcntID, v_clearedQty, v_unClearedQty, v_lienQty, v_trnsDate, 'I');
						IF v_isSrcAcntBalsOK = TRUE AND v_isDstAcntBalsOK = TRUE THEN
							v_OrdrExctnID := nextval('mcf.mcf_standing_order_executions_stndn_order_exec_id_seq'::REGCLASS);
							v_AcntTrnsID := nextval('mcf.mcf_cust_account_transactions_acct_trns_id_seq'::REGCLASS);
							--SOURCE ACCOUNT TRANSACTION
							v_TrnsType := 'WITHDRAWAL';
							v_TrnsNoDte = to_char(now(), 'YYYYMMDD') || '-' || to_char(now(), 'HH24MISS');
							v_GnrtdTrnsNo = 'WTH' || '-' || v_UsrTrnsCode || '-' || v_TrnsNoDte || '-' || floor(random() * (999 - 100)) + 100;
							FOR v_row_data1 IN
							SELECT
								b.account_id,
								b.account_number,
								b.account_title,
								b.currency_id,
								c.mapped_lov_crncy_id,
								gst.get_pssbl_val (c.mapped_lov_crncy_id) crncy_nm,
								b.branch_id,
								mcf.get_cstacnt_unclrd_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								mcf.get_cstacnt_avlbl_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								b.account_type,
								b.status,
								mcf.get_customer_name (b.cust_type, b.cust_id) cstmrnm,
								b.prsn_type_or_entity,
								mcf.get_cstacnt_lien_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')) acntlien,
								b.mandate,
								e.withdrawal_limit_no,
								e.withdrawal_limit_amount,
								e.withdrawal_limit,
								mcf.get_cstacnt_unclrd_funds (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								b.cust_type,
								b.cust_id
							FROM
								mcf.mcf_accounts b
							LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
						LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
					WHERE (b.account_id = v_srcAcntID)
						LOOP
							v_AcntNum := COALESCE(v_row_data1.account_number, '');
							v_acctstatus := COALESCE(v_row_data1.status, '');
							v_acctcustomer := COALESCE(v_row_data1.cstmrnm, '');
							v_acctlien := COALESCE(v_row_data1.acntlien, 0);
							v_mandate := COALESCE(v_row_data1.mandate, '');
							v_wtdrwllimitno := COALESCE(v_row_data1.withdrawal_limit_no, 0);
							v_wtdrwllimitamt := COALESCE(v_row_data1.withdrawal_limit_amount, 0);
							v_wtdrwllimittype := COALESCE(v_row_data1.withdrawal_limit, '');
						END LOOP;
							v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
							INSERT INTO mcf.mcf_cust_account_transactions (acct_trns_id, trns_date, account_id, trns_type, description, amount, value_date, branch_id, doc_no, trns_person_name, trns_person_tel_no, trns_person_address, trns_person_id_type, trns_person_id_number, trns_person_type, created_by, creation_date, last_update_by, last_update_date, org_id, status, doc_type, debit_or_credit, authorized_by_person_id, autorization_date, trns_no, amount_cash, voided_acct_trns_id, voided_trns_type, reversal_reason, approval_limit_id, unclrdbal, clrdbal, acctstatus, acctcustomer, acctlien, mandate, wtdrwllimitno, wtdrwllimitamt, wtdrwllimittype, entered_crncy_id, accnt_crncy_rate, trns_has_other_lines, disbmnt_hdr_id, disbmnt_det_id, sub_trns_type, lnkd_chq_trns_id, lnkd_ordr_exctn_id, lnkd_mscl_trns_id, loan_rpmnt_type)
								VALUES (v_AcntTrnsID, v_trnsDate, v_srcAcntID, v_trnsType, v_Remarks, v_TrnsAmnt, v_trnsDateOnly, v_BrnchID, v_GnrtdTrnsNo, '', '', '', '', '', 'Self', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, p_orgidno, 'Paid', 'Paperless', 'DR', v_AthrzrID, v_RecsDte, v_GnrtdTrnsNo, v_TrnsAmnt, - 1, '', '', v_AprvlLmtID, mcf.get_cstacnt_unclrd_bals (v_srcAcntID, v_trnsDateOnly), mcf.get_cstacnt_avlbl_bals (v_srcAcntID, v_trnsDateOnly), v_acctstatus, v_acctcustomer, v_acctlien, v_mandate, v_wtdrwllimitno, v_wtdrwllimitamt, v_wtdrwllimittype, v_cur_ID, v_TrnsRate, '0', - 1, - 1, 'TRNSFR_ORDER', - 1, v_OrdrExctnID, - 1, '');
							PERFORM
								mcf.update_cstmracnt_balances (v_srcAcntID::bigint, v_clearedQty, v_unClearedQty, v_lienQty, '', v_trnsDateOnly, 'D', 'WTH', '' || v_AcntTrnsID, p_who_rn, v_RecsDte);
							isFunctnDone := mcf.create_mcf_accntng (v_AcntTrnsID, v_PrsnID, p_orgidno, p_who_rn, p_msgid);
							IF isFunctnDone = FALSE THEN
								RAISE EXCEPTION
									USING ERRCODE = 'RHERR', MESSAGE = 'ACCOUNTING FAILED:' || 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!', HINT = 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!';
								RETURN v_msgs;
							END IF;
							--DESTINATION ACCOUNT TRANSACTION
							v_AcntTrnsID1 := nextval('mcf.mcf_cust_account_transactions_acct_trns_id_seq'::REGCLASS);
							v_TrnsType := 'DEPOSIT';
							v_TrnsNoDte = to_char(now(), 'YYYYMMDD') || '-' || to_char(now(), 'HH24MISS');
							v_GnrtdTrnsNo = 'DEP' || '-' || v_UsrTrnsCode || '-' || v_TrnsNoDte || '-' || floor(random() * (999 - 100)) + 100;
							FOR v_row_data1 IN
							SELECT
								b.account_id,
								b.account_number,
								b.account_title,
								b.currency_id,
								c.mapped_lov_crncy_id,
								gst.get_pssbl_val (c.mapped_lov_crncy_id) crncy_nm,
								b.branch_id,
								mcf.get_cstacnt_unclrd_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								mcf.get_cstacnt_avlbl_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								b.account_type,
								b.status,
								mcf.get_customer_name (b.cust_type, b.cust_id) cstmrnm,
								b.prsn_type_or_entity,
								mcf.get_cstacnt_lien_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')) acntlien,
								b.mandate,
								e.withdrawal_limit_no,
								e.withdrawal_limit_amount,
								e.withdrawal_limit,
								mcf.get_cstacnt_unclrd_funds (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								b.cust_type,
								b.cust_id
							FROM
								mcf.mcf_accounts b
							LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
						LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
					WHERE (b.account_id = v_destAcntID)
						LOOP
							v_AcntNum := COALESCE(v_row_data1.account_number, '');
							v_acctstatus := COALESCE(v_row_data1.status, '');
							v_acctcustomer := COALESCE(v_row_data1.cstmrnm, '');
							v_acctlien := COALESCE(v_row_data1.acntlien, 0);
							v_mandate := COALESCE(v_row_data1.mandate, '');
							v_wtdrwllimitno := COALESCE(v_row_data1.withdrawal_limit_no, 0);
							v_wtdrwllimitamt := COALESCE(v_row_data1.withdrawal_limit_amount, 0);
							v_wtdrwllimittype := COALESCE(v_row_data1.withdrawal_limit, '');
						END LOOP;
							v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
							INSERT INTO mcf.mcf_cust_account_transactions (acct_trns_id, trns_date, account_id, trns_type, description, amount, value_date, branch_id, doc_no, trns_person_name, trns_person_tel_no, trns_person_address, trns_person_id_type, trns_person_id_number, trns_person_type, created_by, creation_date, last_update_by, last_update_date, org_id, status, doc_type, debit_or_credit, authorized_by_person_id, autorization_date, trns_no, amount_cash, voided_acct_trns_id, voided_trns_type, reversal_reason, approval_limit_id, unclrdbal, clrdbal, acctstatus, acctcustomer, acctlien, mandate, wtdrwllimitno, wtdrwllimitamt, wtdrwllimittype, entered_crncy_id, accnt_crncy_rate, trns_has_other_lines, disbmnt_hdr_id, disbmnt_det_id, sub_trns_type, lnkd_chq_trns_id, lnkd_ordr_exctn_id, lnkd_mscl_trns_id, loan_rpmnt_type)
								VALUES (v_AcntTrnsID1, v_trnsDate, v_destAcntID, v_trnsType, v_Remarks, v_TrnsAmnt, v_trnsDateOnly, v_BrnchID, v_GnrtdTrnsNo, '', '', '', '', '', 'Self', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, p_orgidno, 'Received', 'Paperless', 'CR', v_AthrzrID, v_RecsDte, v_GnrtdTrnsNo, v_TrnsAmnt, - 1, '', '', v_AprvlLmtID, mcf.get_cstacnt_unclrd_bals (v_destAcntID, v_trnsDateOnly), mcf.get_cstacnt_avlbl_bals (v_destAcntID, v_trnsDateOnly), v_acctstatus, v_acctcustomer, v_acctlien, v_mandate, v_wtdrwllimitno, v_wtdrwllimitamt, v_wtdrwllimittype, v_cur_ID, v_TrnsRate, '0', - 1, - 1, 'TRNSFR_ORDER', - 1, v_OrdrExctnID, - 1, '');
							PERFORM
								mcf.update_cstmracnt_balances (v_destAcntID::bigint, v_clearedQty, v_unClearedQty, v_lienQty, '', v_trnsDateOnly, 'I', 'DEP', '' || v_AcntTrnsID1, p_who_rn, v_RecsDte);
							isFunctnDone := mcf.create_mcf_accntng (v_AcntTrnsID1, v_PrsnID, p_orgidno, p_who_rn, p_msgid);
							IF isFunctnDone = FALSE THEN
								RAISE EXCEPTION
									USING ERRCODE = 'RHERR', MESSAGE = 'ACCOUNTING FAILED:' || 'Transaction ID: ' || v_AcntTrnsID1 || ' Accounting for Transaction could not be created!', HINT = 'Transaction ID: ' || v_AcntTrnsID1 || ' Accounting for Transaction could not be created!';
								RETURN v_msgs;
							END IF;
							INSERT INTO mcf.mcf_standing_order_executions (stndn_order_exec_id, stndn_order_id, src_acnt_trns_id, ach_acnt_trns_id, was_trnsfr_sccfl, failure_reason, created_by, creation_date, last_update_by, last_update_date, stndn_order_src_id)
								VALUES (v_OrdrExctnID, v_StndOrdrID, v_AcntTrnsID, v_AcntTrnsID1, '1', '', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, v_rd5.stndn_order_src_id);
							v_cntr := v_cntr + 1;
						ELSE
							RAISE NOTICE 'Either Source or Destination Account Balances NOT OK:%', v_AcntNum;
							v_msgs := 'Acc/No: ' || v_AcntNum || ' cannot be overdrawn!';
							RAISE EXCEPTION
								USING ERRCODE = 'RHERR', MESSAGE = 'TRANSFER FAILED:' || 'Acc/No: ' || v_AcntNum || ' Either Source or Destination Account Balances NOT OK!', HINT = 'Acc/No: ' || v_AcntNum || ' Either Source or Destination Account Balances NOT OK!';
							RETURN v_msgs;
						END IF;
					ELSIF v_row_data.transfer_type != 'In-House'
							AND v_row_data.status = 'Authorized' THEN
							--UNCLEARED DEBIT SOURCE|CHEQUE FOR DESTINATION
							v_clearedQty := - 1 * v_rd5.amount;
						v_unClearedQty := v_rd5.amount;
						v_lienQty := 0;
						v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
						v_isSrcAcntBalsOK := mcf.is_acnt_amt_avlbl (v_srcAcntID, v_clearedQty, v_unClearedQty, v_lienQty, v_trnsDate, 'D');
						IF v_isSrcAcntBalsOK = TRUE THEN
							v_OrdrExctnID := nextval('mcf_standing_order_executions_stndn_order_exec_id_seq'::REGCLASS);
							v_AcntTrnsID := nextval('mcf.mcf_cust_account_transactions_acct_trns_id_seq'::REGCLASS);
							v_AcntTrnsChqID := nextval('mcf.mcf_cust_account_trns_cheques_trns_cheque_id_seq'::REGCLASS);
							--SOURCE ACCOUNT TRANSACTION
							v_TrnsType := 'WITHDRAWAL';
							v_TrnsNoDte = to_char(now(), 'YYYYMMDD') || '-' || to_char(now(), 'HH24MISS');
							v_GnrtdTrnsNo = 'WTH' || '-' || v_UsrTrnsCode || '-' || v_TrnsNoDte || '-' || floor(random() * (999 - 100)) + 100;
							v_ChequeTypID := gst.get_pssbl_val_id ('External', gst.get_lov_id ("MCF Deposit Cheque Types"));
							FOR v_row_data1 IN
							SELECT
								b.account_id,
								b.account_number,
								b.account_title,
								b.currency_id,
								c.mapped_lov_crncy_id,
								gst.get_pssbl_val (c.mapped_lov_crncy_id) crncy_nm,
								b.branch_id,
								mcf.get_cstacnt_unclrd_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								mcf.get_cstacnt_avlbl_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								b.account_type,
								b.status,
								mcf.get_customer_name (b.cust_type, b.cust_id) cstmrnm,
								b.prsn_type_or_entity,
								mcf.get_cstacnt_lien_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')) acntlien,
								b.mandate,
								e.withdrawal_limit_no,
								e.withdrawal_limit_amount,
								e.withdrawal_limit,
								mcf.get_cstacnt_unclrd_funds (b.account_id, to_char(now(), 'YYYY-MM-DD')),
								b.cust_type,
								b.cust_id
							FROM
								mcf.mcf_accounts b
							LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
						LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
					WHERE (b.account_id = v_srcAcntID)
						LOOP
							v_AcntNum := COALESCE(v_row_data1.account_number, '');
							v_acctstatus := COALESCE(v_row_data1.status, '');
							v_acctcustomer := COALESCE(v_row_data1.cstmrnm, '');
							v_acctlien := COALESCE(v_row_data1.acntlien, 0);
							v_mandate := COALESCE(v_row_data1.mandate, '');
							v_wtdrwllimitno := COALESCE(v_row_data1.withdrawal_limit_no, 0);
							v_wtdrwllimitamt := COALESCE(v_row_data1.withdrawal_limit_amount, 0);
							v_wtdrwllimittype := COALESCE(v_row_data1.withdrawal_limit, '');
						END LOOP;
							v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
							INSERT INTO mcf.mcf_cust_account_transactions (acct_trns_id, trns_date, account_id, trns_type, description, amount, value_date, branch_id, doc_no, trns_person_name, trns_person_tel_no, trns_person_address, trns_person_id_type, trns_person_id_number, trns_person_type, created_by, creation_date, last_update_by, last_update_date, org_id, status, doc_type, debit_or_credit, authorized_by_person_id, autorization_date, trns_no, amount_cash, voided_acct_trns_id, voided_trns_type, reversal_reason, approval_limit_id, unclrdbal, clrdbal, acctstatus, acctcustomer, acctlien, mandate, wtdrwllimitno, wtdrwllimitamt, wtdrwllimittype, entered_crncy_id, accnt_crncy_rate, trns_has_other_lines, disbmnt_hdr_id, disbmnt_det_id, sub_trns_type, lnkd_chq_trns_id, lnkd_ordr_exctn_id, lnkd_mscl_trns_id, loan_rpmnt_type)
								VALUES (v_AcntTrnsID, v_trnsDate, v_srcAcntID, v_trnsType, v_Remarks, v_TrnsAmnt, v_trnsDate, v_BrnchID, v_GnrtdTrnsNo, '', '', '', '', '', 'Self', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, p_orgidno, 'Paid', 'Paperless', 'DR', v_AthrzrID, v_RecsDte, v_GnrtdTrnsNo, v_TrnsAmnt, - 1, '', '', v_AprvlLmtID, mcf.get_cstacnt_unclrd_bals (v_srcAcntID, v_trnsDateOnly), mcf.get_cstacnt_avlbl_bals (v_srcAcntID, v_trnsDateOnly), v_acctstatus, v_acctcustomer, v_acctlien, v_mandate, v_wtdrwllimitno, v_wtdrwllimitamt, v_wtdrwllimittype, v_cur_ID, v_TrnsRate, '1', - 1, - 1, 'TRNSFR_ORDER', - 1, v_OrdrExctnID, - 1, '');
							INSERT INTO mcf.mcf_cust_account_trns_cheques (trns_cheque_id, acct_trns_id, cheque_bank_id, cheque_branch_id, cheque_no, amount, created_by, creation_date, last_update_by, last_update_date, value_date, cheque_type, cheque_date, cheque_type_id, cheque_crncy_id, accnt_crncy_rate, house_chq_src_accnt_id, is_cleared, date_cleared, src_accnt_trns_id, cheque_mandate)
								VALUES (v_AcntTrnsChqID, v_AcntTrnsID, v_ChequeBnkID, v_ChequeBrnchID, v_TrnsfrOrdrNum, v_TrnsAmnt, p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, v_trnsDateOnly, 'External', v_trnsDateOnly, v_ChequeTypID, v_cur_ID, v_TrnsRate, - 1, '0', '', - 1, v_mandate);
							PERFORM
								mcf.update_cstmracnt_balances (v_srcAcntID, v_clearedQty, v_unClearedQty, v_lienQty, '', v_trnsDateOnly, 'D', 'WTH', v_AcntTrnsID, p_who_rn, v_RecsDte);
							isFunctnDone := mcf.create_mcf_accntng (v_AcntTrnsID, v_PrsnID, p_orgidno, p_who_rn, p_msgid);
							IF isFunctnDone = FALSE THEN
								RAISE EXCEPTION
									USING ERRCODE = 'RHERR', MESSAGE = 'ACCOUNTING FAILED:' || 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!', HINT = 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!';
								RETURN v_msgs;
							END IF;
							INSERT INTO mcf.mcf_standing_order_executions (stndn_order_exec_id, stndn_order_id, src_acnt_trns_id, ach_acnt_trns_id, was_trnsfr_sccfl, failure_reason, created_by, creation_date, last_update_by, last_update_date, stndn_order_src_id)
								VALUES (v_OrdrExctnID, v_StndOrdrID, v_AcntTrnsID, - 1, '1', '', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, v_rd5.stndn_order_src_id);
							v_cntr := v_cntr + 1;
						ELSE
							RAISE NOTICE 'Either Source or Destination Account Balances NOT OK:%', v_AcntNum;
							v_msgs := 'Acc/No: ' || v_AcntNum || ' cannot be overdrawn!';
							RAISE EXCEPTION
								USING ERRCODE = 'RHERR', MESSAGE = 'TRANSFER FAILED:' || 'Acc/No: ' || v_AcntNum || ' Either Source or Destination Account Balances NOT OK!', HINT = 'Acc/No: ' || v_AcntNum || ' Either Source or Destination Account Balances NOT OK!';
							RETURN v_msgs;
						END IF;
					END IF;
				END LOOP;
			FOR v_rd4 IN
			SELECT
				stndn_order_misc_id,
				stndn_order_id,
				bulk_trns_hdr_id,
				account_id,
				mcf.get_cust_accnt_num (account_id) accntnum,
				trns_type,
				description,
				amount,
				entered_crncy_id,
				accnt_crncy_rate,
				sub_trns_type,
				balancing_gl_accnt_id,
				created_by,
				creation_date,
				last_update_by,
				last_update_date
			FROM
				mcf.mcf_standing_order_misc
			WHERE
				stndn_order_id = v_StndOrdrID LOOP
					v_AcntNum := COALESCE(v_rd4.accntnum, '');
					v_TrnsAmnt := v_rd4.amount;
					v_TrnsType := v_rd4.trns_type;
					v_SubTrnsType := v_rd4.sub_trns_type;
					v_GlAcntID := v_rd4.balancing_gl_accnt_id;
					v_IncrDcrs := 'D';
					v_TrnsTypePrfx := 'WTH';
					IF v_TrnsType = 'DEPOSIT' THEN
						v_IncrDcrs := 'I';
						v_TrnsTypePrfx := 'DEP';
					END IF;
					v_clearedQty := v_TrnsAmnt;
					v_unClearedQty := 0;
					v_lienQty := 0;
					v_destAcntID := v_rd4.account_id;
					v_isDstAcntBalsOK := TRUE;

					/*mcf.is_acnt_amt_avlbl(v_destAcntID, v_clearedQty, v_unClearedQty,
					 v_lienQty, v_trnsDate, v_IncrDcrs);*/
					v_FeeRemarks := v_rd4.description || ' (' || v_Remarks || ')';
					IF v_isDstAcntBalsOK = TRUE THEN
						v_OrdrExctnID := nextval('mcf.mcf_standing_order_executions_stndn_order_exec_id_seq'::REGCLASS);
						v_AcntTrnsID := nextval('mcf.mcf_cust_account_transactions_acct_trns_id_seq'::REGCLASS);
						v_TrnsNoDte = to_char(now(), 'YYYYMMDD') || '-' || to_char(now(), 'HH24MISS');
						v_GnrtdTrnsNo = v_TrnsTypePrfx || '-' || v_UsrTrnsCode || '-' || v_TrnsNoDte || '-' || floor(random() * (999 - 100)) + 100;
						FOR v_row_data1 IN
						SELECT
							b.account_id,
							b.account_number,
							b.account_title,
							b.currency_id,
							c.mapped_lov_crncy_id,
							gst.get_pssbl_val (c.mapped_lov_crncy_id) crncy_nm,
							b.branch_id,
							mcf.get_cstacnt_unclrd_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
							mcf.get_cstacnt_avlbl_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')),
							b.account_type,
							b.status,
							mcf.get_customer_name (b.cust_type, b.cust_id) cstmrnm,
							b.prsn_type_or_entity,
							mcf.get_cstacnt_lien_bals (b.account_id, to_char(now(), 'YYYY-MM-DD')) acntlien,
							b.mandate,
							e.withdrawal_limit_no,
							e.withdrawal_limit_amount,
							e.withdrawal_limit,
							mcf.get_cstacnt_unclrd_funds (b.account_id, to_char(now(), 'YYYY-MM-DD')),
							b.cust_type,
							b.cust_id
						FROM
							mcf.mcf_accounts b
						LEFT OUTER JOIN mcf.mcf_currencies c ON (b.currency_id = c.crncy_id)
					LEFT OUTER JOIN mcf.mcf_prdt_savings e ON (e.svngs_product_id = b.product_type_id)
				WHERE (b.account_id = v_destAcntID)
					LOOP
						v_AcntNum := COALESCE(v_row_data1.account_number, '');
						v_acctstatus := COALESCE(v_row_data1.status, '');
						v_acctcustomer := COALESCE(v_row_data1.cstmrnm, '');
						v_acctlien := COALESCE(v_row_data1.acntlien, 0);
						v_mandate := COALESCE(v_row_data1.mandate, '');
						v_wtdrwllimitno := COALESCE(v_row_data1.withdrawal_limit_no, 0);
						v_wtdrwllimitamt := COALESCE(v_row_data1.withdrawal_limit_amount, 0);
						v_wtdrwllimittype := COALESCE(v_row_data1.withdrawal_limit, '');
					END LOOP;
						v_trnsDate := v_trnsDateOnly || ' ' || mcf.get_ltst_trns_time (v_trnsDateOnly);
						INSERT INTO mcf.mcf_cust_account_transactions (acct_trns_id, trns_date, account_id, trns_type, description, amount, value_date, branch_id, doc_no, trns_person_name, trns_person_tel_no, trns_person_address, trns_person_id_type, trns_person_id_number, trns_person_type, created_by, creation_date, last_update_by, last_update_date, org_id, status, doc_type, debit_or_credit, authorized_by_person_id, autorization_date, trns_no, amount_cash, voided_acct_trns_id, voided_trns_type, reversal_reason, approval_limit_id, unclrdbal, clrdbal, acctstatus, acctcustomer, acctlien, mandate, wtdrwllimitno, wtdrwllimitamt, wtdrwllimittype, entered_crncy_id, accnt_crncy_rate, trns_has_other_lines, disbmnt_hdr_id, disbmnt_det_id, sub_trns_type, lnkd_chq_trns_id, lnkd_ordr_exctn_id, lnkd_mscl_trns_id, loan_rpmnt_type, loan_rpmnt_src_acct_id, loan_rpmnt_src_amount, bulk_trns_hdr_id, balancing_gl_accnt_id)
							VALUES (v_AcntTrnsID, v_trnsDate, v_destAcntID, v_trnsType, v_FeeRemarks, v_TrnsAmnt, v_trnsDateOnly, v_BrnchID, v_GnrtdTrnsNo, '', '', '', '', '', 'Self', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, p_orgidno, 'Paid', 'Paperless', 'DR', v_AthrzrID, v_RecsDte, v_GnrtdTrnsNo, v_TrnsAmnt, - 1, '', '', v_AprvlLmtID, mcf.get_cstacnt_unclrd_bals (v_destAcntID, v_trnsDateOnly), mcf.get_cstacnt_avlbl_bals (v_destAcntID, v_trnsDateOnly), v_acctstatus, v_acctcustomer, v_acctlien, v_mandate, v_wtdrwllimitno, v_wtdrwllimitamt, v_wtdrwllimittype, v_cur_ID, v_TrnsRate, '0', - 1, - 1, v_SubTrnsType, - 1, v_OrdrExctnID, v_AcntTrnsID, '', - 1, 0, - 1, v_GlAcntID);
						PERFORM
							mcf.update_cstmracnt_balances (v_destAcntID::bigint, v_clearedQty, v_unClearedQty, v_lienQty, '', v_trnsDateOnly, v_IncrDcrs, v_TrnsTypePrfx, '' || v_AcntTrnsID, p_who_rn, v_RecsDte);
						isFunctnDone := mcf.create_mcf_accntng (v_AcntTrnsID, v_PrsnID, p_orgidno, p_who_rn, p_msgid);
						IF isFunctnDone = FALSE THEN
							RAISE EXCEPTION
								USING ERRCODE = 'RHERR', MESSAGE = 'ACCOUNTING FAILED:' || 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!', HINT = 'Transaction ID: ' || v_AcntTrnsID || ' Accounting for Transaction could not be created!';
							RETURN v_msgs;
						END IF;
						INSERT INTO mcf.mcf_standing_order_executions (stndn_order_exec_id, stndn_order_id, src_acnt_trns_id, ach_acnt_trns_id, was_trnsfr_sccfl, failure_reason, created_by, creation_date, last_update_by, last_update_date, stndn_order_dst_id, stndn_order_misc_id)
							VALUES (v_OrdrExctnID, v_StndOrdrID, v_AcntTrnsID, v_AcntTrnsID1, '1', '', p_who_rn, v_RecsDte, p_who_rn, v_RecsDte, - 1, v_rd4.stndn_order_misc_id);
						v_cntr := v_cntr + 1;
					ELSE
						RAISE NOTICE 'Either Source or Destination Account Balances NOT OK:%', v_AcntNum;
						v_msgs := 'Acc/No: ' || v_AcntNum || ' cannot be overdrawn!';
						RAISE EXCEPTION
							USING ERRCODE = 'RHERR', MESSAGE = 'TRANSFER FAILED:' || 'Acc/No: ' || v_AcntNum || ' Either Source or Destination Account Balances NOT OK!', HINT = 'Acc/No: ' || v_AcntNum || ' Either Source or Destination Account Balances NOT OK!';
						RETURN v_msgs;
					END IF;
				END LOOP;
			IF v_cntr > 0 THEN
				UPDATE
					mcf.mcf_standing_orders
				SET
					status = 'Executed',
					processing_ongoing = '1'
				WHERE
					frqncy_no = 1
					AND frqncy_type = 'LifeTime'
					AND stndn_order_id = v_StndOrdrID;
			END IF;
			v_msgs := v_msgs || chr(10) || 'Successfully Created a Total of ' || trim(to_char(v_cntr, '99999999999999999999999999999999999')) || ' Transfer/Order Executions!';
			-- COMMIT;2111001000000901
			v_updtMsg := rpt.updaterptlogmsg ($5, v_msgs, $3, $2);
		END LOOP;
	--v_msgs:=rpt.getLogMsg($5);
	RETURN v_msgs;
EXCEPTION
	WHEN SQLSTATE 'RHERR' THEN
		v_msgs := SQLSTATE || chr(10) || SQLERRM;
	v_updtMsg := rpt.updaterptlogmsg (p_msgid, v_msgs, p_run_date, p_who_rn);
	UPDATE
		mcf.mcf_standing_orders
	SET
		processing_ongoing = '0'
	WHERE
		stndn_order_id = COALESCE(v_StndOrdrID, stndn_order_id)
		AND status IN ('Authorized');
	RAISE NOTICE 'ERRORS:%', v_msgs;
	RETURN v_msgs;
	WHEN OTHERS THEN
		v_msgs := '' || SQLSTATE || chr(10) || SQLERRM;
	v_updtMsg := rpt.updaterptlogmsg ($5, v_msgs, $3, $2);
	UPDATE
		mcf.mcf_standing_orders
	SET
		processing_ongoing = '0'
	WHERE
		stndn_order_id = COALESCE(v_StndOrdrID, stndn_order_id)
		AND status IN ('Authorized');
	RAISE NOTICE 'ERRORS:%', v_msgs;

	/*RAISE EXCEPTION 'ERRORS:%', v_msgs
	 USING HINT = 'Please check your System Setup or Contact Vendor';*/
	RETURN v_msgs;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.invoice_payment (p_orgnlpymntid bigint, p_newpymntbatchid bigint, p_invoice_id bigint, p_mspyid bigint, p_createprepay boolean, p_doc_types character varying, p_pay_mthd_id integer, p_pay_remarks character varying, p_pay_date character varying, p_pay_amt_rcvd numeric, p_appld_prpay_docid bigint, p_cheque_card_name character varying, p_cheque_card_num character varying, p_cheque_card_code character varying, p_cheque_card_expdate character varying, p_who_rn bigint, p_run_date character varying, orgidno integer, p_msgid bigint, p_incstmrspplrid bigint, p_invccurd integer)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	rd3 RECORD;
	rd2 RECORD;
	rd1 RECORD;
	msgs text := chr(10) || '';
	errCntr integer := 0;
	batchCntr integer := 0;
	v_reslt_1 character varying(200) := '';
	dateStr character varying(21) := '';
	v_dte character varying(21) := '';
	v_pay_date timestamp;
	v_usrTrnsCode character varying(100) := '';
	v_drCrdt1 character varying(100) := '';
	v_drCrdt2 character varying(100) := '';
	v_PrsnID bigint := - 1;
	v_PrsnBrnchID integer := - 1;
	v_dfltCashAccntID integer := - 1;
	v_dfltCashAccntID1 integer := - 1;
	v_dfltPyblAccntID integer := - 1;
	v_dfltRcvblAccntID integer := - 1;
	v_docStatus character varying(200) := '';
	p_orgidno integer := - 1;
	v_prcsngPay boolean := FALSE;
	v_dsablPayments boolean := FALSE;
	v_createPrepay boolean := FALSE;
	v_prepayDocType character varying(200) := '';
	v_pymntNthdName character varying(200) := '';
	v_pay_remarks character varying(300) := '';
	v_actvtyDocName character varying(200) := '';
	v_prepayAvlblAmnt numeric := 0;
	v_amntToPay numeric := 0;
	v_amntBeingPaid numeric := 0;
	v_changeBals numeric := 0;
	v_spplrID bigint := - 1;
	v_spplrSiteID bigint := - 1;
	v_srcDocID bigint := - 1;
	v_srcDocType character varying(200) := '';
	v_currID integer := - 1;
	v_funcCurrID integer := - 1;
	v_IncrsDcrs1 character varying(1) := '';
	v_AccntID1 integer := - 1;
	v_IncrsDcrs2 character varying(1) := '';
	v_AccntID2 integer := - 1;
	v_pymntBatchName character varying(200) := '';
	v_docClsftn character varying(200) := '';
	v_docNum character varying(200) := '';
	v_gnrtdTrnsNo1 character varying(200) := '';
	v_glBatchName character varying(200) := '';
	v_glBatchID bigint := - 1;
	v_orgnlGLBatchID bigint := - 1;
	v_pymntBatchID bigint := - 1;
	v_orgnlPymntBatchID bigint := - 1;
	v_glBatchPrfx character varying(100) := '';
	v_glBatchSrc character varying(200) := '';
	v_pymntID bigint := - 1;
	v_accntCurrID integer := - 1;
	v_funcCurrRate numeric := 1;
	v_accntCurrRate numeric := 1;
	v_funcCurrAmnt numeric := 0;
	v_accntCurrAmnt numeric := 0;
	v_prepayDocID bigint := - 1;
	v_otherinfo character varying(200) := '';
	v_AllwDues character varying(1) := '0';
	v_msPyID bigint := - 1;
	v_invoice_id bigint := - 1;
	v_invoice_type character varying(200) := '';
BEGIN
	/*
	 1. Determine amount to pay, change/balance, available amnt on prepay doc id
	 2. Once valid, create payment batch and lines
	 3. Create Journal Batch and Entries
	 4. Update various src, dest tables with amount paid
	 */
	v_msPyID := p_msPyID;
	v_currID := p_invcCurD;
	v_funcCurrID := org.get_orgfunc_crncy_id (orgidno);
	IF (v_currID <= 0) THEN
		v_currID := v_funcCurrID;
	END IF;
	v_spplrID := p_inCstmrSpplrID;
	v_prepayDocID := p_appld_prpay_docid;
	v_pymntBatchID := p_NewPymntBatchID;
	v_pay_date := to_timestamp(p_pay_date, 'DD-Mon-YYYY HH24:MI:SS');
	v_createPrepay := p_createPrepay;
	v_pay_remarks := p_pay_remarks;
	errCntr := 0;
	batchCntr := 0;
	dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	p_orgidno := orgidno;
	v_pymntNthdName := accb.get_pymnt_mthd_name (p_pay_mthd_id);
	v_srcDocID := p_invoice_id;
	v_srcDocType := '';
	v_usrTrnsCode := gst.getGnrlRecNm ('sec.sec_users', 'user_id', 'code_for_trns_nums', p_who_rn);
	IF (char_length(v_usrTrnsCode) <= 0) THEN
		v_usrTrnsCode := 'XX';
	END IF;
	v_dte := to_char(now(), 'YYMMDD');
	v_pymntBatchName := '';
	v_docClsftn := '';
	v_docNum := '';
	v_orgnlPymntBatchID := - 1;
	v_glBatchPrfx := '';
	v_glBatchSrc := '';
	IF p_doc_types = 'Supplier Payments' THEN
		FOR rd2 IN
		SELECT
			pybls_invc_hdr_id,
			pybls_invc_number,
			pybls_invc_type,
			comments_desc,
			src_doc_hdr_id,
			supplier_id,
			supplier_site_id,
			approval_status,
			next_aproval_action,
			org_id,
			invoice_amount,
			src_doc_type,
			pymny_method_id,
			amnt_paid,
			invc_curr_id,
			invc_amnt_appld_elswhr,
			debt_gl_batch_id,
			balancing_accnt_id,
			advc_pay_ifo_doc_id,
			advc_pay_ifo_doc_typ,
			next_part_payment,
			firts_cheque_num
		FROM
			accb.accb_pybls_invc_hdr
		WHERE
			pybls_invc_hdr_id = v_srcDocID LOOP
				p_orgidno := rd2.org_id;
				v_docStatus := rd2.approval_status;
				v_amntToPay := rd2.invoice_amount - rd2.amnt_paid;
				v_spplrID := rd2.supplier_id;
				v_srcDocType := rd2.pybls_invc_type;
				v_spplrSiteID := rd2.supplier_site_id;
				v_currID := rd2.invc_curr_id;
			END LOOP;
	ELSE
		FOR rd2 IN
		SELECT
			rcvbls_invc_hdr_id,
			rcvbls_invc_date,
			rcvbls_invc_number,
			rcvbls_invc_type,
			comments_desc,
			src_doc_hdr_id,
			customer_id,
			customer_site_id,
			approval_status,
			next_aproval_action,
			org_id,
			invoice_amount,
			src_doc_type,
			pymny_method_id,
			amnt_paid,
			invc_curr_id,
			invc_amnt_appld_elswhr,
			balancing_accnt_id,
			debt_gl_batch_id,
			advc_pay_ifo_doc_id,
			advc_pay_ifo_doc_typ
		FROM
			accb.accb_rcvbls_invc_hdr
		WHERE
			rcvbls_invc_hdr_id = v_srcDocID LOOP
				p_orgidno := rd2.org_id;
				v_docStatus := rd2.approval_status;
				v_amntToPay := rd2.invoice_amount - rd2.amnt_paid;
				v_spplrID := rd2.customer_id;
				v_srcDocType := rd2.rcvbls_invc_type;
				v_spplrSiteID := rd2.customer_site_id;
				v_currID := rd2.invc_curr_id;
				v_invoice_id := rd2.src_doc_hdr_id;
				v_invoice_type := rd2.src_doc_type;
			END LOOP;
	END IF;
	IF (p_orgnlPymntID <= 0) THEN
		v_funcCurrID := COALESCE(org.get_Orgfunc_Crncy_id (p_orgidno), - 1);
		IF v_amntToPay >= p_pay_amt_rcvd THEN
			v_amntBeingPaid := p_pay_amt_rcvd;
			v_changeBals := v_amntBeingPaid - p_pay_amt_rcvd;
		ELSIF v_amntToPay > 0 THEN
			v_amntBeingPaid := v_amntToPay;
			v_changeBals := v_amntBeingPaid - p_pay_amt_rcvd;
		ELSE
			v_amntBeingPaid := p_pay_amt_rcvd;
			v_changeBals := 0;
		END IF;
	ELSE
		FOR rd3 IN
		SELECT
			a.pymnt_id,
			a.pymnt_mthd_id,
			accb.get_pymnt_mthd_name (a.pymnt_mthd_id),
			a.amount_paid,
			a.change_or_balance,
			a.pymnt_remark,
			a.src_doc_typ,
			a.src_doc_id,
			accb.get_src_doc_num (a.src_doc_id, a.src_doc_typ),
			to_char(to_timestamp(a.pymnt_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS'),
			a.incrs_dcrs1,
			a.rcvbl_lblty_accnt_id,
			accb.get_accnt_num (a.rcvbl_lblty_accnt_id) || '.' || accb.get_accnt_name (a.rcvbl_lblty_accnt_id) rcvbl_lblty_accnt,
			a.incrs_dcrs2,
			a.cash_or_suspns_acnt_id,
			accb.get_accnt_num (a.cash_or_suspns_acnt_id) || '.' || accb.get_accnt_name (a.cash_or_suspns_acnt_id) cash_or_suspns_acnt,
			a.gl_batch_id,
			accb.get_gl_batch_name (a.gl_batch_id),
			a.orgnl_pymnt_id,
			a.pymnt_vldty_status,
			a.entrd_curr_id,
			gst.get_pssbl_val (a.entrd_curr_id),
			a.func_curr_id,
			gst.get_pssbl_val (a.func_curr_id),
			a.accnt_curr_id,
			gst.get_pssbl_val (a.accnt_curr_id),
			a.func_curr_rate,
			a.accnt_curr_rate,
			a.func_curr_amount,
			a.accnt_curr_amnt,
			a.pymnt_batch_id,
			a.is_removed,
			a.amount_given,
			a.prepay_doc_id,
			accb.get_src_doc_num (a.prepay_doc_id, a.prepay_doc_type),
			a.pay_means_other_info,
			a.cheque_card_name,
			a.expiry_date,
			a.cheque_card_num,
			a.sign_code,
			a.bkgrd_actvty_status,
			a.bkgrd_actvty_gen_doc_name,
			b.cust_spplr_id
		FROM
			accb.accb_payments a,
			accb.accb_payments_batches b
		WHERE ((a.pymnt_batch_id = b.pymnt_batch_id)
			AND (a.pymnt_id = p_orgnlPymntID))
			LOOP
				v_funcCurrID := rd3.func_curr_id;
				v_amntBeingPaid := - 1 * rd3.amount_paid;
				v_changeBals := - 1 * rd3.change_or_balance;
				v_amntToPay := - 1 * rd3.amount_paid;
				v_currID := rd3.entrd_curr_id;
				v_IncrsDcrs1 := rd3.incrs_dcrs1;
				v_AccntID1 := rd3.rcvbl_lblty_accnt_id;
				v_drCrdt1 := accb.dbt_or_crdt_accnt (v_AccntID1, v_IncrsDcrs1);
				v_IncrsDcrs2 := rd3.incrs_dcrs2;
				v_AccntID2 := rd3.cash_or_suspns_acnt_id;
				v_actvtyDocName := rd3.bkgrd_actvty_gen_doc_name;
				v_drCrdt2 := accb.dbt_or_crdt_accnt (v_AccntID2, v_IncrsDcrs2);
				v_accntCurrID := rd3.accnt_curr_id;
				v_funcCurrRate := rd3.func_curr_rate;
				v_accntCurrRate := rd3.accnt_curr_rate;
				v_funcCurrAmnt := - 1 * rd3.func_curr_amount;
				v_accntCurrAmnt := - 1 * rd3.accnt_curr_amnt;
			END LOOP;
	END IF;
	v_PrsnID := sec.get_usr_prsn_id (p_who_rn);
	v_PrsnBrnchID := pasn.get_prsn_siteid (v_PrsnID);
	v_dfltCashAccntID1 := accb.get_DfltCashAcnt (v_PrsnID, p_orgidno);
	v_dfltCashAccntID := org.get_accnt_id_brnch_eqv (v_PrsnBrnchID, v_dfltCashAccntID1);
	v_dfltPyblAccntID := org.get_accnt_id_brnch_eqv (v_PrsnBrnchID, scm.get_dflt_pybl_accid (p_orgidno));
	v_dfltRcvblAccntID := org.get_accnt_id_brnch_eqv (v_PrsnBrnchID, scm.get_dflt_rcvbl_accid (p_orgidno));
	v_reslt_1 := accb.isTransPrmttd (p_orgidno, v_dfltCashAccntID, p_pay_date, 200);
	IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
		msgs := msgs || chr(10) || v_reslt_1;
		msgs := REPLACE(msgs, chr(10), '<br/>');
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
	END IF;
	IF (v_docStatus = 'Cancelled') THEN
		msgs := msgs || chr(10) || 'Cannot Process Payments on Cancelled Documents!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
	END IF;
	v_prcsngPay := TRUE;
	IF (p_pay_mthd_id <= 0) THEN
		msgs := msgs || chr(10) || 'Please indicate the Payment Method!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
	END IF;
	IF (char_length(p_pay_remarks) <= 0) THEN
		msgs := msgs || chr(10) || 'Please indicate the Payment Remark/Comment!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
	END IF;
	IF (p_orgnlPymntID <= 0) THEN
		IF ((v_pymntNthdName ILIKE '%Check%' OR v_pymntNthdName ILIKE '%Cheque%') AND (char_length(p_cheque_card_num) <= 0 OR char_length(p_cheque_card_name) <= 0)) THEN
			msgs := msgs || chr(10) || 'Please Indicate the Card/Cheque Name and No. if Payment Type is Cheque!';
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
		END IF;
		IF (char_length(p_pay_date) <= 0) THEN
			msgs := msgs || chr(10) || 'Please indicate the Payment Date!';
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
		END IF;
		IF (p_pay_amt_rcvd = 0) THEN
			msgs := msgs || chr(10) || 'Please indicate the amount Given!';
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
		END IF;
		IF ((v_pymntNthdName ILIKE '%Prepayment%' OR v_pymntNthdName ILIKE '%Advance%')) THEN
			IF (p_appld_prpay_docid <= 0) THEN
				msgs := msgs || chr(10) || 'Please select the Prepayment you want to Apply First!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
			ELSE
				v_prepayDocID := p_appld_prpay_docid;
				IF (p_doc_types = 'Supplier Payments') THEN
					v_prepayAvlblAmnt := gst.getgnrlrecnm ('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'amnt_paid-invc_amnt_appld_elswhr', p_appld_prpay_docid)::numeric;
					v_prepayDocType := gst.getgnrlrecnm ('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_type', p_appld_prpay_docid);
				ELSE
					v_prepayAvlblAmnt := gst.getgnrlrecnm ('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'amnt_paid-invc_amnt_appld_elswhr', p_appld_prpay_docid)::numeric;
					v_prepayDocType := gst.getgnrlrecnm ('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'rcvbls_invc_type', p_appld_prpay_docid);
				END IF;
				IF (p_pay_amt_rcvd > v_prepayAvlblAmnt) THEN
					msgs := msgs || chr(10) || 'Applied Prepayment Amount Exceeds the Available Amount on the selected Prepayment Document!';
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
				END IF;
			END IF;
		END IF;
	END IF;
	IF (v_amntToPay = 0 AND v_createPrepay = FALSE) THEN
		msgs := msgs || chr(10) || 'Cannot Repay a Fully Paid Document!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
	END IF;
	IF (v_amntToPay < 0 AND p_pay_amt_rcvd > 0) THEN
		msgs := msgs || chr(10) || 'Amount Given Must be Negative(Refund) if Amount to Pay is Negative(Refund)!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
	END IF;
	IF (p_orgnlPymntID > 0) THEN
		IF (accb.isPymntRvrsdB4 (p_orgnlPymntID) > 0) THEN
			msgs := msgs || chr(10) || 'This Payment has been Reversed Already or is the Reversal of Another Payment!';
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
		END IF;
	END IF;
	IF (v_createPrepay = TRUE AND v_spplrID <= 0) THEN
		msgs := msgs || chr(10) || 'Cannot Create Advance Payment when Customer/Supplier is not Specified!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
	END IF;
	IF (p_orgnlPymntID > 0 AND p_msPyID > 0) THEN
		v_reslt_1 := pay.rollBackMsPay (p_msPyID, p_orgidno, p_who_rn);
		IF (v_reslt_1 NOT LIKE 'SUCCESS:%') THEN
			msgs := msgs || chr(10) || v_reslt_1;
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
		END IF;
	END IF;
	IF (v_createPrepay = TRUE AND v_spplrID > 0 AND p_orgnlPymntID <= 0) THEN
		IF (p_doc_types = 'Supplier Payments') THEN
			v_srcDocID := accb.checkNCreatePyblsHdr (p_orgidno, v_spplrID, v_spplrSiteID, substr(p_pay_date, 1, 11), 'Supplier Advance Payment', v_currID, v_amntBeingPaid, p_pay_mthd_id, v_funcCurrID, p_pay_date, - 1, p_who_rn);
			v_srcDocType := gst.getgnrlrecnm ('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_type', v_srcDocID);
		ELSE
			v_srcDocID := accb.checkNCreateRcvblsHdr (p_orgidno, v_spplrID, v_spplrSiteID, substr(p_pay_date, 1, 11), 'Customer Advance Payment', v_currID, v_amntBeingPaid, p_pay_mthd_id, v_funcCurrID, p_pay_date, - 1, p_who_rn);
			v_srcDocType := gst.getgnrlrecnm ('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'rcvbls_invc_type', v_srcDocID);
		END IF;
		v_dsablPayments := FALSE;
		v_createPrepay := FALSE;
	END IF;
	IF p_doc_types = 'Supplier Payments' THEN
		FOR rd2 IN
		SELECT
			pybls_invc_hdr_id,
			pybls_invc_number,
			pybls_invc_type,
			comments_desc,
			src_doc_hdr_id,
			supplier_id,
			supplier_site_id,
			approval_status,
			next_aproval_action,
			org_id,
			invoice_amount,
			src_doc_type,
			pymny_method_id,
			amnt_paid,
			invc_curr_id,
			invc_amnt_appld_elswhr,
			debt_gl_batch_id,
			balancing_accnt_id,
			advc_pay_ifo_doc_id,
			advc_pay_ifo_doc_typ,
			next_part_payment,
			firts_cheque_num
		FROM
			accb.accb_pybls_invc_hdr
		WHERE
			pybls_invc_hdr_id = v_srcDocID LOOP
				p_orgidno := rd2.org_id;
				v_docStatus := rd2.approval_status;
				v_spplrID := rd2.supplier_id;
				v_srcDocType := rd2.pybls_invc_type;
				v_spplrSiteID := rd2.supplier_site_id;
				IF (p_orgnlPymntID <= 0) THEN
					v_currID := rd2.invc_curr_id;
					v_amntToPay := rd2.invoice_amount - rd2.amnt_paid;
					v_IncrsDcrs1 := 'D';
					IF v_srcDocType NOT IN ('Supplier Standard Payment', 'Supplier Advance Payment', 'Direct Topup for Supplier', 'Supplier Debit Memo (InDirect Topup)') THEN
						v_IncrsDcrs1 := 'I';
					END IF;
					v_AccntID1 := rd2.balancing_accnt_id;
					IF coalesce(v_AccntID1, - 1) <= 0 THEN
						v_AccntID1 := v_dfltPyblAccntID;
					END IF;
					v_drCrdt1 := accb.dbt_or_crdt_accnt (v_AccntID1, v_IncrsDcrs1);
					FOR rd1 IN
					SELECT
						current_asst_acnt_id,
						bckgrnd_process_name
					FROM
						accb.accb_paymnt_mthds
					WHERE
						paymnt_mthd_id = p_pay_mthd_id LOOP
							v_IncrsDcrs2 := 'D';
							--v_AccntID2 := rd1.current_asst_acnt_id;
							v_AccntID2 := org.get_accnt_id_brnch_eqv (v_PrsnBrnchID, rd1.current_asst_acnt_id);
							v_actvtyDocName := rd1.bckgrnd_process_name;
							IF (v_drCrdt1 = 'Debit') THEN
								v_IncrsDcrs2 := substr(accb.incrs_or_dcrs_accnt (v_AccntID2, 'Credit'), 1, 1);
							ELSE
								v_IncrsDcrs2 := substr(accb.incrs_or_dcrs_accnt (v_AccntID2, 'Debit'), 1, 1);
							END IF;
							v_drCrdt2 := accb.dbt_or_crdt_accnt (v_AccntID2, v_IncrsDcrs2);
						END LOOP;
				END IF;
			END LOOP;
	ELSE
		FOR rd2 IN
		SELECT
			rcvbls_invc_hdr_id,
			rcvbls_invc_date,
			rcvbls_invc_number,
			rcvbls_invc_type,
			comments_desc,
			src_doc_hdr_id,
			customer_id,
			customer_site_id,
			approval_status,
			next_aproval_action,
			org_id,
			invoice_amount,
			src_doc_type,
			pymny_method_id,
			amnt_paid,
			invc_curr_id,
			invc_amnt_appld_elswhr,
			balancing_accnt_id,
			debt_gl_batch_id,
			advc_pay_ifo_doc_id,
			advc_pay_ifo_doc_typ
		FROM
			accb.accb_rcvbls_invc_hdr
		WHERE
			rcvbls_invc_hdr_id = v_srcDocID LOOP
				p_orgidno := rd2.org_id;
				v_docStatus := rd2.approval_status;
				v_spplrID := rd2.customer_id;
				v_srcDocType := rd2.rcvbls_invc_type;
				v_spplrSiteID := rd2.customer_site_id;
				v_invoice_id := rd2.src_doc_hdr_id;
				v_invoice_type := rd2.src_doc_type;
				IF (p_orgnlPymntID <= 0) THEN
					v_amntToPay := rd2.invoice_amount - rd2.amnt_paid;
					v_currID := rd2.invc_curr_id;
					v_IncrsDcrs1 := 'D';
					IF v_srcDocType NOT IN ('Customer Standard Payment', 'Customer Advance Payment', 'Direct Topup from Customer', 'Customer Credit Memo (InDirect Topup)') THEN
						v_IncrsDcrs1 := 'I';
					END IF;
					v_AccntID1 := rd2.balancing_accnt_id;
					IF coalesce(v_AccntID1, - 1) <= 0 THEN
						v_AccntID1 := v_dfltRcvblAccntID;
					END IF;
					v_drCrdt1 := accb.dbt_or_crdt_accnt (v_AccntID1, v_IncrsDcrs1);
					FOR rd1 IN
					SELECT
						current_asst_acnt_id,
						bckgrnd_process_name
					FROM
						accb.accb_paymnt_mthds
					WHERE
						paymnt_mthd_id = p_pay_mthd_id LOOP
							v_IncrsDcrs2 := 'I';
							--v_AccntID2 := rd1.current_asst_acnt_id;
							v_AccntID2 := org.get_accnt_id_brnch_eqv (v_PrsnBrnchID, rd1.current_asst_acnt_id);
							IF coalesce(v_AccntID2, - 1) <= 0 THEN
								v_AccntID2 := v_dfltCashAccntID;
							END IF;
							v_actvtyDocName := rd1.bckgrnd_process_name;
							IF (v_drCrdt1 = 'Debit') THEN
								v_IncrsDcrs2 := substr(accb.incrs_or_dcrs_accnt (v_AccntID2, 'Credit'), 1, 1);
							ELSE
								v_IncrsDcrs2 := substr(accb.incrs_or_dcrs_accnt (v_AccntID2, 'Debit'), 1, 1);
							END IF;
							v_drCrdt2 := accb.dbt_or_crdt_accnt (v_AccntID2, v_IncrsDcrs2);
						END LOOP;
				END IF;
			END LOOP;
	END IF;
	IF (v_srcDocID <= 0) THEN
		msgs := msgs || chr(10) || 'No Source Receivable or Payable Document Available! Please check your document and try again!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
	END IF;
	IF (v_docStatus != 'Approved') THEN
		msgs := msgs || chr(10) || 'Only Approved Documents can be paid!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
	END IF;
	IF (p_doc_types = 'Supplier Payments') THEN
		v_glBatchPrfx := 'PYMT-SPLR-';
		v_glBatchSrc := 'Payment for Payables Invoice';
		v_gnrtdTrnsNo1 := 'PYMT-SPLR-' || v_usrTrnsCode || '-' || v_dte || '-';
		v_pymntBatchName := v_gnrtdTrnsNo1 || lpad(((gst.getRecCount_LstNum ('accb.accb_payments_batches', 'pymnt_batch_name', 'pymnt_batch_id', v_gnrtdTrnsNo1 || '%') + 1) || ''), 3, '0');
		v_docClsftn := gst.getGnrlRecNm ('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'doc_tmplt_clsfctn', v_srcDocID);
		v_docNum := gst.getGnrlRecNm ('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_number', v_srcDocID);
	ELSE
		v_glBatchPrfx := 'RCPT-CSTMR-';
		v_glBatchSrc := 'Receipt of Payment on Receivables Invoice';
		v_gnrtdTrnsNo1 := 'RCPT-CSTMR-' || v_usrTrnsCode || '-' || v_dte || '-';
		v_pymntBatchName := v_gnrtdTrnsNo1 || lpad(((gst.getRecCount_LstNum ('accb.accb_payments_batches', 'pymnt_batch_name', 'pymnt_batch_id', v_gnrtdTrnsNo1 || '%') + 1) || ''), 3, '0');
		v_docClsftn := gst.getGnrlRecNm ('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'doc_tmplt_clsfctn', v_srcDocID);
		v_docNum := gst.getGnrlRecNm ('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'rcvbls_invc_number', v_srcDocID);
	END IF;
	IF p_NewPymntBatchID <= 0 THEN
		v_pymntBatchID := gst.getGnrlRecID1 ('accb.accb_payments_batches', 'pymnt_batch_name', 'pymnt_batch_id', v_pymntBatchName, p_orgidno);
	END IF;
	IF (p_orgnlPymntID <= 0) THEN
		v_accntCurrID := accb.get_accnt_crncy_id (v_AccntID2);
		v_funcCurrRate := accb.get_ltst_exchrate (v_currID, v_funcCurrID, p_pay_date, p_orgidno);
		v_accntCurrRate := accb.get_ltst_exchrate (v_currID, v_accntCurrID, p_pay_date, p_orgidno);
		v_funcCurrAmnt := v_amntBeingPaid * v_funcCurrRate;
		v_accntCurrAmnt := v_amntBeingPaid * v_accntCurrRate;
	END IF;
	IF (v_pymntBatchID <= 0) THEN
		INSERT INTO accb.accb_payments_batches (pymnt_batch_name, pymnt_batch_desc, pymnt_mthd_id, doc_type, doc_clsfctn, docs_start_date, docs_end_date, batch_status, batch_source, created_by, creation_date, last_update_by, last_update_date, batch_vldty_status, orgnl_batch_id, org_id, cust_spplr_id, pymnt_date, incrs_dcrs1, rcvbl_lblty_accnt_id, incrs_dcrs2, cash_or_suspns_acnt_id, amount_given, amount_being_paid, change_or_balance, entrd_curr_id, func_curr_id, func_curr_rate, func_curr_amount, accnt_curr_id, accnt_curr_rate, accnt_curr_amnt, cheque_card_name, cheque_card_num, sign_code, gl_batch_id)
			VALUES (v_pymntBatchName, v_pymntBatchName, p_pay_mthd_id, v_srcDocType, v_docClsftn, to_char(v_pay_date, 'YYYY-MM-DD HH24:MI:SS'), to_char(v_pay_date, 'YYYY-MM-DD HH24:MI:SS'), 'Unprocessed', p_doc_types, p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), 'VALID', v_orgnlPymntBatchID, p_orgidno, v_spplrID, to_char(v_pay_date, 'YYYY-MM-DD HH24:MI:SS'), v_IncrsDcrs1, v_AccntID1, v_IncrsDcrs2, v_AccntID2, p_pay_amt_rcvd, v_amntBeingPaid, v_changeBals, v_currID, v_funcCurrID, v_funcCurrRate, v_funcCurrAmnt, v_accntCurrID, v_accntCurrRate, v_accntCurrAmnt, p_cheque_card_name, p_cheque_card_num, p_cheque_card_code, - 1);
		IF (v_orgnlPymntBatchID > 0) THEN
			UPDATE
				accb.accb_payments_batches
			SET
				batch_vldty_status = 'VOID',
				last_update_by = p_who_rn,
				last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
			WHERE
				pymnt_batch_id = v_orgnlPymntBatchID;
		END IF;
		v_pymntBatchID := gst.getGnrlRecID1 ('accb.accb_payments_batches', 'pymnt_batch_name', 'pymnt_batch_id', v_pymntBatchName, p_orgidno);
	ELSIF p_NewPymntBatchID <= 0 THEN
		msgs := msgs || chr(10) || 'New Payment Batch Number Exists! Try Again Later!' || v_pymntBatchName;
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
	END IF;
	v_gnrtdTrnsNo1 := v_glBatchPrfx || v_usrTrnsCode || '-' || v_dte || '-';
	v_glBatchName := v_gnrtdTrnsNo1 || lpad(((gst.getRecCount_LstNum ('accb.accb_trnsctn_batches', 'batch_name', 'batch_id', v_gnrtdTrnsNo1 || '%') + 1) || ''), 3, '0');
	v_glBatchID := gst.getGnrlRecID1 ('accb.accb_trnsctn_batches', 'batch_name', 'batch_id', v_glBatchName, p_orgidno);
	v_pay_remarks := p_pay_remarks || ' (' || v_docNum || ')';
	IF (v_glBatchID <= 0) THEN
		INSERT INTO accb.accb_trnsctn_batches (batch_name, batch_description, created_by, creation_date, org_id, batch_status, last_update_by, last_update_date, batch_source, batch_vldty_status, src_batch_id, avlbl_for_postng)
			VALUES (v_glBatchName, v_pay_remarks, p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_orgidno, '0', p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), v_glBatchSrc, 'VALID', v_orgnlGLBatchID, '0');
		v_glBatchID := gst.getGnrlRecID1 ('accb.accb_trnsctn_batches', 'batch_name', 'batch_id', v_glBatchName, p_orgidno);
		IF (v_orgnlGLBatchID > 0) THEN
			UPDATE
				accb.accb_trnsctn_batches
			SET
				batch_vldty_status = 'VOID',
				last_update_by = p_who_rn,
				last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
			WHERE
				batch_id = v_orgnlGLBatchID;
		END IF;
	ELSE
		msgs := msgs || chr(10) || ' GL Batch Could not be Created! Try Again Later!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
	END IF;
	v_glBatchID := gst.getGnrlRecID1 ('accb.accb_trnsctn_batches', 'batch_name', 'batch_id', v_glBatchName, p_orgidno);
	v_pymntID = - 1;
	IF (v_pymntBatchID > 0 AND v_glBatchID > 0) THEN
		/*Check and Run Payroll be4 continuing*/
		IF v_invoice_id > 0 AND v_invoice_type = 'Sales Invoice' AND (p_orgnlPymntID <= 0 AND p_msPyID <= 0) THEN
			v_AllwDues := gst.getGnrlRecNm ('scm.scm_sales_invc_hdr', 'invc_hdr_id', 'allow_dues', v_invoice_id);
			IF v_AllwDues = '1' THEN
				SELECT
					*
				FROM
					pay.createNRunMassPayInvc (v_invoice_id, to_char(v_pay_date, 'DD-Mon-YYYY HH24:MI:SS'), v_amntBeingPaid, p_who_rn) INTO v_msPyID,
					v_reslt_1;
				--v_invoice_id:=1/0;
				IF (v_reslt_1 NOT LIKE 'SUCCESS:%') THEN
					msgs := msgs || chr(10) || v_reslt_1;
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
				END IF;
			END IF;
		END IF;
		v_pymntID := nextval('accb.accb_payments_pymnt_id_seq');
		INSERT INTO accb.accb_payments (pymnt_id, pymnt_mthd_id, amount_paid, change_or_balance, pymnt_remark, src_doc_typ, src_doc_id, created_by, creation_date, last_update_by, last_update_date, pymnt_date, incrs_dcrs1, rcvbl_lblty_accnt_id, incrs_dcrs2, cash_or_suspns_acnt_id, gl_batch_id, orgnl_pymnt_id, pymnt_vldty_status, entrd_curr_id, func_curr_id, accnt_curr_id, func_curr_rate, accnt_curr_rate, func_curr_amount, accnt_curr_amnt, pymnt_batch_id, prepay_doc_id, prepay_doc_type, pay_means_other_info, cheque_card_name, expiry_date, cheque_card_num, sign_code, bkgrd_actvty_status, bkgrd_actvty_gen_doc_name, intnl_pay_trns_id, is_cheque_printed, is_removed, amount_given)
			VALUES (v_pymntID, p_pay_mthd_id, v_amntBeingPaid, v_changeBals, v_pay_remarks, v_srcDocType, v_srcDocID, p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), to_char(v_pay_date, 'YYYY-MM-DD HH24:MI:SS'), v_IncrsDcrs1, v_AccntID1, v_IncrsDcrs2, v_AccntID2, v_glBatchID, p_orgnlPymntID, 'VALID', v_currID, v_funcCurrID, v_accntCurrID, v_funcCurrRate, v_accntCurrRate, v_funcCurrAmnt, v_accntCurrAmnt, v_pymntBatchID, v_prepayDocID, v_prepayDocType, v_otherinfo, p_cheque_card_name, p_cheque_card_expdate, p_cheque_card_num, p_cheque_card_code, '', v_actvtyDocName, v_msPyID, '0', '0', p_pay_amt_rcvd);
		IF (p_orgnlPymntID > 0) THEN
			UPDATE
				accb.accb_payments
			SET
				last_update_by = p_who_rn,
				last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),
				pymnt_vldty_status = 'VOID'
			WHERE
				pymnt_id = p_orgnlPymntID;
		END IF;
		v_reslt_1 := accb.CreatePymntAccntngTrns (v_AccntID2, v_glBatchID, v_IncrsDcrs2, v_funcCurrAmnt, p_orgidno, p_pay_date, v_pay_remarks, v_funcCurrID, v_amntBeingPaid, v_currID, v_accntCurrAmnt, v_accntCurrID, v_funcCurrRate, v_accntCurrRate, p_cheque_card_num, v_pymntID, p_who_rn);
		IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = 'PAYMENT ACCOUNTING TRANSACTION FAILED' || v_reslt_1, HINT = 'Payment Accounting Transaction could not be created!' || v_reslt_1;
		END IF;
		v_reslt_1 := accb.CreatePymntAccntngTrns (v_AccntID1, v_glBatchID, v_IncrsDcrs1, v_funcCurrAmnt, p_orgidno, p_pay_date, v_pay_remarks, v_funcCurrID, v_amntBeingPaid, v_currID, v_accntCurrAmnt, v_accntCurrID, v_funcCurrRate, v_accntCurrRate, p_cheque_card_num, v_pymntID, p_who_rn);
		IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = 'PAYMENT ACCOUNTING TRANSACTION FAILED' || v_reslt_1, HINT = 'Payment Accounting Transaction could not be created!' || v_reslt_1;
		END IF;
	END IF;
	IF (accb.get_Batch_CrdtSum (v_glBatchID) = accb.get_Batch_DbtSum (v_glBatchID)) THEN
		IF (p_doc_types = 'Supplier Payments') THEN
			UPDATE
				accb.accb_pybls_invc_hdr
			SET
				amnt_paid = amnt_paid + v_amntBeingPaid,
				next_part_payment = next_part_payment - v_amntBeingPaid,
				last_update_by = p_who_rn,
				last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
			WHERE (pybls_invc_hdr_id = v_srcDocID);
			UPDATE
				accb.accb_pybls_invc_hdr
			SET
				next_part_payment = 0
			WHERE (next_part_payment < 0);
			IF (v_prepayDocID > 0) THEN
				UPDATE
					accb.accb_pybls_invc_hdr
				SET
					invc_amnt_appld_elswhr = invc_amnt_appld_elswhr + v_amntBeingPaid,
					last_update_by = p_who_rn,
					last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
				WHERE (pybls_invc_hdr_id = v_prepayDocID);
				v_prepayDocType := gst.getGnrlRecNm ('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_type', v_prepayDocID);
				IF (v_prepayDocType = 'Supplier Credit Memo (InDirect Refund)' OR v_prepayDocType = 'Supplier Debit Memo (InDirect Topup)') THEN
					UPDATE
						accb.accb_pybls_invc_hdr
					SET
						amnt_paid = amnt_paid + v_amntBeingPaid,
						next_part_payment = next_part_payment - v_amntBeingPaid,
						last_update_by = p_who_rn,
						last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
					WHERE (pybls_invc_hdr_id = v_prepayDocID);
					UPDATE
						accb.accb_pybls_invc_hdr
					SET
						next_part_payment = 0
					WHERE (next_part_payment < 0);
				END IF;
			END IF;
			v_reslt_1 := accb.reCalcPyblsSmmrys (v_srcDocID, v_srcDocType, p_who_rn);
		ELSE
			UPDATE
				accb.accb_rcvbls_invc_hdr
			SET
				amnt_paid = amnt_paid + v_amntBeingPaid,
				last_update_by = p_who_rn,
				last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
			WHERE (rcvbls_invc_hdr_id = v_srcDocID);
			IF (v_prepayDocID > 0) THEN
				UPDATE
					accb.accb_rcvbls_invc_hdr
				SET
					invc_amnt_appld_elswhr = invc_amnt_appld_elswhr + v_amntBeingPaid,
					last_update_by = p_who_rn,
					last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
				WHERE (rcvbls_invc_hdr_id = v_prepayDocID);
				v_prepayDocType := gst.getGnrlRecNm ('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'rcvbls_invc_type', v_prepayDocID);
				IF (v_prepayDocType = 'Customer Credit Memo (InDirect Topup)' OR v_prepayDocType = 'Customer Debit Memo (InDirect Refund)') THEN
					UPDATE
						accb.accb_rcvbls_invc_hdr
					SET
						amnt_paid = amnt_paid + v_amntBeingPaid,
						last_update_by = p_who_rn,
						last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
					WHERE (rcvbls_invc_hdr_id = v_prepayDocID);
				END IF;
			END IF;
			v_reslt_1 := accb.reCalcRcvblsSmmrys (v_srcDocID, v_srcDocType, p_who_rn);
		END IF;
		IF (v_srcDocType = 'Supplier Credit Memo (InDirect Refund)' OR v_srcDocType = 'Supplier Debit Memo (InDirect Topup)') THEN
			UPDATE
				accb.accb_pybls_invc_hdr
			SET
				invc_amnt_appld_elswhr = invc_amnt_appld_elswhr + v_amntBeingPaid,
				last_update_by = p_who_rn,
				last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
			WHERE (pybls_invc_hdr_id = v_srcDocID);
			UPDATE
				accb.accb_pybls_invc_hdr
			SET
				next_part_payment = 0
			WHERE (next_part_payment < 0);
		ELSIF (v_srcDocType = 'Customer Credit Memo (InDirect Topup)'
				OR v_srcDocType = 'Customer Debit Memo (InDirect Refund)') THEN
			UPDATE
				accb.accb_rcvbls_invc_hdr
			SET
				invc_amnt_appld_elswhr = invc_amnt_appld_elswhr + v_amntBeingPaid,
				last_update_by = p_who_rn,
				last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
			WHERE (rcvbls_invc_hdr_id = v_srcDocID);
		END IF;
		UPDATE
			accb.accb_payments_batches
		SET
			batch_status = 'Processed',
			last_update_by = p_who_rn,
			last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
		WHERE (pymnt_batch_id = v_pymntBatchID);
		UPDATE
			accb.accb_trnsctn_batches
		SET
			avlbl_for_postng = '1',
			last_update_by = p_who_rn,
			last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
		WHERE
			batch_id = v_glBatchID;
		IF (p_doc_types = 'Supplier Payments') THEN
			IF (v_srcDocType ILIKE '%Advance%' AND p_orgnlPymntID > 0 AND accb.shdPyblsDocBeCancelled (v_srcDocID) = TRUE) THEN
				v_reslt_1 := accb.docCanclltnProcess (v_srcDocID, v_srcDocType, 'Payables', p_orgidno, p_who_rn);
				IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR', MESSAGE = 'PAYMENT ACCOUNTING TRANSACTION FAILED' || v_reslt_1, HINT = 'Payment Accounting Transaction could not be created!' || v_reslt_1;
				END IF;
			END IF;
		ELSE
			IF (v_srcDocType ILIKE '%Advance%' AND p_orgnlPymntID > 0 AND accb.shdRcvblsDocBeCancelled (v_srcDocID) = TRUE) THEN
				v_reslt_1 := accb.docCanclltnProcess (v_srcDocID, v_srcDocType, 'Receivables', p_orgidno, p_who_rn);
				IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR', MESSAGE = 'PAYMENT ACCOUNTING TRANSACTION FAILED' || v_reslt_1, HINT = 'Payment Accounting Transaction could not be created!' || v_reslt_1;
				END IF;
			END IF;
		END IF;
		IF v_pymntBatchID > 0 THEN
			UPDATE
				accb.accb_payments_batches a
			SET
				pymnt_date = last_update_date,
				incrs_dcrs1 = (
					SELECT
						max(
							CASE WHEN Coalesce(b.incrs_dcrs1, 'D') = 'D' THEN
								'Decrease'
							ELSE
								'Increase'
							END)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), rcvbl_lblty_accnt_id = (
					SELECT
						max(b.rcvbl_lblty_accnt_id)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), incrs_dcrs2 = (
					SELECT
						max(
							CASE WHEN Coalesce(b.incrs_dcrs2, 'I') = 'I' THEN
								'Increase'
							ELSE
								'Decrease'
							END)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), cash_or_suspns_acnt_id = (
					SELECT
						max(b.cash_or_suspns_acnt_id)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), amount_given = (
					SELECT
						sum(b.amount_given)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), amount_being_paid = (
					SELECT
						sum(b.amount_paid)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), change_or_balance = (
					SELECT
						sum(b.change_or_balance)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), entrd_curr_id = (
					SELECT
						max(b.entrd_curr_id)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), func_curr_id = (
					SELECT
						max(b.func_curr_id)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), func_curr_rate = (
					SELECT
						max(b.func_curr_rate)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), func_curr_amount = (
					SELECT
						sum(b.func_curr_amount)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), accnt_curr_id = (
					SELECT
						max(b.accnt_curr_id)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), accnt_curr_rate = (
					SELECT
						max(b.accnt_curr_rate)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), accnt_curr_amnt = (
					SELECT
						sum(b.accnt_curr_amnt)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), cheque_card_name = (
					SELECT
						max(b.cheque_card_name)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), cheque_card_num = (
					SELECT
						max(b.cheque_card_num)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), sign_code = (
					SELECT
						max(b.sign_code)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id), gl_batch_id = (
					SELECT
						min(b.gl_batch_id)
					FROM
						accb.accb_payments b
					WHERE
						a.pymnt_batch_id = b.pymnt_batch_id)
			WHERE (a.pymnt_batch_id = v_pymntBatchID);
		END IF;
	ELSE
		msgs := msgs || chr(10) || 'The GL Batch created IS NOT Balanced!Transactions created will be reversed AND deleted!';
		DELETE FROM accb.accb_trnsctn_details
		WHERE (batch_id = v_glBatchID);
		DELETE FROM accb.accb_trnsctn_batches
		WHERE (batch_id = v_glBatchID);
		UPDATE
			accb.accb_trnsctn_batches
		SET
			batch_vldty_status = 'VALID'
		WHERE
			batch_id IN (
				SELECT
					h.batch_id
				FROM
					accb.accb_trnsctn_batches h
				WHERE
					batch_vldty_status = 'VOID'
					AND NOT EXISTS (
						SELECT
							g.batch_id
						FROM
							accb.accb_trnsctn_batches g
						WHERE
							h.batch_id = g.src_batch_id));
		DELETE FROM accb.accb_payments
		WHERE pymnt_batch_id = v_pymntBatchID;
		DELETE FROM accb.accb_payments_batches
		WHERE pymnt_batch_id = v_pymntBatchID;
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
		RETURN msgs;
	END IF;
	msgs := 'SUCCESS:Payment Successfully Made!';
	RETURN REPLACE(msgs, chr(10), '<br/>');
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		msgs := msgs || chr(10) || '' || SQLSTATE || chr(10) || SQLERRM;
	--msgs := REPLACE(msgs, chr(10), '<br/>');
	RETURN msgs;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.autoloadbdgttmp (p_bdgtid bigint, p_startdte character varying, p_enddte character varying, p_periodtyp character varying, p_orgid integer, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	rd1 RECORD;
	msgs text := 'ERROR:';
	v_reslt_1 text := '';
	v_dteArray1 text[];
	v_accnt_IDRd integer := - 1;
	v_accntType character varying(10) := '';
	v_bdgtAccntTypes character varying(100) := '';
	v_isprnt character varying(1) := '';
	v_iscntrl character varying(1) := '';
	v_bdgtStrtDate character varying(21) := '';
	v_bdgtEndDate character varying(21) := '';
	v_rem integer := 0;
	v_bdgtlnid bigint := - 1;
	v_oldBdgtDtID1 bigint := - 1;
	v_oldBdgtDtID2 bigint := - 1;
	b_isDteOK boolean := FALSE;
	b_isPrmtd boolean := FALSE;
	v_Cntr integer := 0;
BEGIN
	DELETE FROM accb.accb_budget_details
	WHERE limit_amount = 0
		AND coalesce(entrd_curr_id, - 1) <= 0;
	v_bdgtAccntTypes := gst.getGnrlRecNm ('accb.accb_budget_header', 'budget_id', 'allwd_accnt_types', p_bdgtID);
	v_reslt_1 := accb.getBdgtDates (p_startDte, p_endDte, p_periodTyp);
	v_dteArray1 := string_to_array(v_reslt_1, '|');
	FOR rd1 IN
	SELECT
		accnt_id,
		accnt_num,
		accnt_name,
		accnt_type,
		is_prnt_accnt,
		account_number_name,
		accnt_typ_id,
		prnt_accnt_id,
		control_account_id,
		depth,
		path,
		CYCLE
	FROM
		accb.get_Bdgt_ChrtDet ('%', 'Account Details', 0, 1000000000, p_orgID, - 1, - 1)
		LOOP
			v_accnt_IDRd := rd1.accnt_id;
			v_accntType := rd1.accnt_type;
			IF (v_accntType NOT IN ('R', 'EX') AND v_bdgtAccntTypes = 'INCOME/EXPENDITURE') OR (v_accntType NOT IN ('EX') AND v_bdgtAccntTypes = 'EXPENDITURE') OR (v_accntType NOT IN ('A', 'R', 'EX') AND v_bdgtAccntTypes = 'ASSETS/INCOME/EXPENDITURE') THEN
				CONTINUE;
			END IF;
			v_Cntr := v_Cntr + 1;
			v_isprnt := rd1.is_prnt_accnt;
			v_iscntrl := gst.getGnrlRecNm ('accb.accb_chart_of_accnts', 'accnt_id', 'has_sub_ledgers', v_accnt_IDRd);
			b_isPrmtd := TRUE;
			v_bdgtStrtDate := '';
			v_bdgtEndDate := '';
			FOR a IN 1.. array_length(v_dteArray1, 1)
			LOOP
				v_rem := a % 2;
				IF (v_rem = 1) THEN
					v_bdgtStrtDate := substr(v_dteArray1[a], 1, 21);
					v_bdgtEndDate := substr(v_dteArray1[a + 1], 1, 21);
					IF char_length(v_bdgtStrtDate) <= 0 OR char_length(v_bdgtEndDate) <= 0 THEN
						CONTINUE;
					END IF;
					v_bdgtlnid := accb.get_BdgtLnID (p_bdgtID, v_accnt_IDRd, v_bdgtStrtDate, v_bdgtEndDate);
					v_oldBdgtDtID1 := accb.doesBdgtDteOvrlap (p_bdgtID, v_accnt_IDRd, v_bdgtStrtDate);
					v_oldBdgtDtID2 := accb.doesBdgtDteOvrlap (p_bdgtID, v_accnt_IDRd, v_bdgtEndDate);
					b_isDteOK := TRUE;
					IF (v_bdgtlnid <= 0 AND v_oldBdgtDtID1 > 0) THEN
						b_isDteOK := FALSE;
					END IF;
					IF (v_bdgtlnid <= 0 AND v_oldBdgtDtID2 > 0) THEN
						b_isDteOK := FALSE;
					END IF;
					IF (v_bdgtlnid > 0 AND v_oldBdgtDtID1 > 0 AND v_bdgtlnid != v_oldBdgtDtID1) THEN
						b_isDteOK := FALSE;
					END IF;
					IF (v_bdgtlnid > 0 AND v_oldBdgtDtID2 > 0 AND v_bdgtlnid != v_oldBdgtDtID2) THEN
						b_isDteOK := FALSE;
					END IF;
					IF (v_bdgtlnid > 0 AND b_isDteOK = TRUE AND b_isPrmtd = TRUE) THEN
						v_reslt_1 := '';
					ELSIF (v_isprnt = '0'
							AND v_iscntrl = '0'
							AND b_isDteOK = TRUE
							AND b_isPrmtd = TRUE
							AND v_bdgtlnid <= 0
							AND v_oldBdgtDtID1 <= 0
							AND v_oldBdgtDtID2 <= 0) THEN
						IF (v_accntType = 'EX') THEN
							v_reslt_1 := accb.createBdgtLn (p_bdgtID, v_accnt_IDRd, 0, v_bdgtStrtDate, v_bdgtEndDate, 'Warn', p_who_rn);
							IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
								RAISE EXCEPTION
									USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
								RETURN v_reslt_1;
							END IF;
						ELSE
							v_reslt_1 := accb.createBdgtLn (p_bdgtID, v_accnt_IDRd, 0, v_bdgtStrtDate, v_bdgtEndDate, 'Do Nothing', p_who_rn);
							IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
								RAISE EXCEPTION
									USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
								RETURN v_reslt_1;
							END IF;
						END IF;
					END IF;
				END IF;
			END LOOP;
		END LOOP;
	REFRESH MATERIALIZED VIEW accb.accb_budget_detail_mv WITH DATA;
	--REFRESH MATERIALIZED VIEW CONCURRENTLY accb.accb_budget_detail_mv;
	RETURN 'SUCCESS:' || v_Cntr || ' accounts inserted in Budget';
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;