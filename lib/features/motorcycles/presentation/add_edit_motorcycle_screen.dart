// lib/features/motorcycles/presentation/add_edit_motorcycle_screen.dart
//
// This screen handles both creating a new motorcycle and editing an existing one.
// If `widget.bike` is null, it's in "Add" mode. If it's not null, it's in "Edit" mode.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/validators.dart';
import '../data/motorcycle_repository.dart';
import '../providers/motorcycle_provider.dart';

class AddEditMotorcycleScreen extends StatefulWidget {
  // Pass a bike to edit it. Leave it null to add a new one.
  final Motorcycle? bike;

  const AddEditMotorcycleScreen({super.key, this.bike});

  @override
  State<AddEditMotorcycleScreen> createState() => _AddEditMotorcycleScreenState();
}

class _AddEditMotorcycleScreenState extends State<AddEditMotorcycleScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nicknameController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _odometerController;
  late TextEditingController _dailyDistanceController;

  bool get _isEditing => widget.bike != null;

  @override
  void initState() {
    super.initState();
    // If editing, pre-fill the fields with the bike's data.
    // If adding, start with empty fields (or 0 for odometer).
    _nicknameController = TextEditingController(text: widget.bike?.nickname ?? '');
    _modelController = TextEditingController(text: widget.bike?.model ?? '');
    _yearController = TextEditingController(text: widget.bike?.year?.toString() ?? '');
    _odometerController = TextEditingController(text: widget.bike?.currentOdometer.toString() ?? '0');
     _dailyDistanceController = TextEditingController(
        text: widget.bike != null && widget.bike!.dailyDistanceKm > 0 
            ? widget.bike!.dailyDistanceKm.toString() 
            : '');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _odometerController.dispose();
    _dailyDistanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final provider = context.read<MotorcycleProvider>();

    // Parse the inputs safely (Validators already checked they are valid).
    final year = _yearController.text.trim().isEmpty 
        ? null 
        : int.parse(_yearController.text.trim());
    final odometer = int.parse(_odometerController.text.trim());
    final dailyDistance = _dailyDistanceController.text.trim().isEmpty 
        ? 0.0 
        : double.parse(_dailyDistanceController.text.trim());

    final success = _isEditing
        ? await provider.updateMotorcycle(
            id: widget.bike!.id,
            nickname: _nicknameController.text,
            model: _modelController.text,
            year: year,
            currentOdometer: odometer,
            dailyDistance: dailyDistance,
          )
        : await provider.addMotorcycle(
            nickname: _nicknameController.text,
            model: _modelController.text,
            year: year,
            currentOdometer: odometer,
            dailyDistance: dailyDistance,
          );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

    Future<void> _archiveBike() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: Text('Archive Motorcycle?')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context, false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: const Text(
            'This bike will be hidden from your main list. You can still view it in the Archived section. All service history is kept.'),
        actions: [
          // Removed Cancel button
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<MotorcycleProvider>().archiveMotorcycle(widget.bike!.id);
      if (success && mounted) Navigator.pop(context);
    }
  }

    Future<void> _deleteBike() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: Text('Delete Permanently?')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context, false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: const Text(
            'WARNING: This will permanently delete this motorcycle AND all of its service records and odometer readings. This cannot be undone.'),
        actions: [
          // Removed Cancel button
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<MotorcycleProvider>().deleteMotorcycle(widget.bike!.id);
      if (success && mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<MotorcycleProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Motorcycle' : 'Add Motorcycle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Nickname ---
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: 'Nickname (e.g. Daily Rider)'),
                validator: Validators.nickname,
              ),
              const SizedBox(height: AppSpacing.md),

              // --- Model ---
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model (e.g. Honda Click)'),
                validator: Validators.model,
              ),
              const SizedBox(height: AppSpacing.md),

              // --- Year ---
              TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year (Optional)'),
                validator: Validators.year,
              ),
              const SizedBox(height: AppSpacing.md),

              // --- Current Odometer ---
              TextFormField(
                controller: _odometerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Current Odometer (km)'),
                validator: Validators.odometer,
              ),
              const SizedBox(height: AppSpacing.md),

              // --- Daily Distance ---
              TextFormField(
                controller: _dailyDistanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Estimated Daily Distance (km) - Optional',
                  helperText: 'Used for estimating mileage between readings.',
                ),
                validator: Validators.dailyDistance,
              ),
              const SizedBox(height: AppSpacing.xl),

              // --- Save Button ---
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),

              // --- Edit Mode Actions ---
              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                
                OutlinedButton(
                  onPressed: isLoading ? null : _archiveBike,
                  child: const Text('Archive Motorcycle'),
                ),
                const SizedBox(height: AppSpacing.sm),
                
                TextButton(
                  onPressed: isLoading ? null : _deleteBike,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Delete Permanently'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}