-- ==============================================================================
-- FlipCash: Seed Script
-- Clean slate: No dummy sample users or pre-published exchange requests.
-- Sets up the admin user profile for rinshad@flipcash.com.
-- ==============================================================================

-- Remove any old test / dummy entries if they were previously inserted
DELETE FROM public.exchange_messages WHERE content LIKE '%Koramangala%' OR content LIKE '%Indiranagar%';
DELETE FROM public.exchange_matches WHERE meetup_location LIKE '%Starbucks%' OR meetup_location LIKE '%Indiranagar%';
DELETE FROM public.exchange_requests WHERE location_name LIKE '%Starbucks%' OR location_name LIKE '%Indiranagar%' OR location_name LIKE '%HSR Layout%' OR location_name LIKE '%MG Road%';
DELETE FROM public.profiles WHERE email IN ('rahul.sharma@example.com', 'priya.patel@example.com', 'arjun.verma@example.com', 'sneha.reddy@example.com', 'admin.flipcash@example.com');

-- If you have created the auth user for rinshad@flipcash.com via Supabase Auth signup,
-- this ensures their profile record has the 'admin' role:
UPDATE public.profiles
SET role = 'admin', is_verified = true, trust_score = 100
WHERE LOWER(email) = 'rinshad@flipcash.com';
