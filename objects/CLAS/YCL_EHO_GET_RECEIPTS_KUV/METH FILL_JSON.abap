  METHOD fill_json.
    TYPES : BEGIN OF ty_request,
              _ext_u_name     TYPE string,
              _ext_u_password TYPE string,
              _account_number TYPE string,
              _account_suffix TYPE string,
              _begin_date     TYPE string,
              _end_date       TYPE string,
            END OF ty_request,
            BEGIN OF ty_getaccountstatement,
              request TYPE ty_request,
            END OF ty_getaccountstatement,
            BEGIN OF ty_json,
              _get_account_statement TYPE ty_getaccountstatement,
            END OF ty_json.

    DATA ls_json TYPE ty_json.
    DATA(lv_startdate) = mv_startdate+0(4) && '-' &&
                         mv_startdate+4(2) && '-' &&
                         mv_startdate+6(2).

    DATA(lv_enddate) = mv_enddate+0(4) && '-' &&
                       mv_enddate+4(2) && '-' &&
                       mv_enddate+6(2).
    ls_json-_get_account_statement-request = VALUE #( _ext_u_name = ms_bankpass-service_user
                                                      _ext_u_password = ms_bankpass-service_password
                                                      _account_number = ms_bankpass-bankaccount
                                                      _account_suffix = ms_bankpass-suffix
                                                      _begin_date = lv_startdate
                                                      _end_date = lv_enddate ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.