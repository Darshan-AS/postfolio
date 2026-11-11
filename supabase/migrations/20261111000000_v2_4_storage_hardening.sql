-- Migration: 20261111000000_v2_4_storage_hardening.sql
-- Goal: Consolidated v2.4 Pure-DDD Storage Hardening & Security Lockdown (post-v2.3.1):
--   1. Pure-DDD Boundary: 100% of business rules, financial-terms locks, batch-undo ordering,
--      and enum vocabularies live in Dart; SQL retains strictly universal storage physics.
--   2. Security & Least Privilege: isolate internal SECURITY DEFINER helpers in unexposed
--      `private` schema, inline RLS-enforced nominee JSON into `security_invoker = true` views,
--      and revoke `anon` table grants + wildcard `authenticated` routine grants.
--   3. Storage Physics: exact base-10 `NUMERIC(12,2)` / `NUMERIC(5,2)` scales, universal
--      physical sign bounds (`> 0` / `>= 0`), plain `TEXT` enum columns (dropping hardcoded
--      enum CHECKs), `ON DELETE NO ACTION` parent protection on Customers & RD ledger facts,
--      `ON UPDATE CASCADE` on all `agent_id` FKs, case-insensitive `UNIQUE (lower(email))`
--      on `agent_profiles`, partial `UNIQUE` SB account per customer, and composite indexes.
--   4. Dumb Multi-Table ACID Envelopes (`save_customer_with_sb_account`, `save_one_time_deposit`,
--      `save_recurring_deposit`, `set_deposit_status`), bounded Web crash telemetry
--      (`app_error_logs` + `log_client_error`), and Realtime publication cleanup.

-- ------------------------------------------------------------------------------------------
-- 0. Trigger helpers: pinned search_path & case-insensitive JIT profile linking
-- ------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_existing_id UUID;
BEGIN
  SELECT id INTO v_existing_id
  FROM public.agent_profiles
  WHERE email IS NOT NULL AND NEW.email IS NOT NULL AND lower(email) = lower(NEW.email)
  ORDER BY created_at ASC
  LIMIT 1;

  IF v_existing_id IS NOT NULL THEN
    IF v_existing_id = NEW.id THEN
      UPDATE public.agent_profiles
      SET email = COALESCE(NEW.email, email),
          name = COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', email, name),
          updated_at = NOW()
      WHERE id = NEW.id;
    ELSE
      UPDATE public.agent_profiles
      SET id = NEW.id,
          email = COALESCE(NEW.email, email),
          name = COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', email, name),
          updated_at = NOW()
      WHERE id = v_existing_id;
    END IF;
  ELSE
    INSERT INTO public.agent_profiles (id, email, name)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', NEW.email)
    )
    ON CONFLICT (id) DO UPDATE SET
      email = COALESCE(EXCLUDED.email, public.agent_profiles.email),
      name = COALESCE(EXCLUDED.name, public.agent_profiles.name),
      updated_at = NOW();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------------------
-- 1. Unexposed `private` schema for internal SECURITY DEFINER helpers
-- ------------------------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS private;

REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA private TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA private
  REVOKE ALL ON ROUTINES FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION private.assert_authenticated()
RETURNS UUID AS $$
DECLARE
  v_agent_id UUID := auth.uid();
BEGIN
  IF v_agent_id IS NULL THEN
    RAISE EXCEPTION 'Unauthenticated'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  RETURN v_agent_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, private;

CREATE OR REPLACE FUNCTION private.assert_customer_owner(
  p_customer_id UUID,
  p_agent_id UUID
) RETURNS VOID AS $$
BEGIN
  IF p_customer_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.customers WHERE id = p_customer_id AND agent_id <> p_agent_id
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Customer does not belong to active agent'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, private;

CREATE OR REPLACE FUNCTION private.assert_account_owner(
  p_account_id UUID,
  p_agent_id UUID
) RETURNS VOID AS $$
BEGIN
  IF p_account_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.account_identities WHERE id = p_account_id AND agent_id <> p_agent_id
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Account identity does not belong to active agent'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, private;

