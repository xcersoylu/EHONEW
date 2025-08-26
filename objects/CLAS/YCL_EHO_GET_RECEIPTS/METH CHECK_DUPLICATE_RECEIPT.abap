  METHOD check_duplicate_receipt.
    TYPES : BEGIN OF ty_counter,
              receipt_no TYPE yeho_e_receipt_no,
              counter    TYPE int4,
            END OF ty_counter.
    DATA ls_counter TYPE ty_counter.
    DATA lt_counter TYPE HASHED TABLE OF ty_counter WITH UNIQUE KEY receipt_no.
    LOOP AT ct_bank_data ASSIGNING FIELD-SYMBOL(<ls_bank_data>).
      READ TABLE lt_counter ASSIGNING FIELD-SYMBOL(<ls_counter>)
           WITH TABLE KEY receipt_no = <ls_bank_data>-receipt_no.
      IF sy-subrc = 0.
        <ls_counter>-counter = <ls_counter>-counter + 1.
        <ls_bank_data>-receipt_no = |{ <ls_bank_data>-receipt_no }-{ <ls_counter>-counter }|.
      ELSE.
        ls_counter-receipt_no = <ls_bank_data>-receipt_no.
        ls_counter-counter    = 1.
        INSERT ls_counter INTO TABLE lt_counter.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.