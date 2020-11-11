/* Formatted on 12-14-2018 7:32:19 PM (QP5 v5.126.903.23003) */
-- Function: gst.updatelogmsg(NUMBER, CLOB, VARCHAR2, VARCHAR2, NUMBER)

-- DROP FUNCTION gst.updatelogmsg(NUMBER, CLOB, VARCHAR2, VARCHAR2, NUMBER);
CREATE OR REPLACE DIRECTORY RHOLOGS AS '/home/apache/adbs/bin/log_files/prcs_logs/';
GRANT READ ON DIRECTORY RHOLOGS TO PUBLIC;

CREATE OR REPLACE FUNCTION gst.updatelogmsg (p_msgid       NUMBER,
                                             p_logmsg      CLOB,
                                             p_logtblnm    VARCHAR2,
                                             p_datestr     VARCHAR2,
                                             p_who_rn      NUMBER)
   RETURN NUMBER
AS
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
   BEGIN
      SELECT   process_typ, process_id
        INTO   v_procstyp, v_procsid
        FROM   rpt.rpt_run_msgs
       WHERE   msg_id = p_msgid;

      /*v_PValID := COALESCE(gst.getEnbldPssblValID('FTP Base DB Folder',
                                                  gst.getenbldlovid('All Other General Setups')), -1);
      v_PVal := COALESCE(gst.get_pssbl_val_desc(v_PValID), '');
      IF (char_length(v_PVal) <= 0 OR v_PValID <= 0)
      THEN
        v_PVal := '/home/apache/adbs';
      END IF;
      v_filenm := v_PVal ||
                  '/bin/log_files/prcs_logs/' || p_msgid || '_' || v_procsid || '_' || REPLACE(v_procstyp, ' ', '-') ||
                  '.rho';*/

      /*EXECUTE format($fmt$
        COPY (select '%s') TO '%s'
        $fmt$, p_logmsg, v_filenm
      );*/

      out_File :=
         UTL_FILE.FOPEN (
            'RHOLOGS',
               v_res
            || '_'
            || v_procsID
            || '_'
            || REPLACE (v_procstyp, ' ', '-')
            || '.rho',
            'A'
         );

      UTL_FILE.PUT_LINE (out_file, p_logmsg);
      UTL_FILE.FCLOSE (out_file);
   /*EXECUTE format($fmt$
   COPY (select '%s') TO PROGRAM '%s'
   $fmt$, p_logmsg, 'cat >>' || v_filenm
   );*/
   EXCEPTION
      WHEN OTHERS
      THEN
         v_dateStr :=
            TO_CHAR (TO_TIMESTAMP (p_dateStr, 'DD-Mon-YYYY HH24:MI:SS'),
                     'YYYY-MM-DD HH24:MI:SS');
         v_sql :=
               'UPDATE '
            || p_logTblNm
            || ' '
            || 'SET log_messages=log_messages || '''
            || p_logmsg
            || ''', last_update_by='
            || p_who_rn
            || ', last_update_date='''
            || p_dateStr
            || ''' WHERE msg_id = '
            || p_msgid;

         EXECUTE IMMEDIATE v_sql;
   END;

   RETURN p_msgid;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE ('ERROR ' || SQLCODE || CHR (10) || SQLERRM);
      raise_application_error (-20000, SQLERRM);
      RETURN -1;
END;