/* Formatted on 10/6/2014 11:39:26 AM (QP5 v5.126.903.23003) */
-- FUNCTION: APLAPPS.RVRS_PSTD_PERIOD_CLOSE(VARCHAR2, NUMBER, VARCHAR2, NUMBER, NUMBER)

-- DROP FUNCTION APLAPPS.RVRS_PSTD_PERIOD_CLOSE(VARCHAR2, NUMBER, VARCHAR2, NUMBER, NUMBER);

CREATE OR REPLACE FUNCTION APLAPPS.RVRS_PSTD_PERIOD_CLOSE (
   DATE_TO_CLOSE    VARCHAR2,
   WHO_RN           NUMBER,
   RUN_DATE         VARCHAR2,
   ORGIDNO          NUMBER,
   MSGID            NUMBER
)
   RETURN VARCHAR2
AS
   LAST_CLOSE_DATE   VARCHAR2 (21);
   CRNT_CLOSE_DATE   VARCHAR2 (21);
   ISDATEALLWD       BOOLEAN;
   --ROW_DATA          RECORD;
   MSGS CLOB
         := CHR (10)
            || 'Reversal of Posted Period Close Process About to Start...';
   GL_BTCHID         NUMBER := -1;
   OLD_GL_BTCHID     NUMBER := -1;
   RETERNACCNTID     NUMBER := -1;

   TTL_DBT           NUMBER := 0;
   TTL_CRDT          NUMBER := 0;
   TTL_NET           NUMBER := 0;

   TMP_DBT           NUMBER := 0;
   TMP_CRDT          NUMBER := 0;
   TMP_NET           NUMBER := 0;
   CUR_ID            NUMBER := -1;
   CNTR              NUMBER := 0;
   TRNSCNT           NUMBER := 0;
   BATCHCNT          NUMBER := 0;
   PCLOSECNT         NUMBER := 0;
   UPDTMSG           NUMBER := 0;
