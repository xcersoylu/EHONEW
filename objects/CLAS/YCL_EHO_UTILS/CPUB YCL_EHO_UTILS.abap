CLASS ycl_eho_utils DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    class-data mv_eho_tcode type c LENGTH 20 VALUE 'YEHO'.
    CLASS-METHODS find_customer_from_tax_number
      IMPORTING iv_tax_number      TYPE i_customer-taxnumber1
      RETURNING VALUE(rv_customer) TYPE kunnr.
    CLASS-METHODS find_supplier_from_tax_number
      IMPORTING iv_tax_number      TYPE i_supplier-taxnumber1
      RETURNING VALUE(rv_supplier) TYPE lifnr.
    CLASS-METHODS find_bp_from_iban
      IMPORTING iv_iban                   TYPE i_businesspartnerbank-iban
      RETURNING VALUE(rv_businesspartner) TYPE i_businesspartnerbank-businesspartner.
    CLASS-METHODS get_bank_name
      IMPORTING iv_bank_code        TYPE yeho_e_bank_code
      RETURNING VALUE(rv_bank_name) TYPE banka.
    CLASS-METHODS get_branch_name
      IMPORTING iv_companycode        TYPE bukrs
                iv_bank_code          TYPE yeho_e_bank_code
                iv_branch_code        TYPE yeho_e_branch_code
      RETURNING VALUE(rv_branch_name) TYPE yeho_e_branchnamedescription.
    CONSTANTS mc_message_class TYPE symsgid VALUE 'YEHO_MC'.
    CONSTANTS mc_information TYPE symsgty VALUE 'I'.
    CONSTANTS mc_success TYPE symsgty VALUE 'S'.
    CONSTANTS mc_error TYPE symsgty VALUE 'E'.
    CONSTANTS mc_warning TYPE symsgty VALUE 'W'.

    TYPES: BEGIN OF mty_xml_node,
             node_type  TYPE string,
             prefix     TYPE string,
             name       TYPE string,
             nsuri      TYPE string,
             value_type TYPE string,
             value      TYPE string,
           END OF mty_xml_node,
           mty_xml_nodes TYPE TABLE OF mty_xml_node WITH EMPTY KEY,
           mty_hash      TYPE c LENGTH 32.
    TYPES : BEGIN OF ty_local_time_info,
              timestamp TYPE timestamp,
              date      TYPE d,
              time      TYPE t,
            END OF ty_local_time_info.
    CLASS-METHODS parse_xml
      IMPORTING
        iv_xml_string  TYPE string
        iv_xml_xstring TYPE xstring OPTIONAL
      RETURNING
        VALUE(rt_data) TYPE mty_xml_nodes.
    CLASS-METHODS get_node_type
      IMPORTING
        node_type_int           TYPE i
      RETURNING
        VALUE(node_type_string) TYPE string.
    CLASS-METHODS get_value_type
      IMPORTING
        value_type_int           TYPE i
      RETURNING
        VALUE(value_type_string) TYPE string.
    CLASS-METHODS get_local_time
      RETURNING VALUE(local_time_info) TYPE ty_local_time_info.