*&---------------------------------------------------------------------*
*&  Include           Z_QM_ACTIVE_WI_FORM
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  set_pf_status_1000
*&---------------------------------------------------------------------*
*       [Tomzo] 29.09.2022 DAIP-3147
*----------------------------------------------------------------------*
FORM set_pf_status_1000.

  DATA:
    lt_excl TYPE STANDARD TABLE OF sy-ucomm.

  CHECK sy-tcode(1) = 'Z' AND sy-tcode NE 'ZQM_ACT_WI'.

  APPEND 'SPOS' TO lt_excl.
  APPEND 'GET'  TO lt_excl.
  APPEND 'VSHO' TO lt_excl.
  APPEND 'VDEL' TO lt_excl.

  CALL FUNCTION 'RS_SET_SELSCREEN_STATUS'
    EXPORTING
      p_status  = sy-pfkey
    TABLES
      p_exclude = lt_excl.

ENDFORM.                    "set_pf_status_1000

*&---------------------------------------------------------------------*
*&      Form  read_data
*&---------------------------------------------------------------------*
FORM read_data CHANGING value(p_subrc) TYPE sy-subrc.

  p_subrc = 4.

  TYPES:
    BEGIN OF t_qm_key,
      qmnum TYPE qmnum,
      manum TYPE manum,
    END OF t_qm_key.

  DATA:
    lt_swwuserwi TYPE STANDARD TABLE OF swwuserwi,
    lt_swhactor TYPE STANDARD TABLE OF swhactor.

  DATA:
    lr_uname TYPE RANGE OF swwuserwi-user_id,
    lr_typeid TYPE RANGE OF sww_wi2obj-typeid.

  DATA:
    ls_wi_user_data LIKE LINE OF gt_wi_user_data,
    ls_uname LIKE LINE OF lr_uname,
    ls_typeid LIKE LINE OF lr_typeid,
    ls_swwwihead TYPE swwwihead,
    ls_sww_wi2obj TYPE sww_wi2obj,
    ls_swwwideadl TYPE swwwideadl,
    ls_qm_key TYPE t_qm_key,
    ls_qmel TYPE qmel.

  DATA:
    lv_no_deadl TYPE xfeld,
    lv_otype LIKE swhactor-otype,
    lv_objid LIKE swhactor-objid.

  FIELD-SYMBOLS:
    <swwuserw> LIKE LINE OF lt_swwuserwi,
    <swhactor> LIKE LINE OF lt_swhactor,
    <wi_user> LIKE LINE OF gt_wi_user_data.

  CLEAR: gt_wi_user_data[], lr_uname[], lr_typeid[], ls_typeid, ls_uname.

  ls_typeid-sign = 'I'.
  ls_typeid-option = 'EQ'.
  IF ( NOT p_bus IS INITIAL ).
    ls_typeid-low = c_bus2078.
    APPEND ls_typeid TO lr_typeid.
  ENDIF.

  IF ( NOT p_qmsm IS INITIAL ).
    ls_typeid-low = c_zqmsm.
    APPEND ls_typeid TO lr_typeid.
  ENDIF.

  IF ( lr_typeid[] IS INITIAL ).
    MESSAGE s052 DISPLAY LIKE 'W'.
    EXIT.
  ENDIF.

  IF ( p_user IS INITIAL ).
    IF p_orgu IS INITIAL.
      MESSAGE s049 DISPLAY LIKE 'W'.
      EXIT.
    ENDIF.

    lv_otype = 'O'.
    lv_objid = p_orgu.

    CALL FUNCTION 'SWI_GET_USERS_OF_ORG_UNIT'
      EXPORTING
        otype           = lv_otype
        objid           = lv_objid
      TABLES
        user_list       = lt_swhactor
      EXCEPTIONS
        not_found       = 1
        no_active_plvar = 2
        OTHERS          = 3.
    IF ( NOT sy-subrc IS INITIAL ).
      MESSAGE s051 WITH lv_objid DISPLAY LIKE 'E'.
      EXIT.
    ENDIF.

    ls_uname-sign = 'I'.
    ls_uname-option = 'EQ'.
    LOOP AT lt_swhactor ASSIGNING <swhactor>.
      ls_uname-low = <swhactor>-objid.
      APPEND ls_uname TO lr_uname.
    ENDLOOP.
  ELSE.
    IF p_uname IS INITIAL.
      MESSAGE s050 DISPLAY LIKE 'W'.
      EXIT.
    ENDIF.
    ls_uname-sign = 'I'.
    ls_uname-option = 'EQ'.
    ls_uname-low = p_uname.
    APPEND ls_uname TO lr_uname.
  ENDIF.

  SELECT * INTO TABLE lt_swwuserwi
    FROM swwuserwi
    WHERE user_id IN lr_uname
    AND no_sel = space.

  IF ( NOT sy-subrc IS INITIAL ).
    MESSAGE s047(ih) DISPLAY LIKE 'W'.
    EXIT.
  ENDIF.

  LOOP AT lt_swwuserwi ASSIGNING <swwuserw>.
    CLEAR:
      ls_wi_user_data, ls_swwwihead, ls_sww_wi2obj, lv_no_deadl.

    ls_wi_user_data-uname = <swwuserw>-user_id.
    ls_wi_user_data-wi_id = <swwuserw>-wi_id.
    ls_wi_user_data-wi_rh_task = <swwuserw>-task_obj.

    SELECT SINGLE * INTO ls_swwwihead
      FROM swwwihead
      WHERE wi_id = <swwuserw>-wi_id.
    IF sy-subrc IS INITIAL.
      CHECK ls_swwwihead-wi_type = 'W'.
      IF ( NOT s_datum[] IS INITIAL ).
        CHECK ls_swwwihead-wi_cd IN s_datum.
      ENDIF.

      ls_wi_user_data-wi_type = ls_swwwihead-wi_type.
      ls_wi_user_data-wi_text = ls_swwwihead-wi_text.
      ls_wi_user_data-wi_cd   = ls_swwwihead-wi_cd.
      ls_wi_user_data-wi_ct   = ls_swwwihead-wi_ct.
      ls_wi_user_data-wi_stat = ls_swwwihead-wi_stat.
      lv_no_deadl             = ls_swwwihead-no_deadl.
    ELSE.
      "MESSAGE s045(im) WITH <swwuserw>-wi_id 'SWWWIHEAD' DISPLAY LIKE 'E'.
      CONTINUE.
    ENDIF.

    SELECT SINGLE * INTO ls_sww_wi2obj
      FROM sww_wi2obj
      WHERE wi_id = <swwuserw>-wi_id
      AND removed = space.
    IF sy-subrc IS INITIAL.
      ls_wi_user_data-catid = ls_sww_wi2obj-catid.
      ls_wi_user_data-instid = ls_sww_wi2obj-instid.
      ls_wi_user_data-typeid = ls_sww_wi2obj-typeid.
    ELSEIF ( NOT ls_swwwihead-wi_chckwi IS INITIAL ).
      SELECT SINGLE * INTO ls_sww_wi2obj
        FROM sww_wi2obj
        WHERE wi_id = ls_swwwihead-wi_chckwi
        AND removed = space.
      IF sy-subrc IS INITIAL.
        ls_wi_user_data-catid = ls_sww_wi2obj-catid.
        ls_wi_user_data-instid = ls_sww_wi2obj-instid.
        ls_wi_user_data-typeid = ls_sww_wi2obj-typeid.
      ENDIF.
    ENDIF.

    CHECK ( ls_wi_user_data-catid EQ 'BO' ).
    CHECK ( ls_wi_user_data-typeid IN lr_typeid ).

    IF ( p_deadl = 'X' ) AND ( lv_no_deadl IS INITIAL ).
      SELECT SINGLE * INTO ls_swwwideadl
        FROM swwwideadl
        WHERE wi_id = <swwuserw>-wi_id.

      IF sy-subrc IS INITIAL.
        ls_wi_user_data-wi_lsd = ls_swwwideadl-wi_lsd.
        ls_wi_user_data-wi_lst = ls_swwwideadl-wi_lst.
        ls_wi_user_data-wi_led = ls_swwwideadl-wi_led.
        ls_wi_user_data-wi_let = ls_swwwideadl-wi_let.
      ENDIF.
    ENDIF.

    APPEND ls_wi_user_data TO gt_wi_user_data.
  ENDLOOP.

  SORT gt_wi_user_data BY catid typeid instid uname.

  IF NOT p_ext IS INITIAL.
    CLEAR: ls_qmel, ls_qm_key.
    LOOP AT gt_wi_user_data ASSIGNING <wi_user>.
      CHECK ( <wi_user>-catid EQ 'BO' ).
      CHECK ( <wi_user>-typeid EQ c_bus2078 ) OR ( <wi_user>-typeid EQ c_zqmsm ).

      MOVE <wi_user>-instid TO ls_qm_key.
      IF ( ls_qm_key-qmnum NE ls_qmel-qmnum ).
        SELECT SINGLE * INTO ls_qmel
          FROM qmel
          WHERE qmnum = ls_qm_key-qmnum.
      ENDIF.
      MOVE-CORRESPONDING ls_qmel TO <wi_user>.

      "2014.03.06: Marcin -> kraj zleceniodawcy z faktury
      IF ( p_land1 EQ 'X' ).
        SELECT SINGLE land1 INTO <wi_user>-land1
          FROM vbpa
          WHERE vbeln = <wi_user>-vbeln_vf
          AND parvw = 'AG'.
        IF ( NOT sy-subrc IS INITIAL ).
          CLEAR <wi_user>-land1.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF ( gt_wi_user_data[] IS INITIAL ).
    MESSAGE s047(ih) DISPLAY LIKE 'W'.
  ELSE.
    CLEAR p_subrc.
  ENDIF.

