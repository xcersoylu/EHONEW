  METHOD create_journal_entry.
    TYPES : BEGIN OF ty_currencyamount,
              currencyrole           TYPE string,
              journalentryitemamount TYPE yeho_e_wrbtr,
              currency               TYPE waers,
            END OF ty_currencyamount.
    TYPES tt_currencyamount TYPE TABLE OF ty_currencyamount WITH EMPTY KEY.
    TYPES : BEGIN OF ty_glitem,
              glaccountlineitem             TYPE string,
              glaccount                     TYPE saknr,
              assignmentreference           TYPE dzuonr,
              reference1idbybusinesspartner TYPE xref1,
              reference2idbybusinesspartner TYPE xref2,
              reference3idbybusinesspartner TYPE xref3,
              costcenter                    TYPE kostl,
              orderid                       TYPE aufnr,
              documentitemtext              TYPE sgtxt,
              specialglcode                 TYPE yeho_e_umskz,
              _currencyamount               TYPE tt_currencyamount,
            END OF ty_glitem,
            BEGIN OF ty_aritems, "kunnr
              glaccountlineitem             TYPE string,
              customer                      TYPE kunnr,
              glaccount                     TYPE hkont,
              paymentmethod                 TYPE dzlsch,
              paymentterms                  TYPE dzterm,
              assignmentreference           TYPE dzuonr,
              profitcenter                  TYPE prctr,
              creditcontrolarea             TYPE kkber,
              reference1idbybusinesspartner TYPE xref1,
              reference2idbybusinesspartner TYPE xref2,
              reference3idbybusinesspartner TYPE xref3,
              documentitemtext              TYPE sgtxt,
              specialglcode                 TYPE yeho_e_umskz,
              _currencyamount               TYPE tt_currencyamount,
            END OF ty_aritems,
            BEGIN OF ty_apitems, "lifnr
              glaccountlineitem             TYPE string,
              supplier                      TYPE lifnr,
              glaccount                     TYPE hkont,
              paymentmethod                 TYPE dzlsch,
              paymentterms                  TYPE dzterm,
              assignmentreference           TYPE dzuonr,
              profitcenter                  TYPE prctr,
              creditcontrolarea             TYPE kkber,
              reference1idbybusinesspartner TYPE xref1,
              reference2idbybusinesspartner TYPE xref2,
              reference3idbybusinesspartner TYPE xref3,
              documentitemtext              TYPE sgtxt,
              specialglcode                 TYPE yeho_e_umskz,
              _currencyamount               TYPE tt_currencyamount,
            END OF ty_apitems.

    DATA lt_je             TYPE TABLE FOR ACTION IMPORT i_journalentrytp~post.
    DATA lt_glitem         TYPE TABLE OF ty_glitem.
    DATA lt_apitem         TYPE TABLE OF ty_apitems.
    DATA lt_aritem         TYPE TABLE OF ty_aritems.
    DATA lt_saved_receipts TYPE TABLE OF yeho_t_savedrcpt.

    TRY.
        DATA(lo_log) = cl_bali_log=>create_with_header( cl_bali_header_setter=>create( object = 'YEHO_APP_LOG'
                                                                                       subobject = 'YEHO_AUTOMATIC' ) ).
      CATCH cx_bali_runtime INTO DATA(lx_bali_runtime).
        DATA(lo_free) = cl_bali_free_text_setter=>create( severity = if_bali_constants=>c_severity_warning
                                                          text     = CONV #( lx_bali_runtime->get_text(  ) ) ).
        TRY.
            lo_log->add_item( lo_free ).
          CATCH cx_bali_runtime INTO lx_bali_runtime.
            lo_free = cl_bali_free_text_setter=>create( severity = if_bali_constants=>c_severity_warning
                                                             text     = CONV #( lx_bali_runtime->get_text(  ) ) ).
        ENDTRY.
    ENDTRY.

    LOOP AT mt_automatic_items ASSIGNING FIELD-SYMBOL(<ls_item>).
      APPEND INITIAL LINE TO lt_je ASSIGNING FIELD-SYMBOL(<fs_je>).
      TRY.
          <fs_je>-%cid = to_upper( cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ) ).
          APPEND VALUE #( glaccountlineitem             = |001|
                          glaccount                     = <ls_item>-rule_data-account_no_102
                          assignmentreference           = <ls_item>-rule_data-assignmentreference
                          reference1idbybusinesspartner = <ls_item>-rule_data-reference1idbybusinesspartner
                          reference2idbybusinesspartner = <ls_item>-rule_data-reference2idbybusinesspartner
                          reference3idbybusinesspartner = <ls_item>-rule_data-reference3idbybusinesspartner
                          costcenter                    = <ls_item>-rule_data-costcenter
                          documentitemtext              = <ls_item>-rule_data-documentitemtext_1
                          _currencyamount = VALUE #( ( currencyrole = '00'
                                                      journalentryitemamount = <ls_item>-amount
                                                      currency = <ls_item>-currency  ) )          ) TO lt_glitem.
          IF <ls_item>-rule_data-supplier IS NOT INITIAL.
            APPEND VALUE #( glaccountlineitem             = |002|
                            supplier                      = <ls_item>-rule_data-supplier
