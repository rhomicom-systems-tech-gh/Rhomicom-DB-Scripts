/* Formatted on 10/5/2014 7:32:37 PM (QP5 v5.126.903.23003) */
-- TABLE: PAY.PAY_ITM_SETS_DET

-- DROP TABLE PAY.PAY_ITM_SETS_DET;

CREATE TABLE PAY.PAY_ITM_SETS_DET (
   DET_ID               NUMBER NOT NULL,
   HDR_ID               NUMBER,
   ITEM_ID              NUMBER,
   TO_DO_TRNSCTN_TYPE   VARCHAR2 (100),
   CREATED_BY           NUMBER NOT NULL,
   CREATION_DATE        VARCHAR2 (21) NOT NULL,
   LAST_UPDATE_BY       NUMBER NOT NULL,
   LAST_UPDATE_DATE     VARCHAR2 (21) NOT NULL,
   CONSTRAINT PK_DET_ID PRIMARY KEY (DET_ID)
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

CREATE INDEX PAY.IDX_DET_HDR_ID
   ON PAY.PAY_ITM_SETS_DET (HDR_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX PAY.IDX_SET_ITM_ID
   ON PAY.PAY_ITM_SETS_DET (ITEM_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE SEQUENCE PAY.PAY_ITM_SETS_DET_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER PAY.PAY_ITM_SETS_DET_TRG
   BEFORE INSERT
   ON PAY.PAY_ITM_SETS_DET
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.DET_ID IS NULL)
DECLARE
   V_ID   PAY.PAY_ITM_SETS_DET.DET_ID%TYPE;
BEGIN
   SELECT   PAY.PAY_ITM_SETS_DET_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.DET_ID := V_ID;
END PAY_ITM_SETS_DET_TRG;