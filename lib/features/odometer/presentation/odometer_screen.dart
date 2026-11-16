// Displays the estimated mileage, daily distance settings, and a history
// of all odometer readings for a specific motorcycle.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/validators.dart';
import '../../motorcycles/data/motorcycle_repository.dart';
import '../../motorcycles/providers/motorcycle_provider.dart';
import '../data/odometer_repository.dart';
import '../providers/odometer_provider.dart';

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

  void _showReadingDialog({OdometerReading? readingToEdit}) {
    final provider = context.read<OdometerProvider>();
    final latestReading = provider.latestReading;
    final motorcycleProvider = context.read<MotorcycleProvider>();

    final valueController = TextEditingController(
      text: readingToEdit?.valueKm.toString() ?? '',
    );
    DateTime selectedDate = readingToEdit?.readingDate ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(readingToEdit == null ? 'Add Reading' : 'Edit Reading'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Odometer (km)'),
                      validator: (value) {
                        final baseError = Validators.odometer(value);
                        if (baseError != null) return baseError;

                        final numValue = int.parse(value!);
                        // If editing, we allow it to be lower than the current latest,
                        // but if adding, it must be >= the latest reading.
                        if (readingToEdit == null &&
                            latestReading != null &&
                            numValue < latestReading.valueKm) {
                          return 'Reading cannot be lower than ${latestReading.valueKm} km.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Text('Date: '),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: Text(
                            '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final numValue = int.parse(valueController.text);
                    
                    // Unrealistic jump check (e.g. > 1000 km in one entry)
                    if (readingToEdit == null && latestReading != null) {
                      final jump = numValue - latestReading.valueKm;
                      if (jump > 1000) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Unrealistic Jump'),
                            content: Text('You entered a jump of $jump km. Is this correct?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes, save it')),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                      }
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context); // Close dialog

                    final success = readingToEdit == null
                        ? await provider.addReading(
                            motorcycleId: widget.bike.id,
                            valueKm: numValue,
                            date: selectedDate,
                            dailyDistanceKm: widget.bike.dailyDistanceKm,
                            currentOdometerFallback: widget.bike.currentOdometer,
                          )
                        : await provider.updateReading(
                            id: readingToEdit.id,
                            motorcycleId: widget.bike.id,
                            valueKm: numValue,
                            date: selectedDate,
                            dailyDistanceKm: widget.bike.dailyDistanceKm,
                            currentOdometerFallback: widget.bike.currentOdometer,
                          );

                    if (success) {
                      // Use the provider we grabbed at the beginning!
                      motorcycleProvider.loadMotorcycles();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteReading(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Reading?'),
        content: const Text('This will permanently delete this reading.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
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
                          if (value == 'edit') _showReadingDialog(readingToEdit: r);
                          if (value == 'delete') _deleteReading(r.id);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReadingDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Reading'),
      ),
    );
  }
}