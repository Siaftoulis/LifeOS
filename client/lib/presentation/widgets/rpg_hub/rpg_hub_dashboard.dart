import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'rpg_player/rpg_dashboard.dart';
import 'points/point_star_dashboard.dart';

class RpgHubDashboard extends StatelessWidget {
  const RpgHubDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: EverforestColors.bg0,
        appBar: AppBar(
          backgroundColor: EverforestColors.bg1,
          title: const Text('RPG & Star System', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Profile & Stats'),
              Tab(text: 'Star System'),
            ],
            labelColor: EverforestColors.green,
            unselectedLabelColor: EverforestColors.grey,
            indicatorColor: EverforestColors.green,
          ),
        ),
        body: const TabBarView(
          physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          children: [
            RpgDashboard(),
            PointStarDashboard(),
          ],
        ),
      ),
    );
  }
}
