/* Formatted on 12-18-2018 10:06:11 PM (QP5 v5.126.903.23003) */
DROP TABLE EPAY.EPAY_PSB10_CARD_FEES_HDR CASCADE CONSTRAINTS PURGE;

CREATE TABLE EPAY.EPAY_PSB10_CARD_FEES_HDR (
   CARD_FEE_HDR_ID             NUMBER NOT NULL,
   PSB_HDR_ID                  NUMBER,
   PRODUCT_ID                  NUMBER,
   INTERCHANGE_FEE_TO_ISSUER   NUMBER,
   CREATED_BY                  NUMBER,
   CREATION_DATE               VARCHAR2 (21),
   LAST_UPDATE_BY              NUMBER,
   LAST_UPDATE_DATE            VARCHAR2 (21),
   OLD_CARD_FEE_HDR_ID         NUMBER DEFAULT -1 NOT NULL,
   -- CARD_FEE_HDR_ID FOR WITHDRAWN TRANSACTION
   PRODUCT_NAME                VARCHAR2 (50),
   TRANSACTION_CHANNEL_ID      INTEGER,
   FEE_TYPE_ID                 INTEGER,
   IS_DATA_SRC_COPY            VARCHAR2 (3),       -- YES - FROM COPY PREVIOUS
   CONSTRAINT PK_CARD_FEE_HDR_ID PRIMARY KEY (CARD_FEE_HDR_ID)
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

COMMENT ON COLUMN EPAY.EPAY_PSB10_CARD_FEES_HDR.OLD_CARD_FEE_HDR_ID IS
'card_fee_hdr_id for withdrawn transaction';

COMMENT ON COLUMN EPAY.EPAY_PSB10_CARD_FEES_HDR.IS_DATA_SRC_COPY IS
'YES - from copy previous';

DROP SEQUENCE EPAY.EPAY_PSB10_CARD_FEES_HDR_SEQ;

CREATE SEQUENCE EPAY.EPAY_PSB10_CARD_FEES_HDR_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER EPAY.EPAY_PSB10_CARD_FEES_HDR_TRG
   BEFORE INSERT
   ON EPAY.EPAY_PSB10_CARD_FEES_HDR
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.CARD_FEE_HDR_ID IS NULL)
DECLARE
   V_ID   EPAY.EPAY_PSB10_CARD_FEES_HDR.CARD_FEE_HDR_ID%TYPE;
BEGIN
   SELECT   EPAY.EPAY_PSB10_CARD_FEES_HDR_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.CARD_FEE_HDR_ID := V_ID;
END EPAY_PSB10_CARD_FEES_HDR_TRG;


