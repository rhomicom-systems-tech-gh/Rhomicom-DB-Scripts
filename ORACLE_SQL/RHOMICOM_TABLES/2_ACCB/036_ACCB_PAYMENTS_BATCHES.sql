/* Formatted on 9/22/2014 4:37:39 PM (QP5 v5.126.903.23003) */
-- TABLE: ACCB.ACCB_PAYMENTS_BATCHES

-- DROP TABLE ACCB.ACCB_PAYMENTS_BATCHES;

CREATE TABLE ACCB.ACCB_PAYMENTS_BATCHES (
   PYMNT_BATCH_ID       NUMBER NOT NULL,
   PYMNT_BATCH_NAME     VARCHAR2 (200),
   PYMNT_BATCH_DESC     VARCHAR2 (300),
   PYMNT_MTHD_ID        NUMBER,
   DOC_TYPE             VARCHAR2 (200),
   DOC_CLSFCTN          VARCHAR2 (200),
   DOCS_START_DATE      VARCHAR2 (21),
   DOCS_END_DATE        VARCHAR2 (21),
   BATCH_STATUS         VARCHAR2 (100),
   BATCH_SOURCE         VARCHAR2 (200),
   CREATED_BY           NUMBER DEFAULT (-1) NOT NULL,
   CREATION_DATE        VARCHAR2 (21) NOT NULL,
   LAST_UPDATE_BY       NUMBER NOT NULL,
   LAST_UPDATE_DATE     VARCHAR2 (21),
   BATCH_VLDTY_STATUS   VARCHAR2 (20),
   ORGNL_BATCH_ID       NUMBER,
   ORG_ID               NUMBER,
   CUST_SPPLR_ID        NUMBER,
   CONSTRAINT PK_PYMNT_BATCH_ID PRIMARY KEY (PYMNT_BATCH_ID)
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

CREATE INDEX ACCB.IDX_BATCH_SOURCE1
   ON ACCB.ACCB_PAYMENTS_BATCHES (BATCH_SOURCE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_BATCH_STATUS1
   ON ACCB.ACCB_PAYMENTS_BATCHES (BATCH_STATUS)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_BATCH_VLDTY_STATUS
   ON ACCB.ACCB_PAYMENTS_BATCHES (BATCH_VLDTY_STATUS)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_CUST_SPPLR_ID
   ON ACCB.ACCB_PAYMENTS_BATCHES (CUST_SPPLR_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_DOC_CLSFCTN
   ON ACCB.ACCB_PAYMENTS_BATCHES (DOC_CLSFCTN)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_DOC_TYPE1
   ON ACCB.ACCB_PAYMENTS_BATCHES (DOC_TYPE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_DOCS_END_DATE
   ON ACCB.ACCB_PAYMENTS_BATCHES (DOCS_END_DATE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_DOCS_START_DATE
   ON ACCB.ACCB_PAYMENTS_BATCHES (DOCS_START_DATE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_ORG_ID
   ON ACCB.ACCB_PAYMENTS_BATCHES (ORG_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_ORGNL_BATCH_ID
   ON ACCB.ACCB_PAYMENTS_BATCHES (ORGNL_BATCH_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_PYMNT_BATCH_NAME
   ON ACCB.ACCB_PAYMENTS_BATCHES (PYMNT_BATCH_NAME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_PYMNT_MTHD_ID
   ON ACCB.ACCB_PAYMENTS_BATCHES (PYMNT_MTHD_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;


CREATE SEQUENCE ACCB.ACCB_PAYMENTS_BATCHES_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER ACCB.ACCB_PAYMENTS_BATCHES_TRG
   BEFORE INSERT
   ON ACCB.ACCB_PAYMENTS_BATCHES
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.PYMNT_BATCH_ID IS NULL)
DECLARE
   V_ID   ACCB.ACCB_PAYMENTS_BATCHES.PYMNT_BATCH_ID%TYPE;
BEGIN
   SELECT   ACCB.ACCB_PAYMENTS_BATCHES_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.PYMNT_BATCH_ID := V_ID;
END ACCB_PAYMENTS_BATCHES_TRG;