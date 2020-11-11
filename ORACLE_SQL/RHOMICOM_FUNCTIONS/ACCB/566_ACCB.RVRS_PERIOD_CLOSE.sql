/* Formatted on 10/6/2014 11:42:50 AM (QP5 v5.126.903.23003) */
-- FUNCTION: APLAPPS.RVRS_PERIOD_CLOSE(VARCHAR2, NUMBER, VARCHAR2, NUMBER, NUMBER)

-- DROP FUNCTION APLAPPS.RVRS_PERIOD_CLOSE(VARCHAR2, NUMBER, VARCHAR2, NUMBER, NUMBER);

CREATE OR REPLACE FUNCTION APLAPPS.RVRS_PERIOD_CLOSE (
   DATE_TO_CLOSE    VARCHAR2,
   WHO_RN           NUMBER,
   RUN_DATE         VARCHAR2,
   ORGIDNO          NUMBER,
   MSGID            NUMBER
)
   RETURN VARCHAR2
AS
   LAST_CLOSE_DATE   VARCHAR2 (21);
   ISDATEALLWD       BOOLEAN;
   --ROW_DATA          RECORD;
   MSGS CLOB
         := CHR (10)
            || 'Reversal of Unposted Period Close Process About to Start...';
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

   --CRNT_CLOSE_DATE :=DATE_TO_CLOSE || ' 23:59:59';
   SELECT   TBL1.SELDTE
     INTO   LAST_CLOSE_DATE
     FROM   (  SELECT   TRIM (SUBSTR (PERIOD_CLOSE_DATE, 0, 12)) SELDTE
                 FROM   ACCB.ACCB_PERIOD_CLOSE_DATES
                WHERE   ORG_ID = ORGIDNO
             ORDER BY   PERIOD_CLOSE_ID DESC) TBL1
    WHERE   ROWNUM = 1;

   MSGS := MSGS || CHR (10) || 'Date to Reverse = ' || LAST_CLOSE_DATE;

   IF LAST_CLOSE_DATE IS NULL
   THEN
      MSGS :=
            MSGS
         || CHR (10)
         || 'There is no Unposted Period Close Run Process to Reverse';
      MSGS :=
            MSGS
         || CHR (10)
         || 'Reversal of Unposted Period Close Process will now exit....';
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

   SELECT   COUNT (1)
     INTO   TRNSCNT
     FROM   ACCB.ACCB_TRNSCTN_DETAILS A
    WHERE   A.TRNS_STATUS = '0' AND A.BATCH_ID = OLD_GL_BTCHID;

   SELECT   COUNT (1)
     INTO   BATCHCNT
     FROM   ACCB.ACCB_TRNSCTN_BATCHES B
    WHERE   B.BATCH_ID = OLD_GL_BTCHID AND B.BATCH_STATUS = '0';

   SELECT   COUNT (1)
     INTO   PCLOSECNT
     FROM   ACCB.ACCB_PERIOD_CLOSE_DATES B
    WHERE   LOWER (B.PERIOD_CLOSE_DATE) LIKE
               '%' || LOWER (LAST_CLOSE_DATE) || '%'
            AND B.IS_POSTED = '0'
            AND ORG_ID = ORGIDNO;

   UPDATE   ACCB.ACCB_RUNNING_PRCSES
      SET   LAST_ACTIVE_TIME = TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
    WHERE   WHICH_PROCESS_IS_RNNG = 6;

   DELETE FROM   ACCB.ACCB_TRNSCTN_DETAILS A
         WHERE   A.TRNS_STATUS = '0' AND A.BATCH_ID = OLD_GL_BTCHID;

   DELETE FROM   ACCB.ACCB_TRNSCTN_BATCHES B
         WHERE   B.BATCH_ID = OLD_GL_BTCHID AND B.BATCH_STATUS = '0';

   DELETE FROM   ACCB.ACCB_PERIOD_CLOSE_DATES B
         WHERE   LOWER (B.PERIOD_CLOSE_DATE) LIKE
                    '%' || LOWER (LAST_CLOSE_DATE) || '%'
                 AND B.IS_POSTED = '0'
                 AND ORG_ID = ORGIDNO;

   --AND B.GL_BATCH_ID = OLD_GL_BTCHID;

   UPDATE   ACCB.ACCB_PERIODS_DET
      SET   LAST_UPDATE_BY = WHO_RN,
            LAST_UPDATE_DATE = RUN_DATE,
            PERIOD_STATUS = 'Open'
    WHERE   PERIOD_END_DATE = LAST_CLOSE_DATE || ' 23:59:59';

   UPDATE   ACCB.ACCB_RUNNING_PRCSES
      SET   LAST_ACTIVE_TIME = TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
    WHERE   WHICH_PROCESS_IS_RNNG = 6;

   MSGS :=
         MSGS
      || CHR (10)
      || 'Successfully Deleted '
      || TRIM (TO_CHAR (TRNSCNT, '999999999999999'))
      || ' Transactions, '
      || TRIM (TO_CHAR (BATCHCNT, '999999999999999'))
      || ' Period Close Batch, '
      || TRIM (TO_CHAR (PCLOSECNT, '999999999999999'))
      || ' Period Close Date!';
   -- COMMIT;
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