ENDFORM.                    "read_data

*&---------------------------------------------------------------------*
*&      Form  display_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM display_data.

  DATA:
     lt_fcat TYPE lvc_t_fcat.

  DATA:
     lr_fieldname TYPE RANGE OF lvc_s_fcat-fieldname.

  DATA:
     ls_fieldname LIKE LINE OF lr_fieldname,
     ls_alv_data LIKE LINE OF gt_alv_data,
     ls_wi_user_data LIKE LINE OF gt_wi_user_data,
     ls_fcat LIKE LINE OF g_scr0100-t_fcat.

  DATA:
     lv_icon TYPE icon_d,
     lv_i TYPE i.

  FIELD-SYMBOLS:
    <fcat> LIKE LINE OF g_scr0100-t_fcat.

  CLEAR: gt_alv_data[].

  LOOP AT gt_wi_user_data INTO ls_wi_user_data.
    CLEAR ls_alv_data.
    MOVE-CORRESPONDING ls_wi_user_data TO ls_alv_data.

    "ikona statusu
    CASE ls_alv_data-wi_stat.
      WHEN 'WAITING'.
        lv_icon = icon_wf_workitem_waiting.
      WHEN 'READY'.
        lv_icon = icon_wf_workitem_ready.
      WHEN 'COMPLETED'.
        lv_icon = icon_wf_workitem_completed.
      WHEN 'STARTED'.
        lv_icon = icon_wf_workitem_started.
      WHEN 'COMMITTED'.
        lv_icon = icon_wf_workitem_committed.
      WHEN 'CANCELLED'.
        lv_icon = icon_wf_workitem_cancel.
      WHEN OTHERS.
        "ERROR,EXCPCAUGHT,EXCPHANDLR,SELECTED,CHECKED
        lv_icon = icon_wf_workitem_error.
    ENDCASE.
    PERFORM get_icon_with_quickinfo USING lv_icon CHANGING ls_alv_data-ico_wi_stat.

    "ikona terminu
    IF ( NOT p_deadl IS INITIAL ).
      IF ( ls_alv_data-wi_led IS INITIAL ) OR ( ls_alv_data-wi_let IS INITIAL ).
        lv_icon = icon_checked.
      ELSE.
        IF ( ls_alv_data-wi_led < sy-datum ).
          lv_icon = icon_red_light.
        ELSEIF ( ls_alv_data-wi_led = sy-datum ).
          lv_icon = icon_yellow_light.
        ELSE.
          lv_icon = icon_green_light.
        ENDIF.
      ENDIF.
      PERFORM get_icon_with_quickinfo USING lv_icon CHANGING ls_alv_data-ico_wi_dead.
    ENDIF.

    APPEND ls_alv_data TO gt_alv_data.
  ENDLOOP.

  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = 'ZACT_WI_USER_DATA'
    CHANGING
      ct_fieldcat            = g_scr0100-t_fcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2.

  IF NOT sy-subrc IS INITIAL.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  "domyslne ukryte
  CLEAR: lr_fieldname[], ls_fieldname.
  ls_fieldname-sign = 'I'.
  ls_fieldname-option = 'EQ'.
  ls_fieldname-low = 'UNAME'.      APPEND ls_fieldname TO lr_fieldname.
  ls_fieldname-low = 'WI_TEXT'.    APPEND ls_fieldname TO lr_fieldname.
  ls_fieldname-low = 'WI_CD'.      APPEND ls_fieldname TO lr_fieldname.
  ls_fieldname-low = 'WI_CT'.      APPEND ls_fieldname TO lr_fieldname.
  ls_fieldname-low = 'WI_RH_TASK'. APPEND ls_fieldname TO lr_fieldname.

  "Ikona statusu
  CLEAR: ls_fcat.
  ls_fcat-icon = 'X'.
  ls_fcat-dd_outlen = 10.
  ls_fcat-fieldname = 'ICO_WI_STAT'.
  ls_fcat-reptext = 'St. poz. rob.'(005).
  INSERT ls_fcat INTO g_scr0100-t_fcat INDEX 1.
  ls_fieldname-low = ls_fcat-fieldname.
  APPEND ls_fieldname TO lr_fieldname.

  "ikona terminu
  IF ( p_deadl IS INITIAL ).
    DELETE g_scr0100-t_fcat WHERE fieldname = 'WI_LSD'.
    DELETE g_scr0100-t_fcat WHERE fieldname = 'WI_LST'.
    DELETE g_scr0100-t_fcat WHERE fieldname = 'WI_LED'.
    DELETE g_scr0100-t_fcat WHERE fieldname = 'WI_LET'.
  ELSE.
    CLEAR ls_fcat.
    ls_fcat-icon = 'X'.
    ls_fcat-dd_outlen = 10.
    ls_fcat-fieldname = 'ICO_WI_DEAD'.
    ls_fcat-reptext = 'St. terminu'(004).
    INSERT ls_fcat INTO g_scr0100-t_fcat INDEX 2.
    ls_fieldname-low = ls_fcat-fieldname. APPEND ls_fieldname TO lr_fieldname.
    ls_fieldname-low = 'WI_LSD'. APPEND ls_fieldname TO lr_fieldname.
    ls_fieldname-low = 'WI_LST'. APPEND ls_fieldname TO lr_fieldname.
    ls_fieldname-low = 'WI_LED'. APPEND ls_fieldname TO lr_fieldname.
    ls_fieldname-low = 'WI_LET'. APPEND ls_fieldname TO lr_fieldname.
  ENDIF.


  IF NOT p_ext IS INITIAL.
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = 'QMEL'
      CHANGING
        ct_fieldcat            = lt_fcat
      EXCEPTIONS
        inconsistent_interface = 1
        program_error          = 2.

    IF NOT sy-subrc IS INITIAL.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 DISPLAY LIKE 'E'.
      EXIT.
    ENDIF.

    READ TABLE lt_fcat ASSIGNING <fcat> WITH KEY fieldname = 'QMNUM'.
    IF sy-subrc IS INITIAL.
      CLEAR <fcat>-key.
    ENDIF.

    "2014.03.06: Marcin -> kraj zleceniodawcy
    IF ( p_land1 EQ 'X' ).
      CLEAR ls_fcat.
      CALL FUNCTION 'Z_GET_FCAT_FOR_FIELD'
        EXPORTING
          fvi_tabname   = 'KNA1'
          fvi_fieldname = 'LAND1'
        IMPORTING
          fso_fcat      = ls_fcat
        EXCEPTIONS
          error         = 1
          OTHERS        = 2.
      IF ( sy-subrc IS INITIAL ).
        APPEND ls_fcat TO g_scr0100-t_fcat.
        ls_fieldname-low = 'LAND1'. APPEND ls_fieldname TO lr_fieldname.
      ENDIF.
    ENDIF.

    APPEND LINES OF lt_fcat TO g_scr0100-t_fcat.

    ls_fieldname-low = 'QMNUM'. APPEND ls_fieldname TO lr_fieldname.
    ls_fieldname-low = 'QMTXT'. APPEND ls_fieldname TO lr_fieldname.
    ls_fieldname-low = 'KUNUM'. APPEND ls_fieldname TO lr_fieldname.
    ls_fieldname-low = 'MATNR'. APPEND ls_fieldname TO lr_fieldname.
    ls_fieldname-low = 'VBELN_VF'. APPEND ls_fieldname TO lr_fieldname.
    ls_fieldname-low = 'POSNR_VF'. APPEND ls_fieldname TO lr_fieldname.
  ENDIF.

  "przepisac pozycje
  LOOP AT g_scr0100-t_fcat ASSIGNING <fcat>.
    <fcat>-col_pos = sy-tabix.
    "poukrywac pola
    IF ( NOT <fcat>-fieldname IN lr_fieldname ).
      <fcat>-no_out = 'X'.
    ENDIF.
  ENDLOOP.

  CALL SCREEN 0100.
