*&---------------------------------------------------------------------*
*&  Include           Z_QM_ACTIVE_WI_S100
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.

  IF g_scr0100-obj_alv IS INITIAL.

    SET TITLEBAR 'T0100'.
    SET PF-STATUS 'S0100'.

    CREATE OBJECT g_scr0100-obj_alv
      EXPORTING
        i_lifetime = cl_gui_container=>lifetime_dynpro
        i_parent   = cl_gui_container=>default_screen.

    SET HANDLER alv_event_handlers=>double_click FOR g_scr0100-obj_alv.

    g_scr0100-alv_layout-sel_mode   = 'A'.
    g_scr0100-alv_layout-no_toolbar = ''.
    g_scr0100-alv_layout-cwidth_opt = 'X'.

    g_scr0100-alv_variant-report = sy-repid.

    CALL METHOD g_scr0100-obj_alv->set_table_for_first_display
      EXPORTING
        is_layout       = g_scr0100-alv_layout
        is_variant      = g_scr0100-alv_variant
        i_save          = 'A'
      CHANGING
        it_outtab       = gt_alv_data
        it_fieldcatalog = g_scr0100-t_fcat.
  ENDIF.

ENDMODULE.                 " STATUS0100  OUTPUT
*----------------------------------------------------------------------*
*  MODULE user_comm0100 INPUT
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE g_scr0100-ok_code.
    WHEN 'DISP'.
      PERFORM display_obj.
    WHEN OTHERS.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.                    "user_comm0100 INPUT

*----------------------------------------------------------------------*
*  MODULE user_command_0100_exit INPUT
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
MODULE user_command_0100_exit INPUT.

  LEAVE TO SCREEN 0.

ENDMODULE.                    "user_comm0100 INPUT
