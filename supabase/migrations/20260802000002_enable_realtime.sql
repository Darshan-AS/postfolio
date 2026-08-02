-- Migration: 20260802000002_enable_realtime.sql

-- Set REPLICA IDENTITY FULL so WAL CDC events contain full row details for stream listeners
ALTER TABLE public.customers REPLICA IDENTITY FULL;
ALTER TABLE public.account_identities REPLICA IDENTITY FULL;
ALTER TABLE public.savings_accounts REPLICA IDENTITY FULL;
ALTER TABLE public.one_time_deposits REPLICA IDENTITY FULL;
ALTER TABLE public.recurring_deposits REPLICA IDENTITY FULL;
ALTER TABLE public.nominees REPLICA IDENTITY FULL;
ALTER TABLE public.rd_transactions REPLICA IDENTITY FULL;

-- Enable Realtime CDC on base tables so WebSocket streams emit change events
ALTER PUBLICATION supabase_realtime ADD TABLE public.customers;
ALTER PUBLICATION supabase_realtime ADD TABLE public.account_identities;
ALTER PUBLICATION supabase_realtime ADD TABLE public.savings_accounts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.one_time_deposits;
ALTER PUBLICATION supabase_realtime ADD TABLE public.recurring_deposits;
ALTER PUBLICATION supabase_realtime ADD TABLE public.nominees;
ALTER PUBLICATION supabase_realtime ADD TABLE public.rd_transactions;
