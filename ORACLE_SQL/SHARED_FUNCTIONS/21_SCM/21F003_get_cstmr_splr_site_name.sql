/* Formatted on 12-19-2018 2:30:12 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION SCM.GET_CSTMR_SPLR_SITE_NAME (
   P_CSTMRSPLRSITEID NUMBER
)
   RETURN VARCHAR2
AS
   L_RESULT   VARCHAR2 (200 BYTE);
BEGIN
   SELECT   SITE_NAME
     INTO   L_RESULT
     FROM   SCM.SCM_CSTMR_SUPLR_SITES
    WHERE   CUST_SUP_SITE_ID = P_CSTMRSPLRSITEID;

   RETURN COALESCE (L_RESULT, '');
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN '';
END;
/