import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'word_of_the_day_card.dart';
import 'trivia_log_timeline.dart';

class ProjectInfinityDashboard extends StatelessWidget {
  const ProjectInfinityDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Project Infinity', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: WordOfTheDayCard()),
                SizedBox(width: 16),
                Expanded(flex: 2, child: TriviaLogTimeline()),
              ],
            ),
          )
        ],
      ),
    );
  }
}
