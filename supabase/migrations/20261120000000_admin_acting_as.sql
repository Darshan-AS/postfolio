-- ==========================================================================================
-- Admin Acting-As (CRUD) + Audit Trail
-- ==========================================================================================
-- Allows users with `role = 'admin'` in `public.user_roles` to inspect and (when explicitly
-- unlocked on the client) perform full CRUD on another agent's portfolio without swapping
-- Supabase Auth tokens.
--
-- Design invariants:
--   * Backwards-compatible: every updated write RPC adds `p_agent_id UUID DEFAULT NULL`.
--     Shipped v2.4.0 clients omitting `p_agent_id` resolve to `auth.uid()`.
--   * No ambiguous overloads: each updated RPC drops its previous signature before creating
--     the new one in the same migration transaction.
--   * Future-proof authorization seam: `private.can_access_agent(target_id, mode)` is the
--     single place to extend if user-consented support grants or portfolio sharing are added.
--   * Cross-agent isolation: admin writes on `rd_*` tables require `agent_id` to match the
--     target `account_identities.agent_id`, and `DELETE`s scope to `agent_id = v_agent_id`.
--   * Unforgeable audit trail: `public.admin_audit_logs` records both session events
--     (`start`, `end`) and every admin RPC mutation where `v_agent_id <> auth.uid()`.
-- ==========================================================================================

-- ------------------------------------------------------------------------------------------
-- 1. Centralized Authorization & Acting-Agent Helpers (`private` schema)
-- ------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.can_access_agent(
  p_target_agent_id UUID,
  p_mode TEXT DEFAULT 'read'
) RETURNS BOOLEAN AS $$
BEGIN
  IF auth.uid() IS NULL OR p_target_agent_id IS NULL THEN
    RETURN FALSE;
  END IF;
  IF auth.uid() = p_target_agent_id THEN
    RETURN TRUE;
  END IF;
  RETURN public.is_admin();
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, private;

CREATE OR REPLACE FUNCTION private.resolve_acting_agent(
  p_target_agent_id UUID DEFAULT NULL,
  p_mode TEXT DEFAULT 'write'
) RETURNS UUID AS $$
DECLARE
  v_caller_id UUID := private.assert_authenticated();
BEGIN
  IF p_target_agent_id IS NULL OR p_target_agent_id = v_caller_id THEN
    RETURN v_caller_id;
  END IF;

  IF NOT private.can_access_agent(p_target_agent_id, p_mode) THEN
    RAISE EXCEPTION 'Unauthorized: cannot act as agent %', p_target_agent_id
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.agent_profiles WHERE id = p_target_agent_id) THEN
    RAISE EXCEPTION 'Target agent not found'
      USING ERRCODE = 'no_data_found';
  END IF;

  RETURN p_target_agent_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, private;

