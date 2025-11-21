// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raya_ai/main.dart';
import 'package:raya_ai/theme/theme_controller.dart';
import 'package:raya_ai/theme/theme_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MyApp builds without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final themePreferences = ThemePreferences();
    final themeController = ThemeController(themePreferences);

    await tester.pumpWidget(MyApp(themeController: themeController));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
