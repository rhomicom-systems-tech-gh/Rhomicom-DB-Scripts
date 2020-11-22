/* Formatted on 18/09/2014 09:21:35 (QP5 v5.126.903.23003) */
CREATE OR REPLACE FUNCTION APLAPPS.GET_PAYITM_VAL_AMNT (P_PSBLVALID NUMBER)
   RETURN NUMBER
AS
   L_RESULT   NUMBER (20, 2);
BEGIN
   L_RESULT := 0;

   SELECT   NVL (PSSBL_AMOUNT, 0)
     INTO   L_RESULT
     FROM   ORG.ORG_PAY_ITEMS_VALUES
    WHERE   PSSBL_VALUE_ID = P_PSBLVALID;

   RETURN L_RESULT;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN 0;
END;
/