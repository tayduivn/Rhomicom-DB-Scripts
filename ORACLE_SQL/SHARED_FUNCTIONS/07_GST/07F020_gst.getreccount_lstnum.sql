/* Formatted on 12-14-2018 7:09:18 PM (QP5 v5.126.903.23003) */
-- Function: gst.getreccount_lstnum(VARCHAR2, VARCHAR2, VARCHAR2, VARCHAR2)

-- DROP FUNCTION gst.getreccount_lstnum(VARCHAR2, VARCHAR2, VARCHAR2, VARCHAR2);
GRANT ALL ON publc.chartoint TO GST;

CREATE OR REPLACE FUNCTION gst.getreccount_lstnum (tblnm       VARCHAR2,
                                                   srchcol     VARCHAR2,
                                                   coltocnt    VARCHAR2,
                                                   srchwrds    VARCHAR2)
   RETURN NUMBER
AS
   v_res   NUMBER := 0;
   v_sql   CLOB := '';
BEGIN
   v_sql :=
      'SELECT tbl1.nwNum FROM (SELECT publc.chartoint(regexp_substr((CASE WHEN publc.chartoint(regexp_substr('
      || srchcol
      || ',''[^-]+$'')) = 0
                 THEN (CASE WHEN publc.chartoint(regexp_substr('
      || srchcol
      || ',''(?:.[^-]+){4}.([^-]+)'')) = 0
                                 THEN regexp_substr('
      || srchcol
      || ',''(?:.[^-]+){3}.([^-]+)'')
                            ELSE regexp_substr('
      || srchcol
      || ',''(?:.[^-]+){4}.([^-]+)'') END)
            ELSE regexp_substr('
      || srchcol
      || ',''[^-]+$'') END), ''[0-9]+'')) nwNum from '
      || tblNm
      || ' where lower('
      || srchcol
      || ') like  lower('''
      || srchWrds
      || ''') ORDER BY '
      || colToCnt
      || ' DESC) tbl1 WHERE ROWNUM=1';

   EXECUTE IMMEDIATE v_sql INTO   v_res;

   RETURN COALESCE (v_res, 0);
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN COALESCE (v_res, 0);
      raise_application_error (-20000, SQLERRM || ' ' || v_sql);
END;


SELECT   gst.getreccount_lstnum ('accb.accb_pybls_invc_hdr',
                                 'pybls_invc_number',
                                 'pybls_invc_hdr_id',
                                 'SSP-00-181214-%')
            NUM
  FROM   DUAL;

SELECT   tbl1.nwNum
  FROM   (  SELECT   publc.chartoint(REGEXP_SUBSTR (
                                        (CASE
                                            WHEN publc.chartoint(REGEXP_SUBSTR (
                                                                    pybls_invc_number,
                                                                    '[^-]+$'
                                                                 )) = 0
                                            THEN
                                               (CASE
                                                   WHEN publc.chartoint(REGEXP_SUBSTR (
                                                                           pybls_invc_number,
                                                                           '(?:.[^-]+){4}.([^-]+)'
                                                                        )) = 0
                                                   THEN
                                                      REGEXP_SUBSTR (
                                                         pybls_invc_number,
                                                         '(?:.[^-]+){3}.([^-]+)'
                                                      )
                                                   ELSE
                                                      REGEXP_SUBSTR (
                                                         pybls_invc_number,
                                                         '(?:.[^-]+){4}.([^-]+)'
                                                      )
                                                END)
                                            ELSE
                                               REGEXP_SUBSTR (
                                                  pybls_invc_number,
                                                  '[^-]+$'
                                               )
                                         END),
                                        '[0-9]+'
                                     ))
                        nwNum
              FROM   accb.accb_pybls_invc_hdr
             WHERE   LOWER (pybls_invc_number) LIKE LOWER ('SSP-00-181214-%')
          ORDER BY   pybls_invc_hdr_id DESC) tbl1
 WHERE   ROWNUM = 1;