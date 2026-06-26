-- Initial Schema for Postfolio Migration (Refined)

-- 0. Helper function for updated_at triggers
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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

CREATE TRIGGER trigger_agent_profiles_updated_at
    BEFORE UPDATE ON public.agent_profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 2. Create user_roles table
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT CHECK (role IN ('admin', 'agent')) DEFAULT 'agent',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
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

CREATE TRIGGER trigger_customers_updated_at
    BEFORE UPDATE ON public.customers
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 4. Create account_identities table (Option B - Base table for polymorphic relationships)
CREATE TABLE IF NOT EXISTS public.account_identities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE NOT NULL,
    agent_id UUID REFERENCES public.agent_profiles(id) ON DELETE CASCADE NOT NULL,
    account_type TEXT NOT NULL, -- 'RD', 'OTD', 'SB', 'INSURANCE', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TRIGGER trigger_account_identities_updated_at
    BEFORE UPDATE ON public.account_identities
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5. Create savings_accounts table (Normalized)
CREATE TABLE IF NOT EXISTS public.savings_accounts (
    id UUID PRIMARY KEY REFERENCES public.account_identities(id) ON DELETE CASCADE,
    account_number TEXT NOT NULL,
    linked_date DATE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TRIGGER trigger_savings_accounts_updated_at
    BEFORE UPDATE ON public.savings_accounts
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 6. Create recurring_deposits table
CREATE TABLE IF NOT EXISTS public.recurring_deposits (
    id UUID PRIMARY KEY REFERENCES public.account_identities(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    scheme_type TEXT NOT NULL,
    account_number TEXT NOT NULL,
    serial_no TEXT,
    installment_amount NUMERIC NOT NULL,
    interest_rate NUMERIC NOT NULL,
    term_years INTEGER NOT NULL,
    term_months INTEGER NOT NULL,
    start_date DATE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TRIGGER trigger_recurring_deposits_updated_at
    BEFORE UPDATE ON public.recurring_deposits
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 7. Create one_time_deposits table
CREATE TABLE IF NOT EXISTS public.one_time_deposits (
    id UUID PRIMARY KEY REFERENCES public.account_identities(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    scheme_type TEXT NOT NULL,
    account_number TEXT NOT NULL,
    principal_amount NUMERIC NOT NULL,
    interest_rate NUMERIC NOT NULL,
    term_years INTEGER NOT NULL,
    term_months INTEGER NOT NULL,
    start_date DATE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TRIGGER trigger_one_time_deposits_updated_at
    BEFORE UPDATE ON public.one_time_deposits
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 8. Create nominees table (Polymorphic - Points to base account_identities)
CREATE TABLE IF NOT EXISTS public.nominees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID REFERENCES public.account_identities(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    relationship TEXT NOT NULL,
    share_percentage NUMERIC NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TRIGGER trigger_nominees_updated_at
    BEFORE UPDATE ON public.nominees
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 9. Create rd_transactions table (RD Only)
CREATE TABLE IF NOT EXISTS public.rd_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rd_id UUID REFERENCES public.recurring_deposits(id) ON DELETE CASCADE NOT NULL,
    agent_id UUID REFERENCES public.agent_profiles(id) ON DELETE CASCADE NOT NULL,
    paid_date DATE NOT NULL,
    amount NUMERIC NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TRIGGER trigger_rd_transactions_updated_at
    BEFORE UPDATE ON public.rd_transactions
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Enable RLS on all tables
ALTER TABLE public.agent_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_identities ENABLE ROW LEVEL SECURITY;
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

-- Account Identities: Agents can see own accounts, admins can see all
CREATE POLICY "Agents can see own account identities" ON public.account_identities
    FOR SELECT USING (agent_id = auth.uid() OR public.is_admin());

CREATE POLICY "Agents can insert own account identities" ON public.account_identities
    FOR INSERT WITH CHECK (agent_id = auth.uid());

CREATE POLICY "Agents can update own account identities" ON public.account_identities
    FOR UPDATE USING (agent_id = auth.uid());

CREATE POLICY "Agents can delete own account identities" ON public.account_identities
    FOR DELETE USING (agent_id = auth.uid());

-- Savings Accounts: Linked to account_identities
CREATE POLICY "Agents can see own savings accounts" ON public.savings_accounts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.account_identities
            WHERE id = savings_accounts.id AND (agent_id = auth.uid() OR public.is_admin())
        )
    );

-- Deposits: Linked to account_identities
CREATE POLICY "Agents can see own recurring deposits" ON public.recurring_deposits
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.account_identities
            WHERE id = recurring_deposits.id AND (agent_id = auth.uid() OR public.is_admin())
        )
    );

CREATE POLICY "Agents can see own one time deposits" ON public.one_time_deposits
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.account_identities
            WHERE id = one_time_deposits.id AND (agent_id = auth.uid() OR public.is_admin())
        )
    );

-- Nominees: Linked to account_identities
CREATE POLICY "Agents can see own nominees" ON public.nominees
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.account_identities
            WHERE id = nominees.account_id AND (agent_id = auth.uid() OR public.is_admin())
        )
    );

-- RD Transactions: Linked to recurring_deposits
CREATE POLICY "Agents can see own rd transactions" ON public.rd_transactions
    FOR SELECT USING (agent_id = auth.uid() OR public.is_admin());
