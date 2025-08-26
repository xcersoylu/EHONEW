  METHOD fill_json.

    DATA(lv_startdate) = mv_startdate+0(4) && '-' &&
                         mv_startdate+4(2) && '-' &&
                         mv_startdate+6(2) .
    DATA(lv_enddate) = mv_startdate+0(4) && '-' &&
                         mv_startdate+4(2) && '-' &&
                         mv_startdate+6(2) .

    CONCATENATE
  '{'
  '"BagliMusteriEkstreSorgulama": {'
      '"request": {'
        '"BagliMusteriNumarasi": "' ms_bankpass-firm_code '",'
        '"BaslangicTarihi": "' lv_startdate '",'
        '"BitisTarihi": "' lv_enddate '"'
      '}'
    '}'
  '}' INTO rv_json.

  ENDMETHOD.