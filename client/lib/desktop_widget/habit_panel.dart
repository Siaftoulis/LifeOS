import 'package:flutter/material.dart';

class HabitPanel extends StatelessWidget {
  final Map<String, dynamic> data;
  const HabitPanel({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final habits = data['habits'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Habits', 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        if (habits.isEmpty)
          const Text('All Habits Synced', style: TextStyle(color: Colors.white70)),
        for (var habit in habits)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $habit', style: const TextStyle(color: Colors.white)),
          )
      ],
    );
  }
}
