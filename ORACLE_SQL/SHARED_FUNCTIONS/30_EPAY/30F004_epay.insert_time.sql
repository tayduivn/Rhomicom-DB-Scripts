/* Formatted on 12-19-2018 11:03:36 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION EPAY.INSERT_TIME
   RETURN NUMBER
AS
   PRAGMA AUTONOMOUS_TRANSACTION;
   HR   CLOB;
   MN   CLOB;
   TM   CLOB;
BEGIN
   FOR I IN 1 .. 12
   LOOP
      FOR J IN 0 .. 59
      LOOP
         IF I < 10
         THEN
            HR := '0' || I;
         ELSE
            HR := TO_CHAR (I);
         END IF;

         IF J < 10
         THEN
            MN := '0' || J;
         ELSE
            MN := TO_CHAR (J);
         END IF;

         TM := HR || ':' || MN || ' PM';

         INSERT INTO GST.GEN_STP_LOV_VALUES (
                                                VALUE_LIST_ID,
                                                PSSBL_VALUE,
                                                PSSBL_VALUE_DESC,
                                                CREATED_BY,
                                                CREATION_DATE,
                                                LAST_UPDATE_DATE,
                                                LAST_UPDATE_BY,
                                                IS_ENABLED,
                                                ALLOWED_ORG_IDS
                    )
           VALUES   (
                        (SELECT   VALUE_LIST_ID
                           FROM   GST.GEN_STP_LOV_NAMES B
                          WHERE   VALUE_LIST_NAME =
                                     'Hour And Minute Combinations'),
                        TM,
                        TM,
                        1,
                        '2015-12-07',
                        '2015-12-07',
                        1,
                        '1',
                        ',6,4,5,1,2,3,'
                    );
      END LOOP;
   END LOOP;


   FOR I IN 1 .. 9
   LOOP
      FOR J IN 0 .. 59
      LOOP
         HR := TO_CHAR (I);

         IF J < 10
         THEN
            MN := '0' || J;
         ELSE
            MN := TO_CHAR (J);
         END IF;

         TM := HR || ':' || MN || ' PM';

         INSERT INTO GST.GEN_STP_LOV_VALUES (
                                                VALUE_LIST_ID,
                                                PSSBL_VALUE,
                                                PSSBL_VALUE_DESC,
                                                CREATED_BY,
                                                CREATION_DATE,
                                                LAST_UPDATE_DATE,
                                                LAST_UPDATE_BY,
                                                IS_ENABLED,
                                                ALLOWED_ORG_IDS
                    )
           VALUES   (
                        (SELECT   VALUE_LIST_ID
                           FROM   GST.GEN_STP_LOV_NAMES B
                          WHERE   VALUE_LIST_NAME =
                                     'Hour And Minute Combinations'),
                        TM,
                        TM,
                        1,
                        '2015-12-07',
                        '2015-12-07',
                        1,
                        '1',
                        ',6,4,5,1,2,3,'
                    );
      END LOOP;
   END LOOP;

   COMMIT;
   RETURN 1;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE ('ERROR ' || SQLCODE || CHR (10) || SQLERRM);
      RETURN 0;
END;
/