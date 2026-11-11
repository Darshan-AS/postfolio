-- Wipe every row of app + auth data in the local emulator, keep the schema, then reseed.
BEGIN;
TRUNCATE TABLE
  public.app_error_logs,
  public.rd_ledger_summary,
  public.rd_fee_absorptions,
  public.rd_po_deposits,
  public.rd_transactions,
  public.nominees,
  public.recurring_deposits,
  public.one_time_deposits,
  public.savings_accounts,
  public.account_identities,
  public.customers,
  public.user_roles,
  public.agent_profiles
  CASCADE;
DELETE FROM auth.mfa_factors;
DELETE FROM auth.refresh_tokens;
DELETE FROM auth.sessions;
DELETE FROM auth.identities;
DELETE FROM auth.users;
-- Record the ledger + Stage 0 hotfix migrations as applied (if executed manually against this DB).
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES
  ('20261110000000', 'rd_ledger'),
  ('20261111000000', 'p0_security_and_status_hotfix')
ON CONFLICT (version) DO NOTHING;
COMMIT;
