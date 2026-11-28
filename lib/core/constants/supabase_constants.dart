/// Canonical PostgreSQL table and view names used across Supabase repositories.
abstract final class SupabaseTables {
  static const String customers = 'customers';
  static const String customerDetailsView = 'customer_details_view';
  static const String accountIdentities = 'account_identities';
  static const String oneTimeDepositDetailsView =
      'one_time_deposit_details_view';
  static const String recurringDepositDetailsView =
      'recurring_deposit_details_view';
  static const String agentProfiles = 'agent_profiles';
  static const String rdTransactions = 'rd_transactions';
  static const String rdPoDeposits = 'rd_po_deposits';
  static const String rdFeeAbsorptions = 'rd_fee_absorptions';
  static const String rdLedgerSummary = 'rd_ledger_summary';
}

/// Canonical PostgreSQL RPC function names invoked by data repositories & services.
abstract final class SupabaseRpcs {
  static const String saveCustomerWithSbAccount =
      'save_customer_with_sb_account';
  static const String deleteCustomer = 'delete_customer';
  static const String saveOneTimeDeposit = 'save_one_time_deposit';
  static const String saveRecurringDeposit = 'save_recurring_deposit';
  static const String setDepositStatus = 'set_deposit_status';
  static const String applyRdLedgerChange = 'apply_rd_ledger_change';
  static const String undoRdPoDepositBatch = 'undo_rd_po_deposit_batch';
  static const String isAdmin = 'is_admin';
  static const String listAgentsForAdmin = 'list_agents_for_admin';
  static const String logAdminActingAsEvent = 'log_admin_acting_as_event';
  static const String logClientError = 'log_client_error';
}
