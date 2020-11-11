/* Formatted on 12-15-2018 9:44:26 AM (QP5 v5.126.903.23003) */
DROP TABLE PRS.PRSN_AUDIT_TRAIL_TBL  CASCADE CONSTRAINTS PURGE;

CREATE TABLE PRS.PRSN_AUDIT_TRAIL_TBL (USER_ID          NUMBER NOT NULL,
                                       ACTION_TYPE      VARCHAR2 (30 BYTE),
                                       ACTION_DETAILS   CLOB,
                                       ACTION_TIME      VARCHAR2 (21 BYTE),
                                       LOGIN_NUMBER     NUMBER,
                                       DFLT_ROW_ID      NUMBER NOT NULL)
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

CREATE UNIQUE INDEX PRS.IDX_DFLT_ROW_ID
   ON PRS.PRSN_AUDIT_TRAIL_TBL (DFLT_ROW_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE PRS.PRSN_AUDIT_TRAIL_TBL ADD (
CONSTRAINT PK_DFLT_ROW_ID
PRIMARY KEY
(DFLT_ROW_ID));


CREATE INDEX PRS.IDX_ACTION_TIME
   ON PRS.PRSN_AUDIT_TRAIL_TBL (ACTION_TIME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX PRS.IDX_ACTION_TYPE
   ON PRS.PRSN_AUDIT_TRAIL_TBL (ACTION_TYPE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;


CREATE INDEX PRS.IDX_LOGIN_NUMBER
   ON PRS.PRSN_AUDIT_TRAIL_TBL (LOGIN_NUMBER)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX PRS.IDX_USER_ID
   ON PRS.PRSN_AUDIT_TRAIL_TBL (USER_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP SEQUENCE PRS.PRSN_AUDIT_TRAIL_TBL_SEQ;

CREATE SEQUENCE PRS.PRSN_AUDIT_TRAIL_TBL_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER PRS.PRSN_ALL_OTHER_INFO_TABLE_TRG
   BEFORE INSERT
   ON PRS.PRSN_ALL_OTHER_INFO_TABLE
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.DFLT_ROW_ID IS NULL)
DECLARE
   V_ID   PRS.PRSN_AUDIT_TRAIL_TBL.DFLT_ROW_ID%TYPE;
BEGIN
   SELECT   PRS.PRSN_AUDIT_TRAIL_TBL_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.DFLT_ROW_ID := V_ID;
END PRSN_AUDIT_TRAIL_TBL_TRG;