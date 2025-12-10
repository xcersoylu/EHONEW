  METHOD get_request_id.
    ycl_eho_utils=>generate_random(
      EXPORTING
        iv_randomset = '0123456789'
        iv_length    = 19
      RECEIVING
        rv_string    = rv_request_id
    ).
  ENDMETHOD.