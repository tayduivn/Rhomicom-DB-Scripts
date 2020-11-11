/* Formatted on 10/6/2014 7:48:06 PM (QP5 v5.126.903.23003) */
-- TABLE: INV.INV_CONSGMT_ADJSTMNT_HDR

-- DROP TABLE INV.INV_CONSGMT_ADJSTMNT_HDR;

CREATE TABLE INV.INV_CONSGMT_ADJSTMNT_HDR (
   ADJSTMNT_HDR_ID    NUMBER NOT NULL,
   ADJSTMNT_DATE      VARCHAR2 (50 BYTE),
   CREATED_BY         NUMBER,
   CREATION_DATE      VARCHAR2 (50 BYTE),
   LAST_UPDATE_BY     NUMBER,
   LAST_UPDATE_DATE   VARCHAR2 (50 BYTE),
   DESCRIPTION        VARCHAR2 (300 BYTE),
   ORG_ID             NUMBER,
   SOURCE_TYPE        VARCHAR2 (15 BYTE),
   SOURCE_CODE        VARCHAR2 (50 BYTE),
   STATUS             VARCHAR2 (30 BYTE),
   TOTAL_AMOUNT       NUMBER
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

ALTER TABLE INV.INV_CONSGMT_ADJSTMNT_HDR
  ADD(  CONSTRAINT PK_CONSGMT_ADJSTMT_HDR PRIMARY KEY (ADJSTMNT_HDR_ID ));

-- INDEX: INV.IDX_ADJSTMNT_DATE1

-- DROP INDEX INV.IDX_ADJSTMNT_DATE1;

CREATE INDEX INV.IDX_ADJSTMNT_DATE1
   ON INV.INV_CONSGMT_ADJSTMNT_HDR (ADJSTMNT_DATE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

   /*
-- INDEX: INV.IDX_ADJSTMNT_HDR_ID2

-- DROP INDEX INV.IDX_ADJSTMNT_HDR_ID2;

CREATE UNIQUE INDEX INV.IDX_ADJSTMNT_HDR_ID2
   ON INV.INV_CONSGMT_ADJSTMNT_HDR (ADJSTMNT_HDR_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;
*/
-- INDEX: INV.IDX_ORG_ID1

-- DROP INDEX INV.IDX_ORG_ID1;

CREATE INDEX INV.IDX_ORG_ID1
   ON INV.INV_CONSGMT_ADJSTMNT_HDR (ORG_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

-- INDEX: INV.IDX_SOURCE_CODE1

-- DROP INDEX INV.IDX_SOURCE_CODE1;

CREATE INDEX INV.IDX_SOURCE_CODE1
   ON INV.INV_CONSGMT_ADJSTMNT_HDR (SOURCE_CODE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

-- INDEX: INV.IDX_SOURCE_TYPE1

-- DROP INDEX INV.IDX_SOURCE_TYPE1;

CREATE INDEX INV.IDX_SOURCE_TYPE1
   ON INV.INV_CONSGMT_ADJSTMNT_HDR (SOURCE_TYPE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

-- INDEX: INV.IDX_STATUS1

-- DROP INDEX INV.IDX_STATUS1;

CREATE INDEX INV.IDX_STATUS1
   ON INV.INV_CONSGMT_ADJSTMNT_HDR (STATUS)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE SEQUENCE INV.INV_CONSGMT_ADJSTMNT_HDR_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER INV.INV_CONSGMT_ADJSTMNT_HDR_TRG
   BEFORE INSERT
   ON INV.INV_CONSGMT_ADJSTMNT_HDR
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.ADJSTMNT_HDR_ID IS NULL)
DECLARE
   V_ID   INV.INV_CONSGMT_ADJSTMNT_HDR.ADJSTMNT_HDR_ID%TYPE;
BEGIN
   SELECT   INV.INV_CONSGMT_ADJSTMNT_HDR_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.ADJSTMNT_HDR_ID := V_ID;
END INV_CONSGMT_ADJSTMNT_HDR_TRG;