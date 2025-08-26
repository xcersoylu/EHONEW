  METHOD fill_json.
    TYPES : BEGIN OF ty_json,
              _kullanici_kod    TYPE string,
              _sifre            TYPE string,
              _hesap_no         TYPE string,
              _baslangic_tarihi TYPE string,
              _bitis_tarihi     TYPE string,
              _ref_no           TYPE string,
            END OF ty_json.
    DATA ls_json TYPE ty_json.

    DATA(lv_startdate) = mv_startdate+6(2) && '.' &&
                         mv_startdate+4(2) && '.' &&
                         mv_startdate+0(4).

    DATA(lv_enddate)   = mv_enddate+6(2) && '.' &&
                         mv_enddate+4(2) && '.' &&
                         mv_enddate+0(4).

    ls_json = VALUE #( _kullanici_kod = ms_bankpass-service_user
                       _sifre = ms_bankpass-service_password
                       _hesap_no = ms_bankpass-bankaccount
                       _baslangic_tarihi = lv_startdate
                       _bitis_tarihi = lv_enddate ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.