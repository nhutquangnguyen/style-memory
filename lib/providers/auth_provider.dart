import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/models.dart';
import '../services/supabase_service.dart';

enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  UserProfile? _userProfile;
  String? _errorMessage;
  StreamSubscription<supabase.AuthState>? _authSubscription;
  bool _disposed = false;

  AuthState get state => _state;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  AuthProvider() {
    _initialize();
  }

  void _initialize() {
    // Listen to auth state changes and store subscription
    _authSubscription = SupabaseService.authStateChanges.listen((authState) {
      if (authState.event == supabase.AuthChangeEvent.signedIn) {
        _handleSignedIn();
      } else if (authState.event == supabase.AuthChangeEvent.signedOut) {
        _handleSignedOut();
      }
    });

    // Check initial auth state
    if (SupabaseService.isAuthenticated) {
      _handleSignedIn();
    } else {
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _handleSignedIn() async {
    if (_disposed) return; // Safety check
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try to get user profile, if it doesn't exist, create it
      _userProfile = await SupabaseService.getCurrentUserProfile();

      // If no profile exists, create one
      if (_userProfile == null && SupabaseService.currentUser != null) {
        final user = SupabaseService.currentUser!;
        final newProfile = UserProfile(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name'] ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Create profile in database
        await SupabaseService.createUserProfile(newProfile);
        _userProfile = newProfile;
      }

      _state = AuthState.authenticated;
    } catch (e) {
      _errorMessage = 'Failed to load user profile: $e';
      _state = AuthState.unauthenticated;
    }
    if (!_disposed) notifyListeners(); // Safety check before notifying
  }

  void _handleSignedOut() {
    if (_disposed) return; // Safety check
    _state = AuthState.unauthenticated;
    _userProfile = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        // User will be automatically signed in
        return true;
      } else {
        _errorMessage = 'Failed to create account';
        _state = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }
    } on supabase.AuthException catch (e) {
      _errorMessage = e.message;
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return true;
      } else {
        _errorMessage = 'Failed to sign in';
        _state = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }
    } on supabase.AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('not found')) {
        _errorMessage = 'Invalid email or password';
      } else {
        _errorMessage = e.message;
      }
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await SupabaseService.signOut();
      // _handleSignedOut will be called automatically
    } catch (e) {
      _errorMessage = 'Failed to sign out: $e';
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reset password: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      await SupabaseService.updateUserProfile(profile);
      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}