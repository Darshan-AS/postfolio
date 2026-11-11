-- Self-asserting RLS, privilege, FK-cascade, and RPC contract suite for Postfolio.
-- Every case runs inside BEGIN ... ROLLBACK (zero persistent side effects) and asserts
-- exact outcomes or SQLSTATEs; psql exits non-zero immediately if any positive OR negative
-- invariant regresses.
--
-- Run locally or in CI:
--   docker exec -i supabase_db_postfolio psql -v ON_ERROR_STOP=1 -U postgres -d postgres < supabase/tests/rd_ledger_facts_rls.sql

\set ON_ERROR_STOP on

-- Ensure seed fixture exists before running assertions.
DO $$
BEGIN
  ASSERT EXISTS (
    SELECT 1 FROM public.account_identities WHERE account_type = 'RD'
  ), 'Seed precondition failed: expected at least one seeded RD in public.account_identities';
END $$;

SELECT ai.id AS rd_id, ai.agent_id AS owner
FROM public.account_identities ai
WHERE ai.account_type = 'RD'
LIMIT 1 \gset

\set other 'dddddddd-0000-4000-8000-000000000002'

SELECT
  d.installment_amount,
  d.start_date,
  d.term_years,
  d.term_months,
  d.initial_paid_installments,
  ai.customer_id,
  d.status,
  d.scheme_type
FROM public.recurring_deposits d
JOIN public.account_identities ai ON ai.id = d.id
WHERE d.id = :'rd_id' \gset

\echo '== CASE 1: owner inserts PO deposit, tx, summary (expect OK)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_rd_id UUID := (SELECT ai.id FROM public.account_identities ai WHERE ai.account_type = 'RD' LIMIT 1);
  v_owner UUID := auth.uid();
  v_before BIGINT;
  v_after BIGINT;
BEGIN
  SELECT count(*) INTO v_before FROM public.rd_po_deposits WHERE rd_id = v_rd_id;
  INSERT INTO public.rd_po_deposits (rd_id, agent_id, deposited_on, installment_count, amount)
    VALUES (v_rd_id, v_owner, '2026-07-20', 2, 10000);
  INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode)
    VALUES (v_rd_id, v_owner, '2026-07-20', 1000, 'cash');
  INSERT INTO public.rd_ledger_summary (rd_id, agent_id, facts_version, projected_on, open_items)
    VALUES (v_rd_id, v_owner, 1, '2026-07-20', '[{"installment_no":7}]')
    ON CONFLICT (rd_id) DO UPDATE SET facts_version = EXCLUDED.facts_version;
  SELECT count(*) INTO v_after FROM public.rd_po_deposits WHERE rd_id = v_rd_id;
  ASSERT v_after = v_before + 1, 'CASE 1 FAILED: owner PO deposit insert did not persist';
END $$;
ROLLBACK;

\echo '== CASE 2: PO event with zero installments (expect check_violation 23514)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_rd_id UUID := (SELECT ai.id FROM public.account_identities ai WHERE ai.account_type = 'RD' LIMIT 1);
  v_caught BOOLEAN := FALSE;
BEGIN
  BEGIN
    INSERT INTO public.rd_po_deposits (rd_id, agent_id, deposited_on, installment_count, amount)
      VALUES (v_rd_id, auth.uid(), '2026-07-20', 0, 0);
  EXCEPTION WHEN check_violation THEN
    v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 2 FAILED: expected check_violation on zero-installment PO deposit';
END $$;
ROLLBACK;

\echo '== CASE 3: non-positive payment (expect check_violation 23514)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_rd_id UUID := (SELECT ai.id FROM public.account_identities ai WHERE ai.account_type = 'RD' LIMIT 1);
  v_caught BOOLEAN := FALSE;
BEGIN
  BEGIN
    INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode)
      VALUES (v_rd_id, auth.uid(), '2026-07-20', 0, 'cash');
  EXCEPTION WHEN check_violation THEN
    v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 3 FAILED: expected check_violation on non-positive payment';
END $$;
ROLLBACK;

