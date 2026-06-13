import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class LyricsSyncViewer extends StatelessWidget {
  const LyricsSyncViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Synced Lyrics', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Study Check (+2 Points)', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.yellow, foregroundColor: EverforestColors.bg0),
                onPressed: () {},
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: const [
                _LyricLine(text: "I'm giving you a nightcall to tell you how I feel", active: false),
                _LyricLine(text: "I want to drive you through the night, down the hills", active: true),
                _LyricLine(text: "I'm gonna tell you something you don't want to hear", active: false),
                _LyricLine(text: "I'm gonna show you where it's dark, but have no fear", active: false),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _LyricLine extends StatelessWidget {
  final String text;
  final bool active;

  const _LyricLine({required this.text, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: active ? EverforestColors.green : EverforestColors.grey,
          fontSize: active ? 24 : 18,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
