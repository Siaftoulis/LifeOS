import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class CHTMView extends StatelessWidget {
  const CHTMView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          _buildCalendarStrip(),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily Habits', style: TextStyle(color: EverforestColors.fg, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Expanded(child: _buildHabitsList()),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Time Ledger', style: TextStyle(color: EverforestColors.fg, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Expanded(child: _buildTimeLedger()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${now.day} ${months[now.month - 1]}, ${now.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calendar & Habits',
              style: TextStyle(
                color: EverforestColors.fg,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: const TextStyle(
                color: EverforestColors.green,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EverforestColors.bg2),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.mic, color: EverforestColors.blue),
                onPressed: () {},
                tooltip: 'Voice Note',
              ),
              Container(width: 1, height: 24, color: EverforestColors.bg2),
              IconButton(
                icon: const Icon(Icons.add_task, color: EverforestColors.green),
                onPressed: () {},
                tooltip: 'Add Task',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarStrip() {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14, // show 2 weeks
        itemBuilder: (context, index) {
          // Mocking dates starting from a few days ago
          final date = now.subtract(const Duration(days: 3)).add(Duration(days: index));
          final isToday = date.day == now.day && date.month == now.month;

          return Container(
            width: 60,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isToday ? EverforestColors.green : EverforestColors.bg1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isToday ? EverforestColors.green : EverforestColors.bg2),
              boxShadow: isToday
                  ? [BoxShadow(color: EverforestColors.green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  days[date.weekday - 1],
                  style: TextStyle(
                    color: isToday ? EverforestColors.bg0 : EverforestColors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isToday ? EverforestColors.bg0 : EverforestColors.fg,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHabitsList() {
    final habits = [
      {'name': 'Read 30 mins', 'streak': 12, 'done': true, 'color': EverforestColors.orange},
      {'name': 'Meditation', 'streak': 5, 'done': true, 'color': EverforestColors.purple},
      {'name': 'Workout', 'streak': 2, 'done': false, 'color': EverforestColors.red},
      {'name': 'Drink 2L Water', 'streak': 18, 'done': false, 'color': EverforestColors.aqua},
    ];

    return ListView.builder(
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final isDone = habit['done'] as bool;
        final color = habit['color'] as Color;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDone ? color.withOpacity(0.5) : EverforestColors.bg2),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDone ? color : EverforestColors.grey, width: 2),
                  ),
                  child: isDone ? const Icon(Icons.check, color: EverforestColors.bg0, size: 18) : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit['name'] as String,
                      style: TextStyle(
                        color: isDone ? EverforestColors.fg : EverforestColors.fg.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        decorationColor: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, color: color, size: 14),
                        const SizedBox(width: 4),
                        Text('${habit['streak']} days', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeLedger() {
    final ledgerItems = [
      {'time': '07:00 AM', 'title': 'Morning Routine & Breakfast', 'type': 'personal'},
      {'time': '08:30 AM', 'title': 'Deep Work: Backend API', 'type': 'work'},
      {'time': '11:00 AM', 'title': 'Team Sync Meeting', 'type': 'meeting'},
      {'time': '12:30 PM', 'title': 'Lunch Break', 'type': 'personal'},
      {'time': '01:30 PM', 'title': 'Write Documentation', 'type': 'work'},
      {'time': '04:00 PM', 'title': 'Review Pull Requests', 'type': 'work'},
    ];

    Color getTypeColor(String type) {
      switch (type) {
        case 'work': return EverforestColors.blue;
        case 'meeting': return EverforestColors.yellow;
        case 'personal': return EverforestColors.green;
        default: return EverforestColors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: ListView.builder(
        itemCount: ledgerItems.length,
        itemBuilder: (context, index) {
          final item = ledgerItems[index];
          final color = getTypeColor(item['type'] as String);

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    item['time'] as String,
                    style: const TextStyle(color: EverforestColors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    if (index < ledgerItems.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: EverforestColors.bg2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      )
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EverforestColors.bg0,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EverforestColors.bg2),
                    ),
                    child: Text(
                      item['title'] as String,
                      style: const TextStyle(color: EverforestColors.fg, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
