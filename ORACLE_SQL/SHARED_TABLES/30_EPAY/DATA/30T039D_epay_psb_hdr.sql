/* Formatted on 12-19-2018 10:10:06 AM (QP5 v5.126.903.23003) */
DROP TABLE EPAY.EPAY_PSB_HDR CASCADE CONSTRAINTS PURGE;

CREATE TABLE EPAY.EPAY_PSB_HDR (
   PSB_HDR_ID         NUMBER NOT NULL,
   PERIOD             VARCHAR2 (10),
   PSB_TYPE_ID        INTEGER,
   APPRVR_STATUS      VARCHAR2 (20),
   CREATED_BY         NUMBER,
   CREATION_DATE      VARCHAR2 (21),
   LAST_UPDATE_BY     NUMBER,
   LAST_UPDATE_DATE   VARCHAR2 (21),
   SUBMISSION_DATE    VARCHAR2 (21),
   DUE_DATE           VARCHAR2 (21),
   PERIOD_ID          NUMBER,
   OLD_PSB_HDR_ID     NUMBER DEFAULT -1 NOT NULL, -- PSB_HDR_ID FOR WITHDRAWN PERIOD TRANSACTION
   CONSTRAINT PK_PSB_HDR_ID PRIMARY KEY (PSB_HDR_ID)
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

COMMENT ON TABLE EPAY.EPAY_PSB_HDR IS
'PSB TYPES AND IDS
-------------------------
PSB1 - 1
PSB2 - 2
PSB3 - 3
PSB4 - 4
PSB5 - 5
PSB6 - 6
PSB7 - 7
PSB8A - 81
PSB8B - 82
PSB8C - 83
PSB9 - 11
PSB10 - 12
PSB PERIODS - 13
PSB11 - 14
PSB CATEGORY INDICATORS - 15
PSB INDICATORS - 16';

COMMENT ON COLUMN EPAY.EPAY_PSB_HDR.OLD_PSB_HDR_ID IS
'psb_hdr_id for withdrawn period transaction';

DROP SEQUENCE EPAY.EPAY_PSB_HDR_SEQ;

CREATE SEQUENCE EPAY.EPAY_PSB_HDR_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER EPAY.EPAY_PSB_HDR_TRG
   BEFORE INSERT
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.PSB_HDR_ID IS NULL)
DECLARE
   V_ID   EPAY.EPAY_PSB_HDR.PSB_HDR_ID%TYPE;
BEGIN
   SELECT   EPAY.EPAY_PSB_HDR_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.PSB_HDR_ID := V_ID;
END EPAY_PSB_HDR_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB10HDR_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB10_CARD_FEES_HDR
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;

   DELETE FROM   EPAY.EPAY_PSB10_ATM_TRNS_FEES
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;

   DELETE FROM   EPAY.EPAY_PSB10_INTERNET_TRNS_FEES
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
END DELETE_PSB10HDR_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB11HDR_TRNS
   BEFORE DELETE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB11_BANKS_HDR
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
END DELETE_PSB11HDR_TRNS;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB1HDR_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB1_TRNS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;

   DELETE FROM   EPAY.EPAY_PSB1_MONEY_TRANSFER_COMPANIES
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;

   DELETE FROM   EPAY.EPAY_PSB1_MONEY_TRANSFER_CMPNY_TRNS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;

   DELETE FROM   EPAY.EPAY_PSB1_PREPAID_CARD_TYPES
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;

   DELETE FROM   EPAY.EPAY_PSB1_MULTICURRENCIES
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
END DELETE_PSB1HDR_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB2HDR_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB2_TRNS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;

   DELETE FROM   EPAY.EPAY_PSB2_BANK_ACCOUNT_BALS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;

   DELETE FROM   EPAY.EPAY_PSB2_BANK_UNDERWRITERS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;

   DELETE FROM   EPAY.EPAY_PSB2_INSURANCE_UNDERWRITERS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;

   DELETE FROM   EPAY.EPAY_PSB2_INTEREST_DISBURSEMENT_CRITERIA
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
END DELETE_PSB2HDR_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB3HDR_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB3_TRNS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
END DELETE_PSB3HDR_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB4HDR_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB4_TRNS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
END DELETE_PSB4HDR_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB5HDR_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB5_TRNS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
END DELETE_PSB5HDR_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB6HDR_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB6_TRNS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
END DELETE_PSB6HDR_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB7HDR_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB7_TRNS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
END DELETE_PSB7HDR_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB8EHNTIER_HDR_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB8_EHNTIER_TRNS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
END DELETE_PSB8EHNTIER_HDR_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB8MEDTIER_HDR_TRNS
   BEFORE DELETE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB8_MEDTIER_TRNS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