ENDFORM.                    "display_data

*&---------------------------------------------------------------------*
*&      Form  get_icon_with_quickinfo
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ICON     text
*      -->P_ALV_ICO  text
*----------------------------------------------------------------------*
FORM get_icon_with_quickinfo USING p_icon TYPE icon_d
                             CHANGING p_alv_ico.
  DATA:
    lv_quick TYPE iconshort.

  SELECT SINGLE shorttext INTO lv_quick
    FROM icont
    WHERE langu = sy-langu
    AND id = p_icon.

  IF ( NOT sy-subrc IS INITIAL ).
    lv_quick = '?'.
  ENDIF.

  CONCATENATE p_icon(3) '\Q' lv_quick p_icon+3(1) INTO p_alv_ico.

ENDFORM.                    "get_icon_with_quickinfo
*&---------------------------------------------------------------------*
*&      Form  GET_ORGUNIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_hractor USING p_nrart TYPE nrart
                 CHANGING p_parnr.

  DATA:
    lv_parnr TYPE i_parnr.

  CALL FUNCTION 'SEARCH_OM_PARTNER'
    EXPORTING
      act_nrart       = p_nrart
      search_string   = p_parnr
    IMPORTING
      sel_parnr       = lv_parnr
    EXCEPTIONS
      no_active_plvar = 1
      not_selected    = 2
      no_om_otype     = 3
      OTHERS          = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  IF ( NOT lv_parnr IS INITIAL ).
    p_parnr = lv_parnr.
  ENDIF.

