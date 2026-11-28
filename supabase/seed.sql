-- Seed data for the LOCAL Supabase stack. `supabase db reset` runs this after the migrations.
-- The hosted database never sees this file.
--
-- Three seeded agents:
--   1. Jim Gordon (agent@postfolio.com / password123) — granted 'admin' role, with 22 DC
--      Universe customers, 21 recurring deposits (serials 1..21), 17 one-time deposits (1..17),
--      and 1 savings account (0100030017), mirrored 1-to-1 with FakeDataSource.
--   2. Lucius Fox (lucius@postfolio.com / password123) — 3 customers, 2 RDs, 2 OTDs.
--   3. Perry White (perry@postfolio.com / password123) — 2 customers, 1 RD, 2 OTDs.
--
-- Every date is counted back from the day of the reset, in India time, so "this month",
-- "overdue" and "maturing soon" are true on that day whatever the calendar says. Nothing is
-- dated after that day. The data ages as days pass; reset again to refresh it.
--
-- test/supabase_seed_scenarios_test.dart reads this data through the app's own ledger
-- projection and checks every situation named here. Change the two together.
--
-- To load it into a database that is already running: wipe first
-- (supabase/tests/wipe_emulator_data.sql), then run this file. It does not update rows
-- that exist.

-- Ensure re-running seed.sql after wipe_emulator_data.sql does not trigger seed adoption
-- while inserting the seeded agents.
DROP TRIGGER IF EXISTS trigger_seed_adoption ON public.agent_profiles;

