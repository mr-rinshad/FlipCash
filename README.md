# FlipCash - Peer-to-Peer Cash & Digital Currency Exchange

**FlipCash** is a modern, production-ready Flutter mobile application for peer-to-peer (P2P) cash and digital currency exchange matching.

It directly connects:
1. **Users with physical cash** who want to deposit/transfer it into their digital bank accounts (via UPI, IMPS, GPay, PhonePe, Paytm, etc.).
2. **Users with digital funds in their bank accounts** who need urgent physical cash in hand.

> **Note on Architecture:** The platform does **not** process in-app payments. It serves strictly as a high-trust, location-based discovery and matching platform to facilitate safe physical meetups in verified public venues.

---

## 🚀 Key Features Built

### 1. 🔐 Authentication & Trust Module
- **Supabase Auth with Google Sign-In:** Configured with PKCE auth flow.
- **Email & Password Authentication:** Sign-up, Sign-in, and password reset capability.
- **Instant Demo Logins:** One-tap testing as regular user (`Rahul Sharma`) or Lead Admin (`FlipCash Moderator`).
- **User Reputation & Trust Score (0-100%):** Calculates trust score based on phone verification, successful physical handovers, and 5-star ratings.

### 2. 📢 Availability & Intent Publishing (Core Feature)
- **Two Exchange Modes:**
  - 💵 **"I Have Cash" (Cash-to-Digital):** User holds physical cash notes and wants instant UPI / bank transfer.
  - 💳 **"I Need Cash" (Digital-to-Cash):** User has digital bank balance and needs physical cash in hand.
- **Parameters:**
  - Amount selection with quick chips (₹500, ₹1,000, ₹2,000, ₹5,000, ₹10,000) or custom input.
  - Accepted digital payment rails (UPI, Google Pay, PhonePe, Paytm, IMPS, Bank Transfer).
  - Meeting spot landmark (e.g., *Indiranagar Metro Gate 2*, *Starbucks Koramangala*).
  - Public venue preference (Cafe, Metro concourse, Mall).
  - Expiration time (30 min, 1h, 2h, 4h, 8h).
  - Safety checklist acknowledgement.

### 3. 🎯 Smart Search, Radar Discovery & Live Peer Navigation
- **Interactive Proximity Radar View:**
  - Custom canvas radar visualization with pulsing distance rings (1 km, 3 km, 5 km, 10 km).
  - Real-time peer blips dynamically positioned by GPS coordinates.
  - Visual color indicators (Amber for Cash-to-Digital, Blue for Digital-to-Cash).
- **Proximity Filtering:**
  - Haversine distance calculations showing exact distance (e.g. *450 m away*) and estimated walking time (*~3 mins walk*).
  - Radius slider (2 km to 30 km).
- **Turn-by-Turn Navigation:**
  - Built-in one-tap Google Maps Navigation (`https://www.google.com/maps/dir/?api=1&destination=lat,lng`).
- **Physical Handshake Verification PIN:**
  - Secure 4-digit OTP generated upon matching.
  - Recipient inspects physical banknotes, confirms bank balance in their banking app, and shares the 4-digit code to conclude the exchange.
- **In-App Meetup Chat:**
  - Real-time messaging to coordinate meeting points (*"I am wearing a blue jacket near the cafe counter"*).

### 4. 🛡️ Admin Dashboard & Moderation
- **Platform Analytics:** Active listings count, total active cash liquidity (₹), registered user base, and pending reports.
- **Listings Moderation:** Review and delete suspicious or policy-violating listings.
- **User Management:** Inspect user profiles, verify badges, or suspend/ban fraudulent users.
- **Safety Reports Management:** Review reported incidents, investigate disputes, and record moderation actions.

---

## 📁 Project Structure

```
FlipCash/
├── .env                              # Supabase URL & Anon Key (Pre-configured)
├── supabase_schema.sql               # Full PostgreSQL tables, triggers & RLS policies
├── supabase_seed.sql                 # Sample test listings & users for instant demo
├── pubspec.yaml                      # Dependencies & asset configuration
└── lib/
    ├── main.dart                     # App entry point with MultiProvider & Supabase init
    ├── core/
    │   ├── constants/
    │   │   ├── app_colors.dart       # Modern Emerald/Slate fintech theme palette
    │   │   ├── app_constants.dart    # Constants, defaults & safety guidelines
    │   │   └── app_theme.dart        # Material 3 typography & component styling
    │   ├── services/
    │   │   └── supabase_service.dart # Central Supabase API & mock fallback engine
    │   └── utils/
    │       ├── currency_formatter.dart # INR (₹) formatting with Indian numbering
    │       └── location_helper.dart  # Haversine distance, travel time & maps navigation
    ├── models/
    │   ├── user_profile.dart         # User profile, trust score, and rating model
    │   ├── exchange_request.dart     # Exchange listing intent model
    │   ├── exchange_match.dart       # Peer pairing & Handshake OTP model
    │   └── safety_report.dart        # Admin moderation & report model
    ├── providers/
    │   ├── auth_provider.dart        # User session & profile state
    │   ├── request_provider.dart     # Listings, proximity radar & matching state
    │   └── admin_provider.dart       # Admin moderation & platform analytics state
    └── screens/
        ├── splash_screen.dart        # Animated splash screen
        ├── auth/
        │   └── login_screen.dart     # Google Sign-In & Email authentication
        ├── home/
        │   ├── home_dashboard_screen.dart # Main app dashboard & navigation
        │   └── widgets/
        │       ├── quick_stats_banner.dart
        │       ├── active_request_card.dart
        │       └── safety_tip_card.dart
        ├── publish/
        │   └── publish_request_screen.dart # Publish Cash/Digital availability
        ├── search/
        │   ├── search_discovery_screen.dart # Radar Map & List search view
        │   ├── peer_navigation_screen.dart  # Live Meetup tracker & Google Maps nav
        │   └── widgets/
        │       ├── interactive_radar_map.dart # Custom radar canvas painter
        │       └── request_detail_sheet.dart  # Peer inspection modal
        ├── profile/
        │   ├── user_profile_screen.dart     # Profile, trust score & safety rules
        │   └── edit_profile_screen.dart     # Profile updater
        └── admin/
            └── admin_dashboard_screen.dart  # Admin dashboard & moderation tools
```

---

## 🗄️ Database Setup in Supabase

1. Open your [Supabase Dashboard](https://supabase.com/dashboard/project/vronmezuytwqhpgukmlm).
2. Go to the **SQL Editor** tab on the left sidebar.
3. Open `supabase_schema.sql` located in this project folder, paste its contents into the SQL Editor, and click **Run**.
4. *(Optional for demo data)* Open `supabase_seed.sql` and run it to populate active test requests in Bengaluru/Indiranagar/Koramangala.

---

## 📱 Running the Application

Ensure Flutter SDK is on your PATH, then run:

```bash
# 1. Install dependencies
flutter pub get

# 2. Run the application
flutter run
```

---

## 🔒 Safety & Scam Prevention Principles
- **No in-app escrow or payment credentials held.**
- **Meetup locations must always be well-lit, high-footfall public venues (Cafes, Metro Stations, Malls).**
- **Handshake Verification PIN:** The cash giver does not hand over physical paper cash until the cash receiver verifies the digital transfer directly in their banking app.
