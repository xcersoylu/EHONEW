  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_hareket,
              tarih           TYPE string,
              islemsaati      TYPE string,
              islemsube       TYPE string,
              fisno           TYPE string,
              valor           TYPE string,
              tutar           TYPE string,
              aciklama1       TYPE string,
              aciklama2       TYPE string,
              programkod      TYPE string,
              refno           TYPE string,
              islemsonubakiye TYPE string,
              iban            TYPE string,
              vkn             TYPE string,
            END OF ty_hareket,
            tt_hareket TYPE TABLE OF ty_hareket WITH EMPTY KEY,
            BEGIN OF ty_aktiviteler,
              hareket TYPE tt_hareket,
            END OF ty_aktiviteler,
            BEGIN OF ty_hesap,
              hesapno           TYPE string,
              iban              TYPE string,
              parakod           TYPE string,
              musterino         TYPE string,
              subekodu          TYPE string,
              subeadi           TYPE string,
              hesapacilistarihi TYPE string,
              sonharekettarihi  TYPE string,
              bakiye            TYPE string,
              aktiviteler       TYPE ty_aktiviteler,
              bloketuttari      TYPE string,
              acilisbakiyesi    TYPE string,
            END OF ty_hesap,
            BEGIN OF ty_hareketler,
              hatakodu     TYPE string,
              hataaciklama TYPE string,
              hesap        TYPE ty_hesap,
            END OF ty_hareketler,
            BEGIN OF ty_json,
              hareketler TYPE ty_hareketler,
            END OF ty_json.
    DATA ls_json_response   TYPE ty_json.
    DATA lv_sequence_no     TYPE int4.
    DATA ls_offline_data    TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).
    if ls_json_response-hareketler-hatakodu <> '0'.
      APPEND VALUE #( messagetype = mc_error message = ls_json_response-hareketler-hataaciklama ) TO et_error_messages.
      RETURN.
    endif.
    lv_opening_balance = ls_json_response-hareketler-hesap-acilisbakiyesi.
    SORT ls_json_response-hareketler-hesap-aktiviteler-hareket BY refno ASCENDING. "hareketler sırası ile gelmiyordu refno ya göre sortlandı.
    LOOP AT ls_json_response-hareketler-hesap-aktiviteler-hareket ASSIGNING FIELD-SYMBOL(<fs_hareket>) WHERE tarih IS NOT INITIAL.
      CLEAR ls_offline_data.
      lv_sequence_no += 1.
      ls_offline_data-companycode = ms_bankpass-companycode.
      ls_offline_data-glaccount   = ms_bankpass-glaccount.
      ls_offline_data-sequence_no = lv_sequence_no.
      ls_offline_data-currency    = ms_bankpass-currency.
      CONCATENATE <fs_hareket>-aciklama1
                  <fs_hareket>-aciklama2
                  INTO ls_offline_data-description SEPARATED BY space.
      REPLACE ALL OCCURRENCES OF ',' IN <fs_hareket>-tutar WITH '.'.
      IF <fs_hareket>-tutar > 0.
        ls_offline_data-debit_credit = 'A'.
        ls_offline_data-debtor_vkn = <fs_hareket>-vkn.
      ENDIF.
      IF <fs_hareket>-tutar < 0.
        ls_offline_data-debit_credit = 'B'.
        ls_offline_data-payee_vkn = <fs_hareket>-vkn.
        SHIFT <fs_hareket>-tutar BY 1 PLACES LEFT.
      ENDIF.
      ls_offline_data-amount           = <fs_hareket>-tutar.
      REPLACE ALL OCCURRENCES OF ',' IN <fs_hareket>-islemsonubakiye WITH '.'.
      ls_offline_data-current_balance  = <fs_hareket>-islemsonubakiye.
      ls_offline_data-receipt_no       = <fs_hareket>-refno.
      ls_offline_data-sender_iban      = <fs_hareket>-iban.
      ls_offline_data-sender_branch    = <fs_hareket>-islemsube.

      CONCATENATE <fs_hareket>-tarih+6(4)
                  <fs_hareket>-tarih+3(2)
                  <fs_hareket>-tarih+0(2)
             INTO ls_offline_data-physical_operation_date.

      CONCATENATE <fs_hareket>-islemsaati+0(2)
                  <fs_hareket>-islemsaati+3(2)
                  <fs_hareket>-islemsaati+6(2)
             INTO ls_offline_data-time.

      CONCATENATE <fs_hareket>-valor+6(4)
                  <fs_hareket>-valor+3(2)
                  <fs_hareket>-valor+0(2)
           INTO ls_offline_data-valor.
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
*      SORT lt_bank_data BY physical_operation_date time ASCENDING.
*      READ TABLE lt_bank_data INTO data(ls_bank_data) INDEX 1.
      lv_closing_balance = ls_offline_data-current_balance.
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