-- Migration: 20261028000000_sequential_rd_ledger.sql
-- Goal: align the facts-only RD ledger with how the Post Office and the DOP agent portal
-- actually behave (Phase 7, "Sequential ledger"):
--
--   * PO deposits are a COUNT of installments on a date (the portal assigns months in order),
--     so `rd_po_deposits` becomes an event table instead of one row per month.
--   * The default fee is inseparable from its installment at the counter, so a payment is
--     just money: the split_mode / component columns on `rd_transactions` go away.
--   * "Waiving" a fee never happens at the PO — the agent pays it from pocket. `rd_fee_waivers`
--     becomes `rd_fee_absorptions` with an amount.
--   * Onboarding may carry an opening receivable (customer already owed the agent).
--   * Extensibility hooks only (no feature yet): `collection_id` on transactions for future
--     household lump-sum splits; `batch_id` on PO events for future lots / C-numbers.
--
-- The database keeps its "Muscle" responsibilities only (ownership, integrity, atomicity).

-- ------------------------------------------------------------------------------------------
-- 1. recurring_deposits: opening receivable
-- ------------------------------------------------------------------------------------------
ALTER TABLE public.recurring_deposits
  ADD COLUMN IF NOT EXISTS opening_receivable NUMERIC NOT NULL DEFAULT 0
    CHECK (opening_receivable >= 0);

-- ------------------------------------------------------------------------------------------
-- 2. rd_transactions: a payment is just money
-- ------------------------------------------------------------------------------------------
ALTER TABLE public.rd_transactions
  DROP CONSTRAINT IF EXISTS rd_transactions_components_non_negative,
  DROP CONSTRAINT IF EXISTS rd_transactions_split_mode_check,
  DROP CONSTRAINT IF EXISTS rd_transactions_custom_split_balances;

ALTER TABLE public.rd_transactions
  DROP COLUMN IF EXISTS split_mode,
  DROP COLUMN IF EXISTS installment_amount,
  DROP COLUMN IF EXISTS late_fee_amount,
  ADD COLUMN IF NOT EXISTS collection_id UUID;

CREATE INDEX IF NOT EXISTS idx_rd_transactions_collection
  ON public.rd_transactions(collection_id) WHERE collection_id IS NOT NULL;

-- ------------------------------------------------------------------------------------------
-- 3. rd_po_deposits: per-month rows -> sequential events
-- ------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rd_po_deposit_events (
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

-- Collapse legacy per-month rows into one event per (rd, deposited_on). Months were
-- contiguous by construction of the previous backfill, so the count is exact.
INSERT INTO public.rd_po_deposit_events (rd_id, agent_id, deposited_on, installment_count, fee_paid, amount, batch_id, created_at)
SELECT
  p.rd_id,
  p.agent_id,
  p.deposited_on,
  COUNT(*)::INTEGER,
  0,
  COUNT(*) * d.installment_amount,
  MIN(p.batch_id::text)::uuid,
  MIN(p.created_at)
FROM public.rd_po_deposits p
JOIN public.recurring_deposits d ON d.id = p.rd_id
GROUP BY p.rd_id, p.agent_id, p.deposited_on, d.installment_amount;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'rd_po_deposits'
  ) THEN
    ALTER PUBLICATION supabase_realtime DROP TABLE public.rd_po_deposits;
  END IF;
END $$;

DROP TABLE IF EXISTS public.rd_po_deposits CASCADE;
ALTER TABLE public.rd_po_deposit_events RENAME TO rd_po_deposits;

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

ALTER TABLE public.rd_po_deposits REPLICA IDENTITY FULL;

-- ------------------------------------------------------------------------------------------
-- 4. rd_fee_waivers -> rd_fee_absorptions (agent pays the fee; PO still receives it)
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

-- Legacy waivers carried no amount; the projector caps absorption at the actual fee, so a
-- generous constant keeps the old intent ("fee forgiven in full").
INSERT INTO public.rd_fee_absorptions (rd_id, agent_id, installment_no, amount, absorbed_on, note, created_at)
SELECT rd_id, agent_id, installment_no, 1000000, waived_on, note, created_at
FROM public.rd_fee_waivers
ON CONFLICT (rd_id, installment_no) DO NOTHING;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'rd_fee_waivers'
  ) THEN
    ALTER PUBLICATION supabase_realtime DROP TABLE public.rd_fee_waivers;
  END IF;
END $$;
DROP TABLE IF EXISTS public.rd_fee_waivers CASCADE;

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
ALTER TABLE public.rd_fee_absorptions REPLICA IDENTITY FULL;

-- ------------------------------------------------------------------------------------------
-- 5. Summary cache: new counters (the app rebuilds rows on first Hub load)
-- ------------------------------------------------------------------------------------------
TRUNCATE TABLE public.rd_ledger_summary;

ALTER TABLE public.rd_ledger_summary
  DROP COLUMN IF EXISTS cash_in_hand,
  DROP COLUMN IF EXISTS pocket_advance,
  ADD COLUMN IF NOT EXISTS deposited_through_no INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS opening_receivable_left NUMERIC NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS owed_by_customer NUMERIC NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS receivable NUMERIC NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS cash_in_hand_cash NUMERIC NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS cash_in_hand_digital NUMERIC NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS absorbed_total NUMERIC NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS delay_cost_total NUMERIC NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS arrears_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fee_due NUMERIC NOT NULL DEFAULT 0;

-- ------------------------------------------------------------------------------------------
-- 6. save_recurring_deposit: accept opening_receivable; terms lock uses the event table
-- ------------------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.save_recurring_deposit(
  UUID, UUID, TEXT, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, INTEGER, INTEGER, DATE, JSONB, INTEGER);

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

  DELETE FROM public.rd_ledger_summary WHERE rd_id = p_id;

  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------------------
-- 7. Views & realtime
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

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'rd_po_deposits') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rd_po_deposits;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'rd_fee_absorptions') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rd_fee_absorptions;
  END IF;
END $$;
