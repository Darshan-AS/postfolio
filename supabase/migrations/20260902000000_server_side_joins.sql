-- Migration: 20260902000000_server_side_joins.sql
-- Goal: Update views public.one_time_deposit_details_view and public.recurring_deposit_details_view to join with public.customers and return customer_name.

-- Drop views first to avoid Postgres CREATE OR REPLACE column structure alteration errors on production
DROP VIEW IF EXISTS public.one_time_deposit_details_view CASCADE;
DROP VIEW IF EXISTS public.recurring_deposit_details_view CASCADE;

-- 1. Create one_time_deposit_details_view
CREATE OR REPLACE VIEW public.one_time_deposit_details_view WITH (security_invoker = true) AS
SELECT 
  d.id,
  ai.agent_id,
  ai.customer_id,
  c.name AS customer_name,
  d.status,
  d.scheme_type,
  d.account_no,
  d.principal_amount,
  d.interest_rate,
  d.term_years,
  d.term_months,
  d.start_date,
  d.created_at,
  d.updated_at,
  public.get_account_nominees(d.id) AS nominees
FROM public.one_time_deposits d
JOIN public.account_identities ai ON ai.id = d.id AND ai.account_type = 'OTD'
JOIN public.customers c ON c.id = ai.customer_id;

-- 2. Update recurring_deposit_details_view
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
  d.created_at,
  d.updated_at,
  public.get_account_nominees(d.id) AS nominees
FROM public.recurring_deposits d
JOIN public.account_identities ai ON ai.id = d.id AND ai.account_type = 'RD'
JOIN public.customers c ON c.id = ai.customer_id;
