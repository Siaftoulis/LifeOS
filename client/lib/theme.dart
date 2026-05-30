import 'package:flutter/material.dart';

abstract class OLEDTheme {
  static const bg = Color(0xFF09090B);
  static const primary = Color(0xFFA78BFA);
  static const accent = Color(0xFF00E5FF);
  static const textPrimary = Color(0xFFF0F0F0);
  static const textSecondary = Color(0xFF808080);

  static ThemeData build() => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: primary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.36, // -0.02em of 18px
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      indicatorColor: accent.withOpacity(0.12),
      iconTheme: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? const IconThemeData(color: accent, size: 26) : const IconThemeData(color: textSecondary, size: 24)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? const TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600) : const TextStyle(color: textSecondary, fontSize: 11)),
    ),
    colorScheme: const ColorScheme.dark(surface: bg, primary: primary, secondary: accent),
  );
}
