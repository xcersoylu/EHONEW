  METHOD get_bank_name.
    DATA(lv_bank_code) = |{ iv_bank_code ALPHA = IN }|.
    SELECT SINGLE bank_name FROM yeho_t_bankcode WHERE bank_code = @lv_bank_code INTO @rv_bank_name.
  ENDMETHOD.