END DELETE_PSB8MEDTIER_HDR_TRNS;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB8MINTIER_HDR_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB8_MINTIER_TRNS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
END DELETE_PSB8MINTIER_HDR_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB9HDR_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB9_TRNS
         WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
END DELETE_PSB9HDR_TRNS_TRG;

CREATE OR REPLACE TRIGGER EPAY.DUPLICATE_PSBHDR_WDRWLTRNS_TRG
   AFTER UPDATE
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   DTE         VARCHAR2 (21);
   NEW_HDRID   NUMBER;
   OLD_HDRID   NUMBER;
BEGIN
   IF :OLD.APPRVR_STATUS = 'Approved'
   THEN
      /*GET DATE*/
      SELECT   TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS') INTO DTE FROM DUAL;

      OLD_HDRID := :OLD.PSB_HDR_ID;

      /*INSERT NEW HEADER WITH STATUS WITHDRAWN*/
      INSERT INTO EPAY.EPAY_PSB_HDR (PSB_TYPE_ID,
                                     APPRVR_STATUS,
                                     CREATED_BY,
                                     CREATION_DATE,
                                     LAST_UPDATE_BY,
                                     LAST_UPDATE_DATE,
                                     DUE_DATE,
                                     PERIOD_ID,
                                     OLD_PSB_HDR_ID)
         SELECT   PSB_TYPE_ID,
                  'Withdrawn',
                  CREATED_BY,
                  DTE,
                  LAST_UPDATE_BY,
                  DTE,
                  DUE_DATE,
                  PERIOD_ID,
                  PSB_HDR_ID
           FROM   EPAY.EPAY_PSB_HDR
          WHERE   PSB_HDR_ID = OLD_HDRID;

      /*GET NEW HDR ID*/
      SELECT   MAX (PSB_HDR_ID)
        INTO   NEW_HDRID
        FROM   EPAY.EPAY_PSB_HDR
       WHERE       PERIOD_ID = :OLD.PERIOD_ID
               AND PSB_TYPE_ID = :OLD.PSB_TYPE_ID
               AND CREATED_BY = :OLD.CREATED_BY;

      IF :OLD.PSB_TYPE_ID = 1
      THEN
         /*INSERT TRANSACTION LINES*/
         INSERT INTO EPAY.EPAY_PSB1_TRNS (CATIND_ID,
                                          PSB_HDR_ID,
                                          VALUE,
                                          VOLUME,
                                          CREATED_BY,
                                          CREATION_DATE,
                                          LAST_UPDATE_BY,
                                          LAST_UPDATE_DATE)
            SELECT   CATIND_ID,
                     NEW_HDRID,
                     VALUE,
                     VOLUME,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE
              FROM   EPAY.EPAY_PSB1_TRNS
             WHERE   PSB_HDR_ID = OLD_HDRID;

         INSERT INTO EPAY.EPAY_PSB1_MONEY_TRANSFER_COMPANIES (PSB_HDR_ID,
                                                              CMPNY_ID,
                                                              CATEGORY_ID,
                                                              CREATED_BY,
                                                              CREATION_DATE,
                                                              LAST_UPDATE_BY,
                                                              LAST_UPDATE_DATE,
                                                              VOLUME)
            SELECT   NEW_HDRID,
                     CMPNY_ID,
                     CATEGORY_ID,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE,
                     VOLUME
              FROM   EPAY.EPAY_PSB1_MONEY_TRANSFER_COMPANIES
             WHERE   PSB_HDR_ID = OLD_HDRID;

         INSERT INTO EPAY.EPAY_PSB1_MONEY_TRANSFER_CMPNY_TRNS (PSB_HDR_ID,
                                                               CMPNY_ID,
                                                               CATEGORY_ID,
                                                               VALUE,
                                                               VOLUME,
                                                               CREATED_BY,
                                                               CREATION_DATE,
                                                               LAST_UPDATE_BY,
                                                               LAST_UPDATE_DATE)
            SELECT   NEW_HDRID,
                     CMPNY_ID,
                     CATEGORY_ID,
                     VALUE,
                     VOLUME,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE
              FROM   EPAY.EPAY_PSB1_MONEY_TRANSFER_CMPNY_TRNS
             WHERE   PSB_HDR_ID = OLD_HDRID;

         INSERT INTO EPAY.EPAY_PSB1_PREPAID_CARD_TYPES (PSB_HDR_ID,
                                                        CREATED_BY,
                                                        CREATION_DATE,
                                                        LAST_UPDATE_BY,
                                                        LAST_UPDATE_DATE,
                                                        INDICATOR_ID,
                                                        SINGLE_CURRENCY,
                                                        MULTI_CURRENCY)
            SELECT   NEW_HDRID,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE,
                     INDICATOR_ID,
                     SINGLE_CURRENCY,
                     MULTI_CURRENCY
              FROM   EPAY.EPAY_PSB1_PREPAID_CARD_TYPES
             WHERE   PSB_HDR_ID = OLD_HDRID;

         INSERT INTO EPAY.EPAY_PSB1_MULTICURRENCIES (PSB_HDR_ID,
                                                     CURRENCY_ID,
                                                     CREATED_BY,
                                                     CREATION_DATE,
                                                     LAST_UPDATE_BY,
                                                     LAST_UPDATE_DATE)
            SELECT   NEW_HDRID,
                     CURRENCY_ID,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE
              FROM   EPAY.EPAY_PSB1_MULTICURRENCIES
             WHERE   PSB_HDR_ID = OLD_HDRID;
      ELSIF :OLD.PSB_TYPE_ID = 2
      THEN
         /*INSERT TRANSACTION LINES*/
         INSERT INTO EPAY.EPAY_PSB2_TRNS (CATIND_ID,
                                          PSB_HDR_ID,
                                          VALUE,
                                          VOLUME,
                                          INDICATOR_DETAILS,
                                          CREATED_BY,
                                          CREATION_DATE,
                                          LAST_UPDATE_BY,
                                          LAST_UPDATE_DATE)
            SELECT   CATIND_ID,
                     NEW_HDRID,
                     VALUE,
                     VOLUME,
                     INDICATOR_DETAILS,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE
              FROM   EPAY.EPAY_PSB2_TRNS
             WHERE   PSB_HDR_ID = OLD_HDRID;

         INSERT INTO EPAY.EPAY_PSB2_BANK_ACCOUNT_BALS (PSB_HDR_ID,
                                                       BANK_ID,
                                                       CATEGORY_ID,
                                                       VALUE,
                                                       VOLUME,
                                                       CREATED_BY,
                                                       CREATION_DATE,
                                                       LAST_UPDATE_BY,
                                                       LAST_UPDATE_DATE)
            SELECT   NEW_HDRID,
                     BANK_ID,
                     CATEGORY_ID,
                     VALUE,
                     VOLUME,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE
              FROM   EPAY.EPAY_PSB2_BANK_ACCOUNT_BALS
             WHERE   PSB_HDR_ID = OLD_HDRID;

         INSERT INTO EPAY.EPAY_PSB2_BANK_UNDERWRITERS (PSB_HDR_ID,
                                                       BANK_ID,
                                                       CATEGORY_ID,
                                                       VALUE,
                                                       VOLUME,
                                                       CREATED_BY,
                                                       CREATION_DATE,
                                                       LAST_UPDATE_BY,
                                                       LAST_UPDATE_DATE)
            SELECT   NEW_HDRID,
                     BANK_ID,
                     CATEGORY_ID,
                     VALUE,
                     VOLUME,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE
              FROM   EPAY.EPAY_PSB2_BANK_UNDERWRITERS
             WHERE   PSB_HDR_ID = OLD_HDRID;

         INSERT INTO EPAY.EPAY_PSB2_INSURANCE_UNDERWRITERS (PSB_HDR_ID,
                                                            INSURER_ID,
                                                            CATEGORY_ID,
                                                            VALUE,
                                                            VOLUME,
                                                            CREATED_BY,
                                                            CREATION_DATE,
                                                            LAST_UPDATE_BY,
                                                            LAST_UPDATE_DATE)
            SELECT   NEW_HDRID,
                     INSURER_ID,
                     CATEGORY_ID,
                     VALUE,
                     VOLUME,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE
              FROM   EPAY.EPAY_PSB2_INSURANCE_UNDERWRITERS
             WHERE   PSB_HDR_ID = OLD_HDRID;

         INSERT INTO EPAY.EPAY_PSB2_INTEREST_DISBURSEMENT_CRITERIA (PSB_HDR_ID,
                                                                    CRITERIA,
                                                                    CREATED_BY,
                                                                    CREATION_DATE,
                                                                    LAST_UPDATE_BY,
                                                                    LAST_UPDATE_DATE,
                                                                    CATEGORY_ID)
            SELECT   NEW_HDRID,
                     CRITERIA,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE,
                     CATEGORY_ID
              FROM   EPAY.EPAY_PSB2_INTEREST_DISBURSEMENT_CRITERIA
             WHERE   PSB_HDR_ID = OLD_HDRID;
      ELSIF :OLD.PSB_TYPE_ID = 3
      THEN
         INSERT INTO EPAY.EPAY_PSB3_TRNS (INDICATOR_ID,
                                          PSB_HDR_ID,
                                          GAR_VOLUME,
                                          GAR_VALUE,
                                          ER_VOLUME,
                                          ER_VALUE,
                                          CR_VOLUME,
                                          CR_VALUE,
                                          WR_VOLUME,
                                          WR_VALUE,
                                          VR_VOLUME,
                                          VR_VALUE,
                                          AR_VOLUME,
                                          AR_VALUE,
                                          BAR_VOLUME,
                                          BAR_VALUE,
                                          NR_VOLUME,
                                          NR_VALUE,
                                          UER_VOLUME,
                                          UER_VALUE,
                                          UWR_VOLUME,
                                          UWR_VALUE,
                                          CREATED_BY,
                                          CREATION_DATE,
                                          LAST_UPDATE_BY,
                                          LAST_UPDATE_DATE,
                                          INDICATOR_DETAILS)
            SELECT   INDICATOR_ID,
                     NEW_HDRID,
                     GAR_VOLUME,
                     GAR_VALUE,
                     ER_VOLUME,
                     ER_VALUE,
                     CR_VOLUME,
                     CR_VALUE,
                     WR_VOLUME,
                     WR_VALUE,
                     VR_VOLUME,
                     VR_VALUE,
                     AR_VOLUME,
                     AR_VALUE,
                     BAR_VOLUME,
                     BAR_VALUE,
                     NR_VOLUME,
                     NR_VALUE,
                     UER_VOLUME,
                     UER_VALUE,
                     UWR_VOLUME,
                     UWR_VALUE,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE,
                     INDICATOR_DETAILS
              FROM   EPAY.EPAY_PSB3_TRNS
             WHERE   PSB_HDR_ID = OLD_HDRID;
      ELSIF :OLD.PSB_TYPE_ID = 4
      THEN
         INSERT INTO EPAY.EPAY_PSB4_TRNS (INCIDENT_TYPE_ID,
                                          DATE_OF_OCCURENCE,
                                          DATE_DETECTED,
                                          DATE_REPORTED,
                                          AMOUNT_INVOLVED,
                                          AMOUNT_LOST,
                                          AMOUNT_RECOVERED,
                                          CREATED_BY,
                                          CREATION_DATE,
                                          LAST_UPDATE_BY,
                                          LAST_UPDATE_DATE,
                                          ACTIVITY_INVOLVED_ID,
                                          PSB_HDR_ID,
                                          REMEDIAL_ACTION_TAKEN,
                                          OLD_INCIDENT_ID)
            SELECT   INCIDENT_TYPE_ID,
                     DATE_OF_OCCURENCE,
                     DATE_DETECTED,
                     DATE_REPORTED,
                     AMOUNT_INVOLVED,
                     AMOUNT_LOST,
                     AMOUNT_RECOVERED,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE,
                     ACTIVITY_INVOLVED_ID,
                     NEW_HDRID,
                     REMEDIAL_ACTION_TAKEN,
                     INCIDENT_ID
              FROM   EPAY.EPAY_PSB4_TRNS
             WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
      ELSIF :OLD.PSB_TYPE_ID = 5
      THEN
         INSERT INTO EPAY.EPAY_PSB5_TRNS (COMPLAINT_TYPE_ID,
                                          FEMALE_COMPLAINANTS_NO,
                                          COMPLAINTS_RCVD_RPTMNT,
                                          COMPLAINTS_RSLVD_RPTMNT,
                                          UNRESOLVED_COMPLAINTS_EOM,
                                          PSB_HDR_ID,
                                          CREATED_BY,
                                          CREATION_DATE,
                                          LAST_UPDATE_BY,
                                          LAST_UPDATE_DATE)
            SELECT   COMPLAINT_TYPE_ID,
                     FEMALE_COMPLAINANTS_NO,
                     COMPLAINTS_RCVD_RPTMNT,
                     COMPLAINTS_RSLVD_RPTMNT,
                     UNRESOLVED_COMPLAINTS_EOM,
                     NEW_HDRID,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE
              FROM   EPAY.EPAY_PSB5_TRNS
             WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
      ELSIF :OLD.PSB_TYPE_ID = 6
      THEN
         INSERT INTO EPAY.EPAY_PSB6_TRNS (INTERRUPTION_NATURE_ID,
                                          PSB_HDR_ID,
                                          START_DATE,
                                          START_TIME,
                                          END_DATE,
                                          END_TIME,
                                          CORRECTIVE_ACTION_TAKEN_ID,
                                          CREATED_BY,
                                          CREATION_DATE,
                                          LAST_UPDATE_BY,
                                          LAST_UPDATE_DATE)
            SELECT   INTERRUPTION_NATURE_ID,
                     NEW_HDRID,
                     START_DATE,
                     START_TIME,
                     END_DATE,
                     END_TIME,
                     CORRECTIVE_ACTION_TAKEN_ID,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE
              FROM   EPAY.EPAY_PSB6_TRNS
             WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
      ELSIF :OLD.PSB_TYPE_ID = 7
      THEN
         INSERT INTO EPAY.EPAY_PSB7_TRNS (SUSPTRNS_TYPE_ID,
                                          DATE_OF_OCCURENCE,
                                          DATE_DETECTED,
                                          DATE_REPORTED,
                                          AMOUNT_INVOLVED,
                                          TIME_OF_OCCURENCE,
                                          PSB_HDR_ID,
                                          REMEDIAL_ACTION_TAKEN,
                                          CREATED_BY,
                                          CREATION_DATE,
                                          LAST_UPDATE_BY,
                                          LAST_UPDATE_DATE,
                                          OLD_SUSPTRNS_ID)
            SELECT   SUSPTRNS_TYPE_ID,
                     DATE_OF_OCCURENCE,
                     DATE_DETECTED,
                     DATE_REPORTED,
                     AMOUNT_INVOLVED,
                     TIME_OF_OCCURENCE,
                     NEW_HDRID,
                     REMEDIAL_ACTION_TAKEN,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE,
                     SUSPTRNS_ID
              FROM   EPAY.EPAY_PSB7_TRNS
             WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
      ELSIF :OLD.PSB_TYPE_ID = 81
      THEN
         INSERT INTO EPAY.EPAY_PSB8_MINTIER_TRNS (CUSTOMER_NAME,
                                                  MOBILE_NUMBER,
                                                  OUTSTANDING_BALANCE,
                                                  PSB_HDR_ID,
                                                  CREATED_BY,
                                                  CREATION_DATE,
                                                  LAST_UPDATE_BY,
                                                  LAST_UPDATE_DATE)
            SELECT   CUSTOMER_NAME,
                     MOBILE_NUMBER,
                     OUTSTANDING_BALANCE,
                     NEW_HDRID,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE
              FROM   EPAY.EPAY_PSB8_MINTIER_TRNS
             WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
      ELSIF :OLD.PSB_TYPE_ID = 82
      THEN
         INSERT INTO EPAY.EPAY_PSB8_MEDTIER_TRNS (CUSTOMER_NAME,
                                                  MOBILE_NUMBER,
                                                  OUTSTANDING_BALANCE,
                                                  PSB_HDR_ID,
                                                  CREATED_BY,
                                                  CREATION_DATE,
                                                  LAST_UPDATE_BY,
                                                  LAST_UPDATE_DATE)
            SELECT   CUSTOMER_NAME,
                     MOBILE_NUMBER,
                     OUTSTANDING_BALANCE,
                     NEW_HDRID,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE
              FROM   EPAY.EPAY_PSB8_MEDTIER_TRNS
             WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
      ELSIF :OLD.PSB_TYPE_ID = 83
      THEN
         INSERT INTO EPAY.EPAY_PSB8_EHNTIER_TRNS (CUSTOMER_NAME,
                                                  MOBILE_NUMBER,
                                                  OUTSTANDING_BALANCE,
                                                  PSB_HDR_ID,
                                                  CREATED_BY,
                                                  CREATION_DATE,
                                                  LAST_UPDATE_BY,
                                                  LAST_UPDATE_DATE)
            SELECT   CUSTOMER_NAME,
                     MOBILE_NUMBER,
                     OUTSTANDING_BALANCE,
                     NEW_HDRID,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE
              FROM   EPAY.EPAY_PSB8_EHNTIER_TRNS
             WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
      ELSIF :OLD.PSB_TYPE_ID = 11
      THEN
         INSERT INTO EPAY.EPAY_PSB9_TRNS (CATIND_ID,
                                          PSB_HDR_ID,
                                          CREATED_BY,
                                          CREATION_DATE,
                                          LAST_UPDATE_BY,
                                          LAST_UPDATE_DATE,
                                          OLD_TRANSACTIONS_ID)
            SELECT   CATIND_ID,
                     NEW_HDRID,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE,
                     TRANSACTIONS_ID
              FROM   EPAY.EPAY_PSB9_TRNS
             WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
      ELSIF :OLD.PSB_TYPE_ID = 10
      THEN
         INSERT INTO EPAY.EPAY_PSB10_CARD_FEES_HDR (PSB_HDR_ID,
                                                    PRODUCT_ID,
                                                    INTERCHANGE_FEE_TO_ISSUER,
                                                    CREATED_BY,
                                                    CREATION_DATE,
                                                    LAST_UPDATE_BY,
                                                    LAST_UPDATE_DATE,
                                                    OLD_CARD_FEE_HDR_ID,
                                                    TRANSACTION_CHANNEL_ID,
                                                    FEE_TYPE_ID,
                                                    IS_DATA_SRC_COPY)
            SELECT   NEW_HDRID,
                     PRODUCT_ID,
                     INTERCHANGE_FEE_TO_ISSUER,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE,
                     CARD_FEE_HDR_ID,
                     TRANSACTION_CHANNEL_ID,
                     FEE_TYPE_ID,
                     IS_DATA_SRC_COPY
              FROM   EPAY.EPAY_PSB10_CARD_FEES_HDR
             WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
      ELSIF :OLD.PSB_TYPE_ID = 14
      THEN
         INSERT INTO EPAY.EPAY_PSB11_BANKS_HDR (BNK_ID,
                                                PSB_HDR_ID,
                                                CREATED_BY,
                                                CREATION_DATE,
                                                LAST_UPDATE_BY,
                                                LAST_UPDATE_DATE,
                                                OLD_ROW_ID)
            SELECT   BNK_ID,
                     NEW_HDRID,
                     CREATED_BY,
                     DTE,
                     LAST_UPDATE_BY,
                     DTE,
                     ROW_ID
              FROM   EPAY.EPAY_PSB11_BANKS_HDR
             WHERE   PSB_HDR_ID = :OLD.PSB_HDR_ID;
      END IF;
   END IF;
