  METHOD if_apj_rt_exec_object~execute.
    TRY.
        mo_log = cl_bali_log=>create_with_header( cl_bali_header_setter=>create( object = 'YEHO_APP_LOG'
                                                                                 subobject = 'YEHO_AUTOMATIC' ) ).
      CATCH cx_bali_runtime INTO DATA(lx_bali_runtime).
    ENDTRY.
    LOOP AT it_parameters INTO DATA(ls_parameter).
      CASE ls_parameter-selname.
        WHEN 'P_CCODE'.
          mv_companycode = CONV bukrs( ls_parameter-low ).
        WHEN 'S_GLACC'.
          APPEND INITIAL LINE TO mt_glaccount_range ASSIGNING FIELD-SYMBOL(<ls_glaccount_range>).
          <ls_glaccount_range> = CORRESPONDING #( ls_parameter ).
        WHEN 'P_DATE'.
          mv_date = CONV d( ls_parameter-low ).
          IF mv_date IS INITIAL OR mv_date = '00000000'.
            mv_date = ycl_eho_utils=>get_local_time(  )-date.
          ENDIF.
      ENDCASE.
    ENDLOOP.

    DATA(lo_message) = cl_bali_message_setter=>create( severity = if_bali_constants=>c_severity_information
                                                       id = ycl_eho_utils=>mc_message_class
                                                       number = 001
                                                       variable_1 = |Job çalışma tarihi { mv_date }| ).
    mo_log->add_item( lo_message ).

    LOOP AT mt_glaccount_range ASSIGNING FIELD-SYMBOL(<ls_glaccount>).
      IF <ls_glaccount>-low IS NOT INITIAL.
        <ls_glaccount>-low = |{ <ls_glaccount>-low ALPHA = IN }|.
      ENDIF.
      IF <ls_glaccount>-high IS NOT INITIAL.
        <ls_glaccount>-high = |{ <ls_glaccount>-high ALPHA = IN }|.
      ENDIF.
    ENDLOOP.
    get_items(  ).
    IF mt_automatic_items IS INITIAL.
      lo_message = cl_bali_message_setter=>create( severity = if_bali_constants=>c_severity_information
                                                         id = ycl_eho_utils=>mc_message_class
                                                         number = 022 ) .
      mo_log->add_item( lo_message ).
    ELSE.
      get_rule( CHANGING ct_items = mt_automatic_items ).
    ENDIF.
    DELETE mt_automatic_items WHERE rule_no IS INITIAL.
    IF mt_automatic_items IS INITIAL.
      lo_message = cl_bali_message_setter=>create( severity = if_bali_constants=>c_severity_information
                                                         id = ycl_eho_utils=>mc_message_class
                                                         number = 024 ) .
      mo_log->add_item( lo_message ).
    ELSE.
      create_journal_entry(  ).
    ENDIF.
    TRY.
        cl_bali_log_db=>get_instance( )->save_log( log = mo_log assign_to_current_appl_job = abap_true ).
      CATCH cx_bali_runtime.
    ENDTRY.
  ENDMETHOD.