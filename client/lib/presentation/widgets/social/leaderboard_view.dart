import 'package:flutter/material.dart';

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Leaderboard'),
        backgroundColor: Colors.amber,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildLeaderboardRow(rank: 1, name: 'Alice (Admin)', points: 1540, isMe: true),
          _buildLeaderboardRow(rank: 2, name: 'Bob', points: 820, isMe: false),
          _buildLeaderboardRow(rank: 3, name: 'Charlie', points: 310, isMe: false),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow({required int rank, required String name, required int points, required bool isMe}) {
    return Card(
      color: isMe ? Colors.amber[50] : Colors.white,
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rank == 1 ? Colors.amber : Colors.blueGrey,
          child: Text('#$rank', style: const TextStyle(color: Colors.white)),
        ),
        title: Text(name, style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
        trailing: Text('$points XP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
