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
    final isDark = theme.brightness == Brightness.dark;

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
              Text('Overdue', style: theme.textTheme.titleLarge?.copyWith(color: isDark ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              ...overdueItems.map((o) => Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  title: Text(o.type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Was due at ${o.status.dueKm ?? ''} km'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3B1A1D) : const Color(0xFFFDECEA), 
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: Text('Overdue', style: TextStyle(color: isDark ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              )),
            ],

            const SizedBox(height: AppSpacing.lg),

            // DUE SOON SECTION
            if (dueSoonItems.isNotEmpty) ...[
              Text('Due soon', style: theme.textTheme.titleLarge?.copyWith(color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFED6C02), fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              ...dueSoonItems.map((o) => Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  title: Text(o.type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Due in about ${o.status.dueKm != null ? '${o.status.dueKm! - (activeBike.currentOdometer)} km' : 'soon'}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF33210A) : const Color(0xFFFFF4E5), 
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: Text('Due soon', style: TextStyle(color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFED6C02), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              )),
            ],

            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'On a phone, an alert is also sent.',
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}