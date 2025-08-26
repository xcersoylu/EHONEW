  METHOD mapping_bank_data.

TYPES: BEGIN OF ty_detay,
         ValorTarihi             TYPE string,
         IslemTarihi             TYPE string,
         ReferansNo              TYPE string,
         KarsiHesapIBAN          TYPE string,
         Tutar                   TYPE string,
         SonBakiye               TYPE string,
         Aciklama                TYPE string,
         VKN                     TYPE string,
         TutarBorcAlacak         TYPE string,
         SonBakiyeBorcAlacak     TYPE string,
         FonksiyonKodu           TYPE string,
         MT940FonksiyonKodu      TYPE string,
         FisNo                   TYPE string,
         OzelAlan1               TYPE string,
         OzelAlan2               TYPE string,
         AboneNo                 TYPE string,
         FaturaNo                TYPE string,
         FaturaDonem             TYPE string,
         FaturaSonOdemeTarihi    TYPE string,
         LehdarVKN               TYPE string,
         LehdarTCKN              TYPE string,
         AmirVKN                 TYPE string,
         AmirTCKN                TYPE string,
         BorcluIBAN              TYPE string,
         AlacakliIBAN            TYPE string,
         DekontBorcAciklama      TYPE string,
         DekontAlacakAciklama    TYPE string,
         IslemiYapanSube         TYPE string,
         HareketDurumu           TYPE string,
         TimeStamp               TYPE string,
       END OF ty_detay.
types : tt_detay type table of ty_detay WITH DEFAULT KEY.
TYPES: BEGIN OF ty_hesap,
         SqlID                     TYPE string,
         HesapTuruAdi              TYPE string,
         HesapNo                   TYPE string,
         URF                       TYPE string,
         SubeKodu                  TYPE string,
         SubeAdi                   TYPE string,
         DovizKodu                 TYPE string,
         IBAN                      TYPE string,
         AcilisIlkBakiye           TYPE string,
         AcilisGunBakiye           TYPE string,
         CariBakiye                TYPE string,
         Bakiye                    TYPE string,
         BlokeMeblag               TYPE string,
         HesapAcilisTarihi         TYPE string,
         SonHareketTarihi          TYPE string,
         HesapTuruKodu             TYPE string,
         LastTmSt                  TYPE string,
         AktifFlag                 TYPE string,
         DetayFlag                 TYPE string,
         DekontBilgiFlag           TYPE string,
         VadeliHareketlerIslensin TYPE string,
         Detay                     TYPE tt_detay,
       END OF ty_hesap.

TYPES: BEGIN OF ty_hesaphareketleri_result,
         Hesap TYPE ty_hesap,
       END OF ty_hesaphareketleri_result.
types  tt_hesaphareketleri_result type table of ty_hesaphareketleri_result WITH DEFAULT KEY.
TYPES: BEGIN OF ty_getextre_result,
         HesapHareketleriResult TYPE tt_hesaphareketleri_result,
       END OF ty_getextre_result.

TYPES: BEGIN OF ty_response,
         GetExtreWithParamsResult TYPE ty_getextre_result,
       END OF ty_response.

TYPES: BEGIN OF ty_json,
         GetExtreWithParamsResponse TYPE ty_response,
       END OF ty_json.

    DATA ls_json_response TYPE ty_json.
    DATA lv_json TYPE string.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_sequence_no TYPE int4.
    DATA lv_doviz_kod TYPE string.
    lv_json = iv_json.
    /ui2/cl_json=>deserialize( EXPORTING json = lv_json CHANGING data = ls_json_response ).

    IF ms_bankpass-currency EQ 'TRY' OR ms_bankpass-currency EQ 'TRL'.
      lv_doviz_kod = 'YTL'.
    ELSE.
      lv_doviz_kod = ms_bankpass-currency.
    ENDIF.

    READ TABLE ls_json_response-getextrewithparamsresponse-getextrewithparamsresult-hesaphareketleriresult INTO DATA(ls_hesap) WITH KEY hesap-Dovizkodu = lv_doviz_kod.

    LOOP AT ls_hesap-hesap-detay INTO DATA(ls_detay).
      lv_sequence_no += 1.
      ls_offline_data-companycode = ms_bankpass-companycode.
      ls_offline_data-glaccount   = ms_bankpass-glaccount.
      ls_offline_data-sequence_no = lv_sequence_no.
      ls_offline_data-currency    = ms_bankpass-currency.
      REPLACE ',' in ls_Detay-tutar WITH '.'.
      ls_offline_data-amount = ls_detay-tutar.
      ls_offline_data-description = ls_detay-aciklama.

      IF ls_detay-dekontalacakaciklama IS NOT INITIAL AND ls_detay-dekontborcaciklama IS NOT INITIAL.

        CONCATENATE ls_offline_data-description
                    ls_detay-dekontalacakaciklama
                    ls_detay-dekontborcaciklama
                    INTO ls_offline_data-description SEPARATED BY space.

      ELSEIF ls_detay-dekontalacakaciklama IS NOT INITIAL.

        CONCATENATE ls_offline_data-description
                    ls_detay-dekontalacakaciklama
                    INTO ls_offline_data-description SEPARATED BY space.

      ELSEIF ls_detay-dekontborcaciklama IS NOT INITIAL.

        CONCATENATE ls_offline_data-description
                    ls_detay-dekontborcaciklama
                    INTO ls_offline_data-description SEPARATED BY space.

      ENDIF.

      IF ls_detay-tutarborcalacak EQ '+'.
        ls_offline_data-debtor_vkn = ls_detay-vkn.
        ls_offline_data-debit_credit = 'A'.
        ls_offline_data-sender_iban = ls_detay-borcluiban.
      ELSEIF ls_detay-tutarborcalacak EQ '-'.
        ls_offline_data-payee_vkn = ls_detay-vkn.
        ls_offline_data-debit_credit = 'B'.
        ls_offline_data-sender_iban      = ls_detay-alacakliiban.
      ENDIF.

      ls_offline_data-additional_field1                = ls_detay-ozelalan1.
      ls_offline_data-additional_field2                = ls_detay-ozelalan2.
      REPLACE ',' in ls_Detay-sonbakiye WITH '.'.
      ls_offline_data-current_balance          = ls_detay-sonbakiye.
      ls_offline_data-receipt_no             = ls_detay-fisno.
      ls_offline_data-physical_operation_date = ls_detay-islemtarihi.
      ls_offline_data-valor                 = ls_detay-valortarihi.
      ls_offline_data-sender_branch         = ls_detay-islemiyapansube.
      ls_offline_data-transaction_type            = ls_detay-mt940fonksiyonkodu.

      IF strlen( ls_detay-timestamp ) GE 14.
        ls_offline_data-time = ls_detay-timestamp+8(6).
      ENDIF.
      APPEND ls_offline_data TO et_bank_data.
      CLEAR ls_offline_data.
    ENDLOOP.
    replace ',' in ls_hesap-hesap-acilisgunbakiye WITH '.'.
    replace ',' in ls_Detay-sonbakiye WITH '.'.
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
                    opening_balance =  ls_hesap-hesap-acilisgunbakiye
                    closing_balance = ls_detay-sonbakiye
                    bank_id =  ''
                    account_id = ''
                    bank_code =   ms_bankpass-bank_code
    ) TO  et_bank_balance.

  ENDMETHOD.