/* Formatted on 12-20-2018 9:55:35 AM (QP5 v5.126.903.23003) */
DECLARE
   L_SQL   VARCHAR2 (4000);
BEGIN
   FOR CUR IN (  SELECT   *
                   FROM   ALL_OBJECTS
                  WHERE   OBJECT_TYPE IN ('TABLE', 'SEQUENCE', 'FUNCTION')
                          AND OWNER IN (SELECT   USERNAME
                                          FROM   SYS.ALL_USERS
                                         WHERE   USER_ID BETWEEN 106 AND 2000)
               ORDER BY   OWNER)
   LOOP
      L_SQL :=
            'grant all on '
         || CUR.OWNER
         || '.'
         || CUR.OBJECT_NAME
         || ' to SYSADMIN,GST,EPAY,SEC,PRS,PASN,ORG';


      DBMS_OUTPUT.PUT_LINE (L_SQL || ';');

      EXECUTE IMMEDIATE L_SQL;
   END LOOP;
END;