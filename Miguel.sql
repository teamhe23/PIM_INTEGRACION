
SELECT 
    AtComercial.ATTRIBUTE_NUMBER7 SKU_ID,
    AtComercial.ATTRIBUTE_NUMBER7 SKU_REFID, 
    AtComercial.ATTRIBUTE_NUMBER7 SKU_PROUCTID,

    1 SKU_ACTIVE,   
    1 SKU_AcivateIsPosible,   
    P.DESCRIPTION SKU_NAME,

    sysdate SKU_CREDATE,
    AtLogisticos.ATTRIBUTE_NUMBER18 Ean,
    AtSpcPlan.ATTRIBUTE_NUMBER1 PackagedHeight,
    AtSpcPlan.ATTRIBUTE_NUMBER11 PackagedLength,
    AtSpcPlan.ATTRIBUTE_NUMBER6 PackagedWidth ,
    '' PackagedWeightKg,
    '' Height,
    '' sku_Length,
    '' Width,
    '' WeightKg,
    '' CubicWeight,
    '' IsKit,
    '' RewardValue,
    '' ManufacturerCode,
    '' CommercialConditionId,
    '' MeasurementUnit,
    '' UnitMultiplier,
    '' KitItensSellApart,
    null stimatedDateArrival,
    null ModalType,
    null videos,

    Dep.CATEGORY_ID PROD_IDDep,
    Lin.CATEGORY_ID PROD_IDCAT,
    0 PROD_IDMARCA,
    'insert-product-test' PROD_LinkId,
    1 PROD_IsVisible,
    1 PROD_IsActive,
    1 PROD_ShowWithoutStock,
    sysdate PROD_ReleaseDate,
    '' PROD_TaxCode,
    'tag test' PROD_METADESCRIP,
    1 PROD_IDPROV,
    null PROD_ADWORDS,
    null PROD_LOMACAMPAIG,
    1 PROD_SCORE,
    AtComercial.ATTRIBUTE_NUMBER7 PROD_REFID,
    P.DESCRIPTION PROD_NAME,
    P.DESCRIPTION PROD_DESCRIP,
    P.DESCRIPTION PROD_DESCRSHRT,
    P.DESCRIPTION PROD_KEYWRD,
    P.DESCRIPTION PROD_TITLE,


    0 MARCA_ID,
    'marca' MARCA_NOMBRE,
    'marca' MARCA_TEXT,
    'marca' MARCA_KEYWRD,
    'marca' MARCA_SiteTitle,
    1 MARCA_Active,
    1 MARCA_MenuHom,
    '' MARCA_AdWordsRemark,
    '' MARCA_LomadCampaignCde,
    null MARCA_Score,
    'orma-carbon' MARCA_Linkid,


    Div.CATEGORY_ID DIV_ID,
    Div.CATEGORY_NAME DIV_NAME,
    Div.PARENT_CATEGORY_ID DIV_PARENT,
    Div.CATEGORY_NAME DIV_TITLE,
    Div.CATEGORY_NAME DIV_DESCRIPTION,
    Div.CATEGORY_NAME DIV_KEYWORDS,
    1 DIV_Active,
    1 DIV_ShwInStore,
    1 DIV_ShwBrndFltr,
    1 DIV_ActivStrFrnLnk,
    null DIV_LomaCampaigCode,
    null DIV_AdWordsRemark,
    null DIV_Score,
    'SPECIFICATION' DIV_SKUSelMode,
    0 DIV_GlblCatID,


    Area.CATEGORY_ID AREA_ID,
    Area.CATEGORY_NAME AREA_NAME,
    Area.PARENT_CATEGORY_ID AREA_PARENT,
    Area.CATEGORY_NAME AREA_TITLE,
    Area.CATEGORY_NAME AREA_DESCRIPTION,
    Area.CATEGORY_NAME AREA_KEYWORDS,
    1 AREA_Active,
    1 AREA_ShwInStore,
    1 AREA_ShwBrndFltr,
    1 AREA_ActivStrFrnLnk,
    null AREA_LomaCampaigCode,
    null AREA_AdWordsRemark,
    null AREA_Score,
    'SPECIFICATION' AREA_SKUSelMode,
    0 AREA_GlblCatID,


    Dep.CATEGORY_ID DEP_ID,
    Dep.CATEGORY_NAME DEP_NAME,
    Dep.PARENT_CATEGORY_ID DEP_PARENT,
    Dep.CATEGORY_NAME DEP_TITLE,
    Dep.CATEGORY_NAME DEP_DESCRIPTION,
    Dep.CATEGORY_NAME DEP_KEYWORDS,
    1 DEP_Active,
    1 DEP_ShwInStore,
    1 DEP_ShwBrndFltr,
    1 DEP_ActivStrFrnLnk,
    null DEP_LomaCampaigCode,
    null DEP_AdWordsRemark,
    null DEP_Score,
    'SPECIFICATION' DEP_SKUSelMode,
    0 DEP_GlblCatID,


    Lin.CATEGORY_ID LIN_ID,
    Lin.CATEGORY_NAME LIN_NAME,
    Lin.PARENT_CATEGORY_ID LIN_PARENT,
    Lin.CATEGORY_NAME LIN_TITLE,
    Lin.CATEGORY_NAME LIN_DESCRIPTION,
    Lin.CATEGORY_NAME LIN_KEYWORDS,
    1 LIN_Active,
    1 LIN_ShwInStore,
    1 LIN_ShwBrndFltr,
    1 LIN_ActivStrFrnLnk,
    null LIN_LomaCampaigCode,
    null LIN_AdWordsRemark,
    null LIN_Score,
    'SPECIFICATION' LIN_SKUSelMode,
    0 LIN_GlblCatID
 
 

