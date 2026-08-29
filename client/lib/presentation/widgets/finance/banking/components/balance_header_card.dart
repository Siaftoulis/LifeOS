import 'package:flutter/material.dart';
import '../../../../../theme/everforest_colors.dart';
import '../banking_models_and_helpers.dart';

class BalanceHeaderCard extends StatelessWidget {
  const BalanceHeaderCard({
    super.key,
    required this.balance,
    required this.monthIncome,
    required this.monthExpenses,
  });

  final double balance;
  final double monthIncome;
  final double monthExpenses;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: EverforestColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  monthLabel(),
                  style: const TextStyle(
                      color: EverforestColors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fmtEuro(balance),
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildBalanceStat(
                  icon: Icons.arrow_downward,
                  iconColor: EverforestColors.green,
                  label: 'Income this month',
                  amount: fmtEuro(monthIncome),
                ),
              ),
              Container(width: 1, height: 40, color: EverforestColors.bg2),
              Expanded(
                child: _buildBalanceStat(
                  icon: Icons.arrow_upward,
                  iconColor: EverforestColors.red,
                  label: 'Expenses this month',
                  amount: fmtEuro(monthExpenses),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBalanceStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String amount,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: EverforestColors.grey, fontSize: 12)),
            const SizedBox(height: 2),
            Text(amount,
                style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    required this.onImportReceipt,
    required this.onReceiveMoney,
    required this.onAddBill,
  });

  final VoidCallback onImportReceipt;
  final VoidCallback onReceiveMoney;
  final VoidCallback onAddBill;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(
          icon: Icons.receipt_long,
          label: 'Receipt',
          color: EverforestColors.blue,
          onTap: onImportReceipt,
        ),
        _buildActionItem(
          icon: Icons.download_rounded,
          label: 'Receive',
          color: EverforestColors.green,
          onTap: onReceiveMoney,
        ),
        _buildActionItem(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Bills',
          color: EverforestColors.purple,
          onTap: onAddBill,
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
