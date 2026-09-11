import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/music_playback/android_media_bridge.dart';
import '../../../../../core/music_playback/playback_controller.dart';
import '../../../../../theme/app_skin_manager.dart';

class HomeWidgetCustomizerSheet extends StatefulWidget {
  const HomeWidgetCustomizerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HomeWidgetCustomizerSheet(),
    );
  }

  @override
  State<HomeWidgetCustomizerSheet> createState() => _HomeWidgetCustomizerSheetState();
}

class _HomeWidgetCustomizerSheetState extends State<HomeWidgetCustomizerSheet> {
  bool _showArtwork = true;
  int _opacity = 90;
  String _themeStyle = 'glass'; // 'glass', 'oled', 'accent', 'border'
  String _targetTab = 'music_player'; // 'music_player', 'music', 'movies', 'gallery', 'youtube', 'home'
  String _widgetType = 'standard'; // 'standard', 'compact'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showArtwork = prefs.getBool('widget_show_art') ?? true;
        _opacity = prefs.getInt('widget_bg_opacity') ?? 90;
        _themeStyle = prefs.getString('widget_theme_style') ?? 'glass';
        _targetTab = prefs.getString('widget_target_tab') ?? 'music_player';
        _widgetType = prefs.getString('widget_type') ?? 'standard';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('widget_show_art', _showArtwork);
    await prefs.setInt('widget_bg_opacity', _opacity);
    await prefs.setString('widget_theme_style', _themeStyle);
    await prefs.setString('widget_target_tab', _targetTab);
    await prefs.setString('widget_type', _widgetType);

