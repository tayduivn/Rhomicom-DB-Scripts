/* Formatted on 12-19-2018 1:37:48 PM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION SEC.TEST_PRMSSNS (P_TESTDATA      VARCHAR2,
                                             P_MDLNM         VARCHAR2,
                                             P_SESSNROLES    VARCHAR2)
   RETURN INTEGER
AS
   TYPE NUMBERARRAY IS TABLE OF NUMBER
                          INDEX BY BINARY_INTEGER;

   CNTR         INTEGER := 0;
   N            INTEGER := 0;
   V_DLMTRS     VARCHAR2 (1) := '~';


   V_CHKRSLTS   NUMBERARRAY;

   L_COUNT1     NUMBER := 0;
   V_MSGS       CLOB := '';
BEGIN
   V_MSGS :=
         V_MSGS
      || '..BEFORE SPLIT..'
      || P_TESTDATA
      || '::'
      || P_MDLNM
      || '::'
      || CHR (10);

   --V_PRLDGS_TO_TEST := STRING_TO_ARRAY(P_TESTDATA, V_DLMTRS) :: TEXT [];
   --CNTR := ARRAY_LENGTH(V_PRLDGS_TO_TEST, 1);
   SELECT   COUNT (1)
     INTO   L_COUNT1
     FROM   TABLE (SYSADMIN.DLMTR_TO_TABLE (P_TESTDATA, V_DLMTRS));

   CNTR := L_COUNT1;

   V_MSGS := V_MSGS || 'BEFORE FILL..' || CNTR || '::cntr' || CHR (10);

   WHILE N < L_COUNT1
   LOOP
      V_CHKRSLTS (N) := 0;
      N := N + 1;
   END LOOP;

   N := 0;
   --V_CHKRSLTS := ARRAY_FILL(0, ARRAY [CNTR]);
   V_MSGS :=
         V_MSGS
      || 'AFTER SPLIT..'
      || L_COUNT1
      || V_DLMTRS
      || CHR (10);

   FOR J
   IN (SELECT   TO_NUMBER (COLUMN_VALUE) COLUMN_VALUE
         FROM   TABLE (SYSADMIN.DLMTR_TO_TABLE (P_TESTDATA, V_DLMTRS)))
   LOOP
      --RAISE NOTICE 'IN % RST %', P_MDLNM, V_PRLDGS_TO_TEST [J];
      IF (SEC.DOSLCTDROLESHVTHISPRVLDG (
             SEC.GET_PRVLDG_ID (J.COLUMN_VALUE, P_MDLNM),
             P_SESSNROLES
          ) >= 1)
      THEN
         V_CHKRSLTS (N) := 1;
      ---RAISE NOTICE 'IN % Rst %', 1, V_CHKRSLTS [J];
      END IF;

      N := N + 1;
   END LOOP;

   N := 0;

   WHILE N < L_COUNT1
   LOOP
      IF (V_CHKRSLTS (N) = 0)
      THEN
         RETURN 0;
      END IF;
   END LOOP;

   --RAISE NOTICE 'ENDED %', V_MSGS;
   RETURN 1;
EXCEPTION
   WHEN OTHERS
   THEN
      --RAISE NOTICE 'ERROR %', V_MSGS || SQLSTATE || CHR(10) || SQLERRM;
      RETURN 0;
END;
/