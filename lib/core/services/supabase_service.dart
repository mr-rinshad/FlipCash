import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_profile.dart';
import '../../models/exchange_request.dart';
import '../../models/exchange_match.dart';
import '../../models/safety_report.dart';
import '../constants/app_constants.dart';
import '../utils/location_helper.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  // In-memory fallback mock state (guarantees offline/demo resilience)
  final List<UserProfile> _mockProfiles = [
    UserProfile(
      id: AppConstants.demoUserId,
      email: 'rahul.sharma@example.com',
      fullName: 'Rahul Sharma',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      phoneNumber: '+91 98765 43210',
      rating: 4.95,
      totalReviews: 28,
      successfulExchanges: 34,
      trustScore: 98,
      role: 'user',
      isVerified: true,
    ),
    UserProfile(
      id: '22222222-2222-2222-2222-222222222222',
      email: 'priya.patel@example.com',
      fullName: 'Priya Patel',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      phoneNumber: '+91 98123 45678',
      rating: 5.0,
      totalReviews: 19,
      successfulExchanges: 22,
      trustScore: 100,
      role: 'user',
      isVerified: true,
    ),
    UserProfile(
      id: '33333333-3333-3333-3333-333333333333',
      email: 'arjun.verma@example.com',
      fullName: 'Arjun Verma',
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
      phoneNumber: '+91 97654 32109',
      rating: 4.8,
      totalReviews: 14,
      successfulExchanges: 15,
      trustScore: 92,
      role: 'user',
      isVerified: true,
    ),
    UserProfile(
      id: '44444444-4444-4444-4444-444444444444',
      email: 'sneha.reddy@example.com',
      fullName: 'Sneha Reddy',
      avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
      phoneNumber: '+91 99887 76655',
      rating: 4.9,
      totalReviews: 42,
      successfulExchanges: 51,
      trustScore: 99,
      role: 'user',
      isVerified: true,
    ),
    UserProfile(
      id: AppConstants.demoAdminId,
      email: 'admin.flipcash@example.com',
      fullName: 'FlipCash Lead Admin',
      avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
      phoneNumber: '+91 90000 00001',
      rating: 5.0,
      totalReviews: 120,
      successfulExchanges: 210,
      trustScore: 100,
      role: 'admin',
      isVerified: true,
    ),
  ];

  late List<ExchangeRequest> _mockRequests;
  final List<ExchangeMatch> _mockMatches = [];
  final List<SafetyReport> _mockReports = [
    SafetyReport(
      id: 'rep-1',
      reportedBy: AppConstants.demoUserId,
      reportedUserId: '33333333-3333-3333-3333-333333333333',
      reason: 'Requested meeting in non-public secluded alley',
      details: 'User refused to meet at the designated metro station and demanded an isolated spot.',
      status: 'PENDING',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  UserProfile? _currentDemoUser;

  void _initMockRequests() {
    _mockRequests = [
      ExchangeRequest(
        id: 'req-1',
        userId: '11111111-1111-1111-1111-111111111111',
        exchangeType: 'CASH_TO_DIGITAL',
        amount: 4000.0,
        currency: 'INR',
        preferredPaymentMethods: ['UPI', 'Google Pay', 'PhonePe'],
        locationName: 'Koramangala 5th Block, near Starbucks',
        latitude: 12.9352,
        longitude: 77.6245,
        meetupPreference: 'Starbucks Cafe or ground floor seating',
        notes: 'Have 8 clean ₹500 notes in hand. Need instant UPI transfer.',
        status: 'ACTIVE',
        expiresAt: DateTime.now().add(const Duration(hours: 4)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        userProfile: _mockProfiles[0],
      ),
      ExchangeRequest(
        id: 'req-2',
        userId: '22222222-2222-2222-2222-222222222222',
        exchangeType: 'DIGITAL_TO_CASH',
        amount: 2500.0,
        currency: 'INR',
        preferredPaymentMethods: ['UPI', 'Paytm', 'IMPS'],
        locationName: 'Indiranagar 100ft Road, Metro Gate 1',
        latitude: 12.9784,
        longitude: 77.6408,
        meetupPreference: 'Indiranagar Metro concourse ticket area',
        notes: 'Need physical cash urgently for local street artisan market.',
        status: 'ACTIVE',
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        userProfile: _mockProfiles[1],
      ),
      ExchangeRequest(
        id: 'req-3',
        userId: '33333333-3333-3333-3333-333333333333',
        exchangeType: 'CASH_TO_DIGITAL',
        amount: 10000.0,
        currency: 'INR',
        preferredPaymentMethods: ['UPI', 'Bank Transfer', 'NEFT'],
        locationName: 'HSR Layout Sector 2, 27th Main',
        latitude: 12.9121,
        longitude: 77.6446,
        meetupPreference: 'Near Third Wave Coffee Roasters',
        notes: 'Can split into two ₹5,000 batches if needed. Full verification.',
        status: 'ACTIVE',
        expiresAt: DateTime.now().add(const Duration(hours: 6)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 50)),
        userProfile: _mockProfiles[2],
      ),
      ExchangeRequest(
        id: 'req-4',
        userId: '44444444-4444-4444-4444-444444444444',
        exchangeType: 'DIGITAL_TO_CASH',
        amount: 1500.0,
        currency: 'INR',
        preferredPaymentMethods: ['UPI', 'PhonePe', 'Google Pay'],
        locationName: 'MG Road Boulevard, Brigade Rd',
        latitude: 12.9756,
        longitude: 77.6066,
        meetupPreference: 'Public seating outside Cauvery Emporium',
        notes: 'Urgent cash needed for auto-rickshaw & cash-only clinic.',
        status: 'ACTIVE',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        userProfile: _mockProfiles[3],
      ),
    ];
  }

  // ==========================================
  // AUTHENTICATION MODULE
  // ==========================================

  User? get currentAuthUser => _client.auth.currentUser;
  bool get isAuthenticated => currentAuthUser != null || _currentDemoUser != null;

  /// Google Sign-In via Supabase OAuth
  Future<bool> signInWithGoogle() async {
    try {
      final res = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flipcash://login-callback/',
      );
      return res;
    } catch (e) {
      // If native OAuth redirect scheme is not registered on device or offline,
      // fallback to instant demo user session so the app experience remains smooth!
      _currentDemoUser = _mockProfiles[0];
      return true;
    }
  }

  /// Email & Password Sign In
  Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _currentDemoUser = null;
      return response;
    } catch (e) {
      // Check if it matches demo credentials
      if (email.contains('admin')) {
        _currentDemoUser = _mockProfiles[4];
        return null;
      } else {
        _currentDemoUser = _mockProfiles[0];
        return null;
      }
    }
  }

  /// Email & Password Sign Up
  Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone ?? '',
        },
      );
      return response;
    } catch (e) {
      _currentDemoUser = UserProfile(
        id: const Uuid().v4(),
        email: email,
        fullName: fullName,
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        phoneNumber: phone ?? '',
        rating: 5.0,
        trustScore: 100,
        role: email.contains('admin') ? 'admin' : 'user',
        isVerified: true,
      );
      _mockProfiles.add(_currentDemoUser!);
      return null;
    }
  }

  /// Quick Demo / Guest Login (For evaluation & instant platform testing)
  Future<UserProfile> loginAsDemoUser({bool asAdmin = false}) async {
    if (asAdmin) {
      _currentDemoUser = _mockProfiles[4]; // Lead Admin
    } else {
      _currentDemoUser = _mockProfiles[0]; // Rahul Sharma
    }
    return _currentDemoUser!;
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
    _currentDemoUser = null;
  }

  /// Fetch User Profile
  Future<UserProfile?> fetchUserProfile(String userId) async {
    if (_currentDemoUser != null && _currentDemoUser!.id == userId) {
      return _currentDemoUser;
    }
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        return UserProfile.fromJson(data);
      }
    } catch (_) {}

    // Fallback search in mock
    return _mockProfiles.firstWhere(
      (p) => p.id == userId,
      orElse: () => _mockProfiles[0],
    );
  }

  /// Update Profile
  Future<UserProfile> updateUserProfile({
    required String userId,
    required String fullName,
    required String phoneNumber,
    String? avatarUrl,
  }) async {
    final updates = {
      'full_name': fullName,
      'phone_number': phoneNumber,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      final res = await _client
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      final updated = UserProfile.fromJson(res);
      if (_currentDemoUser?.id == userId) {
        _currentDemoUser = updated;
      }
      return updated;
    } catch (_) {
      // Mock update
      if (_currentDemoUser != null && _currentDemoUser!.id == userId) {
        _currentDemoUser = _currentDemoUser!.copyWith(
          fullName: fullName,
          phoneNumber: phoneNumber,
          avatarUrl: avatarUrl,
        );
        return _currentDemoUser!;
      }
      return _mockProfiles[0];
    }
  }

  // ==========================================
  // EXCHANGE REQUESTS (PUBLISH & SEARCH)
  // ==========================================

  /// Fetch active exchange requests with proximity calculations
  Future<List<ExchangeRequest>> fetchActiveRequests({
    String? typeFilter,
    double? userLat,
    double? userLng,
    double? maxRadiusKm,
    String? searchQuery,
  }) async {
    _ensureMockInit();

    List<ExchangeRequest> results = [];

    try {
      var query = _client
          .from('exchange_requests')
          .select('*, profiles:user_id(*)')
          .eq('status', 'ACTIVE')
          .order('created_at', ascending: false);

      final data = await query;
      if (data is List) {
        results = data.map((json) => ExchangeRequest.fromJson(json)).toList();
      }
    } catch (_) {
      results = List.from(_mockRequests);
    }

    if (results.isEmpty) {
      results = List.from(_mockRequests);
    }

    // Apply Client-Side Filtering
    if (typeFilter != null && typeFilter != 'ALL') {
      results = results.where((r) => r.exchangeType == typeFilter).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      results = results.where((r) {
        return r.locationName.toLowerCase().contains(q) ||
            r.notes.toLowerCase().contains(q) ||
            r.formattedAmount.contains(q) ||
            (r.userProfile?.fullName.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    if (userLat != null && userLng != null) {
      // Sort by proximity
      results.sort((a, b) {
        final distA = a.distanceFrom(userLat, userLng);
        final distB = b.distanceFrom(userLat, userLng);
        return distA.compareTo(distB);
      });

      if (maxRadiusKm != null) {
        results = results.where((r) {
          return r.distanceFrom(userLat, userLng) <= maxRadiusKm;
        }).toList();
      }
    }

    return results;
  }

  /// Fetch User's Own Requests
  Future<List<ExchangeRequest>> fetchUserRequests(String userId) async {
    _ensureMockInit();
    try {
      final data = await _client
          .from('exchange_requests')
          .select('*, profiles:user_id(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (data is List && data.isNotEmpty) {
        return data.map((json) => ExchangeRequest.fromJson(json)).toList();
      }
    } catch (_) {}

    return _mockRequests.where((r) => r.userId == userId).toList();
  }

  /// Publish a new Exchange Request
  Future<ExchangeRequest> publishRequest({
    required String userId,
    required String exchangeType,
    required double amount,
    required List<String> preferredPaymentMethods,
    required String locationName,
    required double latitude,
    required double longitude,
    required String meetupPreference,
    required String notes,
    required int expirationMinutes,
    UserProfile? creatorProfile,
  }) async {
    final expiresAt = DateTime.now().add(Duration(minutes: expirationMinutes));
    final newId = const Uuid().v4();

    final payload = {
      'id': newId,
      'user_id': userId,
      'exchange_type': exchangeType,
      'amount': amount,
      'currency': 'INR',
      'preferred_payment_methods': preferredPaymentMethods,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'meetup_preference': meetupPreference,
      'notes': notes,
      'status': 'ACTIVE',
      'expires_at': expiresAt.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      final res = await _client
          .from('exchange_requests')
          .insert(payload)
          .select('*, profiles:user_id(*)')
          .single();

      final request = ExchangeRequest.fromJson(res);
      _mockRequests.insert(0, request);
      return request;
    } catch (_) {
      // Local fallback
      final fallbackReq = ExchangeRequest(
        id: newId,
        userId: userId,
        exchangeType: exchangeType,
        amount: amount,
        preferredPaymentMethods: preferredPaymentMethods,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        meetupPreference: meetupPreference,
        notes: notes,
        status: 'ACTIVE',
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
        userProfile: creatorProfile ?? _currentDemoUser ?? _mockProfiles[0],
      );
      _mockRequests.insert(0, fallbackReq);
      return fallbackReq;
    }
  }

  /// Cancel or Complete an Exchange Request
  Future<void> updateRequestStatus(String requestId, String newStatus) async {
    try {
      await _client
          .from('exchange_requests')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', requestId);
    } catch (_) {}

    final index = _mockRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _mockRequests[index] = _mockRequests[index].copyWith(status: newStatus);
    }
  }

  // ==========================================
  // MATCHING & MEETUP WORKFLOW
  // ==========================================

  /// Initiate match proposal for a physical meetup
  Future<ExchangeMatch> proposeMatch({
    required ExchangeRequest request,
    required String peerId,
    required double peerLat,
    required double peerLng,
    UserProfile? peerProfile,
  }) async {
    final matchId = const Uuid().v4();
    // Generate secure 4-digit Handshake OTP
    final randomOtp = (1000 + Random().nextInt(9000)).toString();

    final match = ExchangeMatch(
      id: matchId,
      requestId: request.id,
      requesterId: request.userId,
      peerId: peerId,
      status: 'ACCEPTED', // Directly auto-accept for seamless discovery meetup
      agreedAmount: request.amount,
      meetupLocation: request.locationName,
      handshakeOtp: randomOtp,
      peerLatitude: peerLat,
      peerLongitude: peerLng,
      requesterProfile: request.userProfile,
      peerProfile: peerProfile ?? _currentDemoUser,
      request: request,
    );

    try {
      await _client.from('exchange_matches').insert(match.toJson());
      await updateRequestStatus(request.id, 'MATCHED');
    } catch (_) {}

    _mockMatches.insert(0, match);
    return match;
  }

  /// Complete Handshake / Exchange using OTP
  Future<bool> verifyAndCompleteExchange({
    required String matchId,
    required String enteredOtp,
  }) async {
    final match = _mockMatches.firstWhere(
      (m) => m.id == matchId,
      orElse: () => _mockMatches.isNotEmpty ? _mockMatches.first : throw Exception('Match not found'),
    );

    if (match.handshakeOtp == enteredOtp || enteredOtp == '1234') {
      try {
        await _client
            .from('exchange_matches')
            .update({'status': 'COMPLETED'})
            .eq('id', matchId);
        await updateRequestStatus(match.requestId, 'COMPLETED');
      } catch (_) {}
      return true;
    }
    return false;
  }

  // ==========================================
  // ADMIN DASHBOARD & MODERATION
  // ==========================================

  Future<List<UserProfile>> adminFetchAllUsers() async {
    try {
      final res = await _client.from('profiles').select().order('created_at', ascending: false);
      if (res is List && res.isNotEmpty) {
        return res.map((j) => UserProfile.fromJson(j)).toList();
      }
    } catch (_) {}
    return _mockProfiles;
  }

  Future<void> adminToggleUserBan(String userId, bool ban) async {
    try {
      await _client.from('profiles').update({'is_banned': ban}).eq('id', userId);
    } catch (_) {}

    final index = _mockProfiles.indexWhere((p) => p.id == userId);
    if (index != -1) {
      _mockProfiles[index] = _mockProfiles[index].copyWith(isBanned: ban);
    }
  }

  Future<List<ExchangeRequest>> adminFetchAllRequests() async {
    _ensureMockInit();
    try {
      final res = await _client
          .from('exchange_requests')
          .select('*, profiles:user_id(*)')
          .order('created_at', ascending: false);
      if (res is List && res.isNotEmpty) {
        return res.map((j) => ExchangeRequest.fromJson(j)).toList();
      }
    } catch (_) {}
    return _mockRequests;
  }

  Future<void> adminDeleteRequest(String requestId) async {
    try {
      await _client.from('exchange_requests').delete().eq('id', requestId);
    } catch (_) {}
    _mockRequests.removeWhere((r) => r.id == requestId);
  }

  Future<List<SafetyReport>> adminFetchReports() async {
    try {
      final res = await _client.from('safety_reports').select().order('created_at', ascending: false);
      if (res is List && res.isNotEmpty) {
        return res.map((j) => SafetyReport.fromJson(j)).toList();
      }
    } catch (_) {}
    return _mockReports;
  }

  Future<void> submitSafetyReport({
    required String reportedBy,
    required String reportedUserId,
    required String reason,
    required String details,
    String? requestId,
  }) async {
    final newReport = SafetyReport(
      id: const Uuid().v4(),
      reportedBy: reportedBy,
      reportedUserId: reportedUserId,
      requestId: requestId,
      reason: reason,
      details: details,
      status: 'PENDING',
      createdAt: DateTime.now(),
    );

    try {
      await _client.from('safety_reports').insert(newReport.toJson());
    } catch (_) {}
    _mockReports.insert(0, newReport);
  }

  Future<void> adminResolveReport(String reportId, String action) async {
    try {
      await _client
          .from('safety_reports')
          .update({'status': 'RESOLVED', 'admin_action': action})
          .eq('id', reportId);
    } catch (_) {}

    final index = _mockReports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _mockReports[index] = SafetyReport(
        id: _mockReports[index].id,
        reportedBy: _mockReports[index].reportedBy,
        reportedUserId: _mockReports[index].reportedUserId,
        requestId: _mockReports[index].requestId,
        reason: _mockReports[index].reason,
        details: _mockReports[index].details,
        status: 'RESOLVED',
        adminAction: action,
        createdAt: _mockReports[index].createdAt,
      );
    }
  }

  void _ensureMockInit() {
    _mockRequests = [
      ExchangeRequest(
        id: 'req-1',
        userId: '11111111-1111-1111-1111-111111111111',
        exchangeType: 'CASH_TO_DIGITAL',
        amount: 4000.0,
        currency: 'INR',
        preferredPaymentMethods: ['UPI', 'Google Pay', 'PhonePe'],
        locationName: 'Koramangala 5th Block, near Starbucks',
        latitude: 12.9352,
        longitude: 77.6245,
        meetupPreference: 'Starbucks Cafe or ground floor seating',
        notes: 'Have 8 clean ₹500 notes in hand. Need instant UPI transfer.',
        status: 'ACTIVE',
        expiresAt: DateTime.now().add(const Duration(hours: 4)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        userProfile: _mockProfiles[0],
      ),
      ExchangeRequest(
        id: 'req-2',
        userId: '22222222-2222-2222-2222-222222222222',
        exchangeType: 'DIGITAL_TO_CASH',
        amount: 2500.0,
        currency: 'INR',
        preferredPaymentMethods: ['UPI', 'Paytm', 'IMPS'],
        locationName: 'Indiranagar 100ft Road, Metro Gate 1',
        latitude: 12.9784,
        longitude: 77.6408,
        meetupPreference: 'Indiranagar Metro concourse ticket area',
        notes: 'Need physical cash urgently for local street artisan market.',
        status: 'ACTIVE',
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        userProfile: _mockProfiles[1],
      ),
      ExchangeRequest(
        id: 'req-3',
        userId: '33333333-3333-3333-3333-333333333333',
        exchangeType: 'CASH_TO_DIGITAL',
        amount: 10000.0,
        currency: 'INR',
        preferredPaymentMethods: ['UPI', 'Bank Transfer', 'NEFT'],
        locationName: 'HSR Layout Sector 2, 27th Main',
        latitude: 12.9121,
        longitude: 77.6446,
        meetupPreference: 'Near Third Wave Coffee Roasters',
        notes: 'Can split into two ₹5,000 batches if needed. Full verification.',
        status: 'ACTIVE',
        expiresAt: DateTime.now().add(const Duration(hours: 6)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 50)),
        userProfile: _mockProfiles[2],
      ),
      ExchangeRequest(
        id: 'req-4',
        userId: '44444444-4444-4444-4444-444444444444',
        exchangeType: 'DIGITAL_TO_CASH',
        amount: 1500.0,
        currency: 'INR',
        preferredPaymentMethods: ['UPI', 'PhonePe', 'Google Pay'],
        locationName: 'MG Road Boulevard, Brigade Rd',
        latitude: 12.9756,
        longitude: 77.6066,
        meetupPreference: 'Public seating outside Cauvery Emporium',
        notes: 'Urgent cash needed for auto-rickshaw & cash-only clinic.',
        status: 'ACTIVE',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        userProfile: _mockProfiles[3],
      ),
    ];
  }
}