-- ---------------------------------------------------------------------------------------
-- 1. The seeded agents (auth users, identities, profiles, admin role)
-- ---------------------------------------------------------------------------------------
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
) VALUES
(
  '00000000-0000-0000-0000-000000000000',
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d',
  'authenticated',
  'authenticated',
  'agent@postfolio.com',
  crypt('password123', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"name": "Jim Gordon", "full_name": "Jim Gordon"}',
  '', '', '', '',
  now(),
  now()
),
(
  '00000000-0000-0000-0000-000000000000',
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e',
  'authenticated',
  'authenticated',
  'lucius@postfolio.com',
  crypt('password123', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"name": "Lucius Fox", "full_name": "Lucius Fox"}',
  '', '', '', '',
  now(),
  now()
),
(
  '00000000-0000-0000-0000-000000000000',
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f',
  'authenticated',
  'authenticated',
  'perry@postfolio.com',
  crypt('password123', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"name": "Perry White", "full_name": "Perry White"}',
  '', '', '', '',
  now(),
  now()
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,
  last_sign_in_at,
  created_at,
  updated_at
) VALUES
(
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d',
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d',
  jsonb_build_object('sub', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 'email', 'agent@postfolio.com'),
  'email',
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d',
  now(),
  now(),
  now()
),
(
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e',
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e',
  jsonb_build_object('sub', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e', 'email', 'lucius@postfolio.com'),
  'email',
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e',
  now(),
  now(),
  now()
),
(
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f',
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f',
  jsonb_build_object('sub', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f', 'email', 'perry@postfolio.com'),
  'email',
  '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f',
  now(),
  now(),
  now()
)
ON CONFLICT (id) DO NOTHING;

-- public.agent_profiles is filled by the on_auth_user_created trigger.
UPDATE public.agent_profiles SET agency_code = 'GCPD-001' WHERE id = '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d';
UPDATE public.agent_profiles SET agency_code = 'WAYNE-002' WHERE id = '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e';
UPDATE public.agent_profiles SET agency_code = 'PLANET-003' WHERE id = '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f';

-- Grant admin role to the primary seeded agent so Admin Acting-As works out of the box locally.
INSERT INTO public.user_roles (user_id, role)
VALUES ('8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d', 'admin')
ON CONFLICT (user_id, role) DO NOTHING;

-- ---------------------------------------------------------------------------------------
-- 2. Helpers, in a schema that is dropped at the end of this file
-- ---------------------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS seed;

-- The day the seed treats as today: today in India, or the `seed.today` setting when one is
-- given (PGOPTIONS="-c seed.today=2026-11-30"), which is how other days are tried out.
CREATE OR REPLACE FUNCTION seed.today() RETURNS date LANGUAGE sql STABLE AS $$
  SELECT COALESCE(
    NULLIF(current_setting('seed.today', true), '')::date,
    (now() AT TIME ZONE 'Asia/Kolkata')::date
  );
$$;

-- Day `p_day` of the month `p_months_ago` months back (0 = this month). A day the month
-- does not have becomes its last day; a day of this month that is still ahead becomes today.
CREATE OR REPLACE FUNCTION seed.dt(p_months_ago int, p_day int) RETURNS date LANGUAGE sql STABLE AS $$
  SELECT LEAST(
    m.first + LEAST(p_day, EXTRACT(day FROM m.first + interval '1 month - 1 day')::int) - 1,
    CASE WHEN p_months_ago <= 0 THEN seed.today() ELSE 'infinity'::date END
  )
  FROM (
    SELECT (date_trunc('month', seed.today()) - make_interval(months => p_months_ago))::date AS first
  ) m;
$$;

CREATE OR REPLACE FUNCTION seed.agent() RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d'::uuid;
$$;

-- A stable id for a named row, e.g. seed.id('customer:alfred') or seed.id('rd:alfred').
CREATE OR REPLACE FUNCTION seed.id(p_key text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT md5('postfolio-seed:' || p_key)::uuid;
$$;

CREATE OR REPLACE FUNCTION seed.customer(
  p_key text,
  p_name text,
  p_notes text,
  p_phone text DEFAULT NULL,
  p_address text DEFAULT NULL,
  p_dob date DEFAULT NULL,
  p_cif text DEFAULT NULL,
  p_aadhaar text DEFAULT NULL,
  p_pan text DEFAULT NULL,
  p_email text DEFAULT NULL,
  p_agent uuid DEFAULT seed.agent()
) RETURNS void LANGUAGE sql AS $$
  INSERT INTO public.customers (
    id, agent_id, name, phone, email, address, cif_number, aadhaar_number, pan_number,
    date_of_birth, notes
  ) VALUES (
    seed.id('customer:' || p_key), p_agent, p_name, p_phone, p_email, p_address, p_cif,
    p_aadhaar, p_pan, p_dob, p_notes
  );
$$;

-- A 5-year recurring deposit. `p_key` names the account and, unless `p_customer` is given,
-- the customer who holds it. The serial number also ends the account number.
-- A start day up to the 15th makes installments due on the 15th; a later one, at month end.
-- `p_baseline` installments were paid and deposited before the agent started using the app.
CREATE OR REPLACE FUNCTION seed.rd(
  p_key text,
  p_serial int,
  p_amount numeric,
  p_start date,
  p_baseline int,
  p_customer text DEFAULT NULL,
  p_status text DEFAULT 'active',
  p_rate numeric DEFAULT 6.7,
  p_opening_receivable numeric DEFAULT 0,
  p_agent uuid DEFAULT seed.agent(),
  p_prefix text DEFAULT '02000100'
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
  VALUES (
    seed.id('rd:' || p_key), seed.id('customer:' || COALESCE(p_customer, p_key)),
    p_agent, 'RD'
  );
  INSERT INTO public.recurring_deposits (
    id, status, scheme_type, account_no, serial_no, installment_amount, interest_rate,
    term_years, term_months, start_date, initial_paid_installments, opening_receivable
  ) VALUES (
    seed.id('rd:' || p_key), p_status, 'recurringDeposit',
    p_prefix || lpad(p_serial::text, 2, '0'), p_serial::text, p_amount, p_rate,
    5, 0, p_start, p_baseline, p_opening_receivable
  );
END;
$$;

-- A one-time deposit: timeDeposit, monthlyIncomeScheme, nationalSavingsCertificate or
-- kisanVikasPatra. `p_no` ends the account number.
CREATE OR REPLACE FUNCTION seed.otd(
  p_key text,
  p_customer text,
  p_scheme text,
  p_no int,
  p_principal numeric,
  p_rate numeric,
  p_years int,
  p_months int,
  p_start date,
  p_status text DEFAULT 'active',
  p_agent uuid DEFAULT seed.agent(),
  p_prefix text DEFAULT '03000200'
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
  VALUES (seed.id('otd:' || p_key), seed.id('customer:' || p_customer), p_agent, 'OTD');
  INSERT INTO public.one_time_deposits (
    id, status, scheme_type, account_no, principal_amount, interest_rate, term_years,
    term_months, start_date
  ) VALUES (
    seed.id('otd:' || p_key), p_status, p_scheme, p_prefix || lpad(p_no::text, 2, '0'),
    p_principal, p_rate, p_years, p_months, p_start
  );
END;
$$;

-- The customer paid `p_amount` towards the account on `p_on`.
CREATE OR REPLACE FUNCTION seed.collect(
  p_rd text,
  p_on date,
  p_amount numeric,
  p_mode text DEFAULT 'cash',
  p_agent uuid DEFAULT seed.agent()
) RETURNS void LANGUAGE sql AS $$
  INSERT INTO public.rd_transactions (id, rd_id, agent_id, paid_date, amount, payment_mode)
  VALUES (
    seed.id('tx:' || p_rd || ':' || p_on), seed.id('rd:' || p_rd), p_agent, p_on,
    p_amount, p_mode
  );
$$;

-- The account's next `p_count` installments were deposited at the Post Office on `p_on`;
-- `p_fee` is the default fee the counter charged on top.
CREATE OR REPLACE FUNCTION seed.deposit(
  p_rd text,
  p_on date,
  p_count int DEFAULT 1,
  p_fee numeric DEFAULT 0,
  p_agent uuid DEFAULT seed.agent()
) RETURNS void LANGUAGE sql AS $$
  INSERT INTO public.rd_po_deposits (
    id, rd_id, agent_id, deposited_on, installment_count, fee_paid, amount
  )
  SELECT
    seed.id('po:' || p_rd || ':' || p_on), d.id, p_agent, p_on, p_count, p_fee,
    d.installment_amount * p_count + p_fee
  FROM public.recurring_deposits d
  WHERE d.id = seed.id('rd:' || p_rd);
$$;

-- Each month from `p_from` months ago to `p_to` months ago (0 = this month): the customer
-- paid the installment before it was due, and it was deposited two or three days later.
CREATE OR REPLACE FUNCTION seed.on_time(
  p_rd text,
  p_from int,
  p_to int,
  p_mode text DEFAULT 'cash',
  p_agent uuid DEFAULT seed.agent()
) RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_rd public.recurring_deposits%ROWTYPE;
  v_due_on_15th boolean;
BEGIN
  SELECT * INTO STRICT v_rd FROM public.recurring_deposits WHERE id = seed.id('rd:' || p_rd);
  v_due_on_15th := EXTRACT(day FROM v_rd.start_date) <= 15;
  FOR m IN REVERSE p_from..p_to LOOP
    PERFORM seed.collect(
      p_rd, seed.dt(m, CASE WHEN v_due_on_15th THEN 5 ELSE 20 END), v_rd.installment_amount,
      p_mode, p_agent
    );
    PERFORM seed.deposit(
      p_rd, seed.dt(m, CASE WHEN v_due_on_15th THEN 8 ELSE 22 END), 1, 0, p_agent
    );
  END LOOP;
END;
$$;

-- The agent bore `p_amount` of the default fee on the installment of the month of `p_on`.
CREATE OR REPLACE FUNCTION seed.absorb(
  p_rd text,
  p_on date,
  p_amount numeric,
  p_note text,
  p_agent uuid DEFAULT seed.agent()
) RETURNS void LANGUAGE sql AS $$
  INSERT INTO public.rd_fee_absorptions (rd_id, agent_id, installment_no, amount, absorbed_on, note)
  SELECT
    d.id, p_agent,
    (
      (EXTRACT(year FROM p_on) - EXTRACT(year FROM d.start_date)) * 12
      + (EXTRACT(month FROM p_on) - EXTRACT(month FROM d.start_date)) + 1
    )::int,
    p_amount, p_on, p_note
  FROM public.recurring_deposits d
  WHERE d.id = seed.id('rd:' || p_rd);
$$;

-- ---------------------------------------------------------------------------------------
-- 3. Primary Agent (Jim Gordon): Monthly Hub & Ledger Intermediate States (1–13)
-- ---------------------------------------------------------------------------------------

-- 1. In hand, cash: collected this month, ready to deposit at the PO.
SELECT seed.customer(
  'alfred', 'Alfred Pennyworth',
  'Collects household cash on the 3rd; prefers receipt slip for Wayne Manor records.',
  '9845012301', '1007 Mountain Drive, Bristol, Gotham 400001', '1958-04-02', '100200301', '412398760011', 'APENP1234A',
  'alfred.pennyworth@wayne.example'
);
SELECT seed.rd('alfred', 1, 5000, seed.dt(9, 5), 7);
SELECT seed.on_time('alfred', 2, 1);
SELECT seed.collect('alfred', seed.dt(0, 3), 5000, 'cash');

-- 2. One month in arrears: last month unpaid, with default fee.
SELECT seed.customer(
  'arthur', 'Arthur Curry',
  'Frequently offshore near Amnesty Bay; remind via call when an installment slips past the 15th.',
  '9845012302', 'Lighthouse Point, Amnesty Bay 576201', '1982-01-29', '100200302', '412398760022', 'ACURC2345B'
);
SELECT seed.rd('arthur', 2, 2500, seed.dt(11, 7), 8);
SELECT seed.on_time('arthur', 3, 2);

-- 3. Part paid: 2,500 of 4,000 received this month; due at month end.
SELECT seed.customer(
  'barbara', 'Barbara Gordon',
  'Splits monthly RD in two parts around Burnside library payroll.',
  '9845012303', '42 Clock Tower Lane, Burnside, Gotham 575001', '1991-09-23', '100200303', '412398760033', 'BGORG3456C'
);
SELECT seed.rd('barbara', 3, 4000, seed.dt(30, 20), 28);
SELECT seed.on_time('barbara', 2, 1);
SELECT seed.collect('barbara', seed.dt(0, 2), 2500, 'cash');

-- 4. Advance paid (+2 months ahead): settled through thisMonth + 2 via UPI.
SELECT seed.customer(
  'barry', 'Barry Allen',
  'Always pays two months ahead via UPI so he never misses a due date during CCPD lab shifts.',
  '9845012304', '112 Speedway Ave, Central City 581401', '1992-03-14', '100200304', '412398760044', 'BALLA4567D',
  'barry.allen@ccpd.example'
);
SELECT seed.rd('barry', 4, 2000, seed.dt(14, 10), 11);
SELECT seed.on_time('barry', 3, 1, 'upi');
SELECT seed.collect('barry', seed.dt(0, 1), 6000, 'upi');
SELECT seed.deposit('barry', seed.dt(0, 2), 3);

-- 5. Household with many accounts: 2 RDs (settled + due month-end), all 4 OTD schemes
--    across 4+ financial years, and Savings Bank with 3 nominees.
SELECT seed.customer(
  'bruce', 'Bruce Wayne',
  'Multi-scheme family portfolio across Wayne Manor; quarterly review with Alfred.',
  '9845012305', 'Wayne Manor, 1007 Mountain Drive, Gotham 581402', '1978-02-19', '100200305', '412398760055', 'BWAYW5678E',
  'bruce.wayne@wayne.example'
);
SELECT seed.rd('bruce-a', 5, 5000, seed.dt(20, 10), 18, 'bruce');
SELECT seed.on_time('bruce-a', 2, 0);
SELECT seed.rd('bruce-b', 6, 1500, seed.dt(7, 22), 5, 'bruce');
SELECT seed.on_time('bruce-b', 2, 1);
SELECT seed.otd('bruce-td2', 'bruce', 'timeDeposit', 1, 200000, 7.0, 2, 0, seed.dt(14, 12));
SELECT seed.otd('bruce-td5', 'bruce', 'timeDeposit', 2, 500000, 7.5, 5, 0, seed.dt(38, 12));
SELECT seed.otd('bruce-mis', 'bruce', 'monthlyIncomeScheme', 3, 900000, 7.4, 5, 0, seed.dt(30, 6));
SELECT seed.otd('bruce-nsc', 'bruce', 'nationalSavingsCertificate', 4, 150000, 7.7, 5, 0, seed.dt(18, 21));
SELECT seed.otd('bruce-kvp', 'bruce', 'kisanVikasPatra', 5, 100000, 7.5, 9, 7, seed.dt(8, 3));

INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
VALUES (seed.id('sb:bruce'), seed.id('customer:bruce'), seed.agent(), 'SB');
INSERT INTO public.savings_accounts (id, account_number, linked_date)
VALUES (seed.id('sb:bruce'), '0100030017', seed.dt(40, 4));

-- 6. Rich Year-1 passbook showcase (0 baseline): settled + absorbed fee + UPI in hand.
SELECT seed.customer(
  'clark', 'Clark Kent',
  'Daily Planet reporter; transfers every month via UPI and checks his passbook closely.',
  '9845012306', '344 Clinton Street, Apt 3B, Metropolis 576101', '1984-02-29', '100200306', '412398760066', 'CKEPK6789F',
  'clark.kent@planet.example'
);
SELECT seed.rd('clark', 7, 3000, seed.dt(7, 10), 0);
SELECT seed.on_time('clark', 7, 4, 'upi');
SELECT seed.collect('clark', seed.dt(3, 16), 3000, 'upi');
SELECT seed.deposit('clark', seed.dt(3, 18), 1, 30);
SELECT seed.absorb('clark', seed.dt(3, 18), 30, 'Smallville storm delay; fee covered');
SELECT seed.on_time('clark', 2, 1, 'upi');
SELECT seed.collect('clark', seed.dt(0, 4), 3000, 'upi');

-- 7. Large cash in hand (with Alfred > 20,000 -> 2 PO cash lots) + maturing-soon MIS (15d).
SELECT seed.customer(
  'diana', 'Diana Prince',
  'Curator at Themyscira Antiquities Wing; brings large cash installments in person.',
  '9845012307', '7 Embassy Row, Gateway City 580020', '1975-03-22', '100200307', '412398760077', 'DPRPP7890G',
  'diana.prince@themyscira.example'
);
SELECT seed.rd('diana', 8, 18000, seed.dt(5, 8), 3);
SELECT seed.on_time('diana', 2, 1);
SELECT seed.collect('diana', seed.dt(0, 2), 18000, 'cash');
SELECT seed.otd('diana-mis', 'diana', 'monthlyIncomeScheme', 6, 450000, 6.6, 5, 0, (seed.today() + 15 - interval '60 months')::date);

-- 8. In hand via bankTransfer + maturing-soon KVP (25d).
SELECT seed.customer(
  'edward', 'Edward Nygma',
  'Sends exact installments via bank transfer; tracks maturity dates to the day.',
  '9845012308', '1404 Riddle Arcade, Midtown Gotham 580001', '1983-06-15', '100200308', '412398760088', 'ENYPN8901H'
);
SELECT seed.rd('edward', 9, 3500, seed.dt(16, 12), 14);
SELECT seed.on_time('edward', 2, 1, 'bankTransfer');
SELECT seed.collect('edward', seed.dt(0, 4), 3500, 'bankTransfer');
SELECT seed.otd('edward-kvp', 'edward', 'kisanVikasPatra', 7, 100000, 7.5, 9, 7, (seed.today() + 25 - interval '115 months')::date);

-- 9. Fronted by agent (2,000 receivable) + active 5Y NSC.
SELECT seed.customer(
  'hal', 'Hal Jordan',
  'Test pilot at Ferris Aircraft; agent fronts RD when he is away on sector duty.',
  '9845012309', 'Hangar 7, Coast City 577201', '1981-02-20', '100200309', '412398760099', 'HJOPJ9012I'
);
SELECT seed.rd('hal', 10, 2000, seed.dt(40, 14), 38);
SELECT seed.on_time('hal', 2, 1);
SELECT seed.deposit('hal', seed.dt(0, 2));
SELECT seed.otd('hal-nsc', 'hal', 'nationalSavingsCertificate', 8, 75000, 7.7, 5, 0, seed.dt(51, 15));

-- 10. Caught up: 2 months missed, then 3 installments + 30 fees paid & deposited at once.
SELECT seed.customer(
  'harleen', 'Harleen Quinzel',
  'Cleared three missed months plus default fees in one visit this month.',
  '9845012310', '19 Amusement Mile, Gotham 575001', '1990-07-20', '100200310', '412398760110', 'HQUPQ0123J'
);
SELECT seed.rd('harleen', 11, 1000, seed.dt(8, 10), 5);
SELECT seed.on_time('harleen', 3, 3);
SELECT seed.collect('harleen', seed.dt(0, 2), 3030, 'cash');
SELECT seed.deposit('harleen', seed.dt(0, 3), 3, 30);

-- 11. Three to four months in arrears (near 4-default discontinuation threshold).
SELECT seed.customer(
  'harvey', 'Harvey Dent',
  'Three to four months overdue; follow up urgently before RD discontinuation threshold.',
  '9845012311', '50 Courthouse Square, Gotham 571401', '1977-11-11', '100200311', '412398760121', 'HDEPD1234K'
);
SELECT seed.rd('harvey', 12, 1500, seed.dt(26, 3), 22);
SELECT seed.on_time('harvey', 4, 4);

-- 12. Part-paid + prior arrears: last month overdue, 1,000 paid toward 2,020 due.
SELECT seed.customer(
  'jason', 'Jason Todd',
  'Made a partial cash payment toward last month arrears; balance still due.',
  '9845012312', '88 Crime Alley, Park Row, Gotham 585401', '1994-08-16', '100200312', '412398760132', 'JTOPT2345L'
);
SELECT seed.rd('jason', 13, 2000, seed.dt(15, 10), 12);
SELECT seed.on_time('jason', 3, 2);
SELECT seed.collect('jason', seed.dt(0, 3), 1000, 'cash');

-- 13. Absorbed fee on an older account: late 3 months ago; agent bore 50 fee; settled now.
SELECT seed.customer(
  'constantine', 'John Constantine',
  'Late transfer three months ago from London; agent absorbed the 50 rupee counter fee.',
  '9845012313', '13 Mucous Membrane Lane, Gotham 590001', '1976-05-10', '100200313', '412398760143', 'JCOPC3456M'
);
SELECT seed.rd('constantine', 14, 5000, seed.dt(18, 9), 14);
SELECT seed.on_time('constantine', 4, 4);
SELECT seed.collect('constantine', seed.dt(3, 16), 5000, 'upi');
SELECT seed.deposit('constantine', seed.dt(3, 18), 1, 50);
SELECT seed.absorb('constantine', seed.dt(3, 18), 50, 'Late transfer from London; fee absorbed');
SELECT seed.on_time('constantine', 2, 0);

-- ---------------------------------------------------------------------------------------
-- 4. Account Lifecycle & Customer Shape (14–22)
-- ---------------------------------------------------------------------------------------

-- 14. Brand new RD opened on the 1st of this month + active 1Y Time Deposit.
SELECT seed.customer(
  'kara', 'Kara Zor-El',
  'Newly opened RD on the 1st of this month alongside a 1-year Time Deposit.',
  '9845012314', '14 Midvale Terrace, National City 560001', '1995-09-22', '100200314', '412398760154', 'KZOPZ4567N'
);
SELECT seed.rd('kara', 15, 500, seed.dt(0, 1), 0);
SELECT seed.collect('kara', seed.dt(0, 1), 500, 'cash');
SELECT seed.deposit('kara', seed.dt(0, 1));
SELECT seed.otd('kara-td1', 'kara', 'timeDeposit', 9, 100000, 6.9, 1, 0, seed.dt(4, 10));

-- 15. Long name (>50 chars) + unpaid this month (due month-end).
SELECT seed.customer(
  'koriandr', 'Koriand''r of Tamaran, Royal Sovereign of the Vega System',
  'Titans Tower portfolio; prefers month-end reminder for her recurring deposit.',
  '9845012315', 'Titans Tower, Jump City Bay 560087', '1993-04-18', '100200315', '412398760165', 'KTAPK5678O'
);
SELECT seed.rd('koriandr', 16, 500, seed.dt(6, 18), 4);
SELECT seed.on_time('koriandr', 2, 1);

-- 16. Brought into app late: 36 baseline + 10,000 opening receivable + MIS + 3Y TD.
SELECT seed.customer(
  'lex', 'Lex Luthor',
  'Transferred 3-year RD into Postfolio with 10,000 opening receivable plus corporate deposits.',
  '9845012316', 'LexCorp Tower, 1000 Main Street, Metropolis 560003', '1973-01-15', '100200316', '412398760176', 'LLUPL6789P'
);
SELECT seed.rd('lex', 17, 10000, seed.dt(36, 20), 36, p_opening_receivable => 10000);
SELECT seed.otd('lex-mis', 'lex', 'monthlyIncomeScheme', 10, 600000, 7.4, 5, 0, seed.dt(55, 5));
SELECT seed.otd('lex-td3', 'lex', 'timeDeposit', 11, 300000, 7.1, 3, 0, seed.dt(26, 12));

-- 17. To collect (due month-end, up to date through last month) + active 5Y NSC.
SELECT seed.customer(
  'lois', 'Lois Lane',
  'Pays at month-end after Daily Planet column deadline; up to date through last month.',
  '9845012317', '344 Clinton Street, Apt 3B, Metropolis 585401', '1985-08-17', '100200317', '412398760187', 'LLAPL7890Q'
);
SELECT seed.rd('lois', 18, 1000, seed.dt(17, 25), 15);
SELECT seed.on_time('lois', 2, 1);
SELECT seed.otd('lois-nsc', 'lois', 'nationalSavingsCertificate', 12, 125000, 7.7, 5, 0, seed.dt(10, 14));

-- 18. Maturing soon: RD and 1Y TD, both 20 days from maturity.
SELECT seed.customer(
  'oliver', 'Oliver Queen',
  'Both RD and 1-year Time Deposit mature in 20 days; prepare renewal forms.',
  '9845012318', 'Queen Consolidated Plaza, Star City 581301', '1979-05-16', '100200318', '412398760198', 'OQUPO8901R'
);
SELECT seed.rd('oliver', 19, 1000, (seed.today() + 20 - interval '60 months')::date, 60, p_rate => 5.8);
SELECT seed.otd('oliver-td1', 'oliver', 'timeDeposit', 13, 50000, 6.9, 1, 0, (seed.today() + 20 - interval '1 year')::date);

-- 19. Matured, still open: RD and NSC, both 40 days past maturity.
SELECT seed.customer(
  'oswald', 'Oswald Cobblepot',
  'Matured RD and NSC still open past maturity; pending payout instructions from Iceberg Lounge.',
  '9845012319', 'The Iceberg Lounge, Pier 14, Gotham 575002', '1961-12-30', '100200319', '412398760209', 'OCOPC9012S'
);
SELECT seed.rd('oswald', 20, 2000, (seed.today() - 40 - interval '60 months')::date, 60, p_rate => 5.8);
SELECT seed.otd('oswald-nsc', 'oswald', 'nationalSavingsCertificate', 14, 25000, 6.8, 5, 0, (seed.today() - 40 - interval '5 years')::date);

-- 20. Closed: RD, 2Y TD, and 5Y MIS all closed.
SELECT seed.customer(
  'pamela', 'Pamela Isley',
  'Closed her matured RD, 2-year TD, and 5-year MIS after relocating to Robinson Park Conservatory.',
  '9845012320', 'Greenhouse 4, Robinson Park, Gotham 560010', '1980-05-22', '100200320', '412398760220', 'PISPI0123T'
);
SELECT seed.rd('pamela', 21, 3000, seed.dt(66, 10), 60, p_status => 'closed', p_rate => 5.8);
SELECT seed.otd('pamela-td2', 'pamela', 'timeDeposit', 15, 100000, 7.0, 2, 0, seed.dt(27, 14), 'closed');
SELECT seed.otd('pamela-mis', 'pamela', 'monthlyIncomeScheme', 16, 300000, 6.6, 5, 0, seed.dt(64, 8), 'closed');

-- 21. Name only: every optional KYC field empty; one 1,000 rupee KVP with no nominee.
SELECT seed.customer(
  'selina', 'Selina Kyle',
  'Minimal profile — prefers privacy; small KVP with no nominee listed.'
);
SELECT seed.otd('selina-kvp', 'selina', 'kisanVikasPatra', 17, 1000, 7.5, 9, 7, seed.dt(102, 5));

-- 22. No account at all: empty sections, and deleting is allowed.
SELECT seed.customer(
  'victor', 'Victor Stone',
  'Newly onboarded at S.T.A.R. Labs; no deposits linked yet.',
  '9845012322', 'S.T.A.R. Labs Campus, Metropolis 560025', '1997-06-29'
);

-- ---------------------------------------------------------------------------------------
-- 5. Nominees for Primary Agent (PascalCase relationship tokens)
-- ---------------------------------------------------------------------------------------
INSERT INTO public.nominees (account_id, name, relationship, percentage)
VALUES
  (seed.id('rd:alfred'), 'Julia Pennyworth', 'Daughter', 100),
  (seed.id('rd:arthur'), 'Mera Curry', 'Wife', 100),
  (seed.id('rd:barbara'), 'James Gordon', 'Father', 100),
  (seed.id('rd:barry'), 'Iris West-Allen', 'Wife', 100),
  (seed.id('sb:bruce'), 'Dick Grayson', 'Son', 33.34),
  (seed.id('sb:bruce'), 'Damian Wayne', 'Son', 33.33),
  (seed.id('sb:bruce'), 'Cassandra Cain', 'Daughter', 33.33),
  (seed.id('rd:bruce-a'), 'Dick Grayson', 'Son', 100),
  (seed.id('rd:bruce-b'), 'Damian Wayne', 'Son', 100),
  (seed.id('otd:bruce-td2'), 'Dick Grayson', 'Son', 100),
  (seed.id('otd:bruce-td5'), 'Cassandra Cain', 'Daughter', 100),
  (seed.id('otd:bruce-mis'), 'Dick Grayson', 'Son', 100),
  (seed.id('otd:bruce-nsc'), 'Damian Wayne', 'Son', 50),
  (seed.id('otd:bruce-nsc'), 'Cassandra Cain', 'Daughter', 50),
  (seed.id('otd:bruce-kvp'), 'Dick Grayson', 'Son', 100),
  (seed.id('rd:clark'), 'Lois Lane', 'Wife', 100),
  (seed.id('rd:diana'), 'Hippolyta', 'Mother', 60),
  (seed.id('rd:diana'), 'Donna Troy', 'Sister', 40),
  (seed.id('otd:diana-mis'), 'Hippolyta', 'Mother', 100),
  (seed.id('rd:edward'), 'Kristen Kringle', 'Wife', 100),
  (seed.id('otd:edward-kvp'), 'Kristen Kringle', 'Wife', 100),
  (seed.id('rd:hal'), 'Carol Ferris', 'Wife', 50),
  (seed.id('rd:hal'), 'Jim Jordan', 'Brother', 50),
  (seed.id('otd:hal-nsc'), 'Carol Ferris', 'Wife', 100),
  (seed.id('rd:harleen'), 'Pamela Isley', 'Sister', 100),
  (seed.id('rd:harvey'), 'Gilda Dent', 'Wife', 100),
  (seed.id('rd:jason'), 'Bruce Wayne', 'Father', 100),
  (seed.id('rd:constantine'), 'Chas Chandler', 'Brother', 100),
  (seed.id('rd:kara'), 'Alex Danvers', 'Sister', 100),
  (seed.id('otd:kara-td1'), 'Alex Danvers', 'Sister', 100),
  (seed.id('rd:koriandr'), 'Komand''r of Tamaran', 'Sister', 100),
  (seed.id('rd:lex'), 'Lena Luthor', 'Sister', 100),
  (seed.id('otd:lex-mis'), 'Lena Luthor', 'Sister', 100),
  (seed.id('otd:lex-td3'), 'Lena Luthor', 'Sister', 100),
  (seed.id('rd:lois'), 'Clark Kent', 'Husband', 100),
  (seed.id('otd:lois-nsc'), 'Clark Kent', 'Husband', 100),
  (seed.id('rd:oliver'), 'Dinah Lance', 'Wife', 100),
  (seed.id('otd:oliver-td1'), 'Dinah Lance', 'Wife', 100),
  (seed.id('rd:oswald'), 'Esther Cobblepot', 'Mother', 100),
  (seed.id('otd:oswald-nsc'), 'Esther Cobblepot', 'Mother', 100),
  (seed.id('rd:pamela'), 'Harleen Quinzel', 'Sister', 100),
  (seed.id('otd:pamela-td2'), 'Harleen Quinzel', 'Sister', 100),
  (seed.id('otd:pamela-mis'), 'Harleen Quinzel', 'Sister', 100);

-- ---------------------------------------------------------------------------------------
-- 6. Secondary Agents for Local Admin Acting-As Testing
-- ---------------------------------------------------------------------------------------

-- Lucius Fox (8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e): 3 customers, 2 RDs, 2 OTDs
SELECT seed.customer(
  'lucius:kate', 'Kate Kane',
  'Wayne Tower security consultant; monthly RD paid in cash.',
  '9845022301', '14 Kane Plaza, Gotham 400002', '1986-01-26', '200200301', '512398760011', 'KKANK1234A',
  NULL, '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e'::uuid
);
SELECT seed.rd('lucius:kate', 1, 3000, seed.dt(8, 10), 6, 'lucius:kate', 'active', 6.7, 0, '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e'::uuid, '02000200');
SELECT seed.on_time('lucius:kate', 1, 1, 'cash', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e'::uuid);
SELECT seed.collect('lucius:kate', seed.dt(0, 3), 3000, 'cash', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e'::uuid);
SELECT seed.otd('lucius:kate-kvp', 'lucius:kate', 'kisanVikasPatra', 1, 50000, 7.5, 9, 7, seed.dt(12, 5), 'active', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e'::uuid, '03000300');

SELECT seed.customer(
  'lucius:luke', 'Luke Fox',
  'WayneTech R&D lead; last month installment still pending.',
  '9845022302', 'Fox Residence, Bristol, Gotham 400003', '1991-06-15', '200200302', '512398760022', 'LFOXF2345B',
  NULL, '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e'::uuid
);
SELECT seed.rd('lucius:luke', 2, 2000, seed.dt(10, 7), 7, 'lucius:luke', 'active', 6.7, 0, '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e'::uuid, '02000200');
SELECT seed.on_time('lucius:luke', 2, 2, 'upi', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e'::uuid);

SELECT seed.customer(
  'lucius:renee', 'Renee Montoya',
  'GCPD Major Crimes unit; holds a 5-year Monthly Income Scheme.',
  '9845022303', '92 East End Ave, Gotham 400004', '1983-10-12', '200200303', '512398760033', 'RMOPM3456C',
  NULL, '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e'::uuid
);
SELECT seed.otd('lucius:renee-mis', 'lucius:renee', 'monthlyIncomeScheme', 2, 300000, 7.4, 5, 0, seed.dt(18, 9), 'active', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e'::uuid, '03000300');

INSERT INTO public.nominees (account_id, name, relationship, percentage)
VALUES
  (seed.id('rd:lucius:kate'), 'Jacob Kane', 'Father', 100),
  (seed.id('otd:lucius:kate-kvp'), 'Jacob Kane', 'Father', 100),
  (seed.id('rd:lucius:luke'), 'Lucius Fox', 'Father', 100),
  (seed.id('otd:lucius:renee-mis'), 'Hernando Montoya', 'Brother', 100);

-- Perry White (8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f): 2 customers, 1 RD, 2 OTDs
SELECT seed.customer(
  'perry:jimmy', 'Jimmy Olsen',
  'Daily Planet photojournalist; settled RD and 5-year NSC.',
  '9845032301', '21 Bakerline St, Metropolis 500001', '1996-05-03', '300200301', '612398760011', 'JOLPO1234A',
  NULL, '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f'::uuid
);
SELECT seed.rd('perry:jimmy', 1, 1500, seed.dt(6, 10), 4, 'perry:jimmy', 'active', 6.7, 0, '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f'::uuid, '02000300');
SELECT seed.on_time('perry:jimmy', 1, 0, 'upi', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f'::uuid);
SELECT seed.otd('perry:jimmy-nsc', 'perry:jimmy', 'nationalSavingsCertificate', 1, 50000, 7.7, 5, 0, seed.dt(14, 15), 'active', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f'::uuid, '03000400');

SELECT seed.customer(
  'perry:cat', 'Cat Grant',
  'CatCo Media founder; holds a 3-year Time Deposit.',
  '9845032302', 'CatCo Plaza, Suite 400, National City 500002', '1984-11-28', '300200302', '612398760022', 'CGRPG2345B',
  NULL, '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f'::uuid
);
SELECT seed.otd('perry:cat-td3', 'perry:cat', 'timeDeposit', 2, 200000, 7.1, 3, 0, seed.dt(9, 20), 'active', '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f'::uuid, '03000400');

INSERT INTO public.nominees (account_id, name, relationship, percentage)
VALUES
  (seed.id('rd:perry:jimmy'), 'Sarah Olsen', 'Mother', 100),
  (seed.id('otd:perry:jimmy-nsc'), 'Sarah Olsen', 'Mother', 100),
  (seed.id('otd:perry:cat-td3'), 'Adam Grant', 'Son', 100);

DROP SCHEMA seed CASCADE;

-- ---------------------------------------------------------------------------------------
-- 7. Handing the seed data to another agent
--
-- "Sign in as seeded agent" on the login screen (local builds only) signs in as the primary
-- seeded agent above (Jim Gordon). If you sign in with Google instead, the first such
-- sign-in takes over the primary seed portfolio (section 8) and receives the 'admin' role
-- so Lucius Fox and Perry White remain available under Switch Account.
-- To hand it to a particular account by hand:
--   docker exec supabase_db_postfolio psql -U postgres -d postgres \
--     -c "SELECT public.adopt_seed_data('you@example.com');"
-- Local only.
-- ---------------------------------------------------------------------------------------
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
  INSERT INTO public.user_roles (user_id, role)
  VALUES (v_target, 'admin')
  ON CONFLICT (user_id, role) DO NOTHING;
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

-- ---------------------------------------------------------------------------------------
-- 8. The FIRST real agent to sign in (e.g. your Google account) takes over the primary seed
--    portfolio. Throwaway test agents (`*@example.com`) and the three seeded agents are
--    ignored, so they never take the seed data and then cascade-delete it.
-- ---------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_seed_adoption()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.id NOT IN (
       '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d',
       '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71e',
       '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71f'
     )
     AND COALESCE(NEW.email, '') NOT ILIKE '%@example.com'
     AND EXISTS (SELECT 1 FROM public.customers WHERE agent_id = '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d') THEN
    PERFORM public.adopt_seed_data_for(NEW.id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trigger_seed_adoption
  AFTER INSERT ON public.agent_profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_seed_adoption();
