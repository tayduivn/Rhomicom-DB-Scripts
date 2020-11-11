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
		RETURN 'ERROR:APPRV_SALES:' || SQLERRM || v_reslt_1;
END;

$BODY$;

CREATE OR REPLACE FUNCTION scm.validatelns (p_docid bigint, p_doctype character varying)
	RETURNS character varying
	LANGUAGE 'plpgsql'
	COST 100 VOLATILE
	AS $BODY$
	<< outerblock >>
DECLARE
	v_srcDocType character varying(200) := '';
	v_cnsgmntIDs character varying(200) := '';
	v_dateStr character varying(21) := '';
	v_allwDues character varying(1) := '0';
	v_isPrevdlvrd character varying(1) := '0';
	v_itmID bigint := - 1;
	v_storeID bigint := - 1;
	v_lineid bigint := - 1;
	v_srclineID bigint := - 1;
	v_itmType character varying(200) := '';
	v_cntr integer := 0;
	v_srcDocID bigint := - 1;
	v_stckID bigint := - 1;
	v_tst1 numeric := 0;
	v_tst2 numeric := 0;
	v_reslt_1 text := '';
	v_nwCnsgIDs character varying(200) := '';
	v_ttlItmStckQty numeric := 0;
	v_ttlItmCnsgQty numeric := 0;
	v_kk1 numeric := 0;
	v_prsn_id bigint := - 1;
	v_pay_itm_id bigint := - 1;
	v_DocType character varying(200) := '';
	rd1 RECORD;
BEGIN
	v_dateStr := to_char(now(), 'DD-Mon-YYYY HH24:MI:SS');
	v_srcDocID := gst.getGnrlRecNm ('scm.scm_sales_invc_hdr', 'invc_hdr_id', 'src_doc_hdr_id', p_DocID)::bigint;
	v_srcDocType := gst.getGnrlRecNm ('scm.scm_sales_invc_hdr', 'invc_hdr_id', 'invc_type', v_srcDocID);
	v_allwDues := gst.getgnrlrecnm ('scm.scm_sales_invc_hdr', 'invc_hdr_id', 'allow_dues', p_DocID);
	FOR rd1 IN
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
		END alternate_item_name,
		REPLACE(a.cogs_acct_id || ',' || a.sales_rev_accnt_id || ',' || a.sales_ret_accnt_id || ',' || a.purch_ret_accnt_id || ',' || a.expense_accnt_id, '-1,-1,-1,-1,-1', b.cogs_acct_id || ',' || b.sales_rev_accnt_id || ',' || b.sales_ret_accnt_id || ',' || b.purch_ret_accnt_id || ',' || b.expense_accnt_id) itm_accnts,
		b.item_type,
		(
			CASE WHEN p_DocType IN ('Pro-Forma Invoice', 'Internal Item Request') THEN
				scm.get_One_LnTrnsctdQty (p_DocID, a.invc_det_ln_id)
			ELSE
				scm.get_One_AvlblSrcLnQty (a.src_line_id)
			END) lineAvlblQty
	FROM
		scm.scm_sales_invc_det a,
		inv.inv_itm_list b
	WHERE (a.invc_hdr_id = p_DocID
		AND a.invc_hdr_id > 0
		AND a.itm_id = b.item_id)
