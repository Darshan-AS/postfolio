-- RLS + constraint smoke test for the facts-only RD ledger (20261027000000_facts_only_rd_ledger.sql).
-- Run against the local stack (every case rolls back):
--   docker exec -i supabase_db_postfolio psql -U postgres -d postgres < supabase/tests/rd_ledger_facts_rls.sql
-- Expected: CASE 1 & 7 succeed; CASE 2 PK error; CASE 3 CHECK error; CASE 4 & 5 RLS error; CASE 6 terms-lock error.

SELECT ai.id AS rd_id, ai.agent_id AS owner FROM public.account_identities ai WHERE ai.account_type = 'RD' LIMIT 1 \gset
SELECT id AS other FROM public.agent_profiles WHERE id <> :'owner' LIMIT 1 \gset
SELECT d.installment_amount, d.start_date, d.term_years, d.term_months, d.initial_paid_installments, ai.customer_id, d.status, d.scheme_type
FROM public.recurring_deposits d JOIN public.account_identities ai ON ai.id = d.id WHERE d.id = :'rd_id' \gset

\echo '== CASE 1 owner inserts PO deposit, tx, summary (expect 3 OK)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
INSERT INTO public.rd_po_deposits (rd_id, agent_id, installment_no, deposited_on) VALUES (:'rd_id', :'owner', 55, '2026-07-20');
INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode, split_mode) VALUES (:'rd_id', :'owner', '2026-07-20', 1000, 'cash', 'includeFees');
INSERT INTO public.rd_ledger_summary (rd_id, agent_id, facts_version, projected_on, open_items) VALUES (:'rd_id', :'owner', 1, '2026-07-20', '[{"installment_no":7}]') ON CONFLICT (rd_id) DO UPDATE SET facts_version = EXCLUDED.facts_version;
SELECT count(*) AS owner_sees_po FROM public.rd_po_deposits WHERE rd_id = :'rd_id';
ROLLBACK;

\echo '== CASE 2 duplicate PO deposit (expect PK error)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
INSERT INTO public.rd_po_deposits (rd_id, agent_id, installment_no, deposited_on) VALUES (:'rd_id', :'owner', 55, '2026-07-20');
INSERT INTO public.rd_po_deposits (rd_id, agent_id, installment_no, deposited_on) VALUES (:'rd_id', :'owner', 55, '2026-07-21');
ROLLBACK;

\echo '== CASE 3 custom split that does not balance (expect CHECK error)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode, split_mode, installment_amount, late_fee_amount) VALUES (:'rd_id', :'owner', '2026-07-20', 1000, 'cash', 'custom', 900, 50);
ROLLBACK;

\echo '== CASE 4 OTHER agent inserts PO deposit on owner RD with own agent_id (expect RLS error)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'other', 'role', 'authenticated')::text, true) \gset junk
INSERT INTO public.rd_po_deposits (rd_id, agent_id, installment_no, deposited_on) VALUES (:'rd_id', :'other', 8, '2026-08-20');
ROLLBACK;

\echo '== CASE 5 OTHER agent inserts transaction on owner RD (expect RLS error)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'other', 'role', 'authenticated')::text, true) \gset junk
INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode, split_mode) VALUES (:'rd_id', :'other', '2026-07-20', 1000, 'cash', 'includeFees');
ROLLBACK;

\echo '== CASE 6 save_recurring_deposit changes amount while locked (expect check_violation)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode, split_mode) VALUES (:'rd_id', :'owner', '2026-07-20', 1000, 'cash', 'includeFees');
SELECT public.save_recurring_deposit(:'rd_id'::uuid, :'customer_id'::uuid, :'status', :'scheme_type', NULL, NULL, (:installment_amount + 1)::numeric, 6.7, :term_years, :term_months, :'start_date'::date, '[]'::jsonb, :initial_paid_installments);
ROLLBACK;

\echo '== CASE 7 save_recurring_deposit same terms while locked (expect OK)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode, split_mode) VALUES (:'rd_id', :'owner', '2026-07-20', 1000, 'cash', 'includeFees');
SELECT public.save_recurring_deposit(:'rd_id'::uuid, :'customer_id'::uuid, :'status', :'scheme_type', NULL, NULL, :installment_amount, 6.7, :term_years, :term_months, :'start_date'::date, '[]'::jsonb, :initial_paid_installments);
ROLLBACK;
