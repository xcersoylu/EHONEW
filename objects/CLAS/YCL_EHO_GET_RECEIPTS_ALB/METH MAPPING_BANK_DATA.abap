  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_hesaphareket,
              islemsonrasibakiye TYPE string,
              channelcode        TYPE string,
              islemtutari        TYPE string,
              muhrefno           TYPE string,
              seqnumber          TYPE string,
              bakiye             TYPE string,
              code               TYPE string,
              aciklama           TYPE string,
              tarih              TYPE string,
              saat               TYPE string,
              borcalacak         TYPE string,
              karsihesaptcknvkn  TYPE string,
              karsihesapiban     TYPE string,
              branchcode         TYPE string,
              fisno              TYPE string,
            END OF ty_hesaphareket,
            tt_hesaphareket TYPE TABLE OF ty_hesaphareket WITH DEFAULT KEY,
            BEGIN OF ty_hesap,
              musterino    TYPE string,
              hesapno      TYPE string,
              hesapiban    TYPE string,
              hesaphareket TYPE tt_hesaphareket,
            END OF ty_hesap,
            tt_hesap TYPE TABLE OF ty_hesap WITH DEFAULT KEY,
            BEGIN OF ty_hesaphareketleri,
              hesap TYPE tt_hesap,
            END OF ty_hesaphareketleri,
            BEGIN OF ty_result,
              result           TYPE string,
              hesaphareketleri TYPE ty_hesaphareketleri,
            END OF ty_result,
            BEGIN OF ty_responsedata,
              responsedata TYPE ty_result,
            END OF ty_responsedata,
            BEGIN OF ty_json,
              gethesaphareketleriresponse TYPE ty_responsedata,
            END OF ty_json.
    DATA ls_json_response TYPE ty_json.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_sequence_no TYPE int4.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).
    data(ls_Account_Detail) = get_account_detail(  ).
    REPLACE ',' in ls_account_detail-toplambakiye WITH '.'.
    READ TABLE ls_json_response-gethesaphareketleriresponse-responsedata-hesaphareketleri-hesap INTO DATA(ls_hesaphareketleri) WITH KEY hesapiban = ms_bankpass-iban.
    LOOP AT ls_hesaphareketleri-hesaphareket INTO DATA(ls_hesaphareketi).
      replace ',' in ls_hesaphareketi-islemtutari WITH '.'.
      replace ',' in ls_hesaphareketi-islemsonrasibakiye WITH '.'.
      lv_sequence_no += 1.
      ls_offline_data-companycode    = ms_bankpass-companycode.
      ls_offline_data-glaccount      = ms_bankpass-glaccount.
      ls_offline_data-currency       = ms_bankpass-currency.
      ls_offline_data-sequence_no    = lv_sequence_no.
      ls_offline_data-amount         = ls_hesaphareketi-islemtutari.
      ls_offline_data-description    = ls_hesaphareketi-aciklama.
      ls_offline_data-debit_credit   = ls_hesaphareketi-borcalacak.
      IF ls_hesaphareketi-borcalacak = 'B'.
        ls_offline_data-payee_vkn = ls_hesaphareketi-karsihesaptcknvkn.
      ENDIF.
      IF ls_hesaphareketi-borcalacak = 'A'.
        ls_offline_data-debtor_vkn = ls_hesaphareketi-karsihesaptcknvkn.
      ENDIF.
      ls_offline_data-current_balance         = ls_hesaphareketi-islemsonrasibakiye.
      ls_offline_data-receipt_no              = ls_hesaphareketi-fisno.
      ls_offline_data-physical_operation_date = ls_hesaphareketi-tarih.
      ls_offline_data-time                    = ls_hesaphareketi-saat.
      ls_offline_data-valor                   = ls_hesaphareketi-tarih.
      ls_offline_data-sender_iban             = ls_hesaphareketi-karsihesapiban.
      ls_offline_data-transaction_type        = ls_hesaphareketi-code.
      ls_offline_data-sender_branch           = ls_hesaphareketi-branchcode.
      APPEND ls_offline_data TO et_bank_data.
      CLEAR ls_offline_data.
    ENDLOOP.
    IF sy-subrc = 0.
      DATA(lt_bank_data) = et_bank_data.
      SORT lt_bank_data BY physical_operation_date time ASCENDING.
      READ TABLE lt_bank_data INTO DATA(ls_bank_data) INDEX 1.
      IF ls_bank_data-debit_credit = 'B'.
        lv_opening_balance = ls_bank_data-current_balance + ls_bank_data-amount.
      ELSE.
        lv_opening_balance = ls_bank_data-current_balance - ls_bank_data-amount.
      ENDIF.
      SORT lt_bank_data BY physical_operation_date time ASCENDING.
      READ TABLE lt_bank_data INTO ls_bank_data INDEX 1.
      lv_closing_balance = ls_bank_data-current_balance.
    ELSE.
      lv_opening_balance  = lv_closing_balance = ls_Account_Detail-toplambakiye.
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