// lib/features/dashboard/presentation/dashboard_screen.dart
//
// The main Home tab. Displays the active motorcycle, its estimated mileage,
// upcoming services, and quick actions.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../motorcycles/data/motorcycle_repository.dart';
import '../../motorcycles/providers/motorcycle_provider.dart';
import '../../odometer/presentation/odometer_screen.dart';
import '../../odometer/providers/odometer_provider.dart';
import '../../services/domain/service_calculator.dart';
import '../../services/presentation/service_screen.dart';
import '../../services/providers/service_provider.dart';
import '../../services/presentation/log_service_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _lastLoadedBikeId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // didChangeDependencies runs whenever a Provider updates.
    // We use it to check if the active bike changed (e.g. user switched bikes).
    final activeBike = context.watch<MotorcycleProvider>().activeBike;
    
    if (activeBike != null && activeBike.id != _lastLoadedBikeId) {
      _lastLoadedBikeId = activeBike.id;
      _loadData(activeBike);
    }
  }

  Future<void> _loadData(Motorcycle bike) async {
    final odoProvider = context.read<OdometerProvider>();
    final serviceProvider = context.read<ServiceProvider>();

    // 1. Load odometer to get the estimated mileage
    await odoProvider.loadReadings(
      motorcycleId: bike.id,
      dailyDistanceKm: bike.dailyDistanceKm,
      currentOdometerFallback: bike.currentOdometer,
    );

    final estimatedOdo = odoProvider.estimate?.estimatedKm ?? bike.currentOdometer;

    // 2. Load services using the estimated mileage
    if (mounted) {
      await serviceProvider.loadData(
        motorcycleId: bike.id,
        estimatedOdometer: estimatedOdo,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bikeProvider = context.watch<MotorcycleProvider>();
    final activeBike = bikeProvider.activeBike;
    final odoProvider = context.watch<OdometerProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final theme = Theme.of(context);

    // --- Empty State (No Active Bike) ---
    if (activeBike == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.two_wheeler, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: AppSpacing.md),
              const Text('No active motorcycle.'),
              const SizedBox(height: AppSpacing.sm),
              const Text('Go to the Motorcycles tab to add or activate one.'),
            ],
          ),
        ),
      );
    }

    // --- Loading State ---
    if (odoProvider.isLoading || serviceProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Filter for services that are Overdue or Due Soon
    final dueServices = serviceProvider.overviews
        .where((s) => s.status.status == ServiceStatus.overdue || s.status.status == ServiceStatus.dueSoon)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(activeBike),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(activeBike),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // --- Active Bike Card ---
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(activeBike.nickname, style: theme.textTheme.titleLarge),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Odometer: ${odoProvider.estimate?.estimatedKm ?? activeBike.currentOdometer} km (estimated)',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (odoProvider.latestReading != null)
                      Text(
                        'Last real reading: ${odoProvider.latestReading!.readingDate.year}-${odoProvider.latestReading!.readingDate.month.toString().padLeft(2, '0')}-${odoProvider.latestReading!.readingDate.day.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Next Services ---
            Text('Next services', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            if (dueServices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('All caught up! No services due soon.'),
              )
            else
              ...dueServices.map((overview) {
                final isOverdue = overview.status.status == ServiceStatus.overdue;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(overview.type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    isOverdue
                        ? 'Was due at ${overview.status.dueKm ?? ''} km' 
                        : 'Due soon',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverdue ? theme.colorScheme.errorContainer : Colors.orange.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOverdue ? 'Overdue' : 'Due soon',
                      style: TextStyle(
                        color: isOverdue ? theme.colorScheme.onErrorContainer : Colors.orange.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ServiceScreen(bike: activeBike),
                    ));
                  },
                );
              }),
            
            const SizedBox(height: AppSpacing.xl),

            // --- Quick Actions ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => OdometerScreen(bike: activeBike),
                      ));
                    },
                    child: const Text('Update odometer'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => LogServiceScreen(bike: activeBike),
                      ));
                    },
                    child: const Text('Log service'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}