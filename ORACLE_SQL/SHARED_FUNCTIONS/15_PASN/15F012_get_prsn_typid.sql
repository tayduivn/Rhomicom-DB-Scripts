/* Formatted on 12-20-2018 8:49:56 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PASN.GET_PRSN_TYPID (P_PERSONID NUMBER)
   RETURN INTEGER
AS
   BID   INTEGER := -1;
BEGIN
   SELECT   TBL1.PRSNTYPE_ID
     INTO   BID
     FROM   (  SELECT   GST.GET_PSSBL_VAL_ID (A.PRSN_TYPE,
                                              GST.GET_LOV_ID ('Person Types'))
                           PRSNTYPE_ID
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

   RETURN COALESCE (BID, -1);
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN COALESCE (BID, -1);
END;