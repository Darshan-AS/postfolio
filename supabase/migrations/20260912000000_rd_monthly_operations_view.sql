-- Migration: 20260912000000_rd_monthly_operations_view.sql
-- Goal: Create rd_monthly_operations_view to support the RD Macro Monthly Operations Hub.

DROP VIEW IF EXISTS public.rd_monthly_operations_view CASCADE;

CREATE OR REPLACE VIEW public.rd_monthly_operations_view WITH (security_invoker = true) AS
SELECT 
  i.id,
  i.rd_id,
  i.agent_id,
  ai.customer_id,
  c.name AS customer_name,
  d.account_no,
  d.serial_no,
  d.status AS deposit_status,
  d.installment_amount AS plan_installment_amount,
  i.installment_date,
  i.due_date,
  i.installment_amount,
  i.customer_paid_amount,
  i.customer_status,
  i.po_status,
  i.po_paid_date,
  i.late_fee,
  i.paid_late_fee,
  i.is_late_fee_waived,
  (
    SELECT count(*)::int
    FROM public.rd_installments prior
    WHERE prior.rd_id = i.rd_id
      AND prior.installment_date < i.installment_date
      AND prior.customer_status <> 'fullyPaid'
  ) AS prior_overdue_count,
  (
    SELECT COALESCE(sum(prior.installment_amount - prior.customer_paid_amount), 0)::numeric
    FROM public.rd_installments prior
    WHERE prior.rd_id = i.rd_id
      AND prior.installment_date < i.installment_date
      AND prior.customer_status <> 'fullyPaid'
  ) AS prior_overdue_amount
FROM public.rd_installments i
JOIN public.recurring_deposits d ON d.id = i.rd_id
JOIN public.account_identities ai ON ai.id = d.id AND ai.account_type = 'RD'
JOIN public.customers c ON c.id = ai.customer_id;
