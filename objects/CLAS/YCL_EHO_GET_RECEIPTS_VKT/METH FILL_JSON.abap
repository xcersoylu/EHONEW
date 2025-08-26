  METHOD fill_json.
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
               _begin_date                 TYPE string,
               _debit_credit_code          TYPE string,
               _end_date                   TYPE TABLE OF string WITH EMPTY KEY,
               _has_time_filter            TYPE string,
*               iban                       TYPE string,
*               slip_business_key          TYPE string,
*               tax_number                 TYPE string,
*               transaction_type           TYPE string,
             END OF ty_request,
             BEGIN OF ty_getcustomertransactions,
               request TYPE ty_request,
             END OF ty_getcustomertransactions,
             BEGIN OF ty_json,
               getcustomertransactiondetails TYPE ty_getcustomertransactions,
             END OF ty_json.
    DATA ls_json TYPE ty_json.
    DATA lv_start_date TYPE string.
    DATA lv_end_date TYPE string.
    DATA lt_end_date TYPE TABLE OF string.
    CONCATENATE mv_startdate+0(4) '-'
                mv_startdate+4(2) '-'
                mv_startdate+6(2)
                INTO lv_start_date.
    CONCATENATE mv_enddate+0(4) '-'
                mv_enddate+4(2) '-'
                mv_enddate+6(2)
                INTO lv_end_date.
    APPEND lv_end_date TO lt_end_date.
    APPEND lv_end_date TO lt_end_date.
    ls_json-getcustomertransactiondetails-request = VALUE #( _ext_u_name                 = ms_bankpass-service_user
                                                         _ext_u_password             = ms_bankpass-service_password
                                                         _is_new_defined_transaction = 'false'
                                                         _language_id                = '1'
                                                         _account_number             = ms_bankpass-bankaccount
                                                         _account_suffix             = ms_bankpass-suffix
                                                         _begin_date                 = lv_start_date
                                                         _debit_credit_code          = 'All'
                                                         _end_date                   = lt_end_date
                                                         _has_time_filter            = '0' ).
    rv_json = /ui2/cl_json=>serialize( EXPORTING data = ls_json pretty_name = 'X' ).
    REPLACE 'getcustomertransactiondetails' IN rv_json WITH 'GetCustomerTransactionDetails'.
  ENDMETHOD.