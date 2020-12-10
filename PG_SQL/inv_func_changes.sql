CREATE OR REPLACE FUNCTION scm.recalcsmmrys(
	p_srcdocid bigint,
	p_srcdoctype character varying,
	p_cstmrid bigint,
	p_invcurid integer,
	p_docstatus character varying,
	p_org_id integer,
	p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
<< outerblock >>
  DECLARE
  v_txID           INTEGER                := -1;
  v_dscntID        INTEGER                := -1;
  v_grndAmnt       NUMERIC                := 0;
  v_pymntsAmnt     NUMERIC                := 0;
  v_blsAmnt        NUMERIC                := 0;
  v_smmryNm        CHARACTER VARYING(100) := '';
  v_smmryID        BIGINT                 := -1;
  v_codeCntr       INTEGER                := -1;
  v_rcvblHdrID     BIGINT                 := -1;
  v_SIDocID        BIGINT                 := -1;
  v_reslt_1        TEXT                   := '';
  vRD              RECORD;
  v_rcvblDoctype   CHARACTER VARYING(200) := '';
  v_strSrcDocType  CHARACTER VARYING(200) := '';
  v_txAmnts        NUMERIC                := 0;
  v_txAmnts1       NUMERIC                := 0;
  v_dscntAmnts     NUMERIC                := 0;
  v_snglDscnt      NUMERIC                := 0;
  v_dscntAmnts1    NUMERIC                := 0;
  v_extrChrgAmnts  NUMERIC                := 0;
  v_extrChrgAmnts1 NUMERIC                := 0;
  v_chrgID         INTEGER                := -1;
  v_isParnt        CHARACTER VARYING(1)   := '0';
  v_codeIDs        CHARACTER VARYING(100) := ',';
  v_codeIDArrys    TEXT[];
  v_actlblsAmnt    NUMERIC                := 0;
  v_ttlDpsts       NUMERIC                := 0;
  v_initAmnt       NUMERIC                := 0;
  v_tmp            CHARACTER VARYING(200) := '';
  v_unitAmnt       NUMERIC                := 0;
  v_sllngPrc       NUMERIC                := 0;
  v_qnty           NUMERIC                := 0;
  v_msgs           TEXT                   := '';

BEGIN
  v_rcvblHdrID := accb.get_ScmRcvblsDocHdrID(p_srcDocID, p_srcDocType, p_org_id);
  v_rcvblDoctype :=
      gst.getGnrlRecNm('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'rcvbls_invc_type', v_rcvblHdrID);

  v_grndAmnt := scm.getSalesDocGrndAmnt(p_srcDocID);
  -- Grand Total
  v_smmryNm := 'Grand Total';
  v_smmryID := scm.getSalesSmmryItmID('5Grand Total', -1,
                                      p_srcDocID, p_srcDocType);
  IF (v_smmryID <= 0) THEN
    v_reslt_1 := scm.createSmmryItm('5Grand Total', v_smmryNm, v_grndAmnt, -1,
                                    p_srcDocType, p_srcDocID, '1', p_who_rn);
  ELSE
    v_reslt_1 := scm.updateSmmryItm(v_smmryID, '5Grand Total', v_grndAmnt, '1', v_smmryNm, p_who_rn);
  END IF;
  --Total Payments
  v_blsAmnt := 0;
  v_pymntsAmnt := 0;
  v_SIDocID := gst.getGnrlRecNm('scm.scm_sales_invc_hdr', 'invc_hdr_id', 'src_doc_hdr_id', p_srcDocID)::BIGINT;
  v_strSrcDocType := gst.getGnrlRecNm('scm.scm_sales_invc_hdr', 'invc_hdr_id', 'invc_type', v_SIDocID);
  IF (p_srcDocType = 'Sales Invoice') THEN
    v_pymntsAmnt := scm.getRcvblsDocTtlPymnts(v_rcvblHdrID, v_rcvblDoctype);
    --pymntsAmnt = Global.getSalesDocRcvdPymnts(srcDocID, srcDocType);
    v_smmryNm := 'Total Payments Received';
    v_smmryID := scm.getSalesSmmryItmID('6Total Payments Received', -1, p_srcDocID, p_srcDocType);
    IF (v_smmryID <= 0) THEN
      v_reslt_1 :=
          scm.createSmmryItm('6Total Payments Received', v_smmryNm, v_pymntsAmnt, -1, p_srcDocType, p_srcDocID, '1',
                             p_who_rn);
    ELSE
      v_reslt_1 := scm.updateSmmryItm(v_smmryID, '6Total Payments Received', v_pymntsAmnt, '1', v_smmryNm, p_who_rn);
    END IF;
  ELSIF (p_srcDocType = 'Sales Return' AND v_strSrcDocType = 'Sales Invoice') THEN
    v_pymntsAmnt := scm.getRcvblsDocTtlPymnts(v_rcvblHdrID, v_rcvblDoctype);
    v_smmryNm := 'Total Amount Refunded';
    v_smmryID := scm.getSalesSmmryItmID('6Total Payments Received', -1, p_srcDocID, p_srcDocType);
    IF (v_smmryID <= 0) THEN
      v_reslt_1 := scm.createSmmryItm('6Total Payments Received', v_smmryNm, v_pymntsAmnt, -1,
                                      p_srcDocType, p_srcDocID, '1', p_who_rn);
    ELSE
      v_reslt_1 := scm.updateSmmryItm(v_smmryID, '6Total Payments Received', v_pymntsAmnt, '1', v_smmryNm, p_who_rn);
    END IF;
  END IF;
  v_codeCntr := 0;
  --Tax Codes
  v_txAmnts := 0;
  v_dscntAmnts := 0;
  v_extrChrgAmnts := 0;

  v_txAmnts1 := 0;
  v_dscntAmnts1 := 0;
  v_extrChrgAmnts1 := 0;

  UPDATE scm.scm_doc_amnt_smmrys
  SET smmry_amnt = 0
  WHERE (src_doc_type = p_srcDocType
    AND src_doc_hdr_id = p_srcDocID
    AND (code_id_behind > 0 OR substr(smmry_type, 1, 1) IN ('2', '3', '4')));

  FOR vRD IN (SELECT a.invc_det_ln_id,
                     a.itm_id,
                     a.doc_qty * a.rented_itm_qty                                          doc_qty,
                     a.unit_selling_price,
                     (a.doc_qty * a.unit_selling_price * a.rented_itm_qty)                 amnt,
                     a.store_id,
                     a.crncy_id,
                     (a.doc_qty - a.qty_trnsctd_in_dest_doc)                               avlbl_qty,
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
                     REPLACE(prs.get_prsn_surname(a.lnkd_person_id) || ' ('
                               || prs.get_prsn_loc_id(a.lnkd_person_id) || ')', ' ()', '') fullnm,
                     CASE WHEN a.alternate_item_name = '' THEN b.item_desc ELSE a.alternate_item_name END,
                     d.cat_name,
                     REPLACE(a.cogs_acct_id || ',' || a.sales_rev_accnt_id || ',' || a.sales_ret_accnt_id || ',' ||
                             a.purch_ret_accnt_id || ',' || a.expense_accnt_id,
                             '-1,-1,-1,-1,-1',
                             b.cogs_acct_id || ',' || b.sales_rev_accnt_id || ',' || b.sales_ret_accnt_id || ',' ||
                             b.purch_ret_accnt_id || ',' || b.expense_accnt_id)            itm_accnts,
                     b.item_type
              FROM scm.scm_sales_invc_det a,
                   inv.inv_itm_list b,
                   inv.unit_of_measure c,
                   inv.inv_product_categories d
              WHERE (a.invc_hdr_id = p_srcDocID AND a.invc_hdr_id > 0 AND a.itm_id = b.item_id AND
                     b.base_uom_id = c.uom_id AND d.cat_id = b.category_id)
              ORDER BY a.invc_det_ln_id, b.category_id)
    LOOP
      v_txID := vRD.tax_code_id;
      v_dscntID := vRD.dscnt_code_id;
      v_chrgID := vRD.chrg_code_id;
      v_unitAmnt := vRD.orgnl_selling_price;
	  v_sllngPrc := vRD.unit_selling_price;
      v_qnty := vRD.doc_qty;
      v_tmp := '';
      v_snglDscnt := 0;
      IF (v_dscntID > 0) THEN
        v_isParnt := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'is_parent', v_dscntID);
        IF (v_isParnt = '1') THEN
          v_codeIDs := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'child_code_ids', v_dscntID);
          v_codeIDArrys := string_to_array(BTRIM(v_codeIDs, ','), ',');
          v_snglDscnt := 0;
          FOR j IN 1.. array_length(v_codeIDArrys, 1)
            LOOP
              IF ((v_codeIDArrys [ j]::INTEGER) > 0) THEN
                v_snglDscnt := v_snglDscnt + scm.getDscntLessTax(v_txID,
                                                                 scm.getSalesDocCodesAmnt((v_codeIDArrys [ j]::INTEGER),
                                                                                          v_sllngPrc, 1));
                v_dscntAmnts1 := scm.getDscntLessTax(v_txID,
                                                     scm.getSalesDocCodesAmnt((v_codeIDArrys [ j]::INTEGER), v_sllngPrc,
                                                                              v_qnty));
                v_dscntAmnts := v_dscntAmnts + v_dscntAmnts1;
                v_tmp := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', (v_codeIDArrys [ j]::INTEGER));
                v_smmryID := scm.getSalesSmmryItmID('3Discount', (v_codeIDArrys [ j]::INTEGER),
                                                    p_srcDocID, p_srcDocType);
                IF (v_smmryID <= 0 AND v_dscntAmnts1 > 0) THEN
                  v_reslt_1 :=
                      scm.createSmmryItm('3Discount', v_tmp, v_dscntAmnts1, (v_codeIDArrys [ j]::INTEGER), p_srcDocType,
                                         p_srcDocID, '1', p_who_rn);
                ELSIF (v_dscntAmnts1 > 0) THEN
                  v_reslt_1 := scm.updateSmmryItmAddOn(v_smmryID, '3Discount', v_dscntAmnts1, '1', v_tmp, p_who_rn);
                END IF;
                v_codeCntr := v_codeCntr + 1;
              END IF;
            END LOOP;
        ELSE
          v_snglDscnt := scm.getDscntLessTax(v_txID, scm.getSalesDocCodesAmnt(v_dscntID, v_sllngPrc, 1));
          v_dscntAmnts1 := scm.getDscntLessTax(v_txID, scm.getSalesDocCodesAmnt(v_dscntID, v_sllngPrc, v_qnty));
          v_dscntAmnts := v_dscntAmnts + v_dscntAmnts1;
          --MessageBox.Show(dscntAmnts1.ToString());
          v_tmp = gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_dscntID);
          v_smmryID = scm.getSalesSmmryItmID('3Discount', v_dscntID, p_srcDocID, p_srcDocType);
          IF (v_smmryID <= 0 AND v_dscntAmnts1 > 0) THEN
            v_reslt_1 := scm.createSmmryItm('3Discount', v_tmp, v_dscntAmnts1, v_dscntID, p_srcDocType, p_srcDocID, '1',
                                            p_who_rn);
          ELSIF (v_dscntAmnts1 > 0) THEN
            v_reslt_1 := scm.updateSmmryItmAddOn(v_smmryID, '3Discount', v_dscntAmnts1, '', v_tmp, p_who_rn);
          END IF;
          v_codeCntr := v_codeCntr + 1;
        END IF;
        --codeCntr++;
      END IF;

      IF (v_txID > 0) THEN
        v_isParnt := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'is_parent', v_txID);
        IF (v_isParnt = '1') THEN
          v_codeIDs := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'child_code_ids', v_txID);
          v_codeIDArrys := string_to_array(BTRIM(v_codeIDs, ','), ',');
          --snglDscnt = 0;

          FOR j IN 1.. array_length(v_codeIDArrys, 1)
            LOOP
              IF ((v_codeIDArrys [ j]::INTEGER) > 0) THEN
                v_txAmnts1 := scm.getSalesDocCodesAmnt((v_codeIDArrys [ j]::INTEGER), v_unitAmnt - v_snglDscnt, v_qnty);
                v_txAmnts := v_txAmnts + v_txAmnts1;
                v_tmp := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', (v_codeIDArrys [ j]::INTEGER));
                v_smmryID := scm.getSalesSmmryItmID('2Tax', (v_codeIDArrys [ j]::INTEGER), p_srcDocID, p_srcDocType);
                IF (v_smmryID <= 0 AND v_txAmnts1 > 0) THEN
                  v_reslt_1 := scm.createSmmryItm('2Tax', v_tmp, v_txAmnts1, (v_codeIDArrys [ j]::INTEGER),
                                                  p_srcDocType, p_srcDocID, '1', p_who_rn);
                ELSIF (v_txAmnts1 > 0) THEN
                  v_reslt_1 := scm.updateSmmryItmAddOn(v_smmryID, '2Tax', v_txAmnts1, '1', v_tmp, p_who_rn);
                END IF;
                v_codeCntr := v_codeCntr + 1;
              END IF;
            END LOOP;
        ELSE
          v_txAmnts1 := scm.getSalesDocCodesAmnt(v_txID, v_unitAmnt - v_snglDscnt, v_qnty);
          v_txAmnts := v_txAmnts + v_txAmnts1;
          v_tmp := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_txID);

          v_smmryID := scm.getSalesSmmryItmID('2Tax', v_txID, p_srcDocID, p_srcDocType);
          IF (v_smmryID <= 0 AND v_txAmnts1 > 0) THEN
            v_reslt_1 := scm.createSmmryItm('2Tax', v_tmp, v_txAmnts1, v_txID,
                                            p_srcDocType, p_srcDocID, '1', p_who_rn);
          ELSIF (v_txAmnts1 > 0) THEN
            v_reslt_1 := scm.updateSmmryItmAddOn(v_smmryID, '2Tax', v_txAmnts1, '1', v_tmp, p_who_rn);
          END IF;
          v_codeCntr := v_codeCntr + 1;
        END IF;
      END IF;

      IF (v_chrgID > 0) THEN
        v_isParnt := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'is_parent', v_chrgID);
        IF (v_isParnt = '1') THEN
          v_codeIDs := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'child_code_ids', v_chrgID);
          v_codeIDArrys := string_to_array(BTRIM(v_codeIDs, ','), ',');
          --snglDscnt = 0;
          FOR j IN 1.. array_length(v_codeIDArrys, 1)
            LOOP
              IF ((v_codeIDArrys [ j]::INTEGER) > 0) THEN
                v_extrChrgAmnts1 := scm.getSalesDocCodesAmnt((v_codeIDArrys [ j]::INTEGER), v_unitAmnt, v_qnty);
                v_extrChrgAmnts := v_extrChrgAmnts + v_extrChrgAmnts1;
                v_tmp := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', (v_codeIDArrys [ j]::INTEGER));
                v_smmryID :=
                    scm.getSalesSmmryItmID('4Extra Charge', (v_codeIDArrys [ j]::INTEGER), p_srcDocID, p_srcDocType);
                IF (v_smmryID <= 0 AND v_extrChrgAmnts1 > 0) THEN
                  v_reslt_1 :=
                      scm.createSmmryItm('4Extra Charge', v_tmp, v_extrChrgAmnts1, (v_codeIDArrys [ j]::INTEGER),
                                         p_srcDocType, p_srcDocID, '1', p_who_rn);
                ELSIF (v_extrChrgAmnts1 > 0) THEN
                  v_reslt_1 :=
                      scm.updateSmmryItmAddOn(v_smmryID, '4Extra Charge', v_extrChrgAmnts1, '1', v_tmp, p_who_rn);
                END IF;
                v_codeCntr := v_codeCntr + 1;
              END IF;
            END LOOP;
        ELSE
          v_extrChrgAmnts1 := scm.getSalesDocCodesAmnt(v_chrgID, v_unitAmnt, v_qnty);
          v_extrChrgAmnts := v_extrChrgAmnts + v_extrChrgAmnts1;
          v_tmp := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_chrgID);

          v_smmryID := scm.getSalesSmmryItmID('4Extra Charge', v_chrgID, p_srcDocID, p_srcDocType);
          IF (v_smmryID <= 0 AND v_extrChrgAmnts1 > 0) THEN
            v_reslt_1 :=
                scm.createSmmryItm('4Extra Charge', v_tmp, v_extrChrgAmnts1, v_chrgID, p_srcDocType, p_srcDocID, '1',
                                   p_who_rn);
          ELSIF (v_extrChrgAmnts1 > 0) THEN
            v_reslt_1 := scm.updateSmmryItmAddOn(v_smmryID, '4Extra Charge', v_extrChrgAmnts1, '1', v_tmp, p_who_rn);
          END IF;
          v_codeCntr := v_codeCntr + 1;
        END IF;
      END IF;
    END LOOP;

  IF (v_txAmnts <= 0) THEN
    v_reslt_1 := scm.deleteSalesSmmryItm(p_srcDocID, p_srcDocType, '2Tax');
  END IF;

  IF (v_dscntAmnts <= 0) THEN
    v_reslt_1 := scm.deleteSalesSmmryItm(p_srcDocID, p_srcDocType, '3Discount');
  END IF;

  IF (v_extrChrgAmnts <= 0) THEN
    v_reslt_1 := scm.deleteSalesSmmryItm(p_srcDocID, p_srcDocType, '4Extra Charge');
  END IF;
  v_reslt_1 := scm.deleteZeroSmmryItms(p_srcDocID, p_srcDocType);
  --Initial Amount
  v_initAmnt := 0;
  IF (v_txAmnts <= 0 AND v_dscntAmnts <= 0 AND v_extrChrgAmnts <= 0) THEN
    v_reslt_1 := scm.deleteSalesSmmryItm(p_srcDocID, p_srcDocType, '1Initial Amount');
  ELSIF (v_codeCntr > 0) THEN
    v_smmryNm := 'Initial Amount';
    v_smmryID := scm.getSalesSmmryItmID('1Initial Amount', -1, p_srcDocID, p_srcDocType);
    v_initAmnt := v_grndAmnt;
    IF (v_smmryID <= 0) THEN
      v_reslt_1 := scm.createSmmryItm('1Initial Amount', v_smmryNm, v_initAmnt, -1,
                                      p_srcDocType, p_srcDocID, '1', p_who_rn);
    ELSE
      v_reslt_1 := scm.updateSmmryItm(v_smmryID, '1Initial Amount', v_initAmnt, '1', v_smmryNm, p_who_rn);
    END IF;
  END IF;

  -- Grand Total
  v_grndAmnt := v_grndAmnt + v_txAmnts + v_extrChrgAmnts - v_dscntAmnts;
  v_smmryNm := 'Grand Total';
  v_smmryID := scm.getSalesSmmryItmID('5Grand Total', -1,
                                      p_srcDocID, p_srcDocType);
  IF (v_smmryID <= 0) THEN
    v_reslt_1 := scm.createSmmryItm('5Grand Total', v_smmryNm, v_grndAmnt, -1,
                                    p_srcDocType, p_srcDocID, '1', p_who_rn);
  ELSE
    v_reslt_1 := scm.updateSmmryItm(v_smmryID, '5Grand Total', v_grndAmnt, '1', v_smmryNm, p_who_rn);
  END IF;

  --Total Payments
  IF (p_srcDocType = 'Sales Invoice') THEN
    --Change Given/Outstanding Balance
    v_blsAmnt := v_grndAmnt - v_pymntsAmnt;
    IF (round(v_blsAmnt, 2) >= 0.00) THEN
      v_smmryNm := 'Outstanding Balance';
    ELSE
      v_smmryNm := 'Change Given to Customer';
    END IF;
    v_smmryID := scm.getSalesSmmryItmID('7Change/Balance', -1, p_srcDocID, p_srcDocType);
    IF (v_smmryID <= 0) THEN
      v_reslt_1 :=
          scm.createSmmryItm('7Change/Balance', v_smmryNm, v_blsAmnt, -1, p_srcDocType, p_srcDocID, '1', p_who_rn);
    ELSE
      v_reslt_1 := scm.updateSmmryItm(v_smmryID, '7Change/Balance', v_blsAmnt, '1', v_smmryNm, p_who_rn);
    END IF;
    --Customer's Total Deposits
    v_ttlDpsts := scm.getCstmrDpsts(p_cstmrID, p_invCurID);
    v_smmryNm := 'Total Deposits';
    v_smmryID := scm.getSalesSmmryItmID('8Deposits', -1, p_srcDocID, p_srcDocType);
    IF (v_smmryID <= 0) THEN
      v_reslt_1 := scm.createSmmryItm('8Deposits', v_smmryNm, v_ttlDpsts, -1, p_srcDocType, p_srcDocID, '1', p_who_rn);
    ELSE
      v_reslt_1 := scm.updateSmmryItm(v_smmryID, '8Deposits', v_ttlDpsts, '1', v_smmryNm, p_who_rn);
    END IF;

    --Actual Change or Balance
    v_actlblsAmnt := v_blsAmnt - v_ttlDpsts;
    IF (round(v_actlblsAmnt, 2) >= 0.00) THEN
      v_smmryNm := 'Actual Outstanding Balance';
    ELSE
      v_smmryNm := 'Amount to be Refunded to Customer';
    END IF;
    v_smmryID := scm.getSalesSmmryItmID('9Actual_Change/Balance', -1, p_srcDocID, p_srcDocType);
    IF (v_smmryID <= 0) THEN
      v_reslt_1 := scm.createSmmryItm('9Actual_Change/Balance', v_smmryNm, v_actlblsAmnt, -1,
                                      p_srcDocType, p_srcDocID, '1', p_who_rn);
    ELSE
      v_reslt_1 := scm.updateSmmryItm(v_smmryID, '9Actual_Change/Balance', v_actlblsAmnt, '1', v_smmryNm, p_who_rn);
    END IF;
  ELSIF (p_srcDocType = 'Sales Return' AND v_strSrcDocType = 'Sales Invoice') THEN
    --Change Given/Outstanding Balance
    v_blsAmnt := v_grndAmnt - v_pymntsAmnt;
    IF (round(v_blsAmnt, 2) >= 0.00) THEN
      v_smmryNm := 'Outstanding Balance';
    ELSE
      v_smmryNm := 'Change Received from Customer';
    END IF;
    v_smmryID := scm.getSalesSmmryItmID('7Change/Balance', -1,
                                        p_srcDocID, p_srcDocType);
    IF (v_smmryID <= 0) THEN
      v_reslt_1 := scm.createSmmryItm('7Change/Balance', v_smmryNm, v_blsAmnt, -1,
                                      p_srcDocType, p_srcDocID, '1', p_who_rn);
    ELSE
      v_reslt_1 := scm.updateSmmryItm(v_smmryID, '7Change/Balance', v_blsAmnt, '1', v_smmryNm, p_who_rn);
    END IF;
  END IF;
  v_reslt_1 := scm.roundSmmryItms(p_srcDocID, p_srcDocType);

  RETURN 'SUCCESS:';