ORDER BY
	a.invc_det_ln_id,
	b.category_id LOOP
		v_itmID := rd1.itm_id;
		v_storeID := rd1.store_id;
		v_lineid := rd1.invc_det_ln_id;
		v_srclineID := rd1.src_line_id;
		v_itmType := rd1.item_type;
		v_stckID := inv.getItemStockID (v_itmID, v_storeID);
		v_cnsgmntIDs := rd1.consgmnt_ids;
		v_tst1 := rd1.doc_qty;
		v_tst2 := rd1.lineAvlblQty;
		IF (rd1.src_line_id > 0) THEN
			IF (v_tst1 > v_tst2 AND v_itmType != 'Services') THEN
				RETURN 'ERROR:Document Quantity in Row(' || (v_cntr + 1) || '::' || rd1.alternate_item_name || ') cannot EXCEED Available Source Doc. Quantity!';
			END IF;
		END IF;
		IF (v_tst1 > inv.getCnsgmtsQtySum (v_cnsgmntIDs)) THEN
			v_cnsgmntIDs := inv.getOldstItmCnsgmts (v_itmID, v_tst1, v_storeID);
			v_reslt_1 := scm.updateSalesLnCsgmtIDs (v_lineid, v_cnsgmntIDs);
		END IF;
		v_isPrevdlvrd := rd1.is_itm_delivered;
		IF (v_isPrevdlvrd = '0') THEN
			v_nwCnsgIDs := v_cnsgmntIDs;
			SELECT
				p_cnsIDs,
				p_res INTO v_nwCnsgIDs,
				v_ttlItmStckQty
			FROM
				scm.sumGridStckQtys (v_itmID, v_storeID, p_DocID, p_DocType);
			v_ttlItmCnsgQty := v_ttlItmStckQty;
			IF (v_DocType NOT IN ('Sales Return', 'Internal Item Request') AND v_itmType != 'Services' AND v_srcDocType != 'Sales Order') THEN
				v_kk1 := inv.getStockLstAvlblBls (v_stckID, v_dateStr);
				IF (v_tst1 > v_kk1 OR v_ttlItmStckQty > v_kk1) THEN
					RETURN 'ERROR:Quantity in Row(' || (v_cntr + 1) || '::' || rd1.alternate_item_name || ') cannot EXCEED Available Stock[' || inv.get_store_name (v_storeID::integer) || '] Quantity[' || v_kk1 || '] hence cannot be delivered!!';
				END IF;
				v_kk1 := inv.getCnsgmtsQtySum (v_nwCnsgIDs);
				IF (v_tst1 > v_kk1 OR v_ttlItmCnsgQty > v_kk1) THEN
					RETURN 'ERROR:Quantity in Row(' || (v_cntr + 1) || '::' || rd1.alternate_item_name || ') cannot EXCEED Available Quantity[' || v_kk1 || '] in the Selected Consignments[' || v_nwCnsgIDs || '] hence cannot be delivered!!';
				END IF;
			ELSIF (v_srcDocType = 'Sales Order'
					AND v_srclineID > 0) THEN
				v_kk1 := inv.getStockLstRsvdBls (v_stckID, v_dateStr);
				IF (v_tst1 > v_kk1) THEN
					RETURN 'ERROR:Quantity in Row(' || (v_cntr + 1) || '::' || rd1.alternate_item_name || ') cannot EXCEED Reserved Stock Quantity[' || v_kk1 || '] hence cannot be delivered!!';
				END IF;
				v_kk1 := inv.getCnsgmtsRsvdSum (v_cnsgmntIDs);
				IF (v_tst1 > v_kk1) THEN
					RETURN 'ERROR:Quantity in Row(' || (v_cntr + 1) || '::' || rd1.alternate_item_name || ') cannot EXCEED Reserved Quantity[' || v_kk1 || '] in the Selected Consignments hence cannot be delivered[' || v_cnsgmntIDs || ']!';
				END IF;
			END IF;
		END IF;
		v_prsn_id := rd1.lnkd_person_id;
		IF (v_allwDues = '1') THEN
			v_pay_itm_id := coalesce(NULLIF (gst.getGnrlRecNm ('org.org_pay_items', 'inv_item_id', 'item_id', v_itmID), ''), '-1')::bigint;
			--v_srcDocID := 1 / 0;
			IF (v_pay_itm_id > 0 AND v_prsn_id <= 0) THEN
				RETURN 'ERROR:Row(' || (v_cntr + 1) || '::' || rd1.alternate_item_name || ') must have a linked Person!';
			END IF;
		END IF;
		v_cntr := v_cntr + 1;
	END LOOP;
	RETURN 'SUCCESS:';
EXCEPTION
	WHEN OTHERS THEN
		RETURN 'ERROR:' || SQLERRM;
END;

$BODY$;

