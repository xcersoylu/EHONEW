  METHOD if_http_service_extension~handle_request.
    DATA lv_date TYPE datum.
    DATA(lv_request_body) = request->get_text( ).
    DATA(lv_get_method) = request->get_method( ).

    /ui2/cl_json=>deserialize( EXPORTING json = lv_request_body CHANGING data = ms_request ).
    SELECT exchangerate
      FROM i_exchangeraterawdata
      WHERE exchangeratetype  = @ms_request-exchangeratetype
        AND sourcecurrency    = @ms_request-sourcecurrency
        AND targetcurrency    = @ms_request-targetcurrency
        AND validitystartdate <= @ms_request-exchangeratedate
      ORDER BY validitystartdate DESCENDING
      INTO @ms_response-exchangerate
      UP TO 1 ROWS.
    ENDSELECT.
    IF sy-subrc <> 0 OR ms_response-exchangerate < 0.
      SELECT exchangerate
        FROM i_exchangeraterawdata
        WHERE exchangeratetype  = @ms_request-exchangeratetype
          AND sourcecurrency    = @ms_request-targetcurrency
          AND targetcurrency    = @ms_request-sourcecurrency
          AND validitystartdate <= @ms_request-exchangeratedate
        ORDER BY validitystartdate DESCENDING
        INTO @ms_response-exchangerate
        UP TO 1 ROWS.
      ENDSELECT.
    ENDIF.
    DATA(lv_response_body) = /ui2/cl_json=>serialize( EXPORTING data = ms_response ).
    response->set_text( lv_response_body ).
    response->set_header_field( i_name = mc_header_content i_value = mc_content_type ).
  ENDMETHOD.