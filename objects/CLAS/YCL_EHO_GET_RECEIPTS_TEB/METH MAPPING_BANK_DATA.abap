  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_return,
              errormsg      TYPE string,
              sessionid     TYPE string,
              outputdataxml TYPE string,
              errorcode     TYPE string,
            END OF ty_return,
            BEGIN OF ty_response,
              return TYPE ty_return,
            END OF ty_response,
            BEGIN OF ty_json,
              response TYPE ty_response,
            END OF ty_json.
    DATA ls_json_response TYPE ty_json.
    DATA lv_sequence_no TYPE int4.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    CONSTANTS mc_value_node TYPE string VALUE 'CO_NT_VALUE'.
    DATA(lv_json) = iv_json.
    REPLACE 'TEBWebSrvResponse' IN lv_json WITH 'response'.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).
    IF ls_json_response-response-return-errorcode = '00'.
      REPLACE '<![CDATA[' IN ls_json_response-response-return-outputdataxml WITH ''.
      REPLACE ']]>' IN ls_json_response-response-return-outputdataxml WITH ''.
      DATA(lt_xml) = ycl_eho_utils=>parse_xml( iv_xml_string  = ls_json_response-response-return-outputdataxml ).

      LOOP AT lt_xml INTO DATA(ls_xml_line) WHERE name = 'DETAY'
                                              AND node_type = 'CO_NT_ELEMENT_OPEN'.

        APPEND INITIAL LINE TO et_bank_data ASSIGNING FIELD-SYMBOL(<ls_bank_data>).
        lv_sequence_no += 1.
        <ls_bank_data>-companycode = ms_bankpass-companycode.
        <ls_bank_data>-glaccount   = ms_bankpass-glaccount.
        <ls_bank_data>-sequence_no = lv_sequence_no.
        <ls_bank_data>-currency    = ms_bankpass-currency.
        DATA(lv_index) = sy-tabix + 1.
        LOOP AT lt_xml INTO DATA(ls_xml_line2) FROM lv_index.
          IF ( ls_xml_line2-name = 'DETAY' AND ls_xml_line2-node_type = 'CO_NT_ELEMENT_CLOSE' ).
            EXIT.
          ENDIF.
          CHECK ls_xml_line2-node_type = 'CO_NT_VALUE'.

          CASE ls_xml_line2-name.
            WHEN 'HAREKET_KEY'.
              <ls_bank_data>-receipt_no = ls_xml_line2-value.
            WHEN 'TUTAR'.
              <ls_bank_data>-amount = ls_xml_line2-value.
            WHEN 'ACIKLAMA'.
              <ls_bank_data>-description = ls_xml_line2-value.
            WHEN 'BA'.
              <ls_bank_data>-debit_credit = ls_xml_line2-value.
            WHEN 'ISLEM_ACK'.
              <ls_bank_data>-additional_field1 = ls_xml_line2-value.
            WHEN 'MUSTERI_REF'.
              <ls_bank_data>-additional_field2 = ls_xml_line2-value.
            WHEN 'ANLIK_BKY'.
              <ls_bank_data>-current_balance = ls_xml_line2-value.
            WHEN 'DEKONT_NO'.
              <ls_bank_data>-receipt_no = ls_xml_line2-value.
            WHEN 'ISLEM_TAR'.
              <ls_bank_data>-physical_operation_date = ls_xml_line2-value+6(4) && ls_xml_line2-value+3(2) && ls_xml_line2-value(2).
              <ls_bank_data>-valor = ls_xml_line2-value+6(4) && ls_xml_line2-value+3(2) && ls_xml_line2-value(2).
              <ls_bank_data>-accounting_date = ls_xml_line2-value+6(4) && ls_xml_line2-value+3(2) && ls_xml_line2-value(2).
            WHEN 'ISLEM_TAR_SAAT'.
              <ls_bank_data>-time = ls_xml_line2-value(2) && ls_xml_line2-value+3(2) && ls_xml_line2-value+6(2).
            WHEN 'GONDEREN_SUBE'.
              <ls_bank_data>-sender_branch = ls_xml_line2-value.
            WHEN 'ISLEM_TUR'.
              <ls_bank_data>-transaction_type = ls_xml_line2-value.
            WHEN 'ALACAKLI_VKN'.
              IF <ls_bank_data>-debit_credit = 'A'.
                <ls_bank_data>-payee_vkn = ls_xml_line2-value.
              ELSEIF <ls_bank_data>-debit_credit = 'B'.
                <ls_bank_data>-debtor_vkn = ls_xml_line2-value.
              ENDIF.
            WHEN 'GONDEREN_IBAN'.
              IF <ls_bank_data>-debit_credit = 'A'.
                <ls_bank_data>-sender_iban = ls_xml_line2-value.
              ENDIF.
            WHEN 'ALICI_IBAN'.
              IF <ls_bank_data>-debit_credit = 'B'.
                <ls_bank_data>-sender_iban = ls_xml_line2-value.
              ENDIF.
          ENDCASE.
        ENDLOOP.
      ENDLOOP.

      lv_closing_balance = VALUE #(  lt_xml[ node_type = mc_value_node name = 'SONBKY' ]-value OPTIONAL ).

      IF et_bank_data IS INITIAL.
        lv_opening_balance = lv_closing_balance.
      ELSE.
        READ TABLE et_bank_data INTO DATA(ls_first_line) INDEX 1.
        CASE ls_first_line-debit_credit.
          WHEN 'A'.
            lv_opening_balance = ls_first_line-current_balance - ls_first_line-amount.
          WHEN 'B'.
            lv_opening_balance = ls_first_line-amount + ls_first_line-current_balance.
        ENDCASE.
      ENDIF.


      APPEND VALUE #( companycode = ms_bankpass-companycode
                      glaccount   = ms_bankpass-glaccount
                      valid_from  = mv_startdate
                      account_no  = ms_bankpass-bankaccount
                      branch_no   = ms_bankpass-branch_code
                      branch_name_description = ycl_eho_utils=>get_branch_name(
                                                  iv_companycode = ms_bankpass-companycode
                                                  iv_bank_code   = ms_bankpass-bank_code
                                                  iv_branch_code = ms_bankpass-branch_code
                                                )
                      currency = ms_bankpass-currency
                      opening_balance =  lv_opening_balance
                      closing_balance =  lv_closing_balance
                      bank_id =  ''
                      account_id = ''
                      bank_code =   ms_bankpass-bank_code
      ) TO  et_bank_balance.
    ELSE.
      APPEND VALUE #( messagetype = 'E' message = ls_json_response-response-return-errormsg ) TO et_error_messages.
    ENDIF.

  ENDMETHOD.