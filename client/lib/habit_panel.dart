import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/habit_ring.dart';

class HabitMatrixGrid extends StatefulWidget {
  final dynamic db;
  const HabitMatrixGrid({super.key, required this.db});
  @override State<HabitMatrixGrid> createState() => _HMState();
}

class _HMState extends State<HabitMatrixGrid> {
  void _toggle(Map<String, dynamic> item) async {
    final done = item['done'] == 1 ? 0 : 1;
    if (done == 1) HapticFeedback.mediumImpact();
    try {
      await widget.db.customStatement('UPDATE habits SET done = ?, is_dirty = 1 WHERE id = ?', [done, item['id']]);
    } catch (e) { debugPrint("DB error: $e"); }
  }

  @override Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.db.customSelect('SELECT * FROM habits ORDER BY id').watch(),
      builder: (context, snap) {
        final List habits = (snap.data as List?) ?? [];
        if (habits.isEmpty) return const Center(child: Text("No habits defined.", style: TextStyle(color: Colors.grey)));
        
        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: habits.length,
            itemBuilder: (_, i) => HabitRing(item: habits[i].data, onTap: () => _toggle(habits[i].data)),
          ),
        );
      },
    );
  }
}
