import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'slideable_task_card.dart';

class DailyLedgerCard extends StatelessWidget {
  const DailyLedgerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = [
      {'id': '1', 'title': 'Complete CHTM implementation', 'priority': 4, 'status': 'TODO'},
      {'id': '2', 'title': 'Review accounting logs', 'priority': 2, 'status': 'IN_PROGRESS'},
      {'id': '3', 'title': 'Read 10 pages', 'priority': 1, 'status': 'TODO'},
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Ledger',
                  style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${tasks.length} pending',
                  style: const TextStyle(color: EverforestColors.yellow, fontSize: 12)),
            ],
          ),
          const Divider(color: EverforestColors.bg2),
          Expanded(
            child: ListView.separated(
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return SlideableTaskCard(
                  title: task['title'] as String,
                  priority: task['priority'] as int,
                  status: task['status'] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
