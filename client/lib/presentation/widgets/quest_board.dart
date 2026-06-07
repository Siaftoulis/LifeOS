import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

class QuestBoard extends StatelessWidget {
  const QuestBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: EverforestColors.bg0,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: EverforestColors.fg, width: 1.5),
                ),
                child: const Text('QUEST BOARD', style: TextStyle(color: EverforestColors.fg, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: EverforestColors.yellow.withOpacity(0.5), width: 1.0),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star_border, color: EverforestColors.yellow, size: 16),
                    SizedBox(width: 8),
                    Text('1,240', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          const Text('DAILY QUESTS', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          _buildQuestItem('Complete morning workout', '+50', true),
          _buildQuestItem('Read 20 pages of documentation', '+30', false),
          _buildQuestItem('Hydration goal (2L)', '+20', true),
          const SizedBox(height: 48),
          const Text('REWARD STORE', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EverforestColors.grey.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Trip Ticket', style: TextStyle(color: EverforestColors.fg, fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text('Redeem for a weekend getaway', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: EverforestColors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: EverforestColors.yellow, width: 1),
                  ),
                  child: const Text('500 ⭐', style: TextStyle(color: EverforestColors.yellow, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuestItem(String title, String reward, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: isCompleted ? EverforestColors.fg : EverforestColors.grey, width: 1.5),
            ),
            child: isCompleted ? const Center(child: Icon(Icons.check, size: 14, color: EverforestColors.fg)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(color: isCompleted ? EverforestColors.grey : EverforestColors.fg, fontSize: 14, decoration: isCompleted ? TextDecoration.lineThrough : null))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: EverforestColors.yellow.withOpacity(0.5), width: 1),
            ),
            child: Text('$reward', style: const TextStyle(color: EverforestColors.yellow, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
