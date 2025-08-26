  METHOD mapping_bank_data.
    TYPES: BEGIN OF ty_hareket,
             tarih                  TYPE string,
             islem_saati            TYPE string,
             islem_sube             TYPE string,
             fis_no                 TYPE string,
             valor                  TYPE string,
             tutar                  TYPE string,
             aciklama1              TYPE string,
             aciklama2              TYPE string,
             program_kod            TYPE string,
             refno                  TYPE string,
             hareket_sonrasi_bakiye TYPE string,
             hareket_parametre1     TYPE string,
             hareket_parametre2     TYPE string,
             hareket_parametre3     TYPE string,
           END OF ty_hareket.

    TYPES: ty_hareket_tab TYPE STANDARD TABLE OF ty_hareket WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_hesap,
             hesap_no            TYPE string,
             para_kod            TYPE string,
             musteri_no          TYPE string,
             sube_kodu           TYPE string,
             sube_adi            TYPE string,
             hesap_acilis_tarihi TYPE string,
             son_hareket_tarihi  TYPE string,
             gun_acilis_bakiye   TYPE string,
             bakiye              TYPE string,
             hesap_parametre1    TYPE string,
             hesap_parametre2    TYPE string,
             hesap_parametre3    TYPE string,
             hareket             TYPE ty_hareket_tab,
           END OF ty_hesap.

    TYPES: BEGIN OF ty_response,
             error_code TYPE string,
             error_desc TYPE string,
             hesap      TYPE ty_hesap,
           END OF ty_response.

    TYPES: BEGIN OF ty_mt940_response,
             response TYPE ty_response,
           END OF ty_mt940_response.

    DATA ls_json_response TYPE  ty_mt940_response.
    DATA lv_json TYPE string.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_sequence_no TYPE int4.
    lv_json = iv_json.
    REPLACE 'MT940_PARAMETRIK_HESAP_EKSTRE_SORGULAResponse' IN lv_json WITH 'response'.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).
    IF ls_json_response-response-error_code <> '0'.
      APPEND VALUE #( messagetype = mc_error message = ls_json_response-response-error_desc ) TO et_error_messages.
      RETURN.
    ENDIF.

    LOOP AT ls_json_response-response-hesap-hareket INTO DATA(ls_hareket).
      lv_sequence_no += 1.
      ls_offline_data-companycode = ms_bankpass-companycode.
      ls_offline_data-sequence_no = lv_sequence_no.
      ls_offline_data-glaccount   = ms_bankpass-glaccount.
      ls_offline_data-currency    = ms_bankpass-currency.
      ls_offline_data-description = ls_hareket-aciklama1.
      ls_offline_data-amount      = ls_hareket-tutar.
      ls_offline_data-receipt_no  = ls_hareket-fis_no.
      ls_offline_data-current_balance = ls_hareket-hareket_sonrasi_bakiye.
      IF ls_hareket-tutar < 0.
        ls_offline_data-debit_credit = 'B'.
      ELSE.
        ls_offline_data-debit_credit = 'A'.
      ENDIF.
      ls_offline_data-transaction_type        = ls_hareket-program_kod.
      ls_offline_data-physical_operation_date = ls_hareket-tarih.
      ls_offline_data-time                    = ls_hareket-islem_saati.
      ls_offline_data-valor                   = ls_hareket-valor.
      APPEND ls_offline_data TO et_bank_data.
      CLEAR  ls_offline_data.
    ENDLOOP.
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
                    opening_balance =  ls_json_response-response-hesap-gun_acilis_bakiye
                    closing_balance =  ls_json_response-response-hesap-bakiye
                    bank_id =  ''
                    account_id = ''
                    bank_code =   ms_bankpass-bank_code
    ) TO  et_bank_balance.
  ENDMETHOD.