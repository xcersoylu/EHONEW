  METHOD fill_json.
    TYPES : BEGIN OF ty_sorgu,
              _musteri_no             TYPE string,
              _kurum_kullanici        TYPE string,
              _sifre                  TYPE string,
              _sorgu_baslangic_tarihi TYPE string,
              _sorgu_bitis_tarihi     TYPE string,
              _hesap_no               TYPE string,
*              _hareket_tipi           TYPE string,
*              _en_dusuk_tutar         TYPE string,
*              _en_yuksek_tutar        TYPE string,
            END OF ty_sorgu,
            BEGIN OF ty_getir_hareket,
              sorgu TYPE ty_sorgu,
            END OF ty_getir_hareket,
            BEGIN OF ty_json,
              _getir_hareket TYPE ty_getir_hareket,
            END OF ty_json.
    DATA ls_json TYPE ty_json.
    DATA lv_start_date TYPE string.
    DATA lv_end_date TYPE string.
    CONCATENATE mv_startdate+0(4) '-'
                mv_startdate+4(2) '-'
                mv_startdate+6(2)
                INTO lv_start_date.
    CONCATENATE mv_enddate+0(4) '-'
                mv_enddate+4(2) '-'
                mv_enddate+6(2)
                INTO lv_end_date.

    CONCATENATE lv_start_date '00:00' INTO lv_start_date SEPARATED BY space.
    CONCATENATE lv_end_date   '23:59' INTO lv_end_date SEPARATED BY space.

    ls_json-_getir_hareket-sorgu = VALUE #( _musteri_no               = ms_bankpass-firm_code
                                            _kurum_kullanici          = ms_bankpass-service_user
                                            _sifre                    = ms_bankpass-service_password
                                            _sorgu_baslangic_tarihi   = lv_start_date
                                            _sorgu_bitis_tarihi       = lv_end_date
                                            _hesap_no                 = ms_bankpass-bankaccount ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.