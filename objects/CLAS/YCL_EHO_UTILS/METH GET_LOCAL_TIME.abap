  METHOD GET_LOCAL_TIME.
    GET TIME STAMP FIELD DATA(lv_ts).
    TRY.
        DATA(lv_tz) = cl_abap_context_info=>get_user_time_zone(  ) .
        CONVERT TIME STAMP lv_ts TIME ZONE lv_tz INTO DATE local_time_info-date TIME local_time_info-time.
        CONVERT DATE local_time_info-date TIME local_time_info-time INTO TIME STAMP local_time_info-timestamp TIME ZONE 'UTC'.
      CATCH cx_abap_context_info_error.
    ENDTRY.
  ENDMETHOD.