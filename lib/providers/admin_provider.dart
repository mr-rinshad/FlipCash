import 'package:flutter/material.dart';
import '../core/services/supabase_service.dart';
import '../models/user_profile.dart';
import '../models/exchange_request.dart';
import '../models/safety_report.dart';

class AdminProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<UserProfile> _allUsers = [];
  List<ExchangeRequest> _allRequests = [];
  List<SafetyReport> _allReports = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<UserProfile> get allUsers => _allUsers;
  List<ExchangeRequest> get allRequests => _allRequests;
  List<SafetyReport> get allReports => _allReports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Platform Analytics
  int get totalUsersCount => _allUsers.length;
  int get activeListingsCount => _allRequests.where((r) => r.status == 'ACTIVE').length;
  double get totalActiveVolume => _allRequests
      .where((r) => r.status == 'ACTIVE')
      .fold(0.0, (sum, r) => sum + r.amount);
  int get pendingReportsCount => _allReports.where((r) => r.status == 'PENDING').length;

  Future<void> loadAdminData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final usersFuture = _supabaseService.adminFetchAllUsers();
      final reqFuture = _supabaseService.adminFetchAllRequests();
      final repFuture = _supabaseService.adminFetchReports();

      final results = await Future.wait([usersFuture, reqFuture, repFuture]);

      _allUsers = results[0] as List<UserProfile>;
      _allRequests = results[1] as List<ExchangeRequest>;
      _allReports = results[2] as List<SafetyReport>;
    } catch (e) {
      _errorMessage = 'Failed to load admin data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleUserBan(String userId, bool ban) async {
    await _supabaseService.adminToggleUserBan(userId, ban);
    final idx = _allUsers.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _allUsers[idx] = _allUsers[idx].copyWith(isBanned: ban);
      notifyListeners();
    }
  }

  Future<void> deleteListing(String requestId) async {
    await _supabaseService.adminDeleteRequest(requestId);
    _allRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }

  Future<void> resolveReport(String reportId, String action) async {
    await _supabaseService.adminResolveReport(reportId, action);
    final idx = _allReports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      _allReports[idx] = SafetyReport(
        id: _allReports[idx].id,
        reportedBy: _allReports[idx].reportedBy,
        reportedUserId: _allReports[idx].reportedUserId,
        requestId: _allReports[idx].requestId,
        reason: _allReports[idx].reason,
        details: _allReports[idx].details,
        status: 'RESOLVED',
        adminAction: action,
        createdAt: _allReports[idx].createdAt,
      );
      notifyListeners();
    }
  }

  Future<void> submitReport({
    required String reportedBy,
    required String reportedUserId,
    required String reason,
    required String details,
    String? requestId,
  }) async {
    await _supabaseService.submitSafetyReport(
      reportedBy: reportedBy,
      reportedUserId: reportedUserId,
      reason: reason,
      details: details,
      requestId: requestId,
    );
    await loadAdminData();
  }
}
