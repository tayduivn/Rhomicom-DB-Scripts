/* Formatted on 12-20-2018 9:59:43 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION ORG.DOES_PRSN_HV_CRTRIA_ID (
   PRSN_ID       NUMBER,
   CRTRIAID      NUMBER,
   CRTRIATYPE    VARCHAR2
)
   RETURN INTEGER
AS
   BID   INTEGER := -1;
BEGIN
   IF CRTRIATYPE = 'Everyone'
   THEN
      SELECT   1 INTO BID FROM DUAL;
   ELSIF CRTRIATYPE = 'Divisions/Groups'
   THEN
      SELECT   COUNT (1)
        INTO   BID
        FROM   PASN.PRSN_DIVS_GROUPS A
       WHERE   A.DIV_ID = CRTRIAID AND A.PERSON_ID = PRSN_ID
               AND (SYSDATE BETWEEN TO_TIMESTAMP (A.VALID_START_DATE,
                                                  'YYYY-MM-DD 00:00:00')
                                AND  TO_TIMESTAMP (A.VALID_END_DATE,
                                                   'YYYY-MM-DD 23:59:59'));
   ELSIF CRTRIATYPE = 'Grade'
   THEN
      SELECT   COUNT (1)
        INTO   BID
        FROM   PASN.PRSN_GRADES A
       WHERE   A.GRADE_ID = CRTRIAID AND A.PERSON_ID = PRSN_ID
               AND (SYSDATE BETWEEN TO_TIMESTAMP (A.VALID_START_DATE,
                                                  'YYYY-MM-DD 00:00:00')
                                AND  TO_TIMESTAMP (A.VALID_END_DATE,
                                                   'YYYY-MM-DD 23:59:59'));
   ELSIF CRTRIATYPE = 'Job'
   THEN
      SELECT   COUNT (1)
        INTO   BID
        FROM   PASN.PRSN_JOBS A
       WHERE   A.JOB_ID = CRTRIAID AND A.PERSON_ID = PRSN_ID
               AND (SYSDATE BETWEEN TO_TIMESTAMP (A.VALID_START_DATE,
                                                  'YYYY-MM-DD 00:00:00')
                                AND  TO_TIMESTAMP (A.VALID_END_DATE,
                                                   'YYYY-MM-DD 23:59:59'));
   ELSIF CRTRIATYPE = 'Position'
   THEN
      SELECT   COUNT (1)
        INTO   BID
        FROM   PASN.PRSN_POSITIONS A
       WHERE   A.POSITION_ID = CRTRIAID AND A.PERSON_ID = PRSN_ID
               AND (SYSDATE BETWEEN TO_TIMESTAMP (A.VALID_START_DATE,
                                                  'YYYY-MM-DD 00:00:00')
                                AND  TO_TIMESTAMP (A.VALID_END_DATE,
                                                   'YYYY-MM-DD 23:59:59'));
   ELSIF CRTRIATYPE = 'Site/Location'
   THEN
      SELECT   COUNT (1)
        INTO   BID
        FROM   PASN.PRSN_LOCATIONS A
       WHERE   A.LOCATION_ID = CRTRIAID AND A.PERSON_ID = PRSN_ID
               AND (SYSDATE BETWEEN TO_TIMESTAMP (A.VALID_START_DATE,
                                                  'YYYY-MM-DD 00:00:00')
                                AND  TO_TIMESTAMP (A.VALID_END_DATE,
                                                   'YYYY-MM-DD 23:59:59'));
   ELSIF CRTRIATYPE = 'Single Person'
   THEN
      SELECT   COUNT (1)
        INTO   BID
        FROM   PRS.PRSN_NAMES_NOS A
       WHERE   A.PERSON_ID = PRSN_ID AND PRSN_ID = CRTRIAID;
   ELSIF CRTRIATYPE = 'Person Type'
   THEN
      SELECT   COUNT (1)
        INTO   BID
        FROM   PASN.PRSN_PRSNTYPS A
       WHERE   ( (A.PERSON_ID = PRSN_ID)
                AND GST.GET_PSSBL_VAL_ID (A.PRSN_TYPE,
                                          GST.GET_LOV_ID ('Person Types')) =
                      CRTRIAID
                AND (SYSDATE BETWEEN TO_TIMESTAMP (A.VALID_START_DATE,
                                                   'YYYY-MM-DD 00:00:00')
                                 AND  TO_TIMESTAMP (A.VALID_END_DATE,
                                                    'YYYY-MM-DD 23:59:59')));
   ELSE
      SELECT   1 INTO BID FROM DUAL;
   END IF;

   RETURN COALESCE (BID, 1);
END;