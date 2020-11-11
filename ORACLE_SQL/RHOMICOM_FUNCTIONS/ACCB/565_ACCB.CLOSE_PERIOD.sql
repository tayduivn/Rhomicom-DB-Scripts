/* Formatted on 10/6/2014 2:38:45 AM (QP5 v5.126.903.23003) */
-- FUNCTION: APLAPPS.CLOSE_PERIOD(VARCHAR2, BIGINT, VARCHAR2, NUMBER, BIGINT)

-- DROP FUNCTION APLAPPS.CLOSE_PERIOD(VARCHAR2, BIGINT, VARCHAR2, NUMBER, BIGINT);

CREATE OR REPLACE FUNCTION APLAPPS.CLOSE_PERIOD (P_DATE_TO_CLOSE    VARCHAR2,
                                                 P_WHO_RN           NUMBER,
                                                 P_RUN_DATE         VARCHAR2,
                                                 P_ORGIDNO          NUMBER,
                                                 P_MSGID            NUMBER)
   RETURN VARCHAR2
AS
   CRNT_CLOSE_DATE   VARCHAR2 (21);
   LAST_CLOSE_DATE   VARCHAR2 (21);
   ISDATEALLWD       BOOLEAN;
   --ROW_DATA          RECORD;
   MSGS CLOB
         := CHR (10) || 'Period Close Process About to Start...';
   GL_BTCHID         NUMBER := -1;
   RETERNACCNTID     NUMBER := -1;

   TTL_DBT           NUMBER := 0;
   TTL_CRDT          NUMBER := 0;
   TTL_NET           NUMBER := 0;

   TMP_DBT           NUMBER := 0;
   TMP_CRDT          NUMBER := 0;
   TMP_NET           NUMBER := 0;
   CUR_ID            NUMBER := -1;
   CNTR              NUMBER := 0;
   UNPSTDTRNSCNT     NUMBER := 0;
   PRDCLSETRNSCNT    NUMBER := 0;
   UPDTMSG           NUMBER := 0;
BEGIN
   UPDATE   ACCB.ACCB_RUNNING_PRCSES
      SET   LAST_ACTIVE_TIME = TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
    WHERE   WHICH_PROCESS_IS_RNNG = 6;

   CRNT_CLOSE_DATE := P_DATE_TO_CLOSE || ' 23:59:59';

   MSGS := MSGS || CHR (10) || 'Date to Close = ' || CRNT_CLOSE_DATE;

   SELECT   COALESCE (
               APLAPPS.GET_TODYSBATCH_ID (
                  'Period Close Process (' || P_DATE_TO_CLOSE,
                  P_ORGIDNO
               ),
               -1
            )
     INTO   GL_BTCHID
     FROM   DUAL;

   UNPSTDTRNSCNT := 0;
   PRDCLSETRNSCNT := 0;

   SELECT   COALESCE (
               APLAPPS.GETPRDCLSEUNPSTDTRNSCNT (P_ORGIDNO,
                                                CRNT_CLOSE_DATE,
                                                GL_BTCHID),
               0
            )
     INTO   PRDCLSETRNSCNT
     FROM   DUAL;

   IF PRDCLSETRNSCNT > 0
   THEN
      --MSGS:=APLAPPS.GETLOGMSG(P_MSGID);
      MSGS :=
         MSGS || CHR (10) || 'There are '
         || TRIM (
               TO_CHAR (PRDCLSETRNSCNT, '99999999999999999999999999999999')
            )
         || ' Unposted Period Close Transactions on or Before the Date to be Closed'
         || CHR (10)
         || ' Please post or reverse all such transactions!';
      MSGS := MSGS || CHR (10) || 'Period Close Process will now exit....';
      UPDTMSG :=
         APLAPPS.UPDATERPTLOGMSG (P_MSGID,
                                  MSGS,
                                  P_RUN_DATE,
                                  P_WHO_RN);
      MSGS := APLAPPS.GETLOGMSG (P_MSGID);
      RETURN MSGS;
   END IF;

   SELECT   COALESCE (APLAPPS.GETUNPSTDTRNSCNT (P_ORGIDNO, CRNT_CLOSE_DATE),
                      0)
     INTO   UNPSTDTRNSCNT
     FROM   DUAL;

   IF UNPSTDTRNSCNT > 0
   THEN
      MSGS :=
         MSGS || CHR (10) || 'There are '
         || TRIM (
               TO_CHAR (UNPSTDTRNSCNT, '99999999999999999999999999999999')
            )
         || ' Unposted Transactions on or Before the Date to be Closed'
         || CHR (10)
         || ' Please post or delete all such transactions before closing the period ending on this date'
