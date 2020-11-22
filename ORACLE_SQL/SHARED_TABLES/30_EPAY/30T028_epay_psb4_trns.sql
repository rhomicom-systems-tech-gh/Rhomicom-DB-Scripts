/* Formatted on 12-19-2018 8:39:11 AM (QP5 v5.126.903.23003) */
DROP TABLE EPAY.EPAY_PSB4_TRNS CASCADE CONSTRAINTS PURGE;

CREATE TABLE EPAY.EPAY_PSB4_TRNS (
   INCIDENT_ID             NUMBER NOT NULL,
   INCIDENT_TYPE_ID        NUMBER,
   DATE_OF_OCCURENCE       VARCHAR2 (21),
   DATE_DETECTED           VARCHAR2 (21),
   DATE_REPORTED           VARCHAR2 (21),
   AMOUNT_INVOLVED         NUMBER,
   AMOUNT_LOST             NUMBER,
   AMOUNT_RECOVERED        NUMBER,
   CREATED_BY              NUMBER,
   CREATION_DATE           VARCHAR2 (21),
   LAST_UPDATE_BY          NUMBER,
   LAST_UPDATE_DATE        VARCHAR2 (21),
   ACTIVITY_INVOLVED_ID    NUMBER,
   PSB_HDR_ID              NUMBER,
   REMEDIAL_ACTION_TAKEN   NUMBER,
   OLD_INCIDENT_ID         NUMBER DEFAULT -1 NOT NULL, -- INCIDENT ID OF WITHDRAWN EPAY_PSB4_TRNS HDR
   COMMENTS                CLOB,
   CONSTRAINT PK_INCDNT_ID PRIMARY KEY (INCIDENT_ID)
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

COMMENT ON COLUMN EPAY.EPAY_PSB4_TRNS.OLD_INCIDENT_ID IS
'Incident Id of withdrawn epay_psb4_trns hdr';

DROP SEQUENCE EPAY.EPAY_PSB4_TRNS_SEQ;

CREATE SEQUENCE EPAY.EPAY_PSB4_TRNS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER EPAY.EPAY_PSB4_TRNS_TRG
   BEFORE INSERT
   ON EPAY.EPAY_PSB4_TRNS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.INCIDENT_ID IS NULL)
DECLARE
   V_ID   EPAY.EPAY_PSB4_TRNS.INCIDENT_ID%TYPE;
BEGIN
   SELECT   EPAY.EPAY_PSB4_TRNS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.INCIDENT_ID := V_ID;
END EPAY_PSB4_TRNS_TRG;


CREATE OR REPLACE TRIGGER EPAY.DELETE_PSB4_FRAUD_PRS_INST_TRNS_TRG
   BEFORE DELETE
   ON EPAY.EPAY_PSB4_TRNS
   FOR EACH ROW
DECLARE
   I   NUMBER;
BEGIN
   DELETE FROM   EPAY.EPAY_PSB4_FRAUD_PRS_INST
         WHERE   INCIDENT_ID = :OLD.INCIDENT_ID;
END DELETE_PSB4_FRAUD_PRS_INST_TRNS_TRG;

CREATE OR REPLACE TRIGGER EPAY.DUPLICATE_PSB4INCDNT_PRSINST_TRG
   AFTER INSERT
   ON EPAY.EPAY_PSB4_TRNS
   FOR EACH ROW
DECLARE
   DTE                 VARCHAR2 (21);
   HDR_APPRVR_STATUS   VARCHAR2 (100);
BEGIN
   IF :NEW.OLD_INCIDENT_ID > 0
   THEN
      /*GET DATE*/
      SELECT   TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS') INTO DTE FROM DUAL;

      INSERT INTO EPAY.EPAY_PSB4_FRAUD_PRS_INST (PRS_INST_TYPE_ID,
                                                 PRS_INST_NAME,
                                                 PERSONAL_ID_TYPE_ID,
                                                 PERSONAL_ID_NUMBER,
                                                 APPRHNSN_CHRG_STATUS,
                                                 CREATED_BY,
                                                 CREATION_DATE,
                                                 LAST_UPDATE_BY,
                                                 LAST_UPDATE_DATE,
                                                 INCIDENT_ID)
         SELECT   PRS_INST_TYPE_ID,
                  PRS_INST_NAME,
                  PERSONAL_ID_TYPE_ID,
                  PERSONAL_ID_NUMBER,
                  APPRHNSN_CHRG_STATUS,
                  CREATED_BY,
                  DTE,
                  LAST_UPDATE_BY,
                  DTE,
                  :NEW.INCIDENT_ID
           FROM   EPAY.EPAY_PSB4_FRAUD_PRS_INST
          WHERE   INCIDENT_ID = :NEW.OLD_INCIDENT_ID;
   END IF;
END DUPLICATE_PSB4INCDNT_PRSINST_TRG;