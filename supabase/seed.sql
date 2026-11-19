-- Seed data for the LOCAL Supabase stack. `supabase db reset` runs this after the migrations.
-- The hosted database never sees this file.
--
-- One seeded agent (agent@postfolio.com / password123) with 21 customers. Each customer is
-- there to show one situation in the app; the customer's Notes field says which. First
-- names run A to U in the order below, then one customer whose name is written in Kannada.
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

-- ---------------------------------------------------------------------------------------
-- 1. The seeded agent (auth user, identity, profile)
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

-- public.agent_profiles is filled by the on_auth_user_created trigger.
UPDATE public.agent_profiles
SET agency_code = 'POST-001'
WHERE id = '8ffb99b0-9276-4dc0-9cf6-0a563fc8a71d';

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

-- A stable id for a named row, e.g. seed.id('customer:asha') or seed.id('rd:asha').
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
  p_email text DEFAULT NULL
) RETURNS void LANGUAGE sql AS $$
  INSERT INTO public.customers (
    id, agent_id, name, phone, email, address, cif_number, aadhaar_number, pan_number,
    date_of_birth, notes
  ) VALUES (
    seed.id('customer:' || p_key), seed.agent(), p_name, p_phone, p_email, p_address, p_cif,
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
  p_opening_receivable numeric DEFAULT 0
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
  VALUES (
    seed.id('rd:' || p_key), seed.id('customer:' || COALESCE(p_customer, p_key)),
    seed.agent(), 'RD'
  );
  INSERT INTO public.recurring_deposits (
    id, status, scheme_type, account_no, serial_no, installment_amount, interest_rate,
    term_years, term_months, start_date, initial_paid_installments, opening_receivable
  ) VALUES (
    seed.id('rd:' || p_key), p_status, 'recurringDeposit',
    '02000100' || lpad(p_serial::text, 2, '0'), p_serial::text, p_amount, p_rate,
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
  p_status text DEFAULT 'active'
) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
  VALUES (seed.id('otd:' || p_key), seed.id('customer:' || p_customer), seed.agent(), 'OTD');
  INSERT INTO public.one_time_deposits (
    id, status, scheme_type, account_no, principal_amount, interest_rate, term_years,
    term_months, start_date
  ) VALUES (
    seed.id('otd:' || p_key), p_status, p_scheme, '03000200' || lpad(p_no::text, 2, '0'),
    p_principal, p_rate, p_years, p_months, p_start
  );
END;
$$;

-- The customer paid `p_amount` towards the account on `p_on`.
CREATE OR REPLACE FUNCTION seed.collect(
  p_rd text,
  p_on date,
  p_amount numeric,
  p_mode text DEFAULT 'cash'
) RETURNS void LANGUAGE sql AS $$
  INSERT INTO public.rd_transactions (id, rd_id, agent_id, paid_date, amount, payment_mode)
  VALUES (
    seed.id('tx:' || p_rd || ':' || p_on), seed.id('rd:' || p_rd), seed.agent(), p_on,
    p_amount, p_mode
  );
$$;

-- The account's next `p_count` installments were deposited at the Post Office on `p_on`;
-- `p_fee` is the default fee the counter charged on top.
CREATE OR REPLACE FUNCTION seed.deposit(
  p_rd text,
  p_on date,
  p_count int DEFAULT 1,
  p_fee numeric DEFAULT 0
) RETURNS void LANGUAGE sql AS $$
  INSERT INTO public.rd_po_deposits (
    id, rd_id, agent_id, deposited_on, installment_count, fee_paid, amount
  )
  SELECT
    seed.id('po:' || p_rd || ':' || p_on), d.id, seed.agent(), p_on, p_count, p_fee,
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
  p_mode text DEFAULT 'cash'
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
      p_mode
    );
    PERFORM seed.deposit(p_rd, seed.dt(m, CASE WHEN v_due_on_15th THEN 8 ELSE 22 END));
  END LOOP;
END;
$$;

