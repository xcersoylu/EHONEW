  METHOD change_debit_credit.
*tüm bankalarda borç alacak göstergesi ters çalıştğı için değiştirilmesi istendi. Ayrıca Alacak yaptığımız satırların eksi tutar olması istendi
    LOOP AT ct_bank_data ASSIGNING FIELD-SYMBOL(<ls_bank_data>).
      IF <ls_bank_data>-debit_credit = 'B'.
        <ls_bank_data>-debit_credit = 'A'.
        <ls_bank_data>-amount = abs( <ls_bank_data>-amount ) * -1.
      ELSEIF <ls_bank_data>-debit_credit = 'A'.
        <ls_bank_data>-debit_credit = 'B'.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.