import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme() {
    const base = Color(0xFF0A4D68);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: base),
      scaffoldBackgroundColor: const Color(0xFFF5F8FA),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF0D1B2A),
      ),
    );
  }
}
