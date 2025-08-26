  METHOD fill_json.
    DATA lv_cdata TYPE string.

    DATA(lv_begindate) = mv_startdate+6(2) && '.' &&
                         mv_startdate+4(2) && '.' &&
                         mv_startdate+0(4).

    DATA(lv_enddate) = mv_enddate+6(2) && '.' &&
                       mv_enddate+4(2) && '.' &&
                       mv_enddate+0(4).

    CONCATENATE
*    '<![CDATA[<data>'
    '<HESHARSORGU>'
      '<FIRMA_AD>' ms_bankpass-service_user '</FIRMA_AD>'
      '<FIRMA_ANAHTAR>' ms_bankpass-service_password '</FIRMA_ANAHTAR>'
      '<SUBENO>' ms_bankpass-branch_code '</SUBENO>'
      '<HESNO>' ms_bankpass-bankaccount '</HESNO>'
      '<BASTAR>' lv_begindate '</BASTAR>'
      '<BITTAR>' lv_enddate '</BITTAR>'
      '<GON_IBAN_EH>E</GON_IBAN_EH>'
      '<SON_BKY_EH>E</SON_BKY_EH>'
      '<KUL_BKY_EH>E</KUL_BKY_EH>'
*      '<DEKONTNO_EH>E</DEKONTNO_EH>'
      '<BLOKE_BKY_EH>E</BLOKE_BKY_EH>'
      '<ALICI_AD_EH>E</ALICI_AD_EH>'
      '<ALICI_IBAN_EH>E</ALICI_IBAN_EH>'
    '</HESHARSORGU>' INTO lv_cdata.
*    '</data>]]>'

    REPLACE ALL OCCURRENCES OF '<' IN lv_cdata WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN lv_cdata WITH '&gt;'.

    CONCATENATE
    '{'
        '"TEBWebSrv": {'
            '"UserName": "' ms_bankpass-owner_title '",'
            '"Password": "' ms_bankpass-owner_description '",'
            '"ServiceID":' ms_bankpass-additional_field1 ','
            '"Environment": "' ms_bankpass-additional_field2 '",'
            '"InputDataXML": "' lv_cdata '"'

        '}'
    '}' INTO rv_json.

  ENDMETHOD.