END DUPLICATE_PSBHDR_WDRWLTRNS_TRG;

CREATE OR REPLACE TRIGGER EPAY.INS_PSB1INDICATOR_TRNS_TRG
   AFTER INSERT
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   IA   NUMBER;
BEGIN
   IF :NEW.APPRVR_STATUS = 'Incomplete'
   THEN
      FOR I
      IN (SELECT   DISTINCT CATIND_ID
            FROM   EPAY.EPAY_CATEGORY_INDICATORS ECI, EPAY.EPAY_CATEGORIES EC
           WHERE   ECI.CATEGORY_ID = EC.CATEGORY_ID AND EC.PSB_TYPE_ID = 1)
      LOOP
         INSERT INTO EPAY.EPAY_PSB1_TRNS (CATIND_ID,
                                          PSB_HDR_ID,
                                          CREATED_BY,
                                          CREATION_DATE,
                                          LAST_UPDATE_BY,
                                          LAST_UPDATE_DATE)
           VALUES   (I.CATIND_ID,
                     :NEW.PSB_HDR_ID,
                     :NEW.CREATED_BY,
                     :NEW.CREATION_DATE,
                     :NEW.LAST_UPDATE_BY,
                     :NEW.LAST_UPDATE_DATE);
      END LOOP;
   END IF;
