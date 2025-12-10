  METHOD fill_json.
    DATA :
      lv_account_suffix TYPE string,
      lv_association_code type string,
      lv_crid           TYPE c LENGTH 19,
      lv_csid           TYPE c LENGTH 32.

    DATA(lv_begindate) = mv_startdate+0(4) && '-' &&
                         mv_startdate+4(2) && '-' &&
                         mv_startdate+6(2) && 'T00:00:00.000+03:00'.

    DATA(lv_enddate) = mv_enddate+0(4) && '-' &&
                       mv_enddate+4(2) && '-' &&
                       mv_enddate+6(2) && 'T23:59:59.000+03:00'.
    lv_csid = get_session_id(  ).
    lv_crid = get_request_id(  ).
    TRANSLATE lv_csid TO LOWER CASE.
    TRANSLATE lv_crid TO LOWER CASE.

    IF ms_bankpass-additional_field3 IS NOT INITIAL.
      CONCATENATE
      '"AssociationCode": "' ms_bankpass-additional_field3  '",'
      INTO lv_association_code.
    else.
      lv_association_code = '"AssociationCode": " ",'.
    ENDIF.

    CONCATENATE
    '{'
    '"Header":{'
    '"AppKey": "' ms_bankpass-additional_field1 '",'
    '"Channel": "' ms_bankpass-additional_field2 '",'
    '"ChannelSessionId": "' lv_csid '",'
    '"ChannelRequestId": "' lv_crid '"'
    '},'
    '"Parameters":['
    '{'
    '"CustomerNo":"' ms_bankpass-firm_code '",'
    '"AccountBranchCode": "' ms_bankpass-branch_code '",'
    '"AccountSuffix": "' ms_bankpass-suffix '",'
    lv_association_code
    '"IBANNo": " ",'
    '"QueryDate": "' lv_begindate '",'
    '"EndDate": "' lv_enddate '",'
    '"RecordStatus": "A"'
    '}'
    ']'
    '}'
    INTO rv_json.
  ENDMETHOD.