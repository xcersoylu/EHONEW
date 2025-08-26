projection;
strict ( 2 );

define behavior for YEHO_DDL_C_DELETE_RECEIPT //alias <alias_name>
{
  use delete;

  use association _items;
}

define behavior for YEHO_DDL_C_DELETE_RECEIPT_ITEM //alias <alias_name>
{

  use association _header;
}