ENDFORM.                    " GET_ORGUNIT

*&---------------------------------------------------------------------*
*&      Form  get_selected_rows
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->FO_ROWS    text
*----------------------------------------------------------------------*
FORM get_selected_rows TABLES fo_rows LIKE gt_alv_data.

  DATA:
    lt_rows TYPE lvc_t_roid.

  DATA:
    ls_roid TYPE lvc_s_roid.

  FIELD-SYMBOLS:
    <row>   LIKE LINE OF lt_rows,
    <alv> LIKE LINE OF gt_alv_data.

  CALL METHOD g_scr0100-obj_alv->get_selected_rows
    IMPORTING
      et_row_no = lt_rows.

  LOOP AT lt_rows ASSIGNING <row>.
    READ TABLE gt_alv_data ASSIGNING <alv> INDEX <row>-row_id.
    CHECK sy-subrc = 0.
    APPEND <alv> TO fo_rows.
  ENDLOOP.

ENDFORM.                    "get_selected_rows
*&---------------------------------------------------------------------*
*&      Form  display_obj
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM display_obj.

  DATA:
    lt_alv_data LIKE gt_alv_data.

  DATA:
    ls_alv_data LIKE LINE OF lt_alv_data.

  CLEAR lt_alv_data.
  PERFORM get_selected_rows TABLES lt_alv_data.
  IF lt_alv_data IS INITIAL.
    MESSAGE e011(z_w05_spd).
  ENDIF.

  IF lines( lt_alv_data ) > 1.
    MESSAGE e047.
  ENDIF.

  READ TABLE lt_alv_data INTO ls_alv_data INDEX 1.
  CHECK sy-subrc IS INITIAL.

  PERFORM display_sel_object USING ls_alv_data.

