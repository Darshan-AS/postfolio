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

\echo '== CASE 6: save_recurring_deposit changes amount while locked (expect check_violation 23514)'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_rec RECORD;
  v_caught BOOLEAN := FALSE;
BEGIN
  SELECT d.*, ai.customer_id INTO v_rec
  FROM public.recurring_deposits d
  JOIN public.account_identities ai ON ai.id = d.id
  LIMIT 1;

  INSERT INTO public.rd_transactions (rd_id, agent_id, paid_date, amount, payment_mode)
    VALUES (v_rec.id, auth.uid(), '2026-07-20', 1000, 'cash');

  BEGIN
    PERFORM public.save_recurring_deposit(
      v_rec.id, v_rec.customer_id, v_rec.status, v_rec.scheme_type,
      NULL, NULL, v_rec.installment_amount + 1, v_rec.interest_rate,
      v_rec.term_years, v_rec.term_months, v_rec.start_date, '[]'::jsonb,
      v_rec.initial_paid_installments, v_rec.opening_receivable
    );
  EXCEPTION WHEN check_violation THEN
    v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 6 FAILED: expected check_violation when mutating locked financial terms';
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

\echo '== CASE 13: undo_rd_po_deposit_batch succeeds when latest, fails when newer PO deposit exists'
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims', json_build_object('sub', :'owner', 'role', 'authenticated')::text, true) \gset junk
DO $$
DECLARE
  v_rd_id UUID := (SELECT ai.id FROM public.account_identities ai WHERE ai.account_type = 'RD' LIMIT 1);
  v_undone UUID[];
  v_caught BOOLEAN := FALSE;
BEGIN
  INSERT INTO public.rd_po_deposits (rd_id, agent_id, deposited_on, installment_count, amount, batch_id)
    VALUES (v_rd_id, auth.uid(), '2026-10-01', 1, 5000, 'bbbbbbbb-0000-4000-8000-000000000001');

  v_undone := public.undo_rd_po_deposit_batch('bbbbbbbb-0000-4000-8000-000000000001'::uuid);
  ASSERT array_length(v_undone, 1) = 1 AND v_undone[1] = v_rd_id,
    'CASE 13a FAILED: expected undo_rd_po_deposit_batch to return [v_rd_id]';

  INSERT INTO public.rd_po_deposits (rd_id, agent_id, deposited_on, installment_count, amount, batch_id)
    VALUES (v_rd_id, auth.uid(), '2026-10-01', 1, 5000, 'bbbbbbbb-0000-4000-8000-000000000002');
  INSERT INTO public.rd_po_deposits (rd_id, agent_id, deposited_on, installment_count, amount)
    VALUES (v_rd_id, auth.uid(), '2026-10-15', 1, 5000);

  BEGIN
    PERFORM public.undo_rd_po_deposit_batch('bbbbbbbb-0000-4000-8000-000000000002'::uuid);
  EXCEPTION WHEN check_violation THEN
    v_caught := TRUE;
  END;
  ASSERT v_caught, 'CASE 13b FAILED: expected check_violation when undoing superseded PO batch';
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

\echo '== ALL 15 SQL CONTRACT ASSERTIONS PASSED =='