CREATE OR REPLACE FUNCTION private.upsert_account_identity(
  p_id UUID,
  p_customer_id UUID,
  p_agent_id UUID,
  p_account_type TEXT
) RETURNS UUID AS $$
DECLARE
  v_account_id UUID := p_id;
  v_existing_type TEXT;
BEGIN
  IF v_account_id IS NULL THEN
    SELECT id INTO v_account_id
    FROM public.account_identities
    WHERE customer_id = p_customer_id AND account_type = p_account_type
    ORDER BY created_at ASC
    LIMIT 1;
  END IF;

  v_account_id := COALESCE(v_account_id, gen_random_uuid());

  SELECT account_type INTO v_existing_type
  FROM public.account_identities
  WHERE id = v_account_id;

  IF FOUND AND v_existing_type <> p_account_type THEN
    RAISE EXCEPTION 'Account identity % already exists with type % (expected %)',
      v_account_id, v_existing_type, p_account_type
      USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
  VALUES (v_account_id, p_customer_id, p_agent_id, p_account_type)
  ON CONFLICT (id) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    updated_at = NOW();

  RETURN v_account_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

CREATE OR REPLACE FUNCTION private.replace_account_nominees(
  p_account_id UUID,
  p_nominees JSONB
) RETURNS VOID AS $$
BEGIN
  DELETE FROM public.nominees WHERE account_id = p_account_id;

  IF p_nominees IS NOT NULL AND jsonb_array_length(p_nominees) > 0 THEN
    INSERT INTO public.nominees (account_id, name, relationship, custom_relationship, percentage)
    SELECT
      p_account_id,
      elem->>'name',
      elem->>'relationship',
      elem->>'custom_relationship',
      ROUND((elem->>'percentage')::numeric, 2)
    FROM jsonb_array_elements(p_nominees) AS elem;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON ALL ROUTINES IN SCHEMA private FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------------------------------------
-- 2. Exact `NUMERIC(12,2)` / `NUMERIC(5,2)` scales, plain TEXT enums & physical sign bounds
--    (Drop dependent views before ALTER COLUMN TYPE, then recreate with security_invoker)
-- ------------------------------------------------------------------------------------------
DROP VIEW IF EXISTS public.customer_details_view;
DROP VIEW IF EXISTS public.one_time_deposit_details_view;
DROP VIEW IF EXISTS public.recurring_deposit_details_view;

-- Strip leaked enum CHECK from rd_transactions so payment_mode evolves in pure Dart:
ALTER TABLE public.rd_transactions
  DROP CONSTRAINT IF EXISTS rd_transactions_payment_mode_check;

ALTER TABLE public.one_time_deposits
  ALTER COLUMN principal_amount TYPE NUMERIC(12,2) USING ROUND(principal_amount, 2),
  ALTER COLUMN interest_rate TYPE NUMERIC(5,2) USING ROUND(interest_rate, 2);

ALTER TABLE public.recurring_deposits
  ALTER COLUMN installment_amount TYPE NUMERIC(12,2) USING ROUND(installment_amount, 2),
  ALTER COLUMN interest_rate TYPE NUMERIC(5,2) USING ROUND(interest_rate, 2),
  ALTER COLUMN opening_receivable TYPE NUMERIC(12,2) USING ROUND(opening_receivable, 2);

ALTER TABLE public.nominees
  ALTER COLUMN percentage TYPE NUMERIC(5,2) USING ROUND(percentage, 2);

ALTER TABLE public.rd_transactions
  ALTER COLUMN amount TYPE NUMERIC(12,2) USING ROUND(amount, 2);

ALTER TABLE public.rd_po_deposits
  ALTER COLUMN fee_paid TYPE NUMERIC(12,2) USING ROUND(fee_paid, 2),
  ALTER COLUMN amount TYPE NUMERIC(12,2) USING ROUND(amount, 2);