\echo '== CASE 4: OTHER agent inserts PO deposit on owner RD with own agent_id (expect RLS 42501)'
BEGIN;
INSERT INTO auth.users (instance_id,id,aud,role,email,raw_user_meta_data,confirmation_token,recovery_token,email_change_token_new,email_change)
VALUES ('00000000-0000-4000-8000-000000000000','dddddddd-0000-4000-8000-000000000002','authenticated','authenticated','other-agent@example.com','{}','','','','')
ON CONFLICT (id) DO NOTHING;
SELECT set_config('test.target_rd', :'rd_id', true) \gset junk
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'other', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_target_rd UUID := current_setting('test.target_rd')::uuid;
  v_caught BOOLEAN := FALSE;
BEGIN
  BEGIN
    INSERT INTO public.rd_po_deposits (rd_id, agent_id, deposited_on, installment_count, amount)
      VALUES (v_target_rd, auth.uid(), '2026-08-20', 1, 5000);
  EXCEPTION WHEN insufficient_privilege THEN
    v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 4 FAILED: expected RLS insufficient_privilege (42501) on cross-agent PO deposit';
END $$;
ROLLBACK;

\echo '== CASE 5: OTHER agent inserts transaction on owner RD (expect RLS 42501)'
BEGIN;
INSERT INTO auth.users (instance_id,id,aud,role,email,raw_user_meta_data,confirmation_token,recovery_token,email_change_token_new,email_change)
VALUES ('00000000-0000-4000-8000-000000000000','dddddddd-0000-4000-8000-000000000002','authenticated','authenticated','other-agent@example.com','{}','','','','')
ON CONFLICT (id) DO NOTHING;
SELECT set_config('test.target_rd', :'rd_id', true) \gset junk
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'other', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_target_rd UUID := current_setting('test.target_rd')::uuid;
  v_caught BOOLEAN := FALSE;
BEGIN
  BEGIN
    INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode)
      VALUES (v_target_rd, auth.uid(), '2026-07-20', 1000, 'cash');
  EXCEPTION WHEN insufficient_privilege THEN
    v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 5 FAILED: expected RLS insufficient_privilege (42501) on cross-agent transaction';
END $$;
ROLLBACK;

\echo '== CASE 6: save_recurring_deposit is a pure persistence envelope & undo_rd_po_deposit_batch is dropped'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_rec RECORD;
  v_saved UUID;
  v_rpc_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'undo_rd_po_deposit_batch'
  ) INTO v_rpc_exists;
  ASSERT NOT v_rpc_exists, 'CASE 6a FAILED: undo_rd_po_deposit_batch RPC should not exist in SQL';

  SELECT d.*, ai.customer_id INTO v_rec
  FROM public.recurring_deposits d
  JOIN public.account_identities ai ON ai.id = d.id
  LIMIT 1;

  INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode)
    VALUES (v_rec.id, auth.uid(), '2026-07-20', 1000, 'cash');

  -- Domain locking lives in Dart (RecurringDepositsController); SQL envelope persists cleanly.
  v_saved := public.save_recurring_deposit(
    v_rec.id, v_rec.customer_id, v_rec.status, v_rec.scheme_type,
    NULL, NULL, v_rec.installment_amount + 100, v_rec.interest_rate,
    v_rec.term_years, v_rec.term_months, v_rec.start_date, '[]'::jsonb,
    v_rec.initial_paid_installments, v_rec.opening_receivable
  );
  ASSERT v_saved = v_rec.id, 'CASE 6b FAILED: expected save_recurring_deposit envelope to persist';
END $$;
ROLLBACK;

\echo '== CASE 7: save_recurring_deposit same terms while locked (expect OK)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_rec RECORD;
  v_saved UUID;
BEGIN
  SELECT d.*, ai.customer_id INTO v_rec
  FROM public.recurring_deposits d
  JOIN public.account_identities ai ON ai.id = d.id
  LIMIT 1;

  INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode)
    VALUES (v_rec.id, auth.uid(), '2026-07-20', 1000, 'cash');

  v_saved := public.save_recurring_deposit(
    v_rec.id, v_rec.customer_id, v_rec.status, v_rec.scheme_type,
    '999000111', '77', v_rec.installment_amount, v_rec.interest_rate,
    v_rec.term_years, v_rec.term_months, v_rec.start_date, '[]'::jsonb,
    v_rec.initial_paid_installments, v_rec.opening_receivable
  );
  ASSERT v_saved = v_rec.id, 'CASE 7 FAILED: expected metadata edit on locked RD to succeed';
END $$;
ROLLBACK;

