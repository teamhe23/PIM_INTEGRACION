
SELECT * FROM WMS_RETORNOS ORDER BY FEC_CRE DESC;
SELECT * FROM WMS_RETORNOS WHERE ID_NV='2200033249409'

SELECT * FROM PRDMSTEE

SELECT *

FROM EGP_SYSTEMS_ITEMS_B Prod
INNER JOIN EGP_ITEM_CATEGORIES Cat_Prod ON Prod.INVENTORY_ITEM_ID = Cat_Prod.INVENTORY_ITEM_ID
INNER JOIN EGP_CATEGORIES_INT Lin ON Cat_Prod.CATEGORY_ID = Lin.CATEGORY_ID
INNER JOIN EGP_CATEGORIES_INT Dep ON Lin.PARENT_CATEGORY_ID = Dep.CATEGORY_ID
INNER JOIN EGP_CATEGORIES_INT Area ON Dep.PARENT_CATEGORY_ID = Area.CATEGORY_ID
INNER JOIN EGP_CATEGORIES_INT Div ON Area.PARENT_CATEGORY_ID = Div.CATEGORY_ID
INNER JOIN EGP_SYSTEMS_ITEMS_TL P ON Prod.INVENTORY_ITEM_ID = P.INVENTORY_ITEM_ID

WHERE Prod.ITEM_NUMBER LIKE 'PROMART%'
      AND Prod.ACD_TYPE = 'PROD'
      AND P.LANGUAJE = 'E'
      AND ROWNUM = 1



