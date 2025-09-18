  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_hareket,
              aciklama            TYPE string,
              alacaklivkn         TYPE string,
              anlikbakiye         TYPE string,
              borcalacak          TYPE string,
              borcluvkn           TYPE string,
              dekontno            TYPE string,
              fizikselislemtarihi TYPE string,
              gonderenad          TYPE string,
              gonderenbanka       TYPE string,
              gonderenibanno      TYPE string,
              gonderensube        TYPE string,
              hareketkey          TYPE string,
              islemtipi           TYPE string,
              karsihesapvno       TYPE string,
              kontratno           TYPE string,
              muhasebetarihi      TYPE string,
              saat                TYPE string,
              sirano              TYPE string,
              tutar               TYPE string,
              valor               TYPE string,
              uzunaciklama        TYPE string,
            END OF ty_hareket,
            tt_hareket type table of ty_hareket WITH EMPTY KEY,
            BEGIN OF ty_hareketler,
              hareket TYPE tt_hareket, "ty_hareket,
            END OF ty_hareketler,
            tt_hareketler TYPE TABLE OF ty_hareketler WITH EMPTY KEY,
            BEGIN OF ty_hesap,
              acilisbakiyesi  TYPE string,
              doviztipi       TYPE string,
              hesapno         TYPE string,
              kapanisbakiyesi TYPE string,
              subeadi         TYPE string,
              subekodu        TYPE string,
              hareketler      TYPE ty_hareketler, "tt_hareketler,
            END OF ty_hesap,
            BEGIN OF ty_hesaplar,
              hesap TYPE ty_hesap,
            END OF ty_hesaplar,
            tt_hesaplar TYPE TABLE OF ty_hesaplar WITH EMPTY KEY,
            BEGIN OF ty_return,
              id                 TYPE string,
              bankaadi           TYPE string,
              bankakodu          TYPE string,
              bankavergidairesi  TYPE string,
              bankaverginumarasi TYPE string,
              hataaciklamasi     TYPE string,
              hatakodu           TYPE string,
              hesaplar           TYPE ty_hesaplar, "tt_hesaplar,
            END OF ty_return,
            BEGIN OF ty_response,
                return type ty_Return,
            END OF ty_response,
            BEGIN OF ty_json,
             response type ty_response,
            end of ty_json.
    DATA ls_json_response TYPE ty_json.
    DATA lv_sequence_no TYPE int4.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    DATA lv_json type string.
    lv_json = iv_json.
    REPLACE 'sorgulaResponse' in lv_json WITH 'response'.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
*    READ TABLE ls_json_response-response-return-hesaplar-hesap-hareketler INTO DATA(ls_hesaplar) WITH KEY hesap-hesapno = ms_bankpass-bankaccount.
    LOOP AT ls_json_response-response-return-hesaplar-hesap-hareketler-hareket INTO DATA(ls_hareketler).
      ls_offline_data-sequence_no = ls_hareketler-sirano.
      ls_offline_data-glaccount   = ms_bankpass-glaccount.
      ls_offline_data-companycode = ms_bankpass-companycode.
      ls_offline_data-currency    = ms_bankpass-currency.
      ls_offline_data-amount      = ls_hareketler-tutar.
      ls_offline_data-operationalglaccount = ls_json_response-response-return-hesaplar-hesap-hesapno.
      IF ls_hareketler-uzunaciklama IS INITIAL.
        ls_offline_data-description = ls_hareketler-aciklama.
      ELSE.
        ls_offline_data-description = ls_hareketler-uzunaciklama.
      ENDIF.
      ls_offline_data-debit_credit    = ls_hareketler-borcalacak.
      ls_offline_data-payee_vkn       = ls_hareketler-borcluvkn.
      ls_offline_data-debtor_vkn      = ls_hareketler-alacaklivkn.
      ls_offline_data-current_balance = ls_hareketler-anlikbakiye.
      ls_offline_data-receipt_no      = ls_hareketler-dekontno.
      ls_offline_data-sender_iban     = ls_hareketler-gonderenibanno.
      ls_offline_data-sender_branch   = ls_hareketler-gonderensube.
      ls_offline_data-sender_bank     = ls_hareketler-gonderenbanka.
      ls_offline_data-sender_name     = ls_hareketler-gonderenad.
      ls_offline_data-counter_account_no  = ls_hareketler-karsihesapvno.
      ls_offline_data-time            = ls_hareketler-saat(6).
      ls_offline_data-transaction_type = ls_hareketler-islemtipi.
      CONCATENATE lv_today(2)
                  ls_hareketler-muhasebetarihi
                  INTO ls_offline_data-accounting_date.
      CONCATENATE lv_today(2)
                  ls_hareketler-valor
                  INTO ls_offline_data-valor.
      ls_offline_data-physical_operation_date = ls_offline_data-accounting_date.
***      IF ls_list-last_updated_date_time LT ls_hareket-fiziksel_islem_tarihi.
***        ls_list-last_updated_date_time = ls_hareket-fiziksel_islem_tarihi.
***      ENDIF.
      APPEND ls_offline_data TO et_bank_data.
      CLEAR ls_offline_data.
    ENDLOOP.
*    IF sy-subrc = 0.
*      DATA(lt_bank_data) = et_bank_data.
*      SORT lt_bank_data BY sequence_no ASCENDING.
*      READ TABLE lt_bank_data INTO DATA(ls_bank_data) INDEX 1.
*      IF ls_bank_data-debit_credit = 'B'.
*        lv_opening_balance = ls_bank_data-current_balance + ls_bank_data-amount.
*      ELSE.
*        lv_opening_balance = ls_bank_data-current_balance - ls_bank_data-amount.
*      ENDIF.
*      SORT lt_bank_data BY sequence_no ASCENDING.
*      READ TABLE lt_bank_data INTO ls_bank_data INDEX 1.
*      lv_closing_balance = ls_bank_data-current_balance.
*    ELSE.
      lv_opening_balance  = ls_json_response-response-return-hesaplar-hesap-acilisbakiyesi.
      lv_closing_balance = ls_json_response-response-return-hesaplar-hesap-kapanisbakiyesi.
*    ENDIF.

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