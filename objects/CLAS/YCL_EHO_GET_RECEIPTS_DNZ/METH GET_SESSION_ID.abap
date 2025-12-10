  METHOD get_session_id.
    ycl_eho_utils=>generate_random(
      EXPORTING
        iv_randomset = '0123456789ABCDEF'
        iv_length    = 32
      RECEIVING
        rv_string    = rv_session_id
    ).
  ENDMETHOD.