  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_transactiondetailcontract,
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
              iban                 TYPE string,
              resourcecode         TYPE string,
              senderidentitynumber TYPE string,
              swifttransactioncode TYPE string,
              systemdate           TYPE string,
              trandate             TYPE string,
              tranref              TYPE string,
              trantype             TYPE string,
              valuedate            TYPE string,
            END OF ty_transactiondetailcontract,
            tt_transactiondetailcontract TYPE TABLE OF ty_transactiondetailcontract WITH EMPTY KEY,
            BEGIN OF ty_details,
              transactiondetailcontract TYPE tt_transactiondetailcontract,
            END OF ty_details,
            BEGIN OF ty_closingbalance,
              beginamount TYPE string,
              endamount   TYPE string,
              fec         TYPE string,
              trandate    TYPE string,
            END OF ty_closingbalance,
            tt_closingbalance TYPE TABLE OF ty_closingbalance WITH EMPTY KEY,
            BEGIN OF ty_balancedetails,
              closingbalancechangecontract TYPE tt_closingbalance,
            END OF ty_balancedetails,
            BEGIN OF ty_accountcontract,
              accountalias      TYPE string,
              accountnumber     TYPE string,
              accountsuffix     TYPE string,
              balance           TYPE string,
              balancedetails    TYPE ty_balancedetails,
              branchid          TYPE string,
              branchname        TYPE string,
              credentialerror   TYPE string,
              details           TYPE ty_details,
              displayname       TYPE string,
              fec               TYPE string,
              fecname           TYPE string,
              iban              TYPE string,
              internalperiodend TYPE string,
              lastreneweddate   TYPE string,
              lasttrandate      TYPE string,
              maturityend       TYPE string,
              opendate          TYPE string,
              parentproductcode TYPE string,
              productcode       TYPE string,
              tcknortaxnumber   TYPE string,
            END OF ty_accountcontract,
            tt_accountcontract TYPE TABLE OF ty_accountcontract WITH EMPTY KEY,
            BEGIN OF ty_value,
              accountcontract TYPE tt_accountcontract,
            END OF ty_value,
            BEGIN OF ty_result,
              errorcode    TYPE string,
              errormessage TYPE string,
              isfriendly   TYPE string,
            END OF ty_result,
            tt_result TYPE TABLE OF ty_result WITH EMPTY KEY,
            BEGIN OF ty_results,
              result TYPE tt_result,
            END OF ty_results,
            BEGIN OF ty_statement_result,
              results      TYPE ty_results,
              success      TYPE string,
              errorcode    TYPE string,
              errormessage TYPE string,
              value        TYPE ty_value,
            END OF ty_statement_result,
            BEGIN OF ty_statement_response,
              result TYPE ty_statement_result,
            END OF ty_statement_response,
            BEGIN OF ty_json,
              response TYPE ty_statement_response,
            END OF ty_json.
    DATA ls_json_response TYPE ty_json.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_sequence_no TYPE int4.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    DATA lv_json TYPE string.
    lv_json = iv_json.
    REPLACE 'GetAccountStatementResponse' IN lv_json WITH 'response'.
    REPLACE 'GetAccountStatementResult' IN lv_json WITH 'result'.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).

    LOOP AT ls_json_response-response-result-value-accountcontract INTO DATA(ls_accountcontract) WHERE accountnumber = ms_bankpass-bankaccount
                                                                                                   AND accountsuffix = ms_bankpass-suffix.
      SORT ls_accountcontract-details-transactiondetailcontract BY trandate DESCENDING.
      LOOP AT ls_accountcontract-details-transactiondetailcontract INTO DATA(ls_detail).
        CLEAR ls_offline_data.
        lv_sequence_no += 1.
        ls_offline_data-companycode = ms_bankpass-companycode.
        ls_offline_data-glaccount   = ms_bankpass-glaccount.
        ls_offline_data-sequence_no = lv_sequence_no.
        ls_offline_data-currency    = ms_bankpass-currency.
        ls_offline_data-description = ls_detail-description.
        IF ls_detail-amount > 0.
          ls_offline_data-debit_credit = 'A'.
          ls_offline_data-payee_vkn = ls_detail-senderidentitynumber.
        ENDIF.
        IF ls_detail-amount < 0.
          ls_offline_data-debit_credit = 'B'.
          ls_offline_data-debtor_vkn = ls_detail-senderidentitynumber.
          SHIFT ls_detail-amount BY 1 PLACES LEFT.
        ENDIF.
        ls_offline_data-amount           = ls_detail-amount.
        ls_offline_data-current_balance  = ls_detail-currentbalance.
        ls_offline_data-receipt_no       = ls_detail-businesskey.
        IF ls_detail-systemdate IS NOT INITIAL.
          CONCATENATE ls_detail-systemdate+0(4)
                      ls_detail-systemdate+5(2)
                      ls_detail-systemdate+8(2)
                 INTO ls_offline_data-physical_operation_date.

          CONCATENATE ls_detail-systemdate+11(2)
                      ls_detail-systemdate+14(2)
                      ls_detail-systemdate+17(2)
                 INTO ls_offline_data-time.
        ENDIF.
        CONCATENATE ls_detail-trandate+11(2)
                    ls_detail-trandate+14(2)
                    ls_detail-trandate+17(2)
               INTO ls_offline_data-valor.
        ls_offline_data-sender_iban      = ls_detail-iban.
        ls_offline_data-transaction_type = ls_detail-swifttransactioncode.
        ls_offline_data-transaction_type = ls_offline_data-transaction_type+1(10).
        ls_offline_data-sender_branch    = ls_detail-branchname.
        APPEND ls_offline_data TO et_bank_data.
      ENDLOOP.
    ENDLOOP.
*    IF sy-subrc = 0.
*      DATA(lt_bank_data) = et_bank_data.
*      SORT lt_bank_data BY physical_operation_date time ASCENDING.
*      READ TABLE lt_bank_data INTO DATA(ls_bank_data) INDEX 1.
*      IF ls_bank_data-debit_credit = 'B'.
*        lv_opening_balance = ls_bank_data-current_balance + ls_bank_data-amount.
*      ELSE.
*        lv_opening_balance = ls_bank_data-current_balance - ls_bank_data-amount.
*      ENDIF.
*      SORT lt_bank_data BY physical_operation_date time ASCENDING.
*      READ TABLE lt_bank_data INTO ls_bank_data INDEX 1.
*      lv_closing_balance = ls_bank_data-current_balance.
*    ELSE.
*      lv_opening_balance  = lv_closing_balance = ls_json_response-balance.
*    ENDIF.
    lv_opening_balance = VALUE #( ls_accountcontract-balancedetails-closingbalancechangecontract[ 1 ]-beginamount OPTIONAL ).
    lv_closing_balance = VALUE #( ls_accountcontract-balancedetails-closingbalancechangecontract[ 1 ]-endamount OPTIONAL ).
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

  ENDMETHOD.