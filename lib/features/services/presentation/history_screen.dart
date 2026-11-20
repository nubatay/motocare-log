import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../motorcycles/providers/motorcycle_provider.dart';
import '../providers/service_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All Services';

  @override
  void initState() {
    super.initState();
    // Load data when the tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final activeBike = context.read<MotorcycleProvider>().activeBike;
    if (activeBike != null) {
      await context.read<ServiceProvider>().loadData(
            motorcycleId: activeBike.id,
            estimatedOdometer: activeBike.currentOdometer,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bikeProvider = context.watch<MotorcycleProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final activeBike = bikeProvider.activeBike;
    final theme = Theme.of(context);

    // If no bike is active, tell the user
    if (activeBike == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service History')),
        body: const Center(child: Text('No active motorcycle.')),
      );
    }

    // Filter the records based on the dropdown
    final filteredRecords = serviceProvider.records.where((r) {
      if (_selectedFilter == 'All Services') return true;
      return r.serviceTypeName == _selectedFilter;
    }).toList();

    // Get unique service names for the dropdown
    final uniqueServices = ['All Services', ...serviceProvider.records.map((r) => r.serviceTypeName).toSet()];

    return Scaffold(
      appBar: AppBar(title: const Text('Service history')),
      body: Column(
        children: [
          // Filter Dropdown
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedFilter,
              items: uniqueServices.map((name) {
                return DropdownMenuItem(value: name, child: Text(name));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedFilter = val);
              },
              decoration: const InputDecoration(
                labelText: 'Filter by type',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // History List
          Expanded(
            child: serviceProvider.isLoading && serviceProvider.records.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredRecords.isEmpty
                    ? const Center(child: Text('No service history found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: ListTile(
                              title: Text(
                                record.serviceTypeName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${record.serviceDate.year}-${record.serviceDate.month.toString().padLeft(2, '0')}-${record.serviceDate.day.toString().padLeft(2, '0')} • ${record.odometerValue} km',
                              ),
                              trailing: Text(
                                'PHP ${record.cost.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}