\echo '== CASE 8: anon SELECT on public.customers (expect insufficient_privilege 42501)'
BEGIN;
SET LOCAL ROLE anon;
DO $$
DECLARE
  v_cnt BIGINT;
  v_caught BOOLEAN := FALSE;
BEGIN
  BEGIN
    SELECT count(*) INTO v_cnt FROM public.customers;
  EXCEPTION WHEN insufficient_privilege THEN
    v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 8 FAILED: expected anon SELECT on public.customers to be denied';
END $$;
ROLLBACK;

\echo '== CASE 9: authenticated calling private.replace_account_nominees (expect insufficient_privilege 42501)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_caught BOOLEAN := FALSE;
BEGIN
  BEGIN
    EXECUTE 'SELECT private.replace_account_nominees($1, $2)'
      USING gen_random_uuid(), '[]'::jsonb;
  EXCEPTION WHEN insufficient_privilege THEN
    v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 9 FAILED: expected authenticated access to schema private to be denied';
END $$;
ROLLBACK;

\echo '== CASE 10: set_deposit_status preserves nominees, opening_receivable, and rd_ledger_summary (expect OK)'
BEGIN;
UPDATE public.recurring_deposits SET opening_receivable = 750 WHERE id = :'rd_id';
INSERT INTO public.rd_ledger_summary (rd_id, agent_id, facts_version, projected_on, open_items)
VALUES (:'rd_id', :'owner', 42, '2026-07-20', '[]'::jsonb)
ON CONFLICT (rd_id) DO UPDATE SET facts_version = 42;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_rd_id UUID := (SELECT id FROM public.recurring_deposits WHERE opening_receivable = 750 LIMIT 1);
  v_status TEXT;
  v_receivable NUMERIC;
  v_nominees INT;
  v_summary_ver BIGINT;
BEGIN
  PERFORM public.set_deposit_status(v_rd_id, 'closed');
  SELECT
    d.status,
    d.opening_receivable,
    jsonb_array_length(v.nominees),
    (SELECT s.facts_version FROM public.rd_ledger_summary s WHERE s.rd_id = v_rd_id)
  INTO v_status, v_receivable, v_nominees, v_summary_ver
  FROM public.recurring_deposits d
  JOIN public.recurring_deposit_details_view v ON v.id = d.id
  WHERE d.id = v_rd_id;

  ASSERT v_status = 'closed', 'CASE 10 FAILED: status was not updated to closed';
  ASSERT v_receivable = 750, 'CASE 10 FAILED: opening_receivable was clobbered';
  ASSERT v_nominees >= 1, 'CASE 10 FAILED: nominees were wiped by set_deposit_status';
  ASSERT v_summary_ver = 42, 'CASE 10 FAILED: rd_ledger_summary was deleted by set_deposit_status';
END $$;
ROLLBACK;

\echo '== CASE 11: OTHER agent calling set_deposit_status on owner RD (expect insufficient_privilege 42501)'
BEGIN;
INSERT INTO auth.users (instance_id,id,aud,role,email,raw_user_meta_data,confirmation_token,recovery_token,email_change_token_new,email_change)
VALUES ('00000000-0000-0000-0000-000000000000','dddddddd-0000-4000-8000-000000000002','authenticated','authenticated','other-agent@example.com','{}','','','','')
ON CONFLICT (id) DO NOTHING;
SELECT set_config('test.target_rd', :'rd_id', true) \gset junk
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'other', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_target_rd UUID := current_setting('test.target_rd')::uuid;
  v_caught BOOLEAN := FALSE;
BEGIN
  BEGIN
    PERFORM public.set_deposit_status(v_target_rd, 'closed');
  EXCEPTION WHEN insufficient_privilege THEN
    v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 11 FAILED: expected cross-agent set_deposit_status to fail with insufficient_privilege';
END $$;
ROLLBACK;

\echo '== CASE 12: save_recurring_deposit metadata-only edit preserves rd_ledger_summary (expect OK)'
BEGIN;
INSERT INTO public.rd_ledger_summary (rd_id, agent_id, facts_version, projected_on, open_items)
VALUES (:'rd_id', :'owner', 99, '2026-07-20', '[]'::jsonb)
ON CONFLICT (rd_id) DO UPDATE SET facts_version = 99;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_rec RECORD;
  v_summary_count BIGINT;