-- The agent bore `p_amount` of the default fee on the installment of the month of `p_on`.
CREATE OR REPLACE FUNCTION seed.absorb(
  p_rd text,
  p_on date,
  p_amount numeric,
  p_note text
) RETURNS void LANGUAGE sql AS $$
  INSERT INTO public.rd_fee_absorptions (rd_id, agent_id, installment_no, amount, absorbed_on, note)
  SELECT
    d.id, seed.agent(),
    (
      (EXTRACT(year FROM p_on) - EXTRACT(year FROM d.start_date)) * 12
      + (EXTRACT(month FROM p_on) - EXTRACT(month FROM d.start_date)) + 1
    )::int,
    p_amount, p_on, p_note
  FROM public.recurring_deposits d
  WHERE d.id = seed.id('rd:' || p_rd);
$$;

-- ---------------------------------------------------------------------------------------
-- 3. Monthly Hub: what this month looks like
--
-- seed.rd(key, serial, amount, start, baseline): an account that started N months ago has
-- installment N + 1 this month. A baseline of N - k leaves the last k months, and this one,
-- to the facts below.
-- ---------------------------------------------------------------------------------------

-- 1. Settled: paid on time and deposited every month, this month included.
SELECT seed.customer(
  'asha', 'Asha Kulkarni',
  'Seed 1. Recurring deposit paid on time and deposited every month, this month too. Monthly Hub: Settled.',
  '9845012301', '14, Car Street, Sirsi 581401', '1978-03-12', '100200301', '412398760011', 'AKUPK1234A',
  'asha.kulkarni@example.com'
);
SELECT seed.rd('asha', 1, 2000, seed.dt(14, 10), 11);
SELECT seed.on_time('asha', 3, 0);

-- 2. In hand, cash: collected this month, not yet deposited.
SELECT seed.customer(
  'bharat', 'Bharat Shetty',
  'Seed 2. This month collected in cash, not yet deposited. Monthly Hub: In hand, with a Deposit button.',
  '9845012302', '7, Bunder Road, Kundapura 576201', '1969-11-02', '100200302', '412398760022', 'BSHPS2345B'
);
SELECT seed.rd('bharat', 2, 5000, seed.dt(9, 5), 7);
SELECT seed.on_time('bharat', 2, 1);
SELECT seed.collect('bharat', seed.dt(0, 3), 5000, 'cash');

-- 3. In hand, UPI: collected this month by UPI, not yet deposited.
SELECT seed.customer(
  'chitra', 'Chitra Nair',
  'Seed 3. This month collected by UPI, not yet deposited. Post Office visit sheet: UPI total.',
  '9845012303', '22, Temple Road, Udupi 576101', '1985-07-19', '100200303', '412398760033', 'CNAPN3456C'
);
SELECT seed.rd('chitra', 3, 3000, seed.dt(22, 12), 20);
SELECT seed.on_time('chitra', 2, 1, 'upi');
SELECT seed.collect('chitra', seed.dt(0, 4), 3000, 'upi');

-- 4. In hand, a large cash amount: with customer 2 the cash passes 20,000 rupees, so a
--    Post Office visit splits it into two lots.
SELECT seed.customer(
  'dinesh', 'Dinesh Agarwal',
  'Seed 4. 18,000 rupees collected in cash this month. With Bharat Shetty the cash in hand passes 20,000, so the visit sheet shows two cash lots.',
  '9845012304', '3, Market Road, Hubballi 580020', '1972-01-25', '100200304', '412398760044', 'DAGPA4567D'
);
SELECT seed.rd('dinesh', 4, 18000, seed.dt(5, 8), 3);
SELECT seed.on_time('dinesh', 2, 1);
SELECT seed.collect('dinesh', seed.dt(0, 2), 18000, 'cash');

-- 5. Part paid: 2,500 of 4,000 rupees received this month. Due at month end, so no default
--    fee is added during the month and 1,500 stays owed.
SELECT seed.customer(
  'esha', 'Esha Fernandes',
  'Seed 5. 2,500 of this month''s 4,000 rupees received. Monthly Hub: part paid, 1,500 still owed.',
  '9845012305', '9, Church Lane, Mangaluru 575001', '1990-05-30', '100200305', '412398760055', 'EFEPF5678E'
);
SELECT seed.rd('esha', 5, 4000, seed.dt(30, 20), 28);
SELECT seed.on_time('esha', 2, 1);
SELECT seed.collect('esha', seed.dt(0, 2), 2500, 'cash');

