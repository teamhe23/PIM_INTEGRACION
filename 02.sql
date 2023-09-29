-- Create table

DROP table PIM_MODELO_REQUEST
create table PIM_MODELO_REQUEST
(
  id_modelo         NUMBER(18) not null,
  id_tipo           NUMBER(5) not null,
  modelo            CLOB not null,
  identificador     VARCHAR2(50),
  fec_reg           DATE default SYSDATE not null,
  flag_procesado    CHAR(1) default '0' not null,
  fec_proceso       DATE,
  flag_error        CHAR(1) default '0' not null,
  desc_error        VARCHAR2(4000),
  id_message_pubsub VARCHAR2(4000)
)
tablespace EDSR_MDT
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 512K
    next 512K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table PIM_MODELO_REQUEST
  add constraint PK_PIM_MODELO_REQUEST primary key (ID_MODELO)
  using index 
  tablespace EDSR_MDT
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 512K
    next 512K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );
alter table PIM_MODELO_REQUEST
  add constraint FK_PIM_MODELO_REQUEST_TIPO foreign key (ID_TIPO)
  references PIM_TIPO_MODELO_REQUEST (ID_TIPO);
-- Create/Recreate check constraints 
alter table PIM_MODELO_REQUEST
  add constraint CH_PIM_MODELO_REQ_ERROR
  check (FLAG_ERROR IN ('0','1'));
  
  
