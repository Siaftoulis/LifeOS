import 'package:flutter/material.dart';

class ZenThemePreset {
  final String name;
  final Color bg0;
  final Color bg1;
  final Color bg2;
  final Color fg;
  final Color green;
  final Color red;
  final Color yellow;
  final Color blue;
  final Color purple;
  final Color aqua;
  final Color orange;
  final Color grey;
  final Color accent;

  const ZenThemePreset({
    required this.name,
    required this.bg0,
    required this.bg1,
    required this.bg2,
    required this.fg,
    required this.green,
    required this.red,
    required this.yellow,
    required this.blue,
    required this.purple,
    required this.aqua,
    required this.orange,
    required this.grey,
    required this.accent,
  });
}

class ZenThemeService extends ChangeNotifier {
  static final ZenThemeService instance = ZenThemeService._();
  ZenThemeService._();

  static const List<ZenThemePreset> presets = [
    ZenThemePreset(
      name: 'Everforest',
      bg0: Color(0xFF2D353B),
      bg1: Color(0xFF343F44),
      bg2: Color(0xFF3D484D),
      fg: Color(0xFFD3C6AA),
      green: Color(0xFFA7C080),
      red: Color(0xFFE67E80),
      yellow: Color(0xFFDBBC7F),
      blue: Color(0xFF7FBBB3),
      purple: Color(0xFFD699B6),
      aqua: Color(0xFF83C092),
      orange: Color(0xFFE69875),
      grey: Color(0xFF859289),
      accent: Color(0xFF7E57C2),
    ),
    ZenThemePreset(
      name: 'Obsidian Dark',
      bg0: Color(0xFF1E1E1E),
      bg1: Color(0xFF252526),
      bg2: Color(0xFF2D2D30),
      fg: Color(0xFFD4D4D4),
      green: Color(0xFF4EC9B0),
      red: Color(0xFFF44747),
      yellow: Color(0xFFDCDCAA),
      blue: Color(0xFF569CD6),
      purple: Color(0xFFC586C0),
      aqua: Color(0xFF9CDCFE),
      orange: Color(0xFFCE9178),
      grey: Color(0xFF808080),
      accent: Color(0xFF7C3AED),
    ),
    ZenThemePreset(
      name: 'Catppuccin Mocha',
      bg0: Color(0xFF1E1E2E),
      bg1: Color(0xFF181825),
      bg2: Color(0xFF313244),
      fg: Color(0xFFCDD6F4),
      green: Color(0xFFA6E3A1),
      red: Color(0xFFF38BA8),
      yellow: Color(0xFFF9E2AF),
      blue: Color(0xFF89B4FA),
      purple: Color(0xFFCBA6F7),
      aqua: Color(0xFF94E2D5),
      orange: Color(0xFFFAB387),
      grey: Color(0xFF6C7086),
      accent: Color(0xFFCBA6F7),
    ),
    ZenThemePreset(
      name: 'Nord',
      bg0: Color(0xFF2E3440),
      bg1: Color(0xFF3B4252),
      bg2: Color(0xFF434C5E),
      fg: Color(0xFFECEFF4),
      green: Color(0xFFA3BE8C),
      red: Color(0xFFBF616A),
      yellow: Color(0xFFEBCB8B),
      blue: Color(0xFF81A1C1),
      purple: Color(0xFFB48EAD),
      aqua: Color(0xFF88C0D0),
      orange: Color(0xFFD08770),
      grey: Color(0xFF4C566A),
      accent: Color(0xFF5E81AC),
    ),
    ZenThemePreset(
      name: 'Solarized Dark',
      bg0: Color(0xFF002B36),
      bg1: Color(0xFF073642),
      bg2: Color(0xFF586E75),
      fg: Color(0xFF839496),
      green: Color(0xFF859900),
      red: Color(0xFFDC322F),
      yellow: Color(0xFFB58900),
      blue: Color(0xFF268BD2),
      purple: Color(0xFF6C71C4),
      aqua: Color(0xFF2AA198),
      orange: Color(0xFFCB4B16),
      grey: Color(0xFF657B83),
      accent: Color(0xFF268BD2),
    ),
  ];

  static const List<Color> accentSwatches = [
    Color(0xFF7E57C2), // Deep Purple
    Color(0xFF7C3AED), // Obsidian Violet
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFFF97316), // Orange
    Color(0xFFEC4899), // Pink
    Color(0xFFA7C080), // Everforest Green
  ];

  static const List<String> availableFonts = [
    'JetBrainsMono',
    'FiraCode',
    'Inter',
    'System Default',
  ];

  ZenThemePreset _activePreset = presets[0];
  Color _accentColor = presets[0].accent;
  String _fontFamily = 'JetBrainsMono';
  double _fontSize = 16.0;
  String _baseColorScheme = 'Dark';

  ZenThemePreset get current => _activePreset;
  Color get accentColor => _accentColor;
  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  String get baseColorScheme => _baseColorScheme;

  // Markdown Element Specific Colors
  Color getHeadingColor(int level) {
    switch (level) {
      case 1:
        return _activePreset.green;
      case 2:
        return _activePreset.purple;
      case 3:
        return _activePreset.blue;
      case 4:
        return _activePreset.aqua;
      case 5:
        return _activePreset.orange;
      case 6:
      default:
        return _activePreset.grey;
    }
  }

  Color get boldColor => _activePreset.yellow;
  Color get italicColor => _activePreset.fg;
  Color get codeColor => _activePreset.aqua;
  Color get codeBgColor => _activePreset.bg1;
  Color get linkColor => _activePreset.blue;
  Color get quoteColor => _activePreset.yellow;
  Color get tagColor => _activePreset.green;

  ThemeData toThemeData() {
    final bool isDark = _baseColorScheme == 'Dark';
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: _activePreset.bg0,
      primaryColor: _accentColor,
      colorScheme: ColorScheme.dark(
        surface: _activePreset.bg0,
        primary: _accentColor,
        secondary: _activePreset.blue,
      ),
      fontFamily: _fontFamily == 'System Default' ? null : _fontFamily,
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          color: _activePreset.fg,
          fontSize: _fontSize,
          fontFamily: _fontFamily == 'System Default' ? null : _fontFamily,
        ),
      ),
    );
  }

  void setPreset(String presetName) {
    final found = presets.firstWhere(
      (p) => p.name == presetName,
      orElse: () => presets[0],
    );
    _activePreset = found;
    _accentColor = found.accent;
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    notifyListeners();
  }

  void setFontFamily(String font) {
    _fontFamily = font;
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void setBaseColorScheme(String scheme) {
    _baseColorScheme = scheme;
    notifyListeners();
  }
}
