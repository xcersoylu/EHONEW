  METHOD mapping_bank_data.

    TYPES : BEGIN OF ty_transaction,
              amount               TYPE string,
              branchid             TYPE string,
              branchname           TYPE string,
              businesskey          TYPE string,
              channelid            TYPE string,
              credit               TYPE string,
              currentbalance       TYPE string,
              debit                TYPE string,
              description          TYPE string,
              fec                  TYPE string,
              fecname              TYPE string,
              receiveriban         TYPE string,
              resourcecode         TYPE string,
              senderiban           TYPE string,
              senderidentitynumber TYPE string,
              systemdate           TYPE string,
              trandate             TYPE string,
              tranref              TYPE string,
              trantype             TYPE string,
              valuedate            TYPE string,
              virtualiban          TYPE string,
            END OF ty_transaction,
            tt_transaction type table of ty_transaction WITH EMPTY KEY,
            BEGIN OF ty_details,
              transactiondetailcontract TYPE tt_transaction,
            END OF ty_details,
*            tt_details TYPE TABLE OF ty_details WITH EMPTY KEY,
            BEGIN OF ty_accountcontract,
              accountalias      TYPE string,
              accountnumber     TYPE string,
              accountsuffix     TYPE string,
              availablebalance  TYPE string,
              balance           TYPE string,
              branchid          TYPE string,
              branchname        TYPE string,
              details           TYPE ty_details,
              fec               TYPE string,
              feclongname       TYPE string,
              fecname           TYPE string,
              iban              TYPE string,
              internalperiodend TYPE string, ""
              lastreneweddate   TYPE string, """
              lasttrandate      TYPE string,
              maturityend       TYPE string, """
              opendate          TYPE string,
              productcode       TYPE string,
              tcknortaxnumber   TYPE string,
            END OF ty_accountcontract,
            tt_accountcontract TYPE TABLE OF ty_accountcontract WITH EMPTY KEY,
            BEGIN OF ty_value,
              accountcontract TYPE tt_accountcontract,
            END OF ty_value,
            BEGIN OF ty_result2,
              errormessage TYPE string,
              isfriendly   TYPE string,
            END OF ty_result2,
            BEGIN OF ty_results,
              result TYPE ty_result2,
            END OF ty_results,
            BEGIN OF ty_result,
              results      TYPE ty_results,
              success      TYPE string,
              errorcode    TYPE string,
              errormessage TYPE string,
              value        TYPE ty_value,
            END OF ty_result,
            BEGIN OF ty_response,
              getaccountstatementresult TYPE ty_result,
            END OF ty_response,
            BEGIN OF ty_json,
              getaccountstatementresponse TYPE ty_response,
            END OF ty_json.
    DATA ls_json_response TYPE ty_json. "TYPE mty_result.
    DATA lv_sequence_no TYPE int4.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).
    DATA(ls_transactions) = VALUE #( ls_json_response-getaccountstatementresponse-getaccountstatementresult-value-accountcontract[ 1 ] OPTIONAL ).
    lv_closing_balance = ls_transactions-balance.
    LOOP AT ls_transactions-details-transactiondetailcontract INTO DATA(ls_detay).
      lv_sequence_no += 1.
      ls_offline_data-companycode = ms_bankpass-companycode.
      ls_offline_data-glaccount   = ms_bankpass-glaccount.
      ls_offline_data-sequence_no = lv_sequence_no.
      ls_offline_data-currency    = ms_bankpass-currency.
      ls_offline_data-description = ls_detay-description.
      ls_offline_data-sender_iban = ls_detay-senderiban.
      ls_offline_data-amount      = ls_detay-amount.
      IF ls_offline_data-amount > 0.
        ls_offline_data-payee_vkn = ls_detay-senderidentitynumber.
        ls_offline_data-debit_credit = 'A'.
      ELSEIF ls_offline_data-amount < 0.
        ls_offline_data-debtor_vkn = ls_detay-senderidentitynumber.
        ls_offline_data-debit_credit = 'B'.
      ENDIF.

      ls_offline_data-current_balance = ls_detay-currentbalance.
      ls_offline_data-receipt_no      = ls_detay-businesskey.
      CONCATENATE ls_detay-trandate(4)
                  ls_detay-trandate+5(2)
                  ls_detay-trandate+8(2)
             INTO ls_offline_data-physical_operation_date.
      CONCATENATE ls_detay-systemdate(4)
                  ls_detay-systemdate+5(2)
                  ls_detay-systemdate+8(2)
             INTO ls_offline_data-accounting_date.
      CONCATENATE ls_detay-systemdate+11(2)
                  ls_detay-systemdate+14(2)
                  ls_detay-systemdate+17(2)
             INTO ls_offline_data-time.
      ls_offline_data-transaction_type = ls_detay-trantype.
      IF lv_sequence_no = 1.
        lv_opening_balance = ls_detay-currentbalance - ls_detay-amount.
      ENDIF.
      APPEND ls_offline_data TO et_bank_data.
      CLEAR ls_offline_data.
    ENDLOOP.
    IF sy-subrc <> 0.
      lv_opening_balance = lv_closing_balance.
    ENDIF.

    APPEND VALUE #( companycode             = ms_bankpass-companycode
                    glaccount               = ms_bankpass-glaccount
                    valid_from              = mv_startdate
                    account_no = ms_bankpass-bankaccount
                    branch_no = ms_bankpass-branch_code
                    branch_name_description = ycl_eho_utils=>get_branch_name(
                                              iv_companycode = ms_bankpass-companycode
                                              iv_bank_code   = ms_bankpass-bank_code
                                              iv_branch_code = ms_bankpass-branch_code
                                            )
                    currency = ms_bankpass-currency
                    opening_balance         =  lv_opening_balance
                    closing_balance         =  lv_closing_balance
                    bank_id                 =  ''
                    account_id              = ''
                    bank_code               =   ms_bankpass-bank_code
    ) TO  et_bank_balance.

  ENDMETHOD.