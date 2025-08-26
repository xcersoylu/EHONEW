  METHOD mapping_bank_data.
    TYPES: BEGIN OF ty_hesap_hareketi_detail,
             referansno     TYPE string,
             saat           TYPE string,
             digeraciklama  TYPE string,
             dekontno       TYPE string,
             tarih          TYPE string,
             aciklamalar    TYPE string,
             harekettutari  TYPE string,
             islemsubekodu  TYPE string,
             sonbakiye      TYPE string,
             ekbilgi3       TYPE string,
             karsiiban      TYPE string,
             ekbilgi4       TYPE string,
             musterino      TYPE string,
             islemkodu      TYPE string,
             ekbilgi1       TYPE string,
             ekbilgi2       TYPE string,
             sirano         TYPE string,
             karsihesapvkno TYPE string,
           END OF ty_hesap_hareketi_detail.

    TYPES: ty_hesap_hareketi_detail_tab TYPE STANDARD TABLE OF ty_hesap_hareketi_detail WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_hesap_hareketleri,
             hesaphareketidetail TYPE ty_hesap_hareketi_detail_tab,
           END OF ty_hesap_hareketleri.

    TYPES: BEGIN OF ty_hesap_tanimi,
             subeadi                     TYPE string,
             acilistarihi                TYPE string,
             bakiye                      TYPE string,
             vadesonutarihi              TYPE string,
             kredilikullanilabilirbakiye TYPE string,
             hesapcinsi                  TYPE string,
             kredilimiti                 TYPE string,
             hesapturuadi                TYPE string,
             hesapturu                   TYPE string,
             hesapadi                    TYPE string,
             hesapnumarasi               TYPE string,
             blokemeblag                 TYPE string,
             musterino                   TYPE string,
             karorani                    TYPE string,
             subenumarasi                TYPE string,
             vadetarihi                  TYPE string,
             sonharekettarihi            TYPE string,
             kullanilabilirbakiye        TYPE string,
             havuzpaylasimorani          TYPE string,
           END OF ty_hesap_tanimi.

    TYPES: BEGIN OF ty_hesap_bilgisi_detail,
             hesaptanimi      TYPE ty_hesap_tanimi,
             hesaphareketleri TYPE ty_hesap_hareketleri,
           END OF ty_hesap_bilgisi_detail.

    TYPES: ty_hesap_bilgisi_detail_tab TYPE STANDARD TABLE OF ty_hesap_bilgisi_detail WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_banka_hesaplari,
             hesapbilgisidetail TYPE ty_hesap_bilgisi_detail_tab,
           END OF ty_banka_hesaplari.

    TYPES: BEGIN OF ty_class_detail,
             bankahesaplari TYPE ty_banka_hesaplari,
             syssaat        TYPE string,
             hatakodu       TYPE string,
             systarih       TYPE string,
             hataaciklama   TYPE string,
           END OF ty_class_detail.

    TYPES: BEGIN OF ty_account_detail,
             bankahesaplariclassdetail TYPE ty_class_detail,
           END OF ty_account_detail.

    TYPES: BEGIN OF ty_account_report_v2_result,
             accountdetail TYPE ty_account_detail,
           END OF ty_account_report_v2_result.

    TYPES: BEGIN OF ty_account_report_v2_response,
             accountreportv2result TYPE ty_account_report_v2_result,
           END OF ty_account_report_v2_response.
    TYPES: BEGIN OF ty_json,
             accountreportv2response TYPE ty_account_report_v2_response,
           END OF ty_json.

    DATA ls_json_response TYPE ty_json.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_sequence_no TYPE int4.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).

    IF ls_json_response-accountreportv2response-accountreportv2result-accountdetail-bankahesaplariclassdetail-hatakodu IS NOT INITIAL.
      APPEND VALUE #( messagetype = mc_error
                      message = ls_json_response-accountreportv2response-accountreportv2result-accountdetail-bankahesaplariclassdetail-hataaciklama ) TO et_error_messages.
      RETURN.
    ENDIF.

    READ TABLE ls_json_response-accountreportv2response-accountreportv2result-accountdetail-bankahesaplariclassdetail-bankahesaplari-hesapbilgisidetail
        INTO DATA(ls_hareketler)
        WITH KEY hesaptanimi-hesapnumarasi = ms_bankpass-bankaccount.

    LOOP AT ls_hareketler-hesaphareketleri-hesaphareketidetail ASSIGNING FIELD-SYMBOL(<fs_hareket>).
      CLEAR ls_offline_data.

      ls_offline_data-physical_operation_date = ls_offline_data-valor = <fs_hareket>-tarih+6(4) && <fs_hareket>-tarih+3(2) && <fs_hareket>-tarih+0(2).
      ls_offline_data-time = <fs_hareket>-saat+0(2) && <fs_hareket>-saat+3(2) && <fs_hareket>-saat+6(2).

      CHECK ls_offline_data-physical_operation_date = mv_startdate.
      lv_sequence_no += 1.
      ls_offline_data-sequence_no  = lv_sequence_no.
      ls_offline_data-glaccount    = ms_bankpass-glaccount.
      ls_offline_data-companycode  = ms_bankpass-companycode.
      ls_offline_data-currency     = ms_bankpass-currency.
      ls_offline_data-description  = <fs_hareket>-aciklamalar.

      IF <fs_hareket>-harekettutari LT 0.
        ls_offline_data-debit_credit = 'A'.
        ls_offline_data-debtor_vkn = <fs_hareket>-karsihesapvkno.
        lv_opening_balance = lv_opening_balance - <fs_hareket>-harekettutari.
      ELSE.
        ls_offline_data-debit_credit = 'B'.
        ls_offline_data-payee_vkn = <fs_hareket>-karsihesapvkno.
        SHIFT <fs_hareket>-harekettutari BY 1 PLACES LEFT.
        lv_opening_balance = lv_opening_balance + <fs_hareket>-harekettutari.
      ENDIF.

      ls_offline_data-amount           = <fs_hareket>-harekettutari.
      ls_offline_data-current_balance  = <fs_hareket>-sonbakiye.
      ls_offline_data-receipt_no       = <fs_hareket>-dekontno.
      ls_offline_data-transaction_type = <fs_hareket>-islemkodu.

      APPEND ls_offline_data TO et_bank_data.
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
      lv_opening_balance  = lv_closing_balance = ls_hareketler-hesaptanimi-bakiye.
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