/* Formatted on 12-15-2018 8:00:21 AM (QP5 v5.126.903.23003) */
DROP TABLE ORG.ORG_DIVS_GROUPS  CASCADE CONSTRAINTS PURGE;

CREATE TABLE ORG.ORG_DIVS_GROUPS (
   DIV_ID             NUMBER NOT NULL,
   ORG_ID             NUMBER NOT NULL,
   DIV_CODE_NAME      VARCHAR2 (200 BYTE),
   DIV_LOGO           VARCHAR2 (100 BYTE),
   PRNT_DIV_ID        NUMBER,
   DIV_TYP_ID         NUMBER,
   IS_ENABLED         VARCHAR2 (1 BYTE),
   CREATED_BY         NUMBER NOT NULL,
   CREATION_DATE      VARCHAR2 (21 BYTE) NOT NULL,
   LAST_UPDATE_BY     NUMBER NOT NULL,
   LAST_UPDATE_DATE   VARCHAR2 (21 BYTE) NOT NULL,
   DIV_DESC           VARCHAR2 (1000 BYTE),
   EXTRNL_GRP_ID      NUMBER DEFAULT (-1) NOT NULL,
   EXTRNL_GRP_TYPE    VARCHAR2 (100 BYTE) DEFAULT '' NOT NULL
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

CREATE UNIQUE INDEX ORG.IDX_DIV_ID
   ON ORG.ORG_DIVS_GROUPS (DIV_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

ALTER TABLE ORG.ORG_DIVS_GROUPS ADD (
  CONSTRAINT PK_DIV_ID
 PRIMARY KEY
 (DIV_ID));

CREATE INDEX ORG.IDX_DIV_CODE_NAME
   ON ORG.ORG_DIVS_GROUPS (DIV_CODE_NAME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ORG.IDX_DIV_DESC
   ON ORG.ORG_DIVS_GROUPS (DIV_DESC)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;


CREATE INDEX ORG.IDX_ORG_ID_DV
   ON ORG.ORG_DIVS_GROUPS (ORG_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ORG.IDX_PRNT_DIV_ID
   ON ORG.ORG_DIVS_GROUPS (PRNT_DIV_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP  SEQUENCE ORG.ORG_DIVS_GROUPS_SEQ;

CREATE SEQUENCE ORG.ORG_DIVS_GROUPS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER ORG.ORG_DIVS_GROUPS_TRG
   BEFORE INSERT
   ON ORG.ORG_DIVS_GROUPS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.DIV_ID IS NULL)
DECLARE
   V_ID   ORG.ORG_DIVS_GROUPS.DIV_ID%TYPE;
BEGIN
   SELECT   ORG.ORG_DIVS_GROUPS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.DIV_ID := V_ID;
END ORG_DIVS_GROUPS_TRG;