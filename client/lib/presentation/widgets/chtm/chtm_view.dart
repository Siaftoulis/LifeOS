import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../database/chtm_dao.dart';
import 'chtm_full_calendar.dart';
import 'chtm_daily_list.dart';
import 'habit_tracker_view.dart';

class CHTMView extends StatefulWidget {
  const CHTMView({super.key});

  @override
  State<CHTMView> createState() => _CHTMViewState();
}

class _CHTMViewState extends State<CHTMView> {
  DateTime _selectedDate = DateTime.now();
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase.instance;
    final dao = ChtmDao(db);

    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildHeader(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildTabs(),
            ),
            Expanded(
              child: _currentTab == 0 ? _buildCalendarTab(dao) : const HabitTrackerView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton(0, 'Calendar', Icons.calendar_month)),
          Expanded(child: _buildTabButton(1, 'Habits', Icons.track_changes)),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? EverforestColors.green.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? EverforestColors.green : EverforestColors.grey),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? EverforestColors.green : EverforestColors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarTab(ChtmDao dao) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CHTMFullCalendar(
            eventsStream: dao.watchAllEvents(),
            tasksStream: dao.watchAllTasks(),
            habitLogsStream: dao.watchAllHabitLogs(),
            initialDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Daily Agenda',
              style: TextStyle(
                color: EverforestColors.fg,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          CHTMDailyList(
            selectedDate: _selectedDate,
          ),
          const SizedBox(height: 24),
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
              'CHTM',
              style: TextStyle(
                color: EverforestColors.fg,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: const TextStyle(
                color: EverforestColors.green,
                fontSize: 14,
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
                icon: const Icon(Icons.mic, color: EverforestColors.blue, size: 20),
                onPressed: () {},
                tooltip: 'Voice Note',
                constraints: const BoxConstraints(),
              ),
              Container(width: 1, height: 20, color: EverforestColors.bg2),
              IconButton(
                icon: const Icon(Icons.add_task, color: EverforestColors.green, size: 20),
                onPressed: () {},
                tooltip: 'Add Task',
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
