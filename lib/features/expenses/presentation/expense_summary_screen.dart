import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../motorcycles/providers/motorcycle_provider.dart';
import '../../services/providers/service_provider.dart';

class ExpenseSummaryScreen extends StatefulWidget {
  const ExpenseSummaryScreen({super.key});

  @override
  State<ExpenseSummaryScreen> createState() => _ExpenseSummaryScreenState();
}

class _ExpenseSummaryScreenState extends State<ExpenseSummaryScreen> {
  String _selectedPeriod = 'This Year';
  String _selectedType = 'All';

  final List<String> _periods = ['This Month', 'This Year', 'All Time'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeBike = context.read<MotorcycleProvider>().activeBike;
      if (activeBike != null) {
        context.read<ServiceProvider>().loadData(
              motorcycleId: activeBike.id,
              estimatedOdometer: activeBike.currentOdometer,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bikeProvider = context.watch<MotorcycleProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final activeBike = bikeProvider.activeBike;
    final theme = Theme.of(context);

    if (activeBike == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense summary')),
        body: const Center(child: Text('No active motorcycle.')),
      );
    }

    // 1. Get unique service types for the dropdown
    final types = ['All', ...serviceProvider.records.map((r) => r.serviceTypeName).toSet()];
    // Safety check: if the selected type no longer exists, reset it
    if (!types.contains(_selectedType)) {
      _selectedType = 'All';
    }

    // 2. Filter the records
    final now = DateTime.now();
    final filteredRecords = serviceProvider.records.where((r) {
      // Filter by type
      if (_selectedType != 'All' && r.serviceTypeName != _selectedType) {
        return false;
      }
      // Filter by period
      if (_selectedPeriod == 'This Month') {
        if (r.serviceDate.year != now.year || r.serviceDate.month != now.month) return false;
      } else if (_selectedPeriod == 'This Year') {
        if (r.serviceDate.year != now.year) return false;
      }
      return true;
    }).toList();

    // 3. Calculate totals
    double totalSpent = 0;
    final Map<String, double> breakdown = {};
    final Map<String, int> countBreakdown = {};

    for (var record in filteredRecords) {
      totalSpent += record.cost;
      breakdown[record.serviceTypeName] = (breakdown[record.serviceTypeName] ?? 0) + record.cost;
      countBreakdown[record.serviceTypeName] = (countBreakdown[record.serviceTypeName] ?? 0) + 1;
    }

    final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

    return Scaffold(
      appBar: AppBar(title: const Text('Expense summary')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // --- Filters ---
          DropdownButtonFormField<String>(
            initialValue: _selectedPeriod,
            items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedPeriod = val);
            },
            decoration: const InputDecoration(labelText: 'Period'),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedType),
            initialValue: _selectedType,
            items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedType = val);
            },
            decoration: const InputDecoration(labelText: 'Service type'),
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Total Spent Card ---
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Text('Total spent', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    currencyFormat.format(totalSpent),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // --- Breakdown ---
          if (breakdown.isNotEmpty) ...[
            Text('By service type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            ...breakdown.entries.map((entry) {
              final typeName = entry.key;
              final amount = entry.value;
              final count = countBreakdown[typeName] ?? 0;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(typeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('$count service${count > 1 ? 's' : ''}'),
                trailing: Text(
                  currencyFormat.format(amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('No expenses found for this period.'),
              ),
            ),
        ],
      ),
    );
  }
}