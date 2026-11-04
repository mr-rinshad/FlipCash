-- ==============================================================================
-- FlipCash: Realistic Seed Data for Development & Demonstration
-- Run this in Supabase SQL Editor if you want instant test listings & users
-- ==============================================================================

-- Create demo auth accounts / profiles if not already present
-- Note: In production, profiles are generated upon Google / Auth signup.
-- These profiles allow testing peer search and matching right away.

INSERT INTO public.profiles (id, email, full_name, avatar_url, phone_number, rating, total_reviews, successful_exchanges, trust_score, role, is_verified)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'rahul.sharma@example.com', 'Rahul Sharma', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150', '+91 98765 43210', 4.95, 28, 34, 98, 'user', true),
    ('22222222-2222-2222-2222-222222222222', 'priya.patel@example.com', 'Priya Patel', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150', '+91 98123 45678', 5.00, 19, 22, 100, 'user', true),
    ('33333333-3333-3333-3333-333333333333', 'arjun.verma@example.com', 'Arjun Verma', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150', '+91 97654 32109', 4.80, 14, 15, 92, 'user', true),
    ('44444444-4444-4444-4444-444444444444', 'sneha.reddy@example.com', 'Sneha Reddy', 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150', '+91 99887 76655', 4.90, 42, 51, 99, 'user', true),
    ('55555555-5555-5555-5555-555555555555', 'admin.flipcash@example.com', 'FlipCash Moderator', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150', '+91 90000 00001', 5.00, 100, 150, 100, 'admin', true)
ON CONFLICT (id) DO NOTHING;

-- Seed Sample Active Exchange Requests around Bengaluru & Major Hubs
INSERT INTO public.exchange_requests (
    id, user_id, exchange_type, amount, currency, preferred_payment_methods, 
    location_name, latitude, longitude, meetup_preference, notes, status, expires_at
)
VALUES
    (
        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        '11111111-1111-1111-1111-111111111111',
        'CASH_TO_DIGITAL',
        4000.00,
        'INR',
        ARRAY['UPI', 'GPay', 'PhonePe'],
        'Koramangala 5th Block, near Starbucks',
        12.9352,
        77.6245,
        'Inside Starbucks Cafe or outside near entrance',
        'Have clean ₹500 notes. Need instant UPI transfer before cash handover.',
        'ACTIVE',
        NOW() + INTERVAL '4 hours'
    ),
    (
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        '22222222-2222-2222-2222-222222222222',
        'DIGITAL_TO_CASH',
        2500.00,
        'INR',
        ARRAY['UPI', 'Paytm', 'IMPS'],
        'Indiranagar 100ft Road, Metro Station Gate 1',
        12.9784,
        77.6408,
        'Indiranagar Metro concourse ticket counter',
        'Need physical cash for local vendor shopping. Can send GPay/UPI on the spot.',
        'ACTIVE',
        NOW() + INTERVAL '2 hours'
    ),
    (
        'cccccccc-cccc-cccc-cccc-cccccccccccc',
        '33333333-3333-3333-3333-333333333333',
        'CASH_TO_DIGITAL',
        10000.00,
        'INR',
        ARRAY['UPI', 'Bank Transfer', 'NEFT'],
        'HSR Layout Sector 2, 27th Main Rd',
        12.9121,
        77.6446,
        'Near Third Wave Coffee Roasters',
        'Can split into ₹5,000 batches if needed. Full verification required.',
        'ACTIVE',
        NOW() + INTERVAL '6 hours'
    ),
    (
        'dddddddd-dddd-dddd-dddd-dddddddddddd',
        '44444444-4444-4444-4444-444444444444',
        'DIGITAL_TO_CASH',
        1500.00,
        'INR',
        ARRAY['UPI', 'PhonePe', 'GPay'],
        'MG Road Boulevard, Brigade Rd Junction',
        12.9756,
        77.6066,
        'Public seating area next to Cauvery Emporium',
        'Urgent cash needed for auto-rickshaw & market.',
        'ACTIVE',
        NOW() + INTERVAL '1 hour'
    )
ON CONFLICT (id) DO NOTHING;
