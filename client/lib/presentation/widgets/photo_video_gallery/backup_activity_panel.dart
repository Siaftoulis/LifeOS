import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class BackupActivityPanel extends StatelessWidget {
  const BackupActivityPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Backup Activity', style: TextStyle(color: EverforestColors.fg, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: const [
                _BackupItem(name: 'IMG_9001.jpg', progress: 1.0, done: true),
                _BackupItem(name: 'VID_9002.mp4', progress: 0.6, done: false),
                _BackupItem(name: 'IMG_9003.jpg', progress: 0.0, done: false),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _BackupItem extends StatelessWidget {
  final String name;
  final double progress;
  final bool done;

  const _BackupItem({required this.name, required this.progress, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.cloud_upload, color: done ? EverforestColors.green : EverforestColors.cyan),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: const TextStyle(color: EverforestColors.fg))),
          if (!done)
            SizedBox(width: 100, child: LinearProgressIndicator(value: progress, color: EverforestColors.cyan, backgroundColor: EverforestColors.bg2)),
        ],
      ),
    );
  }
}
