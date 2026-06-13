import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class TriviaLogTimeline extends StatelessWidget {
  const TriviaLogTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Daily Trivia Logs', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: EverforestColors.orange, width: 4)),
                    color: EverforestColors.bg0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Day ${100 - index}', style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      const Text('Honey never spoils. Archaeologists have found pots of honey in ancient Egyptian tombs that are over 3,000 years old.', style: TextStyle(color: EverforestColors.fg)),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
