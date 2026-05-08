*&---------------------------------------------------------------------*
*&  Include           Z_QM_ACTIVE_WI_DATA
*&---------------------------------------------------------------------*

  INCLUDE zqmconst.

  TYPE-POOLS:
    icon.

  TABLES:
    swwwihead.

  TYPES:
    BEGIN OF t_ext_wi_user_data.
          INCLUDE STRUCTURE zact_wi_user_data.
          INCLUDE STRUCTURE qmel.
  TYPES:
      land1 TYPE land1.
  TYPES:
    END OF t_ext_wi_user_data.

  TYPES:
    BEGIN OF t_alv_data.
  "INCLUDE STRUCTURE zact_wi_user_data.
          INCLUDE TYPE t_ext_wi_user_data.
  TYPES:
      ico_wi_stat TYPE text100,
      ico_wi_dead TYPE text100,
    END OF t_alv_data.

  DATA:
    gt_wi_user_data TYPE STANDARD TABLE OF t_ext_wi_user_data,"zact_wi_user_data,
    gt_alv_data TYPE STANDARD TABLE OF t_alv_data.

  DATA:
    BEGIN OF g_scr0100,
      ok_code TYPE sy-ucomm,
      alv_layout TYPE lvc_s_layo,
      alv_variant TYPE disvariant,
      obj_alv TYPE REF TO cl_gui_alv_grid,
      t_fcat TYPE lvc_t_fcat,
    END OF g_scr0100.
