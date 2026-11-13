import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://supabase.com/dashboard/project/yfxleiyitrqzksmljjyp',
    publishableKey: 'sb_publishable_pEBKq6u2HNaiRDDNyVAB7Q_bvVqCBNO',
  );
  runApp(const MotoCareApp());
}

final supabase = Supabase.instance.client;

class MotoCareApp extends StatelessWidget {
  const MotoCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'MotoCare Log',
      home: Scaffold(
        body: Center(child: Text('MotoCare Log is running')),
      ),
    );
  }
}