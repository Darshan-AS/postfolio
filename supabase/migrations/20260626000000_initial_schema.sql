-- Initial Schema for Postfolio Migration (Refined & Clean)

-- 0. Helper function for updated_at triggers
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. Create Tables

CREATE TABLE IF NOT EXISTS public.agent_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE RESTRICT,
    legacy_firebase_uid TEXT UNIQUE,
    name TEXT,
    email TEXT,
    agency_code TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT CHECK (role IN ('admin', 'agent')) DEFAULT 'agent',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, role)
);

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

CREATE TABLE IF NOT EXISTS public.account_identities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE NOT NULL,
    agent_id UUID REFERENCES public.agent_profiles(id) ON DELETE CASCADE NOT NULL,
    account_type TEXT NOT NULL, -- 'RD', 'OTD', 'SB', 'INSURANCE', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.savings_accounts (
    id UUID PRIMARY KEY REFERENCES public.account_identities(id) ON DELETE CASCADE,
    account_number TEXT NOT NULL,
    linked_date DATE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.recurring_deposits (
    id UUID PRIMARY KEY REFERENCES public.account_identities(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    scheme_type TEXT NOT NULL,
    account_no TEXT,
    serial_no TEXT,
    installment_amount NUMERIC NOT NULL,
    interest_rate NUMERIC NOT NULL,
    term_years INTEGER NOT NULL,
    term_months INTEGER NOT NULL,
    start_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.one_time_deposits (
    id UUID PRIMARY KEY REFERENCES public.account_identities(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    scheme_type TEXT NOT NULL,
    account_no TEXT,
    principal_amount NUMERIC NOT NULL,
    interest_rate NUMERIC NOT NULL,
    term_years INTEGER NOT NULL,
    term_months INTEGER NOT NULL,
    start_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.nominees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID REFERENCES public.account_identities(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    relationship TEXT NOT NULL,
    custom_relationship TEXT,
    percentage NUMERIC NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.rd_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rd_id UUID REFERENCES public.recurring_deposits(id) ON DELETE CASCADE NOT NULL,
    agent_id UUID REFERENCES public.agent_profiles(id) ON DELETE CASCADE NOT NULL,
    paid_date DATE NOT NULL,
    amount NUMERIC NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Dynamically attach updated_at triggers & enable RLS across all tables
DO $$
DECLARE
    t RECORD;
BEGIN
    FOR t IN SELECT table_name FROM information_schema.columns WHERE column_name = 'updated_at' AND table_schema = 'public' LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trigger_%I_updated_at ON public.%I;', t.table_name, t.table_name);
        EXECUTE format('CREATE TRIGGER trigger_%I_updated_at BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();', t.table_name, t.table_name);
    END LOOP;

    FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', t.tablename);
    END LOOP;
END $$;

-- 3. Performance Indexes for Foreign Keys and RLS Filtering
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id, role);
CREATE INDEX IF NOT EXISTS idx_customers_agent_id ON public.customers(agent_id);
CREATE INDEX IF NOT EXISTS idx_account_identities_agent_id ON public.account_identities(agent_id);
CREATE INDEX IF NOT EXISTS idx_account_identities_customer_id ON public.account_identities(customer_id);
CREATE INDEX IF NOT EXISTS idx_nominees_account_id ON public.nominees(account_id);
CREATE INDEX IF NOT EXISTS idx_rd_transactions_rd_id ON public.rd_transactions(rd_id);
CREATE INDEX IF NOT EXISTS idx_rd_transactions_agent_id ON public.rd_transactions(agent_id);

-- 4. RLS Policies

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_roles
        WHERE user_id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Agent Profiles
CREATE POLICY "Users can manage own profile" ON public.agent_profiles
    FOR ALL USING (auth.uid() = id OR public.is_admin());

-- User Roles
CREATE POLICY "Users can see own roles" ON public.user_roles
    FOR SELECT USING (user_id = auth.uid() OR public.is_admin());

-- Customers
CREATE POLICY "Agents can manage own customers" ON public.customers
    FOR ALL USING (agent_id = auth.uid() OR public.is_admin());

-- Account Identities
CREATE POLICY "Agents can manage own account identities" ON public.account_identities
    FOR ALL USING (agent_id = auth.uid() OR public.is_admin());

-- Savings Accounts (Linked to account_identities)
CREATE POLICY "Agents can manage own savings accounts" ON public.savings_accounts
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.account_identities
            WHERE id = savings_accounts.id AND (agent_id = auth.uid() OR public.is_admin())
        )
    );

-- Recurring Deposits (Linked to account_identities)
CREATE POLICY "Agents can manage own recurring deposits" ON public.recurring_deposits
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.account_identities
            WHERE id = recurring_deposits.id AND (agent_id = auth.uid() OR public.is_admin())
        )
    );

-- One Time Deposits (Linked to account_identities)
CREATE POLICY "Agents can manage own one time deposits" ON public.one_time_deposits
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.account_identities
            WHERE id = one_time_deposits.id AND (agent_id = auth.uid() OR public.is_admin())
        )
    );

-- Nominees (Linked to account_identities)
CREATE POLICY "Agents can manage own nominees" ON public.nominees
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.account_identities
            WHERE id = nominees.account_id AND (agent_id = auth.uid() OR public.is_admin())
        )
    );

-- RD Transactions (Linked to recurring_deposits)
CREATE POLICY "Agents can manage own rd transactions" ON public.rd_transactions
    FOR ALL USING (agent_id = auth.uid() OR public.is_admin());

-- 5. Automatic User Profile Creation Trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.agent_profiles (id, email, name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', NEW.email)
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        name = COALESCE(EXCLUDED.name, public.agent_profiles.name),
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. Schema Grants
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO authenticated, service_role;
