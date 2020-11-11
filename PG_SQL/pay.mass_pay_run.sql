CREATE OR REPLACE FUNCTION pay.get_ltst_paiditem_val_b4 (p_personid bigint, p_pay_itm_id bigint, p_trns_date character varying)
	RETURNS numeric
	LANGUAGE 'sql'
	COST 100 VOLATILE
	AS $BODY$
	SELECT
		COALESCE(a.amount_paid, 0)
	FROM
		pay.pay_itm_trnsctns a
	WHERE
		a.person_id = p_personid
		AND a.item_id = p_pay_itm_id
		AND substring(a.paymnt_date, 1, 10) <= substring(p_trns_date, 1, 10)
		AND (a.pymnt_vldty_status = 'VALID'
			AND a.src_py_trns_id < 0)
	ORDER BY
		a.paymnt_date DESC
	LIMIT 1 OFFSET 0
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_ltst_paiditem_val_afta (p_personid bigint, p_pay_itm_id bigint, p_trns_date character varying)
	RETURNS numeric
	LANGUAGE 'sql'
	COST 100 VOLATILE
	AS $BODY$
	SELECT
		COALESCE(a.amount_paid, 0)
	FROM
		pay.pay_itm_trnsctns a
	WHERE
		a.person_id = p_personid
		AND a.item_id = p_pay_itm_id
		AND substring(a.paymnt_date, 1, 10) >= substring(p_trns_date, 1, 10)
		AND (a.pymnt_vldty_status = 'VALID'
			AND a.src_py_trns_id < 0)
	ORDER BY
		a.paymnt_date DESC
	LIMIT 1 OFFSET 0
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_ltst_paiditem_dte (p_personid bigint, p_pay_itm_id bigint)
	RETURNS character varying
	LANGUAGE 'sql'
	COST 100 VOLATILE
	AS $BODY$
	SELECT
		COALESCE(substring(a.paymnt_date, 1, 10), '')
	FROM
		pay.pay_itm_trnsctns a
	WHERE
		a.person_id = p_personid
		AND a.item_id = p_pay_itm_id
		AND (a.pymnt_vldty_status = 'VALID'
			AND a.src_py_trns_id < 0)
	ORDER BY
		a.paymnt_date DESC
	LIMIT 1 OFFSET 0
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_mass_py_name (p_mass_py_id bigint)
	RETURNS character varying
	LANGUAGE 'sql'
	COST 100 VOLATILE
	AS $BODY$
	SELECT
		mass_pay_name
	FROM
		pay.pay_mass_pay_run_hdr
	WHERE
		mass_pay_id = p_mass_py_id;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_mass_py_desc (p_mass_py_id bigint)
	RETURNS character varying
	LANGUAGE 'sql'
	COST 100 VOLATILE
	AS $BODY$
	SELECT
		mass_pay_desc
	FROM
		pay.pay_mass_pay_run_hdr
	WHERE
		mass_pay_id = p_mass_py_id;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_payment_summrys2 (orgid integer, p_mass_py_id bigint, ordrbycls character varying)
	RETURNS TABLE (
		person_id bigint,
		local_id_no character varying,
		fullname text,
		total_earnings numeric,
		total_employer_charges numeric,
		total_bills_charges numeric,
		total_deductions numeric,
		total_purely_informational numeric)
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE ROWS 1000
	AS $BODY$
DECLARE
	whereclause text;
	fullsql text;
	records RECORD;
	exeQuery text;
BEGIN
	fullsql := 'SELECT tbl1.person_id,
tbl1.local_id_no,
tbl1.fullname,
tbl1.total_earnings,
tbl1.total_employer_charges,
tbl1.total_bills_charges,
tbl1.total_deductions,
tbl1.total_purely_informational
 FROM (SELECT DISTINCT a.person_id, c.local_id_no,
trim(c.title || '' '' || c.sur_name || '', '' || c.first_name || '' '' || c.other_names) fullname,
COALESCE(SUM((Select a.amount_paid FROM org.org_pay_items b WHERE a.item_id = b.item_id and b.item_min_type=''Earnings'')),0) total_earnings,
COALESCE(SUM((Select a.amount_paid FROM org.org_pay_items b WHERE a.item_id = b.item_id and b.item_min_type=''Employer Charges'')),0) total_employer_charges,
COALESCE(SUM((Select a.amount_paid FROM org.org_pay_items b WHERE a.item_id = b.item_id and b.item_min_type IN (''Bills/Charges''))),0) total_bills_charges,
COALESCE(SUM((Select a.amount_paid FROM org.org_pay_items b WHERE a.item_id = b.item_id and b.item_min_type IN (''Deductions''))),0) total_deductions,
COALESCE(SUM((Select a.amount_paid FROM org.org_pay_items b WHERE a.item_id = b.item_id and b.item_min_type IN (''Purely Informational''))),0) total_purely_informational,
to_char(to_timestamp(a.paymnt_date,''YYYY-MM-DD HH24:MI:SS''),''DD-Mon-YYYY'') payment_date
FROM pay.pay_itm_trnsctns a
LEFT OUTER JOIN prs.prsn_names_nos c on a.person_id = c.person_id
WHERE(a.pymnt_vldty_status =''VALID'' and a.mass_pay_id = ' || p_mass_py_id || ')
GROUP BY a.person_id, c.local_id_no,c.title,c.sur_name,c.first_name,c.other_names,a.paymnt_date) tbl1
ORDER BY ' || $3;
	--RAISE NOTICE 'FULL Query = "%"', fullsql;
	exeQuery := '' || fullsql || '';
	RETURN QUERY EXECUTE exeQuery;
END
$BODY$;

CREATE OR REPLACE FUNCTION pay.exct_itm_valsql (itemsql character varying, p_prsn_id bigint, p_org_id integer, p_datestr character varying)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	bid numeric := 0.00;
	nwSQL text := '';
BEGIN
	nwSQL := REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(itemSQL, '{:person_id}', '' || p_prsn_id), '{:org_id}', '' || p_org_id), '{:pay_date}', p_dateStr), '{:item_typ_id}', '-1'), '{:request_id}', '-1');
	--RAISE NOTICE 'Query SQL = "%"', nwSQL;
	--RAISE NOTICE 'Query itemSQL = "%"', itemSQL;
	EXECUTE nwSQL INTO bid;
	RETURN round(COALESCE(bid, 0), 2);
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.getBatchItmTypCnt (p_pyReqID bigint, p_mspyid bigint, p_prsnID bigint)
	RETURNS integer
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	vRes integer := 0;
BEGIN
	SELECT
		count(tbl1.mintyp) INTO vRes
	FROM ( SELECT DISTINCT
			org.get_payitm_mintyp (a.item_id) mintyp
		FROM
			pay.pay_itm_trnsctns a
		WHERE (a.mass_pay_id = p_mspyid
			AND ((a.person_id = p_prsnID
					AND p_prsnID > 0)
				OR p_prsnID <= 0))
	UNION
	SELECT DISTINCT
		org.get_payitm_mintyp (a.pay_item_id) mintyp
	FROM
		self.self_prsn_intrnl_pymnts a
	WHERE (a.pymnt_req_hdr_id = p_pyReqID
		AND ((a.payer_person_id = p_prsnID
				AND p_prsnID > 0)
			OR p_prsnID <= 0)
		AND a.mass_pay_hdr_id <= 0)) tbl1;
	RETURN COALESCE(vRes, 0);
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.getBatchItmTypCnt1 (p_mspyid bigint)
	RETURNS integer
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	vRes integer := 0;
BEGIN
	SELECT
		count(DISTINCT org.get_payitm_mintyp (a.item_id)) INTO vRes
	FROM
		pay.pay_value_sets_det a
	WHERE (a.mass_pay_id = p_mspyid);
	RETURN COALESCE(vRes, 0);
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.getBatchNetAmnt (p_itmTypCnt integer, p_itmTyp character varying, p_itmNm character varying, p_effctOnOrgDbt character varying, p_amnt numeric, p_inbrghtTotal numeric, p_inp_AmntDffrnc numeric, OUT p_prpsdTtlSpnColor character varying, OUT p_brghtTotal numeric, OUT p_fnlColorAmntDffrnc numeric, OUT p_finalTxt character varying)
	RETURNS RECORD
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_spnColor character varying(100) := '';
	v_mltplr character varying(100) := '';
