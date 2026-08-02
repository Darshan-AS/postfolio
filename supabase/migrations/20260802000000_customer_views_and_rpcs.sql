-- Migration: 20260802000000_customer_views_and_rpcs.sql

-- 1. Ensure Unique Constraint on (customer_id, account_type) for account_identities
CREATE UNIQUE INDEX IF NOT EXISTS idx_account_identities_customer_type 
    ON public.account_identities(customer_id, account_type);

-- 2. Create customer_details_view for clean reads
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
  CASE 
    WHEN sa.account_number IS NOT NULL THEN
      jsonb_build_object(
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
      )
    ELSE NULL
  END AS savings_account
FROM public.customers c
LEFT JOIN public.account_identities ai ON ai.customer_id = c.id AND ai.account_type = 'SB'
LEFT JOIN public.savings_accounts sa ON sa.id = ai.id;

-- 3. Create save_customer_with_sb_account RPC function for atomic writes
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
    INSERT INTO public.account_identities (customer_id, agent_id, account_type)
    VALUES (v_customer_id, v_agent_id, 'SB')
    ON CONFLICT (customer_id, account_type) DO UPDATE SET updated_at = NOW()
    RETURNING id INTO v_account_id;

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
$$ LANGUAGE plpgsql SECURITY DEFINER;
