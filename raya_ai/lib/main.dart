import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:raya_ai/screens/splash_screen.dart';
import 'package:raya_ai/theme/app_theme.dart';
import 'package:raya_ai/theme/theme_controller.dart';
import 'package:raya_ai/theme/theme_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://supabase-raya.barancaki.me',
    anonKey: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc2MDg5NDc2MCwiZXhwIjo0OTE2NTY4MzYwLCJyb2xlIjoiYW5vbiJ9.o2R1gN6WAvvVhr4hPKbPb7lSNhhpdLKbItgT2HAKjA8',
  );

  final themePreferences = ThemePreferences();
  final initialThemeMode = await themePreferences.loadThemeMode();
  final themeController = ThemeController(
    themePreferences,
    initialMode: initialThemeMode,
  );

  runApp(
    DevicePreview(
      enabled: true, // test sırasında true, üretimde false yapabilirsiniz
      builder: (context) => MyApp(themeController: themeController),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ThemeControllerProvider(
      controller: themeController,
      child: AnimatedBuilder(
        animation: themeController,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            useInheritedMediaQuery: true, // DevicePreview için gerekli
            locale: DevicePreview.locale(context),
            builder: DevicePreview.appBuilder,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