*                            glaccount                     = <ls_item>-rule_data-reconciliationaccount
                            paymentmethod                 = <ls_item>-rule_data-paymentmethod
                            paymentterms                  = <ls_item>-rule_data-paymentterms
                            assignmentreference           = <ls_item>-rule_data-assignmentreference
                            profitcenter                  = <ls_item>-rule_data-profitcenter
***                            creditcontrolarea             = <ls_item>-creditcontrolarea
                            reference1idbybusinesspartner = <ls_item>-rule_data-reference1idbybusinesspartner
                            reference2idbybusinesspartner = <ls_item>-rule_data-reference2idbybusinesspartner
                            reference3idbybusinesspartner = <ls_item>-rule_data-reference3idbybusinesspartner
                            documentitemtext              = <ls_item>-rule_data-documentitemtext_2
                            specialglcode                 = <ls_item>-rule_data-specialglcode
                            _currencyamount = VALUE #( ( currencyrole = '00'
                                                       journalentryitemamount = -1 * <ls_item>-amount
                                                       currency = <ls_item>-currency  ) ) ) TO lt_apitem.
          ELSEIF <ls_item>-rule_data-customer IS NOT INITIAL.
            APPEND VALUE #( glaccountlineitem              = |002|
                            customer                       = <ls_item>-rule_data-customer
*                             glaccount                     = <ls_item>-rule_data-reconciliationaccount
                             paymentmethod                 = <ls_item>-rule_data-paymentmethod
                             paymentterms                  = <ls_item>-rule_data-paymentterms
                             assignmentreference           = <ls_item>-rule_data-assignmentreference
                             profitcenter                  = <ls_item>-rule_data-profitcenter
