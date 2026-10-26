-- Migration: 20261025000000_sparse_rd_ledger_and_allocations.sql
-- Goal: Upgrade RD Ledger to Option 1+ (Sparse rd_installments + Normalized rd_payment_allocations lineage + Set-based RPC upserts & auto-pruning).

-- 1. Add split_mode intent column to rd_transactions
ALTER TABLE public.rd_transactions
  ADD COLUMN IF NOT EXISTS split_mode TEXT NOT NULL DEFAULT 'includeFees';

-- 2. Add installment_no and po_batch_id (future PO Lot support) to rd_installments
ALTER TABLE public.rd_installments
  ADD COLUMN IF NOT EXISTS installment_no INTEGER,
  ADD COLUMN IF NOT EXISTS po_batch_id UUID;

-- 3. Create normalized rd_payment_allocations table (Receipt -> Installment Month lineage)
CREATE TABLE IF NOT EXISTS public.rd_payment_allocations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID REFERENCES public.rd_transactions(id) ON DELETE CASCADE NOT NULL,
  rd_id UUID REFERENCES public.recurring_deposits(id) ON DELETE CASCADE NOT NULL,
  agent_id UUID REFERENCES public.agent_profiles(id) ON DELETE CASCADE NOT NULL,
  installment_no INTEGER NOT NULL,
  principal_amount NUMERIC NOT NULL DEFAULT 0,
  late_fee_amount NUMERIC NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(transaction_id, installment_no)
);

ALTER TABLE public.rd_payment_allocations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Agents can manage own rd payment allocations" ON public.rd_payment_allocations;
CREATE POLICY "Agents can manage own rd payment allocations" ON public.rd_payment_allocations
  FOR ALL USING (agent_id = auth.uid() OR public.is_admin());

CREATE INDEX IF NOT EXISTS idx_rd_payment_allocations_rd_month
  ON public.rd_payment_allocations(rd_id, installment_no);

CREATE INDEX IF NOT EXISTS idx_rd_payment_allocations_tx
  ON public.rd_payment_allocations(transaction_id);

-- 4. Helper function: Set-based upsert of sparse installments + automatic pruning of untouched baseline rows
CREATE OR REPLACE FUNCTION public.upsert_and_prune_rd_installments(
  p_rd_id UUID,
  p_agent_id UUID,
  p_installments JSONB
) RETURNS VOID AS $$
DECLARE
  v_start_date DATE;
  v_installment_amount NUMERIC;
  v_initial_paid INTEGER;
