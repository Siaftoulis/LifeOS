import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import 'leaderboard_card.dart';
import 'voucher_redeemer_panel.dart';

class PointStarDashboard extends StatelessWidget {
  const PointStarDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Point Star System', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.confirmation_number),
                label: const Text('Store Vouchers'),
                style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.purple),
                onPressed: () => _showVouchers(context),
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: wide
                ? const Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 2, child: _LeaderboardList()),
                      SizedBox(width: 16),
                      Expanded(flex: 3, child: _LedgerLog()),
                    ],
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 2, child: _LeaderboardList()),
                      SizedBox(height: 16),
                      Expanded(flex: 3, child: _LedgerLog()),
                    ],
                  ),
          )
        ],
      ),
    );
  }

  void _showVouchers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const VoucherRedeemerPanel(),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Family Leaderboard', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<SystemUser>>(
              stream: AppDatabase.instance.pointsDao.watchAllUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: EverforestColors.purple));
                }
                final users = snapshot.data!;
                final sortedUsers = List<SystemUser>.from(users)..sort((a, b) => b.currentPoints.compareTo(a.currentPoints));
                return ListView.builder(
                  itemCount: sortedUsers.length,
                  itemBuilder: (context, index) {
                    final user = sortedUsers[index];
                    return LeaderboardCard(
                      username: user.username,
                      points: user.currentPoints,
                      rank: index + 1,
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _LedgerLog extends StatelessWidget {
  const _LedgerLog();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Recent Ledger Logs', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<PointsLedger>>(
              stream: AppDatabase.instance.pointsDao.watchRecentLedger(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: EverforestColors.purple));
                }
                final logs = snapshot.data!;
                if (logs.isEmpty) {
                  return const Center(child: Text('No recent logs', style: TextStyle(color: EverforestColors.grey)));
                }
                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final logEntry = logs[index];
                    final isPositive = logEntry.points >= 0;
                    final time = DateTime.fromMillisecondsSinceEpoch(logEntry.timestamp * 1000);
                    final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                    return ListTile(
                      leading: Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: isPositive ? EverforestColors.green : EverforestColors.red),
                      title: Text(logEntry.event, style: const TextStyle(color: EverforestColors.fg)),
                      subtitle: Text(timeStr, style: const TextStyle(color: EverforestColors.grey)),
                      trailing: Text(
                        "${isPositive ? '+' : ''}${logEntry.points} pts",
                        style: TextStyle(
                          color: isPositive ? EverforestColors.green : EverforestColors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
