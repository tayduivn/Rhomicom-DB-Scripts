/* Formatted on 12-6-2018 5:20:56 PM (QP5 v5.126.903.23003) */
GRANT UNLIMITED TABLESPACE TO SYSADMIN;
ALTER USER SYSADMIN QUOTA 100 M ON RHODB;
ALTER USER SYSADMIN QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='SYSADMIN';
GRANT CONNECT, RESOURCE TO SYSADMIN;
 GRANT EXECUTE ANY TYPE TO SYSADMIN WITH ADMIN OPTION;


/* COMMIT; ALTER USER SYSADMIN QUOTA 100M ON RHODB;
  
  GRANT UNLIMITED RHODB TO SYSADMIN;*/
GRANT UNLIMITED TABLESPACE TO GST;
ALTER USER GST QUOTA 100 M ON RHODB;
ALTER USER GST QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO GST;
 GRANT EXECUTE ANY TYPE TO GST WITH ADMIN OPTION;
GRANT UNLIMITED TABLESPACE TO ACCB;
ALTER USER ACCB QUOTA 100 M ON RHODB;
ALTER USER ACCB QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='ACCB';
GRANT CONNECT, RESOURCE TO ACCB;
 GRANT EXECUTE ANY TYPE TO ACCB WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO ORG;
ALTER USER ORG QUOTA 100 M ON RHODB;
ALTER USER ORG QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='ACCB';
GRANT CONNECT, RESOURCE TO ORG;
 GRANT EXECUTE ANY TYPE TO ORG WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO PASN;
ALTER USER PASN QUOTA 100 M ON RHODB;
ALTER USER PASN QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='ACCB';
GRANT CONNECT, RESOURCE TO PASN;
 GRANT EXECUTE ANY TYPE TO PASN WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO PAY;
ALTER USER PAY QUOTA 100 M ON RHODB;
ALTER USER PAY QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='ACCB';
GRANT CONNECT, RESOURCE TO PAY;
 GRANT EXECUTE ANY TYPE TO PAY WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO PRS;
ALTER USER PRS QUOTA 100 M ON RHODB;
ALTER USER PRS QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='ACCB';
GRANT CONNECT, RESOURCE TO PRS;
 GRANT EXECUTE ANY TYPE TO PRS WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO RPT;
ALTER USER RPT QUOTA 100 M ON RHODB;
ALTER USER RPT QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='ACCB';
GRANT CONNECT, RESOURCE TO RPT;
 GRANT EXECUTE ANY TYPE TO RPT WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO SEC;
ALTER USER SEC QUOTA 100 M ON RHODB;
ALTER USER SEC QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='ACCB';
GRANT CONNECT, RESOURCE TO SEC;
 GRANT EXECUTE ANY TYPE TO SEC WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO SCM;
ALTER USER SCM QUOTA 100 M ON RHODB;
ALTER USER SCM QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='ACCB';
GRANT CONNECT, RESOURCE TO SCM;
 GRANT EXECUTE ANY TYPE TO SCM WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO ACA;
ALTER USER ACA QUOTA 100 M ON RHODB;
ALTER USER ACA QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO ACA;
 GRANT EXECUTE ANY TYPE TO ACA WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO ALRT;
ALTER USER ALRT QUOTA 100 M ON RHODB;
ALTER USER ALRT QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO ALRT;
 GRANT EXECUTE ANY TYPE TO ALRT WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO ATTN;
ALTER USER ATTN QUOTA 100 M ON RHODB;
ALTER USER ATTN QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO ATTN;
 GRANT EXECUTE ANY TYPE TO ATTN WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO INV;
ALTER USER INV QUOTA 100 M ON RHODB;
ALTER USER INV QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO INV;
 GRANT EXECUTE ANY TYPE TO INV WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO MCF;
ALTER USER MCF QUOTA 100 M ON RHODB;
ALTER USER MCF QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO MCF;
 GRANT EXECUTE ANY TYPE TO MCF WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO TKP;
ALTER USER TKP QUOTA 100 M ON RHODB;
ALTER USER TKP QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO TKP;
 GRANT EXECUTE ANY TYPE TO TKP WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO WKF;
ALTER USER WKF QUOTA 100 M ON RHODB;
ALTER USER WKF QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO WKF;
 GRANT EXECUTE ANY TYPE TO WKF WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO HOSP;
ALTER USER HOSP QUOTA 100 M ON RHODB;
ALTER USER HOSP QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO HOSP;
 GRANT EXECUTE ANY TYPE TO HOSP WITH ADMIN OPTION;
 GRANT UNLIMITED TABLESPACE TO HOTL;
ALTER USER HOTL QUOTA 100 M ON RHODB;
ALTER USER HOTL QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO HOTL;
 GRANT EXECUTE ANY TYPE TO HOTL WITH ADMIN OPTION;
 
 GRANT UNLIMITED TABLESPACE TO MNLS;
ALTER USER MNLS QUOTA 100 M ON RHODB;
ALTER USER MNLS QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO MNLS;
 GRANT EXECUTE ANY TYPE TO MNLS WITH ADMIN OPTION;
COMMIT;


 GRANT UNLIMITED TABLESPACE TO EPAY;
ALTER USER EPAY QUOTA 100 M ON RHODB;
ALTER USER EPAY QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO EPAY;
 GRANT EXECUTE ANY TYPE TO EPAY WITH ADMIN OPTION;
COMMIT;

 GRANT UNLIMITED TABLESPACE TO BOG;
ALTER USER BOG QUOTA 100 M ON RHODB;
ALTER USER BOG QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO BOG;
 GRANT EXECUTE ANY TYPE TO BOG WITH ADMIN OPTION;
COMMIT;

 GRANT UNLIMITED TABLESPACE TO SELF;
ALTER USER SELF QUOTA 100 M ON RHODB;
ALTER USER SELF QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO SELF;
 GRANT EXECUTE ANY TYPE TO SELF WITH ADMIN OPTION;
COMMIT;

 GRANT UNLIMITED TABLESPACE TO PUBLC;
ALTER USER PUBLC QUOTA 100 M ON RHODB;
ALTER USER PUBLC QUOTA 100 M ON SYSTEM;
--SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTEE='GST';
GRANT CONNECT, RESOURCE TO PUBLC;
 GRANT EXECUTE ANY TYPE TO PUBLC WITH ADMIN OPTION;
COMMIT;