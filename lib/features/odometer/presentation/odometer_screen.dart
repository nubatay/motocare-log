// Displays the estimated mileage, daily distance settings, and a history
// of all odometer readings for a specific motorcycle.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../motorcycles/data/motorcycle_repository.dart';
import '../../motorcycles/providers/motorcycle_provider.dart';
import '../providers/odometer_provider.dart';
import 'update_odometer_screen.dart';

class OdometerScreen extends StatefulWidget {
  final Motorcycle bike;

  const OdometerScreen({super.key, required this.bike});

  @override
  State<OdometerScreen> createState() => _OdometerScreenState();
}

class _OdometerScreenState extends State<OdometerScreen> {
  @override
  void initState() {
    super.initState();
    // Load the history when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    await context.read<OdometerProvider>().loadReadings(
          motorcycleId: widget.bike.id,
          dailyDistanceKm: widget.bike.dailyDistanceKm,
          currentOdometerFallback: widget.bike.currentOdometer,
        );
  }

    Future<void> _deleteReading(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: Text('Delete Reading?')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(c, false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: const Text('This will permanently delete this reading.'),
        actions: [
          // Removed the Cancel button
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<OdometerProvider>().deleteReading(
            id: id,
            motorcycleId: widget.bike.id,
            dailyDistanceKm: widget.bike.dailyDistanceKm,
            currentOdometerFallback: widget.bike.currentOdometer,
          );
      if (mounted) context.read<MotorcycleProvider>().loadMotorcycles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OdometerProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bike.nickname} - Odometer'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (provider.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  provider.errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            // --- Estimate Card ---
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Text('Estimated Mileage', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      provider.estimate != null ? '${provider.estimate!.estimatedKm} km' : '--- km',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (provider.estimate?.isStale == true)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'Estimate is stale. Please log a recent reading.',
                          style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Reading History ---
            Text('History', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            if (provider.readings.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('No readings logged yet.'),
              )
            else
              ...provider.readings.map((r) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: Icon(Icons.speed, color: theme.colorScheme.secondary),
                      title: Text('${r.valueKm} km'),
                      subtitle: Text(
                          '${r.readingDate.year}-${r.readingDate.month.toString().padLeft(2, '0')}-${r.readingDate.day.toString().padLeft(2, '0')} • ${r.source == 'service' ? 'Service Record' : 'Rider Entry'}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') _deleteReading(r.id);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UpdateOdometerScreen(bike: widget.bike), // <-- NEW
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Reading'),
      ),
    );
  }
}