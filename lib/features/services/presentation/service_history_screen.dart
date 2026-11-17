// lib/features/services/presentation/service_history_screen.dart
//
// Displays a logbook of all past service records for a specific motorcycle.
// Allows editing (cost/notes) and deleting records.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/validators.dart';
import '../../motorcycles/data/motorcycle_repository.dart';
import '../../motorcycles/providers/motorcycle_provider.dart';
import '../data/service_repository.dart';
import '../providers/service_provider.dart';

class ServiceHistoryScreen extends StatefulWidget {
  final Motorcycle bike;
  const ServiceHistoryScreen({super.key, required this.bike});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Refresh the records just in case they were updated on the dashboard.
      context.read<ServiceProvider>().loadData(
            motorcycleId: widget.bike.id,
            estimatedOdometer: widget.bike.currentOdometer,
          );
    });
  }

    void _showEditDialog(ServiceRecord record) {
    // 1. Grab the providers BEFORE the dialog opens
    final serviceProvider = context.read<ServiceProvider>();
    final bikeProvider = context.read<MotorcycleProvider>();

    final costController = TextEditingController(text: record.cost.toString());
    final notesController = TextEditingController(text: record.notes ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Service Record'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${record.serviceTypeName} • ${record.odometerValue} km',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Cost'),
                  validator: Validators.cost,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  validator: Validators.notes,
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
                
                final cost = costController.text.trim().isEmpty ? 0.0 : double.parse(costController.text);
                final notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();

                Navigator.pop(context); // Close dialog

                // 2. Use the providers we grabbed at the start!
                final success = await serviceProvider.updateRecord(
                      id: record.id,
                      cost: cost,
                      notes: notes,
                      estimatedOdometer: widget.bike.currentOdometer,
                      motorcycleId: widget.bike.id,
                    );

                if (success) {
                  bikeProvider.loadMotorcycles();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRecord(ServiceRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Record?'),
        content: const Text(
            'This will delete the service record. The odometer reading will remain in your history.'),
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
      await context.read<ServiceProvider>().deleteRecord(
            id: record.id,
            motorcycleId: widget.bike.id,
            estimatedOdometer: widget.bike.currentOdometer,
          );
      if (mounted) context.read<MotorcycleProvider>().loadMotorcycles();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bike.nickname} - History'),
      ),
      body: provider.isLoading && provider.records.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: AppSpacing.md),
                      Text('No service history yet.', style: theme.textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: provider.records.length,
                  itemBuilder: (context, index) {
                    final record = provider.records[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.build, color: theme.colorScheme.onPrimaryContainer),
                        ),
                        title: Text(
                          record.serviceTypeName,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${record.serviceDate.year}-${record.serviceDate.month.toString().padLeft(2, '0')}-${record.serviceDate.day.toString().padLeft(2, '0')} • ${record.odometerValue} km'),
                            Text('Cost: ₱${record.cost.toStringAsFixed(2)}'),
                            if (record.notes != null && record.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Notes: ${record.notes}',
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _showEditDialog(record);
                            if (value == 'delete') _deleteRecord(record);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit Cost/Notes')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}