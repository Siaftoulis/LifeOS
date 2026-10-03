import 'package:flutter/material.dart';
import 'points/point_star_dashboard.dart';
import 'quests/quest_board.dart';
import 'rpg_player/rpg_dashboard.dart';

import '../../../theme/app_skin_manager.dart';

class RpgHubDashboard extends StatelessWidget {
  const RpgHubDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSkinManager.currentSkinNotifier,
      builder: (context, _) {
        final skin = context.skin;
        return DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: skin.bg0,
            appBar: AppBar(
              backgroundColor: skin.bg0,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: skin.yellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.military_tech_rounded,
                        color: skin.yellow, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'RPG & Star Economy',
                    style: TextStyle(
                      color: skin.fg,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              bottom: TabBar(
                isScrollable: true,
                indicatorColor: skin.yellow,
                indicatorWeight: 3,
                labelColor: skin.yellow,
                unselectedLabelColor: skin.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.person_rounded, size: 18),
                    text: 'Profile & Stats',
                  ),
                  Tab(
                    icon: Icon(Icons.checklist_rounded, size: 18),
                    text: 'Quests & Chores',
                  ),
                  Tab(
                    icon: Icon(Icons.stars_rounded, size: 18),
                    text: 'Star Dashboard',
                  ),
                  Tab(
                    icon: Icon(Icons.shopping_bag_rounded, size: 18),
                    text: 'Rewards Store',
                  ),
                  Tab(
                    icon: Icon(Icons.leaderboard_rounded, size: 18),
                    text: 'Leaderboard & Ledger',
                  ),
                ],
              ),
            ),
            body: TabBarView(
              physics:
                  const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              children: [
                KeyedSubtree(key: ValueKey('rpg_dashboard_${skin.id}'), child: const RpgDashboard()),
                KeyedSubtree(key: ValueKey('rpg_quests_${skin.id}'), child: const QuestBoard()),
                KeyedSubtree(key: ValueKey('rpg_points_${skin.id}'), child: const PointStarDashboard()),
                KeyedSubtree(
                  key: ValueKey('rpg_vouchers_${skin.id}'),
                  child: const SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: VoucherRedeemerPanel(),
                  ),
                ),
                KeyedSubtree(
                  key: ValueKey('rpg_ledger_${skin.id}'),
                  child: const SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        LeaderboardList(),
                        SizedBox(height: 20),
                        PointsLedgerPanel(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