ALTER TABLE public.rd_fee_absorptions
  ALTER COLUMN amount TYPE NUMERIC(12,2) USING ROUND(amount, 2);

ALTER TABLE public.rd_ledger_summary
  ALTER COLUMN customer_credit TYPE NUMERIC(12,2) USING ROUND(customer_credit, 2),
  ALTER COLUMN opening_receivable_left TYPE NUMERIC(12,2) USING ROUND(opening_receivable_left, 2),
  ALTER COLUMN owed_by_customer TYPE NUMERIC(12,2) USING ROUND(owed_by_customer, 2),
  ALTER COLUMN receivable TYPE NUMERIC(12,2) USING ROUND(receivable, 2),
  ALTER COLUMN cash_in_hand_cash TYPE NUMERIC(12,2) USING ROUND(cash_in_hand_cash, 2),
  ALTER COLUMN cash_in_hand_digital TYPE NUMERIC(12,2) USING ROUND(cash_in_hand_digital, 2),
  ALTER COLUMN absorbed_total TYPE NUMERIC(12,2) USING ROUND(absorbed_total, 2),
  ALTER COLUMN delay_cost_total TYPE NUMERIC(12,2) USING ROUND(delay_cost_total, 2),
  ALTER COLUMN fee_due TYPE NUMERIC(12,2) USING ROUND(fee_due, 2);

-- Universal physical sign & range bounds (zero scheme/policy business rules):
ALTER TABLE public.one_time_deposits
  DROP CONSTRAINT IF EXISTS otd_principal_positive,
  DROP CONSTRAINT IF EXISTS otd_rate_non_negative,
  DROP CONSTRAINT IF EXISTS otd_terms_non_negative;
ALTER TABLE public.one_time_deposits
  ADD CONSTRAINT otd_principal_positive CHECK (principal_amount > 0),
  ADD CONSTRAINT otd_rate_non_negative CHECK (interest_rate >= 0),
  ADD CONSTRAINT otd_terms_non_negative CHECK (term_years >= 0 AND term_months >= 0);

ALTER TABLE public.recurring_deposits
  DROP CONSTRAINT IF EXISTS rd_installment_positive,
  DROP CONSTRAINT IF EXISTS rd_rate_non_negative,
  DROP CONSTRAINT IF EXISTS rd_terms_non_negative;
ALTER TABLE public.recurring_deposits
  ADD CONSTRAINT rd_installment_positive CHECK (installment_amount > 0),
  ADD CONSTRAINT rd_rate_non_negative CHECK (interest_rate >= 0),
  ADD CONSTRAINT rd_terms_non_negative
    CHECK (term_years >= 0 AND term_months >= 0 AND initial_paid_installments >= 0);

ALTER TABLE public.nominees
  DROP CONSTRAINT IF EXISTS nominees_percentage_bounds;
ALTER TABLE public.nominees
  ADD CONSTRAINT nominees_percentage_bounds CHECK (percentage > 0 AND percentage <= 100);

-- Recreate `security_invoker = true` read views with inline RLS-safe nominee JSON:
CREATE OR REPLACE VIEW public.customer_details_view WITH (security_invoker = true) AS
SELECT
  c.id,
  c.agent_id,
  c.name,
  c.phone,
  c.email,
  c.address,
  c.cif_number,
  c.date_of_birth,
  c.aadhaar_number,
  c.pan_number,
  c.notes,
  c.created_at,
  c.updated_at,
  sa_lat.savings_account
FROM public.customers c
LEFT JOIN LATERAL (
  SELECT jsonb_build_object(
    'account_number', sa.account_number,
    'nominees', COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'name', n.name,
            'relationship', n.relationship,
            'custom_relationship', n.custom_relationship,
            'percentage', n.percentage
          )
        )
        FROM public.nominees n
        WHERE n.account_id = ai.id
      ),
      '[]'::jsonb
    )
  ) AS savings_account
  FROM public.account_identities ai
  JOIN public.savings_accounts sa ON sa.id = ai.id
  WHERE ai.customer_id = c.id AND ai.account_type = 'SB'
  ORDER BY ai.created_at ASC
  LIMIT 1
) sa_lat ON true;

