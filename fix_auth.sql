-- ==============================================================================
-- FlipCash: Instant Auth Fix Script
-- Run this in your Supabase SQL Editor (https://supabase.com/dashboard)
-- 
-- This script fixes:
-- 1. "Email not confirmed" error (auto-confirms all users immediately)
-- 2. "Email rate limit exceeded" error (bypasses email confirmation requirement)
-- ==============================================================================

-- 1. Confirm all existing users in auth.users immediately
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;

-- 2. Automatically confirm ANY new user before insertion into auth.users
CREATE OR REPLACE FUNCTION public.auto_confirm_new_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.email_confirmed_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_auto_confirm ON auth.users;
CREATE TRIGGER on_auth_user_auto_confirm
    BEFORE INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.auto_confirm_new_user();

-- 3. Create RPC function so the Flutter app can auto-confirm any user by email
CREATE OR REPLACE FUNCTION public.confirm_user_email(user_email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE auth.users
    SET email_confirmed_at = NOW()
    WHERE LOWER(email) = LOWER(TRIM(user_email));
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.confirm_user_email(TEXT) TO anon, authenticated, service_role;

-- 4. Ensure admin account (rinshad@flipcash.com) has admin role in profiles
UPDATE public.profiles
SET role = 'admin', is_verified = TRUE, trust_score = 100
WHERE LOWER(email) = 'rinshad@flipcash.com';
