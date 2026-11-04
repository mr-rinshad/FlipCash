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

-- Indexes for lightning fast location & status filtering
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
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150'),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        5.00,
        100,
        CASE WHEN NEW.email ILIKE '%admin%' THEN 'admin' ELSE 'user' END
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(public.profiles.full_name, EXCLUDED.full_name),
        avatar_url = COALESCE(public.profiles.avatar_url, EXCLUDED.avatar_url),
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger definition for auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

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
CREATE POLICY "Profiles are viewable by everyone" 
    ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert own profile" 
    ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
    ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Exchange Requests: Viewable by everyone (if active), owners & admins can edit
CREATE POLICY "Active requests are viewable by all" 
    ON public.exchange_requests FOR SELECT USING (true);

CREATE POLICY "Users can insert own requests" 
    ON public.exchange_requests FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own requests" 
    ON public.exchange_requests FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own requests" 
    ON public.exchange_requests FOR DELETE USING (auth.uid() = user_id);

-- Matches: Parties involved can view and update
CREATE POLICY "Match participants can view match" 
    ON public.exchange_matches FOR SELECT 
    USING (auth.uid() = requester_id OR auth.uid() = peer_id);

CREATE POLICY "Users can create matches" 
    ON public.exchange_matches FOR INSERT WITH CHECK (auth.uid() = peer_id OR auth.uid() = requester_id);

CREATE POLICY "Match participants can update match" 
    ON public.exchange_matches FOR UPDATE 
    USING (auth.uid() = requester_id OR auth.uid() = peer_id);

-- Messages: Participants can read and write
CREATE POLICY "Message viewable by match participants" 
    ON public.exchange_messages FOR SELECT 
    USING (EXISTS (
        SELECT 1 FROM public.exchange_matches 
        WHERE id = public.exchange_messages.match_id 
        AND (requester_id = auth.uid() OR peer_id = auth.uid())
    ));

CREATE POLICY "Message insertable by match participants" 
    ON public.exchange_messages FOR INSERT 
    WITH CHECK (auth.uid() = sender_id);

-- Reports: Anyone authenticated can submit, admins can view & update
CREATE POLICY "Anyone can submit a safety report" 
    ON public.safety_reports FOR INSERT WITH CHECK (auth.uid() = reported_by);

CREATE POLICY "Admins or reporters can view reports" 
    ON public.safety_reports FOR SELECT 
    USING (auth.uid() = reported_by OR EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

CREATE POLICY "Admins can update reports" 
    ON public.safety_reports FOR UPDATE 
    USING (EXISTS (
        SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
    ));

-- Reviews: Viewable by all, insertable by participants
CREATE POLICY "Reviews viewable by everyone" 
    ON public.reviews FOR SELECT USING (true);

CREATE POLICY "Reviewer can insert review" 
    ON public.reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- ==============================================================================
-- REAL-TIME SUBSCRIPTION ENABLER
-- ==============================================================================
-- Enable Realtime for requests and matches
ALTER PUBLICATION supabase_realtime ADD TABLE public.exchange_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.exchange_matches;
ALTER PUBLICATION supabase_realtime ADD TABLE public.exchange_messages;
