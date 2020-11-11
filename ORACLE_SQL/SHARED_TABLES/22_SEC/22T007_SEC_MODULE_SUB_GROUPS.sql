/* Formatted on 12-17-2018 9:37:23 AM (QP5 v5.126.903.23003) */
DROP TABLE SEC.SEC_MODULE_SUB_GROUPS  CASCADE CONSTRAINTS PURGE;

CREATE TABLE SEC.SEC_MODULE_SUB_GROUPS (
   TABLE_ID          NUMBER NOT NULL,
   SUB_GROUP_NAME    VARCHAR2 (200 BYTE) NOT NULL,
   MAIN_TABLE_NAME   VARCHAR2 (200 BYTE) NOT NULL,
   ROW_PK_COL_NAME   VARCHAR2 (200 BYTE) NOT NULL,
   MODULE_ID         NUMBER NOT NULL,
   DATE_ADDED        VARCHAR2 (21 BYTE) NOT NULL
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

CREATE UNIQUE INDEX SEC.IDX_TABLE_ID
   ON SEC.SEC_MODULE_SUB_GROUPS (TABLE_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP SEQUENCE SEC.SEC_MODULE_SUB_GROUPS_SEQ;

CREATE SEQUENCE SEC.SEC_MODULE_SUB_GROUPS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

ALTER TABLE SEC.SEC_MODULE_SUB_GROUPS ADD (
CONSTRAINT PK_TABLE_ID
PRIMARY KEY
(TABLE_ID));


CREATE INDEX SEC.IDX_MAIN_TABLE_NAME
   ON SEC.SEC_MODULE_SUB_GROUPS (MAIN_TABLE_NAME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX SEC.IDX_MODULE_ID_SBG
   ON SEC.SEC_MODULE_SUB_GROUPS (MODULE_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;


CREATE INDEX SEC.IDX_ROW_PK_COL_NAME
   ON SEC.SEC_MODULE_SUB_GROUPS (ROW_PK_COL_NAME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX SEC.IDX_SUB_GROUP_NAME
   ON SEC.SEC_MODULE_SUB_GROUPS (SUB_GROUP_NAME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;


CREATE OR REPLACE TRIGGER SEC.SEC_MODULE_SUB_GROUPS_TRG
   BEFORE INSERT
   ON SEC.SEC_MODULE_SUB_GROUPS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.TABLE_ID IS NULL)
DECLARE
   V_ID   SEC.SEC_MODULE_SUB_GROUPS.TABLE_ID%TYPE;
BEGIN
   SELECT   SEC.SEC_MODULE_SUB_GROUPS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.TABLE_ID := V_ID;
END SEC_MODULE_SUB_GROUPS_TRG;