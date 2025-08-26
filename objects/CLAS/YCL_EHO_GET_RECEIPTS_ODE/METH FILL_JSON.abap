  METHOD fill_json.
    TYPES : BEGIN OF ty_generalassociationcoderep,
              association TYPE string,
              usercode    TYPE string,
              password    TYPE string,
              startdate   TYPE string,
              enddate     TYPE string,
            END OF ty_generalassociationcoderep,
            BEGIN OF ty_json,
              generalassociationcoderep TYPE ty_generalassociationcoderep,
            END OF ty_json.
    DATA ls_json TYPE ty_json.
    DATA(lv_startdate) = mv_startdate+0(4) && '-' &&
                         mv_startdate+4(2) && '-' &&
                         mv_startdate+6(2).

    DATA(lv_enddate) = mv_enddate+0(4) && '-' &&
                       mv_enddate+4(2) && '-' &&
                       mv_enddate+6(2).

    CONCATENATE
    '{'
        '"GeneralAssociationCodeReportMainProcess": {'
           '"association": "' ms_bankpass-service_user '",'
            '"userCode": "' ms_bankpass-service_user '",'
            '"password": "' ms_bankpass-service_password '",'
            '"startDate": "' lv_startdate '",'
            '"endDate": "' lv_enddate ' "'
        '}'
    '}' INTO rv_json.

  ENDMETHOD.