import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../theme/app_skin_manager.dart';
import 'common/global_search_dialog.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    String h = time.hour.toString().padLeft(2, '0');
    String m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime date) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildSearchBar(BuildContext context, AppSkin skin) {
    final isDesktopOrWeb = kIsWeb || 
        defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.linux || 
        defaultTargetPlatform == TargetPlatform.macOS;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => GlobalSearchDialog.show(context),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            GlobalSearchDialog.show(context);
          },
          borderRadius: BorderRadius.circular(28),
          splashColor: skin.green.withValues(alpha: 0.15),
          highlightColor: skin.bg2.withValues(alpha: 0.3),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: skin.bg1.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: skin.bg2.withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: skin.green,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search LifeOS...',
                    style: TextStyle(
                      color: skin.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (isDesktopOrWeb) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: skin.bg2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: skin.bg2,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      '` / Ctrl+K',
                      style: TextStyle(
                        color: skin.textMuted,
                        fontSize: 11,
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.touch_app_rounded,
                    color: skin.textMuted.withValues(alpha: 0.4),
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Container(
      color: skin.bg0,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(_now),
              style: TextStyle(
                color: skin.fg,
                fontSize: 84,
                fontWeight: FontWeight.w200,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(_now),
              style: TextStyle(
                color: skin.textMuted,
                fontSize: 16,
                letterSpacing: 8.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            _buildSearchBar(context, skin),
          ],
        ),
      ),
    );
  }
}