BEGIN
  SELECT start_date, installment_amount, initial_paid_installments
  INTO v_start_date, v_installment_amount, v_initial_paid
  FROM public.recurring_deposits
  WHERE id = p_rd_id;

  IF jsonb_array_length(COALESCE(p_installments, '[]'::jsonb)) > 0 THEN
    INSERT INTO public.rd_installments (
      id, rd_id, agent_id, installment_no, installment_date, due_date,
      installment_amount, customer_paid_amount, customer_status,
      po_status, po_paid_date, late_fee, paid_late_fee, is_late_fee_waived
    )
    SELECT
      COALESCE((elem->>'id')::UUID, gen_random_uuid()),
      p_rd_id,
      p_agent_id,
      COALESCE(
        (elem->>'installment_no')::INTEGER,
        (EXTRACT(YEAR FROM (elem->>'installment_date')::DATE)::INTEGER - EXTRACT(YEAR FROM v_start_date)::INTEGER) * 12
        + (EXTRACT(MONTH FROM (elem->>'installment_date')::DATE)::INTEGER - EXTRACT(MONTH FROM v_start_date)::INTEGER) + 1
      ),
      (elem->>'installment_date')::DATE,
      COALESCE((elem->>'due_date')::DATE, (elem->>'installment_date')::DATE),
      COALESCE((elem->>'installment_amount')::NUMERIC, v_installment_amount),
      COALESCE((elem->>'customer_paid_amount')::NUMERIC, 0),
      COALESCE((elem->>'customer_status')::TEXT, 'unpaid'),
      COALESCE((elem->>'po_status')::TEXT, 'unpaid'),
      (elem->>'po_paid_date')::DATE,
      COALESCE((elem->>'late_fee')::NUMERIC, 0),
      COALESCE((elem->>'paid_late_fee')::NUMERIC, 0),
      COALESCE((elem->>'is_late_fee_waived')::BOOLEAN, FALSE)
    FROM jsonb_array_elements(p_installments) AS elem
    WHERE (elem->>'installment_date') IS NOT NULL
    ON CONFLICT (rd_id, installment_date) DO UPDATE SET
      installment_no = COALESCE(EXCLUDED.installment_no, public.rd_installments.installment_no),
      customer_paid_amount = EXCLUDED.customer_paid_amount,
      customer_status = EXCLUDED.customer_status,
      po_status = COALESCE(
        CASE WHEN (elem ? 'po_status') THEN EXCLUDED.po_status ELSE NULL END,
        public.rd_installments.po_status
      ),
      po_paid_date = CASE
        WHEN (elem ? 'po_paid_date') THEN EXCLUDED.po_paid_date
        ELSE public.rd_installments.po_paid_date
      END,
      late_fee = EXCLUDED.late_fee,
      paid_late_fee = EXCLUDED.paid_late_fee,
      is_late_fee_waived = EXCLUDED.is_late_fee_waived,
      updated_at = NOW();

    -- Fallback for legacy payloads that only pass `id` + customer fields without `installment_date`
    UPDATE public.rd_installments i
    SET
      customer_paid_amount = COALESCE((elem->>'customer_paid_amount')::NUMERIC, i.customer_paid_amount),
      customer_status = COALESCE((elem->>'customer_status')::TEXT, i.customer_status),
      late_fee = COALESCE((elem->>'late_fee')::NUMERIC, i.late_fee),
      paid_late_fee = COALESCE((elem->>'paid_late_fee')::NUMERIC, i.paid_late_fee),
      is_late_fee_waived = COALESCE((elem->>'is_late_fee_waived')::BOOLEAN, i.is_late_fee_waived),
      updated_at = NOW()
    FROM jsonb_array_elements(p_installments) AS elem
    WHERE (elem->>'installment_date') IS NULL
      AND i.id = (elem->>'id')::UUID
      AND i.agent_id = p_agent_id;
  END IF;

  -- Prune rows that have returned to untouched baseline state (both post-onboarding and pre-onboarding)
  DELETE FROM public.rd_installments
  WHERE rd_id = p_rd_id
    AND agent_id = p_agent_id
    AND (
      (
        COALESCE(installment_no, 9999) > COALESCE(v_initial_paid, 0)
        AND customer_paid_amount = 0
        AND customer_status = 'unpaid'
        AND po_status = 'unpaid'
        AND late_fee = 0
        AND paid_late_fee = 0
        AND is_late_fee_waived = FALSE
      )
      OR (
        COALESCE(installment_no, 9999) <= COALESCE(v_initial_paid, 0)
        AND customer_paid_amount = installment_amount
        AND customer_status = 'fullyPaid'
        AND po_status = 'paid'
        AND late_fee = 0
        AND paid_late_fee = 0
        AND is_late_fee_waived = FALSE
      )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. Upgrade record_rd_customer_payment_allocated to record allocations and set-based sparse installments
CREATE OR REPLACE FUNCTION public.record_rd_customer_payment_allocated(
  p_transaction JSONB,
  p_installments JSONB,
  p_allocations JSONB DEFAULT '[]'::jsonb
) RETURNS VOID AS $$
DECLARE
  v_agent_id UUID := public.assert_authenticated();
  v_transaction_id UUID;
  v_rd_id UUID;
BEGIN
  v_transaction_id := COALESCE((p_transaction->>'id')::UUID, gen_random_uuid());
  v_rd_id := (p_transaction->>'rd_id')::UUID;

  PERFORM public.assert_account_owner(v_rd_id, v_agent_id);

  INSERT INTO public.rd_transactions (
    id, rd_id, agent_id, paid_date, amount, payment_mode,
    split_mode, installment_amount, late_fee_amount
  )
  VALUES (
    v_transaction_id,
    v_rd_id,
    v_agent_id,
    (p_transaction->>'paid_date')::DATE,
    (p_transaction->>'amount')::NUMERIC,
    (p_transaction->>'payment_mode')::TEXT,
    COALESCE((p_transaction->>'split_mode')::TEXT, 'includeFees'),
    (p_transaction->>'installment_amount')::NUMERIC,
    (p_transaction->>'late_fee_amount')::NUMERIC
  )
  ON CONFLICT (id) DO NOTHING;

  -- Insert explicit per-month allocations if provided
  IF jsonb_array_length(COALESCE(p_allocations, '[]'::jsonb)) > 0 THEN
    INSERT INTO public.rd_payment_allocations (
      id, transaction_id, rd_id, agent_id, installment_no, principal_amount, late_fee_amount
    )
    SELECT
      COALESCE((alloc->>'id')::UUID, gen_random_uuid()),
      v_transaction_id,
      v_rd_id,
      v_agent_id,
      (alloc->>'installment_no')::INTEGER,
      COALESCE((alloc->>'principal_amount')::NUMERIC, 0),
      COALESCE((alloc->>'late_fee_amount')::NUMERIC, 0)
    FROM jsonb_array_elements(p_allocations) AS alloc
    ON CONFLICT (transaction_id, installment_no) DO UPDATE SET
      principal_amount = EXCLUDED.principal_amount,
      late_fee_amount = EXCLUDED.late_fee_amount;
  END IF;

  PERFORM public.upsert_and_prune_rd_installments(v_rd_id, v_agent_id, p_installments);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6. Upgrade delete_rd_transaction to use set-based sparse updates
CREATE OR REPLACE FUNCTION public.delete_rd_transaction(
  p_transaction_id UUID,
  p_installments JSONB
) RETURNS VOID AS $$
DECLARE
  v_agent_id UUID := public.assert_authenticated();
  v_rd_id UUID;
BEGIN
  SELECT rd_id INTO v_rd_id
  FROM public.rd_transactions
  WHERE id = p_transaction_id AND agent_id = v_agent_id;

  IF v_rd_id IS NULL THEN
    RAISE EXCEPTION 'Transaction not found or access denied';
  END IF;

  PERFORM public.assert_account_owner(v_rd_id, v_agent_id);

  -- Delete transaction (cascades to rd_payment_allocations automatically)
  DELETE FROM public.rd_transactions
  WHERE id = p_transaction_id AND agent_id = v_agent_id;

  PERFORM public.upsert_and_prune_rd_installments(v_rd_id, v_agent_id, p_installments);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7. Upgrade update_rd_transaction to use set-based sparse updates
CREATE OR REPLACE FUNCTION public.update_rd_transaction(
  p_transaction JSONB,
  p_installments JSONB
) RETURNS VOID AS $$
DECLARE
  v_agent_id UUID := public.assert_authenticated();
  v_transaction_id UUID;
  v_rd_id UUID;
BEGIN
  v_transaction_id := (p_transaction->>'id')::UUID;
  v_rd_id := (p_transaction->>'rd_id')::UUID;

  PERFORM public.assert_account_owner(v_rd_id, v_agent_id);

  UPDATE public.rd_transactions
  SET
    paid_date = (p_transaction->>'paid_date')::DATE,
    amount = (p_transaction->>'amount')::NUMERIC,
    payment_mode = (p_transaction->>'payment_mode')::TEXT,
    split_mode = COALESCE((p_transaction->>'split_mode')::TEXT, split_mode),
    installment_amount = (p_transaction->>'installment_amount')::NUMERIC,
    late_fee_amount = (p_transaction->>'late_fee_amount')::NUMERIC,
    updated_at = NOW()
  WHERE id = v_transaction_id AND agent_id = v_agent_id;

  PERFORM public.upsert_and_prune_rd_installments(v_rd_id, v_agent_id, p_installments);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 8. Upgrade record_rd_po_payments to support sparse installment upserts + set-based execution
CREATE OR REPLACE FUNCTION public.record_rd_po_payments(
  p_installments JSONB
) RETURNS VOID AS $$
DECLARE
  v_agent_id UUID := public.assert_authenticated();
BEGIN
  IF jsonb_array_length(COALESCE(p_installments, '[]'::jsonb)) = 0 THEN
    RETURN;
  END IF;

  -- Upsert when full installment metadata (rd_id, installment_date) is provided
  INSERT INTO public.rd_installments (
    id, rd_id, agent_id, installment_no, installment_date, due_date,
    installment_amount, customer_paid_amount, customer_status,
    po_status, po_paid_date, late_fee, paid_late_fee, is_late_fee_waived
  )
  SELECT
    COALESCE((elem->>'id')::UUID, gen_random_uuid()),
    (elem->>'rd_id')::UUID,
    v_agent_id,
    (elem->>'installment_no')::INTEGER,
    (elem->>'installment_date')::DATE,
    COALESCE((elem->>'due_date')::DATE, (elem->>'installment_date')::DATE),
    COALESCE((elem->>'installment_amount')::NUMERIC, 0),
    COALESCE((elem->>'customer_paid_amount')::NUMERIC, 0),
    COALESCE((elem->>'customer_status')::TEXT, 'unpaid'),
    (elem->>'po_status')::TEXT,
    (elem->>'po_paid_date')::DATE,
    COALESCE((elem->>'late_fee')::NUMERIC, 0),
    COALESCE((elem->>'paid_late_fee')::NUMERIC, 0),
    COALESCE((elem->>'is_late_fee_waived')::BOOLEAN, FALSE)
  FROM jsonb_array_elements(p_installments) AS elem
  WHERE (elem->>'rd_id') IS NOT NULL AND (elem->>'installment_date') IS NOT NULL
  ON CONFLICT (rd_id, installment_date) DO UPDATE SET
    po_status = EXCLUDED.po_status,
    po_paid_date = EXCLUDED.po_paid_date,
    updated_at = NOW();

  -- Set-based update for existing rows when only (id, po_status, po_paid_date) is provided
  UPDATE public.rd_installments i
  SET
    po_status = (elem->>'po_status')::TEXT,
    po_paid_date = (elem->>'po_paid_date')::DATE,
    updated_at = NOW()
  FROM jsonb_array_elements(p_installments) AS elem
  WHERE (elem->>'rd_id') IS NULL
    AND i.id = (elem->>'id')::UUID
    AND i.agent_id = v_agent_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 9. Upgrade save_recurring_deposit to keep rd_installments sparse (0 dummy rows on creation/edit)
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
  p_installments JSONB DEFAULT '[]'::jsonb
) RETURNS UUID AS $$
DECLARE
  v_agent_id UUID := public.assert_authenticated();
  v_existing_amount NUMERIC;
  v_existing_start_date DATE;
