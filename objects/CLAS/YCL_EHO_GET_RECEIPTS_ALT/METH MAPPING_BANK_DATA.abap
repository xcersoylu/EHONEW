  METHOD mapping_bank_data.
    TYPES: BEGIN OF ty_hesap_hareketi_detail2,
             tarih           TYPE string,
             saat            TYPE string,
             sirano          TYPE string,
             harekettutari   TYPE string,
             sonbakiye       TYPE string,
             aciklamalar     TYPE string,
             musterino       TYPE string,
             islemkodu       TYPE string,
             referansno      TYPE string,
             karsihesapvkno  TYPE string,
             dekontno        TYPE string,
             ekbilgi1        TYPE string,
             ekbilgi2        TYPE string,
             ekbilgi3        TYPE string,
             ekbilgi4        TYPE string,
             ibannumarasi    TYPE string,
             aliciiban       TYPE string,
             gondereniban    TYPE string,
             alicivkn        TYPE string,
             gonderenvkn     TYPE string,
             islemtipi       TYPE string,
             plaka           TYPE string,
             uyeisyerino     TYPE string,
             aliciadi        TYPE string,
             gonderenadi     TYPE string,
             islemaciklamasi TYPE string,
           END OF ty_hesap_hareketi_detail2.
    TYPES: BEGIN OF ty_hesap_hareketi_detail,
             hesaphareketidetail TYPE TABLE OF ty_hesap_hareketi_detail2 WITH EMPTY KEY,
           END OF ty_hesap_hareketi_detail.

    TYPES: ty_t_hesap_hareketi TYPE STANDARD TABLE OF ty_hesap_hareketi_detail WITH EMPTY KEY.

    TYPES: BEGIN OF ty_hesap_tanimi,
             hesapturu                   TYPE string,
             hesapadi                    TYPE string,
             musterino                   TYPE string,
             hesapcinsi                  TYPE string,
             hesapnumarasi               TYPE string,
             subenumarasi                TYPE string,
             subeadi                     TYPE string,
             acilistarihi                TYPE string,
             sonharekettarihi            TYPE string,
             bakiye                      TYPE string,
             blokemeblag                 TYPE string,
             kullanilabilirbakiye        TYPE string,
             kredilimiti                 TYPE string,
             kredilikullanilabilirbakiye TYPE string,
             vadetarihi                  TYPE string,
             faizorani                   TYPE string,
             ibannumarasi                TYPE string,
           END OF ty_hesap_tanimi.

    TYPES: BEGIN OF ty_hesap_bilgisi_detail,
             hesaptanimi      TYPE ty_hesap_tanimi,
             hesaphareketleri TYPE ty_hesap_hareketi_detail, "ty_t_hesap_hareketi,
           END OF ty_hesap_bilgisi_detail.

    TYPES: ty_t_hesap_bilgisi_detail TYPE STANDARD TABLE OF ty_hesap_bilgisi_detail WITH EMPTY KEY.

    TYPES: BEGIN OF ty_banka_hesaplari,
             hesapbilgisidetail TYPE ty_t_hesap_bilgisi_detail,
           END OF ty_banka_hesaplari.

    TYPES: BEGIN OF ty_class_detail,
             systarih       TYPE string,
             syssaat        TYPE string,
             hatakodu       TYPE string,
             hataaciklama   TYPE string,
             bankahesaplari TYPE ty_banka_hesaplari,
           END OF ty_class_detail.

    TYPES: BEGIN OF ty_account_detail,
             classdetail TYPE ty_class_detail,
           END OF ty_account_detail.

    TYPES: BEGIN OF ty_with_params_result,
             accountdetail TYPE ty_account_detail,
           END OF ty_with_params_result.

    TYPES: BEGIN OF ty_with_params_response,
             paramsresult TYPE ty_with_params_result,
           END OF ty_with_params_response.

    TYPES: BEGIN OF ty_root,
             paramsresponse TYPE ty_with_params_response,
           END OF ty_root.
    DATA ls_json_response TYPE ty_root.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_sequence_no TYPE int4.
    DATA(lv_json) = iv_json.
    REPLACE 'GetExtreWithParamsResponse' IN lv_json WITH 'ParamsResponse'.
    REPLACE 'GetExtreWithParamsResult' IN lv_json WITH 'ParamsResult'.
    REPLACE 'BankaHesaplariClassDetail' IN lv_json WITH 'ClassDetail'.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).
    IF ls_json_response-paramsresponse-paramsresult-accountdetail-classdetail-hatakodu IS NOT INITIAL.
      APPEND VALUE #( messagetype = mc_error
                      message = ls_json_response-paramsresponse-paramsresult-accountdetail-classdetail-hataaciklama ) TO et_error_messages.
      RETURN.
    ENDIF.
    DATA(lt_hesaplar) = ls_json_response-paramsresponse-paramsresult-accountdetail-classdetail-bankahesaplari-hesapbilgisidetail.

    READ TABLE  lt_hesaplar INTO DATA(ls_hesap) WITH KEY hesaptanimi-ibannumarasi = ms_bankpass-iban.

    LOOP AT ls_hesap-hesaphareketleri-hesaphareketidetail INTO DATA(ls_detay).
      lv_sequence_no += 1.
      ls_offline_data-companycode =  ms_bankpass-companycode.
      ls_offline_data-glaccount   =  ms_bankpass-glaccount.
      ls_offline_data-sequence_no =  lv_sequence_no.
      ls_offline_data-currency    = ms_bankpass-currency.
      ls_offline_data-amount = ls_detay-harekettutari.
      ls_offline_data-description = ls_detay-aciklamalar.
      IF ls_detay-harekettutari GE 0.
        ls_offline_data-payee_vkn = ls_detay-gonderenvkn.
        ls_offline_data-debit_credit = 'A'.
        ls_offline_data-sender_iban = ls_detay-gondereniban.
      ELSE.
        ls_offline_data-debtor_vkn = ls_detay-alicivkn.
        ls_offline_data-debit_credit = 'B'.
        ls_offline_data-sender_iban     = ls_detay-aliciiban.
      ENDIF.
      ls_offline_data-additional_field1 = ls_detay-ekbilgi1.
      ls_offline_data-additional_field2 = ls_detay-ekbilgi2.
      ls_offline_data-additional_field3 = ls_detay-ekbilgi3.
      ls_offline_data-current_balance   = ls_detay-sonbakiye.
      ls_offline_data-receipt_no        = ls_detay-dekontno.
      ls_offline_data-sender_branch     = ls_hesap-hesaptanimi-subenumarasi.
      ls_offline_data-transaction_type  = ls_detay-islemtipi.

      IF strlen( ls_detay-tarih ) = 10.
        CONCATENATE ls_detay-tarih+6(4)
                    ls_detay-tarih+3(2)
                    ls_detay-tarih(2) INTO
                    ls_offline_data-physical_operation_date.
        ls_offline_data-valor                 = ls_offline_data-physical_operation_date.
      ENDIF.

      IF strlen( ls_detay-saat ) = 8.
        CONCATENATE ls_detay-saat(2)
                    ls_detay-saat+3(2)
                    ls_detay-saat+6(2) INTO ls_offline_data-time.
      ENDIF.

      APPEND ls_offline_data TO et_bank_data.
      CLEAR ls_offline_data.
    ENDLOOP.
    IF sy-subrc = 0.
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
                      opening_balance =  ls_hesap-hesaptanimi-bakiye
                      closing_balance = ls_detay-sonbakiye
                      bank_id =  ''
                      account_id = ''
                      bank_code =   ms_bankpass-bank_code
      ) TO  et_bank_balance.
    ENDIF.
  ENDMETHOD.