CREATE OR REPLACE VIEW public.one_time_deposit_details_view WITH (security_invoker = true) AS
SELECT
  d.id,
  ai.agent_id,
  ai.customer_id,
  c.name AS customer_name,
  d.status,
  d.scheme_type,
  d.account_no,
  d.principal_amount,
  d.interest_rate,
  d.term_years,
  d.term_months,
  d.start_date,
  d.created_at,
  d.updated_at,
  COALESCE(
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'name', n.name,
          'relationship', n.relationship,
          'custom_relationship', n.custom_relationship,
          'percentage', n.percentage
        )
      )
      FROM public.nominees n
      WHERE n.account_id = d.id
    ),
    '[]'::jsonb
  ) AS nominees
FROM public.one_time_deposits d
JOIN public.account_identities ai ON ai.id = d.id AND ai.account_type = 'OTD'
JOIN public.customers c ON c.id = ai.customer_id;

CREATE OR REPLACE VIEW public.recurring_deposit_details_view WITH (security_invoker = true) AS
SELECT
  d.id,
  ai.agent_id,
  ai.customer_id,
  c.name AS customer_name,
  d.status,
  d.scheme_type,
  d.account_no,
  d.serial_no,
  d.installment_amount,
  d.interest_rate,
  d.term_years,
  d.term_months,
  d.start_date,
  d.initial_paid_installments,
  d.opening_receivable,
  d.created_at,
  d.updated_at,
  COALESCE(
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'name', n.name,
          'relationship', n.relationship,
          'custom_relationship', n.custom_relationship,
          'percentage', n.percentage
        )
      )
      FROM public.nominees n
      WHERE n.account_id = d.id
    ),
    '[]'::jsonb
  ) AS nominees
FROM public.recurring_deposits d
JOIN public.account_identities ai ON ai.id = d.id AND ai.account_type = 'RD'
JOIN public.customers c ON c.id = ai.customer_id;

