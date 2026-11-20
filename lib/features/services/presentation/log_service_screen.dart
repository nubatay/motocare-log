import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/validators.dart';
import '../../motorcycles/data/motorcycle_repository.dart';
import '../../motorcycles/providers/motorcycle_provider.dart';
import '../../odometer/providers/odometer_provider.dart';
import '../domain/service_calculator.dart';
import '../providers/service_provider.dart';
import '../data/service_repository.dart';

class LogServiceScreen extends StatefulWidget {
  final Motorcycle bike;
  const LogServiceScreen({super.key, required this.bike});

  @override
  State<LogServiceScreen> createState() => _LogServiceScreenState();
}

class _LogServiceScreenState extends State<LogServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  ServiceType? _selectedType;
  late TextEditingController _odoController;
  late TextEditingController _costController;
  late TextEditingController _notesController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final odoEstimate = context.read<OdometerProvider>().estimate?.estimatedKm ?? widget.bike.currentOdometer;
    _odoController = TextEditingController(text: odoEstimate.toString());
    _costController = TextEditingController();
    _notesController = TextEditingController();

    // Auto-select first overdue service, or the first one in the list
    final overviews = context.read<ServiceProvider>().overviews;
    if (overviews.isNotEmpty) {
      final overdue = overviews.where((o) => o.status.status == ServiceStatus.overdue);
      _selectedType = overdue.isNotEmpty ? overdue.first.type : overviews.first.type;
    }
  }

  @override
  void dispose() {
    _odoController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) return;

    final odo = int.parse(_odoController.text);
    final cost = _costController.text.trim().isEmpty ? 0.0 : double.parse(_costController.text);
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();
    final estOdo = context.read<OdometerProvider>().estimate?.estimatedKm ?? widget.bike.currentOdometer;

    final success = await context.read<ServiceProvider>().addRecord(
          motorcycleId: widget.bike.id,
          serviceTypeId: _selectedType!.id,
          odometerKm: odo,
          serviceDate: _selectedDate,
          cost: cost,
          notes: notes,
          estimatedOdometer: estOdo,
        );

    if (success && mounted) {
      context.read<MotorcycleProvider>().loadMotorcycles();
      Navigator.pop(context); // Close screen after save
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Log service record')), // Auto back arrow
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<ServiceType>(
                      initialValue: _selectedType,
                      items: provider.overviews.map((o) => DropdownMenuItem(value: o.type, child: Text(o.type.name))).toList(),
                      onChanged: (val) => setState(() => _selectedType = val),
                      decoration: const InputDecoration(labelText: 'Service type'),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    TextFormField(
                      controller: _odoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Odometer (km)'),
                      validator: Validators.odometer,
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
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Cost (PHP)'),
                      validator: Validators.cost,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                      validator: Validators.notes,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    FilledButton(
                      onPressed: _save,
                      child: const Text('Save service'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}