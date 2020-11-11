/* Formatted on 9/21/2014 8:53:54 PM (QP5 v5.126.903.23003) */
-- TABLE: ACCB.ACCB_ALL_OTHER_INFO_TABLE

--DROP TABLE ACCB.ACCB_ALL_OTHER_INFO_TABLE;

CREATE TABLE ACCB.ACCB_ALL_OTHER_INFO_TABLE (
   DFLT_ROW_ID               NUMBER NOT NULL,
   TBL_OTHR_INF_COMBNTN_ID   NUMBER NOT NULL,
   ROW_PK_ID_VAL             NUMBER NOT NULL,
   OTHER_INFO_VALUE          CLOB,
   CREATED_BY                NUMBER NOT NULL,
   CREATION_DATE             VARCHAR2 (21 BYTE) NOT NULL,
   LAST_UPDATE_BY            NUMBER NOT NULL,
   LAST_UPDATE_DATE          VARCHAR2 (21 BYTE) NOT NULL,
   CONSTRAINT PK_DFLT_ROW_ID_OI PRIMARY KEY (DFLT_ROW_ID)
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

CREATE INDEX ACCB.IDX_ROW_PK_ID_VAL
   ON ACCB.ACCB_ALL_OTHER_INFO_TABLE (ROW_PK_ID_VAL)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_TBL_OTHR_INF_COMBNTN_ID
   ON ACCB.ACCB_ALL_OTHER_INFO_TABLE (TBL_OTHR_INF_COMBNTN_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE SEQUENCE ACCB.ACCB_ALL_OTHER_INFO_TABLE_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER ACCB.ACCB_ALL_OTHER_INFO_TABLE_TRG
   BEFORE INSERT
   ON ACCB.ACCB_ALL_OTHER_INFO_TABLE
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.DFLT_ROW_ID IS NULL)
DECLARE
   V_ID   ACCB.ACCB_ALL_OTHER_INFO_TABLE.DFLT_ROW_ID%TYPE;
BEGIN
   SELECT   ACCB.ACCB_ALL_OTHER_INFO_TABLE_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.DFLT_ROW_ID := V_ID;
END ACCB_ALL_OTHER_INFO_TABLE_TRG;