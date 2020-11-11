/* Formatted on 10/6/2014 2:05:57 AM (QP5 v5.126.903.23003) */
-- Function: APLAPPS.get_ltst_stock_rsrvd_bals(NUMBER)

-- DROP FUNCTION APLAPPS.get_ltst_stock_rsrvd_bals(NUMBER);

CREATE OR REPLACE FUNCTION APLAPPS.get_ltst_stock_rsrvd_bals (stckid NUMBER)
   RETURN NUMBER
AS
   bid   NUMBER := 0.00;
BEGIN
   SELECT   TBL1.RSVTNS
     INTO   bid
     FROM   (  SELECT   NVL (a.reservations, 0) RSVTNS
                 FROM   INV.inv_stock_daily_bals a
                WHERE   (a.stock_id = stckid)
             ORDER BY   a.bals_date DESC) TBL1
    WHERE   ROWNUM < 2;                                   -- LIMIT 1 OFFSET 0;

   RETURN NVL (bid, 0);
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN 0.00;
END;
/