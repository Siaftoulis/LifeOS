import 'package:flutter/material.dart';

/// Represents a cohesive visual skin/theme across the LifeOS ecosystem.
class AppSkin {
  final String id;
  final String name;
  final String description;
  final Brightness brightness;
  final List<String> tags;

  // Background hierarchy
  final Color bg0; // Canvas / base scaffold
  final Color bg1; // Card / modal / sidebar
  final Color bg2; // Elevated surface / input border / divider

  // Typography / Foregrounds
  final Color fg; // Primary text & active icons
  final Color textMuted; // Secondary / muted labels

  // Accent & Brand Colors
  final Color accent; // Signature highlight (e.g. neon cyan, emerald, purple)
  final Color accentSecondary; // Companion highlight

  // Semantic & Syntax Palette
  final Color green;
  final Color red;
  final Color yellow;
  final Color blue;
  final Color purple;
  final Color aqua;
  final Color orange;
  final Color cyan;
  final Color grey;

  const AppSkin({
    required this.id,
    required this.name,
    required this.description,
    required this.brightness,
    required this.tags,
    required this.bg0,
    required this.bg1,
    required this.bg2,
    required this.fg,
    required this.textMuted,
    required this.accent,
    required this.accentSecondary,
    required this.green,
    required this.red,
    required this.yellow,
    required this.blue,
    required this.purple,
    required this.aqua,
    required this.orange,
    required this.cyan,
    required this.grey,
  });

  bool get isDark => brightness == Brightness.dark;
  bool get isOled => id == 'oled';

  /// Generates a matching Flutter [ThemeData]
  ThemeData toThemeData() {
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: bg0,
      canvasColor: bg0,
      cardColor: bg1,
      dividerColor: bg2,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
        secondary: accentSecondary,
        onSecondary: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
        error: red,
        onError: Colors.white,
        surface: bg1,
        onSurface: fg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg0,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accent),
        titleTextStyle: TextStyle(
          color: fg,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg0,
        elevation: 0,
        indicatorColor: accent.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? IconThemeData(color: accent, size: 26)
                : IconThemeData(color: textMuted, size: 24)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)
                : TextStyle(color: textMuted, fontSize: 11)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bg1,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: bg2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg1,
        hintStyle: TextStyle(color: textMuted),
        labelStyle: TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: bg2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: bg2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? accent : grey),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? accent.withValues(alpha: 0.3)
                : bg2),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: bg2,
        thumbColor: accent,
      ),
      extensions: [
        AppSkinExtension(this),
      ],
    );
  }
}

/// Allows Theme.of(context).extension<AppSkinExtension>()
class AppSkinExtension extends ThemeExtension<AppSkinExtension> {
  final AppSkin skin;

  const AppSkinExtension(this.skin);

  @override
  ThemeExtension<AppSkinExtension> copyWith({AppSkin? skin}) {
    return AppSkinExtension(skin ?? this.skin);
  }

  @override
  ThemeExtension<AppSkinExtension> lerp(ThemeExtension<AppSkinExtension>? other, double t) {
    if (other is! AppSkinExtension) return this;
    // Skins switch discretely rather than blending color matrices
    return t < 0.5 ? this : other;
  }
}
