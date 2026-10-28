-- Seed Data for Postfolio
-- Run when "supabase db reset" is executed

-- 1. Create a dummy agent in auth.users and auth.identities
-- Password: password123
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d',
  'authenticated',
  'authenticated',
  'agent@postfolio.com',
  crypt('password123', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"name": "Agent Postfolio", "full_name": "Agent Postfolio"}',
  '', '', '', '',
  now(),
  now()
) ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,
  last_sign_in_at,
  created_at,
  updated_at
) VALUES (
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d',
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d',
  jsonb_build_object('sub', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 'email', 'agent@postfolio.com'),
  'email',
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d',
  now(),
  now(),
  now()
) ON CONFLICT (id) DO NOTHING;

-- Since public.agent_profiles is auto-populated by the on_auth_user_created trigger,
-- we can update it to populate specific fields like agency_code.
UPDATE public.agent_profiles 
SET agency_code = 'POST-001'
WHERE id = '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d';

-- 2. Add sample customers
INSERT INTO public.customers (id, agent_id, name, phone, pan_number, email, address, cif_number, aadhaar_number, date_of_birth, notes)
VALUES 
  ('a1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 'Arjun Mehta', '9876543210', 'ABCDE1234F', 'arjun@example.com', '123, Park Avenue, Mumbai', 'CIF100234', '123456789012', '1985-04-12', 'Preferred communication via WhatsApp.'),
  ('b2222222-2222-2222-2222-222222222222', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 'Deepika Sharma', '9123456780', 'FGHIJ5678K', 'deepika@example.com', '456, Lakeview Road, Bangalore', 'CIF100567', '987654321098', '1990-09-25', 'Requires double nominee allocations.'),
  ('c3333333-3333-3333-3333-333333333333', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 'Rohan Varma', '9345678120', 'KLMNO9012P', 'rohan@example.com', '789, Hill Top, Pune', 'CIF100901', '567890123456', '1978-12-05', 'High net-worth client with multiple short-term schemes.')
ON CONFLICT (id) DO NOTHING;

-- 3. Add account identities
INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
VALUES
  ('d1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 'RD'),
  ('e1111111-1111-1111-1111-111111111111', 'a1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 'OTD'),
  ('f2222222-2222-2222-2222-222222222222', 'b2222222-2222-2222-2222-222222222222', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 'RD'),
  ('f3333333-3333-3333-3333-333333333333', 'b2222222-2222-2222-2222-222222222222', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 'OTD'),
  ('f4444444-4444-4444-4444-444444444444', 'c3333333-3333-3333-3333-333333333333', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 'OTD'),
  ('f5555555-5555-5555-5555-555555555555', 'c3333333-3333-3333-3333-333333333333', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 'RD')
ON CONFLICT (id) DO NOTHING;

-- 4. Add recurring deposits (scheme_type/status/relationship use the app's camelCase enum serialization)
--    initial_paid_installments = months settled before onboarding (projected as baseline, no rows).
--    d111…: opened 15 Jan 2025 (due on the 15th), onboarded with 12 months paid → ledger starts at #13 (Jan 2026).
--    f222…: opened 1 Jun 2024 (due on the 15th), onboarded with 24 months paid → ledger starts at #25 (Jun 2026).
--    f555…: opened 20 Aug 2026 (due end-of-month), brand new account.
INSERT INTO public.recurring_deposits (id, status, scheme_type, account_no, serial_no, installment_amount, interest_rate, term_years, term_months, start_date, initial_paid_installments, opening_receivable)
VALUES
  ('d1111111-1111-1111-1111-111111111111', 'active', 'recurringDeposit', '100200300', '1', 5000.00, 6.7, 5, 0, '2025-01-15', 12, 0),
  ('f2222222-2222-2222-2222-222222222222', 'active', 'recurringDeposit', '100200400', '2', 10000.00, 6.7, 5, 0, '2024-06-01', 24, 0),
  ('f5555555-5555-5555-5555-555555555555', 'active', 'recurringDeposit', '100200500', '3', 2000.00, 6.7, 5, 0, '2026-08-20', 0, 0)
ON CONFLICT (id) DO NOTHING;

-- 4b. RD ledger facts (facts-only ledger: payments, PO deposits, waivers; everything else is projected)
--     d111…: #13–#16 paid on time (#14 one day late, fee absorbed by the agent), #17 (May) skipped, so the
--            Jun/Jul/Aug payments roll forward chronologically and Aug/Sep/Oct are in arrears; a ₹100 top-up in Sep.
--     f222…: #25, #26 on time, #27 paid late (default fee), #28 and #29 unpaid.
--     f555…: #1 paid, #2 unpaid (overdue), #3 due end of October.
INSERT INTO public.rd_transactions (id, rd_id, agent_id, paid_date, amount, payment_mode)
VALUES
  ('aa000000-0000-4000-8000-000000000101', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-01-14', 5000.00, 'cash'),
  ('aa000000-0000-4000-8000-000000000102', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-02-16', 5000.00, 'upi'),
  ('aa000000-0000-4000-8000-000000000103', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-03-12', 5000.00, 'cash'),
  ('aa000000-0000-4000-8000-000000000104', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-04-15', 5000.00, 'cash'),
  ('aa000000-0000-4000-8000-000000000105', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-06-20', 5000.00, 'cash'),
  ('aa000000-0000-4000-8000-000000000106', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-07-14', 5000.00, 'upi'),
  ('aa000000-0000-4000-8000-000000000107', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-08-14', 5000.00, 'cash'),
  ('aa000000-0000-4000-8000-000000000108', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-09-16', 100.00,  'cash'),
  ('aa000000-0000-4000-8000-000000000201', 'f2222222-2222-2222-2222-222222222222', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-06-10', 10000.00, 'bankTransfer'),
  ('aa000000-0000-4000-8000-000000000202', 'f2222222-2222-2222-2222-222222222222', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-07-13', 10000.00, 'cash'),
  ('aa000000-0000-4000-8000-000000000203', 'f2222222-2222-2222-2222-222222222222', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-08-30', 10100.00, 'cash'),
  ('aa000000-0000-4000-8000-000000000301', 'f5555555-5555-5555-5555-555555555555', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-08-28', 2000.00, 'cash')
ON CONFLICT (id) DO NOTHING;

-- PO visits are sequential events: "deposited the next N installments on <date>".
--   d111…: six monthly visits covering #13–#18 (one month each), nothing since July.
--   f222…: #25 and #26 deposited; #27 collected late and still with the agent.
--   f555…: #1 deposited.
INSERT INTO public.rd_po_deposits (id, rd_id, agent_id, deposited_on, installment_count, fee_paid, amount)
VALUES
  ('bb000000-0000-4000-8000-000000000101', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-01-16', 1, 0,  5000.00),
  ('bb000000-0000-4000-8000-000000000102', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-02-18', 1, 50, 5050.00),
  ('bb000000-0000-4000-8000-000000000103', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-03-14', 1, 0,  5000.00),
  ('bb000000-0000-4000-8000-000000000104', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-04-17', 1, 50, 5050.00),
  ('bb000000-0000-4000-8000-000000000105', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-06-22', 1, 50, 5050.00),
  ('bb000000-0000-4000-8000-000000000106', 'd1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-07-16', 1, 50, 5050.00),
  ('bb000000-0000-4000-8000-000000000201', 'f2222222-2222-2222-2222-222222222222', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-06-12', 1, 0,  10000.00),
  ('bb000000-0000-4000-8000-000000000202', 'f2222222-2222-2222-2222-222222222222', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-07-15', 1, 0,  10000.00),
  ('bb000000-0000-4000-8000-000000000301', 'f5555555-5555-5555-5555-555555555555', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', '2026-08-29', 1, 0,  2000.00)
ON CONFLICT (id) DO NOTHING;

-- The agent paid #14's ₹50 default fee from pocket for a good customer.
INSERT INTO public.rd_fee_absorptions (rd_id, agent_id, installment_no, amount, absorbed_on, note)
VALUES
  ('d1111111-1111-1111-1111-111111111111', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 14, 50, '2026-02-18', 'Customer travelling; one-day delay')
ON CONFLICT (rd_id, installment_no) DO NOTHING;

-- 5. Add one time deposits
INSERT INTO public.one_time_deposits (id, status, scheme_type, account_no, principal_amount, interest_rate, term_years, term_months, start_date)
VALUES
  ('e1111111-1111-1111-1111-111111111111', 'active', 'monthlyIncomeScheme', '500600700', 450000.00, 7.4, 5, 0, '2023-10-01'),
  ('f3333333-3333-3333-3333-333333333333', 'active', 'kisanVikasPatra', '500600800', 100000.00, 7.5, 9, 7, '2022-04-15'),
  ('f4444444-4444-4444-4444-444444444444', 'active', 'timeDeposit', '500600900', 200000.00, 7.0, 3, 0, '2024-11-20')
ON CONFLICT (id) DO NOTHING;

-- 6. Add nominees
INSERT INTO public.nominees (id, account_id, name, relationship, percentage)
VALUES
  (gen_random_uuid(), 'd1111111-1111-1111-1111-111111111111', 'Karan Mehta', 'Son', 100),
  (gen_random_uuid(), 'e1111111-1111-1111-1111-111111111111', 'Sujata Mehta', 'Wife', 100),
  (gen_random_uuid(), 'f2222222-2222-2222-2222-222222222222', 'Siddharth Sharma', 'Husband', 50),
  (gen_random_uuid(), 'f2222222-2222-2222-2222-222222222222', 'Kriti Sharma', 'Daughter', 50),
  (gen_random_uuid(), 'f3333333-3333-3333-3333-333333333333', 'Siddharth Sharma', 'Husband', 100),
  (gen_random_uuid(), 'f4444444-4444-4444-4444-444444444444', 'Preeti Varma', 'Wife', 100),
  (gen_random_uuid(), 'f5555555-5555-5555-5555-555555555555', 'Preeti Varma', 'Wife', 100)
ON CONFLICT (id) DO NOTHING;

-- 7. Dev helper: hand the seeded portfolio to the agent you actually sign in with (e.g. Google
--    sign-in on the local emulator). Run once after your first sign-in:
--      docker exec supabase_db_postfolio psql -U postgres -d postgres \
--        -c "SELECT public.adopt_seed_data('you@example.com');"
--    Moves every seeded row from the dummy agent to the agent with that email. Local-only.
CREATE OR REPLACE FUNCTION public.adopt_seed_data_for(v_target UUID)
RETURNS TEXT AS $$
DECLARE
  v_seed UUID := '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d';
BEGIN
  IF v_target IS NULL OR v_target = v_seed THEN
    RETURN 'Nothing to do.';
  END IF;
  UPDATE public.customers          SET agent_id = v_target WHERE agent_id = v_seed;
  UPDATE public.account_identities SET agent_id = v_target WHERE agent_id = v_seed;
  UPDATE public.rd_transactions    SET agent_id = v_target WHERE agent_id = v_seed;
  UPDATE public.rd_po_deposits     SET agent_id = v_target WHERE agent_id = v_seed;
  UPDATE public.rd_fee_absorptions SET agent_id = v_target WHERE agent_id = v_seed;
  DELETE FROM public.rd_ledger_summary WHERE agent_id = v_seed; -- cache; rebuilt by the app
  RETURN 'Seed data now belongs to ' || v_target::text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.adopt_seed_data(p_email TEXT)
RETURNS TEXT AS $$
DECLARE
  v_target UUID;
BEGIN
  SELECT id INTO v_target FROM auth.users WHERE lower(email) = lower(p_email);
  IF v_target IS NULL THEN
    RETURN 'No auth user with email ' || p_email || ' — sign in once first.';
  END IF;
  INSERT INTO public.agent_profiles (id, name, email)
  SELECT v_target, COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', 'Agent'), email
  FROM auth.users WHERE id = v_target
  ON CONFLICT (id) DO NOTHING;
  RETURN public.adopt_seed_data_for(v_target);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 8. Local convenience: the FIRST real agent to sign in (e.g. your Google account on the
--    emulator) automatically adopts the seeded portfolio. Throwaway test agents created by the
--    repository tests (`*@example.com`) are ignored so they never steal — and then cascade-delete —
--    the seed data.
CREATE OR REPLACE FUNCTION public.handle_seed_adoption()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.id <> '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d'
     AND COALESCE(NEW.email, '') NOT ILIKE '%@example.com'
     AND EXISTS (SELECT 1 FROM public.customers WHERE agent_id = '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d') THEN
    PERFORM public.adopt_seed_data_for(NEW.id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trigger_seed_adoption ON public.agent_profiles;
CREATE TRIGGER trigger_seed_adoption
  AFTER INSERT ON public.agent_profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_seed_adoption();
