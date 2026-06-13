import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'leaderboard_card.dart';
import 'voucher_redeemer_panel.dart';

class PointStarDashboard extends StatelessWidget {
  const PointStarDashboard({super.key});

  @override
  Widget build(BuildContext context) {
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
          const Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: _LeaderboardList()),
                SizedBox(width: 16),
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
            child: ListView(
              children: const [
                LeaderboardCard(username: 'Alice (Admin)', points: 1540, rank: 1),
                LeaderboardCard(username: 'Bob', points: 820, rank: 2),
                LeaderboardCard(username: 'Charlie', points: 310, rank: 3),
              ],
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
            child: ListView.builder(
              itemCount: 15,
              itemBuilder: (context, index) {
                final isPositive = index % 3 != 0;
                return ListTile(
                  leading: Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: isPositive ? EverforestColors.green : EverforestColors.red),
                  title: Text(isPositive ? 'Completed Math Homework' : 'Redeemed Netflix Hour', style: const TextStyle(color: EverforestColors.fg)),
                  subtitle: const Text('2 hours ago', style: TextStyle(color: EverforestColors.grey)),
                  trailing: Text(isPositive ? '+10 pts' : '-50 pts', style: TextStyle(color: isPositive ? EverforestColors.green : EverforestColors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
