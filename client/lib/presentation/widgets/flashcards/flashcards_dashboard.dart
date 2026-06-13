import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'deck_card.dart';

class FlashcardsDashboard extends StatelessWidget {
  const FlashcardsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildDailyTargets(),
          const SizedBox(height: 24),
          const Text('Active Decks', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: const [
                DeckCard(title: 'Go Programming', newCards: 12, dueCards: 45),
                DeckCard(title: 'History 101', newCards: 0, dueCards: 5),
                DeckCard(title: 'Spanish Vocab', newCards: 20, dueCards: 110),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Flashcards & SRS', style: TextStyle(color: EverforestColors.fg, fontSize: 20, fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.file_upload, color: EverforestColors.green),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import .apkg dialog...')));
          },
        ),
      ],
    );
  }

  Widget _buildDailyTargets() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Due Today', value: '160', color: EverforestColors.red),
          _Stat(label: 'New Cards', value: '32', color: EverforestColors.blue),
          _Stat(label: 'Streak', value: '12 Days', color: EverforestColors.orange),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
      ],
    );
  }
}
