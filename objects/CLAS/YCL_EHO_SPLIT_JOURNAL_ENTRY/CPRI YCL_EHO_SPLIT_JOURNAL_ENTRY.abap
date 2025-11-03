  PRIVATE SECTION.
    TYPES : BEGIN OF ty_taxcodeinfo,
              taxcode               TYPE mwskz,
              ratio                 TYPE yeho_e_tax_ratio,
              conditiontype         TYPE kschl,
              taxitemclassification TYPE ktosl,
            END OF ty_taxcodeinfo.
    DATA: ms_request  TYPE yeho_s_split_journal_req,
          ms_response TYPE yeho_s_split_journal_res.
    CONSTANTS: mc_header_content TYPE string VALUE 'content-type',
               mc_content_type   TYPE string VALUE 'text/json',
               mc_error          TYPE messagetyp VALUE 'E'.
    METHODS get_tax_ratio IMPORTING iv_taxcode        TYPE mwskz
                                    iv_companycode    TYPE bukrs
                          RETURNING VALUE(rs_taxinfo) TYPE ty_taxcodeinfo.