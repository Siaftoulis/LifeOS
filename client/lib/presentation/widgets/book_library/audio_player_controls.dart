import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class AudioPlayerControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onRewind;
  final VoidCallback onForward;

  const AudioPlayerControls({
    super.key,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onRewind,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10, color: EverforestColors.fg, size: 32),
          onPressed: onRewind,
        ),
        GestureDetector(
          onTap: onTogglePlay,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EverforestColors.green.withValues(alpha: 0.2),
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: EverforestColors.green,
              size: 48,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.forward_30, color: EverforestColors.fg, size: 32),
          onPressed: onForward,
        ),
      ],
    );
  }
}
