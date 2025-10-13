import 'package:flutter/material.dart';
import 'package:raya_ai/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hmgogtftoaqqkkyaukog.supabase.co/',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtZ29ndGZ0b2FxcWtreWF1a29nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk4OTUzMzQsImV4cCI6MjA3NTQ3MTMzNH0.xlXwFLeXb3Gb9E6lwdpglt3dg6wJPQI12ooiJkw0Y70', 
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const SplashScreen(),
    );
  }
}
