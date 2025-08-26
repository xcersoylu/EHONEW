  METHOD mapping_bank_data.
    TYPES:
      BEGIN OF ty_detail,
        referansno      TYPE string,
        karsiiban       TYPE string,
        trancode        TYPE string,
        fonksiyonkodu   TYPE string,
        karsitcknvkn    TYPE string,
        tutar           TYPE string,
        sonbakiye       TYPE string,
        aciklama        TYPE string,
        fisno           TYPE string,
        islemiyapansube TYPE string,
        valortarihi     TYPE string,
        islemtarihi     TYPE string,
        islemsaati      TYPE string,
        karsiadsoyad    TYPE string,
      END OF ty_detail .
    TYPES:
      BEGIN OF ty_hesap,
        bakiye              TYPE string,
        maksimumsayfaboyutu TYPE string,
        iban                TYPE string,
        dovizkodu           TYPE string,
        detay               TYPE TABLE OF ty_detail WITH DEFAULT KEY,
        subekodu            TYPE string,
        sonbakiye           TYPE string,
        sayfanumarasi       TYPE string,
        hesapturukodu       TYPE string,
        hesapno             TYPE string,
        toplamsayfasayisi   TYPE string,
        caribakiye          TYPE string,
        toplankayitsayisi   TYPE string.
    TYPES END OF ty_hesap .

    TYPES : BEGIN OF ty_hesaphareketleriresult,
              hesap TYPE ty_hesap,
            END OF ty_hesaphareketleriresult,
            BEGIN OF ty_result,
              hesaphareketleriresult TYPE ty_hesaphareketleriresult,
            END OF ty_result,
            BEGIN OF ty_response,
              result TYPE ty_result,
            END OF ty_response,
            BEGIN OF ty_json,
              response TYPE ty_response,
            END OF ty_json.
    DATA ls_json_response TYPE ty_json.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_sequence_no TYPE int4.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    DATA lv_json TYPE string.
    lv_json = iv_json.
    REPLACE 'GeneralAccountStatementsResponse' IN lv_json WITH 'response'.
    REPLACE 'GeneralAccountStatementsResult' IN lv_json WITH 'result'.
    REPLACE 'GenelHesapHareketleriResult' IN lv_json WITH 'hesaphareketleriresult'.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).


    lv_opening_balance = ls_json_response-response-result-hesaphareketleriresult-hesap-bakiye.
    lv_closing_balance = ls_json_response-response-result-hesaphareketleriresult-hesap-caribakiye.
    LOOP AT ls_json_response-response-result-hesaphareketleriresult-hesap-detay INTO DATA(ls_detay).
      lv_sequence_no += 1.
      ls_offline_data-companycode             = ms_bankpass-companycode.
      ls_offline_data-glaccount               = ms_bankpass-glaccount.
      ls_offline_data-sequence_no             = lv_sequence_no.
      ls_offline_data-currency                = ms_bankpass-currency.
      ls_offline_data-amount                  = ls_detay-tutar.
      ls_offline_data-description             = ls_detay-aciklama.
      ls_offline_data-counter_account_no      = ls_detay-karsitcknvkn.
      ls_offline_data-sender_iban             = ls_detay-karsiiban.
      ls_offline_data-additional_field1       = ls_detay-referansno.
      ls_offline_data-additional_field2       = ls_detay-fonksiyonkodu.
      ls_offline_data-current_balance         = ls_detay-sonbakiye.
      ls_offline_data-receipt_no              = ls_detay-fisno.
      ls_offline_data-physical_operation_date = ls_detay-islemtarihi.

      CONCATENATE ls_detay-islemsaati(2)
                  ls_detay-islemsaati+3(2)
                  ls_detay-islemsaati+6(2)
      INTO ls_offline_data-time.

      ls_offline_data-valor                 = ls_detay-valortarihi.
      ls_offline_data-transaction_type            = ls_detay-trancode.

      IF ls_offline_data-amount LT 0.
        ls_offline_data-debit_credit = 'B'.
      ELSE.
        ls_offline_data-debit_credit = 'A'.
      ENDIF.

      APPEND ls_offline_data TO et_bank_data.
      CLEAR ls_offline_data.
    ENDLOOP.
    IF sy-subrc <> 0.
      lv_closing_balance = lv_opening_balance.
    ENDIF.
    APPEND VALUE #( companycode = ms_bankpass-companycode
                    glaccount = ms_bankpass-glaccount
                    valid_from = mv_startdate
                    account_no = ms_bankpass-bankaccount
                    branch_no = ms_bankpass-branch_code
                    branch_name_description = ycl_eho_utils=>get_branch_name(
                                                iv_companycode = ms_bankpass-companycode
                                                iv_bank_code   = ms_bankpass-bank_code
                                                iv_branch_code = ms_bankpass-branch_code
                                              )
                    currency = ms_bankpass-currency
                    opening_balance =  lv_opening_balance
                    closing_balance = lv_closing_balance
                    bank_id =  ''
                    account_id = ''
                    bank_code =   ms_bankpass-bank_code
    ) TO  et_bank_balance.

  ENDMETHOD.