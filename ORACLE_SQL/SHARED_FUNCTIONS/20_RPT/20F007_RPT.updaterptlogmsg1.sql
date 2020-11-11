/* Formatted on 12-19-2018 4:48:04 PM (QP5 v5.126.903.23003) */
-- FUNCTION: GST.UPDATELOGMSG(NUMBER, CLOB, VARCHAR2, VARCHAR2, NUMBER)

-- DROP FUNCTION GST.UPDATELOGMSG(NUMBER, CLOB, VARCHAR2, VARCHAR2, NUMBER);
CREATE OR REPLACE DIRECTORY RHOLOGS AS '/home/apache/adbs/bin/log_files/prcs_logs/';
GRANT READ ON DIRECTORY RHOLOGS TO PUBLIC;

CREATE OR REPLACE FUNCTION RPT.UPDATERPTLOGMSG1 (P_MSGID      NUMBER,
                                                 P_LOGMSG     CLOB,
                                                 P_DATESTR    VARCHAR2,
                                                 P_WHO_RN     NUMBER)
   RETURN NUMBER
AS
   V_RES        NUMBER := -1;
   V_DATESTR    VARCHAR2 (21) := '';
   V_SQL        CLOB := '';
   V_FILENM     VARCHAR2 (200) := '';
   V_PROCSTYP   VARCHAR2 (100) := '';
   V_PROCSID    NUMBER := -1;
   V_PVALID     INTEGER := -1;
   V_PVAL       VARCHAR2 (300) := '';
   OUT_FILE     UTL_FILE.FILE_TYPE;
BEGIN
   BEGIN
      SELECT   PROCESS_TYP, PROCESS_ID
        INTO   V_PROCSTYP, V_PROCSID
        FROM   RPT.RPT_RUN_MSGS
       WHERE   MSG_ID = P_MSGID;

      OUT_FILE :=
         UTL_FILE.FOPEN (
            'RHOLOGS',
               V_RES
            || '_'
            || V_PROCSID
            || '_'
            || REPLACE (V_PROCSTYP, ' ', '-')
            || '.rho',
            'W'
         );

      UTL_FILE.PUT_LINE (OUT_FILE, P_LOGMSG);
      UTL_FILE.FCLOSE (OUT_FILE);
   EXCEPTION
      WHEN OTHERS
      THEN
         V_DATESTR :=
            TO_CHAR (TO_TIMESTAMP (P_DATESTR, 'DD-Mon-YYYY HH24:MI:SS'),
                     'YYYY-MM-DD HH24:MI:SS');

         UPDATE   RPT.RPT_RUN_MSGS
            SET   LOG_MESSAGES = P_LOGMSG,
                  LAST_UPDATE_BY = P_WHO_RN,
                  LAST_UPDATE_DATE = P_DATESTR
          WHERE   MSG_ID = P_MSGID;
   END;

   RETURN P_MSGID;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE ('ERROR ' || SQLCODE || CHR (10) || SQLERRM);
      RAISE_APPLICATION_ERROR (-20000, SQLERRM);
      RETURN -1;
END;