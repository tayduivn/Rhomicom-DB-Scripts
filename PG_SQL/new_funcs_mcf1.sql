CREATE OR REPLACE FUNCTION aca.isPrsnElgblToRgstr (p_prsnid bigint, p_allwd_prsn_typs character varying, p_fees_prcnt numeric, p_ttl_pymnts_itm_st_nm character varying, p_ttl_bills_itm_st_nm character varying, p_ttl_bals_itm_st_nm character varying)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res character varying(4000) := '';
	v_ttl_pymnts_itm_st_id bigint := - 1;
	v_ttl_bills_itm_st_id bigint := - 1;
	v_ttl_bals_itm_st_id bigint := - 1;
	v_ttl_pymnts_itm_st_sum numeric := 0;
	v_ttl_bills_itm_st_sum numeric := 0;
	v_ttl_bals_itm_st_sum numeric := 0;
	v_ltst_bill_dte character varying(21) := '';
BEGIN
	/*Work with latest figures from each itm set*/
	v_ttl_pymnts_itm_st_id := org.get_payitm_id (p_ttl_pymnts_itm_st_nm);
	v_ttl_bills_itm_st_id := org.get_payitm_id (p_ttl_bills_itm_st_nm);
	v_ttl_bals_itm_st_id := org.get_payitm_id (p_ttl_bals_itm_st_nm);
	IF coalesce(v_ttl_bills_itm_st_id, - 1) > 0 THEN
		SELECT
			SUM(coalesce(pay.get_ltst_paiditem_val_b4 (p_prsnid, item_id, to_char(now(), 'YYYY-MM-DD')), 0)),
			MAX(pay.get_ltst_paiditem_dte (p_prsnid, item_id)) INTO v_ttl_bills_itm_st_sum,
			v_ltst_bill_dte
		FROM
			pay.get_AllItmStDet (v_ttl_bills_itm_st_id::integer);
	END IF;
	IF coalesce(v_ltst_bill_dte, '') != '' THEN
		v_ltst_bill_dte := to_char(now(), 'YYYY-MM-DD');
	END IF;
	IF coalesce(v_ttl_pymnts_itm_st_id, - 1) > 0 THEN
		SELECT
			SUM(coalesce(pay.get_ltst_paiditem_val_afta (p_prsnid, item_id, v_ltst_bill_dte), 0)) INTO v_ttl_pymnts_itm_st_sum
		FROM
			pay.get_AllItmStDet (v_ttl_pymnts_itm_st_id::integer);
	END IF;
	IF coalesce(v_ttl_bals_itm_st_id, - 1) > 0 THEN
		SELECT
			SUM(coalesce(pay.get_ltst_blsitm_bals (p_prsnid, item_id, to_char(now(), 'YYYY-MM-DD')), 0)) INTO v_ttl_bals_itm_st_sum
		FROM
			pay.get_AllItmStDet (v_ttl_bals_itm_st_id::integer);
	END IF;
	IF coalesce(v_ttl_bills_itm_st_sum, 0) = 0 THEN
		v_ttl_bills_itm_st_sum := 1;
	END IF;
	IF NOT (p_allwd_prsn_typs ILIKE '%;' || pasn.get_prsn_type (p_prsnid) || ';%') THEN
		v_res := 'NO:Sorry you cannot Register until you are defined in the ff Person Types! - ' || BTRIM(p_allwd_prsn_typs, ';');
	END IF;
	IF (round((v_ttl_pymnts_itm_st_sum / v_ttl_bills_itm_st_sum),2) < (p_fees_prcnt / 100)) THEN
		v_res := 'NO:Sorry you cannot Register until you have paid ' || p_fees_prcnt || '% of your Total Bills/Charges!<br/>Outstanding Balance is ' || v_ttl_bals_itm_st_sum;
	END IF;
	RETURN COALESCE(v_res, 'YES:You can Register!');
EXCEPTION
	WHEN OTHERS THEN
		v_res := 'NO:' || SQLERRM;
	RETURN v_res;
END;

$BODY$;

--DROP FUNCTION pay.get_tk_tied_to_frm_bls (p_itmName bigint, p_replace_str character varying);
CREATE OR REPLACE FUNCTION pay.get_tk_tied_to_frm_bls (p_PrsnID bigint, p_itmName character varying, p_replace_str character varying)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid character varying(300) := '';
	v_repay_prd numeric := 0;
	v_nwSQL text := '';
