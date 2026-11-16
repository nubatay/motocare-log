// lib/main.dart
//
// Entry point. Initialises Supabase, injects the AuthRepository and
// AuthProvider into the widget tree, and applies the app theme.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/motorcycles/providers/motorcycle_provider.dart';
import 'features/motorcycles/data/motorcycle_repository.dart';

Future<void> main() async {
  // Ensures Flutter bindings are ready before calling Supabase.
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yfxleiyitrqzksmljjyp.supabase.co',
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
    // MultiProvider lets us provide multiple objects to the widget tree.
    // 1. AuthRepository (plain Provider because it doesn't hold UI state).
    // 2. AuthProvider (ChangeNotifierProvider so it can rebuild the UI).
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => AuthRepository(supabase),
        ),
        ChangeNotifierProvider<AuthProvider>(
          // context.read grabs the AuthRepository we just created above.
          create: (context) => AuthProvider(context.read<AuthRepository>()),
        ),
        Provider<MotorcycleRepository>(
          create: (_) => MotorcycleRepository(supabase),
        ),
        ChangeNotifierProvider<MotorcycleProvider>(
          create: (context) => MotorcycleProvider(context.read<MotorcycleRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'MotoCare Log',
        debugShowCheckedModeBanner: false,
        
        // Apply the themes we created in File 3.
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        
        // ThemeMode.system means it follows the user's phone/browser
        // light or dark mode setting automatically.
        themeMode: ThemeMode.system,
        
        // We use a temporary Home widget here.
        // In File 10, we will replace this with the real AuthGate.
        home: const AuthGate(),
      ),
    );
  }
}
