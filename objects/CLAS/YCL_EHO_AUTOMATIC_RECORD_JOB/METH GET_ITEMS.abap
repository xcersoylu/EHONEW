  METHOD get_items.
*EHO dışından atılan kayıtlar için
    SELECT bseg~companycode,
           bseg~accountingdocument,
           bseg~fiscalyear,
           bseg~accountingdocumentitem,
           bkpf~postingdate,
           bseg~absoluteamountintransaccrcy,
           bseg~transactioncurrency,
           bseg~glaccount,
           bseg~debitcreditcode,
           bkpf~transactioncode,
           bkpf~accountingdoccreatedbyuser
       FROM yeho_t_amounttc AS amounttc INNER JOIN i_journalentry AS bkpf ON bkpf~companycode = amounttc~companycode
                                                                         AND bkpf~accountingdocumenttype = amounttc~document_type
                                                                         AND bkpf~transactioncode = amounttc~transaction_code
                                        INNER JOIN i_operationalacctgdocitem AS bseg ON bseg~companycode = bkpf~companycode
                                                                                    AND bseg~accountingdocument = bkpf~accountingdocument
                                                                                    AND bseg~fiscalyear = bkpf~fiscalyear
       WHERE bkpf~postingdate = @mv_date
         AND bkpf~isreversal = ''
         AND bkpf~isreversed = ''
         AND bkpf~companycode = @mv_companycode
         INTO TABLE @DATA(lt_manual_documents).

****şirket kendi hesabından kendine yollamışsa bir bankadan kayıt atıldığı zaman diğerinden atılmaması için
    SELECT bseg~companycode,
           bseg~accountingdocument,
           bseg~fiscalyear,
           bseg~accountingdocumentitem,
           bkpf~postingdate,
           bseg~absoluteamountintransaccrcy,
           bseg~transactioncurrency,
           bseg~glaccount,
           bseg~debitcreditcode,
           bkpf~transactioncode,
           bkpf~accountingdoccreatedbyuser,
           ' ' AS delete
       FROM yeho_t_savedrcpt AS savedrcpt INNER JOIN i_journalentry AS bkpf ON bkpf~companycode = savedrcpt~companycode
                                                                         AND bkpf~accountingdocument = savedrcpt~accountingdocument
                                                                         AND bkpf~fiscalyear = savedrcpt~fiscal_year
                                        INNER JOIN i_operationalacctgdocitem AS bseg ON bseg~companycode = bkpf~companycode
                                                                                    AND bseg~accountingdocument = bkpf~accountingdocument
                                                                                    AND bseg~fiscalyear = bkpf~fiscalyear
                                                                                    AND bseg~glaccount <> savedrcpt~glaccount
       WHERE bkpf~postingdate = @mv_date
         AND bkpf~isreversal = ''
         AND bkpf~isreversed = ''
         AND savedrcpt~internal_transfer = @abap_true
         AND bkpf~companycode = @mv_companycode
         INTO TABLE @DATA(lt_virman).

    SELECT *
      FROM yeho_t_offlinedt
     WHERE companycode = @mv_companycode
       AND glaccount IN @mt_glaccount_range
       AND physical_operation_date = @mv_date
       AND NOT EXISTS ( SELECT * FROM yeho_t_savedrcpt WHERE companycode = yeho_t_offlinedt~companycode
                                                         AND glaccount = yeho_t_offlinedt~glaccount
                                                         AND receipt_no = yeho_t_offlinedt~receipt_no
                                                         AND physical_operation_date = yeho_t_offlinedt~physical_operation_date )
       INTO CORRESPONDING FIELDS OF TABLE @mt_automatic_items.
    IF sy-subrc = 0.
      SELECT mandoc~*
        FROM @mt_automatic_items AS items INNER JOIN yeho_t_mandoc AS mandoc ON mandoc~companycode = items~companycode
                                                                          AND mandoc~glaccount = items~glaccount
                                                                          AND mandoc~receipt_no = items~receipt_no
                                                                          AND mandoc~physical_operation_date = items~physical_operation_date
       ORDER BY mandoc~companycode,mandoc~glaccount,mandoc~receipt_no,mandoc~physical_operation_date
       INTO TABLE @DATA(lt_mandoc_db).

      LOOP AT mt_automatic_items ASSIGNING FIELD-SYMBOL(<ls_item>).
        READ TABLE lt_manual_documents INTO DATA(ls_manual_document)
                                       WITH KEY glaccount = <ls_item>-glaccount
                                                postingdate = <ls_item>-physical_operation_date
                                                debitcreditcode = COND #( WHEN <ls_item>-debit_credit = 'B' THEN 'S' ELSE 'H' )
                                                absoluteamountintransaccrcy = abs( <ls_item>-amount ). "#TODO binary search
        IF sy-subrc = 0.
          <ls_item>-manualrecord = abap_true.
        ELSE.
          READ TABLE lt_mandoc_db INTO DATA(ls_mandoc_db) WITH KEY companycode = <ls_item>-companycode
                                                                   glaccount = <ls_item>-glaccount
                                                                   receipt_no = <ls_item>-receipt_no
                                                                   physical_operation_date = <ls_item>-physical_operation_date BINARY SEARCH.
          IF sy-subrc = 0.
            <ls_item>-manualrecord = abap_true.
          ENDIF.
        ENDIF.
*virman olabilir mi ?
        IF <ls_item>-manualrecord IS INITIAL.
          READ TABLE lt_virman ASSIGNING FIELD-SYMBOL(<ls_virman>)
                                         WITH KEY glaccount = <ls_item>-glaccount
                                                  postingdate = <ls_item>-physical_operation_date
                                                  absoluteamountintransaccrcy = abs( <ls_item>-amount ).
          IF sy-subrc = 0.
            <ls_virman>-delete = abap_true.
            <ls_item>-manualrecord = abap_true.
          ENDIF.
          DELETE lt_virman WHERE delete = abap_true.
        ENDIF.
      ENDLOOP.
      DELETE mt_automatic_items WHERE manualrecord = abap_true.
    ENDIF.
  ENDMETHOD.