BEGIN
  PERFORM public.assert_customer_owner(p_customer_id, v_agent_id);
  PERFORM public.assert_account_owner(p_id, v_agent_id);

  IF EXISTS(SELECT 1 FROM public.rd_transactions WHERE rd_id = p_id) OR
     EXISTS(SELECT 1 FROM public.rd_installments WHERE rd_id = p_id AND po_status = 'paid' AND COALESCE(installment_no, 9999) > p_initial_paid_installments) THEN
    SELECT installment_amount, start_date INTO v_existing_amount, v_existing_start_date
    FROM public.recurring_deposits WHERE id = p_id;

    IF p_installment_amount <> v_existing_amount OR p_start_date <> v_existing_start_date THEN
      RAISE EXCEPTION 'Financial terms (installment amount and start date) cannot be modified after payments have been recorded.';
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

  -- If no transactions or post-onboarding PO payments exist, clear any stale sparse rows when terms change
  IF NOT EXISTS(SELECT 1 FROM public.rd_transactions WHERE rd_id = p_id) AND
     NOT EXISTS(SELECT 1 FROM public.rd_installments WHERE rd_id = p_id AND po_status = 'paid' AND COALESCE(installment_no, 9999) > p_initial_paid_installments) THEN
    DELETE FROM public.rd_installments WHERE rd_id = p_id;
  END IF;

  IF jsonb_array_length(COALESCE(p_installments, '[]'::jsonb)) > 0 THEN
    PERFORM public.upsert_and_prune_rd_installments(p_id, v_agent_id, p_installments);
  END IF;

  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 10. Upgrade toggle_rd_late_fee_waiver to support waiving on both existing sparse rows and virtual unmaterialized months
