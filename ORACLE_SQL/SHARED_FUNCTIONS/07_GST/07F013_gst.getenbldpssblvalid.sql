/* Formatted on 12-14-2018 5:54:58 PM (QP5 v5.126.903.23003) */
-- Function: gst.getenbldpssblvalid(VARCHAR2, integer)

-- DROP FUNCTION gst.getenbldpssblvalid(VARCHAR2, integer);

CREATE OR REPLACE FUNCTION gst.getenbldpssblvalid (p_pssblval    VARCHAR2,
                                                   p_lovid       INTEGER)
   RETURN INTEGER
AS
   L_RESULT   INTEGER := -1;
BEGIN
   SELECT   tbl1.pssbl_value_id
     INTO   L_RESULT
     FROM   (  SELECT   pssbl_value_id
                 FROM   gst.gen_stp_lov_values
                WHERE       LOWER (pssbl_value) LIKE LOWER (p_pssblval)
                        AND value_list_id = p_lovid
                        AND is_enabled = '1'
             ORDER BY   pssbl_value_id ASC) tbl1
    WHERE   ROWNUM = 1;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN '';
END;
/