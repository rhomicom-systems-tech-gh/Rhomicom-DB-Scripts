/* Formatted on 9/22/2014 12:45:54 PM (QP5 v5.126.903.23003) */
-- TABLE: ACCB.ACCB_BATCH_TRNS_ATTCHMNTS

-- DROP TABLE ACCB.ACCB_BATCH_TRNS_ATTCHMNTS;

CREATE TABLE ACCB.ACCB_BATCH_TRNS_ATTCHMNTS (
   ATTCHMNT_ID        NUMBER NOT NULL,
   BATCH_ID           NUMBER NOT NULL,
   ATTCHMNT_DESC      VARCHAR2 (500 BYTE) NOT NULL,
   FILE_NAME          VARCHAR2 (50 BYTE) NOT NULL,
   CREATED_BY         NUMBER NOT NULL,
   CREATION_DATE      VARCHAR2 (21 BYTE) NOT NULL,
   LAST_UPDATE_BY     NUMBER NOT NULL,
   LAST_UPDATE_DATE   VARCHAR2 (21 BYTE) NOT NULL,
   CONSTRAINT PK_ATTCHMNT_ID PRIMARY KEY (ATTCHMNT_ID)
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

CREATE INDEX ACCB.IDX_ATTCHMNT_DESC
   ON ACCB.ACCB_BATCH_TRNS_ATTCHMNTS (ATTCHMNT_DESC)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_ATTCHMT_BATCH_ID
   ON ACCB.ACCB_BATCH_TRNS_ATTCHMNTS (BATCH_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE SEQUENCE ACCB.ACCB_BATCH_TRNS_ATTCHMNTS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER ACCB.ACCB_BATCH_TRNS_ATTCHMNTS_TRG
   BEFORE INSERT
   ON ACCB.ACCB_BATCH_TRNS_ATTCHMNTS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.ATTCHMNT_ID IS NULL)
DECLARE
   V_ID   ACCB.ACCB_BATCH_TRNS_ATTCHMNTS.ATTCHMNT_ID%TYPE;
BEGIN
   SELECT   ACCB.ACCB_BATCH_TRNS_ATTCHMNTS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.ATTCHMNT_ID := V_ID;
END ACCB_BATCH_TRNS_ATTCHMNTS_TRG;