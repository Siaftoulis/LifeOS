import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../database/database.dart';
import '../../../../database/points_dao.dart';
import 'quest_daily_list.dart';
import 'quest_pool_list.dart';
import 'quest_reward_store.dart';
import 'add_quest_dialog.dart';
import '../../../../api_client.dart';
import '../../../../core/event_hub.dart';

class QuestBoard extends StatefulWidget {
  const QuestBoard({super.key});

  @override
  State<QuestBoard> createState() => _QuestBoardState();
}

class _QuestBoardState extends State<QuestBoard> {
  int _points = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPoints();
    // Live: the daemon pushed a balance change → refresh instantly, no poll.
    EventHub.instance.on('points:balance-change').listen((_) => _fetchPoints());
  }

  Future<void> _fetchPoints() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/points/leaderboard');
      final users = res as List<dynamic>;
      final user = users.firstWhere((u) => u['username'] == 'panospds', orElse: () => null);
      if (mounted) {
        setState(() {
          _points = user != null ? (user['points'] as int) : 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddQuestDialog() {
    showDialog(
      context: context,
      builder: (_) => AddQuestDialog(
        onQuestAdded: () {
          // Rebuild to fetch new quests in pool
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase.instance;
    final pointsDao = PointsDao(db);

    return Container(
      color: EverforestColors.bg0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: EverforestColors.bg0,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: EverforestColors.fg, width: 1.5),
                  ),
                  child: const Text('QUEST BOARD', style: TextStyle(color: EverforestColors.fg, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: EverforestColors.yellow.withValues(alpha: 0.5), width: 1.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_border, color: EverforestColors.yellow, size: 16),
                      const SizedBox(width: 8),
                      Text(_isLoading ? '...' : _points.toString(), style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AVAILABLE QUESTS', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w500)),
                ElevatedButton.icon(
                  onPressed: _showAddQuestDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Custom Quest'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EverforestColors.bg1,
                    foregroundColor: EverforestColors.green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: EverforestColors.green)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            QuestPoolList(key: UniqueKey(), onQuestActivated: () {
              // Rebuild the daily list when a quest is activated
              setState(() {});
            }),
            const SizedBox(height: 48),
            QuestDailyList(key: UniqueKey(), onQuestCompleted: _fetchPoints),
            const SizedBox(height: 48),
            QuestRewardStore(vouchersStream: pointsDao.watchAllVouchers()),
          ],
        ),
      ),
    );
  }
}
