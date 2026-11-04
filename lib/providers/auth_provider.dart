import 'package:flutter/material.dart';
import '../core/services/supabase_service.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  AuthProvider() {
    init();
  }

  Future<void> init() async {
    _setLoading(true);
    try {
      final authUser = _supabaseService.currentAuthUser;
      if (authUser != null) {
        _currentUser = await _supabaseService.fetchUserProfile(authUser.id);
      } else {
        // Start with default demo user so user immediately experiences the platform
        _currentUser = await _supabaseService.loginAsDemoUser(asAdmin: false);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final success = await _supabaseService.signInWithGoogle();
      if (success) {
        final authUser = _supabaseService.currentAuthUser;
        if (authUser != null) {
          _currentUser = await _supabaseService.fetchUserProfile(authUser.id);
        } else {
          _currentUser = await _supabaseService.loginAsDemoUser(asAdmin: false);
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Google Sign In failed: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final res = await _supabaseService.signInWithEmail(
        email: email,
        password: password,
      );
      if (res?.user != null) {
        _currentUser = await _supabaseService.fetchUserProfile(res!.user!.id);
      } else {
        // Handled in mock fallback
        _currentUser = await _supabaseService.loginAsDemoUser(
          asAdmin: email.toLowerCase().contains('admin'),
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final res = await _supabaseService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      if (res?.user != null) {
        _currentUser = await _supabaseService.fetchUserProfile(res!.user!.id);
      } else {
        _currentUser = await _supabaseService.fetchUserProfile(email);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Sign Up failed: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginAsDemo({bool asAdmin = false}) async {
    _setLoading(true);
    try {
      _currentUser = await _supabaseService.loginAsDemoUser(asAdmin: asAdmin);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    try {
      _currentUser = await _supabaseService.updateUserProfile(
        userId: _currentUser!.id,
        fullName: fullName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _supabaseService.signOut();
      _currentUser = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
