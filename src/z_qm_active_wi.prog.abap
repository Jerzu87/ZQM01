*&---------------------------------------------------------------------*
*& Report  Z_QM_ACTIVE_WI
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT z_qm_active_wi MESSAGE-ID zqm.

INCLUDE z_qm_active_wi_data.
INCLUDE zqmforms.
INCLUDE z_qm_active_wi_class.
INCLUDE z_qm_active_wi_sscr.
INCLUDE z_qm_active_wi_form.
INCLUDE z_qm_active_wi_s100.

START-OF-SELECTION.

  PERFORM read_data CHANGING sy-subrc.
  CHECK sy-subrc IS INITIAL.

  PERFORM display_data.
