// lib/main.dart
//
// Entry point. Initialises Supabase, injects the repositories and
// providers into the widget tree, and applies the app theme.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/motorcycles/data/motorcycle_repository.dart';
import 'features/motorcycles/providers/motorcycle_provider.dart';
import 'features/odometer/data/odometer_repository.dart';
import 'features/odometer/providers/odometer_provider.dart';
import 'features/services/data/service_repository.dart';
import 'features/services/providers/service_provider.dart';

Future<void> main() async {
  // Ensures Flutter bindings are ready before calling Supabase.
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yfxleiyitrqzksmljjyp.supabase.co',
    // Note: The publishable key is safe to use in the client, but 
    // avoid committing it to public repositories.
    publishableKey: 'sb_publishable_FYSGTk5mPRJFv9tjylJ0yQ_fclXf1_U',
  );

  runApp(const MotoCareApp());
}

// A global shortcut so the repository can access the client easily.
final supabase = Supabase.instance.client;

class MotoCareApp extends StatelessWidget {
  const MotoCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // --- Auth ---
        Provider<AuthRepository>(
          create: (_) => AuthRepository(supabase),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthRepository>()),
        ),
        
        // --- Motorcycles ---
        Provider<MotorcycleRepository>(
          create: (_) => MotorcycleRepository(supabase),
        ),
        ChangeNotifierProvider<MotorcycleProvider>(
          create: (context) => MotorcycleProvider(context.read<MotorcycleRepository>()),
        ),
        
        // --- Odometer ---
        Provider<OdometerRepository>(
          create: (_) => OdometerRepository(supabase),
        ),
        ChangeNotifierProvider<OdometerProvider>(
          create: (context) => OdometerProvider(context.read<OdometerRepository>()),
        ),

        // --- SERVICES ---
        Provider<ServiceRepository>(
          create: (_) => ServiceRepository(supabase),
        ),
        ChangeNotifierProvider<ServiceProvider>(
          create: (context) => ServiceProvider(context.read<ServiceRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'MotoCare Log',
        debugShowCheckedModeBanner: false,
        
        // Apply the Material 3 themes
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        
        // Follows the user's phone/browser setting
        themeMode: ThemeMode.system,
        
        // The AuthGate decides whether to show Login or MyMotorcycles
        home: const AuthGate(),
      ),
    );
  }
}