BEGIN
  SELECT d.*, ai.customer_id INTO v_rec
  FROM public.recurring_deposits d
  JOIN public.account_identities ai ON ai.id = d.id
  JOIN public.rd_ledger_summary s ON s.rd_id = d.id AND s.facts_version = 99
  LIMIT 1;

  PERFORM public.save_recurring_deposit(
    v_rec.id, v_rec.customer_id, v_rec.status, v_rec.scheme_type,
    '999888777', '99', v_rec.installment_amount, v_rec.interest_rate,
    v_rec.term_years, v_rec.term_months, v_rec.start_date,
    '[{"name":"Kept Nominee","relationship":"Son","percentage":100}]'::jsonb,
    v_rec.initial_paid_installments, v_rec.opening_receivable
  );

  SELECT count(*) INTO v_summary_count
  FROM public.rd_ledger_summary
  WHERE rd_id = v_rec.id AND facts_version = 99;

  ASSERT v_summary_count = 1, 'CASE 12 FAILED: metadata-only edit deleted rd_ledger_summary';
END $$;
ROLLBACK;

\echo '== CASE 13: enum columns reject tokens no shipped client can decode (check_violation 23514)'
-- The Dart models decode these columns strictly, and one undecodable row makes a whole list
-- unloadable. The vocabularies are owned by the Dart enums; the CHECKs mirror them
-- (test/core/sql_enum_contract_test.dart fails if the two lists drift apart).
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_customer_id UUID := (SELECT id FROM public.customers WHERE agent_id = auth.uid() LIMIT 1);
  v_otd_id UUID := gen_random_uuid();
  v_rd_id UUID := (SELECT ai.id FROM public.account_identities ai WHERE ai.account_type = 'RD' AND ai.agent_id = auth.uid() LIMIT 1);
  v_caught BOOLEAN;
BEGIN
  -- 13a. Known tokens are accepted end to end.
  PERFORM public.save_one_time_deposit(
    v_otd_id, v_customer_id, 'active', 'timeDeposit', 'TD-ENUM-OK',
    100000, 7.50, 5, 0, '2026-01-15',
    '[{"name":"Known Nominee","relationship":"SonInLaw","percentage":100}]'::jsonb
  );
  PERFORM public.set_deposit_status(v_otd_id, 'closed');
  INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode)
    VALUES (v_rd_id, auth.uid(), '2026-08-01', 500, 'bankTransfer');

  -- 13b. Unknown deposit status.
  v_caught := FALSE;
  BEGIN
    PERFORM public.set_deposit_status(v_otd_id, 'prematurelyClosed');
  EXCEPTION WHEN check_violation THEN v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 13b FAILED: an unknown deposit status was stored';

  -- 13c. Unknown scheme type.
  v_caught := FALSE;
  BEGIN
    PERFORM public.save_one_time_deposit(
      gen_random_uuid(), v_customer_id, 'active', 'seniorCitizenSavingsScheme', 'SCSS-001',
      100000, 8.20, 5, 0, '2026-01-15', '[]'::jsonb
    );
  EXCEPTION WHEN check_violation THEN v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 13c FAILED: an unknown one-time scheme type was stored';

  -- 13d. Nominee relationship in the wrong case (`son` instead of `Son`) and an unknown one.
  v_caught := FALSE;
  BEGIN
    PERFORM public.save_one_time_deposit(
      gen_random_uuid(), v_customer_id, 'active', 'timeDeposit', 'TD-REL-CASE',
      100000, 7.50, 5, 0, '2026-01-15',
      '[{"name":"Wrong Case","relationship":"son","percentage":100}]'::jsonb
    );
  EXCEPTION WHEN check_violation THEN v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 13d FAILED: a wrongly-cased nominee relationship was stored';

  v_caught := FALSE;
  BEGIN
    PERFORM public.save_one_time_deposit(
      gen_random_uuid(), v_customer_id, 'active', 'timeDeposit', 'TD-REL-NEW',
      100000, 7.50, 5, 0, '2026-01-15',
      '[{"name":"Legal Guardian","relationship":"legalGuardian","percentage":100}]'::jsonb
    );
  EXCEPTION WHEN check_violation THEN v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 13d FAILED: an unknown nominee relationship was stored';

  -- 13e. Unknown payment mode.
  v_caught := FALSE;
  BEGIN
    INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode)
      VALUES (v_rd_id, auth.uid(), '2026-08-01', 500, 'neft');
  EXCEPTION WHEN check_violation THEN v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 13e FAILED: an unknown payment mode was stored';
