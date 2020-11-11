/* Formatted on 12-19-2018 6:27:55 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION PRS.XX_GET_NEXT_DATE_AFTR (
   P_START_DATE    VARCHAR2,
   P_NO_DAYS       INTEGER
)
   RETURN VARCHAR2
AS
   P_START_DAY   VARCHAR2 (21) := '';
   I             INTEGER := 0;
   J             INTEGER := 1;
   Y             INTEGER := 0;
   IS_HLDY       VARCHAR2 (5) := 'FALSE';
   IS_WKND       VARCHAR2 (5) := 'FALSE';
   HLDY_CNT      INTEGER := 0;
   P_ERR         VARCHAR2(4000) := '';
   RCRD_COUNT    INTEGER := 0;
BEGIN
   IF P_NO_DAYS <= 0
   THEN
      RETURN P_START_DATE;
   END IF;

   P_START_DAY := P_START_DATE;

   WHILE Y < P_NO_DAYS
   LOOP
      SELECT   TO_CHAR (
                  TO_TIMESTAMP (P_START_DAY, 'YYYY-MM-DD') + INTERVAL '1' DAY,
                  'YYYY-MM-DD'
               )
        INTO   P_START_DAY
        FROM   DUAL;

      WHILE J > 0
      LOOP
         SELECT   PRS.IS_DATE_HOLIDAY (P_START_DAY) INTO IS_HLDY FROM DUAL;

         SELECT   PRS.IS_DATE_WEEKEND (P_START_DAY) INTO IS_WKND FROM DUAL;

         IF IS_HLDY = 'TRUE' OR IS_WKND = 'TRUE'
         THEN
            SELECT   TO_CHAR (
                        TO_TIMESTAMP (P_START_DAY, 'YYYY-MM-DD')
                        + INTERVAL '1' DAY,
                        'YYYY-MM-DD'
                     )
              INTO   P_START_DAY
              FROM   DUAL;

            J := 1;
            I := 1;
         ELSE
            J := 0;
         END IF;
      END LOOP;

      Y := Y + 1;

      --RAISE NOTICE 'Y=:%', Y;
      --RAISE NOTICE 'NEW DATE=:%', Y;
      IF Y = P_NO_DAYS
      THEN
         I := 0;
      ELSE
         I := 1;
         J := 1;
      END IF;

      EXIT WHEN I = 0;
   END LOOP;

   RETURN P_START_DAY;
END;

select PRS.XX_GET_NEXT_DATE_AFTR ('2018-12-27',2
) from dual;