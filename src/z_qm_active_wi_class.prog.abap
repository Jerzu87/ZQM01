*&---------------------------------------------------------------------*
*&  Include           Z_QM_ACTIVE_WI_CLASS
*&---------------------------------------------------------------------*
CLASS alv_event_handlers DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      double_click
        FOR EVENT double_click OF cl_gui_alv_grid
        IMPORTING es_row_no.
ENDCLASS.                    "alv_event_handlers DEFINITION
