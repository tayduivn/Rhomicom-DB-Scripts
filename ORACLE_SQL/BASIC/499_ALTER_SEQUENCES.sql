/* Formatted on 12-13-2018 11:28:34 AM (QP5 v5.126.903.23003) */
CREATE OR REPLACE PROCEDURE SYS.SEQUENCE_NEWVALUE (SEQOWNER    VARCHAR2,
                                                   SEQNAME     VARCHAR2,
                                                   NEWVALUE    NUMBER)
AS
   LN   NUMBER;
   IB   NUMBER;
BEGIN
   SELECT   LAST_NUMBER, INCREMENT_BY
     INTO   LN, IB
     FROM   SYS.DBA_SEQUENCES
    WHERE   SEQUENCE_OWNER = UPPER (SEQOWNER)
            AND SEQUENCE_NAME = UPPER (SEQNAME);

   EXECUTE IMMEDIATE   'ALTER SEQUENCE '
                    || SEQOWNER
                    || '.'
                    || SEQNAME
                    || ' INCREMENT BY '
                    || (NEWVALUE - LN);

   EXECUTE IMMEDIATE   'SELECT '
                    || SEQOWNER
                    || '.'
                    || SEQNAME
                    || '.NEXTVAL FROM DUAL'
      INTO   LN;

   EXECUTE IMMEDIATE   'ALTER SEQUENCE '
                    || SEQOWNER
                    || '.'
                    || SEQNAME
                    || ' INCREMENT BY '
                    || IB;
END;

GRANT EXECUTE ON SYS.SEQUENCE_NEWVALUE TO SYSTEM;


SELECT   LAST_NUMBER, INCREMENT_BY
  --INTO   LN, IB
  FROM   SYS.DBA_SEQUENCES
 WHERE   SEQUENCE_OWNER = UPPER (:SEQOWNER)
         AND SEQUENCE_NAME = UPPER (:SEQNAME);

/*SELECT   ALRT.ALRT_ALERTS_SEQ.NEXTVAL FROM DUAL;
EXEC SYS.SEQUENCE_NEWVALUE( 'ALRT', 'ALRT_ALERTS_SEQ', 4 );*/
