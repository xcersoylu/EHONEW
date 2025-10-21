  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_hareket,
              aciklama           TYPE string,
              atmno              TYPE string,
              bakiye             TYPE string,
              dekontno           TYPE string,
              ekbilgi            TYPE string,
              ekstreaciklama     TYPE string,
              harekettutari      TYPE string,
              iptal              TYPE string,
              islemkod           TYPE string,
              islemyapanadsoyad  TYPE string,
              islemyapankimlikno TYPE string,
              karsiadsoyad       TYPE string,
              karsibankakod      TYPE string,
              karsihesapiban     TYPE string,
              karsikimlikno      TYPE string,
              karsimusterino     TYPE string,
              karsisubekod       TYPE string,
              referansno         TYPE string,
              saat               TYPE string,
              sirano             TYPE string,
              tarih              TYPE string,
            END OF ty_hareket,
            tt_hareket TYPE TABLE OF ty_hareket WITH EMPTY KEY,
            BEGIN OF ty_array_hareket,
              hareket TYPE tt_hareket,
            END OF ty_array_hareket,
            BEGIN OF ty_hesap,
              bakiye                      TYPE string,
              blokemeblag                 TYPE string,
              faizorani                   TYPE string,
              hareketler                  TYPE ty_array_hareket,
              hesapacilis_tarihi          TYPE string,
              hesapadi                    TYPE string,
              hesapcinsi                  TYPE string,
              hesapno                     TYPE string,
              hesapturu                   TYPE string,
              ibanno                      TYPE string,
              kredilimit                  TYPE string,
              kredilikullanilabilirbakiye TYPE string,
              kullanilabilirbakiye        TYPE string,
              musterino                   TYPE string,
              sonharekettarihi            TYPE string,
              subeadi                     TYPE string,
              subekodu                    TYPE string,
              vadetarihi                  TYPE string,
            END OF ty_hesap,
            tt_hesap TYPE TABLE OF ty_hesap WITH EMPTY KEY,
            BEGIN OF ty_array_hesap,
              hesap TYPE tt_hesap,
            END OF ty_array_hesap,
            BEGIN OF ty_hesap_ekstre,
              hataaciklama TYPE string,
              hatakodu     TYPE string,
              hesaplar     TYPE ty_array_hesap,
            END OF ty_hesap_ekstre,
            BEGIN OF ty_result,
              result TYPE ty_hesap_ekstre,
            END OF ty_result,
            BEGIN OF ty_response,
              response TYPE ty_result,
            END OF ty_response.

    DATA ls_json_response   TYPE ty_response.
    DATA lv_sequence_no     TYPE int4.
    DATA ls_offline_data    TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    DATA lv_json TYPE string.
    DATA lv_sifir type string VALUE '0.00'.
    lv_json = iv_json.
    REPLACE 'BagliMusteriEkstreSorgulamaResponse' IN lv_json WITH 'response'.
    REPLACE 'BagliMusteriEkstreSorgulamaResult' IN lv_json WITH 'result'.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).

    IF ls_json_response-response-result-hatakodu <> '0'.
      APPEND VALUE #( messagetype = mc_error message = ls_json_response-response-result-hataaciklama ) TO et_error_messages.
      RETURN.
    ENDIF.

    READ TABLE ls_json_response-response-result-hesaplar-hesap INTO DATA(ls_hesap) WITH KEY ibanno = ms_bankpass-iban.
    IF sy-subrc = 0.
      REPLACE ',' IN ls_hesap-kullanilabilirbakiye WITH '.'.
    ENDIF.

    LOOP AT ls_hesap-hareketler-hareket ASSIGNING FIELD-SYMBOL(<fs_hareket>) WHERE iptal NE 'E'.
      CLEAR ls_offline_data.
      REPLACE ',' IN <fs_hareket>-harekettutari WITH '.'.
      REPLACE ',' IN <fs_hareket>-bakiye WITH '.'.
      CONCATENATE <fs_hareket>-tarih+6(4)
                  <fs_hareket>-tarih+3(2)
                  <fs_hareket>-tarih+0(2)
             INTO ls_offline_data-physical_operation_date.
      lv_sequence_no += 1.
      ls_offline_data-companycode = ms_bankpass-companycode.
      ls_offline_data-glaccount   = ms_bankpass-glaccount.
      ls_offline_data-sequence_no = lv_sequence_no.
      ls_offline_data-currency    = ms_bankpass-currency.
      ls_offline_data-description = <fs_hareket>-ekstreaciklama.
      IF <fs_hareket>-harekettutari < lv_sifir.
        ls_offline_data-debit_credit = 'B'.
        ls_offline_data-payee_vkn = <fs_hareket>-karsikimlikno.
      ENDIF.
      IF <fs_hareket>-harekettutari > lv_sifir.
        ls_offline_data-debit_credit = 'A'.
        ls_offline_data-debtor_vkn = <fs_hareket>-karsikimlikno.
      ENDIF.
      SHIFT <fs_hareket>-harekettutari BY 1 PLACES LEFT.
      ls_offline_data-current_balance    = <fs_hareket>-bakiye.
      ls_offline_data-amount             = <fs_hareket>-harekettutari.
      ls_offline_data-receipt_no         = <fs_hareket>-dekontno.
      ls_offline_data-sender_name        = <fs_hareket>-karsiadsoyad.
      ls_offline_data-sender_bank        = <fs_hareket>-karsibankakod.
      ls_offline_data-sender_iban        = <fs_hareket>-karsihesapiban.
      ls_offline_data-sender_branch      = <fs_hareket>-karsisubekod.
      ls_offline_data-transaction_type   = <fs_hareket>-islemkod.
      ls_offline_data-counter_account_no = <fs_hareket>-karsikimlikno.
      ls_offline_data-accounting_date    = ls_offline_data-physical_operation_date.
      CONCATENATE <fs_hareket>-saat+0(2)
                  <fs_hareket>-saat+3(2)
                  <fs_hareket>-saat+6(2)
             INTO ls_offline_data-time.
      ls_offline_data-valor = ls_offline_data-physical_operation_date.
      APPEND ls_offline_data TO et_bank_data.
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
      SORT lt_bank_data BY sequence_no desCENDING.
      READ TABLE lt_bank_data INTO ls_bank_data INDEX 1.
      lv_closing_balance = ls_bank_data-current_balance.
    ELSE.
      lv_opening_balance  = lv_closing_balance = ls_hesap-kullanilabilirbakiye.
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