EXCEPTION
  WHEN OTHERS
    THEN
      RETURN 'ERROR:' || SQLERRM || '::MSGs::' || v_msgs;
END;
$BODY$;

CREATE OR REPLACE FUNCTION scm.approve_sales_prchsdoc(
	p_dochdrid bigint,
	p_dockind character varying,
	p_orgid integer,
	p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
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
			
		v_reslt_1 := accb.isTransPrmttd (v_orgid, v_dfltRcvblAcntID, v_docDte, 200);
		IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
			RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
		END IF;	
		v_reslt_1 := accb.isTransPrmttd (v_orgid, v_dfltLbltyAccnt, v_docDte, 200);
		IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
			RAISE EXCEPTION
					USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
		END IF;
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

CREATE OR REPLACE FUNCTION accb.creatercvblsdocdet(
	p_smmryid bigint,
	p_hdrid bigint,
	p_linetype character varying,
	p_linedesc character varying,
	p_entrdamnt numeric,
	p_entrdcurrid integer,
	p_codebhnd integer,
	p_doctype character varying,
	p_autocalc character varying,
	p_incrdcrs1 character varying,
	p_costngid integer,
	p_incrdcrs2 character varying,
	p_blncgaccntid integer,
	p_prepaydochdrid bigint,
	p_vldystatus character varying,
	p_orgnllnid bigint,
	p_funccurrid integer,
	p_accntcurrid integer,
	p_funccurrrate numeric,
	p_accntcurrrate numeric,
	p_funccurramnt numeric,
	p_accntcurramnt numeric,
	p_initial_amnt_line_id bigint,
	p_line_qty numeric,
	p_unit_price numeric,
	p_ref_doc_number character varying,
	p_slctd_amnt_brkdwns character varying,
	p_tax_code_id integer,
	p_whtax_code_id integer,
	p_dscnt_code_id integer,
	p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
<< outerblock >>
  DECLARE
  v_reslt_1       TEXT                    := '';
  v_smmryID       BIGINT                  := -1;
  c_codeIDs       CHARACTER VARYING(4000) := '';
  v_codeIDs       CHARACTER VARYING(4000)[];
  v_ArryLen       INTEGER                 := 0;
  v_tax_code_id   INTEGER                 := -1;
  v_tax_accid     INTEGER                 := -1;
  v_txsmmryNm     CHARACTER VARYING(200)  := '';
  v_dcntAMnt      NUMERIC                 := 0;
  v_codeAmnt      NUMERIC                 := 0;
  v_lnSmmryLnID   BIGINT                  := -1;
  c_accnts        CHARACTER VARYING(4000) := '';
  v_accnts        CHARACTER VARYING(4000)[];
  v_funcCurrAmnt  NUMERIC                 := 0;
  v_accntCurrAmnt NUMERIC                 := 0;
  v_txlineDesc    CHARACTER VARYING(300)  := '';
  p_orgid         INTEGER                 := -1;
  v_dscntAmnts     NUMERIC                := 0;
  v_dscntAmnts1     NUMERIC                := 0;
  v_snglDscnt      NUMERIC                := 0;
  v_sllngPrc       NUMERIC                := 0;
BEGIN
  v_reslt_1 := accb.createRcvblsDocDet1(p_smmryID, p_hdrID, p_lineType, p_lineDesc, p_entrdAmnt,
                                        p_entrdCurrID, p_codeBhnd, p_docType, p_autoCalc, p_incrDcrs1,
                                        p_costngID, p_incrDcrs2, p_blncgAccntID, p_prepayDocHdrID, p_vldyStatus,
                                        p_orgnlLnID, p_funcCurrID, p_accntCurrID, p_funcCurrRate, p_accntCurrRate,
                                        p_funcCurrAmnt,
                                        p_accntCurrAmnt, p_initial_amnt_line_id, p_line_qty, p_unit_price,
                                        p_ref_doc_number,
                                        p_slctd_amnt_brkdwns, p_tax_code_id, p_whtax_code_id, p_dscnt_code_id,
                                        p_who_rn);
  IF v_reslt_1 NOT LIKE 'SUCCESS:%'
  THEN
    RAISE EXCEPTION USING
      ERRCODE = 'RHERR',
      MESSAGE = v_reslt_1,
      HINT = v_reslt_1;
  END IF;

  IF p_initial_amnt_line_id <= 0 AND p_lineType = '1Initial Amount' THEN
    p_orgid := gst.getGnrlRecNm('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'org_id', p_hdrID)::INTEGER;
    v_smmryID := p_smmryID;
	
	v_snglDscnt :=0;
    IF (p_tax_code_id > 0 AND scm.istaxaparent(p_tax_code_id) = '1') THEN
      c_codeIDs := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'child_code_ids', p_tax_code_id);
      v_codeIDs := string_to_array(BTRIM(c_codeIDs, ', '), ',');

      v_ArryLen := array_length(v_codeIDs, 1);
      FOR y IN 1..v_ArryLen
        LOOP
          v_tax_code_id := v_codeIDs [ y];
          v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);
          --v_dcntAMnt := scm.getSalesDocCodesAmnt(p_dscnt_code_id, p_entrdAmnt, 1);
          v_codeAmnt := v_codeAmnt + scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt - v_snglDscnt, 1);    
          END LOOP;
    ELSIF (p_tax_code_id > 0) THEN
      v_tax_code_id := p_tax_code_id;
      v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);
      --v_dcntAMnt := scm.getSalesDocCodesAmnt(p_dscnt_code_id, p_entrdAmnt, 1);
      v_codeAmnt := scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt - v_snglDscnt, 1);
    END IF;

	v_sllngPrc := v_codeAmnt + p_entrdAmnt;

    IF (p_dscnt_code_id > 0 AND scm.istaxaparent(p_dscnt_code_id) = '1') THEN
      c_codeIDs := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'child_code_ids', p_dscnt_code_id);
      v_codeIDs := string_to_array(BTRIM(c_codeIDs, ', '), ',');
      
      v_ArryLen := array_length(v_codeIDs, 1);
      FOR y IN 1..v_ArryLen
        LOOP
          v_tax_code_id := v_codeIDs [y];
          v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);

		  v_snglDscnt := scm.getDscntLessTax(p_tax_code_id, scm.getSalesDocCodesAmnt(v_tax_code_id, v_sllngPrc, 1));
          v_dscntAmnts1 := scm.getDscntLessTax(p_tax_code_id, scm.getSalesDocCodesAmnt(v_tax_code_id, v_sllngPrc, 1));
          v_dscntAmnts := v_dscntAmnts + v_dscntAmnts1;
          
		  v_codeAmnt := v_dscntAmnts;--scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt, 1);
          v_lnSmmryLnID := accb.getRcvblsLnDetID('3Discount', v_tax_code_id, v_smmryID);
          c_accnts := accb.getRcvblBalncnAccnt('3Discount', v_tax_code_id, -1, -1, p_docType, p_orgid);
          v_accnts := string_to_array(BTRIM(c_accnts, '; '), ';');
          v_funcCurrAmnt := v_codeAmnt * p_funcCurrRate;
          v_accntCurrAmnt := v_codeAmnt * p_accntCurrRate;
          v_txlineDesc := v_txsmmryNm || ' on ' || p_lineDesc || ' (' || p_entrdAmnt || ')';
          v_tax_accid := org.get_accnt_id_frmaccnt(p_costngID, v_accnts [ 4]::INTEGER);
          IF (v_lnSmmryLnID <= 0) THEN
            v_lnSmmryLnID := nextval('accb.accb_rcvbl_amnt_smmrys_rcvbl_smmry_id_seq');
            v_reslt_1 := accb.createRcvblsDocDet1(v_lnSmmryLnID, p_hdrID, '3Discount', v_txlineDesc, v_codeAmnt,
                                                  p_entrdCurrID, v_tax_code_id, p_docType, '1', v_accnts [ 3],
                                                  v_tax_accid, v_accnts [ 1],
                                                  p_blncgAccntID, -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID,
                                                  p_funcCurrRate, p_accntCurrRate, v_funcCurrAmnt,
                                                  v_accntCurrAmnt, v_smmryID, 1, v_codeAmnt, p_ref_doc_number,
                                                  ',', -1, -1, -1, p_who_rn);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
              RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            END IF;
          ELSE
            v_reslt_1 := accb.updtRcvblsDocDet1(v_lnSmmryLnID, p_hdrID, '3Discount', v_txlineDesc, v_codeAmnt,
                                                p_entrdCurrID, v_tax_code_id, p_docType, '1', v_accnts [ 3],
                                                v_tax_accid, v_accnts [ 1], p_blncgAccntID, -1, p_vldyStatus,
                                                -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate, p_accntCurrRate,
                                                v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID, 1, v_codeAmnt,
                                                p_ref_doc_number, ',', -1, -1, -1, p_who_rn);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
              RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            END IF;
          END IF;
          END LOOP;
    ELSIF (p_dscnt_code_id > 0) THEN
      v_tax_code_id := p_dscnt_code_id;
      v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);
	  
		  v_snglDscnt := scm.getDscntLessTax(p_tax_code_id, scm.getSalesDocCodesAmnt(v_tax_code_id, v_sllngPrc, 1));
          v_dscntAmnts1 := scm.getDscntLessTax(p_tax_code_id, scm.getSalesDocCodesAmnt(v_tax_code_id, v_sllngPrc, 1));
          v_dscntAmnts := v_dscntAmnts + v_dscntAmnts1;

      v_codeAmnt := v_dscntAmnts;--scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt, 1);
      v_lnSmmryLnID := accb.getRcvblsLnDetID('3Discount', v_tax_code_id, v_smmryID);
      c_accnts := accb.getRcvblBalncnAccnt('3Discount', v_tax_code_id, -1, -1, p_docType, p_orgid);
      v_accnts := string_to_array(BTRIM(c_accnts, '; '), ';');
      v_funcCurrAmnt := v_codeAmnt * p_funcCurrRate;
      v_accntCurrAmnt := v_codeAmnt * p_accntCurrRate;
      v_txlineDesc := v_txsmmryNm || ' on ' || p_lineDesc || ' (' || p_entrdAmnt || ')';
      v_tax_accid := org.get_accnt_id_frmaccnt(p_costngID, v_accnts [ 4]::INTEGER);

      IF (v_lnSmmryLnID <= 0) THEN
        v_lnSmmryLnID := nextval('accb.accb_rcvbl_amnt_smmrys_rcvbl_smmry_id_seq');
        v_reslt_1 := accb.createRcvblsDocDet1(v_lnSmmryLnID, p_hdrID, '3Discount', v_txlineDesc, v_codeAmnt,
                                              p_entrdCurrID, v_tax_code_id, p_docType, '1', v_accnts [ 3],
                                              v_tax_accid, v_accnts [ 1],
                                              p_blncgAccntID, -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID,
                                              p_funcCurrRate, p_accntCurrRate, v_funcCurrAmnt,
                                              v_accntCurrAmnt, v_smmryID, 1, v_codeAmnt, p_ref_doc_number,
                                              ',', -1, -1, -1, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
          RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = v_reslt_1,
            HINT = v_reslt_1;
        END IF;
      ELSE
        v_reslt_1 := accb.updtRcvblsDocDet1(v_lnSmmryLnID, p_hdrID, '3Discount', v_txlineDesc, v_codeAmnt,
                                            p_entrdCurrID, v_tax_code_id, p_docType, '1', v_accnts [ 3],
                                            v_tax_accid, v_accnts [ 1], p_blncgAccntID, -1, p_vldyStatus,
                                            -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate, p_accntCurrRate,
                                            v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID, 1, v_codeAmnt,
                                            p_ref_doc_number, ',', -1, -1, -1, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
          RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = v_reslt_1,
            HINT = v_reslt_1;
        END IF;
      END IF;
    END IF;

    IF (p_tax_code_id > 0 AND scm.istaxaparent(p_tax_code_id) = '1') THEN
      c_codeIDs := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'child_code_ids', p_tax_code_id);
      v_codeIDs := string_to_array(BTRIM(c_codeIDs, ', '), ',');

      v_ArryLen := array_length(v_codeIDs, 1);
      FOR y IN 1..v_ArryLen
        LOOP
          v_tax_code_id := v_codeIDs [ y];
          v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);
          --v_dcntAMnt := scm.getSalesDocCodesAmnt(p_dscnt_code_id, p_entrdAmnt, 1);
          v_codeAmnt := scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt - v_snglDscnt, 1);
          v_lnSmmryLnID := accb.getRcvblsLnDetID('2Tax', v_tax_code_id, v_smmryID);
          c_accnts := accb.getRcvblBalncnAccnt('2Tax', v_tax_code_id, -1, -1, p_docType, p_orgid);
          --v_reslt_1 := ':c_accnts:' || c_accnts;
          --v_lnSmmryLnID := 1 / 0;
          v_accnts := string_to_array(BTRIM(c_accnts, '; '), ';');
          v_funcCurrAmnt := v_codeAmnt * p_funcCurrRate;
          v_accntCurrAmnt := v_codeAmnt * p_accntCurrRate;
          v_txlineDesc := v_txsmmryNm || ' on ' || p_lineDesc || ' (' || p_entrdAmnt || ')';
          v_tax_accid := org.get_accnt_id_frmaccnt(p_costngID, v_accnts [ 4]::INTEGER);
          IF (v_lnSmmryLnID <= 0) THEN
            v_lnSmmryLnID := nextval('accb.accb_rcvbl_amnt_smmrys_rcvbl_smmry_id_seq');
            v_reslt_1 := accb.createRcvblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt,
                                                  p_entrdCurrID, v_tax_code_id, p_docType, '1', v_accnts [ 3],
                                                  v_tax_accid, v_accnts [ 1],
                                                  p_blncgAccntID, -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID,
                                                  p_funcCurrRate, p_accntCurrRate, v_funcCurrAmnt,
                                                  v_accntCurrAmnt, v_smmryID, 1, v_codeAmnt, p_ref_doc_number,
                                                  ',', -1, -1, -1, p_who_rn);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
              RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            END IF;
          ELSE
            v_reslt_1 := accb.updtRcvblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt,
                                                p_entrdCurrID, v_tax_code_id, p_docType, '1', v_accnts [ 3],
                                                v_tax_accid, v_accnts [ 1], p_blncgAccntID, -1, p_vldyStatus,
                                                -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate, p_accntCurrRate,
                                                v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID, 1, v_codeAmnt,
                                                p_ref_doc_number, ',', -1, -1, -1, p_who_rn);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
              RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            END IF;
          END IF;
          END LOOP;
    ELSIF (p_tax_code_id > 0) THEN
      v_tax_code_id := p_tax_code_id;
      v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);
      --v_dcntAMnt := scm.getSalesDocCodesAmnt(p_dscnt_code_id, p_entrdAmnt, 1);
      v_codeAmnt := scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt - v_snglDscnt, 1);
      v_lnSmmryLnID := accb.getRcvblsLnDetID('2Tax', v_tax_code_id, v_smmryID);
      c_accnts := accb.getRcvblBalncnAccnt('2Tax', v_tax_code_id, -1, -1, p_docType, p_orgid);
      v_accnts := string_to_array(BTRIM(c_accnts, '; '), ';');
      v_funcCurrAmnt := v_codeAmnt * p_funcCurrRate;
      v_accntCurrAmnt := v_codeAmnt * p_accntCurrRate;
      v_txlineDesc := v_txsmmryNm || ' on ' || p_lineDesc || ' (' || p_entrdAmnt || ')';
      v_tax_accid := org.get_accnt_id_frmaccnt(p_costngID, v_accnts [ 4]::INTEGER);
      IF (v_lnSmmryLnID <= 0) THEN
        v_lnSmmryLnID := nextval('accb.accb_rcvbl_amnt_smmrys_rcvbl_smmry_id_seq');
        v_reslt_1 := accb.createRcvblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt,
                                              p_entrdCurrID, v_tax_code_id, p_docType, '1', v_accnts [ 3],
                                              v_tax_accid, v_accnts [ 1],
                                              p_blncgAccntID, -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID,
                                              p_funcCurrRate, p_accntCurrRate, v_funcCurrAmnt,
                                              v_accntCurrAmnt, v_smmryID, 1, v_codeAmnt, p_ref_doc_number,
                                              ',', -1, -1, -1, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
          RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = v_reslt_1,
            HINT = v_reslt_1;
        END IF;
      ELSE
        v_reslt_1 := accb.updtRcvblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt,
                                            p_entrdCurrID, v_tax_code_id, p_docType, '1', v_accnts [ 3],
                                            v_tax_accid, v_accnts [ 1], p_blncgAccntID, -1, p_vldyStatus,
                                            -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate, p_accntCurrRate,
                                            v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID, 1, v_codeAmnt,
                                            p_ref_doc_number, ',', -1, -1, -1, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
          RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = v_reslt_1,
            HINT = v_reslt_1;
        END IF;
      END IF;
    END IF;
    
    IF (p_whtax_code_id > 0 AND scm.istaxaparent(p_whtax_code_id) = '1') THEN
      c_codeIDs := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'child_code_ids', p_whtax_code_id);
      v_codeIDs := string_to_array(BTRIM(c_codeIDs, ', '), ',');
      
      v_ArryLen := array_length(v_codeIDs, 1);
      FOR y IN 1..v_ArryLen
        LOOP
          v_tax_code_id := v_codeIDs [ y];
          v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);
          --v_dcntAMnt := scm.getSalesDocCodesAmnt(p_dscnt_code_id, p_entrdAmnt, 1);
          v_codeAmnt := scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt - v_snglDscnt, 1);
          v_lnSmmryLnID := accb.getRcvblsLnDetID('2Tax', v_tax_code_id, v_smmryID);
          c_accnts := accb.getRcvblBalncnAccnt('2Tax', v_tax_code_id, -1, -1, p_docType, p_orgid);
          v_accnts := string_to_array(BTRIM(c_accnts, '; '), ';');
          v_funcCurrAmnt := v_codeAmnt * p_funcCurrRate;
          v_accntCurrAmnt := v_codeAmnt * p_accntCurrRate;
          v_txlineDesc := v_txsmmryNm || ' on ' || p_lineDesc || ' (' || p_entrdAmnt || ')';
          v_tax_accid := org.get_accnt_id_frmaccnt(p_costngID, v_accnts [ 4]::INTEGER);
          IF (v_lnSmmryLnID <= 0) THEN
            v_lnSmmryLnID := nextval('accb.accb_rcvbl_amnt_smmrys_rcvbl_smmry_id_seq');
            v_reslt_1 := accb.createRcvblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt,
                                                  p_entrdCurrID, v_tax_code_id, p_docType, '1', v_accnts [ 3],
                                                  v_tax_accid, v_accnts [ 1],
                                                  p_blncgAccntID, -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID,
                                                  p_funcCurrRate, p_accntCurrRate, v_funcCurrAmnt,
                                                  v_accntCurrAmnt, v_smmryID, 1, v_codeAmnt, p_ref_doc_number,
                                                  ',', -1, -1, -1, p_who_rn);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
              RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            END IF;
          ELSE
            v_reslt_1 := accb.updtRcvblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt,
                                                p_entrdCurrID, v_tax_code_id, p_docType, '1', v_accnts [ 3],
                                                v_tax_accid, v_accnts [ 1], p_blncgAccntID, -1, p_vldyStatus,
                                                -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate, p_accntCurrRate,
                                                v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID, 1, v_codeAmnt,
                                                p_ref_doc_number, ',', -1, -1, -1, p_who_rn);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
              RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            END IF;
          END IF;
          END LOOP;
    ELSIF (p_whtax_code_id > 0) THEN
      v_tax_code_id := p_whtax_code_id;
      v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);
      --v_dcntAMnt := scm.getSalesDocCodesAmnt(p_dscnt_code_id, p_entrdAmnt, 1);
      v_codeAmnt := scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt - v_snglDscnt, 1);
      v_lnSmmryLnID := accb.getRcvblsLnDetID('2Tax', v_tax_code_id, v_smmryID);
      c_accnts := accb.getRcvblBalncnAccnt('2Tax', v_tax_code_id, -1, -1, p_docType, p_orgid);
      v_accnts := string_to_array(BTRIM(c_accnts, '; '), ';');
      v_funcCurrAmnt := v_codeAmnt * p_funcCurrRate;
      v_accntCurrAmnt := v_codeAmnt * p_accntCurrRate;
      v_txlineDesc := v_txsmmryNm || ' on ' || p_lineDesc || ' (' || p_entrdAmnt || ')';
      v_tax_accid := org.get_accnt_id_frmaccnt(p_costngID, v_accnts [ 4]::INTEGER);
      IF (v_lnSmmryLnID <= 0) THEN
        v_lnSmmryLnID := nextval('accb.accb_rcvbl_amnt_smmrys_rcvbl_smmry_id_seq');
        v_reslt_1 := accb.createRcvblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt,
                                              p_entrdCurrID, v_tax_code_id, p_docType, '1', v_accnts [ 3],
                                              v_tax_accid, v_accnts [ 1],
                                              p_blncgAccntID, -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID,
                                              p_funcCurrRate, p_accntCurrRate, v_funcCurrAmnt,
                                              v_accntCurrAmnt, v_smmryID, 1, v_codeAmnt, p_ref_doc_number,
                                              ',', -1, -1, -1, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
          RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = v_reslt_1,
            HINT = v_reslt_1;
        END IF;
      ELSE
        v_reslt_1 := accb.updtRcvblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt,
                                            p_entrdCurrID, v_tax_code_id, p_docType, '1', v_accnts [ 3],
                                            v_tax_accid, v_accnts [ 1], p_blncgAccntID, -1, p_vldyStatus,
                                            -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate, p_accntCurrRate,
                                            v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID, 1, v_codeAmnt,
                                            p_ref_doc_number, ',', -1, -1, -1, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
          RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = v_reslt_1,
            HINT = v_reslt_1;
        END IF;
      END IF;
    END IF;
    
  END IF;
  RETURN v_reslt_1;
  EXCEPTION
  WHEN OTHERS
    THEN
      RETURN 'ERROR:' || SQLERRM || ' ' || v_reslt_1;
