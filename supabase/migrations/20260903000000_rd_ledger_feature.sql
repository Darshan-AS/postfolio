-- Migration: 20260903000000_rd_ledger_feature.sql
-- Goal: Introduce monthly ledger (installments) schedule and payment modes for rd_transactions, utilizing clean, high-performance database RPCs for atomic operations designed around app-driven business calculations.

-- 1. Alter recurring_deposits to add initial_paid_installments backfill column
ALTER TABLE public.recurring_deposits 
  ADD COLUMN IF NOT EXISTS initial_paid_installments INTEGER NOT NULL DEFAULT 0;

-- 2. Alter rd_transactions to support payment_mode
ALTER TABLE public.rd_transactions 
  ADD COLUMN IF NOT EXISTS payment_mode TEXT NOT NULL;

-- 3. Create rd_installments table
CREATE TABLE IF NOT EXISTS public.rd_installments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rd_id UUID REFERENCES public.recurring_deposits(id) ON DELETE CASCADE NOT NULL,
  agent_id UUID REFERENCES public.agent_profiles(id) ON DELETE CASCADE NOT NULL,
  installment_date DATE NOT NULL,
  due_date DATE NOT NULL,
  installment_amount NUMERIC NOT NULL,
  customer_paid_amount NUMERIC NOT NULL DEFAULT 0,
  customer_status TEXT NOT NULL,
  po_status TEXT NOT NULL,
  po_paid_date DATE,
  late_fee NUMERIC NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(rd_id, installment_date)
);

-- 4. Set up Row Level Security and indexes on rd_installments
ALTER TABLE public.rd_installments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Agents can manage own rd installments" ON public.rd_installments
  FOR ALL USING (agent_id = auth.uid() OR public.is_admin());

CREATE INDEX IF NOT EXISTS idx_rd_installments_rd_month 
  ON public.rd_installments(rd_id, installment_date);

-- Attach standard updated_at trigger to rd_installments
CREATE TRIGGER trigger_handle_updated_at_rd_installments
  BEFORE UPDATE ON public.rd_installments
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- 5. Set up Realtime CDC on rd_installments
ALTER TABLE public.rd_installments REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE public.rd_installments;

-- 6. Atomic RPC to create/save Recurring Deposit along with its pre-computed installments schedule
DROP FUNCTION IF EXISTS public.save_recurring_deposit(UUID, UUID, TEXT, TEXT, TEXT, TEXT, NUMERIC, NUMERIC, INTEGER, INTEGER, DATE, JSONB);

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

  -- Protect financial terms if transactions or PO payments are linked
  IF EXISTS(SELECT 1 FROM public.rd_transactions WHERE rd_id = p_id) OR
     EXISTS(SELECT 1 FROM public.rd_installments WHERE rd_id = p_id AND po_status = 'paid') THEN
    SELECT installment_amount, start_date INTO v_existing_amount, v_existing_start_date
    FROM public.recurring_deposits WHERE id = p_id;
    
    IF p_installment_amount <> v_existing_amount OR p_start_date <> v_existing_start_date THEN
      RAISE EXCEPTION 'Financial terms (installment amount and start date) cannot be modified after payments have been recorded.';
    END IF;
  END IF;

  -- Ensure account identity exists (Polymorphic upserter)
  PERFORM public.upsert_account_identity(p_id, p_customer_id, v_agent_id, 'RD');

  -- Upsert deposit record
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

  -- Replace nominees
  PERFORM public.replace_account_nominees(p_id, p_nominees);

  -- Bulk insert/upsert installments
  IF jsonb_array_length(p_installments) > 0 THEN
    -- If no transactions or PO paid installments exist, purge existing installments to avoid orphaned rows when schedule dates shift or term changes
    IF NOT EXISTS(SELECT 1 FROM public.rd_transactions WHERE rd_id = p_id) AND
       NOT EXISTS(SELECT 1 FROM public.rd_installments WHERE rd_id = p_id AND po_status = 'paid') THEN
      DELETE FROM public.rd_installments WHERE rd_id = p_id;
    END IF;

    INSERT INTO public.rd_installments (
      id, rd_id, agent_id, installment_date, due_date, installment_amount,
      customer_paid_amount, customer_status, po_status, po_paid_date, late_fee
    )
    SELECT 
      COALESCE((elem->>'id')::UUID, gen_random_uuid()),
      p_id,
      v_agent_id,
      (elem->>'installment_date')::DATE,
      (elem->>'due_date')::DATE,
      (elem->>'installment_amount')::NUMERIC,
      (elem->>'customer_paid_amount')::NUMERIC,
      (elem->>'customer_status')::TEXT,
      (elem->>'po_status')::TEXT,
      (elem->>'po_paid_date')::DATE,
      (elem->>'late_fee')::NUMERIC
    FROM jsonb_array_elements(p_installments) AS elem
    ON CONFLICT (rd_id, installment_date) DO UPDATE SET
      installment_amount = EXCLUDED.installment_amount,
      customer_paid_amount = EXCLUDED.customer_paid_amount,
      customer_status = EXCLUDED.customer_status,
      po_status = EXCLUDED.po_status,
      po_paid_date = EXCLUDED.po_paid_date,
      late_fee = EXCLUDED.late_fee,
      updated_at = NOW();
  END IF;

  RETURN p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7. Atomic RPC to log customer payment and update associated pre-calculated installments
