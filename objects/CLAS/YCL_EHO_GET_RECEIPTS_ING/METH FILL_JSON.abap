  METHOD fill_json.
    TYPES : BEGIN OF ty_hesapno,
              _ekno   TYPE string,
              _hestur TYPE string,
              _ilk7   TYPE string,
              _sinif  TYPE string,
              _sube   TYPE string,
            END OF ty_hesapno,
            BEGIN OF ty_input,
              _baslangic_tarihi TYPE string,
              _bitis_tarihi     TYPE string,
              _hesap_no         TYPE ty_hesapno,
              _kullanici_kodu   TYPE string,
            END OF ty_input,
            BEGIN OF ty_getaccountactivities,
              input TYPE ty_input,
            END OF ty_getaccountactivities,
            BEGIN OF ty_json,
              get_account_activities TYPE ty_getaccountactivities,
            END OF ty_json.

    DATA ls_json TYPE ty_json.
    DATA lv_start_date TYPE string.
    DATA lv_end_date TYPE string.
    CONCATENATE mv_startdate+0(4) '-'
                mv_startdate+4(2) '-'
                mv_startdate+6(2)
                'T'
                '00:00:00'
                INTO lv_start_date.
    CONCATENATE mv_enddate+0(4) '-'
                mv_enddate+4(2) '-'
                mv_enddate+6(2)
                'T'
                '23:59:59'
                INTO lv_end_date.
    ls_json-get_account_activities-input = VALUE #( _baslangic_tarihi = lv_start_date
                                                    _bitis_tarihi = lv_end_date
                                                    _hesap_no = VALUE #( _ekno = ms_bankpass-suffix+2(1)
                                                                        _hestur = ms_bankpass-suffix(2)
                                                                        _ilk7 = ms_bankpass-firm_code
                                                                        _sinif = ms_bankpass-additional_field1
                                                                        _sube = ms_bankpass-branch_code )
                                                    _kullanici_kodu = ms_bankpass-firm_code ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
    REPLACE 'getAccountActivities' IN rv_json WITH 'GetAccountActivitiesWithToken'.
  ENDMETHOD.