managed implementation in class zbp_eho_ddl_i_paymthexc unique;
strict ( 2 );

define behavior for yeho_ddl_I_paymthexc //alias <alias_name>
persistent table yeho_t_paymthexc
lock master
authorization master ( instance )
//etag master <field_name>
{
  create;
  update;
  delete;
  field ( readonly :update ) Country,Paymentmethod;
  mapping for yeho_t_paymthexc
  {
   Country = country;
   Paymentmethod = paymentmethod;
  }
}