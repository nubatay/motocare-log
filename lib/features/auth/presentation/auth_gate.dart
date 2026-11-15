// The "Bouncer". Decides whether to show the Login screen or the Home screen.
// Because we removed the 30-day rule, this is now a simple, synchronous check.
// If a session exists, go to Home. If not, go to Login.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_placeholder_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // We use Consumer to listen to AuthProvider. If `isLoggedIn` changes
    // (e.g., the user taps Log out or Log in), this builder re-runs.
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoggedIn) {
          return const HomePlaceholderScreen();
        }
        return const LoginScreen();
      },
    );
  }
}