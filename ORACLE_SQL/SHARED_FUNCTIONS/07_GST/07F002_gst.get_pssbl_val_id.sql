/* Formatted on 12-13-2018 10:15:34 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION gst.get_pssbl_val_id (p_pssblval    VARCHAR2,
                                                 p_lovid       NUMBER)
   RETURN NUMBER
AS
   L_RESULT   NUMBER;
BEGIN
   SELECT   tbl1.pssbl_value_id
     INTO   L_RESULT
     FROM   (  SELECT   pssbl_value_id
                 FROM   gst.gen_stp_lov_values
                WHERE   LOWER (pssbl_value) LIKE LOWER (p_pssblval)
                        AND value_list_id = p_lovid
             ORDER BY   pssbl_value_id ASC) tbl1
    WHERE   ROWNUM = 1;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN -1;
END;
/