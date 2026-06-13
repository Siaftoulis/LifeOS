import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class WordOfTheDayCard extends StatelessWidget {
  const WordOfTheDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Word of the Day', style: TextStyle(color: EverforestColors.grey, fontSize: 16)),
          const SizedBox(height: 16),
          const Text('Ενσυναίσθηση', style: TextStyle(color: EverforestColors.yellow, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Empathy', style: TextStyle(color: EverforestColors.blue, fontSize: 24, fontStyle: FontStyle.italic)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: EverforestColors.bg0, borderRadius: BorderRadius.circular(8)),
            child: const Text(
              'The ability to understand and share the feelings of another.',
              style: TextStyle(color: EverforestColors.fg, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}
