/* Formatted on 9/22/2014 1:41:50 PM (QP5 v5.126.903.23003) */
-- TABLE: ACCB.ACCB_EXCHANGE_RATES

-- DROP TABLE ACCB.ACCB_EXCHANGE_RATES;

CREATE TABLE ACCB.ACCB_EXCHANGE_RATES (
   RATE_ID            NUMBER NOT NULL,
   CONVERSION_DATE    VARCHAR2 (21) NOT NULL,
   CURRENCY_FROM      VARCHAR2 (5) NOT NULL,
   CURRENCY_FROM_ID   NUMBER NOT NULL,
   CURRENCY_TO        VARCHAR2 (5) NOT NULL,
   CURRENCY_TO_ID     NUMBER NOT NULL,
   MULTIPLY_FROM_BY   NUMBER NOT NULL,
   CREATED_BY         NUMBER NOT NULL,
   CREATION_DATE      VARCHAR2 (21) NOT NULL,
   LAST_UPDATE_BY     NUMBER NOT NULL,
   LAST_UPDATE_DATE   VARCHAR2 (21) NOT NULL,
   CONSTRAINT PK_RATE_ID PRIMARY KEY (RATE_ID)
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

CREATE INDEX ACCB.IDX_CONVERSION_DATE
   ON ACCB.ACCB_EXCHANGE_RATES (CONVERSION_DATE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_CURRENCY_FROM
   ON ACCB.ACCB_EXCHANGE_RATES (CURRENCY_FROM)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_CURRENCY_FROM_ID
   ON ACCB.ACCB_EXCHANGE_RATES (CURRENCY_FROM_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_CURRENCY_TO
   ON ACCB.ACCB_EXCHANGE_RATES (CURRENCY_TO)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_CURRENCY_TO_ID
   ON ACCB.ACCB_EXCHANGE_RATES (CURRENCY_TO_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE SEQUENCE ACCB.ACCB_EXCHANGE_RATES_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER ACCB.ACCB_EXCHANGE_RATES_TRG
   BEFORE INSERT
   ON ACCB.ACCB_EXCHANGE_RATES
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.RATE_ID IS NULL)
DECLARE
   V_ID   ACCB.ACCB_EXCHANGE_RATES.RATE_ID%TYPE;
BEGIN
   SELECT   ACCB.ACCB_EXCHANGE_RATES_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.RATE_ID := V_ID;
END ACCB_EXCHANGE_RATES_TRG;