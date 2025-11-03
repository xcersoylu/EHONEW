  METHOD get_tax_ratio.
    DATA(lv_datum) = ycl_eho_utils=>get_local_time( )-date.
    SELECT SINGLE taxcode , conditionrateratio AS ratio , accountkeyforglaccount AS taxitemclassification , vatconditiontype AS conditiontype
        FROM i_taxcoderate AS taxratio INNER JOIN i_companycode AS t001 ON t001~country = taxratio~country
        WHERE t001~companycode = @iv_companycode
          AND taxratio~taxcode = @iv_taxcode
          AND taxratio~cndnrecordvalidityenddate >= @lv_datum
          AND taxratio~cndnrecordvaliditystartdate >= @lv_datum
    INTO CORRESPONDING FIELDS OF @rs_taxinfo.
  ENDMETHOD.