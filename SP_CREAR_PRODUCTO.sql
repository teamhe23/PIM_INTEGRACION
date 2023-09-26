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
    
    CARGA_PRD_VARIABLE; -- V_COD_BAR_AUX = FVC_OBTENER_COD_BARRA_AUX
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