/* Formatted on 10/6/2014 9:13:22 PM (QP5 v5.126.903.23003) */
-- FUNCTION: APLAPPS.GET_INV_SLLNG_PRICE(NUMBER, NUMBER, NUMBER, VARCHAR2, VARCHAR2)

-- DROP FUNCTION APLAPPS.GET_INV_SLLNG_PRICE(NUMBER, NUMBER, NUMBER, VARCHAR2, VARCHAR2);
--DROP TYPE APLAPPS.T_INV_TABLE1;

CREATE OR REPLACE TYPE APLAPPS.T_INV_COLS1 AS OBJECT
   (ITEM_ID NUMBER,
    ITEM_CODE VARCHAR2 (200),
    ITEM_DESC VARCHAR2 (300),
    CAT_NAME VARCHAR2 (200),
    SUBINV_NAME VARCHAR2 (200),
    TOTQTY VARCHAR2 (200),
    UOM_NAME VARCHAR2 (200),
    COSTPRICE VARCHAR2 (200),
    PRICELESSTAX VARCHAR2 (200),
    TAXAMNT VARCHAR2 (200),
    DSCNTAMNT VARCHAR2 (200),
    CHARGEAMNT VARCHAR2 (200),
    CRNT_SLLNG_RPICE NUMBER,
    CRNT_PRFT_AMNT NUMBER,
    CRNT_PRFT_MGN NUMBER,
    NWPRICELESSTAXES VARCHAR2 (200),
    NWTAXAMNT VARCHAR2 (200),
    NWDSCNTAMNT VARCHAR2 (200),
    NWCHARGEAMNT VARCHAR2 (200),
    NW_PRFT_MGN VARCHAR2 (200),
    NW_PRFT_AMNT VARCHAR2 (200),
    NW_SLLNG_RPICE VARCHAR2 (200));

CREATE OR REPLACE TYPE APLAPPS.T_INV_TABLE1 AS TABLE OF APLAPPS.T_INV_COLS1;

CREATE OR REPLACE FUNCTION APLAPPS.GET_INV_SLLNG_PRICE (
   ORGID        NUMBER,
   STORID       NUMBER,
   CATEGRID     NUMBER,
   NWPRFTMGN    VARCHAR2,
   ORDRBYCLS    VARCHAR2
)
   RETURN APLAPPS.T_INV_TABLE1
AS
   WHERECLAUSE   CLOB;
   FULLSQL       CLOB;
   RECORDS       APLAPPS.T_INV_TABLE1;
   EXEQUERY      CLOB;
BEGIN
   WHERECLAUSE :=
      'WHERE a.category_id = c.cat_id and e.uom_id=a.base_uom_id and a.org_id='
      || ORGID;

   IF STORID > 0
   THEN
      WHERECLAUSE := WHERECLAUSE || ' AND d.subinv_id=' || STORID;
   END IF;

   IF CATEGRID > 0
   THEN
      WHERECLAUSE := WHERECLAUSE || ' AND a.category_id=' || CATEGRID;
   END IF;

   --RAISE NOTICE 'WHERECLAUSE = "%"', WHERECLAUSE;


   FULLSQL :=
      'SELECT item_id, item_code, item_desc, cat_name, subinv_name, totqty, uom_name,costprice, pricelesstax,
taxamnt, dscntamnt,chrgeamnt,selling_price crnt_sllng_rpice,
selling_price-chrgeamnt-taxamnt-costprice crntprftamnt,
CASE WHEN costprice!=0 THEN 100*((selling_price-chrgeamnt-taxamnt-costprice)/costprice) ELSE 0 END crntprftmgn,
nwprclsstax,
nwtaxamnt,
nwdscntamnt, 
nwchrgeamnt,
nwprftmgn,
nwprftamnt,
nwprclsstax+nwchrgeamnt+nwtaxamnt nwsllngprice
FROM (SELECT a.item_id, a.item_code, a.item_desc, c.cat_name, b.subinv_name, 
APLAPPS.get_ltst_stock_bals(d.stock_id,to_char(now(),''YYYY-MM-DD'')) totqty, 
e.uom_name, 
APLAPPS.get_hgst_cost_price(a.item_id) costprice, 
a.orgnl_selling_price pricelesstax, 
a.tax_code_id,
a.dscnt_code_id,
a.extr_chrg_id,
APLAPPS.get_doc_codes_amnt(a.tax_code_id, a.orgnl_selling_price-APLAPPS.get_doc_codes_amnt(a.dscnt_code_id, a.orgnl_selling_price, 1), 1) taxamnt,
APLAPPS.get_doc_codes_amnt(a.dscnt_code_id, a.orgnl_selling_price, 1) dscntamnt, 
APLAPPS.get_doc_codes_amnt(a.extr_chrg_id, a.orgnl_selling_price, 1) chrgeamnt, 
a.selling_price, 
((100.00 + '
      || NWPRFTMGN
      || ')*APLAPPS.get_hgst_cost_price(a.item_id))/100.00 nwprclsstax,
APLAPPS.get_doc_codes_amnt(a.tax_code_id, (((100.00 + '
      || NWPRFTMGN
      || ')*APLAPPS.get_hgst_cost_price(a.item_id))/100.00)-(APLAPPS.get_doc_codes_amnt(a.dscnt_code_id,((100.00 + '
      || NWPRFTMGN
      || ')*APLAPPS.get_hgst_cost_price(a.item_id))/100.00, 1)), 1) nwtaxamnt,
APLAPPS.get_doc_codes_amnt(a.dscnt_code_id, ((100.00 + '
      || NWPRFTMGN
      || ')*APLAPPS.get_hgst_cost_price(a.item_id))/100.00, 1) nwdscntamnt, 
APLAPPS.get_doc_codes_amnt(a.extr_chrg_id, ((100.00 + '
      || NWPRFTMGN
      || ')*APLAPPS.get_hgst_cost_price(a.item_id))/100.00, 1) nwchrgeamnt,
'
      || NWPRFTMGN
      || ' nwprftmgn, 
('
      || NWPRFTMGN
      || '*APLAPPS.get_hgst_cost_price(a.item_id))/100.00 nwprftamnt
FROM inv.inv_itm_list a LEFT OUTER JOIN inv.inv_stock d ON (a.item_id = d.itm_id) LEFT OUTER JOIN inv.inv_itm_subinventories b ON (d.subinv_id = b.subinv_id), inv.inv_product_categories c, inv.unit_of_measure e 
'
      || WHERECLAUSE
      || '
) tbl1
ORDER BY '
      || ORDRBYCLS;

   --RAISE NOTICE 'FULL QUERY = "%"', FULLSQL;

   EXEQUERY := '' || FULLSQL || '';

   EXECUTE IMMEDIATE   'SELECT   CAST (MULTISET('
                    || EXEQUERY
                    || ') AS APLAPPS.T_INV_TABLE1) 
     FROM   DUAL'
      INTO   RECORDS;

   RETURN RECORDS;
END;
/

--EXECUTE IMMEDIATE