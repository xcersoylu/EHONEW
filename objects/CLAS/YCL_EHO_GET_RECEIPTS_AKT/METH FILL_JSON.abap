  METHOD fill_json.
    CONCATENATE
    '{'
      '"MT940_PARAMETRIK_HESAP_EKSTRE_SORGULA": {'
        '"KURUM_KODU": "' ms_bankpass-firm_code '",'
        '"HESAP_NO":' ms_bankpass-bankaccount ','
        '"IBAN": "",'
        '"BASLANGIC_TARIHI":' mv_startdate ','
        '"BITIS_TARIHI":' mv_enddate ','
        '"REF_NO": ""'
      '}'
    '}' INTO rv_json.
  ENDMETHOD.