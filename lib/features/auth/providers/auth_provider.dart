// lib/features/auth/providers/auth_provider.dart
//
// This class holds the UI state for authentication.
// It uses `ChangeNotifier`, which means whenever its internal data changes,
// it "notifies" Flutter, and any screen listening to it will rebuild.

import 'package:flutter/foundation.dart';
import '../data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo);

  final AuthRepository _repo;

  // ---------------------------------------------------------------
  // State variables (private, so screens can't change them directly)
  // ---------------------------------------------------------------
  bool _isLoading = false;
  String? _errorMessage;

  // ---------------------------------------------------------------
  // Public getters (screens read these to decide what to draw)
  // ---------------------------------------------------------------
  
  /// True while a network request is running. Screens use this to
  /// show a spinner and disable buttons.
  bool get isLoading => _isLoading;

  /// If the last action failed, this holds the friendly message.
  /// If null, there is no error.
  String? get errorMessage => _errorMessage;

  /// True if someone is currently logged in (useful for the AuthGate).
  bool get isLoggedIn => _repo.currentUser != null;

  // ---------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _repo.signIn(email: email, password: password);
      return true; // Success!
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred.';
      return false;
    } finally {
      // `finally` ALWAYS runs, whether we succeeded, failed, or threw.
      // It guarantees the spinner stops spinning.
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    try {
      await _repo.signUp(email: email, password: password, name: name);
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'An unexpected error occurred.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _repo.signOut();
    } catch (e) {
      // If sign out fails (e.g. no internet), we still clear the error
      // locally so the user isn't stuck on a screen they can't leave.
      // Supabase usually clears local tokens even if the server call fails.
      _errorMessage = 'Signed out locally.';
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------
  // Helper to update loading state and notify the UI in one step.
  // Also clears old errors whenever a new action starts.
  // ---------------------------------------------------------------
  void _setLoading(bool value) {
    _isLoading = value;
    if (value) {
      _errorMessage = null; // Clear old errors when starting a new action
    }
    notifyListeners(); // This is the magic line that tells the UI to rebuild.
  }
}