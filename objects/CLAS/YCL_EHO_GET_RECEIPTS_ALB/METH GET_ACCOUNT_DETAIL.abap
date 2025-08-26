  METHOD get_account_detail.
    TYPES : tt_hesap TYPE TABLE OF ty_hesap WITH DEFAULT KEY,
            BEGIN OF ty_hesaplar,
              hesaplar TYPE tt_hesap,
            END OF ty_hesaplar,
            BEGIN OF ty_hesapdetaylari,
              hesapdetaylari TYPE ty_hesaplar,
            END OF ty_hesapdetaylari,
            BEGIN OF ty_response,
              responsedata TYPE ty_hesapdetaylari,
            END OF ty_response,
            BEGIN OF ty_json,
              gethesapdetaylariresponse TYPE ty_response,
            END OF ty_json.
    DATA lv_json TYPE string.
    DATA ls_response_json TYPE ty_json.
    CONCATENATE
  '{'
      '"getHesapDetaylari": {'
          '"pId": "' ms_bankpass-service_user '",'
          '"pIdPass": "' ms_bankpass-service_password '",'
          '"pParams": {'
              '"musteriNo":' ms_bankpass-firm_code ','
          '}'
      '}'
  '}' INTO lv_json.

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
        READ TABLE ls_response_json-gethesapdetaylariresponse-responsedata-hesapdetaylari-hesaplar
        INTO rs_account_detail WITH KEY iban = ms_bankpass-iban.
      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
    ENDTRY.

  ENDMETHOD.