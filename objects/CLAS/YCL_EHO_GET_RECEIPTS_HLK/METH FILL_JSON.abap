  METHOD fill_json.

    DATA(lv_startdate) = mv_startdate+0(4) && '-' &&
                         mv_startdate+4(2) && '-' &&
                         mv_startdate+6(2) .
    DATA(lv_enddate) = mv_startdate+0(4) && '-' &&
                         mv_startdate+4(2) && '-' &&
                         mv_startdate+6(2) .
    CASE ms_bankpass-additional_field1.
      WHEN 'BagliMusteriEkstreSorgulama'.
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
      WHEN 'EkstreSorgulama'.
        CONCATENATE
      '{'
      '"EkstreSorgulama": {'
          '"request": {'
            '"BaslangicTarihi": "' lv_startdate '",'
            '"BitisTarihi": "' lv_enddate '",'
            '"HesapNo": "' ms_bankpass-bankaccount '",'
            '"SubeKodu": "' ms_bankpass-branch_code '"'
          '}'
        '}'
      '}' INTO rv_json.
    ENDCASE.
  ENDMETHOD.