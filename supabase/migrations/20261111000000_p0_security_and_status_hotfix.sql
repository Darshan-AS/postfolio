-- Migration: 20261111000000_p0_security_and_status_hotfix.sql
-- Goal: Stage 0 emergency P0 security, data-loss, and batch-undo hotfixes:
--   1. Move internal SECURITY DEFINER helpers out of PostgREST-exposed `public` into `private`.
--   2. Inline nominee JSON aggregation into `security_invoker = true` views (drop `get_account_nominees`).
--   3. Revoke `anon` table grants and wildcard `authenticated` routine grants in `public`.
--   4. Add missing `ON UPDATE CASCADE` on `agent_id` FKs for `rd_po_deposits`,
--      `rd_fee_absorptions`, and `rd_ledger_summary` (fixes JIT profile relinking).
--   5. Add `public.set_deposit_status(p_id, p_status)` so status toggles never touch nominees,
--      `opening_receivable`, or `rd_ledger_summary`.
--   6. Preserve `rd_ledger_summary` in `save_recurring_deposit` when financial/schedule terms
--      are unchanged, and include `rd_fee_absorptions` in the financial-terms lock check.
--   7. Add `public.undo_rd_po_deposit_batch(p_batch_id)` with row locking + latest-visit
--      ordering enforcement, returning affected `rd_id`s (`UUID[]`).

-- ------------------------------------------------------------------------------------------
-- 0. Pin search_path on handle_updated_at trigger function
-- ------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

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
      (elem->>'percentage')::numeric
    FROM jsonb_array_elements(p_nominees) AS elem;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON ALL ROUTINES IN SCHEMA private FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------------------------------------
-- 2. Inline nominee JSON aggregation into `security_invoker = true` views (RLS enforced)
-- ------------------------------------------------------------------------------------------
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

-- ------------------------------------------------------------------------------------------
-- 3. Repoint public RPCs to `private.*` helpers & add status / batch-undo RPCs
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
    DELETE FROM public.account_identities WHERE customer_id = v_customer_id AND account_type = 'SB';
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
  v_existing public.recurring_deposits%ROWTYPE;
  v_existed BOOLEAN := FALSE;
  v_locked BOOLEAN := FALSE;
  v_terms_changed BOOLEAN := FALSE;
BEGIN
  PERFORM private.assert_customer_owner(p_customer_id, v_agent_id);
  PERFORM private.assert_account_owner(p_id, v_agent_id);

  SELECT * INTO v_existing FROM public.recurring_deposits WHERE id = p_id;
  v_existed := FOUND;

  IF v_existed THEN
    v_locked := EXISTS (SELECT 1 FROM public.rd_transactions WHERE rd_id = p_id)
      OR EXISTS (SELECT 1 FROM public.rd_po_deposits WHERE rd_id = p_id)
      OR EXISTS (SELECT 1 FROM public.rd_fee_absorptions WHERE rd_id = p_id);

    v_terms_changed := (
      p_installment_amount <> v_existing.installment_amount OR
      p_start_date <> v_existing.start_date OR
      p_term_years <> v_existing.term_years OR
      p_term_months <> v_existing.term_months OR
      p_initial_paid_installments <> v_existing.initial_paid_installments OR
      p_opening_receivable <> v_existing.opening_receivable
    );

    IF v_locked AND v_terms_changed THEN
      RAISE EXCEPTION 'Financial terms cannot be modified after ledger activity has been recorded.'
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;

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

  -- Only invalidate cached hub summary when financial/schedule terms on an existing RD changed.
  IF v_existed AND v_terms_changed THEN
    DELETE FROM public.rd_ledger_summary WHERE rd_id = p_id;
  END IF;

  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

-- Atomic status-only toggle for OTD and RD accounts (preserves nominees, opening_receivable,
-- and rd_ledger_summary, while touching account_identities for Realtime listeners).
CREATE OR REPLACE FUNCTION public.set_deposit_status(
  p_id UUID,
  p_status TEXT
) RETURNS VOID AS $$
DECLARE
  v_agent_id UUID := private.assert_authenticated();
  v_account_type TEXT;
BEGIN
  IF p_status IS NULL OR p_status NOT IN ('active', 'closed') THEN
    RAISE EXCEPTION 'Invalid deposit status: %', COALESCE(p_status, 'NULL')
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
    SET status = p_status,
        updated_at = NOW()
    WHERE id = p_id;
  ELSIF v_account_type = 'RD' THEN
    UPDATE public.recurring_deposits
    SET status = p_status,
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