END $$;
ROLLBACK;

-- 13f. The same holds for recurring deposits (status and scheme type), written directly.
BEGIN;
DO $$
DECLARE
  v_rd_id UUID := (SELECT id FROM public.recurring_deposits LIMIT 1);
  v_caught BOOLEAN;
BEGIN
  v_caught := FALSE;
  BEGIN
    UPDATE public.recurring_deposits SET status = 'discontinued' WHERE id = v_rd_id;
  EXCEPTION WHEN check_violation THEN v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 13f FAILED: an unknown RD status was stored';

  v_caught := FALSE;
  BEGIN
    UPDATE public.recurring_deposits SET scheme_type = 'RD' WHERE id = v_rd_id;
  EXCEPTION WHEN check_violation THEN v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 13f FAILED: a short-code RD scheme type was stored';
END $$;
ROLLBACK;

\echo '== CASE 14: ON UPDATE CASCADE on agent_profiles.id cascades to all RD ledger tables (expect OK)'
BEGIN;
INSERT INTO auth.users (instance_id,id,aud,role,email,raw_user_meta_data,confirmation_token,recovery_token,email_change_token_new,email_change)
VALUES ('00000000-0000-0000-0000-000000000000','eeeeeeee-0000-4000-8000-000000000099','authenticated','authenticated','relocated@example.com','{}','','','','')
ON CONFLICT (id) DO NOTHING;
DELETE FROM public.agent_profiles WHERE id = 'eeeeeeee-0000-4000-8000-000000000099';
INSERT INTO public.rd_ledger_summary (rd_id, agent_id, facts_version, projected_on, open_items)
VALUES (:'rd_id', :'owner', 7, '2026-07-20', '[]'::jsonb)
ON CONFLICT (rd_id) DO UPDATE SET facts_version = 7;
UPDATE public.agent_profiles SET id = 'eeeeeeee-0000-4000-8000-000000000099' WHERE id = :'owner';
DO $$
DECLARE
  v_po BIGINT := (SELECT count(*) FROM public.rd_po_deposits WHERE agent_id = 'eeeeeeee-0000-4000-8000-000000000099');
  v_abs BIGINT := (SELECT count(*) FROM public.rd_fee_absorptions WHERE agent_id = 'eeeeeeee-0000-4000-8000-000000000099');
  v_sum BIGINT := (SELECT count(*) FROM public.rd_ledger_summary WHERE agent_id = 'eeeeeeee-0000-4000-8000-000000000099');
BEGIN
  ASSERT v_po > 0 AND v_abs > 0 AND v_sum > 0,
    'CASE 14 FAILED: agent_profiles.id update did not cascade to RD ledger tables';
END $$;
ROLLBACK;

\echo '== CASE 15: log_client_error truncates oversized payloads, enforces RLS, and blocks anon'
BEGIN;
INSERT INTO auth.users (instance_id,id,aud,role,email,raw_user_meta_data,confirmation_token,recovery_token,email_change_token_new,email_change)
VALUES ('00000000-0000-0000-0000-000000000000','dddddddd-0000-4000-8000-000000000002','authenticated','authenticated','other-agent@example.com','{}','','','','')
ON CONFLICT (id) DO NOTHING;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_err_len INT;
  v_stack_len INT;
BEGIN
  PERFORM public.log_client_error('web', repeat('E', 1500), repeat('S', 9000), '2.4.0');
  SELECT char_length(error_message), char_length(stack_trace)
  INTO v_err_len, v_stack_len
  FROM public.app_error_logs
  WHERE agent_id = auth.uid()
  ORDER BY created_at DESC
  LIMIT 1;
  ASSERT v_err_len = 1000 AND v_stack_len = 8000,
    'CASE 15a FAILED: expected log_client_error to truncate oversized error and stack payloads';
END $$;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'other', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_visible BIGINT;
BEGIN
  SELECT count(*) INTO v_visible FROM public.app_error_logs;
  ASSERT v_visible = 0, 'CASE 15b FAILED: other agent must not read owner error logs';
