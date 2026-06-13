import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class LeaderboardCard extends StatelessWidget {
  final String username;
  final int points;
  final int rank;

  const LeaderboardCard({super.key, required this.username, required this.points, required this.rank});

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    if (rank == 1) rankColor = EverforestColors.yellow;
    else if (rank == 2) rankColor = EverforestColors.grey;
    else rankColor = EverforestColors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: rankColor.withOpacity(0.2),
            child: Text('#$rank', style: TextStyle(color: rankColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: points / 2000, color: rankColor, backgroundColor: EverforestColors.bg2),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text('$points ⭐', style: const TextStyle(color: EverforestColors.yellow, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