BEGIN
   UPDATE   ACCB.ACCB_RUNNING_PRCSES
      SET   LAST_ACTIVE_TIME = TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
    WHERE   WHICH_PROCESS_IS_RNNG = 6;

   CRNT_CLOSE_DATE := DATE_TO_CLOSE || ' 23:59:59';

   SELECT   TBL1.SELDTE
     INTO   LAST_CLOSE_DATE
     FROM   (  SELECT   TRIM (SUBSTR (PERIOD_CLOSE_DATE, 0, 12)) SELDTE
                 FROM   ACCB.ACCB_PERIOD_CLOSE_DATES
                WHERE   ORG_ID = ORGIDNO
             ORDER BY   PERIOD_CLOSE_ID DESC) TBL1
    WHERE   ROWNUM = 1;

   MSGS := MSGS || CHR (10) || 'Date to Reverse = ' || CRNT_CLOSE_DATE;

   IF LAST_CLOSE_DATE IS NULL
   THEN
      MSGS :=
            MSGS
         || CHR (10)
         || 'There is no Posted Period Close Run Process to Reverse';
      MSGS :=
            MSGS
         || CHR (10)
         || 'Reversal of Posted Period Close Process will now exit....';
      UPDTMSG :=
         APLAPPS.UPDATERPTLOGMSG (MSGID,
                                  MSGS,
                                  RUN_DATE,
                                  WHO_RN);
      RETURN MSGS;
   END IF;

   SELECT   COALESCE (
               APLAPPS.GET_BATCH_ID (
                  'Period Close Process (' || LAST_CLOSE_DATE || ')',
                  ORGIDNO
               ),
               -1
            )
     INTO   OLD_GL_BTCHID
     FROM   DUAL;

   /*SELECT COALESCE(APLAPPS.GET_TODYSBATCH_ID('REVERSAL OF UNPOSTED PERIOD CLOSE PROCESS (' || DATE_TO_CLOSE,ORGIDNO),-1) INTO GL_BTCHID;
   UNPSTDTRNSCNT:=0;
   PRDCLSETRNSCNT:=0;*/

   --GET A NEW BATCH ID (REVERSAL OF POSTED PERIOD CLOSE PROCESS (LAST_CLOSE_DATE))
   --GET TRANSACTIONS IN THE OLD BATCH
   --FOR EACH TRANSACTION INSERT SAME RECORD NEGATING ALL AMOUNTS INVOLVED INTO THE NEW BATCH
   --UPDATE OLD BATCH TO (VOIDED) BOTH NAME AND VALIDTY STATUS
   --DELETE LAST PERIOD CLOSE DATE
   --UPDATE PERIOD STATUS TO OPEN

   ISDATEALLWD :=
      TO_TIMESTAMP (CRNT_CLOSE_DATE, 'YYYY-MM-DD HH24:MI:SS') =
         TO_TIMESTAMP (LAST_CLOSE_DATE || ' 23:59:59',
                       'YYYY-MM-DD HH24:MI:SS');

   MSGS :=
         MSGS
      || CHR (10)
      || 'Last Period Close Date = '
      || LAST_CLOSE_DATE
      || ' 23:59:59';

   IF ISDATEALLWD
   THEN
      MSGS := MSGS;
   ELSE
      MSGS :=
         MSGS || CHR (10)
         || 'Cannot delete a date that is not equal to the last period close date';
      MSGS :=
            MSGS
         || CHR (10)
         || 'Reversal of Posted Period Close Process will now exit....';
      UPDTMSG :=
         APLAPPS.UPDATERPTLOGMSG (MSGID,
                                  MSGS,
                                  RUN_DATE,
                                  WHO_RN);
      MSGS := APLAPPS.GETLOGMSG (MSGID);
      RETURN MSGS;
   END IF;

   --NEW GL BATCH ID
   SELECT   COALESCE (
               APLAPPS.GET_TODYSBATCH_ID (
                  'Reversal of Posted Period Close Process ('
                  || DATE_TO_CLOSE,
                  ORGIDNO
               ),
               -1
            )
     INTO   GL_BTCHID
     FROM   DUAL;

   IF GL_BTCHID <= 0
   THEN
      INSERT INTO ACCB.ACCB_TRNSCTN_BATCHES (
                                                BATCH_NAME,
                                                BATCH_DESCRIPTION,
                                                CREATED_BY,
                                                CREATION_DATE,
                                                ORG_ID,
                                                BATCH_STATUS,
                                                LAST_UPDATE_BY,
                                                LAST_UPDATE_DATE,
                                                BATCH_SOURCE,
                                                BATCH_VLDTY_STATUS,
                                                SRC_BATCH_ID
                 )
        VALUES   (
                        'Reversal of Posted Period Close Process ('
                     || DATE_TO_CLOSE
                     || ')-'
                     || TO_CHAR (SYSDATE, 'YYYYMMDDHH24MISS'),
                        'Reversal of Posted Period Close Process ('
                     || DATE_TO_CLOSE
                     || ')-'
                     || TO_CHAR (SYSDATE, 'YYYYMMDDHH24MISS'),
                     WHO_RN,
                     RUN_DATE,
                     ORGIDNO,
                     '0',
                     WHO_RN,
                     RUN_DATE,
                     'Period Close Process',
                     'VALID',
                     OLD_GL_BTCHID
                 );
   --COMMIT;
   END IF;

   SELECT   COALESCE (
               APLAPPS.GET_TODYSBATCH_ID (
                  'Reversal of Posted Period Close Process ('
                  || DATE_TO_CLOSE,
                  ORGIDNO
               ),
               -1
            )
     INTO   GL_BTCHID
     FROM   DUAL;

   MSGS :=
         MSGS
      || CHR (10)
      || 'Reversal of Posted Period Close Process GL Batch ID= '
      || TRIM (
            TO_CHAR (GL_BTCHID, '999999999999999999999999999999999999999999')
         );
   MSGS :=
      MSGS || CHR (10)
      || 'Reversal of Posted Period Close Process GL Batch Name= ''Reversal of Posted Period Close Process ('
      || DATE_TO_CLOSE
      || ')''';

   SELECT   COUNT (1)
     INTO   PCLOSECNT
     FROM   ACCB.ACCB_PERIOD_CLOSE_DATES B
    WHERE   LOWER (B.PERIOD_CLOSE_DATE) LIKE
               '%' || LOWER (LAST_CLOSE_DATE) || '%'
            AND B.IS_POSTED = '1'
            AND ORG_ID = ORGIDNO;


   SELECT   COALESCE (APLAPPS.GET_ORGFUNC_CRNCY_ID (ORGIDNO), -1)
     INTO   CUR_ID
     FROM   DUAL;

   MSGS := MSGS || CHR (10) || 'About to create Transactions...';

   FOR ROW_DATA
   IN (  SELECT   -1 * A.DBT_AMOUNT DBTS,
                  -1 * A.CRDT_AMOUNT CRDTS,
                  B.ACCNT_ID ACNTID,
                  B.ACCNT_TYPE ACNTTYP,
                  B.ACCNT_TYP_ID,
                  -1 * A.NET_AMOUNT NTMT
           FROM   ACCB.ACCB_TRNSCTN_DETAILS A, ACCB.ACCB_CHART_OF_ACCNTS B
          WHERE   (    (B.ORG_ID = ORGIDNO)
                   AND (A.ACCNT_ID = B.ACCNT_ID)
                   AND (A.BATCH_ID = OLD_GL_BTCHID))
       ORDER BY   B.ACCNT_TYP_ID, B.ACCNT_TYPE, B.ACCNT_ID)
   LOOP
      UPDATE   ACCB.ACCB_RUNNING_PRCSES
         SET   LAST_ACTIVE_TIME = TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
       WHERE   WHICH_PROCESS_IS_RNNG = 6;

      TMP_DBT := ROW_DATA.DBTS;
      TMP_CRDT := ROW_DATA.CRDTS;
      MSGS :=
         MSGS || CHR (10) || 'Transaction Details: '
         || TRIM(TO_CHAR (ROW_DATA.DBTS,
                          '99999999999999999999999999999999999990.00'))
         || '|'
         || TRIM(TO_CHAR (ROW_DATA.CRDTS,
                          '99999999999999999999999999999999999990.00'))
         || '|'
         || ROW_DATA.ACNTTYP
         || '|'
         || TRIM(TO_CHAR (ROW_DATA.ACNTID,
                          '9999999999999999999999999999999999999'))
         || '';

      TMP_NET := ROW_DATA.NTMT;

      TTL_DBT := TTL_DBT + TMP_DBT;
      TTL_CRDT := TTL_CRDT + TMP_CRDT;

      INSERT INTO ACCB.ACCB_TRNSCTN_DETAILS (
                                                ACCNT_ID,
                                                TRANSACTION_DESC,
                                                DBT_AMOUNT,
                                                TRNSCTN_DATE,
                                                FUNC_CUR_ID,
                                                CREATED_BY,
                                                CREATION_DATE,
                                                BATCH_ID,
                                                CRDT_AMOUNT,
                                                LAST_UPDATE_BY,
                                                LAST_UPDATE_DATE,
                                                NET_AMOUNT,
                                                TRNS_STATUS,
                                                SOURCE_TRNS_IDS
                 )
        VALUES   (
                     ROW_DATA.ACNTID,
                     'Reversal of Posted Period Close Process for the Period that Ended on '
                     || CRNT_CLOSE_DATE,
                     TMP_DBT,
                     CRNT_CLOSE_DATE,
                     CUR_ID,
                     WHO_RN,
                     RUN_DATE,
                     GL_BTCHID,
                     TMP_CRDT,
                     WHO_RN,
                     RUN_DATE,
                     TMP_NET,
                     '0',
                     ','
                 );

      CNTR := CNTR + 1;
      --COMMIT;
      MSGS :=
            MSGS
         || CHR (10)
         || 'Successfully Created '
         || TRIM (TO_CHAR (CNTR, '99999999999999999999999999999999999'))
         || ' Transaction(s)!';
   END LOOP;

   CNTR := CNTR + 1;

   IF CNTR > 0
   THEN
      UPDATE   ACCB.ACCB_TRNSCTN_BATCHES
         SET   BATCH_VLDTY_STATUS = 'VOID',
               BATCH_NAME = '(VOIDED) ' || BATCH_NAME,
               BATCH_DESCRIPTION = '(VOIDED) ' || BATCH_DESCRIPTION
       WHERE   BATCH_ID = OLD_GL_BTCHID;

      DELETE FROM   ACCB.ACCB_PERIOD_CLOSE_DATES B
            WHERE   LOWER (B.PERIOD_CLOSE_DATE) LIKE
                       '%' || LOWER (LAST_CLOSE_DATE) || '%'
                    AND B.IS_POSTED = '1'
                    AND ORG_ID = ORGIDNO;

      --AND B.GL_BATCH_ID = OLD_GL_BTCHID;

      UPDATE   ACCB.ACCB_PERIODS_DET
         SET   LAST_UPDATE_BY = WHO_RN,
               LAST_UPDATE_DATE = RUN_DATE,
               PERIOD_STATUS = 'Open'
       WHERE   PERIOD_END_DATE = LAST_CLOSE_DATE || ' 23:59:59';

      MSGS :=
            MSGS
         || CHR (10)
         || 'Successfully Deleted '
         || TRIM (TO_CHAR (PCLOSECNT, '999999999999999'))
         || ' Period Close Date!';
   -- COMMIT;
   END IF;

   UPDTMSG :=
      APLAPPS.UPDATERPTLOGMSG (MSGID,
                               MSGS,
                               RUN_DATE,
                               WHO_RN);
   MSGS := APLAPPS.GETLOGMSG (MSGID);
   RETURN MSGS;
EXCEPTION
   WHEN OTHERS
   THEN
      MSGS := MSGS || CHR (10) || SQLERRM;
      UPDTMSG :=
         APLAPPS.UPDATERPTLOGMSG (MSGID,
                                  MSGS,
                                  RUN_DATE,
                                  WHO_RN);
      MSGS := APLAPPS.GETLOGMSG (MSGID);
      RETURN MSGS;
END;