CREATE OR REPLACE FUNCTION public.record_rd_customer_payment_allocated(
  p_transaction JSONB,
  p_installments JSONB
) RETURNS VOID AS $$
DECLARE
  v_agent_id UUID := public.assert_authenticated();
  v_transaction_id UUID;
  v_rd_id UUID;
  v_elem JSONB;
BEGIN
  v_transaction_id := (p_transaction->>'id')::UUID;
  v_rd_id := (p_transaction->>'rd_id')::UUID;

  -- Verify agent ownership of RD
  PERFORM public.assert_account_owner(v_rd_id, v_agent_id);

  -- Insert raw transaction log record
  INSERT INTO public.rd_transactions (id, rd_id, agent_id, paid_date, amount, payment_mode)
  VALUES (
    COALESCE(v_transaction_id, gen_random_uuid()),
    v_rd_id,
    v_agent_id,
    (p_transaction->>'paid_date')::DATE,
    (p_transaction->>'amount')::NUMERIC,
    (p_transaction->>'payment_mode')::TEXT
  )
  ON CONFLICT (id) DO NOTHING;

  -- Bulk update installments affected by the allocation cascade
  FOR v_elem IN SELECT * FROM jsonb_array_elements(p_installments) LOOP
    UPDATE public.rd_installments
    SET
      customer_paid_amount = (v_elem->>'customer_paid_amount')::NUMERIC,
      customer_status = (v_elem->>'customer_status')::TEXT,
      late_fee = (v_elem->>'late_fee')::NUMERIC,
      updated_at = NOW()
    WHERE id = (v_elem->>'id')::UUID AND agent_id = v_agent_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 8. Atomic RPC to update PO settlement status for installments in bulk
CREATE OR REPLACE FUNCTION public.record_rd_po_payments(
  p_installments JSONB
) RETURNS VOID AS $$
DECLARE
  v_agent_id UUID := public.assert_authenticated();
  v_elem JSONB;
BEGIN
  FOR v_elem IN SELECT * FROM jsonb_array_elements(p_installments) LOOP
    UPDATE public.rd_installments
    SET
      po_status = (v_elem->>'po_status')::TEXT,
      po_paid_date = (v_elem->>'po_paid_date')::DATE,
      updated_at = NOW()
    WHERE id = (v_elem->>'id')::UUID AND agent_id = v_agent_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 9. Update recurring_deposit_details_view to output initial_paid_installments
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
  d.created_at,
  d.updated_at,
  public.get_account_nominees(d.id) AS nominees
FROM public.recurring_deposits d
JOIN public.account_identities ai ON ai.id = d.id AND ai.account_type = 'RD'
JOIN public.customers c ON c.id = ai.customer_id;
