import 'package:flutter/material.dart';
import 'theme_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._preferences, {ThemeMode initialMode = ThemeMode.dark})
      : _themeMode = initialMode;

  final ThemePreferences _preferences;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _preferences.saveThemeMode(mode);
  }
}

class ThemeControllerProvider extends InheritedNotifier<ThemeController> {
  const ThemeControllerProvider({
    super.key,
    required ThemeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();
    assert(provider != null, 'ThemeControllerProvider bulunamadı.');
    return provider!.notifier!;
  }
}

