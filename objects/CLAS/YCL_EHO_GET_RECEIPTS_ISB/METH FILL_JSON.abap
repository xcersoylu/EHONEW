  METHOD fill_json.
    TYPES : BEGIN OF ty_json,
              uid         TYPE string,
              pwd         TYPE string,
              _begin_date TYPE string,
              _end_date   TYPE string,
            END OF ty_json.
    DATA ls_json TYPE ty_json.
    DATA lv_start_date TYPE string.
    DATA lv_end_date TYPE string.
    lv_start_date = |{ mv_startdate+6(2) }.{ mv_startdate+4(2) }.{ mv_startdate(4) } 00:00:01|.
    lv_end_date = |{ mv_enddate+6(2) }.{ mv_enddate+4(2) }.{ mv_enddate(4) } 23:59:59|.

    ls_json = VALUE #( uid = ms_bankpass-service_user
                      pwd = ms_bankpass-service_password
                      _begin_date = lv_start_date
                      _end_date = lv_end_date ).

    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.