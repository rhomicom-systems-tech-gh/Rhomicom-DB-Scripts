/* Formatted on 12-15-2018 1:00:07 PM (QP5 v5.126.903.23003) */
DROP TABLE SCM.SCM_DFLT_ACCNTS  CASCADE CONSTRAINTS PURGE;

CREATE TABLE SCM.SCM_DFLT_ACCNTS (
   ITM_INV_ASST_ACNT_ID          NUMBER,
   COST_OF_GOODS_ACNT_ID         NUMBER,
   EXPENSE_ACNT_ID               NUMBER,
   PRCHS_RTRNS_ACNT_ID           NUMBER,
   RVNU_ACNT_ID                  NUMBER,
   SALES_RTRNS_ACNT_ID           NUMBER,
   SALES_CASH_ACNT_ID            NUMBER,
   SALES_CHECK_ACNT_ID           NUMBER,
   SALES_RCVBL_ACNT_ID           NUMBER,
   RCPT_CASH_ACNT_ID             NUMBER,
   RCPT_LBLTY_ACNT_ID            NUMBER,
   RHO_NAME                      VARCHAR2 (200 BYTE),
   ORG_ID                        NUMBER,
   CREATED_BY                    NUMBER,
   CREATION_DATE                 VARCHAR2 (21 BYTE),
   LAST_UPDATE_BY                NUMBER,
   LAST_UPDATE_DATE              VARCHAR2 (21 BYTE),
   ROW_ID                        NUMBER NOT NULL,
   INV_ADJSTMNTS_LBLTY_ACNT_ID   NUMBER DEFAULT -1 NOT NULL,
   TTL_CAA                       INTEGER DEFAULT -1 NOT NULL,
   TTL_CLA                       INTEGER DEFAULT -1 NOT NULL,
   TTL_AA                        INTEGER DEFAULT -1 NOT NULL,
   TTL_LA                        INTEGER DEFAULT -1 NOT NULL,
   TTL_OEA                       INTEGER DEFAULT -1 NOT NULL,
   TTL_RA                        INTEGER DEFAULT -1 NOT NULL,
   TTL_CGSA                      INTEGER DEFAULT -1 NOT NULL,
   TTL_IA                        INTEGER DEFAULT -1 NOT NULL,
   TTL_PEA                       INTEGER DEFAULT -1 NOT NULL,
   SALES_DSCNT_ACCNT             INTEGER DEFAULT -1 NOT NULL,
   PRCHS_DSCNT_ACCNT             INTEGER DEFAULT -1 NOT NULL,
   SALES_LBLTY_ACNT_ID           INTEGER DEFAULT -1 NOT NULL,
   BAD_DEBT_ACNT_ID              INTEGER DEFAULT -1 NOT NULL,
   RCPT_RCVBL_ACNT_ID            INTEGER DEFAULT -1 NOT NULL,
   PETTY_CASH_ACNT_ID            INTEGER DEFAULT -1 NOT NULL,
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


CREATE UNIQUE INDEX SCM.IDX_DFLT_ORG_ID
   ON SCM.SCM_DFLT_ACCNTS (ORG_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP SEQUENCE SCM.SCM_DFLT_ACCNTS_ROW_ID_SEQ;

CREATE SEQUENCE SCM.SCM_DFLT_ACCNTS_ROW_ID_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER SCM.SCM_DFLT_ACCNTS_ROW_ID_TRG
   BEFORE INSERT
   ON SCM.SCM_DFLT_ACCNTS
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.ROW_ID IS NULL)
DECLARE
   V_ID   SCM.SCM_DFLT_ACCNTS.ROW_ID%TYPE;
BEGIN
   SELECT   SCM.SCM_DFLT_ACCNTS_ROW_ID_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.ROW_ID := V_ID;
END SCM_DFLT_ACCNTS_ROW_ID_TRG;