-- Drop legacy exposed SECURITY DEFINER helpers from `public`:
DROP FUNCTION IF EXISTS public.get_account_nominees(UUID);
DROP FUNCTION IF EXISTS public.replace_account_nominees(UUID, JSONB);
DROP FUNCTION IF EXISTS public.upsert_account_identity(UUID, UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.assert_account_owner(UUID, UUID);
DROP FUNCTION IF EXISTS public.assert_customer_owner(UUID, UUID);
DROP FUNCTION IF EXISTS public.assert_authenticated();
DROP FUNCTION IF EXISTS public.undo_rd_po_deposit_batch(UUID);

-- ------------------------------------------------------------------------------------------
-- 3. Referential Integrity: protect parent Customers & RD ledger facts (`ON DELETE NO ACTION`)
--    and cascade `agent_profiles.id` JIT relinking (`ON UPDATE CASCADE`)
-- ------------------------------------------------------------------------------------------
ALTER TABLE public.account_identities
  DROP CONSTRAINT IF EXISTS account_identities_customer_id_fkey;
ALTER TABLE public.account_identities
  ADD CONSTRAINT account_identities_customer_id_fkey
  FOREIGN KEY (customer_id) REFERENCES public.customers(id)
  ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE public.rd_transactions
  DROP CONSTRAINT IF EXISTS rd_transactions_rd_id_fkey;
ALTER TABLE public.rd_transactions
  ADD CONSTRAINT rd_transactions_rd_id_fkey
  FOREIGN KEY (rd_id) REFERENCES public.recurring_deposits(id)
  ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE public.rd_po_deposits
  DROP CONSTRAINT IF EXISTS rd_po_deposits_rd_id_fkey;
ALTER TABLE public.rd_po_deposits
  ADD CONSTRAINT rd_po_deposits_rd_id_fkey
  FOREIGN KEY (rd_id) REFERENCES public.recurring_deposits(id)
  ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE public.rd_fee_absorptions
  DROP CONSTRAINT IF EXISTS rd_fee_absorptions_rd_id_fkey;
ALTER TABLE public.rd_fee_absorptions
  ADD CONSTRAINT rd_fee_absorptions_rd_id_fkey
  FOREIGN KEY (rd_id) REFERENCES public.recurring_deposits(id)
  ON UPDATE CASCADE ON DELETE NO ACTION;

ALTER TABLE public.rd_po_deposits
  DROP CONSTRAINT IF EXISTS rd_po_deposits_agent_id_fkey;
ALTER TABLE public.rd_po_deposits
  ADD CONSTRAINT rd_po_deposits_agent_id_fkey
  FOREIGN KEY (agent_id) REFERENCES public.agent_profiles(id)
  ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE public.rd_fee_absorptions
  DROP CONSTRAINT IF EXISTS rd_fee_absorptions_agent_id_fkey;
ALTER TABLE public.rd_fee_absorptions
  ADD CONSTRAINT rd_fee_absorptions_agent_id_fkey
  FOREIGN KEY (agent_id) REFERENCES public.agent_profiles(id)
  ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE public.rd_ledger_summary
  DROP CONSTRAINT IF EXISTS rd_ledger_summary_agent_id_fkey;
ALTER TABLE public.rd_ledger_summary
  ADD CONSTRAINT rd_ledger_summary_agent_id_fkey
  FOREIGN KEY (agent_id) REFERENCES public.agent_profiles(id)
  ON UPDATE CASCADE ON DELETE CASCADE;

-- ------------------------------------------------------------------------------------------
-- 4. Uniqueness & Composite Query Indexes
-- ------------------------------------------------------------------------------------------
-- Deduplicate any stray secondary SB identities per customer before adding partial UNIQUE index:
DELETE FROM public.account_identities ai
WHERE ai.account_type = 'SB'
  AND EXISTS (
    SELECT 1 FROM public.account_identities earlier
    WHERE earlier.customer_id = ai.customer_id
      AND earlier.account_type = 'SB'
      AND (earlier.created_at, earlier.id) < (ai.created_at, ai.id)
  );

CREATE UNIQUE INDEX IF NOT EXISTS idx_agent_profiles_email_lower
  ON public.agent_profiles (lower(email))
  WHERE email IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_account_identities_unique_customer_sb
  ON public.account_identities (customer_id)
  WHERE account_type = 'SB';

CREATE INDEX IF NOT EXISTS idx_customers_agent_name_id
  ON public.customers (agent_id, name, id);

CREATE INDEX IF NOT EXISTS idx_account_identities_agent_type_id
  ON public.account_identities (agent_id, account_type, id);

CREATE INDEX IF NOT EXISTS idx_rd_ledger_summary_agent_rd
  ON public.rd_ledger_summary (agent_id, rd_id);

-- ------------------------------------------------------------------------------------------
-- 5. Dumb Multi-Table ACID Persistence Envelopes (zero business rules in SQL)
-- ------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.save_customer_with_sb_account(
  p_id UUID DEFAULT NULL,
  p_name TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_email TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL,
  p_cif_number TEXT DEFAULT NULL,
  p_date_of_birth DATE DEFAULT NULL,
  p_aadhaar_number TEXT DEFAULT NULL,
  p_pan_number TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_sb_account_number TEXT DEFAULT NULL,
  p_nominees JSONB DEFAULT '[]'::jsonb
) RETURNS UUID AS $$
DECLARE
  v_customer_id UUID;
  v_account_id UUID;
  v_agent_id UUID := private.assert_authenticated();
BEGIN
  PERFORM private.assert_customer_owner(p_id, v_agent_id);

  p_nominees := COALESCE(p_nominees, '[]'::jsonb);

  INSERT INTO public.customers (
    id, agent_id, name, phone, email, address,
    cif_number, date_of_birth, aadhaar_number, pan_number, notes
  )
  VALUES (
    COALESCE(p_id, gen_random_uuid()),
    v_agent_id,
    p_name,
    p_phone,
    p_email,
    p_address,
    p_cif_number,
    p_date_of_birth,
    p_aadhaar_number,
    p_pan_number,
    p_notes
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    address = EXCLUDED.address,
    cif_number = EXCLUDED.cif_number,
    date_of_birth = EXCLUDED.date_of_birth,
    aadhaar_number = EXCLUDED.aadhaar_number,
    pan_number = EXCLUDED.pan_number,
    notes = EXCLUDED.notes,
    updated_at = NOW()
  RETURNING id INTO v_customer_id;

  IF p_sb_account_number IS NOT NULL AND TRIM(p_sb_account_number) <> '' THEN
    v_account_id := private.upsert_account_identity(NULL, v_customer_id, v_agent_id, 'SB');

    INSERT INTO public.savings_accounts (id, account_number)
    VALUES (v_account_id, TRIM(p_sb_account_number))
    ON CONFLICT (id) DO UPDATE SET account_number = EXCLUDED.account_number;

    PERFORM private.replace_account_nominees(v_account_id, p_nominees);
  ELSE
    DELETE FROM public.account_identities
    WHERE customer_id = v_customer_id AND account_type = 'SB';
  END IF;

  RETURN v_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

CREATE OR REPLACE FUNCTION public.save_one_time_deposit(
  p_id UUID,
  p_customer_id UUID,
  p_status TEXT,
  p_scheme_type TEXT,
  p_account_no TEXT DEFAULT NULL,
  p_principal_amount NUMERIC DEFAULT 0,
  p_interest_rate NUMERIC DEFAULT 0,
  p_term_years INTEGER DEFAULT 0,
  p_term_months INTEGER DEFAULT 0,
  p_start_date DATE DEFAULT CURRENT_DATE,
  p_nominees JSONB DEFAULT '[]'::jsonb
) RETURNS UUID AS $$
DECLARE
  v_agent_id UUID := private.assert_authenticated();
BEGIN
  PERFORM private.assert_customer_owner(p_customer_id, v_agent_id);
  PERFORM private.assert_account_owner(p_id, v_agent_id);

  PERFORM private.upsert_account_identity(p_id, p_customer_id, v_agent_id, 'OTD');

  INSERT INTO public.one_time_deposits (
    id, status, scheme_type, account_no,
    principal_amount, interest_rate, term_years, term_months, start_date
  )
  VALUES (
    p_id, p_status, p_scheme_type, p_account_no,
    p_principal_amount, p_interest_rate, p_term_years, p_term_months, p_start_date
  )
  ON CONFLICT (id) DO UPDATE SET
    status = EXCLUDED.status,
    scheme_type = EXCLUDED.scheme_type,
    account_no = EXCLUDED.account_no,
    principal_amount = EXCLUDED.principal_amount,
    interest_rate = EXCLUDED.interest_rate,
    term_years = EXCLUDED.term_years,
    term_months = EXCLUDED.term_months,
    start_date = EXCLUDED.start_date,
    updated_at = NOW();

  PERFORM private.replace_account_nominees(p_id, p_nominees);

  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

CREATE OR REPLACE FUNCTION public.save_recurring_deposit(
  p_id UUID,
  p_customer_id UUID,
  p_status TEXT,
  p_scheme_type TEXT,
  p_account_no TEXT DEFAULT NULL,
  p_serial_no TEXT DEFAULT NULL,
  p_installment_amount NUMERIC DEFAULT 0,
  p_interest_rate NUMERIC DEFAULT 0,
  p_term_years INTEGER DEFAULT 0,
  p_term_months INTEGER DEFAULT 0,
  p_start_date DATE DEFAULT CURRENT_DATE,
  p_nominees JSONB DEFAULT '[]'::jsonb,
  p_initial_paid_installments INTEGER DEFAULT 0,
  p_opening_receivable NUMERIC DEFAULT 0
) RETURNS UUID AS $$
DECLARE
  v_agent_id UUID := private.assert_authenticated();
BEGIN
  PERFORM private.assert_customer_owner(p_customer_id, v_agent_id);
  PERFORM private.assert_account_owner(p_id, v_agent_id);

  PERFORM private.upsert_account_identity(p_id, p_customer_id, v_agent_id, 'RD');

  INSERT INTO public.recurring_deposits (
    id, status, scheme_type, account_no, serial_no,
    installment_amount, interest_rate, term_years, term_months, start_date,
    initial_paid_installments, opening_receivable
  )
  VALUES (
    p_id, p_status, p_scheme_type, p_account_no, p_serial_no,
    p_installment_amount, p_interest_rate, p_term_years, p_term_months, p_start_date,
    p_initial_paid_installments, p_opening_receivable
  )
  ON CONFLICT (id) DO UPDATE SET
    status = EXCLUDED.status,
    scheme_type = EXCLUDED.scheme_type,
    account_no = EXCLUDED.account_no,
    serial_no = EXCLUDED.serial_no,
    installment_amount = EXCLUDED.installment_amount,
    interest_rate = EXCLUDED.interest_rate,
    term_years = EXCLUDED.term_years,
    term_months = EXCLUDED.term_months,
    start_date = EXCLUDED.start_date,
    initial_paid_installments = EXCLUDED.initial_paid_installments,
    opening_receivable = EXCLUDED.opening_receivable,
    updated_at = NOW();

  PERFORM private.replace_account_nominees(p_id, p_nominees);

  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

-- Atomic status-only update envelope (preserves nominees, opening_receivable & rd_ledger_summary,
-- without hardcoding allowed status enum names in SQL):
CREATE OR REPLACE FUNCTION public.set_deposit_status(
  p_id UUID,
  p_status TEXT
) RETURNS VOID AS $$
DECLARE
  v_agent_id UUID := private.assert_authenticated();
  v_account_type TEXT;
BEGIN
  IF NULLIF(TRIM(COALESCE(p_status, '')), '') IS NULL THEN
    RAISE EXCEPTION 'Deposit status cannot be empty'
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT account_type INTO v_account_type
  FROM public.account_identities
  WHERE id = p_id AND agent_id = v_agent_id;

  IF NOT FOUND THEN
    PERFORM private.assert_account_owner(p_id, v_agent_id);
    RAISE EXCEPTION 'Deposit not found'
      USING ERRCODE = 'no_data_found';
  END IF;

  IF v_account_type = 'OTD' THEN
    UPDATE public.one_time_deposits
    SET status = TRIM(p_status),
        updated_at = NOW()
    WHERE id = p_id;
  ELSIF v_account_type = 'RD' THEN
    UPDATE public.recurring_deposits
    SET status = TRIM(p_status),
        updated_at = NOW()
    WHERE id = p_id;
  ELSE
    RAISE EXCEPTION 'Account % is not a deposit (type: %)', p_id, v_account_type
      USING ERRCODE = 'check_violation';
  END IF;

  UPDATE public.account_identities
  SET updated_at = NOW()
  WHERE id = p_id AND agent_id = v_agent_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

-- ------------------------------------------------------------------------------------------
-- 6. Bounded Web/Client Crash Telemetry (`app_error_logs` + `log_client_error`)
-- ------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_error_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id UUID REFERENCES public.agent_profiles(id) ON UPDATE CASCADE ON DELETE CASCADE,
  platform TEXT NOT NULL CHECK (char_length(platform) <= 32),
  error_message TEXT NOT NULL CHECK (char_length(error_message) <= 1000),
  stack_trace TEXT CHECK (stack_trace IS NULL OR char_length(stack_trace) <= 8000),
  app_version TEXT CHECK (app_version IS NULL OR char_length(app_version) <= 64),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE public.app_error_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Agents read own error logs" ON public.app_error_logs;
CREATE POLICY "Agents read own error logs" ON public.app_error_logs
  FOR SELECT USING (agent_id = auth.uid() OR public.is_admin());

CREATE INDEX IF NOT EXISTS idx_app_error_logs_created_at
  ON public.app_error_logs(created_at DESC);

CREATE OR REPLACE FUNCTION public.log_client_error(
  p_platform TEXT,
  p_error TEXT,
  p_stack_trace TEXT DEFAULT NULL,
  p_app_version TEXT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
  v_agent_id UUID := private.assert_authenticated();
BEGIN
  INSERT INTO public.app_error_logs (
    agent_id,
    platform,
    error_message,
    stack_trace,
    app_version
  )
  VALUES (
    v_agent_id,
    LEFT(COALESCE(NULLIF(TRIM(p_platform), ''), 'unknown'), 32),
    LEFT(COALESCE(NULLIF(TRIM(p_error), ''), 'Unknown error'), 1000),
    CASE WHEN p_stack_trace IS NULL THEN NULL ELSE LEFT(p_stack_trace, 8000) END,
    CASE WHEN p_app_version IS NULL THEN NULL ELSE LEFT(TRIM(p_app_version), 64) END
  );

  DELETE FROM public.app_error_logs
  WHERE id IN (
    SELECT id
    FROM public.app_error_logs
    ORDER BY created_at DESC
    OFFSET 500
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

-- ------------------------------------------------------------------------------------------
-- 7. Realtime Publication Hygiene (remove unstreamed child tables to cut WAL overhead)
-- ------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_tbl TEXT;
BEGIN
  FOREACH v_tbl IN ARRAY ARRAY['savings_accounts', 'one_time_deposits', 'recurring_deposits', 'nominees'] LOOP
    IF EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = v_tbl
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime DROP TABLE public.%I;', v_tbl);
    END IF;
    EXECUTE format('ALTER TABLE public.%I REPLICA IDENTITY DEFAULT;', v_tbl);
  END LOOP;
END $$;

-- ------------------------------------------------------------------------------------------
-- 8. Least-Privilege Table & Routine Grants in `public`
-- ------------------------------------------------------------------------------------------
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon;

REVOKE ALL ON ALL ROUTINES IN SCHEMA public FROM PUBLIC, anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON ROUTINES FROM PUBLIC, anon, authenticated;

-- PUBLIC's EXECUTE on newly created functions is a *global* default privilege. Postgres adds
-- per-schema defaults on top of the global ones, so the per-schema REVOKE above removes the
-- anon/authenticated defaults granted in the initial schema but cannot remove PUBLIC's. Without
-- this global revoke, every function a later migration creates is callable by anon until
-- that migration remembers to revoke it (asserted by CASE 19 in supabase/tests).
-- Consequence to remember: this applies to every schema, so functions from an extension
-- enabled later by this role are not callable by API roles until explicitly granted.
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON ROUTINES FROM PUBLIC;

-- RLS boolean helpers evaluated by `authenticated` policies:
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.owns_account(UUID) TO authenticated, service_role;

-- Client-callable RPCs (4 multi-table ACID persistence envelopes + 1 error logger):
GRANT EXECUTE ON FUNCTION public.save_customer_with_sb_account(
  UUID, TEXT, TEXT, TEXT, TEXT, TEXT, DATE, TEXT, TEXT, TEXT, TEXT, JSONB
) TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.save_one_time_deposit(
  UUID, UUID, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, INTEGER, INTEGER, DATE, JSONB
) TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.save_recurring_deposit(
  UUID, UUID, TEXT, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, INTEGER, INTEGER, DATE, JSONB, INTEGER, NUMERIC
) TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.set_deposit_status(UUID, TEXT)
  TO authenticated, service_role;

GRANT EXECUTE ON FUNCTION public.log_client_error(TEXT, TEXT, TEXT, TEXT)
  TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';
