import 'package:flutter/material.dart';
import '../../../../auth_service.dart';
import '../../../../theme/everforest_colors.dart';
import 'family_goal_widget.dart';
import 'family_quests_section.dart';
import 'leaderboard_list.dart';
import 'points_ledger_panel.dart';
import 'voucher_redeemer_panel.dart';

export 'family_goal_widget.dart';
export 'family_quests_section.dart';
export 'leaderboard_list.dart';
export 'points_ledger_panel.dart';
export 'voucher_redeemer_panel.dart';

class PointStarDashboard extends StatelessWidget {
  const PointStarDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;

    return ValueListenableBuilder<UserProfile?>(
      valueListenable: AuthService.instance.currentUser,
      builder: (context, user, _) {
        final isAdmin = user?.role == 'ADMIN';

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                EverforestColors.bg0,
                EverforestColors.bg1,
              ],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 16,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'S Y S T E M',
                        style: TextStyle(
                          color: EverforestColors.green,
                          fontSize: 14,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Star System & Family Quests',
                        style: TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                                color: EverforestColors.green
                                    .withValues(alpha: 0.5),
                                blurRadius: 10)
                          ],
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.stars, color: Colors.white),
                        label: const Text('REWARD STORE',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EverforestColors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                          elevation: 10,
                          shadowColor:
                              EverforestColors.purple.withValues(alpha: 0.8),
                        ),
                        onPressed: () => _showVouchers(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // BODY
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Expanded(flex: 1, child: LeaderboardList()),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                FamilyGoalWidget(isAdmin: isAdmin),
                                const SizedBox(height: 24),
                                Expanded(
                                    child: FamilyQuestsSection(
                                        isAdmin: isAdmin)),
                                const SizedBox(height: 24),
                                SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxHeight: 420),
                                    child: const PointsLedgerPanel(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            FamilyGoalWidget(isAdmin: isAdmin),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 480,
                              child: FamilyQuestsSection(isAdmin: isAdmin),
                            ),
                            const SizedBox(height: 24),
                            const SizedBox(
                              height: 320,
                              child: LeaderboardList(),
                            ),
                            const SizedBox(height: 24),
                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxHeight: 420),
                              child: const PointsLedgerPanel(),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVouchers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoucherRedeemerPanel(),
    );
  }
}
