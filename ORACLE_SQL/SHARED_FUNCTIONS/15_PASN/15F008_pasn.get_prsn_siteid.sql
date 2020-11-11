/* Formatted on 12-20-2018 8:34:05 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PASN.GET_PRSN_JOBID (P_PERSONID NUMBER)
   RETURN INTEGER
AS
   BID   INTEGER := -1;
BEGIN
   SELECT   TBL1.LOCATION_ID
     INTO   BID
     FROM   (  SELECT   A.LOCATION_ID
                 FROM   PASN.PRSN_LOCATIONS A
                WHERE   ( (A.PERSON_ID = P_PERSONID)
                         AND (SYSDATE BETWEEN TO_TIMESTAMP (
                                                 A.VALID_START_DATE,
                                                 'YYYY-MM-DD 00:00:00'
                                              )
                                          AND  TO_TIMESTAMP (
                                                  A.VALID_END_DATE,
                                                  'YYYY-MM-DD 23:59:59'
                                               )))
             ORDER BY   A.PRSN_LOC_ID DESC) TBL1
    WHERE   ROWNUM <= 1;

   RETURN COALESCE (BID, -1);
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN COALESCE (BID, -1);
END;