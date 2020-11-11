/* Formatted on 12-19-2018 6:34:46 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PASN.AUTO_CNVRT_PRSNTYPE (
   ORGID            INTEGER,
   CUR_PRSN_TYPE    VARCHAR2,
   NEWPRSNTYP       VARCHAR2,
   NEWPRSNTYPRSN    VARCHAR2,
   FTHDETAILS       VARCHAR2,
   MSGID            NUMBER,
   RUNBY            NUMBER
)
   RETURN CLOB
AS
   MSGS CLOB
         := CHR (10) || 'Auto Conversion of Person Type About to Start...';
   --ROW_DATA RECORD;
   UPDTMSG   NUMBER := 0;
BEGIN
   FOR ROW_DATA
   IN (  SELECT   DISTINCT
                  C.PERSON_ID,
                  C.LOCAL_ID_NO ID_NO,
                  TRIM(   C.TITLE
                       || ' '
                       || C.SUR_NAME
                       || ', '
                       || C.FIRST_NAME
                       || ' '
                       || C.OTHER_NAMES)
                     FULLNAME,
                  SUM(PAY.GET_LTST_BLSITM_BALS (
                         C.PERSON_ID,
                         ORG.GET_PAYITM_ID (B.ITEM_CODE_NAME),
                         TO_CHAR (NOW (), 'YYYY-MM-DD')
                      ))
                     TOTAL_BALANCE,
                  MAX( (SELECT   MAX (SUBSTR (Y.PAYMNT_DATE, 1, 10))
                          FROM   PAY.PAY_ITM_TRNSCTNS Y
                         WHERE   Y.PERSON_ID = F.PERSON_ID
                                 AND UPPER (ORG.GET_PAYITM_NM (Y.ITEM_ID)) LIKE
                                       UPPER ('%(Payment)%')))
                     PAY_DATE
           FROM            PRS.PRSN_NAMES_NOS C
                        LEFT OUTER JOIN
                           PASN.PRSN_PRSNTYPS PPT
                        ON (C.PERSON_ID = PPT.PERSON_ID
                            AND (NOW () BETWEEN TO_TIMESTAMP (
                                                   PPT.VALID_START_DATE,
                                                   'YYYY-MM-DD HH24:MI:SS'
                                                )
                                            AND  TO_TIMESTAMP (
                                                    PPT.VALID_END_DATE,
                                                    'YYYY-MM-DD HH24:MI:SS'
                                                 )))
                     LEFT OUTER JOIN
                        PASN.PRSN_BNFTS_CNTRBTNS F
                     ON (C.PERSON_ID = F.PERSON_ID)
                  LEFT OUTER JOIN
                     ORG.ORG_PAY_ITEMS B
                  ON (B.ITEM_ID = F.ITEM_ID)
          WHERE   (    (B.ORG_ID = ORGID)
                   AND (B.ITEM_MAJ_TYPE = 'Balance Item')
                   AND PPT.PRSN_TYPE = CUR_PRSN_TYPE
                   AND (SELECT   COUNT (1)
                          FROM   PAY.PAY_ITM_TRNSCTNS Y
                         WHERE   Y.PERSON_ID = F.PERSON_ID
                                 AND UPPER (ORG.GET_PAYITM_NM (Y.ITEM_ID)) LIKE
                                       UPPER ('%(Payment)%')) > 0)
       GROUP BY   1, 2
         HAVING   SUM(PAY.GET_LTST_BLSITM_BALS (
                         C.PERSON_ID,
                         ORG.GET_PAYITM_ID (B.ITEM_CODE_NAME),
                         TO_CHAR (NOW (), 'YYYY-MM-DD')
                      )) = 0
       ORDER BY   C.LOCAL_ID_NO)
   LOOP
      UPDATE   PASN.PRSN_PRSNTYPS
         SET   LAST_UPDATE_BY = RUNBY,
               LAST_UPDATE_DATE = TO_CHAR (NOW (), 'YYYY-MM-DD HH24:MI:SS'),
               VALID_END_DATE =
                  TO_CHAR (
                     TO_TIMESTAMP (ROW_DATA.PAY_DATE, 'YYYY-MM-DD')
                     - INTERVAL '1' DAY,
                     'YYYY-MM-DD'
                  )
       WHERE   ( (PERSON_ID = ROW_DATA.PERSON_ID)
                AND (TO_TIMESTAMP (VALID_END_DATE || ' 23:59:59',
                                   'YYYY-MM-DD HH24:MI:SS') >=
                        TO_TIMESTAMP (
                           TO_CHAR (
                              TO_TIMESTAMP (ROW_DATA.PAY_DATE, 'YYYY-MM-DD')
                              - INTERVAL '1' DAY,
                              'YYYY-MM-DD'
                           )
                           || ' 00:00:00',
                           'YYYY-MM-DD HH24:MI:SS'
                        )));

      INSERT INTO PASN.PRSN_PRSNTYPS (PERSON_ID,
                                      PRN_TYP_ASGNMNT_RSN,
                                      VALID_START_DATE,
                                      VALID_END_DATE,
                                      CREATED_BY,
                                      CREATION_DATE,
                                      LAST_UPDATE_BY,
                                      LAST_UPDATE_DATE,
                                      FURTHER_DETAILS,
                                      PRSN_TYPE)
        VALUES   (ROW_DATA.PERSON_ID,
                  NEWPRSNTYPRSN,
                  ROW_DATA.PAY_DATE,
                  '4000-12-31',
                  RUNBY,
                  TO_CHAR (NOW (), 'YYYY-MM-DD HH24:MI:SS'),
                  RUNBY,
                  TO_CHAR (NOW (), 'YYYY-MM-DD HH24:MI:SS'),
                  FTHDETAILS,
                  NEWPRSNTYP);

      MSGS :=
            MSGS
         || CHR (10)
         || ROW_DATA.PERSON_ID
         || '|'
         || ROW_DATA.ID_NO
         || '|'
         || ROW_DATA.FULLNAME
         || '|'
         || ROW_DATA.TOTAL_BALANCE
         || '|'
         || ROW_DATA.PAY_DATE
         || ' - Conversion Successfull';
   END LOOP;

   UPDTMSG :=
      RPT.UPDATERPTLOGMSG (MSGID,
                           MSGS,
                           TO_CHAR (NOW (), 'YYYY-MM-DD HH24:MI:SS'),
                           RUNBY);

   MSGS := RPT.GETLOGMSG (MSGID);
   RETURN MSGS;
EXCEPTION
   WHEN OTHERS
   THEN
      MSGS := MSGS || CHR (10) || '' || SQLSTATE || CHR (10) || SQLERRM;
      UPDTMSG :=
         RPT.UPDATERPTLOGMSG (MSGID,
                              MSGS,
                              TO_CHAR (NOW (), 'YYYY-MM-DD HH24:MI:SS'),
                              RUNBY);
      MSGS := RPT.GETLOGMSG (MSGID);
      RETURN MSGS;
END;