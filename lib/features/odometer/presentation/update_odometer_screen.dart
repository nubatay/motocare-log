import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/validators.dart';
import '../../motorcycles/data/motorcycle_repository.dart';
import '../../motorcycles/providers/motorcycle_provider.dart';
import '../providers/odometer_provider.dart';

class UpdateOdometerScreen extends StatefulWidget {
  final Motorcycle bike;
  const UpdateOdometerScreen({super.key, required this.bike});

  @override
  State<UpdateOdometerScreen> createState() => _UpdateOdometerScreenState();
}

class _UpdateOdometerScreenState extends State<UpdateOdometerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _valueController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController();
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final value = int.parse(_valueController.text);
    final provider = context.read<OdometerProvider>();
    final motorcycleProvider = context.read<MotorcycleProvider>();
    final latestReading = provider.latestReading;

    // Unrealistic jump check (e.g., > 1000 km)
    if (latestReading != null) {
      final jump = value - latestReading.valueKm;
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

    if (!mounted) return;

    final success = await provider.addReading(
      motorcycleId: widget.bike.id,
      valueKm: value,
      date: _selectedDate,
      dailyDistanceKm: widget.bike.dailyDistanceKm,
      currentOdometerFallback: widget.bike.currentOdometer,
    );

    if (success && mounted) {
      motorcycleProvider.loadMotorcycles(); // Update the main list
      Navigator.pop(context); // Close screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OdometerProvider>();
    final theme = Theme.of(context);
    final latest = provider.latestReading;

    return Scaffold(
      appBar: AppBar(title: const Text('Update odometer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current mileage', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Estimated now: ${provider.estimate?.estimatedKm ?? widget.bike.currentOdometer} km'),
                      if (latest != null)
                        Text('Last real reading: ${latest.valueKm} km (${latest.readingDate.year}-${latest.readingDate.month.toString().padLeft(2, '0')}-${latest.readingDate.day.toString().padLeft(2, '0')})'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'New odometer reading (km)'),
                validator: (value) {
                  final baseError = Validators.odometer(value);
                  if (baseError != null) return baseError;

                  if (latest != null && int.parse(value!) < latest.valueKm) {
                    return 'Must not be lower than ${latest.valueKm} km';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              FilledButton(
                onPressed: provider.isLoading ? null : _save,
                child: provider.isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save reading'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}