REVOKE ALL ON FUNCTION private.can_access_agent(UUID, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.resolve_acting_agent(UUID, TEXT) FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------------------------------------
-- 2. Admin Audit Log (`public.admin_audit_logs`) & Admin RPCs
-- ------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_agent_id UUID NOT NULL REFERENCES public.agent_profiles(id) ON UPDATE CASCADE ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (
    action IN (
      'start',
      'end',
      'rpc:save_customer_with_sb_account',
      'rpc:save_one_time_deposit',
      'rpc:save_recurring_deposit',
      'rpc:set_deposit_status',
      'rpc:delete_customer',
      'rpc:apply_rd_ledger_change'
    )
  ),
  record_id UUID,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_created_at
  ON public.admin_audit_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_target_created_at
  ON public.admin_audit_logs (target_agent_id, created_at DESC);

ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.admin_audit_logs FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.admin_audit_logs TO authenticated;
GRANT ALL ON public.admin_audit_logs TO service_role;

DROP POLICY IF EXISTS "Admins can read admin audit logs" ON public.admin_audit_logs;
CREATE POLICY "Admins can read admin audit logs" ON public.admin_audit_logs
  FOR SELECT USING (public.is_admin());

CREATE OR REPLACE FUNCTION public.log_admin_acting_as_event(
  p_target_agent_id UUID,
  p_action TEXT,
  p_record_id UUID DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
  v_caller_id UUID := private.assert_authenticated();
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF p_target_agent_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.agent_profiles WHERE id = p_target_agent_id
  ) THEN
    RAISE EXCEPTION 'Target agent not found'
      USING ERRCODE = 'no_data_found';
  END IF;

  INSERT INTO public.admin_audit_logs (admin_id, target_agent_id, action, record_id)
  VALUES (v_caller_id, p_target_agent_id, p_action, p_record_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

CREATE OR REPLACE FUNCTION public.list_agents_for_admin()
RETURNS TABLE (
  id UUID,
  name TEXT,
  email TEXT,
  agency_code TEXT
) AS $$
BEGIN
  PERFORM private.assert_authenticated();
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  RETURN QUERY
  SELECT ap.id, ap.name, ap.email, ap.agency_code
  FROM public.agent_profiles ap
  ORDER BY LOWER(COALESCE(NULLIF(TRIM(ap.name), ''), NULLIF(TRIM(ap.email), ''), ap.id::text)) ASC,
           ap.id ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, private;

-- ------------------------------------------------------------------------------------------
-- 3. Update `rd_*` Write RLS Policies for Admin CRUD (strictly matched to RD owner)
-- ------------------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Agents insert own rd transactions" ON public.rd_transactions;
CREATE POLICY "Agents insert own rd transactions" ON public.rd_transactions
  FOR INSERT WITH CHECK (
    (agent_id = auth.uid() AND public.owns_account(rd_id))
    OR (
      public.is_admin() AND EXISTS (
        SELECT 1 FROM public.account_identities ai
        WHERE ai.id = rd_id AND ai.agent_id = rd_transactions.agent_id
      )
    )
  );

DROP POLICY IF EXISTS "Agents update own rd transactions" ON public.rd_transactions;
CREATE POLICY "Agents update own rd transactions" ON public.rd_transactions
  FOR UPDATE
  USING (agent_id = auth.uid() OR public.is_admin())
  WITH CHECK (
    (agent_id = auth.uid() AND public.owns_account(rd_id))
    OR (
      public.is_admin() AND EXISTS (
        SELECT 1 FROM public.account_identities ai
        WHERE ai.id = rd_id AND ai.agent_id = rd_transactions.agent_id
      )
    )
  );

DROP POLICY IF EXISTS "Agents write own rd po deposits" ON public.rd_po_deposits;
CREATE POLICY "Agents write own rd po deposits" ON public.rd_po_deposits
  FOR INSERT WITH CHECK (
    (agent_id = auth.uid() AND public.owns_account(rd_id))
    OR (
      public.is_admin() AND EXISTS (
        SELECT 1 FROM public.account_identities ai
        WHERE ai.id = rd_id AND ai.agent_id = rd_po_deposits.agent_id
      )
    )
  );

DROP POLICY IF EXISTS "Agents update own rd po deposits" ON public.rd_po_deposits;
CREATE POLICY "Agents update own rd po deposits" ON public.rd_po_deposits
  FOR UPDATE
  USING (agent_id = auth.uid() OR public.is_admin())
  WITH CHECK (
    (agent_id = auth.uid() AND public.owns_account(rd_id))
    OR (
      public.is_admin() AND EXISTS (
        SELECT 1 FROM public.account_identities ai
        WHERE ai.id = rd_id AND ai.agent_id = rd_po_deposits.agent_id
      )
    )
  );

DROP POLICY IF EXISTS "Agents write own rd fee absorptions" ON public.rd_fee_absorptions;
CREATE POLICY "Agents write own rd fee absorptions" ON public.rd_fee_absorptions
  FOR INSERT WITH CHECK (
    (agent_id = auth.uid() AND public.owns_account(rd_id))
    OR (
      public.is_admin() AND EXISTS (
        SELECT 1 FROM public.account_identities ai
        WHERE ai.id = rd_id AND ai.agent_id = rd_fee_absorptions.agent_id
      )
    )
  );

DROP POLICY IF EXISTS "Agents update own rd fee absorptions" ON public.rd_fee_absorptions;
CREATE POLICY "Agents update own rd fee absorptions" ON public.rd_fee_absorptions
  FOR UPDATE
  USING (agent_id = auth.uid() OR public.is_admin())
  WITH CHECK (
    (agent_id = auth.uid() AND public.owns_account(rd_id))
    OR (
      public.is_admin() AND EXISTS (
        SELECT 1 FROM public.account_identities ai
        WHERE ai.id = rd_id AND ai.agent_id = rd_fee_absorptions.agent_id
      )
    )
  );

DROP POLICY IF EXISTS "Agents insert own rd ledger summary" ON public.rd_ledger_summary;
CREATE POLICY "Agents insert own rd ledger summary" ON public.rd_ledger_summary
  FOR INSERT WITH CHECK (
    (agent_id = auth.uid() AND public.owns_account(rd_id))
    OR (
      public.is_admin() AND EXISTS (
        SELECT 1 FROM public.account_identities ai
        WHERE ai.id = rd_id AND ai.agent_id = rd_ledger_summary.agent_id
      )
    )
  );

DROP POLICY IF EXISTS "Agents update own rd ledger summary" ON public.rd_ledger_summary;
CREATE POLICY "Agents update own rd ledger summary" ON public.rd_ledger_summary
  FOR UPDATE
  USING (agent_id = auth.uid() OR public.is_admin())
  WITH CHECK (
    (agent_id = auth.uid() AND public.owns_account(rd_id))
    OR (
      public.is_admin() AND EXISTS (
        SELECT 1 FROM public.account_identities ai
        WHERE ai.id = rd_id AND ai.agent_id = rd_ledger_summary.agent_id
      )
    )
  );

-- ------------------------------------------------------------------------------------------
-- 4. Update the 6 Write RPC Envelopes (drop old signatures, add `p_agent_id UUID DEFAULT NULL`)
-- ------------------------------------------------------------------------------------------

-- 4a. save_customer_with_sb_account
DROP FUNCTION IF EXISTS public.save_customer_with_sb_account(
  UUID, TEXT, TEXT, TEXT, TEXT, TEXT, DATE, TEXT, TEXT, TEXT, TEXT, JSONB
);

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
  p_nominees JSONB DEFAULT '[]'::jsonb,
  p_agent_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_customer_id UUID;
  v_account_id UUID;
  v_agent_id UUID := private.resolve_acting_agent(p_agent_id, 'write');
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
    WHERE customer_id = v_customer_id AND account_type = 'SB' AND agent_id = v_agent_id;
  END IF;

  IF v_agent_id <> auth.uid() THEN
    PERFORM public.log_admin_acting_as_event(
      v_agent_id, 'rpc:save_customer_with_sb_account', v_customer_id
    );
  END IF;

  RETURN v_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

-- 4b. save_one_time_deposit
DROP FUNCTION IF EXISTS public.save_one_time_deposit(
  UUID, UUID, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, INTEGER, INTEGER, DATE, JSONB
);

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
  p_nominees JSONB DEFAULT '[]'::jsonb,
  p_agent_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_agent_id UUID := private.resolve_acting_agent(p_agent_id, 'write');
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

  IF v_agent_id <> auth.uid() THEN
    PERFORM public.log_admin_acting_as_event(v_agent_id, 'rpc:save_one_time_deposit', p_id);
  END IF;

  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

-- 4c. save_recurring_deposit
DROP FUNCTION IF EXISTS public.save_recurring_deposit(
  UUID, UUID, TEXT, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, INTEGER, INTEGER, DATE, JSONB, INTEGER, NUMERIC
);

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
  p_opening_receivable NUMERIC DEFAULT 0,
  p_agent_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_agent_id UUID := private.resolve_acting_agent(p_agent_id, 'write');
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

  IF v_agent_id <> auth.uid() THEN
    PERFORM public.log_admin_acting_as_event(v_agent_id, 'rpc:save_recurring_deposit', p_id);
  END IF;

  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

-- 4d. set_deposit_status
DROP FUNCTION IF EXISTS public.set_deposit_status(UUID, TEXT);

CREATE OR REPLACE FUNCTION public.set_deposit_status(
  p_id UUID,
  p_status TEXT,
  p_agent_id UUID DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
  v_agent_id UUID := private.resolve_acting_agent(p_agent_id, 'write');
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

  IF v_agent_id <> auth.uid() THEN
    PERFORM public.log_admin_acting_as_event(v_agent_id, 'rpc:set_deposit_status', p_id);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, private;

-- 4e. delete_customer (SECURITY INVOKER: RLS applies + explicit agent_id scoping)
DROP FUNCTION IF EXISTS public.delete_customer(UUID);

CREATE OR REPLACE FUNCTION public.delete_customer(
  p_id UUID,
  p_agent_id UUID DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_agent_id UUID;
  v_deleted_count INTEGER := 0;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Unauthenticated'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF p_agent_id IS NULL OR p_agent_id = v_caller_id THEN
    v_agent_id := v_caller_id;
  ELSE
    IF NOT public.is_admin() THEN
      RAISE EXCEPTION 'Unauthorized: cannot act as agent %', p_agent_id
        USING ERRCODE = 'insufficient_privilege';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.agent_profiles WHERE id = p_agent_id) THEN
      RAISE EXCEPTION 'Target agent not found'
        USING ERRCODE = 'no_data_found';
    END IF;
    v_agent_id := p_agent_id;
  END IF;

  DELETE FROM public.account_identities
  WHERE customer_id = p_id AND account_type = 'SB' AND agent_id = v_agent_id;

  DELETE FROM public.customers
  WHERE id = p_id AND agent_id = v_agent_id;
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

  IF v_deleted_count > 0 AND v_agent_id <> v_caller_id THEN
    PERFORM public.log_admin_acting_as_event(v_agent_id, 'rpc:delete_customer', p_id);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER SET search_path = public;

-- 4f. apply_rd_ledger_change (SECURITY INVOKER: RLS applies + explicit agent_id scoping)
DROP FUNCTION IF EXISTS public.apply_rd_ledger_change(
  JSONB, UUID[], JSONB, UUID[], JSONB, JSONB, JSONB
);

CREATE OR REPLACE FUNCTION public.apply_rd_ledger_change(
  p_upsert_transactions JSONB DEFAULT '[]'::jsonb,
  p_delete_transaction_ids UUID[] DEFAULT '{}'::uuid[],
  p_insert_po_deposits JSONB DEFAULT '[]'::jsonb,
  p_delete_po_deposit_ids UUID[] DEFAULT '{}'::uuid[],
  p_upsert_fee_absorptions JSONB DEFAULT '[]'::jsonb,
  p_delete_fee_absorptions JSONB DEFAULT '[]'::jsonb,
  p_summaries JSONB DEFAULT '[]'::jsonb,
  p_agent_id UUID DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_agent_id UUID;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Unauthenticated'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  IF p_agent_id IS NULL OR p_agent_id = v_caller_id THEN
    v_agent_id := v_caller_id;
  ELSE
    IF NOT public.is_admin() THEN
      RAISE EXCEPTION 'Unauthorized: cannot act as agent %', p_agent_id
        USING ERRCODE = 'insufficient_privilege';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM public.agent_profiles WHERE id = p_agent_id) THEN
      RAISE EXCEPTION 'Target agent not found'
        USING ERRCODE = 'no_data_found';
    END IF;
    v_agent_id := p_agent_id;
  END IF;

  DELETE FROM public.rd_transactions
  WHERE id = ANY (COALESCE(p_delete_transaction_ids, '{}'::uuid[]))
    AND agent_id = v_agent_id;

  DELETE FROM public.rd_po_deposits
  WHERE id = ANY (COALESCE(p_delete_po_deposit_ids, '{}'::uuid[]))
    AND agent_id = v_agent_id;

  DELETE FROM public.rd_fee_absorptions a
  USING jsonb_to_recordset(COALESCE(p_delete_fee_absorptions, '[]'::jsonb))
    AS d(rd_id UUID, installment_no INTEGER)
  WHERE a.rd_id = d.rd_id
    AND a.installment_no = d.installment_no
    AND a.agent_id = v_agent_id;

  INSERT INTO public.rd_transactions (
    id, rd_id, agent_id, paid_date, amount, payment_mode, collection_id
  )
  SELECT t.id, t.rd_id, v_agent_id, t.paid_date, t.amount, t.payment_mode, t.collection_id
  FROM jsonb_to_recordset(COALESCE(p_upsert_transactions, '[]'::jsonb))
    AS t(id UUID, rd_id UUID, paid_date DATE, amount NUMERIC, payment_mode TEXT, collection_id UUID)
  ON CONFLICT (id) DO UPDATE SET
    agent_id = EXCLUDED.agent_id,
    paid_date = EXCLUDED.paid_date,
    amount = EXCLUDED.amount,
    payment_mode = EXCLUDED.payment_mode,
    collection_id = EXCLUDED.collection_id;

  INSERT INTO public.rd_po_deposits (
    id, rd_id, agent_id, deposited_on, installment_count, fee_paid, amount, batch_id
  )
  SELECT e.id, e.rd_id, v_agent_id, e.deposited_on, e.installment_count,
         COALESCE(e.fee_paid, 0), COALESCE(e.amount, 0), e.batch_id
  FROM jsonb_to_recordset(COALESCE(p_insert_po_deposits, '[]'::jsonb))
    AS e(id UUID, rd_id UUID, deposited_on DATE, installment_count INTEGER,
         fee_paid NUMERIC, amount NUMERIC, batch_id UUID)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.rd_fee_absorptions (
    rd_id, agent_id, installment_no, amount, absorbed_on, note
  )
  SELECT a.rd_id, v_agent_id, a.installment_no, a.amount, a.absorbed_on, a.note
  FROM jsonb_to_recordset(COALESCE(p_upsert_fee_absorptions, '[]'::jsonb))
    AS a(rd_id UUID, installment_no INTEGER, amount NUMERIC, absorbed_on DATE, note TEXT)
  ON CONFLICT (rd_id, installment_no) DO UPDATE SET
    amount = EXCLUDED.amount,
    absorbed_on = EXCLUDED.absorbed_on,
    note = EXCLUDED.note;

  INSERT INTO public.rd_ledger_summary (
    rd_id, agent_id, facts_version, projected_on, paid_through_no, deposited_through_no,
    next_due_no, customer_credit, opening_receivable_left, owed_by_customer, receivable,
    cash_in_hand_cash, cash_in_hand_digital, absorbed_total, delay_cost_total,
    arrears_count, fee_due, open_items
  )
  SELECT
    s.rd_id, v_agent_id, COALESCE(s.facts_version, 0), s.projected_on,
    COALESCE(s.paid_through_no, 0), COALESCE(s.deposited_through_no, 0), s.next_due_no,
    COALESCE(s.customer_credit, 0), COALESCE(s.opening_receivable_left, 0),
    COALESCE(s.owed_by_customer, 0), COALESCE(s.receivable, 0),
    COALESCE(s.cash_in_hand_cash, 0), COALESCE(s.cash_in_hand_digital, 0),
    COALESCE(s.absorbed_total, 0), COALESCE(s.delay_cost_total, 0),
    COALESCE(s.arrears_count, 0), COALESCE(s.fee_due, 0),
    COALESCE(s.open_items, '[]'::jsonb)
  FROM jsonb_to_recordset(COALESCE(p_summaries, '[]'::jsonb)) AS s(
    rd_id UUID, facts_version BIGINT, projected_on DATE, paid_through_no INTEGER,
    deposited_through_no INTEGER, next_due_no INTEGER, customer_credit NUMERIC,
    opening_receivable_left NUMERIC, owed_by_customer NUMERIC, receivable NUMERIC,
    cash_in_hand_cash NUMERIC, cash_in_hand_digital NUMERIC, absorbed_total NUMERIC,
    delay_cost_total NUMERIC, arrears_count INTEGER, fee_due NUMERIC, open_items JSONB
  )
  ON CONFLICT (rd_id) DO UPDATE SET
    facts_version = EXCLUDED.facts_version,
    projected_on = EXCLUDED.projected_on,
    paid_through_no = EXCLUDED.paid_through_no,
    deposited_through_no = EXCLUDED.deposited_through_no,
    next_due_no = EXCLUDED.next_due_no,
    customer_credit = EXCLUDED.customer_credit,
    opening_receivable_left = EXCLUDED.opening_receivable_left,
    owed_by_customer = EXCLUDED.owed_by_customer,
    receivable = EXCLUDED.receivable,
    cash_in_hand_cash = EXCLUDED.cash_in_hand_cash,
    cash_in_hand_digital = EXCLUDED.cash_in_hand_digital,
    absorbed_total = EXCLUDED.absorbed_total,
    delay_cost_total = EXCLUDED.delay_cost_total,
    arrears_count = EXCLUDED.arrears_count,
    fee_due = EXCLUDED.fee_due,
    open_items = EXCLUDED.open_items;

  IF v_agent_id <> v_caller_id THEN
    PERFORM public.log_admin_acting_as_event(v_agent_id, 'rpc:apply_rd_ledger_change', NULL);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER SET search_path = public;

-- ------------------------------------------------------------------------------------------
-- 5. Least-Privilege Grants for New & Updated Functions
-- ------------------------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.log_admin_acting_as_event(UUID, TEXT, UUID)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.log_admin_acting_as_event(UUID, TEXT, UUID)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.list_agents_for_admin()
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_agents_for_admin()
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.save_customer_with_sb_account(
  UUID, TEXT, TEXT, TEXT, TEXT, TEXT, DATE, TEXT, TEXT, TEXT, TEXT, JSONB, UUID
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_customer_with_sb_account(
  UUID, TEXT, TEXT, TEXT, TEXT, TEXT, DATE, TEXT, TEXT, TEXT, TEXT, JSONB, UUID
) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.save_one_time_deposit(
  UUID, UUID, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, INTEGER, INTEGER, DATE, JSONB, UUID
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_one_time_deposit(
  UUID, UUID, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, INTEGER, INTEGER, DATE, JSONB, UUID
) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.save_recurring_deposit(
  UUID, UUID, TEXT, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, INTEGER, INTEGER, DATE, JSONB, INTEGER, NUMERIC, UUID
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_recurring_deposit(
  UUID, UUID, TEXT, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, INTEGER, INTEGER, DATE, JSONB, INTEGER, NUMERIC, UUID
) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.set_deposit_status(UUID, TEXT, UUID)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_deposit_status(UUID, TEXT, UUID)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.delete_customer(UUID, UUID)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_customer(UUID, UUID)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.apply_rd_ledger_change(
  JSONB, UUID[], JSONB, UUID[], JSONB, JSONB, JSONB, UUID
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.apply_rd_ledger_change(
  JSONB, UUID[], JSONB, UUID[], JSONB, JSONB, JSONB, UUID
) TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';
