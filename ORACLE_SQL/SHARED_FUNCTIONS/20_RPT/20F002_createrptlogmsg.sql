/* Formatted on 12-19-2018 2:41:26 PM (QP5 v5.126.903.23003) */
-- FUNCTION: GST.CREATERPTLOGMSG(CLOB, VARCHAR2, VARCHAR2, NUMBER, VARCHAR2, NUMBER)

-- DROP FUNCTION GST.CREATERPTLOGMSG(CLOB, VARCHAR2, VARCHAR2, NUMBER, VARCHAR2, NUMBER);
CREATE OR REPLACE DIRECTORY RHOLOGS AS '/home/apache/adbs/bin/log_files/prcs_logs/';
GRANT READ ON DIRECTORY RHOLOGS TO PUBLIC;

CREATE OR REPLACE FUNCTION RPT.CREATERPTLOGMSG (P_LOGMSG      CLOB,
                                                P_PROCSTYP    VARCHAR2,
                                                P_PROCSID     NUMBER,
                                                P_DATESTR     VARCHAR2,
                                                P_WHO_RN      NUMBER)
   RETURN NUMBER
AS
   PRAGMA AUTONOMOUS_TRANSACTION;
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
   V_DATESTR :=
      TO_CHAR (TO_TIMESTAMP (P_DATESTR, 'DD-Mon-YYYY HH24:MI:SS'),
               'YYYY-MM-DD HH24:MI:SS');

   INSERT INTO RPT.RPT_RUN_MSGS (LOG_MESSAGES,
                                 PROCESS_TYP,
                                 PROCESS_ID,
                                 CREATED_BY,
                                 CREATION_DATE,
                                 LAST_UPDATE_BY,
                                 LAST_UPDATE_DATE)
     VALUES   (P_LOGMSG,
               P_PROCSTYP,
               P_PROCSID,
               P_WHO_RN,
               P_DATESTR,
               P_WHO_RN,
               P_DATESTR);

   V_RES := RPT.GETRPTLOGMSGID (P_PROCSID, P_PROCSTYP);

   OUT_FILE :=
      UTL_FILE.FOPEN (
         'RHOLOGS',
            V_RES
         || '_'
         || P_PROCSID
         || '_'
         || REPLACE (P_PROCSTYP, ' ', '-')
         || '.rho',
         'A'
      );

   UTL_FILE.PUT_LINE (OUT_FILE, P_LOGMSG);
   UTL_FILE.FCLOSE (OUT_FILE);
   COMMIT;
   RETURN V_RES;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE ('ERROR ' || SQLCODE || CHR (10) || SQLERRM);
      RAISE_APPLICATION_ERROR (-20000, SQLERRM);
      RETURN -1;
END;