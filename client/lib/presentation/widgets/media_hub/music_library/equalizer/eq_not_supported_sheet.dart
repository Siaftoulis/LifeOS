import 'package:flutter/material.dart';
import '../../../../../theme/app_skin_manager.dart';

/// Shown when EQ is opened on platforms that don't support DSP (Web, macOS, iOS).
class EqNotSupportedSheet extends StatelessWidget {
  const EqNotSupportedSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: BoxDecoration(
        color: skin.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 40,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 48,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Icon(Icons.equalizer_rounded,
              color: skin.textMuted, size: 48),
          const SizedBox(height: 16),
          Text(
            'Equalizer Not Available',
            style: TextStyle(
              color: skin.fg,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Audio DSP is only available on Windows, Linux, and Android. '
              'On this platform, audio plays through the system mixer without EQ.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: skin.textMuted, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: skin.accent,
              foregroundColor: skin.accentContrast,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
