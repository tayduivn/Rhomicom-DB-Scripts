/* Formatted on 12-20-2018 8:37:37 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PASN.GET_PRSN_TYPE (P_PERSONID NUMBER)
   RETURN VARCHAR2
AS
   BID   VARCHAR2 (200) := '';
BEGIN
   SELECT   TBL1.PRSN_TYPE
     INTO   BID
     FROM   (  SELECT   A.PRSN_TYPE
                 FROM   PASN.PRSN_PRSNTYPS A
                WHERE   ( (A.PERSON_ID = P_PERSONID)
                         AND (SYSDATE BETWEEN TO_TIMESTAMP (
                                                 A.VALID_START_DATE,
                                                 'YYYY-MM-DD 00:00:00'
                                              )
                                          AND  TO_TIMESTAMP (
                                                  A.VALID_END_DATE,
                                                  'YYYY-MM-DD 23:59:59'
                                               )))
             ORDER BY   A.PRSNTYPE_ID DESC) TBL1
    WHERE   ROWNUM <= 1;

   RETURN COALESCE (BID, '');
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN COALESCE (BID, '');
END;