  METHOD fill_json.
    TYPES : BEGIN OF ty_getextrewithparams,
              association_code TYPE string,
              user_code        TYPE string,
              password         TYPE string,
              start_date       TYPE string,
              end_date         TYPE string,
            END OF ty_getextrewithparams,
            BEGIN OF ty_json,
              _get_extre_with_params TYPE ty_getextrewithparams,
            END OF ty_json.
    DATA : lv_startdate TYPE string,
           lv_enddate   TYPE string,
           ls_json      TYPE ty_json.
    CONCATENATE mv_startdate(4) '-' mv_startdate+4(2) '-' mv_startdate+6(2) 'T00:00:00'  INTO lv_startdate.
    CONCATENATE mv_enddate(4) '-' mv_enddate+4(2) '-' mv_enddate+6(2) 'T23:59:00' INTO lv_enddate.
    ls_json-_get_extre_with_params = VALUE #( association_code = ms_bankpass-service_user
                                             user_code = ms_bankpass-service_user
                                             password = ms_bankpass-service_password
                                             start_date = lv_startdate
                                             end_date = lv_enddate ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
  ENDMETHOD.