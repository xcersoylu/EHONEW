  METHOD get_tax_ratio.
    SELECT SINGLE conditionrateratio
        FROM i_taxcoderate AS taxratio INNER JOIN i_companycode AS t001 ON t001~country = taxratio~country
        WHERE t001~companycode = @iv_companycode
          AND taxratio~taxcode = @iv_taxcode
          AND taxratio~cndnrecordvalidityenddate = '99991231'
    INTO @DATA(lv_tax_ratio).
    rv_ratio = CONV #( lv_tax_ratio ).
  ENDMETHOD.