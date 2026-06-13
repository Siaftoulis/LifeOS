import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'lyrics_sync_viewer.dart';

class MusicPlayerOverlay extends StatelessWidget {
  const MusicPlayerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: _buildNowPlaying()),
                const SizedBox(width: 24),
                const Expanded(flex: 3, child: LyricsSyncViewer()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200, height: 200,
          decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
          child: const Icon(Icons.album, size: 100, color: EverforestColors.grey),
        ),
        const SizedBox(height: 32),
        const Text('Nightcall', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
        const Text('Kavinsky', style: TextStyle(color: EverforestColors.cyan, fontSize: 18)),
        const SizedBox(height: 32),
        const LinearProgressIndicator(value: 0.3, backgroundColor: EverforestColors.bg2, color: EverforestColors.green),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.skip_previous, color: EverforestColors.fg, size: 40),
            SizedBox(width: 16),
            Icon(Icons.play_circle_fill, color: EverforestColors.green, size: 64),
            SizedBox(width: 16),
            Icon(Icons.skip_next, color: EverforestColors.fg, size: 40),
          ],
        ),
      ],
    );
  }
}
