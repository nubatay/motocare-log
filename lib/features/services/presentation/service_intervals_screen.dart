import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../motorcycles/data/motorcycle_repository.dart';
import '../providers/service_provider.dart';

class ServiceIntervalsScreen extends StatelessWidget {
  final Motorcycle bike;
  const ServiceIntervalsScreen({super.key, required this.bike});

  void _showEditDialog(BuildContext context, ServiceOverview overview) {
    final kmController = TextEditingController(text: overview.intervalKm?.toString() ?? '');
    final monthController = TextEditingController(text: overview.intervalMonths?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${overview.type.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: kmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kilometers (km)'),
                validator: (v) => v != null && v.isNotEmpty && int.tryParse(v) == null ? 'Enter a number' : null,
              ),
              TextFormField(
                controller: monthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Months'),
                validator: (v) => v != null && v.isNotEmpty && int.tryParse(v) == null ? 'Enter a number' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final km = kmController.text.isEmpty ? null : int.parse(kmController.text);
              final months = monthController.text.isEmpty ? null : int.parse(monthController.text);
              
              Navigator.pop(context);
              await context.read<ServiceProvider>().updateInterval(
                id: overview.intervalId,
                motorcycleId: bike.id,
                estimatedOdometer: bike.currentOdometer,
                km: km,
                months: months,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetDefaults(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset to default?'),
        content: const Text('This will restore the factory intervals for all services.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<ServiceProvider>().resetIntervals(
        motorcycleId: bike.id,
        estimatedOdometer: bike.currentOdometer,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Service intervals')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: provider.overviews.length + 1, // +1 for the reset button
              itemBuilder: (context, index) {
                if (index == provider.overviews.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: OutlinedButton(
                      onPressed: () => _resetDefaults(context),
                      child: const Text('Reset all to default'),
                    ),
                  );
                }

                final overview = provider.overviews[index];
                final kmText = overview.intervalKm != null ? '${overview.intervalKm} km' : '';
                final monthText = overview.intervalMonths != null ? '${overview.intervalMonths} months' : '';
                final intervalText = [kmText, monthText].where((s) => s.isNotEmpty).join(' or ');

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    title: Text(overview.type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Every $intervalText'),
                    trailing: TextButton(
                      onPressed: () => _showEditDialog(context, overview),
                      child: const Text('Edit'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}