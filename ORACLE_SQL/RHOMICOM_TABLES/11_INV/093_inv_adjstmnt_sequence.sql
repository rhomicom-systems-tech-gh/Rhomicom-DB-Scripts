/* Formatted on 10/6/2014 7:43:48 PM (QP5 v5.126.903.23003) */
-- TABLE: INV.INV_ADJSTMNT_SEQUENCE

-- DROP TABLE INV.INV_ADJSTMNT_SEQUENCE;

CREATE TABLE INV.INV_ADJSTMNT_SEQUENCE (SEQ_NO NUMBER NOT NULL)
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

ALTER TABLE INV.INV_ADJSTMNT_SEQUENCE ADD(
CONSTRAINT PK_ADJSTMNT_SEQ_NO PRIMARY KEY (SEQ_NO ));

/*
CREATE UNIQUE INDEX INV.IDX_SEQ_NO
   ON INV.INV_ADJSTMNT_SEQUENCE (SEQ_NO)
   LOGGING
   TABLESPACE RHODB
   PCTFREE 10
   INITRANS 2
   MAXTRANS 255
   STORAGE (PCTINCREASE 0 BUFFER_POOL DEFAULT)
   NOPARALLEL;
*/

CREATE SEQUENCE INV.INV_ADJSTMNT_SEQUENCE_SEQ
   START WITH 1
   MAXVALUE 9223372036854775807
   MINVALUE 1
   NOCYCLE
   CACHE 20
   ORDER;

CREATE OR REPLACE TRIGGER INV.INV_ADJSTMNT_SEQUENCE_TRG
   BEFORE INSERT
   ON INV.INV_ADJSTMNT_SEQUENCE
   FOR EACH ROW
   -- OPTIONALLY RESTRICT THIS TRIGGER TO FIRE ONLY WHEN REALLY NEEDED
   WHEN (NEW.SEQ_NO IS NULL)
DECLARE
   V_ID   INV.INV_ADJSTMNT_SEQUENCE.SEQ_NO%TYPE;
BEGIN
   SELECT   INV.INV_ADJSTMNT_SEQUENCE_SEQ.NEXTVAL INTO V_ID FROM DUAL;

   :NEW.SEQ_NO := V_ID;
END INV_ADJSTMNT_SEQUENCE_TRG;