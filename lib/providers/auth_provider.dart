import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
        _currentUser = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _currentUser = null;
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
      final profile = await _supabaseService.signInWithEmail(
        email: email,
        password: password,
      );
      _currentUser = profile;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Post-Registration: Registers the user and keeps them logged OUT so they must
  /// enter their credentials on the Login screen.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final success = await _supabaseService.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      // Explicitly ensure user is logged out after registration
      _currentUser = null;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = _formatErrorMessage(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _formatErrorMessage(dynamic error) {
    if (error is AuthException) {
      return error.message;
    }
    final str = error.toString();
    final msgMatch = RegExp(r'message:\s*([^,)]+)').firstMatch(str);
    if (msgMatch != null && msgMatch.group(1) != null) {
      return msgMatch.group(1)!.trim();
    }
    return str
        .replaceAll('AuthApiException', '')
        .replaceAll('AuthException', '')
        .replaceAll('Exception:', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .trim();
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

  /// Upload new avatar photo from gallery or camera
  Future<bool> uploadProfilePicture(XFile imageFile) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    try {
      final bytes = await imageFile.readAsBytes();
      final ext = imageFile.name.contains('.')
          ? imageFile.name.split('.').last
          : 'jpg';

      final publicUrl = await _supabaseService.uploadProfilePicture(
        userId: _currentUser!.id,
        bytes: bytes,
        fileExtension: ext,
      );

      if (publicUrl != null) {
        _currentUser = _currentUser!.copyWith(avatarUrl: publicUrl);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to upload photo: $e';
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
