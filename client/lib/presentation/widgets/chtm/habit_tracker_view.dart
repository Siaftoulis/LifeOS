import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../database/chtm_dao.dart';
import '../../../database/points_dao.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
class HabitTrackerView extends StatefulWidget {
  const HabitTrackerView({super.key});

  @override
  State<HabitTrackerView> createState() => _HabitTrackerViewState();
}

class _HabitTrackerViewState extends State<HabitTrackerView> {
  final db = AppDatabase.instance;
  late final ChtmDao dao;
  late final PointsDao pointsDao;

  @override
  void initState() {
    super.initState();
    dao = ChtmDao(db);
    pointsDao = PointsDao(db);
  }

  void _showAddPresetDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: EverforestColors.bg0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Habit Preset',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildPresetOption(
                icon: Icons.water_drop,
                title: 'Drink Water',
                subtitle: 'Simple Check (Yes/No)',
                type: 'CHECK',
                color: EverforestColors.blue,
              ),
              _buildPresetOption(
                icon: Icons.directions_run,
                title: '10k Steps',
                subtitle: 'Goal-based Tracking',
                type: 'STEPS',
                goalValue: 10000.0,
                unit: 'steps',
                color: EverforestColors.green,
              ),
              _buildPresetOption(
                icon: Icons.directions_bike,
                title: 'Cycling Distance',
                subtitle: 'Distance Tracking (km)',
                type: 'DISTANCE',
                goalValue: 5.0,
                unit: 'km',
                color: EverforestColors.yellow,
              ),
              _buildPresetOption(
                icon: Icons.timer,
                title: 'Gymnastics Routine',
                subtitle: 'Timer-based (30 mins)',
                type: 'TIMER',
                goalValue: 30.0,
                unit: 'mins',
                color: EverforestColors.red,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String type,
    required Color color,
    double goalValue = 1.0,
    String? unit,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: EverforestColors.grey)),
      onTap: () async {
        Navigator.pop(context);
        await dao.insertHabit(UserHabitsCompanion.insert(
          id: const Uuid().v4(),
          name: title,
          frequencyCron: '* * * * *',
          type: Value(type), // This requires the new drift generation
          goalValue: Value(goalValue),
          unit: unit == null ? const Value.absent() : Value(unit),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserHabit>>(
      stream: dao.watchAllHabits(),
      builder: (context, snapshot) {
        final habits = snapshot.data ?? [];
        return Scaffold(
          backgroundColor: EverforestColors.bg0,
          body: habits.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    return _buildHabitCard(habits[index]);
                  },
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: EverforestColors.green,
            foregroundColor: EverforestColors.bg0,
            onPressed: _showAddPresetDialog,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.track_changes, size: 64, color: EverforestColors.grey),
          const SizedBox(height: 16),
          const Text(
            'No habits tracked yet',
            style: TextStyle(color: EverforestColors.grey, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showAddPresetDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Habit from Presets'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EverforestColors.green,
              foregroundColor: EverforestColors.bg0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(UserHabit habit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${habit.type} • Goal: ${habit.goalValue.toInt()} ${habit.unit ?? ""}',
                      style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildPointsBadge(habit.baseXp),
            ],
          ),
          const SizedBox(height: 16),
          _buildHabitControl(habit),
        ],
      ),
    );
  }

  Widget _buildPointsBadge(int xp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: EverforestColors.yellow.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: EverforestColors.yellow, size: 14),
          const SizedBox(width: 4),
          Text(
            '+$xp XP',
            style: const TextStyle(
              color: EverforestColors.yellow,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitControl(UserHabit habit) {
    if (habit.type == 'CHECK') {
      return ElevatedButton.icon(
        onPressed: () => _completeHabit(habit, habit.goalValue),
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Mark Completed'),
        style: ElevatedButton.styleFrom(
          backgroundColor: EverforestColors.green,
          foregroundColor: EverforestColors.bg0,
        ),
      );
    } else if (habit.type == 'STEPS' || habit.type == 'DISTANCE') {
      return FutureBuilder<double>(
        future: dao.getTodayProgress(habit.id),
        builder: (context, snapshot) {
          final progress = (snapshot.data ?? 0.0).clamp(0.0, habit.goalValue) / habit.goalValue;
          return Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: EverforestColors.bg2,
                  color: habit.type == 'STEPS' ? EverforestColors.green : EverforestColors.blue,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.add_circle, color: EverforestColors.green),
                onPressed: () => _completeHabit(habit, habit.goalValue),
              ),
            ],
          );
        },
      );
    } else if (habit.type == 'TIMER') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.play_circle_fill, color: EverforestColors.red, size: 48),
            onPressed: () {}, // Start timer
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.stop_circle, color: EverforestColors.grey, size: 36),
            onPressed: () => _completeHabit(habit, habit.goalValue),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  void _completeHabit(UserHabit habit, double value) async {
    // 1. Calculate partial status
    String status = 'DONE';
    double ratio = value / habit.goalValue;
    if (ratio < 1.0) {
      status = 'PARTIAL';
    }
    
    int xpToAward = (habit.baseXp * ratio).round();

    // 2. Insert Log
    await dao.insertHabitLog(HabitLogsCompanion.insert(
      id: const Uuid().v4(),
      habitId: habit.id,
      checkinDate: DateTime.now().millisecondsSinceEpoch,
      pointsAwarded: xpToAward,
      completedValue: Value(value),
      status: Value(status),
      isDirty: const Value(1),
    ));

    // 3. Award XP & Points in Economy
    if (xpToAward > 0) {
      await pointsDao.awardPoints(xpToAward, 'Completed Habit: ${habit.name}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Awesome! You earned +$xpToAward XP!'),
            backgroundColor: EverforestColors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
