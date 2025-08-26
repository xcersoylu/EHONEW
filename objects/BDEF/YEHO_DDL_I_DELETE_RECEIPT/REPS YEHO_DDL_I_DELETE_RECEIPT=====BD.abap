unmanaged implementation in class zbp_eho_ddl_i_delete_receipt unique;
strict ( 2 );

define behavior for YEHO_DDL_I_DELETE_RECEIPT //alias <alias_name>
//late numbering
lock master
authorization master ( instance )
//etag master <field_name>
{
//  create;
//  update;
  delete;
  field ( readonly ) companycode, glaccount, physical_operation_date;
  association _items { }
}

define behavior for YEHO_DDL_I_DELETE_RECEIPT_ITEM //alias <alias_name>
//late numbering
lock dependent by _header
authorization dependent by _header
//etag master <field_name>
{
//  update;
//  delete;
  field ( readonly ) Companycode, Glaccount, ReceiptNo, PhysicalOperationDate, Accountingdocument, FiscalYear;
  association _header;
}