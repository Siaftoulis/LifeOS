import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class HabitProgressGrid extends StatelessWidget {
  const HabitProgressGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final habits = [
      {'name': 'Morning Run', 'streak': 5, 'target': 7},
      {'name': 'Read Book', 'streak': 2, 'target': 30},
    ];

    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Habit Streaks',
              style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(color: EverforestColors.bg2),
          Expanded(
            child: ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(habit['name'] as String, style: const TextStyle(color: EverforestColors.fg)),
                      ),
                      Expanded(
                        flex: 3,
                        child: _buildDots(habit['streak'] as int, habit['target'] as int),
                      ),
                      Text('${habit['streak']} / ${habit['target']}',
                          style: const TextStyle(color: EverforestColors.green, fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots(int streak, int target) {
    int maxDots = target > 7 ? 7 : target; // Show up to 7 dots visually
    return Row(
      children: List.generate(maxDots, (i) {
        final isActive = i < streak;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? EverforestColors.green : EverforestColors.bg2,
          ),
        );
      }),
    );
  }
}