BEGIN
	/* Items Net Effect on Person's Organisational Debt
	 * if(same itemtype in batch then + throughout)
	 * Dues/Bills/Charges - (red) - increase
	 * Dues/Bills/Charges Payments - (green) - decrease
	 *
	 * Earnings - (green) - decrease
	 * Payroll Deductions - (red) - increase
	 * Payroll Staff Liability Balance - green - decrease
	 * Employer Charges (None) (black)
	 * Purely Informational (None) (black)
	 * */
	p_fnlColorAmntDffrnc := 0;
	v_spnColor := 'black';
	v_mltplr := '+';
	IF (p_effctOnOrgDbt = 'Increase') THEN
		v_spnColor := 'red';
		p_fnlColorAmntDffrnc := p_inp_AmntDffrnc - p_amnt;
		IF (p_itmTyp = 'Bills/Charges') THEN
			v_spnColor := 'red';
			p_brghtTotal := p_inbrghtTotal + p_amnt;
		ELSE
			IF (p_itmTypCnt > 1 OR p_itmTyp = 'Balance Item') THEN
				v_mltplr := '-';
				p_brghtTotal := p_inbrghtTotal - p_amnt;
			ELSE
				p_brghtTotal := p_inbrghtTotal + p_amnt;
			END IF;
		END IF;
	ELSIF (p_effctOnOrgDbt = 'Decrease') THEN
		v_spnColor := 'green';
		p_fnlColorAmntDffrnc := p_inp_AmntDffrnc + p_amnt;
		p_brghtTotal := p_inbrghtTotal + p_amnt;
	ELSE
		IF (p_itmTyp = 'Bills/Charges') THEN
			v_spnColor := 'red';
			p_fnlColorAmntDffrnc := p_inp_AmntDffrnc - p_amnt;
			p_brghtTotal := p_inbrghtTotal + p_amnt;
		ELSIF (p_itmTyp = 'Deductions') THEN
			IF (p_itmNm ILIKE '(Payment)' OR p_itmNm = 'Advance Payments Amount Kept') THEN
				v_spnColor := 'green';
				p_fnlColorAmntDffrnc := p_inp_AmntDffrnc + p_amnt;
			ELSE
				v_spnColor := 'red';
				p_fnlColorAmntDffrnc := p_inp_AmntDffrnc - p_amnt;
			END IF;
			IF (p_itmTypCnt > 1) THEN
				v_mltplr := '-';
				p_brghtTotal := p_inbrghtTotal - p_amnt;
			ELSE
				p_brghtTotal := p_inbrghtTotal + p_amnt;
			END IF;
		ELSIF (p_itmTyp = 'Earnings') THEN
			v_spnColor := 'green';
			p_fnlColorAmntDffrnc := p_inp_AmntDffrnc + p_amnt;
			IF (p_itmNm = 'Advance Payments Amount Applied') THEN
				IF (p_itmTypCnt > 1) THEN
					v_mltplr := '-';
					p_brghtTotal := p_inbrghtTotal - p_amnt;
				ELSE
					p_brghtTotal := p_inbrghtTotal + p_amnt;
				END IF;
			ELSE
				p_brghtTotal := p_inbrghtTotal + p_amnt;
			END IF;
		ELSE
			v_spnColor := 'black';
		END IF;
	END IF;
	IF (p_brghtTotal >= 0 AND p_fnlColorAmntDffrnc >= 0) THEN
		p_prpsdTtlSpnColor := 'green';
	ELSE
		p_prpsdTtlSpnColor := 'red';
	END IF;
	IF (v_mltplr = '-') THEN
		p_finalTxt := '<span style="color:' || v_spnColor || ';">' || round((- 1 * p_amnt), 2) || '</span>';
	ELSE
		p_finalTxt := '<span style="color:' || v_spnColor || ';">' || round(p_amnt, 2) || '</span>';
	END IF;
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_MsPay_SumTtl (p_PyReqID bigint, p_mspyid bigint, p_prsnID bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	vRD RECORD;
	v_inbrghtTotal numeric := 0.00;
	v_inp_AmntDffrnc numeric := 0.00;
	v_inbrghtTotal1 numeric := 0.00;
	v_inp_AmntDffrnc1 numeric := 0.00;
	v_prpsdTtlSpnColor character varying(200) := '';
	v_finalTxt character varying(2000) := '';
	v_isQuickPay character varying(1) := '0';
	v_itmTypCnt integer := 0;
	v_itmTypCnt1 integer := 0;
BEGIN
	v_inbrghtTotal := 0.00;
	v_inp_AmntDffrnc := 0.00;
	v_inbrghtTotal1 := 0.00;
	v_inp_AmntDffrnc1 := 0.00;
	v_itmTypCnt := pay.getBatchItmTypCnt (p_PyReqID, p_mspyid, p_prsnID);
	v_itmTypCnt1 := pay.getBatchItmTypCnt1 (p_mspyid);
	v_isQuickPay := gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'is_quick_pay', p_mspyid);
	IF v_isQuickPay = '0' THEN
		FOR vRD IN
		SELECT
			tbl1.payer_person_id,
			tbl1.mass_pay_hdr_id,
			tbl1.pymnt_trns_id,
			tbl1.pay_item_id,
			tbl1.itmNm,
			coalesce(tbl1.amount_paid, 0) amount_paid,
			tbl1.payment_date,
			tbl1.line_description,
			tbl1.effct,
			tbl1.mintyp
		FROM (
			SELECT
				pymnt_req_id,
				payer_person_id,
				mass_pay_hdr_id,
				pymnt_req_hdr_id,
				pymnt_trns_id,
				pay_item_id,
				org.get_payitm_nm (pay_item_id) itmNm,
				a.amount_paid amount_paid,
				to_char(to_timestamp(a.payment_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') payment_date,
				line_description,
				org.get_payitm_effct (pay_item_id) effct,
				org.get_payitm_mintyp (pay_item_id) mintyp
			FROM
				self.self_prsn_intrnl_pymnts a
			WHERE (a.pymnt_req_id = p_mspyid
				AND ((payer_person_id = p_prsnID
						AND p_prsnID > 0)
					OR p_prsnID <= 0))
		UNION
		SELECT
			- 1,
			a.person_id,
			a.mass_pay_id,
			- 1,
			a.pay_trns_id,
			a.item_id,
			org.get_payitm_nm (a.item_id) itmNm,
			a.amount_paid,
			to_char(to_timestamp(a.paymnt_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') paymnt_date,
			a.pymnt_desc,
			org.get_payitm_effct (a.item_id) effct,
			org.get_payitm_mintyp (a.item_id) mintyp
		FROM
			pay.pay_itm_trnsctns a
		WHERE (a.mass_pay_id = p_mspyid
			AND ((person_id = p_prsnID
					AND p_prsnID > 0)
				OR p_prsnID <= 0)
			AND a.pymnt_vldty_status = 'VALID'
			AND a.src_py_trns_id <= 0)) tbl1
ORDER BY
	tbl1.pymnt_trns_id ASC LOOP
		SELECT
			p_prpsdTtlSpnColor,
			p_brghtTotal,
			p_fnlColorAmntDffrnc,
			p_finalTxt
		FROM
			pay.getBatchNetAmnt (v_itmTypCnt, vRD.mintyp, vRD.itmNm, vRD.effct, vRD.amount_paid, v_inbrghtTotal1, v_inp_AmntDffrnc1) INTO v_prpsdTtlSpnColor,
		v_inbrghtTotal,
		v_inp_AmntDffrnc,
		v_finalTxt;
		--RAISE NOTICE 'v_inbrghtTotal = "%"', v_inbrghtTotal;
		IF coalesce(v_inbrghtTotal, 0) != 0 THEN
			v_inbrghtTotal1 := coalesce(v_inbrghtTotal, 0);
			v_inp_AmntDffrnc1 := coalesce(v_inp_AmntDffrnc, 0);
		END IF;
	END LOOP;
	ELSE
		FOR vRD IN
		SELECT
			tbl1.payer_person_id,
			tbl1.mass_pay_hdr_id,
			tbl1.pymnt_trns_id,
			tbl1.pay_item_id,
			tbl1.itmNm,
			coalesce(tbl1.amount_paid, 0) amount_paid,
			tbl1.payment_date,
			tbl1.line_description,
			tbl1.effct,
			tbl1.mintyp
		FROM (
			SELECT
				- 1 pymnt_req_id,
				person_id payer_person_id,
				mass_pay_id mass_pay_hdr_id,
				- 1 pymnt_req_hdr_id,
				value_set_det_id pymnt_trns_id,
				item_id pay_item_id,
				org.get_payitm_nm (item_id) itmNm,
				a.value_to_use amount_paid,
				to_char(to_timestamp(a.creation_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') payment_date,
				'' line_description,
				org.get_payitm_effct (item_id) effct,
				org.get_payitm_mintyp (item_id) mintyp
			FROM
				pay.pay_value_sets_det a
			WHERE (mass_pay_id = p_mspyid
				AND ((person_id = p_prsnID
						AND p_prsnID > 0)
					OR p_prsnID <= 0))) tbl1
	ORDER BY
		tbl1.pymnt_trns_id ASC LOOP
			SELECT
				p_prpsdTtlSpnColor,
				p_brghtTotal,
				p_fnlColorAmntDffrnc,
				p_finalTxt
			FROM
				pay.getBatchNetAmnt (v_itmTypCnt1, vRD.mintyp, vRD.itmNm, vRD.effct, vRD.amount_paid, v_inbrghtTotal1, v_inp_AmntDffrnc1) INTO v_prpsdTtlSpnColor,
	v_inbrghtTotal,
	v_inp_AmntDffrnc,
	v_finalTxt;
			--RAISE NOTICE 'v_inbrghtTotal = "%"', v_inbrghtTotal;
			IF coalesce(v_inbrghtTotal, 0) != 0 THEN
				v_inbrghtTotal1 := coalesce(v_inbrghtTotal, 0);
				v_inp_AmntDffrnc1 := coalesce(v_inp_AmntDffrnc, 0);
			END IF;
		END LOOP;
	END IF;
	RETURN COALESCE(v_inbrghtTotal, 0);
END;
$BODY$;

--DROP FUNCTION pay.rollBackMsPay (p_mspID bigint, p_orgid integer, p_who_rn bigint);
--DROP FUNCTION pay.rollbackmspay (p_mspid bigint, p_orgid integer, v_msg_id bigint, p_who_rn bigint);

CREATE OR REPLACE FUNCTION pay.rollBackMsPay (p_mspID bigint, p_orgid integer, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_cntr integer := 0;
	rd1 RECORD;
	msgs text := 'ERROR:';
	v_reslt_1 text := '';
	v_msPyNm character varying(200) := '';
	v_msPyDesc character varying(300) := '';
	v_dateStr character varying(21) := '';
	v_gldateStr character varying(21) := '';
	v_msPyPrsStID integer := - 1;
	v_msPyItmStID integer := - 1;
	v_nwmspyid bigint := - 1;
	v_msg_id bigint := - 1;
	v_retmsg text := '';
	v_pytrnsamnt numeric := 0;
	v_intfcDbtAmnt numeric := 0;
	v_intfcCrdtAmnt numeric := 0;
	v_invcnt integer := 0;
BEGIN
	v_msPyNm := gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'mass_pay_name', p_mspID);
	IF (char_length(v_msPyNm) <= 0 OR p_mspID <= 0) THEN
		msgs := 'ERROR:Mass Pay cannot be empty!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
	END IF;
	v_msPyDesc := gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'mass_pay_desc', p_mspID);
	v_msPyPrsStID := gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'prs_st_id', p_mspID);
	v_msPyItmStID := gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'itm_st_id', p_mspID);
	v_dateStr := to_char(to_timestamp(gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'mass_pay_trns_date', p_mspID), 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
	v_gldateStr := to_char(to_timestamp(gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'gl_date', p_mspID), 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
	v_nwmspyid := COALESCE(pay.get_ms_pay_id (v_msPyNm || ' (Reversal)'), - 1);
	IF (v_nwmspyid <= 0) THEN
		v_reslt_1 := pay.createMsPy (p_orgid, (v_msPyNm || ' (Reversal)')::character varying, ('(Reversal) ' || v_msPyDesc)::character varying, v_dateStr, v_msPyPrsStID, v_msPyItmStID, v_gldateStr, p_who_rn);
	END IF;
	v_nwmspyid := COALESCE(pay.get_ms_pay_id (v_msPyNm || ' (Reversal)'), - 1);
	v_msg_id := gst.getLogMsgID ('pay.pay_mass_pay_run_msgs', 'Mass Pay Run Reversal', v_nwmspyid);
	--RAISE NOTICE 'v_nwmspyid = "%"', v_nwmspyid;
	IF (v_msg_id <= 0) THEN
		v_reslt_1 := gst.createLogMsg (v_dateStr || ' .... Mass Pay Run Reversal is about to Start...', 'pay.pay_mass_pay_run_msgs', 'Mass Pay Run Reversal', v_nwmspyid, v_dateStr, p_who_rn);
	END IF;
	v_msg_id := gst.getLogMsgID ('pay.pay_mass_pay_run_msgs', 'Mass Pay Run Reversal', v_nwmspyid);
	v_retmsg := '';
	-- LOOP through ALL payments TO REVERSE them
	--RAISE NOTICE 'v_msg_id = "%"', v_msg_id;
	FOR rd1 IN
	SELECT
		a.pay_trns_id,
		a.person_id,
		a.item_id,
		a.amount_paid,
		to_char(to_timestamp(a.paymnt_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') paymnt_date,
		a.paymnt_source,
		a.pay_trns_type,
		a.pymnt_desc,
		- 1,
		a.crncy_id,
		c.local_id_no,
		trim(c.title || ' ' || c.sur_name || ', ' || c.first_name || ' ' || c.other_names) fullname,
		b.item_code_name,
		b.item_value_uom,
		b.item_maj_type,
		b.item_min_type
	FROM (pay.pay_itm_trnsctns a
	LEFT OUTER JOIN org.org_pay_items b ON a.item_id = b.item_id)
	LEFT OUTER JOIN prs.prsn_names_nos c ON a.person_id = c.person_id
WHERE (a.mass_pay_id = p_mspID)
ORDER BY
	a.pay_trns_id LOOP
		v_retmsg := pay.rvrsMassPay (p_orgid, rd1.person_id, rd1.local_id_no, rd1.item_id, rd1.item_code_name, rd1.item_value_uom, v_nwmspyid, rd1.paymnt_date, rd1.pay_trns_type, rd1.item_maj_type, rd1.item_min_type, v_msg_id, 'pay.pay_mass_pay_run_msgs', v_dateStr, rd1.amount_paid, rd1.crncy_id, '(Reversal) ' || rd1.pymnt_desc, rd1.pay_trns_id, v_gldateStr, p_who_rn);
		--RAISE NOTICE 'rd1.pay_trns_id = "%"', rd1.pay_trns_id;
		--RAISE NOTICE 'v_retmsg = "%"', v_retmsg;
		v_cntr := v_cntr + 1;
	END LOOP;

	/* DO SOME summation checks BEFORE updating the Status
	 -- FUNCTION TO CHECK IF sum OF debits IS equal sum OF credits TO sum OF amnts IN ALL these pay trns
	 -- IF correct the SET gone TO gl TO '1' ELSE '0'*/
	v_reslt_1 := pay.chck_n_updt_pay_rqsts (v_nwmspyid);
	v_pytrnsamnt := pay.getMsPyAmntSum (v_nwmspyid);
	v_intfcDbtAmnt := pay.getMsPyIntfcDbtSum (v_nwmspyid);
	v_intfcCrdtAmnt := pay.getMsPyIntfcCrdtSum (v_nwmspyid);
	SELECT
		count(pymnt_id) INTO v_invcnt
	FROM
		accb.accb_payments
	WHERE
		intnl_pay_trns_id = p_mspID;
	IF coalesce(v_invcnt, 0) > 0 THEN
		v_intfcDbtAmnt := 0;
		v_intfcCrdtAmnt := 0;
	END IF;
	IF (v_pytrnsamnt = v_intfcCrdtAmnt AND v_pytrnsamnt = v_intfcDbtAmnt AND v_pytrnsamnt != 0) THEN
		v_reslt_1 := pay.updateMsPyStatus (v_nwmspyid, '1', '1', p_who_rn);
	ELSIF (v_pytrnsamnt != 0
			AND coalesce(v_invcnt, 0) <= 0) THEN
		v_reslt_1 := pay.updateMsPyStatus (v_nwmspyid, '1', '0', p_who_rn);
	ELSIF (pay.get_Total_MsPyDt (v_nwmspyid) > 0
			AND v_intfcCrdtAmnt = 0) THEN
		v_reslt_1 := pay.updateMsPyStatus (v_nwmspyid, '1', '1', p_who_rn);
	END IF;
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.createMsPy (p_orgid integer, p_mspyname character varying, p_mspydesc character varying, p_trnsdte character varying, p_prstid integer, p_itmstid integer, p_glDate character varying, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_trnsdte character varying(21) := '';
	v_glDate character varying(21) := '';
	v_dateStr character varying(21) := '';
BEGIN
	v_trnsdte := to_char(to_timestamp(p_trnsdte, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_glDate := to_char(to_timestamp(p_glDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	INSERT INTO pay.pay_mass_pay_run_hdr (mass_pay_name, mass_pay_desc, created_by, creation_date, last_update_by, last_update_date, run_status, mass_pay_trns_date, prs_st_id, itm_st_id, org_id, sent_to_gl, gl_date)
		VALUES (p_mspyname, p_mspydesc, p_who_rn, v_dateStr, p_who_rn, v_dateStr, '0', v_trnsdte, p_prstid, p_itmstid, p_orgid, '0', v_glDate);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.createmspy2 (p_orgid integer, p_mspyname character varying, p_mspydesc character varying, p_trnsdte character varying, p_prstid integer, p_itmstid integer, p_gldate character varying, p_who_rn bigint, p_allwd_group_type character varying, p_allwd_group_value character varying, p_workplace_cstmr_id bigint, p_workplace_cstmr_site_id bigint, p_entered_amnt numeric, p_entered_amt_crncy_id integer, p_cheque_card_num character varying, p_sign_code character varying, p_is_quick_pay character varying, p_auto_asgn_itms character varying, p_mspy_apply_advnc character varying, p_mspy_keep_excess character varying)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_trnsdte character varying(21) := '';
	v_glDate character varying(21) := '';
	v_dateStr character varying(21) := '';
BEGIN
	v_trnsdte := to_char(to_timestamp(p_trnsdte, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_glDate := to_char(to_timestamp(p_glDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	INSERT INTO pay.pay_mass_pay_run_hdr (mass_pay_name, mass_pay_desc, created_by, creation_date, last_update_by, last_update_date, run_status, mass_pay_trns_date, prs_st_id, itm_st_id, org_id, sent_to_gl, gl_date, allwd_group_type, allwd_group_value, workplace_cstmr_id, workplace_cstmr_site_id, entered_amnt, entered_amt_crncy_id, cheque_card_num, sign_code, is_quick_pay, auto_asgn_itms, mspy_apply_advnc, mspy_keep_excess)
		VALUES (p_mspyname, p_mspydesc, p_who_rn, v_dateStr, p_who_rn, v_dateStr, '0', v_trnsdte, p_prstid, p_itmstid, p_orgid, '0', v_glDate, p_allwd_group_type, p_allwd_group_value, p_workplace_cstmr_id, p_workplace_cstmr_site_id, p_entered_amnt, p_entered_amt_crncy_id, p_cheque_card_num, p_sign_code, p_is_quick_pay, p_auto_asgn_itms, p_mspy_apply_advnc, p_mspy_keep_excess);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_Total_MsPyDt (p_mspyid bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		count(1) INTO v_res
	FROM (pay.pay_itm_trnsctns a
	LEFT OUTER JOIN org.org_pay_items b ON a.item_id = b.item_id)
	LEFT OUTER JOIN prs.prsn_names_nos c ON a.person_id = c.person_id
WHERE (a.mass_pay_id = p_mspyid);
	RETURN COALESCE(v_res, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getMsPyAmntSum (p_mspyid bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res numeric := 0;
BEGIN
	SELECT
		SUM(a.amount_paid) INTO v_res
	FROM
		pay.pay_itm_trnsctns a,
		org.org_pay_items b
	WHERE
		a.item_id = b.item_id
		AND a.pay_trns_type != 'Purely Informational'
		AND b.cost_accnt_id > 0
		AND b.bals_accnt_id > 0
		AND a.crncy_id > 0
		AND a.mass_pay_id = p_mspyid;
	RETURN COALESCE(v_res, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

--DROP FUNCTION pay.getmspyintfcdbtsum (bigint);
CREATE OR REPLACE FUNCTION pay.getmspyintfcdbtsum (p_mspyid bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res numeric := 0.00;
BEGIN
	SELECT
		SUM(a.dbt_amount) INTO v_res
	FROM
		pay.pay_gl_interface a
	WHERE
		a.source_trns_id IN (
			SELECT
				b.pay_trns_id
			FROM
				pay.pay_itm_trnsctns b
			WHERE
				b.mass_pay_id = p_mspyid);
	RETURN COALESCE(v_res, 0.00);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

--DROP FUNCTION pay.getmspyintfccrdtsum (bigint);
CREATE OR REPLACE FUNCTION pay.getmspyintfccrdtsum (p_mspyid bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res numeric := 0.00;
BEGIN
	SELECT
		SUM(a.crdt_amount) INTO v_res
	FROM
		pay.pay_gl_interface a
	WHERE
		a.source_trns_id IN (
			SELECT
				b.pay_trns_id
			FROM
				pay.pay_itm_trnsctns b
			WHERE
				b.mass_pay_id = p_mspyid);
	RETURN COALESCE(v_res, 0.00);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0.00;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.updateMsPyStatus (p_mspyid bigint, p_run_cmpltd character varying, p_to_gl_intfc character varying, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
BEGIN
	v_dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	UPDATE
		pay.pay_mass_pay_run_hdr
	SET
		run_status = p_run_cmpltd,
		sent_to_gl = p_to_gl_intfc,
		last_update_by = p_who_rn,
		last_update_date = v_dateStr
	WHERE
		mass_pay_id = p_mspyid;
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getPymntRvrslTrnsID (p_paytrnsid bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		a.pay_trns_id INTO v_res
	FROM
		pay.pay_itm_trnsctns a
	WHERE ((a.src_py_trns_id = p_paytrnsid)
		OR (a.pay_trns_id = p_paytrnsid
			AND a.src_py_trns_id > 0));
	RETURN COALESCE(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.updateTrnsVldtyStatus (p_paytrnsid bigint, p_vldty character varying, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
BEGIN
	v_dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	UPDATE
		pay.pay_itm_trnsctns
	SET
		pymnt_vldty_status = p_vldty,
		last_update_by = p_who_rn,
		last_update_date = v_dateStr
	WHERE
		pay_trns_id = p_paytrnsid;
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getPaymntTrnsID (p_prsnid bigint, p_itmid bigint, p_amnt numeric, p_paydate character varying, p_orgnlTrnsID bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	v_paydate character varying(21) := '';
BEGIN
	v_paydate := to_char(to_timestamp(p_paydate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	SELECT
		pay_trns_id INTO v_res
	FROM
		pay.pay_itm_trnsctns
	WHERE (person_id = p_prsnid
		AND item_id = p_itmid
		AND amount_paid = p_amnt
		AND paymnt_date = v_paydate
		AND pymnt_vldty_status = 'VALID'
		AND src_py_trns_id = p_orgnlTrnsID);
	RETURN COALESCE(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_InvoiceMsPyID (p_invcID bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		mass_pay_id INTO v_res
	FROM
		pay.pay_itm_trnsctns a
	WHERE (a.sales_invoice_id = p_invcID
		AND a.sales_invoice_id > 0
		AND a.pymnt_vldty_status = 'VALID'
		AND a.src_py_trns_id <= 0)
ORDER BY
	mass_pay_id DESC
LIMIT 1 OFFSET 0;
	RETURN COALESCE(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_MsPyInvoiceID (p_mspyID bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		sales_invoice_id INTO v_res
	FROM
		pay.pay_itm_trnsctns a
	WHERE (a.mass_pay_id = p_mspyID
		AND a.sales_invoice_id > 0
		AND a.pymnt_vldty_status = 'VALID'
		AND a.src_py_trns_id <= 0)
ORDER BY
	mass_pay_id DESC
LIMIT 1 OFFSET 0;
	RETURN COALESCE(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.deletePymntGLInfcLns (p_pyTrnsID bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	DELETE FROM pay.pay_gl_interface
	WHERE source_trns_id = p_pyTrnsID
		AND gl_batch_id = - 1;
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.rvrsMassPay (p_org_id integer, p_prsn_id bigint, p_loc_id_no character varying, p_itm_id integer, p_itm_name character varying, p_itm_uom character varying, p_mspy_id bigint, p_trns_date character varying, p_trns_typ character varying, p_itm_maj_typ character varying, p_itm_min_typ character varying, p_msg_id bigint, p_log_tbl character varying, p_dateStr character varying, p_pay_amount numeric, p_crncy_id integer, p_pay_trns_desc character varying, p_orgnlPyTrnsID bigint, p_glDate character varying, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_Reslg bigint := - 1;
	v_res text := '';
	v_crncy_cde character varying(50) := '';
	v_pay_amount numeric := 0;
	v_crncy_id integer := - 1;
	v_tstPyTrnsID bigint := - 1;
	v_nwpaytrnsid bigint := - 1;
	b_res boolean := FALSE;
BEGIN
	v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Reversing Transaction for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
	v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Reversing Transaction for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
	IF upper(p_itm_maj_typ) = upper('Balance Item') THEN
		RETURN 'Continue';
	END IF;
	IF (char_length(p_trns_typ) <= 0) THEN
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Transaction Type not Specified for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Transaction Type not Specified for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
		RETURN 'Continue';
	END IF;
	IF (pay.getPymntRvrslTrnsID (p_orgnlPyTrnsID) > 0) THEN
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>This Payment has been reversed already or is a reversal for another Transaction:- Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>This Payment has been reversed already or is a reversal for another Transaction:- Person:' || p_loc_id_no || ' Item: ' || p_itm_name, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
		RETURN 'Continue';
	END IF;

	/*Processing a Payment
	 * 1. Create Payment line pay.pay_itm_trnsctns for Pay Value Items
	 * 2. Update Daily BalsItms for all balance items this Pay value Item feeds into
	 * 3. Create Tmp GL Lines in a temp GL interface Table
	 * 4. Need to check whether any of its Balance Items disallows negative balance.
	 * If Not disallow this trans if it will lead to a negative balance on a Balance Item
	 */
	v_crncy_cde := p_itm_uom;
	IF (p_itm_uom = 'Money') THEN
		v_crncy_cde := gst.get_pssbl_val (v_crncy_id);
	END IF;
	IF (p_pay_amount = 0) THEN
		RETURN 'Continue';
	END IF;
	v_pay_amount := - 1 * p_pay_amount;

	/*if paid check if
	 * 1. Prsn Itm Balances have been updated by this trns_id
	 * 2. Check if the debit and credit legs for this trns_id have been created in gl_interface
	 * 3. Do them all if any is not done else return continue if all is done
	 */
	v_tstPyTrnsID := pay.hsPrsnBnPaidItmMsPy (p_prsn_id, p_itm_id, p_trns_date, v_pay_amount);
	IF (v_tstPyTrnsID <= 0) THEN
		v_res := pay.createPaymntLine (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, 'Mass Pay Run Reversal', p_trns_typ, p_mspy_id, p_pay_trns_desc, p_crncy_id, p_dateStr, 'VALID', p_orgnlPyTrnsID, p_glDate, '', p_who_rn);
		v_res := pay.updateTrnsVldtyStatus (p_orgnlPyTrnsID, 'VOID', p_who_rn);
	ELSE
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Same Payment has been made for this Person on the same Date already! Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Same Payment has been made for this Person on the same Date already! Person:' || p_loc_id_no || ' Item: ' || p_itm_name, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
	END IF;
	-- UPDATE Balance Items
	v_res := pay.updtBlsItms (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, 'Mass Pay Run Reversal', p_orgnlPyTrnsID, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);
	v_res := pay.deletePymntGLInfcLns (p_orgnlPyTrnsID);
	v_nwpaytrnsid := pay.getPaymntTrnsID (p_prsn_id, p_itm_id, p_pay_amount, p_trns_date, p_orgnlPyTrnsID);
	b_res := pay.rvrsImprtdPymntIntrfcTrns (p_orgnlPyTrnsID, v_nwpaytrnsid, p_dateStr, p_who_rn);
	IF (b_res) THEN
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Successfully processed Payment Reversal for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Successfully processed Payment Reversal for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
	ELSE
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Processing Payment Reversal Failed for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Processing Payment Reversal Failed for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
	END IF;
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

--DROP FUNCTION pay.createPaymntLine (p_prsnid bigint, p_itmid integer, p_amnt numeric, p_paydate character varying, p_paysource character varying, p_trnsType character varying, p_msspyid bigint, p_paydesc character varying, p_crncyid integer, p_dateStr character varying, p_pymt_vldty character varying, p_src_trns_id bigint, p_glDate character varying, p_dteErnd character varying, p_who_rn bigint);
CREATE OR REPLACE FUNCTION pay.createPaymntLine (p_prsnid bigint, p_itmid bigint, p_amnt numeric, p_paydate character varying, p_paysource character varying, p_trnsType character varying, p_msspyid bigint, p_paydesc character varying, p_crncyid integer, p_dateStr character varying, p_pymt_vldty character varying, p_src_trns_id bigint, p_glDate character varying, p_dteErnd character varying, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
	v_paydate character varying(21) := '';
	v_glDate character varying(21) := '';
	v_dteErnd character varying(21) := '';
BEGIN
	v_paydate := to_char(to_timestamp(p_paydate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_dateStr := to_char(to_timestamp(p_dateStr, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_glDate := to_char(to_timestamp(p_glDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (char_length(p_dteErnd) <= 0) THEN
		v_dteErnd := v_paydate;
	END IF;
	INSERT INTO pay.pay_itm_trnsctns (person_id, item_id, amount_paid, paymnt_date, paymnt_source, pay_trns_type, created_by, creation_date, last_update_by, last_update_date, mass_pay_id, pymnt_desc, crncy_id, pymnt_vldty_status, src_py_trns_id, gl_date, date_earned)
		VALUES (p_prsnid, p_itmid, p_amnt, v_paydate, p_paysource, p_trnsType, p_who_rn, v_dateStr, p_who_rn, v_dateStr, p_msspyid, p_paydesc, p_crncyid, p_pymt_vldty, p_src_trns_id, v_glDate, v_dteErnd);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.createPaymntLine2 (p_prsnid bigint, p_itmid bigint, p_amnt numeric, p_paydate character varying, p_paysource character varying, p_trnsType character varying, p_msspyid bigint, p_paydesc character varying, p_crncyid integer, p_dateStr character varying, p_pymt_vldty character varying, p_src_trns_id bigint, p_glDate character varying, p_dteErnd character varying, p_who_rn bigint, p_sales_invoice_id bigint, p_leave_of_absence_id bigint, p_invc_det_ln_id bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
	v_paydate character varying(21) := '';
	v_glDate character varying(21) := '';
	v_dteErnd character varying(21) := '';
BEGIN
	v_paydate := to_char(to_timestamp(p_paydate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_dateStr := to_char(to_timestamp(p_dateStr, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_glDate := to_char(to_timestamp(p_glDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (char_length(p_dteErnd) <= 0) THEN
		v_dteErnd := v_paydate;
	END IF;
	INSERT INTO pay.pay_itm_trnsctns (person_id, item_id, amount_paid, paymnt_date, paymnt_source, pay_trns_type, created_by, creation_date, last_update_by, last_update_date, mass_pay_id, pymnt_desc, crncy_id, pymnt_vldty_status, src_py_trns_id, gl_date, date_earned, sales_invoice_id, leave_of_absence_id, invc_det_ln_id)
		VALUES (p_prsnid, p_itmid, p_amnt, v_paydate, p_paysource, p_trnsType, p_who_rn, v_dateStr, p_who_rn, v_dateStr, p_msspyid, p_paydesc, p_crncyid, p_pymt_vldty, p_src_trns_id, v_glDate, v_dteErnd, p_sales_invoice_id, p_leave_of_absence_id, p_invc_det_ln_id);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.createPaymntLine3 (p_prsnid bigint, p_itmid bigint, p_amnt numeric, p_paydate character varying, p_paysource character varying, p_trnsType character varying, p_msspyid bigint, p_paydesc character varying, p_crncyid integer, p_dateStr character varying, p_pymt_vldty character varying, p_src_trns_id bigint, p_glDate character varying, p_dteErnd character varying, p_who_rn bigint, p_rqst_id bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
	v_paydate character varying(21) := '';
	v_glDate character varying(21) := '';
	v_dteErnd character varying(21) := '';
BEGIN
	v_paydate := to_char(to_timestamp(p_paydate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_dateStr := to_char(to_timestamp(p_dateStr, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_glDate := to_char(to_timestamp(p_glDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (char_length(p_dteErnd) <= 0) THEN
		v_dteErnd := v_paydate;
	END IF;
	INSERT INTO pay.pay_itm_trnsctns (person_id, item_id, amount_paid, paymnt_date, paymnt_source, pay_trns_type, created_by, creation_date, last_update_by, last_update_date, mass_pay_id, pymnt_desc, crncy_id, pymnt_vldty_status, src_py_trns_id, gl_date, date_earned, pay_request_id)
		VALUES (p_prsnid, p_itmid, p_amnt, v_paydate, p_paysource, p_trnsType, p_who_rn, v_dateStr, p_who_rn, v_dateStr, p_msspyid, p_paydesc, p_crncyid, p_pymt_vldty, p_src_trns_id, v_glDate, v_dteErnd, p_rqst_id);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.hsPrsnBnPaidItmMsPy (p_prsnID bigint, p_itmID bigint, p_trns_date character varying, p_amnt numeric)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	v_trns_date character varying(21) := '';
BEGIN
	v_trns_date := to_char(to_timestamp(p_trns_date, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	SELECT
		a.pay_trns_id INTO v_res
	FROM
		pay.pay_itm_trnsctns a
	WHERE ((a.person_id = p_prsnID)
		AND (a.item_id = p_itmID)
		AND (paymnt_date ILIKE '%' || v_trns_date || '%')
		AND (amount_paid = p_amnt)
		AND (a.pymnt_vldty_status = 'VALID'
			AND a.src_py_trns_id < 0));
	RETURN COALESCE(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.hsPrsnBnPaidItmMsPy2 (p_prsnID bigint, p_itmID bigint, p_trns_date character varying, p_amnt numeric, p_rqst_id bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	v_trns_date character varying(21) := '';
BEGIN
	v_trns_date := to_char(to_timestamp(p_trns_date, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	SELECT
		a.pay_trns_id INTO v_res
	FROM
		pay.pay_itm_trnsctns a
	WHERE ((a.person_id = p_prsnID)
		AND (a.item_id = p_itmID)
		AND (paymnt_date ILIKE '%' || v_trns_date || '%')
		AND (pymnt_desc ILIKE '%REQUEST ID:' || p_rqst_id || '%')
		AND (amount_paid = p_amnt)
		AND (a.pymnt_vldty_status = 'VALID'
			AND a.src_py_trns_id < 0));
	RETURN COALESCE(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.hsPrsnBnPaidItmMsPyRetro (p_prsnID bigint, p_itmID bigint, p_trns_date character varying, p_amnt numeric)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	v_trns_date character varying(21) := '';
BEGIN
	v_trns_date := to_char(to_timestamp(p_trns_date, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	SELECT
		a.pay_trns_id INTO v_res
	FROM
		pay.pay_itm_trnsctns_retro a
	WHERE ((a.person_id = p_prsnID)
		AND (a.item_id = p_itmID)
		AND (paymnt_date ILIKE '%' || p_trns_date || '%')
		AND (amount_paid = p_amnt)
		AND (a.pymnt_vldty_status = 'VALID'
			AND a.src_py_trns_id < 0));
	RETURN COALESCE(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.hsPrsnBnPaidItmInInvc (p_prsnID bigint, p_itmID bigint, OUT p_rcvblInvcID bigint, OUT p_rcvblInvcTyp character varying, OUT b_res boolean)
LANGUAGE 'plpgsql'
COST 100 VOLATILE
AS $BODY$
	<< outerblock >>
DECLARE
	rd1 RECORD;
BEGIN
	FOR rd1 IN
	SELECT
		a.pymnt_id,
		a.amount_paid,
		b.rcvbls_invc_number,
		b.rcvbls_invc_type,
		b.rcvbls_invc_hdr_id,
		a.intnl_pay_trns_id,
		c.person_id,
		c.item_id
	FROM
		accb.accb_payments a,
		accb.accb_rcvbls_invc_hdr b,
		pay.pay_itm_trnsctns c
	WHERE
		a.src_doc_id = b.rcvbls_invc_hdr_id
		AND a.src_doc_typ = b.rcvbls_invc_type
		AND a.intnl_pay_trns_id = c.pay_trns_id
		AND c.person_id = p_prsnID
		AND c.item_id = p_itmID
	ORDER BY
		3 LOOP
			p_rcvblInvcID := rd1.rcvbls_invc_hdr_id;
			p_rcvblInvcTyp := rd1.rcvbls_invc_type;
			b_res := TRUE;
			RETURN;
		END LOOP;
	p_rcvblInvcID := - 1;
	p_rcvblInvcTyp := '';
	b_res := FALSE;
EXCEPTION
	WHEN OTHERS THEN
		p_rcvblInvcID := - 1;
	p_rcvblInvcTyp := '';
	b_res := FALSE;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.hsPrsnBnPaidItmMnl (p_prsnID bigint, p_itmID bigint, p_trns_date character varying, p_amnt numeric)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := 0;
	v_trns_date character varying(21) := '';
BEGIN
	v_trns_date := to_char(to_timestamp(p_trns_date, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	SELECT
		count(a.pay_trns_id) INTO v_res
	FROM
		pay.pay_itm_trnsctns a
	WHERE ((a.person_id = p_prsnID)
		AND (a.item_id = p_itmID)
		AND (paymnt_date LIKE '%' || v_trns_date || '%')
		AND (amount_paid = p_amnt)
		AND (a.pymnt_vldty_status = 'VALID'
			AND a.src_py_trns_id < 0));
	RETURN COALESCE(v_res, 0) > 0;
EXCEPTION
	WHEN OTHERS THEN
		RETURN FALSE;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.rvrsImprtdPymntIntrfcTrns (p_orgnlPyTrnsID bigint, p_nwPyTrnsID bigint, p_dateStr character varying, p_who_rn bigint)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	v_dateStr character varying(21) := '';
	rd1 RECORD;
	v_accntID integer := - 1;
	v_dbtamount numeric := 0;
	v_crdtamount numeric := 0;
	v_crncy_id integer := - 1;
	v_netamnt numeric := 0;
	v_trnsdte character varying(21) := '';
BEGIN
	v_dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	FOR rd1 IN
	SELECT
		interface_id,
		accnt_id,
		transaction_desc,
		dbt_amount,
		trnsctn_date,
		func_cur_id,
		created_by,
		creation_date,
		crdt_amount,
		last_update_by,
		last_update_date,
		net_amount,
		source_trns_id,
		gl_batch_id,
		trns_source
	FROM
		pay.pay_gl_interface
	WHERE
		source_trns_id = p_orgnlPyTrnsID
		AND gl_batch_id != - 1 LOOP
			v_accntID := rd1.accnt_id;
			v_dbtamount := rd1.dbt_amount;
			v_crdtamount := rd1.crdt_amount;
			v_crncy_id := rd1.func_cur_id;
			v_netamnt := rd1.net_amount;
			v_trnsdte := to_char(to_timestamp(rd1.trnsctn_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
			v_res := pay.createPymntGLIntFcLn (v_accntID, '(Reversal)' || rd1.transaction_desc, - 1 * v_dbtamount, v_trnsdte, v_crncy_id, - 1 * v_crdtamount, - 1 * v_netamnt, p_nwPyTrnsID, v_dateStr, p_who_rn);
		END LOOP;
	RETURN TRUE;
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN FALSE;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.createPymntGLIntFcLn (p_accntid integer, p_trnsdesc character varying, p_dbtamnt numeric, p_trnsdte character varying, p_crncyid integer, p_crdtamnt numeric, p_netamnt numeric, p_srcid bigint, p_dateStr character varying, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
	v_trnsdte character varying(21) := '';
BEGIN
	IF (p_accntid <= 0) THEN
		RETURN 'ERROR:' || SQLERRM;
	END IF;
	v_trnsdte := to_char(to_timestamp(p_trnsdte, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_dateStr := to_char(to_timestamp(p_dateStr, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	INSERT INTO pay.pay_gl_interface (accnt_id, transaction_desc, dbt_amount, trnsctn_date, func_cur_id, created_by, creation_date, crdt_amount, last_update_by, last_update_date, net_amount, source_trns_id)
		VALUES (p_accntid, p_trnsdesc, p_dbtamnt, v_trnsdte, p_crncyid, p_who_rn, v_dateStr, p_crdtamnt, p_who_rn, v_dateStr, p_netamnt, p_srcid);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.updtBlsItms (p_prsn_id bigint, p_itm_id bigint, p_pay_amount numeric, p_trns_date character varying, p_trns_src character varying, p_orgnlTrnsID bigint, p_dateStr character varying, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res character varying(4000) := '';
	v_dateStr character varying(21) := '';
	rd1 RECORD;
	v_nwAmnt numeric := 0;
	v_lstBals numeric := 0;
	v_scaleFctr numeric := 0;
	v_paytrnsid bigint := - 1;
	b_hsBlsBnUpdtd boolean := FALSE;
	v_dailybalID bigint := - 1;
	v_org_id integer := - 1;
BEGIN
	v_org_id := prs.get_prsn_org_id (p_prsn_id);
	v_nwAmnt := 0;
	FOR rd1 IN
	SELECT
		a.balance_item_id,
		a.adds_subtracts,
		b.balance_type,
		a.scale_factor,
		C.pssbl_value_id
	FROM
		org.org_pay_itm_feeds a
	LEFT OUTER JOIN org.org_pay_items b ON a.balance_item_id = b.item_id
	LEFT OUTER JOIN org.org_pay_items_values C ON C.item_id = a.balance_item_id
WHERE ((a.fed_by_itm_id = p_itm_id))
ORDER BY
	a.feed_id LOOP
		v_lstBals := 0;
		v_scaleFctr := rd1.scale_factor;
		IF (rd1.balance_type = 'Cumulative') THEN
			v_lstBals := pay.getBlsItmLtstDailyBals (rd1.balance_item_id, p_prsn_id, p_trns_date, v_org_id);
		ELSE
			v_lstBals := pay.getBlsItmDailyBals (rd1.balance_item_id, p_prsn_id, p_trns_date, v_org_id);
		END IF;
		IF (rd1.adds_subtracts = 'Subtracts') THEN
			v_nwAmnt := - 1 * p_pay_amount * v_scaleFctr;
		ELSE
			v_nwAmnt := p_pay_amount * v_scaleFctr;
		END IF;
		-- CHECK IF PRSN 's balance has not been updated already
		v_paytrnsid := pay.getPaymntTrnsID (p_prsn_id, p_itm_id, p_pay_amount, p_trns_date, p_orgnlTrnsID);
		b_hsBlsBnUpdtd := pay.hsPrsItmBlsBnUptd (v_paytrnsid, p_trns_date, rd1.balance_item_id, p_prsn_id);
		v_dailybalID := pay.getItmDailyBalsID (rd1.balance_item_id, p_trns_date, p_prsn_id);
		IF (b_hsBlsBnUpdtd = FALSE) THEN
			IF (v_dailybalID <= 0) THEN
				v_res := pay.createItmBals (rd1.balance_item_id, v_lstBals, p_prsn_id, p_trns_date, - 1, p_who_rn);
				IF (rd1.balance_type = 'Cumulative') THEN
					v_res := pay.updtItmDailyBalsCum (p_trns_date, rd1.balance_item_id, p_prsn_id, v_nwAmnt, v_paytrnsid, p_who_rn);
				ELSE
					v_res := pay.updtItmDailyBalsNonCum (p_trns_date, rd1.balance_item_id, p_prsn_id, v_nwAmnt, v_paytrnsid, p_who_rn);
				END IF;
			ELSE
				IF (rd1.balance_type = 'Cumulative') THEN
					v_res := pay.updtItmDailyBalsCum (p_trns_date, rd1.balance_item_id, p_prsn_id, v_nwAmnt, v_paytrnsid, p_who_rn);
				ELSE
					v_res := pay.updtItmDailyBalsNonCum (p_trns_date, rd1.balance_item_id, p_prsn_id, v_nwAmnt, v_paytrnsid, p_who_rn);
				END IF;
			END IF;
		END IF;
	END LOOP;
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getItmDailyBalsID (p_balsItmID bigint, p_balsDate character varying, p_prsn_id bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	v_balsDate character varying(21) := '';
BEGIN
	v_balsDate := to_char(to_timestamp(p_balsDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_balsDate := substr(v_balsDate, 1, 10);
	SELECT
		a.bals_id INTO v_res
	FROM
		pay.pay_balsitm_bals a
	WHERE (to_timestamp(a.bals_date, 'YYYY-MM-DD') = to_timestamp(p_balsDate, 'YYYY-MM-DD')
		AND a.bals_itm_id = p_balsItmID
		AND a.person_id = p_prsn_id);
	RETURN coalesce(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getBlsItmDailyBals (p_balsItmID bigint, p_prsn_id bigint, p_balsDate character varying, p_org_id integer)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	d_res numeric := 0;
	v_orgnlDte character varying(21) := '';
	v_balsDate character varying(21) := '';
	v_usesSQL character varying(1) := '0';
	v_valSQL text := '';
BEGIN
	v_orgnlDte := p_balsDate;
	v_balsDate := to_char(to_timestamp(p_balsDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_balsDate := substr(v_balsDate, 1, 10);
	d_res := 0;
	v_usesSQL := gst.getGnrlRecNm ('org.org_pay_items', 'item_id', 'uses_sql_formulas', p_balsItmID);
	IF (v_usesSQL != '1') THEN
		SELECT
			a.bals_amount INTO d_res
		FROM
			pay.pay_balsitm_bals a
		WHERE (to_timestamp(a.bals_date, 'YYYY-MM-DD') = to_timestamp(v_balsDate, 'YYYY-MM-DD')
			AND a.bals_itm_id = p_balsItmID
			AND a.person_id = p_prsn_id);
	ELSE
		v_valSQL := pay.getItmValSQL (pay.getPrsnItmVlID (p_prsn_id, p_balsItmID, v_orgnlDte));
		IF (char_length(v_valSQL) > 0) THEN
			d_res := pay.exct_itm_valsql (v_valSQL, p_prsn_id, p_org_id, v_balsDate);
		END IF;
	END IF;
	RETURN COALESCE(d_res, 0);
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getPrsnItmVlID (p_prsnID bigint, p_itmID bigint, p_trnsdte character varying)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	v_trnsdte character varying(21) := '';
BEGIN
	v_trnsdte := to_char(to_timestamp(p_trnsdte, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	SELECT
		a.item_pssbl_value_id INTO v_res
	FROM
		pasn.prsn_bnfts_cntrbtns a
	WHERE ((a.person_id = p_prsnID)
		AND (a.item_id = p_itmID)
		AND (to_timestamp(v_trnsdte, 'YYYY-MM-DD HH24:MI:SS') BETWEEN to_timestamp(valid_start_date || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
			AND to_timestamp(valid_end_date || ' 23:59:59', 'YYYY-MM-DD HH24:MI:SS')));
	RETURN COALESCE(v_res, - 100000);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 100000;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getBlsItmLtstDailyBals (p_balsItmID bigint, p_prsn_id bigint, p_balsDate character varying, p_org_id integer)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	d_res numeric := 0;
	v_orgnlDte character varying(21) := '';
	v_balsDate character varying(21) := '';
	v_usesSQL character varying(1) := '0';
	v_valSQL text := '';
BEGIN
	v_orgnlDte := p_balsDate;
	v_balsDate := to_char(to_timestamp(p_balsDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_balsDate := substr(v_balsDate, 1, 10);
	d_res := 0;
	v_valSQL := '';
	v_usesSQL := gst.getGnrlRecNm ('org.org_pay_items', 'item_id', 'uses_sql_formulas', p_balsItmID);
	IF (v_usesSQL != '1') THEN
		SELECT
			a.bals_amount INTO d_res
		FROM
			pay.pay_balsitm_bals a
		WHERE (to_timestamp(a.bals_date, 'YYYY-MM-DD') <= to_timestamp(v_balsDate, 'YYYY-MM-DD')
			AND a.bals_itm_id = p_balsItmID
			AND a.person_id = p_prsn_id)
	ORDER BY
		to_timestamp(a.bals_date, 'YYYY-MM-DD') DESC
	LIMIT 1 OFFSET 0;
	ELSE
		v_valSQL := pay.getItmValSQL (pay.getPrsnItmVlID (p_prsn_id, p_balsItmID, v_orgnlDte));
		IF (char_length(v_valSQL) > 0) THEN
			d_res := pay.exct_itm_valsql (v_valSQL, p_prsn_id, p_org_id, v_balsDate);
		END IF;
	END IF;
	RETURN coalesce(d_res, 0);
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.hsPrsItmBlsBnUptd (p_pytrnsid bigint, p_trnsdate character varying, p_bals_itm_id bigint, p_prsn_id bigint)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res boolean := FALSE;
	v_trnsdate character varying(21) := '';
	v_sql text := '';
	v_cntr integer := 0;
BEGIN
	v_trnsdate := to_char(to_timestamp(p_trnsdate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (char_length(p_trnsdate) > 10) THEN
		v_trnsdate := substr(p_trnsdate, 1, 10);
	END IF;
	SELECT
		count(a.bals_id) INTO v_cntr
	FROM
		pay.pay_balsitm_bals a
	WHERE
		a.bals_itm_id = p_bals_itm_id
		AND a.person_id = p_prsn_id
		AND a.bals_date = p_trnsdate
		AND a.source_trns_ids LIKE '%,' || p_pytrnsid || ',%';
	RETURN COALESCE(v_cntr, 0) > 0;
EXCEPTION
	WHEN OTHERS THEN
		RETURN FALSE;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.updtItmDailyBalsCum (p_balsDate character varying, p_blsItmID bigint, p_prsn_id bigint, p_netAmnt numeric, p_py_trns_id bigint, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
	v_balsDate character varying(21) := '';
BEGIN
	v_balsDate := to_char(to_timestamp(p_balsDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_balsDate := substr(v_balsDate, 1, 10);
	v_dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	UPDATE
		pay.pay_balsitm_bals
	SET
		last_update_by = p_who_rn,
		last_update_date = v_dateStr,
		bals_amount = bals_amount + p_netAmnt,
		source_trns_ids = source_trns_ids || '' || p_py_trns_id || ','
	WHERE (to_timestamp(bals_date, 'YYYY-MM-DD') >= to_timestamp(v_balsDate, 'YYYY-MM-DD')
		AND bals_itm_id = p_blsItmID
		AND person_id = p_prsn_id);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.updtItmDailyBalsNonCum (p_balsDate character varying, p_blsItmID bigint, p_prsn_id bigint, p_netAmnt numeric, p_py_trns_id bigint, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
	v_balsDate character varying(21) := '';
BEGIN
	v_balsDate := to_char(to_timestamp(p_balsDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_balsDate := substr(v_balsDate, 1, 10);
	v_dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	UPDATE
		pay.pay_balsitm_bals
	SET
		last_update_by = p_who_rn,
		last_update_date = v_dateStr,
		bals_amount = bals_amount + p_netAmnt,
		source_trns_ids = source_trns_ids || '' || p_py_trns_id || ','
	WHERE (to_timestamp(bals_date, 'YYYY-MM-DD') = to_timestamp(v_balsDate, 'YYYY-MM-DD')
		AND bals_itm_id = p_blsItmID
		AND person_id = p_prsn_id);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.createItmBals (p_blsitmid bigint, p_netbals numeric, p_prsn_id bigint, p_balsDate character varying, p_py_trns_id bigint, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
	v_balsDate character varying(21) := '';
	v_src_trns character varying(21) := '';
BEGIN
	v_balsDate := to_char(to_timestamp(p_balsDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_balsDate := substr(v_balsDate, 1, 10);
	v_dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	v_src_trns := ',';
	IF (p_py_trns_id > 0) THEN
		v_src_trns := ',' || p_py_trns_id || ',';
	END IF;
	INSERT INTO pay.pay_balsitm_bals (bals_itm_id, bals_amount, person_id, bals_date, created_by, creation_date, last_update_by, last_update_date, source_trns_ids)
		VALUES (p_blsitmid, p_netbals, p_prsn_id, v_balsDate, p_who_rn, v_dateStr, p_who_rn, v_dateStr, v_src_trns);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.doesPrsnHvItmPrs (p_prsnid bigint, p_itmid bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		row_id INTO v_res
	FROM
		pasn.prsn_bnfts_cntrbtns
	WHERE ((person_id = p_prsnid)
		AND (item_id = p_itmid));
	RETURN COALESCE(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.doesPrsnHvItm (p_prsnID bigint, p_itmID bigint, p_dateStr character varying, OUT p_strtDte character varying, OUT p_res boolean)
LANGUAGE 'plpgsql'
COST 100 VOLATILE
AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
	rd1 RECORD;
	vCntr integer := 0;
BEGIN
	p_strtDte := '';
	p_res := FALSE;
	v_dateStr := to_char(to_timestamp(p_dateStr, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	FOR rd1 IN
	SELECT
		a.row_id,
		to_char(to_timestamp(valid_start_date || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-MON-YYYY HH24:MI:SS') strtDte
	FROM
		pasn.prsn_bnfts_cntrbtns a
	WHERE ((a.person_id = p_prsnID)
		AND (a.item_id = p_itmID)
		AND (to_timestamp(v_dateStr, 'YYYY-MM-DD HH24:MI:SS') BETWEEN to_timestamp(valid_start_date || ' 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
			AND to_timestamp(valid_end_date || ' 23:59:59', 'YYYY-MM-DD HH24:MI:SS')))
		LOOP
			p_strtDte := rd1.strtDte;
			p_res := rd1.row_id > 0;
			vCntr := vCntr + 1;
		END LOOP;
	IF vCntr <= 0 THEN
		p_strtDte := '';
		p_res := FALSE;
	END IF;

	/*EXCEPTION
	 WHEN OTHERS
	 THEN
	 p_strtDte := '';
	 p_res := FALSE;*/
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.createBnftsPrs (p_prsnid bigint, p_itmid bigint, p_itm_val_id bigint, p_strtdte character varying, p_enddte character varying, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	v_dateStr character varying(21) := '';
	v_strtdte character varying(21) := '';
	v_enddte character varying(21) := '';
BEGIN
	v_dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	v_strtdte := to_char(to_timestamp(p_strtdte, 'DD-Mon-YYYY'), 'YYYY-MM-DD');
	v_enddte := to_char(to_timestamp(p_enddte, 'DD-Mon-YYYY'), 'YYYY-MM-DD');
	INSERT INTO pasn.prsn_bnfts_cntrbtns (person_id, item_id, item_pssbl_value_id, valid_start_date, valid_end_date, created_by, creation_date, last_update_by, last_update_date)
		VALUES (p_prsnid, p_itmid, p_itm_val_id, v_strtdte, v_enddte, p_who_rn, v_dateStr, p_who_rn, v_dateStr);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.doesPrsnHvItm1 (p_prsnID bigint, p_itmID bigint)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		count(a.row_id) INTO v_res
	FROM
		pasn.prsn_bnfts_cntrbtns a
	WHERE ((a.person_id = p_prsnID)
		AND (a.item_id = p_itmID));
	RETURN COALESCE(v_res, 0) > 0;
EXCEPTION
	WHEN OTHERS THEN
		RETURN FALSE;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.willItmBlsBeNgtv (p_prsn_id bigint, p_itm_id bigint, p_pay_amount numeric, p_trns_date character varying, p_org_id integer, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	b_res boolean := FALSE;
	v_tstDte character varying(21) := '';
	v_result1 text := '';
	rd1 RECORD;
	v_nwAmnt numeric := 0;
	v_scaleFctr numeric := 0;
BEGIN
	v_nwAmnt := 0;
	FOR rd1 IN
	SELECT
		a.balance_item_id,
		a.adds_subtracts,
		b.balance_type,
		a.scale_factor,
		C.pssbl_value_id
	FROM
		org.org_pay_itm_feeds a
	LEFT OUTER JOIN org.org_pay_items b ON a.balance_item_id = b.item_id
	LEFT OUTER JOIN org.org_pay_items_values C ON C.item_id = a.balance_item_id
WHERE ((a.fed_by_itm_id = p_itm_id))
ORDER BY
	a.feed_id LOOP
		IF (pay.doesPrsnHvItmPrs (p_prsn_id, rd1.balance_item_id) <= 0) THEN
			v_tstDte := '';
			b_res := FALSE;
			SELECT
				p_strtDte,
				p_res
			FROM
				pay.doesPrsnHvItm (p_prsn_id, p_itm_id, p_trns_date) INTO v_tstDte,
	b_res;
			IF (char_length(v_tstDte) <= 0) THEN
				v_tstDte := '01-Jan-1900 00:00:00';
			END IF;
			v_result1 := pay.createBnftsPrs (p_prsn_id, rd1.balance_item_id, rd1.pssbl_value_id, ('01-' || substr(v_tstDte, 4, 8))::character varying, '31-Dec-4000', p_who_rn);
		END IF;
		v_scaleFctr := rd1.scale_factor;
		IF (rd1.balance_type = 'Cumulative') THEN
			IF (rd1.adds_subtracts = 'Subtracts') THEN
				v_nwAmnt := pay.getBlsItmLtstDailyBals (rd1.balance_item_id, p_prsn_id, p_trns_date, p_org_id) - (p_pay_amount * v_scaleFctr);
			ELSE
				v_nwAmnt := (p_pay_amount * v_scaleFctr) + pay.getBlsItmLtstDailyBals (rd1.balance_item_id, p_prsn_id, p_trns_date, p_org_id);
			END IF;
		ELSE
			IF (rd1.adds_subtracts = 'Subtracts') THEN
				v_nwAmnt := pay.getBlsItmDailyBals (rd1.balance_item_id, p_prsn_id, p_trns_date, p_org_id) - (p_pay_amount * v_scaleFctr);
			ELSE
				v_nwAmnt := (p_pay_amount * v_scaleFctr) + pay.getBlsItmDailyBals (rd1.balance_item_id, p_prsn_id, p_trns_date, p_org_id);
			END IF;
		END IF;
		IF (v_nwAmnt < 0) THEN
			RETURN v_nwAmnt;
		END IF;
	END LOOP;
	RETURN v_nwAmnt;
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getItmValueAmnt (p_itmvalid bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res numeric := 0;
BEGIN
	SELECT
		pssbl_amount INTO v_res
	FROM
		org.org_pay_items_values
	WHERE
		pssbl_value_id = p_itmvalid;
	RETURN COALESCE(v_res, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN COALESCE(v_res, 0);
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getItmValSQL (p_itmvalid bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res text := '';
BEGIN
	SELECT
		pssbl_value_sql INTO v_res
	FROM
		org.org_pay_items_values
	WHERE
		pssbl_value_id = p_itmvalid;
	RETURN COALESCE(v_res, '');
EXCEPTION
	WHEN OTHERS THEN
		RETURN COALESCE(v_res, '');
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getItmValName (p_itmvalid bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res character varying(200) := '';
BEGIN
	SELECT
		pssbl_value_code_name INTO v_res
	FROM
		org.org_pay_items_values
	WHERE
		pssbl_value_id = p_itmvalid;
	RETURN COALESCE(v_res, '');
EXCEPTION
	WHEN OTHERS THEN
		RETURN COALESCE(v_res, '');
END;

$BODY$;


/*CREATE OR REPLACE FUNCTION pay.getPrsBalItmID(
 p_orgid INTEGER)
 RETURNS BIGINT
 LANGUAGE 'plpgsql'
 COST 100
 VOLATILE
 AS $BODY$
 << outerblock >>
 DECLARE
 v_res BIGINT := -1;
 BEGIN
 SELECT item_id INTO v_res FROM org.org_pay_items WHERE is_take_home_pay = '1' AND org_id = p_orgid;
 RETURN COALESCE(v_res, 0);

 EXCEPTION WHEN OTHERS
 THEN
 RETURN COALESCE(v_res, 0);
 END;
 $BODY$;*/
/*CREATE OR REPLACE FUNCTION pay.getItmName(
 p_itmid BIGINT)
 RETURNS CHARACTER VARYING
 LANGUAGE 'plpgsql'
 COST 100
 VOLATILE
 AS $BODY$
 << outerblock >>
 DECLARE
 v_res CHARACTER VARYING(200) := '';
 BEGIN
 SELECT item_code_name INTO v_res FROM org.org_pay_items WHERE item_id = p_itmid;
 RETURN COALESCE(v_res, '');

 EXCEPTION WHEN OTHERS
 THEN
 RETURN COALESCE(v_res, '');
 END;
 $BODY$;*/
CREATE OR REPLACE FUNCTION pay.getItmID (p_itmname character varying, p_orgid integer)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		item_id INTO v_res
	FROM
		org.org_pay_items
	WHERE
		lower(item_code_name) = lower(p_itmname)
		AND org_id = p_orgid;
	RETURN COALESCE(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN COALESCE(v_res, - 1);
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getInvItmID (p_itmname character varying, p_orgid integer)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		item_id INTO v_res
	FROM
		inv.inv_itm_list
	WHERE
		lower(item_code) = lower(p_itmname)
		AND org_id = p_orgid;
	RETURN COALESCE(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN COALESCE(v_res, - 1);
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getItmMinType (p_itmid bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res character varying(200) := '';
BEGIN
	SELECT
		item_min_type INTO v_res
	FROM
		org.org_pay_items
	WHERE
		item_id = p_itmid;
	RETURN COALESCE(v_res, '');
EXCEPTION
	WHEN OTHERS THEN
		RETURN COALESCE(v_res, '');
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getItmMajType (p_itmid bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res character varying(200) := '';
BEGIN
	SELECT
		item_maj_type INTO v_res
	FROM
		org.org_pay_items
	WHERE
		item_id = p_itmid;
	RETURN COALESCE(v_res, '');
EXCEPTION
	WHEN OTHERS THEN
		RETURN COALESCE(v_res, '');
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getItmValID (p_itmvalname character varying, p_itmid bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		pssbl_value_id INTO v_res
	FROM
		org.org_pay_items_values
	WHERE
		lower(pssbl_value_code_name) = lower(p_itmvalname)
		AND item_id = p_itmid;
	RETURN COALESCE(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN COALESCE(v_res, - 1);
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.isItmValSQLValid (p_itemSQL text, p_prsn_id bigint, p_org_id integer, p_dateStr character varying)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res numeric := 0;
	v_nwSQL text := '';
	v_dateStr character varying(21) := '';
BEGIN
	v_dateStr := to_char(to_timestamp(p_dateStr, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_dateStr := substr(v_dateStr, 1, 10);
	v_nwSQL := REPLACE(REPLACE(REPLACE(p_itemSQL, '{:person_id}', '' || p_prsn_id), '{:org_id}', '' || p_org_id), '{:pay_date}', v_dateStr);
	EXECUTE v_nwSQL INTO v_res;
	RETURN TRUE;
EXCEPTION
	WHEN OTHERS THEN
		RETURN FALSE;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.get_ItmAccntInfo (p_itmID bigint, p_prsnID bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res character varying(200) := '';
BEGIN
	v_res := 'Q:-123:Q:-123';
	SELECT
		a.incrs_dcrs_cost_acnt || ':' || org.get_dflt_accnt_id (p_prsnID, a.cost_accnt_id) || ':' || a.incrs_dcrs_bals_acnt || ':' || org.get_dflt_accnt_id (p_prsnID, a.bals_accnt_id) INTO v_res
	FROM
		org.org_pay_items a
	WHERE (a.item_id = p_itmid);
	RETURN COALESCE(v_res, 'Q:-123:Q:-123');
EXCEPTION
	WHEN OTHERS THEN
		RETURN COALESCE(v_res, 'Q:-123:Q:-123');
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.ismspaytrnsvalid (p_itmuom character varying, p_itmmjtyp character varying, p_itmintyp character varying, p_itmid bigint, p_trnsdte character varying, p_pyamnt numeric, p_prsn_id bigint, p_orgid integer, OUT p_errmsgs text, OUT p_result boolean)
	RETURNS record
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res text := '';
	v_netamnt numeric := 0;
	v_accntinf character varying(50)[];
	v_accntinfstr character varying(200) := '';
BEGIN
	IF (p_itmuom != 'Number' AND p_itmmjtyp != 'Balance Item' AND p_itmintyp != 'Purely Informational') THEN
		v_netamnt := 0;
		v_accntinfstr := pay.get_ItmAccntInfo (p_itmid, p_prsn_id);
		v_accntinf := string_to_array(v_accntinfstr, ':');
		IF (coalesce(v_accntinf[2], '0')::integer > 0 AND coalesce(v_accntinf[4], '0')::integer > 0) THEN
			v_netamnt := accb.dbt_or_crdt_accnt_multiplier ((v_accntinf[2])::integer, substr(v_accntinf[1], 1, 1)) * p_pyamnt;
			v_res := accb.istransprmttd (p_orgid, (v_accntinf[2])::integer, p_trnsdte, v_netamnt);
			p_errMsgs := v_res;
			p_result := v_res LIKE 'SUCCESS:%';
		END IF;
	END IF;
	p_errMsgs := v_res;
	p_result := TRUE;
EXCEPTION
	WHEN OTHERS THEN
		p_errMsgs := v_res || ' SQLERRM:' || SQLERRM;
	p_result := FALSE;
END;

$BODY$;

--DROP FUNCTION pay.get_AllItmStDet (p_itmStID integer);
CREATE OR REPLACE FUNCTION pay.get_AllItmStDet (p_itmStID integer)
	RETURNS TABLE (
		item_id bigint,
		item_code_name character varying,
		item_value_uom character varying,
		trns_typ text,
		item_maj_type character varying,
		item_min_type character varying)
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_itmSQL text := '';
	v_mnlSQL text := '';
	v_strSql text := '';
BEGIN
	v_itmSQL := gst.getGnrlRecNm ('pay.pay_itm_sets_hdr', 'hdr_id', 'sql_query', p_itmStID);
	v_strSql := '';
	v_mnlSQL := '';
	v_mnlSQL := 'SELECT a.item_id::bigint, b.item_code_name, b.item_value_uom, ' || 'a.to_do_trnsctn_type::text trns_typ, b.item_maj_type, b.item_min_type ' || 'FROM pay.pay_itm_sets_det a , org.org_pay_items b ' || 'WHERE((a.hdr_id = ' || p_itmStID || ') and (a.item_id = b.item_id) and (b.is_enabled = ''1'')) ORDER BY b.pay_run_priority';
	v_strSql := 'SELECT tbl1.item_id::bigint, tbl1.item_code_name, tbl1.item_value_uom, tbl1.trns_typ::text, a.item_maj_type, a.item_min_type ' || 'FROM (' || v_itmSQL || ') tbl1, org.org_pay_items a ' || 'WHERE ((tbl1.item_id = a.item_id) and (a.is_enabled = ''1'')) ' || 'ORDER BY a.pay_run_priority';
	IF (char_length(v_itmSQL) <= 0) THEN
		v_strSql := v_mnlSQL;
	END IF;
	--RAISE NOTICE ' v_strSql = "%"', v_strSql;
	RETURN QUERY EXECUTE v_strSql;
END;
$BODY$;

--DROP FUNCTION pay.get_allprsstdet (integer);
CREATE OR REPLACE FUNCTION pay.get_AllPrsStDet (p_prsStID integer)
	RETURNS TABLE (
		person_id bigint,
		local_id_no character varying,
		full_name text,
		img_location character varying)
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_prsSQL text := '';
	v_mnlSQL text := '';
	v_strSql text := '';
BEGIN
	v_prsSQL := pay.get_prs_st_sql (p_prsStID);
	v_strSql := '';
	v_mnlSQL := '';
	v_mnlSQL := 'Select distinct a.person_id, a.local_id_no, (trim(a.title || '' '' || a.sur_name || '', '' || a.first_name || '' '' || a.other_names))::text full_name, a.img_location ' || 'from prs.prsn_names_nos a, pay.pay_prsn_sets_det b ' || 'WHERE ((a.person_id = b.person_id) and (b.prsn_set_hdr_id = ' || p_prsStID || ' )) ORDER BY a.local_id_no';
	v_strSql := 'select tbl1.person_id, tbl1.local_id_no, tbl1.full_name::text, tbl1.img_location from (' || v_prsSQL || ') tbl1 ORDER BY tbl1.local_id_no';
	IF (char_length(v_prsSQL) <= 0) THEN
		v_strSql := v_mnlSQL;
	END IF;
	RETURN QUERY EXECUTE v_strSql;
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.getPrsnsInvolved (p_GrpType character varying, p_GrpID bigint, p_wrkPlcID bigint, p_wrkPlcSiteID bigint, p_trnsDate character varying, p_orgid integer, p_msPyPrsStID integer)
	RETURNS TABLE (
		person_id bigint)
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_grpSQL text := '';
	v_dateStr character varying(21) := '';
	v_extrWhr character varying(400) := '';
BEGIN
	v_dateStr := to_char(to_timestamp(p_trnsDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_extrWhr := '';
	IF (p_wrkPlcID > 0) THEN
		v_extrWhr := v_extrWhr || ' and (Select distinct z.lnkd_firm_org_id From prs.prsn_names_nos z where z.person_id=a.person_id)=' || p_wrkPlcID;
	END IF;
	IF (p_wrkPlcSiteID > 0) THEN
		v_extrWhr := v_extrWhr || ' and (Select distinct z.lnkd_firm_site_id From prs.prsn_names_nos z where z.person_id=a.person_id)=' || p_wrkPlcSiteID;
	END IF;
	IF p_msPyPrsStID > 0 THEN
		v_extrWhr := v_extrWhr || ' and (a.person_id IN (select person_id from pay.get_AllPrsStDet(' || p_msPyPrsStID || ')))';
	END IF;

	/*pay.get_AllPrsStDet(v_msPyPrsStID)*/
	v_grpSQL := '';
	IF (p_GrpType = 'Divisions/Groups') THEN
		v_grpSQL := 'Select distinct a.person_id From pasn.prsn_divs_groups a Where ((a.div_id = ' || p_GrpID || ') and (to_timestamp(' || '''' || v_dateStr || '''' || ',''YYYY-MM-DD HH24:MI:SS'') between to_timestamp(a.valid_start_date|| '' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') ' || 'AND to_timestamp(a.valid_end_date || '' 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))' || v_extrWhr || ') ORDER BY a.person_id';
	ELSIF (p_GrpType = 'Grade') THEN
		v_grpSQL := 'Select distinct a.person_id From pasn.prsn_grades a Where ((a.grade_id = ' || p_GrpID || ') and (to_timestamp(' || '''' || v_dateStr || '''' || ',''YYYY-MM-DD HH24:MI:SS'') between to_timestamp(a.valid_start_date|| '' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') ' || 'AND to_timestamp(a.valid_end_date || '' 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))' || v_extrWhr || ') ORDER BY a.person_id';
	ELSIF (p_GrpType = 'Job') THEN
		v_grpSQL := 'Select distinct a.person_id From pasn.prsn_jobs a Where ((a.job_id = ' || p_GrpID || ') and (to_timestamp(' || '''' || v_dateStr || '''' || ',''YYYY-MM-DD HH24:MI:SS'') between to_timestamp(a.valid_start_date|| '' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') ' || 'AND to_timestamp(a.valid_end_date || '' 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))' || v_extrWhr || ') ORDER BY a.person_id';
	ELSIF (p_GrpType = 'Position') THEN
		v_grpSQL := 'Select distinct a.person_id From pasn.prsn_positions a Where ((a.position_id = ' || p_GrpID || ') and (to_timestamp(' || '''' || v_dateStr || '''' || ',''YYYY-MM-DD HH24:MI:SS'') between to_timestamp(a.valid_start_date|| '' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') ' || 'AND to_timestamp(a.valid_end_date || '' 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))' || v_extrWhr || ') ORDER BY a.person_id';
	ELSIF (p_GrpType = 'Site/Location') THEN
		v_grpSQL := 'Select distinct a.person_id From pasn.prsn_locations a Where ((a.location_id = ' || p_GrpID || ') and (to_timestamp(' || '''' || v_dateStr || '''' || ',''YYYY-MM-DD HH24:MI:SS'') between to_timestamp(a.valid_start_date|| '' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') ' || 'AND to_timestamp(a.valid_end_date || '' 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))' || v_extrWhr || ') ORDER BY a.person_id';
	ELSIF (p_GrpType = 'Person Type') THEN
		v_grpSQL := 'Select distinct a.person_id From pasn.prsn_prsntyps a, prs.prsn_names_nos b ' || 'Where ((a.person_id = b.person_id) and (b.org_id = ' || p_orgid || ') and (a.prsn_type =' || '''' || gst.get_pssbl_val (p_GrpID) || '''' || ') and (to_timestamp(' || '''' || v_dateStr || '''' || ',''YYYY-MM-DD HH24:MI:SS'') between to_timestamp(a.valid_start_date|| '' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') ' || 'AND to_timestamp(a.valid_end_date || '' 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))' || v_extrWhr || ') ORDER BY a.person_id';
	ELSIF (p_GrpType = 'Working Hour Type') THEN
		v_grpSQL := 'Select distinct a.person_id From pasn.prsn_work_id a Where ((a.work_hour_id = ' || p_GrpID || ') and (to_timestamp(' || '''' || v_dateStr || '''' || ',''YYYY-MM-DD HH24:MI:SS'') between to_timestamp(a.valid_start_date|| '' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') ' || 'AND to_timestamp(a.valid_end_date || '' 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))' || v_extrWhr || ') ORDER BY a.person_id';
	ELSIF (p_GrpType = 'Gathering Type') THEN
		v_grpSQL := 'Select distinct a.person_id From pasn.prsn_gathering_typs a Where ((a.gatherng_typ_id = ' || p_GrpID || ') and (to_timestamp(' || '''' || v_dateStr || '''' || ',''YYYY-MM-DD HH24:MI:SS'') between to_timestamp(a.valid_start_date|| '' 00:00:00'',''YYYY-MM-DD HH24:MI:SS'') ' || 'AND to_timestamp(a.valid_end_date || '' 23:59:59'',''YYYY-MM-DD HH24:MI:SS''))' || v_extrWhr || ') ORDER BY a.person_id';
	ELSIF (p_GrpType = 'Everyone') THEN
		v_grpSQL := 'Select distinct a.person_id From prs.prsn_names_nos a Where ((a.org_id = ' || p_orgid || ')' || v_extrWhr || ') ORDER BY a.person_id';
	ELSE
		v_grpSQL := 'Select distinct a.person_id From prs.prsn_names_nos a Where ((a.person_id = ' || p_GrpID || ')' || v_extrWhr || ') ORDER BY a.person_id';
	END IF;
	--RAISE NOTICE ' v_grpSQL = "%"', v_grpSQL;
	RETURN QUERY EXECUTE v_grpSQL;
END;
$BODY$;


/*DROP FUNCTION pay.bulkSaveMassPayVals(p_msPyID BIGINT,
 p_shdSkip CHARACTER VARYING, p_who_rn BIGINT);*/
CREATE OR REPLACE FUNCTION pay.invcSaveMassPayItms (p_salesIvcID bigint, p_StoreID bigint, p_who_rn bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_msg text := '';
	v_valSQL text := '';
	v_result1 text := '';
	v_retmsg text := '';
	vRD RECORD;
	rd1 RECORD;
	rd2 RECORD;
	rd4 RECORD;
	rd5 RECORD;
	v_ttlCnt integer := 0;
	v_prsn_id bigint := - 1;
	v_prsn_id1 bigint := - 1;
	v_shdSkip boolean := FALSE;
	p_shdSkip character varying(5) := '';
	v_itmAssgnDte character varying(21) := '';
	v_tstDte character varying(21) := '';
	v_dateStr character varying(21) := '';
	v_trnsDate character varying(21) := '';
	v_GrpType character varying(300) := 'Everyone';
	v_GrpID bigint := - 1;
	v_WrkPlcID bigint := - 1;
	v_WrkPlcSite bigint := - 1;
	v_orgid integer := 0;
	v_payItmAmnt numeric := 0;
	v_AmntGvn numeric := 0;
	v_pay_amount numeric := 0;
	v_ttlAmntLoaded numeric := 0;
	v_outstandgAdvcAmnt numeric := 0;
	v_ValSetDetID bigint := - 1;
	v_advBlsItmID bigint := - 1;
	v_advApplyItmID bigint := - 1;
	v_advApplyItmValID bigint := - 1;
	v_advKeptItmID bigint := - 1;
	v_advKeptItmValID bigint := - 1;
	v_advKeptInvItmID bigint := - 1;
	v_advApplyInvItmID bigint := - 1;
	b_res boolean := FALSE;
	v_msPyGLDate character varying(21) := '';
	v_msPyNm character varying(200) := '';
	v_msPyDesc character varying(300) := '';
	v_msPyPrsStID integer := - 1;
	v_msPyItmStID integer := - 1;
	v_itm_id bigint := - 1;
	v_prs_itm_val_id bigint := - 1;
BEGIN
	IF (p_salesIvcID <= 0) THEN
		v_msg := 'Please select a Saved Invoice First!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
	END IF;
	FOR vRD IN
	SELECT
		invc_hdr_id,
		invc_date,
		created_by,
		creation_date,
		last_update_by,
		last_update_date,
		invc_number,
		invc_type,
		comments_desc,
		src_doc_hdr_id,
		customer_id,
		customer_site_id,
		scm.get_cstmrsplr_lnkdprsnid (customer_id) lnkdprsnid,
		approval_status,
		next_aproval_action,
		org_id,
		receivables_accnt_id,
		payment_terms,
		src_doc_type,
		pymny_method_id,
		invc_curr_id,
		exchng_rate,
		other_mdls_doc_id,
		other_mdls_doc_type,
		enbl_auto_misc_chrges,
		event_rgstr_id,
		evnt_cost_category,
		allow_dues,
		event_doc_type,
		branch_id,
		invoice_clsfctn,
		mspy_amnt_gvn,
		mspy_item_set_id,
		cheque_card_num,
		sign_code,
		mspy_apply_advnc,
		mspy_keep_excess
	FROM
		scm.scm_sales_invc_hdr
	WHERE
		invc_hdr_id = p_salesIvcID LOOP
			v_orgid := vRD.org_id;
			v_msPyNm := '';
			v_msPyDesc := '';
			v_msPyPrsStID := - 1;
			v_msPyItmStID := vRD.mspy_item_set_id;
			v_AmntGvn := vRD.mspy_amnt_gvn;
			IF vrD.lnkdprsnid > 0 THEN
				v_GrpType := 'Single Person';
				v_GrpID := vrD.lnkdprsnid;
				v_WrkPlcID := - 1;
				v_WrkPlcSite := - 1;
			ELSE
				v_GrpType := 'Everyone';
				v_GrpID := - 1;
				v_WrkPlcID := vRD.customer_id;
				v_WrkPlcSite := vRD.customer_site_id;
			END IF;
			v_trnsDate := to_char(to_timestamp(vRD.invc_date || ' 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
			v_msPyGLDate := v_trnsDate;
			v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
			IF (v_msPyItmStID <= 0) THEN
				v_msg := 'Please select a Mass Pay Item Set!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			IF (v_GrpType != 'Everyone' AND v_GrpType != 'Single Person') THEN
				IF (v_GrpID <= 0) THEN
					v_msg := 'Please select a Group Name!';
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
				END IF;
			END IF;
			p_shdSkip := 'NO';
			v_shdSkip := (
				CASE WHEN p_shdSkip = 'YES' THEN
					TRUE
				ELSE
					FALSE
				END);
			IF v_shdSkip = FALSE THEN
				v_itmAssgnDte := v_trnsDate;
			END IF;
			v_advBlsItmID := pay.getItmID ('Total Advance Payments Balance', v_orgid);
			v_advApplyItmID := pay.getItmID ('Advance Payments Amount Applied', v_orgid);
			v_advKeptItmID := pay.getItmID ('Advance Payments Amount Kept', v_orgid);
			v_advApplyItmValID := pay.get_first_itmval_id (v_advApplyItmID);
			v_advKeptItmValID := pay.get_first_itmval_id (v_advKeptItmID);
			v_advKeptInvItmID := pay.getInvItmID ('Advance Payments Amount Kept', v_orgid);
			v_advApplyInvItmID := pay.getInvItmID ('Advance Payments Amount Applied', v_orgid);
			v_payItmAmnt := 0;
			b_res := FALSE;
			--RAISE NOTICE ' v_GrpType = "%"', v_GrpType;
			FOR rd1 IN
			SELECT
				person_id
			FROM
				pay.getPrsnsInvolved (v_GrpType, v_GrpID, v_WrkPlcID, v_WrkPlcSite, v_trnsDate, v_orgid, v_msPyPrsStID)
				LOOP
					--Loop through all items to pay them for this person only
					IF v_ttlCnt = 0 THEN
						v_prsn_id1 := rd1.person_id;
					END IF;
					v_prsn_id := rd1.person_id;
					v_outstandgAdvcAmnt := pay.getBlsItmLtstDailyBals (v_advBlsItmID, rd1.person_id, v_trnsDate, v_orgid);
					--RAISE NOTICE ' v_msPyItmStID = "%"', coalesce(v_msPyItmStID, -1);
					FOR rd2 IN
					SELECT
						a.item_id,
						b.inv_item_id,
						REPLACE(c.item_code || ' (' || c.item_desc || ')', ' (' || c.item_code || ')', '') inv_name,
						c.tax_code_id,
						c.dscnt_code_id,
						c.extr_chrg_id,
						c.inv_asset_acct_id,
						c.sales_rev_accnt_id,
						c.sales_ret_accnt_id,
						c.purch_ret_accnt_id,
						c.expense_accnt_id,
						c.cogs_acct_id,
						a.item_code_name,
						a.item_value_uom,
						a.trns_typ,
						a.item_maj_type,
						a.item_min_type,
						b.allow_value_editing,
						b.uses_sql_formulas
					FROM
						pay.get_AllItmStDet (v_msPyItmStID) a,
	org.org_pay_items b,
	inv.inv_itm_list c
WHERE (a.item_id = b.item_id
	AND b.inv_item_id = c.item_id
	AND b.inv_item_id > 0)
	LOOP
		--v_prsn_id := 1 / 0;
		v_retmsg := 'Do';
		v_itm_id := rd2.item_id;
		v_prs_itm_val_id := pay.getPrsnItmVlID (v_prsn_id, v_itm_id, v_trnsDate);
		b_res := FALSE;
		SELECT
			p_strtDte,
			p_res
		FROM
			pay.doesPrsnHvItm (v_prsn_id, v_itm_id, v_trnsDate) INTO v_tstDte,
	b_res;
		--RAISE NOTICE ' v_prs_itm_val_id = "%"', v_prs_itm_val_id;
		--RAISE NOTICE ' b_res = "%"', b_res;
		IF (v_prs_itm_val_id <= 0 AND v_shdSkip = TRUE) THEN
			v_retmsg := 'Continue';
			v_payItmAmnt := 0;
		ELSIF (v_prs_itm_val_id <= 0
				AND v_shdSkip = FALSE
				AND v_itmAssgnDte != '') THEN
			v_prs_itm_val_id := pay.get_first_itmval_id (v_itm_id);
			IF (v_prs_itm_val_id > 0) THEN
				v_result1 := pay.createBnftsPrs (v_prsn_id, v_itm_id, v_prs_itm_val_id, ('01-' || substr(v_itmAssgnDte, 4, 8))::character varying, '31-Dec-4000', p_who_rn);
			END IF;
		ELSIF (b_res = FALSE) THEN
			v_retmsg := 'Continue';
			v_payItmAmnt := 0;
		END IF;
		v_valSQL := pay.getItmValSQL (v_prs_itm_val_id);
		v_payItmAmnt := 0;
		IF (char_length(v_valSQL) <= 0) THEN
			v_pay_amount := pay.getItmValueAmnt (v_prs_itm_val_id);
		ELSE
			v_pay_amount := pay.exct_itm_valsql (v_valSQL, v_prsn_id, v_orgid, vRD.invc_date || ' 12:00:00');
		END IF;
		v_pay_amount := coalesce(v_pay_amount, 0);
		v_ttlAmntLoaded := v_ttlAmntLoaded + v_pay_amount;
		--RAISE NOTICE ' v_retmsg = "%"', v_retmsg;
		--RAISE NOTICE ' v_ValSetDetID = "%"', v_ValSetDetID;
		IF (v_ttlAmntLoaded > v_AmntGvn AND v_AmntGvn > 0) THEN
			--v_pay_amount := v_ttlAmntLoaded - v_AmntGvn;
			v_pay_amount := v_AmntGvn - (v_ttlAmntLoaded - v_pay_amount);
			IF v_pay_amount <= 0 THEN
				v_pay_amount := 0;
			END IF;
			DELETE FROM scm.scm_sales_invc_det
			WHERE invc_hdr_id = p_salesIvcID
				AND itm_id = rd2.inv_item_id
				AND lnkd_person_id = v_prsn_id;
		END IF;
		SELECT
			invc_det_ln_id INTO v_ValSetDetID
		FROM
			scm.scm_sales_invc_det
		WHERE
			lnkd_person_id = v_prsn_id
			AND itm_id = rd2.inv_item_id
			AND invc_hdr_id = p_salesIvcID;
		IF coalesce(v_ValSetDetID, - 1) <= 0 AND v_retmsg = 'Do' AND v_pay_amount != 0 AND rd2.inv_item_id > 0 THEN
			INSERT INTO scm.scm_sales_invc_det (invc_hdr_id, itm_id, store_id, doc_qty, unit_selling_price, tax_code_id, created_by, creation_date, last_update_by, last_update_date, dscnt_code_id, chrg_code_id, src_line_id, qty_trnsctd_in_dest_doc, crncy_id, rtrn_reason, consgmnt_ids, cnsgmnt_qty_dist, orgnl_selling_price, is_itm_delivered, other_mdls_doc_id, other_mdls_doc_type, extra_desc, lnkd_person_id, alternate_item_name, rented_itm_qty, cogs_acct_id, sales_rev_accnt_id, sales_ret_accnt_id, purch_ret_accnt_id, expense_accnt_id, inv_asset_acct_id)
				VALUES (p_salesIvcID, rd2.inv_item_id, p_StoreID, 1, v_pay_amount, rd2.tax_code_id, p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), rd2.dscnt_code_id, rd2.extr_chrg_id, - 1, 0, vRD.invc_curr_id, '', ',', ',', scm.get_sllng_price_lesstax (rd2.tax_code_id, v_pay_amount), '0', - 1, '', '', v_prsn_id, rd2.inv_name, 1, rd2.cogs_acct_id, rd2.sales_rev_accnt_id, rd2.sales_ret_accnt_id, rd2.purch_ret_accnt_id, rd2.expense_accnt_id, rd2.inv_asset_acct_id);

			/*
			 1. Check if this person has advance amount left
			 2. Insert a line for the advance amount equal to or less than pay_amount
			 */
			IF v_outstandgAdvcAmnt > 0 AND vRD.mspy_apply_advnc = '1' AND rd2.item_min_type != 'Purely Informational' AND v_advApplyInvItmID > 0 THEN
				IF v_outstandgAdvcAmnt < v_pay_amount THEN
					v_pay_amount := v_outstandgAdvcAmnt;
				END IF;
				v_outstandgAdvcAmnt := v_outstandgAdvcAmnt - v_pay_amount;

				/*SELECT
				 invc_det_ln_id INTO v_ValSetDetID
				 FROM
				 scm.scm_sales_invc_det
				 WHERE
				 lnkd_person_id = v_prsn_id
				 AND itm_id = v_advApplyInvItmID
				 AND invc_hdr_id = p_salesIvcID;
				 IF coalesce(v_ValSetDetID, - 1) <= 0 THEN*/
				FOR rd4 IN
				SELECT
					c.item_id,
					REPLACE(c.item_code || ' (' || c.item_desc || ')', ' (' || c.item_code || ')', '') inv_name,
					c.tax_code_id,
					c.dscnt_code_id,
					c.extr_chrg_id,
					c.inv_asset_acct_id,
					c.sales_rev_accnt_id,
					c.sales_ret_accnt_id,
					c.purch_ret_accnt_id,
					c.expense_accnt_id,
					c.cogs_acct_id
				FROM
					inv.inv_itm_list c
				WHERE (c.item_id = v_advApplyInvItmID)
					LOOP
						INSERT INTO scm.scm_sales_invc_det (invc_hdr_id, itm_id, store_id, doc_qty, unit_selling_price, tax_code_id, created_by, creation_date, last_update_by, last_update_date, dscnt_code_id, chrg_code_id, src_line_id, qty_trnsctd_in_dest_doc, crncy_id, rtrn_reason, consgmnt_ids, cnsgmnt_qty_dist, orgnl_selling_price, is_itm_delivered, other_mdls_doc_id, other_mdls_doc_type, extra_desc, lnkd_person_id, alternate_item_name, rented_itm_qty, cogs_acct_id, sales_rev_accnt_id, sales_ret_accnt_id, purch_ret_accnt_id, expense_accnt_id, inv_asset_acct_id)
							VALUES (p_salesIvcID, v_advApplyInvItmID, p_StoreID, 1, - 1 * v_pay_amount, rd4.tax_code_id, p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), rd4.dscnt_code_id, rd4.extr_chrg_id, - 1, 0, vRD.invc_curr_id, '', ',', ',', scm.get_sllng_price_lesstax (rd4.tax_code_id, - 1 * v_pay_amount), '0', - 1, '', '', v_prsn_id, rd4.inv_name, 1, rd4.cogs_acct_id, rd4.sales_rev_accnt_id, rd4.sales_ret_accnt_id, rd4.purch_ret_accnt_id, rd4.expense_accnt_id, rd4.inv_asset_acct_id);
					END LOOP;

				/*END IF;*/
			END IF;
		END IF;
	END LOOP;
					v_ttlCnt := v_ttlCnt + 1;
				END LOOP;

			/*
			 1. After everything if part of amount Given still remains and option to keep advance selected then
			 2. Loop through all persons again and start keeping advance for them
			 */
			IF vRD.mspy_keep_excess = '1' AND (v_ttlAmntLoaded < v_AmntGvn AND v_AmntGvn > 0) THEN
				SELECT
					invc_det_ln_id INTO v_ValSetDetID
				FROM
					scm.scm_sales_invc_det
				WHERE
					lnkd_person_id = v_prsn_id1
					AND itm_id = v_advKeptInvItmID
					AND invc_hdr_id = p_salesIvcID;
				v_pay_amount := v_AmntGvn - v_ttlAmntLoaded;
				IF coalesce(v_ValSetDetID, - 1) <= 0 AND v_retmsg = 'Do' AND v_pay_amount != 0 AND v_pay_amount > 0 AND v_prsn_id1 > 0 AND v_advKeptInvItmID > 0 THEN
					--v_msg := 'v_advKeptInvItmID!:' || v_advKeptInvItmID || '::' || inv.get_invitm_name(v_advKeptInvItmID);
					FOR rd5 IN
					SELECT
						c.item_id,
						REPLACE(c.item_code || ' (' || c.item_desc || ')', ' (' || c.item_code || ')', '') inv_name,
						c.tax_code_id,
						c.dscnt_code_id,
						c.extr_chrg_id,
						c.inv_asset_acct_id,
						c.sales_rev_accnt_id,
						c.sales_ret_accnt_id,
						c.purch_ret_accnt_id,
						c.expense_accnt_id,
						c.cogs_acct_id
					FROM
						inv.inv_itm_list c
					WHERE (c.item_id = v_advKeptInvItmID)
						LOOP
							INSERT INTO scm.scm_sales_invc_det (invc_hdr_id, itm_id, store_id, doc_qty, unit_selling_price, tax_code_id, created_by, creation_date, last_update_by, last_update_date, dscnt_code_id, chrg_code_id, src_line_id, qty_trnsctd_in_dest_doc, crncy_id, rtrn_reason, consgmnt_ids, cnsgmnt_qty_dist, orgnl_selling_price, is_itm_delivered, other_mdls_doc_id, other_mdls_doc_type, extra_desc, lnkd_person_id, alternate_item_name, rented_itm_qty, cogs_acct_id, sales_rev_accnt_id, sales_ret_accnt_id, purch_ret_accnt_id, expense_accnt_id, inv_asset_acct_id)
								VALUES (p_salesIvcID, v_advKeptInvItmID, p_StoreID, 1, v_pay_amount, rd5.tax_code_id, p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), rd5.dscnt_code_id, rd5.extr_chrg_id, - 1, 0, vRD.invc_curr_id, '', ',', ',', scm.get_sllng_price_lesstax (rd5.tax_code_id, v_pay_amount), '0', - 1, '', '', v_prsn_id, rd5.inv_name, 1, rd5.cogs_acct_id, rd5.sales_rev_accnt_id, rd5.sales_ret_accnt_id, rd5.purch_ret_accnt_id, rd5.expense_accnt_id, rd5.inv_asset_acct_id);
						END LOOP;
				END IF;
			END IF;
		END LOOP;
	RETURN 'SUCCESS:Attached Values Loaded Successfully';
EXCEPTION
	WHEN OTHERS THEN
		v_msg := v_msg || ' SQLERRM:' || SQLERRM;
	--RAISE NOTICE ' ERROR = "%"', v_msg;
	RETURN 'ERROR:' || v_msg;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.bulkSaveMassPayVals (p_msPyID bigint, p_who_rn bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_msg text := '';
	v_valSQL text := '';
	v_result1 text := '';
	v_retmsg text := '';
	vRD RECORD;
	rd1 RECORD;
	rd2 RECORD;
	v_ttlCnt integer := 0;
	v_prsn_id integer := - 1;
	v_shdSkip boolean := FALSE;
	p_shdSkip character varying(5) := '';
	v_itmAssgnDte character varying(21) := '';
	v_tstDte character varying(21) := '';
	v_dateStr character varying(21) := '';
	v_trnsDate character varying(21) := '';
	v_GrpType character varying(300) := '';
	v_GrpID bigint := - 1;
	v_WrkPlcID bigint := - 1;
	v_WrkPlcSite bigint := - 1;
	v_orgid integer := 0;
	v_payItmAmnt numeric := 0;
	v_AmntGvn numeric := 0;
	v_pay_amount numeric := 0;
	v_ValSetDetID bigint := - 1;
	v_advBlsItmID bigint := - 1;
	v_advApplyItmID bigint := - 1;
	v_advApplyItmValID bigint := - 1;
	b_res boolean := FALSE;
	v_msPyGLDate character varying(21) := '';
	v_msPyNm character varying(200) := '';
	v_msPyDesc character varying(300) := '';
	v_msPyPrsStID integer := - 1;
	v_msPyItmStID integer := - 1;
	v_itm_id bigint := - 1;
	v_prs_itm_val_id bigint := - 1;
	rd4 RECORD;
	rd5 RECORD;
	rd9 RECORD;
	v_prsn_id1 bigint := - 1;
	v_ttlAmntLoaded numeric := 0;
	v_outstandgAdvcAmnt numeric := 0;
	v_advKeptItmID bigint := - 1;
	v_advKeptItmValID bigint := - 1;
	v_advKeptInvItmID bigint := - 1;
	v_advApplyInvItmID bigint := - 1;
BEGIN
	IF (p_msPyID <= 0) THEN
		v_msg := 'Please select a Mass Pay Run First!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
	END IF;
	IF (pay.hsMsPyBnRun (p_msPyID) = TRUE OR pay.hsMsPyGoneToGL (p_msPyID) = TRUE) THEN
		v_msg := 'Cannot modify a Mass Pay that has been fully run already!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
	END IF;
	UPDATE
		org.org_pay_items_values
	SET
		pssbl_value_sql = ''
	WHERE
		char_length(pssbl_value_sql) > 0
		AND pssbl_value_sql NOT ILIKE '%select%';
	FOR vRD IN
	SELECT
		mass_pay_id,
		mass_pay_name,
		mass_pay_desc,
		created_by,
		creation_date,
		last_update_by,
		last_update_date,
		run_status,
		mass_pay_trns_date,
		prs_st_id,
		itm_st_id,
		org_id,
		sent_to_gl,
		gl_date,
		allwd_group_type,
		allwd_group_value,
		workplace_cstmr_id,
		workplace_cstmr_site_id,
		entered_amnt,
		entered_amt_crncy_id,
		cheque_card_num,
		sign_code,
		is_quick_pay,
		auto_asgn_itms
	FROM
		pay.pay_mass_pay_run_hdr
	WHERE
		mass_pay_id = p_msPyID LOOP
			v_orgid := vRD.org_id;
			v_msPyNm := vRD.mass_pay_name;
			v_msPyDesc := vRD.mass_pay_desc;
			v_msPyPrsStID := vRD.prs_st_id;
			v_msPyItmStID := vRD.itm_st_id;
			v_GrpType := vRD.allwd_group_type;
			v_GrpID := vRD.allwd_group_value::bigint;
			v_WrkPlcID := vRD.workplace_cstmr_id;
			v_WrkPlcSite := vRD.workplace_cstmr_site_id;
			v_AmntGvn := vRD.entered_amnt;
			v_trnsDate := to_char(to_timestamp(vRD.mass_pay_trns_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
			v_msPyGLDate := to_char(to_timestamp(vRD.gl_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
			v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
			IF (v_msPyItmStID <= 0) THEN
				v_msg := 'Please select a Mass Pay Item Set!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			IF (v_GrpType != 'Everyone' AND v_GrpType != 'Single Person') THEN
				IF (v_GrpID <= 0) THEN
					v_msg := 'Please select a Group Name!';
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
				END IF;
			END IF;
			p_shdSkip := (
				CASE WHEN vRD.auto_asgn_itms = '0' THEN
					'YES'
				ELSE
					'NO'
				END);
			v_shdSkip := (
				CASE WHEN p_shdSkip = 'YES' THEN
					TRUE
				ELSE
					FALSE
				END);
			IF v_shdSkip = FALSE THEN
				v_itmAssgnDte := v_trnsDate;
			END IF;
			v_advBlsItmID := pay.getItmID ('Total Advance Payments Balance', v_orgid);
			v_advApplyItmID := pay.getItmID ('Advance Payments Amount Applied', v_orgid);
			v_advKeptItmID := pay.getItmID ('Advance Payments Amount Kept', v_orgid);
			v_advApplyItmValID := pay.get_first_itmval_id (v_advApplyItmID);
			v_advKeptItmValID := pay.get_first_itmval_id (v_advKeptItmID);
			--v_advKeptInvItmID := pay.getInvItmID ('Advance Payments Amount Kept', v_orgid);
			--v_advApplyInvItmID := pay.getInvItmID ('Advance Payments Amount Applied', v_orgid);
			v_payItmAmnt := 0;
			b_res := FALSE;
			--RAISE NOTICE ' v_GrpType = "%"', v_GrpType;
			FOR rd1 IN
			SELECT
				person_id
			FROM
				pay.getPrsnsInvolved (v_GrpType, v_GrpID, v_WrkPlcID, v_WrkPlcSite, v_trnsDate, v_orgid, v_msPyPrsStID)
				LOOP
					IF v_ttlCnt = 0 THEN
						v_prsn_id1 := rd1.person_id;
					END IF;
					--Loop through all items to pay them for this person only
					v_prsn_id := rd1.person_id;
					v_outstandgAdvcAmnt := pay.getBlsItmLtstDailyBals (v_advBlsItmID, rd1.person_id, v_trnsDate, v_orgid);
					--RAISE NOTICE ' v_msPyItmStID = "%"', coalesce(v_msPyItmStID, -1);
					FOR rd2 IN
					SELECT
						a.item_id,
						a.item_code_name,
						a.item_value_uom,
						a.trns_typ,
						a.item_maj_type,
						a.item_min_type,
						b.allow_value_editing,
						b.uses_sql_formulas
					FROM
						pay.get_AllItmStDet (v_msPyItmStID) a,
	org.org_pay_items b
WHERE (a.item_id = b.item_id)
	LOOP
		v_retmsg := 'Do';
		v_itm_id := rd2.item_id;
		v_prs_itm_val_id := pay.getPrsnItmVlID (v_prsn_id, v_itm_id, v_trnsDate);
		b_res := FALSE;
		SELECT
			p_strtDte,
			p_res
		FROM
			pay.doesPrsnHvItm (v_prsn_id, v_itm_id, v_trnsDate) INTO v_tstDte,
	b_res;
		--RAISE NOTICE ' v_prs_itm_val_id = "%"', v_prs_itm_val_id;
		--RAISE NOTICE ' b_res = "%"', b_res;
		IF (v_prs_itm_val_id <= 0 AND v_shdSkip = TRUE) THEN
			v_retmsg := 'Continue';
			v_payItmAmnt := 0;
		ELSIF (v_prs_itm_val_id <= 0
				AND v_shdSkip = FALSE
				AND v_itmAssgnDte != '') THEN
			v_prs_itm_val_id := pay.get_first_itmval_id (v_itm_id);
			IF (v_prs_itm_val_id > 0) THEN
				v_result1 := pay.createBnftsPrs (v_prsn_id, v_itm_id, v_prs_itm_val_id, ('01-' || substr(v_itmAssgnDte, 4, 8))::character varying, '31-Dec-4000', p_who_rn);
			END IF;
		ELSIF (b_res = FALSE) THEN
			v_retmsg := 'Continue';
			v_payItmAmnt := 0;
		END IF;
		v_valSQL := pay.getItmValSQL (v_prs_itm_val_id);
		IF pay.doesPrsnHvPndngRqsts (v_prsn_id, v_itm_id) <= 0 THEN
			v_payItmAmnt := 0;
			IF (char_length(v_valSQL) <= 0) THEN
				v_pay_amount := pay.getItmValueAmnt (v_prs_itm_val_id);
			ELSE
				v_pay_amount := pay.exct_itm_valsql (v_valSQL, v_prsn_id, v_orgid, vRD.mass_pay_trns_date);
			END IF;
			v_pay_amount := coalesce(v_pay_amount, 0);
			v_ttlAmntLoaded := v_ttlAmntLoaded + v_pay_amount;
			IF (v_ttlAmntLoaded > v_AmntGvn AND v_AmntGvn > 0) THEN
				--v_pay_amount := v_ttlAmntLoaded - v_AmntGvn;
				v_pay_amount := v_AmntGvn - (v_ttlAmntLoaded - v_pay_amount);
				IF v_pay_amount <= 0 THEN
					v_pay_amount := 0;
				END IF;
			END IF;
			SELECT
				value_set_det_id INTO v_ValSetDetID
			FROM
				pay.pay_value_sets_det
			WHERE
				person_id = v_prsn_id
				AND item_id = v_itm_id
				AND mass_pay_id = p_msPyID;
			IF coalesce(v_ValSetDetID, - 1) <= 0 AND v_retmsg = 'Do' AND (rd2.allow_value_editing = '1' OR vRD.is_quick_pay = '1') THEN
				INSERT INTO pay.pay_value_sets_det (mass_pay_id, person_id, item_id, value_to_use, created_by, creation_date, last_update_by, last_update_date, itm_pssbl_val_id, date_earned)
					VALUES (p_msPyID, v_prsn_id, v_itm_id, v_pay_amount, p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), v_prs_itm_val_id, '');
			END IF;
			v_ttlCnt := v_ttlCnt + 1;

			/*
			 1. Check if this person has advance amount left
			 2. Insert a line for the advance amount equal to or less than pay_amount
			 */
			/*IF v_outstandgAdvcAmnt > 0 AND vRD.mspy_apply_advnc = '1' AND rd2.item_min_type != 'Purely Informational' AND v_advApplyItmID > 0 THEN
			 IF v_outstandgAdvcAmnt < v_pay_amount THEN
			 v_pay_amount := v_outstandgAdvcAmnt;
			 END IF;
			 v_outstandgAdvcAmnt := v_outstandgAdvcAmnt - v_pay_amount;
			 INSERT INTO pay.pay_value_sets_det (mass_pay_id, person_id, item_id, value_to_use, created_by, creation_date, last_update_by, last_update_date, itm_pssbl_val_id, date_earned)
			 VALUES (p_msPyID, v_prsn_id, v_advApplyItmID, - 1 * v_pay_amount, p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), v_advApplyItmValID, '');
			 END IF;*/
		ELSE
			/*REPEAT LOOP AGAIN FOR ALL OTHER SIMILA REQUESTS*/
			FOR rd9 IN (
				SELECT
					y.pay_request_id,
					y.item_type_id,
					y.creation_date
				FROM
					pay.pay_loan_pymnt_rqsts y,
					pay.loan_pymnt_invstmnt_typs z
				WHERE
					y.item_type_id = z.item_type_id
					AND y.RQSTD_FOR_PERSON_ID = v_prsn_id
					AND (z.main_amnt_itm_id = v_itm_id
						OR v_itm_id IN (
							SELECT
								a.item_id
							FROM
								pay.get_AllItmStDet (z.pay_itm_set_id::integer) a))
						AND y.REQUEST_STATUS = 'Approved'
						AND y.IS_PROCESSED != '1'
					ORDER BY
						pay_request_id ASC)
					LOOP
						v_payItmAmnt := 0;
						IF (char_length(v_valSQL) <= 0) THEN
							v_pay_amount := pay.getItmValueAmnt (v_prs_itm_val_id);
						ELSE
							v_pay_amount := pay.exct_itm_type_sql (v_valSQL, rd9.item_type_id, rd9.pay_request_id, v_prsn_id, v_orgid, vRD.mass_pay_trns_date);
							--pay.exct_itm_valsql (v_valSQL , v_prsn_id , v_orgid , vRD.mass_pay_trns_date);
						END IF;
						v_ttlAmntLoaded := v_ttlAmntLoaded + v_pay_amount;
						IF (v_ttlAmntLoaded > v_AmntGvn AND v_AmntGvn > 0) THEN
							v_pay_amount := v_AmntGvn - (v_ttlAmntLoaded - v_pay_amount);
							IF v_pay_amount <= 0 THEN
								v_pay_amount := 0;
							END IF;
						END IF;
						SELECT
							value_set_det_id INTO v_ValSetDetID
						FROM
							pay.pay_value_sets_det
						WHERE
							person_id = v_prsn_id
							AND item_id = v_itm_id
							AND mass_pay_id = p_msPyID
							AND pay_request_id = rd9.pay_request_id;
						IF coalesce(v_ValSetDetID, - 1) <= 0 AND v_retmsg = 'Do' AND (rd2.allow_value_editing = '1' OR vRD.is_quick_pay = '1') THEN
							INSERT INTO pay.pay_value_sets_det (mass_pay_id, person_id, item_id, value_to_use, created_by, creation_date, last_update_by, last_update_date, itm_pssbl_val_id, date_earned, pay_request_id)
								VALUES (p_msPyID, v_prsn_id, v_itm_id, v_pay_amount, p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), v_prs_itm_val_id, rd9.creation_date, rd9.pay_request_id);
						END IF;
						v_ttlCnt := v_ttlCnt + 1;

						/*
						 1. Check if this person has advance amount left
						 2. Insert a line for the advance amount equal to or less than pay_amount
						 */
						/*IF v_outstandgAdvcAmnt > 0 AND vRD.mspy_apply_advnc = '1' AND rd2.item_min_type != 'Purely Informational' AND v_advApplyItmID > 0 THEN
						 IF v_outstandgAdvcAmnt < v_pay_amount THEN
						 v_pay_amount := v_outstandgAdvcAmnt;
						 END IF;
						 v_outstandgAdvcAmnt := v_outstandgAdvcAmnt - v_pay_amount;
						 INSERT INTO pay.pay_value_sets_det (mass_pay_id, person_id, item_id, value_to_use, created_by, creation_date, last_update_by, last_update_date, itm_pssbl_val_id, date_earned)
						 VALUES (p_msPyID, v_prsn_id, v_advApplyItmID, - 1 * v_pay_amount, p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), v_advApplyItmValID, '');
						 END IF;*/
					END LOOP;
		END IF;
	END LOOP;
				END LOOP;

			/*
			 1. After everything if part of amount Given still remains and option to keep advance selected then
			 2. Loop through all persons again and start keeping advance for them
			 */
			/*IF vRD.mspy_keep_excess = '1' AND (v_ttlAmntLoaded < v_AmntGvn AND v_AmntGvn > 0 AND v_advKeptItmID > 0) THEN
			 SELECT
			 value_set_det_id INTO v_ValSetDetID
			 FROM
			 pay.pay_value_sets_det
			 WHERE
			 person_id = v_prsn_id1
			 AND item_id = v_advKeptItmID
			 AND mass_pay_id = p_msPyID;
			 v_pay_amount := v_AmntGvn - v_ttlAmntLoaded;
			 IF coalesce(v_ValSetDetID, - 1) <= 0 AND v_retmsg = 'Do' AND v_pay_amount != 0 AND v_pay_amount > 0 AND v_prsn_id1 > 0 AND v_advKeptItmID > 0 THEN
			 --v_msg := 'v_advKeptInvItmID!:' || v_advKeptInvItmID || '::' || inv.get_invitm_name(v_advKeptInvItmID);
			 INSERT INTO pay.pay_value_sets_det (mass_pay_id, person_id, item_id, value_to_use, created_by, creation_date, last_update_by, last_update_date, itm_pssbl_val_id, date_earned)
			 VALUES (p_msPyID, v_prsn_id, v_advKeptItmID, - 1 * v_pay_amount, p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), v_advKeptItmValID, '');
			 END IF;
			 END IF;*/
		END LOOP;
	RETURN 'SUCCESS:Attached Values Loaded Successfully';
EXCEPTION
	WHEN OTHERS THEN
		v_msg := v_msg || ' SQLERRM:' || SQLERRM;
	--RAISE NOTICE ' ERROR = "%"', v_msg;
	RETURN 'ERROR:' || v_msg;
END;

$BODY$;

--DROP FUNCTION pay.bulkMassPayRun (p_msPyID bigint, p_itmAssgnDte character varying);
--DROP FUNCTION pay.bulkMassPayRun (p_msPyID bigint, p_who_rn bigint);

CREATE OR REPLACE FUNCTION pay.bulkMassPayRun (p_msPyID bigint, v_msg_id bigint, p_who_rn bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_GrpType character varying(300) := '';
	v_GrpID bigint := - 1;
	v_WrkPlcID bigint := - 1;
	v_WrkPlcSite bigint := - 1;
	v_msg text := '';
	v_result1 text := '';
	v_retmsg text := '';
	vRD RECORD;
	rd1 RECORD;
	rd2 RECORD;
	rd9 RECORD;
	v_ttlCnt integer := 0;
	v_prsn integer := - 1;
	v_shdSkip boolean := FALSE;
	p_shdSkip character varying(5) := '';
	v_itmAssgnDte character varying(21) := '';
	v_dateStr character varying(21) := '';
	v_gldateStr character varying(21) := '';
	v_trDte character varying(21) := '';
	v_trnsDesc character varying(300) := '';
	--v_msg_id            BIGINT                 := -1;
	i integer := 0;
	j integer := 0;
	v_outstandgAdvcAmnt numeric := 0;
	v_ttlAmntLoaded numeric := 0;
	v_payItmAmnt numeric := 0;
	v_AmntGvn numeric := 0;
	v_pay_amount numeric := 0;
	v_ValSetDetID bigint := - 1;
	v_advBlsItmID bigint := - 1;
	v_advApplyItmID bigint := - 1;
	v_advApplyItmValID bigint := - 1;
	v_advKeptItmID bigint := - 1;
	v_advKeptItmValID bigint := - 1;
	v_advKeptInvItmID bigint := - 1;
	v_advApplyInvItmID bigint := - 1;
	v_Reslg bigint := - 1;
	v_advPymnt numeric := 0;
	v_pytrnsamnt numeric := 0;
	v_intfcDbtAmnt numeric := 0;
	v_intfcCrdtAmnt numeric := 0;
	v_prsn_id bigint := - 1;
	v_prsn_id1 bigint := - 1;
	b_res boolean := FALSE;
	v_trnsDate character varying(21) := '';
	v_msPyGLDate character varying(21) := '';
	v_msPyNm character varying(200) := '';
	v_msPyDesc character varying(300) := '';
	v_msPyPrsStID integer := - 1;
	v_msPyItmStID integer := - 1;
	v_orgid integer := - 1;
BEGIN
	UPDATE
		org.org_pay_items_values
	SET
		pssbl_value_sql = ''
	WHERE
		char_length(pssbl_value_sql) <= 7;
	v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
	IF (p_msPyID <= 0) THEN
		v_msg := 'Please select a Mass Pay Run First!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
	END IF;
	IF (pay.hsMsPyBnRun (p_msPyID) = TRUE OR pay.hsMsPyGoneToGL (p_msPyID) = TRUE) THEN
		v_msg := 'Cannot rerun a Mass Pay that has been fully run already!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
	END IF;
	FOR vRD IN
	SELECT
		mass_pay_id,
		mass_pay_name,
		mass_pay_desc,
		created_by,
		creation_date,
		last_update_by,
		last_update_date,
		run_status,
		mass_pay_trns_date,
		prs_st_id,
		itm_st_id,
		org_id,
		sent_to_gl,
		gl_date,
		allwd_group_type,
		allwd_group_value,
		workplace_cstmr_id,
		workplace_cstmr_site_id,
		entered_amnt,
		entered_amt_crncy_id,
		cheque_card_num,
		sign_code,
		is_quick_pay,
		auto_asgn_itms,
		mspy_apply_advnc,
		mspy_keep_excess
	FROM
		pay.pay_mass_pay_run_hdr
	WHERE
		mass_pay_id = p_msPyID LOOP
			v_orgid := vRD.org_id;
			v_msPyNm := vRD.mass_pay_name;
			v_msPyDesc := vRD.mass_pay_desc;
			v_msPyPrsStID := vRD.prs_st_id;
			v_msPyItmStID := vRD.itm_st_id;
			v_GrpType := vRD.allwd_group_type;
			v_GrpID := vRD.allwd_group_value::bigint;
			v_WrkPlcID := vRD.workplace_cstmr_id;
			v_WrkPlcSite := vRD.workplace_cstmr_site_id;
			v_AmntGvn := vRD.entered_amnt;
			v_trnsDate := to_char(to_timestamp(vRD.mass_pay_trns_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
			v_msPyGLDate := to_char(to_timestamp(vRD.gl_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
			v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
			v_result1 := accb.isTransPrmttd (v_orgid, accb.get_DfltCashAcnt (sec.get_usr_prsn_id (p_who_rn), v_orgid), v_msPyGLDate, 200);
			IF (v_result1 NOT LIKE 'SUCCESS:%') THEN
				v_msg := v_result1;
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			IF (char_length(v_trnsDate) <= 0) THEN
				v_msg := 'Please enter a Mass Pay Run Date!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			IF (char_length(v_msPyGLDate) <= 0) THEN
				v_msg := 'Please enter a Mass Pay Run GL Date!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			v_prsn := v_msPyPrsStID;
			IF (v_msPyPrsStID <= 0 AND vRD.is_quick_pay != '1') THEN
				v_msg := 'Please select a Mass Pay Person Set!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			IF (v_GrpID <= 0 AND v_WrkPlcID <= 0 AND vRD.is_quick_pay = '1' AND v_GrpType != 'Everyone') THEN
				v_msg := 'Please select a Group and Group Value for a quick pay!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			IF (v_msPyItmStID <= 0) THEN
				v_msg := 'Please select a Mass Pay Item Set!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			p_shdSkip := (
				CASE WHEN vRD.auto_asgn_itms = '0' THEN
					'YES'
				ELSE
					'NO'
				END);
			v_shdSkip := (
				CASE WHEN p_shdSkip = 'YES' THEN
					TRUE
				ELSE
					FALSE
				END);
			IF v_shdSkip = FALSE AND char_length(v_itmAssgnDte) <= 0 THEN
				v_itmAssgnDte := v_trnsDate;
			END IF;
			v_gldateStr := v_msPyGLDate;
			v_retmsg := '';
			v_outstandgAdvcAmnt := 0;
			v_advBlsItmID := pay.getItmID ('Total Advance Payments Balance', v_orgid);
			v_advApplyItmID := pay.getItmID ('Advance Payments Amount Applied', v_orgid);
			v_advKeptItmID := pay.getItmID ('Advance Payments Amount Kept', v_orgid);
			v_advApplyItmValID := pay.get_first_itmval_id (v_advApplyItmID);
			v_advKeptItmValID := pay.get_first_itmval_id (v_advKeptItmID);
			--v_advKeptInvItmID := pay.getInvItmID ('Advance Payments Amount Kept', v_orgid);
			--v_advApplyInvItmID := pay.getInvItmID ('Advance Payments Amount Applied', v_orgid);
			v_payItmAmnt := 0;
			v_trDte := v_trnsDate;
			i := 0;
			j := 0;
			b_res := FALSE;
			FOR rd1 IN
			SELECT
				a.person_id,
				b.local_id_no,
				trim(b.title || ' ' || b.sur_name || ', ' || b.first_name || ' ' || b.other_names) full_name,
				b.img_location
			FROM
				pay.getPrsnsInvolved (v_GrpType, v_GrpID, v_WrkPlcID, v_WrkPlcSite, v_trnsDate, v_orgid, v_msPyPrsStID) a,
	prs.prsn_names_nos b
WHERE
	a.person_id = b.person_id LOOP
		--Loop through all items to pay them for this person only
		IF v_ttlCnt = 0 THEN
			v_prsn_id1 := rd1.person_id;
		END IF;
		v_prsn_id := rd1.person_id;
		v_outstandgAdvcAmnt := pay.getBlsItmLtstDailyBals (v_advBlsItmID, rd1.person_id, v_trDte, v_orgid);
		FOR rd2 IN
		SELECT
			item_id,
			item_code_name,
			item_value_uom,
			trns_typ,
			item_maj_type,
			item_min_type
		FROM
			pay.get_AllItmStDet (v_msPyItmStID)
			LOOP
				IF (i = 0) THEN
					SELECT
						p_errMsgs,
						p_result
					FROM
						pay.isMsPayTrnsValid (rd2.item_value_uom, rd2.item_maj_type, rd2.item_min_type, rd2.item_id, v_gldateStr, 1000, rd1.person_id, v_orgid) INTO v_msg,
					b_res;
					IF (b_res = FALSE) THEN
						RAISE EXCEPTION
							USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
					END IF;
				END IF;
				v_payItmAmnt := 0;
				IF (v_ttlAmntLoaded >= v_AmntGvn AND v_AmntGvn > 0) THEN
					EXIT;
				END IF;
				SELECT
					*
				FROM
					pay.runMassPay (v_orgid, rd1.person_id, (rd1.full_name || ' (' || rd1.local_id_no || ')')::character varying, rd2.item_id, rd2.item_code_name, rd2.item_value_uom, p_msPyID, v_trnsDate, rd2.trns_typ::character varying, rd2.item_maj_type, rd2.item_min_type, v_msg_id, 'pay.pay_mass_pay_run_msgs', v_dateStr, v_gldateStr, v_shdSkip, v_itmAssgnDte, '', p_who_rn, v_ttlAmntLoaded, v_AmntGvn, v_payItmAmnt) INTO v_payItmAmnt,
	v_retmsg;
				v_ttlAmntLoaded := v_ttlAmntLoaded + v_payItmAmnt;
				IF (v_retmsg LIKE 'Stop:%') THEN
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR', MESSAGE = v_retmsg, HINT = v_retmsg;
				END IF;
				IF (v_outstandgAdvcAmnt > 0 AND vRD.mspy_apply_advnc = '1' AND v_advApplyItmID > 0 AND rd2.item_min_type = 'Bills/Charges') THEN
					v_advPymnt := 0;
					IF (v_payItmAmnt > v_outstandgAdvcAmnt) THEN
						v_advPymnt := round(v_outstandgAdvcAmnt, 4);
						v_outstandgAdvcAmnt := 0;
					ELSE
						v_advPymnt := v_payItmAmnt;
						v_outstandgAdvcAmnt := v_outstandgAdvcAmnt - v_payItmAmnt;
					END IF;
					v_advPymnt := (- 1 * v_advPymnt);
					v_trnsDesc := 'Advance Payments Amount Applied for ' || rd1.local_id_no || ' in settlement of ' || rd2.item_code_name;
					SELECT
						*
					FROM
						pay.runMassPay (v_orgid, rd1.person_id, (rd1.full_name || ' (' || rd1.local_id_no || ')')::character varying, v_advApplyItmID, 'Advance Payments Amount Applied', 'Money', p_msPyID, substr(v_trDte, 1, 12) || substr(v_trDte, 13, 3) || LPAD((j % 60)::text, 2, '0') || ':' || LPAD((j % 60)::text, 2, '0'), 'Payment by Organisation', 'Pay Value Item', 'Earnings', v_msg_id, 'pay.pay_mass_pay_run_msgs', v_dateStr, v_gldateStr, v_shdSkip, v_itmAssgnDte, v_trnsDesc, p_who_rn, v_ttlAmntLoaded, v_AmntGvn, v_advPymnt) INTO v_payItmAmnt,
	v_retmsg;
					--v_Reslg := rpt.updaterptlogmsg(v_msg_id, v_retmsg, v_dateStr, p_who_rn);
					IF (v_retmsg LIKE 'Stop:%') THEN
						RAISE EXCEPTION
							USING ERRCODE = 'RHERR', MESSAGE = v_retmsg, HINT = v_retmsg;
					END IF;
					SELECT
						*
					FROM
						pay.runMassPay (v_orgid, rd1.person_id, (rd1.full_name || ' (' || rd1.local_id_no || ')')::character varying, rd2.item_id, rd2.item_code_name, rd2.item_value_uom, p_msPyID, substr(v_trDte, 1, 12) || substr(v_trDte, 13, 3) || LPAD((j % 60)::text, 2, '0') || ':' || LPAD((j % 60)::text, 2, '0'), rd2.trns_typ::character varying, rd2.item_maj_type, rd2.item_min_type, v_msg_id, 'pay.pay_mass_pay_run_msgs', v_dateStr, v_gldateStr, v_shdSkip, v_itmAssgnDte, '', p_who_rn, v_ttlAmntLoaded, v_AmntGvn, v_advPymnt) INTO v_payItmAmnt,
	v_retmsg;
					--v_Reslg := rpt.updaterptlogmsg(v_msg_id, v_retmsg, v_dateStr, p_who_rn);
					IF (v_retmsg LIKE 'Stop:%') THEN
						RAISE EXCEPTION
							USING ERRCODE = 'RHERR', MESSAGE = v_retmsg, HINT = v_retmsg;
					END IF;
				ELSIF (v_outstandgAdvcAmnt > 0
						AND vRD.mspy_apply_advnc = '1'
						AND v_advApplyItmID > 0
						AND rd2.item_min_type = 'Deductions') THEN
					v_advPymnt := 0;
					IF (v_payItmAmnt > v_outstandgAdvcAmnt) THEN
						v_advPymnt := round(v_outstandgAdvcAmnt, 4);
						v_outstandgAdvcAmnt := 0;
					ELSE
						v_advPymnt := v_payItmAmnt;
						v_outstandgAdvcAmnt := v_outstandgAdvcAmnt - v_payItmAmnt;
					END IF;
					v_advPymnt := (- 1 * v_advPymnt);
					v_trnsDesc := 'Advance Payments Amount Applied for ' || rd1.local_id_no || ' in settlement of ' || rd2.item_code_name;
					SELECT
						*
					FROM
						pay.runMassPay (v_orgid, rd1.person_id, (rd1.full_name || ' (' || rd1.local_id_no || ')')::character varying, v_advApplyItmID, 'Advance Payments Amount Applied', 'Money', p_msPyID, substr(v_trDte, 1, 12) || substr(v_trDte, 13, 3) || LPAD((j % 60)::text, 2, '0') || ':' || LPAD((j % 60)::text, 2, '0'), 'Payment by Organisation', 'Pay Value Item', 'Earnings', v_msg_id, 'pay.pay_mass_pay_run_msgs', v_dateStr, v_gldateStr, v_shdSkip, v_itmAssgnDte, v_trnsDesc, p_who_rn, v_ttlAmntLoaded, v_AmntGvn, v_advPymnt) INTO v_payItmAmnt,
	v_retmsg;
					--v_Reslg := rpt.updaterptlogmsg(v_msg_id, v_retmsg, v_dateStr, p_who_rn);
					IF (v_retmsg LIKE 'Stop:%') THEN
						RAISE EXCEPTION
							USING ERRCODE = 'RHERR', MESSAGE = v_retmsg, HINT = v_retmsg;
					END IF;
				END IF;
				v_ttlCnt := v_ttlCnt + 1;
				j := j + 1;
				IF (v_ttlAmntLoaded >= v_AmntGvn AND v_AmntGvn > 0) THEN
					EXIT;
				END IF;
			END LOOP;
		i := i + 1;
	END LOOP;

			/*
			 1. After everything if part of amount Given still remains and option to keep advance selected then
			 2. Loop through all persons again and start keeping advance for them
			 */
			IF vRD.mspy_keep_excess = '1' AND (v_ttlAmntLoaded < v_AmntGvn AND v_AmntGvn > 0 AND v_advKeptItmID > 0) THEN
				v_payItmAmnt := v_AmntGvn - v_ttlAmntLoaded;
				IF v_payItmAmnt > 0 AND v_prsn_id1 > 0 AND v_advKeptItmID > 0 THEN
					v_trnsDesc := 'Advance Payments Amount Kept for ' || rd1.local_id_no;
					SELECT
						*
					FROM
						pay.runMassPay (v_orgid, rd1.person_id, (rd1.full_name || ' (' || rd1.local_id_no || ')')::character varying, v_advKeptItmID, 'Advance Payments Amount Kept', 'Money', p_msPyID, substr(v_trDte, 1, 12) || substr(v_trDte, 13, 3) || LPAD((j % 60)::text, 2, '0') || ':' || LPAD((j % 60)::text, 2, '0'), 'Payment by Person', 'Pay Value Item', 'Deductions', v_msg_id, 'pay.pay_mass_pay_run_msgs', v_dateStr, v_gldateStr, v_shdSkip, v_itmAssgnDte, v_trnsDesc, p_who_rn, v_ttlAmntLoaded, v_AmntGvn, v_payItmAmnt) INTO v_payItmAmnt,
	v_retmsg;
				END IF;
			END IF;
			v_result1 := pay.chck_n_updt_pay_rqsts (p_msPyID);
		END LOOP;
	v_pytrnsamnt := pay.getMsPyAmntSum (p_msPyID);
	v_intfcDbtAmnt := pay.getMsPyIntfcDbtSum (p_msPyID);
	v_intfcCrdtAmnt := pay.getMsPyIntfcCrdtSum (p_msPyID);
	IF (v_pytrnsamnt = v_intfcCrdtAmnt AND v_pytrnsamnt = v_intfcDbtAmnt AND v_pytrnsamnt != 0) THEN
		v_result1 := pay.updateMsPyStatus (p_msPyID, '1', '1', p_who_rn);
	ELSIF (v_pytrnsamnt != 0) THEN
		v_result1 := pay.updateMsPyStatus (p_msPyID, '1', '0', p_who_rn);
	ELSIF (v_ttlCnt > 0
			AND v_intfcCrdtAmnt = 0) THEN
		v_result1 := pay.updateMsPyStatus (p_msPyID, '1', '1', p_who_rn);
	END IF;
	RETURN 'SUCCESS:Pay Run Completed Successfuly!';
EXCEPTION
	WHEN OTHERS THEN
		v_msg := v_msg || '::' || SQLERRM;
	v_Reslg := rpt.updaterptlogmsg (v_msg_id, v_msg, v_dateStr, p_who_rn);
	RETURN 'ERROR:' || v_msg;
END;

$BODY$;

DROP FUNCTION pay.runMassPay (p_org_id integer, p_prsn_id bigint, p_loc_id_no character varying, p_itm_id bigint, p_itm_name character varying, p_itm_uom character varying, p_mspy_id bigint, p_trns_date character varying, p_trns_typ character varying, p_itm_maj_typ character varying, p_itm_min_typ character varying, p_msg_id bigint, p_log_tbl character varying, p_dateStr character varying, p_glDate character varying, p_shdSkip boolean, p_itmAssgnDte character varying, p_trnsDesc character varying, p_who_rn bigint, OUT p_payItmAmnt numeric, OUT p_retmsg character varying);

DROP FUNCTION pay.runMassPay (p_org_id integer, p_prsn_id bigint, p_loc_id_no character varying, p_itm_id bigint, p_itm_name character varying, p_itm_uom character varying, p_mspy_id bigint, p_trns_date character varying, p_trns_typ character varying, p_itm_maj_typ character varying, p_itm_min_typ character varying, p_msg_id bigint, p_log_tbl character varying, p_dateStr character varying, p_glDate character varying, p_shdSkip boolean, p_itmAssgnDte character varying, p_trnsDesc character varying, p_who_rn bigint, INOUT p_payItmAmnt numeric, OUT p_retmsg character varying);

CREATE OR REPLACE FUNCTION pay.runMassPay (p_org_id integer, p_prsn_id bigint, p_loc_id_no character varying, p_itm_id bigint, p_itm_name character varying, p_itm_uom character varying, p_mspy_id bigint, p_trns_date character varying, p_trns_typ character varying, p_itm_maj_typ character varying, p_itm_min_typ character varying, p_msg_id bigint, p_log_tbl character varying, p_dateStr character varying, p_glDate character varying, p_shdSkip boolean, p_itmAssgnDte character varying, p_trnsDesc character varying, p_who_rn bigint, p_ttlAmntLoaded numeric, p_AmntGvn numeric, INOUT p_payItmAmnt numeric, OUT p_retmsg character varying)
LANGUAGE 'plpgsql'
COST 100 VOLATILE
AS $BODY$
	<< outerblock >>
DECLARE
	v_Reslg bigint := - 1;
	rd1 RECORD;
	rd9 RECORD;
	v_prsnItmRwID bigint := - 1;
	v_dateStr character varying(21) := '';
	v_dteEarned character varying(21) := '';
	v_tstDte character varying(21) := '';
	v_trns_date character varying(21) := '';
	b_res boolean := FALSE;
	v_res1 boolean := FALSE;
	v_dfltVal bigint := - 1;
	v_result1 text := '';
	v_valSQL text := '';
	v_pay_amount numeric := 0;
	v_ttlAmntLoaded1 numeric := 0;
	v_AmntGvn1 numeric := 0;
	v_prs_itm_val_id bigint := - 1;
	v_crncy_id integer := - 1;
	v_crncy_cde character varying(50) := '';
	v_isRetroElmnt character varying(1) := '';
	v_AllwEdit character varying(1) := '';
	v_pay_trns_desc character varying(300) := '';
	v_nwAmnt numeric := 0;
	v_tstPyTrnsID bigint := - 1;
BEGIN
	v_trns_date := to_char(to_timestamp(p_trns_date, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (upper(p_itm_maj_typ) = upper('Balance Item')) THEN
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/> Item:' || p_itm_name || ' Type ' || p_itm_maj_typ, p_dateStr, p_who_rn);
		p_retmsg := 'Continue';
		p_payItmAmnt := 0;
		RETURN;
	END IF;
	v_prsnItmRwID := pay.doesPrsnHvItmPrs (p_prsn_id, p_itm_id);
	--v_trns_date := '';
	b_res := FALSE;
	SELECT
		p_strtDte,
		p_res
	FROM
		pay.doesPrsnHvItm (p_prsn_id, p_itm_id, p_trns_date) INTO v_tstDte,
	b_res;
	IF (v_prsnItmRwID <= 0 AND p_shdSkip = TRUE) THEN
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Person:' || p_loc_id_no || ' does not have Item:' || p_itm_name || ' as at ' || p_trns_date, p_dateStr, p_who_rn);
		p_retmsg := 'Continue';
		p_payItmAmnt := 0;
		RETURN;
	ELSIF (v_prsnItmRwID <= 0
			AND p_shdSkip = FALSE
			AND p_itmAssgnDte != '') THEN
		v_dfltVal := pay.get_first_itmval_id (p_itm_id);
		IF (v_dfltVal > 0) THEN
			v_result1 := pay.createBnftsPrs (p_prsn_id, p_itm_id, v_dfltVal, ('01-' || substr(p_itmAssgnDte, 4, 8))::character varying, '31-Dec-4000', p_who_rn);
		END IF;
	ELSIF (b_res = FALSE) THEN
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Person:' || p_loc_id_no || ' does not have Item:' || p_itm_name || ' as at ' || p_trns_date, p_dateStr, p_who_rn);
		p_retmsg := 'Continue';
		p_payItmAmnt := 0;
		RETURN;
	END IF;
	IF (p_trns_typ = '') THEN
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Transaction Type not Specified for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
		p_retmsg := 'Continue';
		p_payItmAmnt := 0;
		RETURN;
	END IF;
	v_pay_amount := 0;
	v_prs_itm_val_id := pay.getPrsnItmVlID (p_prsn_id, p_itm_id, p_trns_date);
	v_crncy_id := - 1;
	v_crncy_cde := p_itm_uom;
	IF (p_itm_uom = 'Money') THEN
		v_crncy_id := org.get_orgfunc_crncy_id (p_org_id);
		v_crncy_cde := gst.get_pssbl_val (v_crncy_id);
	END IF;
	v_isRetroElmnt := gst.getGnrlRecNm ('org.org_pay_items', 'item_id', 'is_retro_element', p_itm_id);
	v_AllwEdit := gst.getGnrlRecNm ('org.org_pay_items', 'item_id', 'allow_value_editing', p_itm_id);
	v_dteEarned := '';
	v_valSQL := pay.getItmValSQL (v_prs_itm_val_id);
	IF (v_isRetroElmnt = '1') THEN
		FOR rd1 IN
		SELECT
			value_to_use,
			date_earned
		FROM
			pay.pay_value_sets_det
		WHERE ((person_id = p_prsn_id)
			AND (mass_pay_id = p_mspy_id)
			AND (item_id = p_itm_id))
			LOOP
				v_pay_amount := rd1.value_to_use;
				v_dteEarned := rd1.date_earned;
				IF (v_pay_amount = 0) THEN
					v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Person:' || p_loc_id_no || ' Item:' || p_itm_name || ' Value ' || v_pay_amount, p_dateStr, p_who_rn);
					p_retmsg := 'Continue';
					p_payItmAmnt := 0;
					RETURN;
				END IF;
				--Check if a Balance Item will be negative if this trns is done
				v_nwAmnt := pay.willItmBlsBeNgtv (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, p_org_id, p_who_rn);
				IF (v_nwAmnt < 0) THEN
					v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Transaction will cause a Balance Item ' || 'to Have Negative Balance and hence cannot be allowed! Person:' || p_loc_id_no || ' Item: ' || p_itm_name || 'Amount:' || v_nwAmnt || '/' || v_pay_amount || '/' || p_trns_date, p_dateStr, p_who_rn);
					p_retmsg := 'Continue';
					p_payItmAmnt := 0;
					RETURN;
				END IF;
				v_pay_trns_desc := '';
				IF (p_itm_min_typ = 'Earnings' OR p_itm_min_typ = 'Employer Charges') THEN
					IF (char_length(p_trnsDesc) > 0) THEN
						v_pay_trns_desc := p_trnsDesc;
					ELSE
						v_pay_trns_desc := 'Payment of ' || p_itm_name || ' for ' || p_loc_id_no || ' Source Date:' || v_dteEarned;
					END IF;
				ELSIF (p_itm_min_typ = 'Bills/Charges'
						OR p_itm_min_typ = 'Deductions') THEN
					IF (char_length(p_trnsDesc) > 0) THEN
						v_pay_trns_desc := p_trnsDesc;
					ELSE
						v_pay_trns_desc := 'Payment of ' || p_itm_name || ' by ' || p_loc_id_no || ' Source Date:' || v_dteEarned;
					END IF;
				ELSE
					IF (char_length(p_trnsDesc) > 0) THEN
						v_pay_trns_desc := p_trnsDesc;
					ELSE
						v_pay_trns_desc := 'Running of Purely Informational Item ' || p_itm_name || ' for ' || p_loc_id_no || ' Source Date:' || v_dteEarned;
					END IF;
				END IF;
				v_tstPyTrnsID := - 1;
				IF (v_tstPyTrnsID <= 0) THEN
					v_result1 := pay.createPaymntLine (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, 'Mass Pay Run', p_trns_typ, p_mspy_id, v_pay_trns_desc, v_crncy_id, p_dateStr, 'VALID', - 1, p_glDate, v_dteEarned, p_who_rn);
				ELSE
					v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Same Payment has been made for this Person on the same Date already! Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
				END IF;
				--Update Balance Items
				v_result1 := pay.updtBlsItms (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, 'Mass Pay Run', - 1, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);
				v_res1 := TRUE;
				IF org.get_payitm_createsAccntng (p_itm_id) = '1' THEN
					v_res1 := pay.sendToGLInterfaceRetro (p_prsn_id, p_loc_id_no, p_itm_id, p_itm_name, p_itm_uom, v_pay_amount, p_trns_date, v_pay_trns_desc, v_crncy_id, p_msg_id, p_log_tbl, p_dateStr, 'Mass Pay Run', p_glDate, - 1, v_dteEarned, p_who_rn);
				END IF;
				IF (v_res1) THEN
					v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Successfully processed Payment for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
				ELSE
					v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Processing Payment Failed for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
				END IF;
			END LOOP;
		v_pay_amount := COALESCE(v_pay_amount, 0);
		p_payItmAmnt := COALESCE(p_payItmAmnt, 0);
	ELSE
		IF pay.doesPrsnHvPndngRqsts (p_prsn_id, p_itm_id) <= 0 THEN
			IF v_AllwEdit = '1' THEN
				SELECT
					p_dteErnd,
					p_value
				FROM
					pay.getAtchdValPrsnAmnt (p_prsn_id, p_mspy_id, p_itm_id) INTO v_dteEarned,
	v_pay_amount;
			END IF;
			IF (p_payItmAmnt != 0 OR p_itm_name = 'Advance Payments Amount Applied' OR p_itm_name = 'Advance Payments Amount Kept') THEN
				v_pay_amount := p_payItmAmnt;
			ELSIF (char_length(v_valSQL) <= 0) THEN
				IF (coalesce(v_pay_amount, 0) = 0) THEN
					v_pay_amount := pay.getItmValueAmnt (v_prs_itm_val_id);
				END IF;
				p_payItmAmnt := v_pay_amount;
			ELSIF (char_length(v_valSQL) > 0
					AND coalesce(v_pay_amount, 0) = 0) THEN
				v_pay_amount := pay.exct_itm_valsql (v_valSQL, p_prsn_id, p_org_id, v_trns_date);
				p_payItmAmnt := v_pay_amount;
			ELSE
				p_payItmAmnt := COALESCE(v_pay_amount, 0);
			END IF;
			v_pay_amount := COALESCE(v_pay_amount, 0);
			p_payItmAmnt := COALESCE(p_payItmAmnt, 0);
			IF (NOT (p_itm_name = 'Advance Payments Amount Applied' OR p_itm_name = 'Advance Payments Amount Kept')) THEN
				v_ttlAmntLoaded1 := COALESCE(p_ttlAmntLoaded, 0) + p_payItmAmnt;
				v_AmntGvn1 := COALESCE(p_AmntGvn, 0);
				IF (v_ttlAmntLoaded1 > v_AmntGvn1 AND v_AmntGvn1 > 0) THEN
					v_pay_amount := v_AmntGvn1 - (v_ttlAmntLoaded1 - v_pay_amount);
					IF v_pay_amount <= 0 THEN
						v_pay_amount := 0;
					END IF;
					p_payItmAmnt := v_pay_amount;
					v_pay_amount := COALESCE(v_pay_amount, 0);
					p_payItmAmnt := COALESCE(p_payItmAmnt, 0);
				END IF;
			END IF;
			IF (v_pay_amount = 0) THEN
				v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Skipped Zero Value for Person:' || p_loc_id_no || ' Item:' || p_itm_name || ' Value ' || v_pay_amount || ' v_isRetroElmnt:' || v_isRetroElmnt, p_dateStr, p_who_rn);
				p_retmsg := 'Continue';
				p_payItmAmnt := 0;
				RETURN;
			END IF;
			--Check if a Balance Item will be negative if this trns is done
			v_nwAmnt := pay.willItmBlsBeNgtv (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, p_org_id, p_who_rn);
			IF (v_nwAmnt < 0) THEN
				v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Transaction will cause a Balance Item ' || 'to Have Negative Balance and hence cannot be allowed! Person:' || p_loc_id_no || ' Item: ' || p_itm_name || 'Amount:' || v_nwAmnt || '/' || v_pay_amount || '/' || p_trns_date, p_dateStr, p_who_rn);
				p_retmsg := 'Continue';
				p_payItmAmnt := 0;
				RETURN;
			END IF;
			--RAISE NOTICE 'v_nwAmnt RUN 3 %', v_nwAmnt;
			IF (pay.doesPymntDteViolateFreq (p_prsn_id, p_itm_id, p_trns_date) = TRUE) THEN
				v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>The Payment Date violates the ' || 'Item''s Defined Pay Frequency! Person:' || p_loc_id_no || ' Item:' || p_itm_name || ' Payment Date:' || p_trns_date, p_dateStr, p_who_rn);
				p_retmsg := 'Continue';
				p_payItmAmnt := 0;
				RETURN;
			END IF;
			--RAISE NOTICE 'v_nwAmnt RUN 4 %', v_nwAmnt;
			v_pay_trns_desc := '';
			IF (char_length(p_trnsDesc) <= 0) THEN
				IF (p_itm_min_typ = 'Earnings' OR p_itm_min_typ = 'Employer Charges') THEN
					v_pay_trns_desc := 'Payment of ' || p_itm_name || ' for ' || p_loc_id_no;
				ELSIF (p_itm_min_typ = 'Bills/Charges'
						OR p_itm_min_typ = 'Deductions') THEN
					v_pay_trns_desc := 'Payment of ' || p_itm_name || ' by ' || p_loc_id_no;
				ELSE
					v_pay_trns_desc := 'Running of Purely Informational Item ' || p_itm_name || ' for ' || p_loc_id_no;
				END IF;
			ELSE
				v_pay_trns_desc := p_trnsDesc;
			END IF;
			v_tstPyTrnsID := pay.hsPrsnBnPaidItmMsPy (p_prsn_id, p_itm_id, p_trns_date, v_pay_amount);
			IF (v_tstPyTrnsID <= 0) THEN
				v_result1 := pay.createPaymntLine (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, 'Mass Pay Run', p_trns_typ, p_mspy_id, v_pay_trns_desc, v_crncy_id, p_dateStr, 'VALID', - 1, p_glDate, v_dteEarned, p_who_rn);
			ELSE
				v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Same Payment has been made FOR this Person ON the same Date already! Person:' || p_loc_id_no || ' Item:' || p_itm_name, p_dateStr, p_who_rn);
			END IF;
			--Update Balance Items
			--RAISE NOTICE 'updtBlsItms RUN 2 %', v_pay_amount;
			v_result1 := pay.updtBlsItms (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, 'Mass Pay Run', - 1, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);
			--RAISE NOTICE 'sendToGLInterface RUN 2 %', v_pay_amount;
			v_res1 := TRUE;
			IF org.get_payitm_createsAccntng (p_itm_id) = '1' THEN
				v_res1 := pay.sendToGLInterface (p_prsn_id, p_loc_id_no, p_itm_id, p_itm_name, p_itm_uom, v_pay_amount, p_trns_date, v_pay_trns_desc, v_crncy_id, p_msg_id, p_log_tbl, p_dateStr, 'Mass Pay Run', p_glDate, - 1, p_who_rn);
				--RAISE NOTICE 'sendToGLInterface RUN 5 %', v_pay_amount;
			END IF;
			IF (v_res1) THEN
				v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Successfully processed Payment for Person:' || p_loc_id_no || ' Item:' || p_itm_name, p_dateStr, p_who_rn);
			ELSE
				v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Processing Payment Failed for Person:' || p_loc_id_no || ' Item:' || p_itm_name, p_dateStr, p_who_rn);
			END IF;
		ELSE
			/*REPEAT LOOP AGAIN FOR ALL OTHER SIMILA REQUESTS runMassPay*/
			FOR rd9 IN (
				SELECT
					y.pay_request_id,
					y.item_type_id,
					y.creation_date
				FROM
					pay.pay_loan_pymnt_rqsts y,
					pay.loan_pymnt_invstmnt_typs z
				WHERE
					y.item_type_id = z.item_type_id
					AND y.RQSTD_FOR_PERSON_ID = p_prsn_id
					AND (z.main_amnt_itm_id = p_itm_id
						OR p_itm_id IN (
							SELECT
								a.item_id
							FROM
								pay.get_AllItmStDet (z.pay_itm_set_id::integer) a))
						AND y.REQUEST_STATUS = 'Approved'
						AND y.IS_PROCESSED != '1'
						AND z.item_type_name ILIKE substr(p_itm_name, 1, 2) || '%'
					ORDER BY
						pay_request_id ASC)
					LOOP
						p_payItmAmnt := 0;
						v_pay_amount := 0;
						IF v_AllwEdit = '1' THEN
							SELECT
								p_dteErnd,
								p_value
							FROM
								pay.getAtchdValPrsnAmnt2 (p_prsn_id, p_mspy_id, p_itm_id, rd9.pay_request_id) INTO v_dteEarned,
	v_pay_amount;
						END IF;
						IF (p_payItmAmnt != 0 OR p_itm_name = 'Advance Payments Amount Applied' OR p_itm_name = 'Advance Payments Amount Kept') THEN
							v_pay_amount := p_payItmAmnt;
						ELSIF (char_length(v_valSQL) <= 0) THEN
							IF (coalesce(v_pay_amount, 0) = 0) THEN
								v_pay_amount := pay.getItmValueAmnt (v_prs_itm_val_id);
							END IF;
							p_payItmAmnt := v_pay_amount;
						ELSIF (char_length(v_valSQL) > 0
								AND coalesce(v_pay_amount, 0) = 0) THEN
							v_pay_amount := pay.exct_itm_type_sql (v_valSQL, rd9.item_type_id, rd9.pay_request_id, p_prsn_id, p_org_id, v_trns_date);
							--v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>'||v_valSQL||' AMOUNT:'||v_pay_amount|| ' REQUEST ID:' || rd9.pay_request_id, p_dateStr, p_who_rn);
							--v_pay_amount := pay.exct_itm_valsql (v_valSQL, p_prsn_id, p_org_id, v_trns_date);
							p_payItmAmnt := v_pay_amount;
						ELSE
							p_payItmAmnt := COALESCE(v_pay_amount, 0);
						END IF;
						v_pay_amount := COALESCE(v_pay_amount, 0);
						p_payItmAmnt := COALESCE(p_payItmAmnt, 0);
						IF (NOT (p_itm_name = 'Advance Payments Amount Applied' OR p_itm_name = 'Advance Payments Amount Kept')) THEN
							v_ttlAmntLoaded1 := COALESCE(p_ttlAmntLoaded, 0) + p_payItmAmnt;
							v_AmntGvn1 := COALESCE(p_AmntGvn, 0);
							IF (v_ttlAmntLoaded1 > v_AmntGvn1 AND v_AmntGvn1 > 0) THEN
								v_pay_amount := v_AmntGvn1 - (v_ttlAmntLoaded1 - v_pay_amount);
								IF v_pay_amount <= 0 THEN
									v_pay_amount := 0;
								END IF;
								p_payItmAmnt := v_pay_amount;
								v_pay_amount := COALESCE(v_pay_amount, 0);
								p_payItmAmnt := COALESCE(p_payItmAmnt, 0);
							END IF;
						END IF;
						IF (v_pay_amount = 0) THEN
							v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Skipped Zero Value for Person:' || p_loc_id_no || ' Item:' || p_itm_name || ' Value: ' || v_pay_amount || ' REQUEST ID:' || rd9.pay_request_id, p_dateStr, p_who_rn);
							p_retmsg := 'Continue';
							p_payItmAmnt := 0;
							--RETURN;
						END IF;
						--Check if a Balance Item will be negative if this trns is done
						v_nwAmnt := pay.willItmBlsBeNgtv (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, p_org_id, p_who_rn);
						IF (v_nwAmnt < 0) THEN
							v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Transaction will cause a Balance Item ' || 'to Have Negative Balance and hence cannot be allowed! Person:' || p_loc_id_no || ' Item: ' || p_itm_name || 'Amount:' || v_nwAmnt || '/' || v_pay_amount || '/' || p_trns_date || ' REQUEST ID:' || rd9.pay_request_id, p_dateStr, p_who_rn);
							p_retmsg := 'Continue';
							p_payItmAmnt := 0;
							RETURN;
						END IF;
						--RAISE NOTICE 'v_nwAmnt RUN 3 %', v_nwAmnt;
						IF (pay.doesPymntDteViolateFreq (p_prsn_id, p_itm_id, p_trns_date) = TRUE) THEN
							v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>The Payment Date violates the ' || 'Item''s Defined Pay Frequency! Person:' || p_loc_id_no || ' Item:' || p_itm_name || ' Payment Date:' || p_trns_date || ' REQUEST ID:' || rd9.pay_request_id, p_dateStr, p_who_rn);
							p_retmsg := 'Continue';
							p_payItmAmnt := 0;
							RETURN;
						END IF;
						--RAISE NOTICE 'v_nwAmnt RUN 4 %', v_nwAmnt;
						v_pay_trns_desc := '';
						IF (char_length(p_trnsDesc) <= 0) THEN
							IF (p_itm_min_typ = 'Earnings' OR p_itm_min_typ = 'Employer Charges') THEN
								v_pay_trns_desc := 'Payment of ' || p_itm_name || ' for ' || p_loc_id_no || ' REQUEST ID:' || rd9.pay_request_id;
							ELSIF (p_itm_min_typ = 'Bills/Charges'
									OR p_itm_min_typ = 'Deductions') THEN
								v_pay_trns_desc := 'Payment of ' || p_itm_name || ' by ' || p_loc_id_no || ' REQUEST ID:' || rd9.pay_request_id;
							ELSE
								v_pay_trns_desc := 'Running of Purely Informational Item ' || p_itm_name || ' for ' || p_loc_id_no || ' REQUEST ID:' || rd9.pay_request_id;
							END IF;
						ELSE
							v_pay_trns_desc := p_trnsDesc || ' REQUEST ID:' || rd9.pay_request_id;
						END IF;
						--|| ' REQUEST ID:' || rd9.pay_request_id
						v_tstPyTrnsID := pay.hsPrsnBnPaidItmMsPy2 (p_prsn_id, p_itm_id, p_trns_date, v_pay_amount, rd9.pay_request_id);
						IF (v_tstPyTrnsID <= 0) THEN
							v_result1 := pay.createPaymntLine3 (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, 'Mass Pay Run', p_trns_typ, p_mspy_id, v_pay_trns_desc, v_crncy_id, p_dateStr, 'VALID', - 1, p_glDate, v_dteEarned, p_who_rn, rd9.pay_request_id);
						ELSE
							v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Same Payment has been made FOR this Person ON the same Date already! Person:' || p_loc_id_no || ' Item:' || p_itm_name || ' REQUEST ID:' || rd9.pay_request_id, p_dateStr, p_who_rn);
						END IF;
						--Update Balance Items
						--RAISE NOTICE 'updtBlsItms RUN 2 %', v_pay_amount;
						v_result1 := pay.updtBlsItms (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, 'Mass Pay Run', - 1, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);
						--RAISE NOTICE 'sendToGLInterface RUN 2 %', v_pay_amount;
						v_res1 := TRUE;
						IF org.get_payitm_createsAccntng (p_itm_id) = '1' THEN
							v_res1 := pay.sendToGLInterface (p_prsn_id, p_loc_id_no, p_itm_id, p_itm_name, p_itm_uom, v_pay_amount, p_trns_date, v_pay_trns_desc, v_crncy_id, p_msg_id, p_log_tbl, p_dateStr, 'Mass Pay Run', p_glDate, - 1, p_who_rn);
							--RAISE NOTICE 'sendToGLInterface RUN 5 %', v_pay_amount;
						END IF;
						IF (v_res1) THEN
							v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Successfully processed Payment for Person:' || p_loc_id_no || ' Item:' || p_itm_name || ' REQUEST ID:' || rd9.pay_request_id, p_dateStr, p_who_rn);
						ELSE
							v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Processing Payment Failed for Person:' || p_loc_id_no || ' Item:' || p_itm_name || ' REQUEST ID:' || rd9.pay_request_id, p_dateStr, p_who_rn);
						END IF;
					END LOOP;
		END IF;
	END IF;
	p_retmsg := '';
	p_payItmAmnt := v_pay_amount;
	RETURN;
EXCEPTION
	WHEN OTHERS THEN
		RAISE NOTICE 'SQLERRM RUN %', SQLERRM;
	p_retmsg := 'Stop:Processing Payment Failed for Person:' || p_loc_id_no || ' Item:' || p_itm_name || ' ERRMSG:' || SQLERRM;
	p_payItmAmnt := 0;
	RETURN;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.createNRunMassPayInvc (p_invoice_id bigint, p_payment_date character varying, p_pay_amnt_gvn numeric, p_who_rn bigint, OUT p_msPyID bigint, OUT p_retmsg character varying)
LANGUAGE 'plpgsql'
COST 100 VOLATILE
AS $BODY$
	<< outerblock >>
DECLARE
	v_GrpType character varying(200) := '';
	v_GrpID bigint := - 1;
	v_WrkPlcID bigint := - 1;
	v_WrkPlcSite bigint := - 1;
	v_msg text := '';
	v_result1 text := '';
	v_retmsg text := '';
	vRD RECORD;
	rd1 RECORD;
	rd2 RECORD;
	rd3 RECORD;
	v_ttlCnt integer := 0;
	v_prsn integer := - 1;
	v_shdSkip boolean := FALSE;
	p_shdSkip character varying(5) := '';
	v_itmAssgnDte character varying(21) := '';
	v_dateStr character varying(21) := '';
	v_gldateStr character varying(21) := '';
	v_trDte character varying(21) := '';
	v_trnsDesc character varying(300) := '';
	v_msg_id bigint := - 1;
	i integer := 0;
	j integer := 0;
	v_ttlAmntLoaded numeric := 0;
	v_outstandgAdvcAmnt numeric := 0;
	v_payItmAmnt numeric := 0;
	v_AmntGvn numeric := 0;
	v_pay_amount numeric := 0;
	v_ValSetDetID bigint := - 1;
	v_Reslg bigint := - 1;
	v_advPymnt numeric := 0;
	v_pytrnsamnt numeric := 0;
	v_intfcDbtAmnt numeric := 0;
	v_intfcCrdtAmnt numeric := 0;
	v_advBlsItmID bigint := - 1;
	v_advApplyItmID bigint := - 1;
	v_advApplyItmValID bigint := - 1;
	b_res boolean := FALSE;
	v_trnsDate character varying(21) := '';
	v_msPyGLDate character varying(21) := '';
	v_msPyNm character varying(200) := '';
	v_msPyDesc character varying(300) := '';
	v_msPyPrsStID integer := - 1;
	v_msPyItmStID integer := - 1;
	v_orgid integer := - 1;
	v_gnrtdTrnsNo1 character varying(200) := '';
	v_dte character varying(21) := '';
	v_usrTrnsCode character varying(100) := '';
BEGIN
	UPDATE
		org.org_pay_items_values
	SET
		pssbl_value_sql = ''
	WHERE
		char_length(pssbl_value_sql) <= 7;
	v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
	IF (p_invoice_id <= 0) THEN
		v_msg := 'Please select a Sales Invoice First!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
	END IF;
	FOR rd3 IN
	SELECT
		invc_hdr_id,
		invc_date,
		created_by,
		creation_date,
		last_update_by,
		last_update_date,
		invc_number,
		invc_type,
		comments_desc,
		src_doc_hdr_id,
		customer_id,
		customer_site_id,
		scm.get_cstmrsplr_lnkdprsnid (customer_id) lnkdprsnid,
		approval_status,
		next_aproval_action,
		org_id,
		receivables_accnt_id,
		payment_terms,
		src_doc_type,
		pymny_method_id,
		invc_curr_id,
		exchng_rate,
		other_mdls_doc_id,
		other_mdls_doc_type,
		enbl_auto_misc_chrges,
		event_rgstr_id,
		evnt_cost_category,
		allow_dues,
		event_doc_type,
		branch_id,
		invoice_clsfctn,
		mspy_amnt_gvn,
		mspy_item_set_id,
		cheque_card_num,
		sign_code,
		mspy_apply_advnc,
		mspy_keep_excess
	FROM
		scm.scm_sales_invc_hdr
	WHERE
		invc_hdr_id = p_invoice_id
		AND allow_dues = '1' LOOP
			v_orgid := rd3.org_id;
			v_usrTrnsCode := gst.getGnrlRecNm ('sec.sec_users', 'user_id', 'code_for_trns_nums', p_who_rn);
			IF (char_length(v_usrTrnsCode) <= 0) THEN
				v_usrTrnsCode := 'XX';
			END IF;
			v_dte := to_char(now(), 'YYMMDD');
			v_gnrtdTrnsNo1 := 'QPINV-' || v_usrTrnsCode || '-' || v_dte || '-';
			v_msPyNm := v_gnrtdTrnsNo1 || lpad(((gst.getRecCount_LstNum ('pay.pay_mass_pay_run_hdr', 'mass_pay_name', 'mass_pay_id', v_gnrtdTrnsNo1 || '%') + 1) || ''), 3, '0');
			p_msPyID := gst.getGnrlRecID1 ('pay.pay_mass_pay_run_hdr', 'mass_pay_name', 'mass_pay_id', v_msPyNm, rd3.org_id);
			v_AmntGvn := p_pay_amnt_gvn;
			v_ttlAmntLoaded := 0;
			v_msPyDesc := substring(v_msPyNm || ' ' || rd3.comments_desc || ' (' || rd3.invc_number || ')', 1, 299);
			v_msPyPrsStID := - 1;
			v_msPyItmStID := rd3.mspy_item_set_id;
			v_trnsDate := p_payment_date;
			v_msPyGLDate := p_payment_date;
			v_result1 := accb.isTransPrmttd (v_orgid, accb.get_DfltCashAcnt (sec.get_usr_prsn_id (p_who_rn), v_orgid), v_msPyGLDate, 200);
			IF (v_result1 NOT LIKE 'SUCCESS:%') THEN
				v_msg := v_result1;
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			IF rd3.lnkdprsnid > 0 THEN
				v_GrpType := 'Single Person';
				v_GrpID := rd3.lnkdprsnid;
				v_WrkPlcID := - 1;
				v_WrkPlcSite := - 1;
			ELSE
				v_GrpType := 'Everyone';
				v_GrpID := - 1;
				v_WrkPlcID := rd3.customer_id;
				v_WrkPlcSite := rd3.customer_site_id;
			END IF;
			IF coalesce(p_msPyID, 0) <= 0 THEN
				v_result1 := pay.createmspy2 (rd3.org_id, substring(v_msPyNm, 1, 199), v_msPyDesc, v_trnsDate, - 1, rd3.mspy_item_set_id, v_msPyGLDate, p_who_rn, substring(v_GrpType, 1, 199), substring('' || v_GrpID, 1, 199), v_WrkPlcID, v_WrkPlcSite, v_AmntGvn, rd3.invc_curr_id, substring(rd3.cheque_card_num, 1, 49), substring(rd3.sign_code, 1, 199), '1', '1', rd3.mspy_apply_advnc, rd3.mspy_keep_excess);
				IF (v_result1 NOT LIKE 'SUCCESS:%') THEN
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR', MESSAGE = v_result1, HINT = v_result1;
				END IF;
				p_msPyID := gst.getGnrlRecID1 ('pay.pay_mass_pay_run_hdr', 'mass_pay_name', 'mass_pay_id', v_msPyNm, rd3.org_id);
			END IF;
			IF (p_msPyID <= 0) THEN
				v_msg := 'Please select a Mass Pay Run First!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			IF (pay.hsMsPyBnRun (p_msPyID) = TRUE OR pay.hsMsPyGoneToGL (p_msPyID) = TRUE) THEN
				v_msg := 'Cannot rerun a Mass Pay that has been fully run already!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			IF (char_length(v_trnsDate) <= 0) THEN
				v_msg := 'Please enter a Mass Pay Run Date!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			IF (char_length(v_msPyGLDate) <= 0) THEN
				v_msg := 'Please enter a Mass Pay Run GL Date!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			v_prsn := v_msPyPrsStID;
			IF (v_GrpID <= 0 AND v_WrkPlcID <= 0 AND v_GrpType != 'Everyone') THEN
				v_msg := 'Please select a Group and Group Value for a quick pay!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			IF (v_msPyItmStID <= 0) THEN
				v_msg := 'Please select a Mass Pay Item Set!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			p_shdSkip := 'NO';
			v_shdSkip := (
				CASE WHEN p_shdSkip = 'YES' THEN
					TRUE
				ELSE
					FALSE
				END);
			IF v_shdSkip = FALSE AND char_length(v_itmAssgnDte) <= 0 THEN
				v_itmAssgnDte := v_trnsDate;
			END IF;
			v_gldateStr := v_msPyGLDate;
			v_msg_id := gst.getLogMsgID ('pay.pay_mass_pay_run_msgs', 'Mass Pay Run', p_msPyID);
			IF (v_msg_id <= 0) THEN
				v_result1 := gst.createLogMsg (v_dateStr || ' .... Mass Pay Run is about to Start...', 'pay.pay_mass_pay_run_msgs', 'Mass Pay Run', p_msPyID, v_dateStr, p_who_rn);
				v_msg_id := gst.getLogMsgID ('pay.pay_mass_pay_run_msgs', 'Mass Pay Run', p_msPyID);
			END IF;
			IF (v_msg_id <= 0) THEN
				v_msg := 'Log Message ID could not be created!';
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
			END IF;
			v_retmsg := '';
			v_outstandgAdvcAmnt := 0;
			v_advBlsItmID := pay.getItmID ('Total Advance Payments Balance', v_orgid);
			v_advApplyItmID := pay.getItmID ('Advance Payments Amount Applied', v_orgid);
			v_advApplyItmValID := pay.get_first_itmval_id (v_advApplyItmID);
			v_payItmAmnt := 0;
			v_trDte := v_trnsDate;
			i := 0;
			j := 0;
			b_res := FALSE;
			FOR rd2 IN
			SELECT
				sid.invc_det_ln_id,
				sid.invc_hdr_id,
				sid.itm_id,
				sid.store_id,
				sid.doc_qty,
				sid.unit_selling_price,
				sid.tax_code_id,
				sid.created_by,
				sid.creation_date,
				sid.last_update_by,
				sid.last_update_date,
				sid.dscnt_code_id,
				sid.chrg_code_id,
				sid.src_line_id,
				sid.qty_trnsctd_in_dest_doc,
				sid.crncy_id,
				sid.rtrn_reason,
				sid.consgmnt_ids,
				sid.cnsgmnt_qty_dist,
				sid.orgnl_selling_price,
				sid.is_itm_delivered,
				sid.other_mdls_doc_id,
				sid.other_mdls_doc_type,
				sid.extra_desc,
				sid.lnkd_person_id,
				sid.alternate_item_name,
				sid.rented_itm_qty,
				sid.cogs_acct_id,
				sid.sales_rev_accnt_id,
				sid.sales_ret_accnt_id,
				sid.purch_ret_accnt_id,
				sid.expense_accnt_id,
				sid.inv_asset_acct_id,
				opi.item_id,
				opi.item_code_name,
				opi.item_value_uom,
				(
					CASE WHEN opi.item_min_type = 'Earnings'
						OR opi.item_min_type = 'Employer Charges' THEN
						'Payment by Organisation'
					WHEN opi.item_min_type = 'Bills/Charges'
						OR opi.item_min_type = 'Deductions' THEN
						'Payment by Person'
					ELSE
						'Purely Informational'
					END) trns_typ,
				opi.item_maj_type,
				opi.item_min_type
			FROM
				scm.scm_sales_invc_det sid
			LEFT OUTER JOIN org.org_pay_items opi ON (sid.itm_id = opi.inv_item_id)
	WHERE
		invc_hdr_id = p_invoice_id
		AND opi.inv_item_id > 0 LOOP
			IF (i = 0) THEN
				SELECT
					p_errMsgs,
					p_result
				FROM
					pay.isMsPayTrnsValid (rd2.item_value_uom, rd2.item_maj_type, rd2.item_min_type, rd2.item_id, v_gldateStr, 1000, rd2.lnkd_person_id, v_orgid) INTO v_msg,
		b_res;
				IF (b_res = FALSE) THEN
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR', MESSAGE = v_msg, HINT = v_msg;
				END IF;
			END IF;
			v_payItmAmnt := 0;
			SELECT
				sum(pit.amount_paid) INTO v_payItmAmnt
			FROM
				pay.pay_itm_trnsctns pit
			WHERE (pit.invc_det_ln_id = rd2.invc_det_ln_id
				AND pit.invc_det_ln_id > 0
				AND pit.src_py_trns_id <= 0
				AND pit.pymnt_vldty_status = 'VALID');
			v_payItmAmnt := rd2.unit_selling_price - coalesce(v_payItmAmnt, 0);

			/*IF (v_AmntGvn - coalesce(v_payItmAmnt, 0)) <= 0 THEN
			 v_payItmAmnt := v_AmntGvn;
			 END IF;*/
			IF (v_ttlAmntLoaded >= v_AmntGvn AND v_AmntGvn > 0) THEN
				EXIT;
			END IF;
			IF (v_payItmAmnt != 0) THEN
				SELECT
					*
				FROM
					pay.runMassPayInvc (v_orgid, rd2.lnkd_person_id, (prs.get_prsn_name (rd2.lnkd_person_id) || ' (' || prs.get_prsn_loc_id (rd2.lnkd_person_id) || ')')::character varying, rd2.item_id, rd2.item_code_name, rd2.item_value_uom, p_msPyID, v_trnsDate, rd2.trns_typ::character varying, rd2.item_maj_type, rd2.item_min_type, v_msg_id, 'pay.pay_mass_pay_run_msgs', v_dateStr, v_gldateStr, v_shdSkip, v_itmAssgnDte, '', p_who_rn, p_invoice_id, - 1, rd2.invc_det_ln_id, v_payItmAmnt) INTO v_payItmAmnt,
	v_retmsg;
				v_ttlAmntLoaded := v_ttlAmntLoaded + coalesce(v_payItmAmnt, 0);
				--v_AmntGvn := v_AmntGvn - coalesce(v_payItmAmnt, 0);
				IF (v_retmsg LIKE 'Stop:%') THEN
					RAISE EXCEPTION
						USING ERRCODE = 'RHERR', MESSAGE = v_retmsg, HINT = v_retmsg;
				END IF;
				v_ttlCnt := v_ttlCnt + 1;
				IF (v_ttlAmntLoaded >= v_AmntGvn AND v_AmntGvn > 0) THEN
					EXIT;
				END IF;
			END IF;
		END LOOP;
		END LOOP;
	v_pytrnsamnt := pay.getMsPyAmntSum (p_msPyID);
	v_intfcDbtAmnt := 0;
	v_intfcCrdtAmnt := 0;
	IF (v_ttlCnt > 0 AND v_intfcCrdtAmnt = 0) THEN
		v_result1 := pay.updateMsPyStatus (p_msPyID, '1', '1', p_who_rn);
	END IF;
	p_retmsg := 'SUCCESS:Pay Run from Invoice Completed Successfuly!';
EXCEPTION
	WHEN OTHERS THEN
		v_msg := v_msg || '::' || SQLERRM || ':v_result1:' || v_result1;
	p_retmsg := 'ERROR:MASSPAY:' || v_msg;
	v_Reslg := gst.updatelogmsg (v_msg_id, v_msg, 'pay.pay_mass_pay_run_msgs', v_dateStr, p_who_rn);
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.runMassPayInvc (p_org_id integer, p_prsn_id bigint, p_loc_id_no character varying, p_itm_id bigint, p_itm_name character varying, p_itm_uom character varying, p_mspy_id bigint, p_trns_date character varying, p_trns_typ character varying, p_itm_maj_typ character varying, p_itm_min_typ character varying, p_msg_id bigint, p_log_tbl character varying, p_dateStr character varying, p_glDate character varying, p_shdSkip boolean, p_itmAssgnDte character varying, p_trnsDesc character varying, p_who_rn bigint, p_sales_invoice_id bigint, p_leave_of_absence_id bigint, p_invc_det_ln_id bigint, p_pay_amount numeric, OUT p_payItmAmnt numeric, OUT p_retmsg character varying)
LANGUAGE 'plpgsql'
COST 100 VOLATILE
AS $BODY$
	<< outerblock >>
DECLARE
	v_Reslg bigint := - 1;
	rd1 RECORD;
	v_prsnItmRwID bigint := - 1;
	v_dateStr character varying(21) := '';
	v_dteEarned character varying(21) := '';
	v_tstDte character varying(21) := '';
	v_trns_date character varying(21) := '';
	b_res boolean := FALSE;
	v_res1 boolean := FALSE;
	v_dfltVal bigint := - 1;
	v_result1 text := '';
	v_valSQL text := '';
	v_pay_amount numeric := 0;
	v_prs_itm_val_id bigint := - 1;
	v_crncy_id integer := - 1;
	v_crncy_cde character varying(50) := '';
	v_isRetroElmnt character varying(1) := '';
	v_pay_trns_desc character varying(300) := '';
	v_nwAmnt numeric := 0;
	v_tstPyTrnsID bigint := - 1;
BEGIN
	v_trns_date := to_char(to_timestamp(p_trns_date, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	p_payItmAmnt := p_pay_amount;
	v_pay_amount := p_pay_amount;
	IF (upper(p_itm_maj_typ) = upper('Balance Item')) THEN
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/> Item:' || p_itm_name || ' Type ' || p_itm_maj_typ, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
		p_retmsg := 'Continue';
		p_payItmAmnt := 0;
		RETURN;
	END IF;
	v_prsnItmRwID := pay.doesPrsnHvItmPrs (p_prsn_id, p_itm_id);
	--v_trns_date := '';
	b_res := FALSE;
	SELECT
		p_strtDte,
		p_res
	FROM
		pay.doesPrsnHvItm (p_prsn_id, p_itm_id, p_trns_date) INTO v_tstDte,
	b_res;
	IF (v_prsnItmRwID <= 0 AND p_shdSkip = TRUE) THEN
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Person:' || p_loc_id_no || ' does not have Item:' || p_itm_name || ' as at ' || p_trns_date, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
		p_retmsg := 'Continue';
		p_payItmAmnt := 0;
		RETURN;
	ELSIF (v_prsnItmRwID <= 0
			AND p_shdSkip = FALSE
			AND p_itmAssgnDte != '') THEN
		v_dfltVal := pay.get_first_itmval_id (p_itm_id);
		IF (v_dfltVal > 0) THEN
			v_result1 := pay.createBnftsPrs (p_prsn_id, p_itm_id, v_dfltVal, ('01-' || substr(p_itmAssgnDte, 4, 8))::character varying, '31-Dec-4000', p_who_rn);
		END IF;
	ELSIF (b_res = FALSE) THEN
		/*v_result1 := gst.updateLogMsg(p_msg_id,
		 '<br/>Person:' || p_loc_id_no || ' does not have Item:' || p_itm_name || ' as at ' ||
		 p_trns_date, p_log_tbl, p_dateStr, p_who_rn);*/
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Person:' || p_loc_id_no || ' does not have Item:' || p_itm_name || ' as at ' || p_trns_date, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
		p_retmsg := 'Continue';
		p_payItmAmnt := 0;
		RETURN;
	END IF;
	IF (p_trns_typ = '') THEN
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Transaction Type not Specified for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
		p_retmsg := 'Continue';
		p_payItmAmnt := 0;
		RETURN;
	END IF;
	v_pay_amount := p_pay_amount;
	v_prs_itm_val_id := pay.getPrsnItmVlID (p_prsn_id, p_itm_id, p_trns_date);
	v_crncy_id := - 1;
	v_crncy_cde := p_itm_uom;
	IF (p_itm_uom = 'Money') THEN
		v_crncy_id := org.get_orgfunc_crncy_id (p_org_id);
		v_crncy_cde := gst.get_pssbl_val (v_crncy_id);
	END IF;
	v_isRetroElmnt := gst.getGnrlRecNm ('org.org_pay_items', 'item_id', 'is_retro_element', p_itm_id);
	v_dteEarned := '';
	v_valSQL := pay.getItmValSQL (v_prs_itm_val_id);
	v_pay_amount := p_payItmAmnt;
	v_pay_amount := COALESCE(v_pay_amount, 0);
	p_payItmAmnt := COALESCE(p_payItmAmnt, 0);
	--RAISE NOTICE 'v_pay_amount RUN 2 %', v_pay_amount;
	IF (v_pay_amount = 0) THEN
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Person:' || p_loc_id_no || ' Item:' || p_itm_name || ' Value ' || v_pay_amount || ' v_isRetroElmnt:' || v_isRetroElmnt, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
		p_retmsg := 'Continue';
		p_payItmAmnt := 0;
		RETURN;
	END IF;
	--Check if a Balance Item will be negative if this trns is done
	v_nwAmnt := pay.willItmBlsBeNgtv (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, p_org_id, p_who_rn);
	IF (v_nwAmnt < 0) THEN
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Transaction will cause a Balance Item ' || 'to Have Negative Balance and hence cannot be allowed! Person:' || p_loc_id_no || ' Item: ' || p_itm_name || 'Amount:' || v_nwAmnt || '/' || v_pay_amount || '/' || p_trns_date, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
		p_retmsg := 'Continue';
		p_payItmAmnt := 0;
		RETURN;
	END IF;
	v_pay_trns_desc := '';
	IF (char_length(p_trnsDesc) <= 0) THEN
		IF (p_itm_min_typ = 'Earnings' OR p_itm_min_typ = 'Employer Charges') THEN
			v_pay_trns_desc := 'Payment of ' || p_itm_name || ' for ' || p_loc_id_no;
		ELSIF (p_itm_min_typ = 'Bills/Charges'
				OR p_itm_min_typ = 'Deductions') THEN
			v_pay_trns_desc := 'Payment of ' || p_itm_name || ' by ' || p_loc_id_no;
		ELSE
			v_pay_trns_desc := 'Running of Purely Informational Item ' || p_itm_name || ' for ' || p_loc_id_no;
		END IF;
	ELSE
		v_pay_trns_desc := p_trnsDesc;
	END IF;
	v_tstPyTrnsID := pay.hsPrsnBnPaidItmMsPy (p_prsn_id, p_itm_id, p_trns_date, v_pay_amount);
	IF (v_tstPyTrnsID <= 0) THEN
		v_result1 := pay.createPaymntLine2 (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, 'Mass Pay Run', p_trns_typ, p_mspy_id, v_pay_trns_desc, v_crncy_id, p_dateStr, 'VALID', - 1, p_glDate, v_dteEarned, p_who_rn, p_sales_invoice_id, p_leave_of_absence_id, p_invc_det_ln_id);
	ELSE
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Same Payment has been made FOR this Person ON the same Date already! Person:' || p_loc_id_no || ' Item:' || p_itm_name, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
	END IF;
	--Update Balance Items
	v_result1 := pay.updtBlsItms (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date, 'Mass Pay Run', - 1, to_char(now(), 'YYYY-MM-DD HH24:MI:SS'), p_who_rn);
	v_res1 := TRUE;
	IF (v_res1) THEN
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Successfully processed Payment for Person:' || p_loc_id_no || ' Item:' || p_itm_name, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
	ELSE
		v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Processing Payment Failed for Person:' || p_loc_id_no || ' Item:' || p_itm_name, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
	END IF;
	p_retmsg := '';
	p_payItmAmnt := v_pay_amount;
	RETURN;
EXCEPTION
	WHEN OTHERS THEN
		p_retmsg := 'Stop';
	p_payItmAmnt := 0;
	v_Reslg := gst.updatelogmsg (p_msg_id, '<br/>Processing Payment Failed for Person:' || p_loc_id_no || ' Item:' || p_itm_name || '::' || SQLERRM, 'pay.pay_mass_pay_run_msgs', p_dateStr, p_who_rn);
	RETURN;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.rllbckMassPyRn (p_mspyid bigint, v_msg_id bigint, p_who_rn bigint)
	RETURNS text
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_Reslg bigint := - 1;
	b_res boolean := FALSE;
	rd1 RECORD;
	msgs text := '';
	v_retmsg text := '';
	i integer := 0;
	v_dateStr character varying(21) := '';
	v_reslt_1 text := '';
	v_Org_id integer := - 1;
	v_nwmspyid bigint := - 1;
	v_trnsDate character varying(21) := '';
	v_msPyGLDate character varying(21) := '';
	v_msPyNm character varying(200) := '';
	v_msPyDesc character varying(300) := '';
	v_msPyPrsStID integer := - 1;
	v_msPyItmStID integer := - 1;
	--v_msg_id        BIGINT                 := -1;
	v_pytrnsamnt numeric := 0;
	v_intfcDbtAmnt numeric := 0;
	v_intfcCrdtAmnt numeric := 0;
BEGIN
	IF (p_msPyID <= 0) THEN
		msgs := 'ERROR:Please SELECT a Mass Pay Run FIRST !';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
		RETURN msgs;
	END IF;
	v_Org_id := gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'org_id', p_msPyID)::integer;
	v_msPyNm := gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'mass_pay_name', p_msPyID);
	v_msPyDesc := gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'mass_pay_desc', p_msPyID);
	v_msPyPrsStID := gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'prs_st_id', p_msPyID)::integer;
	v_msPyItmStID := gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'itm_st_id', p_msPyID)::integer;
	v_trnsDate := to_char(to_timestamp(gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'mass_pay_trns_date', p_msPyID), 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
	v_msPyGLDate := to_char(to_timestamp(gst.getGnrlRecNm ('pay.pay_mass_pay_run_hdr', 'mass_pay_id', 'gl_date', p_msPyID), 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS');
	IF (char_length(v_trnsDate) <= 0) THEN
		msgs := 'ERROR:Please enter a Mass Pay Run Date!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
		RETURN msgs;
	END IF;
	IF (char_length(v_msPyGLDate) <= 0) THEN
		msgs := 'ERROR:Please enter a Mass Pay Run GL Date!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
		RETURN msgs;
	END IF;
	IF (pay.get_MsPyInvoiceID (p_msPyID) > 0) THEN
		msgs := 'ERROR:Cannot Roll Back a Pay Run that was GENERATED FROM Sales!<br/>Cancel the Source Sales DOCUMENT INSTEAD !';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
		RETURN msgs;
	END IF;
	v_reslt_1 := accb.isTransPrmttd (v_Org_id, accb.get_DfltCashAcnt (sec.get_usr_prsn_id (p_who_rn), v_Org_id), v_msPyGLDate, 200);
	IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
		msgs := msgs || chr(10) || v_reslt_1;
		msgs := REPLACE(msgs, chr(10), '<br/>');
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
		RETURN msgs;
	END IF;
	v_nwmspyid := COALESCE(pay.get_ms_pay_id (v_msPyNm || ' (Reversal)', v_Org_id), - 1);
	IF (v_nwmspyid <= 0) THEN
		v_reslt_1 := pay.createMsPy (v_Org_id, (v_msPyNm || ' (Reversal)')::character varying, ('(Reversal) ' || v_msPyDesc)::character varying, v_trnsDate, v_msPyPrsStID, v_msPyItmStID, v_msPyGLDate, p_who_rn);
	END IF;
	v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
	v_nwmspyid := COALESCE(pay.get_ms_pay_id (v_msPyNm || ' (Reversal)', v_Org_id), - 1);
	IF (v_nwmspyid <= 0) THEN
		msgs := 'Failed TO CREATE Mass Pay run Reversal Batch!<br/>Please try again Later!';
		RAISE EXCEPTION
			USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
		RETURN msgs;
	END IF;
	--Get dataset for Payments to reverse
	--loop through such payments reversing them
	/*v_msg_id := gst.getLogMsgID('pay.pay_mass_pay_run_msgs', 'Mass Pay Run Reversal', v_nwmspyid);
	 IF (v_msg_id <= 0)
	 THEN
	 v_reslt_1 := gst.createLogMsg(v_dateStr || ' .... Mass Pay Run Reversal IS about TO START ...',
	 'pay.pay_mass_pay_run_msgs', 'Mass Pay Run Reversal', v_nwmspyid, v_dateStr,
	 p_who_rn);
	 END IF;
	 v_msg_id := gst.getLogMsgID('pay.pay_mass_pay_run_msgs', 'Mass Pay Run Reversal', v_nwmspyid);*/
	v_retmsg := '';
	i := 0;
	--Loop through all payments to reverse them
	FOR rd1 IN
	SELECT
		a.pay_trns_id,
		a.person_id,
		a.item_id,
		a.amount_paid,
		to_char(to_timestamp(a.paymnt_date, 'YYYY-MM-DD HH24:MI:SS'), 'DD-Mon-YYYY HH24:MI:SS') paymnt_date,
		a.paymnt_source,
		a.pay_trns_type,
		a.pymnt_desc,
		- 1,
		a.crncy_id,
		c.local_id_no,
		trim(c.title || ' ' || c.sur_name || ', ' || c.first_name || ' ' || c.other_names) fullname,
		b.item_code_name,
		b.item_value_uom,
		b.item_maj_type,
		b.item_min_type
	FROM (pay.pay_itm_trnsctns a
	LEFT OUTER JOIN org.org_pay_items b ON a.item_id = b.item_id)
	LEFT OUTER JOIN prs.prsn_names_nos c ON a.person_id = c.person_id
WHERE (a.mass_pay_id = p_msPyID)
ORDER BY
	a.pay_trns_id LOOP
		IF (i = 0) THEN
			SELECT
				p_errMsgs,
				p_result
			FROM
				pay.isMsPayTrnsValid (rd1.item_value_uom, rd1.item_maj_type, rd1.item_min_type, rd1.item_id, v_msPyGLDate, 1000, rd1.person_id, v_Org_id) INTO msgs,
	b_res;
			IF (b_res = FALSE) THEN
				RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
				RETURN msgs;
			END IF;
		END IF;
		v_retmsg := pay.rvrsMassPay (v_Org_id, rd1.person_id, rd1.local_id_no, rd1.item_id, rd1.item_code_name, rd1.item_value_uom, v_nwmspyid, rd1.paymnt_date, rd1.pay_trns_type, rd1.item_maj_type, rd1.item_min_type, v_msg_id, 'pay.pay_mass_pay_run_msgs', v_dateStr, rd1.amount_paid, rd1.crncy_id, '(Reversal) ' || rd1.pymnt_desc, rd1.pay_trns_id, v_msPyGLDate, p_who_rn);
		IF (v_retmsg LIKE 'Stop:%') THEN
			msgs := 'Process Stopped';
			RAISE EXCEPTION
				USING ERRCODE = 'RHERR', MESSAGE = msgs, HINT = msgs;
		END IF;
		i := i + 1;
	END LOOP;
	--Do some summation checks before updating the Status
	--Function to check if sum of debits is equal sum of credits to sum of amnts in all these pay trns
	--if correct the set gone to gl to '1' else '0'
	v_reslt_1 := pay.chck_n_updt_pay_rqsts (v_nwmspyid);
	v_pytrnsamnt := pay.getMsPyAmntSum (v_nwmspyid);
	v_intfcDbtAmnt := pay.getMsPyIntfcDbtSum (v_nwmspyid);
	v_intfcCrdtAmnt := pay.getMsPyIntfcCrdtSum (v_nwmspyid);
	IF (v_pytrnsamnt = v_intfcCrdtAmnt AND v_pytrnsamnt = v_intfcDbtAmnt AND v_pytrnsamnt != 0) THEN
		v_reslt_1 := pay.updateMsPyStatus (v_nwmspyid, '1', '1', p_who_rn);
	ELSIF (v_pytrnsamnt != 0) THEN
		v_reslt_1 := pay.updateMsPyStatus (v_nwmspyid, '1', '0', p_who_rn);
	ELSIF (i > 0
			AND v_intfcCrdtAmnt = 0) THEN
		v_reslt_1 := pay.updateMsPyStatus (v_nwmspyid, '1', '1', p_who_rn);
	END IF;
	UPDATE
		pay.pay_balsitm_bals
	SET
		bals_amount = 0
	WHERE
		bals_amount < 0;
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.doesPymntDteViolateFreq (p_prsnID bigint, p_itmID bigint, p_trns_date character varying)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res numeric := 0;
	v_trns_date character varying(21) := '';
	v_Cntr integer := 0;
	v_pyFreq character varying(100) := '';
	v_intrvlCls character varying(100) := '';
	v_whrCls text := '';
	v_strSql text := '';
BEGIN
	/*Daily
	 Weekly
	 Fortnightly
	 Semi-Monthly
	 Monthly
	 Quarterly
	 Half-Yearly
	 Annually
	 Adhoc
	 None*/
	v_trns_date := to_char(to_timestamp(p_trns_date, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_pyFreq := gst.getGnrlRecNm ('org.org_pay_items', 'item_id', 'pay_frequency', p_itmID);
	v_intrvlCls := '';
	v_whrCls := '';
	IF (v_pyFreq = 'Daily') THEN
		v_intrvlCls := '1 day';
	ELSIF (v_pyFreq = 'Weekly') THEN
		v_intrvlCls := '7 day';
	ELSIF (v_pyFreq = 'Fortnightly') THEN
		v_intrvlCls := '14 day';
	ELSIF (v_pyFreq = 'Semi-Monthly') THEN
		v_intrvlCls := '14 day';
	ELSIF (v_pyFreq = 'Monthly') THEN
		v_intrvlCls := '28 day';
	ELSIF (v_pyFreq = 'Quarterly') THEN
		v_intrvlCls := '90 day';
	ELSIF (v_pyFreq = 'Half-Yearly') THEN
		v_intrvlCls := '182 day';
	ELSIF (v_pyFreq = 'Annually') THEN
		v_intrvlCls := '365 day';
	ELSIF (v_pyFreq = 'Adhoc') THEN
		v_intrvlCls := '0 second';
	ELSIF (v_pyFreq = 'None') THEN
		v_intrvlCls := '0 second';
		RETURN FALSE;
	ELSE
		v_intrvlCls := '0 second';
		IF (v_pyFreq = 'Once a Month' OR v_pyFreq = 'Twice a Month') THEN
			v_whrCls := ' and (substr(a.paymnt_date,1,7) = substr(' || '''' || v_trns_date || '''' || ',1,7))';
		END IF;
	END IF;
	IF (char_length(v_whrCls) <= 0) THEN
		v_whrCls := ' and (age(GREATEST(paymnt_date::timeSTAMP,' || '''' || v_trns_date || '''' || '::timeSTAMP),LEAST(paymnt_date::timeSTAMP, ' || '''' || v_trns_date || '''' || '::timeSTAMP)) < interval ' || '''' || v_intrvlCls || '''' || ')';
	END IF;
	v_strSql := 'Select count(1) FROM pay.pay_itm_trnsctns a where((a.person_id = ' || p_prsnID || ') and (a.item_id = ' || p_itmID || ') and (a.pymnt_vldty_status=''VALID'' and a.src_py_trns_id <= 0)' || v_whrCls || ')';
	EXECUTE v_strSql INTO v_Cntr;
	IF (v_Cntr > 0) THEN
		IF (v_pyFreq = 'Once a Month' AND v_Cntr >= 1) THEN
			RETURN TRUE;
		ELSIF (v_pyFreq = 'Twice a Month'
				AND v_Cntr >= 2) THEN
			RETURN TRUE;
		ELSIF (NOT (v_pyFreq = 'Once a Month'
					OR v_pyFreq = 'Twice a Month')
				AND (v_Cntr > 0)) THEN
			RETURN TRUE;
		END IF;
	END IF;
	RETURN FALSE;
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.getAtchdValPrsnAmnt (p_prsnid bigint, p_mspyid bigint, p_itmid bigint, OUT p_dteErnd character varying, OUT p_value numeric)
LANGUAGE 'plpgsql'
COST 100 VOLATILE
AS $BODY$
	<< outerblock >>
DECLARE
	v_dteErnd character varying(21) := '';
	v_value numeric := 0;
BEGIN
	SELECT
		value_to_use,
		date_earned INTO v_value,
		v_dteErnd
	FROM
		pay.pay_value_sets_det
	WHERE ((person_id = p_prsnid)
		AND (mass_pay_id = p_mspyid)
		AND (item_id = p_itmid));
	p_dteErnd := coalesce(v_dteErnd, '');
	p_value := coalesce(v_value, 0);
EXCEPTION
	WHEN OTHERS THEN
		p_dteErnd := '';
	p_value := 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getAtchdValPrsnAmnt2 (p_prsnid bigint, p_mspyid bigint, p_itmid bigint, p_rqst_id bigint, OUT p_dteErnd character varying, OUT p_value numeric)
LANGUAGE 'plpgsql'
COST 100 VOLATILE
AS $BODY$
	<< outerblock >>
DECLARE
	v_dteErnd character varying(21) := '';
	v_value numeric := 0;
BEGIN
	SELECT
		value_to_use,
		date_earned INTO v_value,
		v_dteErnd
	FROM
		pay.pay_value_sets_det
	WHERE ((person_id = p_prsnid)
		AND (mass_pay_id = p_mspyid)
		AND (item_id = p_itmid)
		AND pay_request_id = p_rqst_id);
	p_dteErnd := coalesce(v_dteErnd, '');
	p_value := coalesce(v_value, 0);
EXCEPTION
	WHEN OTHERS THEN
		p_dteErnd := '';
	p_value := 0;
END;

$BODY$;

--DROP FUNCTION pay.sendToGLInterface (p_prsn_id bigint, p_loc_id_no character varying, p_itm_id integer, p_itm_name character varying, p_itm_uom character varying, p_pay_amnt numeric, p_trns_date character varying, p_trns_desc character varying, p_crncy_id integer, p_msg_id integer, p_log_tbl character varying, p_dateStr character varying, p_trns_src character varying, p_glDate character varying, p_orgnlTrnsID bigint, p_who_rn bigint);
CREATE OR REPLACE FUNCTION pay.sendToGLInterface (p_prsn_id bigint, p_loc_id_no character varying, p_itm_id bigint, p_itm_name character varying, p_itm_uom character varying, p_pay_amnt numeric, p_trns_date character varying, p_trns_desc character varying, p_crncy_id integer, p_msg_id bigint, p_log_tbl character varying, p_dateStr character varying, p_trns_src character varying, p_glDate character varying, p_orgnlTrnsID bigint, p_who_rn bigint)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_result1 text := '';
	v_paytrnsid bigint := - 1;
	v_netamnt numeric := 0;
	v_accntinf character varying(50)[];
	v_accntinfstr character varying(200) := '';
	v_py_dbt_ln bigint := - 1;
	v_py_crdt_ln bigint := - 1;
BEGIN
	v_paytrnsid := pay.getPaymntTrnsID (p_prsn_id, p_itm_id, p_pay_amnt, p_trns_date, p_orgnlTrnsID);
	--Create GL Lines based on item's defined accounts
	v_netamnt := 0;
	v_accntinfstr := pay.get_ItmAccntInfo (p_itm_id, p_prsn_id);
	v_accntinf := string_to_array(v_accntinfstr, ':');
	--RAISE NOTICE 'v_accntinf [ 1] %', v_accntinf [ 1];
	--RAISE NOTICE 'v_accntinf [ 2] %', v_accntinf [ 2];
	--RAISE NOTICE 'v_accntinf [ 3] %', v_accntinf [ 3];
	--RAISE NOTICE 'v_accntinf [ 4] %', v_accntinf [ 4];
	IF (p_itm_uom != 'Number' AND (v_accntinf[2])::integer > 0 AND (v_accntinf[4])::integer > 0) THEN
		v_netamnt := accb.dbt_or_crdt_accnt_multiplier (v_accntinf[2]::integer, substr(v_accntinf[1], 1, 1)) * p_pay_amnt;
		--RAISE NOTICE 'v_netamnt %', v_netamnt;
		v_py_dbt_ln := pay.getIntFcTrnsDbtLn (v_paytrnsid, p_pay_amnt);
		v_py_crdt_ln := pay.getIntFcTrnsCrdtLn (v_paytrnsid, p_pay_amnt);
		--RAISE NOTICE 'p_pay_amnt %', p_pay_amnt;
		IF (accb.dbt_or_crdt_accnt (v_accntinf[2]::integer, substr(v_accntinf[1], 1, 1)) = 'Debit') THEN
			IF (v_py_dbt_ln <= 0) THEN
				v_result1 := pay.createPymntGLIntFcLn (v_accntinf[2]::integer, p_trns_desc, p_pay_amnt, p_glDate, p_crncy_id, 0, v_netamnt, v_paytrnsid, p_dateStr, p_who_rn);
			END IF;
		ELSE
			IF (v_py_crdt_ln <= 0) THEN
				v_result1 := pay.createPymntGLIntFcLn (v_accntinf[2]::integer, p_trns_desc, 0, p_glDate, p_crncy_id, p_pay_amnt, v_netamnt, v_paytrnsid, p_dateStr, p_who_rn);
			END IF;
		END IF;
		--RAISE NOTICE 'v_result1 %', v_result1;
		--RAISE NOTICE 'p_trns_desc %', p_trns_desc;
		--Repeat same for balancing leg
		v_netamnt := accb.dbt_or_crdt_accnt_multiplier (v_accntinf[4]::integer, substr(v_accntinf[3], 1, 1)) * p_pay_amnt;
		--RAISE NOTICE 'v_netamnt %', v_netamnt;
		IF (accb.dbt_or_crdt_accnt (v_accntinf[4]::integer, substr(v_accntinf[3], 1, 1)) = 'Debit') THEN
			IF (v_py_dbt_ln <= 0) THEN
				v_result1 := pay.createPymntGLIntFcLn (v_accntinf[4]::integer, p_trns_desc, p_pay_amnt, p_glDate, p_crncy_id, 0, v_netamnt, v_paytrnsid, p_dateStr, p_who_rn);
			END IF;
		ELSE
			IF (v_py_crdt_ln <= 0) THEN
				v_result1 := pay.createPymntGLIntFcLn (v_accntinf[4]::integer, p_trns_desc, 0, p_glDate, p_crncy_id, p_pay_amnt, v_netamnt, v_paytrnsid, p_dateStr, p_who_rn);
			END IF;
		END IF;
		--RAISE NOTICE 'v_result2 %', v_result1;
	END IF;
	RETURN TRUE;
EXCEPTION
	WHEN OTHERS THEN
		--RAISE NOTICE 'SQLERRM INTERFACE %', SQLERRM;
		RETURN FALSE;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getIntFcTrnsDbtLn (p_pytrnsid bigint, p_pay_amnt numeric)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := 0;
BEGIN
	SELECT
		a.interface_id INTO v_res
	FROM
		pay.pay_gl_interface a
	WHERE
		a.source_trns_id = p_pytrnsid
		AND a.dbt_amount = p_pay_amnt;
	RETURN coalesce(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getIntFcTrnsCrdtLn (p_pytrnsid bigint, p_pay_amnt numeric)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		a.interface_id INTO v_res
	FROM
		pay.pay_gl_interface a
	WHERE
		a.source_trns_id = p_pytrnsid
		AND a.crdt_amount = p_pay_amnt;
	RETURN coalesce(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.sendToGLInterfaceRetro (p_prsn_id bigint, p_loc_id_no character varying, p_itm_id integer, p_itm_name character varying, p_itm_uom character varying, p_pay_amnt numeric, p_trns_date character varying, p_trns_desc character varying, p_crncy_id integer, p_msg_id bigint, p_log_tbl character varying, p_dateStr character varying, p_trns_src character varying, p_glDate character varying, p_orgnlTrnsID bigint, p_dteEarned character varying, p_who_rn bigint)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_Reslg bigint := - 1;
	v_result1 text := '';
	v_paytrnsid bigint := - 1;
	v_netamnt numeric := 0;
	v_accntinf character varying(50)[];
	v_accntinfstr character varying(200) := '';
	v_py_dbt_ln bigint := - 1;
	v_py_crdt_ln bigint := - 1;
BEGIN
	v_paytrnsid := pay.getPaymntTrnsIDREtro (p_prsn_id, p_itm_id, p_pay_amnt, p_trns_date, p_dteEarned, p_orgnlTrnsID);
	v_accntinfstr := pay.get_ItmAccntInfo (p_itm_id, p_prsn_id);
	v_accntinf := string_to_array(v_accntinfstr, ':');
	IF (p_itm_uom != 'Number' AND v_accntinf[2]::integer > 0 AND v_accntinf[4]::integer > 0) THEN
		v_netamnt := accb.dbt_or_crdt_accnt_multiplier (v_accntinf[2]::integer, substr(v_accntinf[1], 1, 1)) * p_pay_amnt;
		v_py_dbt_ln := pay.getIntFcTrnsDbtLn (v_paytrnsid, p_pay_amnt);
		v_py_crdt_ln := pay.getIntFcTrnsCrdtLn (v_paytrnsid, p_pay_amnt);
		IF (accb.dbt_or_crdt_accnt (v_accntinf[2]::integer, substr(v_accntinf[1], 1, 1)) = 'Debit') THEN
			IF (v_py_dbt_ln <= 0) THEN
				v_result1 := pay.createPymntGLIntFcLn (v_accntinf[2]::integer, p_trns_desc, p_pay_amnt, p_glDate, p_crncy_id, 0, v_netamnt, v_paytrnsid, p_dateStr, p_who_rn);
			END IF;
		ELSE
			IF (v_py_crdt_ln <= 0) THEN
				v_result1 := pay.createPymntGLIntFcLn (v_accntinf[2]::integer, p_trns_desc, 0, p_glDate, p_crncy_id, p_pay_amnt, v_netamnt, v_paytrnsid, p_dateStr, p_who_rn);
			END IF;
		END IF;
		--Repeat same for balancing leg
		v_netamnt := accb.dbt_or_crdt_accnt_multiplier (v_accntinf[4]::integer, substr(v_accntinf[3], 1, 1)) * p_pay_amnt;
		IF (accb.dbt_or_crdt_accnt (v_accntinf[4]::integer, substr(v_accntinf[3], 1, 1)) = 'Debit') THEN
			IF (v_py_dbt_ln <= 0) THEN
				v_result1 := pay.createPymntGLIntFcLn (v_accntinf[4]::integer, p_trns_desc, p_pay_amnt, p_glDate, p_crncy_id, 0, v_netamnt, v_paytrnsid, p_dateStr, p_who_rn);
			END IF;
		ELSE
			IF (v_py_crdt_ln <= 0) THEN
				v_result1 := pay.createPymntGLIntFcLn (v_accntinf[4]::integer, p_trns_desc, 0, p_glDate, p_crncy_id, p_pay_amnt, v_netamnt, v_paytrnsid, p_dateStr, p_who_rn);
			END IF;
		END IF;
	END IF;
	RETURN TRUE;
EXCEPTION
	WHEN OTHERS THEN
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Error Sending Retro Payment to GL Interface for Person:' || p_loc_id_no || ' Item: ' || p_itm_name || ' ', p_dateStr, p_who_rn);
	RETURN FALSE;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.sendToGLInterfaceMnl (p_prsn_id bigint, p_itm_id bigint, p_itm_uom character varying, p_pay_amnt numeric, p_trns_date character varying, p_trns_desc character varying, p_crncy_id integer, p_dateStr character varying, p_trns_src character varying, p_glDate character varying, p_orgnlTrnsID bigint, p_org_id integer, p_who_rn bigint)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_result1 text := '';
	v_paytrnsid bigint := - 1;
	v_netamnt numeric := 0;
	v_accntinf character varying(50)[];
	v_accntinfstr character varying(200) := '';
	v_py_dbt_ln bigint := - 1;
	v_py_crdt_ln bigint := - 1;
BEGIN
	v_paytrnsid := pay.getPaymntTrnsID (p_prsn_id, p_itm_id, p_pay_amnt, p_trns_date, p_orgnlTrnsID);
	--Create GL Lines based on item's defined accounts
	v_accntinfstr := pay.get_ItmAccntInfo (p_itm_id, p_prsn_id);
	v_accntinf := string_to_array(v_accntinfstr, ':');
	IF (p_itm_uom != 'Number' AND v_accntinf[2]::integer > 0 AND v_accntinf[4]::integer > 0) THEN
		v_netamnt := 0;
		v_netamnt := accb.dbt_or_crdt_accnt_multiplier (v_accntinf[2]::integer, substr(v_accntinf[1], 1, 1)) * p_pay_amnt;
		v_py_dbt_ln := pay.getIntFcTrnsDbtLn (v_paytrnsid, p_pay_amnt);
		v_py_crdt_ln := pay.getIntFcTrnsCrdtLn (v_paytrnsid, p_pay_amnt);
		IF (accb.dbt_or_crdt_accnt (v_accntinf[2]::integer, substr(v_accntinf[1], 1, 1)) = 'Debit') THEN
			IF (v_py_dbt_ln <= 0) THEN
				v_result1 := pay.createPymntGLIntFcLn (v_accntinf[2]::integer, p_trns_desc, p_pay_amnt, p_glDate, p_crncy_id, 0, v_netamnt, v_paytrnsid, p_dateStr, p_who_rn);
			END IF;
		ELSE
			IF (v_py_crdt_ln <= 0) THEN
				v_result1 := pay.createPymntGLIntFcLn (v_accntinf[2]::integer, p_trns_desc, 0, p_glDate, p_crncy_id, p_pay_amnt, v_netamnt, v_paytrnsid, p_dateStr, p_who_rn);
			END IF;
		END IF;
		--Repeat same for balancing leg
		v_netamnt := accb.dbt_or_crdt_accnt_multiplier (v_accntinf[4]::integer, substr(v_accntinf[3], 1, 1)) * p_pay_amnt;
		IF (accb.dbt_or_crdt_accnt (v_accntinf[4]::integer, substr(v_accntinf[3], 1, 1)) = 'Debit') THEN
			IF (v_py_dbt_ln <= 0) THEN
				v_result1 := pay.createPymntGLIntFcLn (v_accntinf[4]::integer, p_trns_desc, p_pay_amnt, p_glDate, p_crncy_id, 0, v_netamnt, v_paytrnsid, p_dateStr, p_who_rn);
			END IF;
		ELSE
			IF (v_py_crdt_ln <= 0) THEN
				v_result1 := pay.createPymntGLIntFcLn (v_accntinf[4]::integer, p_trns_desc, 0, p_glDate, p_crncy_id, p_pay_amnt, v_netamnt, v_paytrnsid, p_dateStr, p_who_rn);
			END IF;
		END IF;
	END IF;
	RETURN TRUE;
EXCEPTION
	WHEN OTHERS THEN
		RETURN FALSE;
	--RETURN 'ERROR:Error Sending Payment to GL Interface'||SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.runRetroMassPay (p_org_id integer, p_prsn_id bigint, p_loc_id_no character varying, p_itm_id integer, p_retroItmID integer, p_itm_name character varying, p_itm_uom character varying, p_mspy_id bigint, p_trns_date_ernd character varying, p_cur_pay_dte character varying, p_trns_typ character varying, p_itm_maj_typ character varying, p_itm_min_typ character varying, p_msg_id bigint, p_log_tbl character varying, p_dateStr character varying, p_glDate character varying, p_who_rn bigint, OUT pay_amount numeric, OUT p_res_msg character varying)
LANGUAGE 'plpgsql'
COST 100 VOLATILE
AS $BODY$
	<< outerblock >>
DECLARE
	v_Reslg bigint := - 1;
	v_res boolean := FALSE;
	v_pay_amount numeric := 0;
	v_result1 text := '';
	v_prs_itm_val_id bigint := - 1;
	v_crncy_id integer := - 1;
	v_crncy_cde character varying(50) := '';
	v_valSQL text := '';
	v_pay_trns_desc character varying(300) := '';
	v_nwAmnt numeric := 0;
	v_tstPyTrnsID bigint := - 1;
BEGIN
	v_pay_amount := 0;
	IF (upper(p_itm_maj_typ) = upper('Balance Item')) THEN
		p_res_msg := 'Continue';
		pay_amount := 0;
		RETURN;
	END IF;
	IF (pay.doesPrsnHvItm1 (p_prsn_id, p_itm_id) = FALSE) THEN
		p_res_msg := 'Continue';
		pay_amount := 0;
		RETURN;
	END IF;
	IF (char_length(p_trns_typ) <= 0) THEN
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Transaction Type not Specified for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
		p_res_msg := 'Continue';
		pay_amount := 0;
		RETURN;
	END IF;
	v_prs_itm_val_id := pay.getPrsnItmVlID (p_prsn_id, p_retroItmID, p_trns_date_ernd);
	IF (v_prs_itm_val_id <= 0) THEN
		v_prs_itm_val_id := pay.get_first_itmval_id (p_retroItmID);
	END IF;
	v_crncy_id := - 1;
	v_crncy_cde := p_itm_uom;
	IF (p_itm_uom = 'Money') THEN
		v_crncy_id := org.get_orgfunc_crncy_id (p_org_id);
		v_crncy_cde := gst.get_pssbl_val (v_crncy_id);
	END IF;
	v_valSQL := pay.getItmValSQL (v_prs_itm_val_id);
	IF (char_length(v_valSQL) <= 0) THEN
		v_pay_amount = 0;
		v_pay_amount := pay.getItmValueAmnt (v_prs_itm_val_id);
	ELSE
		v_pay_amount := pay.exct_itm_valsql (v_valSQL, p_prsn_id, p_org_id, p_trns_date_ernd);
	END IF;
	IF (v_pay_amount = 0) THEN
		p_res_msg := 'Continue';
		pay_amount := 0;
		RETURN;
	END IF;
	v_nwAmnt := pay.willItmBlsBeNgtvRetro (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date_ernd, p_org_id, p_who_rn);
	IF (v_nwAmnt < 0) THEN
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Transaction will cause a Balance Item ' || 'to Have Negative Balance and hence cannot be allowed! Person:' || p_loc_id_no || ' Item: ' || p_itm_name || 'Amount:' || v_nwAmnt || '/' || v_pay_amount || '/' || p_trns_date_ernd, p_dateStr, p_who_rn);
		p_res_msg := 'Continue';
		pay_amount := 0;
		RETURN;
	END IF;
	v_pay_trns_desc := '';
	IF (p_itm_min_typ = 'Earnings' OR p_itm_min_typ = 'Employer Charges') THEN
		v_pay_trns_desc := 'Payment of ' || p_itm_name || ' for ' || p_loc_id_no;
	ELSIF (p_itm_min_typ = 'Bills/Charges'
			OR p_itm_min_typ = 'Deductions') THEN
		v_pay_trns_desc := 'Payment of ' || p_itm_name || ' by ' || p_loc_id_no;
	ELSE
		v_pay_trns_desc := 'Running of Purely Informational Item ' || p_itm_name || ' for ' || p_loc_id_no;
	END IF;
	v_tstPyTrnsID := pay.hsPrsnBnPaidItmMsPyRetro (p_prsn_id, p_itm_id, p_trns_date_ernd, v_pay_amount);
	IF (v_tstPyTrnsID <= 0) THEN
		v_result1 := pay.createPaymntLineRetro (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date_ernd, 'Mass Pay Run', p_trns_typ, p_mspy_id, v_pay_trns_desc, v_crncy_id, p_dateStr, 'VALID', - 1, p_glDate, p_who_rn);
	ELSE
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Same Payment has been made for this Person on the same Date already! Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
	END IF;
	v_result1 := pay.updtBlsItmsRetro (p_prsn_id, p_itm_id, v_pay_amount, p_trns_date_ernd, 'Mass Pay Run', - 1, p_who_rn);
	v_res := TRUE;
	IF (v_res) THEN
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Successfully processed Payment for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
	ELSE
		v_Reslg := rpt.updaterptlogmsg (p_msg_id, '<br/>Processing Payment Failed for Person:' || p_loc_id_no || ' Item: ' || p_itm_name, p_dateStr, p_who_rn);
	END IF;
	p_res_msg := '';
	pay_amount := v_pay_amount;
	RETURN;
EXCEPTION
	WHEN OTHERS THEN
		p_res_msg := 'stop';
	pay_amount := 0;
	RETURN;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.updtBlsItmsRetro (p_prsn_id bigint, p_itm_id integer, p_pay_amount numeric, p_trns_date character varying, p_trns_src character varying, p_orgnlTrnsID bigint, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_Reslg bigint := - 1;
	v_nwAmnt numeric := 0;
	v_lstBals numeric := 0;
	v_scaleFctr numeric := 0;
	rd1 RECORD;
	v_org_id integer := - 1;
	v_paytrnsid bigint := - 1;
	b_hsBlsBnUpdtd boolean := FALSE;
	v_dailybalID bigint := - 1;
	v_result1 text := '';
BEGIN
	v_org_id := prs.get_prsn_org_id (p_prsn_id);
	v_nwAmnt := 0;
	FOR rd1 IN
	SELECT
		a.balance_item_id,
		a.adds_subtracts,
		b.balance_type,
		a.scale_factor,
		c.pssbl_value_id
	FROM
		org.org_pay_itm_feeds a
	LEFT OUTER JOIN org.org_pay_items b ON a.balance_item_id = b.item_id
	LEFT OUTER JOIN org.org_pay_items_values c ON c.item_id = a.balance_item_id
WHERE ((a.fed_by_itm_id = p_itm_id))
ORDER BY
	a.feed_id LOOP
		v_lstBals := 0;
		v_scaleFctr := rd1.scale_factor;
		IF (rd1.balance_type = 'Cumulative') THEN
			v_lstBals := pay.getBlsItmLtstDailyBalsRetro (rd1.balance_item_id, p_prsn_id, p_trns_date, v_org_id);
			IF (rd1.adds_subtracts = 'Subtracts') THEN
				v_nwAmnt := - 1 * p_pay_amount * v_scaleFctr;
			ELSE
				v_nwAmnt := p_pay_amount * v_scaleFctr;
			END IF;
		ELSE
			v_lstBals := pay.getBlsItmDailyBalsRetro (rd1.balance_item_id, p_prsn_id, p_trns_date, v_org_id);
			IF (rd1.adds_subtracts = 'Subtracts') THEN
				v_nwAmnt := - 1 * p_pay_amount * v_scaleFctr;
			ELSE
				v_nwAmnt := p_pay_amount * v_scaleFctr;
			END IF;
		END IF;
		--Check if prsn's balance has not been updated already
		v_paytrnsid := pay.getPaymntTrnsIDREtro (p_prsn_id, p_itm_id, p_pay_amount, p_trns_date, p_orgnlTrnsID);
		b_hsBlsBnUpdtd := pay.hsPrsItmBlsBnUptdRetro (v_paytrnsid, p_trns_date, rd1.balance_item_id, p_prsn_id);
		v_dailybalID := pay.getItmDailyBalsIDRetro (rd1.balance_item_id, p_trns_date, p_prsn_id);
		IF (b_hsBlsBnUpdtd = FALSE) THEN
			IF (v_dailybalID <= 0) THEN
				v_result1 := pay.createItmBalsRetro (rd1.balance_item_id, v_lstBals, p_prsn_id, p_trns_date, - 1);
				IF (rd1.balance_type = 'Cumulative') THEN
					v_result1 := pay.updtItmDailyBalsCumRetro (p_trns_date, rd1.balance_item_id, p_prsn_id, v_nwAmnt, v_paytrnsid);
				ELSE
					v_result1 := pay.updtItmDailyBalsNonCumRetro (p_trns_date, rd1.balance_item_id, p_prsn_id, v_nwAmnt, v_paytrnsid);
				END IF;
			ELSE
				IF (rd1.balance_type = 'Cumulative') THEN
					v_result1 := pay.updtItmDailyBalsCumRetro (p_trns_date, rd1.balance_item_id, p_prsn_id, v_nwAmnt, v_paytrnsid);
				ELSE
					v_result1 := pay.updtItmDailyBalsNonCumRetro (p_trns_date, rd1.balance_item_id, p_prsn_id, v_nwAmnt, v_paytrnsid);
				END IF;
			END IF;
		END IF;
	END LOOP;
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.willItmBlsBeNgtvRetro (p_prsn_id bigint, p_itm_id bigint, p_pay_amount numeric, p_trns_date character varying, p_org_id integer, p_who_rn bigint)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_Reslg bigint := - 1;
	v_tstDte character varying(21) := '';
	v_nwAmnt numeric := 0;
	v_lstBals numeric := 0;
	v_scaleFctr numeric := 0;
	rd1 RECORD;
	v_paytrnsid bigint := - 1;
	b_res boolean := FALSE;
	v_dailybalID bigint := - 1;
	v_result1 text := '';
BEGIN
	v_nwAmnt := 0;
	FOR rd1 IN
	SELECT
		a.balance_item_id,
		a.adds_subtracts,
		b.balance_type,
		a.scale_factor,
		c.pssbl_value_id
	FROM
		org.org_pay_itm_feeds a
	LEFT OUTER JOIN org.org_pay_items b ON a.balance_item_id = b.item_id
	LEFT OUTER JOIN org.org_pay_items_values c ON c.item_id = a.balance_item_id
WHERE ((a.fed_by_itm_id = p_itm_id))
ORDER BY
	a.feed_id LOOP
		IF (pay.doesPrsnHvItmPrs (p_prsn_id, rd1.balance_item_id) <= 0) THEN
			v_tstDte := '';
			b_res := FALSE;
			SELECT
				p_strtDte,
				p_res
			FROM
				pay.doesPrsnHvItm (p_prsn_id, p_itm_id, p_trns_date) INTO v_tstDte,
	b_res;
			IF (char_length(v_tstDte) <= 0) THEN
				v_tstDte := '01-Jan-1900 00:00:00';
			END IF;
			v_result1 := pay.createBnftsPrs (p_prsn_id, rd1.balance_item_id, rd1.pssbl_value_id, ('01-' || substr(v_tstDte, 4, 8))::character varying, '31-Dec-4000', p_who_rn);
		END IF;
		v_scaleFctr := rd1.scale_factor;
		IF (rd1.balance_type = 'Cumulative') THEN
			IF (rd1.adds_subtracts = 'Subtracts') THEN
				v_nwAmnt := pay.getBlsItmLtstDailyBalsRetro (rd1.balance_item_id, p_prsn_id, p_trns_date, p_org_id) - (p_pay_amount * v_scaleFctr);
			ELSE
				v_nwAmnt := (p_pay_amount * v_scaleFctr) + pay.getBlsItmLtstDailyBalsRetro (rd1.balance_item_id, p_prsn_id, p_trns_date, p_org_id);
			END IF;
		ELSE
			IF (rd1.adds_subtracts = 'Subtracts') THEN
				v_nwAmnt := pay.getBlsItmDailyBalsRetro (rd1.balance_item_id, p_prsn_id, p_trns_date, p_org_id) - (p_pay_amount * v_scaleFctr);
			ELSE
				v_nwAmnt := (p_pay_amount * v_scaleFctr) + pay.getBlsItmDailyBalsRetro (rd1.balance_item_id, p_prsn_id, p_trns_date, p_org_id);
			END IF;
		END IF;
		IF (v_nwAmnt < 0) THEN
			RETURN v_nwAmnt;
		END IF;
	END LOOP;
	RETURN v_nwAmnt;
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

--DROP FUNCTION pay.rllbckMassPyRn (p_msPyID bigint, p_who_rn bigint);
CREATE OR REPLACE FUNCTION pay.getItmDailyBalsIDRetro (p_balsItmID bigint, p_balsDate character varying, p_prsn_id bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	v_balsDate character varying(21) := '';
BEGIN
	v_balsDate := to_char(to_timestamp(p_balsDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (char_length(v_balsDate) > 10) THEN
		v_balsDate := substr(v_balsDate, 1, 10);
	END IF;
	SELECT
		a.bals_id INTO v_res
	FROM
		pay.pay_balsitm_bals_retro a
	WHERE (to_timestamp(a.bals_date, 'YYYY-MM-DD') = to_timestamp(v_balsDate, 'YYYY-MM-DD')
		AND a.bals_itm_id = p_balsItmID
		AND a.person_id = p_prsn_id);
	RETURN coalesce(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getBlsItmDailyBalsRetro (p_balsItmID bigint, p_prsn_id bigint, p_balsDate character varying, p_orgid integer)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res numeric := 0;
	v_orgnlDte character varying(21) := '';
	v_balsDate character varying(21) := '';
	v_usesSQL character varying(1) := '0';
	v_sql text := '';
BEGIN
	v_orgnlDte := p_balsDate;
	v_balsDate := to_char(to_timestamp(p_balsDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (char_length(v_balsDate) > 10) THEN
		v_balsDate := substr(v_balsDate, 1, 10);
	END IF;
	v_res := 0;
	v_sql := '';
	v_usesSQL := gst.getGnrlRecNm ('org.org_pay_items', 'item_id', 'uses_sql_formulas', p_balsItmID);
	IF (v_usesSQL != '1') THEN
		v_sql := 'SELECT a.bals_amount ' || 'FROM pay.pay_balsitm_bals_retro a ' || 'WHERE(to_timestamp(a.bals_date,''YYYY-MM-DD'') =  to_timestamp(' || '''' || v_balsDate || '''' || ',''YYYY-MM-DD'') and a.bals_itm_id = ' || p_balsItmID || ' and a.person_id = ' || p_prsn_id || ')';
	ELSE
		v_sql := pay.getItmValSQL (pay.getPrsnItmVlID (p_prsn_id, p_balsItmID, v_orgnlDte));
		IF (char_length(v_sql) > 0) THEN
			v_res := pay.exct_itm_valsql (v_sql, p_prsn_id, p_orgid, v_balsDate);
		END IF;
	END IF;
	RETURN coalesce(v_res, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getBlsItmLtstDailyBalsRetro (p_balsItmID bigint, p_prsn_id bigint, p_balsDate character varying, p_orgid integer)
	RETURNS numeric
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res numeric := 0;
	v_orgnlDte character varying(21) := '';
	v_balsDate character varying(21) := '';
	v_usesSQL character varying(1) := '0';
	v_sql text := '';
BEGIN
	v_orgnlDte := p_balsDate;
	v_balsDate := to_char(to_timestamp(p_balsDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (char_length(v_balsDate) > 10) THEN
		v_balsDate := substr(v_balsDate, 1, 10);
	END IF;
	v_res := 0;
	v_sql := '';
	v_usesSQL := gst.getGnrlRecNm ('org.org_pay_items', 'item_id', 'uses_sql_formulas', p_balsItmID);
	IF (v_usesSQL != '1') THEN
		v_sql := 'SELECT a.bals_amount ' || 'FROM pay.pay_balsitm_bals_retro a ' || 'WHERE(to_timestamp(a.bals_date,''YYYY-MM-DD'') <=  to_timestamp(' || '''' || v_balsDate || '''' || ',''YYYY-MM-DD'') and a.bals_itm_id = ' || p_balsItmID || ' and a.person_id = ' || p_prsn_id || ') ORDER BY to_timestamp(a.bals_date,''YYYY-MM-DD'') DESC LIMIT 1 OFFSET 0';
		EXECUTE v_sql INTO v_res;
	ELSE
		v_sql := pay.getItmValSQL (pay.getPrsnItmVlID (p_prsn_id, p_balsItmID, v_orgnlDte));
		IF (char_length(v_sql) > 0) THEN
			v_res := pay.exct_itm_valsql (v_sql, p_prsn_id, p_orgid, v_balsDate);
		END IF;
	END IF;
	RETURN coalesce(v_res, 0);
EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.updtItmDailyBalsCumRetro (p_balsDate character varying, p_blsItmID bigint, p_prsn_id bigint, p_netAmnt numeric, p_py_trns_id bigint, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
	v_balsDate character varying(21) := '';
BEGIN
	v_balsDate := to_char(to_timestamp(p_balsDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (char_length(v_balsDate) > 10) THEN
		v_balsDate := substr(v_balsDate, 1, 10);
	END IF;
	v_dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	UPDATE
		pay.pay_balsitm_bals_retro
	SET
		last_update_by = p_who_rn,
		last_update_date = v_dateStr,
		bals_amount = bals_amount + p_netAmnt,
		source_trns_ids = source_trns_ids || p_py_trns_id || ', '
	WHERE (to_timestamp(bals_date, 'YYYY-MM-DD') >= to_timestamp(v_balsDate, 'YYYY-MM-DD')
		AND bals_itm_id = p_blsItmID
		AND person_id = p_prsn_id);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.updtItmDailyBalsNonCumRetro (p_balsDate character varying, p_blsItmID bigint, p_prsn_id bigint, p_netAmnt numeric, p_py_trns_id bigint, p_who_rn bigint)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
	v_balsDate character varying(21) := '';
BEGIN
	v_balsDate := to_char(to_timestamp(p_balsDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (char_length(v_balsDate) > 10) THEN
		v_balsDate := substr(v_balsDate, 1, 10);
	END IF;
	v_dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	UPDATE
		pay.pay_balsitm_bals_retro
	SET
		last_update_by = p_who_rn,
		last_update_date = v_dateStr,
		bals_amount = bals_amount + p_netAmnt,
		source_trns_ids = source_trns_ids || p_py_trns_id || ', '
	WHERE (to_timestamp(bals_date, 'YYYY-MM-DD') = to_timestamp(v_balsDate, 'YYYY-MM-DD')
		AND bals_itm_id = p_blsItmID
		AND person_id = p_prsn_id);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.createItmBalsRetro (p_blsitmid bigint, p_netbals numeric, p_prsn_id bigint, p_balsDate character varying, p_py_trns_id bigint, p_who_rn bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_dateStr character varying(21) := '';
	v_balsDate character varying(21) := '';
	v_src_trns character varying(50) := '';
BEGIN
	v_balsDate := to_char(to_timestamp(p_balsDate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (char_length(v_balsDate) > 10) THEN
		v_balsDate := substr(v_balsDate, 1, 10);
	END IF;
	v_src_trns := ',';
	IF (p_py_trns_id > 0) THEN
		v_src_trns := ',' || p_py_trns_id || ',';
	END IF;
	v_dateStr := to_char(now(), 'YYYY-MM-DD HH24:MI:SS');
	INSERT INTO pay.pay_balsitm_bals_retro (bals_itm_id, bals_amount, person_id, bals_date, created_by, creation_date, last_update_by, last_update_date, source_trns_ids)
		VALUES (p_blsitmid, p_netbals, p_prsn_id, v_balsDate, p_who_rn, v_dateStr, p_who_rn, v_dateStr, v_src_trns);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.createPaymntLineRetro (p_prsnid bigint, p_itmid bigint, p_amnt numeric, p_paydate character varying, p_paysource character varying, p_trnsType character varying, p_msspyid bigint, p_paydesc character varying, p_crncyid integer, p_dateStr character varying, p_pymt_vldty character varying, p_src_trns_id bigint, p_glDate character varying, p_who_rn bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_paydate character varying(21) := '';
	v_dateStr character varying(21) := '';
BEGIN
	v_paydate := to_char(to_timestamp(p_paydate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	v_dateStr := to_char(to_timestamp(p_dateStr, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	INSERT INTO pay.pay_itm_trnsctns_retro (person_id, item_id, amount_paid, paymnt_date, paymnt_source, pay_trns_type, created_by, creation_date, last_update_by, last_update_date, mass_pay_id, pymnt_desc, crncy_id, pymnt_vldty_status, src_py_trns_id, gl_date)
		VALUES (p_prsnid, p_itmid, p_amnt, v_paydate, p_paysource, p_trnsType, p_who_rn, v_dateStr, p_who_rn, v_dateStr, p_msspyid, p_paydesc, p_crncyid, p_pymt_vldty, p_src_trns_id, p_glDate);
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		--ROLLBACK;
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.getPaymntTrnsIDREtro (p_prsnid bigint, p_itmid bigint, p_amnt numeric, p_paydate character varying, p_dteEarned character varying, p_orgnlTrnsID bigint)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	v_paydate character varying(21) := '';
BEGIN
	v_paydate := to_char(to_timestamp(p_paydate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	SELECT
		pay_trns_id INTO v_res
	FROM
		pay.pay_itm_trnsctns
	WHERE (person_id = p_prsnid
		AND item_id = p_itmid
		AND amount_paid = p_amnt
		AND date_earned = p_dteEarned
		AND paymnt_date = v_paydate
		AND pymnt_vldty_status = 'VALID'
		AND src_py_trns_id = p_orgnlTrnsID);
	RETURN coalesce(v_res, - 1);
EXCEPTION
	WHEN OTHERS THEN
		RETURN - 1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION pay.hsPrsItmBlsBnUptdRetro (p_pytrnsid bigint, p_trnsdate character varying, p_bals_itm_id bigint, p_prsn_id bigint)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	v_trnsdate character varying(21) := '';
BEGIN
	v_trnsdate := to_char(to_timestamp(p_trnsdate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (char_length(v_trnsdate) > 10) THEN
		v_trnsdate := substr(v_trnsdate, 1, 10);
	END IF;
	SELECT
		count(a.bals_id) INTO v_res
	FROM
		pay.pay_balsitm_bals_retro a
	WHERE
		a.bals_itm_id = p_bals_itm_id
		AND a.person_id = p_prsn_id
		AND a.bals_date = v_trnsdate
		AND a.source_trns_ids LIKE '%,' || p_pytrnsid || ',%';
	IF coalesce(v_res, 0) > 0 THEN
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.hsMsPyBnRun (p_mspyid bigint)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res character varying(1) := '0';
BEGIN
	SELECT
		a.run_status INTO v_res
	FROM
		pay.pay_mass_pay_run_hdr a
	WHERE
		a.mass_pay_id = p_mspyid;
	IF coalesce(v_res, '0') = '1' THEN
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.hsMsPyGoneToGL (p_mspyid bigint)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res character varying(1) := '0';
BEGIN
	SELECT
		a.sent_to_gl INTO v_res
	FROM
		pay.pay_mass_pay_run_hdr a
	WHERE
		a.mass_pay_id = p_mspyid;
	IF coalesce(v_res, '0') = '1' THEN
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.hsPrsItmBlsBnUptd (p_pytrnsid bigint, p_trnsdate character varying, p_bals_itm_id bigint, p_prsn_id bigint)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	v_trnsdate character varying(21) := '';
BEGIN
	v_trnsdate := to_char(to_timestamp(p_trnsdate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (char_length(v_trnsdate) > 10) THEN
		v_trnsdate := substr(v_trnsdate, 1, 10);
	END IF;
	SELECT
		count(a.bals_id) INTO v_res
	FROM
		pay.pay_balsitm_bals a
	WHERE
		a.bals_itm_id = p_bals_itm_id
		AND a.person_id = p_prsn_id
		AND a.bals_date = v_trnsdate
		AND a.source_trns_ids LIKE '%,' || p_pytrnsid || ',%';
	IF coalesce(v_res, 0) > 0 THEN
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.hsPrsItmBlsBnUptdRetro (p_pytrnsid bigint, p_trnsdate character varying, p_bals_itm_id bigint, p_prsn_id bigint)
	RETURNS boolean
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
	v_trnsdate character varying(21) := '';
BEGIN
	v_trnsdate := to_char(to_timestamp(p_trnsdate, 'DD-Mon-YYYY HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS');
	IF (char_length(v_trnsdate) > 10) THEN
		v_trnsdate := substr(v_trnsdate, 1, 10);
	END IF;
	SELECT
		count(a.bals_id) INTO v_res
	FROM
		pay.pay_balsitm_bals_retro a
	WHERE
		a.bals_itm_id = p_bals_itm_id
		AND a.person_id = p_prsn_id
		AND a.bals_date = v_trnsdate
		AND a.source_trns_ids LIKE '%,' || p_pytrnsid || ',%';
	IF coalesce(v_res, 0) > 0 THEN
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_ms_pay_id (p_ms_py_nm character varying)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		mass_pay_id INTO v_res
	FROM
		pay.pay_mass_pay_run_hdr
	WHERE
		mass_pay_name ILIKE p_ms_py_nm;
	RETURN coalesce(v_res, - 1);
END;
$BODY$;

CREATE OR REPLACE FUNCTION pay.get_ms_pay_id (p_ms_py_nm character varying, p_org_id integer)
	RETURNS bigint
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_res bigint := - 1;
BEGIN
	SELECT
		mass_pay_id INTO v_res
	FROM
		pay.pay_mass_pay_run_hdr
	WHERE
		mass_pay_name ILIKE p_ms_py_nm
		AND org_id = p_org_id;
	RETURN coalesce(v_res, - 1);
END;
$BODY$;

