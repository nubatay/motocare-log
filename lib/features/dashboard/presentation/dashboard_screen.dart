import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../motorcycles/data/motorcycle_repository.dart';
import '../../motorcycles/providers/motorcycle_provider.dart';
import '../../odometer/providers/odometer_provider.dart';
import '../../services/domain/service_calculator.dart';
import '../../services/presentation/service_screen.dart';
import '../../services/providers/service_provider.dart';
import '../../services/presentation/log_service_screen.dart';
import '../../odometer/presentation/update_odometer_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _lastLoadedBikeId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeBike = context.watch<MotorcycleProvider>().activeBike;
    
    if (activeBike != null && activeBike.id != _lastLoadedBikeId) {
      _lastLoadedBikeId = activeBike.id;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadData(activeBike);
      });
    }
  }

  Future<void> _loadData(Motorcycle bike) async {
    final odoProvider = context.read<OdometerProvider>();
    final serviceProvider = context.read<ServiceProvider>();

    await odoProvider.loadReadings(
      motorcycleId: bike.id,
      dailyDistanceKm: bike.dailyDistanceKm,
      currentOdometerFallback: bike.currentOdometer,
    );

    final estimatedOdo = odoProvider.estimate?.estimatedKm ?? bike.currentOdometer;

    if (mounted) {
      await serviceProvider.loadData(
        motorcycleId: bike.id,
        estimatedOdometer: estimatedOdo,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bikeProvider = context.watch<MotorcycleProvider>();
    final activeBike = bikeProvider.activeBike;
    final odoProvider = context.watch<OdometerProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (activeBike == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.two_wheeler, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: AppSpacing.md),
              const Text('No active motorcycle.'),
              const SizedBox(height: AppSpacing.sm),
              const Text('Go to the Motorcycles tab to add or activate one.'),
            ],
          ),
        ),
      );
    }

    // --- SKELETON LOADING STATE ---
    if (odoProvider.isLoading || serviceProvider.isLoading) {
      return const _DashboardSkeleton();
    }

    final dueServices = serviceProvider.overviews
        .where((s) => s.status.status == ServiceStatus.overdue || s.status.status == ServiceStatus.dueSoon)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(activeBike),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(activeBike),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(activeBike.nickname, style: theme.textTheme.titleLarge),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Estimated mileage', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${odoProvider.estimate?.estimatedKm ?? activeBike.currentOdometer} km',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 36, 
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (odoProvider.latestReading != null)
                      Text(
                        'Last real reading: ${odoProvider.latestReading!.valueKm} km on ${odoProvider.latestReading!.readingDate.month}/${odoProvider.latestReading!.readingDate.day}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text('Next services', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            if (dueServices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('All caught up! No services due soon.'),
              )
            else
              ...dueServices.map((overview) {
                final isOverdue = overview.status.status == ServiceStatus.overdue;
                
                final bgColor = isOverdue 
                    ? (isDark ? const Color(0xFF3B1A1D) : const Color(0xFFFDECEA))
                    : (isDark ? const Color(0xFF33210A) : const Color(0xFFFFF4E5));
                final txtColor = isOverdue 
                    ? (isDark ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F))
                    : (isDark ? const Color(0xFFFFB74D) : const Color(0xFFED6C02));

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                    title: Text(overview.type.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      isOverdue
                          ? 'Was due at ${overview.status.dueKm ?? ''} km' 
                          : 'Due soon',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOverdue ? 'Overdue' : 'Due soon',
                        style: TextStyle(color: txtColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ServiceScreen(bike: activeBike),
                      ));
                    },
                  ),
                );
              }),
            
            const SizedBox(height: AppSpacing.xl),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UpdateOdometerScreen(bike: activeBike),
                        ),
                      );
                    },
                    child: const Text('Update odometer'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => LogServiceScreen(bike: activeBike),
                      ));
                    },
                    child: const Text('Log service'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------
// SKELETON LOADING WIDGETS
// -------------------------------------------------------------------------

class _DashboardSkeleton extends StatefulWidget {
  const _DashboardSkeleton();

  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: FadeTransition(
        opacity: _animation,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Skeleton for Active Bike Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _SkeletonBox(width: 100, height: 24), // Nickname
                        _SkeletonBox(width: 60, height: 24, radius: 20), // Active Badge
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SkeletonBox(width: 120, height: 14), // "Estimated mileage"
                    const SizedBox(height: AppSpacing.sm),
                    const _SkeletonBox(width: 200, height: 40), // The big number
                    const SizedBox(height: AppSpacing.sm),
                    const _SkeletonBox(width: 180, height: 14), // "Last real reading"
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Skeleton for "Next services" header
            const _SkeletonBox(width: 140, height: 24),
            const SizedBox(height: AppSpacing.md),
            
            // Skeleton for 2 list items
            ...List.generate(2, (index) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _SkeletonBox(width: 150, height: 18), // Service name
                        SizedBox(height: AppSpacing.sm),
                        _SkeletonBox(width: 100, height: 14), // Due details
                      ],
                    ),
                    const _SkeletonBox(width: 80, height: 28, radius: 20), // Badge
                  ],
                ),
              ),
            )),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Skeleton for Quick Actions
            Row(
              children: const [
                Expanded(child: _SkeletonBox(width: double.infinity, height: 52, radius: 26)),
                SizedBox(width: AppSpacing.md),
                Expanded(child: _SkeletonBox(width: double.infinity, height: 52, radius: 26)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}