BEGIN
	v_repay_prd := pay.get_ltst_blsitm_bals (p_PrsnID, org.get_payitm_id (REPLACE(p_itmName, p_replace_str, '') || ' Repayment Period Balance'), to_char(now(), 'YYYY-MM-DD'));
	SELECT
		' (' || (
			CASE WHEN a.item_type_name ILIKE 'Semi%Month%' THEN
				'Till ' || pay.get_tk_loan_end_dte (b.pay_request_id) || ' [' || round(coalesce(v_repay_prd, 0) / 2, 2) || ' months remaining]'
			ELSE
				substr(pay.get_tk_loan_end_dte (b.pay_request_id), 8, 4)
			END) || ')' INTO bid
	FROM
		pay.loan_pymnt_invstmnt_typs a,
		pay.pay_loan_pymnt_rqsts b
	WHERE
		a.item_type_id = b.item_type_id
		AND a.item_type_name ILIKE REPLACE(p_itmName, p_replace_str, '') || '%'
		AND a.item_type = 'LOAN'
		AND b.is_processed = '1'
		AND b.rqstd_for_person_id = p_PrsnID
	ORDER BY
		b.pay_request_id DESC
	LIMIT 1 OFFSET 0;
	IF coalesce(bid, '') = '' AND p_itmName ILIKE 'Semi%Month%' THEN
		v_nwSQL := 'Select to_char(now() + interval ''' || round(v_repay_prd / 2, 2) || ' months'',''DD-Mon-YYYY'')';
		EXECUTE v_nwSQL INTO bid;
		IF coalesce(bid, '') != '' THEN
			bid := ' (Till ' || bid || ' [' || round(v_repay_prd / 2, 2) || ' months remaining])';
		END IF;
	END IF;
	RETURN coalesce(bid, '');
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.doesPrsnHvPndngRqsts (p_prsnid bigint, p_itmid bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		count(y.pay_request_id) INTO v_res
	FROM
		pay.pay_loan_pymnt_rqsts y,
		pay.loan_pymnt_invstmnt_typs z
	WHERE
		y.item_type_id = z.item_type_id
		AND y.RQSTD_FOR_PERSON_ID = p_prsnid
		AND (z.main_amnt_itm_id = p_itmid
			OR p_itmid IN (
				SELECT
					a.item_id
				FROM
					pay.get_AllItmStDet (z.pay_itm_set_id::integer) a))
		AND y.REQUEST_STATUS = 'Approved'
		AND y.IS_PROCESSED != '1'
		AND z.item_type_name ILIKE substr(org.get_payitm_nm (p_itmid), 1, 2) || '%';
	RETURN COALESCE(v_res, 0);
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION accb.get_template_name (glbatchid bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid character varying := '';
BEGIN
	SELECT
		template_name INTO bid
	FROM
		accb.accb_trnsctn_templates_hdr
	WHERE
		template_id = $1;
	RETURN bid;
END;
$BODY$;

CREATE OR REPLACE FUNCTION public.chartonumeric (charparam character varying)
	RETURNS numeric
	LANGUAGE 'sql'
	COST 100 VOLATILE
	AS $BODY$
	SELECT
		CASE WHEN trim(REPLACE($1, ',', ''))
		SIMILAR TO '[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?' THEN
			CAST(trim(REPLACE($1, ',', '')) AS numeric)
		ELSE
			0
		END;

$BODY$;

CREATE OR REPLACE FUNCTION org.get_payitm_uom (itmid bigint)
	RETURNS character varying
	LANGUAGE 'sql'
	COST 100 VOLATILE
	AS $BODY$
	SELECT
		item_value_uom
	FROM
		org.org_pay_items
	WHERE
		item_id = $1
$BODY$;

CREATE OR REPLACE FUNCTION gst.cnvrt_ymdtm_to_dmytm (inptdte character varying)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid character varying := '';
BEGIN
	SELECT
		to_char(to_timestamp(inptDte, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') INTO bid;
	RETURN COALESCE(bid, '');
EXCEPTION
	WHEN OTHERS THEN
		RETURN '';
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trans_typ_nm (p_trns_typ_id bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid character varying(200) := '';
BEGIN
	SELECT
		item_type_name INTO bid
	FROM
		pay.loan_pymnt_invstmnt_typs
	WHERE
		item_type_id = p_trns_typ_id;
	RETURN coalesce(bid, '');
EXCEPTION
	WHEN OTHERS THEN
		RETURN '';
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.chck_n_updt_pay_rqsts (p_ms_py_id bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid character varying(200) := '';
	v_request_id bigint := - 1;
	v_itm_typ_id bigint := - 1;
	rw RECORD;
BEGIN
	FOR rw IN
	SELECT
		a.person_id,
		a.item_id,
		a.mass_pay_id,
		b.run_status,
		a.src_py_trns_id,
		a.pay_request_id,
		a.pay_trns_id,
		a.paymnt_date,
		(
			CASE WHEN a.src_py_trns_id > 0 THEN
			(
				SELECT
					f.pay_request_id
				FROM
					pay.pay_itm_trnsctns f
				WHERE
					f.pay_trns_id = a.src_py_trns_id)
			ELSE
				- 1
			END) src_pay_request_id
FROM
	pay.pay_itm_trnsctns a,
	pay.pay_mass_pay_run_hdr b
WHERE
	a.mass_pay_id = b.mass_pay_id
		AND a.mass_pay_id = p_ms_py_id
		AND a.pymnt_vldty_status = 'VALID' LOOP
			IF coalesce(rw.src_py_trns_id, - 1) <= 0 THEN
				v_request_id := rw.pay_request_id;
				IF coalesce(v_request_id, - 1) > 0 THEN
					UPDATE
						pay.pay_loan_pymnt_rqsts
					SET
						IS_PROCESSED = '1',
						last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
					WHERE
						pay_request_id = v_request_id;
				END IF;
			ELSIF coalesce(rw.src_py_trns_id, - 1) > 0 THEN
				v_request_id := rw.src_pay_request_id;
				IF coalesce(v_request_id, - 1) > 0 THEN
					UPDATE
						pay.pay_itm_trnsctns
					SET
						pay_request_id = - 1
					WHERE
						pay_trns_id = rw.src_py_trns_id;
					UPDATE
						pay.pay_loan_pymnt_rqsts
					SET
						IS_PROCESSED = '0',
						date_processed = '',
						last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
					WHERE
						pay_request_id = v_request_id;
				END IF;
			END IF;
		END LOOP;
	RETURN 'SUCCESS:';

	/*EXCEPTION
	 WHEN OTHERS THEN
	 RETURN 'ERROR:' || SQLERRM;*/
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_ltst_pay_rqst_amnt2 (p_prsn_id bigint, p_item_typ_nm character varying, p_trns_date character varying, p_rqst_id bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
	v_request_id bigint := - 1;
	v_itm_typ_id bigint := - 1;
BEGIN
	SELECT
		PRNCPL_AMOUNT,
		pay_request_id,
		item_type_id INTO bid,
		v_request_id,
		v_itm_typ_id
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		RQSTD_FOR_PERSON_ID = p_prsn_id
		AND UPPER(pay.get_trans_typ_nm (item_type_id)) = UPPER(p_item_typ_nm)
		AND REQUEST_STATUS = 'Approved'
		AND IS_PROCESSED != '1'
		AND pay_request_id = p_rqst_id
	ORDER BY
		pay_request_id DESC
	LIMIT 1 OFFSET 0;
	IF coalesce(v_request_id, - 1) > 0 THEN
		UPDATE
			pay.pay_loan_pymnt_rqsts
		SET
			date_processed = p_trns_date,
			last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
		WHERE
			pay_request_id = v_request_id;
	END IF;
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_ltstpy_rqst_netamt2 (p_prsn_id bigint, p_item_typ_nm character varying, p_trns_date character varying, p_rqst_id bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
	v_request_id bigint := - 1;
	v_itm_typ_id bigint := - 1;
BEGIN
	SELECT
		net_loan_amount,
		pay_request_id,
		item_type_id INTO bid,
		v_request_id,
		v_itm_typ_id
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		RQSTD_FOR_PERSON_ID = p_prsn_id
		AND UPPER(pay.get_trans_typ_nm (item_type_id)) = UPPER(p_item_typ_nm)
		AND REQUEST_STATUS = 'Approved'
		AND IS_PROCESSED != '1'
		AND pay_request_id = p_rqst_id
	ORDER BY
		pay_request_id DESC
	LIMIT 1 OFFSET 0;
	IF coalesce(v_request_id, - 1) > 0 THEN
		UPDATE
			pay.pay_loan_pymnt_rqsts
		SET
			date_processed = p_trns_date,
			last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
		WHERE
			pay_request_id = v_request_id;
	END IF;
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_ltst_rqst_intrst2 (p_prsn_id bigint, p_item_typ_nm character varying, p_trns_date character varying, p_rqst_id bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
	v_request_id bigint := - 1;
	v_itm_typ_id bigint := - 1;
BEGIN
	SELECT
		(mnthly_deduc * repay_period) - PRNCPL_AMOUNT INTO bid
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		RQSTD_FOR_PERSON_ID = p_prsn_id
		AND UPPER(pay.get_trans_typ_nm (item_type_id)) = UPPER(p_item_typ_nm)
		AND REQUEST_STATUS = 'Approved'
		AND IS_PROCESSED != '1'
		AND pay_request_id = p_rqst_id
	ORDER BY
		pay_request_id DESC
	LIMIT 1 OFFSET 0;
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_ltst_rqst_rpy_prd2 (p_prsn_id bigint, p_item_typ_nm character varying, p_trns_date character varying, p_rqst_id bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
	v_request_id bigint := - 1;
	v_itm_typ_id bigint := - 1;
BEGIN
	SELECT
		repay_period INTO bid
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		RQSTD_FOR_PERSON_ID = p_prsn_id
		AND UPPER(pay.get_trans_typ_nm (item_type_id)) = UPPER(p_item_typ_nm)
		AND REQUEST_STATUS = 'Approved'
		AND IS_PROCESSED != '1'
		AND pay_request_id = p_rqst_id
	ORDER BY
		pay_request_id DESC
	LIMIT 1 OFFSET 0;
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

--DROP FUNCTION pay.get_ltst_pay_rqst_amnt(p_prsn_id bigint, p_item_typ_nm CHARACTER VARYING);
CREATE OR REPLACE FUNCTION pay.get_ltst_pay_rqst_amnt (p_prsn_id bigint, p_item_typ_nm character varying, p_trns_date character varying)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
	v_request_id bigint := - 1;
	v_itm_typ_id bigint := - 1;
BEGIN
	SELECT
		PRNCPL_AMOUNT,
		pay_request_id,
		item_type_id INTO bid,
		v_request_id,
		v_itm_typ_id
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		RQSTD_FOR_PERSON_ID = p_prsn_id
		AND UPPER(pay.get_trans_typ_nm (item_type_id)) = UPPER(p_item_typ_nm)
		AND REQUEST_STATUS = 'Approved'
		AND IS_PROCESSED != '1'
	ORDER BY
		pay_request_id DESC
	LIMIT 1 OFFSET 0;
	IF coalesce(v_request_id, - 1) > 0 THEN
		UPDATE
			pay.pay_loan_pymnt_rqsts
		SET
			date_processed = p_trns_date,
			last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
		WHERE
			pay_request_id = v_request_id;
	END IF;
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_ltstpy_rqst_netamt (p_prsn_id bigint, p_item_typ_nm character varying, p_trns_date character varying)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
	v_request_id bigint := - 1;
	v_itm_typ_id bigint := - 1;
BEGIN
	SELECT
		net_loan_amount,
		pay_request_id,
		item_type_id INTO bid,
		v_request_id,
		v_itm_typ_id
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		RQSTD_FOR_PERSON_ID = p_prsn_id
		AND UPPER(pay.get_trans_typ_nm (item_type_id)) = UPPER(p_item_typ_nm)
		AND REQUEST_STATUS = 'Approved'
		AND IS_PROCESSED != '1'
	ORDER BY
		pay_request_id DESC
	LIMIT 1 OFFSET 0;
	IF coalesce(v_request_id, - 1) > 0 THEN
		UPDATE
			pay.pay_loan_pymnt_rqsts
		SET
			date_processed = p_trns_date,
			last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
		WHERE
			pay_request_id = v_request_id;
	END IF;
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_ltst_rqst_intrst (p_prsn_id bigint, p_item_typ_nm character varying, p_trns_date character varying)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
	v_request_id bigint := - 1;
	v_itm_typ_id bigint := - 1;
BEGIN
	SELECT
		(mnthly_deduc * repay_period) - PRNCPL_AMOUNT INTO bid
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		RQSTD_FOR_PERSON_ID = p_prsn_id
		AND UPPER(pay.get_trans_typ_nm (item_type_id)) = UPPER(p_item_typ_nm)
		AND REQUEST_STATUS = 'Approved'
		AND IS_PROCESSED != '1'
	ORDER BY
		pay_request_id DESC
	LIMIT 1 OFFSET 0;
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_ltst_rqst_rpy_prd (p_prsn_id bigint, p_item_typ_nm character varying, p_trns_date character varying)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
	v_request_id bigint := - 1;
	v_itm_typ_id bigint := - 1;
BEGIN
	SELECT
		repay_period INTO bid
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		RQSTD_FOR_PERSON_ID = p_prsn_id
		AND UPPER(pay.get_trans_typ_nm (item_type_id)) = UPPER(p_item_typ_nm)
		AND REQUEST_STATUS = 'Approved'
		AND IS_PROCESSED != '1'
	ORDER BY
		pay_request_id DESC
	LIMIT 1 OFFSET 0;
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_tk_loan_end_dte (p_request_id bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid character varying(21) := '';
	v_rqst_date character varying(300) := '';
	v_clsfctn_date character varying(300) := '';
	v_clsfctn_Nm character varying(300) := '';
	v_crnt_yr character varying(4) := '';
	v_item_type_id bigint := - 1;
	v_item_nm character varying(200) := '';
	v_date_prcsd character varying(21) := '';
	v_repay_prd numeric := 0;
	v_nwSQL text := '';
BEGIN
	v_crnt_yr := to_char(now(), 'YYYY');
	SELECT
		a.last_update_date,
		a.local_clsfctn,
		a.item_type_id,
		e.item_type_name,
		a.date_processed,
		a.repay_period INTO v_rqst_date,
		v_clsfctn_Nm,
		v_item_type_id,
		v_item_nm,
		v_date_prcsd,
		v_repay_prd
	FROM
		pay.pay_loan_pymnt_rqsts a,
		pay.loan_pymnt_invstmnt_typs e
	WHERE
		a.item_type_id = e.item_type_id
		AND a.pay_request_id = p_request_id;
	IF v_item_nm ILIKE 'Semi%Month%' THEN
		v_nwSQL := 'Select to_char(to_timestamp(' || '''' || v_date_prcsd || '''' || ',''YYYY-MM-DD HH24:MI:SS'') + interval ''' || round(v_repay_prd / 2) || ' months'',''DD-Mon-YYYY'')';
		--RAISE NOTICE 'v_nwSQL: %', v_nwSQL;
		EXECUTE v_nwSQL INTO bid;
	ELSE
		SELECT
			substring(clsfctn_desc, 1, 6) INTO v_clsfctn_date
		FROM
			pay.loan_pymnt_typ_clsfctn
		WHERE
			clsfctn_name = v_clsfctn_Nm
			AND item_type_id = v_item_type_id;
		IF age(to_timestamp(v_clsfctn_date || '-' || v_crnt_yr || ' 00:00:00', 'DD-Mon-YYYY HH24:MI:SS'), to_timestamp(substring(v_rqst_date, 1, 10) || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS')) < interval '0 second' THEN
			v_crnt_yr := ((v_crnt_yr::integer) + 1) || '';
		END IF;
		bid := v_clsfctn_date || '-' || v_crnt_yr;
	END IF;
	RETURN coalesce(bid, '');
EXCEPTION
	WHEN OTHERS THEN
		RETURN '';
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trns_date_intrvl (p_request_id bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
	v_rqst_date character varying(300) := '';
	v_clsfctn_date character varying(300) := '';
	v_clsfctn_Nm character varying(300) := '';
	v_crnt_yr character varying(4) := '';
	v_item_type_id bigint := - 1;
BEGIN
	v_crnt_yr := to_char(now(), 'YYYY');
	SELECT
		last_update_date,
		local_clsfctn,
		item_type_id INTO v_rqst_date,
		v_clsfctn_Nm,
		v_item_type_id
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		pay_request_id = p_request_id;
	SELECT
		substring(clsfctn_desc, 1, 6) INTO v_clsfctn_date
	FROM
		pay.loan_pymnt_typ_clsfctn
	WHERE
		clsfctn_name = v_clsfctn_Nm
		AND item_type_id = v_item_type_id;
	IF age(to_timestamp(v_clsfctn_date || '-' || v_crnt_yr || ' 00:00:00', 'DD-Mon-YYYY HH24:MI:SS'), to_timestamp(substring(v_rqst_date, 1, 10) || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS')) < interval '0 second' THEN
		v_crnt_yr := ((v_crnt_yr::integer) + 1) || '';
	END IF;
	bid := round((EXTRACT('epoch' FROM (v_clsfctn_date || '-' || v_crnt_yr)::date - (to_char(to_timestamp(substring(v_rqst_date, 1, 10) || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY')::date - '0 seconds'::interval)) / 86400)::numeric, 2);
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trn_sttl_dte_intvl (p_request_id bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
	v_rqst_date character varying(300) := '';
	v_clsfctn_date character varying(300) := '';
	v_clsfctn_Nm character varying(300) := '';
	v_crnt_yr character varying(4) := '';
	v_item_type_id bigint := - 1;
	v_lnkd_loan_id bigint := - 1;
BEGIN
	v_crnt_yr := to_char(now(), 'YYYY');
	SELECT
		lnkd_loan_id INTO v_lnkd_loan_id
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		pay_request_id = p_request_id;
	SELECT
		last_update_date,
		local_clsfctn,
		item_type_id INTO v_rqst_date,
		v_clsfctn_Nm,
		v_item_type_id
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		pay_request_id = v_lnkd_loan_id;

	/*IF coalesce(v_lnkd_loan_id, - 1) <= 0 THEN
	 v_rqst_date := now() - '1 day'::interval
	 END IF;*/
	bid := round((EXTRACT('epoch' FROM (to_char(now(), 'DD-Mon-YYYY'))::date - (to_char(to_timestamp(substring(v_rqst_date, 1, 10) || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY')::date - '0 seconds'::interval)) / 86400)::numeric, 2);
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

--DROP FUNCTION pay.exct_itm_type_sql(character varying, bigint, bigint, integer, character varying);
CREATE OR REPLACE FUNCTION pay.exct_itm_type_sql (itemsql text, p_itm_typ_id bigint, p_request_id bigint, p_prsn_id bigint, p_org_id integer, p_datestr character varying)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0.00;
	nwSQL text := '';
BEGIN
	nwSQL := REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(itemSQL, '{:person_id}', '' || p_prsn_id), '{:org_id}', '' || p_org_id), '{:pay_date}', p_dateStr), '{:item_typ_id}', '' || p_itm_typ_id), '{:request_id}', '' || p_request_id);
	EXECUTE nwSQL INTO bid;
	RETURN round(COALESCE(bid, 0), 2);
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_lnkd_rqst_id (p_request_id bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
	v_lnkd_rqst_id bigint := - 1;
BEGIN
	SELECT
		lnkd_loan_id INTO v_lnkd_rqst_id
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		pay_request_id = p_request_id;
	RETURN coalesce(v_lnkd_rqst_id, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_lnkd_rqst_amnt (p_request_id bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
	v_lnkd_rqst_id bigint := - 1;
BEGIN
	SELECT
		lnkd_loan_id INTO v_lnkd_rqst_id
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		pay_request_id = p_request_id;
	SELECT
		PRNCPL_AMOUNT INTO bid
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		pay_request_id = v_lnkd_rqst_id;
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trns_rqst_amnt (p_request_id bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
BEGIN
	SELECT
		PRNCPL_AMOUNT INTO bid
	FROM
		pay.pay_loan_pymnt_rqsts
	WHERE
		pay_request_id = p_request_id;
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trans_repay_prd (p_trns_typ_id bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
BEGIN
	SELECT
		REPAY_PERIOD INTO bid
	FROM
		pay.loan_pymnt_invstmnt_typs
	WHERE
		item_type_id = p_trns_typ_id;
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trans_repay_typ (p_trns_typ_id bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid character varying(100) := '';
BEGIN
	SELECT
		repay_period_type INTO bid
	FROM
		pay.loan_pymnt_invstmnt_typs
	WHERE
		item_type_id = p_trns_typ_id;
	RETURN coalesce(bid, '');
EXCEPTION
	WHEN OTHERS THEN
		RETURN '';
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trntyp_enfrc_mx (p_trns_typ_id bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid character varying(1) := '';
BEGIN
	SELECT
		enforce_max_amnt INTO bid
	FROM
		pay.loan_pymnt_invstmnt_typs
	WHERE
		item_type_id = p_trns_typ_id;
	RETURN coalesce(bid, '0');
EXCEPTION
	WHEN OTHERS THEN
		RETURN '0';
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trans_type_rate (p_trns_typ_id bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0;
BEGIN
	SELECT
		INTRST_RATE INTO bid
	FROM
		pay.loan_pymnt_invstmnt_typs
	WHERE
		item_type_id = p_trns_typ_id;
	RETURN coalesce(bid, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trans_ratetype (p_trns_typ_id bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid character varying(100) := '';
BEGIN
	SELECT
		intrst_period_type INTO bid
	FROM
		pay.loan_pymnt_invstmnt_typs
	WHERE
		item_type_id = p_trns_typ_id;
	RETURN coalesce(bid, '');
EXCEPTION
	WHEN OTHERS THEN
		RETURN '';
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trntyp_net_sql (p_trns_typ_id bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid text := '';
BEGIN
	SELECT
		net_loan_amount_sql INTO bid
	FROM
		pay.loan_pymnt_invstmnt_typs
	WHERE
		item_type_id = p_trns_typ_id;
	RETURN coalesce(NULLIF (bid, ''), 'Select 0');
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'Select 0';
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trntyp_mx_sql (p_trns_typ_id bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid text := '';
BEGIN
	SELECT
		max_loan_amount_sql INTO bid
	FROM
		pay.loan_pymnt_invstmnt_typs
	WHERE
		item_type_id = p_trns_typ_id;
	RETURN coalesce(NULLIF (bid, ''), 'Select 0');
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'Select 0';
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trntyp_min_sql (p_trns_typ_id bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid text := '';
BEGIN
	SELECT
		min_loan_amount_sql INTO bid
	FROM
		pay.loan_pymnt_invstmnt_typs
	WHERE
		item_type_id = p_trns_typ_id;
	RETURN coalesce(NULLIF (bid, ''), 'Select 0');
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'Select 0';
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trans_typ_sql (p_trns_typ_id bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid text := '';
BEGIN
	SELECT
		perdic_deduc_frmlr INTO bid
	FROM
		pay.loan_pymnt_invstmnt_typs
	WHERE
		item_type_id = p_trns_typ_id;
	RETURN coalesce(NULLIF (bid, ''), 'Select 0');
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'Select 0';
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_trans_type (p_trns_typ_id bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid character varying(50) := '';
BEGIN
	SELECT
		item_type INTO bid
	FROM
		pay.loan_pymnt_invstmnt_typs
	WHERE
		item_type_id = p_trns_typ_id;
	RETURN coalesce(bid, '');
EXCEPTION
	WHEN OTHERS THEN
		RETURN '';
END;

$BODY$;

CREATE OR REPLACE FUNCTION public.last_date_of_month (p_date character varying)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid character varying(21) := '';
BEGIN
	SELECT
		to_char((date_trunc('MONTH', to_date(p_date, 'DD-Mon-YYYY')) + interval '1 MONTH - 1 day')::date, 'DD-Mon-YYYY') INTO bid;
	RETURN coalesce(bid, '');
EXCEPTION
	WHEN OTHERS THEN
		RETURN '';
END;

$BODY$;

CREATE OR REPLACE FUNCTION prs.get_xtra_prsn_data (p_col_num integer, p_person_id bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_data text := '';
	v_sql text := '';
BEGIN
	v_sql := 'SELECT coalesce(data_col' || p_col_num || ','''')
		    FROM prs.prsn_extra_data c
		    WHERE c.person_id = ' || p_person_id;
	EXECUTE v_sql INTO v_data;
	RETURN v_data;
EXCEPTION
	WHEN OTHERS THEN
		RETURN '';
END;

$BODY$;

CREATE OR REPLACE FUNCTION scm.generateitmaccntng (p_itmid bigint, p_qnty numeric, p_cnsgmntids character varying, p_txcodeid integer, p_dscntcodeid integer, p_chrgcodeid integer, p_doctyp character varying, p_docid bigint, p_srcdocid bigint, p_dfltrcvblacntid integer, p_dfltinvacntid integer, p_dfltcgsacntid integer, p_dfltexpnsacntid integer, p_dfltrvnuacntid integer, p_stckid bigint, p_unitsllgprc numeric, p_crncyid integer, p_doclnid bigint, p_dfltsracntid integer, p_dfltcashacntid integer, p_dfltcheckacntid integer, p_srcdoclnid bigint, p_datestr character varying, p_docidnum character varying, p_entrdcurrid integer, p_exchngrate numeric, p_dfltlbltyaccnt bigint, p_strsrcdoctype character varying, p_cstmrnm character varying, p_docdesc character varying, p_itmdesc character varying, p_storeid bigint, p_itmtype character varying, p_orgnlsllngprce numeric, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
	v_cstmrNm character varying(300) := '';
	v_docDesc character varying(300) := '';
	v_csngmtData text := '';
	v_csngmtDataArrys text[];
	v_ary text[];
	b_succs boolean := TRUE;
	v_funcCurrrate numeric := 0;
	v_ttlSllngPrc numeric := 0;
	v_ttlCstPrice numeric := 0;
	v_fig1Qty numeric := 0;
	v_fig2Prc numeric := 0;
	v_ttlRvnuAmnt numeric := 0;
	v_msgs text := '';
BEGIN
	v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
	v_cstmrNm := p_cstmrNm;
	v_docDesc := p_docDesc;
	IF (char_length(v_cstmrNm) <= 0) THEN
		v_cstmrNm := 'Unspecified Customer';
	END IF;
	IF (char_length(v_docDesc) <= 0) THEN
		v_docDesc := 'Unstated Purpose';
	END IF;
	b_succs := TRUE;

	/*For each Item in a Sales Invoice
	 * 1. Get Items Consgnmnt Cost Prices using all selected consignments and their used qtys
	 * 2. Decrease Inv Account by Cost Price --0Inventory
	 * 3. Increase Cost of Goods Sold by Cost Price --0Inventory
	 * 4. Get Selling Price, Taxes, Extra Charges, Discounts
	 * 5. Get Net Selling Price = (Selling Price - Taxes - Extra Charges + Discounts)*Qty
	 * 6. Increase Revenue Account by Net Selling Price --1Initial Amount
	 * 7. Increase Receivables account by Net Selling price --1Initial Amount
	 * 8. Increase Taxes Payable by Taxes  --2Tax
	 * 9. Increase Receivables account by Taxes --2Tax
	 * 10.Increase Extra Charges Revenue by Extra Charges --4Extra Charge
	 * 11.Increase Receivables account by Extra Charges --4Extra Charge
	 * 12.Increase Sales Discounts by Discounts --3Discount
	 * 13.Decrease Receivables by Discounts --3Discount
	 */
	v_msgs := 'p_itmDesc:' || p_itmDesc;
	v_funcCurrrate := round(1.00 / p_exchngRate, 15);
	v_ttlSllngPrc := round(p_qnty * p_unitSllgPrc, 2);
	--Get Net Selling Price = Selling Price - Taxes
	v_ttlRvnuAmnt := v_ttlSllngPrc;
	--For Sales Invoice, Sales Return, Item Issues-Unbilled Docs get the ff
	IF (p_dfltRcvblAcntID <= 0 OR p_dfltInvAcntID <= 0 OR p_dfltCGSAcntID <= 0 OR p_dfltExpnsAcntID <= 0 OR p_dfltRvnuAcntID <= 0) THEN
		RETURN 'ERROR: You must first Setup all Default Accounts before Accounting can be Created! ' || p_dfltRcvblAcntID || ',' || p_dfltInvAcntID || ',' || p_dfltCGSAcntID || ',' || p_dfltExpnsAcntID || ',' || p_dfltRvnuAcntID;
	END IF;
	IF (p_itmType ILIKE '%Inventory%' OR p_itmType ILIKE '%Fixed Assets%') THEN
		v_csngmtData := '';
		IF (p_docTyp != 'Sales Return') THEN
			v_csngmtData := inv.getItmCnsgmtVals1 (p_qnty, p_cnsgmntIDs);
		ELSE
			v_csngmtData := inv.getSRItmCnsgmtVals (p_docLnID, p_qnty, p_cnsgmntIDs, p_srcDocLnID);
		END IF;
		v_csngmtDataArrys := string_to_array(BTRIM(v_csngmtData, '|'), '|');
		--From the List get Total Cost Price of the Item
		v_ttlCstPrice := 0;
		v_msgs := 'v_csngmtData:' || coalesce(array_length(v_csngmtDataArrys, 1), 0) || ':p_qnty:' || p_qnty || ':p_cnsgmntIDs:' || p_cnsgmntIDs;
		FOR i IN 1..array_length(v_csngmtDataArrys, 1)
		LOOP
			v_ary := string_to_array(BTRIM(v_csngmtDataArrys[i], ';'), ';');
			v_fig1Qty := v_ary[2];
			v_fig2Prc := v_ary[3];
			v_ttlCstPrice := v_ttlCstPrice + (v_fig1Qty * v_fig2Prc);
		END LOOP;
		IF (p_dfltInvAcntID > 0 AND p_dfltCGSAcntID > 0 AND p_docTyp = 'Sales Invoice') THEN
			b_succs := scm.sendToGLInterfaceMnl (p_dfltInvAcntID, 'D', v_ttlCstPrice, p_dateStr, 'Sale of ' || p_itmDesc || ' to ' || v_cstmrNm || ' (' || v_docDesc || ')', p_crncyID, v_dateStr, p_docTyp, p_docID, p_docLnID, p_who_rn);
			IF (b_succs = FALSE) THEN
				RETURN 'ERROR:';
			END IF;
			b_succs := scm.sendToGLInterfaceMnl (p_dfltCGSAcntID, 'I', v_ttlCstPrice, p_dateStr, 'Sale of ' || p_itmDesc || ' to ' || v_cstmrNm || ' (' || v_docDesc || ')', p_crncyID, v_dateStr, p_docTyp, p_docID, p_docLnID, p_who_rn);
			IF (b_succs = FALSE) THEN
				RETURN 'ERROR:';
			END IF;
		ELSIF (p_dfltInvAcntID > 0
				AND p_dfltCGSAcntID > 0
				AND p_docTyp = 'Sales Return'
				AND p_strSrcDocType = 'Sales Invoice') THEN
			b_succs := scm.sendToGLInterfaceMnl (p_dfltInvAcntID, 'I', v_ttlCstPrice, p_dateStr, 'Return of Sold ' || p_itmDesc || ' to ' || v_cstmrNm || ' (' || v_docDesc || ')', p_crncyID, v_dateStr, p_docTyp, p_docID, p_docLnID, p_who_rn);
			IF (b_succs = FALSE) THEN
				RETURN 'ERROR:';
			END IF;
			b_succs := scm.sendToGLInterfaceMnl (p_dfltCGSAcntID, 'D', v_ttlCstPrice, p_dateStr, 'Return of Sold ' || p_itmDesc || ' to ' || v_cstmrNm || ' (' || v_docDesc || ')', p_crncyID, v_dateStr, p_docTyp, p_docID, p_docLnID, p_who_rn);
			IF (b_succs = FALSE) THEN
				RETURN 'ERROR:';
			END IF;
		ELSIF (p_docTyp = 'Item Issue-Unbilled') THEN
			IF (p_dfltInvAcntID > 0 AND p_dfltExpnsAcntID > 0) THEN
				b_succs := scm.sendToGLInterfaceMnl (p_dfltInvAcntID, 'D', v_ttlCstPrice, p_dateStr, 'Issue Out of ' || p_itmDesc || ' to ' || v_cstmrNm || ' (' || v_docDesc || ')', p_crncyID, v_dateStr, p_docTyp, p_docID, p_docLnID, p_who_rn);
				IF (b_succs = FALSE) THEN
					RETURN 'ERROR:';
				END IF;
				b_succs := scm.sendToGLInterfaceMnl (p_dfltExpnsAcntID, 'I', v_ttlCstPrice, p_dateStr, 'Issue Out of ' || p_itmDesc || ' to ' || v_cstmrNm || ' (' || v_docDesc || ')', p_crncyID, v_dateStr, p_docTyp, p_docID, p_docLnID, p_who_rn);
				IF (b_succs = FALSE) THEN
					RETURN 'ERROR:';
				END IF;
			END IF;
		ELSIF (p_docTyp = 'Sales Return'
				AND p_strSrcDocType = 'Item Issue-Unbilled') THEN
			IF (p_dfltInvAcntID > 0 AND p_dfltExpnsAcntID > 0) THEN
				b_succs := scm.sendToGLInterfaceMnl (p_dfltInvAcntID, 'I', v_ttlCstPrice, p_dateStr, 'Return of ' || p_itmDesc || ' Issued Out to ' || v_cstmrNm || ' (' || v_docDesc || ')', p_crncyID, v_dateStr, p_docTyp, p_docID, p_docLnID, p_who_rn);
				IF (b_succs = FALSE) THEN
					RETURN 'ERROR:';
				END IF;
				b_succs := scm.sendToGLInterfaceMnl (p_dfltExpnsAcntID, 'D', v_ttlCstPrice, p_dateStr, 'Return of ' || p_itmDesc || ' Issued Out to ' || v_cstmrNm || ' (' || v_docDesc || ')', p_crncyID, v_dateStr, p_docTyp, p_docID, p_docLnID, p_who_rn);
				IF (b_succs = FALSE) THEN
					RETURN 'ERROR:';
				END IF;
			END IF;
		END IF;
	END IF;
	RETURN 'SUCCESS:';
END;
$BODY$;

CREATE OR REPLACE FUNCTION scm.approve_sales_prchsdoc (p_dochdrid bigint, p_dockind character varying, p_orgid integer, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	rd1 RECORD;
	rd2 RECORD;
	rd3 RECORD;
	msgs text := 'ERROR:';
	v_reslt_1 text := '';
	v_docNum character varying(100) := '';
	v_funcCurrID integer := - 1;
	v_dfltRcvblAcntID integer := - 1;
	v_dfltBadDbtAcntID integer := - 1;
	v_dfltLbltyAccnt integer := - 1;
	v_parAcctInvAcrlID integer := - 1;
	v_dfltInvAcntID integer := - 1;
	v_dfltCGSAcntID integer := - 1;
	v_dfltExpnsAcntID integer := - 1;
	v_dfltRvnuAcntID integer := - 1;
	v_dfltSRAcntID integer := - 1;
	v_dfltCashAcntID integer := - 1;
	v_dfltCheckAcntID integer := - 1;
	v_orgid integer := - 1;
	v_clientID bigint := - 1;
	v_clientSiteID bigint := - 1;
	v_docDte character varying(21) := '';
	v_DocType character varying(200) := '';
	v_srcDocType character varying(200) := '';
	v_apprvlStatus character varying(100) := '';
	v_entrdCurrID integer := - 1;
	v_pymntMthdID integer := - 1;
	v_invcAmnt numeric := 0;
	v_itmID bigint := - 1;
	v_storeID bigint := - 1;
	v_lnID bigint := - 1;
	v_curid integer := - 1;
	v_stckID bigint := - 1;
	v_cnsgmntIDs character varying(4000) := '';
	v_isPrevdlvrd character varying(1) := '0';
	v_slctdAccntIDs character varying(4000) := '';
	v_AcntArrys text[];
	v_itmInvAcntID integer := - 1;
	v_cogsID integer := - 1;
	v_salesRevID integer := - 1;
	v_salesRetID integer := - 1;
	v_purcRetID integer := - 1;
	v_expnsID integer := - 1;
	v_itmInvAcntID1 integer := - 1;
	v_cogsID1 integer := - 1;
	v_salesRevID1 integer := - 1;
	v_salesRetID1 integer := - 1;
	v_purcRetID1 integer := - 1;
	v_expnsID1 integer := - 1;
	v_srclnID bigint := - 1;
	v_qty numeric := 0;
	v_price numeric := 0;
	v_lineid bigint := - 1;
	v_taxID integer := - 1;
	v_dscntID integer := - 1;
	v_chrgeID integer := - 1;
	v_orgnlSllngPrce numeric := 0;
	v_rcvblHdrID bigint := - 1;
	v_rcvblDocNum character varying(200) := '';
	v_exchRate numeric := 1;
	v_srcDocID bigint := - 1;
	v_dateStr character varying(21) := '';
	v_cstmrNm character varying(200) := '';
	v_docDesc character varying(300) := '';
	v_itmDesc character varying(200) := '';
	v_itmType character varying(200) := '';
	v_PrsnID bigint := - 1;
	v_BranchID integer := - 1;
	v_PrsnBrnchID integer := - 1;
BEGIN
	/* 1. Update Item Balances
	 * 2. checkNCreateSalesRcvblsHdr
	 */
	v_PrsnID := sec.get_usr_prsn_id (p_who_rn);
	v_PrsnBrnchID := pasn.get_prsn_siteid (v_PrsnID);
	v_orgid := p_orgid;
	IF p_DocKind = 'Sales' THEN
		FOR rd2 IN (
			SELECT
				to_char(to_timestamp(invc_date || ' 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') invc_date,
				invc_number,
				invc_type,
				comments_desc,
				src_doc_hdr_id,
				customer_id,
				scm.get_cstmr_splr_name (a.customer_id) cstmr_splr_name,
				customer_site_id,
				approval_status,
				next_aproval_action,
				org_id,
				receivables_accnt_id,
				src_doc_type,
				pymny_method_id,
				invc_curr_id,
				exchng_rate,
				other_mdls_doc_id,
				other_mdls_doc_type,
				event_rgstr_id,
				evnt_cost_category,
				allow_dues,
				event_doc_type,
				round(scm.get_DocSmryGrndTtl (a.invc_hdr_id, a.invc_type), 2) invoice_amount,
				branch_id
			FROM
				scm.scm_sales_invc_hdr a
			WHERE
				a.invc_hdr_id = p_dochdrid)
			LOOP
				v_clientID := rd2.customer_id;
				v_clientSiteID := rd2.customer_site_id;
				v_docDte := rd2.invc_date;
				v_DocType := rd2.invc_type;
				v_srcDocType := rd2.src_doc_type;
				v_apprvlStatus := rd2.approval_status;
				v_entrdCurrID := rd2.invc_curr_id;
				v_pymntMthdID := rd2.pymny_method_id;
				v_invcAmnt := rd2.invoice_amount;
				v_orgid := rd2.org_id;
				v_exchRate := rd2.exchng_rate;
				v_srcDocID := rd2.src_doc_hdr_id;
				v_dateStr := rd2.invc_date;
				v_cstmrNm := rd2.cstmr_splr_name;
				v_docDesc := substring(rd2.comments_desc, 1, 299);
				IF rd2.branch_id > 0 THEN
					v_PrsnBrnchID := rd2.branch_id;
				END IF;
			END LOOP;
		v_reslt_1 := scm.reCalcSmmrys (p_dochdrid, v_DocType, v_clientID, v_entrdCurrID, v_apprvlStatus, v_orgid, p_who_rn);
		IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
		END IF;
		v_funcCurrID := org.get_orgfunc_crncy_id (v_orgid);
		IF v_exchRate = 0 THEN
			v_exchRate := round(accb.get_ltst_exchrate (v_entrdCurrID, v_funcCurrID, v_dateStr, v_orgid), 15);
		END IF;
		FOR rd3 IN (
			SELECT
				itm_inv_asst_acnt_id,
				cost_of_goods_acnt_id,
				expense_acnt_id,
				prchs_rtrns_acnt_id,
				rvnu_acnt_id,
				sales_rtrns_acnt_id,
				sales_cash_acnt_id,
				sales_check_acnt_id,
				sales_rcvbl_acnt_id,
				rcpt_cash_acnt_id,
				rcpt_lblty_acnt_id,
				inv_adjstmnts_lblty_acnt_id,
				sales_dscnt_accnt,
				prchs_dscnt_accnt,
				sales_lblty_acnt_id,
				bad_debt_acnt_id,
				rcpt_rcvbl_acnt_id,
				petty_cash_acnt_id
			FROM
				scm.scm_dflt_accnts
			WHERE
				org_id = v_orgid)
			LOOP
				v_dfltRcvblAcntID := rd3.sales_rcvbl_acnt_id;
				v_dfltBadDbtAcntID := rd3.bad_debt_acnt_id;
				v_dfltLbltyAccnt := rd3.rcpt_lblty_acnt_id;
				v_parAcctInvAcrlID := rd3.inv_adjstmnts_lblty_acnt_id;
				v_dfltInvAcntID := rd3.itm_inv_asst_acnt_id;
				v_dfltCGSAcntID := rd3.cost_of_goods_acnt_id;
				v_dfltExpnsAcntID := rd3.expense_acnt_id;
				v_dfltRvnuAcntID := rd3.rvnu_acnt_id;
				v_dfltSRAcntID := rd3.sales_rtrns_acnt_id;
				v_dfltCashAcntID := rd3.sales_cash_acnt_id;
				v_dfltCheckAcntID := rd3.sales_check_acnt_id;
			END LOOP;
		IF (v_apprvlStatus = 'Not Validated') THEN
			v_reslt_1 := scm.validateLns (p_dochdrid, v_DocType);
			IF (v_reslt_1 LIKE 'SUCCESS:%') THEN
				FOR rd1 IN (
					SELECT
						a.invc_det_ln_id,
						a.itm_id,
						a.doc_qty,
						a.unit_selling_price,
						(a.doc_qty * a.unit_selling_price * a.rented_itm_qty) amnt,
						a.store_id,
						a.crncy_id,
						(a.doc_qty - a.qty_trnsctd_in_dest_doc) avlbl_qty,
						a.src_line_id,
						a.tax_code_id,
						a.dscnt_code_id,
						a.chrg_code_id,
						a.rtrn_reason,
						a.consgmnt_ids,
						a.orgnl_selling_price,
						b.base_uom_id,
						b.item_code,
						b.item_desc,
						c.uom_name,
						a.is_itm_delivered,
						REPLACE(a.extra_desc || ' (' || a.other_mdls_doc_type || ')', ' ()', ''),
						a.other_mdls_doc_id,
						a.other_mdls_doc_type,
						a.lnkd_person_id,
						REPLACE(prs.get_prsn_surname (a.lnkd_person_id) || ' (' || prs.get_prsn_loc_id (a.lnkd_person_id) || ')', ' ()', '') fullnm,
						CASE WHEN a.alternate_item_name = '' THEN
							b.item_desc
						ELSE
							a.alternate_item_name
						END item_desc_ext,
						d.cat_name,
						REPLACE(a.cogs_acct_id || ',' || a.sales_rev_accnt_id || ',' || a.sales_ret_accnt_id || ',' || a.purch_ret_accnt_id || ',' || a.expense_accnt_id || ',' || a.inv_asset_acct_id, '-1,-1,-1,-1,-1,-1', b.cogs_acct_id || ',' || b.sales_rev_accnt_id || ',' || b.sales_ret_accnt_id || ',' || b.purch_ret_accnt_id || ',' || b.expense_accnt_id || ',' || b.inv_asset_acct_id) itm_accnts,
						b.item_type
					FROM
						scm.scm_sales_invc_det a,
						inv.inv_itm_list b,
						inv.unit_of_measure c,
						inv.inv_product_categories d
					WHERE (a.invc_hdr_id = p_dochdrid
						AND a.invc_hdr_id > 0
						AND a.itm_id = b.item_id
						AND b.base_uom_id = c.uom_id
						AND d.cat_id = b.category_id)
				ORDER BY
					a.invc_det_ln_id)
				LOOP
					v_itmID := rd1.itm_id;
					v_storeID := rd1.store_id;
					v_BranchID := coalesce(inv.get_store_brnch_id (v_storeID), - 1);
					IF v_BranchID <= 0 AND v_PrsnBrnchID > 0 THEN
						v_BranchID := v_PrsnBrnchID;
					END IF;
					v_lnID := rd1.invc_det_ln_id;
					v_curid := rd1.crncy_id;
					v_itmDesc := rd1.item_desc_ext;
					v_itmType := rd1.item_type;
					v_stckID := inv.getItemStockID (v_itmID, v_storeID);
					v_isPrevdlvrd := rd1.is_itm_delivered;
					v_slctdAccntIDs := BTRIM(rd1.itm_accnts, ',');
					v_AcntArrys := string_to_array(v_slctdAccntIDs, ',');
					v_itmInvAcntID1 := - 1;
					v_cogsID1 := - 1;
					v_salesRevID1 := - 1;
					v_salesRetID1 := - 1;
					v_purcRetID1 := - 1;
					v_expnsID1 := - 1;
					FOR z IN 1..array_length(v_AcntArrys, 1)
					LOOP
						IF z = 1 THEN
							v_cogsID1 := v_AcntArrys[z];
						ELSIF z = 2 THEN
							v_salesRevID1 := v_AcntArrys[z];
						ELSIF z = 3 THEN
							v_salesRetID1 := v_AcntArrys[z];
						ELSIF z = 4 THEN
							v_purcRetID1 := v_AcntArrys[z];
						ELSIF z = 5 THEN
							v_expnsID1 := v_AcntArrys[z];
						ELSE
							v_itmInvAcntID1 := v_AcntArrys[z];
						END IF;
					END LOOP;
					IF (v_itmInvAcntID1 <= 0) THEN
						v_itmInvAcntID1 := v_dfltInvAcntID;
					END IF;
					IF (v_cogsID1 <= 0) THEN
						v_cogsID1 := v_dfltCGSAcntID;
					END IF;
					IF (v_salesRevID1 <= 0) THEN
						v_salesRevID1 := v_dfltRvnuAcntID;
					END IF;
					IF (v_salesRetID1 <= 0) THEN
						v_salesRetID1 := v_dfltSRAcntID;
					END IF;
					IF (v_expnsID1 <= 0) THEN
						v_expnsID1 := v_dfltExpnsAcntID;
					END IF;
					v_itmInvAcntID := org.get_accnt_id_brnch_eqv (v_BranchID, v_itmInvAcntID1);
					v_cogsID := org.get_accnt_id_brnch_eqv (v_BranchID, v_cogsID1);
					v_salesRevID := org.get_accnt_id_brnch_eqv (v_BranchID, v_salesRevID1);
					v_salesRetID := org.get_accnt_id_brnch_eqv (v_BranchID, v_salesRetID1);
					v_expnsID := org.get_accnt_id_brnch_eqv (v_BranchID, v_expnsID1);
					v_purcRetID := org.get_accnt_id_brnch_eqv (v_BranchID, v_purcRetID1);
					v_srclnID := rd1.src_line_id;
					v_qty := rd1.doc_qty;
					v_price := rd1.unit_selling_price;
					v_lineid := rd1.invc_det_ln_id;
					v_taxID := rd1.tax_code_id;
					v_dscntID := rd1.dscnt_code_id;
					v_chrgeID := rd1.chrg_code_id;
					-- inv.getUOMPriceLsTx(v_itmID, v_qty)
					v_orgnlSllngPrce := round(v_exchRate * rd1.orgnl_selling_price, 5);
					v_stckID := inv.getItemStockID (v_itmID, v_storeID);
					v_cnsgmntIDs := rd1.consgmnt_ids;
					v_reslt_1 := 'SUCCESS:';
					msgs := 'item_desc:' || rd1.item_desc || '::' || v_cnsgmntIDs || '::Cnt::' || array_length(v_AcntArrys, 1);
					IF v_itmID > 0 AND v_DocType NOT IN ('Pro-Forma Invoice', 'Internal Item Request', 'Sales Order') THEN
						v_reslt_1 := scm.generateItmAccntng (v_itmID, v_qty, v_cnsgmntIDs, v_taxID, v_dscntID, v_chrgeID, v_doctype, p_dochdrid, v_srcDocID, v_dfltRcvblAcntID, v_itmInvAcntID, v_cogsID, v_expnsID, v_salesRevID, v_stckID, v_price, v_funcCurrID, v_lineid, v_salesRetID, v_dfltCashAcntID, v_dfltCheckAcntID, v_srclnID, v_dateStr, v_docNum, v_entrdCurrID, v_exchRate, v_dfltLbltyAccnt, v_srcDocType, v_cstmrNm, v_docDesc, v_itmDesc, v_storeID, v_itmType, v_orgnlSllngPrce, p_who_rn);
						IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
							RAISE EXCEPTION
								USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
							RETURN msgs;
						END IF;
					END IF;
					IF (v_itmID > 0 AND v_storeID > 0 AND v_isPrevdlvrd = '0' AND v_DocType NOT IN ('Pro-Forma Invoice', 'Internal Item Request')) THEN
						v_reslt_1 := inv.udateItemBalances (v_itmID, v_qty, v_cnsgmntIDs, v_taxID, v_dscntID, v_chrgeID, v_doctype, p_dochdrid, v_srcDocID, v_dfltRcvblAcntID, v_dfltInvAcntID, v_dfltCGSAcntID, v_dfltExpnsAcntID, v_dfltRvnuAcntID, v_stckID, v_price, v_curid, v_lineid, v_dfltSRAcntID, v_dfltCashAcntID, v_dfltCheckAcntID, v_srclnID, v_dateStr, v_docNum, v_entrdCurrID, v_exchRate, v_dfltLbltyAccnt, v_srcDocType, p_who_rn);
						IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
							RAISE EXCEPTION
								USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
							RETURN msgs;
						END IF;
						v_reslt_1 := scm.updateSalesLnDlvrd (v_lineid, '1');
					ELSIF (v_isPrevdlvrd = '0'
							AND v_lineid > 0
							AND v_DocType NOT IN ('Pro-Forma Invoice', 'Internal Item Request')) THEN
						v_reslt_1 := scm.updateSalesLnDlvrd (v_lineid, '1');
					END IF;
					IF v_reslt_1 LIKE 'SUCCESS:%' THEN
						IF (rd1.src_line_id > 0) THEN
							v_reslt_1 := scm.updtSrcDocTrnsctdQty (rd1.src_line_id, rd1.doc_qty, p_who_rn);
							IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
								RAISE EXCEPTION
									USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
							END IF;
						END IF;
					END IF;
				END LOOP;
				IF v_DocType IN ('Sales Invoice', 'Sales Return') THEN
					v_rcvblHdrID := accb.checkNCreateSalesRcvblsHdr (v_orgid, v_clientID, v_clientSiteID, v_docDte, v_DocType, v_entrdCurrID, v_invcAmnt, v_pymntMthdID, v_funcCurrID, p_dochdrid, p_who_rn);
					--v_rcvblHdrID := accb.get_ScmRcvblsDocHdrID(p_dochdrid, v_DocType, v_orgid);
					--v_rcvblHdrID := 1 / 0;
					v_rcvblDocNum := gst.getGnrlRecNm ('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'rcvbls_invc_number', v_rcvblHdrID);
					v_reslt_1 := accb.approve_pyblrcvbldoc (v_rcvblHdrID, v_rcvblDocNum, 'Receivables', v_orgid, p_who_rn);
					IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
						RAISE EXCEPTION
							USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
					END IF;
				END IF;
			ELSE
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
			END IF;
		END IF;
	ELSIF p_DocKind = 'Purchase' THEN
		FOR rd2 IN (
			SELECT
				to_char(to_timestamp(prchs_doc_date || ' 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') invc_date,
				purchase_doc_num,
				purchase_doc_type,
				comments_desc,
				requisition_id src_doc_hdr_id,
				supplier_id,
				scm.get_cstmr_splr_name (a.supplier_id) cstmr_splr_name,
				supplier_site_id,
				approval_status,
				next_aproval_action,
				org_id,
				payables_accnt_id,
				CASE WHEN requisition_id > 0 THEN
					'Purchase Requisition'
				ELSE
					''
				END src_doc_type,
				prntd_doc_curr_id invc_curr_id,
				exchng_rate,
				branch_id
			FROM
				scm.scm_prchs_docs_hdr a
			WHERE
				a.prchs_doc_hdr_id = p_dochdrid)
			LOOP
				v_clientID := rd2.supplier_id;
				v_clientSiteID := rd2.supplier_site_id;
				v_docDte := rd2.invc_date;
				v_DocType := rd2.purchase_doc_type;
				v_srcDocType := rd2.src_doc_type;
				v_apprvlStatus := rd2.approval_status;
				v_entrdCurrID := rd2.invc_curr_id;
				v_orgid := rd2.org_id;
				v_exchRate := rd2.exchng_rate;
				v_srcDocID := rd2.src_doc_hdr_id;
				v_dateStr := rd2.invc_date;
				v_cstmrNm := rd2.cstmr_splr_name;
				v_docDesc := substring(rd2.comments_desc, 1, 299);
				IF rd2.branch_id > 0 THEN
					v_PrsnBrnchID := rd2.branch_id;
				END IF;
			END LOOP;
		v_reslt_1 := scm.reCalcPrchsDocSmmrys (p_dochdrid, v_DocType, v_clientID, v_entrdCurrID, v_apprvlStatus, v_orgid, p_who_rn);
		IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
		END IF;
		v_funcCurrID := org.get_orgfunc_crncy_id (v_orgid);
		v_reslt_1 := 'SUCCESS:';
		IF (v_apprvlStatus = 'Not Validated') THEN
			IF v_DocType IN ('Purchase Order') AND v_srcDocID > 0 THEN
				FOR rd1 IN (
					SELECT
						prchs_doc_line_id,
						itm_id,
						quantity,
						unit_price,
						created_by,
						creation_date,
						last_update_by,
						last_update_date,
						store_id,
						crncy_id,
						qty_rcvd,
						rqstd_qty_ordrd,
						src_line_id,
						dsply_doc_line_in_rcpt,
						alternate_item_name,
						tax_code_id,
						dscnt_code_id,
						extr_chrg_id
					FROM
						scm.scm_prchs_docs_det
					WHERE
						prchs_doc_hdr_id = p_dochdrid
					ORDER BY
						prchs_doc_line_id)
					LOOP
						v_reslt_1 := scm.updtprchsreqOrdrdqty (rd1.src_line_id, rd1.quantity, p_who_rn);
						IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
							RAISE EXCEPTION
								USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
						END IF;
					END LOOP;
			END IF;
		END IF;
	END IF;
	IF v_reslt_1 LIKE 'SUCCESS:%' THEN
		IF p_DocKind = 'Sales' THEN
			v_reslt_1 := scm.updtSalesDocApprvl (p_dochdrid, 'Approved', 'Cancel', p_who_rn);
		ELSIF p_DocKind = 'Purchase' THEN
			v_reslt_1 := scm.updtprchsdocapprvl (p_dochdrid, 'Approved', 'Cancel', p_who_rn);
		END IF;
	END IF;
	RETURN 'SUCCESS: Item Transaction DOCUMENT Finalized!';
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

