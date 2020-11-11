/* Formatted on 12-18-2018 3:42:35 PM (QP5 v5.126.903.23003) */
DROP TABLE EPAY.EPAY_PSB2_BANK_ACCOUNT_BALS CASCADE CONSTRAINTS PURGE;

CREATE TABLE EPAY.EPAY_PSB2_BANK_ACCOUNT_BALS (
   BNKBALS_ID         NUMBER NOT NULL,
   PSB_HDR_ID         NUMBER,
   BANK_ID            NUMBER,
   CATEGORY_ID        NUMBER,
   VALUE              NUMERIC,
   VOLUME             NUMERIC,
   CREATED_BY         NUMBER,
   CREATION_DATE      VARCHAR2 (21),
   LAST_UPDATE_BY     NUMBER,
   LAST_UPDATE_DATE   VARCHAR2 (21),
   CONSTRAINT PK_BNKBALS_ID PRIMARY KEY (BNKBALS_ID)
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

DROP SEQUENCE EPAY.EPAY_PSB2_BANK_ACCOUNT_BALS_SEQ;

CREATE SEQUENCE EPAY.EPAY_PSB2_BANK_ACCOUNT_BALS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER EPAY.EPAY_PSB2_BANK_ACCOUNT_BALS_TRG
   BEFORE INSERT
   ON EPAY.EPAY_PSB2_BANK_ACCOUNT_BALS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.BNKBALS_ID IS NULL)
DECLARE
   V_ID   EPAY.EPAY_PSB2_BANK_ACCOUNT_BALS.BNKBALS_ID%TYPE;
BEGIN
   SELECT   EPAY.EPAY_PSB2_BANK_ACCOUNT_BALS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.BNKBALS_ID := V_ID;
END EPAY_PSB2_BANK_ACCOUNT_BALS_TRG;