import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../api_client.dart';
import '../../../../auth_service.dart';

class QuestDailyList extends StatefulWidget {
  final VoidCallback? onQuestCompleted;
  final DateTime? date;
  const QuestDailyList({super.key, this.onQuestCompleted, this.date});

  @override
  State<QuestDailyList> createState() => _QuestDailyListState();
}

class _QuestDailyListState extends State<QuestDailyList> {
  List<dynamic> _quests = [];
  bool _isLoading = true;

  String get _username => AuthService.instance.currentUser.value?.username ?? 'panospds';

  String get _today {
    final now = widget.date ?? DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

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
          _quests = allQuests.where((q) {
            final status = q['status'];
            if (status == 'ACTIVE' || status == 'DONE') return true;
            if (status == 'POOL' && q['due_date'] == _today) return true;
            return false;
          }).toList();
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

  void _onQuestChanged() {
    _fetchQuests();
    if (widget.onQuestCompleted != null) {
      widget.onQuestCompleted!();
    }
  }

  Future<void> _accept(String questId) async {
    try {
      setState(() => _isLoading = true);
      await ApiClient.instance.postDaemon('/api/v1/rpg/quests/accept', {'quest_id': questId});
      _onQuestChanged();
    } catch (e) {
      debugPrint('Failed to accept quest: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _complete(String questId) async {
    try {
      setState(() => _isLoading = true);
      await ApiClient.instance.postDaemon('/api/v1/rpg/quests/complete', {'quest_id': questId});
      _onQuestChanged();
    } catch (e) {
      debugPrint('Failed to complete quest: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancel(String questId, String title, int reward) async {
    final penalty = (reward + 1) ~/ 2;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Cancel Quest?', style: TextStyle(color: EverforestColors.fg)),
        content: Text(
          'You claimed "$title". Cancelling costs a penalty of $penalty stars. Continue?',
          style: const TextStyle(color: EverforestColors.fg),
        ),
        actions: [
          TextButton(
            child: const Text('Keep Quest', style: TextStyle(color: EverforestColors.grey)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Cancel Quest', style: TextStyle(color: EverforestColors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        await ApiClient.instance.postDaemon('/api/v1/rpg/quests/cancel', {'quest_id': questId});
        _onQuestChanged();
      } catch (e) {
        debugPrint('Failed to cancel quest: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
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
        const Text('DAILY BOUNTY PASS', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
        ..._quests.map((q) {
          final isDone = q['status'] == 'DONE';
          final acceptedBy = q['accepted_by'] ?? '';
          final claimedByMe = acceptedBy == _username;
          final available = q['status'] == 'POOL';

          final Widget trailing;
          if (isDone) {
            trailing = const Icon(Icons.check_circle, color: EverforestColors.green, size: 20);
          } else if (available) {
            trailing = IconButton(
              icon: const Icon(Icons.flag, color: EverforestColors.green),
              onPressed: () => _accept(q['id']),
              tooltip: 'Accept Quest',
            );
          } else if (claimedByMe) {
            trailing = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: EverforestColors.green),
                  onPressed: () => _complete(q['id']),
                  tooltip: 'Complete Quest',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: EverforestColors.red),
                  onPressed: () => _cancel(q['id'], q['title'] ?? 'Unknown', (q['xp_reward'] ?? 0) as int),
                  tooltip: 'Cancel Quest',
                ),
              ],
            );
          } else {
            trailing = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: EverforestColors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Claimed by $acceptedBy',
                style: const TextStyle(color: EverforestColors.green, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isDone ? EverforestColors.green : EverforestColors.grey, width: 1.5),
                  ),
                  child: isDone ? const Icon(Icons.check, size: 16, color: EverforestColors.green) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q['title'] ?? 'Unknown',
                        style: TextStyle(
                          color: isDone ? EverforestColors.grey : EverforestColors.fg,
                          fontSize: 15,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (!isDone && (q['description'] ?? '').toString().isNotEmpty)
                        Text(
                          q['description'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (!isDone)
                  Text(
                    '+${q['xp_reward']} XP',
                    style: TextStyle(
                      color: isDone ? EverforestColors.grey : EverforestColors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
