import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class DownloadedVideosList extends StatelessWidget {
  const DownloadedVideosList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Downloaded Media', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: const [
                _VideoItem('Flutter Tutorial - State Management', '345 MB'),
                _VideoItem('Lofi Hip Hop Radio 24/7', '1.2 GB'),
                _VideoItem('Tech News Weekly', '128 MB'),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _VideoItem extends StatelessWidget {
  final String title;
  final String size;

  const _VideoItem(this.title, this.size);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: EverforestColors.bg0, borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(4)),
          child: const Icon(Icons.play_arrow, color: EverforestColors.grey),
        ),
        title: Text(title, style: const TextStyle(color: EverforestColors.fg, fontSize: 14)),
        subtitle: Text(size, style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
        trailing: const Icon(Icons.delete_outline, color: EverforestColors.red),
      ),
    );
  }
}
