CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES : BEGIN OF ty_keys,
              companycode            TYPE bukrs,
              glaccount              TYPE saknr,
              phsical_operation_date TYPE datum,
            END OF ty_keys.
    CLASS-DATA mt_keys TYPE TABLE OF ty_keys WITH DEFAULT KEY.
    CLASS-DATA mt_companycode TYPE RANGE OF bukrs.
    CLASS-DATA mt_glaccount TYPE RANGE OF saknr.
    CLASS-DATA mt_date TYPE RANGE OF datum.
ENDCLASS.
CLASS lhc_yeho_ddl_i_delete_receipt DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR yeho_ddl_i_delete_receipt RESULT result.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE yeho_ddl_i_delete_receipt.

    METHODS read FOR READ
      IMPORTING keys FOR READ yeho_ddl_i_delete_receipt RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK yeho_ddl_i_delete_receipt.

    METHODS rba_items FOR READ
      IMPORTING keys_rba FOR READ yeho_ddl_i_delete_receipt\_items FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_yeho_ddl_i_delete_receipt IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD delete.
    SELECT * FROM yeho_t_savedrcpt
      FOR ALL ENTRIES IN @keys
      WHERE companycode              = @keys-companycode
        AND glaccount                = @keys-glaccount
        AND physical_operation_date  = @keys-physical_operation_date
        INTO TABLE @DATA(lt_savedreceipt).
    IF sy-subrc = 0.
      LOOP AT keys INTO DATA(ls_key).
        failed-yeho_ddl_i_delete_receipt = VALUE #( ( %key = CORRESPONDING #( ls_key  ) ) ).
      ENDLOOP.
        reported-yeho_ddl_i_delete_receipt = VALUE #( ( %msg = new_message( id  = 'YEHO_MC'
                                                                            number   = '019'
                                                                            severity = if_abap_behv_message=>severity-error ) ) ).
    ELSE.
      lcl_buffer=>mt_companycode = VALUE #( FOR wa IN keys (  sign = 'I' option = 'EQ' low = wa-companycode ) ) .
      lcl_buffer=>mt_glaccount = VALUE #( FOR wa IN keys (  sign = 'I' option = 'EQ' low = wa-glaccount ) ) .
      lcl_buffer=>mt_date = VALUE #( FOR wa IN keys (  sign = 'I' option = 'EQ' low = wa-physical_operation_date ) ) .
    ENDIF.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_items.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_yeho_ddl_i_delete_receipt_ DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS read FOR READ
      IMPORTING keys FOR READ yeho_ddl_i_delete_receipt_item RESULT result.

    METHODS rba_header FOR READ
      IMPORTING keys_rba FOR READ yeho_ddl_i_delete_receipt_item\_header FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_yeho_ddl_i_delete_receipt_ IMPLEMENTATION.

  METHOD read.
  ENDMETHOD.

  METHOD rba_header.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_yeho_ddl_i_delete_receipt DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_yeho_ddl_i_delete_receipt IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    DELETE FROM yeho_t_offlinebd WHERE companycode IN @lcl_buffer=>mt_companycode
                                   AND glaccount IN @lcl_buffer=>mt_glaccount
                                   AND valid_from IN @lcl_buffer=>mt_date.
    DELETE FROM yeho_t_offlinedt WHERE companycode IN @lcl_buffer=>mt_companycode
                                   AND glaccount IN @lcl_buffer=>mt_glaccount
                                   AND physical_operation_date IN @lcl_buffer=>mt_date.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.