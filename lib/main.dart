import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://yfxleiyitrqzksmljjyp.supabase.co/rest/v1/',
    publishableKey: 'sb_publishable_FYSGTk5mPRJFv9tjylJ0yQ_fclXf1_U',
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