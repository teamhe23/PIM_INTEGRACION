select 
Prod.ITEM_NUMBER                IdPim,
P.DESCRIPTION                   NombreProducto,

AtComercial.ATTRIBUTE_CHAR10    TipoNegociacion,
AtContenido13.ATTRIBUTE_CHAR1   Marca,
AtComercial.ATTRIBUTE_CHAR16    TipoMarca,
AtComercial.ATTRIBUTE_CHAR30    SkuProveedor,
AtComercial.ATTRIBUTE_CHAR37    CodigoLineaPromart,
AtComercial.ATTRIBUTE_NUMBER2   PrecioUnitario,
AtComercial.ATTRIBUTE_NUMBER5   CodigoProveedor,
AtComercial.ATTRIBUTE_NUMBER6   Costo,

AtSurt.ATTRIBUTE_CHAR1          ClusterSurtido,
'LONGTAIL'                      LONGTAIL,
AtSurt.ATTRIBUTE_CHAR3          AtrSurt3,

AtComercial2.ATTRIBUTE_CHAR10   UnidadMedidaVenta,
AtComercial2.ATTRIBUTE_CHAR11   PuntoPrecio,
AtComercial2.ATTRIBUTE_CHAR7    TipoSurtido,

'AFECTO_DETRACCION'             AfectoDetr,
AtContab.ATTRIBUTE_CHAR2,
'AFECTO_IGV'                    AfectoIGV,
AtContab.ATTRIBUTE_CHAR3        AtrContab3,
AtAprob.ATTRIBUTE_CHAR8         AtAprob8,
'DESPACHO_CD'                   DespachoCD,
AtLogist.ATTRIBUTE_CHAR2        DUN14,
AtLogist.ATTRIBUTE_CHAR3,
AtLogist.ATTRIBUTE_CHAR4        Perecible,
AtLogist.ATTRIBUTE_CHAR5        TipoMasterpack,
'BIG_TICKET'                    BigTicket,
AtLogist.ATTRIBUTE_CHAR8        AtLog8,
'PRODUCTOS_SENSIBLES'           ProdSensibl,
AtLogist.ATTRIBUTE_CHAR10       AtLog10,
'EMPIOCHADO'                    Empiochado,
AtLogist.ATTRIBUTE_CHAR12       UnidadMedidadInventarioUMI,
AtLogist.ATTRIBUTE_CHAR13       TipoCodigoEAN,
AtLogist.ATTRIBUTE_CHAR15,
AtLogist.ATTRIBUTE_NUMBER2      AnchoUnidadLogistica,
AtLogist.ATTRIBUTE_NUMBER7      CantidadMasterpack,
AtLogist.ATTRIBUTE_NUMBER8      PesoProducto,
AtLogist.ATTRIBUTE_NUMBER9      AlturaUnidadLogistica,
AtLogist.ATTRIBUTE_NUMBER12     PesoUnidadLogistica,
AtLogist.ATTRIBUTE_NUMBER17     ProfundidadUnidadLogistica,
AtLogist.ATTRIBUTE_NUMBER18     EAN,
AtLogist.ATTRIBUTE_NUMBER19     VolumenUnidadLogistica,



FROM EGP_SYSTEM_ITEMS_B Prod
left join EGP_SYSTEM_ITEMS_TL P on Prod.INVENTORY_ITEM_ID = P.INVENTORY_ITEM_ID 

left join EGO_ITEM_EFF_B AtComercial on Prod.INVENTORY_ITEM_ID = AtComercial.INVENTORY_ITEM_ID and AtComercial.CONTEXT_CODE = 'HPSA_ATRIBUTOS_COMERCIALES'
left join EGO_ITEM_EFF_B AtSurt on Prod.INVENTORY_ITEM_ID = AtSurt.INVENTORY_ITEM_ID and AtSurt.CONTEXT_CODE = 'HPSA_ATRIBUTOS_DE_SURTIDO'
left join EGO_ITEM_EFF_B AtComercial2 on Prod.INVENTORY_ITEM_ID = AtComercial2.INVENTORY_ITEM_ID and AtComercial2.CONTEXT_CODE = 'HPSA_ATRIBUTOS_COMERCIALES_2'
left join EGO_ITEM_EFF_B AtContab on Prod.INVENTORY_ITEM_ID = AtContab.INVENTORY_ITEM_ID and AtContab.CONTEXT_CODE = 'HPSA_ATRIBUTOS_CONTABLES'
left join EGO_ITEM_EFF_B AtAprob on Prod.INVENTORY_ITEM_ID = AtAprob.INVENTORY_ITEM_ID and AtAprob.CONTEXT_CODE = 'HPSA_APROBACION_FINAL'
left join EGO_ITEM_EFF_B AtLogist on Prod.INVENTORY_ITEM_ID = AtLogist.INVENTORY_ITEM_ID and AtLogist.CONTEXT_CODE = 'HPSA_ATRIBUTOS_LOGISTICOS'

left join EGO_ITEM_EFF_B AtContenido13 on Prod.INVENTORY_ITEM_ID = AtContenido13.INVENTORY_ITEM_ID and AtContenido13.CONTEXT_CODE = 'HPSA_ATRIBUTOS_CONTENIDO_13'


where Prod.ITEM_NUMBER like 'HESA%'
and Prod.ACD_TYPE= 'PROD'
and P.LANGUAGE = 'E'
and rownum < 4



-- FORMATEADO

