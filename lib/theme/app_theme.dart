import 'package:flutter/material.dart';

class AppTheme {
  static const accent = Color(0xFFC8E84A);
  static const dark = Color(0xFF1E1E1E);
  static const danger = Color(0xFFE74C3C);
  static const muscle = Color(0xFFE57373);
  static const water = Color(0xFF4FC3F7);
  static const fat = Color(0xFFE5C453);
  static const positive = Color(0xFF66BB6A);
  static const bgGrey = Color(0xFFF7F8F5);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: bgGrey,
      appBarTheme: const AppBarTheme(
        backgroundColor: dark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