CREATE OR REPLACE FUNCTION public.toggle_rd_late_fee_waiver(
  p_installment_id UUID,
  p_is_waived BOOLEAN,
  p_installment JSONB DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
  v_agent_id UUID := public.assert_authenticated();
  v_paid_late_fee NUMERIC;
  v_late_fee NUMERIC;
  v_rd_id UUID;
BEGIN
  SELECT paid_late_fee, late_fee, rd_id
  INTO v_paid_late_fee, v_late_fee, v_rd_id
  FROM public.rd_installments
  WHERE id = p_installment_id AND agent_id = v_agent_id;

  IF NOT FOUND THEN
    IF p_installment IS NOT NULL AND (p_installment->>'rd_id') IS NOT NULL THEN
      v_rd_id := (p_installment->>'rd_id')::UUID;
      PERFORM public.assert_account_owner(v_rd_id, v_agent_id);
      PERFORM public.upsert_and_prune_rd_installments(
        v_rd_id,
        v_agent_id,
        jsonb_build_array(
          p_installment || jsonb_build_object('id', p_installment_id, 'is_late_fee_waived', p_is_waived)
        )
      );
      RETURN;
    END IF;
    RAISE EXCEPTION 'Installment not found or access denied';
  END IF;

  IF p_is_waived AND v_paid_late_fee >= v_late_fee AND v_late_fee > 0 THEN
    RAISE EXCEPTION 'Cannot forgive an already paid default fee. Edit payment transaction to reallocate funds.';
  END IF;

  UPDATE public.rd_installments
  SET
    is_late_fee_waived = p_is_waived,
    updated_at = NOW()
  WHERE id = p_installment_id AND agent_id = v_agent_id;

  PERFORM public.upsert_and_prune_rd_installments(v_rd_id, v_agent_id, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
