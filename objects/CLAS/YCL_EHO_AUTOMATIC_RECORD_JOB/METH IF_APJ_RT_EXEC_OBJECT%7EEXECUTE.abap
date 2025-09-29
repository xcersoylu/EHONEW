  METHOD if_apj_rt_exec_object~execute.
    LOOP AT it_parameters INTO DATA(ls_parameter).
      CASE ls_parameter-selname.
        WHEN 'P_CCODE'.
          mv_companycode = CONV bukrs( ls_parameter-low ).
        WHEN 'S_GLACC'.
          APPEND INITIAL LINE TO mt_glaccount_range ASSIGNING FIELD-SYMBOL(<ls_glaccount_range>).
          <ls_glaccount_range> = CORRESPONDING #( ls_parameter ).
        WHEN 'P_DATE'.
          mv_date = CONV d( ls_parameter-low ).
          IF mv_date IS INITIAL.
            mv_date = ycl_eho_utils=>get_local_time(  )-date.
          ENDIF.
      ENDCASE.
    ENDLOOP.

    LOOP AT mt_glaccount_range ASSIGNING FIELD-SYMBOL(<ls_glaccount>).
      IF <ls_glaccount>-low IS NOT INITIAL.
        <ls_glaccount>-low = |{ <ls_glaccount>-low ALPHA = IN }|.
      ENDIF.
      IF <ls_glaccount>-high IS NOT INITIAL.
        <ls_glaccount>-high = |{ <ls_glaccount>-high ALPHA = IN }|.
      ENDIF.
    ENDLOOP.
    get_items(  ).
    IF mt_automatic_items IS NOT INITIAL.
      get_rule( CHANGING ct_items = mt_automatic_items ).
    ENDIF.
    DELETE mt_automatic_items WHERE rule_no IS INITIAL.
    IF mt_automatic_items IS NOT INITIAL.
      create_journal_entry(  ).
    ENDIF.
  ENDMETHOD.