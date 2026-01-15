  METHOD get_exchange_rate.
    SELECT exchangerate
      FROM i_exchangeraterawdata
      WHERE exchangeratetype  = @iv_exchangeratetype
        AND sourcecurrency    = @iv_sourcecurrency
        AND targetcurrency    = @iv_targetcurrency
        AND validitystartdate <= @iv_exchangeratedate
      ORDER BY validitystartdate DESCENDING
      INTO @rv_exchangerate
      UP TO 1 ROWS.
    ENDSELECT.
    IF sy-subrc <> 0 OR rv_exchangerate < 0.
      SELECT exchangerate
        FROM i_exchangeraterawdata
        WHERE exchangeratetype  = @iv_exchangeratetype
          AND sourcecurrency    = @iv_targetcurrency
          AND targetcurrency    = @iv_sourcecurrency
          AND validitystartdate <= @iv_exchangeratedate
        ORDER BY validitystartdate DESCENDING
        INTO @rv_exchangerate
        UP TO 1 ROWS.
      ENDSELECT.
    ENDIF.
  ENDMETHOD.