END INS_PSB1INDICATOR_TRNS_TRG;

CREATE OR REPLACE TRIGGER EPAY.INS_PSB2INDICATOR_TRNS_TRG
   AFTER INSERT
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   IA   NUMBER;
BEGIN
   IF :NEW.APPRVR_STATUS = 'Incomplete'
   THEN
      FOR I
      IN (SELECT   DISTINCT CATIND_ID
            FROM   EPAY.EPAY_CATEGORY_INDICATORS ECI, EPAY.EPAY_CATEGORIES EC
           WHERE   ECI.CATEGORY_ID = EC.CATEGORY_ID AND EC.PSB_TYPE_ID = 2)
      LOOP
         INSERT INTO EPAY.EPAY_PSB2_TRNS (CATIND_ID,
                                          PSB_HDR_ID,
                                          CREATED_BY,
                                          CREATION_DATE,
                                          LAST_UPDATE_BY,
                                          LAST_UPDATE_DATE)
           VALUES   (I.CATIND_ID,
                     :NEW.PSB_HDR_ID,
                     :NEW.CREATED_BY,
                     :NEW.CREATION_DATE,
                     :NEW.LAST_UPDATE_BY,
                     :NEW.LAST_UPDATE_DATE);
      END LOOP;
   END IF;
END INS_PSB2INDICATOR_TRNS_TRG;

