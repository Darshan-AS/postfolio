-- Migration: 20260802000000_customer_views_and_rpcs.sql

-- 0. Helper Functions (DRY Operations & Guards)

-- Authentication Guard
CREATE OR REPLACE FUNCTION public.assert_authenticated()
RETURNS UUID AS $$
DECLARE
  v_agent_id UUID := auth.uid();
BEGIN
  IF v_agent_id IS NULL THEN
    RAISE EXCEPTION 'Unauthenticated';
  END IF;
  RETURN v_agent_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Customer Ownership Guard
CREATE OR REPLACE FUNCTION public.assert_customer_owner(p_customer_id UUID, p_agent_id UUID)
RETURNS VOID AS $$
BEGIN
  IF p_customer_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.customers WHERE id = p_customer_id AND agent_id <> p_agent_id
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Customer does not belong to active agent';
  END IF;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Account Ownership Guard
CREATE OR REPLACE FUNCTION public.assert_account_owner(p_account_id UUID, p_agent_id UUID)
RETURNS VOID AS $$
BEGIN
  IF p_account_id IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.account_identities WHERE id = p_account_id AND agent_id <> p_agent_id
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Account identity does not belong to active agent';
  END IF;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Unified Polymorphic Upsert for Account Identities
CREATE OR REPLACE FUNCTION public.upsert_account_identity(
  p_id UUID,
  p_customer_id UUID,
  p_agent_id UUID,
  p_account_type TEXT
) RETURNS UUID AS $$
DECLARE
  v_account_id UUID := p_id;
BEGIN
  -- If direct account identity ID isn't provided, try to locate an existing one of that type for the customer
  IF v_account_id IS NULL THEN
    SELECT id INTO v_account_id
    FROM public.account_identities
    WHERE customer_id = p_customer_id AND account_type = p_account_type
    ORDER BY created_at ASC
    LIMIT 1;
  END IF;

  v_account_id := COALESCE(v_account_id, gen_random_uuid());

  INSERT INTO public.account_identities (id, customer_id, agent_id, account_type)
  VALUES (v_account_id, p_customer_id, p_agent_id, p_account_type)
  ON CONFLICT (id) DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    updated_at = NOW();

  RETURN v_account_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Nominee Aggregate Helper (Read)
CREATE OR REPLACE FUNCTION public.get_account_nominees(p_account_id UUID)
RETURNS JSONB AS $$
  SELECT COALESCE(
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
      WHERE n.account_id = p_account_id
    ),
    '[]'::jsonb
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- Nominee Replacement Helper (Write)
CREATE OR REPLACE FUNCTION public.replace_account_nominees(
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 1. Create customer_details_view for clean reads
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
    'nominees', public.get_account_nominees(ai.id)
  ) AS savings_account
  FROM public.account_identities ai
  JOIN public.savings_accounts sa ON sa.id = ai.id
  WHERE ai.customer_id = c.id AND ai.account_type = 'SB'
  ORDER BY ai.created_at ASC
  LIMIT 1
) sa_lat ON true;

-- 2. Create save_customer_with_sb_account RPC function for atomic writes
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
  v_agent_id UUID := public.assert_authenticated();
BEGIN
  PERFORM public.assert_customer_owner(p_id, v_agent_id);

  p_nominees := COALESCE(p_nominees, '[]'::jsonb);

  -- 1. Insert or Update Customer
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

  -- 2. Handle Savings Account & Nominees
  IF p_sb_account_number IS NOT NULL AND TRIM(p_sb_account_number) <> '' THEN
    v_account_id := public.upsert_account_identity(NULL, v_customer_id, v_agent_id, 'SB');

    INSERT INTO public.savings_accounts (id, account_number)
    VALUES (v_account_id, TRIM(p_sb_account_number))
    ON CONFLICT (id) DO UPDATE SET account_number = EXCLUDED.account_number;

    PERFORM public.replace_account_nominees(v_account_id, p_nominees);
  ELSE
    DELETE FROM public.account_identities WHERE customer_id = v_customer_id AND account_type = 'SB';
  END IF;

  RETURN v_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
