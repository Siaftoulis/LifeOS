import 'package:flutter/material.dart';
import '../../../../core/models/player_models.dart';
import '../../../../theme/everforest_colors.dart';
import 'player_card_header.dart';
import 'player_xp_progress.dart';
import 'stat_box.dart';

class RpgPlayerCard extends StatelessWidget {
  final PlayerStats stats;
  final IllnessState? activeIllness;
  final VoidCallback onRefresh;

  const RpgPlayerCard({Key? key, required this.stats, this.activeIllness, required this.onRefresh}) : super(key: key);

  bool get _isInjured => activeIllness?.type == 'physical_injury';

  @override
  Widget build(BuildContext context) {
    final hasMild = activeIllness?.isActive == true && activeIllness?.type == 'mild_illness';
    final attrs = stats.attributes;
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2, width: 1.5),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlayerCardHeader(effectiveLevel: stats.effectiveLevel, age: stats.age.toInt(), onRefresh: onRefresh),
          const SizedBox(height: 24),
          PlayerXpProgress(xp: stats.xp, nextLevelXp: stats.nextLevelXp, biologicalCap: stats.biologicalCap, isInjured: _isInjured),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: StatBox(label: "Stamina", value: _isInjured ? "LOCKED" : "${attrs['stamina'] ?? 0}", icon: Icons.fitness_center, color: _isInjured ? EverforestColors.red : EverforestColors.green)),
            const SizedBox(width: 12),
            Expanded(child: StatBox(label: "Intelligence", value: "${attrs['intelligence'] ?? 0}", icon: Icons.lightbulb, color: EverforestColors.yellow)),
            const SizedBox(width: 12),
            Expanded(child: StatBox(label: "Focus", value: "${attrs['focus'] ?? 0}", icon: Icons.center_focus_strong, color: EverforestColors.blue)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: StatBox(label: "Charisma", value: "${attrs['charisma'] ?? 0}", icon: Icons.record_voice_over, color: EverforestColors.orange)),
            const SizedBox(width: 12),
            Expanded(child: StatBox(
              label: "Willpower", value: "${attrs['willpower'] ?? 0}", icon: Icons.psychology, color: EverforestColors.purple,
              badge: hasMild ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: EverforestColors.green, borderRadius: BorderRadius.circular(4)),
                child: const Text("+200%", style: TextStyle(color: EverforestColors.bg0, fontSize: 10, fontWeight: FontWeight.bold)),
              ) : null,
            )),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.shield, color: EverforestColors.blue, size: 18),
            const SizedBox(width: 8),
            Text("Atrophy Buffer: ${stats.atrophyBufferDays} days", style: const TextStyle(color: EverforestColors.fg, fontSize: 13)),
          ]),
        ],
      ),
    );
  }
}
