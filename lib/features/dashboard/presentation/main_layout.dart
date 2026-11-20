// lib/features/dashboard/presentation/main_layout.dart
//
// The main shell of the app. Holds the Bottom Navigation Bar and switches
// between the Dashboard, Motorcycles, History, and More tabs.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../../motorcycles/presentation/my_motorcycles_screen.dart';
import 'dashboard_screen.dart';
import '../../services/presentation/history_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // IndexedStack keeps all the screens alive in memory.
  // When you switch tabs, it just changes which one is visible.
  // This is why your scroll position and typed text aren't lost.
  final List<Widget> _tabs = [
    const DashboardScreen(),
    const MyMotorcyclesScreen(),
    const HistoryScreen(),
    const MorePlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack is the standard way to handle tabs in Flutter.
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.two_wheeler_outlined),
            selectedIcon: Icon(Icons.two_wheeler),
            label: 'Motorcycles',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// TEMPORARY PLACEHOLDERS
// We will replace these with real screens in the next few steps.
// -----------------------------------------------------------------

class DashboardPlaceholder extends StatelessWidget {
  const DashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('Dashboard coming next!')),
    );
  }
}

class HistoryPlaceholder extends StatelessWidget {
  const HistoryPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service History')),
      body: const Center(child: Text('Global History coming soon!')),
    );
  }
}

class MorePlaceholder extends StatelessWidget {
  const MorePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('More options coming soon!'),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}