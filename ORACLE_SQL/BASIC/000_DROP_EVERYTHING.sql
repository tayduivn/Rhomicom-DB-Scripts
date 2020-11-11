/* Formatted on 12-6-2018 5:03:34 PM (QP5 v5.126.903.23003) */
    ALTER SESSION SET "_ORACLE_SCRIPT"=TRUE;

BEGIN
   FOR CUR_REC IN (  SELECT   OBJECT_NAME, OWNER, OBJECT_TYPE
                       FROM   ALL_OBJECTS
                      WHERE   OBJECT_TYPE IN
                                    ('TABLE',
                                     'VIEW',
                                     'PACKAGE',
                                     'PROCEDURE',
                                     'FUNCTION',
                                     'SEQUENCE')
                              AND OWNER IN
                                       ('SYSADMIN',
                                        'ALRT',
                                        'ACA',
                                        'ATTN',
                                        'HOSP',
                                        'SEC',
                                        'SCM',
                                        'INV',
                                        'PAY',
                                        'PRS',
                                        'PASN',
                                        'HOTL',
                                        'WKF',
                                        'TKP',
                                        'ACCB',
                                        'GST',
                                        'ORG',
                                        'RPT',
                                        'MCF',
                                        'MNLS',
                                        'EPAY','SELF','BOG','PUBLC')
                   ORDER BY   2)
   LOOP
      BEGIN
         IF CUR_REC.OBJECT_TYPE = 'TABLE'
         THEN
            EXECUTE IMMEDIATE   'DROP '
                             || CUR_REC.OBJECT_TYPE
                             || ' '
                             || CUR_REC.OWNER
                             || '.'
                             || CUR_REC.OBJECT_NAME
                             || ' CASCADE CONSTRAINTS';
         ELSE
            EXECUTE IMMEDIATE   'DROP '
                             || CUR_REC.OBJECT_TYPE
                             || ' '
                             || CUR_REC.OWNER
                             || '.'
                             || CUR_REC.OBJECT_NAME
                             || '';
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE(   'FAILED: DROP '
                                 || CUR_REC.OBJECT_TYPE
                                 || ' '
                                 || CUR_REC.OWNER
                                 || '.'
                                 || CUR_REC.OBJECT_NAME
                                 || '');
      END;
   END LOOP;

   FOR CUR_REC1 IN (  SELECT   USERNAME
                        FROM   SYS.ALL_USERS
                       WHERE   USER_ID BETWEEN 106 AND 2000
                    ORDER BY   1)
   LOOP
      BEGIN
         EXECUTE IMMEDIATE 'DROP USER ' || CUR_REC1.USERNAME || ' CASCADE';
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.PUT_LINE ('FAILED: DROP ' || CUR_REC1.USERNAME || '');
      END;
   END LOOP;

   EXECUTE IMMEDIATE 'ALTER DATABASE DEFAULT TABLESPACE SYSAUX';

   EXECUTE IMMEDIATE 'DROP TABLESPACE RHODB  INCLUDING CONTENTS AND DATAFILES'
;
EXCEPTION
   WHEN OTHERS
   THEN
      DBMS_OUTPUT.PUT_LINE ('FAILED: DROP TABLESPACE' || CHR (10) || SQLERRM);
END;
/

--DROP TABLESPACE RHODB  INCLUDING CONTENTS AND DATAFILES;
--DROP USER WKF CASCADE;