CREATE OR REPLACE TRIGGER EPAY.COPY_PSB10_DET_TRNS_TRG
   AFTER INSERT
   ON EPAY.EPAY_PSB10_CARD_FEES_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   IF :NEW.IS_DATA_SRC_COPY = 'YES'
   THEN
      INSERT INTO EPAY.EPAY_PSB10_CARD_FEES_DET (CARD_FEE_HDR_ID,
                                                 AMOUNT_LOW,
                                                 AMOUNT_HIGH,
                                                 FEE_CHARGED_FLAT_RATE,
                                                 REMARKS,
                                                 CREATED_BY,
                                                 CREATION_DATE,
                                                 LAST_UPDATE_BY,
                                                 LAST_UPDATE_DATE,
                                                 AMOUNT_TYPE,
                                                 CURRENCY_CODE,
                                                 FEE_CHARGED_PERCENTAGE)
         SELECT   :NEW.CARD_FEE_HDR_ID,
                  AMOUNT_LOW,
                  AMOUNT_HIGH,
                  FEE_CHARGED_FLAT_RATE,
                  REMARKS,
                  :NEW.CREATED_BY,
                  :NEW.CREATION_DATE,
                  :NEW.LAST_UPDATE_BY,
                  :NEW.LAST_UPDATE_DATE,
                  AMOUNT_TYPE,
                  CURRENCY_CODE,
                  FEE_CHARGED_PERCENTAGE
           FROM   EPAY.EPAY_PSB10_CARD_FEES_DET
          WHERE   CARD_FEE_HDR_ID =
                     (SELECT   MAX (DET.CARD_FEE_HDR_ID)
                        FROM   EPAY.EPAY_PSB10_CARD_FEES_HDR HDR,
                               EPAY.EPAY_PSB10_CARD_FEES_DET DET
                       WHERE   HDR.PRODUCT_ID = :NEW.PRODUCT_ID
                               AND HDR.TRANSACTION_CHANNEL_ID =
                                     :NEW.TRANSACTION_CHANNEL_ID
                               AND HDR.FEE_TYPE_ID = :NEW.FEE_TYPE_ID
                               AND HDR.CARD_FEE_HDR_ID = DET.CARD_FEE_HDR_ID
                               AND DET.CREATED_BY IN
                                        (SELECT   A.USER_ID
                                           FROM   SEC.SEC_USERS A,
                                                  PRS.PRSN_NAMES_NOS B
                                          WHERE   (A.PERSON_ID = B.PERSON_ID)
                                                  AND B.LNKD_FIRM_ORG_ID =
                                                        (SELECT   LNKD_FIRM_ORG_ID
                                                           FROM   SEC.SEC_USERS A,
                                                                  PRS.PRSN_NAMES_NOS B
                                                          WHERE   (A.PERSON_ID =
                                                                      B.PERSON_ID)
                                                                  AND A.USER_ID =
                                                                        :NEW.CREATED_BY))
                               AND DET.CARD_FEE_HDR_ID !=
                                     :NEW.CARD_FEE_HDR_ID);
   END IF;
END COPY_PSB10_DET_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB10_CARD_FEES_DET_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB10_CARD_FEES_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB10_CARD_FEES_DET
         WHERE   CARD_FEE_HDR_ID = :OLD.CARD_FEE_HDR_ID;
END DELETE_PSB10_CARD_FEES_DET_TRNS_TRG;

CREATE OR REPLACE TRIGGER EPAY.DUPLICATE_PSB10CARDFEES_DETTRNS_TRG
   AFTER INSERT
   ON EPAY.EPAY_PSB10_CARD_FEES_HDR
   FOR EACH ROW
DECLARE
   DTE   VARCHAR2 (21);
BEGIN
   IF :NEW.OLD_CARD_FEE_HDR_ID > 0
   THEN
      /*GET DATE*/
      SELECT   TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS') INTO DTE FROM DUAL;

      INSERT INTO EPAY.EPAY_PSB10_CARD_FEES_DET (CARD_FEE_HDR_ID,
                                                 AMOUNT_LOW,
                                                 AMOUNT_HIGH,
                                                 FEE_CHARGED_FLAT_RATE,
                                                 REMARKS,
                                                 CREATED_BY,
                                                 CREATION_DATE,
                                                 LAST_UPDATE_BY,
                                                 LAST_UPDATE_DATE,
                                                 AMOUNT_TYPE,
                                                 CURRENCY_CODE,
                                                 FEE_CHARGED_PERCENTAGE)
         SELECT   :NEW.CARD_FEE_HDR_ID,
                  AMOUNT_LOW,
                  AMOUNT_HIGH,
                  FEE_CHARGED_FLAT_RATE,
                  REMARKS,
                  CREATED_BY,
                  DTE,
                  LAST_UPDATE_BY,
                  DTE,
                  AMOUNT_TYPE,
                  CURRENCY_CODE,
                  FEE_CHARGED_PERCENTAGE
           FROM   EPAY.EPAY_PSB10_CARD_FEES_DET
          WHERE   CARD_FEE_HDR_ID = :NEW.OLD_CARD_FEE_HDR_ID;
   END IF;
END DUPLICATE_PSB10CARDFEES_DETTRNS_TRG;