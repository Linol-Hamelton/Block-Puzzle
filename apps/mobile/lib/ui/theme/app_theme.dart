import 'package:flutter/material.dart';

class LuminaPalette {
  static const Color midnight = Color(0xFF0A1222);
  static const Color deepNavy = Color(0xFF12213A);
  static const Color panel = Color(0xE61B2C49);
  static const Color panelBorder = Color(0x444C75A4);
  static const Color cyan = Color(0xFF56D4FF);
  static const Color violet = Color(0xFF9B7CFF);
  static const Color amber = Color(0xFFFFAA6A);
  static const Color textPrimary = Color(0xFFEAF3FF);
  static const Color textSecondary = Color(0xFFB6CBE2);
}

class AppTheme {
  static ThemeData lightTheme() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: LuminaPalette.cyan,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: LuminaPalette.midnight,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: LuminaPalette.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 50)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          elevation: const WidgetStatePropertyAll<double>(0),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.2,
              height: 1.05,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return const Color(0xFF2D3E55);
              }
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFF3BBEE7);
              }
              if (states.contains(WidgetState.hovered)) {
                return const Color(0xFF49C9F0);
              }
              return LuminaPalette.cyan;
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return const Color(0xFF93A8BE);
              }
              return const Color(0xFF052033);
            },
          ),
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0x22FFFFFF);
              }
              if (states.contains(WidgetState.focused)) {
                return const Color(0x14FFFFFF);
              }
              return null;
            },
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 50)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          elevation: const WidgetStatePropertyAll<double>(0),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.2,
              height: 1.05,
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return const Color(0xFF8EA2B8);
              }
              return LuminaPalette.textPrimary;
            },
          ),
          side: WidgetStateProperty.resolveWith<BorderSide>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return const BorderSide(color: Color(0x334C75A4));
              }
              if (states.contains(WidgetState.pressed)) {
                return const BorderSide(color: Color(0xAA7FD6FF), width: 1.2);
              }
              return const BorderSide(color: LuminaPalette.panelBorder);
            },
          ),
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0x1FFFFFFF);
              }
              if (states.contains(WidgetState.focused)) {
                return const Color(0x14FFFFFF);
              }
              return null;
            },
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFFF8FBFF),
        elevation: 4,
        shadowColor: const Color(0x1A000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0x1A56D4FF),
        disabledColor: Color(0x331A2B42),
        selectedColor: Color(0x334FA7FF),
        secondarySelectedColor: Color(0x339B7CFF),
        labelStyle: TextStyle(
          color: LuminaPalette.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        secondaryLabelStyle: TextStyle(
          color: LuminaPalette.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        brightness: Brightness.dark,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: StadiumBorder(
          side: BorderSide(color: LuminaPalette.panelBorder),
        ),
      ),
    );
  }
}
