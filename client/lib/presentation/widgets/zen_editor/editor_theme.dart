import 'package:flutter/material.dart';

class EverforestColors {
  static const Color bg0 = Color(0xFF2d353b);
  static const Color bg1 = Color(0xFF343f44);
  static const Color bg2 = Color(0xFF3d484d);
  
  static const Color fg = Color(0xFFd3c6aa);
  static const Color grey = Color(0xFF859289);
  static const Color accent = Color(0xFFa7c080);
}

class ZenEditorTheme {
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: EverforestColors.bg0,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: EverforestColors.fg),
        bodyMedium: TextStyle(color: EverforestColors.fg),
        labelSmall: TextStyle(color: EverforestColors.grey),
      ),
      cardColor: EverforestColors.bg1,
      dividerColor: EverforestColors.bg2,
    );
  }
}
