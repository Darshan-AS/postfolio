-- Migration: 20260802000000_customer_views_and_rpcs.sql

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
  v_agent_id UUID := auth.uid();
BEGIN
  IF v_agent_id IS NULL THEN
    RAISE EXCEPTION 'Unauthenticated';
  END IF;

  p_nominees := COALESCE(p_nominees, '[]'::jsonb);

  -- Security Check: Ensure target customer belongs to the active agent if updating existing
  IF p_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.customers WHERE id = p_id AND agent_id <> v_agent_id) THEN
    RAISE EXCEPTION 'Unauthorized: Customer does not belong to active agent';
  END IF;

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
    SELECT id INTO v_account_id
    FROM public.account_identities
    WHERE customer_id = v_customer_id AND account_type = 'SB'
    ORDER BY created_at ASC
    LIMIT 1;

    IF v_account_id IS NULL THEN
      INSERT INTO public.account_identities (customer_id, agent_id, account_type)
      VALUES (v_customer_id, v_agent_id, 'SB')
      RETURNING id INTO v_account_id;
    ELSE
      UPDATE public.account_identities
      SET updated_at = NOW()
      WHERE id = v_account_id;
    END IF;

    INSERT INTO public.savings_accounts (id, account_number)
    VALUES (v_account_id, TRIM(p_sb_account_number))
    ON CONFLICT (id) DO UPDATE SET account_number = EXCLUDED.account_number;

    DELETE FROM public.nominees WHERE account_id = v_account_id;

    IF jsonb_array_length(p_nominees) > 0 THEN
      INSERT INTO public.nominees (account_id, name, relationship, custom_relationship, percentage)
      SELECT
        v_account_id,
        elem->>'name',
        elem->>'relationship',
        elem->>'custom_relationship',
        (elem->>'percentage')::numeric
      FROM jsonb_array_elements(p_nominees) AS elem;
    END IF;
  ELSE
    DELETE FROM public.account_identities WHERE customer_id = v_customer_id AND account_type = 'SB';
  END IF;

  RETURN v_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