;
      MSGS := MSGS || CHR (10) || 'Period Close Process will now exit....';
      UPDTMSG :=
         APLAPPS.UPDATERPTLOGMSG (P_MSGID,
                                  MSGS,
                                  P_RUN_DATE,
                                  P_WHO_RN);
      MSGS := APLAPPS.GETLOGMSG (P_MSGID);
      RETURN MSGS;
   END IF;

   SELECT   TBL1.P_CL_DATE
     INTO   LAST_CLOSE_DATE
     FROM   (  SELECT   COALESCE (PERIOD_CLOSE_DATE, '0001-01-01 00:00:00')
                           P_CL_DATE
                 FROM   ACCB.ACCB_PERIOD_CLOSE_DATES
                WHERE   ORG_ID = P_ORGIDNO
             ORDER BY   PERIOD_CLOSE_ID DESC) TBL1
    WHERE   ROWNUM = 1;

   IF LAST_CLOSE_DATE IS NULL
   THEN
      LAST_CLOSE_DATE := '0001-01-01 00:00:00';
   END IF;

   ISDATEALLWD :=
      TO_DATE (CRNT_CLOSE_DATE, 'YYYY-MM-DD HH24:MI:SS') >
         TO_DATE (LAST_CLOSE_DATE, 'YYYY-MM-DD HH24:MI:SS');
   MSGS := MSGS || CHR (10) || 'Last Period Close Date = ' || LAST_CLOSE_DATE;

   --RAISE NOTICE 'QUANTITY 5 HERE IS %', MSGS;
   SELECT   COALESCE (
               APLAPPS.GET_TODYSBATCH_ID (
                  'Period Close Process (' || P_DATE_TO_CLOSE,
                  P_ORGIDNO
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
                                                BATCH_SOURCE
                 )
        VALUES   (
                        'Period Close Process ('
                     || P_DATE_TO_CLOSE
                     || ')-'
                     || TO_CHAR (SYSDATE, 'YYYYMMDDHH24MISS'),
                        'Period Close Process ('
                     || P_DATE_TO_CLOSE
                     || ')-'
                     || TO_CHAR (SYSDATE, 'YYYYMMDDHH24MISS'),
                     P_WHO_RN,
                     P_RUN_DATE,
                     P_ORGIDNO,
                     '0',
                     P_WHO_RN,
                     P_RUN_DATE,
                     'Period Close Process'
                 );
   --COMMIT;
   END IF;

   SELECT   COALESCE (
               APLAPPS.GET_TODYSBATCH_ID (
                  'Period Close Process (' || P_DATE_TO_CLOSE,
                  P_ORGIDNO
               ),
               -1
            )
     INTO   GL_BTCHID
     FROM   DUAL;

   MSGS :=
      MSGS || CHR (10) || 'Period Close Process GL Batch ID= '
      || TRIM (
            TO_CHAR (GL_BTCHID, '999999999999999999999999999999999999999999')
         );
   MSGS :=
         MSGS
      || CHR (10)
      || 'Period Close Process GL Batch Name= ''Period Close Process ('
      || P_DATE_TO_CLOSE
      || ')''';

   IF ISDATEALLWD
   THEN
      INSERT INTO ACCB.ACCB_PERIOD_CLOSE_DATES (
                                                   PERIOD_CLOSE_DATE,
                                                   RUN_BY,
                                                   RUN_DATE,
                                                   PERIOD_CLOSE_DESCRIPTION,
                                                   ORG_ID,
                                                   IS_POSTED,
                                                   GL_BATCH_ID
                 )
        VALUES   (
                     CRNT_CLOSE_DATE,
                     P_WHO_RN,
                     P_RUN_DATE,
                     'Running Period Close Process for the Period that Ended on '
                     || CRNT_CLOSE_DATE,
                     P_ORGIDNO,
                     '0',
                     GL_BTCHID
                 );

      MSGS :=
            MSGS
         || CHR (10)
         || 'Created Period Close Process line in Database....';
   ELSE
      MSGS :=
         MSGS || CHR (10)
         || 'Cannot close a date that comes before or is equal to the last period close date'
;
      MSGS := MSGS || CHR (10) || 'Period Close Process will now exit....';
      UPDTMSG :=
         APLAPPS.UPDATERPTLOGMSG (P_MSGID,
                                  MSGS,
                                  P_RUN_DATE,
                                  P_WHO_RN);
      MSGS := APLAPPS.GETLOGMSG (P_MSGID);
      RETURN MSGS;
   END IF;


   SELECT   COALESCE (APLAPPS.GET_ORGFUNC_CRNCY_ID (P_ORGIDNO), -1)
     INTO   CUR_ID
     FROM   DUAL;

   MSGS := MSGS || CHR (10) || 'About to create Transactions...';

   FOR ROW_DATA IN (  SELECT   SUM (A.DBT_AMOUNT) DBTS,
                               SUM (A.CRDT_AMOUNT) CRDTS,
                               B.ACCNT_ID ACNTID,
                               B.ACCNT_TYPE ACNTTYP,
                               B.ACCNT_TYP_ID
                        FROM   ACCB.ACCB_TRNSCTN_DETAILS A,
                               ACCB.ACCB_CHART_OF_ACCNTS B,
                               ACCB.ACCB_TRNSCTN_BATCHES C
                       WHERE   (    (B.ORG_ID = P_ORGIDNO)
                                AND (A.BATCH_ID = C.BATCH_ID AND A.ACCNT_ID = B.ACCNT_ID)
                                AND (A.TRNS_STATUS = '1')
                                AND (TO_TIMESTAMP (A.TRNSCTN_DATE, 'YYYY-MM-DD HH24:MI:SS') >
                                        TO_TIMESTAMP (LAST_CLOSE_DATE,
                                                      'YYYY-MM-DD HH24:MI:SS')
                                     AND TO_TIMESTAMP (A.TRNSCTN_DATE,
                                                       'YYYY-MM-DD HH24:MI:SS') <=
                                           TO_TIMESTAMP (CRNT_CLOSE_DATE,
                                                         'YYYY-MM-DD HH24:MI:SS'))
                                AND (B.ACCNT_TYPE = 'R' OR B.ACCNT_TYPE = 'EX')
                                AND (B.HAS_SUB_LEDGERS = '0')
                                AND (C.BATCH_SOURCE != 'Period Close Process'))
                    GROUP BY   B.ACCNT_TYP_ID, B.ACCNT_TYPE, B.ACCNT_ID
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

      IF ROW_DATA.ACNTTYP = 'R'
      THEN
         TMP_NET := ROW_DATA.DBTS - ROW_DATA.CRDTS;
      ELSE
         TMP_NET := ROW_DATA.CRDTS - ROW_DATA.DBTS;
      END IF;

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
                     'Period Close Process for the Period that Ended on '
                     || CRNT_CLOSE_DATE,
                     TMP_CRDT,
                     CRNT_CLOSE_DATE,
                     CUR_ID,
                     P_WHO_RN,
                     P_RUN_DATE,
                     GL_BTCHID,
                     TMP_DBT,
                     P_WHO_RN,
                     P_RUN_DATE,
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

   TTL_NET := ABS (TTL_DBT - TTL_CRDT);
   RETERNACCNTID := APLAPPS.GET_ORGRETERNACCNTID (P_ORGIDNO);

   UPDATE   ACCB.ACCB_RUNNING_PRCSES
      SET   LAST_ACTIVE_TIME = TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
    WHERE   WHICH_PROCESS_IS_RNNG = 6;

   IF TTL_DBT > TTL_CRDT
   THEN
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
                     RETERNACCNTID,
                     'Period Close Process for the Period that Ended on '
                     || CRNT_CLOSE_DATE,
                     TTL_NET,
                     CRNT_CLOSE_DATE,
                     CUR_ID,
                     P_WHO_RN,
                     P_RUN_DATE,
                     GL_BTCHID,
                     0,
                     P_WHO_RN,
                     P_RUN_DATE,
                     -1 * TTL_NET,
                     '0',
                     ','
                 );

      --COMMIT;
      CNTR := CNTR + 1;
   ELSIF TTL_DBT < TTL_CRDT
   THEN
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
                     RETERNACCNTID,
                     'Period Close Process for the Period that Ended on '
                     || CRNT_CLOSE_DATE,
                     0,
                     CRNT_CLOSE_DATE,
                     CUR_ID,
                     P_WHO_RN,
                     P_RUN_DATE,
                     GL_BTCHID,
                     TTL_NET,
                     P_WHO_RN,
                     P_RUN_DATE,
                     TTL_NET,
                     '0',
                     ','
                 );

      --COMMIT;
      CNTR := CNTR + 1;
   END IF;

   UPDATE   ACCB.ACCB_RUNNING_PRCSES
      SET   LAST_ACTIVE_TIME = TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
    WHERE   WHICH_PROCESS_IS_RNNG = 6;

   UPDATE   ACCB.ACCB_PERIODS_DET
      SET   LAST_UPDATE_BY = P_WHO_RN,
            LAST_UPDATE_DATE = P_RUN_DATE,
            PERIOD_STATUS = 'Closed'
    WHERE   PERIOD_END_DATE = CRNT_CLOSE_DATE;

   MSGS :=
         MSGS
      || CHR (10)
      || 'Successfully Created a Total of '
      || TRIM (TO_CHAR (CNTR, '99999999999999999999999999999999999'))
      || ' Transaction(s) In the Period Close Transactions Batch waiting to be Posted!'
;
   -- COMMIT;
   UPDTMSG :=
      APLAPPS.UPDATERPTLOGMSG (P_MSGID,
                               MSGS,
                               P_RUN_DATE,
                               P_WHO_RN);

   MSGS := APLAPPS.GETLOGMSG (P_MSGID);
   RETURN MSGS;
EXCEPTION
   WHEN OTHERS
   THEN
      MSGS := MSGS || CHR (10) || SQLERRM;
      UPDTMSG :=
         APLAPPS.UPDATERPTLOGMSG (P_MSGID,
                                  MSGS,
                                  P_RUN_DATE,
                                  P_WHO_RN);
      MSGS := APLAPPS.GETLOGMSG (P_MSGID);
      RETURN MSGS;
END;