END;
$BODY$;


CREATE OR REPLACE FUNCTION accb.recalcrcvblssmmrys(
	p_srcdocid bigint,
	p_srcdoctype character varying,
	p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
<< outerblock >>
  DECLARE
  v_msgs          TEXT                   := '';
  v_grndAmnt      NUMERIC                := 0;
  v_grndAmnt2     NUMERIC                := 0;
  v_diff          NUMERIC                := 0;
  v_pymntsAmnt    NUMERIC                := 0;
  v_outstndngAmnt NUMERIC                := 0;
  v_smmryNm       CHARACTER VARYING(100) := '';
  v_smmryID       BIGINT                 := -1;
  v_entrdCurrID   INTEGER                := -1;
  v_curlnID       BIGINT                 := -1;
  v_reslt_1       TEXT                   := '';
  vRD RECORD;
  v_CntID         BIGINT                 := 0;
BEGIN
  v_grndAmnt := accb.getRcvblsDocGrndAmnt(p_srcDocID);
  v_grndAmnt2 := accb.getRcvblsDocGrndAmnt2(p_srcDocID);
  v_diff := round(v_grndAmnt - v_grndAmnt2, 2);
  v_smmryNm := 'Grand Total';
  v_smmryID := accb.getRcvblsSmmryItmID('6Grand Total', -1, p_srcDocID, p_srcDocType, v_smmryNm);
  v_entrdCurrID := gst.getGnrlRecNm('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'invc_curr_id',
                                    p_srcDocID) :: INTEGER;
  IF (v_smmryID <= 0)
  THEN
    v_curlnID := nextval('accb.accb_rcvbl_amnt_smmrys_rcvbl_smmry_id_seq');
    v_reslt_1 := accb.createRcvblsDocDet(v_curlnID, p_srcDocID, '6Grand Total',
                                         v_smmryNm, v_grndAmnt, v_entrdCurrID,
                                         -1, p_srcDocType, '1', 'Increase',
                                         -1, 'Increase', -1, -1, 'VALID', -1, -1,
                                         -1, 0, 0, 0, 0, -1, 1, 0, '', ',', -1, -1, -1, p_who_rn);
  ELSE
    v_reslt_1 := accb.updtRcvblsDocDet(v_smmryID, p_srcDocID, '6Grand Total',
                                       v_smmryNm, v_grndAmnt, v_entrdCurrID,
                                       -1, p_srcDocType, '1', 'Increase',
                                       -1, 'Increase', -1, -1, 'VALID', -1, -1,
                                       -1, 0, 0, 0, 0, -1, 1, 0, '', ',', -1, -1, -1, p_who_rn);
  END IF;
  
  v_smmryNm := 'Total Payments Made';
  v_smmryID := accb.getRcvblsSmmryItmID('7Total Payments Made', -1,
                                        p_srcDocID, p_srcDocType, v_smmryNm);
  v_pymntsAmnt := accb.getDocsTtlPymnts(p_srcDocID, p_srcDocType);
  
  IF (v_smmryID <= 0)
  THEN
    v_curlnID := nextval('accb.accb_rcvbl_amnt_smmrys_rcvbl_smmry_id_seq');
    v_reslt_1 := accb.createRcvblsDocDet(v_curlnID, p_srcDocID, '7Total Payments Made',
                                         v_smmryNm, v_pymntsAmnt, v_entrdCurrID,
                                         -1, p_srcDocType, '1', 'Increase',
                                         -1, 'Increase', -1, -1, 'VALID', -1, -1,
                                         -1, 0, 0, 0, 0, -1, 1, 0, '', ',', -1, -1, -1, p_who_rn);
  ELSE
    v_reslt_1 := accb.updtRcvblsDocDet(v_smmryID, p_srcDocID, '7Total Payments Made',
                                       v_smmryNm, v_pymntsAmnt, v_entrdCurrID,
                                       -1, p_srcDocType, '1', 'Increase',
                                       -1, 'Increase', -1, -1, 'VALID', -1, -1,
                                       -1, 0, 0, 0, 0, -1, 1, 0, '', ',', -1, -1, -1, p_who_rn);
  END IF;
  
  v_smmryNm := 'Outstanding Balance';
  v_smmryID := accb.getRcvblsSmmryItmID('8Outstanding Balance', -1, p_srcDocID, p_srcDocType, v_smmryNm);
  v_outstndngAmnt := v_grndAmnt - v_pymntsAmnt;
  IF (v_smmryID <= 0)
  THEN
    v_curlnID := nextval('accb.accb_rcvbl_amnt_smmrys_rcvbl_smmry_id_seq');
    v_reslt_1 := accb.createRcvblsDocDet(v_curlnID, p_srcDocID, '8Outstanding Balance',
                                         v_smmryNm, v_outstndngAmnt, v_entrdCurrID,
                                         -1, p_srcDocType, '1', 'Increase',
                                         -1, 'Increase', -1, -1, 'VALID', -1, -1,
                                         -1, 0, 0, 0, 0, -1, 1, 0, '', ',', -1, -1, -1, p_who_rn);
  ELSE
    v_reslt_1 := accb.updtRcvblsDocDet(v_smmryID, p_srcDocID, '8Outstanding Balance',
                                       v_smmryNm, v_outstndngAmnt, v_entrdCurrID,
                                       -1, p_srcDocType, '1', 'Increase',
                                       -1, 'Increase', -1, -1, 'VALID', -1, -1,
                                       -1, 0, 0, 0, 0, -1, 1, 0, '', ',', -1, -1, -1, p_who_rn);
  END IF;
  --SELECT z.rcvbl_smmry_id INTO v_smmryID FROM accb.accb_rcvbl_amnt_smmrys z WHERE z.rcvbl_smmry_type = '1Initial Amount' ORDER BY z.rcvbl_smmry_id ASC LIMIT 1 OFFSET 0;
  --v_msgs := 'v_diff:' || v_diff || ':v_smmryID:' || v_smmryID;
  --v_smmryID := 1 / 0;
  /*Loop through all Taxes and spread differences to balance if need be.*/
  IF v_diff != 0 THEN
	SELECT count(z.rcvbl_smmry_id) 
				INTO v_CntID
		FROM accb.accb_rcvbl_amnt_smmrys z
		WHERE z.rcvbl_smmry_type = '2Tax'
			AND z.src_rcvbl_hdr_id = p_srcDocID;

		IF COALESCE(v_CntID, 0) != 0 THEN
			v_diff := v_diff/COALESCE(v_CntID, 0.00);
			FOR vRD IN (
				SELECT z.rcvbl_smmry_id 
					FROM accb.accb_rcvbl_amnt_smmrys z
				WHERE z.rcvbl_smmry_type = '2Tax'
					AND z.src_rcvbl_hdr_id = p_srcDocID
					)
				LOOP
					UPDATE accb.accb_rcvbl_amnt_smmrys
					SET rcvbl_smmry_amnt=rcvbl_smmry_amnt + v_diff,
						func_curr_amount=(rcvbl_smmry_amnt + v_diff) * func_curr_rate,
						accnt_curr_amnt=(rcvbl_smmry_amnt + v_diff) * accnt_curr_rate,
						unit_price=(round(rcvbl_smmry_amnt, 2) + v_diff) / (CASE WHEN line_qty = 0 THEN 1 ELSE line_qty END)
					WHERE src_rcvbl_hdr_id = p_srcDocID
						AND rcvbl_smmry_id = vRD.rcvbl_smmry_id;				
				END LOOP;
		END IF;
  END IF;
  
				UPDATE accb.accb_rcvbl_amnt_smmrys
				SET rcvbl_smmry_amnt=round(rcvbl_smmry_amnt, 2),
					func_curr_amount=round(rcvbl_smmry_amnt, 2) * func_curr_rate,
					accnt_curr_amnt=round(rcvbl_smmry_amnt, 2) * accnt_curr_rate,
					unit_price=round(rcvbl_smmry_amnt, 2) / (CASE WHEN line_qty = 0 THEN 1 ELSE line_qty END)
				WHERE src_rcvbl_hdr_id = p_srcDocID;
  RETURN 'SUCCESS:';
  EXCEPTION
  WHEN OTHERS
    THEN
      RETURN 'ERROR:' || SQLERRM || ' v_msgs:' || v_msgs;
END;
$BODY$;

CREATE OR REPLACE FUNCTION accb.recalcpyblssmmrys(
	p_srcdocid bigint,
	p_srcdoctype character varying,
	p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
<< outerblock >>
  DECLARE
  v_diff          NUMERIC                := 0;
  v_grndAmnt      NUMERIC                := 0;
  v_grndAmnt2     NUMERIC                := 0;
  v_pymntsAmnt    NUMERIC                := 0;
  v_outstndngAmnt NUMERIC                := 0;
  v_smmryNm       CHARACTER VARYING(100) := '';
  v_smmryID       BIGINT                 := -1;
  v_entrdCurrID   INTEGER                := -1;
  v_curlnID       BIGINT                 := -1;
  v_reslt_1       TEXT                   := '';
  v_msgs          TEXT                   := '';
  vRD RECORD;
  v_CntID         BIGINT                 := 0;
BEGIN
  v_grndAmnt := accb.getPyblsDocGrndAmnt(p_srcDocID);
  v_grndAmnt2 := accb.getPyblsDocGrndAmnt2(p_srcDocID);
  v_diff := round(v_grndAmnt - v_grndAmnt2, 2);
  v_smmryNm := 'Grand Total';
  v_smmryID := accb.getPyblsSmmryItmID('6Grand Total', -1, p_srcDocID, p_srcDocType, v_smmryNm);
  v_entrdCurrID := gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'invc_curr_id',
                                    p_srcDocID) :: INTEGER;
  IF (v_smmryID <= 0)
  THEN
    v_curlnID := nextval('accb.accb_pybls_amnt_smmrys_pybls_smmry_id_seq');
    v_reslt_1 := accb.createPyblsDocDet(v_curlnID, p_srcDocID, '6Grand Total',
                                        v_smmryNm, v_grndAmnt, v_entrdCurrID,
                                        -1, p_srcDocType, '1', 'Increase',
                                        -1, 'Increase', -1, -1, 'VALID', -1, -1,
                                        -1, 0, 0, 0, 0, -1, '', ',', -1, -1, -1, p_who_rn);
  ELSE
    v_reslt_1 := accb.updtPyblsDocDet(v_smmryID, p_srcDocID, '6Grand Total',
                                      v_smmryNm, v_grndAmnt, v_entrdCurrID,
                                      -1, p_srcDocType, '1', 'Increase',
                                      -1, 'Increase', -1, -1, 'VALID', -1, -1,
                                      -1, 0, 0, 0, 0, -1,
                                      '', ',', -1, -1, -1, p_who_rn);
    --v_smmryID := 1 / 0;
  END IF;
  
  v_smmryNm := 'Total Payments Made';
  v_smmryID := accb.getPyblsSmmryItmID('7Total Payments Made', -1,
                                       p_srcDocID, p_srcDocType, v_smmryNm);
  v_pymntsAmnt := accb.getDocsTtlPymnts(p_srcDocID, p_srcDocType);
  
  IF (v_smmryID <= 0)
  THEN
    v_curlnID := nextval('accb.accb_pybls_amnt_smmrys_pybls_smmry_id_seq');
    v_reslt_1 := accb.createPyblsDocDet(v_curlnID, p_srcDocID, '7Total Payments Made',
                                        v_smmryNm, v_pymntsAmnt, v_entrdCurrID,
                                        -1, p_srcDocType, '1', 'Increase',
                                        -1, 'Increase', -1, -1, 'VALID', -1, -1,
                                        -1, 0, 0, 0, 0, -1, '', ',', -1, -1, -1, p_who_rn);
  ELSE
    v_reslt_1 := accb.updtPyblsDocDet(v_smmryID, p_srcDocID, '7Total Payments Made',
                                      v_smmryNm, v_pymntsAmnt, v_entrdCurrID,
                                      -1, p_srcDocType, '1', 'Increase',
                                      -1, 'Increase', -1, -1, 'VALID', -1, -1,
                                      -1, 0, 0, 0, 0, -1, '', ',', -1, -1, -1, p_who_rn);
  END IF;
  v_smmryNm := 'Outstanding Balance';
  v_smmryID := accb.getPyblsSmmryItmID('8Outstanding Balance', -1,
                                       p_srcDocID, p_srcDocType, v_smmryNm);
  v_outstndngAmnt := v_grndAmnt - v_pymntsAmnt;
  IF (v_smmryID <= 0)
  THEN
    v_curlnID := nextval('accb.accb_pybls_amnt_smmrys_pybls_smmry_id_seq');
    v_reslt_1 := accb.createPyblsDocDet(v_curlnID, p_srcDocID, '8Outstanding Balance',
                                        v_smmryNm, v_outstndngAmnt, v_entrdCurrID,
                                        -1, p_srcDocType, '1', 'Increase',
                                        -1, 'Increase', -1, -1, 'VALID', -1, -1,
                                        -1, 0, 0, 0, 0, -1, '', ',', -1, -1, -1, p_who_rn);
  ELSE
    v_reslt_1 := accb.updtPyblsDocDet(v_smmryID, p_srcDocID, '8Outstanding Balance',
                                      v_smmryNm, v_outstndngAmnt, v_entrdCurrID,
                                      -1, p_srcDocType, '1', 'Increase',
                                      -1, 'Increase', -1, -1, 'VALID', -1, -1,
                                      -1, 0, 0, 0, 0, -1, '', ',', -1, -1, -1, p_who_rn);
  END IF;
  
  /*Loop through all Taxes and spread differences to balance if need be.*/
  IF v_diff != 0 THEN
	SELECT count(z.pybls_smmry_id) 
				INTO v_CntID
		FROM accb.accb_pybls_amnt_smmrys z
		WHERE z.pybls_smmry_type = '2Tax'
			AND z.src_pybls_hdr_id = p_srcDocID;

		IF COALESCE(v_CntID, 0) != 0 THEN

			v_diff := v_diff/COALESCE(v_CntID, 0.00);
		FOR vRD IN (
			SELECT z.pybls_smmry_id 
				FROM accb.accb_pybls_amnt_smmrys z
			WHERE z.pybls_smmry_type = '2Tax'
				AND z.src_pybls_hdr_id = p_srcDocID
				)
			LOOP
				UPDATE accb.accb_pybls_amnt_smmrys
				SET pybls_smmry_amnt=pybls_smmry_amnt + v_diff,
					func_curr_amount=(pybls_smmry_amnt + v_diff) * func_curr_rate,
					accnt_curr_amnt=(pybls_smmry_amnt + v_diff) * accnt_curr_rate
				WHERE src_pybls_hdr_id = p_srcDocID
					AND pybls_smmry_id = vRD.pybls_smmry_id;				
			END LOOP;
		END IF;
  END IF;
  
				UPDATE accb.accb_pybls_amnt_smmrys
				SET pybls_smmry_amnt=round(pybls_smmry_amnt, 2),
					func_curr_amount=round(pybls_smmry_amnt, 2) * func_curr_rate,
					accnt_curr_amnt=round(pybls_smmry_amnt, 2) * accnt_curr_rate
				WHERE src_pybls_hdr_id = p_srcDocID;
  RETURN 'SUCCESS:';
  EXCEPTION
  WHEN OTHERS
    THEN
      RETURN 'ERROR:' || SQLERRM || ' v_msgs:' || v_msgs;
END;
$BODY$;

CREATE OR REPLACE FUNCTION accb.createpyblsdocdet(
	p_smmryid bigint,
	p_hdrid bigint,
	p_linetype character varying,
	p_linedesc character varying,
	p_entrdamnt numeric,
	p_entrdcurrid integer,
	p_codebhnd integer,
	p_doctype character varying,
	p_autocalc character varying,
	p_incrdcrs1 character varying,
	p_costngid integer,
	p_incrdcrs2 character varying,
	p_blncgaccntid integer,
	p_prepaydochdrid bigint,
	p_vldystatus character varying,
	p_orgnllnid bigint,
	p_funccurrid integer,
	p_accntcurrid integer,
	p_funccurrrate numeric,
	p_accntcurrrate numeric,
	p_funccurramnt numeric,
	p_accntcurramnt numeric,
	p_initial_amnt_line_id bigint,
	p_ref_doc_number character varying,
	p_slctd_amnt_brkdwns character varying,
	p_tax_code_id integer,
	p_whtax_code_id integer,
	p_dscnt_code_id integer,
	p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
<< outerblock >>
  DECLARE
  v_reslt_1       TEXT                    := '';
  v_smmryID       BIGINT                  := -1;
  c_codeIDs       CHARACTER VARYING(4000) := '';
  v_codeIDs       CHARACTER VARYING(4000)[];
  v_ArryLen       INTEGER                 := 0;
  v_tax_code_id   INTEGER                 := -1;
  v_tax_accid     INTEGER                 := -1;
  v_txsmmryNm     CHARACTER VARYING(200)  := '';
  v_dcntAMnt      NUMERIC                 := 0;
  v_codeAmnt      NUMERIC                 := 0;
  v_lnSmmryLnID   BIGINT                  := -1;
  c_accnts        CHARACTER VARYING(4000) := '';
  v_accnts        CHARACTER VARYING(4000)[];
  v_funcCurrAmnt  NUMERIC                 := 0;
  v_accntCurrAmnt NUMERIC                 := 0;
  v_txlineDesc    CHARACTER VARYING(300)  := '';
  p_orgid         INTEGER                 := -1;
  v_dscntAmnts     NUMERIC                := 0;
  v_dscntAmnts1     NUMERIC                := 0;
  v_snglDscnt      NUMERIC                := 0;
  v_sllngPrc       NUMERIC                := 0;
BEGIN
  v_reslt_1 :=
      accb.createPyblsDocDet1(p_smmryID, p_hdrID, p_lineType, p_lineDesc, p_entrdAmnt, p_entrdCurrID, p_codeBhnd,
                              p_docType, p_autoCalc, p_incrDcrs1, p_costngID, p_incrDcrs2, p_blncgAccntID,
                              p_prepayDocHdrID, p_vldyStatus, p_orgnlLnID, p_funcCurrID, p_accntCurrID, p_funcCurrRate,
                              p_accntCurrRate, p_funcCurrAmnt, p_accntCurrAmnt, p_initial_amnt_line_id,
                              p_ref_doc_number, p_slctd_amnt_brkdwns, p_tax_code_id, p_whtax_code_id, p_dscnt_code_id,
                              p_who_rn);
  IF v_reslt_1 NOT LIKE 'SUCCESS:%'
  THEN
    RAISE EXCEPTION USING
      ERRCODE = 'RHERR',
      MESSAGE = v_reslt_1,
      HINT = v_reslt_1;
  END IF;
  IF p_initial_amnt_line_id <= 0 AND p_lineType = '1Initial Amount' THEN
    p_orgid := gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'org_id', p_hdrID)::INTEGER;
    v_smmryID := p_smmryID;
	
	v_snglDscnt :=0;
	
    
    IF (p_tax_code_id > 0 AND scm.istaxaparent(p_tax_code_id) = '1') THEN
      c_codeIDs := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'child_code_ids', p_tax_code_id);
      v_codeIDs := string_to_array(BTRIM(c_codeIDs, ', '), ',');
      
      v_ArryLen := array_length(v_codeIDs, 1);
      FOR y IN 1..v_ArryLen
        LOOP
          v_tax_code_id := v_codeIDs [ y];
          v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);
          --v_dcntAMnt := scm.getSalesDocCodesAmnt(p_dscnt_code_id, p_entrdAmnt, 1);
          v_codeAmnt := v_codeAmnt + scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt - v_snglDscnt, 1);
          END LOOP;
    ELSIF (p_tax_code_id > 0) THEN
      v_tax_code_id := p_tax_code_id;
      v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);
      --v_dcntAMnt := scm.getSalesDocCodesAmnt(p_dscnt_code_id, p_entrdAmnt, 1);
      v_codeAmnt := scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt - v_snglDscnt, 1);
    END IF;

	v_sllngPrc := v_codeAmnt +p_entrdAmnt;
	
    IF (p_dscnt_code_id > 0 AND scm.istaxaparent(p_dscnt_code_id) = '1') THEN
      c_codeIDs := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'child_code_ids', p_dscnt_code_id);
      v_codeIDs := string_to_array(BTRIM(c_codeIDs, ', '), ',');
      
      v_ArryLen := array_length(v_codeIDs, 1);
      FOR y IN 1..v_ArryLen
        LOOP
          v_tax_code_id := v_codeIDs [ y];
          v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);

		  v_snglDscnt := scm.getDscntLessTax(p_tax_code_id, scm.getSalesDocCodesAmnt(v_tax_code_id, v_sllngPrc, 1));
          v_dscntAmnts1 := scm.getDscntLessTax(p_tax_code_id, scm.getSalesDocCodesAmnt(v_tax_code_id, v_sllngPrc, 1));
          v_dscntAmnts := v_dscntAmnts + v_dscntAmnts1;
          
		  v_codeAmnt := v_dscntAmnts;--scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt, 1);
		  
          v_lnSmmryLnID := accb.getPyblsLnDetID('3Discount', v_tax_code_id, v_smmryID);
          c_accnts := accb.getPyblBalncnAccnt('3Discount', v_tax_code_id, -1, -1, p_docType, p_orgid);
          v_accnts := string_to_array(BTRIM(c_accnts, '; '), ';');
          v_funcCurrAmnt := v_codeAmnt * p_funcCurrRate;
          v_accntCurrAmnt := v_codeAmnt * p_accntCurrRate;
          v_txlineDesc := v_txsmmryNm || ' on ' || p_lineDesc || ' (' || p_entrdAmnt || ')';
          v_tax_accid := org.get_accnt_id_frmaccnt(p_costngID, v_accnts [ 4]::INTEGER);
          IF (v_lnSmmryLnID <= 0) THEN
            v_lnSmmryLnID := nextval('accb.accb_pybls_amnt_smmrys_pybls_smmry_id_seq');
            v_reslt_1 :=
                accb.createPyblsDocDet1(v_lnSmmryLnID, p_hdrID, '3Discount', v_txlineDesc, v_codeAmnt, p_entrdCurrID,
                                        v_tax_code_id,
                                        p_docType, '1', v_accnts [ 3], v_tax_accid, v_accnts [ 1],
                                        p_blncgAccntID,
                                        -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate,
                                        p_accntCurrRate, v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID,
                                        p_ref_doc_number, ',', -1, -1, -1, p_who_rn);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
              RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            END IF;
          ELSE
            v_reslt_1 :=
                accb.updtPyblsDocDet1(v_lnSmmryLnID, p_hdrID, '3Discount', v_txlineDesc, v_codeAmnt, p_entrdCurrID,
                                      v_tax_code_id,
                                      p_docType, '1', v_accnts [ 3], v_tax_accid, v_accnts [ 1],
                                      p_blncgAccntID,
                                      -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate,
                                      p_accntCurrRate, v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID, p_ref_doc_number,
                                      ',', -1, -1, -1, p_who_rn);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
              RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            END IF;
          END IF;
          END LOOP;
    ELSIF (p_dscnt_code_id > 0) THEN
      v_tax_code_id := p_dscnt_code_id;
      v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);

	  v_snglDscnt := scm.getDscntLessTax(p_tax_code_id, scm.getSalesDocCodesAmnt(v_tax_code_id, v_sllngPrc, 1));
      v_dscntAmnts1 := scm.getDscntLessTax(p_tax_code_id, scm.getSalesDocCodesAmnt(v_tax_code_id, v_sllngPrc, 1));
      v_dscntAmnts := v_dscntAmnts + v_dscntAmnts1;
          
	  v_codeAmnt := v_dscntAmnts;--v_codeAmnt := scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt, 1);
      
	  v_lnSmmryLnID := accb.getPyblsLnDetID('3Discount', v_tax_code_id, v_smmryID);
      c_accnts := accb.getPyblBalncnAccnt('3Discount', v_tax_code_id, -1, -1, p_docType, p_orgid);
      v_accnts := string_to_array(BTRIM(c_accnts, '; '), ';');
      v_funcCurrAmnt := v_codeAmnt * p_funcCurrRate;
      v_accntCurrAmnt := v_codeAmnt * p_accntCurrRate;
      v_txlineDesc := v_txsmmryNm || ' on ' || p_lineDesc || ' (' || p_entrdAmnt || ')';
      v_tax_accid := org.get_accnt_id_frmaccnt(p_costngID, v_accnts [ 4]::INTEGER);
      IF (v_lnSmmryLnID <= 0) THEN
        v_lnSmmryLnID := nextval('accb.accb_pybls_amnt_smmrys_pybls_smmry_id_seq');
        v_reslt_1 :=
            accb.createPyblsDocDet1(v_lnSmmryLnID, p_hdrID, '3Discount', v_txlineDesc, v_codeAmnt, p_entrdCurrID,
                                    v_tax_code_id,
                                    p_docType, '1', v_accnts [ 3], v_tax_accid, v_accnts [ 1],
                                    p_blncgAccntID,
                                    -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate,
                                    p_accntCurrRate, v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID,
                                    p_ref_doc_number, ',', -1, -1, -1, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
          RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = v_reslt_1,
            HINT = v_reslt_1;
        END IF;
      ELSE
        v_reslt_1 := accb.updtPyblsDocDet1(v_lnSmmryLnID, p_hdrID, '3Discount', v_txlineDesc, v_codeAmnt, p_entrdCurrID,
                                           v_tax_code_id,
                                           p_docType, '1', v_accnts [ 3], v_tax_accid, v_accnts [ 1],
                                           p_blncgAccntID,
                                           -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate,
                                           p_accntCurrRate, v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID,
                                           p_ref_doc_number,
                                           ',', -1, -1, -1, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
          RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = v_reslt_1,
            HINT = v_reslt_1;
        END IF;
      END IF;
    END IF;
    IF (p_tax_code_id > 0 AND scm.istaxaparent(p_tax_code_id) = '1') THEN
      c_codeIDs := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'child_code_ids', p_tax_code_id);
      v_codeIDs := string_to_array(BTRIM(c_codeIDs, ', '), ',');
      
      v_ArryLen := array_length(v_codeIDs, 1);
      FOR y IN 1..v_ArryLen
        LOOP
          v_tax_code_id := v_codeIDs [ y];
          v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);
          --v_dcntAMnt := scm.getSalesDocCodesAmnt(p_dscnt_code_id, p_entrdAmnt, 1);
          v_codeAmnt := scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt - v_snglDscnt, 1);
          v_lnSmmryLnID := accb.getPyblsLnDetID('2Tax', v_tax_code_id, v_smmryID);
          c_accnts := accb.getPyblBalncnAccnt('2Tax', v_tax_code_id, -1, -1, p_docType, p_orgid);
          --v_reslt_1 := ':c_accnts:' || c_accnts;
          --v_lnSmmryLnID := 1 / 0;
          v_accnts := string_to_array(BTRIM(c_accnts, '; '), ';');
          v_funcCurrAmnt := v_codeAmnt * p_funcCurrRate;
          v_accntCurrAmnt := v_codeAmnt * p_accntCurrRate;
          v_txlineDesc := v_txsmmryNm || ' on ' || p_lineDesc || ' (' || p_entrdAmnt || ')';
          v_tax_accid := org.get_accnt_id_frmaccnt(p_costngID, v_accnts [ 4]::INTEGER);
          IF (v_lnSmmryLnID <= 0) THEN
            v_lnSmmryLnID := nextval('accb.accb_pybls_amnt_smmrys_pybls_smmry_id_seq');
            v_reslt_1 :=
                accb.createPyblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt, p_entrdCurrID,
                                        v_tax_code_id,
                                        p_docType, '1', v_accnts [ 3], v_tax_accid, v_accnts [ 1],
                                        p_blncgAccntID,
                                        -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate,
                                        p_accntCurrRate, v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID,
                                        p_ref_doc_number, ',', -1, -1, -1, p_who_rn);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
              RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            END IF;
          ELSE
            v_reslt_1 := accb.updtPyblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt, p_entrdCurrID,
                                               v_tax_code_id,
                                               p_docType, '1', v_accnts [ 3], v_tax_accid, v_accnts [ 1],
                                               p_blncgAccntID,
                                               -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate,
                                               p_accntCurrRate, v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID,
                                               p_ref_doc_number,
                                               ',', -1, -1, -1, p_who_rn);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
              RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            END IF;
          END IF;
          END LOOP;
    ELSIF (p_tax_code_id > 0) THEN
      v_tax_code_id := p_tax_code_id;
      v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);
      --v_dcntAMnt := scm.getSalesDocCodesAmnt(p_dscnt_code_id, p_entrdAmnt, 1);
      v_codeAmnt := scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt - v_snglDscnt, 1);
      v_lnSmmryLnID := accb.getPyblsLnDetID('2Tax', v_tax_code_id, v_smmryID);
      c_accnts := accb.getPyblBalncnAccnt('2Tax', v_tax_code_id, -1, -1, p_docType, p_orgid);
      v_accnts := string_to_array(BTRIM(c_accnts, '; '), ';');
      v_funcCurrAmnt := v_codeAmnt * p_funcCurrRate;
      v_accntCurrAmnt := v_codeAmnt * p_accntCurrRate;
      v_txlineDesc := v_txsmmryNm || ' on ' || p_lineDesc || ' (' || p_entrdAmnt || ')';
      v_tax_accid := org.get_accnt_id_frmaccnt(p_costngID, v_accnts [ 4]::INTEGER);
      IF (v_lnSmmryLnID <= 0) THEN
        v_lnSmmryLnID := nextval('accb.accb_pybls_amnt_smmrys_pybls_smmry_id_seq');
        v_reslt_1 := accb.createPyblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt, p_entrdCurrID,
                                             v_tax_code_id,
                                             p_docType, '1', v_accnts [ 3], v_tax_accid, v_accnts [ 1],
                                             p_blncgAccntID,
                                             -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate,
                                             p_accntCurrRate, v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID,
                                             p_ref_doc_number, ',', -1, -1, -1, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
          RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = v_reslt_1,
            HINT = v_reslt_1;
        END IF;
      ELSE
        v_reslt_1 := accb.updtPyblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt, p_entrdCurrID,
                                           v_tax_code_id,
                                           p_docType, '1', v_accnts [ 3], v_tax_accid, v_accnts [ 1],
                                           p_blncgAccntID,
                                           -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate,
                                           p_accntCurrRate, v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID,
                                           p_ref_doc_number,
                                           ',', -1, -1, -1, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
          RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = v_reslt_1,
            HINT = v_reslt_1;
        END IF;
      END IF;
    END IF;
    
    IF (p_whtax_code_id > 0 AND scm.istaxaparent(p_whtax_code_id) = '1') THEN
      c_codeIDs := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'child_code_ids', p_whtax_code_id);
      v_codeIDs := string_to_array(BTRIM(c_codeIDs, ', '), ',');
      
      v_ArryLen := array_length(v_codeIDs, 1);
      FOR y IN 1..v_ArryLen
        LOOP
          v_tax_code_id := v_codeIDs [ y];
          v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);
          --v_dcntAMnt := scm.getSalesDocCodesAmnt(p_dscnt_code_id, p_entrdAmnt, 1);
          v_codeAmnt := scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt - v_snglDscnt, 1);
          v_lnSmmryLnID := accb.getPyblsLnDetID('2Tax', v_tax_code_id, v_smmryID);
          c_accnts := accb.getPyblBalncnAccnt('2Tax', v_tax_code_id, -1, -1, p_docType, p_orgid);
          v_accnts := string_to_array(BTRIM(c_accnts, '; '), ';');
          v_funcCurrAmnt := v_codeAmnt * p_funcCurrRate;
          v_accntCurrAmnt := v_codeAmnt * p_accntCurrRate;
          v_txlineDesc := v_txsmmryNm || ' on ' || p_lineDesc || ' (' || p_entrdAmnt || ')';
          v_tax_accid := org.get_accnt_id_frmaccnt(p_costngID, v_accnts [ 4]::INTEGER);
          IF (v_lnSmmryLnID <= 0) THEN
            v_lnSmmryLnID := nextval('accb.accb_pybls_amnt_smmrys_pybls_smmry_id_seq');
            v_reslt_1 :=
                accb.createPyblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt, p_entrdCurrID,
                                        v_tax_code_id,
                                        p_docType, '1', v_accnts [ 3], v_tax_accid, v_accnts [ 1],
                                        p_blncgAccntID,
                                        -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate,
                                        p_accntCurrRate, v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID,
                                        p_ref_doc_number, ',', -1, -1, -1, p_who_rn);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
              RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            END IF;
          ELSE
            v_reslt_1 := accb.updtPyblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt, p_entrdCurrID,
                                               v_tax_code_id,
                                               p_docType, '1', v_accnts [ 3], v_tax_accid, v_accnts [ 1],
                                               p_blncgAccntID,
                                               -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate,
                                               p_accntCurrRate, v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID,
                                               p_ref_doc_number,
                                               ',', -1, -1, -1, p_who_rn);
            IF v_reslt_1 NOT LIKE 'SUCCESS:%'
            THEN
              RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            END IF;
          END IF;
          END LOOP;
    ELSIF (p_whtax_code_id > 0) THEN
      v_tax_code_id := p_whtax_code_id;
      v_txsmmryNm := gst.getGnrlRecNm('scm.scm_tax_codes', 'code_id', 'code_name', v_tax_code_id);
      --v_dcntAMnt := scm.getSalesDocCodesAmnt(p_dscnt_code_id, p_entrdAmnt, 1);
      v_codeAmnt := scm.getSalesDocCodesAmnt(v_tax_code_id, p_entrdAmnt - v_snglDscnt, 1);
      v_lnSmmryLnID := accb.getPyblsLnDetID('2Tax', v_tax_code_id, v_smmryID);
      c_accnts := accb.getPyblBalncnAccnt('2Tax', v_tax_code_id, -1, -1, p_docType, p_orgid);
      v_accnts := string_to_array(BTRIM(c_accnts, '; '), ';');
      v_funcCurrAmnt := v_codeAmnt * p_funcCurrRate;
      v_accntCurrAmnt := v_codeAmnt * p_accntCurrRate;
      v_txlineDesc := v_txsmmryNm || ' on ' || p_lineDesc || ' (' || p_entrdAmnt || ')';
      v_tax_accid := org.get_accnt_id_frmaccnt(p_costngID, v_accnts [ 4]::INTEGER);
      IF (v_lnSmmryLnID <= 0) THEN
        v_lnSmmryLnID := nextval('accb.accb_pybls_amnt_smmrys_pybls_smmry_id_seq');
        v_reslt_1 := accb.createPyblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt, p_entrdCurrID,
                                             v_tax_code_id,
                                             p_docType, '1', v_accnts [ 3], v_tax_accid, v_accnts [ 1],
                                             p_blncgAccntID,
                                             -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate,
                                             p_accntCurrRate, v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID,
                                             p_ref_doc_number, ',', -1, -1, -1, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
          RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = v_reslt_1,
            HINT = v_reslt_1;
        END IF;
      ELSE
        v_reslt_1 := accb.updtPyblsDocDet1(v_lnSmmryLnID, p_hdrID, '2Tax', v_txlineDesc, v_codeAmnt, p_entrdCurrID,
                                           v_tax_code_id,
                                           p_docType, '1', v_accnts [ 3], v_tax_accid, v_accnts [ 1],
                                           p_blncgAccntID,
                                           -1, p_vldyStatus, -1, p_funcCurrID, p_accntCurrID, p_funcCurrRate,
                                           p_accntCurrRate, v_funcCurrAmnt, v_accntCurrAmnt, v_smmryID,
                                           p_ref_doc_number,
                                           ',', -1, -1, -1, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
          RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = v_reslt_1,
            HINT = v_reslt_1;
        END IF;
      END IF;
    END IF;    
  END IF;
  
  RETURN v_reslt_1;
  EXCEPTION
  WHEN OTHERS
    THEN
      RETURN 'ERROR:createPyblsDocDet' || SQLERRM;
END;
$BODY$;


CREATE OR REPLACE FUNCTION accb.approve_pyblrcvbldoc(
	p_dochdrid bigint,
	p_docnum character varying,
	p_dockind character varying,
	p_orgid integer,
	p_who_rn bigint)
    RETURNS character varying
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
<< outerblock >>
    DECLARE
    v_sameprepayCnt  BIGINT                 := 0;
    rd1              RECORD;
    msgs             TEXT                   := '';
    v_reslt_1        TEXT                   := '';
    v_usrTrnsCode    CHARACTER VARYING(50)  := '';
    v_dte            CHARACTER VARYING(21)  := '';
    v_lnDte          CHARACTER VARYING(21)  := '';
    v_docHdrDesc     CHARACTER VARYING(300) := '';
    v_docNum         CHARACTER VARYING(100) := '';
    v_gnrtdTrnsNo1   CHARACTER VARYING(100) := '';
    v_frstChqNum     CHARACTER VARYING(100) := '';
    v_ref_doc_number CHARACTER VARYING(100) := '';
    v_glBatchName    CHARACTER VARYING(100) := '';
    v_glBatchID      BIGINT                 := -1;
    v_balcngAccntID  INTEGER                := -1;
    v_lineTypeNm     CHARACTER VARYING(50)  := '';
    v_codeBhndID     INTEGER                := -1;
    v_incrDcrs1      CHARACTER VARYING(50)  := '';
    v_accntID1       INTEGER                := -1;
    v_incrDcrs2      CHARACTER VARYING(50)  := '';
    v_accntID2       INTEGER                := -1;
    v_isdbtCrdt1     CHARACTER VARYING(50)  := '';
    v_isdbtCrdt2     CHARACTER VARYING(50)  := '';
    v_accntID3       INTEGER                := -1;
    v_incrDcrs3      CHARACTER VARYING(50)  := '';
    v_netAmnt        NUMERIC                := 0;
    v_lnAmnt         NUMERIC                := 0;
    v_acntAmnt       NUMERIC                := 0;
    v_entrdAmnt      NUMERIC                := 0;
    v_funcCurrRate   NUMERIC                := 1;
    v_accntCurrRate  NUMERIC                := 1;
    v_lneDesc        CHARACTER VARYING(300) := '';
    v_entrdCurrID    INTEGER                := -1;
    v_funcCurrID     INTEGER                := -1;
    v_accntCurrID    INTEGER                := -1;
    v_grndAmnt       NUMERIC                := 0;
    v_funcCurrAmnt   NUMERIC                := 0;
    v_accntCurrAmnt  NUMERIC                := 0;
    v_accntCurrRate1 NUMERIC                := 1;
    v_doctype        CHARACTER VARYING(300) := '';
BEGIN
    /* 1. Create a GL Batch and get all doc lines
     * 2. for each line create costing account transaction
     * 3. create one balancing account transaction using the grand total amount
     * 4. Check if created gl_batch is balanced.
     * 5. if balanced update docHdr else delete the gl batch created and throw error message
     */
    v_usrTrnsCode := gst.getGnrlRecNm('sec.sec_users', 'user_id', 'code_for_trns_nums', p_who_rn);
    IF (char_length(v_usrTrnsCode) <= 0)
    THEN
        v_usrTrnsCode := 'XX';
    END IF;
    v_dte := to_char(now(), 'YYMMDD');
    IF p_DocHdrID <= 0 THEN
        RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = 'No Document to Approve!',
            HINT = 'No Document to Approve!';
    END IF;
    IF p_DocKind = 'Receivables'
    THEN
        v_lnDte := gst.getGnrlRecNm('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'rcvbls_invc_date', p_DocHdrID);
        --msgs := ':' || coalesce(v_lnDte, 'X') || ':'||p_DocHdrID;
        v_lnDte :=
                to_char(to_timestamp(substring(v_lnDte, 1, 10) || to_char(now(), ' HH24:MI:SS'),
                                     'YYYY-MM-DD HH24:MI:SS'),
                        'DD-Mon-YYYY HH24:MI:SS');
        --v_accntID1 := 1 / 0;
        v_docHdrDesc :=
                gst.getGnrlRecNm('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'comments_desc', p_DocHdrID);
        v_docNum :=
                gst.getGnrlRecNm('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'rcvbls_invc_number', p_DocHdrID);
        v_doctype :=
                gst.getGnrlRecNm('accb.accb_rcvbls_invc_hdr', 'rcvbls_invc_hdr_id', 'rcvbls_invc_type', p_DocHdrID);
        v_gnrtdTrnsNo1 := 'RCVBL-' || v_usrTrnsCode || '-' || v_dte || '-';
        v_reslt_1 := accb.recalcrcvblssmmrys(p_docHdrID, v_doctype, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
            RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1,
                HINT = v_reslt_1;
            RETURN msgs;
        END IF;
        UPDATE accb.accb_rcvbls_invc_hdr
        SET invoice_amount=accb.getRcvblsDocGrndAmnt(p_DocHdrID)
        WHERE (rcvbls_invc_hdr_id = p_DocHdrID);
        v_sameprepayCnt := accb.getRcvblsPrepayDocCnt(p_DocHdrID);
        IF (v_sameprepayCnt > 1) THEN
            msgs := 'ERROR: Same Prepayment Cannot be Applied More than Once!';
            RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = msgs,
                HINT = msgs;
            RETURN msgs;
        END IF;
    ELSIF p_DocKind = 'Payables'
    THEN
        v_lnDte := gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_date', p_DocHdrID);
        v_lnDte := to_char(to_timestamp(v_lnDte || to_char(now(), ' HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS'),
                           'DD-Mon-YYYY HH24:MI:SS');
        v_docHdrDesc := gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'comments_desc', p_DocHdrID);
        v_docNum := gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_number', p_DocHdrID);
        v_doctype := gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'pybls_invc_type', p_DocHdrID);
        v_gnrtdTrnsNo1 := 'PYBL-' || v_usrTrnsCode || '-' || v_dte || '-';
        v_frstChqNum :=
                gst.getGnrlRecNm('accb.accb_pybls_invc_hdr', 'pybls_invc_hdr_id', 'firts_cheque_num', p_DocHdrID);
        v_reslt_1 := accb.recalcpyblssmmrys(p_docHdrID, v_doctype, p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
            RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = v_reslt_1 || 'RECLACL',
                HINT = v_reslt_1 || 'RECLACL';
            RETURN msgs;
        END IF;
        UPDATE accb.accb_pybls_invc_hdr
        	SET invoice_amount=accb.getPyblsDocGrndAmnt(p_DocHdrID)
        WHERE (pybls_invc_hdr_id = p_DocHdrID);
        v_sameprepayCnt := accb.getPyblsPrepayDocCnt(p_DocHdrID);
        IF (v_sameprepayCnt > 1) THEN
            msgs := 'ERROR: Same Prepayment Cannot be Applied More than Once!';
            RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = msgs,
                HINT = msgs;
            RETURN msgs;
        END IF;
    END IF;

    v_glBatchName := v_gnrtdTrnsNo1 || lpad(
            ((gst.getRecCount_LstNum('accb.accb_trnsctn_batches', 'batch_name', 'batch_id',
                                     v_gnrtdTrnsNo1 || '%') + 1) || ''), 3, '0');

    v_glBatchID := gst.getGnrlRecID1('accb.accb_trnsctn_batches', 'batch_name', 'batch_id', v_glBatchName, p_orgid);

    IF (v_glBatchID <= 0)
    THEN
        v_reslt_1 := accb.createBatch(p_orgid, v_glBatchName,
                                      v_docHdrDesc || ' (' || v_docNum || ')',
                                      p_DocKind || ' Invoice Document', 'VALID', -1, '0', p_who_rn);
        IF v_reslt_1 NOT LIKE 'SUCCESS:%'
        THEN
            RAISE EXCEPTION USING
                ERRCODE = 'RHERR',
                MESSAGE = 'BATCH CREATION FAILED',
                HINT = 'Journal Batch could not be created!';
            RETURN msgs;
        END IF;
    ELSE
        RETURN 'ERROR:New GL Batch Number Exists! Try Again Later!';
    END IF;

    v_glBatchID := gst.getGnrlRecID1('accb.accb_trnsctn_batches', 'batch_name', 'batch_id', v_glBatchName, p_orgid);
    v_balcngAccntID := -1;
    IF p_DocKind = 'Receivables'
    THEN
        FOR rd1 IN SELECT rcvbl_smmry_id,
                          rcvbl_smmry_type,
                          rcvbl_smmry_desc,
                          rcvbl_smmry_amnt,
                          code_id_behind,
                          auto_calc,
                          incrs_dcrs1,
                          rvnu_acnt_id,
                          incrs_dcrs2,
                          rcvbl_acnt_id,
                          appld_prepymnt_doc_id,
                          entrd_curr_id,
                          gst.get_pssbl_val(a.entrd_curr_id),
                          func_curr_id,
                          gst.get_pssbl_val(a.func_curr_id),
                          accnt_curr_id,
                          gst.get_pssbl_val(a.accnt_curr_id),
                          func_curr_rate,
                          accnt_curr_rate,
                          rcvbl_smmry_amnt * func_curr_rate  func_curr_amount,
                          rcvbl_smmry_amnt * accnt_curr_rate accnt_curr_amnt,
                          ref_doc_number
                   FROM accb.accb_rcvbl_amnt_smmrys a
                   WHERE ((a.src_rcvbl_hdr_id = p_DocHdrID) AND (a.rcvbl_smmry_type != '6Grand Total' AND
                                                                 a.rcvbl_smmry_type != '7Total Payments Made' AND
                                                                 a.rcvbl_smmry_type != '8Outstanding Balance'))
                   ORDER BY rcvbl_smmry_type ASC
            LOOP
                v_lineTypeNm := rd1.rcvbl_smmry_type;
                v_codeBhndID := rd1.code_id_behind;
                v_incrDcrs1 := substr(rd1.incrs_dcrs1, 1, 1);
                v_accntID1 := rd1.rvnu_acnt_id;
                v_isdbtCrdt1 := accb.dbt_or_crdt_accnt(v_accntID1, v_incrDcrs1);

                v_incrDcrs2 := substr(rd1.incrs_dcrs2, 1, 1);
                v_accntID2 := rd1.rcvbl_acnt_id;
                v_balcngAccntID := v_accntID2;
                v_entrdAmnt := rd1.rcvbl_smmry_amnt;
                IF v_lineTypeNm = '1Initial Amount' THEN
                    v_incrDcrs3 := v_incrDcrs2;
                    v_accntID3 := v_accntID2;
                end if;
                v_lnAmnt := rd1.func_curr_amount;

                v_acntAmnt := rd1.accnt_curr_amnt;

                v_lneDesc := rd1.rcvbl_smmry_desc;
                v_entrdCurrID := rd1.entrd_curr_id;
                v_funcCurrID := rd1.func_curr_id;
                v_accntCurrID := rd1.accnt_curr_id;
                v_funcCurrRate := rd1.func_curr_rate;
                v_accntCurrRate := rd1.accnt_curr_rate;
                v_ref_doc_number := rd1.ref_doc_number;
                IF char_length(v_ref_doc_number) <= 0 AND char_length(v_frstChqNum) > 0
                THEN
                    v_ref_doc_number := v_frstChqNum;
                END IF;
                IF (v_accntID1 > 0 AND (v_lnAmnt != 0 OR v_acntAmnt != 0) AND char_length(v_incrDcrs1) > 0 AND
                    char_length(v_lneDesc) > 0)
                THEN
                    v_netAmnt := accb.dbt_or_crdt_accnt_multiplier(v_accntID1, v_incrDcrs1) * v_lnAmnt;
					
					v_reslt_1 := accb.isTransPrmttd (p_orgid, v_accntID1, v_lnDte, v_netAmnt);
					IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
						RAISE EXCEPTION
								USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
					END IF;	
                    IF (v_isdbtCrdt1 = 'Debit')
                    THEN
                        v_reslt_1 := accb.createTransaction(v_accntID1,
                                                            v_lneDesc, v_lnAmnt,
                                                            v_lnDte, v_funcCurrID, v_glBatchID, 0.00,
                                                            v_netAmnt, ',', v_entrdAmnt, v_entrdCurrID, v_acntAmnt,
                                                            v_accntCurrID, v_funcCurrRate, v_accntCurrRate, 'D', '',
                                                            p_DocKind || ' Invoice', rd1.rcvbl_smmry_id, p_who_rn);
                    ELSE
                        v_reslt_1 := accb.createTransaction(v_accntID1,
                                                            v_lneDesc, 0.00,
                                                            v_lnDte, v_funcCurrID,
                                                            v_glBatchID, v_lnAmnt, v_netAmnt, ',',
                                                            v_entrdAmnt, v_entrdCurrID, v_acntAmnt, v_accntCurrID,
                                                            v_funcCurrRate, v_accntCurrRate, 'C', '',
                                                            p_DocKind || ' Invoice',
                                                            rd1.rcvbl_smmry_id, p_who_rn);
                    END IF;
                    v_funcCurrAmnt := v_funcCurrAmnt + v_lnAmnt;
                    v_grndAmnt := v_grndAmnt + v_entrdAmnt;
                    IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                    THEN
                        RAISE EXCEPTION USING
                            ERRCODE = 'RHERR',
                            MESSAGE = 'BATCH TRANSACTION CREATION FAILED',
                            HINT = 'Journal Batch Transaction could not be created!';
                        RETURN msgs;
                    END IF;
                END IF;
            END LOOP;
    ELSIF p_DocKind = 'Payables'
    THEN
        FOR rd1 IN SELECT pybls_smmry_id,
                          pybls_smmry_type,
                          pybls_smmry_desc,
                          pybls_smmry_amnt,
                          code_id_behind,
                          auto_calc,
                          incrs_dcrs1,
                          asset_expns_acnt_id,
                          incrs_dcrs2,
                          liability_acnt_id,
                          appld_prepymnt_doc_id,
                          entrd_curr_id,
                          gst.get_pssbl_val(a.entrd_curr_id),
                          func_curr_id,
                          gst.get_pssbl_val(a.func_curr_id),
                          accnt_curr_id,
                          gst.get_pssbl_val(a.accnt_curr_id),
                          func_curr_rate,
                          accnt_curr_rate,
                          pybls_smmry_amnt * func_curr_rate  func_curr_amount,
                          pybls_smmry_amnt * accnt_curr_rate accnt_curr_amnt,
                          ref_doc_number
                   FROM accb.accb_pybls_amnt_smmrys a
                   WHERE ((a.src_pybls_hdr_id = p_DocHdrID) AND (a.pybls_smmry_type != '6Grand Total' AND
                                                                 a.pybls_smmry_type != '7Total Payments Made' AND
                                                                 a.pybls_smmry_type != '8Outstanding Balance'))
                   ORDER BY pybls_smmry_type ASC
            LOOP
                v_lineTypeNm := rd1.pybls_smmry_type;
                v_codeBhndID := rd1.code_id_behind;
                v_incrDcrs1 := substr(rd1.incrs_dcrs1, 1, 1);
                v_accntID1 := rd1.asset_expns_acnt_id;
                v_isdbtCrdt1 := accb.dbt_or_crdt_accnt(v_accntID1, v_incrDcrs1);

                v_incrDcrs2 := substr(rd1.incrs_dcrs2, 1, 1);
                v_accntID2 := rd1.liability_acnt_id;
                v_balcngAccntID := v_accntID2;
                IF v_lineTypeNm = '1Initial Amount' THEN
                    v_incrDcrs3 := v_incrDcrs2;
                    v_accntID3 := v_accntID2;
                end if;
                v_isdbtCrdt2 := accb.dbt_or_crdt_accnt(v_accntID2, v_incrDcrs2);
                v_lnAmnt := rd1.func_curr_amount;
                v_acntAmnt := rd1.accnt_curr_amnt;
                v_entrdAmnt := rd1.pybls_smmry_amnt;

                v_lneDesc := rd1.pybls_smmry_desc;
                v_entrdCurrID := rd1.entrd_curr_id;
                v_funcCurrID := rd1.func_curr_id;
                v_accntCurrID := rd1.accnt_curr_id;
                v_funcCurrRate := rd1.func_curr_rate;
                v_accntCurrRate := rd1.accnt_curr_rate;
                v_ref_doc_number := rd1.ref_doc_number;
                IF char_length(v_ref_doc_number) <= 0 AND char_length(v_frstChqNum) > 0
                THEN
                    v_ref_doc_number := v_frstChqNum;
                END IF;
                IF (v_accntID1 > 0 AND (v_lnAmnt != 0 OR v_acntAmnt != 0) AND char_length(v_incrDcrs1) > 0 AND
                    char_length(v_lneDesc) > 0)
                THEN
                    v_netAmnt := accb.dbt_or_crdt_accnt_multiplier(v_accntID1, v_incrDcrs1) * v_lnAmnt;
	
				v_reslt_1 := accb.isTransPrmttd (p_orgid, v_accntID1, v_lnDte, v_netAmnt);
				IF v_reslt_1 NOT LIKE 'SUCCESS:%' THEN
					RAISE EXCEPTION
							USING ERRCODE = 'RHERR', MESSAGE = v_reslt_1, HINT = v_reslt_1;
				END IF;	
                    IF (v_isdbtCrdt1 = 'Debit')
                    THEN
                        v_reslt_1 := accb.createTransaction(v_accntID1,
                                                            v_lneDesc, v_lnAmnt,
                                                            v_lnDte, v_funcCurrID, v_glBatchID, 0.00,
                                                            v_netAmnt, ',', v_entrdAmnt, v_entrdCurrID, v_acntAmnt,
                                                            v_accntCurrID, v_funcCurrRate, v_accntCurrRate, 'D', '',
                                                            p_DocKind || ' Invoice', rd1.pybls_smmry_id, p_who_rn);
                    ELSE
                        v_reslt_1 := accb.createTransaction(v_accntID1,
                                                            v_lneDesc, 0.00,
                                                            v_lnDte, v_funcCurrID,
                                                            v_glBatchID, v_lnAmnt, v_netAmnt, ',',
                                                            v_entrdAmnt, v_entrdCurrID, v_acntAmnt, v_accntCurrID,
                                                            v_funcCurrRate, v_accntCurrRate, 'C', '',
                                                            p_DocKind || ' Invoice',
                                                            rd1.pybls_smmry_id, p_who_rn);
                    END IF;
                    v_funcCurrAmnt := v_funcCurrAmnt + v_lnAmnt;
                    v_grndAmnt := v_grndAmnt + v_entrdAmnt;
                    IF v_reslt_1 NOT LIKE 'SUCCESS:%'
                    THEN
                        RAISE EXCEPTION USING
                            ERRCODE = 'RHERR',
                            MESSAGE = 'BATCH TRANSACTION CREATION FAILED ' || v_reslt_1,
                            HINT = 'Journal Batch Transaction could not be created! ' || v_reslt_1;
                        RETURN msgs;
                    END IF;
                END IF;
            END LOOP;
    END IF;

    --Balancing Leg

    v_accntCurrID := gst.getGnrlRecNm('accb.accb_chart_of_accnts', 'accnt_id', 'crncy_id', v_balcngAccntID) :: INTEGER;
    v_funcCurrRate := accb.get_ltst_exchrate(v_entrdCurrID, v_funcCurrID, v_lnDte, p_orgid);
    v_accntCurrRate := accb.get_ltst_exchrate(v_entrdCurrID, v_accntCurrID, v_lnDte, p_orgid);
    v_accntID2 := v_accntID3;
    IF p_DocKind = 'Receivables'
    THEN
        v_isdbtCrdt2 := 'I';
        v_isdbtCrdt2 := v_incrDcrs3;
        v_grndAmnt := accb.getRcvblsDocGrndAmnt(p_DocHdrID);
        v_funcCurrAmnt := accb.getRcvblsDocFuncAmnt(p_DocHdrID);
    ELSIF p_DocKind = 'Payables'
    THEN
        v_isdbtCrdt2 := 'I';
        v_isdbtCrdt2 := v_incrDcrs3;
        v_grndAmnt := accb.getPyblsDocGrndAmnt(p_DocHdrID);
        v_funcCurrAmnt = accb.getPyblsDocFuncAmnt(p_DocHdrID);
    END IF;
    v_accntCurrAmnt := (v_accntCurrRate1 * v_grndAmnt);
    v_netAmnt := accb.dbt_or_crdt_accnt_multiplier(v_accntID2, v_isdbtCrdt2) * v_funcCurrAmnt;
    v_isdbtCrdt2 := accb.dbt_or_crdt_accnt(v_accntID2, v_isdbtCrdt2);
    IF (v_isdbtCrdt2 = 'Debit')
    THEN
        v_reslt_1 := accb.createTransaction(v_balcngAccntID,
                                            v_docHdrDesc ||
                                            ' (Balacing Leg for ' || p_DocKind || ' Doc:-' ||
                                            v_docNum || ')', v_funcCurrAmnt,
                                            v_lnDte, v_funcCurrID, v_glBatchID, 0.00,
                                            v_netAmnt, ',', v_grndAmnt, v_entrdCurrID,
                                            v_accntCurrAmnt, v_accntCurrID, v_funcCurrRate, v_accntCurrRate, 'D', '',
                                            p_DocKind || ' Invoice', -1, p_who_rn);
    ELSE
        v_reslt_1 := accb.createTransaction(v_balcngAccntID,
                                            v_docHdrDesc ||
                                            ' (Balacing Leg for ' || p_DocKind || ' Doc:-' ||
                                            v_docNum || ')', 0.00,
                                            v_lnDte, v_funcCurrID,
                                            v_glBatchID, v_funcCurrAmnt, v_netAmnt, ',',
                                            v_grndAmnt, v_entrdCurrID, v_accntCurrAmnt,
                                            v_accntCurrID, v_funcCurrRate, v_accntCurrRate, 'C', '',
                                            p_DocKind || ' Invoice', -1, p_who_rn);
    END IF;
    IF v_reslt_1 NOT LIKE 'SUCCESS:%'
    THEN
        RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = 'BALANCING TRANSACTION CREATION FAILED ' || v_reslt_1,
            HINT = 'BALANCING Transaction could not be created! ' || v_reslt_1;
        RETURN msgs;
    END IF;
    msgs := 'CR:' || accb.get_Batch_CrdtSum(v_glBatchID) || ':DR:' || accb.get_Batch_DbtSum(v_glBatchID);
    --v_balcngAccntID := 1 / 0;
    IF (accb.get_Batch_CrdtSum(v_glBatchID) = accb.get_Batch_DbtSum(v_glBatchID))
    THEN
        IF p_DocKind = 'Receivables'
        THEN
            UPDATE accb.accb_rcvbls_invc_hdr
            SET gl_batch_id      = v_glBatchID,
                last_update_by   = p_who_rn,
                last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
            WHERE (rcvbls_invc_hdr_id = p_DocHdrID);

            UPDATE accb.accb_trnsctn_batches
            SET avlbl_for_postng = '1',
                last_update_by   = p_who_rn,
                last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
            WHERE batch_id = v_glBatchID;

            UPDATE accb.accb_rcvbls_invc_hdr
            SET approval_status     = 'Approved',
                last_update_by      = p_who_rn,
                last_update_date    = to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),
                next_aproval_action = 'Cancel'
            WHERE (rcvbls_invc_hdr_id = p_DocHdrID);
        ELSIF p_DocKind = 'Payables'
        THEN
            UPDATE accb.accb_pybls_invc_hdr
            SET gl_batch_id      = v_glBatchID,
                last_update_by   = p_who_rn,
                last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
            WHERE (pybls_invc_hdr_id = p_DocHdrID);

            UPDATE accb.accb_trnsctn_batches
            SET avlbl_for_postng = '1',
                last_update_by   = p_who_rn,
                last_update_date = to_char(now(), 'YYYY-MM-DD HH24:MI:SS')
            WHERE batch_id = v_glBatchID;

            UPDATE accb.accb_pybls_invc_hdr
            SET approval_status     = 'Approved',
                last_update_by      = p_who_rn,
                last_update_date    = to_char(now(), 'YYYY-MM-DD HH24:MI:SS'),
                next_aproval_action = 'Cancel'
            WHERE (pybls_invc_hdr_id = p_DocHdrID);
        END IF;
    ELSE
        msgs := 'ERROR:The GL Batch created is not Balanced!Transactions created will be reversed and deleted! ' ||
                msgs;
        DELETE FROM accb.accb_trnsctn_details WHERE (batch_id = v_glBatchID);
        DELETE FROM accb.accb_trnsctn_batches WHERE (batch_id = v_glBatchID);
        UPDATE accb.accb_trnsctn_batches
        SET batch_vldty_status = 'VALID'
        WHERE batch_id IN (SELECT h.batch_id
                           FROM accb.accb_trnsctn_batches h
                           WHERE batch_vldty_status = 'VOID'
                             AND NOT EXISTS(SELECT g.batch_id
                                            FROM accb.accb_trnsctn_batches g
                                            WHERE h.batch_id = g.src_batch_id));
        RAISE EXCEPTION USING
            ERRCODE = 'RHERR',
            MESSAGE = msgs,
            HINT = msgs;
        RETURN msgs;
    END IF;
    RETURN 'SUCCESS: ' || p_DocKind || ' Document Approved!';
EXCEPTION
    WHEN OTHERS
        THEN
            msgs := msgs || v_reslt_1;
            RETURN 'ERROR:' || p_DocKind || 'APPROVAL:' || SQLERRM || ' [' || msgs || ']';
END;
$BODY$;