END $$;
SET LOCAL ROLE anon;
DO $$
DECLARE
  v_caught BOOLEAN := FALSE;
BEGIN
  BEGIN
    PERFORM public.log_client_error('web', 'anon error', NULL, NULL);
  EXCEPTION WHEN insufficient_privilege THEN
    v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 15c FAILED: anon must not execute log_client_error';
END $$;
ROLLBACK;

\echo '== CASE 16: ON DELETE RESTRICT (23503) protects Customers with deposits and RDs with ledger facts'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_customer_with_deposit UUID := (
    SELECT ai.customer_id FROM public.account_identities ai
    WHERE ai.agent_id = auth.uid() AND ai.account_type IN ('OTD', 'RD')
    LIMIT 1
  );
  v_rd_with_facts UUID := gen_random_uuid();
  v_empty_rd UUID := gen_random_uuid();
  v_caught_customer BOOLEAN := FALSE;
  v_caught_rd BOOLEAN := FALSE;
BEGIN
  -- 16a: Deleting a customer who owns an OTD/RD must fail with 23503 foreign_key_violation.
  BEGIN
    DELETE FROM public.customers WHERE id = v_customer_with_deposit;
  EXCEPTION WHEN foreign_key_violation THEN
    v_caught_customer := TRUE;
  END;
  ASSERT v_caught_customer,
    'CASE 16a FAILED: expected foreign_key_violation (23503) when deleting customer with deposits';

  -- 16b: Deleting an RD with recorded ledger facts must fail with 23503 foreign_key_violation.
  PERFORM public.save_recurring_deposit(
    v_rd_with_facts, v_customer_with_deposit, 'active', 'recurringDeposit',
    'RD-RESTRICT-1', '901', 1000, 6.70, 5, 0, '2026-01-01', '[]'::jsonb, 0, 0
  );
  INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode)
    VALUES (v_rd_with_facts, auth.uid(), '2026-01-10', 1000, 'cash');

  BEGIN
    DELETE FROM public.account_identities WHERE id = v_rd_with_facts;
  EXCEPTION WHEN foreign_key_violation THEN
    v_caught_rd := TRUE;
  END;
  ASSERT v_caught_rd,
    'CASE 16b FAILED: expected foreign_key_violation (23503) when deleting RD with transactions';

  -- 16c: Deleting an RD with zero facts (even with summary cache + nominees) cascades cleanly.
  PERFORM public.save_recurring_deposit(
    v_empty_rd, v_customer_with_deposit, 'active', 'recurringDeposit',
    'RD-EMPTY-1', '902', 1000, 6.70, 5, 0, '2026-01-01',
    '[{"name":"Test Nominee","relationship":"Wife","percentage":100}]'::jsonb, 0, 0
  );
  INSERT INTO public.rd_ledger_summary (rd_id, agent_id, facts_version, projected_on, open_items)
    VALUES (v_empty_rd, auth.uid(), 1, '2026-01-01', '[]'::jsonb);

  DELETE FROM public.account_identities WHERE id = v_empty_rd;
  ASSERT NOT EXISTS (SELECT 1 FROM public.recurring_deposits WHERE id = v_empty_rd),
    'CASE 16c FAILED: expected empty RD (cache + nominees only) to delete cleanly';
END $$;
ROLLBACK;

\echo '== CASE 17: Case-insensitive UNIQUE email on agent_profiles & partial UNIQUE SB per customer (23505)'
BEGIN;
DO $$
DECLARE
  v_existing_email TEXT := (SELECT email FROM public.agent_profiles WHERE email IS NOT NULL LIMIT 1);
  v_owner UUID := (SELECT id FROM public.agent_profiles WHERE email = v_existing_email LIMIT 1);
  v_customer_id UUID := (SELECT id FROM public.customers WHERE agent_id = v_owner LIMIT 1);
  v_caught_email BOOLEAN := FALSE;
  v_caught_sb BOOLEAN := FALSE;
