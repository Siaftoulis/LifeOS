import 'package:flutter/material.dart';

class PlayerXpProgress extends StatelessWidget {
  final int xp;
  final int nextLevelXp;
  final int biologicalCap;
  final bool isInjured;

  const PlayerXpProgress({
    super.key,
    required this.xp,
    required this.nextLevelXp,
    required this.biologicalCap,
    required this.isInjured,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = nextLevelXp > 0 ? (xp / nextLevelXp) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "XP: $xp / $nextLevelXp",
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              "Biological Cap: Lvl $biologicalCap",
              style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isInjured ? Colors.redAccent : Colors.cyanAccent,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
