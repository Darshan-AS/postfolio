-- Seed Data for Postfolio
-- Run when "supabase db reset" is executed

-- 1. Create a dummy agent in auth.users and auth.identities
-- Password: password123
INSERT INTO auth.users (
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
) VALUES (
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d',
  'authenticated',
  'authenticated',
  'agent@postfolio.com',
  crypt('password123', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"name": "Agent Postfolio", "full_name": "Agent Postfolio"}',
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
  ('f4444444-4444-4444-4444-444444444444', 'c3333333-3333-3333-3333-333333333333', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 'OTD')
ON CONFLICT (id) DO NOTHING;

-- 4. Add recurring deposits
INSERT INTO public.recurring_deposits (id, status, scheme_type, account_no, serial_no, installment_amount, interest_rate, term_years, term_months, start_date)
VALUES
  ('d1111111-1111-1111-1111-111111111111', 'active', 'RD', '100200300', '1', 5000.00, 6.7, 5, 0, '2025-01-15'),
  ('f2222222-2222-2222-2222-222222222222', 'active', 'RD', '100200400', '2', 10000.00, 6.7, 5, 0, '2024-06-01')
ON CONFLICT (id) DO NOTHING;

-- 5. Add one time deposits
INSERT INTO public.one_time_deposits (id, status, scheme_type, account_no, principal_amount, interest_rate, term_years, term_months, start_date)
VALUES
  ('e1111111-1111-1111-1111-111111111111', 'active', 'MIS', '500600700', 450000.00, 7.4, 5, 0, '2023-10-01'),
  ('f3333333-3333-3333-3333-333333333333', 'active', 'KVP', '500600800', 100000.00, 7.5, 9, 7, '2022-04-15'),
  ('f4444444-4444-4444-4444-444444444444', 'active', 'TD', '500600900', 200000.00, 7.0, 3, 0, '2024-11-20')
ON CONFLICT (id) DO NOTHING;

-- 6. Add nominees
INSERT INTO public.nominees (id, account_id, name, relationship, percentage)
VALUES
  (gen_random_uuid(), 'd1111111-1111-1111-1111-111111111111', 'Karan Mehta', 'son', 100),
  (gen_random_uuid(), 'e1111111-1111-1111-1111-111111111111', 'Sujata Mehta', 'wife', 100),
  (gen_random_uuid(), 'f2222222-2222-2222-2222-222222222222', 'Siddharth Sharma', 'husband', 50),
  (gen_random_uuid(), 'f2222222-2222-2222-2222-222222222222', 'Kriti Sharma', 'daughter', 50),
  (gen_random_uuid(), 'f3333333-3333-3333-3333-333333333333', 'Siddharth Sharma', 'husband', 100),
  (gen_random_uuid(), 'f4444444-4444-4444-4444-444444444444', 'Preeti Varma', 'wife', 100)
ON CONFLICT (id) DO NOTHING;