***                             creditcontrolarea             = <ls_item>-creditcontrolarea
                             reference1idbybusinesspartner = <ls_item>-rule_data-reference1idbybusinesspartner
                             reference2idbybusinesspartner = <ls_item>-rule_data-reference2idbybusinesspartner
                             reference3idbybusinesspartner = <ls_item>-rule_data-reference3idbybusinesspartner
                             documentitemtext              = <ls_item>-rule_data-documentitemtext_2
                             specialglcode                 = <ls_item>-rule_data-specialglcode
                            _currencyamount = VALUE #( ( currencyrole = '00'
                                                        journalentryitemamount = -1 * <ls_item>-amount
                                                        currency = <ls_item>-currency  ) ) ) TO lt_aritem.
          ELSEIF <ls_item>-rule_data-account_no IS NOT INITIAL.
            APPEND VALUE #( glaccountlineitem             = |002|
                            glaccount                     = <ls_item>-rule_data-account_no
                            assignmentreference           = <ls_item>-rule_data-assignmentreference
                            reference1idbybusinesspartner = <ls_item>-rule_data-reference1idbybusinesspartner
                            reference2idbybusinesspartner = <ls_item>-rule_data-reference2idbybusinesspartner
                            reference3idbybusinesspartner = <ls_item>-rule_data-reference3idbybusinesspartner
                            costcenter                    = <ls_item>-rule_data-costcenter
                            orderid                       = <ls_item>-rule_data-orderid
                            documentitemtext              = <ls_item>-rule_data-documentitemtext_2
                            specialglcode                 = <ls_item>-rule_data-specialglcode
                            _currencyamount = VALUE #( ( currencyrole = '00'
                                                        journalentryitemamount = -1 * <ls_item>-amount
                                                        currency = <ls_item>-currency  ) )          ) TO lt_glitem.
          ENDIF.
          <fs_je>-%param = VALUE #( companycode                  = <ls_item>-rule_data-companycode
                                    documentreferenceid          = <ls_item>-rule_data-documentreferenceid
                                    createdbyuser                = sy-uname
                                    businesstransactiontype      = 'RFBU'
                                    accountingdocumenttype       = <ls_item>-rule_data-document_type
                                    documentdate                 = <ls_item>-physical_operation_date
                                    postingdate                  = <ls_item>-physical_operation_date
                                    accountingdocumentheadertext = <ls_item>-rule_data-accountingdocumentheadertext
                                    _apitems                     = VALUE #( FOR wa_apitem  IN lt_apitem  ( CORRESPONDING #( wa_apitem  MAPPING _currencyamount = _currencyamount ) ) )
                                    _aritems                     = VALUE #( FOR wa_aritem  IN lt_aritem  ( CORRESPONDING #( wa_aritem  MAPPING _currencyamount = _currencyamount ) ) )
                                    _glitems                     = VALUE #( FOR wa_glitem  IN lt_glitem  ( CORRESPONDING #( wa_glitem  MAPPING _currencyamount = _currencyamount ) ) )
                                  ).
          WAIT UP TO 1 SECONDS.
          MODIFY ENTITIES OF i_journalentrytp
           ENTITY journalentry
           EXECUTE post FROM lt_je
           FAILED DATA(ls_failed)
           REPORTED DATA(ls_reported)
           MAPPED DATA(ls_mapped).
          IF ls_failed IS NOT INITIAL.
            LOOP AT ls_reported-journalentry INTO DATA(ls_reported_line).
              lo_free = cl_bali_free_text_setter=>create( severity = if_bali_constants=>c_severity_warning
                                                                text     = CONV #( ls_reported_line-%msg->if_message~get_text( ) ) ).
              lo_log->add_item( lo_free ).
            ENDLOOP.
          ELSE.
            COMMIT ENTITIES BEGIN
             RESPONSE OF i_journalentrytp
             FAILED DATA(ls_commit_failed)
             REPORTED DATA(ls_commit_reported).
            COMMIT ENTITIES END.
            IF ls_commit_failed IS INITIAL.
              DATA(lo_message) = cl_bali_message_setter=>create( severity = if_bali_constants=>c_severity_information
                                                                 id = ycl_eho_utils=>mc_message_class
                                                                 number = 016
                                                                 variable_1 = VALUE #( ls_commit_reported-journalentry[ 1 ]-accountingdocument OPTIONAL ) ).
              lo_log->add_item( lo_message ).

              APPEND VALUE #( companycode             = <ls_item>-companycode
                              glaccount               = <ls_item>-glaccount
                              receipt_no              = <ls_item>-receipt_no
                              physical_operation_date = <ls_item>-physical_operation_date
                              accountingdocument      = VALUE #( ls_commit_reported-journalentry[ 1 ]-accountingdocument OPTIONAL )
                              fiscal_year             = VALUE #( ls_commit_reported-journalentry[ 1 ]-fiscalyear OPTIONAL ) ) TO lt_saved_receipts.

            ELSE.
              LOOP AT ls_commit_reported-journalentry INTO DATA(ls_commit_reported_line).
                lo_free = cl_bali_free_text_setter=>create( severity = if_bali_constants=>c_severity_warning
                                                                  text     = CONV #( ls_commit_reported_line-%msg->if_message~get_text( ) ) ).
                lo_log->add_item( lo_free ).
              ENDLOOP.
            ENDIF.
          ENDIF.
          CLEAR : lt_je, lt_glitem , lt_apitem , lt_aritem , ls_failed , ls_reported , ls_commit_failed , ls_commit_reported.
        CATCH cx_uuid_error INTO DATA(lx_error).
        CATCH cx_bali_runtime INTO lx_bali_runtime.
          lo_free = cl_bali_free_text_setter=>create( severity = if_bali_constants=>c_severity_warning
                                                            text     = CONV #( lx_error->get_longtext(  ) ) ).
          TRY.
              lo_log->add_item( lo_free ).
            CATCH cx_bali_runtime INTO lx_bali_runtime.
          ENDTRY.
      ENDTRY.
    ENDLOOP.
    TRY.
        cl_bali_log_db=>get_instance( )->save_log( log = lo_log assign_to_current_appl_job = abap_true ).
      CATCH cx_bali_runtime.
    ENDTRY.
    IF lt_saved_receipts[] IS NOT INITIAL.
      INSERT yeho_t_savedrcpt FROM TABLE @lt_saved_receipts.
    ENDIF.
  ENDMETHOD.