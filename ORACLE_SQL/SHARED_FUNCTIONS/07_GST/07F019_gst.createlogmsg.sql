/* Formatted on 12-13-2018 12:41:04 PM (QP5 v5.126.903.23003) */
-- Function: gst.createlogmsg(CLOB, VARCHAR2, VARCHAR2, NUMBER, VARCHAR2, NUMBER)

-- DROP FUNCTION gst.createlogmsg(CLOB, VARCHAR2, VARCHAR2, NUMBER, VARCHAR2, NUMBER);
CREATE OR REPLACE DIRECTORY RHOLOGS AS '/home/apache/adbs/bin/log_files/prcs_logs/';
GRANT READ ON DIRECTORY RHOLOGS TO PUBLIC;

CREATE OR REPLACE FUNCTION gst.createlogmsg (p_logmsg      CLOB,
                                             p_logtblnm    VARCHAR2,
                                             p_procstyp    VARCHAR2,
                                             p_procsid     NUMBER,
                                             p_datestr     VARCHAR2,
                                             p_who_rn      NUMBER)
   RETURN NUMBER
AS
   PRAGMA AUTONOMOUS_TRANSACTION;
   v_res        NUMBER := -1;
   v_dateStr    VARCHAR2 (21) := '';
   v_sql        CLOB := '';
   v_filenm     VARCHAR2 (200) := '';
   v_procstyp   VARCHAR2 (100) := '';
   v_procsid    NUMBER := -1;
   v_PValID     INTEGER := -1;
   v_PVal       VARCHAR2 (300) := '';
   out_File     UTL_FILE.FILE_TYPE;
BEGIN
   v_dateStr :=
      TO_CHAR (TO_TIMESTAMP (p_dateStr, 'DD-Mon-YYYY HH24:MI:SS'),
               'YYYY-MM-DD HH24:MI:SS');
   v_sql :=
         'INSERT INTO '
      || p_logTblNm
      || ' ('
      || 'log_messages, process_typ, process_id, created_by, creation_date, '
      || 'last_update_by, last_update_date) '
      || 'VALUES ('''
      || p_logmsg
      || ''','''
      || p_procstyp
      || ''','
      || p_procsID
      || ', '
      || p_who_rn
      || ', '''
      || v_dateStr
      || ''', '
      || p_who_rn
      || ', '''
      || v_dateStr
      || ''')';

   EXECUTE IMMEDIATE v_sql;

   v_res := gst.getlogmsgid (p_logTblNm, p_procstyp, p_procsID);
   /*v_PValID := COALESCE(gst.getEnbldPssblValID('FTP Base DB Folder',
                                               gst.getenbldlovid(
       'All Other General Setups')), -1);
   v_PVal := COALESCE(gst.get_pssbl_val_desc(v_PValID), '');
   IF (char_length(v_PVal) <= 0 OR v_PValID <= 0)
   THEN
     v_PVal := '/home/apache/adbs';
   END IF;
   v_filenm := v_PVal ||
               '/bin/log_files/prcs_logs/' || v_res || '_' || p_procsID || '_'
       || REPLACE(p_procstyp, ' ', '-') ||
               '.rho';*/

   out_File :=
      UTL_FILE.FOPEN (
         'RHOLOGS',
            v_res
         || '_'
         || p_procsID
         || '_'
         || REPLACE (p_procstyp, ' ', '-')
         || '.rho',
         'A'
      );

   UTL_FILE.PUT_LINE (out_file, p_logmsg);
   UTL_FILE.FCLOSE (out_file);
   /*EXECUTE format($fmt$
     COPY (select '%s') TO '%s'
     $fmt$, p_logmsg, v_filenm
   );*/
   COMMIT;
   RETURN v_res;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE ('ERROR ' || SQLCODE || CHR (10) || SQLERRM);
      raise_application_error (-20000, SQLERRM);
      RETURN -1;
END;