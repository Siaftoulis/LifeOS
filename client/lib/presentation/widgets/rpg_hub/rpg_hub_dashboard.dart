import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'points/point_star_dashboard.dart';
import 'quests/quest_board.dart';
import 'rpg_player/rpg_dashboard.dart';

class RpgHubDashboard extends StatelessWidget {
  const RpgHubDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: EverforestColors.bg0,
        appBar: AppBar(
          backgroundColor: EverforestColors.bg0,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EverforestColors.yellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.military_tech_rounded,
                    color: EverforestColors.yellow, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'RPG & Star Economy',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: EverforestColors.yellow,
            indicatorWeight: 3,
            labelColor: EverforestColors.yellow,
            unselectedLabelColor: EverforestColors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
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
            const RpgDashboard(),
            const QuestBoard(),
            const PointStarDashboard(),
            const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: VoucherRedeemerPanel(),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  LeaderboardList(),
                  SizedBox(height: 20),
                  PointsLedgerPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
