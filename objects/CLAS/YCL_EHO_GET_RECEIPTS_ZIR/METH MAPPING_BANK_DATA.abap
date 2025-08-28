  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_hareketler,
              doviztipi      TYPE string,
              islemtarihi    TYPE string,
              tutar          TYPE string,
              borcalacak     TYPE string,
              aciklama       TYPE string,
              muhasebetarihi TYPE string,
              valortarihi    TYPE string,
              timestamp      TYPE string,
              islemaciklama  TYPE string,
              tcknvkn        TYPE string,
              adunvan        TYPE string,
              iban           TYPE string,
              muhref         TYPE string,
              programkod     TYPE string,
              dekontno       TYPE string,
              islemtipi      TYPE string,
              kayitdurumu    TYPE string,
              iptalzamani    TYPE string,
              bakiye         TYPE string,
            END OF ty_hareketler,
            tt_hareketlerdetay TYPE TABLE OF ty_hareketler WITH EMPTY KEY,
            BEGIN OF ty_hareketdetay,
              hareketlerdetay TYPE tt_hareketlerdetay,
            END OF ty_hareketdetay,
            BEGIN OF ty_results,
              hatakodu      TYPE string,
              hataack       TYPE string,
              subekodu      TYPE string,
              subeadi       TYPE string,
              hesapno       TYPE string,
              acilisbakiye  TYPE string,
              caribakiye    TYPE string,
              blokelibakiye TYPE string,
              hareketdetay  TYPE ty_hareketdetay,
            END OF ty_results,
            BEGIN OF ty_result_zaman,
              result TYPE ty_results,
            END OF ty_result_zaman,
            BEGIN OF ty_response,
              response TYPE ty_result_zaman,
            END OF ty_response.
    DATA ls_json_response TYPE ty_response.
    DATA lv_sequence_no TYPE int4.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    DATA(lv_json) = iv_json.
    REPLACE 'SorgulaHesapHareketZamanIleResponse' IN lv_json WITH 'response'.
    REPLACE 'SorgulaHesapHareketZamanIleResult' IN lv_json WITH 'result'.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).

    IF ls_json_response-response-result-hatakodu <> '00'.
      APPEND VALUE #( messagetype = mc_error message = ls_json_response-response-result-hataack ) TO et_error_messages.
      RETURN.
    ENDIF.
    CHECK ls_json_response-response-result-hesapno = ms_bankpass-iban.
    LOOP AT ls_json_response-response-result-hareketdetay-hareketlerdetay INTO DATA(ls_hareketdetay).
      lv_sequence_no += 1.
      ls_offline_data-companycode     = ms_bankpass-companycode.
      ls_offline_data-sequence_no     = lv_sequence_no.
      ls_offline_data-glaccount       = ms_bankpass-glaccount.
      ls_offline_data-currency        = ms_bankpass-currency.
      ls_offline_data-description     = ls_hareketdetay-aciklama.
      ls_offline_data-amount          = ls_hareketdetay-tutar.
      ls_offline_data-receipt_no      = ls_hareketdetay-dekontno.
      ls_offline_data-current_balance = ls_hareketdetay-bakiye.
      ls_offline_data-debit_credit    = ls_hareketdetay-borcalacak.

      IF ls_hareketdetay-borcalacak EQ 'B'.
        ls_offline_data-debtor_vkn   = ls_hareketdetay-tcknvkn.
      ELSEIF ls_offline_data-debit_credit EQ 'A'.
        ls_offline_data-debtor_vkn = ls_hareketdetay-tcknvkn.
      ENDIF.

      ls_offline_data-transaction_type       = ls_hareketdetay-islemtipi.
      ls_offline_data-sender_name      = ls_hareketdetay-adunvan.
      ls_offline_data-sender_iban = ls_hareketdetay-iban.

      CONCATENATE ls_hareketdetay-islemtarihi+0(4)
                  ls_hareketdetay-islemtarihi+5(2)
                  ls_hareketdetay-islemtarihi+8(2)
                  INTO ls_offline_data-physical_operation_date.

      CONCATENATE ls_hareketdetay-islemtarihi+11(2)
                  ls_hareketdetay-islemtarihi+14(2)
                  ls_hareketdetay-islemtarihi+17(2)
             INTO ls_offline_data-time.

*      IF ls_list-last_updated_date_time LT ls_hareket-fiziksel_islem_tarihi.
*        ls_list-last_updated_date_time = ls_hareket-fiziksel_islem_tarihi.
*      ENDIF.

      APPEND ls_offline_data TO et_bank_data.
      CLEAR  ls_offline_data.
    ENDLOOP.
    IF sy-subrc = 0.
      DATA(lt_bank_data) = et_bank_data.
      SORT lt_bank_data BY sequence_no ASCENDING.
      READ TABLE lt_bank_data INTO DATA(ls_bank_data) INDEX 1.
      IF ls_bank_data-debit_credit = 'B'.
        lv_opening_balance = ls_bank_data-current_balance + ls_bank_data-amount.
      ELSE.
        lv_opening_balance = ls_bank_data-current_balance - ls_bank_data-amount.
      ENDIF.
      SORT lt_bank_data BY sequence_no DESCENDING.
      READ TABLE lt_bank_data INTO ls_bank_data INDEX 1.
      lv_closing_balance = ls_bank_data-current_balance.
    ELSE.
      lv_opening_balance  = ls_json_response-response-result-acilisbakiye.
      lv_closing_balance = ls_json_response-response-result-caribakiye.
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