-- ==============================================================================
-- FlipCash: P2P Cash & Digital Currency Exchange Database Schema
-- Run this script in your Supabase SQL Editor (https://supabase.com/dashboard)
-- ==============================================================================

-- 1. Create custom types
DO $$ BEGIN
    CREATE TYPE exchange_type_enum AS ENUM ('CASH_TO_DIGITAL', 'DIGITAL_TO_CASH');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE request_status_enum AS ENUM ('ACTIVE', 'MATCHED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'EXPIRED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE match_status_enum AS ENUM ('PROPOSED', 'ACCEPTED', 'ARRIVED', 'COMPLETED', 'CANCELLED', 'DISPUTED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE report_status_enum AS ENUM ('PENDING', 'INVESTIGATING', 'RESOLVED', 'DISMISSED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Profiles Table (Extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    phone_number TEXT,
    rating NUMERIC(3,2) DEFAULT 5.00,
    total_reviews INTEGER DEFAULT 0,
    successful_exchanges INTEGER DEFAULT 0,
    trust_score INTEGER DEFAULT 100, -- 0 to 100
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    is_verified BOOLEAN DEFAULT false,
    is_banned BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Exchange Requests Table (Core Availability & Intent Postings)
CREATE TABLE IF NOT EXISTS public.exchange_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    exchange_type TEXT NOT NULL CHECK (exchange_type IN ('CASH_TO_DIGITAL', 'DIGITAL_TO_CASH')),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    currency TEXT DEFAULT 'INR',
    preferred_payment_methods TEXT[] DEFAULT ARRAY['UPI', 'GPay', 'PhonePe', 'Paytm', 'Bank Transfer'],
    location_name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    meetup_preference TEXT DEFAULT 'Public Place (Cafe, Metro, Mall)',
    notes TEXT,
    status TEXT DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'MATCHED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'EXPIRED')),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for location & status filtering
CREATE INDEX IF NOT EXISTS idx_requests_status ON public.exchange_requests(status);
CREATE INDEX IF NOT EXISTS idx_requests_type ON public.exchange_requests(exchange_type);
CREATE INDEX IF NOT EXISTS idx_requests_coords ON public.exchange_requests(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_requests_created ON public.exchange_requests(created_at DESC);

-- 4. Exchange Matches Table (Peer pairing & physical handshake)
CREATE TABLE IF NOT EXISTS public.exchange_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES public.exchange_requests(id) ON DELETE CASCADE,
    requester_id UUID NOT NULL REFERENCES public.profiles(id),
    peer_id UUID NOT NULL REFERENCES public.profiles(id),
    status TEXT DEFAULT 'PROPOSED' CHECK (status IN ('PROPOSED', 'ACCEPTED', 'ARRIVED', 'COMPLETED', 'CANCELLED', 'DISPUTED')),
    agreed_amount NUMERIC(12,2) NOT NULL,
    meetup_location TEXT,
    handshake_otp TEXT, -- 4-digit code generated for physical exchange verification
    peer_latitude DOUBLE PRECISION,
    peer_longitude DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_matches_users ON public.exchange_matches(requester_id, peer_id);

-- 5. Exchange Messages (In-app meetup coordination)
CREATE TABLE IF NOT EXISTS public.exchange_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID NOT NULL REFERENCES public.exchange_matches(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Safety Reports (Admin Moderation & Platform Safety)
CREATE TABLE IF NOT EXISTS public.safety_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reported_by UUID NOT NULL REFERENCES public.profiles(id),
    reported_user_id UUID REFERENCES public.profiles(id),
    request_id UUID REFERENCES public.exchange_requests(id) ON DELETE SET NULL,
    reason TEXT NOT NULL,
    details TEXT,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'INVESTIGATING', 'RESOLVED', 'DISMISSED')),
    admin_action TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- 7. Reviews Table (Peer feedback & rating)
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID REFERENCES public.exchange_matches(id) ON DELETE SET NULL,
    reviewer_id UUID NOT NULL REFERENCES public.profiles(id),
    reviewee_id UUID NOT NULL REFERENCES public.profiles(id),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- AUTOMATIC PROFILE CREATION TRIGGER (When user signs in via Supabase Auth)
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (
        id, 
        email, 
        full_name, 
        avatar_url, 
        phone_number,
        rating,
        trust_score,
        role
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', ''),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        5.00,
        100,
        CASE 
            WHEN LOWER(NEW.email) = 'rinshad@flipcash.com' OR LOWER(NEW.email) LIKE '%admin%' THEN 'admin' 
            ELSE 'user' 
        END
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(public.profiles.full_name, EXCLUDED.full_name),
        avatar_url = CASE WHEN EXCLUDED.avatar_url <> '' THEN EXCLUDED.avatar_url ELSE public.profiles.avatar_url END,
        role = CASE 
            WHEN LOWER(EXCLUDED.email) = 'rinshad@flipcash.com' OR LOWER(EXCLUDED.email) LIKE '%admin%' THEN 'admin' 
            ELSE public.profiles.role 
        END,
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger definition for auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-confirm trigger so users never get blocked by "Email not confirmed"
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

-- RPC function allowing the app to auto-confirm any user by email
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

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exchange_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exchange_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exchange_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.safety_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Profiles: Publicly viewable, users can edit own profile, admins can manage all
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Profiles are viewable by everyone" 
    ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" 
    ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" 
    ON public.profiles FOR UPDATE USING (auth.uid() = id OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

-- Exchange Requests: Viewable by everyone (if active), owners & admins can edit
DROP POLICY IF EXISTS "Active requests are viewable by all" ON public.exchange_requests;
CREATE POLICY "Active requests are viewable by all" 
    ON public.exchange_requests FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own requests" ON public.exchange_requests;
CREATE POLICY "Users can insert own requests" 
    ON public.exchange_requests FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own requests" ON public.exchange_requests;
CREATE POLICY "Users can update own requests" 
    ON public.exchange_requests FOR UPDATE USING (auth.uid() = user_id OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

DROP POLICY IF EXISTS "Users can delete own requests" ON public.exchange_requests;
CREATE POLICY "Users can delete own requests" 
    ON public.exchange_requests FOR DELETE USING (auth.uid() = user_id OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

-- Matches
DROP POLICY IF EXISTS "Match participants can view match" ON public.exchange_matches;
CREATE POLICY "Match participants can view match" 
    ON public.exchange_matches FOR SELECT 
    USING (auth.uid() = requester_id OR auth.uid() = peer_id);

DROP POLICY IF EXISTS "Users can create matches" ON public.exchange_matches;
CREATE POLICY "Users can create matches" 
    ON public.exchange_matches FOR INSERT WITH CHECK (auth.uid() = peer_id OR auth.uid() = requester_id);

DROP POLICY IF EXISTS "Match participants can update match" ON public.exchange_matches;
CREATE POLICY "Match participants can update match" 
    ON public.exchange_matches FOR UPDATE 
    USING (auth.uid() = requester_id OR auth.uid() = peer_id);

-- Messages
DROP POLICY IF EXISTS "Message viewable by match participants" ON public.exchange_messages;
CREATE POLICY "Message viewable by match participants" 
    ON public.exchange_messages FOR SELECT 
    USING (EXISTS (
        SELECT 1 FROM public.exchange_matches 
        WHERE id = public.exchange_messages.match_id 
        AND (requester_id = auth.uid() OR peer_id = auth.uid())
    ));

DROP POLICY IF EXISTS "Message insertable by match participants" ON public.exchange_messages;
CREATE POLICY "Message insertable by match participants" 
    ON public.exchange_messages FOR INSERT 
    WITH CHECK (auth.uid() = sender_id);

-- Reports
DROP POLICY IF EXISTS "Anyone can submit a safety report" ON public.safety_reports;
CREATE POLICY "Anyone can submit a safety report" 
    ON public.safety_reports FOR INSERT WITH CHECK (auth.uid() = reported_by);

DROP POLICY IF EXISTS "Admins or reporters can view reports" ON public.safety_reports;
CREATE POLICY "Admins or reporters can view reports" 
    ON public.safety_reports FOR SELECT 
    USING (auth.uid() = reported_by OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

DROP POLICY IF EXISTS "Admins can update reports" ON public.safety_reports;
CREATE POLICY "Admins can update reports" 
    ON public.safety_reports FOR UPDATE 
    USING (EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

-- Reviews
DROP POLICY IF EXISTS "Reviews viewable by everyone" ON public.reviews;
CREATE POLICY "Reviews viewable by everyone" 
    ON public.reviews FOR SELECT USING (true);

DROP POLICY IF EXISTS "Reviewer can insert review" ON public.reviews;
CREATE POLICY "Reviewer can insert review" 
    ON public.reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- Storage bucket for avatar image uploads
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Authenticated users can upload avatar images" ON storage.objects;
CREATE POLICY "Authenticated users can upload avatar images"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can update own avatar images" ON storage.objects;
CREATE POLICY "Users can update own avatar images"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'avatars');
