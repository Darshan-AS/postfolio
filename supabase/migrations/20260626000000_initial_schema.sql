-- Initial Schema for Postfolio Migration

-- 1. Create agent_profiles table
CREATE TABLE IF NOT EXISTS public.agent_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    legacy_firebase_uid TEXT UNIQUE,
    name TEXT,
    email TEXT,
    agency_code TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create user_roles table
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT CHECK (role IN ('admin', 'agent')) DEFAULT 'agent',
    UNIQUE(user_id, role)
);

-- 3. Create customers table
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID REFERENCES public.agent_profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    phone TEXT,
    pan_number TEXT,
    email TEXT,
    address TEXT,
    cif_number TEXT,
    aadhaar_number TEXT,
    date_of_birth DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create savings_accounts table (Normalized)
CREATE TABLE IF NOT EXISTS public.savings_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE UNIQUE NOT NULL,
    account_number TEXT NOT NULL,
    linked_date DATE
);

-- 5. Create recurring_deposits table
CREATE TABLE IF NOT EXISTS public.recurring_deposits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE NOT NULL,
    agent_id UUID REFERENCES public.agent_profiles(id) ON DELETE CASCADE NOT NULL,
    status TEXT NOT NULL,
    scheme_type TEXT NOT NULL,
    account_number TEXT NOT NULL,
    serial_no TEXT,
    installment_amount NUMERIC NOT NULL,
    interest_rate NUMERIC NOT NULL,
    term_years INTEGER NOT NULL,
    term_months INTEGER NOT NULL,
    start_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Create one_time_deposits table
CREATE TABLE IF NOT EXISTS public.one_time_deposits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE NOT NULL,
    agent_id UUID REFERENCES public.agent_profiles(id) ON DELETE CASCADE NOT NULL,
    status TEXT NOT NULL,
    scheme_type TEXT NOT NULL,
    account_number TEXT NOT NULL,
    principal_amount NUMERIC NOT NULL,
    interest_rate NUMERIC NOT NULL,
    term_years INTEGER NOT NULL,
    term_months INTEGER NOT NULL,
    start_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Create nominees table (Normalized)
CREATE TABLE IF NOT EXISTS public.nominees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recurring_deposit_id UUID REFERENCES public.recurring_deposits(id) ON DELETE CASCADE,
    one_time_deposit_id UUID REFERENCES public.one_time_deposits(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    relationship TEXT NOT NULL,
    share_percentage NUMERIC NOT NULL,
    CONSTRAINT one_deposit_only CHECK (
        (recurring_deposit_id IS NOT NULL AND one_time_deposit_id IS NULL) OR
        (recurring_deposit_id IS NULL AND one_time_deposit_id IS NOT NULL)
    )
);

-- 8. Create rd_transactions table
CREATE TABLE IF NOT EXISTS public.rd_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rd_id UUID REFERENCES public.recurring_deposits(id) ON DELETE CASCADE NOT NULL,
    agent_id UUID REFERENCES public.agent_profiles(id) ON DELETE CASCADE NOT NULL,
    paid_date DATE NOT NULL,
    amount NUMERIC NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE public.agent_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.savings_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recurring_deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.one_time_deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nominees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rd_transactions ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Agent Profiles: Users can see their own profile, admins can see all
CREATE POLICY "Users can see own profile" ON public.agent_profiles
    FOR SELECT USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "Users can update own profile" ON public.agent_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Customers: Agents can see own customers, admins can see all
CREATE POLICY "Agents can see own customers" ON public.customers
    FOR SELECT USING (agent_id = auth.uid() OR public.is_admin());

CREATE POLICY "Agents can insert own customers" ON public.customers
    FOR INSERT WITH CHECK (agent_id = auth.uid());

CREATE POLICY "Agents can update own customers" ON public.customers
    FOR UPDATE USING (agent_id = auth.uid());

CREATE POLICY "Agents can delete own customers" ON public.customers
    FOR DELETE USING (agent_id = auth.uid());

-- Savings Accounts: Linked to customers
CREATE POLICY "Agents can see own savings accounts" ON public.savings_accounts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.customers
            WHERE id = savings_accounts.customer_id AND (agent_id = auth.uid() OR public.is_admin())
        )
    );

-- Deposits: Agents can see own deposits, admins can see all
CREATE POLICY "Agents can see own recurring deposits" ON public.recurring_deposits
    FOR SELECT USING (agent_id = auth.uid() OR public.is_admin());

CREATE POLICY "Agents can see own one time deposits" ON public.one_time_deposits
    FOR SELECT USING (agent_id = auth.uid() OR public.is_admin());

-- Nominees: Linked to deposits
CREATE POLICY "Agents can see own nominees" ON public.nominees
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.recurring_deposits
            WHERE id = nominees.recurring_deposit_id AND (agent_id = auth.uid() OR public.is_admin())
        ) OR
        EXISTS (
            SELECT 1 FROM public.one_time_deposits
            WHERE id = nominees.one_time_deposit_id AND (agent_id = auth.uid() OR public.is_admin())
        )
    );