CREATE OR REPLACE TRIGGER EPAY.INS_PSB3INDICATOR_TRNS_TRG
   AFTER INSERT
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   IA   NUMBER;
BEGIN
   IF :NEW.APPRVR_STATUS = 'Incomplete'
   THEN
      FOR I IN (SELECT   INDICATOR_ID
                  FROM   EPAY.EPAY_INDICATOR
                 WHERE   CATEGORY_ID IN (1))
      LOOP
         INSERT INTO EPAY.EPAY_PSB3_TRNS (INDICATOR_ID,
                                          PSB_HDR_ID,
                                          CREATED_BY,
                                          CREATION_DATE,
                                          LAST_UPDATE_BY,
                                          LAST_UPDATE_DATE)
           VALUES   (I.INDICATOR_ID,
                     :NEW.PSB_HDR_ID,
                     :NEW.CREATED_BY,
                     :NEW.CREATION_DATE,
                     :NEW.LAST_UPDATE_BY,
                     :NEW.LAST_UPDATE_DATE);
      END LOOP;
   END IF;

   RETURN;
END INS_PSB3INDICATOR_TRNS_TRG;

CREATE OR REPLACE TRIGGER EPAY.INS_PSB9INDICATOR_TRNS_TRG
   AFTER INSERT
   ON EPAY.EPAY_PSB_HDR
   FOR EACH ROW
DECLARE
   IA   NUMBER;
BEGIN
   IF :NEW.APPRVR_STATUS = 'Incomplete'
   THEN
      FOR I
      IN (SELECT   DISTINCT CATIND_ID
            FROM   EPAY.EPAY_CATEGORY_INDICATORS ECI, EPAY.EPAY_CATEGORIES EC
           WHERE   ECI.CATEGORY_ID = EC.CATEGORY_ID AND EC.PSB_TYPE_ID = 11)
      LOOP
         INSERT INTO EPAY.EPAY_PSB9_TRNS (CATIND_ID,
                                          PSB_HDR_ID,
                                          CREATED_BY,
                                          CREATION_DATE,
                                          LAST_UPDATE_BY,
                                          LAST_UPDATE_DATE)
           VALUES   (I.CATIND_ID,
                     :NEW.PSB_HDR_ID,
                     :NEW.CREATED_BY,
                     :NEW.CREATION_DATE,
                     :NEW.LAST_UPDATE_BY,
                     :NEW.LAST_UPDATE_DATE);
      END LOOP;
   END IF;
END INS_PSB9INDICATOR_TRNS_TRG;