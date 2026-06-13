import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class MarkdownFocusViewport extends StatelessWidget {
  const MarkdownFocusViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ideas.md', style: TextStyle(color: EverforestColors.grey, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: EverforestColors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Text('Syncing... (+5 pts/hr)', style: TextStyle(color: EverforestColors.green, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 24),
          const Expanded(
            child: TextField(
              maxLines: null,
              expands: true,
              style: TextStyle(color: Color(0xFFFAFAFA), fontSize: 18, height: 1.6),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Type your thoughts...',
                hintStyle: TextStyle(color: EverforestColors.bg2),
              ),
            ),
          )
        ],
      ),
    );
  }
}
