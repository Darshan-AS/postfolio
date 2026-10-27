-- Wipe every row of app + auth data in the local emulator, keep the schema, then reseed.
BEGIN;
TRUNCATE TABLE
  public.rd_ledger_summary,
  public.rd_fee_waivers,
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
-- Record the facts-only migration as applied (it was executed manually against this DB).
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('20261027000000', 'facts_only_rd_ledger')
ON CONFLICT (version) DO NOTHING;
COMMIT;
