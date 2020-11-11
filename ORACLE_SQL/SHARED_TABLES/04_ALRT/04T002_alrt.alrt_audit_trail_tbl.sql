/* Formatted on 12-12-2018 2:14:28 PM (QP5 v5.126.903.23003) */
CREATE TABLE ALRT.ALRT_AUDIT_TRAIL_TBL (DFLT_ROW_ID      NUMBER NOT NULL,
                                        USER_ID          NUMBER NOT NULL,
                                        ACTION_TYPE      VARCHAR2 (30 BYTE),
                                        ACTION_DETAILS   CLOB,
                                        ACTION_TIME      VARCHAR2 (21 BYTE),
                                        LOGIN_NUMBER     NUMBER)
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

CREATE UNIQUE INDEX ALRT.IDX_DFLT_ROW_ID
   ON ALRT.ALRT_AUDIT_TRAIL_TBL (DFLT_ROW_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ALRT.IDX_ACTION_TIME
   ON ALRT.ALRT_AUDIT_TRAIL_TBL (ACTION_TIME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE UNIQUE INDEX ALRT.IDX_ACTION_TYPE
   ON ALRT.ALRT_AUDIT_TRAIL_TBL (ACTION_TYPE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ALRT.IDX_LOGIN_NUMBER
   ON ALRT.ALRT_AUDIT_TRAIL_TBL (LOGIN_NUMBER)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ALRT.IDX_USER_ID
   ON ALRT.ALRT_AUDIT_TRAIL_TBL (USER_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE ALRT.ALRT_AUDIT_TRAIL_TBL ADD (
  CONSTRAINT PK_DFLT_ROW_ID
 PRIMARY KEY
 (DFLT_ROW_ID));

CREATE SEQUENCE ALRT.ALRT_AUDIT_TRAIL_TBLT_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER ALRT.ALRT_AUDIT_TRAIL_TBL_TRG
   BEFORE INSERT
   ON ALRT.ALRT_AUDIT_TRAIL_TBL
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.DFLT_ROW_ID IS NULL)
DECLARE
   V_ID   ALRT.ALRT_AUDIT_TRAIL_TBL.DFLT_ROW_ID%TYPE;
BEGIN
   SELECT   ALRT.ALRT_AUDIT_TRAIL_TBLT_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.DFLT_ROW_ID := V_ID;
END ALRT_AUDIT_TRAIL_TBL_TRG;