SELECT * FROM EDSR.PIM_PRODUCTO
SELECT * FROM EDSR.PIM_PRODUCTO_ATRIB

SELECT * FROM EPMM.PRDUPCEE
SELECT * FROM HESAS.PRDUPCEE

SELECT 2 || LPAD(TRIM('123456789'), 11, '0') AS AUX FROM DUAL

SELECT * FROM EPMM.PRDUPCEE

SELECT * FROM EPMM.SDIPRDMSI


SELECT * FROM EPMM.prdctlee;
SELECT * FROM EPMM.PRDMSTEE WHERE PRD_LVL_ID = 5;
SELECT * FROM EPMM.PRDMSTEE WHERE PRD_LVL_PARENT = 91449;
SELECT * FROM EPMM.PRDMSTEE WHERE PRD_LVL_CHILD = 91461;


-- 1.
SELECT * FROM EDSR.PIM_PRODUCTO
SELECT * FROM EDSR.PIM_PRODUCTO_ATRIB


SELECT DECODE(FLG_ID_VAL, 'TL', VALOR, ID)
FROM PIM_PRODUCTO_ATRIB
WHERE   ID_PIM_PROD    = P_ID_PIM_PROD
      AND COD_ATRIBUTO   = P_COD_ATRIBUTO;
    
