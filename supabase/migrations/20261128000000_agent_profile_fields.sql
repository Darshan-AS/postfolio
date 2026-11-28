-- Migration: 20261128000000_agent_profile_fields.sql
-- Adds full India Post agent personal, licensing, KYC, and commission metadata columns
-- to `public.agent_profiles` with a Dart-mirrored CHECK constraint on `agency_types`.

ALTER TABLE public.agent_profiles
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS address TEXT,
  ADD COLUMN IF NOT EXISTS date_of_birth DATE,
  ADD COLUMN IF NOT EXISTS agency_types TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS post_office_branch TEXT,
  ADD COLUMN IF NOT EXISTS mpkby_license_no TEXT,
  ADD COLUMN IF NOT EXISTS mpkby_valid_until DATE,
  ADD COLUMN IF NOT EXISTS sas_license_no TEXT,
  ADD COLUMN IF NOT EXISTS sas_valid_until DATE,
  ADD COLUMN IF NOT EXISTS pan_number TEXT,
  ADD COLUMN IF NOT EXISTS aadhaar_number TEXT,
  ADD COLUMN IF NOT EXISTS commission_sb_account TEXT,
  ADD COLUMN IF NOT EXISTS notes TEXT;

ALTER TABLE public.agent_profiles
  DROP CONSTRAINT IF EXISTS agent_profiles_agency_type_check;

ALTER TABLE public.agent_profiles
  DROP CONSTRAINT IF EXISTS agent_profiles_agency_types_check;

ALTER TABLE public.agent_profiles
  ADD CONSTRAINT agent_profiles_agency_types_check CHECK (
    agency_types <@ ARRAY['mpkby', 'sas']::text[]
  );

NOTIFY pgrst, 'reload schema';
