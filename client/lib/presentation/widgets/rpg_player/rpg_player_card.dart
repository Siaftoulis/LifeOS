import 'package:flutter/material.dart';
import '../../../core/models/player_models.dart';

class RpgPlayerCard extends StatelessWidget {
  final PlayerStats stats;
  final IllnessState? activeIllness;
  final VoidCallback onRefresh;

  const RpgPlayerCard({
    Key? key,
    required this.stats,
    this.activeIllness,
    required this.onRefresh,
  }) : super(key: key);

  bool get _isInjured => activeIllness?.type == 'physical_injury';

  @override
  Widget build(BuildContext context) {
    // Current XP progression in the current level bounds
    // Not provided directly, so we just show XP / NextLevelXP
    final double progress = stats.nextLevelXp > 0 ? (stats.xp / stats.nextLevelXp) : 0.0;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade900,
              Colors.black87,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.person, size: 40, color: Colors.black87),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Player One",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: 
                            FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Lvl ${stats.effectiveLevel}  |  Age ${stats.age.toInt()}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "XP: ${stats.xp} / ${stats.nextLevelXp}",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "Biological Cap: Lvl ${stats.biologicalCap}",
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
                      _isInjured ? Colors.redAccent : Colors.cyanAccent,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: "Willpower",
                    value: stats.willpower.toStringAsFixed(0),
                    icon: Icons.psychology,
                    color: Colors.purpleAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: "Atrophy Buffer",
                    value: "${stats.atrophyBufferDays} days",
                    icon: Icons.shield,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: "Stamina",
                    value: _isInjured ? "LOCKED (-50%)" : "Active",
                    icon: Icons.fitness_center,
                    color: _isInjured ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