-- 6. To collect: up to date through last month, nothing yet this month. Due at month end:
--    upcoming all month, due today on its last day.
SELECT seed.customer(
  'farhan', 'Farhan Qureshi',
  'Seed 6. Up to date through last month, nothing paid this month. Due at month end: upcoming, then due today on the last day.',
  '9845012306', '41, Fort Road, Bidar 585401', '1981-09-08', '100200306', '412398760066', 'FQUPQ6789F'
);
SELECT seed.rd('farhan', 6, 1000, seed.dt(17, 25), 15);
SELECT seed.on_time('farhan', 2, 1);

-- 7. One month in arrears: last month unpaid, with its default fee; this month unpaid too,
--    and overdue once the 15th has passed.
SELECT seed.customer(
  'gauri', 'Gauri Deshpande',
  'Seed 7. Last month unpaid. The Monthly Hub row carries one month of arrears and its default fee; this month goes overdue after the 15th.',
  '9845012307', '18, Station Road, Dharwad 580001', '1976-12-14', '100200307', '412398760077', 'GDEPD7890G'
);
SELECT seed.rd('gauri', 7, 2500, seed.dt(11, 7), 8);
SELECT seed.on_time('gauri', 3, 2);

-- 8. Three months in arrears: nothing paid or deposited for three months.
SELECT seed.customer(
  'harish', 'Harish Gowda',
  'Seed 8. Nothing paid or deposited for three months. Monthly Hub: Arrears tile and the Overdue filter.',
  '9845012308', '5, Sugar Factory Road, Mandya 571401', '1965-04-03', '100200308', '412398760088', 'HGOPG8901H'
);
SELECT seed.rd('harish', 8, 1500, seed.dt(26, 3), 22);
SELECT seed.on_time('harish', 4, 4);

-- 9. Fronted: the agent deposited this month from their own pocket; the customer has not paid.
SELECT seed.customer(
  'indira', 'Indira Menon',
  'Seed 9. This month deposited from the agent''s pocket; the customer has not paid. Monthly Hub: Fronted filter and the Receivable tile.',
  '9845012309', '12, Lake View Road, Shivamogga 577201', '1958-08-21', '100200309', '412398760099', 'IMEPM9012I'
);
SELECT seed.rd('indira', 9, 2000, seed.dt(40, 14), 38);
SELECT seed.on_time('indira', 2, 1);
SELECT seed.deposit('indira', seed.dt(0, 2));

-- 10. Caught up: two months missed, then three installments and 30 rupees of default fees
--     paid in one go this month, and one Post Office visit depositing all three.
SELECT seed.customer(
  'jayant', 'Jayant Bhat',
  'Seed 10. Missed two months, then paid three installments and 30 rupees of default fees at once this month. One Post Office visit deposited all three.',
  '9845012310', '27, Hampankatta, Mangaluru 575001', '1983-02-17', '100200310', '412398760110', 'JBHPB0123J'
);
SELECT seed.rd('jayant', 10, 1000, seed.dt(8, 10), 5);
SELECT seed.on_time('jayant', 3, 3);
SELECT seed.collect('jayant', seed.dt(0, 2), 3030, 'cash');
SELECT seed.deposit('jayant', seed.dt(0, 3), 3, 30);

-- 11. A fee the agent bore: three months ago the customer paid a day late, the counter
--     charged 50 rupees and the agent absorbed it. Settled since, this month included.
SELECT seed.customer(
  'kavita', 'Kavita Joshi',
  'Seed 11. Paid one day late three months ago; the Post Office charged a 50 rupee default fee and the agent bore it. Settled now.',
  '9845012311', '8, College Road, Belagavi 590001', '1987-10-09', '100200311', '412398760121', 'KJOPJ1234K'
);
SELECT seed.rd('kavita', 11, 5000, seed.dt(18, 9), 14);
SELECT seed.on_time('kavita', 4, 4);
SELECT seed.collect('kavita', seed.dt(3, 16), 5000, 'upi');
SELECT seed.deposit('kavita', seed.dt(3, 18), 1, 50);
SELECT seed.absorb('kavita', seed.dt(3, 18), 50, 'Customer was travelling; one day late');
SELECT seed.on_time('kavita', 2, 0);

-- ---------------------------------------------------------------------------------------
-- 4. Account lifecycle
-- ---------------------------------------------------------------------------------------

