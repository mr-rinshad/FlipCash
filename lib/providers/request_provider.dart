import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/services/supabase_service.dart';
import '../models/exchange_request.dart';
import '../models/exchange_match.dart';
import '../models/user_profile.dart';

class RequestProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<ExchangeRequest> _activeRequests = [];
  List<ExchangeRequest> _userRequests = [];
  ExchangeMatch? _currentActiveMatch;

  bool _isLoading = false;
  String? _errorMessage;

  // Filter state
  String _selectedTypeFilter = 'ALL'; // 'ALL', 'CASH_TO_DIGITAL', 'DIGITAL_TO_CASH'
  double _selectedRadiusKm = 15.0; // 1 to 30 km
  String _searchQuery = '';

  // User simulated location (defaults to Bengaluru MG Rd / Koramangala tech hub)
  double _userLatitude = AppConstants.defaultLatitude;
  double _userLongitude = AppConstants.defaultLongitude;
  String _userLocationName = AppConstants.defaultCity;

  // Getters
  List<ExchangeRequest> get activeRequests => _activeRequests;
  List<ExchangeRequest> get userRequests => _userRequests;
  ExchangeMatch? get currentActiveMatch => _currentActiveMatch;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get selectedTypeFilter => _selectedTypeFilter;
  double get selectedRadiusKm => _selectedRadiusKm;
  String get searchQuery => _searchQuery;

  double get userLatitude => _userLatitude;
  double get userLongitude => _userLongitude;
  String get userLocationName => _userLocationName;

  // Filtered requests based on active criteria
  List<ExchangeRequest> get filteredRequests {
    return _activeRequests.where((req) {
      if (_selectedTypeFilter != 'ALL' && req.exchangeType != _selectedTypeFilter) {
        return false;
      }
      final dist = req.distanceFrom(_userLatitude, _userLongitude);
      if (dist > _selectedRadiusKm) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesLoc = req.locationName.toLowerCase().contains(q);
        final matchesNotes = req.notes.toLowerCase().contains(q);
        final matchesUser = req.userProfile?.fullName.toLowerCase().contains(q) ?? false;
        if (!matchesLoc && !matchesNotes && !matchesUser) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // Quick stats
  double get totalCashLiquidityNearby {
    return _activeRequests
        .where((r) => r.isCashToDigital && r.distanceFrom(_userLatitude, _userLongitude) <= _selectedRadiusKm)
        .fold(0.0, (sum, r) => sum + r.amount);
  }

  int get activeRequestsCountNearby {
    return _activeRequests
        .where((r) => r.distanceFrom(_userLatitude, _userLongitude) <= _selectedRadiusKm)
        .length;
  }

  RequestProvider() {
    loadRequests();
  }

  Future<void> loadRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activeRequests = await _supabaseService.fetchActiveRequests(
        typeFilter: _selectedTypeFilter == 'ALL' ? null : _selectedTypeFilter,
        userLat: _userLatitude,
        userLng: _userLongitude,
        maxRadiusKm: 50.0,
      );
    } catch (e) {
      _errorMessage = 'Failed to load requests: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserRequests(String userId) async {
    try {
      _userRequests = await _supabaseService.fetchUserRequests(userId);
      notifyListeners();
    } catch (_) {}
  }

  void setTypeFilter(String type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void setRadiusFilter(double radiusKm) {
    _selectedRadiusKm = radiusKm;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setUserLocation({
    required double latitude,
    required double longitude,
    required String locationName,
  }) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    _userLocationName = locationName;
    notifyListeners();
    loadRequests();
  }

  Future<bool> publishRequest({
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
    _isLoading = true;
    notifyListeners();

    try {
      final req = await _supabaseService.publishRequest(
        userId: userId,
        exchangeType: exchangeType,
        amount: amount,
        preferredPaymentMethods: preferredPaymentMethods,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        meetupPreference: meetupPreference,
        notes: notes,
        expirationMinutes: expirationMinutes,
        creatorProfile: creatorProfile,
      );

      _activeRequests.insert(0, req);
      _userRequests.insert(0, req);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to publish request: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelRequest(String requestId) async {
    await _supabaseService.updateRequestStatus(requestId, 'CANCELLED');
    _activeRequests.removeWhere((r) => r.id == requestId);
    final userReqIndex = _userRequests.indexWhere((r) => r.id == requestId);
    if (userReqIndex != -1) {
      _userRequests[userReqIndex] = _userRequests[userReqIndex].copyWith(status: 'CANCELLED');
    }
    notifyListeners();
  }

  Future<ExchangeMatch> proposeMatch({
    required ExchangeRequest request,
    required String currentUserId,
    UserProfile? currentUserProfile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final match = await _supabaseService.proposeMatch(
        request: request,
        peerId: currentUserId,
        peerLat: _userLatitude,
        peerLng: _userLongitude,
        peerProfile: currentUserProfile,
      );
      _currentActiveMatch = match;
      return match;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyHandshakeOtp(String otp) async {
    if (_currentActiveMatch == null) return false;
    final success = await _supabaseService.verifyAndCompleteExchange(
      matchId: _currentActiveMatch!.id,
      requestId: _currentActiveMatch!.requestId,
      enteredOtp: otp,
      correctOtp: _currentActiveMatch!.handshakeOtp,
    );
    if (success) {
      _activeRequests.removeWhere((r) => r.id == _currentActiveMatch!.requestId);
      _currentActiveMatch = null;
      notifyListeners();
    }
    return success;
  }

  void clearActiveMatch() {
    _currentActiveMatch = null;
    notifyListeners();
  }
}