BEGIN
  INSERT INTO auth.users (instance_id,id,aud,role,email,raw_user_meta_data,confirmation_token,recovery_token,email_change_token_new,email_change)
  VALUES ('00000000-0000-0000-0000-000000000000','ffffffff-0000-4000-8000-000000000077','authenticated','authenticated','unique-probe@example.com','{}','','','','')
  ON CONFLICT (id) DO NOTHING;

  BEGIN
    UPDATE public.agent_profiles
    SET email = upper(v_existing_email)
    WHERE id = 'ffffffff-0000-4000-8000-000000000077';
  EXCEPTION WHEN unique_violation THEN
    v_caught_email := TRUE;
  END;
  ASSERT v_caught_email,
    'CASE 17a FAILED: expected unique_violation (23505) on case-insensitive duplicate agent email';

  INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
  VALUES (gen_random_uuid(), v_customer_id, v_owner, 'SB')
  ON CONFLICT DO NOTHING;

  BEGIN
    INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
    VALUES (gen_random_uuid(), v_customer_id, v_owner, 'SB');
  EXCEPTION WHEN unique_violation THEN
    v_caught_sb := TRUE;
  END;
  ASSERT v_caught_sb,
    'CASE 17b FAILED: expected unique_violation (23505) on second SB account for same customer';
END $$;
ROLLBACK;

\echo '== CASE 18: NUMERIC(12,2)/NUMERIC(5,2) precision & physical sign bounds (23514)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_customer_id UUID := (SELECT id FROM public.customers WHERE agent_id = auth.uid() LIMIT 1);
  v_rd_id UUID := (SELECT ai.id FROM public.account_identities ai WHERE ai.account_type = 'RD' AND ai.agent_id = auth.uid() LIMIT 1);
  v_caught_neg_principal BOOLEAN := FALSE;
  v_caught_bad_pct BOOLEAN := FALSE;
  v_po_id UUID := gen_random_uuid();
  v_fee NUMERIC;
BEGIN
  BEGIN
    PERFORM public.save_one_time_deposit(
      gen_random_uuid(), v_customer_id, 'active', 'timeDeposit',
      'TD-NEG', 0, 7.50, 5, 0, '2026-01-01', '[]'::jsonb
    );
  EXCEPTION WHEN check_violation THEN
    v_caught_neg_principal := TRUE;
  END;
  ASSERT v_caught_neg_principal,
    'CASE 18a FAILED: expected check_violation (23514) on non-positive principal_amount';

  BEGIN
    PERFORM public.save_one_time_deposit(
      gen_random_uuid(), v_customer_id, 'active', 'timeDeposit',
      'TD-PCT', 10000, 7.50, 5, 0, '2026-01-01',
      '[{"name":"Bad Share","relationship":"Son","percentage":105}]'::jsonb
    );
  EXCEPTION WHEN check_violation THEN
    v_caught_bad_pct := TRUE;
  END;
  ASSERT v_caught_bad_pct,
    'CASE 18b FAILED: expected check_violation (23514) on nominee percentage > 100';

  INSERT INTO public.rd_po_deposits (id, rd_id, agent_id, deposited_on, installment_count, fee_paid, amount)
    VALUES (v_po_id, v_rd_id, auth.uid(), '2026-09-10', 1, 2.50, 252.50);
  SELECT fee_paid INTO v_fee FROM public.rd_po_deposits WHERE id = v_po_id;
  ASSERT v_fee = 2.50, 'CASE 18c FAILED: expected exact paise round-trip (2.50) in NUMERIC(12,2)';
END $$;
ROLLBACK;

\echo '== CASE 19: privilege lockdown holds for objects that do not exist yet'
-- 19a. A function created in `public` AFTER the migrations must not be callable by anyone
--      until a migration grants it. PUBLIC's EXECUTE on new functions is a global default,
--      so a per-schema ALTER DEFAULT PRIVILEGES cannot remove it.
BEGIN;
CREATE FUNCTION public.contract_probe_fn() RETURNS int LANGUAGE sql AS 'SELECT 1';
DO $$
BEGIN
  ASSERT NOT has_function_privilege('anon', 'public.contract_probe_fn()', 'execute'),
    'CASE 19a FAILED: a new function in public is executable by anon';
  ASSERT NOT has_function_privilege('authenticated', 'public.contract_probe_fn()', 'execute'),
    'CASE 19a FAILED: a new function in public is executable by authenticated without a grant';
END $$;
ROLLBACK;

-- 19b. No existing function in `public` is executable by anon, and the functions
--      authenticated may call are exactly the documented client surface.
DO $$
DECLARE
  v_anon TEXT;
  v_authenticated TEXT;
