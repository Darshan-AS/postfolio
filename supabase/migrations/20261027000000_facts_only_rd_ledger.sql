-- Migration: 20261027000000_facts_only_rd_ledger.sql
-- Goal: Replace the persisted, client-written RD installment ledger with a facts-only schema.
--
-- Truth is now three fact tables (customer payments, PO deposits, fee waivers). Every derived
-- figure (paid amounts, statuses, default fees, arrears) is projected client-side by
-- RDLedgerProjector. `rd_ledger_summary` is a rebuildable per-RD cache for the Monthly Hub.
--
-- The database keeps its "Muscle" responsibilities only: ownership (RLS), integrity (CHECK,
-- PK/FK), atomicity. No business rules live in SQL.

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
-- 2. Fact table: Post Office deposits (one row per deposited month)
-- ------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rd_po_deposits (
  rd_id UUID NOT NULL REFERENCES public.recurring_deposits(id) ON DELETE CASCADE,
  agent_id UUID NOT NULL REFERENCES public.agent_profiles(id) ON DELETE CASCADE,
  installment_no INTEGER NOT NULL CHECK (installment_no >= 1),
  deposited_on DATE NOT NULL,
  batch_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (rd_id, installment_no)
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

CREATE INDEX IF NOT EXISTS idx_rd_po_deposits_agent ON public.rd_po_deposits(agent_id, deposited_on);
CREATE INDEX IF NOT EXISTS idx_rd_po_deposits_batch ON public.rd_po_deposits(batch_id) WHERE batch_id IS NOT NULL;

-- ------------------------------------------------------------------------------------------
-- 3. Fact table: default-fee waivers (one row per waived month)
-- ------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rd_fee_waivers (
  rd_id UUID NOT NULL REFERENCES public.recurring_deposits(id) ON DELETE CASCADE,
  agent_id UUID NOT NULL REFERENCES public.agent_profiles(id) ON DELETE CASCADE,
  installment_no INTEGER NOT NULL CHECK (installment_no >= 1),
  waived_on DATE NOT NULL,
  note TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (rd_id, installment_no)
);

ALTER TABLE public.rd_fee_waivers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Agents read own rd fee waivers" ON public.rd_fee_waivers
  FOR SELECT USING (agent_id = auth.uid() OR public.is_admin());
CREATE POLICY "Agents write own rd fee waivers" ON public.rd_fee_waivers
  FOR INSERT WITH CHECK (agent_id = auth.uid() AND public.owns_account(rd_id));
CREATE POLICY "Agents update own rd fee waivers" ON public.rd_fee_waivers
  FOR UPDATE USING (agent_id = auth.uid())
  WITH CHECK (agent_id = auth.uid() AND public.owns_account(rd_id));
CREATE POLICY "Agents delete own rd fee waivers" ON public.rd_fee_waivers
  FOR DELETE USING (agent_id = auth.uid() OR public.is_admin());

CREATE INDEX IF NOT EXISTS idx_rd_fee_waivers_agent ON public.rd_fee_waivers(agent_id);

-- ------------------------------------------------------------------------------------------
-- 4. Harden the existing fact table: rd_transactions
-- ------------------------------------------------------------------------------------------
ALTER TABLE public.rd_transactions
  ALTER COLUMN installment_amount SET DEFAULT 0,
  ALTER COLUMN late_fee_amount SET DEFAULT 0;

UPDATE public.rd_transactions
SET installment_amount = COALESCE(installment_amount, 0),
    late_fee_amount = COALESCE(late_fee_amount, 0)
WHERE installment_amount IS NULL OR late_fee_amount IS NULL;

ALTER TABLE public.rd_transactions
  ALTER COLUMN installment_amount SET NOT NULL,
  ALTER COLUMN late_fee_amount SET NOT NULL;

ALTER TABLE public.rd_transactions
  DROP CONSTRAINT IF EXISTS rd_transactions_amount_positive,
  DROP CONSTRAINT IF EXISTS rd_transactions_components_non_negative,
  DROP CONSTRAINT IF EXISTS rd_transactions_payment_mode_check,
  DROP CONSTRAINT IF EXISTS rd_transactions_split_mode_check,
  DROP CONSTRAINT IF EXISTS rd_transactions_custom_split_balances;

ALTER TABLE public.rd_transactions
  ADD CONSTRAINT rd_transactions_amount_positive CHECK (amount > 0),
  ADD CONSTRAINT rd_transactions_components_non_negative
    CHECK (installment_amount >= 0 AND late_fee_amount >= 0),
  ADD CONSTRAINT rd_transactions_payment_mode_check
    CHECK (payment_mode IN ('cash', 'upi', 'cheque', 'bankTransfer')),
  ADD CONSTRAINT rd_transactions_split_mode_check
    CHECK (split_mode IN ('installmentsOnly', 'includeFees', 'feesOnly', 'custom')),
  ADD CONSTRAINT rd_transactions_custom_split_balances
    CHECK (split_mode <> 'custom' OR installment_amount + late_fee_amount = amount);

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

-- ------------------------------------------------------------------------------------------
-- 5. Cache table: per-RD projected summary for the Monthly Hub (rebuildable, never truth)
-- ------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.rd_ledger_summary (
  rd_id UUID PRIMARY KEY REFERENCES public.recurring_deposits(id) ON DELETE CASCADE,
  agent_id UUID NOT NULL REFERENCES public.agent_profiles(id) ON DELETE CASCADE,
  facts_version BIGINT NOT NULL DEFAULT 0,
  projected_on DATE NOT NULL,
  paid_through_no INTEGER NOT NULL DEFAULT 0,
  next_due_no INTEGER,
  customer_credit NUMERIC NOT NULL DEFAULT 0,
  cash_in_hand NUMERIC NOT NULL DEFAULT 0,
  pocket_advance NUMERIC NOT NULL DEFAULT 0,
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
-- 6. Backfill facts from the legacy materialised ledger (idempotent)
-- ------------------------------------------------------------------------------------------
INSERT INTO public.rd_po_deposits (rd_id, agent_id, installment_no, deposited_on, batch_id)
SELECT
  i.rd_id,
  i.agent_id,
  COALESCE(
    i.installment_no,
    (EXTRACT(YEAR FROM i.installment_date)::INTEGER - EXTRACT(YEAR FROM d.start_date)::INTEGER) * 12
      + (EXTRACT(MONTH FROM i.installment_date)::INTEGER - EXTRACT(MONTH FROM d.start_date)::INTEGER) + 1
  ) AS installment_no,
  COALESCE(i.po_paid_date, i.due_date, i.installment_date),
  NULL
FROM public.rd_installments i
JOIN public.recurring_deposits d ON d.id = i.rd_id
WHERE i.po_status = 'paid'
  AND COALESCE(
    i.installment_no,
    (EXTRACT(YEAR FROM i.installment_date)::INTEGER - EXTRACT(YEAR FROM d.start_date)::INTEGER) * 12
      + (EXTRACT(MONTH FROM i.installment_date)::INTEGER - EXTRACT(MONTH FROM d.start_date)::INTEGER) + 1
  ) > d.initial_paid_installments
ON CONFLICT (rd_id, installment_no) DO NOTHING;

INSERT INTO public.rd_fee_waivers (rd_id, agent_id, installment_no, waived_on)
SELECT
  i.rd_id,
  i.agent_id,
  COALESCE(
    i.installment_no,
    (EXTRACT(YEAR FROM i.installment_date)::INTEGER - EXTRACT(YEAR FROM d.start_date)::INTEGER) * 12
      + (EXTRACT(MONTH FROM i.installment_date)::INTEGER - EXTRACT(MONTH FROM d.start_date)::INTEGER) + 1
  ),
  COALESCE(i.updated_at::DATE, CURRENT_DATE)
FROM public.rd_installments i
JOIN public.recurring_deposits d ON d.id = i.rd_id
WHERE i.is_late_fee_waived = TRUE
ON CONFLICT (rd_id, installment_no) DO NOTHING;

-- ------------------------------------------------------------------------------------------
-- 7. Retire the derived-state machinery
-- ------------------------------------------------------------------------------------------
DROP VIEW IF EXISTS public.rd_monthly_operations_view CASCADE;

DROP FUNCTION IF EXISTS public.upsert_and_prune_rd_installments(UUID, UUID, JSONB);
DROP FUNCTION IF EXISTS public.record_rd_customer_payment_allocated(JSONB, JSONB, JSONB);
DROP FUNCTION IF EXISTS public.record_rd_customer_payment_allocated(JSONB, JSONB);
DROP FUNCTION IF EXISTS public.delete_rd_transaction(UUID, JSONB);
DROP FUNCTION IF EXISTS public.update_rd_transaction(JSONB, JSONB);
DROP FUNCTION IF EXISTS public.record_rd_po_payments(JSONB);
DROP FUNCTION IF EXISTS public.toggle_rd_late_fee_waiver(UUID, BOOLEAN, JSONB);
DROP FUNCTION IF EXISTS public.toggle_rd_late_fee_waiver(UUID, BOOLEAN);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'rd_installments'
  ) THEN
    ALTER PUBLICATION supabase_realtime DROP TABLE public.rd_installments;
  END IF;
END $$;

DROP TABLE IF EXISTS public.rd_payment_allocations CASCADE;
DROP TABLE IF EXISTS public.rd_installments CASCADE;

-- ------------------------------------------------------------------------------------------
-- 8. save_recurring_deposit: terms lock now derives from facts; no installment payload
-- ------------------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.save_recurring_deposit(
  UUID, UUID, TEXT, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, INTEGER, INTEGER, DATE, JSONB, INTEGER, JSONB);
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
  p_initial_paid_installments INTEGER DEFAULT 0
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
      OR EXISTS (
        SELECT 1 FROM public.rd_po_deposits
        WHERE rd_id = p_id AND installment_no > v_existing.initial_paid_installments
      );

    IF v_locked AND (
      p_installment_amount <> v_existing.installment_amount OR
      p_start_date <> v_existing.start_date OR
      p_term_years <> v_existing.term_years OR
      p_term_months <> v_existing.term_months OR
      p_initial_paid_installments <> v_existing.initial_paid_installments
    ) THEN
      RAISE EXCEPTION 'Financial terms cannot be modified after ledger activity has been recorded.'
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;

  PERFORM public.upsert_account_identity(p_id, p_customer_id, v_agent_id, 'RD');

  INSERT INTO public.recurring_deposits (
    id, status, scheme_type, account_no, serial_no,
    installment_amount, interest_rate, term_years, term_months, start_date,
    initial_paid_installments
  )
  VALUES (
    p_id, p_status, p_scheme_type, p_account_no, p_serial_no,
    p_installment_amount, p_interest_rate, p_term_years, p_term_months, p_start_date,
    p_initial_paid_installments
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
    updated_at = NOW();

  PERFORM public.replace_account_nominees(p_id, p_nominees);

  -- Terms changed on an unlocked account: the cached summary is now meaningless.
  DELETE FROM public.rd_ledger_summary WHERE rd_id = p_id;

  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ------------------------------------------------------------------------------------------
-- 9. Realtime CDC for the fact tables and the summary cache
-- ------------------------------------------------------------------------------------------
ALTER TABLE public.rd_po_deposits REPLICA IDENTITY FULL;
ALTER TABLE public.rd_fee_waivers REPLICA IDENTITY FULL;
ALTER TABLE public.rd_ledger_summary REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'rd_po_deposits') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rd_po_deposits;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'rd_fee_waivers') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rd_fee_waivers;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'rd_ledger_summary') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rd_ledger_summary;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'rd_transactions') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rd_transactions;
  END IF;
END $$;
