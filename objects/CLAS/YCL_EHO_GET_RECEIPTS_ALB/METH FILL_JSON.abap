  METHOD fill_json.
    TYPES : BEGIN OF ty_pparams,
              musteri_no TYPE string,
              hesap_no   TYPE string,
              bas_tarih  TYPE string,
              son_tarih  TYPE string,
            END OF ty_pparams,
            BEGIN OF ty_gethesaphareketleri,
              p_id      TYPE string,
              p_id_pass TYPE string,
              p_params  TYPE ty_pparams,
            END OF ty_gethesaphareketleri,
            BEGIN OF ty_json,
              get_hesap_hareketleri TYPE ty_gethesaphareketleri,
            END OF ty_json.
    DATA ls_json TYPE ty_json.

    DATA(lv_startdate) = mv_startdate+0(4) &&
                         mv_startdate+4(2) &&
                         mv_startdate+6(2).

    DATA(lv_enddate) = mv_enddate+0(4) &&
                       mv_enddate+4(2) &&
                       mv_enddate+6(2).
    ls_json-get_hesap_hareketleri = VALUE #(  p_id = ms_bankpass-service_user
                                              p_id_pass = ms_bankpass-service_password
                                              p_params = VALUE #( musteri_no = ms_bankpass-firm_code
                                                                  hesap_no = ms_bankpass-suffix
                                                                  bas_tarih = lv_startdate
                                                                  son_tarih = lv_enddate ) ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.