-- 12. Brand new: opened on the 1st of this month, first installment paid at opening.
SELECT seed.customer(
  'lalit', 'Lalit Saxena',
  'Seed 12. Recurring deposit opened on the 1st of this month, first installment paid. No history yet.',
  '9845012312', '33, MG Road, Bengaluru 560001', '1995-06-27', '100200312', '412398760132', 'LSAPS2345L'
);
SELECT seed.rd('lalit', 12, 500, seed.dt(0, 1), 0);
SELECT seed.collect('lalit', seed.dt(0, 1), 500, 'cash');
SELECT seed.deposit('lalit', seed.dt(0, 1));

-- 13. Brought into the app late: three years old, 36 installments already paid, and the
--     customer still owed the agent 10,000 rupees on that day.
SELECT seed.customer(
  'meera', 'Meera Iyer',
  'Seed 13. Three-year-old account entered with 36 installments already paid and an opening receivable of 10,000 rupees.',
  '9845012313', '6, Sampige Road, Bengaluru 560003', '1971-01-15', '100200313', '412398760143', 'MIYPI3456M'
);
SELECT seed.rd('meera', 13, 10000, seed.dt(36, 20), 36, p_opening_receivable => 10000);

-- 14. Maturing soon: a recurring deposit and a one-year Time Deposit, both 20 days from maturity.
SELECT seed.customer(
  'naveen', 'Naveen Pillai',
  'Seed 14. A recurring deposit and a one-year Time Deposit that both mature in 20 days: "maturing soon".',
  '9845012314', '19, Beach Road, Karwar 581301', '1962-07-04', '100200314', '412398760154', 'NPIPP4567N'
);
SELECT seed.rd('naveen', 14, 1000, (seed.today() + 20 - interval '60 months')::date, 60, p_rate => 5.8);
SELECT seed.otd('naveen-td', 'naveen', 'timeDeposit', 1, 50000, 6.9, 1, 0, (seed.today() + 20 - interval '1 year')::date);

-- 15. Matured, still open: a recurring deposit and a National Savings Certificate, both
--     40 days past maturity and not yet closed.
SELECT seed.customer(
  'omana', 'Omana Kurup',
  'Seed 15. A recurring deposit and a National Savings Certificate, both 40 days past maturity and still open: "matured".',
  '9845012315', '2, Kadri Hills, Mangaluru 575002', '1955-12-30', '100200315', '412398760165', 'OKUPK5678O'
);
SELECT seed.rd('omana', 15, 2000, (seed.today() - 40 - interval '60 months')::date, 60, p_rate => 5.8);
SELECT seed.otd('omana-nsc', 'omana', 'nationalSavingsCertificate', 2, 25000, 6.8, 5, 0, (seed.today() - 40 - interval '5 years')::date);

-- 16. Closed: a recurring deposit and a two-year Time Deposit, both closed.
SELECT seed.customer(
  'prakash', 'Prakash Rao',
  'Seed 16. A recurring deposit and a two-year Time Deposit, both closed. Lists show the Closed badge; the Monthly Hub leaves the account out.',
  '9845012316', '11, Rajajinagar 2nd Block, Bengaluru 560010', '1968-05-22', '100200316', '412398760176', 'PRAPR6789P'
);
SELECT seed.rd('prakash', 16, 3000, seed.dt(66, 10), 60, p_status => 'closed', p_rate => 5.8);
SELECT seed.otd('prakash-td', 'prakash', 'timeDeposit', 3, 100000, 7.0, 2, 0, seed.dt(27, 14), 'closed');

-- ---------------------------------------------------------------------------------------
-- 5. Customer shape
-- ---------------------------------------------------------------------------------------

