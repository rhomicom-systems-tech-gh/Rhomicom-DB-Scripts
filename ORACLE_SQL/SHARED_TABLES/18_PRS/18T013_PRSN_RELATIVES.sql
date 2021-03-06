/* Formatted on 12-15-2018 10:20:55 AM (QP5 v5.126.903.23003) */
DROP TABLE PRS.PRSN_RELATIVES  CASCADE CONSTRAINTS PURGE;

CREATE TABLE PRS.PRSN_RELATIVES (
   PERSON_ID           NUMBER NOT NULL,
   RELATIVE_PRSN_ID    NUMBER,
   RELATIONSHIP_TYPE   VARCHAR2 (100 BYTE),
   CREATED_BY          NUMBER NOT NULL,
   CREATION_DATE       VARCHAR2 (21 BYTE) NOT NULL,
   LAST_UPDATE_BY      NUMBER NOT NULL,
   LAST_UPDATE_DATE    VARCHAR2 (21 BYTE) NOT NULL,
   RLTV_ID             NUMBER NOT NULL,
   CONSTRAINT PK_RLTV_ID PRIMARY KEY (RLTV_ID)
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

CREATE INDEX PRS.IDX_RELATIONSHIP_TYPE
   ON PRS.PRSN_RELATIVES (RELATIONSHIP_TYPE)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX PRS.IDX_RELATIVE_PRSN_ID
   ON PRS.PRSN_RELATIVES (RELATIVE_PRSN_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

CREATE INDEX PRS.IDX_RL_PERSON_ID
   ON PRS.PRSN_RELATIVES (PERSON_ID)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;

DROP SEQUENCE PRS.PRSN_RELATIVES_SEQ;

CREATE SEQUENCE PRS.PRSN_RELATIVES_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   NOCACHE
   ORDER;

CREATE OR REPLACE TRIGGER PRS.PRSN_RELATIVES_TRG
   BEFORE INSERT
   ON PRS.PRSN_RELATIVES
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.RLTV_ID IS NULL)
DECLARE
   V_ID   PRS.PRSN_RELATIVES.RLTV_ID%TYPE;
BEGIN
   SELECT   PRS.PRSN_RELATIVES_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.RLTV_ID := V_ID;
END PRSN_RELATIVES_TRG;