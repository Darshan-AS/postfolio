-- Migration: 20260830000000_jit_linking.sql
-- Goal: Ensure high-fidelity JIT linking of legacy placeholders when real users sign up or log in.

-- 1. Re-create Foreign Keys referencing agent_profiles with ON UPDATE CASCADE
-- This allows updating agent_profiles.id (PK) to automatically cascade to all dependent tables.

ALTER TABLE public.customers DROP CONSTRAINT IF EXISTS customers_agent_id_fkey;
ALTER TABLE public.customers 
  ADD CONSTRAINT customers_agent_id_fkey 
  FOREIGN KEY (agent_id) REFERENCES public.agent_profiles(id) 
  ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE public.account_identities DROP CONSTRAINT IF EXISTS account_identities_agent_id_fkey;
ALTER TABLE public.account_identities 
  ADD CONSTRAINT account_identities_agent_id_fkey 
  FOREIGN KEY (agent_id) REFERENCES public.agent_profiles(id) 
  ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE public.rd_transactions DROP CONSTRAINT IF EXISTS rd_transactions_agent_id_fkey;
ALTER TABLE public.rd_transactions 
  ADD CONSTRAINT rd_transactions_agent_id_fkey 
  FOREIGN KEY (agent_id) REFERENCES public.agent_profiles(id) 
  ON UPDATE CASCADE ON DELETE CASCADE;

-- 2. Drop any previous unique index on email for agent_profiles if it exists (skipping database email enforcement)
DROP INDEX IF EXISTS public.idx_agent_profiles_email;

-- 3. Upgrade handle_new_user trigger function to automatically link legacy profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_existing_id UUID;
BEGIN
    -- Check if there is an existing profile with the same email
    SELECT id INTO v_existing_id
    FROM public.agent_profiles
    WHERE email = NEW.email;

    IF v_existing_id IS NOT NULL THEN
        -- If the ID is already correct, update user metadata
        IF v_existing_id = NEW.id THEN
            UPDATE public.agent_profiles
            SET name = COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', email, name),
                updated_at = NOW()
            WHERE id = NEW.id;
        ELSE
            -- We found a legacy profile with a different ID (placeholder UUID)
            -- Update its ID to NEW.id. ON UPDATE CASCADE will automatically cascade this to all child tables!
            UPDATE public.agent_profiles
            SET id = NEW.id,
                name = COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', email, name),
                updated_at = NOW()
            WHERE id = v_existing_id;
        END IF;
    ELSE
        -- No existing profile with this email, insert a new one
        INSERT INTO public.agent_profiles (id, email, name)
        VALUES (
            NEW.id,
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', NEW.email)
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