FROM EGP_SYSTEM_ITEMS_B Prod
INNER JOIN EGP_SYSTEM_ITEMS_TL P on Prod.INVENTORY_ITEM_ID = P.INVENTORY_ITEM_ID
INNER JOIN egp_item_categories Cat_Prod on Prod.INVENTORY_ITEM_ID = Cat_Prod.INVENTORY_ITEM_ID
INNER JOIN EGP_CATEGORIES_INT Lin on Cat_Prod.CATEGORY_ID = Lin.CATEGORY_ID
INNER JOIN EGP_CATEGORIES_INT Dep on Lin.PARENT_CATEGORY_ID = Dep.CATEGORY_ID
INNER JOIN EGP_CATEGORIES_INT Area on Dep.PARENT_CATEGORY_ID = Area.CATEGORY_ID
INNER JOIN EGP_CATEGORIES_INT Div on Area.PARENT_CATEGORY_ID = Div.CATEGORY_ID

 

LEFT JOIN EGO_ITEM_EFF_B AtComercial on Prod.INVENTORY_ITEM_ID = AtComercial.INVENTORY_ITEM_ID and AtComercial.CONTEXT_CODE = 'HPSA_ATRIBUTOS_COMERCIALES' --NOMBRE DEL GRUPO,
 
LEFT JOIN EGO_ITEM_EFF_B AtLogisticos on Prod.INVENTORY_ITEM_ID = AtLogisticos.INVENTORY_ITEM_ID and AtLogisticos.CONTEXT_CODE = 'HPSA_ATRIBUTOS_LOGISTICOS'

LEFT JOIN EGO_ITEM_EFF_B AtSpcPlan on Prod.INVENTORY_ITEM_ID = AtSpcPlan.INVENTORY_ITEM_ID and AtSpcPlan.CONTEXT_CODE = 'HPSA_ATRIBUTOS_SPACE_PLANING'

 --PROMART_ATRIBUTOS_LOGISTICOS  PESO_DEL_PRODUCTO   ATTRIBUTE_NUMBER8
 
WHERE Prod.ITEM_NUMBER like 'PROMART%' 
    and Prod.ACD_TYPE= 'PROD'
    and P.LANGUAGE ='E'