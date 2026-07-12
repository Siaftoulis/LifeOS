import 'package:flutter/material.dart';

class QuestBoard extends StatefulWidget {
  const QuestBoard({super.key});

  @override
  State<QuestBoard> createState() => _QuestBoardState();
}

class _QuestBoardState extends State<QuestBoard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Quests'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildQuestCard(
            title: 'Take a biscuit',
            points: 10,
            assignedTo: 'Bob',
            status: 'PENDING',
          ),
          _buildQuestCard(
            title: 'Clean the kitchen',
            points: 50,
            assignedTo: 'Anyone',
            status: 'OPEN',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Show Create Quest Dialog
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildQuestCard({required String title, required int points, required String assignedTo, required String status}) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Chip(
                  label: Text('$points XP', style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.amber[700],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Assigned to: $assignedTo', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'PENDING') ...[
                  TextButton(
                    onPressed: () {
                      // TODO: Deny Quest
                    },
                    child: const Text('Deny', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Accept Quest
                    },
                    child: const Text('Accept'),
                  ),
                ],
                if (status == 'OPEN')
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Claim Quest
                    },
                    child: const Text('Claim'),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
