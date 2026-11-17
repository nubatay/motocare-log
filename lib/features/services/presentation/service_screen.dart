// lib/features/services/presentation/service_screen.dart
//
// Displays the service dashboard for a specific motorcycle.
// Shows status badges (Overdue, Due Soon, OK) and allows logging new services.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/validators.dart';
import '../../motorcycles/data/motorcycle_repository.dart';
import '../../motorcycles/providers/motorcycle_provider.dart';
import '../../odometer/providers/odometer_provider.dart';
import '../data/service_repository.dart';
import '../domain/service_calculator.dart';
import '../providers/service_provider.dart';
import 'service_history_screen.dart';

class ServiceScreen extends StatefulWidget {
  final Motorcycle bike;
  const ServiceScreen({super.key, required this.bike});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final odometerProvider = context.read<OdometerProvider>();
    
    // Ensure odometer history is loaded so we have an accurate estimate
    await odometerProvider.loadReadings(
      motorcycleId: widget.bike.id,
      dailyDistanceKm: widget.bike.dailyDistanceKm,
      currentOdometerFallback: widget.bike.currentOdometer,
    );

    // Use the estimated odometer, or fallback to the bike's saved odometer
    final estimatedOdo = odometerProvider.estimate?.estimatedKm ?? widget.bike.currentOdometer;

    if (mounted) {
      await context.read<ServiceProvider>().loadData(
        motorcycleId: widget.bike.id,
        estimatedOdometer: estimatedOdo,
      );
    }
  }

  void _showLogServiceDialog() {
    final serviceProvider = context.read<ServiceProvider>();
    final odometerProvider = context.read<OdometerProvider>();
    final bikeProvider = context.read<MotorcycleProvider>();
    final estimatedOdo = odometerProvider.estimate?.estimatedKm ?? widget.bike.currentOdometer;

    // Find the service type that needs attention most, or default to the first one
    ServiceType? selectedType;
    if (serviceProvider.overviews.isNotEmpty) {
      final overdue = serviceProvider.overviews.where((o) => o.status.status == ServiceStatus.overdue);
      selectedType = overdue.isNotEmpty ? overdue.first.type : serviceProvider.overviews.first.type;
    }

    final odoController = TextEditingController(text: estimatedOdo.toString());
    final costController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Log Service'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Service Type Dropdown
                      DropdownButtonFormField<ServiceType>(
                        initialValue: selectedType, 
                        items: serviceProvider.overviews.map((o) {
                          return DropdownMenuItem(
                            value: o.type,
                            child: Text(o.type.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => selectedType = val),
                        decoration: const InputDecoration(labelText: 'Service Type'),
                        validator: (val) => val == null ? 'Select a service' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 2. Odometer
                      TextFormField(
                        controller: odoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Odometer (km)'),
                        validator: Validators.odometer,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 3. Date
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
                              if (picked != null) setState(() => selectedDate = picked);
                            },
                            child: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // 4. Cost
                      TextFormField(
                        controller: costController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Cost (Optional)'),
                        validator: Validators.cost,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 5. Notes
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                        validator: Validators.notes,
                      ),
                    ],
                  ),
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
                    
                    final odo = int.parse(odoController.text);
                    final cost = costController.text.trim().isEmpty ? 0.0 : double.parse(costController.text);
                    
                    if (!context.mounted) return;
                    Navigator.pop(context); // Close dialog

                    final success = await serviceProvider.addRecord(
                      motorcycleId: widget.bike.id,
                      serviceTypeId: selectedType!.id,
                      odometerKm: odo,
                      serviceDate: selectedDate,
                      cost: cost,
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      estimatedOdometer: estimatedOdo,
                    );

                    if (success) {
                      // Refresh the parent screens
                      bikeProvider.loadMotorcycles();
                      _refreshData();
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServiceProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bike.nickname} - Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ServiceHistoryScreen(bike: widget.bike),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (provider.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                color: theme.colorScheme.errorContainer,
                child: Text(provider.errorMessage!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
              ),

            if (provider.isLoading && provider.overviews.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),

            if (!provider.isLoading && provider.overviews.isEmpty)
              const Center(child: Text('No service types found.')),

            ...provider.overviews.map((overview) => _ServiceCard(overview: overview)),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogServiceDialog,
        icon: const Icon(Icons.build),
        label: const Text('Log Service'),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceOverview overview;
  const _ServiceCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine badge color and text based on status
    Color badgeColor;
    Color textColor;
    String statusText;

    switch (overview.status.status) {
      case ServiceStatus.overdue:
        badgeColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        statusText = 'Overdue';
        break;
      case ServiceStatus.dueSoon:
        badgeColor = Colors.orange.shade200;
        textColor = Colors.orange.shade900;
        statusText = 'Due Soon';
        break;
      case ServiceStatus.ok:
        badgeColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        statusText = 'OK';
        break;
      case ServiceStatus.noRecord:
        badgeColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        statusText = 'No Record';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(overview.type.name, style: theme.textTheme.titleLarge),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(statusText, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Status Details
            if (overview.status.status == ServiceStatus.noRecord)
              Text('Log your first service to start tracking.', style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic))
            else ...[
              if (overview.status.dueKm != null)
                Text('Due at: ${overview.status.dueKm} km', style: theme.textTheme.bodyMedium),
              if (overview.status.dueDate != null)
                Text('Due on: ${overview.status.dueDate!.year}-${overview.status.dueDate!.month.toString().padLeft(2, '0')}-${overview.status.dueDate!.day.toString().padLeft(2, '0')}', style: theme.textTheme.bodyMedium),
            ],
            
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Interval: ${overview.intervalKm != null ? '${overview.intervalKm} km' : ''}${overview.intervalKm != null && overview.intervalMonths != null ? ' / ' : ''}${overview.intervalMonths != null ? '${overview.intervalMonths} months' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}