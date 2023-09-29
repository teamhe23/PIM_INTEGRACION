-- Create table
create table PIM_TIPO_MODELO_REQUEST
(
  id_tipo   NUMBER(5) not null,
  desc_tipo VARCHAR2(50) not null,
  constraint PK_PIM_TIPO_MODELO_REQUEST primary key (ID_TIPO)
)
organization index;


SELECT * FROM EGP_SYSTEM_ITEMS_B
WHERE ITEM_NUMBER like 'HESA%'