-- 17. A household with many accounts: two recurring deposits (one due on the 15th and
--     settled, one due at month end and not yet paid), every one-time scheme, opened across
--     four financial years, and a savings account with three nominees.
SELECT seed.customer(
  'ramesh', 'Ramesh Hegde',
  'Seed 17. Many accounts: two recurring deposits, Time Deposits of 1, 2, 3 and 5 years, a Monthly Income Scheme at the 9,00,000 limit, a National Savings Certificate, a Kisan Vikas Patra and a savings account with three nominees. Opened across four financial years.',
  '9845012317', '45, Yellapur Road, Sirsi 581402', '1960-02-11', '100200317', '412398760187', 'RHEPH7890R',
  'ramesh.hegde@example.com'
);
SELECT seed.rd('ramesh-a', 17, 5000, seed.dt(20, 10), 18, 'ramesh');
SELECT seed.on_time('ramesh-a', 2, 0);
SELECT seed.rd('ramesh-b', 18, 1500, seed.dt(7, 22), 5, 'ramesh');
SELECT seed.on_time('ramesh-b', 2, 1);
SELECT seed.otd('ramesh-td1', 'ramesh', 'timeDeposit', 4, 200000, 6.9, 1, 0, seed.dt(2, 12));
SELECT seed.otd('ramesh-td2', 'ramesh', 'timeDeposit', 5, 150000, 7.0, 2, 0, seed.dt(14, 12));
SELECT seed.otd('ramesh-td3', 'ramesh', 'timeDeposit', 6, 300000, 7.1, 3, 0, seed.dt(26, 12));
SELECT seed.otd('ramesh-td5', 'ramesh', 'timeDeposit', 7, 500000, 7.5, 5, 0, seed.dt(38, 12));
SELECT seed.otd('ramesh-mis', 'ramesh', 'monthlyIncomeScheme', 8, 900000, 7.4, 5, 0, seed.dt(30, 6));
SELECT seed.otd('ramesh-nsc', 'ramesh', 'nationalSavingsCertificate', 9, 100000, 7.7, 5, 0, seed.dt(18, 21));
SELECT seed.otd('ramesh-kvp', 'ramesh', 'kisanVikasPatra', 10, 50000, 7.5, 9, 7, seed.dt(8, 3));

INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
VALUES (seed.id('sb:ramesh'), seed.id('customer:ramesh'), seed.agent(), 'SB');
INSERT INTO public.savings_accounts (id, account_number, linked_date)
VALUES (seed.id('sb:ramesh'), '0100030017', seed.dt(40, 4));

-- 18. Name only: no phone, address, date of birth, CIF, Aadhaar, PAN or email, and no
--     nominee. One Time Deposit of the smallest amount.
SELECT seed.customer(
  'sunita', 'Sunita Thomas',
  'Seed 18. Only a name is known: every other field is empty. One Time Deposit of 1,000 rupees with no nominee.'
);
SELECT seed.otd('sunita-td', 'sunita', 'timeDeposit', 11, 1000, 6.9, 1, 0, seed.dt(2, 12));

-- 19. A name too long for one line. Not yet paid this month, so the name also appears on a
--     Monthly Hub row with a Collect button.
SELECT seed.customer(
  'tejaswini', 'Tejaswini Venkata Subrahmanya Lakshminarasimha Chintalapati',
  'Seed 19. A name too long for one line, at 360dp and at large text. Not yet paid this month, so the Monthly Hub shows it beside a Collect button.',
  '9845012319', 'Flat 1204, Tower C, Prestige Lakeside Habitat, Whitefield-Sarjapur Road, Varthur, Bengaluru 560087',
  '1992-11-18', '100200319', '412398760209', 'TCHPC9012T'
);
SELECT seed.rd('tejaswini', 19, 500, seed.dt(6, 18), 4);
SELECT seed.on_time('tejaswini', 2, 1);

-- 20. No account at all: empty sections, and a customer that can be deleted.
SELECT seed.customer(
  'uma', 'Uma Bose',
  'Seed 20. A customer with no account: empty sections on the detail screen, and deleting is allowed.',
  '9845012320', '16, Residency Road, Bengaluru 560025', '1999-09-09'
);

-- 21. A name in Kannada script: fonts, the avatar's initial, sorting and search.
SELECT seed.customer(
  'vijayalakshmi', 'ವಿಜಯಲಕ್ಷ್ಮಿ ಗೌಡ',
  'Seed 21. A name written in Kannada (Vijayalakshmi Gowda): fonts, the avatar initial, sorting and search on non-Latin text. Recurring deposit settled this month.',
  '9845012321', '30, ರಥಬೀದಿ, ಮೈಸೂರು 570001', '1980-04-14', '100200321', '412398760221', 'VGOPG1234V'
);
SELECT seed.rd('vijayalakshmi', 20, 1000, seed.dt(10, 6), 8);
SELECT seed.on_time('vijayalakshmi', 2, 0, 'upi');