-- Atomic PO visit batch undo: verifies every event in `p_batch_id` is still the latest
-- PO deposit on its RD, deletes the batch rows, and returns the affected RD IDs.
CREATE OR REPLACE FUNCTION public.undo_rd_po_deposit_batch(
  p_batch_id UUID
) RETURNS UUID[] AS $$
DECLARE
  v_agent_id UUID := private.assert_authenticated();
  v_rd_ids UUID[];
BEGIN
  IF p_batch_id IS NULL THEN
    RETURN '{}'::uuid[];
  END IF;

  PERFORM 1
  FROM public.rd_po_deposits d
  WHERE d.agent_id = v_agent_id
    AND d.rd_id IN (
      SELECT b.rd_id
      FROM public.rd_po_deposits b
      WHERE b.batch_id = p_batch_id AND b.agent_id = v_agent_id
    )
  FOR UPDATE;

  IF EXISTS (
    SELECT 1
    FROM public.rd_po_deposits b
    JOIN public.rd_po_deposits later
      ON later.rd_id = b.rd_id
     AND later.batch_id IS DISTINCT FROM p_batch_id
     AND (later.deposited_on, later.created_at, later.id) >
         (b.deposited_on, b.created_at, b.id)
    WHERE b.batch_id = p_batch_id
      AND b.agent_id = v_agent_id
  ) THEN
    RAISE EXCEPTION 'Cannot undo visit: a newer Post Office deposit exists on one or more accounts.'
      USING ERRCODE = 'check_violation';
  END IF;

  WITH deleted AS (
    DELETE FROM public.rd_po_deposits
    WHERE batch_id = p_batch_id
      AND agent_id = v_agent_id
    RETURNING rd_id
  )
  SELECT COALESCE(array_agg(DISTINCT rd_id), '{}'::uuid[])
  INTO v_rd_ids
  FROM deleted;

  RETURN v_rd_ids;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

-- ------------------------------------------------------------------------------------------
-- 4. Drop legacy exposed SECURITY DEFINER helpers from `public`
-- ------------------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_account_nominees(UUID);
DROP FUNCTION IF EXISTS public.replace_account_nominees(UUID, JSONB);
DROP FUNCTION IF EXISTS public.upsert_account_identity(UUID, UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.assert_account_owner(UUID, UUID);
DROP FUNCTION IF EXISTS public.assert_customer_owner(UUID, UUID);
DROP FUNCTION IF EXISTS public.assert_authenticated();

-- ------------------------------------------------------------------------------------------
-- 5. Add missing ON UPDATE CASCADE on RD ledger `agent_id` FKs (for JIT profile linking)
-- ------------------------------------------------------------------------------------------
ALTER TABLE public.rd_po_deposits DROP CONSTRAINT IF EXISTS rd_po_deposits_agent_id_fkey;
ALTER TABLE public.rd_po_deposits
  ADD CONSTRAINT rd_po_deposits_agent_id_fkey
  FOREIGN KEY (agent_id) REFERENCES public.agent_profiles(id)
  ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE public.rd_fee_absorptions DROP CONSTRAINT IF EXISTS rd_fee_absorptions_agent_id_fkey;
ALTER TABLE public.rd_fee_absorptions
  ADD CONSTRAINT rd_fee_absorptions_agent_id_fkey
  FOREIGN KEY (agent_id) REFERENCES public.agent_profiles(id)
  ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE public.rd_ledger_summary DROP CONSTRAINT IF EXISTS rd_ledger_summary_agent_id_fkey;
ALTER TABLE public.rd_ledger_summary
  ADD CONSTRAINT rd_ledger_summary_agent_id_fkey
  FOREIGN KEY (agent_id) REFERENCES public.agent_profiles(id)
  ON UPDATE CASCADE ON DELETE CASCADE;

-- ------------------------------------------------------------------------------------------
-- 6. Least-privilege table & routine grants in `public`
-- ------------------------------------------------------------------------------------------
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon;

REVOKE ALL ON ALL ROUTINES IN SCHEMA public FROM PUBLIC, anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON ROUTINES FROM PUBLIC, anon, authenticated;

-- RLS boolean helpers evaluated by `authenticated` policies:
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.owns_account(UUID) TO authenticated, service_role;

-- Client-callable RPCs:
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

GRANT EXECUTE ON FUNCTION public.undo_rd_po_deposit_batch(UUID)
  TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';