ENDFORM.                    "display_obj
*&---------------------------------------------------------------------*
*&      Form  display_sel_object
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ALV_DATA text
*----------------------------------------------------------------------*
FORM display_sel_object USING p_alv_data TYPE t_alv_data.

  DATA:
    BEGIN OF ls_qmsm_key,
      qmnum TYPE qmnum,
      manum TYPE manum,
    END OF ls_qmsm_key.

  IF ( p_alv_data-catid NE 'BO' ) OR ( p_alv_data-instid IS INITIAL ).
    MESSAGE e048.
  ENDIF.

  CASE p_alv_data-typeid.
    WHEN c_bus2078.
      MOVE p_alv_data-instid TO ls_qmsm_key.
      PERFORM display_bus2078 USING ls_qmsm_key-qmnum.
    WHEN c_zqmsm.
      MOVE p_alv_data-instid TO ls_qmsm_key.
      PERFORM display_qmsm USING ls_qmsm_key-qmnum ls_qmsm_key-manum.
  ENDCASE.
ENDFORM.                    "display_sel_object
* 2014.03.06: Marcin -> przeniesione do ZQMFORMS
**&---------------------------------------------------------------------*
**&      Form  display_bus2078
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**      -->P_QMNUM    text
**----------------------------------------------------------------------*
*FORM display_bus2078 USING p_qmnum TYPE qmnum.
*
*  SET PARAMETER ID 'IQM' FIELD p_qmnum.
*  CALL TRANSACTION 'QM03' AND SKIP FIRST SCREEN.
*
*ENDFORM.                    "display_bus2078
**&---------------------------------------------------------------------*
**&      Form  display_qmsm
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**      -->P_QMNUM    text
**      -->P_MANUM    text
**----------------------------------------------------------------------*
*FORM display_qmsm USING p_qmnum TYPE qmnum
*                        p_manum TYPE manum.
*
*  DATA:
*    lv_fenum TYPE viqmsm-fenum.
*
*  SELECT SINGLE fenum INTO lv_fenum
*    FROM viqmsm
*    WHERE qmnum = p_qmnum
*    AND manum = p_manum.
*
*  CHECK sy-subrc IS INITIAL.
*
*  EXPORT lv_fenum p_manum TO MEMORY ID 'WF'.
*
*  SET PARAMETER ID 'IQM' FIELD p_qmnum.
*  SET PARAMETER ID 'IMA' FIELD p_manum.
*  SET PARAMETER ID 'IFE' FIELD lv_fenum.
*  CALL TRANSACTION 'IQS13' AND SKIP FIRST SCREEN.
*
*ENDFORM.                    "display_qmsm
*----------------------------------------------------------------------*
*       CLASS alv_event_handlers IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS alv_event_handlers IMPLEMENTATION.
  METHOD double_click.

    DATA:
      ls_alv_data LIKE LINE OF gt_alv_data.

    READ TABLE gt_alv_data INTO ls_alv_data INDEX es_row_no-row_id.
    IF sy-subrc IS INITIAL.
      PERFORM display_sel_object USING ls_alv_data.
    ENDIF.
  ENDMETHOD.                    "double_click
ENDCLASS.                    "alv_event_handlers IMPLEMENTATION
