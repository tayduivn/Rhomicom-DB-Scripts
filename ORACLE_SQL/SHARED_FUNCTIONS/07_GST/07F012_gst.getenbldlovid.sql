/* Formatted on 12-14-2018 5:51:35 PM (QP5 v5.126.903.23003) */
-- Function: gst.getenbldlovid(character varying)

-- DROP FUNCTION gst.getenbldlovid(character varying);

CREATE OR REPLACE FUNCTION gst.getenbldlovid (p_lovname VARCHAR2)
   RETURN INTEGER
AS
   L_RESULT   INTEGER := -1;
BEGIN
   SELECT   value_list_id
     INTO   L_RESULT
     FROM   gst.gen_stp_lov_names
    WHERE   LOWER (value_list_name) LIKE LOWER (p_lovname)
            AND is_enabled = '1';

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN '';
END;
/