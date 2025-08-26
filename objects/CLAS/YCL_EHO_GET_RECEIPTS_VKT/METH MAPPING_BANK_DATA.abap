  METHOD mapping_bank_data.
    TYPES: BEGIN OF ty_customer_transaction,
             results                    TYPE string,
             success                    TYPE string,
             amount                     TYPE string,
             businesskey                TYPE string,
             channelid                  TYPE string,
             comment                    TYPE string,
             fecname                    TYPE string,
             systemdate                 TYPE string,
             tranbranchid               TYPE string,
             tranbranchname             TYPE string,
             trandate                   TYPE string,
             balance                    TYPE string,
             description                TYPE string,
             mainbusinesskey            TYPE string,
             querytokenstr              TYPE string,
             receiveraccountnumber      TYPE string,
             receiverbankcode           TYPE string,
             receiverbranchcode         TYPE string,
             receivername               TYPE string,
             receiverphonenumber        TYPE string,
             receivertaxnumber          TYPE string,
             senderaccountnumber        TYPE string,
             senderbankcode             TYPE string,
             senderbranchcode           TYPE string,
             sendername                 TYPE string,
             senderphonenumber          TYPE string,
             sendertaxnumber            TYPE string,
             seqnum                     TYPE string,
             transactiontype            TYPE string,
             transactiontypedescription TYPE string,
           END OF ty_customer_transaction.

    TYPES: ty_t_customer_transaction TYPE STANDARD TABLE OF ty_customer_transaction WITH EMPTY KEY.

    TYPES: BEGIN OF ty_value,
             transactiondetailresponsemodel TYPE ty_t_customer_transaction,
           END OF ty_value.

    TYPES: BEGIN OF ty_transaction_result,
             results      TYPE string,
             success      TYPE string,
             errorcode    TYPE string,
             errormessage TYPE string,
             value        TYPE ty_value,
           END OF ty_transaction_result.

    TYPES: BEGIN OF ty_transaction_response,
             transactiondetailsresult TYPE ty_transaction_result,
           END OF ty_transaction_response.

    TYPES: BEGIN OF ty_root,
             transactiondetailsresponse TYPE ty_transaction_response,
           END OF ty_root.
    DATA ls_json_response TYPE ty_root.
    DATA lv_sequence_no TYPE int4.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    DATA(lv_json) = iv_json.
    REPLACE 'GetCustomerTransactionDetailsResponse' IN lv_json WITH 'TransactionDetailsResponse'.
    REPLACE 'GetCustomerTransactionDetailsResult' IN lv_json WITH 'TransactionDetailsResult'.
    REPLACE 'CustomerTransactionDetailResponseModel' IN lv_json WITH 'TransactionDetailResponseModel'.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).

    IF ls_json_response-transactiondetailsresponse-transactiondetailsresult-errorcode IS NOT INITIAL.
      APPEND VALUE #( messagetype = mc_error
                      message = ls_json_response-transactiondetailsresponse-transactiondetailsresult-errormessage ) TO et_error_messages.
      RETURN.
    ENDIF.

    lv_opening_balance = get_account_balance(  ).
    LOOP AT ls_json_response-transactiondetailsresponse-transactiondetailsresult-value-transactiondetailresponsemodel INTO DATA(ls_detay).
      lv_sequence_no += 1.
      ls_offline_data-companycode = ms_bankpass-companycode.
      ls_offline_data-glaccount   = ms_bankpass-glaccount.
      ls_offline_data-sequence_no = lv_sequence_no.
      ls_offline_data-currency    = ms_bankpass-currency.
      ls_offline_data-description = ls_detay-comment.
      ls_offline_data-sender_bank = ls_detay-senderbankcode.
      ls_offline_data-sender_branch = ls_detay-senderbranchcode.
      ls_offline_data-amount    = ls_detay-amount.
      IF ls_offline_data-amount > 0.
        ls_offline_data-payee_vkn = ls_detay-sendertaxnumber.
        ls_offline_data-debit_credit = 'A'.
        ls_offline_data-sender_iban = ls_detay-senderaccountnumber.
      ELSEIF ls_offline_data-amount < 0.
        ls_offline_data-debtor_vkn = ls_detay-sendertaxnumber.
        ls_offline_data-debit_credit = 'B'.
        ls_offline_data-sender_iban      = ls_detay-senderaccountnumber.
      ENDIF.

      ls_offline_data-current_balance          = ls_detay-balance.
      ls_offline_data-receipt_no             = ls_detay-businesskey.
      IF ls_detay-trandate IS NOT INITIAL.
        CONCATENATE ls_detay-trandate(4) ls_detay-trandate+5(2) ls_detay-trandate+8(2)
               INTO ls_offline_data-physical_operation_date.
      ENDIF.
      IF ls_detay-systemdate IS NOT INITIAL.
        CONCATENATE ls_detay-systemdate(4) ls_detay-systemdate+5(2) ls_detay-systemdate+8(2)
               INTO ls_offline_data-accounting_date.
        CONCATENATE ls_detay-systemdate+11(2) ls_detay-systemdate+14(2) ls_detay-systemdate+17(2)
               INTO ls_offline_data-time.
      ENDIF.
      ls_offline_data-transaction_type            = ls_detay-transactiontype.
      ls_offline_data-additional_field1                = ls_detay-transactiontypedescription.
      APPEND ls_offline_data TO et_bank_data.
      CLEAR ls_offline_data.
    ENDLOOP.
    IF sy-subrc = 0.
      lv_closing_balance = ls_detay-balance.
    ELSE.
      lv_closing_balance = lv_opening_balance.
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

  ENDMETHOD.