-- ---------------------------------------------------------------------------------------
-- 6. Nominees. Relationships use the app's serialised names (Wife, Son, FatherInLaw, ...).
-- ---------------------------------------------------------------------------------------
INSERT INTO public.nominees (account_id, name, relationship, percentage)
VALUES
  (seed.id('rd:asha'), 'Vinod Kulkarni', 'Husband', 100),
  (seed.id('rd:bharat'), 'Sharada Shetty', 'Wife', 100),
  (seed.id('rd:chitra'), 'Gopalan Nair', 'Father', 100),
  (seed.id('rd:dinesh'), 'Rekha Agarwal', 'Wife', 60),
  (seed.id('rd:dinesh'), 'Mohit Agarwal', 'Son', 40),
  (seed.id('rd:esha'), 'Maria Fernandes', 'Mother', 100),
  (seed.id('rd:farhan'), 'Ayesha Qureshi', 'Wife', 100),
  (seed.id('rd:gauri'), 'Sameer Deshpande', 'Son', 100),
  (seed.id('rd:harish'), 'Lakshmi Gowda', 'Wife', 100),
  (seed.id('rd:indira'), 'Suresh Menon', 'Son', 50),
  (seed.id('rd:indira'), 'Latha Menon', 'Daughter', 50),
  (seed.id('rd:jayant'), 'Vidya Bhat', 'Wife', 100),
  (seed.id('rd:kavita'), 'Anand Joshi', 'Husband', 100),
  (seed.id('rd:lalit'), 'Neha Saxena', 'Sister', 100),
  (seed.id('rd:meera'), 'Krishnan Iyer', 'Husband', 100),
  (seed.id('rd:naveen'), 'Deepa Pillai', 'Daughter', 100),
  (seed.id('otd:naveen-td'), 'Deepa Pillai', 'Daughter', 100),
  (seed.id('rd:omana'), 'Rajan Kurup', 'Son', 100),
  (seed.id('otd:omana-nsc'), 'Rajan Kurup', 'Son', 100),
  (seed.id('rd:prakash'), 'Sudha Rao', 'Wife', 100),
  (seed.id('otd:prakash-td'), 'Sudha Rao', 'Wife', 100),
  (seed.id('sb:ramesh'), 'Shanta Hegde', 'Wife', 33.34),
  (seed.id('sb:ramesh'), 'Arun Hegde', 'Son', 33.33),
  (seed.id('sb:ramesh'), 'Anita Hegde', 'Daughter', 33.33),
  (seed.id('rd:ramesh-a'), 'Shanta Hegde', 'Wife', 100),
  (seed.id('rd:ramesh-b'), 'Arun Hegde', 'Son', 100),
  (seed.id('otd:ramesh-td1'), 'Shanta Hegde', 'Wife', 100),
  (seed.id('otd:ramesh-td2'), 'Shanta Hegde', 'Wife', 100),
  (seed.id('otd:ramesh-td3'), 'Arun Hegde', 'Son', 100),
  (seed.id('otd:ramesh-td5'), 'Anita Hegde', 'Daughter', 100),
  (seed.id('otd:ramesh-mis'), 'Shanta Hegde', 'Wife', 100),
  (seed.id('otd:ramesh-nsc'), 'Arun Hegde', 'Son', 50),
  (seed.id('otd:ramesh-nsc'), 'Anita Hegde', 'Daughter', 50),
  (seed.id('otd:ramesh-kvp'), 'Shanta Hegde', 'Wife', 100),
  (seed.id('rd:tejaswini'), 'Venkata Ramana Chintalapati', 'Father', 100),
  (seed.id('rd:vijayalakshmi'), 'ಮಂಜುನಾಥ ಗೌಡ', 'Husband', 100);

DROP SCHEMA seed CASCADE;

-- ---------------------------------------------------------------------------------------
-- 7. Handing the seed data to another agent
--
-- "Sign in as seeded agent" on the login screen (local builds only) signs in as the agent
-- above. If you sign in with Google instead, the first such sign-in takes over the seed
-- data (section 8). To hand it to a particular account by hand:
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
-- 8. The FIRST real agent to sign in (e.g. your Google account) takes over the seed data.
--    Throwaway test agents created by the repository tests (`*@example.com`) are ignored, so
--    they never take the seed data and then cascade-delete it.
-- ---------------------------------------------------------------------------------------
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