    AndroidMediaBridge.instance.updateWidgetConfig(
      showArtwork: _showArtwork,
      opacity: _opacity,
      themeStyle: _themeStyle,
      targetTab: _targetTab,
      widgetType: _widgetType,
    );
  }

  String _destinationLabel(String key) {
    switch (key) {
      case 'music_player':
        return 'Now Playing (At Play)';
      case 'music':
        return 'Music Library';
      case 'movies':
        return 'Movies & Series';
      case 'gallery':
        return 'Gallery';
      case 'youtube':
        return 'YouTube';
      case 'home':
        return 'LifeOS Home';
      default:
        return 'Now Playing';
    }
  }

  Color _computePreviewBg(AppSkin skin) {
    final alpha = (_opacity / 100.0).clamp(0.0, 1.0);
    switch (_themeStyle) {
      case 'oled':
        return Colors.black.withValues(alpha: alpha);
      case 'accent':
        return const Color(0xFF0E1E30).withValues(alpha: alpha);
      case 'border':
        return const Color(0xFF080A0C).withValues(alpha: alpha);
      case 'glass':
      default:
        return const Color(0xFF12161A).withValues(alpha: alpha);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final activeItem = PlaybackController.instance.currentItem;
    final displayTitle = activeItem?.title.isNotEmpty == true ? activeItem!.title : 'Starboy';
    final displayArtist = activeItem?.artist.isNotEmpty == true ? activeItem!.artist : 'The Weeknd • Daft Punk';

    return Container(
      decoration: BoxDecoration(
        color: skin.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: _isLoading
          ? const Center(heightFactor: 5, child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Row(
                    children: [
                      Icon(Icons.widgets_rounded, color: skin.accent, size: 26),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Home Screen Widget',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Customize how the music widget looks outside the app on your phone home screen.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // LIVE PREVIEW CARD
                  Text(
                    'LIVE PREVIEW',
                    style: TextStyle(
                      color: skin.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _computePreviewBg(skin),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _themeStyle == 'border' ? Colors.white30 : Colors.white12,
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Widget Tag & Destination Badge
                        Row(
                          children: [
                            Text(
                              'LIFEOS',
                              style: TextStyle(
                                color: skin.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.1,
                              ),
                            ),
                            Text(
                              _widgetType == 'compact' ? ' • COMPACT' : ' • MUSIC',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                letterSpacing: 0.08,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: skin.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: skin.accent.withValues(alpha: 0.4), width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app_rounded, color: skin.accent, size: 11),
                                  const SizedBox(width: 4),
                                  Text(
                                    _destinationLabel(_targetTab),
                                    style: TextStyle(
                                      color: skin.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Track row
                        Row(
                          children: [
                            if (_showArtwork) ...[
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white24, width: 1),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: activeItem?.thumbnail.isNotEmpty == true
                                    ? Image.network(activeItem!.thumbnail, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.music_note_rounded, color: Colors.white70))
                                    : const Icon(Icons.music_note_rounded, color: Colors.white70),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    displayArtist,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Controls Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_widgetType != 'compact') ...[
                              _buildPreviewBtn(Icons.skip_previous_rounded, 38),
                              const SizedBox(width: 18),
                            ],
                            _buildPreviewBtn(Icons.play_arrow_rounded, 44, isPlay: true, accent: skin.accent),
                            if (_widgetType != 'compact') ...[
                              const SizedBox(width: 18),
                              _buildPreviewBtn(Icons.skip_next_rounded, 38),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 1. TAP DESTINATION SELECTOR
                  const Text(
                    'Tap Action (Open Directly To)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose where LifeOS navigates when you tap the widget on your home screen',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChoiceChip('music_player', '🎵 Now Playing (At Play)', skin, _targetTab, (k) => setState(() => _targetTab = k)),
                      _buildChoiceChip('music', '🎶 Music Library', skin, _targetTab, (k) => setState(() => _targetTab = k)),
                      _buildChoiceChip('movies', '🎬 Movies & Series', skin, _targetTab, (k) => setState(() => _targetTab = k)),
                      _buildChoiceChip('gallery', '🖼️ Gallery', skin, _targetTab, (k) => setState(() => _targetTab = k)),
                      _buildChoiceChip('youtube', '📺 YouTube', skin, _targetTab, (k) => setState(() => _targetTab = k)),
                      _buildChoiceChip('home', '🏠 LifeOS Home', skin, _targetTab, (k) => setState(() => _targetTab = k)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 2. WIDGET LAYOUT STYLE
                  const Text(
                    'Widget Layout Style',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Full player with 3 controls or sleek minimalist single-button compact bar',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChoiceChip('standard', '📻 Full Media Player (3 Buttons)', skin, _widgetType, (k) => setState(() => _widgetType = k)),
                      _buildChoiceChip('compact', '⚡ Compact Bar (Quick Play)', skin, _widgetType, (k) => setState(() => _widgetType = k)),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 12),

                  // 3. ALBUM ART TOGGLE
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: skin.accent,
                    title: const Text(
                      'Show Album Artwork',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Displays live song cover inside the home screen widget',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    value: _showArtwork,
                    onChanged: (val) {
                      setState(() => _showArtwork = val);
                      _saveAndSync();
                    },
                  ),

                  const SizedBox(height: 16),

                  // 4. TRANSPARENCY SLIDER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Background Transparency',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${_opacity}%',
                        style: TextStyle(color: skin.accent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: _opacity.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    activeColor: skin.accent,
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      setState(() => _opacity = val.toInt());
                    },
                    onChangeEnd: (val) {
                      _saveAndSync();
                    },
                  ),

                  const SizedBox(height: 16),

                  // 5. THEME STYLE CHOICES
                  const Text(
                    'Widget Theme Style',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildThemeChip('glass', 'Glass Dark', skin),
                      _buildThemeChip('oled', 'Pure OLED', skin),
                      _buildThemeChip('accent', 'Aura Accent', skin),
                      _buildThemeChip('border', 'Minimal Border', skin),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: skin.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        _saveAndSync();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Widget appearance synced to Android home screen!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text(
                        'Save & Apply to Home Screen',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChoiceChip(
    String key,
    String label,
    AppSkin skin,
    String selectedValue,
    ValueChanged<String> onSelected,
  ) {
    final selected = selectedValue == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: skin.accent,
      backgroundColor: skin.bg1,
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white70,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) {
          onSelected(key);
          _saveAndSync();
        }
      },
    );
  }

  Widget _buildThemeChip(String key, String label, AppSkin skin) {
    final selected = _themeStyle == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: skin.accent,
      backgroundColor: skin.bg1,
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white70,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _themeStyle = key);
          _saveAndSync();
        }
      },
    );
  }

  Widget _buildPreviewBtn(IconData icon, double size, {bool isPlay = false, Color? accent}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPlay ? (accent ?? Colors.white) : Colors.white.withValues(alpha: 0.15),
      ),
      child: Center(
        child: Icon(
          icon,
          size: size * 0.55,
          color: isPlay ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}