BEGIN
  SELECT string_agg(p.proname, ', ' ORDER BY p.proname) INTO v_anon
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND has_function_privilege('anon', p.oid, 'execute');
  ASSERT v_anon IS NULL,
    format('CASE 19b FAILED: functions in public executable by anon: %s', v_anon);

  SELECT string_agg(p.proname, ', ' ORDER BY p.proname) INTO v_authenticated
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND has_function_privilege('authenticated', p.oid, 'execute');
  ASSERT v_authenticated =
    'delete_customer, is_admin, log_client_error, owns_account, save_customer_with_sb_account, '
    'save_one_time_deposit, save_recurring_deposit, set_deposit_status',
    format('CASE 19b FAILED: unexpected functions executable by authenticated: %s', v_authenticated);
END $$;

-- 19c. Every table in `public` has row-level security enabled.
DO $$
DECLARE
  v_without_rls TEXT;
BEGIN
  SELECT string_agg(c.relname, ', ' ORDER BY c.relname) INTO v_without_rls
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public' AND c.relkind = 'r' AND NOT c.relrowsecurity;
  ASSERT v_without_rls IS NULL,
    format('CASE 19c FAILED: tables in public without RLS: %s', v_without_rls);
END $$;

\echo '== CASE 20: delete_customer removes a customer with its savings account, or nothing at all'
\set lonely 'cccccccc-0000-4000-8000-000000000020'
BEGIN;
INSERT INTO auth.users (instance_id,id,aud,role,email,raw_user_meta_data,confirmation_token,recovery_token,email_change_token_new,email_change)
VALUES ('00000000-0000-0000-0000-000000000000','dddddddd-0000-4000-8000-000000000002','authenticated','authenticated','other-agent@example.com','{}','','','','')
ON CONFLICT (id) DO NOTHING;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_with_deposit UUID := (
    SELECT ai.customer_id FROM public.account_identities ai
    WHERE ai.agent_id = auth.uid() AND ai.account_type IN ('OTD', 'RD')
    LIMIT 1
  );
  v_caught BOOLEAN := FALSE;
BEGIN
  -- 20a. A customer with deposits is refused, and the savings account is still there.
  INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
    VALUES (gen_random_uuid(), v_with_deposit, auth.uid(), 'SB')
    ON CONFLICT DO NOTHING;
  BEGIN
    PERFORM public.delete_customer(v_with_deposit);
  EXCEPTION WHEN foreign_key_violation THEN
    v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 20a FAILED: expected 23503 when deleting a customer who has deposits';
  ASSERT EXISTS (
    SELECT 1 FROM public.account_identities
    WHERE customer_id = v_with_deposit AND account_type = 'SB'
  ), 'CASE 20a FAILED: a refused delete removed the savings account';

  -- A customer with only a savings account and a nominee, used by 20b and 20c.
  PERFORM public.save_customer_with_sb_account(
    'cccccccc-0000-4000-8000-000000000020', 'Lonely Customer', '9876543210',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'SB-LONELY-1',
    '[{"name":"Only Nominee","relationship":"Son","percentage":100}]'::jsonb
  );
END $$;

-- 20b. Another agent calling it on this customer deletes nothing (RLS applies: SECURITY INVOKER).
SELECT set_config('request.jwt.claims', json_build_object('sub', :'other', 'role', 'authenticated')::text, true) \gset junk
SELECT public.delete_customer(:'lonely') \gset junk
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
BEGIN
  ASSERT EXISTS (SELECT 1 FROM public.customers WHERE id = 'cccccccc-0000-4000-8000-000000000020'),
    'CASE 20b FAILED: another agent deleted this customer';

  -- 20c. The owner deletes the customer, its savings account and nominees in one call.
  PERFORM public.delete_customer('cccccccc-0000-4000-8000-000000000020');
  ASSERT NOT EXISTS (SELECT 1 FROM public.customers WHERE id = 'cccccccc-0000-4000-8000-000000000020'),
    'CASE 20c FAILED: customer was not deleted';
  ASSERT NOT EXISTS (
    SELECT 1 FROM public.account_identities WHERE customer_id = 'cccccccc-0000-4000-8000-000000000020'
  ), 'CASE 20c FAILED: savings account identity was left behind';
END $$;
ROLLBACK;

\echo '== ALL 20 SQL CONTRACT ASSERTIONS PASSED =='
