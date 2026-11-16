// The main dashboard showing the rider's motorcycles.
// Now fully connected to the Add/Edit screen and the AuthProvider for Logout.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/motorcycle_repository.dart';
import '../providers/motorcycle_provider.dart';
import 'add_edit_motorcycle_screen.dart';

class MyMotorcyclesScreen extends StatefulWidget {
  const MyMotorcyclesScreen({super.key});

  @override
  State<MyMotorcyclesScreen> createState() => _MyMotorcyclesScreenState();
}

class _MyMotorcyclesScreenState extends State<MyMotorcyclesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch motorcycles AFTER the first frame so we don't trigger a build error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MotorcycleProvider>().loadMotorcycles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MotorcycleProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Motorcycles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () {
              // Wired up to AuthProvider. AuthGate will handle the screen swap.
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadMotorcycles(),
        child: _buildBody(provider, theme),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to the Add screen (bike: null means "Add Mode").
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddEditMotorcycleScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Motorcycle'),
      ),
    );
  }

  Widget _buildBody(MotorcycleProvider provider, ThemeData theme) {
    // 1. Loading State
    if (provider.isLoading && provider.activeBikes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Error State
    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            provider.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      );
    }

    // 3. Empty State
    if (provider.activeBikes.isEmpty && provider.archivedBikes.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Icon(
            Icons.two_wheeler,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No motorcycles yet.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap "Add Motorcycle" to get started.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    }

    // 4. Data State
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // --- Active Bikes Section ---
        if (provider.activeBikes.isNotEmpty) ...[
          Text(
            'Garage',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...provider.activeBikes.map((bike) => _BikeCard(bike: bike)),
        ],

        // --- Archived Bikes Section ---
        if (provider.archivedBikes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Archived',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...provider.archivedBikes.map((bike) => _BikeCard(bike: bike)),
        ],

        // Add extra padding at the bottom so the FAB doesn't cover the last card
        const SizedBox(height: 80),
      ],
    );
  }
}

class _BikeCard extends StatelessWidget {
  const _BikeCard({required this.bike});

  final Motorcycle bike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<MotorcycleProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Nickname, Model, Active Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bike.nickname,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${bike.year != null ? '${bike.year} ' : ''}${bike.model}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (bike.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Odometer
            Row(
              children: [
                Icon(Icons.speed, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${bike.currentOdometer.toString()} km',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!bike.isActive && !bike.isArchived) ...[
                  TextButton(
                    onPressed: () => provider.switchActiveMotorcycle(bike.id),
                    child: const Text('Switch to this'),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton(
                  onPressed: () {
                    // Navigate to the Edit screen, passing the bike data.
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddEditMotorcycleScreen(bike: bike),
                      ),
                    );
                  },
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}