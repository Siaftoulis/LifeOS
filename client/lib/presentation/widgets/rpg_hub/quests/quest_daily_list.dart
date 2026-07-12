import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../api_client.dart';

class QuestDailyList extends StatefulWidget {
  final VoidCallback? onQuestCompleted;
  const QuestDailyList({super.key, this.onQuestCompleted});

  @override
  State<QuestDailyList> createState() => _QuestDailyListState();
}

class _QuestDailyListState extends State<QuestDailyList> {
  List<dynamic> _quests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQuests();
  }

  Future<void> _fetchQuests() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/rpg/quests');
      if (mounted) {
        setState(() {
          final allQuests = res as List<dynamic>;
          _quests = allQuests.where((q) => q['status'] == 'ACTIVE' || q['status'] == 'DONE').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching quests: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: EverforestColors.green),
      );
    }

    if (_quests.isEmpty) {
      return const Center(
        child: Text(
          "All quests completed for today!",
          style: TextStyle(color: EverforestColors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('DAILY QUESTS', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
        ..._quests.map((q) {
          final isDone = q['status'] == 'DONE';
          return _buildQuestItem(
            q['title'] ?? 'Unknown',
            '+${q['xp_reward']} XP',
            isDone,
            isDone ? () {} : () async {
              try {
                setState(() => _isLoading = true);
                await ApiClient.instance.postDaemon('/api/v1/rpg/quests/complete', {'quest_id': q['id']});
                await _fetchQuests();
                if (widget.onQuestCompleted != null) {
                  widget.onQuestCompleted!();
                }
              } catch (e) {
                debugPrint('Failed to complete quest: $e');
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            }
          );
        }).toList(),
      ],
    );
  }

  Widget _buildQuestItem(String title, String reward, bool isCompleted, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isCompleted ? EverforestColors.fg : EverforestColors.grey, width: 1.5),
              ),
              child: isCompleted ? const Icon(Icons.check, size: 16, color: EverforestColors.fg) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isCompleted ? EverforestColors.grey : EverforestColors.fg,
                  fontSize: 15,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Text(
              reward,
              style: TextStyle(
                color: isCompleted ? EverforestColors.grey : EverforestColors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
