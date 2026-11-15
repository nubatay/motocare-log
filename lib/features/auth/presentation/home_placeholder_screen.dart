// lib/features/auth/presentation/home_placeholder_screen.dart
//
// A temporary "landing" screen. It proves the user is authenticated
// and gives them a way to log out.
// In B-03, we will replace this with the real "My Motorcycles" screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We get the current user directly from Supabase just to display their email.
    // In later increments, we will get this from the AuthProvider instead.
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MotoCare Log'),
        actions: [
          // context.read() is used for actions (like button presses).
          // It lets us call a method WITHOUT rebuilding the screen when
          // the loading state changes.
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // A green checkmark is a universal "success" icon.
              Icon(
                Icons.check_circle,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Signed in successfully!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              // Display the email to prove WHO is logged in.
              // If for some reason the user is null (shouldn't happen here),
              // we show a safe fallback string.
              Text(
                user?.email ?? 'Unknown user',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'My motorcycles will appear here in B-03.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}