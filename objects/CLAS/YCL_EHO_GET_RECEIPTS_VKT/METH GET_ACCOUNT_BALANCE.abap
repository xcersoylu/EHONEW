  METHOD get_account_balance.
******response
    TYPES: BEGIN OF ty_value,
             results           TYPE string,
             success           TYPE string,
             accountalias      TYPE string,
             accountnumber     TYPE string,
             accountsuffix     TYPE string,
             accounttype       TYPE string,
             balance           TYPE string,
             branchname        TYPE string,
             customername      TYPE string,
             fecname           TYPE string,
             iban              TYPE string,
             isactive          TYPE string,
             opendate          TYPE string,
             withholdingamount TYPE string,
           END OF ty_value.

    TYPES: BEGIN OF ty_balance_result,
             results      TYPE string,
             success      TYPE string,
             errorcode    TYPE string,  " @nil olabilir, string olarak tutulur
             errormessage TYPE string,  " @nil olabilir, string olarak tutulur
             value        TYPE ty_value,
           END OF ty_balance_result.

    TYPES: BEGIN OF ty_balance_response,
             getaccountbalanceresult TYPE ty_balance_result,
           END OF ty_balance_response.
    TYPES: BEGIN OF ty_root,
             getaccountbalanceresponse TYPE ty_balance_response,
           END OF ty_root.
******response

****request
    TYPES  : BEGIN OF ty_request,
               _encrypted_value            TYPE string,
               _ext_u_name                 TYPE string,
               _ext_u_password             TYPE string,
               _ext_u_sessionkey           TYPE string,
               _is_new_defined_transaction TYPE string,
               _language_id                TYPE string,
               _method_name                TYPE string,
               _account_number             TYPE string,
               _account_suffix             TYPE string,
               _balance_date               TYPE string,
             END OF ty_request,
             BEGIN OF ty_getaccountbalance,
               request TYPE ty_request,
             END OF ty_getaccountbalance,
             BEGIN OF ty_json,
               _get_account_balance TYPE ty_getaccountbalance,
             END OF ty_json.
*******request
    DATA ls_json TYPE ty_json.
    DATA lv_json TYPE string.
    DATA lv_balance_date TYPE string.
    DATA lv_startdate TYPE datum.
    DATA ls_response_json TYPE ty_root.
    lv_startdate = mv_startdate - 1.
    CONCATENATE lv_startdate+0(4) '-'
                lv_startdate+4(2) '-'
                lv_startdate+6(2)
                INTO lv_balance_date.
    ls_json-_get_account_balance-request = VALUE #( _ext_u_name                 = ms_bankpass-service_user
                                                 _ext_u_password             = ms_bankpass-service_password
                                                 _is_new_defined_transaction = 'false'
                                                 _language_id                = '1'
                                                 _account_number             = ms_bankpass-bankaccount
                                                 _account_suffix             = ms_bankpass-suffix
                                                 _balance_date               = lv_balance_date ).
    lv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
    TRY.
        DATA(lo_http_destination) = cl_http_destination_provider=>create_by_url( CONV #( ms_bankpass-additional_field1 ) ).
        DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ) .
        DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).
        lo_web_http_request->set_authorization_basic(
          EXPORTING
            i_username = CONV #( ms_bankpass-cpi_user )
            i_password = CONV #( ms_bankpass-cpi_password )
        ).

        lo_web_http_request->set_header_fields( VALUE #( (  name = 'Accept' value = 'application/json' )
                                                         (  name = 'Content-Type' value = 'application/json' ) ) ).
        lo_web_http_request->set_text(
          EXPORTING
            i_text   = lv_json
        ).

        DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>post ).
        DATA(lv_response) = lo_web_http_response->get_text( ).

        /ui2/cl_json=>deserialize( EXPORTING json = lv_response CHANGING data = ls_response_json ).
        rv_balance = ls_response_json-getaccountbalanceresponse-getaccountbalanceresult-value-balance +
                     ls_response_json-getaccountbalanceresponse-getaccountbalanceresult-value-withholdingamount.
      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
    ENDTRY.
  ENDMETHOD.