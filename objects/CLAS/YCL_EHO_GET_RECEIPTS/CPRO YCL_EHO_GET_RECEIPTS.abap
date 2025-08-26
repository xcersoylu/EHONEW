  PROTECTED SECTION.
    CONSTANTS mc_error TYPE msgty VALUE 'E'.
    DATA ms_bankpass TYPE yeho_t_bankpass.
    DATA mv_startdate TYPE datum.
    DATA mv_enddate TYPE datum.
    DATA mt_bank_data TYPE yeho_tt_offline_bank_data.
    METHODS fill_json ABSTRACT RETURNING VALUE(rv_json) TYPE string.
    METHODS mapping_bank_data ABSTRACT IMPORTING iv_json TYPE string EXPORTING et_bank_data TYPE yeho_tt_offline_bank_data
                                                                               et_bank_balance TYPE yeho_tt_offlinebd
                                                                               et_error_messages TYPE yeho_tt_message.
    METHODS check_duplicate_receipt CHANGING ct_bank_data      TYPE yeho_tt_offline_bank_data.