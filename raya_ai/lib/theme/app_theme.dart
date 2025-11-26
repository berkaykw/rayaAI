import 'package:flutter/material.dart';

class AppColors {
  static const Color pinkPrimary = Color(0xFFE91E63); // Colors.pink
  static const Color pinkSecondary = Color(0xFFF06292); // Colors.pinkAccent

  static const Color darkBackground = Color(0xFF101014);
  static const Color darkBackgroundTop = Color(0xFF1C1C1F);
  static const Color darkBackgroundBottom = Color(0xFF050505);
  static const Color darkSurface = Color(0xFF15151A);

  static const Color lightBackground = Color(0xFFFDFBFF);
  static const Color lightSurface = Color(0xFFFFFFFF);

  static const Color darkText = Colors.white;
  static const Color lightText = Color(0xFF2A2A2F);
}

class AppGradients {
  static const LinearGradient darkBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.darkBackgroundTop, AppColors.darkBackgroundBottom],
  );

  static const LinearGradient darkCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF23232A), Color(0xFF15151A)],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.pinkPrimary,
      brightness: Brightness.dark,
      primary: AppColors.pinkPrimary,
      secondary: AppColors.pinkSecondary,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.pinkPrimary.withOpacity(0.2),
        selectedColor: AppColors.pinkPrimary,
        labelStyle: const TextStyle(color: AppColors.darkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.darkText),
        bodyMedium: TextStyle(color: AppColors.darkText),
        bodySmall: TextStyle(color: Colors.white70),
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.pinkPrimary,
      brightness: Brightness.light,
      primary: AppColors.pinkPrimary,
      secondary: AppColors.pinkSecondary,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
    );

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.lightText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withOpacity(0.04)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.pinkPrimary.withOpacity(0.12),
        selectedColor: AppColors.pinkPrimary,
        labelStyle: const TextStyle(color: AppColors.lightText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.lightText),
        bodyMedium: TextStyle(color: AppColors.lightText),
        bodySmall: TextStyle(color: Colors.black54),
      ),
    );
  }
}
