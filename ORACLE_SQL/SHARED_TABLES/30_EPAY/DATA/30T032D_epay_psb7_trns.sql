/* Formatted on 12-19-2018 8:48:29 AM (QP5 v5.126.903.23003) */
DROP TABLE EPAY.EPAY_PSB7_TRNS CASCADE CONSTRAINTS PURGE;

CREATE TABLE EPAY.EPAY_PSB7_TRNS (
   SUSPTRNS_ID                     NUMBER NOT NULL,
   SUSPTRNS_TYPE_ID                NUMBER,
   DATE_OF_OCCURENCE               VARCHAR2 (21),
   DATE_DETECTED                   VARCHAR2 (21),
   DATE_REPORTED                   VARCHAR2 (21),
   AMOUNT_INVOLVED                 NUMERIC,
   TIME_OF_OCCURENCE               VARCHAR2 (21),
   PSB_HDR_ID                      NUMBER,
   REMEDIAL_ACTION_TAKEN           NUMBER,
   CREATED_BY                      NUMBER,
   CREATION_DATE                   VARCHAR2 (21),
   LAST_UPDATE_BY                  NUMBER,
   LAST_UPDATE_DATE                VARCHAR2 (21),
   OLD_SUSPTRNS_ID                 NUMBER DEFAULT -1 NOT NULL,
   -- SUSPTRNS_ID FOR EPAY_PSB7_TRNS WITHDRAWAL
   REPORTED_TO_SECURITY_AGENCIES   VARCHAR2 (3),
   CONSTRAINT PK_SUSPTRNS_ID PRIMARY KEY (SUSPTRNS_ID)
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

COMMENT ON COLUMN EPAY.EPAY_PSB7_TRNS.OLD_SUSPTRNS_ID IS
'susptrns_id for epay_psb7_trns withdrawal';

DROP SEQUENCE EPAY.EPAY_PSB7_TRNS_SEQ;

CREATE SEQUENCE EPAY.EPAY_PSB7_TRNS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER EPAY.EPAY_PSB7_TRNS_TRG
   BEFORE INSERT
   ON EPAY.EPAY_PSB7_TRNS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.SUSPTRNS_ID IS NULL)
DECLARE
   V_ID   EPAY.EPAY_PSB7_TRNS.SUSPTRNS_ID%TYPE;
BEGIN
   SELECT   EPAY.EPAY_PSB7_TRNS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.SUSPTRNS_ID := V_ID;
END EPAY_PSB7_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB7_SUSPTRNS_PRS_INST_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB7_TRNS
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB7_SUSPTRNS_PRS_INST
         WHERE   SUSPTRNS_ID = :OLD.SUSPTRNS_ID;
END DELETE_PSB7_SUSPTRNS_PRS_INST_TRNS_TRG;

CREATE OR REPLACE TRIGGER EPAY.DUPLICATE_PSB7SUSPTRNS_PRSINST_TRG
   AFTER INSERT
   ON EPAY.EPAY_PSB7_TRNS
   FOR EACH ROW
DECLARE
   DTE                 VARCHAR2 (21);
   HDR_APPRVR_STATUS   VARCHAR2 (100);
BEGIN
   IF :NEW.OLD_SUSPTRNS_ID > 0
   THEN
      /*GET DATE*/
      SELECT   TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS') INTO DTE FROM DUAL;

      INSERT INTO EPAY.EPAY_PSB7_SUSPTRNS_PRS_INST (PRS_INST_TYPE_ID,
                                                    PRS_INST_NAME,
                                                    PERSONAL_ID_TYPE_ID,
                                                    PERSONAL_ID_NUMBER,
                                                    APPRHNSN_CHRG_STATUS,
                                                    CREATED_BY,
                                                    CREATION_DATE,
                                                    LAST_UPDATE_BY,
                                                    LAST_UPDATE_DATE,
                                                    SUSPTRNS_ID)
         SELECT   PRS_INST_TYPE_ID,
                  PRS_INST_NAME,
                  PERSONAL_ID_TYPE_ID,
                  PERSONAL_ID_NUMBER,
                  APPRHNSN_CHRG_STATUS,
                  CREATED_BY,
                  DTE,
                  LAST_UPDATE_BY,
                  DTE,
                  :NEW.SUSPTRNS_ID
           FROM   EPAY.EPAY_PSB7_SUSPTRNS_PRS_INST
          WHERE   SUSPTRNS_ID = :NEW.OLD_SUSPTRNS_ID;
   END IF;
END DUPLICATE_PSB7SUSPTRNS_PRSINST_TRG;