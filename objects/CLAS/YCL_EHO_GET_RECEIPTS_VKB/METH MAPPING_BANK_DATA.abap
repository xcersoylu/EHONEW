  METHOD mapping_bank_data.
    TYPES : BEGIN OF ty_detaylar,
              key   TYPE string,
              value TYPE string,
            END OF ty_detaylar,
            tt_detaylar TYPE TABLE OF ty_detaylar WITH EMPTY KEY,
            BEGIN OF ty_keyvalueofstring,
              keyvalueofstringstring TYPE tt_detaylar,
            END OF ty_keyvalueofstring,
            BEGIN OF ty_hareketler,
              islemtarihi        TYPE string,
              islemno            TYPE string,
              islemadi           TYPE string,
              tutar              TYPE string,
              borcalacak         TYPE string,
              aciklama           TYPE string,
              islemoncesibakiye  TYPE string,
              islemsonrasibakiye TYPE string,
              islemyeri          TYPE string,
              islemkanal         TYPE string,
              kartno             TYPE string,
              islemkodu          TYPE string,
              detaylar           TYPE ty_keyvalueofstring, "tt_detaylar,
              islemtarihzamani   TYPE string,
              id                 TYPE string,
            END OF ty_hareketler,
            tt_hareketler TYPE TABLE OF ty_hareketler WITH EMPTY KEY,
            BEGIN OF ty_dtoekstrehareket,
              dtoekstrehareket TYPE tt_hareketler,
            END OF ty_dtoekstrehareket,
            BEGIN OF ty_ekstrehesap,
              hesapno                  TYPE string,
              musterino                TYPE string,
              musteriunvani            TYPE string,
              subekodu                 TYPE string,
              subeadi                  TYPE string,
              doviztipi                TYPE string,
              acilisbakiye             TYPE string,
              caribakiye               TYPE string,
              kullanilabilirbakiye     TYPE string,
              kredilibankomatlimiti    TYPE string,
              kredibakiyesi            TYPE string,
              sonharekettarihi         TYPE string,
              vergikimliknumarasi      TYPE string,
              hareketler               TYPE ty_dtoekstrehareket, "tt_hareketler,
              hesaptipi                TYPE string,
              vadebaslangictarihi      TYPE string,
              vadebitistarihi          TYPE string,
              vadesonubeklenenbakiye   TYPE string,
              vadefaizorani            TYPE string,
              vadesonuodenecekbrutfaiz TYPE string, "vadesonuodenecekbrutfaiztutari
              vadesonuodeneceknetfaiz  TYPE string, "vadesonuodeneceknetfaiztutari
              hesap_no_iban            TYPE string,
            END OF ty_ekstrehesap,
            tt_ekstrehesap TYPE TABLE OF ty_ekstrehesap WITH EMPTY KEY,
            BEGIN OF ty_dtoekstrehesap,
              dtoekstrehesap TYPE ty_ekstrehesap,
            END OF ty_dtoekstrehesap,
            BEGIN OF ty_getirhareketresult,
              bankakodu          TYPE string,
              bankaadi           TYPE string,
              bankavergidairesi  TYPE string,
              bankaverginumarasi TYPE string,
              islemkodu          TYPE string,
              islemaciklamasi    TYPE string,
              hesaplar           TYPE ty_dtoekstrehesap, "tt_ekstrehesap,
            END OF ty_getirhareketresult,
            BEGIN OF ty_getirhareketresponse,
              getirhareketresult TYPE ty_getirhareketresult,
            END OF ty_getirhareketresponse,
            BEGIN OF ty_body,
              getirhareketresponse TYPE ty_getirhareketresponse,
            END OF ty_body,
            BEGIN OF ty_envelope,
              header TYPE string,
              body   TYPE ty_body,
            END OF ty_envelope,
            BEGIN OF ty_json,
              envelope TYPE ty_envelope,
            END OF ty_json.
    DATA ls_json_response   TYPE ty_json. "ty_getirhareket.
    DATA lv_json            TYPE string.
    DATA lv_bankinternalid  TYPE bankl.
    DATA ls_offline_data    TYPE yeho_t_offlinedt.
    DATA lv_opening_balance TYPE yeho_e_opening_balance.
    DATA lv_closing_balance TYPE yeho_e_closing_balance.
    DATA lv_sequence_no TYPE int4.
    lv_json = iv_json.
*Alan adı uzun olduğu için değiştirildi.
    REPLACE 'VadeSonuOdenecekBrutFaizTutari' IN lv_json WITH 'VadeSonuOdenecekBrutFaiz'.
    REPLACE 'VadeSonuOdenecekNetFaizTutari' IN lv_json WITH 'VadeSonuOdenecekNetFaiz'.
