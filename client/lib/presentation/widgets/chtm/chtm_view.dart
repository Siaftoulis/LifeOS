import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'daily_ledger_card.dart';
import 'habit_progress_grid.dart';
import 'voice_recorder_dialog.dart';

class CHTMView extends StatelessWidget {
  const CHTMView({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, dateStr),
          const SizedBox(height: 16),
          _buildCalendarStrip(),
          const SizedBox(height: 16),
          const Expanded(
            flex: 1,
            child: HabitProgressGrid(),
          ),
          const SizedBox(height: 16),
          const Expanded(
            flex: 2,
            child: DailyLedgerCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String dateStr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Task Manager',
                style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(dateStr, style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.mic, color: EverforestColors.green),
          onPressed: () => showDialog(context: context, builder: (_) => const VoiceRecorderDialog()),
        ),
      ],
    );
  }

  Widget _buildCalendarStrip() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final isToday = index == 3;
          return Container(
            width: 50,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isToday ? EverforestColors.green.withOpacity(0.2) : EverforestColors.bg1,
              border: Border.all(color: isToday ? EverforestColors.green : EverforestColors.bg2),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text('${index + 1}', style: TextStyle(color: isToday ? EverforestColors.green : EverforestColors.fg)),
          );
        },
      ),
    );
  }
}
