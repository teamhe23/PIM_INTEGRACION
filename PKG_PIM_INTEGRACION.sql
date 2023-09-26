create or replace package body edsr.PKG_PIM_INTEGRACION is
  
  C_TIPO_CREACION         CONSTANT NUMBER(1)    := 1;
  
  C_ATR_CODLINEA          CONSTANT VARCHAR2(50) := 'CodLinea';
  C_ATR_PROVEEDOR         CONSTANT VARCHAR2(50) := 'Proveedor';
  C_ATR_UMV               CONSTANT VARCHAR2(50) := 'UMV';
  C_ATR_PROCEDENCIA       CONSTANT VARCHAR2(50) := 'Procedencia';
  C_ATR_MP_CANT           CONSTANT VARCHAR2(50) := 'MasterPackCantidad';
  C_ATR_EAN               CONSTANT VARCHAR2(50) := 'EAN';
  C_ATR_EAN_TIPO          CONSTANT VARCHAR2(50) := 'TipoEan';
  C_ATR_PRECIO_UNIT       CONSTANT VARCHAR2(50) := 'PrecioUnitario';
  C_ATR_SKU_PROVEEDOR     CONSTANT VARCHAR2(50) := 'SkuProveedor';
  C_ATR_UMI               CONSTANT VARCHAR2(50) := 'UMI';
  C_ATR_COSTO             CONSTANT VARCHAR2(50) := 'Costo';
  C_ATR_PESO_BRUTO        CONSTANT VARCHAR2(50) := 'PesoUnidadLogistica';
  C_ATR_PESO_NETO         CONSTANT VARCHAR2(50) := 'PesoProducto';
  C_ATR_UND_LOG_ALTO      CONSTANT VARCHAR2(50) := 'AlturaUnidadLogistica';
  C_ATR_UND_LOG_ANCHO     CONSTANT VARCHAR2(50) := 'AnchoUnidadLogistica';
  C_ATR_UND_LOG_LONGITUD  CONSTANT VARCHAR2(50) := 'ProfundidadUnidadLogistica';
  C_ATR_UND_LOG_VOLUMEN   CONSTANT VARCHAR2(50) := 'VolumendelaUnidadLogistica';
  C_ATR_DUN14             CONSTANT VARCHAR2(50) := 'DUN14';
  C_ATR_TIPO_SURTIDO      CONSTANT VARCHAR2(50) := 'TipoSurtido';
  C_ATR_CLUSTER_SURTIDO   CONSTANT VARCHAR2(50) := 'ClusterSurtido';
  C_ATR_MARCA             CONSTANT VARCHAR2(50) := 'Marca';
  C_ATR_MP_TIPO           CONSTANT VARCHAR2(50) := 'MasterPackTipo';
  C_ATR_PERECIBLE         CONSTANT VARCHAR2(50) := 'Perecible';
  C_ATR_PUNTO_PRECIO      CONSTANT VARCHAR2(50) := 'PuntoPrecio';
  C_ATR_TIPO_MARCA        CONSTANT VARCHAR2(50) := 'TipoMarca';
  C_ATR_TIPO_NEG          CONSTANT VARCHAR2(50) := 'TipoNegociacion';
  
  PROCEDURE SP_INS_PIM_MODELO(
    P_ID_TIPO          NUMBER,
    P_CONTENIDO        CLOB,
    P_MESSAGE_ID       VARCHAR2,
    P_ID_MODELO        OUT NUMBER
  )
  IS
  BEGIN
    
    SELECT SEQ_PIM_MODELO.NEXTVAL
      INTO P_ID_MODELO
    FROM DUAL;
  
    INSERT INTO PIM_MODELO(
      ID_MODELO,
      ID_TIPO,
      CONTENIDO,
      MESSAGE_ID
    )
    VALUES(
      P_ID_MODELO,
      P_ID_TIPO,
      P_CONTENIDO,
      P_MESSAGE_ID
    );
    COMMIT;
  END;
  
  PROCEDURE SP_PROCESO_GENERAL
  IS
    V_FLG_ERROR        CHAR(1);
    V_MENSAJE          VARCHAR2(4000);
    V_PRD_LVL_CHILD    NUMBER(12);
    
    CURSOR CUR_NUEVO IS
      SELECT P.ID_PIM_PROD
      FROM PIM_PRODUCTO P
        INNER JOIN PIM_MODELO M ON M.ID_MODELO = P.ID_MODELO
      WHERE P.FLG_PROCESADO = '0'
        AND M.ID_TIPO       = C_TIPO_CREACION;
  BEGIN
    EXECUTE IMMEDIATE ('alter session set NLS_NUMERIC_CHARACTERS=''.,'' ');
    
    SP_GEN_LOG('*Inicio proceso general');
    
    SP_PROCESAR_MODELO;
    
    FOR PROD IN CUR_NUEVO LOOP
      
      V_FLG_ERROR := '0';
      V_MENSAJE   := '';
      BEGIN
        SP_PROCESAR_PRODUCTO_NUEVO(PROD.ID_PIM_PROD, V_PRD_LVL_CHILD);
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          V_FLG_ERROR := '1';
          V_MENSAJE   := SUBSTR(SQLERRM, 0, 4000);
          SP_GEN_LOG('*****Error: ' || V_MENSAJE);
      END;
      
      UPDATE PIM_PRODUCTO
         SET FLG_PROCESADO = '1',
             FEC_PROCESO   = SYSDATE,
             PRD_LVL_CHILD = V_PRD_LVL_CHILD,
             FLG_ERROR     = V_FLG_ERROR,
             MENSAJE       = V_MENSAJE
      WHERE ID_PIM_PROD = PROD.ID_PIM_PROD;
      COMMIT;
    END LOOP;
    
    SP_GEN_LOG('*Final proceso general');
  END;
  
  PROCEDURE SP_PROCESAR_MODELO
  IS
    V_ID_PIM_PROD    NUMBER(18);
    V_FLG_ERROR      CHAR(1);
    V_MENSAJE        VARCHAR2(4000);
    
    CURSOR CUR_MODELO IS
      SELECT ID_MODELO,
             CONTENIDO
      FROM PIM_MODELO
      WHERE ID_TIPO       = C_TIPO_CREACION
        AND FLG_PROCESADO = '0';
  BEGIN
    SP_GEN_LOG('***Inicio procesar modelo');
    
    FOR MODELO IN CUR_MODELO LOOP
      
      SP_GEN_LOG('******Modelo: ' || TO_CHAR(MODELO.ID_MODELO));
      V_FLG_ERROR := '0';
      V_MENSAJE   := '';
      BEGIN
        SELECT SEQ_PIM_PRODUCTO.NEXTVAL
          INTO V_ID_PIM_PROD
        FROM DUAL;  
      
        INSERT INTO PIM_PRODUCTO(
          ID_PIM_PROD,
          ID_MODELO,
          ID_PIM,
          DESCRIPCION
        )
        SELECT V_ID_PIM_PROD,
               M.ID_MODELO,
               JSON.IDPIM,
               JSON.DESCRIPCION
        FROM PIM_MODELO M,
        JSON_TABLE (M.CONTENIDO, '$[*]'
                    COLUMNS(IDPIM           NUMBER(18)    PATH '$.IdPim',
                            DESCRIPCION     VARCHAR2(100) PATH '$.Descripcion')
                   ) AS JSON
        WHERE M.ID_MODELO = MODELO.ID_MODELO;
        
        IF SQL%ROWCOUNT = 0 THEN
          V_FLG_ERROR := '1';
          V_MENSAJE   := 'Modelo JSON no válido';
        END IF;
        
        INSERT INTO PIM_PRODUCTO_ATRIB(
          ID_PIM_PROD,
          COD_ATRIBUTO,
          ID,
          VALOR,
          UND_MEDIDA,
          FLG_UND_MEDIDA,
          FLG_ID_VAL,
          FLG_CAMPO_ADD,
          ATR_TYP_TECH_KEY,
          ATR_HDR_TECH_KEY
        )
        SELECT  V_ID_PIM_PROD,
                JSON.CODIGO,
                JSON.ID,
                JSON.VALOR,
                JSON.UND_MEDIDA,
                ATR.FLG_UND_MEDIDA,
                ATR.FLG_ID_VAL,
                ATR.FLG_CAMPO_ADD,
                ATR.ATR_TYP_TECH_KEY,
                ATR.ATR_HDR_TECH_KEY
        FROM PIM_MODELO M,
        JSON_TABLE (M.CONTENIDO, '$[*]'
                    COLUMNS (NESTED PATH '$.Atributos[*]'
                             COLUMNS (CODIGO       VARCHAR2(50) PATH '$.Codigo',
                                      ID           VARCHAR2(20) PATH '$.Id',
                                      VALOR        VARCHAR2(200) PATH '$.Valor',
                                      UND_MEDIDA   VARCHAR2(20) PATH '$.CodUndMedida')
                            )
                   ) AS JSON,
             PIM_ATRIBUTO ATR
        WHERE M.ID_MODELO = MODELO.ID_MODELO
          AND ATR.COD_ATRIBUTO = JSON.CODIGO;
        
      EXCEPTION
        WHEN OTHERS THEN
          V_FLG_ERROR := '1';
          V_MENSAJE   := SUBSTR(SQLERRM, 0, 4000);
      END;
      
      IF V_FLG_ERROR = '1' THEN
        SP_GEN_LOG('*********Error: ' || V_MENSAJE);
      END IF;
      
      UPDATE PIM_MODELO
        SET  FLG_PROCESADO = '1',
             FEC_PROCESO   = SYSDATE,
             FLG_ERROR     = V_FLG_ERROR,
             MENSAJE       = V_MENSAJE
      WHERE ID_MODELO = MODELO.ID_MODELO;
      
      COMMIT;
    END LOOP;
    SP_GEN_LOG('***Final procesar modelo');
  END;
  
  PROCEDURE SP_PROCESAR_PRODUCTO_NUEVO(
    P_ID_PIM_PROD        NUMBER,
    P_PRD_LVL_CHILD      OUT NUMBER
  )
  IS
  BEGIN
    SP_GEN_LOG('***Inicio procesar producto nuevo. id_pim_prod: ' || P_ID_PIM_PROD);
    
    SP_VALIDAR_NUEVO(P_ID_PIM_PROD);
    SP_CREAR_PRODUCTO(P_ID_PIM_PROD, P_PRD_LVL_CHILD);
    
    SP_GEN_LOG('***Final procesar producto nuevo. id_pim_prod: ' || P_ID_PIM_PROD);
  END;
  
  PROCEDURE SP_VALIDAR_NUEVO(
    P_ID_PIM_PROD        NUMBER
  )
  IS
    V_COUNT              NUMBER(10);
    V_ID_PIM             NUMBER(18);
    V_VPC_TECH_KEY       NUMBER(12);
    
    PROCEDURE VALIDAR_DUPLICADO
    IS
    BEGIN
      
      SELECT ID_PIM
        INTO V_ID_PIM
      FROM PIM_PRODUCTO
      WHERE ID_PIM_PROD = P_ID_PIM_PROD;
      
      SELECT COUNT(1)
        INTO V_COUNT
      FROM PIM_PRODUCTO
      WHERE ID_PIM_PROD   != P_ID_PIM_PROD
        AND ID_PIM        = V_ID_PIM
        AND FLG_PROCESADO = '1'
        AND FLG_ERROR     = '0';
        
      IF V_COUNT > 0 THEN
        raise_application_error(-20001, 'El id_pim ya se encuentra asignado a un producto');
      END IF;
    END;
    
    PROCEDURE VALIDAR_PROVEEDOR
    IS
      V_VENDOR_NUMBER      VARCHAR2(15);
    BEGIN
      
      BEGIN
        V_VENDOR_NUMBER     := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_PROVEEDOR);
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'El código de proveedor tiene más de 15 caracteres.');
      END;
      
      BEGIN
        SELECT V.VPC_TECH_KEY
          INTO V_VPC_TECH_KEY
        FROM VPCMSTEE V
        WHERE V.VENDOR_NUMBER = RPAD(V_VENDOR_NUMBER, 15, ' ');
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'El proveedor no existe');
      END;

    END;
    
    PROCEDURE VALIDAR_CREAR_PRODUCTO
    IS
      V_COD_LINEA          VARCHAR2(15);
    BEGIN
      
      BEGIN
        V_COD_LINEA         := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_CODLINEA);
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'El código de la línea tiene más de 15 caracteres.');
      END;
      
      IF V_COD_LINEA IS NULL THEN
        raise_application_error(-20001, 'No se ingreso el código de la línea del producto');
      END IF;
      
      SELECT COUNT(1)
        INTO V_COUNT
      FROM PRDMSTEE
      WHERE PRD_LVL_NUMBER = RPAD(V_COD_LINEA, 15, ' ');
      
      IF V_COUNT = 0 THEN
        raise_application_error(-20001, 'La línea del producto no existe');
      END IF;
      
    END;
    
    PROCEDURE VALIDAR_CREAR_ATRIBUTO
    IS
      V_CLUSTER_SURTIDO  VARCHAR2(40);
      V_TIPO_SURTIDO     VARCHAR2(15);
      V_MARCA            VARCHAR2(40);
      V_MP_TIPO          VARCHAR2(40);
      V_PERECIBLE        VARCHAR2(40);
      V_PUNTO_PRECIO     VARCHAR2(40);
      V_TIPO_MARCA       VARCHAR2(40);
      V_TIPO_NEG         VARCHAR2(40);
    BEGIN
      
      V_CLUSTER_SURTIDO := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_CLUSTER_SURTIDO);
      IF V_CLUSTER_SURTIDO IS NULL THEN
        raise_application_error(-20001, 'El atributo Cluster de surtido no se identifica.');
      END IF;
      
      V_TIPO_SURTIDO := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_TIPO_SURTIDO);
      IF V_TIPO_SURTIDO IS NULL THEN
        raise_application_error(-20001, 'El atributo tipo de surtido no se identifica');
      END IF;
      
      V_MARCA := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_MARCA);
      IF V_MARCA IS NULL THEN
        raise_application_error(-20001, 'El atributo Marca no se identifica.');
      END IF;
      
      V_MP_TIPO := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_MP_TIPO);
      IF V_MP_TIPO IS NULL THEN
        raise_application_error(-20001, 'El atributo MasterPackTipo no se identifica.');
      END IF;

      V_PERECIBLE := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_PERECIBLE);
      IF V_PERECIBLE IS NULL THEN
        raise_application_error(-20001, 'El atributo Perecible no se identifica.');
      END IF;
      
      V_PUNTO_PRECIO := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_PUNTO_PRECIO);
      IF V_PUNTO_PRECIO IS NULL THEN
        raise_application_error(-20001, 'El atributo PuntoPrecio no se identifica.');
      END IF;
      
      V_TIPO_MARCA := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_TIPO_MARCA);
      IF V_TIPO_MARCA IS NULL THEN
        raise_application_error(-20001, 'El atributo TipoMarca no se identifica.');
      END IF;
      
      V_TIPO_NEG := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_TIPO_NEG);
      IF V_TIPO_NEG IS NULL THEN
        raise_application_error(-20001, 'El atributo TipoNegociacion no se identifica.');
      END IF;

    END;
    
    PROCEDURE VALIDAR_EAN
    IS
      V_EAN                 VARCHAR2(15);
      V_EAN_SIN_ULT_DIG     VARCHAR2(15);
      V_EAN_PARA_VALIDAR    VARCHAR2(15);
      V_TIPO_EAN_CAD        VARCHAR2(4);
      V_TIPO_EAN_NUM        NUMERIC(4);
    BEGIN
      
      V_EAN                 := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_EAN);
      V_EAN_SIN_ULT_DIG     := SUBSTR(V_EAN, 1, LENGTH(V_EAN) - 1);
      V_TIPO_EAN_CAD        := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_EAN_TIPO);
      
      IF V_EAN IS NULL THEN
        RETURN;
      END IF;
      
      SELECT COUNT(*)
        INTO V_COUNT
      FROM PRDUPCEE
      WHERE PRD_UPC = V_EAN;
      
      IF V_COUNT > 0 THEN
        raise_application_error(-20001, 'El codigo EAN ingresado ya existe');
      END IF;
      
      SELECT V_EAN_SIN_ULT_DIG || TP_PKG_GEN_FUNCIONES.SP_DIGITO_VERIFICADOR(V_EAN_SIN_ULT_DIG)
        INTO V_EAN_PARA_VALIDAR
      FROM DUAL;
    
      IF V_EAN <> V_EAN_PARA_VALIDAR THEN
        raise_application_error(-20001, 'El dígito verificador del EAN es incorrecto');
      END IF;
      
      BEGIN
        SELECT TO_NUMBER(V_TIPO_EAN_CAD)
          INTO V_TIPO_EAN_NUM
        FROM DUAL;
      EXCEPTION
        WHEN OTHERS THEN
          V_TIPO_EAN_NUM := 0;
      END;
      
      SELECT COUNT(*)
        INTO V_COUNT
      FROM PRDUCDEE
      WHERE UPC_TYPE = V_TIPO_EAN_NUM;
      
      IF V_COUNT = 0 THEN
        raise_application_error(-20001, 'El tipo EAN no existe');
      END IF;
      
      IF LENGTH(V_EAN) > V_TIPO_EAN_NUM THEN
        raise_application_error(-20001, 'El EAN contiene muchos caracteres');
      END IF;
    END;
    
    PROCEDURE VALIDAR_PRECIO
    IS
      V_PRECIO_UNIT        NUMBER(11,3);
      V_PRD_SLL_UOM        VARCHAR2(6);
    BEGIN
      
      BEGIN
        V_PRECIO_UNIT := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_PRECIO_UNIT);
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'El precio no es un número válido.');
      END;
      
      IF V_PRECIO_UNIT IS NULL THEN
        raise_application_error(-20001, 'No se ingreso el precio.');
      END IF;
      
      IF V_PRECIO_UNIT <= 0 THEN
        raise_application_error(-20001, 'El precio debe ser mayor a cero.');
      END IF;
      
      
      V_PRD_SLL_UOM := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_UMV);
      
      IF V_PRD_SLL_UOM IS NULL THEN
        raise_application_error(-20001, 'No se ingreso la UMV.');
      END IF;
    END;

    PROCEDURE VALIDAR_CASEPACK
    IS
      V_SKU_PROVEEDOR      VARCHAR2(25);
      V_UMI                VARCHAR2(6);
      V_COSTO              NUMBER(15,5);
      V_MP_CANT            NUMBER(11,4);
      V_PESO_BRUTO         NUMBER(11,4);
      V_PESO_NETO          NUMBER(11,4);
      V_UND_LOG_ALTO       NUMBER(10,3);
      V_UND_LOG_ANCHO      NUMBER(10,3);
      V_UND_LOG_LONGITUD   NUMBER(10,3);
      V_UND_LOG_VOLUMEN    NUMBER(10,3);
      V_UND_LOG_UND_MED    VARCHAR2(6);
    BEGIN
      
      BEGIN
        V_SKU_PROVEEDOR := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_SKU_PROVEEDOR);
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'El case pack tiene más de 25 caracteres.');
      END;
      
      IF V_SKU_PROVEEDOR IS NULL THEN
        raise_application_error(-20001, 'No se ingreso el case pack.');
      END IF;
      
      SELECT COUNT(1)
        INTO V_COUNT
      FROM VPCPRDEE CP
      WHERE CP.VPC_TECH_KEY = V_VPC_TECH_KEY
        AND CP.VPC_CASE_PACK_ID = RPAD(V_SKU_PROVEEDOR, 25, ' ');
    
      IF V_COUNT > 0 THEN
        raise_application_error(-20001, 'Ya existe el case pack para el proveedor');
      END IF;
      
      
      V_UMI := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_UMI);
      IF V_UMI IS NULL THEN
        raise_application_error(-20001, 'No se ingreso la UMI.');
      END IF;
      
      
      BEGIN
        V_COSTO := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_COSTO);
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'El costo no es un número válido.');
      END;
      
      IF V_COSTO IS NULL THEN
        raise_application_error(-20001, 'No se ingreso el costo.');
      END IF;
      
      IF V_COSTO <= 0 THEN
        raise_application_error(-20001, 'El costo debe ser mayor a cero.');
      END IF;
      
      
      BEGIN
        V_MP_CANT := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_MP_CANT);
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'El master pack cantidad no es un número válido.');
      END;
      
      IF V_MP_CANT IS NULL THEN
        raise_application_error(-20001, 'No se ingreso el master pack cantidad.');
      END IF;
      
      IF V_MP_CANT <= 0 THEN
        raise_application_error(-20001, 'El master pack cantidad debe ser mayor a cero.');
      END IF;
      
      
      BEGIN
        V_PESO_BRUTO := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_PESO_BRUTO);
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'El peso bruto no es un número válido.');
      END;
      
      IF V_PESO_BRUTO IS NULL THEN
        raise_application_error(-20001, 'No se ingreso el peso bruto.');
      END IF;
      
      IF V_PESO_BRUTO <= 0 THEN
        raise_application_error(-20001, 'El peso bruto debe ser mayor a cero.');
      END IF;
      
      
      BEGIN
        V_PESO_NETO := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_PESO_NETO);
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'El peso neto no es un número válido.');
      END;
      
      IF V_PESO_NETO IS NULL THEN
        raise_application_error(-20001, 'No se ingreso el peso neto.');
      END IF;
      
      IF V_PESO_NETO <= 0 THEN
        raise_application_error(-20001, 'El peso neto debe ser mayor a cero.');
      END IF;
      
      
      BEGIN
        V_UND_LOG_ALTO := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_UND_LOG_ALTO);
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'La altura de la unidad logística no es un número válido.');
      END;
      
      IF V_UND_LOG_ALTO IS NULL THEN
        raise_application_error(-20001, 'No se ingreso la altura de la unidad logística.');
      END IF;
      
      IF V_UND_LOG_ALTO <= 0 THEN
        raise_application_error(-20001, 'La altura de la unidad logística debe ser mayor a cero.');
      END IF;
      
      
      BEGIN
        V_UND_LOG_ANCHO := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_UND_LOG_ANCHO);
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'El ancho de la unidad logística no es un número válido.');
      END;
      
      IF V_UND_LOG_ANCHO IS NULL THEN
        raise_application_error(-20001, 'No se ingreso el ancho de la unidad logística.');
      END IF;
      
      IF V_UND_LOG_ANCHO <= 0 THEN
        raise_application_error(-20001, 'El ancho de la unidad logística debe ser mayor a cero.');
      END IF;
      
      
      BEGIN
        V_UND_LOG_LONGITUD := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_UND_LOG_LONGITUD);
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'La profundidad de la unidad logística no es un número válido.');
      END;
      
      IF V_UND_LOG_LONGITUD IS NULL THEN
        raise_application_error(-20001, 'No se ingreso la profundidad de la unidad logística.');
      END IF;
      
      IF V_UND_LOG_LONGITUD <= 0 THEN
        raise_application_error(-20001, 'La profundidad de la unidad logística debe ser mayor a cero.');
      END IF;
      
      
      BEGIN
        V_UND_LOG_VOLUMEN := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_UND_LOG_VOLUMEN);
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'El volumen de la unidad logística no es un número válido.');
      END;
      
      IF V_UND_LOG_VOLUMEN IS NULL THEN
        raise_application_error(-20001, 'No se ingreso el volumen de la unidad logística.');
      END IF;
      
      IF V_UND_LOG_VOLUMEN <= 0 THEN
        raise_application_error(-20001, 'El volumen de la unidad logística debe ser mayor a cero.');
      END IF;
      
      
      V_UND_LOG_UND_MED   := FVC_ATRIBUTO_UNID_MED(P_ID_PIM_PROD, C_ATR_UND_LOG_ANCHO);
      IF V_UND_LOG_UND_MED IS NULL THEN
        raise_application_error(-20001, 'No se ingreso la unidad de medida de la unidad logística.');
      END IF;
    END;
 
    PROCEDURE VALIDAR_DUN14
    IS
      V_DUN14    VARCHAR2(15);
    BEGIN
      
      V_DUN14             := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_DUN14);
      
      IF V_DUN14 IS NULL THEN
        RETURN;
      END IF;
      
      SELECT COUNT(*)
        INTO V_COUNT
      FROM PRDUPCEE
      WHERE PRD_UPC = V_DUN14;
      
      IF V_COUNT > 0 THEN
        raise_application_error(-20001, 'El codigo DUN14 ingresado ya existe');
      END IF;
    END;

  BEGIN
    SP_GEN_LOG('*****Inicio validar nuevo. id_pim_prod: ' || P_ID_PIM_PROD);
    
    VALIDAR_DUPLICADO;
    VALIDAR_PROVEEDOR;
    VALIDAR_CREAR_PRODUCTO;
    VALIDAR_CREAR_ATRIBUTO;
    VALIDAR_EAN;
    VALIDAR_PRECIO;
    VALIDAR_CASEPACK;
    VALIDAR_DUN14;
    
    SP_GEN_LOG('*****Final validar nuevo. id_pim_prod: ' || P_ID_PIM_PROD);
  END;
  
  PROCEDURE SP_CREAR_PRODUCTO(
    P_ID_PIM_PROD        NUMBER,
    P_PRD_LVL_CHILD      OUT NUMBER
  )
  IS
    V_BATCH_NUM          NUMBER(14);
    V_PRD_LVL_CHILD      NUMBER(12);
    V_PRD_LVL_NUMBER     VARCHAR2(15);
    V_COD_BAR_AUX        NUMBER(18);
    V_COUNT              NUMBER(18);
    V_PRD_LVL_ID         NUMBER(1) := 1;
    V_COD_LINEA          VARCHAR2(15);
    V_PRD_NAME_FULL      VARCHAR2(50);
    V_VENDOR_NUMBER      VARCHAR2(50);
    V_PRD_SLL_UOM        VARCHAR2(6);
    V_MP_CANT            NUMBER(11,4);
    V_EAN                VARCHAR2(15);
    V_TIPO_EAN           VARCHAR2(4);
    V_PRECIO_UNIT        NUMBER(11,3);
    V_SKU_PROVEEDOR      VARCHAR2(25);
    V_UMI                VARCHAR2(6);
    V_COSTO              NUMBER(15,5);
    V_PESO_BRUTO         NUMBER(11,4);
    V_PESO_NETO          NUMBER(11,4);
    V_UND_LOG_ALTO       NUMBER(10,3);
    V_UND_LOG_ANCHO      NUMBER(10,3);
    V_UND_LOG_LONGITUD   NUMBER(10,3);
    V_UND_LOG_VOLUMEN    NUMBER(10,3);
    V_UND_LOG_UND_MED    VARCHAR2(6);
    V_DUN14              VARCHAR2(15);
    
    FUNCTION FVC_OBTENER_COD_BARRA_AUX
    RETURN NUMBER
    IS
      V_COD_BAR    NUMBER(18);
    BEGIN
      SELECT A.AUX || TP_PKG_GEN_FUNCIONES.SP_DIGITO_VERIFICADOR(A.AUX)
        INTO V_COD_BAR
      FROM (
            SELECT 2 || LPAD(TRIM(V_PRD_LVL_NUMBER), 11, '0') AS AUX
            FROM DUAL
           ) A;
           
      SELECT COUNT(*)
        INTO V_COUNT
      FROM PRDUPCEE
      WHERE PRD_UPC = V_COD_BAR;
      
      WHILE V_COUNT <> 0 LOOP
        -- Si en caso ya existe el cod de barras por defecto
        -- del SKU entonces se toma el siguiente SKU
        bastkey('prd_lvl_number', 0, V_PRD_LVL_NUMBER);
        SP_GEN_LOG('*****prd_lvl_number: ' || V_PRD_LVL_NUMBER);
        
        SELECT A.AUX || TP_PKG_GEN_FUNCIONES.SP_DIGITO_VERIFICADOR(A.AUX)
          INTO V_COD_BAR
        FROM (
              SELECT 2 || LPAD(TRIM(V_PRD_LVL_NUMBER), 11, '0') AS AUX
              FROM DUAL
             ) A;
      
        SELECT COUNT(*)
          INTO V_COUNT
        FROM PRDUPCEE
        WHERE PRD_UPC = V_COD_BAR;
      END LOOP;
      
      SP_GEN_LOG('*****códig barra auxiliar: ' || V_COD_BAR);
      RETURN V_COD_BAR;
    END;
    
    PROCEDURE CARGA_PRD_VARIABLE
    IS
    BEGIN
      SELECT SEQ_TE_LOD_ATR.NEXTVAL
        INTO V_BATCH_NUM
      FROM DUAL;
      
      SELECT DESCRIPCION
        INTO V_PRD_NAME_FULL
      FROM PIM_PRODUCTO
      WHERE ID_PIM_PROD = P_ID_PIM_PROD;
      
      bastkey('prd_lvl_number', 0, V_PRD_LVL_NUMBER);
      SP_GEN_LOG('*****prd_lvl_number: ' || V_PRD_LVL_NUMBER);
      
      V_COD_BAR_AUX       := FVC_OBTENER_COD_BARRA_AUX;
      V_COD_LINEA         := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_CODLINEA);
      V_VENDOR_NUMBER     := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_PROVEEDOR);
      V_PRD_SLL_UOM       := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_UMV);
      V_MP_CANT           := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_MP_CANT);
      V_EAN               := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_EAN);
      V_TIPO_EAN          := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_EAN_TIPO);
      V_PRECIO_UNIT       := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_PRECIO_UNIT);
      V_SKU_PROVEEDOR     := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_SKU_PROVEEDOR);
      V_UMI               := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_UMI);
      V_COSTO             := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_COSTO);
      V_PESO_BRUTO        := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_PESO_BRUTO);
      V_PESO_NETO         := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_PESO_NETO);
      V_UND_LOG_ALTO      := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_UND_LOG_ALTO);
      V_UND_LOG_ANCHO     := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_UND_LOG_ANCHO);
      V_UND_LOG_LONGITUD  := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_UND_LOG_LONGITUD);
      V_UND_LOG_VOLUMEN   := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_UND_LOG_VOLUMEN);
      V_UND_LOG_UND_MED   := FVC_ATRIBUTO_UNID_MED(P_ID_PIM_PROD, C_ATR_UND_LOG_ANCHO);
      V_DUN14             := FVC_ATRIBUTO_VALOR(P_ID_PIM_PROD, C_ATR_DUN14);
    END;
    
    PROCEDURE CARGA_PRD_SDI
    IS
    BEGIN
      INSERT INTO SDIPRDMSI(
        BATCH_NUM,
        PRD_LVL_NUMBER,
        PRD_LVL_ID,
        TRAN_TYPE,
        PRD_LVL_PARENT,
        PRD_NAME_FULL,
        VENDOR_NUMBER,
        PRD_STYLE_IND,
        IMP_DSS_FLAG,
        PRD_SLL_UOM
      )
      VALUES(
        V_BATCH_NUM,
        V_PRD_LVL_NUMBER,
        V_PRD_LVL_ID,
        'A',
        V_COD_LINEA,
        V_PRD_NAME_FULL,
        V_VENDOR_NUMBER,
        'F',
        'F',
        V_PRD_SLL_UOM
      );
    END;
    
    PROCEDURE CARGA_ATR_PROCEDENCIA
    IS
      V_PAIS           VARCHAR2(12);
      V_PAIS_PROV      VARCHAR2(12);
      V_COD_ATR_PROC   VARCHAR2(20);
    BEGIN
      
      SELECT TRIM(P.PARAM_VALUE)
        INTO V_PAIS
      FROM CHLPARAM P
      WHERE P.PARAM_CODE = 'PAIS';

      SELECT TO_CHAR(CNTRY_LVL_CHILD)
        INTO V_PAIS_PROV
      FROM VPCMSTEE
      WHERE VENDOR_NUMBER = RPAD(V_VENDOR_NUMBER, 15, ' ');
      
      V_COD_ATR_PROC := 'IMPORTADO';
      IF V_PAIS = V_PAIS_PROV THEN
        V_COD_ATR_PROC := 'NACIONAL';
      END IF;
      
      MERGE INTO PIM_PRODUCTO_ATRIB ATR
      USING (
        SELECT 
          COD_ATRIBUTO,
          V_COD_ATR_PROC AS COD_ATR_PROC,
          FLG_UND_MEDIDA,
          FLG_ID_VAL,
          FLG_CAMPO_ADD,
          ATR_TYP_TECH_KEY,
          ATR_HDR_TECH_KEY        
        FROM PIM_ATRIBUTO
        WHERE COD_ATRIBUTO = C_ATR_PROCEDENCIA
      ) SRC
      ON (ATR.ID_PIM_PROD = P_ID_PIM_PROD AND ATR.COD_ATRIBUTO = SRC.COD_ATRIBUTO)
      WHEN NOT MATCHED THEN
        INSERT (
          ID_PIM_PROD,
          COD_ATRIBUTO,
          ID,
          VALOR,
          FLG_UND_MEDIDA,
          FLG_ID_VAL,
          FLG_CAMPO_ADD,
          ATR_TYP_TECH_KEY,
          ATR_HDR_TECH_KEY
        )
        VALUES(
          P_ID_PIM_PROD,
          SRC.COD_ATRIBUTO,
          SRC.COD_ATR_PROC,
          SRC.COD_ATR_PROC,
          SRC.FLG_UND_MEDIDA,
          SRC.FLG_ID_VAL,
          SRC.FLG_CAMPO_ADD,
          SRC.ATR_TYP_TECH_KEY,
          SRC.ATR_HDR_TECH_KEY
        )
      WHEN MATCHED THEN
        UPDATE
          SET  ID      = SRC.COD_ATR_PROC,
               VALOR   = SRC.COD_ATR_PROC;
    END;
    
    PROCEDURE CARGA_ATR_SDI
    IS
    BEGIN
      
      INSERT INTO SDIPRDATI(
        BATCH_NUM,
        CONTROL_NUMBER,
        PRD_LVL_NUMBER,
        ORG_LVL_NUMBER,
        ATR_TYP_TECH_KEY,
        ATR_HDR_TECH_KEY,
        ATR_CODE,
        TRAN_TYPE,
        PRD_LVL_ID)
      SELECT
        V_BATCH_NUM,
        ROWNUM,
        V_PRD_LVL_NUMBER,
        0,
        ATR_TYP_TECH_KEY,
        ATR_HDR_TECH_KEY,
        ID,
        'A',
        1
      FROM PIM_PRODUCTO_ATRIB
      WHERE ID_PIM_PROD = P_ID_PIM_PROD
        AND ATR_TYP_TECH_KEY IS NOT NULL;
    END;
    
    PROCEDURE EJECUTAR_PRD_SDI
    IS
      V_MSG_ERROR            VARCHAR2(4000);
      V_ERROR                BOOLEAN;
    BEGIN
      SDIPRDBA(V_BATCH_NUM);
      
      BEGIN
        SELECT SUBSTR(SDI.ERROR_CODE || ' - ' || ERR.REJ_DESC, 0, 4000)
          INTO V_MSG_ERROR
          FROM SDIPRDMSI SDI
            INNER JOIN SDIREJCD ERR ON SDI.ERROR_CODE = ERR.REJ_CODE
        WHERE SDI.BATCH_NUM = V_BATCH_NUM
          AND ROWNUM = 1
          AND SDI.ERROR_CODE IS NOT NULL
          AND SDI.ERROR_CODE > 0;
        
        V_ERROR := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          V_MSG_ERROR := '';
          V_ERROR := FALSE;
      END;
      
      IF V_ERROR THEN
        raise_application_error(-20001, V_MSG_ERROR);
      END IF;
    END;
    
    PROCEDURE OBTENER_PRD_LVL_CHILD
    IS
    BEGIN
      BEGIN
        SELECT PRD_LVL_CHILD
          INTO V_PRD_LVL_CHILD
        FROM PRDMSTEE
        WHERE PRD_LVL_NUMBER = RPAD(V_PRD_LVL_NUMBER, 15, ' ');
      EXCEPTION
        WHEN OTHERS THEN
          raise_application_error(-20001, 'No se puede obtener el id del producto.');
      END;
    END;
    
    PROCEDURE EJECUTAR_ATR_SDI
    IS
      V_MSG_ERROR            VARCHAR2(4000);
      V_ERROR                BOOLEAN;
    BEGIN
      SDIATIBA(V_BATCH_NUM, 'F', 0, V_PRD_LVL_NUMBER);
      
      BEGIN       
        SELECT SUBSTR(SDI.ERROR_CODE || ' - ' || ERR.REJ_DESC, 0, 4000)
          INTO V_MSG_ERROR
        FROM SDIPRDATI SDI
          INNER JOIN SDIREJCD ERR ON SDI.ERROR_CODE = ERR.REJ_CODE
        where SDI.BATCH_NUM = V_BATCH_NUM
          AND ROWNUM = 1
          AND SDI.ERROR_CODE IS NOT NULL
          AND SDI.ERROR_CODE > 0;
           
        V_ERROR := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          V_MSG_ERROR := '';
          V_ERROR := FALSE;
      END;
      
      IF V_ERROR THEN
        raise_application_error(-20001, V_MSG_ERROR);
      END IF;
    END;
    
    PROCEDURE REGISTRA_WHSPRDEE
    IS
    BEGIN
      
      IF V_MP_CANT != 0 then
        INSERT INTO WHSPRDEE
          (ORG_LVL_CHILD, PRD_LVL_CHILD, TRF_DIST_PAK)
        SELECT O.ORG_LVL_CHILD, V_PRD_LVL_CHILD, V_MP_CANT
          FROM ORGMSTEE O
        WHERE O.ORG_IS_STORE  = 'F'
          AND O.ORG_LVL_ID    = 1;
      END IF;
    END;

    PROCEDURE REGISTRA_EAN_PRD
    IS
      V_MSG_ERROR            VARCHAR2(4000);
      V_ERROR                BOOLEAN;
    BEGIN

      IF V_EAN IS NULL THEN
        RETURN;
      END IF;
      
      UPDATE PRDUPCEE
        SET  PRD_PRIMARY_FLAG = 'F',
             DEFAULT_FLAG     = 'F'
      WHERE PRD_LVL_CHILD = V_PRD_LVL_CHILD;

      INSERT INTO SDIPRDUPI(
        batch_num,
        prd_upc,
        tran_type,
        prd_lvl_number,
        upc_type,
        prd_primary_flag,
        vpc_primary_flag,
        prd_upc_desc,
        date_created,
        default_flag,
        active_flag,
        product_upc,
        case_pack_upc
      )
      VALUES(
        V_BATCH_NUM,
        V_EAN,
        'A',
        V_PRD_LVL_NUMBER,
        V_TIPO_EAN,
        'T',
        'F',
        SUBSTR(V_PRD_NAME_FULL, 1, 40),
        SYSDATE,
        'T',
        'T',
        'T',
        'F');
    
      SDIUPIBA(V_BATCH_NUM, 'F', V_PRD_LVL_NUMBER, NULL);
    
      BEGIN
        SELECT SUBSTR(SDI.ERROR_CODE || ' - ' || ERR.REJ_DESC, 0, 4000)
          INTO V_MSG_ERROR
        FROM SDIUPIREJ SDI
            INNER JOIN SDIREJCD ERR ON SDI.ERROR_CODE = ERR.REJ_CODE
        WHERE SDI.BATCH_NUM = V_BATCH_NUM
          AND ROWNUM = 1
          AND SDI.ERROR_CODE IS NOT NULL
          AND SDI.ERROR_CODE > 0;
      
        V_ERROR := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          V_MSG_ERROR := '';
          V_ERROR := FALSE;
      END;
      
      IF V_ERROR THEN
        raise_application_error(-20001, V_MSG_ERROR);
      END IF;
    END;
    
    PROCEDURE REGISTRA_PRECIO
    IS
      V_MSG_ERROR            VARCHAR2(4000);
      V_ERROR                BOOLEAN;
    BEGIN
      
      INSERT INTO PRDPRCEE(
        batch_num,
        cap_chain_id,
        record_type,
        prc_type,
        org_lvl_child,
        org_lvl_number,
        PRD_LVL_CHILD,
        prd_lvl_number,
        prd_eff_date,
        prd_to_date,
        prc_zone_id,
        prc_zone_number,
        curr_code,
        prd_plu,
        PROC_BY_PRICE,
        PRD_PRC_PRICE,
        PRD_PRC_MULT,
        PRD_PRC_UOM
      )
      VALUES(
        V_BATCH_NUM,
       (SELECT PARAM_VALUE FROM CHLPARAM WHERE PARAM_CODE = 'CHAIN'),
       'A',
       1,
       0,
       0,
       0,
       V_PRD_LVL_NUMBER,
       (select t.caldat from caldayee t),
       to_date('31/12/2999', 'dd/mm/yyyy'),
       0,
       0,
       'USD',
       '  ',
       'F',
       V_PRECIO_UNIT,
       1,
       V_PRD_SLL_UOM
     );
        
      PRDPRCUNL('F', V_BATCH_NUM);

      BEGIN
        SELECT SUBSTR(SDI.ERROR_CODE || ' - ' || ERR.REJ_DESC, 0, 4000)
          INTO V_MSG_ERROR
        FROM PRDPRCREJ SDI
          INNER JOIN SDIREJCD ERR ON SDI.ERROR_CODE = ERR.REJ_CODE
        WHERE SDI.BATCH_NUM = V_BATCH_NUM
          AND ROWNUM = 1
          AND SDI.ERROR_CODE IS NOT NULL
          AND SDI.ERROR_CODE > 0;

        V_ERROR := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          V_MSG_ERROR := '';
          V_ERROR := FALSE;
      END;
      
      IF V_ERROR THEN
        raise_application_error(-20001, V_MSG_ERROR);
      END IF;
    END;

    PROCEDURE REGISTRA_CASE_PACK
    IS
      V_MSG_ERROR            VARCHAR2(4000);
      V_ERROR                BOOLEAN;
    BEGIN
      
      INSERT INTO SDIVPCCSI(
        BATCH_NUM,
        TECH_KEY,
        PRD_LVL_NUMBER,
        TRAN_TYPE,
        VENDOR_NUMBER,
        CASE_PACK_ID,
        inv_uom,
        VPC_CST_START,
        VPC_CST_END,
        CASE_PACK_DESC,
        EACHES_PER_INNER,
        VPC_PRD_COST,
        vpc_primary_flag,
        vpc_buy_multiple,
        VPC_CASE_QTY_UOM,
        VPC_CASE_QTY,
        VPC_CASE_GROSS_WGT,
        VPC_CASE_WGT,
        VPC_CASE_WIDTH,
        VPC_CASE_LEN,
        VPC_CASE_HEIGHT,
        VPC_CASE_CUBE,
        SLL_UNITS_PER_INNER,
        ASSOCIATED_PRD_UPC,
        VPC_CASE_WGT_UOM,
        VPC_CASE_DIM_UOM,
        CASE_CUBE_UOM,
        VPC_CASE_STD_PACK,
        NUMBER_OF_INNERS
      )
      VALUES(
        V_BATCH_NUM,
        1,
        V_PRD_LVL_NUMBER,
        'A',
        V_VENDOR_NUMBER,
        V_SKU_PROVEEDOR,
        V_UMI,
        (select t.caldat from caldayee t),
        to_date('31/12/2999', 'dd/mm/yyyy'),
        V_PRD_NAME_FULL,
        1,
        V_COSTO,
        'T',
        DECODE(V_MP_CANT, 0, NULL, V_MP_CANT),
        V_UMI,
        1,
        V_PESO_BRUTO,
        V_PESO_NETO,
        V_UND_LOG_ANCHO,
        V_UND_LOG_LONGITUD,
        V_UND_LOG_ALTO,
        V_UND_LOG_VOLUMEN,
        1,
        NVL(V_EAN, V_COD_BAR_AUX),
        FN_GET_UND_MED_DEF('PESO'),
        V_UND_LOG_UND_MED,
        FN_GET_UND_MED_DEF('VOLUMEN'),
        V_MP_CANT,
        1
      );
      
      VPCCSTIM(V_BATCH_NUM, 100, null, 'F');
      
      BEGIN
        SELECT SUBSTR(SDI.ERROR_CODE || ' - ' || ERR.REJ_DESC, 0, 4000)
          INTO V_MSG_ERROR
        FROM SDIVPCREJ SDI
          INNER JOIN SDIREJCD ERR ON SDI.ERROR_CODE = ERR.REJ_CODE
        WHERE SDI.BATCH_NUM = V_BATCH_NUM
          AND ROWNUM = 1
          AND SDI.ERROR_CODE IS NOT NULL;
      
        V_ERROR := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          V_MSG_ERROR := '';
          V_ERROR := FALSE;
      END;
      
      IF V_ERROR THEN
        raise_application_error(-20001, V_MSG_ERROR);
      END IF;
    END;

    PROCEDURE REGISTRA_DUN14
    IS
      V_MSG_ERROR            VARCHAR2(4000);
      V_ERROR                BOOLEAN;
    BEGIN
      
      IF V_DUN14 IS NULL THEN
        SELECT COD_BAR_ND ||
               TP_PKG_GEN_FUNCIONES.SP_DIGITO_VERIFICADOR(COD_BAR_ND)
          INTO V_DUN14
          FROM (
                SELECT '125' || LPAD(V_PRD_LVL_NUMBER, 10, '0') AS COD_BAR_ND 
                FROM DUAL
               );
      END IF;
    
      INSERT INTO SDIPRDUPI(
        batch_num,
        prd_upc,
        tran_type,
        prd_lvl_number,
        upc_type,
        prd_primary_flag,
        vpc_primary_flag,
        prd_upc_desc,
        date_created,
        default_flag,
        active_flag,
        product_upc,
        case_pack_upc
      )
      VALUES(
        V_BATCH_NUM,
        V_DUN14,
        'A',
        V_PRD_LVL_NUMBER,
        14,
        'F',
        'T',
        SUBSTR(V_PRD_NAME_FULL, 1, 40),
        SYSDATE,
        'T',
        'T',
        'F',
        'T'
      );
  
      INSERT INTO SDIVPCUPI(
        BATCH_NUM,
        PRD_UPC,
        VENDOR_NUMBER,
        VPC_CASE_PACK_ID,
        VPC_PRIMARY_FLAG)
      VALUES(
        V_BATCH_NUM,
        V_DUN14,
        V_VENDOR_NUMBER,
        V_SKU_PROVEEDOR,
        'T');
      
      SDIUPIBA(V_BATCH_NUM, 'F', V_PRD_LVL_NUMBER, NULL);
      
      BEGIN
        SELECT SUBSTR(SDI.ERROR_CODE || ' - ' || ERR.REJ_DESC, 0, 4000)
          INTO V_MSG_ERROR
        FROM SDIVPCUPI SDI
          INNER JOIN SDIREJCD ERR ON SDI.ERROR_CODE = ERR.REJ_CODE
        WHERE SDI.BATCH_NUM = V_BATCH_NUM
           AND ROWNUM       = 1
           AND SDI.ERROR_CODE IS NOT NULL;
      
        V_ERROR := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          V_MSG_ERROR := '';
          V_ERROR := FALSE;
      END;
      
      IF V_ERROR THEN
        raise_application_error(-20001, V_MSG_ERROR);
      END IF;
      
    END;
  
    PROCEDURE REGISTRA_INNER_PACK
    IS
      V_MSG_ERROR            VARCHAR2(4000);
      V_ERROR                BOOLEAN;
    BEGIN
      
      INSERT INTO SDIPRDPCI(
        BATCH_NUM,
        INNER_PACK_ID,
        WEIGHT_UOM,
        DIMENSION_UOM,
        CASE_CUBE_UOM,
        GROSS_WEIGHT,
        NET_WEIGHT,
        VPC_CASE_WIDTH,
        VPC_CASE_LEN,
        VPC_CASE_HEIGHT,
        VPC_CASE_CUBE
      )
      VALUES(
        V_BATCH_NUM,
        (SELECT INNER_PACK_ID
         FROM prdpcdee
         WHERE PRD_LVL_CHILD = V_PRD_LVL_CHILD
           AND ROWNUM = 1),
        FN_GET_UND_MED_DEF('PESO'),
        V_UND_LOG_UND_MED,
        FN_GET_UND_MED_DEF('VOLUMEN'),
        V_PESO_BRUTO,
        V_PESO_NETO,
        V_UND_LOG_ANCHO,
        V_UND_LOG_LONGITUD,
        V_UND_LOG_ALTO,
        V_UND_LOG_VOLUMEN);
  
      SDIPRDPCDIM('F', V_BATCH_NUM);
    
      BEGIN
        SELECT SUBSTR(SDI.ERROR_CODE || ' - ' || ERR.REJ_DESC, 0, 4000)
          INTO V_MSG_ERROR
        FROM SDIPRDPCI SDI
          INNER JOIN SDIREJCD ERR ON SDI.ERROR_CODE = ERR.REJ_CODE
         where SDI.BATCH_NUM = V_BATCH_NUM
           AND ROWNUM = 1
           AND SDI.ERROR_CODE IS NOT NULL
           AND SDI.ERROR_CODE > 0;
      
        V_ERROR := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          V_MSG_ERROR := '';
          V_ERROR := FALSE;
      END;
        
      IF V_ERROR THEN
        raise_application_error(-20001, V_MSG_ERROR);
      END IF;
    END;
  BEGIN
    SP_GEN_LOG('*****Inicio crear producto. id_pim_prod: ' || P_ID_PIM_PROD);
    
    CARGA_PRD_VARIABLE;
    CARGA_PRD_SDI;
    CARGA_ATR_PROCEDENCIA;
    CARGA_ATR_SDI;
    
    EJECUTAR_PRD_SDI;
    OBTENER_PRD_LVL_CHILD;
    EJECUTAR_ATR_SDI;
    REGISTRA_WHSPRDEE;
    REGISTRA_EAN_PRD;
    REGISTRA_PRECIO;
    REGISTRA_CASE_PACK;
    REGISTRA_DUN14;
    REGISTRA_INNER_PACK;
    
    P_PRD_LVL_CHILD := V_PRD_LVL_CHILD;
    
    SP_GEN_LOG('*****Final crear producto. id_pim_prod: ' || P_ID_PIM_PROD);
  END;
  
  FUNCTION FVC_ATRIBUTO_VALOR(
    P_ID_PIM_PROD          NUMBER,
    P_COD_ATRIBUTO         VARCHAR2
  ) RETURN VARCHAR2
  IS
    V_RETORNO    VARCHAR2(50);
  BEGIN
    
    BEGIN
      SELECT DECODE(FLG_ID_VAL, 'TL', VALOR, ID)
        INTO V_RETORNO
      FROM PIM_PRODUCTO_ATRIB
      WHERE ID_PIM_PROD    = P_ID_PIM_PROD
        AND COD_ATRIBUTO   = P_COD_ATRIBUTO;
    EXCEPTION
      WHEN OTHERS THEN
        V_RETORNO := '';
    END;
    RETURN V_RETORNO;
  END;
  
  FUNCTION FVC_ATRIBUTO_UNID_MED(
    P_ID_PIM_PROD          NUMBER,
    P_COD_ATRIBUTO         VARCHAR2
  ) RETURN VARCHAR2
  IS
    V_RETORNO    VARCHAR2(50);
  BEGIN
    
    BEGIN
      SELECT UND_MEDIDA
        INTO V_RETORNO
      FROM PIM_PRODUCTO_ATRIB
      WHERE ID_PIM_PROD    = P_ID_PIM_PROD
        AND COD_ATRIBUTO   = P_COD_ATRIBUTO;
    EXCEPTION
      WHEN OTHERS THEN
        V_RETORNO := '';
    END;
    RETURN V_RETORNO;
  END;
  
  FUNCTION FN_GET_UND_MED_DEF(
    P_TIPO         VARCHAR2
  ) RETURN VARCHAR2
  IS
   V_UNID          VARCHAR2(20) := '';
  BEGIN
    SELECT NUM_PAR
      INTO V_UNID
      FROM IFH_PARAMETROS
     WHERE COD_SIS = '48'
       AND COD_PAR = P_TIPO;
  
    RETURN V_UNID;
  END;
  
end PKG_PIM_INTEGRACION;
