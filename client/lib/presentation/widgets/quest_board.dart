import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';
import '../../database/database.dart';
import '../../database/chtm_dao.dart';
import '../../database/points_dao.dart';
import 'package:provider/provider.dart';
import 'quests/quest_daily_list.dart';
import 'quests/quest_reward_store.dart';

class QuestBoard extends StatelessWidget {
  const QuestBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final chtmDao = ChtmDao(db);
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
                StreamBuilder<SystemUser?>(
                  stream: pointsDao.watchAdminUser(),
                  builder: (context, snapshot) {
                    final points = snapshot.data?.currentPoints ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: EverforestColors.yellow.withOpacity(0.5), width: 1.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_border, color: EverforestColors.yellow, size: 16),
                          const SizedBox(width: 8),
                          Text(points.toString(), style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    );
                  }
                ),
              ],
            ),
            const SizedBox(height: 48),
            QuestDailyList(
              dao: chtmDao, 
              habitsStream: chtmDao.watchAllHabits(), 
              tasksStream: chtmDao.watchAllTasks()
            ),
            const SizedBox(height: 48),
            QuestRewardStore(vouchersStream: pointsDao.watchAllVouchers()),
          ],
        ),
      ),
    );
  }
}
