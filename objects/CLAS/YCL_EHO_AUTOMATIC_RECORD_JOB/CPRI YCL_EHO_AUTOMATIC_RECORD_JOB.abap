  PRIVATE SECTION.
    DATA mt_automatic_items TYPE yeho_tt_bank_automatic_items.
    DATA mv_companycode TYPE bukrs.
    DATA mt_glaccount_range TYPE RANGE OF hkont.
    DATA mv_date TYPE d.
    DATA mo_log TYPE REF TO if_bali_log.
    METHODS get_items.
    METHODS get_rule CHANGING ct_items TYPE yeho_tt_bank_automatic_items.
    METHODS get_rule_data
      IMPORTING
        iv_rule_no       TYPE posnr
      RETURNING
        VALUE(rs_result) TYPE yeho_s_rule_data.
    METHODS create_journal_entry.
    METHODS get_tax_ratio IMPORTING iv_taxcode      TYPE mwskz
                                    iv_companycode  TYPE bukrs
                          RETURNING VALUE(rv_ratio) TYPE yeho_e_tax_ratio.