  PRIVATE SECTION.
    METHODS get_rule_data IMPORTING it_items TYPE yeho_tt_create_journal_items RETURNING VALUE(rt_rule_data) TYPE yeho_tt_rule_data.
    METHODS get_tax_ratio IMPORTING iv_taxcode      TYPE mwskz
                                    iv_companycode  TYPE bukrs
                          RETURNING VALUE(rv_ratio) TYPE yeho_e_tax_ratio.
    DATA: ms_request  TYPE yeho_s_create_journal_req,
          ms_response TYPE yeho_s_create_journal_res.
    CONSTANTS: mc_header_content TYPE string VALUE 'content-type',
               mc_content_type   TYPE string VALUE 'text/json',
               mc_error          TYPE messagetyp VALUE 'E'.