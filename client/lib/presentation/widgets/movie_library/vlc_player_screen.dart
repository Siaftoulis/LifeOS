import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class VLCPlayerScreen extends StatelessWidget {
  const VLCPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Mock Video Display
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.video_camera_back, size: 100, color: EverforestColors.bg2),
                SizedBox(height: 16),
                Text('LibVLC Stub Player', style: TextStyle(color: EverforestColors.grey, fontSize: 24)),
              ],
            ),
          ),
          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: EverforestColors.fg, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Playback Controls
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: EverforestColors.bg0.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_arrow, color: EverforestColors.fg, size: 36),
                  const SizedBox(width: 16),
                  const Text('01:23:45', style: TextStyle(color: EverforestColors.fg)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: 0.6,
                      backgroundColor: EverforestColors.bg2,
                      color: EverforestColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('02:15:00', style: TextStyle(color: EverforestColors.fg)),
                  const SizedBox(width: 24),
                  const Icon(Icons.subtitles, color: EverforestColors.green, size: 28),
                  const SizedBox(width: 16),
                  const Icon(Icons.volume_up, color: EverforestColors.fg, size: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
