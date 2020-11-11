/* Formatted on 10/6/2014 2:34:58 AM (QP5 v5.126.903.23003) */
-- FUNCTION: APLAPPS.CALC_IRS_PAYE_MNTHLY_TAX(NUMBER)

-- DROP FUNCTION APLAPPS.CALC_IRS_PAYE_MNTHLY_TAX(NUMBER);

CREATE OR REPLACE FUNCTION APLAPPS.CALC_IRS_PAYE_MNTHLY_TAX (
   TXABL_INCME NUMBER
)
   RETURN NUMBER
AS
   TAX_ANS          NUMBER := 0;
   RMNG_TXBL_INCM   NUMBER := 0;
   CUR_INCM         NUMBER := 0;

   TYPE ARRAY_T IS VARRAY (5) OF NUMBER;

   --ARRAY ARRAY_T := ARRAY_T('MATT', 'JOANNE', 'ROBERT');

   RATES ARRAY_T
         := ARRAY_T (0.0,
                     0.05,
                     0.10,
                     0.175,
                     0.25);
   BOUNDS ARRAY_T
         := ARRAY_T (120,
                     60,
                     84,
                     2136,
                     0);
--BOUNDS NUMBER() := '{100,35,92,1933,0}';
BEGIN
   RMNG_TXBL_INCM := TXABL_INCME;
   CUR_INCM := 0;

   FOR I IN 1 .. 5
   LOOP
      -- I WILL TAKE ON THE VALUES 1,2,3,4,5 WITHIN THE LOOP
      --1=0% 2=5% 3=10% 4=17.5% 5=25%
      IF I <= 4
      THEN
         IF (RMNG_TXBL_INCM >= BOUNDS (I))
         THEN
            CUR_INCM := BOUNDS (I);
         ELSE
            CUR_INCM := RMNG_TXBL_INCM;
         END IF;

         TAX_ANS := TAX_ANS + (CUR_INCM * RATES (I));
         RMNG_TXBL_INCM := RMNG_TXBL_INCM - BOUNDS (I);
      ELSIF I = 5
      THEN
         IF (RMNG_TXBL_INCM >= BOUNDS (I))
         THEN
            CUR_INCM := RMNG_TXBL_INCM;
         ELSE
            CUR_INCM := BOUNDS (I);
         END IF;

         TAX_ANS := TAX_ANS + (CUR_INCM * RATES (I));
      END IF;

      IF (RMNG_TXBL_INCM <= 0)
      THEN
         RETURN TAX_ANS;
      END IF;
   END LOOP;

   RETURN TAX_ANS;
END;


SELECT   APLAPPS.CALC_IRS_PAYE_MNTHLY_TAX (4321) FROM DUAL;