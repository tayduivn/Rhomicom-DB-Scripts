/* Formatted on 12-19-2018 11:09:01 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION WKF.ACTION_SQL_FOR_LOGIN (ROUTNGID     NUMBER,
                                                     USRID        NUMBER,
                                                     ACTTOPRFM    VARCHAR2)
   RETURN VARCHAR2
AS
   RESULT         VARCHAR2 (200 BYTE) := '|ERROR|-Action Failed';
   --MSGS VARCHAR2         := '';
   MSGID          NUMBER := 0;
   APPID          NUMBER := 0;
   APPNM          VARCHAR2 (200 BYTE) := '';
   SRC_MODULE     VARCHAR2 (200 BYTE) := '';
   MSGTYP         VARCHAR2 (200 BYTE) := '';
   DATESNT        VARCHAR2 (200 BYTE) := '';
   TODDATE        VARCHAR2 (200 BYTE) := '';
   FROMPRNID      NUMBER := -1;
   TOPRNID        NUMBER := -1;
   USRPRSNID      NUMBER := -1;
   CURMSGSTATUS   VARCHAR2 (200 BYTE) := '';
   ORGACTTOPRFM   VARCHAR2 (200 BYTE) := '';
   ISACTDONE      VARCHAR (200 BYTE) := '';
   ISACTALLWD     VARCHAR2 (200 BYTE) := '0';
BEGIN
   /*
   1. VERIFY ROUTING ID INFORMATION
   2. UPDATE ROUTING ID ACTED ON STATUS AND MSG_STATUS AND ACTION TO PERFORM
   */
   USRPRSNID := SEC.GET_USR_PRSN_ID (USRID);
   TODDATE := SEC.GETDB_DATE_TIME ();


   SELECT   TBL1.MSG_ID,
            TBL1.APP_NAME,
            TBL1.SOURCE_MODULE,
            TBL1.MSG_TYP,
            TBL1.APP_ID,
            TBL1.FROM_PRSN_ID,
            TBL1.TO_PRSN_ID,
            TBL1.DATE_SENT,
            TBL1.MSG_STATUS,
            TBL1.ACTION_TO_PERFORM,
            TBL1.IS_ACTION_DONE
     INTO   MSGID,
            APPNM,
            SRC_MODULE,
            MSGTYP,
            APPID,
            FROMPRNID,
            TOPRNID,
            DATESNT,
            CURMSGSTATUS,
            ORGACTTOPRFM,
            ISACTDONE
     FROM   (  SELECT   A.MSG_ID,
                        C.APP_NAME,
                        C.SOURCE_MODULE,
                        B.MSG_TYP,
                        B.APP_ID,
                        A.FROM_PRSN_ID,
                        A.TO_PRSN_ID,
                        A.DATE_SENT,
                        A.MSG_STATUS,
                        A.ACTION_TO_PERFORM,
                        A.IS_ACTION_DONE
                 FROM   WKF.WKF_ACTUAL_MSGS_ROUTNG A,
                        WKF.WKF_ACTUAL_MSGS_HDR B,
                        WKF.WKF_APPS C
                WHERE   (    (C.APP_ID = B.APP_ID)
                         AND (A.MSG_ID = B.MSG_ID)
                         AND (A.TO_PRSN_ID = USRPRSNID)
                         AND (A.ROUTING_ID = ROUTNGID)
                         AND (A.ACTION_TO_PERFORM LIKE '%' || ACTTOPRFM || '%'))
             ORDER BY   A.DATE_SENT DESC) TBL1
    WHERE   ROWNUM <= 1;


   --RESULT :=RESULT || ACTTOPRFM || ISACTDONE||'<BR/>'||$1 ||'-' ||$2||'-'||USRPRSNID||'-'||TODDATE;
   IF     APPNM = 'Login'
      AND SRC_MODULE = 'System Administration'
      AND ISACTDONE = '0'
      AND ACTTOPRFM = 'Acknowledge'
      AND USRPRSNID = TOPRNID
   THEN
      UPDATE   WKF.WKF_ACTUAL_MSGS_ROUTNG
         SET   IS_ACTION_DONE = '1',
               WHO_PRFMD_ACTION = USRPRSNID,
               DATE_ACTION_WS_PRFMD = TODDATE,
               STATUS_AFTR_ACTION = 'Acknowledged',
               NXT_ACTION_TO_PRFM = 'None',
               LAST_UPDATE_BY = USRID,
               LAST_UPDATE_DATE = TODDATE
       WHERE   ROUTING_ID = ROUTNGID;

      RESULT := '|SUCCESS|-Action Successfully Executed!';
   ELSE
      RESULT :=
         '|ERROR|-This message has been acted on already! or Your action is disallowed because it is suspicious'
;
   END IF;

   RETURN RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      --RESULT := RESULT || '|ERROR|-ACTION FAILED';
      RESULT := RESULT || '<br/>' || SQLERRM;
      --UPDTMSG := APLAPPS.UPDATERPTLOGMSG(MSGID, MSGS, ACTTOPRFM, USRID);
      --MSGS:=APLAPPS.GETLOGMSG($5);
      RETURN RESULT;
END;
/