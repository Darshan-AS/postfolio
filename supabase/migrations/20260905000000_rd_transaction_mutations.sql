-- Migration: 20260905000000_rd_transaction_mutations.sql
-- Goal: Provide atomic RPCs for deleting and editing rd_transactions while updating recalculated rd_installments schedules.

-- 1. Atomic RPC to delete an RD transaction and update affected installments
CREATE OR REPLACE FUNCTION public.delete_rd_transaction(
  p_transaction_id UUID,
  p_installments JSONB
) RETURNS VOID AS $$
DECLARE
  v_agent_id UUID := public.assert_authenticated();
  v_rd_id UUID;
  v_elem JSONB;
BEGIN
  -- Look up transaction and verify ownership
  SELECT rd_id INTO v_rd_id
  FROM public.rd_transactions
  WHERE id = p_transaction_id AND agent_id = v_agent_id;

  IF v_rd_id IS NULL THEN
    RAISE EXCEPTION 'Transaction not found or access denied';
  END IF;

  PERFORM public.assert_account_owner(v_rd_id, v_agent_id);

  -- Delete transaction record
  DELETE FROM public.rd_transactions
  WHERE id = p_transaction_id AND agent_id = v_agent_id;

  -- Bulk update recomputed installments
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

-- 2. Atomic RPC to update an RD transaction and update affected installments
CREATE OR REPLACE FUNCTION public.update_rd_transaction(
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

  PERFORM public.assert_account_owner(v_rd_id, v_agent_id);

  -- Update transaction log record
  UPDATE public.rd_transactions
  SET
    paid_date = (p_transaction->>'paid_date')::DATE,
    amount = (p_transaction->>'amount')::NUMERIC,
    payment_mode = (p_transaction->>'payment_mode')::TEXT,
    updated_at = NOW()
  WHERE id = v_transaction_id AND agent_id = v_agent_id;

  -- Bulk update recomputed installments
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
