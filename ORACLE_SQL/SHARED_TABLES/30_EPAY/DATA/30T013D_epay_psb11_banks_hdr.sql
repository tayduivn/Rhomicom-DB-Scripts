/* Formatted on 12-19-2018 8:26:18 AM (QP5 v5.126.903.23003) */
DROP TABLE EPAY.EPAY_PSB11_BANKS_HDR CASCADE CONSTRAINTS PURGE;

CREATE TABLE EPAY.EPAY_PSB11_BANKS_HDR (
   ROW_ID             NUMBER NOT NULL,
   BNK_ID             NUMBER,
   PSB_HDR_ID         NUMBER,
   CREATED_BY         NUMBER,
   CREATION_DATE      VARCHAR2 (21),
   LAST_UPDATE_BY     NUMBER,
   LAST_UPDATE_DATE   VARCHAR2 (21),
   OLD_ROW_ID         NUMBER,
   CONSTRAINT PK_ROW_ID PRIMARY KEY (ROW_ID)
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

DROP SEQUENCE EPAY.EPAY_PSB11_BANKS_HDR_SEQ;

CREATE SEQUENCE EPAY.EPAY_PSB11_BANKS_HDR_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER EPAY.EPAY_PSB11_BANKS_HDR_TRG
   BEFORE INSERT
   ON EPAY.EPAY_PSB11_BANKS_HDR
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.ROW_ID IS NULL)
DECLARE
   V_ID   EPAY.EPAY_PSB11_BANKS_HDR.ROW_ID%TYPE;
BEGIN
   SELECT   EPAY.EPAY_PSB11_BANKS_HDR_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.ROW_ID := V_ID;
END EPAY_PSB11_BANKS_HDR_TRG;





CREATE OR REPLACE TRIGGER EPAY.INS_PSB11INDICATOR_TRNS_TRG
   AFTER INSERT
   ON EPAY.EPAY_PSB11_BANKS_HDR
   FOR EACH ROW
DECLARE
   IA   NUMBER;
BEGIN
   FOR I
   IN (SELECT   DISTINCT CATIND_ID
         FROM   EPAY.EPAY_CATEGORY_INDICATORS ECI, EPAY.EPAY_CATEGORIES EC
        WHERE   ECI.CATEGORY_ID = EC.CATEGORY_ID AND EC.PSB_TYPE_ID = 14)
   LOOP
      INSERT INTO EPAY.EPAY_PSB11_TRUST_ACCBAL_TRNS (CATIND_ID,
                                                     PSB_HDR_ID,
                                                     CREATED_BY,
                                                     CREATION_DATE,
                                                     LAST_UPDATE_BY,
                                                     LAST_UPDATE_DATE,
                                                     ROW_ID)
        VALUES   (I.CATIND_ID,
                  :NEW.PSB_HDR_ID,
                  :NEW.CREATED_BY,
                  :NEW.CREATION_DATE,
                  :NEW.LAST_UPDATE_BY,
                  :NEW.LAST_UPDATE_DATE,
                  :NEW.ROW_ID);
   END LOOP;

   RETURN;
END INS_PSB11INDICATOR_TRNS_TRG;



CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB11DET_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB11_BANKS_HDR
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB11_TRUST_ACCBAL_TRNS
         WHERE   ROW_ID = :OLD.ROW_ID;

   DELETE FROM   EPAY.EPAY_PSB11_RECON_ITEMS
         WHERE   ROW_ID = :OLD.ROW_ID;
END DELETE_PSB11DET_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DUPLICATE_PSB11DET_TRNS_TRG
   AFTER INSERT
   ON EPAY.EPAY_PSB11_BANKS_HDR
   FOR EACH ROW
DECLARE
   DTE                 VARCHAR2 (21);
   HDR_APPRVR_STATUS   VARCHAR2 (100);
BEGIN
   IF :NEW.OLD_ROW_ID > 0
   THEN
      /*GET DATE*/
      SELECT   TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS') INTO DTE FROM DUAL;

      INSERT INTO EPAY.EPAY_PSB11_TRUST_ACCBAL_TRNS (CATIND_ID,
                                                     PSB_HDR_ID,
                                                     CREATED_BY,
                                                     CREATION_DATE,
                                                     LAST_UPDATE_BY,
                                                     LAST_UPDATE_DATE,
                                                     AMOUNT,
                                                     ROW_ID)
         SELECT   CATIND_ID,
                  PSB_HDR_ID,
                  CREATED_BY,
                  DTE,
                  LAST_UPDATE_BY,
                  DTE,
                  AMOUNT,
                  :NEW.ROW_ID
           FROM   EPAY.EPAY_PSB11_TRUST_ACCBAL_TRNS
          WHERE   ROW_ID = :NEW.OLD_ROW_ID;

      INSERT INTO EPAY.EPAY_PSB11_RECON_ITEMS (PSB_HDR_ID,
                                               CATEGORY_ID,
                                               ITEM_DATE,
                                               ITEM_DESC,
                                               ITEM_AMOUNT,
                                               CREATED_BY,
                                               CREATION_DATE,
                                               LAST_UPDATE_BY,
                                               LAST_UPDATE_DATE,
                                               ROW_ID)
         SELECT   PSB_HDR_ID,
                  CATEGORY_ID,
                  ITEM_DATE,
                  ITEM_DESC,
                  ITEM_AMOUNT,
                  CREATED_BY,
                  DTE,
                  LAST_UPDATE_BY,
                  DTE,
                  :NEW.ROW_ID
           FROM   EPAY.EPAY_PSB11_RECON_ITEMS
          WHERE   ROW_ID = :NEW.OLD_ROW_ID;
   END IF;
END DUPLICATE_PSB11DET_TRNS_TRG;
