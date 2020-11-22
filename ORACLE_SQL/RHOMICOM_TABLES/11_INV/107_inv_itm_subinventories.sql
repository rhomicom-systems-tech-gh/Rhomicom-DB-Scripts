/* Formatted on 10/6/2014 8:12:58 PM (QP5 v5.126.903.23003) */
-- TABLE: INV.INV_ITM_SUBINVENTORIES

-- DROP TABLE INV.INV_ITM_SUBINVENTORIES;

CREATE TABLE INV.INV_ITM_SUBINVENTORIES (
   SUBINV_ID           NUMBER NOT NULL,
   SUBINV_NAME         VARCHAR2 (100 BYTE),
   SUBINV_DESC         VARCHAR2 (200 BYTE),
   ADDRESS             VARCHAR2 (300),
   CREATION_DATE       VARCHAR2 (50 BYTE),
   CREATED_BY          NUMBER,
   LAST_UPDATE_BY      NUMBER,
   LAST_UPDATE_DATE    VARCHAR2 (50 BYTE),
   ALLOW_SALES         VARCHAR2 (1),
   SUBINV_MANAGER      NUMBER,
   ORG_ID              NUMBER,
   ENABLED_FLAG        VARCHAR2 (1 BYTE),
   INV_ASSET_ACCT_ID   NUMBER
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

ALTER TABLE INV.INV_ITM_SUBINVENTORIES
ADD(  CONSTRAINT PK_ITM_SUBINVS PRIMARY KEY (SUBINV_ID ));

-- INDEX: INV.INV.IDX_ENABLED_FLAG1

-- DROP INDEX INV.INV.IDX_ENABLED_FLAG1;

CREATE INDEX INV.IDX_ENABLED_FLAG1
   ON INV.INV_ITM_SUBINVENTORIES (ENABLED_FLAG)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

-- INDEX: INV.INV.IDX_ORG_ID6

-- DROP INDEX INV.INV.IDX_ORG_ID6;

CREATE INDEX INV.IDX_ORG_ID6
   ON INV.INV_ITM_SUBINVENTORIES (ORG_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

   /*
-- INDEX: INV.INV.IDX_SUBINV_ID4

-- DROP INDEX INV.INV.IDX_SUBINV_ID4;

CREATE UNIQUE INDEX INV.IDX_SUBINV_ID4
   ON INV.INV_ITM_SUBINVENTORIES (SUBINV_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;
*/
-- INDEX: INV.INV.IDX_SUBINV_NAME

-- DROP INDEX INV.INV.IDX_SUBINV_NAME;

CREATE INDEX INV.IDX_SUBINV_NAME
   ON INV.INV_ITM_SUBINVENTORIES (SUBINV_NAME)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;


CREATE SEQUENCE INV.INV_ITM_SUBINVENTORIES_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER INV.INV_ITM_SUBINVENTORIES_TRG
   BEFORE INSERT
   ON INV.INV_ITM_SUBINVENTORIES
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.SUBINV_ID IS NULL)
DECLARE
   V_ID   INV.INV_ITM_SUBINVENTORIES.SUBINV_ID%TYPE;
BEGIN
   SELECT   INV.INV_ITM_SUBINVENTORIES_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.SUBINV_ID := V_ID;
END INV_ITM_SUBINVENTORIES_TRG;