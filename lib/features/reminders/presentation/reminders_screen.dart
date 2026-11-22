import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../motorcycles/providers/motorcycle_provider.dart';
import '../../odometer/providers/odometer_provider.dart';
import '../../services/domain/service_calculator.dart';
import '../../services/providers/service_provider.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final activeBike = context.read<MotorcycleProvider>().activeBike;
    if (activeBike != null) {
      final odoProvider = context.read<OdometerProvider>();
      await odoProvider.loadReadings(
        motorcycleId: activeBike.id,
        dailyDistanceKm: activeBike.dailyDistanceKm,
        currentOdometerFallback: activeBike.currentOdometer,
      );
      
      final estOdo = odoProvider.estimate?.estimatedKm ?? activeBike.currentOdometer;
      
      if (mounted) {
        await context.read<ServiceProvider>().loadData(
          motorcycleId: activeBike.id,
          estimatedOdometer: estOdo,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bikeProvider = context.watch<MotorcycleProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final activeBike = bikeProvider.activeBike;
    final theme = Theme.of(context);

    if (activeBike == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reminders')),
        body: const Center(child: Text('No active motorcycle.')),
      );
    }

    final overdueItems = serviceProvider.overviews.where((o) => o.status.status == ServiceStatus.overdue).toList();
    final dueSoonItems = serviceProvider.overviews.where((o) => o.status.status == ServiceStatus.dueSoon).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (overdueItems.isEmpty && dueSoonItems.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: Text('All caught up! No reminders.')),
              ),

            // OVERDUE SECTION
            if (overdueItems.isNotEmpty) ...[
              Text('Overdue', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              ...overdueItems.map((o) => Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(o.type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Was due at ${o.status.dueKm ?? ''} km'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                    child: Text('Overdue', style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              )),
            ],

            const SizedBox(height: AppSpacing.lg),

            // DUE SOON SECTION
            if (dueSoonItems.isNotEmpty) ...[
              Text('Due soon', style: theme.textTheme.titleLarge?.copyWith(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              ...dueSoonItems.map((o) => Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(o.type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Due in about ${o.status.dueKm != null ? '${o.status.dueKm! - (activeBike.currentOdometer)} km' : 'soon'}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.shade200, borderRadius: BorderRadius.circular(8)),
                    child: Text('Due soon', style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              )),
            ],

            const SizedBox(height: AppSpacing.xl),
            const Center(
              child: Text(
                'On a phone, an alert is also sent.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}