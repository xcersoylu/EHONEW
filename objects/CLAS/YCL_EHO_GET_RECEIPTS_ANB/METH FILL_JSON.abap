  METHOD fill_json.
    DATA(lv_startdate) = mv_startdate+6(2) && '.' &&
                         mv_startdate+4(2) && '.' &&
                         mv_startdate+0(4) && | | && '08:00:00'.

    DATA(lv_enddate) = mv_enddate+6(2) && '.' &&
                       mv_enddate+4(2) && '.' &&
                       mv_enddate+0(4) && | | && '23:59:59'.

    CONCATENATE
    '{'
    '"Key": "' ms_bankpass-namespace_url '",'
    '"BaslangicTarih": "' lv_startdate '",'
    '"BitisTarih": "' lv_enddate '",'
    '"MusteriNo": "' ms_bankpass-bankaccount '",'
    '"Iban": "' ms_bankpass-iban '"'
    '}'
    INTO rv_json.
  ENDMETHOD.