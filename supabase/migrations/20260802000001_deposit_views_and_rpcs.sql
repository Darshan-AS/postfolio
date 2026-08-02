-- Migration: 20260802000001_deposit_views_and_rpcs.sql

-- 1. Create one_time_deposit_details_view for clean reads
CREATE OR REPLACE VIEW public.one_time_deposit_details_view WITH (security_invoker = true) AS
SELECT 
  d.id,
  ai.agent_id,
  ai.customer_id,
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
JOIN public.account_identities ai ON ai.id = d.id AND ai.account_type = 'OTD';

-- 2. Create recurring_deposit_details_view for clean reads
CREATE OR REPLACE VIEW public.recurring_deposit_details_view WITH (security_invoker = true) AS
SELECT 
  d.id,
  ai.agent_id,
  ai.customer_id,
  d.status,
  d.scheme_type,
  d.account_no,
  d.serial_no,
  d.installment_amount,
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
FROM public.recurring_deposits d
JOIN public.account_identities ai ON ai.id = d.id AND ai.account_type = 'RD';

-- 3. Create save_one_time_deposit RPC function for atomic writes
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
  v_agent_id UUID := auth.uid();
BEGIN
  IF v_agent_id IS NULL THEN
    RAISE EXCEPTION 'Unauthenticated';
  END IF;

  p_nominees := COALESCE(p_nominees, '[]'::jsonb);

  -- Security Check: Validate customer ownership
  IF NOT EXISTS (SELECT 1 FROM public.customers WHERE id = p_customer_id AND agent_id = v_agent_id) THEN
    RAISE EXCEPTION 'Unauthorized: Customer does not belong to active agent';
  END IF;

  -- Security Check: Validate existing account identity ownership
  IF p_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.account_identities WHERE id = p_id AND agent_id <> v_agent_id) THEN
    RAISE EXCEPTION 'Unauthorized: Account identity does not belong to active agent';
  END IF;

  -- 1. Ensure account_identity exists
  INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
  VALUES (p_id, p_customer_id, v_agent_id, 'OTD')
  ON CONFLICT (id) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    updated_at = NOW();

  -- 2. Upsert into one_time_deposits
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

  -- 3. Replace nominees
  DELETE FROM public.nominees WHERE account_id = p_id;

  IF jsonb_array_length(p_nominees) > 0 THEN
    INSERT INTO public.nominees (account_id, name, relationship, custom_relationship, percentage)
    SELECT
      p_id,
      elem->>'name',
      elem->>'relationship',
      elem->>'custom_relationship',
      (elem->>'percentage')::numeric
    FROM jsonb_array_elements(p_nominees) AS elem;
  END IF;

  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Create save_recurring_deposit RPC function for atomic writes
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
  p_nominees JSONB DEFAULT '[]'::jsonb
) RETURNS UUID AS $$
DECLARE
  v_agent_id UUID := auth.uid();
BEGIN
  IF v_agent_id IS NULL THEN
    RAISE EXCEPTION 'Unauthenticated';
  END IF;

  p_nominees := COALESCE(p_nominees, '[]'::jsonb);

  -- Security Check: Validate customer ownership
  IF NOT EXISTS (SELECT 1 FROM public.customers WHERE id = p_customer_id AND agent_id = v_agent_id) THEN
    RAISE EXCEPTION 'Unauthorized: Customer does not belong to active agent';
  END IF;

  -- Security Check: Validate existing account identity ownership
  IF p_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.account_identities WHERE id = p_id AND agent_id <> v_agent_id) THEN
    RAISE EXCEPTION 'Unauthorized: Account identity does not belong to active agent';
  END IF;

  -- 1. Ensure account_identity exists
  INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
  VALUES (p_id, p_customer_id, v_agent_id, 'RD')
  ON CONFLICT (id) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    updated_at = NOW();

  -- 2. Upsert into recurring_deposits
  INSERT INTO public.recurring_deposits (
    id, status, scheme_type, account_no, serial_no,
    installment_amount, interest_rate, term_years, term_months, start_date
  )
  VALUES (
    p_id, p_status, p_scheme_type, p_account_no, p_serial_no,
    p_installment_amount, p_interest_rate, p_term_years, p_term_months, p_start_date
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
    updated_at = NOW();

  -- 3. Replace nominees
  DELETE FROM public.nominees WHERE account_id = p_id;

  IF jsonb_array_length(p_nominees) > 0 THEN
    INSERT INTO public.nominees (account_id, name, relationship, custom_relationship, percentage)
    SELECT
      p_id,
      elem->>'name',
      elem->>'relationship',
      elem->>'custom_relationship',
      (elem->>'percentage')::numeric
    FROM jsonb_array_elements(p_nominees) AS elem;
  END IF;

  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
