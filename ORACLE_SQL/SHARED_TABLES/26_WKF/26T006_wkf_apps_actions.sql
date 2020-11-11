/* Formatted on 12-18-2018 9:50:32 AM (QP5 v5.126.903.23003) */
DROP TABLE WKF.WKF_APPS_ACTIONS CASCADE CONSTRAINTS PURGE;

CREATE TABLE WKF.WKF_APPS_ACTIONS (
   ACTION_SQL_ID         NUMBER NOT NULL,
   ACTION_PERFORMED_NM   VARCHAR2 (50 BYTE),
   SQL_STMNT             CLOB,
   CREATED_BY            NUMBER NOT NULL,
   CREATION_DATE         VARCHAR2 (21 BYTE) NOT NULL,
   LAST_UPDATE_BY        NUMBER NOT NULL,
   LAST_UPDATE_DATE      VARCHAR2 (21 BYTE) NOT NULL,
   APP_ID                NUMBER,
   EXECUTABLE_FILE_NM    VARCHAR2 (200 BYTE),
   WEB_URL               VARCHAR2 (300 BYTE),
   IS_WEB_DSPLY_DIAG     VARCHAR2 (1 BYTE),
   ACTION_DESC           VARCHAR2 (300 BYTE),
   IS_ADMIN_ONLY         VARCHAR2 (1 BYTE) DEFAULT '0' NOT NULL,
   RPT_ID                INTEGER DEFAULT -1 NOT NULL,
   ALERT_ID              INTEGER DEFAULT -1 NOT NULL,
   PARAM_VALS_REP_STR    VARCHAR2 (500),
   CONSTRAINT PK_ACTION_SQL_ID PRIMARY KEY (ACTION_SQL_ID)
)
TABLESPACE RHODB
PCTUSED 0
PCTFREE 10
INITRANS 1
MAXTRANS 255
STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
LOGGING
NOCOMPRESS
NOCACHE
NOPARALLEL
MONITORING;

CREATE INDEX WKF.IDX_ACTION_PERFORMED_NM
   ON WKF.WKF_APPS_ACTIONS (ACTION_PERFORMED_NM)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX WKF.IDX_APP_ID_SQL
   ON WKF.WKF_APPS_ACTIONS (APP_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP SEQUENCE WKF.WKF_APPS_N_ACTION_SQLS_ID_SEQ;

CREATE SEQUENCE WKF.WKF_APPS_N_ACTION_SQLS_ID_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER WKF.WKF_APPS_N_ACTION_SQLS_ID_TRG
   BEFORE INSERT
   ON WKF.WKF_APPS_ACTIONS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.ACTION_SQL_ID IS NULL)
DECLARE
   V_ID   WKF.WKF_APPS_ACTIONS.ACTION_SQL_ID%TYPE;
BEGIN
   SELECT   WKF.WKF_APPS_N_ACTION_SQLS_ID_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.ACTION_SQL_ID := V_ID;
END WKF_APPS_N_ACTION_SQLS_ID_TRG;