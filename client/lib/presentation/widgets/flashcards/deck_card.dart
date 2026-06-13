import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'flashcard_session_screen.dart';

class DeckCard extends StatelessWidget {
  final String title;
  final int newCards;
  final int dueCards;

  const DeckCard({super.key, required this.title, required this.newCards, required this.dueCards});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FlashcardSessionScreen()));
      },
      child: Container(
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EverforestColors.bg2),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_special, color: EverforestColors.yellow, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('New: $newCards', style: const TextStyle(color: EverforestColors.blue, fontSize: 12)),
                Text('Due: $dueCards', style: const TextStyle(color: EverforestColors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: 0.3, backgroundColor: EverforestColors.bg2, color: EverforestColors.green),
          ],
        ),
      ),
    );
  }
}
