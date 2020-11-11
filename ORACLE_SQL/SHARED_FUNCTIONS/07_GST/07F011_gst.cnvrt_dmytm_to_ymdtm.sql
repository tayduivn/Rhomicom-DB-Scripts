/* Formatted on 12-14-2018 5:48:54 PM (QP5 v5.126.903.23003) */
-- Function: gst.cnvrt_dmytm_to_ymdtm(VARCHAR2)

-- DROP FUNCTION gst.cnvrt_dmytm_to_ymdtm(VARCHAR2);

CREATE OR REPLACE FUNCTION gst.cnvrt_dmytm_to_ymdtm (inptdte VARCHAR2)
   RETURN VARCHAR2
AS
   bid   VARCHAR2 (21) := '';
BEGIN
   SELECT   TO_CHAR (TO_TIMESTAMP (inptDte, 'DD-Mon-YYYY HH24:MI:SS'),
                     'YYYY-MM-DD HH24:MI:SS')
     INTO   bid
     FROM   DUAL;

   RETURN COALESCE (bid, '');
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN '';
END;