***
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).

    lv_bankinternalid = |{ ms_bankpass-bank_code ALPHA = IN }| && '-' && |{ ms_bankpass-branch_code ALPHA = IN }|.

    SELECT SINGLE bankbranch
      FROM i_bank_2 INNER JOIN i_companycode ON i_bank_2~bankcountry EQ  i_companycode~country
      WHERE bankinternalid EQ  @lv_bankinternalid
        AND companycode EQ @ms_bankpass-companycode
     INTO @DATA(lv_branch_name).
    lv_opening_balance = ls_json_response-envelope-body-getirhareketresponse-getirhareketresult-hesaplar-dtoekstrehesap-acilisbakiye.
    LOOP AT ls_json_response-envelope-body-getirhareketresponse-getirhareketresult-hesaplar-dtoekstrehesap-hareketler-dtoekstrehareket
    ASSIGNING FIELD-SYMBOL(<fs_hareket>).
      CLEAR ls_offline_data.
      lv_sequence_no += 1.
      ls_offline_data-companycode = ms_bankpass-companycode.
      ls_offline_data-glaccount   = ms_bankpass-glaccount.
      ls_offline_data-sequence_no = lv_sequence_no.
      ls_offline_data-currency    = ms_bankpass-currency.
      IF <fs_hareket>-tutar < 0.
        SHIFT <fs_hareket>-tutar BY 1 PLACES LEFT.
      ENDIF.
      ls_offline_data-amount       = <fs_hareket>-tutar.
      ls_offline_data-description    = <fs_hareket>-aciklama.
      ls_offline_data-debit_credit = <fs_hareket>-borcalacak.

      READ TABLE <fs_hareket>-detaylar-keyvalueofstringstring INTO DATA(ls_detay) WITH KEY key = 'GonderenKimlikNumarasi'.
      IF sy-subrc = 0.
        ls_offline_data-payee_vkn = ls_detay-value.
      ENDIF.

      READ TABLE <fs_hareket>-detaylar-keyvalueofstringstring INTO ls_detay WITH KEY key = 'AliciKimlikNumarasi'.
      IF sy-subrc = 0.
        ls_offline_data-debtor_vkn = ls_detay-value.
      ENDIF.

      ls_offline_data-current_balance = <fs_hareket>-islemsonrasibakiye.
      ls_offline_data-receipt_no      = <fs_hareket>-islemno.


      CONCATENATE <fs_hareket>-islemtarihi+0(4)
                  <fs_hareket>-islemtarihi+5(2)
                  <fs_hareket>-islemtarihi+8(2)
             INTO ls_offline_data-physical_operation_date.

      CONCATENATE <fs_hareket>-islemtarihi+11(2)
                  <fs_hareket>-islemtarihi+14(2)
                  <fs_hareket>-islemtarihi+17(2)
             INTO ls_offline_data-time.

      CONCATENATE <fs_hareket>-islemtarihi+11(2)
                  <fs_hareket>-islemtarihi+14(2)
                  <fs_hareket>-islemtarihi+17(2)
             INTO ls_offline_data-valor.

      IF <fs_hareket>-borcalacak = 'B'.
        READ TABLE <fs_hareket>-detaylar-keyvalueofstringstring INTO ls_detay WITH KEY key = 'AliciIbanKumarasi'.
        IF sy-subrc = 0.
          ls_offline_data-sender_iban = ls_detay-value.
        ENDIF.
      ELSE.

        READ TABLE <fs_hareket>-detaylar-keyvalueofstringstring INTO ls_detay WITH KEY key = 'GonderenIbanKumarasi'.
        IF sy-subrc = 0.
          ls_offline_data-sender_iban = ls_detay-value.
        ENDIF.
      ENDIF.

      READ TABLE <fs_hareket>-detaylar-keyvalueofstringstring INTO ls_detay WITH KEY key = 'SwiftKodu'.
      IF sy-subrc = 0.
        ls_offline_data-transaction_type  = ls_detay-value.
      ENDIF.

      READ TABLE <fs_hareket>-detaylar-keyvalueofstringstring INTO ls_detay WITH KEY key = 'GonderenSubeKodu'.
      IF sy-subrc = 0.
        ls_offline_data-sender_branch = ls_detay-value.
      ENDIF.
      APPEND ls_offline_data TO et_bank_data.
    ENDLOOP.
    IF sy-subrc = 0.
      lv_closing_balance = ls_offline_data-current_balance.
    ELSE.
      lv_closing_balance = lv_opening_balance.
    ENDIF.


*    IF sy-subrc = 0.
*      SORT et_bank_data BY physical_operation_date time ASCENDING.
*      READ TABLE et_bank_data INTO DATA(ls_hareket) INDEX 1.
*      IF ls_hareket-debit_credit = 'B'.
*        lv_opening_balance = ls_hareket-current_balance + ls_hareket-amount.
*      ELSE.
*        lv_opening_balance = ls_hareket-current_balance - ls_hareket-amount.
*      ENDIF.
*      SORT et_bank_data BY physical_operation_date time DESCENDING.
*      READ TABLE et_bank_data INTO ls_hareket INDEX 1.
*      IF sy-subrc = 0.
*        lv_closing_balance = ls_hareket-current_balance.
*      ENDIF.
*    ELSE.
*      lv_opening_balance         = ls_hesap-acilis_bakiye.
*      lv_closing_balance        = ls_hesap-cari_bakiye.
*    ENDIF.
    APPEND VALUE #( companycode             = ms_bankpass-companycode
                    glaccount               = ms_bankpass-glaccount
                    valid_from              = mv_startdate
                    account_no              = ms_bankpass-bankaccount
                    branch_no               = ms_bankpass-branch_code
                    branch_name_description = lv_bankinternalid
                    currency                = ms_bankpass-currency
                    opening_balance         = lv_opening_balance
                    closing_balance         = lv_closing_balance
                    bank_id                 =  ''
                    account_id              = ''
                    bank_code               =   ms_bankpass-bank_code
    ) TO  et_bank_balance.

  ENDMETHOD.