/* Formatted on 18/09/2014 09:18:54 (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION APLAPPS.GET_PAYITM_NM (P_ITMID NUMBER)
   RETURN VARCHAR2
AS
   L_RESULT   VARCHAR2 (200 BYTE);
BEGIN
   SELECT   ITEM_CODE_NAME
     INTO   L_RESULT
     FROM   ORG.ORG_PAY_ITEMS
    WHERE   ITEM_ID = P_ITMID;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN '';
END;
/