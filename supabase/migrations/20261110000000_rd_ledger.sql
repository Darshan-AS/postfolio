-- Migration: 20261110000000_rd_ledger.sql
-- Goal: facts-only, sequential RD ledger.
--
-- Truth is three fact tables; every derived figure (paid-through, arrears, default fees,
-- cash in hand) is projected client-side by RDLedgerProjector:
--
--   * rd_transactions    — money the customer handed to the agent (a payment is just money).
--   * rd_po_deposits     — a COUNT of installments deposited at the Post Office on a date
--                          (the DOP portal assigns months in order, so events are sequential).
--   * rd_fee_absorptions — default fees the agent paid from pocket (the PO still receives them).
--
-- rd_ledger_summary is a rebuildable per-RD cache for the Monthly Hub, never truth.
-- Onboarding may carry an opening receivable (customer already owed the agent).
-- Extensibility hooks only (no feature yet): collection_id on transactions for future household
-- lump-sum splits; batch_id on PO events for future lots / C-numbers.
--
-- The database keeps its "Muscle" responsibilities only: ownership (RLS), integrity
-- (CHECK, PK/FK), atomicity. No business rules live in SQL.

-- ------------------------------------------------------------------------------------------
-- 1. Ownership helper usable inside RLS WITH CHECK (an agent may only attach facts to own RDs)
-- ------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.owns_account(p_account_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.account_identities
    WHERE id = p_account_id AND agent_id = auth.uid()
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------------------
-- 2. recurring_deposits: onboarding terms
-- ------------------------------------------------------------------------------------------
ALTER TABLE public.recurring_deposits
  ADD COLUMN IF NOT EXISTS initial_paid_installments INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS opening_receivable NUMERIC NOT NULL DEFAULT 0
    CHECK (opening_receivable >= 0);

-- ------------------------------------------------------------------------------------------
-- 3. Fact table: customer payments (rd_transactions exists since the initial schema)
-- ------------------------------------------------------------------------------------------
ALTER TABLE public.rd_transactions
  ADD COLUMN IF NOT EXISTS payment_mode TEXT NOT NULL DEFAULT 'cash',
  ADD COLUMN IF NOT EXISTS collection_id UUID;

ALTER TABLE public.rd_transactions
  DROP CONSTRAINT IF EXISTS rd_transactions_amount_positive,
  DROP CONSTRAINT IF EXISTS rd_transactions_payment_mode_check;

ALTER TABLE public.rd_transactions
  ADD CONSTRAINT rd_transactions_amount_positive CHECK (amount > 0),
  ADD CONSTRAINT rd_transactions_payment_mode_check
    CHECK (payment_mode IN ('cash', 'upi', 'cheque', 'bankTransfer'));

-- Tighten RLS: inserting a payment against another agent's RD must fail even with own agent_id.
DROP POLICY IF EXISTS "Agents can manage own rd transactions" ON public.rd_transactions;
CREATE POLICY "Agents read own rd transactions" ON public.rd_transactions
  FOR SELECT USING (agent_id = auth.uid() OR public.is_admin());
CREATE POLICY "Agents insert own rd transactions" ON public.rd_transactions
  FOR INSERT WITH CHECK (agent_id = auth.uid() AND public.owns_account(rd_id));
CREATE POLICY "Agents update own rd transactions" ON public.rd_transactions
  FOR UPDATE USING (agent_id = auth.uid())
  WITH CHECK (agent_id = auth.uid() AND public.owns_account(rd_id));
CREATE POLICY "Agents delete own rd transactions" ON public.rd_transactions
  FOR DELETE USING (agent_id = auth.uid() OR public.is_admin());

CREATE INDEX IF NOT EXISTS idx_rd_transactions_rd_paid_date
  ON public.rd_transactions(rd_id, paid_date);
CREATE INDEX IF NOT EXISTS idx_rd_transactions_collection
  ON public.rd_transactions(collection_id) WHERE collection_id IS NOT NULL;

-- ------------------------------------------------------------------------------------------
-- 4. Fact table: Post Office deposit events (a count of installments on a date)
-- ------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rd_po_deposits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rd_id UUID NOT NULL REFERENCES public.recurring_deposits(id) ON DELETE CASCADE,
  agent_id UUID NOT NULL REFERENCES public.agent_profiles(id) ON DELETE CASCADE,
  deposited_on DATE NOT NULL,
  installment_count INTEGER NOT NULL CHECK (installment_count >= 1),
  fee_paid NUMERIC NOT NULL DEFAULT 0 CHECK (fee_paid >= 0),
  amount NUMERIC NOT NULL DEFAULT 0 CHECK (amount >= 0),
  batch_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.rd_po_deposits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Agents read own rd po deposits" ON public.rd_po_deposits
  FOR SELECT USING (agent_id = auth.uid() OR public.is_admin());
CREATE POLICY "Agents write own rd po deposits" ON public.rd_po_deposits
  FOR INSERT WITH CHECK (agent_id = auth.uid() AND public.owns_account(rd_id));
CREATE POLICY "Agents update own rd po deposits" ON public.rd_po_deposits
  FOR UPDATE USING (agent_id = auth.uid())
  WITH CHECK (agent_id = auth.uid() AND public.owns_account(rd_id));
CREATE POLICY "Agents delete own rd po deposits" ON public.rd_po_deposits
  FOR DELETE USING (agent_id = auth.uid() OR public.is_admin());

CREATE INDEX IF NOT EXISTS idx_rd_po_deposits_rd_date ON public.rd_po_deposits(rd_id, deposited_on);
CREATE INDEX IF NOT EXISTS idx_rd_po_deposits_agent ON public.rd_po_deposits(agent_id, deposited_on);
CREATE INDEX IF NOT EXISTS idx_rd_po_deposits_batch ON public.rd_po_deposits(batch_id) WHERE batch_id IS NOT NULL;

-- ------------------------------------------------------------------------------------------
-- 5. Fact table: default fees absorbed by the agent (one row per installment)
-- ------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rd_fee_absorptions (
  rd_id UUID NOT NULL REFERENCES public.recurring_deposits(id) ON DELETE CASCADE,
  agent_id UUID NOT NULL REFERENCES public.agent_profiles(id) ON DELETE CASCADE,
  installment_no INTEGER NOT NULL CHECK (installment_no >= 1),
  amount NUMERIC NOT NULL CHECK (amount > 0),
  absorbed_on DATE NOT NULL,
  note TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (rd_id, installment_no)
);

ALTER TABLE public.rd_fee_absorptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Agents read own rd fee absorptions" ON public.rd_fee_absorptions
  FOR SELECT USING (agent_id = auth.uid() OR public.is_admin());
CREATE POLICY "Agents write own rd fee absorptions" ON public.rd_fee_absorptions
  FOR INSERT WITH CHECK (agent_id = auth.uid() AND public.owns_account(rd_id));
CREATE POLICY "Agents update own rd fee absorptions" ON public.rd_fee_absorptions
  FOR UPDATE USING (agent_id = auth.uid())
  WITH CHECK (agent_id = auth.uid() AND public.owns_account(rd_id));
CREATE POLICY "Agents delete own rd fee absorptions" ON public.rd_fee_absorptions
  FOR DELETE USING (agent_id = auth.uid() OR public.is_admin());

CREATE INDEX IF NOT EXISTS idx_rd_fee_absorptions_agent ON public.rd_fee_absorptions(agent_id);

-- ------------------------------------------------------------------------------------------
-- 6. Cache table: per-RD projected summary for the Monthly Hub (rebuildable, never truth)
-- ------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rd_ledger_summary (
  rd_id UUID PRIMARY KEY REFERENCES public.recurring_deposits(id) ON DELETE CASCADE,
  agent_id UUID NOT NULL REFERENCES public.agent_profiles(id) ON DELETE CASCADE,
  facts_version BIGINT NOT NULL DEFAULT 0,
  projected_on DATE NOT NULL,
  paid_through_no INTEGER NOT NULL DEFAULT 0,
  deposited_through_no INTEGER NOT NULL DEFAULT 0,
  next_due_no INTEGER,
  customer_credit NUMERIC NOT NULL DEFAULT 0,
  opening_receivable_left NUMERIC NOT NULL DEFAULT 0,
  owed_by_customer NUMERIC NOT NULL DEFAULT 0,
  receivable NUMERIC NOT NULL DEFAULT 0,
  cash_in_hand_cash NUMERIC NOT NULL DEFAULT 0,
  cash_in_hand_digital NUMERIC NOT NULL DEFAULT 0,
  absorbed_total NUMERIC NOT NULL DEFAULT 0,
  delay_cost_total NUMERIC NOT NULL DEFAULT 0,
  arrears_count INTEGER NOT NULL DEFAULT 0,
  fee_due NUMERIC NOT NULL DEFAULT 0,
  open_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.rd_ledger_summary ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Agents read own rd ledger summary" ON public.rd_ledger_summary
  FOR SELECT USING (agent_id = auth.uid() OR public.is_admin());
CREATE POLICY "Agents insert own rd ledger summary" ON public.rd_ledger_summary
  FOR INSERT WITH CHECK (agent_id = auth.uid() AND public.owns_account(rd_id));
CREATE POLICY "Agents update own rd ledger summary" ON public.rd_ledger_summary
  FOR UPDATE USING (agent_id = auth.uid())
  WITH CHECK (agent_id = auth.uid() AND public.owns_account(rd_id));
CREATE POLICY "Agents delete own rd ledger summary" ON public.rd_ledger_summary
  FOR DELETE USING (agent_id = auth.uid() OR public.is_admin());

CREATE INDEX IF NOT EXISTS idx_rd_ledger_summary_agent ON public.rd_ledger_summary(agent_id);

DROP TRIGGER IF EXISTS trigger_handle_updated_at_rd_ledger_summary ON public.rd_ledger_summary;
CREATE TRIGGER trigger_handle_updated_at_rd_ledger_summary
  BEFORE UPDATE ON public.rd_ledger_summary
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------------------
-- 7. save_recurring_deposit: onboarding terms; financial terms lock once facts exist
-- ------------------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.save_recurring_deposit(
  UUID, UUID, TEXT, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, INTEGER, INTEGER, DATE, JSONB);

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
  v_agent_id UUID := public.assert_authenticated();
  v_existing public.recurring_deposits%ROWTYPE;
  v_locked BOOLEAN;
BEGIN
  PERFORM public.assert_customer_owner(p_customer_id, v_agent_id);
  PERFORM public.assert_account_owner(p_id, v_agent_id);

  SELECT * INTO v_existing FROM public.recurring_deposits WHERE id = p_id;

  IF FOUND THEN
    v_locked := EXISTS (SELECT 1 FROM public.rd_transactions WHERE rd_id = p_id)
      OR EXISTS (SELECT 1 FROM public.rd_po_deposits WHERE rd_id = p_id);

    IF v_locked AND (
      p_installment_amount <> v_existing.installment_amount OR
      p_start_date <> v_existing.start_date OR
      p_term_years <> v_existing.term_years OR
      p_term_months <> v_existing.term_months OR
      p_initial_paid_installments <> v_existing.initial_paid_installments OR
      p_opening_receivable <> v_existing.opening_receivable
    ) THEN
      RAISE EXCEPTION 'Financial terms cannot be modified after ledger activity has been recorded.'
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;

  PERFORM public.upsert_account_identity(p_id, p_customer_id, v_agent_id, 'RD');

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

  PERFORM public.replace_account_nominees(p_id, p_nominees);

  -- Terms changed on an unlocked account: the cached summary is now meaningless.
  DELETE FROM public.rd_ledger_summary WHERE rd_id = p_id;

  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------------------
-- 8. Views
-- ------------------------------------------------------------------------------------------
DROP VIEW IF EXISTS public.recurring_deposit_details_view CASCADE;
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
  public.get_account_nominees(d.id) AS nominees
FROM public.recurring_deposits d
JOIN public.account_identities ai ON ai.id = d.id AND ai.account_type = 'RD'
JOIN public.customers c ON c.id = ai.customer_id;

-- ------------------------------------------------------------------------------------------
-- 9. Realtime CDC for the fact tables and the summary cache
-- ------------------------------------------------------------------------------------------
ALTER TABLE public.rd_transactions REPLICA IDENTITY FULL;
ALTER TABLE public.rd_po_deposits REPLICA IDENTITY FULL;
ALTER TABLE public.rd_fee_absorptions REPLICA IDENTITY FULL;
ALTER TABLE public.rd_ledger_summary REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'rd_transactions') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rd_transactions;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'rd_po_deposits') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rd_po_deposits;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'rd_fee_absorptions') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rd_fee_absorptions;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'rd_ledger_summary') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rd_ledger_summary;
  END IF;
END $$;
