  METHOD fill_json.
*    TYPES : BEGIN OF ty_hesap,
*              hesapno TYPE string,
*            END OF ty_hesap,
*            BEGIN OF ty_netbankpacket,
*              packettype      TYPE string,
*              hesaplar        TYPE ty_hesap,
*              baslangictarihi TYPE string,
*              bitistarihi     TYPE string,
*            END OF ty_netbankpacket.
*    DATA ls_json TYPE ty_netbankpacket.
*    ls_json = VALUE #( packettype = 'HesapHareketleri'
*                       hesaplar-hesapno = ms_bankpass-iban
*                       baslangictarihi = mv_startdate
*                       bitistarihi = mv_enddate ).
*    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
    CONCATENATE
      '{'
      '"GeneralAccountStatements": {'
        '"requestXML": {'
          '"NETBANKPACKET": {'
            '"PACKETTYPE": "HesapHareketleri",'
            '"USERNAME": "' ms_bankpass-service_user '",'
            '"PASSWORD": "' ms_bankpass-service_password '",'
            '"HESAPLAR": {'
              '"HESAPNO": "' ms_bankpass-iban '"'
            '},'
            '"BASLANGICTARIHI":' mv_startdate ','
            '"BITISTARIHI": ' mv_enddate ','
            '"PAGENUMBER": 1,'
            '"SERIALNUMBER": 0'
          '}'
        '}'
        '}'
      '}' INTO rv_json.
  ENDMETHOD.