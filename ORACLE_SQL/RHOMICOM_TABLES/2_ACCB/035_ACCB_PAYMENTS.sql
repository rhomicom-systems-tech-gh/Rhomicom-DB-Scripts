/* Formatted on 9/22/2014 4:16:31 PM (QP5 v5.126.903.23003) */
-- TABLE: ACCB.ACCB_PAYMENTS

-- DROP TABLE ACCB.ACCB_PAYMENTS;

CREATE TABLE ACCB.ACCB_PAYMENTS (
   PYMNT_ID                 NUMBER NOT NULL,
   PYMNT_MTHD_ID            NUMBER,
   AMOUNT_PAID              NUMBER,
   CHANGE_OR_BALANCE        NUMBER,
   PYMNT_REMARK             VARCHAR2 (300),
   SRC_DOC_TYP              VARCHAR2 (100),
   SRC_DOC_ID               NUMBER NOT NULL,
   CREATED_BY               NUMBER,
   CREATION_DATE            VARCHAR2 (21),
   LAST_UPDATE_BY           NUMBER,
   LAST_UPDATE_DA0TE        VARCHAR2 (21),
   PYMNT_DATE               VARCHAR2 (21) NOT NULL,
   INCRS_DCRS1              VARCHAR2 (1),
   RCVBL_LBLTY_ACCNT_ID     NUMBER,
   INCRS_DCRS2              VARCHAR2 (1),
   CASH_OR_SUSPNS_ACNT_ID   NUMBER,
   GL_BATCH_ID              NUMBER DEFAULT -1 NOT NULL,
   ORGNL_PYMNT_ID           NUMBER,
   PYMNT_VLDTY_STATUS       VARCHAR2 (20),
   ENTRD_CURR_ID            NUMBER,
   FUNC_CURR_ID             NUMBER,
   ACCNT_CURR_ID            NUMBER,
   FUNC_CURR_RATE           NUMBER,
   ACCNT_CURR_RATE          NUMBER,
   FUNC_CURR_AMOUNT         NUMBER,
   ACCNT_CURR_AMNT          NUMBER,
   PYMNT_BATCH_ID           NUMBER,
   CONSTRAINT PK_PYMNT_ID PRIMARY KEY (PYMNT_ID)
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

CREATE INDEX ACCB.IDX_DATE_RCVD
   ON ACCB.ACCB_PAYMENTS (PYMNT_DATE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_PY_CREATED_BY
   ON ACCB.ACCB_PAYMENTS (CREATED_BY)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_PY_LAST_UPDATE_BY
   ON ACCB.ACCB_PAYMENTS (LAST_UPDATE_BY)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_PY_SRC_DOC_ID
   ON ACCB.ACCB_PAYMENTS (SRC_DOC_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_PY_SRC_DOC_TYP
   ON ACCB.ACCB_PAYMENTS (SRC_DOC_TYP)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_PYMNT_REMARK
   ON ACCB.ACCB_PAYMENTS (PYMNT_REMARK)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX ACCB.IDX_PYMNT_TRNS_MTHD_ID
   ON ACCB.ACCB_PAYMENTS (PYMNT_MTHD_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE SEQUENCE ACCB.ACCB_PAYMENTS_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER ACCB.ACCB_PAYMENTS_TRG
   BEFORE INSERT
   ON ACCB.ACCB_PAYMENTS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.PYMNT_ID IS NULL)
DECLARE
   V_ID   ACCB.ACCB_PAYMENTS.PYMNT_ID%TYPE;
BEGIN
   SELECT   ACCB.ACCB_PAYMENTS_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.PYMNT_ID := V_ID;
END ACCB_PAYMENTS_TRG;