/* Formatted on 9/22/2014 1:59:12 PM (QP5 v5.126.903.23003) */
-- TABLE: ACCB.ACCB_FA_ASSET_TRNS

-- DROP TABLE ACCB.ACCB_FA_ASSET_TRNS;

CREATE TABLE ACCB.ACCB_FA_ASSET_TRNS (
   ASSET_TRNS_ID       NUMBER NOT NULL,
   TRNS_TYPE           VARCHAR2 (50),
   -- 1RECORD INITIAL VALUE (INCREASE ASSET/INCREASE LIABILITY)...
   INCRS_DCRS1         VARCHAR2 (1),
   COST_ACCNT_ID       NUMBER,
   INCRS_DCRS2         VARCHAR2 (1),
   BALS_LEG_ACCNT_ID   NUMBER,
   CREATED_BY          NUMBER NOT NULL,
   CREATION_DATE       VARCHAR2 (21) NOT NULL,
   LAST_UPDATE_BY      NUMBER NOT NULL,
   LAST_UPDATE_DATE    VARCHAR2 (21) NOT NULL,
   ASSET_ID            NUMBER,
   GL_BATCH_ID         NUMBER,
   CONSTRAINT PK_ASSET_TRNS_ID PRIMARY KEY (ASSET_TRNS_ID)
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

CREATE INDEX ACCB.IDX_FA_TRNS_TYPE
   ON ACCB.ACCB_FA_ASSET_TRNS (TRNS_TYPE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE SEQUENCE ACCB.ACCB_FA_ASSET_TRNS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER ACCB.ACCB_FA_ASSET_TRNS_TRG
   BEFORE INSERT
   ON ACCB.ACCB_FA_ASSET_TRNS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.ASSET_TRNS_ID IS NULL)
DECLARE
   V_ID   ACCB.ACCB_FA_ASSET_TRNS.ASSET_TRNS_ID%TYPE;
BEGIN
   SELECT   ACCB.ACCB_FA_ASSET_TRNS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.ASSET_TRNS_ID := V_ID;
END ACCB_FA_ASSET_TRNS_TRG;