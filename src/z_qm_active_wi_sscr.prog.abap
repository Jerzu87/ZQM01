*&---------------------------------------------------------------------*
*&  Include           Z_QM_ACTIVE_WI_SSCR
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK stype WITH FRAME TITLE text-001.

PARAMETER:
  p_user RADIOBUTTON GROUP rg1 USER-COMMAND rg1 DEFAULT 'X',
  p_unit RADIOBUTTON GROUP rg1.

SELECTION-SCREEN END OF BLOCK stype.

SELECTION-SCREEN BEGIN OF BLOCK main WITH FRAME TITLE text-002.

PARAMETER:
  p_uname TYPE syuname MODIF ID usr,
  p_orgu TYPE hrobjid MODIF ID grp,
  p_deadl TYPE xfeld AS CHECKBOX DEFAULT space.

SELECT-OPTIONS:
  s_datum FOR swwwihead-wi_cd.

SELECTION-SCREEN END OF BLOCK main.

SELECTION-SCREEN BEGIN OF BLOCK add WITH FRAME TITLE text-003.

PARAMETER:
  p_bus TYPE xfeld AS CHECKBOX DEFAULT space,
  p_qmsm TYPE xfeld AS CHECKBOX DEFAULT 'X',
  p_ext TYPE xfeld AS CHECKBOX DEFAULT space USER-COMMAND rg1.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 6.
PARAMETER:
  p_land1 TYPE xfeld AS CHECKBOX DEFAULT 'X' MODIF ID ext.
SELECTION-SCREEN COMMENT 26(40) FOR FIELD p_land1 MODIF ID ext.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK add.

AT SELECTION-SCREEN OUTPUT.
  PERFORM set_pf_status_1000.  " [Tomzo] 29.09.2022 DAIP-3147
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'USR'.
        IF p_user = 'X'.
          screen-active = 1.
        ELSE.
          screen-active = 0.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'GRP'.
        IF p_unit = 'X'.
          screen-active = 1.
        ELSE.
          screen-active = 0.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'EXT'.
        IF p_ext = 'X'.
          screen-active = 1.
        ELSE.
          screen-active = 0.
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_orgu.
  PERFORM get_hractor USING 'O' CHANGING p_orgu.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_uname.
  PERFORM get_hractor USING 'US' CHANGING p_uname.
