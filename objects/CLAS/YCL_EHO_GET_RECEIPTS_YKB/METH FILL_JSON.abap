  METHOD fill_json.
    DATA lv_dovizkodu TYPE string.
    CASE ms_bankpass-currency.
      WHEN 'TRY'.
        lv_dovizkodu = 'TL'.
      WHEN OTHERS.
        lv_dovizkodu = ms_bankpass-currency.
    ENDCASE.

    CONCATENATE
      '{ "sorgula": { "arg0": {'
      '"baslangicSaat":'     '0000,'
      '"baslangicTarih":'    mv_startdate ','
      '"bitisSaat":'         '2359,'
      '"bitisTarih":'        mv_enddate ','
      '"dovizKodu":"' lv_dovizkodu '",'
      '"firmaKodu":"' ms_bankpass-firm_code '",'
      '"hesapNo":'           ms_bankpass-bankaccount
      '} } }'
      INTO rv_json.
  ENDMETHOD.