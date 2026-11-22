import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../motorcycles/data/motorcycle_repository.dart';
import '../../motorcycles/providers/motorcycle_provider.dart';
import '../data/renewal_repository.dart';
import '../providers/renewal_provider.dart';

class RenewalsScreen extends StatefulWidget {
  const RenewalsScreen({super.key});

  @override
  State<RenewalsScreen> createState() => _RenewalsScreenState();
}

class _RenewalsScreenState extends State<RenewalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RenewalProvider>().loadRenewals();
    });
  }

  void _showAddEditDialog({Renewal? renewalToEdit}) {
    final provider = context.read<RenewalProvider>();
    final bikes = context.read<MotorcycleProvider>().activeBikes;
    
    String selectedType = renewalToEdit?.renewalType ?? 'registration';
    String? selectedBikeId = renewalToEdit?.motorcycleId ?? (bikes.isNotEmpty ? bikes.first.id : null);
    DateTime selectedDate = renewalToEdit?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(renewalToEdit == null ? 'Add Renewal' : 'Edit Renewal'),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      items: const [
                        DropdownMenuItem(value: 'registration', child: Text('Registration')),
                        DropdownMenuItem(value: 'insurance', child: Text('Insurance')),
                        DropdownMenuItem(value: 'license', child: Text("Driver's License")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedType = val;
                            // If license, clear bike. Otherwise, pick the first bike.
                            if (val == 'license') {
                              selectedBikeId = null;
                            } else if (selectedBikeId == null && bikes.isNotEmpty) {
                              selectedBikeId = bikes.first.id;
                            }
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (selectedType != 'license') ...[
                      DropdownButtonFormField<String>(
                        key: ValueKey(selectedType), // force rebuild when type changes
                        initialValue: selectedBikeId,
                        items: bikes.map((b) => DropdownMenuItem(value: b.id, child: Text(b.nickname))).toList(),
                        onChanged: (val) => setState(() => selectedBikeId = val),
                        decoration: const InputDecoration(labelText: 'Motorcycle'),
                        validator: (val) => val == null ? 'Select a motorcycle' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Due Date'),
                        child: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context);

                    final success = renewalToEdit == null
                        ? await provider.addRenewal(
                            renewalType: selectedType,
                            motorcycleId: selectedBikeId,
                            dueDate: selectedDate,
                          )
                        : await provider.updateRenewal(
                            id: renewalToEdit.id,
                            renewalType: selectedType,
                            motorcycleId: selectedBikeId,
                            dueDate: selectedDate,
                          );
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

  Future<void> _deleteRenewal(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: Text('Delete Renewal?')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(c, false),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: const Text('This will permanently delete this renewal date.'),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<RenewalProvider>().deleteRenewal(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RenewalProvider>();
    final bikeProvider = context.watch<MotorcycleProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Renewal dates')),
      body: provider.isLoading && provider.renewals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadRenewals(),
              child: provider.renewals.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 100),
                      Center(child: Text('No renewals added yet.')),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: provider.renewals.length,
                      itemBuilder: (context, index) {
                        final renewal = provider.renewals[index];
                        final status = provider.getStatus(renewal);

                        // Find the bike name for display
                        String bikeName = '';
                        if (renewal.motorcycleId != null) {
                          try {
                            final bike = bikeProvider.activeBikes.firstWhere((b) => b.id == renewal.motorcycleId);
                            bikeName = '${bike.nickname} • ';
                          } catch (_) {}
                        }

                        Color badgeColor;
                        Color textColor;
                        String statusText;

                        switch (status) {
                          case RenewalStatus.overdue:
                            badgeColor = theme.colorScheme.errorContainer;
                            textColor = theme.colorScheme.onErrorContainer;
                            statusText = 'Overdue';
                            break;
                          case RenewalStatus.dueSoon:
                            badgeColor = Colors.orange.shade200;
                            textColor = Colors.orange.shade900;
                            statusText = 'Due soon';
                            break;
                          case RenewalStatus.ok:
                            badgeColor = Colors.green.shade100;
                            textColor = Colors.green.shade900;
                            statusText = 'OK';
                            break;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            title: Text(
                              renewal.renewalType[0].toUpperCase() + renewal.renewalType.substring(1),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('$bikeName${renewal.dueDate.year}-${renewal.dueDate.month.toString().padLeft(2, '0')}-${renewal.dueDate.day.toString().padLeft(2, '0')}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                                  child: Text(statusText, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'edit') _showAddEditDialog(renewalToEdit: renewal);
                                    if (val == 'delete') _deleteRenewal(renewal.id);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add renewal'),
      ),
    );
  }
}