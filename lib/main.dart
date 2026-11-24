import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart'; // <-- NEW IMPORT
import 'features/auth/data/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/motorcycles/data/motorcycle_repository.dart';
import 'features/motorcycles/providers/motorcycle_provider.dart';
import 'features/odometer/data/odometer_repository.dart';
import 'features/odometer/providers/odometer_provider.dart';
import 'features/services/data/service_repository.dart';
import 'features/services/providers/service_provider.dart';
import 'features/renewals/data/renewal_repository.dart';
import 'features/renewals/providers/renewal_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://yfxleiyitrqzksmljjyp.supabase.co',
    publishableKey: 'sb_publishable_FYSGTk5mPRJFv9tjylJ0yQ_fclXf1_U',
  );
  runApp(const MotoCareApp());
}

final supabase = Supabase.instance.client;

class MotoCareApp extends StatelessWidget {
  const MotoCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- NEW: Theme Provider ---
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // --- AUTH ---
        Provider<AuthRepository>(create: (_) => AuthRepository(supabase)),
        ChangeNotifierProvider<AuthProvider>(
            create: (context) => AuthProvider(context.read<AuthRepository>())),

        // --- MOTORCYCLES ---
        Provider<MotorcycleRepository>(create: (_) => MotorcycleRepository(supabase)),
        ChangeNotifierProvider<MotorcycleProvider>(
            create: (context) => MotorcycleProvider(context.read<MotorcycleRepository>())),

        // --- ODOMETER ---
        Provider<OdometerRepository>(create: (_) => OdometerRepository(supabase)),
        ChangeNotifierProvider<OdometerProvider>(
            create: (context) => OdometerProvider(context.read<OdometerRepository>())),

        // --- SERVICES ---
        Provider<ServiceRepository>(create: (_) => ServiceRepository(supabase)),
        ChangeNotifierProvider<ServiceProvider>(
            create: (context) => ServiceProvider(context.read<ServiceRepository>())),

        // --- RENEWALS ---
        Provider<RenewalRepository>(create: (_) => RenewalRepository(supabase)),
        ChangeNotifierProvider<RenewalProvider>(
            create: (context) => RenewalProvider(context.read<RenewalRepository>())),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MotoCare Log',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode, // <-- Listens to the provider
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}