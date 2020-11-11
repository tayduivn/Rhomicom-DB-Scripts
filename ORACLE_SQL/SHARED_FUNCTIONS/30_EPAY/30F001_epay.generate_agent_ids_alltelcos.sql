/* Formatted on 12-19-2018 10:54:11 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION EPAY.GENERATE_AGENT_IDS_ALLTELCOS (
   P_LISTLIMIT    VARCHAR2,
   P_TELCO        VARCHAR2
)
   RETURN NUMBER
AS
   V_TELCO             VARCHAR (200) := P_TELCO;
   V_REGN_CODE         VARCHAR (200) := '';
   V_CITY_CODE         VARCHAR (200) := '';
   V_OUTLET_CODE       VARCHAR (200) := '';
   V_AGENT_SERIAL_NO   VARCHAR (200) := '';
   V_AGENT_CODE        VARCHAR (200) := '';
   V_AGENT_FIN_CODE    VARCHAR (200) := '';
   V_SERIAL_NO         NUMBER := -1;
   V_LIMIT             NUMBER := P_LISTLIMIT;
   CNTA                INTEGER := 0;
BEGIN
   --SELECT AGENT RECORDS
   FOR AGENT_LIST IN (SELECT   TBL1.*
                        FROM   (  SELECT   AGENT_NAME,
                                           REGION,
                                           CITY,
                                           TELCO,
                                           MSISDN,
                                           AGENT_NO,
                                           ROW_ID,
                                           ID_TYPE,
                                           ID_NUMBER
                                    FROM   EPAY.EPAY_AGENT_IDS
                                   WHERE   1 = 1 AND LENGTH (AGENT_NO) = 0
                                ORDER BY   REGION, AGENT_NAME) TBL1
                       WHERE   ROWNUM <= V_LIMIT)
   LOOP
      --GET REGION AND ASSIGN CODE
      CASE AGENT_LIST.REGION
         WHEN 'NOTHERN REGION'
         THEN
            V_REGN_CODE := 'NR';
         WHEN 'WESTERN REGION'
         THEN
            V_REGN_CODE := 'WR';
         WHEN 'ASHANTI REGION'
         THEN
            V_REGN_CODE := 'AR';
         WHEN 'UPPER EAST REGION'
         THEN
            V_REGN_CODE := 'UE';
         WHEN 'EASTERN REGION'
         THEN
            V_REGN_CODE := 'ER';
         WHEN 'GREATER ACCRA REGION'
         THEN
            V_REGN_CODE := 'AC';
         WHEN 'UPPER WEST REGION'
         THEN
            V_REGN_CODE := 'UW';
         WHEN 'CENTRAL REGION'
         THEN
            V_REGN_CODE := 'CR';
         WHEN 'VOLTA REGION'
         THEN
            V_REGN_CODE := 'VR';
         ELSE                                      --'BRONG-AHAFO REGION' THEN
            V_REGN_CODE := 'BR';
      END CASE;

      IF LENGTH (AGENT_LIST.ID_TYPE) > 0
         AND LENGTH (AGENT_LIST.ID_NUMBER) > 0
      THEN
         SELECT   DISTINCT AGENT_NO, SERIAL_NO
           INTO   V_AGENT_CODE, V_SERIAL_NO
           FROM   EPAY.EPAY_AGENT_IDS
          WHERE       ID_TYPE = AGENT_LIST.ID_TYPE
                  AND ID_NUMBER = AGENT_LIST.ID_NUMBER
                  AND REGION = AGENT_LIST.REGION;
      ELSE
         --GET AGENT NO
         SELECT   DISTINCT AGENT_NO, SERIAL_NO
           INTO   V_AGENT_CODE, V_SERIAL_NO
           FROM   EPAY.EPAY_AGENT_IDS
          WHERE   AGENT_NAME = AGENT_LIST.AGENT_NAME
                  AND REGION = AGENT_LIST.REGION;
      -- AND AGENT_NO IS NOT NULL AND ROW_ID != AGENT_LIST.ROW_ID;

      END IF;

      IF LENGTH (V_AGENT_CODE) = 0
      THEN
         SELECT   COALESCE (MAX (SERIAL_NO), 0)
           INTO   V_SERIAL_NO
           FROM   EPAY.EPAY_AGENT_IDS
          WHERE   REGION = AGENT_LIST.REGION;

         V_AGENT_CODE := LPAD (TRIM ( (V_SERIAL_NO + 1) || ''), 6, '0');

         V_AGENT_FIN_CODE := V_REGN_CODE || V_AGENT_CODE;

         IF LENGTH (AGENT_LIST.ID_TYPE) > 0
            AND LENGTH (AGENT_LIST.ID_NUMBER) > 0
         THEN
            UPDATE   EPAY.EPAY_AGENT_IDS
               SET   AGENT_NO = V_AGENT_FIN_CODE,
                     SERIAL_NO = (V_SERIAL_NO + 1)
             WHERE       1 = 1
                     AND ID_TYPE = AGENT_LIST.ID_TYPE
                     AND ID_NUMBER = AGENT_LIST.ID_NUMBER
                     AND REGION = AGENT_LIST.REGION;
         ELSE
            UPDATE   EPAY.EPAY_AGENT_IDS
               SET   AGENT_NO = V_AGENT_FIN_CODE,
                     SERIAL_NO = (V_SERIAL_NO + 1)
             WHERE       1 = 1
                     AND AGENT_NAME = AGENT_LIST.AGENT_NAME
                     AND REGION = AGENT_LIST.REGION;
         END IF;
      ELSE
         V_AGENT_FIN_CODE := V_AGENT_CODE;

         IF LENGTH (AGENT_LIST.ID_TYPE) > 0
            AND LENGTH (AGENT_LIST.ID_NUMBER) > 0
         THEN
            UPDATE   EPAY.EPAY_AGENT_IDS
               SET   AGENT_NO = V_AGENT_FIN_CODE, SERIAL_NO = V_SERIAL_NO
             WHERE       1 = 1
                     AND ID_TYPE = AGENT_LIST.ID_TYPE
                     AND ID_NUMBER = AGENT_LIST.ID_NUMBER
                     AND REGION = AGENT_LIST.REGION;
         ELSE
            UPDATE   EPAY.EPAY_AGENT_IDS
               SET   AGENT_NO = V_AGENT_FIN_CODE, SERIAL_NO = V_SERIAL_NO
             WHERE       1 = 1
                     AND AGENT_NAME = AGENT_LIST.AGENT_NAME
                     AND REGION = AGENT_LIST.REGION;
         END IF;
      END IF;

      --AND ROW_ID = AGENT_LIST.ROW_ID;

      --RETURN AGENT_LIST.AGENT_NAME||', '||AGENT_LIST.REGION||', '||AGENT_LIST.CITY||', '||AGENT_LIST.MSISDN;
      CNTA := CNTA + 1;
   END LOOP;

   RETURN CNTA;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE ('ERROR ' || SQLCODE || CHR (10) || SQLERRM);
      RETURN -1;
END;
/