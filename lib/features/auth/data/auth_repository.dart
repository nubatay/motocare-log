// All Supabase Auth logic lives here.
// Note: The 30-day session rule has been removed. Sessions now stay
// active on the device until the user explicitly signs out.

import 'package:supabase_flutter/supabase_flutter.dart';

/// A friendly, user-facing error for auth failures.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  // ---------------------------------------------------------------
  // Session state
  // ---------------------------------------------------------------
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  // ---------------------------------------------------------------
  // Register
  // ---------------------------------------------------------------
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _client.auth.signUp(
        email: email.trim(),
        password: password, // do NOT trim — see validators.dart
        data: {'name': name.trim()},
      );
    } on AuthException catch (e) {
      throw AuthFailure(_friendlySignUpMessage(e));
    } catch (_) {
      throw const AuthFailure(
        'Could not create your account. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------
  // Log in
  // ---------------------------------------------------------------
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
        } on AuthException {
      // ADD THIS LINE to see the real error in your terminal: 
      
      throw const AuthFailure('Invalid email or password.');
    } catch (_) {
      throw const AuthFailure('Could not sign you in. Please try again.');
    }
  }

  // ---------------------------------------------------------------
  // Log out
  // ---------------------------------------------------------------
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      throw const AuthFailure('Could not sign you out. Please try again.');
    }
  }

  // ---------------------------------------------------------------
  // Error mapping
  // ---------------------------------------------------------------
  String _friendlySignUpMessage(AuthException e) {
    final raw = e.message.toLowerCase();
    if (raw.contains('already') || raw.contains('exists')) {
      return 'An account with this email already exists. Try logging in.';
    }
    if (raw.contains('password')) {
      return 'Your password does not meet the requirements.';
    }
    if (raw.contains('rate limit') || raw.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return 'Could not create your account. Please try again.';
  }
}