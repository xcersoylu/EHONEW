  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_muhasebekayitlari,
              muhasebetarihi       TYPE string,
              islemsubesi          TYPE string,
              muhasebereferanskodu TYPE string,
              muhasebereferansno   TYPE string,
              aciklama             TYPE string,
              borcalacak           TYPE string,
              kayitnumarasi        TYPE string,
              tutar                TYPE string,
              bakiye               TYPE string,
              gerceklesmetarihi    TYPE string,
              sorguid              TYPE string,
              sonuckoduaciklama    TYPE string,
              gonderenadsoyad      TYPE string,
              gonderenhesapno      TYPE string,
              gonderenkimlikno     TYPE string,
              alicihesapno         TYPE string,
              mt940kodu            TYPE string,
              mt940aciklamasi      TYPE string,
              pk                   TYPE string,
            END OF ty_muhasebekayitlari,
            tt_muhasebekayitlari TYPE TABLE OF ty_muhasebekayitlari WITH DEFAULT KEY,
            BEGIN OF ty_hesapbilgisi,
              subekod         TYPE string,
              subeadi         TYPE string,
              hesapno         TYPE string,
              ekno            TYPE string,
              acilistarihi    TYPE string,
              parabirimi      TYPE string,
              hesaptipi       TYPE string,
              acilisbakiyesi  TYPE string,
              kapanisbakiyesi TYPE string,
              bloketutar      TYPE string,
              bakiye          TYPE string,
              iban            TYPE string,
            END OF ty_hesapbilgisi,
            BEGIN OF ty_hesapekstresi,
              hesapbilgisi      TYPE ty_hesapbilgisi,
              muhasebekayitlari TYPE tt_muhasebekayitlari,
            END OF ty_hesapekstresi,
            tt_hesapekstresi TYPE TABLE OF ty_hesapekstresi WITH DEFAULT KEY,
            BEGIN OF ty_anadolubank,
              sonuckodu         TYPE string,
              sorguid           TYPE string,
              sonuckoduaciklama TYPE string,
              ekstreler         TYPE tt_hesapekstresi,
            END OF ty_anadolubank.
    DATA ls_response_json TYPE ty_anadolubank.
    DATA lv_sequence_no TYPE int4.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    /ui2/cl_json=>deserialize(
      EXPORTING json = iv_json
      CHANGING data = ls_response_json ).

    IF ls_response_json-sonuckodu > 0.
      APPEND VALUE #( messagetype = mc_error message = ls_response_json-sonuckoduaciklama ) TO et_error_messages.
      return.
    ENDIF.

    READ TABLE ls_response_json-ekstreler INTO DATA(ls_account) WITH KEY hesapbilgisi-iban = ms_bankpass-iban.
    LOOP AT ls_account-muhasebekayitlari INTO DATA(ls_muhasebekayitlari).
      lv_sequence_no += 1.
      ls_offline_data-companycode  = ms_bankpass-companycode.
      ls_offline_data-glaccount    = ms_bankpass-glaccount.
      ls_offline_data-sequence_no  = lv_sequence_no.
      ls_offline_data-currency     = ms_bankpass-currency.
      ls_offline_data-amount       = ls_muhasebekayitlari-tutar.
      ls_offline_data-description  = ls_muhasebekayitlari-aciklama.
      ls_offline_data-debit_credit = ls_muhasebekayitlari-borcalacak.

      DATA(lv_len) = strlen( ls_muhasebekayitlari-gonderenkimlikno ).
      IF lv_len = 10 OR lv_len = 11.
        IF ls_offline_data-debit_credit = 'B'.
          ls_offline_data-payee_vkn = ls_muhasebekayitlari-gonderenkimlikno.
        ENDIF.
        IF ls_offline_data-debit_credit = 'A'.
          ls_offline_data-debtor_vkn = ls_muhasebekayitlari-gonderenkimlikno.
        ENDIF.
      ENDIF.

      ls_offline_data-current_balance = ls_muhasebekayitlari-bakiye.
      ls_offline_data-receipt_no      = ls_muhasebekayitlari-pk.

      IF ls_muhasebekayitlari-gerceklesmetarihi IS NOT INITIAL.
        REPLACE ALL OCCURRENCES OF  '.' IN ls_muhasebekayitlari-gerceklesmetarihi WITH ''.
        REPLACE ALL OCCURRENCES OF  ':' IN ls_muhasebekayitlari-gerceklesmetarihi WITH ''.
        CONCATENATE ls_muhasebekayitlari-gerceklesmetarihi+4(4)
            ls_muhasebekayitlari-gerceklesmetarihi+2(2)
            ls_muhasebekayitlari-gerceklesmetarihi(2)
       INTO ls_offline_data-physical_operation_date.

        ls_offline_data-time             = ls_muhasebekayitlari-gerceklesmetarihi+9(6).
        ls_offline_data-transaction_type = ls_muhasebekayitlari-mt940kodu.
        APPEND ls_offline_data TO et_bank_data.
        CLEAR ls_offline_data.
      ENDIF.
    ENDLOOP.
*    IF sy-subrc = 0.
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
                    opening_balance =  ls_account-hesapbilgisi-acilisbakiyesi
                    closing_balance = ls_account-hesapbilgisi-kapanisbakiyesi
                    bank_id =  ''
                    account_id = ''
                    bank_code =   ms_bankpass-bank_code
    ) TO  et_bank_balance.
*    ENDIF.
  ENDMETHOD.